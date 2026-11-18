`timescale 1ns/1ps

module tb_conv1d_engine;

    parameter N = 16;
    parameter TW = 7;
    parameter T = 64;
    parameter NCFG = 4;
    parameter SH_W = 5;

    reg clk = 0;
    reg rst_n = 0;
    reg start = 0;

    always #5 clk = ~clk;

    reg [TW:0] n_t = T;
    reg [4:0] c_out, dil;
    reg [3:0] ktaps;
    reg [SH_W-1:0] shift;
    reg relu;

    reg [6:0] wbase;
    reg [5:0] bbase;

    wire busy, done;

    wire [TW-1:0] act_raddr, out_waddr;
    wire [127:0] act_rdata, w_data, out_wdata;
    wire [6:0] w_addr;
    wire [5:0] b_addr;

    wire signed [31:0] b_data;
    wire out_we;

    // Activation RAM
    reg act_we = 0;
    reg [TW-1:0] act_waddr = 0;
    reg [127:0] act_din = 0;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) act_ram (
        .clk(clk),
        .we(act_we),
        .waddr(act_waddr),
        .din(act_din),
        .raddr(act_raddr),
        .dout(act_rdata)
    );

    // Output RAM
    reg [TW-1:0] chk_addr = 0;
    wire [127:0] chk_data;

    dp_ram #(
        .DW(128),
        .AW(TW)
    ) out_ram (
        .clk(clk),
        .we(out_we),
        .waddr(out_waddr),
        .din(out_wdata),
        .raddr(chk_addr),
        .dout(chk_data)
    );

    // Weight ROM
    weight_rom #(
        .DW(128),
        .AW(7),
        .FILE("vectors/conv_wrom.mem")
    ) wrom (
        .clk(clk),
        .addr(w_addr),
        .dout(w_data)
    );

    // Bias ROM
    weight_rom #(
        .DW(32),
        .AW(6),
        .FILE("vectors/conv_brom.mem")
    ) brom (
        .clk(clk),
        .addr(b_addr),
        .dout(b_data)
    );

    // DUT
    conv1d_engine #(
        .N(N),
        .TW(TW),
        .WAW(7),
        .BAW(6),
        .SH_W(SH_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .n_t(n_t),
        .c_out(c_out),
        .ktaps(ktaps),
        .dil(dil),
        .shift(shift),
        .relu(relu),
        .wbase(wbase),
        .bbase(bbase),
        .busy(busy),
        .done(done),
        .act_raddr(act_raddr),
        .act_rdata(act_rdata),
        .w_addr(w_addr),
        .w_data(w_data),
        .b_addr(b_addr),
        .b_data(b_data),
        .out_we(out_we),
        .out_waddr(out_waddr),
        .out_wdata(out_wdata)
    );

    // Test data
    reg [111:0] cfg [0:NCFG-1];
    reg [127:0] acts [0:T-1];
    reg [127:0] exps [0:T-1];

    integer i, g;
    integer errors = 0;
    integer cycles;

    reg [8*40-1:0] fa;
    reg [8*40-1:0] fe;

    initial begin

        $readmemh("vectors/conv_cfg.mem", cfg);

        #22 rst_n = 1;

        for (g = 0; g < NCFG; g = g + 1)
        begin

            // Generate activation and expected-output filenames
            if (g == 0) begin
                fa = "vectors/conv_act_0.mem";
                fe = "vectors/conv_exp_0.mem";
            end
            else if (g == 1) begin
                fa = "vectors/conv_act_1.mem";
                fe = "vectors/conv_exp_1.mem";
            end
            else if (g == 2) begin
                fa = "vectors/conv_act_2.mem";
                fe = "vectors/conv_exp_2.mem";
            end
            else begin
                fa = "vectors/conv_act_3.mem";
                fe = "vectors/conv_exp_3.mem";
            end

            $readmemh(fa, acts);
            $readmemh(fe, exps);

            // Load activation RAM
            for (i = 0; i < T; i = i + 1)
            begin
                @(negedge clk);
                act_we = 1;
                act_waddr = i;
                act_din = acts[i];
            end

            @(negedge clk);
            act_we = 0;

            // Load configuration
            c_out = cfg[g][111:96];
            ktaps = cfg[g][95:80];
            dil = cfg[g][79:64];
            shift = cfg[g][63:48];
            relu = cfg[g][32];
            wbase = cfg[g][31:16];
            bbase = cfg[g][15:0];

            // Start engine
            @(negedge clk);
            start = 1;

            @(negedge clk);
            start = 0;

            // Wait for completion
            cycles = 0;

            while (!done && cycles < 200000)
            begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            if (!done)
            begin
                errors = errors + 1;
                $display("cfg %0d timeout", g);
            end

            // Check output RAM
            for (i = 0; i < T; i = i + 1)
            begin
                chk_addr = i;

                @(negedge clk);
                @(negedge clk);

                if (chk_data !== exps[i])
                begin
                    errors = errors + 1;

                    if (errors < 6)
                        $display(
                            "cfg %0d t=%0d got %h exp %h",
                            g, i, chk_data, exps[i]
                        );
                end
            end

            $display(
                "cfg %0d (c_out=%0d k=%0d dil=%0d shift=%0d relu=%0d): %0d cycles",
                g, c_out, ktaps, dil, shift, relu, cycles
            );

        end

        if (errors == 0)
            $display("tb_conv1d_engine: %0d configs, %0d mismatches -> PASS",
                     NCFG, errors);
        else
            $display("tb_conv1d_engine: %0d configs, %0d mismatches -> FAIL",
                     NCFG, errors);

        $finish;

    end

endmodule