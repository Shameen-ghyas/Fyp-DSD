// weight_rom.v
// ROM initialized from a hex .mem file.
// One-cycle read latency.

module weight_rom #(
    parameter DW = 8,
    parameter AW = 10,
    parameter FILE = "weights.mem"
)
(
    input clk,
    input [AW-1:0] addr,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] mem [0:(1<<AW)-1];

    initial begin
        $readmemh(FILE, mem);
    end

    always @(posedge clk) begin
        dout <= mem[addr];
    end

endmodule