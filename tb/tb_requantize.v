`timescale 1ns/1ps
module tb_requantize;
    parameter DATA_W = 8;
    parameter ACC_W  = 32;
    parameter SH_W   = 5;

    reg signed [ACC_W-1:0] acc, bias;
    reg        [SH_W-1:0] shift;
    reg                   relu_en;
    wire signed [DATA_W-1:0] y;

    requantize #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .SH_W(SH_W)
    ) dut (
        .acc(acc),
        .bias(bias),
        .shift(shift),
        .relu_en(relu_en),
        .y(y)
    );

    reg [87:0] vec [0:8191];
    reg signed [7:0] expv;
    integer i, errors, n;

    initial begin
        for (i = 0; i < 8192; i = i + 1)
            vec[i] = {88{1'bx}};

        $readmemh("vectors/requant_vec.mem", vec);

        errors = 0;
        n = 0;

        for (i = 0; i < 8192; i = i + 1) begin

            if ((^vec[i]) !== 1'bx) begin
                acc     = vec[i][87:56];
                bias    = vec[i][55:24];
                shift   = vec[i][20:16];
                relu_en = vec[i][8];

                expv = vec[i][7:0];

                #1;

                if (y !== expv) begin
                    errors = errors + 1;
                end

                n = n + 1;
            end
        end

        $display("tb_requantize: %0d vectors, %0d mismatches -> %s",
                 n, errors, errors == 0 ? "PASS" : "FAIL");

        $finish;

    end

endmodule