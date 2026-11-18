module requantize #(parameter SHIFT = 4)(
  input  signed [15:0] acc,
  output signed [7:0]  b
);
  wire signed [15:0] rounded = acc + (16'sd1 << (SHIFT-1));  
  wire signed [15:0] shifted = rounded >>> SHIFT;             

  assign b = (shifted > 127)  ? 8'sd127 :                     
             (shifted < -128) ? 8'sh80  :                     
                                shifted[7:0];
endmodule
