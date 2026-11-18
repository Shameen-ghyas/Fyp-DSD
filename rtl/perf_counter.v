
module perf_counter (
    input clk,
    input reset,
    input start,
    input done,
    output reg [31:0] cycle_count,
    output reg busy
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            cycle_count <= 0;
            busy <= 0;
        end

        else if (start && !busy) begin
            cycle_count <= 0;
            busy <= 1;
        end

        else if (busy) begin
            if (done) begin
                busy <= 0;
            end
            else begin
                cycle_count <= cycle_count + 1;
            end
        end

    end

endmodule
