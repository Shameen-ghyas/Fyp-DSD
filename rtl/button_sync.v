
module button_sync (
    input clk,
    input reset,
    input button_in,
    output button_out
);

    reg [1:0] sync_ff;

    always @(posedge clk or posedge reset) begin
        if (reset)
            sync_ff <= 2'b00;
        else
            sync_ff <= {sync_ff[0], button_in};
    end

    assign button_out = sync_ff[1];

endmodule
