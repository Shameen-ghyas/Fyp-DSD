
module uart_report_fsm (
    input clk,
    input rst_n,
    input start,

    input [31:0] score,
    input [2:0] flagged_channel,
    input [15:0] intensity,
    input [31:0] latency,

    output reg tx_start,
    output reg [7:0] tx_data,
    input tx_busy,
    input tx_done,

    output reg report_done
);

    localparam IDLE = 2'b00,
               SEND = 2'b01,
               WAIT = 2'b10,
               FINISH = 2'b11;

    reg [1:0] state;
    reg [3:0] byte_index;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state <= IDLE;
            byte_index <= 0;
            tx_start <= 0;
            tx_data <= 0;
            report_done <= 0;
        end

        else begin
            tx_start <= 0;
            report_done <= 0;

            case (state)

                IDLE: begin
                    if (start) begin
                        byte_index <= 0;
                        state <= SEND;
                    end
                end

                SEND: begin
                    if (!tx_busy) begin

                    case (byte_index)
                            0:  tx_data <= 8'hA5;
                            1:  tx_data <= score[31:24];
                            2:  tx_data <= score[23:16];
                            3:  tx_data <= score[15:8];
                            4:  tx_data <= score[7:0];
                            5:  tx_data <= {5'b0, flagged_channel};
                            6:  tx_data <= intensity[15:8];
                            7:  tx_data <= intensity[7:0];
                            8:  tx_data <= latency[31:24];
                            9:  tx_data <= latency[23:16];
                            10: tx_data <= latency[15:8];
                            11: tx_data <= latency[7:0];
                        endcase

                        tx_start <= 1;
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    if (tx_done) begin
                        if (byte_index == 11)
                            state <= FINISH;
                        else begin
                            byte_index <= byte_index + 1;
                            state <= SEND;
                        end
                    end
                end

                FINISH: begin
                    report_done <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
