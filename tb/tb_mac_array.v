
`timescale 1ns/1ps

module tb_mac_array;

    parameter N = 16;
    parameter DATA_W = 8;
    parameter ACC_W = 32;

    reg clk = 0;
    reg rst_n = 0;
    reg en = 0;
    reg clr = 0;

    reg [N*DATA_W-1:0] a, b;
    wire [N*ACC_W-1:0] acc;

    // Instantiate MAC array
    mac_array #(.N(N)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clr(clr),
        .a(a),
        .b(b),
        .acc(acc)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Expected results
    reg signed [ACC_W-1:0] ref_acc [0:N-1];

    integer i, t, trial, errors;

    initial begin

        errors = 0;

        // Release reset
        #12 rst_n = 1;

        // Run 200 tests
        for (trial = 0; trial < 200; trial = trial + 1)
        begin

            // Each test has 12 MAC operations
            for (t = 0; t < 12; t = t + 1)
            begin

                @(negedge clk);

                // Give inputs to all 16 MAC units
                for (i = 0; i < N; i = i + 1)
                begin

                    a[i*8 +: 8] = $random;
                    b[i*8 +: 8] = $random;

                    // Calculate expected answer
                    if (t == 0)
                        ref_acc[i] = $signed(a[i*8 +: 8]) *
                                     $signed(b[i*8 +: 8]);

                    else
                        ref_acc[i] = ref_acc[i] +
                                     $signed(a[i*8 +: 8]) *
                                     $signed(b[i*8 +: 8]);

                end

                // Enable MAC operation
                en = 1;

                // Start a new accumulation
                if (t == 0)
                    clr = 1;
                else
                    clr = 0;

            end

            // Stop MAC operation
            @(negedge clk);
            en = 0;
            clr = 0;

            // Compare actual and expected answers
            for (i = 0; i < N; i = i + 1)
            begin

                if ($signed(acc[i*32 +: 32]) !== ref_acc[i])
                begin
                    errors = errors + 1;

                    if (errors < 10)
                        $display("Lane %0d: Actual = %0d, Expected = %0d",
                            i,
                            $signed(acc[i*32 +: 32]),
                            ref_acc[i]);
                end

            end

        end

        // Final result
        if (errors == 0)
            $display("PASS: All tests successful!");
        else
            $display("FAIL: Total errors = %0d", errors);

        $finish;

    end

endmodule
