`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2026 10:57:17 PM
// Design Name: 
// Module Name: tb_reset_sync
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module tb_reset_sync;

    reg clk;
    reg async_reset;
    wire sync_reset;

    reset_sync uut (
        .clk(clk),
        .async_reset(async_reset),
        .sync_reset(sync_reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        async_reset = 1;

        #12;
        async_reset = 0;

        #50;
        $finish;
    end

endmodule
