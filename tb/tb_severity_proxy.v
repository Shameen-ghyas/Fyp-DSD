`timescale 1ns/1ps

// Tests severity_proxy:
//   intensity <  200        -> 2'b01 (LOW)
//   200 <= intensity < 400  -> 2'b10 (MEDIUM)
//   intensity >= 400        -> 2'b11 (HIGH)
// Boundary cases first, then ALL 65536 intensity values.

module tb_severity_proxy;

    reg  [15:0] intensity;
    wire [1:0]  severity;

    severity_proxy dut (
        .intensity (intensity),
        .severity  (severity)
    );

    integer errors = 0;
    integer i;
    reg [1:0] expected;

    task check;
        input [15:0] v;
        begin
            intensity = v;
            #1;

            if (v < 200)      expected = 2'b01;
            else if (v < 400) expected = 2'b10;
            else              expected = 2'b11;

            if (severity !== expected) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("BAD: intensity=%0d -> severity=%b expected %b",
                             v, severity, expected);
            end
        end
    endtask

    initial begin
        // boundaries
        check(16'd0);
        check(16'd1);
        check(16'd199);    // LOW
        check(16'd200);    // MEDIUM starts
        check(16'd201);
        check(16'd399);    // MEDIUM
        check(16'd400);    // HIGH starts
        check(16'd401);
        check(16'd65535);  // HIGH

        // every possible value
        for (i = 0; i < 65536; i = i + 1)
            check(i);

        if (errors == 0)
            $display("tb_severity_proxy: %0d errors -> PASS", errors);
        else
            $display("tb_severity_proxy: %0d errors -> FAIL", errors);

        $finish;
    end

endmodule
