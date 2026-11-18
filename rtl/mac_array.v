
module mac_array
#(
    parameter N = 16
)
(
    input clk,
    input rst_n,
    input en,
    input clr,

    input  [N*8-1:0]  a,
    input  [N*8-1:0]  b,

    output [N*32-1:0] acc
);

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1)
        begin : lane

            mac_unit u (
                .clk   (clk),
                .rst_n (rst_n),
                .en    (en),
                .clr   (clr),

                .a     (a[i*8 +: 8]),
                .b     (b[i*8 +: 8]),

                .acc   (acc[i*32 +: 32])
            );

        end
    endgenerate

endmodule
