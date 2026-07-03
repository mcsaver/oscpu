`include "define.v"

// stop-pending 之后的 drain/resolve 事件归 control 中枢，core glue 只转接事件。
module OooPendingDrainResolveGate #(
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W
)(
  input [ROB_COUNT_W-1:0] rob_count_i,
  input [ISSUE_COUNT_W-1:0] issue_count_i,
  input [1:0] core_retire_count_i,
  input synth_lane1_ret_pending_i,
  input synth_lane1_branch_drop_pending_i,
  input direct_frontend_flush_i,
  input stop_pending_i,
  input backend_drained_q_i,
  input pending_control_ready_i,
  input dispatch0_ready_i,
  input branch_resolve_pending_match_i,
  input branch_spec_active_i,
  input branch_spec_checkpoint_pending_i,
  input pending_arch_trap_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input pending_jump_i,
  input pending_jump_dispatched_i,
  input pending_jump_resolve_ready_i,
  input pending_jump_nolink_i,
  input pending_jump_misaligned_i,
  input pending_mem_i,
  input pending_mem_dispatched_i,
  // 【LSQ·SQ 切换】退休侧访存静默: SQ 化后 ROB 空不再隐含"store 已全部落存"
  // (退休 store 可能仍在 SQ 待 drain), 串行点必须等它。
  input mem_retire_quiet_i,
  input pending_system_i,
  input pending_system_csr_i,
  input pending_system_dispatched_i,
  output backend_drained_o,
  output jump_dispatch_valid_o,
  output system_csr_dispatch_valid_o,
  output system_csr_dispatch_fire_o,
  output pending_mem_resolve_ready_o,
  output mem_dispatch_valid_o,
  output pending_branch_commit_resolve_o,
  output pending_branch_match_clear_o,
  output pending_replay_wait_o,
  output drain_complete_o
);

  wire pending_branch_resolve_wait_w =
      pending_branch_i && pending_branch_dispatched_i &&
      !branch_resolve_pending_match_i && !pending_branch_commit_resolve_o;

  assign backend_drained_o = (rob_count_i == {ROB_COUNT_W{1'b0}}) &&
                             (issue_count_i == {ISSUE_COUNT_W{1'b0}}) &&
                             (core_retire_count_i == 2'b00) &&
                             !synth_lane1_ret_pending_i &&
                             !synth_lane1_branch_drop_pending_i &&
                             mem_retire_quiet_i;

  assign jump_dispatch_valid_o = pending_jump_resolve_ready_i &&
                                 !pending_jump_nolink_i &&
                                 !pending_jump_misaligned_i;
  assign system_csr_dispatch_valid_o =
      stop_pending_i && pending_system_i && pending_system_csr_i &&
      !pending_system_dispatched_i && backend_drained_q_i;
  assign system_csr_dispatch_fire_o =
      system_csr_dispatch_valid_o && dispatch0_ready_i;

  assign pending_mem_resolve_ready_o =
      stop_pending_i && pending_mem_i && !pending_mem_dispatched_i &&
      backend_drained_q_i;
  assign mem_dispatch_valid_o = pending_mem_resolve_ready_o;

  assign pending_branch_commit_resolve_o =
      !direct_frontend_flush_i && stop_pending_i && backend_drained_o &&
      pending_branch_i && pending_branch_dispatched_i &&
      !branch_resolve_pending_match_i && !branch_spec_active_i &&
      !branch_spec_checkpoint_pending_i && !pending_jump_i &&
      !pending_mem_i && !pending_arch_trap_i &&
      !pending_system_i;
  assign pending_branch_match_clear_o =
      !direct_frontend_flush_i && stop_pending_i && pending_branch_i &&
      pending_branch_dispatched_i && branch_resolve_pending_match_i &&
      !branch_spec_active_i;

  assign pending_replay_wait_o =
      pending_branch_resolve_wait_w ||
      (pending_jump_i && !pending_jump_dispatched_i) ||
      (pending_mem_i && !pending_mem_dispatched_i) ||
      (pending_system_i && pending_system_csr_i);
  assign drain_complete_o =
      stop_pending_i && backend_drained_o && pending_control_ready_i &&
      !pending_replay_wait_o;

endmodule
