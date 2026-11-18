module sp_ram_tb;
  reg clk = 0;
  reg we;
  reg  [3:0] addr;
  reg  signed [7:0] din;
  wire signed [7:0] dout;

  sp_ram uut (.clk(clk), .we(we), .addr(addr), .din(din), .dout(dout));

  always #5 clk = ~clk;  

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, sp_ram_tb);

    $monitor("time=%0t  we=%b  addr=%0d  din=%0d  dout=%0d", $time, we, addr, din, dout);

   
    we = 1; addr = 0; din = 5;  #10;
    addr = 1; din = 9;          #10;
    addr = 2; din = -3;         #10;

   
    we = 0; addr = 0;           #10;
    addr = 1;                   #10;
    addr = 2;                   #10;
    $finish;
  end
endmodule
