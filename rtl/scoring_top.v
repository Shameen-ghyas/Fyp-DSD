module scoring_top #(
    parameter W  = 64,
    parameter AW = 6
)(
    input              clk,
    input              rst_n,
    input              start,          // 1 clk pulse, TCN done hone ke baad

    output [AW-1:0]    rd_addr,        // window_buffer.raddr aur encdec.ext_raddr dono ko
    input  [127:0]     orig_row,       // window_buffer.rdata (scaled input)
    input  [127:0]     recon_row,      // encdec_top_tcn.out_rdata

    output reg         busy,
    output reg         done,           // 1 clk pulse, scores final
    output [7*32-1:0]  score_ch,       // ch c = [32*c +: 32]
    output [31:0]      total_score
);

    localparam S_IDLE = 3'd0, S_CLR = 3'd1, S_RUN = 3'd2, S_FLUSH = 3'd3, S_DONE = 3'd4;

    reg [2:0]    state;
    reg [AW-1:0] addr;
    reg          v;                    // rdata valid (ram read 1 clk latency)

    assign rd_addr = addr;

    // lanes 0-6: 7 x squared error
    wire [7*18-1:0] err;
    genvar c;
    generate
        for (c = 0; c < 7; c = c + 1) begin : g_err
            recon_error_unit u_err (
                .original_data     (orig_row [8*c +: 8]),
                .reconstructed_data(recon_row[8*c +: 8]),
                .squared_error     (err[18*c +: 18])
            );
        end
    endgenerate

    score_acc u_acc (
        .clk(clk), .rst_n(rst_n),
        .en(v), .clear(state == S_CLR),
        .error_ch0(err[ 0*18 +: 18]), .error_ch1(err[ 1*18 +: 18]),
        .error_ch2(err[ 2*18 +: 18]), .error_ch3(err[ 3*18 +: 18]),
        .error_ch4(err[ 4*18 +: 18]), .error_ch5(err[ 5*18 +: 18]),
        .error_ch6(err[ 6*18 +: 18]),
        .score_ch0(score_ch[ 0*32 +: 32]), .score_ch1(score_ch[ 1*32 +: 32]),
        .score_ch2(score_ch[ 2*32 +: 32]), .score_ch3(score_ch[ 3*32 +: 32]),
        .score_ch4(score_ch[ 4*32 +: 32]), .score_ch5(score_ch[ 5*32 +: 32]),
        .score_ch6(score_ch[ 6*32 +: 32]),
        .total_score(total_score)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            addr  <= 0;
            v     <= 1'b0;
            busy  <= 1'b0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;
            v    <= 1'b0;
            case (state)
                S_IDLE: begin
                    if (start) begin
                        busy  <= 1'b1;
                        state <= S_CLR;
                    end
                end
                S_CLR: begin
                    addr  <= 0;
                    state <= S_RUN;
                end
                S_RUN: begin
                    v <= 1'b1;
                    if (addr == W-1)
                        state <= S_FLUSH;
                    else
                        addr <= addr + 1'b1;
                end
                S_FLUSH: begin
                    // last row ka error yahin accumulate hota hai (v = 1)
                    done  <= 1'b1;
                    busy  <= 1'b0;
                    state <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule