`timescale 1ns/1ps

// Tests score_acc:
//   1. all scores 0 after reset
//   2. enable=1 accumulates each channel
//   3. enable=0 holds the values
//   4. clear (sync) zeros everything
//   5. clear wins over enable
//   6. 32-bit width (many large additions)
//   7. async reset, and reset wins over enable
//   8. 300 random cycles against a reference model
// total_score is checked every time (= sum of the 7 scores).

module tb_score_acc;

    reg clk    = 0;
    reg reset  = 1;
    reg enable = 0;
    reg clear  = 0;

    reg [17:0] error_ch0 = 0, error_ch1 = 0, error_ch2 = 0, error_ch3 = 0,
               error_ch4 = 0, error_ch5 = 0, error_ch6 = 0;

    wire [31:0] score_ch0, score_ch1, score_ch2, score_ch3,
                score_ch4, score_ch5, score_ch6;
    wire [31:0] total_score;

    score_acc dut (
        .clk(clk), .reset(reset), .enable(enable), .clear(clear),
        .error_ch0(error_ch0), .error_ch1(error_ch1), .error_ch2(error_ch2),
        .error_ch3(error_ch3), .error_ch4(error_ch4), .error_ch5(error_ch5),
        .error_ch6(error_ch6),
        .score_ch0(score_ch0), .score_ch1(score_ch1), .score_ch2(score_ch2),
        .score_ch3(score_ch3), .score_ch4(score_ch4), .score_ch5(score_ch5),
        .score_ch6(score_ch6),
        .total_score(total_score)
    );

    always #5 clk = ~clk;

    // reference model
    reg [17:0] ev    [0:6];   // error values currently driven
    reg [31:0] exp_s [0:6];   // expected scores
    reg [31:0] got   [0:6];
    reg [31:0] exp_total;

    integer errors = 0;
    integer n, j, k;

    // drive the 7 error inputs (and remember them for the model)
    task load_err;
        input [17:0] a, b, c, d, e, f, g;
        begin
            ev[0] = a; ev[1] = b; ev[2] = c; ev[3] = d;
            ev[4] = e; ev[5] = f; ev[6] = g;
            error_ch0 = a; error_ch1 = b; error_ch2 = c; error_ch3 = d;
            error_ch4 = e; error_ch5 = f; error_ch6 = g;
        end
    endtask

    // one clock cycle with given enable / clear, then update the model
    task cycle;
        input en;
        input clr;
        begin
            @(negedge clk);
            enable = en;
            clear  = clr;
            @(posedge clk);
            #1;
            if (clr)
                for (j = 0; j < 7; j = j + 1) exp_s[j] = 0;
            else if (en)
                for (j = 0; j < 7; j = j + 1) exp_s[j] = exp_s[j] + ev[j];
        end
    endtask

    // compare DUT with the model
    task check_scores;
        input [8*28:1] msg;
        begin
            got[0] = score_ch0; got[1] = score_ch1; got[2] = score_ch2;
            got[3] = score_ch3; got[4] = score_ch4; got[5] = score_ch5;
            got[6] = score_ch6;

            exp_total = 0;
            for (k = 0; k < 7; k = k + 1) begin
                exp_total = exp_total + exp_s[k];
                if (got[k] !== exp_s[k]) begin
                    errors = errors + 1;
                    $display("[%0t] %0s: ch%0d got %0d expected %0d",
                             $time, msg, k, got[k], exp_s[k]);
                end
            end

            if (total_score !== exp_total) begin
                errors = errors + 1;
                $display("[%0t] %0s: total got %0d expected %0d",
                         $time, msg, total_score, exp_total);
            end
        end
    endtask

    initial begin
        for (n = 0; n < 7; n = n + 1) exp_s[n] = 0;
        load_err(0, 0, 0, 0, 0, 0, 0);

        // 1. reset
        #22 reset = 0;
        check_scores("1: after reset");

        // 2. accumulate
        load_err(1, 2, 3, 4, 5, 6, 7);
        cycle(1, 0);  check_scores("2: acc #1");
        cycle(1, 0);  check_scores("2: acc #2");
        load_err(100, 200, 300, 400, 500, 600, 700);
        cycle(1, 0);  check_scores("2: acc #3");

        // 3. enable = 0 must hold
        load_err(18'h3FFFF, 18'h3FFFF, 18'h3FFFF, 18'h3FFFF,
                 18'h3FFFF, 18'h3FFFF, 18'h3FFFF);
        cycle(0, 0);  check_scores("3: hold");
        cycle(0, 0);  check_scores("3: hold again");

        // 4. clear zeros everything
        cycle(0, 1);  check_scores("4: clear");

        // 5. clear has priority over enable
        load_err(9, 8, 7, 6, 5, 4, 3);
        cycle(1, 0);  check_scores("5: acc before clear");
        cycle(1, 1);  check_scores("5: clear beats enable");

        // 6. 32-bit width: 100 additions of the max error value
        load_err(18'h3FFFF, 18'h3FFFF, 18'h3FFFF, 18'h3FFFF,
                 18'h3FFFF, 18'h3FFFF, 18'h3FFFF);
        for (n = 0; n < 100; n = n + 1) cycle(1, 0);
        check_scores("6: wide accumulation");

        // 7. async reset (no clock edge needed) and reset beats enable
        load_err(5, 5, 5, 5, 5, 5, 5);
        cycle(1, 0);  check_scores("7: nonzero before reset");
        #1 reset = 1;                       // enable is still 1
        #1;
        for (n = 0; n < 7; n = n + 1) exp_s[n] = 0;
        check_scores("7: async reset");
        @(posedge clk); #1;
        check_scores("7: reset beats enable");
        @(negedge clk);
        reset  = 0;
        enable = 0;

        // 8. random cycles
        for (n = 0; n < 300; n = n + 1) begin
            load_err($random & 32'h3FFFF, $random & 32'h3FFFF,
                     $random & 32'h3FFFF, $random & 32'h3FFFF,
                     $random & 32'h3FFFF, $random & 32'h3FFFF,
                     $random & 32'h3FFFF);
            cycle((($random & 3) != 0), (($random & 15) == 0));
            check_scores("8: random");
        end

        if (errors == 0)
            $display("tb_score_acc: %0d errors -> PASS", errors);
        else
            $display("tb_score_acc: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule
