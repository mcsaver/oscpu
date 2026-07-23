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

  assign system_csr_admission_clear_o =
      csr_trap_mem_valid_i ||
      branch_spec_resolve_valid_i ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      branch_resolve_untracked_i ||
      pending_jump_clear_w ||
      pending_system_csr_commit_i ||
      head0_csr_commit_i;

  assign system_csr_dispatch_cancel_o =
      rst_i || core_local_flush_i || system_csr_admission_clear_o;

endmodule
/* verilator lint_on TIMESCALEMOD */
