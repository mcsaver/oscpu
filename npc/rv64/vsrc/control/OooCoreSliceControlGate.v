// core slice 的 flush/checkpoint/commit 准入由 control 统一裁决。
module OooCoreSliceControlGate (
  input flush_i,
  input core_trap_flush_i,
  input core_serial_flush_i,
  input commit_ready_i,
  input branch_spec_checkpoint_capture_i,
  input branch_spec_restore_i,
  input branch_spec_checkpoint_pending_i,
  input branch_spec_active_i,
  input ctrl_commit_valid_i,
  input synth_lane1_ret_pending_i,
  input synth_lane1_branch_drop_match_i,
  input synth_lane1_ret_branch_seen_i,
  input synth_lane1_ret_branch_commit0_i,

  output core_checkpoint_capture_o,
  output core_checkpoint_restore_o,
  output core_checkpoint_quiesce_o,
  output core_mem_issue_block_o,
  output core_local_flush_o,
  output core_commit_ready_o,
  output core_commit1_block_o
);

  assign core_checkpoint_capture_o = branch_spec_checkpoint_capture_i;
  assign core_checkpoint_restore_o = branch_spec_restore_i;
  assign core_checkpoint_quiesce_o =
      branch_spec_checkpoint_pending_i && !core_checkpoint_capture_o;
  assign core_mem_issue_block_o = branch_spec_active_i;

  assign core_local_flush_o =
      flush_i || core_trap_flush_i || core_serial_flush_i;
  assign core_commit_ready_o =
      commit_ready_i && !core_trap_flush_i && !core_serial_flush_i &&
      !branch_spec_checkpoint_pending_i && !branch_spec_active_i &&
      !core_checkpoint_restore_o;
  assign core_commit1_block_o =
      !ctrl_commit_valid_i && synth_lane1_ret_pending_i &&
      !synth_lane1_branch_drop_match_i &&
      (synth_lane1_ret_branch_seen_i || synth_lane1_ret_branch_commit0_i);

endmodule
