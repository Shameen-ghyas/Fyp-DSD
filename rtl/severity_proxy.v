
module severity_proxy (
    input [15:0] intensity,
    output reg [1:0] severity
);

    always @(*) begin
        if (intensity < 200)
            severity = 2'b01;       // LOW

        else if (intensity < 400)
            severity = 2'b10;       // MEDIUM

        else
            severity = 2'b11;       // HIGH
    end

endmodule
