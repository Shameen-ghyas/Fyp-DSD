module relu_unit_tb;
  reg signed [7:0] a;
  wire signed [7:0] b;
  relu_unit uut(.a(a), .b(b));
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, relu_unit_tb);
    a = -128; #10;
    a = -50;  #10;
    a = -1;   #10;
    a = 0;    #10;
    a = 1;    #10;
    a = 50;   #10;
    a = 127;  #10;
    $finish;
  end
endmodule