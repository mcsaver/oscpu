`include "define.v"

module OooDirectRasCandidateGate #(
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter ENABLE_DIRECT_RAS_RET = 1'b1
) (
  input head0_jal_raw_i,
  input [`REG_ADDR_W-1:0] head0_rd_i,
  input head1_jal_raw_i,
  input [`REG_ADDR_W-1:0] head1_rd_i,

  input [ROB_COUNT_W-1:0] rob_count_i,
  input stop_pending_i,
  input branch_spec_active_i,
  input branch_spec_checkpoint_pending_i,

  input dispatch0_jump_i,
  input [`REG_ADDR_W-1:0] head0_rs1_i,
  input [`XLEN-1:0] head0_imm_i,
  input head1_jalr_raw_i,
  input [`REG_ADDR_W-1:0] head1_rs1_i,
  input [`XLEN-1:0] head1_imm_i,
  input ras_reliable_i,
  input ras_empty_i,

  output head0_jal_call_raw_o,
  output head1_jal_call_raw_o,
  output ras_direct_update_safe_o,
  output dispatch0_return_o,
  output head1_return_candidate_o
);

  wire head0_jal_call_rd_w = (head0_rd_i == 5'd1) || (head0_rd_i == 5'd5);
  wire head1_jal_call_rd_w = (head1_rd_i == 5'd1) || (head1_rd_i == 5'd5);
  wire head0_return_hint_w =
      (head0_rd_i == {`REG_ADDR_W{1'b0}}) &&
      ((head0_rs1_i == 5'd1) || (head0_rs1_i == 5'd5)) &&
      (head0_imm_i == {`XLEN{1'b0}});
  wire head1_return_hint_w =
      (head1_rd_i == {`REG_ADDR_W{1'b0}}) &&
      ((head1_rs1_i == 5'd1) || (head1_rs1_i == 5'd5)) &&
      (head1_imm_i == {`XLEN{1'b0}});
  wire ras_direct_ret_ready_w =
      ENABLE_DIRECT_RAS_RET &&
      ras_direct_update_safe_o &&
      ras_reliable_i &&
      !ras_empty_i;

  assign head0_jal_call_raw_o = head0_jal_raw_i && head0_jal_call_rd_w;
  assign head1_jal_call_raw_o = head1_jal_raw_i && head1_jal_call_rd_w;
  assign ras_direct_update_safe_o =
      (rob_count_i == {ROB_COUNT_W{1'b0}}) &&
      !stop_pending_i &&
      !branch_spec_active_i &&
      !branch_spec_checkpoint_pending_i;
  assign dispatch0_return_o =
      ras_direct_ret_ready_w &&
      dispatch0_jump_i &&
      head0_return_hint_w;
  assign head1_return_candidate_o =
      ras_direct_ret_ready_w &&
      head1_jalr_raw_i &&
      head1_return_hint_w;

endmodule
