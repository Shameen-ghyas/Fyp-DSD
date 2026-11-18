module staleness_counter_tb;
  reg clk = 0;
  reg rst;
  reg [6:0] fresh;
  wire [20:0] stale;

  staleness_counter #(.CH(7), .W(3)) uut (.clk(clk), .rst(rst), .fresh(fresh), .stale(stale));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, staleness_counter_tb);

    $monitor("t=%0t  fresh=%b  ch0=%0d  ch1=%0d", $time, fresh, stale[2:0], stale[5:3]);

    rst = 1; fresh = 0;       #10;
    rst = 0;                  #100;
    fresh = 7'b0000001;       #10;
    fresh = 0;                #30;
    $finish;
  end
endmodule
