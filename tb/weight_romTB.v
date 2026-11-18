module weight_rom_tb;
  reg clk = 0;
  reg [3:0] addr;
  wire signed [7:0] dout;
  integer i;

  weight_rom #(.DATA_W(8), .ADDR_W(4), .INIT_FILE("weights.mem")) uut (.clk(clk), .addr(addr), .dout(dout));

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, weight_rom_tb);

    for (i = 0; i < 16; i = i + 1) begin
      addr = i; #10;
      $display("addr=%0d  dout=%0d", addr, dout);
    end
    $finish;
  end
endmodule