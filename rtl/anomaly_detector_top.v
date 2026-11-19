module anomaly_detector_top #(
    // preprocessing scaler params (lane c = [16*c +: 16]), abhi placeholder
    parameter [7*16-1:0] MEDIAN_V   = {7{16'sd100}},
    parameter [7*16-1:0] INV_IQR_V  = {7{16'sd16}},
    // intensity ke liye raw-domain median / scale (lane c = [8*c +: 8]), abhi placeholder
    parameter [8*8-1:0]  MEDIAN8_V  = {8{8'd100}},
    parameter [8*8-1:0]  SCALE8_V   = {8{8'd16}}
)(
    input          clk,
    input          rst_n,

    // sample input (board_top test_window_rom se push karega)
    input          in_valid,
    input  [62:0]  in_word,         // {fresh[6:0], ch6..ch0}
    output         in_ready,

    input  [31:0]  threshold,

    // results (done pulse pe valid, agli run tak held)
    output reg         done,
    output reg         anomaly_flag,
    output reg [2:0]   top_channel,
    output reg [15:0]  intensity,    // x100
    output reg [1:0]   severity,     // 01 low, 10 med, 11 high
    output reg [31:0]  total_score,
    output [31:0]      latency_cycles,
    output             busy
);

    localparam S_FILL = 2'd0, S_TCN = 2'd1, S_SCORE = 2'd2;
    reg [1:0] state;
    reg       tcn_start, sc_start, wb_clear;

    // ---------------- preprocessing ----------------
    wire         row_valid;
    wire [127:0] row;

    preproc_top #(.MEDIAN_V(MEDIAN_V), .INV_IQR_V(INV_IQR_V)) u_pre (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_word(in_word),
        .row_valid(row_valid), .row(row)
    );

    reg [55:0] raw_last;            // latest raw sample (intensity ke liye)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)        raw_last <= 56'd0;
        else if (in_valid) raw_last <= in_word[55:0];
    end

    // ---------------- window buffer ----------------
    wire         wb_full;
    wire [5:0]   tcn_in_raddr, sc_rd_addr;
    wire [127:0] wb_rdata;
    wire [5:0]   wb_raddr = (state == S_TCN) ? tcn_in_raddr : sc_rd_addr;

    window_buffer #(.W(64), .ROW_W(128), .AW(6)) u_wb (
        .clk(clk), .rst_n(rst_n),
        .row_valid(row_valid), .row(row),
        .clear(wb_clear),
        .full(wb_full),
        .raddr(wb_raddr),
        .rdata(wb_rdata)
    );

    assign in_ready = (state == S_FILL) && !wb_full;

    // ---------------- TCN ----------------
    wire         tcn_busy, tcn_done;
    wire [31:0]  tcn_cycles;
    wire [127:0] recon_row;

    encdec_top_tcn u_tcn (
        .clk(clk), .rst_n(rst_n),
        .start(tcn_start),
        .busy(tcn_busy), .done(tcn_done), .cycles(tcn_cycles),
        .in_raddr(tcn_in_raddr), .in_rdata(wb_rdata),
        .ext_raddr(sc_rd_addr),  .out_rdata(recon_row)
    );

    // ---------------- scoring ----------------
    wire         sc_busy, sc_done;
    wire [7*32-1:0] score_ch;
    wire [31:0]  sc_total;

    scoring_top u_sc (
        .clk(clk), .rst_n(rst_n),
        .start(sc_start),
        .rd_addr(sc_rd_addr),
        .orig_row(wb_rdata), .recon_row(recon_row),
        .busy(sc_busy), .done(sc_done),
        .score_ch(score_ch), .total_score(sc_total)
    );

    // ---------------- decision ----------------
    wire        flag_w;
    wire [2:0]  top_ch_w;
    wire [31:0] top_score_w;
    wire [15:0] intensity_w;
    wire [1:0]  severity_w;

    threshold_static u_thr (
        .total_score(sc_total), .threshold(threshold), .anomaly_flag(flag_w)
    );

    top_channel_ranker u_rank (
        .score_ch0(score_ch[ 0*32 +: 32]), .score_ch1(score_ch[ 1*32 +: 32]),
        .score_ch2(score_ch[ 2*32 +: 32]), .score_ch3(score_ch[ 3*32 +: 32]),
        .score_ch4(score_ch[ 4*32 +: 32]), .score_ch5(score_ch[ 5*32 +: 32]),
        .score_ch6(score_ch[ 6*32 +: 32]),
        .top_channel(top_ch_w), .top_score(top_score_w)
    );

    wire [63:0] raw_pad = {8'd0, raw_last};

    intensity_unit u_int (
        .channel_value(raw_pad  [8*top_ch_w +: 8]),
        .median_value (MEDIAN8_V[8*top_ch_w +: 8]),
        .robust_scale (SCALE8_V [8*top_ch_w +: 8]),
        .intensity(intensity_w)
    );

    severity_proxy u_sev (.intensity(intensity_w), .severity(severity_w));

    // ---------------- latency ----------------
    perf_counter u_perf (
        .clk(clk), .rst_n(rst_n),
        .start(tcn_start), .done(sc_done),
        .cycle_count(latency_cycles), .busy()
    );

    // ---------------- control FSM ----------------
    assign busy = (state != S_FILL);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_FILL;
            tcn_start    <= 1'b0;
            sc_start     <= 1'b0;
            wb_clear     <= 1'b0;
            done         <= 1'b0;
            anomaly_flag <= 1'b0;
            top_channel  <= 3'd0;
            intensity    <= 16'd0;
            severity     <= 2'd0;
            total_score  <= 32'd0;
        end else begin
            tcn_start <= 1'b0;
            sc_start  <= 1'b0;
            wb_clear  <= 1'b0;
            done      <= 1'b0;
            case (state)
                S_FILL: if (wb_full) begin
                    tcn_start <= 1'b1;
                    state     <= S_TCN;
                end
                S_TCN: if (tcn_done) begin
                    sc_start <= 1'b1;
                    state    <= S_SCORE;
                end
                S_SCORE: if (sc_done) begin
                    anomaly_flag <= flag_w;
                    top_channel  <= top_ch_w;
                    intensity    <= intensity_w;
                    severity     <= severity_w;
                    total_score  <= sc_total;
                    done         <= 1'b1;
                    wb_clear     <= 1'b1;
                    state        <= S_FILL;
                end
                default: state <= S_FILL;
            endcase
        end
    end

endmodule