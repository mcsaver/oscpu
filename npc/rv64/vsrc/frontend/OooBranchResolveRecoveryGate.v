`include "include/define.v"

module OooBranchResolveRecoveryGate (
  input stop_pending_i,
  input pending_branch_i,
  input pending_branch_dispatched_i,
  input [`XLEN-1:0] pending_branch_pc_i,
  input branch_prefetch_match_i,
  input core_branch_resolve_valid_i,
  input [`XLEN-1:0] core_branch_resolve_pc_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,
  input core_branch_resolve_misaligned_i,
  input trap_redirect_squash_i,
  input execute0_valid_i,
  input execute1_valid_i,
  input mem_rsp_ready_i,
  input mem1_rsp_ready_i,
  input branch_spec_checkpoint_pending_i,
  input branch_spec_active_i,
  input [`XLEN-1:0] branch_spec_pred_pc_i,
  input core_mem_idle_i,
  input core_pending_load_branch_dep_i,
  input direct_branch_wait_pending_i,
  input [`XLEN-1:0] direct_branch_wait_pc_i,
  input direct_branch_resolve_valid_i,
  output branch_resolve_pending_pc_match_o,
  output branch_resolve_pending_match_o,
  output branch_resolve_redirect_o,
  output backend_execute_quiet_o,
  output branch_spec_checkpoint_capture_o,
  output branch_spec_resolve_valid_o,
  output branch_spec_pred_match_o,
  output branch_spec_restore_o,
  output branch_spec_redirect_o,
  output direct_branch_wait_resolve_match_o,
  output direct_branch_wait_untracked_o,
  output branch_resolve_untracked_o,
  output branch_resolve_untracked_redirect_o
);
  wire branch_resolve_redirect_raw_w =
      stop_pending_i && pending_branch_i &&
      pending_branch_dispatched_i &&
      branch_resolve_pending_match_o &&
      !core_branch_resolve_misaligned_i &&
      !branch_prefetch_match_i;

  wire branch_spec_redirect_raw_w =
      branch_spec_restore_o && !core_branch_resolve_misaligned_i;

  wire branch_resolve_untracked_raw_w =
      (direct_branch_wait_untracked_o ||
       (core_branch_resolve_valid_i &&
        !stop_pending_i &&
        !branch_resolve_pending_pc_match_o &&
        !direct_branch_resolve_valid_i)) &&
      !branch_spec_resolve_valid_o;

  assign branch_resolve_pending_pc_match_o =
      core_branch_resolve_valid_i &&
      (core_branch_resolve_pc_i == pending_branch_pc_i);
  assign branch_resolve_pending_match_o =
      stop_pending_i && pending_branch_i && pending_branch_dispatched_i &&
      branch_resolve_pending_pc_match_o;
  assign branch_resolve_redirect_o =
      branch_resolve_redirect_raw_w && !trap_redirect_squash_i;
  assign backend_execute_quiet_o =
      !execute0_valid_i && !execute1_valid_i &&
      !mem_rsp_ready_i && !mem1_rsp_ready_i;
  assign branch_spec_checkpoint_capture_o =
      branch_spec_checkpoint_pending_i && stop_pending_i &&
      pending_branch_i && pending_branch_dispatched_i &&
      backend_execute_quiet_o &&
      (core_mem_idle_i || core_pending_load_branch_dep_i);
  assign branch_spec_resolve_valid_o =
      branch_spec_active_i && pending_branch_i &&
      pending_branch_dispatched_i && branch_resolve_pending_pc_match_o;
  assign branch_spec_pred_match_o =
      !core_branch_resolve_misaligned_i &&
      (core_branch_resolve_next_pc_i == branch_spec_pred_pc_i);
  assign branch_spec_restore_o =
      branch_spec_resolve_valid_o && !branch_spec_pred_match_o;
  assign branch_spec_redirect_o =
      branch_spec_redirect_raw_w && !trap_redirect_squash_i;
  assign direct_branch_wait_resolve_match_o =
      direct_branch_wait_pending_i && core_branch_resolve_valid_i &&
      (core_branch_resolve_pc_i == direct_branch_wait_pc_i);
  assign direct_branch_wait_untracked_o =
      direct_branch_wait_resolve_match_o &&
      !branch_resolve_pending_match_o &&
      !direct_branch_resolve_valid_i;
  assign branch_resolve_untracked_o =
      branch_resolve_untracked_raw_w && !trap_redirect_squash_i;
  assign branch_resolve_untracked_redirect_o =
      branch_resolve_untracked_o && !core_branch_resolve_misaligned_i;
endmodule
