module robust_scaler #(
  parameter signed [15:0] MEDIAN  = 16'sd100,
  parameter signed [15:0] INV_IQR = 16'sd16,
  parameter FRAC = 8
)(
  input                    clk,
  input                    rst_n,
  input  signed [15:0]     x,
  output reg signed [7:0]  y
);
  wire signed [16:0] diff    = x - MEDIAN;
  wire signed [33:0] prod    = diff * INV_IQR;
  wire signed [33:0] rounded = prod + (34'sd1 << (FRAC-1));
  wire signed [33:0] shifted = rounded >>> FRAC;

  always @(posedge clk) begin
    if (!rst_n)
      y <= 8'sd0;
    else if (shifted > 127)
      y <= 8'sd127;
    else if (shifted < -128)
      y <= -8'sd128;
    else
      y <= shifted[7:0];
  end
endmodule

