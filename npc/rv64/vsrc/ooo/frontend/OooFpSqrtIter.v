`include "define.v"

// Digit-by-digit non-restoring square-root unit for the serialized FP path.
// One radicand bit-pair is consumed per cycle, avoiding a wide combinational
// candidate-square tree in the frontend commit cone.
module OooFpSqrtIter #(
  parameter VALUE_W = 112,
  parameter ROOT_W = 56,
  parameter INDEX_W = 6
) (
  input clk,
  input rst,
  input flush_i,
  input start_i,
  input [VALUE_W-1:0] value_i,
  output busy_o,
  output done_o,
  output [ROOT_W-1:0] root_o,
  output remainder_nonzero_o
);

  reg busy_q;
  reg done_q;
  reg [VALUE_W-1:0] radicand_q;
  reg [VALUE_W+1:0] remainder_q;
  reg [ROOT_W-1:0] root_q;
  reg [ROOT_W-1:0] root_result_q;
  reg remainder_nonzero_q;
  reg [INDEX_W-1:0] step_idx_q;

  localparam [INDEX_W-1:0] LAST_ROOT_BIT = ROOT_W - 1;

  wire [1:0] next_pair_w = radicand_q[VALUE_W-1:VALUE_W-2];
  wire [VALUE_W+1:0] shifted_remainder_w =
      {remainder_q[VALUE_W-1:0], next_pair_w};
  wire [VALUE_W+1:0] trial_w =
      {{(VALUE_W-ROOT_W){1'b0}}, root_q, 2'b01};
  wire accept_step_w = shifted_remainder_w >= trial_w;
  wire [VALUE_W+1:0] step_remainder_w =
      accept_step_w ? (shifted_remainder_w - trial_w) : shifted_remainder_w;
  wire [ROOT_W-1:0] step_root_w = {root_q[ROOT_W-2:0], accept_step_w};
  wire [VALUE_W-1:0] step_radicand_w =
      {radicand_q[VALUE_W-3:0], 2'b00};
  wire last_step_w = step_idx_q == {INDEX_W{1'b0}};

  always @(posedge clk) begin
    if (rst || flush_i) begin
      busy_q <= 1'b0;
      done_q <= 1'b0;
      radicand_q <= {VALUE_W{1'b0}};
      remainder_q <= {(VALUE_W+2){1'b0}};
      root_q <= {ROOT_W{1'b0}};
      root_result_q <= {ROOT_W{1'b0}};
      remainder_nonzero_q <= 1'b0;
      step_idx_q <= {INDEX_W{1'b0}};
    end else begin
      done_q <= 1'b0;
      if (start_i && !busy_q) begin
        busy_q <= 1'b1;
        radicand_q <= value_i;
        remainder_q <= {(VALUE_W+2){1'b0}};
        root_q <= {ROOT_W{1'b0}};
        step_idx_q <= LAST_ROOT_BIT;
      end else if (busy_q) begin
        radicand_q <= step_radicand_w;
        remainder_q <= step_remainder_w;
        root_q <= step_root_w;
        if (last_step_w) begin
          busy_q <= 1'b0;
          done_q <= 1'b1;
          root_result_q <= step_root_w;
          remainder_nonzero_q <= |step_remainder_w;
          step_idx_q <= {INDEX_W{1'b0}};
        end else begin
          step_idx_q <= step_idx_q - {{(INDEX_W-1){1'b0}}, 1'b1};
        end
      end
    end
  end

  assign busy_o = busy_q;
  assign done_o = done_q;
  assign root_o = root_result_q;
  assign remainder_nonzero_o = remainder_nonzero_q;

endmodule
