module requantize_tb;
  reg  signed [15:0] acc;
  wire signed [7:0]  b;

  requantize uut (.acc(acc), .b(b));

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, requantize_tb);
    $monitor("acc=%0d  b=%0d", acc, b);
    acc = 0;     #10;
    acc = 7;     #10;
    acc = 8;     #10;
    acc = 100;   #10;
    acc = 2047;  #10;
    acc = 3000;  #10;
    acc = -100;  #10;
    acc = -3000; #10;
    $finish;
  end
endmodule
