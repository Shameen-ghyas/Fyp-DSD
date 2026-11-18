module recon_error_unit (
    input  signed [7:0] original_data,
    input  signed [7:0] reconstructed_data,
    output        [17:0] squared_error
);

    wire signed [8:0] difference;
    wire signed [17:0] square;

    assign difference = original_data - reconstructed_data;
    assign square     = difference * difference;
    assign squared_error = square[17:0];

endmodule
