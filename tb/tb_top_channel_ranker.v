`timescale 1ns/1ps

// Tests top_channel_ranker: finds the largest of 7 scores.
// The DUT uses ">" so on a tie the LOWEST channel number wins.
// The reference model in this testbench follows the same rule.

module tb_top_channel_ranker;

    reg  [31:0] score_ch0, score_ch1, score_ch2, score_ch3,
                score_ch4, score_ch5, score_ch6;
    wire [2:0]  top_channel;
    wire [31:0] top_score;

    top_channel_ranker dut (
        .score_ch0(score_ch0), .score_ch1(score_ch1), .score_ch2(score_ch2),
        .score_ch3(score_ch3), .score_ch4(score_ch4), .score_ch5(score_ch5),
        .score_ch6(score_ch6),
        .top_channel(top_channel),
        .top_score(top_score)
    );

    reg [31:0] s [0:6];       // the 7 scores to apply
    reg [2:0]  exp_ch;
    reg [31:0] exp_sc;

    integer errors = 0;
    integer n, k;

    // apply s[0..6], compute the expected winner, compare
    task drive;
        input [8*24:1] msg;
        begin
            score_ch0 = s[0]; score_ch1 = s[1]; score_ch2 = s[2];
            score_ch3 = s[3]; score_ch4 = s[4]; score_ch5 = s[5];
            score_ch6 = s[6];
            #1;

            exp_ch = 0;
            exp_sc = s[0];
            for (k = 1; k < 7; k = k + 1)
                if (s[k] > exp_sc) begin
                    exp_sc = s[k];
                    exp_ch = k;
                end

            if (top_channel !== exp_ch || top_score !== exp_sc) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("BAD %0s: got ch%0d score %0d, expected ch%0d score %0d",
                             msg, top_channel, top_score, exp_ch, exp_sc);
            end
        end
    endtask

    task fill;
        input [31:0] v;
        begin
            for (k = 0; k < 7; k = k + 1) s[k] = v;
        end
    endtask

    initial begin
        // all zero -> channel 0
        fill(0);
        drive("all zero");

        // each channel as the single maximum
        for (n = 0; n < 7; n = n + 1) begin
            fill(5);
            s[n] = 50;
            drive("single max");
        end

        // ties -> lowest channel
        fill(7);
        drive("all equal");

        fill(1);
        s[2] = 100; s[5] = 100;
        drive("tie ch2 / ch5");

        fill(1);
        s[0] = 100; s[6] = 100;
        drive("tie ch0 / ch6");

        // ascending and descending
        for (n = 0; n < 7; n = n + 1) s[n] = n + 1;
        drive("ascending");
        for (n = 0; n < 7; n = n + 1) s[n] = 7 - n;
        drive("descending");

        // largest possible values
        fill(32'hFFFFFFFE);
        s[6] = 32'hFFFFFFFF;
        drive("max on ch6");

        fill(32'hFFFFFFFE);
        s[3] = 32'hFFFFFFFF;
        s[6] = 32'hFFFFFFFF;
        drive("max tie ch3 / ch6");

        // unsigned compare check: 0x80000000 > 0x7FFFFFFF
        fill(32'h7FFFFFFF);
        s[4] = 32'h80000000;
        drive("unsigned compare");

        // random values
        for (n = 0; n < 1000; n = n + 1) begin
            for (k = 0; k < 7; k = k + 1) s[k] = $random;
            drive("random");
        end

        // random small values (lots of ties)
        for (n = 0; n < 1000; n = n + 1) begin
            for (k = 0; k < 7; k = k + 1) s[k] = {$random} % 4;
            drive("random ties");
        end

        if (errors == 0)
            $display("tb_top_channel_ranker: %0d errors -> PASS", errors);
        else
            $display("tb_top_channel_ranker: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule
