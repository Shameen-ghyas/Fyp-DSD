`timescale 1ns/1ps

// Tests threshold_static: anomaly_flag = (total_score > threshold), UNSIGNED.
// Equal values must NOT raise the flag.

module tb_threshold_static;

    reg  [31:0] total_score;
    reg  [31:0] threshold;
    wire        anomaly_flag;

    threshold_static dut (
        .total_score  (total_score),
        .threshold    (threshold),
        .anomaly_flag (anomaly_flag)
    );

    integer errors = 0;
    integer n, delta;
    reg [31:0] ts;

    task check;
        input [31:0] t;
        input [31:0] th;
        reg expected;
        begin
            total_score = t;
            threshold   = th;
            #1;
            expected = (t > th);

            if (anomaly_flag !== expected) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("BAD: score=%0d threshold=%0d -> flag=%b expected %b",
                             t, th, anomaly_flag, expected);
            end
        end
    endtask

    initial begin
        // equal / just above / just below
        check(0, 0);
        check(1, 0);
        check(0, 1);
        check(100, 100);
        check(101, 100);
        check(99, 100);

        // extremes
        check(32'hFFFFFFFF, 32'hFFFFFFFF);
        check(32'hFFFFFFFF, 32'hFFFFFFFE);
        check(32'hFFFFFFFE, 32'hFFFFFFFF);

        // must be unsigned: 0x80000000 is bigger than 0x7FFFFFFF
        check(32'h80000000, 32'h7FFFFFFF);
        check(32'h7FFFFFFF, 32'h80000000);

        // random values
        for (n = 0; n < 1000; n = n + 1)
            check($random, $random);

        // random values very close to the threshold (-2 .. +2)
        for (n = 0; n < 1000; n = n + 1) begin
            ts    = $random;
            delta = {$random} % 5;
            check(ts, ts + delta - 2);
        end

        if (errors == 0)
            $display("tb_threshold_static: %0d errors -> PASS", errors);
        else
            $display("tb_threshold_static: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule
