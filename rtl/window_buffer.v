module window_buffer
#(
    parameter W = 64,
    parameter ROW_W = 128,
    parameter AW = 6
)
(
    input clk,
    input rst_n,
    input row_valid,
    input [ROW_W-1:0] row,
    input clear,
    output reg full,
    input [AW-1:0] raddr,
    output [ROW_W-1:0] rdata
);

    reg [AW-1:0] wptr;
    wire we;

    assign we = row_valid && !full;

    dp_ram #(
        .DW(ROW_W),
        .AW(AW)
    ) ram (
        .clk(clk),
        .we(we),
        .waddr(wptr),
        .din(row),
        .raddr(raddr),
        .dout(rdata)
    );

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            wptr <= 0;
            full <= 1'b0;
        end

        else if (clear)
        begin
            wptr <= 0;
            full <= 1'b0;
        end

        else if (we)
        begin
            wptr <= wptr + 1'b1;

            if (wptr == W-1)
                full <= 1'b1;
        end
    end

endmodule