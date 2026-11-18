module sp_ram #(parameter DW = 8, AW = 4)(
  input                 clk,
  input                 we,
  input      [AW-1:0]   addr,
  input      [DW-1:0]   din,
  output reg [DW-1:0]   dout
);
  reg [DW-1:0] mem [0:(1<<AW)-1];

  always @(posedge clk) begin
    if (we) mem[addr] <= din;
    dout <= mem[addr];
  end
endmodule
