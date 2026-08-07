// Feedback-free cancellation policy for pending-system CSR ROB admission.
//
// Deliberately has no direct_frontend_flush or backend-ready input.  The
// pending-system owner already makes frontend direct fire unreachable; feeding
// that derived event back here would create an admission/ready combinational
// cycle.  Every level input below is either a real clear witness or is qualified
// into one before it gains cancellation authority.
/* verilator lint_off TIMESCALEMOD */
module OooPendingSystemAdmissionCancelGate (
  input rst_i,
  input core_local_flush_i,
  input csr_trap_mem_valid_i,
  input branch_spec_resolve_valid_i,
  input pending_branch_commit_resolve_i,
  input pending_branch_match_clear_i,
  input branch_resolve_untracked_i,
  input pending_jump_resolve_ready_i,
  input pending_jump_misaligned_i,
  input pending_jump_nolink_commit_i,
  input pending_jump_redirect_after_dispatch_i,
  input pending_system_csr_commit_i,
  input head0_csr_commit_i,
  output system_csr_admission_clear_o,
  output system_csr_dispatch_cancel_o
);

  wire pending_jump_clear_w =
      pending_jump_resolve_ready_i &&
      (pending_jump_misaligned_i ||
       pending_jump_nolink_commit_i ||
       pending_jump_redirect_after_dispatch_i);

  // branch-owner terminal 由 direct frontend action 后置屏蔽，属于完整 clear
  // 观测而不是 admission 权限。若把它们反喂 cancel，会重新形成
  // system-valid -> backend-ready -> direct-fire -> branch-terminal -> valid
  // 的组合环；真正的 cancel 只消费下列单向见证。
  wire feedback_free_dispatch_clear_w =
      csr_trap_mem_valid_i ||
      branch_spec_resolve_valid_i ||
      branch_resolve_untracked_i ||
      pending_jump_clear_w ||
      pending_system_csr_commit_i ||
      head0_csr_commit_i;

  assign system_csr_admission_clear_o =
      feedback_free_dispatch_clear_w ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i;

  assign system_csr_dispatch_cancel_o =
      rst_i || core_local_flush_i || feedback_free_dispatch_clear_w;

endmodule
/* verilator lint_on TIMESCALEMOD */
