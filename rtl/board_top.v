module board_top (
    input         clk,           // 100 MHz
    input         cpu_resetn,    // active low
    input         btnc,          // replay start
    input  [1:0]  sw,            // window select (4 windows)
    output [15:0] led,
    output [6:0]  seg,
    output [7:0]  an,
    output        uart_txd
);

    parameter [31:0] THRESHOLD = 32'd100000;   // placeholder, validation se set hoga

    // ---------- reset ----------
    wire rst_n;
    reset_sync u_rs (.clk(clk), .async_rst_n(cpu_resetn), .sync_rst_n(rst_n));

    // ---------- button ----------
    wire btn_s, btn_db;
    reg  btn_d;
    button_sync u_bs (.clk(clk), .rst_n(rst_n), .button_in(btnc), .button_out(btn_s));
    debounce    u_db (.clk(clk), .rst_n(rst_n), .button_in(btn_s), .button_out(btn_db));
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) btn_d <= 1'b0;
        else        btn_d <= btn_db;
    end
    wire start_pulse = btn_db & ~btn_d;

    // ---------- test window replay ----------
    localparam S_IDLE = 1'b0, S_FEED = 1'b1;
    reg        rstate;
    reg [1:0]  sel;
    reg [5:0]  cnt;
    wire       det_busy;
    wire       det_in_ready;
    wire       rom_en = (rstate == S_FEED) && det_in_ready;
    reg        rom_en_d;
    wire [118:0] rom_dout;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rstate   <= S_IDLE;
            sel      <= 2'd0;
            cnt      <= 6'd0;
            rom_en_d <= 1'b0;
        end else begin
            rom_en_d <= rom_en;
            case (rstate)
                S_IDLE: if (start_pulse && !det_busy) begin
                    sel    <= sw;
                    cnt    <= 6'd0;
                    rstate <= S_FEED;
                end
                S_FEED: if (rom_en) begin
                    if (cnt == 6'd63) rstate <= S_IDLE;
                    else              cnt    <= cnt + 1'b1;
                end
            endcase
        end
    end

    test_window_rom #(.DW(119), .DEPTH(256), .AW(8), .FILE("test_window.mem")) u_rom (
        .clk(clk), .en(rom_en), .addr({sel, cnt}), .dout(rom_dout)
    );

    // ---------- detector ----------
    wire        det_done, anomaly_flag;
    wire [2:0]  top_channel;
    wire [15:0] intensity;
    wire [1:0]  severity;
    wire [31:0] total_score, latency_cycles;

    anomaly_detector_top u_det (
        .clk(clk), .rst_n(rst_n),
        .in_valid(rom_en_d), .in_word(rom_dout), .in_ready(det_in_ready),
        .threshold(THRESHOLD),
        .done(det_done), .anomaly_flag(anomaly_flag), .top_channel(top_channel),
        .intensity(intensity), .severity(severity), .total_score(total_score),
        .latency_cycles(latency_cycles), .busy(det_busy)
    );

    reg result_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)                          result_valid <= 1'b0;
        else if (start_pulse && !det_busy)   result_valid <= 1'b0;
        else if (det_done)                   result_valid <= 1'b1;
    end

    // ---------- UART report ----------
    wire       tx_start, tx_busy, tx_done, report_done;
    wire [7:0] tx_data;

    uart_report_fsm u_rep (
        .clk(clk), .rst_n(rst_n),
        .start(det_done),
        .score(total_score), .flagged_channel(top_channel),
        .intensity(intensity), .latency(latency_cycles),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx_busy(tx_busy), .tx_done(tx_done),
        .report_done(report_done)
    );

    uart_tx u_tx (
        .clk(clk), .rst_n(rst_n),
        .tx_start(tx_start), .tx_data(tx_data),
        .tx(uart_txd), .tx_busy(tx_busy), .tx_done(tx_done)
    );

    // ---------- 7-segment: total score ----------
    seg7_driver u_seg (.clk(clk), .rst_n(rst_n), .data_in(total_score), .an(an), .seg(seg));

    // ---------- LEDs ----------
    assign led[0]    = anomaly_flag & result_valid;
    assign led[2:1]  = result_valid ? severity : 2'b00;
    assign led[5:3]  = result_valid ? top_channel : 3'b000;
    assign led[6]    = result_valid;
    assign led[7]    = det_busy;
    assign led[8]    = tx_busy;
    assign led[15:9] = 7'b0;

endmodule