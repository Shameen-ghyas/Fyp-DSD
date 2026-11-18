module conv1d_engine
#(
    parameter N = 16,
    parameter TW = 7,
    parameter WAW = 7,
    parameter BAW = 6,
    parameter SH_W = 5
)
(
    input clk,
    input rst_n,
    input start,
    input [TW:0] n_t,
    input [4:0] c_out,
    input [3:0] ktaps,
    input [4:0] dil,
    input [SH_W-1:0] shift,
    input relu,
    input [WAW-1:0] wbase,
    input [BAW-1:0] bbase,

    output busy,
    output reg done,

    output [TW-1:0] act_raddr,
    input [N*8-1:0] act_rdata,

    output [WAW-1:0] w_addr,
    input [N*8-1:0] w_data,

    output [BAW-1:0] b_addr,
    input signed [31:0] b_data,

    output out_we,
    output [TW-1:0] out_waddr,
    output [N*8-1:0] out_wdata
);

    // State definitions
    parameter S_IDLE  = 3'b000;
    parameter S_ADDR  = 3'b001;
    parameter S_MAC   = 3'b010;
    parameter S_SUM   = 3'b011;
    parameter S_WRITE = 3'b100;

    reg [2:0] state;

    reg [TW-1:0] t;
    reg [4:0] co;
    reg [3:0] k;
    reg [7:0] off;

    reg [N*8-1:0] orow;

    // Address calculations
    wire [8:0] cok;

    assign cok = co * ktaps;

    assign w_addr = wbase + cok + k;
    assign b_addr = bbase + co;

    // Check whether the tap reaches before time zero
    wire neg;

    assign neg = (t < off);

    assign act_raddr = t - off[TW-1:0];

    // MAC array
    wire [N*32-1:0] acc;

    wire mac_en;
    wire mac_clr;

    assign mac_en = (state == S_MAC);
    assign mac_clr = (state == S_MAC) && (k == 4'd0);

    mac_array #(
        .N(N)
    ) macs (
        .clk(clk),
        .rst_n(rst_n),
        .en(mac_en),
        .clr(mac_clr),
        .a(neg ? {N*8{1'b0}} : act_rdata),
        .b(w_data),
        .acc(acc)
    );

    // Add all MAC lane accumulators
    function signed [31:0] sum_lanes;
        input [N*32-1:0] v;

        integer i;
        reg signed [31:0] s;

        begin
            s = 32'sd0;

            for (i = 0; i < N; i = i + 1)
                s = s + $signed(v[i*32 +: 32]);

            sum_lanes = s;
        end
    endfunction

    wire signed [31:0] lane_sum;
    wire signed [7:0] yq;

    assign lane_sum = sum_lanes(acc);

    requantize #(
        .ACC_W(32),
        .DATA_W(8),
        .SH_W(SH_W)
    ) rq (
        .acc(lane_sum),
        .bias(b_data),
        .shift(shift),
        .relu_en(relu),
        .y(yq)
    );

    // Output signals
    assign out_we = (state == S_WRITE);
    assign out_waddr = t;
    assign out_wdata = orow;

    assign busy = (state != S_IDLE);

    // Main state machine
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= S_IDLE;
            t <= 0;
            co <= 0;
            k <= 0;
            off <= 0;
            orow <= 0;
            done <= 0;
        end

        else
        begin
            done <= 0;

            case (state)

                S_IDLE:
                begin
                    if (start)
                    begin
                        t <= 0;
                        co <= 0;
                        k <= 0;
                        off <= 0;
                        orow <= 0;
                        state <= S_ADDR;
                    end
                end

                S_ADDR:
                begin
                    state <= S_MAC;
                end

                S_MAC:
                begin
                    if (k == ktaps - 1)
                    begin
                        state <= S_SUM;
                    end

                    else
                    begin
                        k <= k + 1'b1;
                        off <= off + dil;
                        state <= S_ADDR;
                    end
                end

                S_SUM:
                begin
                    orow[co*8 +: 8] <= yq;

                    if (co == c_out - 1)
                    begin
                        state <= S_WRITE;
                    end

                    else
                    begin
                        co <= co + 1'b1;
                        k <= 0;
                        off <= 0;
                        state <= S_ADDR;
                    end
                end

                S_WRITE:
                begin
                    if (t == n_t - 1)
                    begin
                        done <= 1'b1;
                        state <= S_IDLE;
                    end

                    else
                    begin
                        t <= t + 1'b1;
                        co <= 0;
                        k <= 0;
                        off <= 0;
                        orow <= 0;
                        state <= S_ADDR;
                    end
                end

                default:
                begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

endmodule