`include "include/define.v"

module tb_ooo_trap_exit_event_mux;
  reg csr_trap_mem_valid_i;
  reg direct_frontend_flush_i;
  reg stop_pending_i;
  reg drain_complete_i;
  reg branch_spec_resolve_valid_i;
  reg branch_spec_restore_i;
  reg core_branch_resolve_misaligned_i;
  reg [`XLEN-1:0] core_branch_resolve_pc_i;
  reg [`XLEN-1:0] core_branch_resolve_next_pc_i;
  reg pending_branch_commit_resolve_i;
  reg pending_branch_match_clear_i;
  reg branch_resolve_untracked_i;
  reg pending_branch_misaligned_i;
  reg [`XLEN-1:0] pending_branch_pc_i;
  reg [`XLEN-1:0] pending_branch_target_i;
  reg pending_branch_valid_i;
  reg pending_branch_dispatched_i;
  reg pending_jump_resolve_ready_i;
  reg pending_jump_misaligned_i;
  reg [`XLEN-1:0] pending_jump_pc_i;
  reg [`XLEN-1:0] pending_jump_resolved_target_i;
  reg pending_mem_resolve_ready_i;
  reg system_csr_dispatch_fire_i;
  reg pending_system_csr_commit_i;
  reg pending_arch_trap_i;
  reg pending_system_i;
  reg pending_jump_i;
  reg pending_mem_i;
  reg pending_fp_i;
  reg pending_exit_i;
  reg pending_exit_is_ecall_i;
  reg pending_exit_is_ebreak_i;
  reg [`TRAP_CAUSE_W-1:0] pending_trap_cause_i;
  reg [`XLEN-1:0] pending_trap_pc_i;
  reg [`XLEN-1:0] pending_trap_tval_i;

  wire trap_o;
  wire [`TRAP_CAUSE_W-1:0] trap_cause_o;
  wire [`XLEN-1:0] trap_pc_o;
  wire [`XLEN-1:0] trap_tval_o;
  wire exit_o;
  wire exit_is_ecall_o;
  wire exit_is_ebreak_o;

  OooTrapExitEventMux dut (
    .csr_trap_mem_valid_i(csr_trap_mem_valid_i),
    .direct_frontend_flush_i(direct_frontend_flush_i),
    .stop_pending_i(stop_pending_i),
    .drain_complete_i(drain_complete_i),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid_i),
    .branch_spec_restore_i(branch_spec_restore_i),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned_i),
    .core_branch_resolve_pc_i(core_branch_resolve_pc_i),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_i),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_i),
    .pending_branch_match_clear_i(pending_branch_match_clear_i),
    .branch_resolve_untracked_i(branch_resolve_untracked_i),
    .pending_branch_misaligned_i(pending_branch_misaligned_i),
    .pending_branch_pc_i(pending_branch_pc_i),
    .pending_branch_target_i(pending_branch_target_i),
    .pending_branch_valid_i(pending_branch_valid_i),
    .pending_branch_dispatched_i(pending_branch_dispatched_i),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_i),
    .pending_jump_misaligned_i(pending_jump_misaligned_i),
    .pending_jump_pc_i(pending_jump_pc_i),
    .pending_jump_resolved_target_i(pending_jump_resolved_target_i),
    .pending_mem_resolve_ready_i(pending_mem_resolve_ready_i),
    .system_csr_dispatch_fire_i(system_csr_dispatch_fire_i),
    .pending_system_csr_commit_i(pending_system_csr_commit_i),
    .pending_arch_trap_i(pending_arch_trap_i),
    .pending_system_i(pending_system_i),
    .pending_jump_i(pending_jump_i),
    .pending_mem_i(pending_mem_i),
    .pending_fp_i(pending_fp_i),
    .pending_exit_i(pending_exit_i),
    .pending_exit_is_ecall_i(pending_exit_is_ecall_i),
    .pending_exit_is_ebreak_i(pending_exit_is_ebreak_i),
    .pending_trap_cause_i(pending_trap_cause_i),
    .pending_trap_pc_i(pending_trap_pc_i),
    .pending_trap_tval_i(pending_trap_tval_i),
    .trap_o(trap_o),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_tval_o(trap_tval_o),
    .exit_o(exit_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_is_ebreak_o(exit_is_ebreak_o)
  );

  task clear_inputs;
    begin
      csr_trap_mem_valid_i = 1'b0;
      direct_frontend_flush_i = 1'b0;
      stop_pending_i = 1'b0;
      drain_complete_i = 1'b0;
      branch_spec_resolve_valid_i = 1'b0;
      branch_spec_restore_i = 1'b0;
      core_branch_resolve_misaligned_i = 1'b0;
      core_branch_resolve_pc_i = 64'h8000_0100;
      core_branch_resolve_next_pc_i = 64'h8000_0102;
      pending_branch_commit_resolve_i = 1'b0;
      pending_branch_match_clear_i = 1'b0;
      branch_resolve_untracked_i = 1'b0;
      pending_branch_misaligned_i = 1'b0;
      pending_branch_pc_i = 64'h8000_0200;
      pending_branch_target_i = 64'h8000_0202;
      pending_branch_valid_i = 1'b0;
      pending_branch_dispatched_i = 1'b0;
      pending_jump_resolve_ready_i = 1'b0;
      pending_jump_misaligned_i = 1'b0;
      pending_jump_pc_i = 64'h8000_0300;
      pending_jump_resolved_target_i = 64'h8000_0302;
      pending_mem_resolve_ready_i = 1'b0;
      system_csr_dispatch_fire_i = 1'b0;
      pending_system_csr_commit_i = 1'b0;
      pending_arch_trap_i = 1'b0;
      pending_system_i = 1'b0;
      pending_jump_i = 1'b0;
      pending_mem_i = 1'b0;
      pending_fp_i = 1'b0;
      pending_exit_i = 1'b0;
      pending_exit_is_ecall_i = 1'b0;
      pending_exit_is_ebreak_i = 1'b0;
      pending_trap_cause_i = `EXC_ILLEGAL_INST;
      pending_trap_pc_i = 64'h8000_0400;
      pending_trap_tval_i = 64'hdead_beef;
    end
  endtask

  task expect_event;
    input exp_trap;
    input [`TRAP_CAUSE_W-1:0] exp_cause;
    input [`XLEN-1:0] exp_pc;
    input [`XLEN-1:0] exp_tval;
    input exp_exit;
    input exp_ecall;
    input exp_ebreak;
    begin
      #1;
      if (trap_o !== exp_trap ||
          trap_cause_o !== exp_cause ||
          trap_pc_o !== exp_pc ||
          trap_tval_o !== exp_tval ||
          exit_o !== exp_exit ||
          exit_is_ecall_o !== exp_ecall ||
          exit_is_ebreak_o !== exp_ebreak) begin
        $display("FAIL trap=%0b cause=%0h pc=%0h tval=%0h exit=%0b/%0b/%0b",
                 trap_o, trap_cause_o, trap_pc_o, trap_tval_o,
                 exit_o, exit_is_ecall_o, exit_is_ebreak_o);
        $finish;
      end
    end
  endtask

  task make_drain_ready;
    begin
      stop_pending_i = 1'b1;
      drain_complete_i = 1'b1;
    end
  endtask

  initial begin
    clear_inputs();
    expect_event(1'b0, `EXC_INST_ADDR_MISALIGN, 64'h8000_0100,
                 64'h8000_0102, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    branch_spec_resolve_valid_i = 1'b1;
    branch_spec_restore_i = 1'b1;
    core_branch_resolve_misaligned_i = 1'b1;
    expect_event(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0100,
                 64'h8000_0102, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    branch_spec_resolve_valid_i = 1'b1;
    branch_spec_restore_i = 1'b1;
    core_branch_resolve_misaligned_i = 1'b1;
    pending_branch_commit_resolve_i = 1'b1;
    pending_branch_misaligned_i = 1'b1;
    expect_event(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0200,
                 64'h8000_0202, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    branch_spec_resolve_valid_i = 1'b1;
    branch_spec_restore_i = 1'b1;
    core_branch_resolve_misaligned_i = 1'b1;
    pending_jump_resolve_ready_i = 1'b1;
    pending_jump_misaligned_i = 1'b1;
    expect_event(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0300,
                 64'h8000_0302, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    make_drain_ready();
    pending_branch_valid_i = 1'b1;
    pending_branch_misaligned_i = 1'b1;
    expect_event(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0200,
                 64'h8000_0202, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    make_drain_ready();
    pending_exit_i = 1'b1;
    pending_exit_is_ecall_i = 1'b1;
    expect_event(1'b0, `EXC_INST_ADDR_MISALIGN, 64'h8000_0100,
                 64'h8000_0102, 1'b1, 1'b1, 1'b0);

    clear_inputs();
    make_drain_ready();
    pending_mem_resolve_ready_i = 1'b1;
    pending_exit_i = 1'b1;
    pending_exit_is_ebreak_i = 1'b1;
    expect_event(1'b0, `EXC_INST_ADDR_MISALIGN, 64'h8000_0100,
                 64'h8000_0102, 1'b0, 1'b0, 1'b1);

    clear_inputs();
    make_drain_ready();
    expect_event(1'b1, `EXC_ILLEGAL_INST, 64'h8000_0400,
                 64'hdead_beef, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    make_drain_ready();
    branch_spec_resolve_valid_i = 1'b1;
    branch_spec_restore_i = 1'b1;
    core_branch_resolve_misaligned_i = 1'b1;
    pending_trap_cause_i = `EXC_BREAKPOINT;
    pending_trap_pc_i = 64'h8000_0500;
    pending_trap_tval_i = 64'h0;
    expect_event(1'b1, `EXC_BREAKPOINT, 64'h8000_0500,
                 64'h0, 1'b0, 1'b0, 1'b0);

    clear_inputs();
    make_drain_ready();
    branch_spec_resolve_valid_i = 1'b1;
    branch_spec_restore_i = 1'b1;
    core_branch_resolve_misaligned_i = 1'b1;
    pending_exit_i = 1'b1;
    pending_exit_is_ebreak_i = 1'b1;
    expect_event(1'b1, `EXC_INST_ADDR_MISALIGN, 64'h8000_0100,
                 64'h8000_0102, 1'b1, 1'b0, 1'b1);

    $display("PASS tb_ooo_trap_exit_event_mux");
    $finish;
  end
endmodule
