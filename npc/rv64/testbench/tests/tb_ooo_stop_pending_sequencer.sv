`timescale 1ns/1ps
`include "define.v"

module tb_ooo_stop_pending_sequencer;
  reg clk;
  reg rst;
  reg flush;
  reg csr_trap_mem_valid;
  reg direct_frontend_flush;
  reg direct_branch0_fire;
  reg direct_branch1_fire;
  reg direct_branch_resolve_redirect;
  reg branch_spec_checkpoint_capture;
  reg branch_spec_resolve_valid;
  reg orphan_stop_pending;
  reg pending_branch_commit_resolve;
  reg pending_branch_match_clear;
  reg branch_resolve_untracked;
  reg pending_jump_resolve_ready;
  reg pending_jump_misaligned;
  reg pending_jump_nolink_commit;
  reg pending_jump_redirect_after_dispatch;
  reg jump_dispatch_fire;
  reg pending_mem_resolve_ready;
  reg system_csr_dispatch_fire;
  reg pending_system_csr_commit;
  reg head0_csr_commit;
  reg head0_csr_inflight;
  reg head0_csr_owner_birth;
  reg head0_csr_owner_kill;
  reg pending_owner_birth;
  reg pending_owner_live;
  reg pending_system_producer_valid;
  reg core_local_flush;
  reg drain_complete;
  reg can_run;
  reg fifo_has_packet;
  reg csr_irq_pending;
  reg head_fetch_fault0;
  reg dispatch0_arch_trap;
  reg dispatch0_exit;
  reg dispatch0_fp;
  reg dispatch0_system;
  reg head0_csr_illegal;
  reg dispatch0_branch;
  reg direct_branch0_dispatch_valid;
  reg dispatch0_jal;
  reg direct_jal0_dispatch_valid;
  reg dispatch0_jump;
  reg dispatch0_return;
  reg dispatch1_barrier_fire;
  reg dispatch_unsupported;
  reg rob_walk_mode;

  wire stop_pending;

  integer errors;

  OooStopPendingSequencer dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .csr_trap_mem_valid_i(csr_trap_mem_valid),
    .direct_frontend_flush_i(direct_frontend_flush),
    .direct_branch0_fire_i(direct_branch0_fire),
    .direct_branch1_fire_i(direct_branch1_fire),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect),
    .branch_spec_checkpoint_capture_i(branch_spec_checkpoint_capture),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid),
    .orphan_stop_pending_i(orphan_stop_pending),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve),
    .pending_branch_match_clear_i(pending_branch_match_clear),
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready),
    .pending_jump_misaligned_i(pending_jump_misaligned),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit),
    .pending_jump_redirect_after_dispatch_i(pending_jump_redirect_after_dispatch),
    .jump_dispatch_fire_i(jump_dispatch_fire),
    .pending_mem_resolve_ready_i(pending_mem_resolve_ready),
    .system_csr_dispatch_fire_i(system_csr_dispatch_fire),
    .pending_system_csr_commit_i(pending_system_csr_commit),
    .head0_csr_commit_i(head0_csr_commit),
    .head0_csr_inflight_i(head0_csr_inflight),
    .head0_csr_owner_birth_i(head0_csr_owner_birth),
    .head0_csr_owner_kill_i(head0_csr_owner_kill),
    .pending_owner_birth_i(pending_owner_birth),
    .pending_owner_live_i(pending_owner_live),
    .pending_system_producer_valid_i(pending_system_producer_valid),
    .core_local_flush_i(core_local_flush),
    .drain_complete_i(drain_complete),
    .rob_walk_mode_i(rob_walk_mode),
    .stop_pending_o(stop_pending)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tb_check1;
    input [255:0] name;
    input actual;
    input expected;
    begin
      if (actual !== expected) begin
        $display("FAIL %0s actual=%0b expected=%0b", name, actual, expected);
        errors = errors + 1;
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      flush = 1'b0;
      csr_trap_mem_valid = 1'b0;
      direct_frontend_flush = 1'b0;
      direct_branch0_fire = 1'b0;
      direct_branch1_fire = 1'b0;
      direct_branch_resolve_redirect = 1'b0;
      branch_spec_checkpoint_capture = 1'b0;
      branch_spec_resolve_valid = 1'b0;
      orphan_stop_pending = 1'b0;
      pending_branch_commit_resolve = 1'b0;
      pending_branch_match_clear = 1'b0;
      branch_resolve_untracked = 1'b0;
      pending_jump_resolve_ready = 1'b0;
      pending_jump_misaligned = 1'b0;
      pending_jump_nolink_commit = 1'b0;
      pending_jump_redirect_after_dispatch = 1'b0;
      jump_dispatch_fire = 1'b0;
      pending_mem_resolve_ready = 1'b0;
      system_csr_dispatch_fire = 1'b0;
      pending_system_csr_commit = 1'b0;
      head0_csr_commit = 1'b0;
      head0_csr_inflight = 1'b0;
      head0_csr_owner_birth = 1'b0;
      head0_csr_owner_kill = 1'b0;
      pending_owner_birth = 1'b0;
      pending_owner_live = 1'b0;
      pending_system_producer_valid = 1'b0;
      core_local_flush = 1'b0;
      drain_complete = 1'b0;
      can_run = 1'b0;
      fifo_has_packet = 1'b0;
      csr_irq_pending = 1'b0;
      head_fetch_fault0 = 1'b0;
      dispatch0_arch_trap = 1'b0;
      dispatch0_exit = 1'b0;
      dispatch0_fp = 1'b0;
      dispatch0_system = 1'b0;
      head0_csr_illegal = 1'b0;
      dispatch0_branch = 1'b0;
      direct_branch0_dispatch_valid = 1'b0;
      dispatch0_jal = 1'b0;
      direct_jal0_dispatch_valid = 1'b0;
      dispatch0_jump = 1'b0;
      dispatch0_return = 1'b0;
      dispatch1_barrier_fire = 1'b0;
      dispatch_unsupported = 1'b0;
      rob_walk_mode = 1'b0;
    end
  endtask

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic expect_stop;
    input [255:0] name;
    input expected;
    begin
      tb_check1(name, stop_pending, expected);
    end
  endtask

  task automatic set_from_irq;
    begin
      clear_inputs();
      pending_owner_birth = 1'b1;
      tick();
      expect_stop("accepted pending owner birth sets stop", 1'b1);
    end
  endtask

  initial begin
    errors = 0;
    clear_inputs();
    rst = 1'b1;
    repeat (2) tick();
    rst = 1'b0;
    tick();
    expect_stop("reset clears", 1'b0);

    clear_inputs();
    direct_frontend_flush = 1'b1;
    direct_branch0_fire = 1'b1;
    direct_branch_resolve_redirect = 1'b0;
    tick();
    expect_stop("direct branch follows configured branch domain",
                `OOO_DBRANCH_DOMAIN_A ? 1'b0 : 1'b1);

    clear_inputs();
    direct_frontend_flush = 1'b1;
    direct_branch1_fire = 1'b1;
    direct_branch_resolve_redirect = 1'b1;
    tick();
    expect_stop("direct branch redirect clears", 1'b0);

    set_from_irq();
    clear_inputs();
    branch_spec_checkpoint_capture = 1'b1;
    tick();
    expect_stop("checkpoint clears", 1'b0);

    set_from_irq();
    clear_inputs();
    orphan_stop_pending = 1'b1;
    tick();
    expect_stop("orphan clears", 1'b0);

    set_from_irq();
    clear_inputs();
    pending_jump_resolve_ready = 1'b1;
    jump_dispatch_fire = 1'b1;
    tick();
    expect_stop("jump dispatch holds", 1'b1);
    clear_inputs();
    pending_jump_resolve_ready = 1'b1;
    pending_jump_misaligned = 1'b1;
    tick();
    expect_stop("jump misaligned clears", 1'b0);

    set_from_irq();
    clear_inputs();
    branch_spec_checkpoint_capture = 1'b1;
    pending_jump_resolve_ready = 1'b1;
    jump_dispatch_fire = 1'b1;
    tick();
    expect_stop("checkpoint clear survives jump hold", 1'b0);

    set_from_irq();
    clear_inputs();
    pending_mem_resolve_ready = 1'b1;
    tick();
    expect_stop("pending memory resolve holds", 1'b1);
    clear_inputs();
    pending_system_csr_commit = 1'b1;
    tick();
    expect_stop("csr commit clears", 1'b0);

    clear_inputs();
    head0_csr_owner_birth = 1'b1;
    tick();
    expect_stop("head0 csr accepted birth sets", 1'b1);
    clear_inputs();
    head0_csr_inflight = 1'b1;
    tick();
    expect_stop("head0 csr inflight holds", 1'b1);
    clear_inputs();
    head0_csr_commit = 1'b1;
    head0_csr_inflight = 1'b1;
    tick();
    expect_stop("head0 csr commit excludes inflight hold", 1'b0);

    clear_inputs();
    dispatch0_system = 1'b1;
    tick();
    expect_stop("queue-head csr visible without dispatch fire does not set",
                1'b0);

    clear_inputs();
    dispatch0_system = 1'b1;
    head0_csr_owner_kill = 1'b1;
    tick();
    expect_stop("queue-head csr killed birth does not set", 1'b0);

    clear_inputs();
    head0_csr_owner_birth = 1'b1;
    tick();
    expect_stop("queue-head csr rebirth sets", 1'b1);
    clear_inputs();
    head0_csr_inflight = 1'b1;
    tick();
    expect_stop("queue-head csr rebirth inflight holds", 1'b1);
    clear_inputs();
    head0_csr_inflight = 1'b1;
    core_local_flush = 1'b1;
    tick();
    expect_stop("queue-head csr C1 flush clears edge-old inflight", 1'b0);

    clear_inputs();
    pending_owner_birth = 1'b1;
    tick();
    expect_stop("pending csr pre-ROB birth sets", 1'b1);
    clear_inputs();
    pending_system_producer_valid = 1'b1;
    branch_resolve_untracked = 1'b1;
    tick();
    expect_stop("exact pending csr lease rejects ordinary recovery clear",
                1'b1);
    clear_inputs();
    pending_system_producer_valid = 1'b1;
    pending_system_csr_commit = 1'b1;
    tick();
    expect_stop("exact pending csr death clears stop", 1'b0);

    set_from_irq();
    clear_inputs();
    drain_complete = 1'b1;
    tick();
    expect_stop("drain clears", 1'b0);

    clear_inputs();
    pending_owner_birth = 1'b1;
    tick();
    expect_stop("accepted trap owner birth sets", 1'b1);

    clear_inputs();
    pending_branch_commit_resolve = 1'b1;
    tick();
    expect_stop("branch commit clears", 1'b0);

    clear_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch0_branch = 1'b1;
    direct_branch0_dispatch_valid = 1'b0;
    tick();
    expect_stop("dead branch raw classification cannot set stop", 1'b0);

    clear_inputs();
    pending_branch_match_clear = 1'b1;
    tick();
    expect_stop("branch match clears", 1'b0);

    clear_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch0_jump = 1'b1;
    dispatch0_return = 1'b0;
    tick();
    expect_stop("dead jump raw classification cannot set stop", 1'b0);

    clear_inputs();
    branch_resolve_untracked = 1'b1;
    tick();
    expect_stop("untracked branch clears", 1'b0);

    // V9X RED: an older recovery and a younger serialized-system candidate
    // may be visible on the same edge.  The pending holder is clear-wins, so
    // stop must not be born from the rejected raw lane classification.
    clear_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch0_system = 1'b1;
    branch_spec_resolve_valid = 1'b1;
    rob_walk_mode = 1'b0;
    tick();
    expect_stop("V9X lane0 checkpoint recovery rejects raw system stop birth",
                1'b0);

    clear_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch1_barrier_fire = 1'b1;
    branch_spec_resolve_valid = 1'b1;
    rob_walk_mode = 1'b0;
    tick();
    expect_stop("V9X lane1 checkpoint recovery rejects raw barrier stop birth",
                1'b0);
    $display("[V9X-STOP-OWNER-BIRTH][PASS] lane0/lane1 recovery collision checked");

    clear_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch1_barrier_fire = 1'b1;
    tick();
    expect_stop("raw lane1 barrier without accepted owner cannot set", 1'b0);

    clear_inputs();
    pending_owner_birth = 1'b1;
    tick();
    expect_stop("accepted lane1 owner birth sets", 1'b1);

    clear_inputs();
    system_csr_dispatch_fire = 1'b1;
    tick();
    expect_stop("system csr dispatch holds", 1'b1);

    clear_inputs();
    can_run = 1'b1;
    fifo_has_packet = 1'b1;
    dispatch_unsupported = 1'b1;
    csr_trap_mem_valid = 1'b1;
    tick();
    expect_stop("late trap overrides capture", 1'b0);

    clear_inputs();
    flush = 1'b1;
    tick();
    expect_stop("flush clears", 1'b0);

    if (errors == 0) begin
      $display("PASS tb_ooo_stop_pending_sequencer");
      $finish;
    end
    $fatal(1, "FAIL tb_ooo_stop_pending_sequencer errors=%0d", errors);
  end
endmodule
