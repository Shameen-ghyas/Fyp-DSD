
module recon_error_unit (
    input  [7:0] original_data,
    input  [7:0] reconstructed_data,
    output [17:0] squared_error
);

    wire signed [8:0] difference;

    assign difference =
        {1'b0, original_data} - {1'b0, reconstructed_data};

    assign squared_error = difference * difference;

endmodule
