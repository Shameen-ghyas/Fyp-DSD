module phase_counter #(parameter N = 16, AW = 4)(
  input               clk,
  input               rst_n,
  input               en,
  output reg [AW-1:0] phase
);
  always @(posedge clk) begin
    if (!rst_n)
      phase <= 0;
    else if (en) begin
      if (phase == N-1)
        phase <= 0;
      else
        phase <= phase + 1;
    end
  end
endmodule

module orbit_phase_rom (
  input                    clk,
  input      [3:0]         addr,
  output reg signed [7:0]  sin_out,
  output reg signed [7:0]  cos_out
);
  always @(posedge clk) begin
    case (addr)
      4'd0:  begin sin_out <= 8'sd0;    cos_out <= 8'sd127;  end
      4'd1:  begin sin_out <= 8'sd49;   cos_out <= 8'sd117;  end
      4'd2:  begin sin_out <= 8'sd90;   cos_out <= 8'sd90;   end
      4'd3:  begin sin_out <= 8'sd117;  cos_out <= 8'sd49;   end
      4'd4:  begin sin_out <= 8'sd127;  cos_out <= 8'sd0;    end
      4'd5:  begin sin_out <= 8'sd117;  cos_out <= -8'sd49;  end
      4'd6:  begin sin_out <= 8'sd90;   cos_out <= -8'sd90;  end
      4'd7:  begin sin_out <= 8'sd49;   cos_out <= -8'sd117; end
      4'd8:  begin sin_out <= 8'sd0;    cos_out <= -8'sd127; end
      4'd9:  begin sin_out <= -8'sd49;  cos_out <= -8'sd117; end
      4'd10: begin sin_out <= -8'sd90;  cos_out <= -8'sd90;  end
      4'd11: begin sin_out <= -8'sd117; cos_out <= -8'sd49;  end
      4'd12: begin sin_out <= -8'sd127; cos_out <= 8'sd0;    end
      4'd13: begin sin_out <= -8'sd117; cos_out <= 8'sd49;   end
      4'd14: begin sin_out <= -8'sd90;  cos_out <= 8'sd90;   end
      4'd15: begin sin_out <= -8'sd49;  cos_out <= 8'sd117;  end
    endcase
  end
endmodule

module phase_top (
  input                   clk,
  input                   rst_n,
  input                   en,
  output signed [7:0]     sin_out,
  output signed [7:0]     cos_out
);
  wire [3:0] phase;

  phase_counter #(.N(16), .AW(4)) u_cnt (.clk(clk), .rst_n(rst_n), .en(en), .phase(phase));
  orbit_phase_rom u_rom (.clk(clk), .addr(phase), .sin_out(sin_out), .cos_out(cos_out));
endmodule


