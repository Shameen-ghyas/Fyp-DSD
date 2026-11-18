`timescale 1ns/1ps

// Tests intensity_unit:
//   deviation = |channel_value - median_value|
//   intensity = (deviation * 100) / robust_scale   (integer division, rounds down)
//   intensity = 0 when robust_scale = 0
// Directed cases, a sweep over channel_value, then random inputs.

module tb_intensity_unit;

    reg  [7:0]  channel_value;
    reg  [7:0]  median_value;
    reg  [7:0]  robust_scale;
    wire [15:0] intensity;

    intensity_unit dut (
        .channel_value (channel_value),
        .median_value  (median_value),
        .robust_scale  (robust_scale),
        .intensity     (intensity)
    );

    integer errors = 0;
    integer n, mi, c;
    integer dev;
    integer exp_i;
    reg [15:0] expected;

    task check;
        input [7:0] cv;
        input [7:0] mv;
        input [7:0] rs;
        begin
            channel_value = cv;
            median_value  = mv;
            robust_scale  = rs;
            #1;

            if (cv >= mv) dev = cv - mv;
            else          dev = mv - cv;

            if (rs == 0) exp_i = 0;
            else         exp_i = (dev * 100) / rs;

            expected = exp_i;

            if (intensity !== expected) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("BAD: value=%0d median=%0d scale=%0d -> got %0d expected %0d",
                             cv, mv, rs, intensity, expected);
            end
        end
    endtask

    // all channel values for one (median, scale) pair
    task sweep_c;
        input [7:0] mv;
        input [7:0] rs;
        integer cc;
        begin
            for (cc = 0; cc < 256; cc = cc + 1)
                check(cc, mv, rs);
        end
    endtask

    initial begin
        // directed
        check(8'd100, 8'd100, 8'd10);   // deviation 0        -> 0
        check(8'd150, 8'd100, 8'd25);   // 50*100/25  = 200
        check(8'd50,  8'd100, 8'd25);   // below median, same -> 200
        check(8'd50,  8'd100, 8'd30);   // 5000/30    = 166 (rounds down)
        check(8'd255, 8'd0,   8'd1);    // 25500 (largest possible)
        check(8'd0,   8'd255, 8'd255);  // 100
        check(8'd120, 8'd100, 8'd0);    // scale 0 -> 0 (no divide by zero)
        check(8'd0,   8'd0,   8'd0);    // 0

        // sweep every channel value for several medians / scales
        for (mi = 0; mi < 4; mi = mi + 1) begin
            sweep_c(mi * 85, 8'd0);
            sweep_c(mi * 85, 8'd1);
            sweep_c(mi * 85, 8'd3);
            sweep_c(mi * 85, 8'd50);
            sweep_c(mi * 85, 8'd255);
        end

        // random
        for (n = 0; n < 10000; n = n + 1)
            check($random, $random, $random);

        if (errors == 0)
            $display("tb_intensity_unit: %0d errors -> PASS", errors);
        else
            $display("tb_intensity_unit: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule
