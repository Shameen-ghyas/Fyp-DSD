module phase_top_tb;
  reg clk = 0;
  reg rst;
  reg en;
  wire signed [7:0] sin_out;
  wire signed [7:0] cos_out;

  phase_top uut (.clk(clk), .rst(rst), .en(en), .sin_out(sin_out), .cos_out(cos_out));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, phase_top_tb);
    $monitor("t=%0t  phase=%0d  sin=%0d  cos=%0d", $time, uut.phase, sin_out, cos_out);

    rst = 1; en = 0; #20;
    rst = 0; en = 1; #350;
    $finish;
  end
endmodule

