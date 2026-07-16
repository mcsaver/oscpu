// Encodes redirect/recovery events into a fetch-packet FIFO clear action.
//
// T3V physically removes the packet-seed dataplane.  Every former set-seed
// owner is structurally unreachable in the production ROB-walk architecture
// (fallthrough append, branch-prefetch hit and JALR-prefetch hit are disabled).
// Keeping the payload mux behind module boundaries nevertheless left real
// cells and a seed mux on every FIFO D input.  If one of those legacy control
// combinations is ever observed, clearing and refetching is the safe fallback.
module OooFetchPacketSeedMux (
  input csr_trap_i,
  input direct_flush_i,
  input branch_spec_restore_i,
  input pending_branch_commit_resolve_i,
  input pending_branch_match_i,
  input branch_resolve_untracked_i,
  input pending_jump_resolve_i,
  input pending_jump_misaligned_i,
  input pending_jump_redirect_i,
  input pending_mem_resolve_i,
  input system_csr_dispatch_i,
  input pending_system_csr_commit_i,
  input head0_csr_commit_i,
  input drain_complete_i,
  input drain_pending_arch_trap_i,
  input drain_pending_system_i,
  input drain_pending_branch_undispatched_i,
  input drain_pending_jump_i,
  input drain_pending_mem_i,

  output reg clear_o
);

  always @* begin
    clear_o = 1'b0;

    if (csr_trap_i) begin
      clear_o = 1'b1;
    end else if (direct_flush_i) begin
      // The old fallthrough-capture seed arm is unreachable.  A direct flush
      // now always invalidates resident packets and refetches the redirect PC.
      clear_o = 1'b1;
    end

    if (!direct_flush_i && branch_spec_restore_i)
      clear_o = 1'b1;

    if (pending_branch_commit_resolve_i) begin
      clear_o = 1'b1;
    end else if (!direct_flush_i && pending_branch_match_i) begin
      // Covers both the old misaligned clear and dead prefetch-hit seed arms.
      clear_o = 1'b1;
    end else if (!direct_flush_i && branch_resolve_untracked_i) begin
      clear_o = 1'b1;
    end else if (!direct_flush_i && pending_jump_resolve_i) begin
      if (pending_jump_misaligned_i || pending_jump_redirect_i)
        clear_o = 1'b1;
    end else if (!direct_flush_i && pending_mem_resolve_i) begin
      // LSU replay dispatch does not change frontend FIFO storage.
    end else if (!direct_flush_i && system_csr_dispatch_i) begin
      // CSR dispatch waits for commit before clearing the frontend FIFO.
    end else if (!direct_flush_i &&
                 (pending_system_csr_commit_i || head0_csr_commit_i)) begin
      clear_o = 1'b1;
    end else if (!csr_trap_i && !direct_flush_i && drain_complete_i) begin
      if (drain_pending_arch_trap_i ||
          drain_pending_system_i ||
          drain_pending_branch_undispatched_i ||
          drain_pending_jump_i ||
          drain_pending_mem_i)
        clear_o = 1'b1;
    end

    // Precise trap is the final priority owner, matching the original encoder.
    if (csr_trap_i)
      clear_o = 1'b1;
  end

endmodule
