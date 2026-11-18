module sp_ram #(parameter DATA_W = 8, ADDR_W = 4)(
  input                      clk,
  input                      we,
  input      [ADDR_W-1:0]    addr,
  input      [DATA_W-1:0]    din,
  output reg [DATA_W-1:0]    dout
);
  reg [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];   

  always @(posedge clk) begin
    if (we) mem[addr] <= din;               
    dout <= mem[addr];                      
  end
endmodule
