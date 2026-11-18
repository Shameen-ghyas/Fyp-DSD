
module intensity_unit (
    input [7:0] channel_value,
    input [7:0] median_value,
    input [7:0] robust_scale,
    output reg [15:0] intensity
);

    reg [8:0] deviation;
    reg [16:0] numerator;

    always @(*) begin
        if (channel_value >= median_value)
            deviation = channel_value - median_value;
        else
            deviation = median_value - channel_value;

        numerator = deviation * 9'd100;

        if (robust_scale != 0)
            intensity = numerator / robust_scale;
        else
            intensity = 0;
    end

endmodule
