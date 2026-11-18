module downsample_unit
#(
    parameter N = 16,
    parameter TW = 7
)
(
    input clk,
    input rst_n,
    input start,
    input [TW:0] n_t,

    output busy,
    output reg done,

    output [TW:0] raddr,
    input [N*8-1:0] rdata,

    output out_we,
    output [TW-1:0] out_waddr,
    output [N*8-1:0] out_wdata
);

    // State definitions
    parameter S_IDLE = 3'b000;
    parameter S_A0   = 3'b001;
    parameter S_A1   = 3'b010;
    parameter S_D    = 3'b011;

    reg [2:0] state;

    reg [TW-1:0] t;
    reg [N*8-1:0] r0;

    // Address and control signals
    assign raddr = {t, (state == S_A1)};

    assign out_waddr = t;

    assign out_we = (state == S_D);

    assign busy = (state != S_IDLE);

    // Average each pair of input bytes
    genvar i;

    generate
        for (i = 0; i < N; i = i + 1)
        begin : lane

            wire signed [9:0] s;

            assign s =
                $signed(r0[i*8 +: 8]) +
                $signed(rdata[i*8 +: 8]) +
                10'sd1;

            assign out_wdata[i*8 +: 8] = s[8:1];

        end
    endgenerate

    // State machine
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= S_IDLE;
            t <= 0;
            r0 <= 0;
            done <= 1'b0;
        end

        else
        begin
            done <= 1'b0;

            case (state)

                S_IDLE:
                begin
                    if (start)
                    begin
                        t <= 0;
                        state <= S_A0;
                    end
                end

                S_A0:
                begin
                    state <= S_A1;
                end

                S_A1:
                begin
                    r0 <= rdata;
                    state <= S_D;
                end

                S_D:
                begin
                    if (t == n_t - 1)
                    begin
                        done <= 1'b1;
                        state <= S_IDLE;
                    end

                    else
                    begin
                        t <= t + 1'b1;
                        state <= S_A0;
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