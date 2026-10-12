// Test-only adapter for legacy ordered translation stimuli. Production always
// returns explicit opaque tokens; no backwards-compatible production port exists.
module R64TranslationTokenEcho #(parameter TOKEN_W = 5) (
  input clk_i, rst_i,
  input [1:0] req_fire_i,
  input [2*TOKEN_W-1:0] req_token_i,
  input [1:0] rsp_fire_i,
  output [2*TOKEN_W-1:0] rsp_token_o
);
  generate for (genvar g = 0; g < 2; g = g + 1) begin : lane
    reg [TOKEN_W-1:0] tokens[0:15];
    reg [3:0] head_q, tail_q;
    integer count_q;
    assign rsp_token_o[g*TOKEN_W+:TOKEN_W] = tokens[head_q];
    always @(posedge clk_i) begin
      if (rst_i) begin
        head_q <= 0; tail_q <= 0; count_q <= 0;
      end else begin
        count_q <= count_q + (req_fire_i[g] ? 1 : 0) - (rsp_fire_i[g] ? 1 : 0);
        if (req_fire_i[g]) begin
          tokens[tail_q] <= req_token_i[g*TOKEN_W+:TOKEN_W];
          tail_q <= tail_q + 1'b1;
        end
        if (rsp_fire_i[g]) head_q <= head_q + 1'b1;
        if (count_q > 16 || (req_fire_i[g] && count_q == 16) ||
            (rsp_fire_i[g] && count_q == 0))
          $fatal(1, "translation test token model capacity mismatch");
      end
    end
  end endgenerate
endmodule
