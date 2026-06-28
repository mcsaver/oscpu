`include "define.v"

// Branch prefetch 的清空条件属于 frontend 投机队列边界，core glue 只消费结果。
module OooBranchPrefetchClearGate(
  input csr_trap_mem_valid_i,
  input direct_frontend_flush_i,
  input branch_spec_resolve_valid_i,
  input pending_branch_commit_resolve_i,
  input pending_branch_match_clear_i,
  input branch_resolve_untracked_i,
  input pending_jump_resolve_ready_i,
  input pending_jump_misaligned_i,
  input pending_jump_nolink_commit_i,
  input pending_jump_redirect_after_dispatch_i,
  input pending_system_csr_commit_i,
  input stop_pending_i,
  input drain_complete_i,
  input pending_arch_trap_i,
  input pending_system_i,
  input pending_jump_i,
  input pending_fp_i,
  output clear_o
);

  assign clear_o =
      csr_trap_mem_valid_i ||
      direct_frontend_flush_i ||
      (!direct_frontend_flush_i && branch_spec_resolve_valid_i) ||
      pending_branch_commit_resolve_i ||
      pending_branch_match_clear_i ||
      (!direct_frontend_flush_i && branch_resolve_untracked_i) ||
      (!direct_frontend_flush_i && pending_jump_resolve_ready_i &&
       (pending_jump_misaligned_i || pending_jump_nolink_commit_i ||
        pending_jump_redirect_after_dispatch_i)) ||
      (!direct_frontend_flush_i && pending_system_csr_commit_i) ||
      (!csr_trap_mem_valid_i && !direct_frontend_flush_i && stop_pending_i &&
       drain_complete_i &&
       (pending_arch_trap_i || pending_system_i || pending_jump_i ||
        pending_fp_i));

endmodule
