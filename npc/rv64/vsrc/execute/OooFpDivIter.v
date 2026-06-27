`include "define.v"

// Serial restoring divider used by the serialized FP bring-up path.
// It replaces the wide single-cycle / and % operators with one subtract/compare
// step per quotient bit, which is a much friendlier ASIC timing boundary.
module OooFpDivIter #(
  parameter DIVIDEND_W = 108,
  parameter DIVISOR_W = 53,
  parameter QUOTIENT_W = 56,
  parameter INDEX_W = 6
) (
  input clk,
  input rst,
  input flush_i,
  input start_i,
  input [DIVIDEND_W-1:0] dividend_i,
  input [DIVISOR_W-1:0] divisor_i,
  output busy_o,
  output done_o,
  output [QUOTIENT_W-1:0] quotient_o,
  output remainder_nonzero_o
);

  reg busy_q;
  reg done_q;
  reg [DIVIDEND_W-1:0] remainder_q;
  reg [DIVIDEND_W-1:0] shifted_divisor_q;
  reg [QUOTIENT_W-1:0] quotient_q;
  reg [QUOTIENT_W-1:0] quotient_result_q;
  reg remainder_nonzero_q;
  reg [INDEX_W-1:0] bit_idx_q;

  localparam [INDEX_W-1:0] LAST_QUOTIENT_BIT = QUOTIENT_W - 1;

  wire subtract_step_w = shifted_divisor_q <= remainder_q;
  wire [DIVIDEND_W-1:0] step_remainder_w =
      subtract_step_w ? (remainder_q - shifted_divisor_q) : remainder_q;
  wire [QUOTIENT_W-1:0] step_quotient_w =
      {quotient_q[QUOTIENT_W-2:0], subtract_step_w};
  wire [DIVIDEND_W-1:0] next_shifted_divisor_w =
      {1'b0, shifted_divisor_q[DIVIDEND_W-1:1]};
  wire last_step_w = bit_idx_q == {INDEX_W{1'b0}};

  always @(posedge clk) begin
    if (rst || flush_i) begin
      busy_q <= 1'b0;
      done_q <= 1'b0;
      remainder_q <= {DIVIDEND_W{1'b0}};
      shifted_divisor_q <= {DIVIDEND_W{1'b0}};
      quotient_q <= {QUOTIENT_W{1'b0}};
      quotient_result_q <= {QUOTIENT_W{1'b0}};
      remainder_nonzero_q <= 1'b0;
      bit_idx_q <= {INDEX_W{1'b0}};
    end else begin
      done_q <= 1'b0;
      if (start_i && !busy_q) begin
        busy_q <= 1'b1;
        remainder_q <= dividend_i;
        shifted_divisor_q <=
            ({{(DIVIDEND_W-DIVISOR_W){1'b0}}, divisor_i} <<
             LAST_QUOTIENT_BIT);
        quotient_q <= {QUOTIENT_W{1'b0}};
        bit_idx_q <= LAST_QUOTIENT_BIT;
      end else if (busy_q) begin
        remainder_q <= step_remainder_w;
        quotient_q <= step_quotient_w;
        if (last_step_w) begin
          busy_q <= 1'b0;
          done_q <= 1'b1;
          shifted_divisor_q <= {DIVIDEND_W{1'b0}};
          quotient_result_q <= step_quotient_w;
          remainder_nonzero_q <= |step_remainder_w;
          bit_idx_q <= {INDEX_W{1'b0}};
        end else begin
          shifted_divisor_q <= next_shifted_divisor_w;
          bit_idx_q <= bit_idx_q - {{(INDEX_W-1){1'b0}}, 1'b1};
        end
      end
    end
  end

  assign busy_o = busy_q;
  assign done_o = done_q;
  assign quotient_o = quotient_result_q;
  assign remainder_nonzero_o = remainder_nonzero_q;

endmodule
