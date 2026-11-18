module robust_scaler_tb;
  reg clk = 0;
  reg rst;
  reg signed [15:0] x;
  wire signed [7:0] y;

  robust_scaler #(.MEDIAN(100), .INV_IQR(16), .FRAC(8)) uut (.clk(clk), .rst(rst), .x(x), .y(y));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, robust_scaler_tb);

    rst = 1; x = 0; #20;
    rst = 0;

    x = 100;   #20; $display("x=%0d  y=%0d", x, y);
    x = 116;   #20; $display("x=%0d  y=%0d", x, y);
    x = 164;   #20; $display("x=%0d  y=%0d", x, y);
    x = 84;    #20; $display("x=%0d  y=%0d", x, y);
    x = 36;    #20; $display("x=%0d  y=%0d", x, y);
    x = 107;   #20; $display("x=%0d  y=%0d", x, y);
    x = 108;   #20; $display("x=%0d  y=%0d", x, y);
    x = 0;     #20; $display("x=%0d  y=%0d", x, y);
    x = 3000;  #20; $display("x=%0d  y=%0d", x, y);
    x = -3000; #20; $display("x=%0d  y=%0d", x, y);
    $finish;
  end
endmodule