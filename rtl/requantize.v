// module requantize #(
//     parameter DATA_W = 8,
//     parameter ACC_W  = 32,
//     parameter SH_W   = 5
// )(
//     input  wire signed [ACC_W-1:0] acc,
//     input  wire signed [ACC_W-1:0] bias,
//     input  wire        [SH_W-1:0]  shift,
//     input  wire                   relu_en,
//     output wire signed [DATA_W-1:0] y
// );

//     wire signed [ACC_W-1:0] biased;
//     wire signed [ACC_W-1:0] shifted;
//     wire signed [DATA_W-1:0] sat;

//     assign biased = acc + bias;

//     wire signed [ACC_W-1:0] rounding_value;

//     assign rounding_value =
//         (shift == 0) ? biased :
//         biased + ({{(ACC_W-1){1'b0}}, 1'b1} << (shift - 1));

//     assign shifted =
//         (shift == 0) ? biased : (rounding_value >>> shift);

//     // Step 3: Saturate to signed INT8 range
//     assign sat =
//         (shifted > 127)  ? 127 :
//         (shifted < -128) ? -128 :
//         shifted[DATA_W-1:0];

//     // Step 4: Optional ReLU
//     assign y = (relu_en && (sat < 0)) ? 0 : sat;

// endmodule


module requantize
#(
    parameter ACC_W = 32,
    parameter DATA_W = 8,
    parameter SH_W = 5
)
(
    input signed [ACC_W-1:0] acc,
    input signed [ACC_W-1:0] bias,
    input [SH_W-1:0] shift,
    input relu_en,
    output signed [DATA_W-1:0] y
);

    wire signed [ACC_W-1:0] biased;
    wire signed [ACC_W-1:0] shifted;
    wire signed [DATA_W-1:0] sat;

    assign biased = acc + bias;

    // Round and shift function
    function signed [ACC_W-1:0] round_shift;
        input signed [ACC_W-1:0] x;
        input [SH_W-1:0] s;
        reg signed [ACC_W-1:0] half;
        begin
            if (s == 0)
                round_shift = x;
            else
            begin
                half = 1;
                half = half << (s - 1);
                if (x >= 0)
                    round_shift = (x + half) >>> s;
                else
                    round_shift = (x - half) >>> s;
            end
        end
    endfunction

    // Saturation function: INT32 to INT8
    function signed [DATA_W-1:0] sat8;
        input signed [ACC_W-1:0] x;
        begin
            if (x > 127)
                sat8 = 127;
            else if (x < -128)
                sat8 = -128;
            else
                sat8 = x;
        end
    endfunction

    assign shifted = round_shift(biased, shift);
    assign sat = sat8(shifted);

    assign y = (relu_en && sat < 0) ? 0 : sat;

endmodule
