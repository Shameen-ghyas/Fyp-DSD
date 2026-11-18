module staleness_counter #(parameter CH = 7, W = 8)(
  input                 clk,
  input                 rst_n,
  input                 en,
  input      [CH-1:0]   fresh,
  output reg [CH*W-1:0] stale
);
  localparam [W-1:0] MAX = (1 << (W-1)) - 1;   // 127, same as STALE_MAX in fixed_ref.py
  integer i;

  always @(posedge clk) begin
    if (!rst_n)
      stale <= 0;
    else if (en) begin
      for (i = 0; i < CH; i = i + 1) begin
        if (fresh[i])
          stale[i*W +: W] <= 0;
        else if (stale[i*W +: W] != MAX)
          stale[i*W +: W] <= stale[i*W +: W] + 1;
      end
    end
  end
endmodule