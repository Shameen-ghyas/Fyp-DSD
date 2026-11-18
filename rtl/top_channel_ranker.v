
module top_channel_ranker (
    input [31:0] score_ch0,
    input [31:0] score_ch1,
    input [31:0] score_ch2,
    input [31:0] score_ch3,
    input [31:0] score_ch4,
    input [31:0] score_ch5,
    input [31:0] score_ch6,

    output reg [2:0] top_channel,
    output reg [31:0] top_score
);

    always @(*) begin
        top_channel = 0;
        top_score = score_ch0;

        if (score_ch1 > top_score) begin
            top_score = score_ch1;
            top_channel = 1;
        end

        if (score_ch2 > top_score) begin
            top_score = score_ch2;
            top_channel = 2;
        end

        if (score_ch3 > top_score) begin
            top_score = score_ch3;
            top_channel = 3;
        end

        if (score_ch4 > top_score) begin
            top_score = score_ch4;
            top_channel = 4;
        end

        if (score_ch5 > top_score) begin
            top_score = score_ch5;
            top_channel = 5;
        end

        if (score_ch6 > top_score) begin
            top_score = score_ch6;
            top_channel = 6;
        end
    end

endmodule
