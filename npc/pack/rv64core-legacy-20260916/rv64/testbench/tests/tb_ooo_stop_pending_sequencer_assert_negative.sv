`timescale 1ns/1ps
`include "define.v"

module tb_ooo_stop_pending_sequencer_assert_negative;
  reg clk;
  reg rst;
  reg pending_owner_birth;
  reg pending_owner_live;
  reg pending_system_producer_valid;
  reg head0_csr_inflight;
  reg head0_csr_owner_birth;
  reg head0_csr_owner_kill;
  wire stop_pending;

  OooStopPendingSequencer dut (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .csr_trap_mem_valid_i(1'b0),
    .direct_frontend_flush_i(1'b0),
    .direct_branch0_fire_i(1'b0),
    .direct_branch1_fire_i(1'b0),
    .direct_branch_resolve_redirect_i(1'b0),
    .branch_spec_checkpoint_capture_i(1'b0),
    .branch_spec_resolve_valid_i(1'b0),
    .orphan_stop_pending_i(1'b0),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(1'b0),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_nolink_commit_i(1'b0),
    .pending_jump_redirect_after_dispatch_i(1'b0),
    .jump_dispatch_fire_i(1'b0),
    .pending_mem_resolve_ready_i(1'b0),
    .system_csr_dispatch_fire_i(1'b0),
    .pending_system_csr_commit_i(1'b0),
    .head0_csr_commit_i(1'b0),
    .head0_csr_inflight_i(head0_csr_inflight),
    .head0_csr_owner_birth_i(head0_csr_owner_birth),
    .head0_csr_owner_kill_i(head0_csr_owner_kill),
    .pending_owner_birth_i(pending_owner_birth),
    .pending_owner_live_i(pending_owner_live),
    .pending_system_producer_valid_i(pending_system_producer_valid),
    .core_local_flush_i(1'b0),
    .drain_complete_i(1'b0),
    .rob_walk_mode_i(1'b1),
    .stop_pending_o(stop_pending)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    rst = 1'b1;
    pending_owner_birth = 1'b0;
    pending_owner_live = 1'b0;
    pending_system_producer_valid = 1'b0;
    head0_csr_inflight = 1'b0;
    head0_csr_owner_birth = 1'b0;
    head0_csr_owner_kill = 1'b0;
    repeat (2) tick();
    rst = 1'b0;

    if ($test$plusargs("V9X_NEG_BIRTH")) begin
      pending_owner_birth = 1'b1;
      pending_owner_live = 1'b1;
      tick();
      pending_owner_birth = 1'b0;
      force dut.accepted_owner_birth_prev_q = 1'b0;
      tick();
      $fatal(1, "V9X_NEG_BIRTH did not trigger");
    end else if ($test$plusargs("V9X_NEG_LEASE")) begin
      pending_system_producer_valid = 1'b1;
      tick();
      $fatal(1, "V9X_NEG_LEASE did not trigger");
    end else if ($test$plusargs("V9X_NEG_QCSR")) begin
      head0_csr_inflight = 1'b1;
      tick();
      $fatal(1, "V9X_NEG_QCSR did not trigger");
    end else if ($test$plusargs("V9X_NEG_LIVE")) begin
      pending_owner_birth = 1'b1;
      pending_owner_live = 1'b1;
      tick();
      pending_owner_birth = 1'b0;
      pending_owner_live = 1'b0;
      tick();
      $fatal(1, "V9X_NEG_LIVE did not trigger");
    end

    $fatal(1, "missing V9X negative case plusarg");
  end
endmodule
