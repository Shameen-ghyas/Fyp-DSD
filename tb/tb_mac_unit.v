`timescale 1ns/1ps
module tb_mac_unit;
    parameter DATA_W = 8;
    parameter ACC_W  = 32;

    reg clk;
    reg rst_n;
    reg en, clr;

    reg signed [DATA_W-1:0] a, b;
    wire signed [ACC_W-1:0] acc;

    mac_unit #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .clr(clr),
        .a(a),
        .b(b),
        .acc(acc)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Test vector memory 512 x 288 = 147456 bits

    reg [287:0] vec [0:511];

    reg signed [ACC_W-1:0] expv;

    integer i, k;
    integer errors, n;

    initial begin
        rst_n = 0;
        en = 0;
        clr = 0;
        a = 0;
        b = 0;

        errors = 0;
        n = 0;

        for (i = 0; i < 512; i = i + 1)
            vec[i] = {288{1'bx}};

        // Load test vectors
        $readmemh("vectors/mac_vec.mem", vec);

        #12 rst_n = 1;

        for (i = 0; i < 512; i = i + 1) begin
            if ((^vec[i]) !== 1'bx) begin
                for (k = 0; k < 16; k = k + 1) begin

                    @(negedge clk);
                    a = vec[i][287 - 8*k -: 8];
                    b = vec[i][159 - 8*k -: 8];

                    en = 1;
                    clr = (k == 0);

                end

                // Stop accumulation
                @(negedge clk);
                en = 0;
                clr = 0;
                expv = vec[i][31:0];
                if (acc !== expv) begin
                    errors = errors + 1;

                end
                n = n + 1;
            end
        end

        // Test clear operation
        @(negedge clk);
        clr = 1;

        @(negedge clk);
        clr = 0;

        @(negedge clk);

        if (acc !== 0) begin
            errors = errors + 1;
            $display("Clear failed");
        end

        // Test hold operation
        @(negedge clk);
        en = 1;
        clr = 1;
        a = 8'sd2;
        b = 8'sd3;

        @(negedge clk);
        en = 0;
        clr = 0;

        @(negedge clk);

        if (acc !== 32'sd6) begin
            errors = errors + 1;
            $display("MAC operation failed");
        end

        // Final result
        if (errors == 0)
            $display("tb_mac_unit: %0d dot-products, PASS", n);
        else
            $display("tb_mac_unit: %0d dot-products, %0d errors, FAIL",
                     n, errors);

        $finish;

    end

endmodule
