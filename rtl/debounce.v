
module debounce (
    input clk,
    input rst_n,
    input button_in,
    output reg button_out
);

    parameter COUNT_MAX = 2000000;

    reg [20:0] count;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            count <= 0;
            button_out <= 0;
        end

        else if (button_in == button_out) begin
            count <= 0;
        end

        else if (count == COUNT_MAX - 1) begin
            button_out <= button_in;
            count <= 0;
        end

        else begin
            count <= count + 1;
        end

    end

endmodule
