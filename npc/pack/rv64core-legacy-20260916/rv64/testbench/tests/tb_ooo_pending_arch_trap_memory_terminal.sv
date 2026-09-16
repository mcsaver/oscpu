`include "include/define.v"

module tb_ooo_pending_arch_trap_memory_terminal;
  `include "tb_common.svh"

  localparam ROB_COUNT_W = 5;
  localparam ISSUE_COUNT_W = 4;

  reg stop_pending;
  reg pending_control_ready;
  reg pending_arch_trap;
  reg mem_idle;
  reg mem_owner_terminalized;
  reg serialized_mem_terminal_ready;
  reg pending_system;
  reg pending_system_fence;

  wire backend_drained;
  wire drain_complete;
  wire pending_arch_trap_fire;
  wire trap_ex_valid;
  wire [`XLEN-1:0] trap_ex_pc;
  wire [`TRAP_CAUSE_W-1:0] trap_ex_cause;
  wire [`XLEN-1:0] trap_ex_tval;
  wire priv_predictor_boundary;

  localparam [`XLEN-1:0] TRAP_PC = 64'h0000_0000_8000_0130;
  localparam [`XLEN-1:0] TRAP_TVAL = 64'h0000_0000_dead_0130;

  OooPendingDrainResolveGate #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) drain_gate (
    .rob_count_i({ROB_COUNT_W{1'b0}}),
    .issue_count_i({ISSUE_COUNT_W{1'b0}}),
    .tensor_pre_rob_owner_live_i(1'b0),
    .synth_lane1_ret_pending_i(1'b0),
    .synth_lane1_branch_drop_pending_i(1'b0),
    .direct_frontend_flush_i(1'b0),
    .stop_pending_i(stop_pending),
    .backend_drained_q_i(1'b0),
    .pending_control_ready_i(pending_control_ready),
    .dispatch0_ready_i(1'b0),
    .branch_resolve_pending_match_i(1'b0),
    .branch_spec_active_i(1'b0),
    .branch_spec_checkpoint_pending_i(1'b0),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_exit_i(1'b0),
    .pending_branch_i(1'b0),
    .pending_branch_dispatched_i(1'b0),
    .pending_jump_i(1'b0),
    .pending_jump_dispatched_i(1'b0),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_nolink_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .mem_retire_quiet_i(1'b1),
    .mem_idle_i(mem_idle),
    .mem_owner_terminalized_i(mem_owner_terminalized),
    .serialized_mem_terminal_ready_i(serialized_mem_terminal_ready),
    .pending_system_i(pending_system),
    .pending_system_fence_i(pending_system_fence),
    .pending_system_csr_i(1'b0),
    .pending_system_dispatched_i(1'b0),
    .system_csr_dispatch_cancel_i(1'b0),
    .backend_drained_o(backend_drained),
    .jump_dispatch_valid_o(),
    .system_csr_dispatch_valid_o(),
    .system_csr_dispatch_fire_o(),
    .pending_branch_commit_resolve_o(),
    .pending_branch_match_clear_o(),
    .pending_replay_wait_o(),
    .drain_complete_o(drain_complete)
  );

  OooCsrTrapRequestMux trap_mux (
    .core_commit0_valid_i(1'b0),
    .core_commit0_exception_i(1'b0),
    .core_commit0_pc_i({`XLEN{1'b0}}),
    .core_commit0_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .core_commit0_tval_i({`XLEN{1'b0}}),
    .core_commit1_valid_i(1'b0),
    .core_commit1_exception_i(1'b0),
    .core_commit1_pc_i({`XLEN{1'b0}}),
    .core_commit1_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .core_commit1_tval_i({`XLEN{1'b0}}),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_trap_cause_i(`EXC_ILLEGAL_INST),
    .pending_trap_pc_i(TRAP_PC),
    .pending_trap_tval_i(TRAP_TVAL),
    .pending_system_i(pending_system),
    .pending_system_ecall_i(1'b0),
    .pending_system_mret_i(1'b0),
    .pending_system_irq_i(1'b0),
    .pending_system_pc_i({`XLEN{1'b0}}),
    .pending_system_inst_i({`INST_W{1'b0}}),
    .pending_system_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .csr_ecall_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_system_satp_write_commit_i(1'b0),
    .pending_system_sfence_commit_i(1'b0),
    .core_commit_exception_trap_o(),
    .trap_mem_valid_o(),
    .trap_mem_pc_o(),
    .trap_mem_cause_o(),
    .trap_mem_tval_o(),
    .pending_system_ecall_trap_o(),
    .pending_arch_trap_fire_o(pending_arch_trap_fire),
    .trap_ex_valid_o(trap_ex_valid),
    .trap_ex_pc_o(trap_ex_pc),
    .trap_ex_cause_o(trap_ex_cause),
    .trap_ex_tval_o(trap_ex_tval),
    .trap_irq_valid_o(),
    .trap_irq_pc_o(),
    .trap_irq_cause_o(),
    .mret_valid_o(),
    .sret_valid_o(),
    .real_mret_valid_o(),
    .priv_predictor_boundary_o(priv_predictor_boundary)
  );

  task automatic clear_inputs;
    begin
      stop_pending = 1'b0;
      pending_control_ready = 1'b0;
      pending_arch_trap = 1'b0;
      mem_idle = 1'b1;
      mem_owner_terminalized = 1'b1;
      serialized_mem_terminal_ready = 1'b1;
      pending_system = 1'b0;
      pending_system_fence = 1'b0;
    end
  endtask

  task automatic check_trap_metadata;
    begin
      if (trap_ex_pc !== TRAP_PC ||
          trap_ex_cause !== `EXC_ILLEGAL_INST ||
          trap_ex_tval !== TRAP_TVAL) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] pending arch trap metadata pc=%h cause=%h tval=%h",
                 trap_ex_pc, trap_ex_cause, trap_ex_tval);
      end
    end
  endtask

  initial begin
    tb_errors = 0;

    // V9Z RED oracle: an architectural trap cannot fire while an older
    // memory owner remains active without an accepted terminal transfer.
    clear_inputs();
    stop_pending = 1'b1;
    pending_control_ready = 1'b1;
    pending_arch_trap = 1'b1;
    mem_idle = 1'b0;
    mem_owner_terminalized = 1'b0;
    serialized_mem_terminal_ready = 1'b0;
    #1;
    tb_check1("V9Z active memory holder blocks drain", drain_complete, 1'b0);
    tb_check1("V9Z active memory holder blocks arch trap fire",
              pending_arch_trap_fire, 1'b0);
    tb_check1("V9Z active memory holder blocks trap request",
              trap_ex_valid, 1'b0);
    tb_check1("V9Z active memory holder blocks predictor boundary",
              priv_predictor_boundary, 1'b0);

    // The exact current-edge accepted terminal transfer and the
    // collector-pending-only phase both present the same qualified scalar.
    mem_owner_terminalized = 1'b1;
    serialized_mem_terminal_ready = 1'b1;
    #1;
    tb_check1("V9Z exact terminal admits drain", drain_complete, 1'b1);
    tb_check1("V9Z exact terminal admits arch trap fire",
              pending_arch_trap_fire, 1'b1);
    tb_check1("V9Z exact terminal emits trap request", trap_ex_valid, 1'b1);
    tb_check1("V9Z exact terminal marks predictor boundary",
              priv_predictor_boundary, 1'b1);
    check_trap_metadata();
    $display("[V9Z-ARCH-TRAP-MEM-TERMINAL] active=0 exact_terminal_or_pending_only=1 PASS");

    // Do not extend the memory-owner condition to unrelated drained control
    // cycles that carry neither an architectural trap nor a system request.
    pending_arch_trap = 1'b0;
    mem_owner_terminalized = 1'b0;
    serialized_mem_terminal_ready = 1'b0;
    #1;
    tb_check1("V9Z unrelated drained control ignores memory holder",
              drain_complete, 1'b1);

    // Overlapping architectural-trap and non-FENCE system ownership shares
    // the exact terminal scalar.
    pending_arch_trap = 1'b1;
    pending_system = 1'b1;
    #1;
    tb_check1("V9Z overlapping serialized controls block active holder",
              drain_complete, 1'b0);
    mem_owner_terminalized = 1'b1;
    serialized_mem_terminal_ready = 1'b1;
    #1;
    tb_check1("V9Z overlapping serialized controls admit exact terminal",
              drain_complete, 1'b1);

    // Ordinary FENCE preserves its stronger full-memory-idle requirement.
    pending_system_fence = 1'b1;
    mem_idle = 1'b0;
    #1;
    tb_check1("V9Z overlapping FENCE still waits full memory idle",
              drain_complete, 1'b0);
    mem_idle = 1'b1;
    #1;
    tb_check1("V9Z overlapping FENCE completes at full memory idle",
              drain_complete, 1'b1);

    tb_check1("V9Z empty backend precondition", backend_drained, 1'b1);
    tb_finish("tb_ooo_pending_arch_trap_memory_terminal");
  end
endmodule
