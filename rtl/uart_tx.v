
module uart_tx #(
    parameter CLOCK_FREQ = 100000000,
    parameter BAUD_RATE = 115200
)(
    input clk,
    input rst_n,
    input tx_start,
    input [7:0] tx_data,

    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    localparam CLKS_PER_BIT = CLOCK_FREQ / BAUD_RATE;

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state;
    reg [15:0] baud_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state <= IDLE;
            tx <= 1'b1;
            tx_busy <= 0;
            tx_done <= 0;
            baud_count <= 0;
            bit_index <= 0;
            data_reg <= 0;
        end

        else begin
            tx_done <= 0;

            case (state)

                IDLE: begin
                    tx <= 1;
                    tx_busy <= 0;

                    if (tx_start) begin
                        data_reg <= tx_data;
                        tx_busy <= 1;
                        baud_count <= 0;
                        state <= START;
                    end
                end

                START: begin
                    tx <= 0;

                    if (baud_count == CLKS_PER_BIT-1) begin
                        baud_count <= 0;
                        bit_index <= 0;
                        state <= DATA;
                    end
                    else
                        baud_count <= baud_count + 1;
                end

                DATA: begin
                    tx <= data_reg[bit_index];

                    if (baud_count == CLKS_PER_BIT-1) begin
                        baud_count <= 0;

                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end
                    else
                        baud_count <= baud_count + 1;
                end

                STOP: begin
                    tx <= 1;

                    if (baud_count == CLKS_PER_BIT-1) begin
                        baud_count <= 0;
                        state <= IDLE;
                        tx_done <= 1;
                    end
                    else
                        baud_count <= baud_count + 1;
                end

            endcase
        end
    end

endmodule
