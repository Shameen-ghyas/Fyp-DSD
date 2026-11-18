// encdec_top_tcn.v
// Descriptor-driven TCN autoencoder.

module encdec_top_tcn
#(
    parameter N = 16,
    parameter TW = 7,
    parameter AWB = 6,
    parameter NL = 7,
    parameter WAW = 8,
    parameter BAW = 6,
    parameter OUT_BUF = 2,

    parameter DESC_FILE = "vectors/tcn_desc.mem",
    parameter WFILE = "vectors/tcn_wrom.mem",
    parameter BFILE = "vectors/tcn_brom.mem"
)
(
    input clk,
    input rst_n,
    input start,

    output busy,
    output reg done,
    output reg [31:0] cycles,

    output [AWB-1:0] in_raddr,
    input [N*8-1:0] in_rdata,

    input [AWB-1:0] ext_raddr,
    output [N*8-1:0] out_rdata
);

    // --------------------------------
    // Operation codes
    // --------------------------------

    localparam OP_CONV = 3'd0;
    localparam OP_POOL = 3'd1;
    localparam OP_UP   = 3'd2;
    localparam OP_ADD  = 3'd3;

    // --------------------------------
    // Descriptor ROM
    // --------------------------------

    reg [63:0] desc_mem [0:NL-1];

    initial
        $readmemh(DESC_FILE, desc_mem);

    reg [3:0] layer;

    wire [63:0] desc;

    assign desc = desc_mem[layer];

    wire [2:0] op;
    wire [1:0] src, src2, dst;

    wire [7:0] n_t;

    wire [4:0] c_out, dil, shift;
    wire [3:0] ktaps;

    wire relu;

    wire [7:0] wbase;
    wire [5:0] bbase;

    assign op    = desc[2:0];
    assign src   = desc[4:3];
    assign src2  = desc[6:5];
    assign dst   = desc[8:7];

    assign n_t   = desc[16:9];
    assign c_out = desc[21:17];
    assign ktaps = desc[25:22];
    assign dil   = desc[30:26];

    assign shift = desc[35:31];
    assign relu  = desc[36];

    assign wbase = desc[44:37];
    assign bbase = desc[50:45];

    // --------------------------------
    // Controller FSM
    // --------------------------------

    localparam S_IDLE  = 2'b00;
    localparam S_START = 2'b01;
    localparam S_RUN   = 2'b10;
    localparam S_NEXT  = 2'b11;

    reg [1:0] state;

    wire op_done;

    assign busy = (state != S_IDLE);

    wire go;

    assign go = (state == S_START);

    wire conv_start;
    wire pool_start;
    wire up_start;
    wire add_start;

    assign conv_start = go && (op == OP_CONV);
    assign pool_start = go && (op == OP_POOL);
    assign up_start   = go && (op == OP_UP);
    assign add_start  = go && (op == OP_ADD);

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state  <= S_IDLE;
            layer  <= 0;
            done   <= 0;
            cycles <= 0;
        end
        else
        begin
            done <= 0;

            if (state != S_IDLE)
                cycles <= cycles + 1'b1;

            case (state)

                S_IDLE:
                begin
                    if (start)
                    begin
                        layer  <= 0;
                        cycles <= 0;
                        state  <= S_START;
                    end
                end

                S_START:
                    state <= S_RUN;

                S_RUN:
                begin
                    if (op_done)
                        state <= S_NEXT;
                end

                S_NEXT:
                begin
                    if (layer == NL - 1)
                    begin
                        done  <= 1;
                        state <= S_IDLE;
                    end
                    else
                    begin
                        layer <= layer + 1'b1;
                        state <= S_START;
                    end
                end

                default:
                    state <= S_IDLE;

            endcase
        end
    end

    // --------------------------------
    // Memories
    // --------------------------------

    wire [AWB-1:0] rd_addr;
    wire [AWB-1:0] eng_raddr;

    wire [N*8-1:0] qa, qb, qc;

    wire wr_we;
    wire [AWB-1:0] wr_addr;
    wire [N*8-1:0] wr_data;

    assign rd_addr = busy ? eng_raddr : ext_raddr;

    assign in_raddr = rd_addr;

    dp_ram #(
        .DW(N*8),
        .AW(AWB)
    ) mem_a (
        .clk(clk),
        .we(wr_we && dst == 2'd1),
        .waddr(wr_addr),
        .din(wr_data),
        .raddr(rd_addr),
        .dout(qa)
    );

    dp_ram #(
        .DW(N*8),
        .AW(AWB)
    ) mem_b (
        .clk(clk),
        .we(wr_we && dst == 2'd2),
        .waddr(wr_addr),
        .din(wr_data),
        .raddr(rd_addr),
        .dout(qb)
    );

    dp_ram #(
        .DW(N*8),
        .AW(AWB)
    ) mem_c (
        .clk(clk),
        .we(wr_we && dst == 2'd3),
        .waddr(wr_addr),
        .din(wr_data),
        .raddr(rd_addr),
        .dout(qc)
    );

    assign out_rdata =
        (OUT_BUF == 1) ? qa :
        (OUT_BUF == 2) ? qb : qc;

    // --------------------------------
    // Source selection function
    // --------------------------------

    function [N*8-1:0] sel;

        input [1:0] s;

        input [N*8-1:0] i0;
        input [N*8-1:0] a;
        input [N*8-1:0] b;
        input [N*8-1:0] c;

        begin
            case (s)

                2'd0: sel = i0;
                2'd1: sel = a;
                2'd2: sel = b;

                default: sel = c;

            endcase
        end

    endfunction

    wire [N*8-1:0] src_data;
    wire [N*8-1:0] src2_data;

    assign src_data =
        sel(src, in_rdata, qa, qb, qc);

    assign src2_data =
        sel(src2, in_rdata, qa, qb, qc);

    // --------------------------------
    // Engines
    // --------------------------------

    // CONV engine

    wire conv_done, conv_busy, conv_we;

    wire [TW-1:0] conv_raddr;
    wire [TW-1:0] conv_waddr;

    wire [N*8-1:0] conv_wdata;

    wire [WAW-1:0] w_addr;
    wire [N*8-1:0] w_data;

    wire [BAW-1:0] b_addr;
    wire signed [31:0] b_data;

    weight_rom #(
        .DW(N*8),
        .AW(WAW),
        .FILE(WFILE)
    ) wrom (
        .clk(clk),
        .addr(w_addr),
        .dout(w_data)
    );

    weight_rom #(
        .DW(32),
        .AW(BAW),
        .FILE(BFILE)
    ) brom (
        .clk(clk),
        .addr(b_addr),
        .dout(b_data)
    );

    wire [TW:0] conv_n_t;

    assign conv_n_t = n_t;

    conv1d_engine #(
        .N(N),
        .TW(TW),
        .WAW(WAW),
        .BAW(BAW)
    ) conv (
        .clk(clk),
        .rst_n(rst_n),
        .start(conv_start),

        .n_t(conv_n_t),
        .c_out(c_out),
        .ktaps(ktaps),
        .dil(dil),

        .shift(shift),
        .relu(relu),

        .wbase(wbase),
        .bbase(bbase),

        .busy(conv_busy),
        .done(conv_done),

        .act_raddr(conv_raddr),
        .act_rdata(src_data),

        .w_addr(w_addr),
        .w_data(w_data),

        .b_addr(b_addr),
        .b_data(b_data),

        .out_we(conv_we),
        .out_waddr(conv_waddr),
        .out_wdata(conv_wdata)
    );

    // POOL / DOWNSAMPLE engine

    wire dn_done, dn_busy, dn_we;

    wire [TW:0] dn_raddr;
    wire [TW-1:0] dn_waddr;

    wire [N*8-1:0] dn_wdata;

    downsample_unit #(
        .N(N),
        .TW(TW)
    ) dn (
        .clk(clk),
        .rst_n(rst_n),
        .start(pool_start),

        .n_t(n_t),

        .busy(dn_busy),
        .done(dn_done),

        .raddr(dn_raddr),
        .rdata(src_data),

        .out_we(dn_we),
        .out_waddr(dn_waddr),
        .out_wdata(dn_wdata)
    );

    // UPSAMPLE engine

    wire up_done, up_busy, up_we;

    wire [TW-1:0] up_raddr;
    wire [TW:0] up_waddr;

    wire [N*8-1:0] up_wdata;

    upsample_unit #(
        .N(N),
        .TW(TW)
    ) up (
        .clk(clk),
        .rst_n(rst_n),
        .start(up_start),

        .n_t(n_t),

        .busy(up_busy),
        .done(up_done),

        .raddr(up_raddr),
        .rdata(src_data),

        .out_we(up_we),
        .out_waddr(up_waddr),
        .out_wdata(up_wdata)
    );

    // ADD / RESIDUAL engine

    wire add_done, add_busy, add_we;

    wire [TW-1:0] add_raddr;
    wire [TW-1:0] add_waddr;

    wire [N*8-1:0] add_wdata;

    residual_add #(
        .N(N),
        .TW(TW)
    ) add (
        .clk(clk),
        .rst_n(rst_n),
        .start(add_start),

        .n_t(n_t),
        .relu(1'b0),

        .busy(add_busy),
        .done(add_done),

        .raddr(add_raddr),

        .a_rdata(src_data),
        .b_rdata(src2_data),

        .out_we(add_we),
        .out_waddr(add_waddr),
        .out_wdata(add_wdata)
    );

    // --------------------------------
    // Per-operation muxes
    // --------------------------------

    assign op_done =
        (op == OP_CONV) ? conv_done :
        (op == OP_POOL) ? dn_done :
        (op == OP_UP)   ? up_done :
                          add_done;

    assign eng_raddr =
        (op == OP_CONV) ? conv_raddr[AWB-1:0] :
        (op == OP_POOL) ? dn_raddr[AWB-1:0] :
        (op == OP_UP)   ? up_raddr[AWB-1:0] :
                          add_raddr[AWB-1:0];

    assign wr_we =
        (op == OP_CONV) ? conv_we :
        (op == OP_POOL) ? dn_we :
        (op == OP_UP)   ? up_we :
                          add_we;

    assign wr_addr =
        (op == OP_CONV) ? conv_waddr[AWB-1:0] :
        (op == OP_POOL) ? dn_waddr[AWB-1:0] :
        (op == OP_UP)   ? up_waddr[AWB-1:0] :
                          add_waddr[AWB-1:0];

    assign wr_data =
        (op == OP_CONV) ? conv_wdata :
        (op == OP_POOL) ? dn_wdata :
        (op == OP_UP)   ? up_wdata :
                          add_wdata;

endmodule