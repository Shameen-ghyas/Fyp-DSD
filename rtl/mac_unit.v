module mac_unit #(
    parameter DATA_W = 8,
    parameter ACC_W  = 32
)
(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire clr,
    input wire signed [DATA_W-1:0] a,
    input wire signed [DATA_W-1:0] b,
    output reg signed [ACC_W-1:0] acc
);
    wire signed [2*DATA_W-1:0] prod;

    assign prod = a * b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            acc <= 0;

        else if (en) begin
            if (clr)
                acc <= {{(ACC_W-2*DATA_W){prod[2*DATA_W-1]}}, prod};
            else
                acc <= acc + 
                       {{(ACC_W-2*DATA_W){prod[2*DATA_W-1]}}, prod};
        end

        else if (clr)
            acc <= 0;

    end
endmodule
