module weight_rom #(
  parameter DATA_W = 8,
  parameter ADDR_W = 4,
  parameter INIT_FILE = "weights.mem"
)(
  input                           clk,
  input      [ADDR_W-1:0]         addr,
  output reg signed [DATA_W-1:0]  dout
);
  reg [DATA_W-1:0] rom [0:(1<<ADDR_W)-1];

  initial $readmemh(INIT_FILE, rom);

  always @(posedge clk)
    dout <= rom[addr];
endmodule