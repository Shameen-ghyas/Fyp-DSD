module preproc_top #(
    // per-channel scaler params, lane c = bits [16*c +: 16]
    // abhi defaults (100, 16) placeholder hain, real values baad mein
    parameter [7*16-1:0] MEDIAN_V  = {7{16'sd100}},
    parameter [7*16-1:0] INV_IQR_V = {7{16'sd16}}
)(
    input          clk,
    input          rst_n,
    input          in_valid,       // 1 clk pulse, in_word valid hone pe
    input  [62:0]  in_word,        // {fresh[6:0], ch6..ch0}, ch c = [8*c +: 8]
    output         row_valid,      // in_valid ke 1 clk baad
    output [127:0] row             // lane i = row[8*i +: 8]
);

    wire [55:0] raw   = in_word[55:0];
    wire [6:0]  fresh = in_word[62:56];

    // lanes 0-6: scaled channels
    wire [55:0] scaled;
    genvar c;
    generate
        for (c = 0; c < 7; c = c + 1) begin : g_scale
            robust_scaler #(
                .MEDIAN (MEDIAN_V[16*c +: 16]),
                .INV_IQR(INV_IQR_V[16*c +: 16]),
                .FRAC   (8)
            ) u_sc (
                .clk  (clk),
                .rst_n(rst_n),
                .x    ({8'b0, raw[8*c +: 8]}),
                .y    (scaled[8*c +: 8])
            );
        end
    endgenerate

    // lanes 7-13: staleness
    wire [55:0] stale;
    staleness_counter #(.CH(7), .W(8)) u_stale (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (in_valid),
        .fresh(fresh),
        .stale(stale)
    );

    // lanes 14-15: sin, cos
    wire [3:0] phase;
    wire [7:0] sin_w, cos_w;
    phase_counter #(.N(16), .AW(4)) u_ph (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (in_valid),
        .phase(phase)
    );
    orbit_phase_rom u_rom (
        .clk    (clk),
        .addr   (phase),
        .sin_out(sin_w),
        .cos_out(cos_w)
    );

    // sab blocks ki latency 1 clk hai, to valid bhi 1 clk delay
    reg v_d;
    always @(posedge clk) begin
        if (!rst_n) v_d <= 1'b0;
        else        v_d <= in_valid;
    end

    assign row_valid = v_d;
    assign row       = {cos_w, sin_w, stale, scaled};

endmodule