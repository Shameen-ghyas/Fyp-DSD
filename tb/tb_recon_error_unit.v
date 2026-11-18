`timescale 1ns/1ps

// Tests recon_error_unit: squared_error must equal (original - reconstructed)^2.
// Directed corner cases first, then ALL 65536 input combinations.

module tb_recon_error_unit;

    reg  [7:0]  original_data;
    reg  [7:0]  reconstructed_data;
    wire [17:0] squared_error;

    recon_error_unit dut (
        .original_data      (original_data),
        .reconstructed_data (reconstructed_data),
        .squared_error      (squared_error)
    );

    integer errors = 0;
    integer a, b;
    integer diff;
    reg [17:0] expected;

    task check;
        input [7:0] o;
        input [7:0] r;
        begin
            original_data      = o;
            reconstructed_data = r;
            #1;

            diff     = o - r;          // can be negative
            expected = diff * diff;    // square is always positive

            if (squared_error !== expected) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("BAD: orig=%0d recon=%0d -> got %0d expected %0d",
                             o, r, squared_error, expected);
            end
        end
    endtask

    initial begin
        // Directed corner cases
        check(8'd0,   8'd0);      // 0
        check(8'd255, 8'd255);    // 0
        check(8'd255, 8'd0);      // 65025 (largest)
        check(8'd0,   8'd255);    // 65025 (negative diff)
        check(8'd10,  8'd3);      // 49
        check(8'd3,   8'd10);     // 49 (negative diff)
        check(8'd128, 8'd127);    // 1
        check(8'd127, 8'd128);    // 1

        // Exhaustive sweep
        for (a = 0; a < 256; a = a + 1)
            for (b = 0; b < 256; b = b + 1)
                check(a, b);

        if (errors == 0)
            $display("tb_recon_error_unit: %0d errors -> PASS", errors);
        else
            $display("tb_recon_error_unit: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule
