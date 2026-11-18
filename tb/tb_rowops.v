`timescale 1ns/1ps

module tb_rowops;

    parameter N = 16;
    parameter TW = 7;
    parameter T = 64;

    reg clk = 0;
    reg rst_n = 0;

    always #5 clk = ~clk;

    // Shared TB write port for input RAMs
    reg we = 0;
    reg [TW-1:0] waddr = 0;
    reg [127:0] din_a = 0;
    reg [127:0] din_b = 0;

    // Expected and input data
    reg [127:0] exp_res [0:T-1];
    reg [127:0] exp_resr [0:T-1];
    reg [127:0] exp_up [0:T-1];
    reg [127:0] exp_down [0:T/2-1];
    reg [127:0] va [0:T-1];
    reg [127:0] vb [0:T-1];

    // --------------------------------
    // residual_add
    // --------------------------------

    reg r_start = 0;
    reg r_relu = 0;

    wire r_busy, r_done, r_we;

    wire [TW-1:0] r_raddr, r_waddr;

    wire [127:0] ra, rb, r_wdata;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_a (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .din(din_a),
        .raddr(r_raddr),
        .dout(ra)
    );

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_b (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .din(din_b),
        .raddr(r_raddr),
        .dout(rb)
    );

    reg [TW-1:0] chk = 0;
    wire [127:0] r_chk;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_ro (
        .clk(clk),
        .we(r_we),
        .waddr(r_waddr),
        .din(r_wdata),
        .raddr(chk),
        .dout(r_chk)
    );

    residual_add #(
        .N(N),
        .TW(TW)
    ) res (
        .clk(clk),
        .rst_n(rst_n),
        .start(r_start),
        .n_t(T+1),
        .relu(r_relu),
        .busy(r_busy),
        .done(r_done),
        .raddr(r_raddr),
        .a_rdata(ra),
        .b_rdata(rb),
        .out_we(r_we),
        .out_waddr(r_waddr),
        .out_wdata(r_wdata)
    );

    // --------------------------------
    // upsample_unit
    // Input = first T/2 rows of A
    // --------------------------------

    reg u_start = 0;

    wire u_busy, u_done, u_we;

    wire [TW-1:0] u_raddr;
    wire [TW:0] u_waddr;

    wire [127:0] u_rd, u_wdata;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_u (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .din(din_a),
        .raddr(u_raddr),
        .dout(u_rd)
    );

    wire [127:0] u_chk;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_uo (
        .clk(clk),
        .we(u_we),
        .waddr(u_waddr[TW-1:0]),
        .din(u_wdata),
        .raddr(chk),
        .dout(u_chk)
    );

    upsample_unit #(
        .N(N),
        .TW(TW)
    ) up (
        .clk(clk),
        .rst_n(rst_n),
        .start(u_start),
        .n_t(T/2),
        .busy(u_busy),
        .done(u_done),
        .raddr(u_raddr),
        .rdata(u_rd),
        .out_we(u_we),
        .out_waddr(u_waddr),
        .out_wdata(u_wdata)
    );

    // --------------------------------
    // downsample_unit
    // Input = all T rows of A
    // Output = T/2 rows
    // --------------------------------

    reg d_start = 0;

    wire d_busy, d_done, d_we;

    wire [TW:0] d_raddr;
    wire [TW-1:0] d_waddr;

    wire [127:0] d_rd, d_wdata;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_d (
        .clk(clk),
        .we(we),
        .waddr(waddr),
        .din(din_a),
        .raddr(d_raddr[TW-1:0]),
        .dout(d_rd)
    );

    wire [127:0] d_chk;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) ram_do (
        .clk(clk),
        .we(d_we),
        .waddr(d_waddr),
        .din(d_wdata),
        .raddr(chk),
        .dout(d_chk)
    );

    downsample_unit #(
        .N(N),
        .TW(TW)
    ) dn (
        .clk(clk),
        .rst_n(rst_n),
        .start(d_start),
        .n_t(T/2),
        .busy(d_busy),
        .done(d_done),
        .raddr(d_raddr),
        .rdata(d_rd),
        .out_we(d_we),
        .out_waddr(d_waddr),
        .out_wdata(d_wdata)
    );

    // --------------------------------
    // Test variables
    // --------------------------------

    integer i;
    integer errors = 0;
    integer cyc;

    // --------------------------------
    // Run task
    // --------------------------------

    task run;
        input integer which;

        begin
            cyc = 0;

            @(negedge clk);

            case (which)
                0, 1: r_start = 1;
                2: u_start = 1;
                3: d_start = 1;
            endcase

            @(negedge clk);

            r_start = 0;
            u_start = 0;
            d_start = 0;

            while (!(r_done || u_done || d_done) && cyc < 5000)
            begin
                @(negedge clk);
                cyc = cyc + 1;
            end

            if (cyc >= 5000)
            begin
                errors = errors + 1;
                $display("op %0d timeout", which);
            end
        end
    endtask

    // --------------------------------
    // Check task
    // --------------------------------

    task check;
        input integer which;
        input integer n;

        integer k;

        begin
            for (k = 0; k < n; k = k + 1)
            begin
                chk = k;

                @(negedge clk);
                @(negedge clk);

                case (which)

                    0:
                    begin
                        if (r_chk !== exp_res[k])
                        begin
                            errors = errors + 1;

                            if (errors < 6)
                                $display("res  row %0d got %h exp %h",
                                         k, r_chk, exp_res[k]);
                        end
                    end

                    1:
                    begin
                        if (r_chk !== exp_resr[k])
                        begin
                            errors = errors + 1;

                            if (errors < 6)
                                $display("relu row %0d got %h exp %h",
                                         k, r_chk, exp_resr[k]);
                        end
                    end

                    2:
                    begin
                        if (u_chk !== exp_up[k])
                        begin
                            errors = errors + 1;

                            if (errors < 6)
                                $display("up   row %0d got %h exp %h",
                                         k, u_chk, exp_up[k]);
                        end
                    end

                    3:
                    begin
                        if (d_chk !== exp_down[k])
                        begin
                            errors = errors + 1;

                            if (errors < 6)
                                $display("down row %0d got %h exp %h",
                                         k, d_chk, exp_down[k]);
                        end
                    end

                endcase
            end
        end
    endtask

    // --------------------------------
    // Main test
    // --------------------------------

    initial
    begin

        // Load test vectors
        $readmemh("vectors/rowops_a.mem", va);
        $readmemh("vectors/rowops_b.mem", vb);

        $readmemh("vectors/rowops_res.mem", exp_res);
        $readmemh("vectors/rowops_res_relu.mem", exp_resr);

        $readmemh("vectors/rowops_up.mem", exp_up);
        $readmemh("vectors/rowops_down.mem", exp_down);

        #22 rst_n = 1;

        // Load input RAMs
        for (i = 0; i < T; i = i + 1)
        begin
            @(negedge clk);

            we = 1;
            waddr = i;
            din_a = va[i];
            din_b = vb[i];
        end

        @(negedge clk);
        we = 0;

        // Test residual addition
        r_relu = 0;
        run(0);
        check(0, T);

        $display("residual_add          : %0d cycles", cyc);

        // Test residual addition with ReLU
        r_relu = 1;
        run(1);
        check(1, T);

        $display("residual_add (ReLU)   : %0d cycles", cyc);

        // Test upsampling
        run(2);
        check(2, T);

        $display("upsample_unit (32->64): %0d cycles", cyc);

        // Test downsampling
        run(3);
        check(3, T/2);

        $display("downsample_unit (64->32): %0d cycles", cyc);

        // Final result
        if (errors == 0)
            $display("tb_rowops: %0d mismatches -> PASS", errors);
        else
            $display("tb_rowops: %0d mismatches -> FAIL", errors);

        $finish;

    end

endmodule