module staleness_counter #(parameter CH = 7, W = 8)(
  input                 clk,
  input                 rst,
  input      [CH-1:0]   fresh,
  output reg [CH*W-1:0] stale
);
  integer i;

  always @(posedge clk) begin
    if (rst)
      stale <= 0;
    else begin
      for (i = 0; i < CH; i = i + 1) begin
        if (fresh[i])
          stale[i*W +: W] <= 0;
        else if (stale[i*W +: W] != {W{1'b1}})
          stale[i*W +: W] <= stale[i*W +: W] + 1;
      end
    end
  end
endmodule
