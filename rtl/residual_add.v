module residual_add
#(
    parameter N = 16,
    parameter TW = 7
)
(
    input clk,
    input rst_n,
    input start,
    input [TW:0] n_t,
    input relu,

    output busy,
    output reg done,

    output [TW-1:0] raddr,
    input [N*8-1:0] a_rdata,
    input [N*8-1:0] b_rdata,

    output out_we,
    output [TW-1:0] out_waddr,
    output [N*8-1:0] out_wdata
);

    // State definitions
    parameter S_IDLE = 2'b00;
    parameter S_ADDR = 2'b01;
    parameter S_DATA = 2'b10;

    reg [1:0] state;

    reg [TW-1:0] t;

    assign raddr = t;
    assign out_waddr = t;

    assign out_we = (state == S_DATA);
    assign busy = (state != S_IDLE);

    // Process each byte independently
    genvar i;

    generate
        for (i = 0; i < N; i = i + 1)
        begin : lane

            wire signed [8:0] s;
            wire signed [7:0] q;

            assign s =
                $signed(a_rdata[i*8 +: 8]) +
                $signed(b_rdata[i*8 +: 8]);

            // Sign extend the 9-bit sum to 32 bits
            assign q = sat8({{23{s[8]}}, s});

            assign out_wdata[i*8 +: 8] =
                (relu && q < 0) ? 8'sd0 : q;

        end
    endgenerate

    // State machine
    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= S_IDLE;
            t <= 0;
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
                        state <= S_ADDR;
                    end
                end

                S_ADDR:
                begin
                    state <= S_DATA;
                end

                S_DATA:
                begin
                    if (t == n_t - 1)
                    begin
                        done <= 1'b1;
                        state <= S_IDLE;
                    end

                    else
                    begin
                        t <= t + 1'b1;
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

    // Saturate a signed 32-bit value to signed 8-bit range
    function signed [7:0] sat8;
        input signed [31:0] x;

        begin
            if (x > 127)
                sat8 = 127;
            else if (x < -128)
                sat8 = -128;
            else
                sat8 = x[7:0];
        end
    endfunction

endmodule