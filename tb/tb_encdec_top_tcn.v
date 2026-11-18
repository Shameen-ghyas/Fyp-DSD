`timescale 1ns/1ps

module tb_encdec_top_tcn;

    parameter N = 16;
    parameter AWB = 6;
    parameter T = 64;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    always #5 clk = ~clk;

    wire busy;
    wire done;

    wire [31:0] cycles;

    wire [AWB-1:0] in_raddr;
    reg [AWB-1:0] ext_raddr = 0;

    wire [127:0] in_rdata;
    wire [127:0] out_rdata;

    // --------------------------------
    // External input memory
    // --------------------------------

    reg we = 0;
    reg [AWB-1:0] waddr = 0;
    reg [127:0] din = 0;

    dp_ram #(
        .DW(128),
        .AW(AWB)
    ) in_ram (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .din(din),
        .raddr(in_raddr),
        .dout(in_rdata)
    );

    // --------------------------------
    // DUT
    // --------------------------------

    encdec_top_tcn #(
        .N(N),
        .AWB(AWB)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .cycles(cycles),
        .in_raddr(in_raddr),
        .in_rdata(in_rdata),
        .ext_raddr(ext_raddr),
        .out_rdata(out_rdata)
    );

    // --------------------------------
    // Test vectors
    // --------------------------------

    reg [127:0] xin [0:T-1];
    reg [127:0] expv [0:T-1];

    integer i;
    integer errors = 0;
    integer guard = 0;

    // --------------------------------
    // Main test
    // --------------------------------

    initial begin

        // Load input and expected output
        $readmemh("vectors/tcn_in.mem", xin);
        $readmemh("vectors/tcn_exp.mem", expv);

        #22 rst_n = 1;

        // Write input data into external RAM
        for (i = 0; i < T; i = i + 1) begin
            @(negedge clk);

            we = 1;
            waddr = i;
            din = xin[i];
        end

        @(negedge clk);
        we = 0;

        // Start TCN execution
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Wait for completion
        while (!done && guard < 400000) begin
            @(negedge clk);
            guard = guard + 1;
        end

        if (!done) begin
            errors = errors + 1;
            $display("timeout");
        end

        // Read and compare output rows
        for (i = 0; i < T; i = i + 1) begin

            ext_raddr = i;

            @(negedge clk);
            @(negedge clk);

            if (out_rdata !== expv[i]) begin
                errors = errors + 1;

                if (errors < 6)
                    $display(
                        "row %0d got %h exp %h",
                        i, out_rdata, expv[i]
                    );
            end
        end

        // Final results
        $display(
            "full TCN forward pass: %0d cycles (%0d us at 100 MHz)",
            cycles, cycles / 100
        );

        if (errors == 0)
            $display("tb_encdec_top_tcn: %0d mismatches -> PASS", errors);
        else
            $display("tb_encdec_top_tcn: %0d mismatches -> FAIL", errors);

        $finish;

    end

endmodule