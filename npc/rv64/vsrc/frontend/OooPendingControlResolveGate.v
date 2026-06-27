`include "include/define.v"

module OooPendingControlResolveGate (
  input pending_branch_i,
  input pending_branch_taken_i,
  input [`XLEN-1:0] pending_branch_target_i,
  input [`XLEN-1:0] pending_branch_next_pc_i,
  input stop_pending_i,
  input pending_jump_i,
  input pending_jump_jalr_i,
  input pending_jump_dispatched_i,
  input backend_drained_i,
  input [`XLEN-1:0] pending_jump_pc_i,
  input [`XLEN-1:0] pending_jump_imm_i,
  input [`XLEN-1:0] pending_jump_rs1_data_i,
  input [`INST_W-1:0] pending_jump_inst_i,
  input [`REG_ADDR_W-1:0] pending_jump_rs1_i,
  input ras_empty_i,
  input jump_dispatch_fire_i,
  input commit_ready_i,
  output [`XLEN-1:0] pending_branch_fallthrough_o,
  output [`XLEN-1:0] pending_branch_next_pc_o,
  output pending_branch_misaligned_o,
  output pending_jump_jalr_sum_lsb_o,
  output [`XLEN-1:0] pending_jump_resolved_target_o,
  output pending_jump_misaligned_o,
  output pending_jump_resolve_ready_o,
  output pending_jump_return_o,
  output pending_jump_return_fire_o,
  output pending_jump_call_o,
  output pending_jump_call_fire_o,
  output pending_jump_nolink_o,
  output pending_jump_nolink_commit_o,
  output pending_jump_redirect_after_dispatch_o,
  output pending_control_ready_o
);
  wire [`XLEN-1:0] pending_jump_jal_target_w =
      pending_jump_pc_i + pending_jump_imm_i;
  wire [`XLEN-1:0] pending_jump_jalr_sum_w =
      pending_jump_rs1_data_i + pending_jump_imm_i;
  wire [`REG_ADDR_W-1:0] pending_jump_rd_w = pending_jump_inst_i[11:7];

  assign pending_branch_fallthrough_o = pending_branch_next_pc_i;
  assign pending_branch_next_pc_o =
      pending_branch_taken_i ? pending_branch_target_i :
                               pending_branch_fallthrough_o;
  assign pending_branch_misaligned_o =
      pending_branch_taken_i && pending_branch_target_i[0];

  assign pending_jump_jalr_sum_lsb_o = pending_jump_jalr_sum_w[0];
  assign pending_jump_resolved_target_o =
      pending_jump_jalr_i ? {pending_jump_jalr_sum_w[`XLEN-1:1], 1'b0} :
                            pending_jump_jal_target_w;
  assign pending_jump_misaligned_o = pending_jump_resolved_target_o[0];
  assign pending_jump_resolve_ready_o =
      stop_pending_i && pending_jump_i &&
      !pending_jump_dispatched_i && backend_drained_i;

  assign pending_jump_return_o =
      pending_jump_i && pending_jump_jalr_i && !ras_empty_i &&
      (pending_jump_rd_w == 5'd0) &&
      ((pending_jump_rs1_i == 5'd1) || (pending_jump_rs1_i == 5'd5)) &&
      (pending_jump_imm_i == {`XLEN{1'b0}});
  assign pending_jump_return_fire_o =
      pending_jump_return_o && pending_jump_resolve_ready_o &&
      jump_dispatch_fire_i && !pending_jump_misaligned_o;

  assign pending_jump_call_o =
      pending_jump_i &&
      ((pending_jump_rd_w == 5'd1) || (pending_jump_rd_w == 5'd5));
  assign pending_jump_call_fire_o =
      pending_jump_call_o && pending_jump_resolve_ready_o &&
      jump_dispatch_fire_i && !pending_jump_misaligned_o;

  assign pending_jump_nolink_o =
      pending_jump_i && pending_jump_jalr_i && !pending_jump_return_o &&
      (pending_jump_rd_w == 5'd0);
  assign pending_jump_nolink_commit_o =
      pending_jump_nolink_o && pending_jump_resolve_ready_o &&
      !pending_jump_misaligned_o && commit_ready_i;
  assign pending_jump_redirect_after_dispatch_o =
      pending_jump_resolve_ready_o && !pending_jump_misaligned_o &&
      !pending_jump_nolink_o && jump_dispatch_fire_i;
  assign pending_control_ready_o = !pending_branch_i || commit_ready_i;
endmodule
