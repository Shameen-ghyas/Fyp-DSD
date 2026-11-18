module test_window_rom #(
    parameter DW    = 63,
    parameter DEPTH = 256,
    parameter AW    = 8,
    parameter FILE  = "test_window.mem"
)(
    input clk,
    input en,
    input [AW-1:0] addr,

    output reg [DW-1:0] dout
);

    reg [DW-1:0] memory [0:DEPTH-1];

    initial begin
        $readmemh(FILE, memory);
    end

    always @(posedge clk) begin
        if (en)
            dout <= memory[addr];
    end

endmodule
