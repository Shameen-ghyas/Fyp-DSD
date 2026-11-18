
module score_acc (
    input clk,
    input reset,
    input enable,
    input clear,
    input [17:0] error_ch0,
    input [17:0] error_ch1,
    input [17:0] error_ch2,
    input [17:0] error_ch3,
    input [17:0] error_ch4,
    input [17:0] error_ch5,
    input [17:0] error_ch6,

    output reg [31:0] score_ch0,
    output reg [31:0] score_ch1,
    output reg [31:0] score_ch2,
    output reg [31:0] score_ch3,
    output reg [31:0] score_ch4,
    output reg [31:0] score_ch5,
    output reg [31:0] score_ch6,
    output wire [31:0] total_score
);

    assign total_score =
        score_ch0 + score_ch1 + score_ch2 +
        score_ch3 + score_ch4 + score_ch5 + score_ch6;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            score_ch0 <= 0;
            score_ch1 <= 0;
            score_ch2 <= 0;
            score_ch3 <= 0;
            score_ch4 <= 0;
            score_ch5 <= 0;
            score_ch6 <= 0;
        end
        else if (clear) begin
            score_ch0 <= 0;
            score_ch1 <= 0;
            score_ch2 <= 0;
            score_ch3 <= 0;
            score_ch4 <= 0;
            score_ch5 <= 0;
            score_ch6 <= 0;
        end
        else if (enable) begin
            score_ch0 <= score_ch0 + error_ch0;
            score_ch1 <= score_ch1 + error_ch1;
            score_ch2 <= score_ch2 + error_ch2;
            score_ch3 <= score_ch3 + error_ch3;
            score_ch4 <= score_ch4 + error_ch4;
            score_ch5 <= score_ch5 + error_ch5;
            score_ch6 <= score_ch6 + error_ch6;
        end
    end

endmodule
