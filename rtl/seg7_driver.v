
module seg7_driver (
    input clk,
    input reset,
    input [31:0] data_in,

    output reg [7:0] an,
    output reg [6:0] seg
);

    reg [18:0] refresh_count;
    wire [2:0] digit_select;
    reg [3:0] hex_digit;

    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_count <= 0;
        else
            refresh_count <= refresh_count + 1;
    end

    assign digit_select = refresh_count[18:16];

    always @(*) begin

        case (digit_select)
            3'd0: begin
                an = 8'b11111110;
                hex_digit = data_in[3:0];
            end

            3'd1: begin
                an = 8'b11111101;
                hex_digit = data_in[7:4];
            end

            3'd2: begin
                an = 8'b11111011;
                hex_digit = data_in[11:8];
            end

            3'd3: begin
                an = 8'b11110111;
                hex_digit = data_in[15:12];
            end

            3'd4: begin
                an = 8'b11101111;
                hex_digit = data_in[19:16];
            end

            3'd5: begin
                an = 8'b11011111;
                hex_digit = data_in[23:20];
            end

            3'd6: begin
                an = 8'b10111111;
                hex_digit = data_in[27:24];
            end

            3'd7: begin
                an = 8'b01111111;
                hex_digit = data_in[31:28];
            end
        endcase

        case (hex_digit)
            4'h0: seg = 7'b0000001;
            4'h1: seg = 7'b1001111;
            4'h2: seg = 7'b0010010;
            4'h3: seg = 7'b0000110;
            4'h4: seg = 7'b1001100;
            4'h5: seg = 7'b0100100;
            4'h6: seg = 7'b0100000;
            4'h7: seg = 7'b0001111;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0000100;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b1100000;
            4'hC: seg = 7'b0110001;
            4'hD: seg = 7'b1000010;
            4'hE: seg = 7'b0110000;
            4'hF: seg = 7'b0111000;
        endcase

    end

endmodule
