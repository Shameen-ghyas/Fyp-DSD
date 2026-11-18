module relu_unit(
  input signed [7:0] a,
  output signed [7:0] b
);
  assign b = a[7] ? 8'b00000000 : a;
endmodule