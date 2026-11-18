module upsample_unit
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

    output [TW-1:0] raddr,
    input [N*8-1:0] rdata,

    output out_we,
    output [TW:0] out_waddr,
    output [N*8-1:0] out_wdata
);

    // State definitions
    parameter S_IDLE = 3'b000;
    parameter S_ADDR = 3'b001;
    parameter S_W0   = 3'b010;
    parameter S_W1   = 3'b011;

    reg [2:0] state;

    reg [TW-1:0] t;

    // Address and output assignments
    assign raddr = t;

    assign out_wdata = rdata;

    assign out_we = (state == S_W0) || (state == S_W1);

    // Output addresses: 2t and 2t+1
    assign out_waddr = {t, (state == S_W1)};

    assign busy = (state != S_IDLE);

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
                    state <= S_W0;
                end

                S_W0:
                begin
                    state <= S_W1;
                end

                S_W1:
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

endmodule