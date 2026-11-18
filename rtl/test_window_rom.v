
module test_window_rom #(
    parameter DATA_WIDTH = 63,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 8,
    parameter MEM_FILE = "test_window.mem"
)(
    input clk,
    input enable,
    input [ADDR_WIDTH-1:0] address,

    output reg [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    initial begin
        $readmemh(MEM_FILE, memory);
    end

    always @(posedge clk) begin
        if (enable)
            data_out <= memory[address];
    end

endmodule
