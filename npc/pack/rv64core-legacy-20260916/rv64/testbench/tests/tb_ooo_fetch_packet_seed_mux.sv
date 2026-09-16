`include "tb_common.svh"

module tb_ooo_fetch_packet_seed_mux;
  reg csr_trap;
  reg direct_flush;
  reg branch_spec_restore;
  reg pending_branch_commit_resolve;
  reg pending_branch_match;
  reg branch_resolve_untracked;
  reg pending_jump_resolve;
  reg pending_jump_misaligned;
  reg pending_jump_redirect;
  reg pending_mem_resolve;
  reg system_csr_dispatch;
  reg pending_system_csr_commit;
  reg head0_csr_commit;
  reg drain_complete;
  reg drain_pending_arch_trap;
  reg drain_pending_system;
  reg drain_pending_branch_undispatched;
  reg drain_pending_jump;
  reg drain_pending_mem;
  wire clear;

  OooFetchPacketSeedMux dut (
    .csr_trap_i(csr_trap),
    .direct_flush_i(direct_flush),
    .branch_spec_restore_i(branch_spec_restore),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .pending_branch_match_i(pending_branch_match),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_i(pending_jump_resolve),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .pending_jump_redirect_i(pending_jump_redirect),
    .pending_mem_resolve_i(pending_mem_resolve),
    .system_csr_dispatch_i(system_csr_dispatch),
    .pending_system_csr_commit_i(pending_system_csr_commit),
    .head0_csr_commit_i(head0_csr_commit),
    .drain_complete_i(drain_complete),
    .drain_pending_arch_trap_i(drain_pending_arch_trap),
    .drain_pending_system_i(drain_pending_system),
    .drain_pending_branch_undispatched_i(
        drain_pending_branch_undispatched),
    .drain_pending_jump_i(drain_pending_jump),
    .drain_pending_mem_i(drain_pending_mem),
    .clear_o(clear)
  );

  task automatic reset_inputs;
    begin
      csr_trap = 1'b0;
      direct_flush = 1'b0;
      branch_spec_restore = 1'b0;
      pending_branch_commit_resolve = 1'b0;
      pending_branch_match = 1'b0;
      branch_resolve_untracked = 1'b0;
      pending_jump_resolve = 1'b0;
      pending_jump_misaligned = 1'b0;
      pending_jump_redirect = 1'b0;
      pending_mem_resolve = 1'b0;
      system_csr_dispatch = 1'b0;
      pending_system_csr_commit = 1'b0;
      head0_csr_commit = 1'b0;
      drain_complete = 1'b0;
      drain_pending_arch_trap = 1'b0;
      drain_pending_system = 1'b0;
      drain_pending_branch_undispatched = 1'b0;
      drain_pending_jump = 1'b0;
      drain_pending_mem = 1'b0;
      #1;
    end
  endtask

  task automatic expect_clear;
    input [1023:0] tag;
    input expected;
    begin
      #1;
      tb_check1(tag, clear, expected);
    end
  endtask

  initial begin
    tb_errors = 0;

    reset_inputs();
    expect_clear("idle keeps FIFO", 1'b0);

    reset_inputs(); csr_trap = 1'b1;
    expect_clear("precise trap clears", 1'b1);

    reset_inputs(); direct_flush = 1'b1;
    expect_clear("direct flush clears and refetches", 1'b1);

    reset_inputs(); branch_spec_restore = 1'b1;
    expect_clear("branch restore clears", 1'b1);

    reset_inputs(); pending_branch_commit_resolve = 1'b1;
    expect_clear("branch commit resolve clears", 1'b1);

    reset_inputs(); pending_branch_match = 1'b1;
    expect_clear("branch match clears dead seed fallback", 1'b1);

    reset_inputs(); branch_resolve_untracked = 1'b1;
    expect_clear("untracked branch clears", 1'b1);

    reset_inputs(); pending_jump_resolve = 1'b1;
    expect_clear("resolved jump without redirect is no-op", 1'b0);
    pending_jump_misaligned = 1'b1;
    expect_clear("misaligned jump clears", 1'b1);

    reset_inputs(); pending_jump_resolve = 1'b1;
    pending_jump_redirect = 1'b1;
    expect_clear("redirecting jump clears dead seed fallback", 1'b1);

    // Preserve the original priority skeleton: replay/system-dispatch no-op
    // owners suppress later commit/drain actions in the same decision.
    reset_inputs(); pending_mem_resolve = 1'b1;
    pending_system_csr_commit = 1'b1;
    expect_clear("memory replay suppresses later clear", 1'b0);

    reset_inputs(); system_csr_dispatch = 1'b1;
    head0_csr_commit = 1'b1;
    expect_clear("CSR dispatch suppresses later commit clear", 1'b0);

    reset_inputs(); pending_system_csr_commit = 1'b1;
    expect_clear("pending CSR commit clears", 1'b1);

    reset_inputs(); head0_csr_commit = 1'b1;
    expect_clear("queue-head CSR commit clears", 1'b1);

    reset_inputs(); drain_complete = 1'b1;
    expect_clear("ownerless drain completion is no-op", 1'b0);
    drain_pending_arch_trap = 1'b1;
    expect_clear("drained arch trap clears", 1'b1);

    reset_inputs(); drain_complete = 1'b1;
    drain_pending_jump = 1'b1;
    expect_clear("drained jump clears dead seed fallback", 1'b1);

    reset_inputs(); pending_mem_resolve = 1'b1; csr_trap = 1'b1;
    expect_clear("precise trap final priority wins", 1'b1);

    tb_finish("tb_ooo_fetch_packet_seed_mux");
  end

endmodule
