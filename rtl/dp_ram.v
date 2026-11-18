module dp_ram #(parameter DW = 8, parameter AW = 10)
(
    input clk,
    input we,
    input [AW-1:0] waddr,
    input [DW-1:0] din,
    input [AW-1:0] raddr,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] mem [0:(1<<AW)-1];

    always @(posedge clk)
    begin
        if (we)
            mem[waddr] <= din;

        dout <= mem[raddr];
    end

endmodule