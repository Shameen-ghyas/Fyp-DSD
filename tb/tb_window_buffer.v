`timescale 1ns/1ps

module tb_window_buffer;

    parameter W = 16;

    reg clk = 0;
    reg rst_n = 0;
    reg row_valid = 0;
    reg clear = 0;

    wire full;

    reg [127:0] row;
    wire [127:0] rdata;
    reg [3:0] raddr;

    window_buffer #(
        .W(W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .row_valid(row_valid),
        .row(row),
        .clear(clear),
        .full(full),
        .raddr(raddr),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    reg [127:0] exp [0:W-1];

    integer i;
    integer errors = 0;

    integer pass;
    integer k;
    integer base;

    // Task to fill the buffer
    task fill;
        input integer base;
        begin
            for (k = 0; k < W + 3; k = k + 1)
            begin
                @(negedge clk);

                row = {4{(base + k * 77 + 5)}};
                row_valid = 1;

                // Store expected values for the first W rows
                if (k < W)
                    exp[k] = row;
            end

            @(negedge clk);
            row_valid = 0;
        end
    endtask

    initial
    begin
        #22 rst_n = 1;

        for (pass = 0; pass < 2; pass = pass + 1)
        begin
            if (full)
            begin
                errors = errors + 1;
                $display("full too early");
            end

            fill(pass * 1000);

            if (!full)
            begin
                errors = errors + 1;
                $display("full not set");
            end

            // Read and verify all stored rows
            for (i = 0; i < W; i = i + 1)
            begin
                @(negedge clk);
                raddr = i;

                @(negedge clk);

                if (rdata !== exp[i])
                begin
                    errors = errors + 1;
                    $display("pass %0d row %0d bad", pass, i);
                end
            end

            // Clear buffer for next pass
            @(negedge clk);
            clear = 1;

            @(negedge clk);
            clear = 0;
        end

        if (errors == 0)
            $display("tb_window_buffer: %0d errors -> PASS", errors);
        else
            $display("tb_window_buffer: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule