`timescale 1ns/1ps
`include "define.v"
`include "common/OooSlotFacts.v"

// V10A SERIALIZE-G1 clocked contract:
//   accepted birth -> registered exact-one owner/stop ->
//   exact memory terminal C0 -> CsrFile sample + C1 owner/stop clear ->
//   C2 no repeat.
// The test counts every raw request pulse.  It deliberately contains no
// event de-duplication, so a repeated terminal transaction is a hard failure.
module tb_ooo_serialized_owner_exactly_once;
  `include "tb_common.svh"

  localparam integer PRODUCER_ID_W =
      `OOO_ROB_INDEX_W + `OOO_PRODUCER_GEN_W;
  localparam integer KIND_ECALL = 0;
  localparam integer KIND_IRQ   = 1;
  localparam integer KIND_XRET  = 2;
  localparam integer KIND_CSR   = 3;
  localparam integer KIND_FENCE = 4;

  localparam [`XLEN-1:0] ARCH_PC =
      64'h0000_0000_8000_1200;
  localparam [`XLEN-1:0] MEM_PC =
      64'h0000_0000_8000_2200;
  localparam [`XLEN-1:0] ARCH_TVAL =
      64'h0000_0000_ffff_ffff;
  localparam [`INST_W-1:0] INST_ADDI  = 32'h0000_0013;
  localparam [`INST_W-1:0] INST_BAD   = 32'hffff_ffff;
  localparam [`INST_W-1:0] INST_ECALL = 32'h0000_0073;
  localparam [`INST_W-1:0] INST_EBREAK = 32'h0010_0073;
  localparam [`INST_W-1:0] INST_MRET  = 32'h3020_0073;
  localparam [`INST_W-1:0] INST_CSR   = 32'h3000_1073;
  localparam [`INST_W-1:0] INST_FENCE = 32'h0000_000f;

  reg clk;
  reg rst;

  reg fifo_has_packet;
  reg csr_irq_pending;
  reg direct_frontend_flush;
  reg dispatch1_barrier_fire;
  reg [`OOO_SLOT_FACTS_W-1:0] head0_facts;
  reg [`OOO_SLOT_FACTS_W-1:0] head1_facts;
  reg [`XLEN-1:0] head_pc0;
  reg [`XLEN-1:0] head_pc1;
  reg [`INST_W-1:0] head_inst0;
  reg [`INST_W-1:0] head_inst1;

  reg head0_csr;
  reg head0_ecall;
  reg head0_mret;
  reg head0_wfi;
  reg head0_sfence;
  reg head0_fencei;
  reg head1_csr;
  reg head1_ecall;
  reg head1_mret;
  reg head1_wfi;
  reg head1_sfence;
  reg head1_fencei;

  reg mem_owner_terminalized;
  reg mem_idle;
  reg core_local_flush;
  reg branch_spec_active;
  reg branch_spec_checkpoint_pending;
  reg branch_spec_resolve_valid;
  reg branch_spec_restore;
  reg branch_spec_misaligned;
  reg core_commit0_valid;
  reg core_commit0_exception;
  reg [`XLEN-1:0] core_commit0_pc;
  reg [`TRAP_CAUSE_W-1:0] core_commit0_cause;
  reg [`XLEN-1:0] core_commit0_tval;

  wire orphan_stop_pending;
  wire stop_pending_busy;
  wire can_run;
  wire stop_pending;

  wire pending_system_capture_irq;
  wire pending_system_capture_head0;
  wire pending_system_capture_lane1;
  wire pending_system_clear;
  wire pending_trap_clear_exit;
  wire pending_trap_clear_arch;
  wire pending_trap_clear_arch_squash;
  wire pending_trap_capture_exit;
  wire pending_trap_capture_exit_valid;
  wire pending_trap_capture_exit_ecall;
  wire pending_trap_capture_exit_ebreak;
  wire pending_trap_capture_arch;
  wire pending_trap_capture_arch_valid;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_capture_cause;
  wire [`XLEN-1:0] pending_trap_capture_pc;
  wire [`XLEN-1:0] pending_trap_capture_tval;

  wire pending_exit;
  wire pending_exit_ecall;
  wire pending_exit_ebreak;
  wire pending_arch_trap;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_cause;
  wire [`XLEN-1:0] pending_trap_pc;
  wire [`XLEN-1:0] pending_trap_tval;

  wire pending_system;
  wire pending_system_dispatched;
  wire pending_system_csr;
  wire pending_system_ecall;
  wire pending_system_mret;
  wire pending_system_wfi;
  wire pending_system_sfence;
  wire pending_system_fencei;
  wire pending_system_fence;
  wire pending_system_irq;
  wire [`XLEN-1:0] pending_system_pc;
  wire [`INST_W-1:0] pending_system_inst;
  wire [`XLEN-1:0] pending_system_next_pc;
  wire [`XLEN-1:0] pending_system_csr_rdata;
  wire [`TRAP_CAUSE_W-1:0] pending_system_irq_cause;
  wire pending_system_producer_valid;
  wire [PRODUCER_ID_W-1:0] pending_system_producer_id;

  wire backend_drained;
  wire drain_complete;
  wire pending_replay_wait;
  wire system_csr_dispatch_valid;
  wire system_csr_dispatch_fire;

  wire core_commit_exception_trap;
  wire trap_mem_valid;
  wire [`XLEN-1:0] trap_mem_pc;
  wire [`TRAP_CAUSE_W-1:0] trap_mem_cause;
  wire [`XLEN-1:0] trap_mem_tval;
  wire pending_system_ecall_trap;
  wire pending_arch_trap_fire;
  wire trap_ex_valid;
  wire [`XLEN-1:0] trap_ex_pc;
  wire [`TRAP_CAUSE_W-1:0] trap_ex_cause;
  wire [`XLEN-1:0] trap_ex_tval;
  wire trap_irq_valid;
  wire [`XLEN-1:0] trap_irq_pc;
  wire [`TRAP_CAUSE_W-1:0] trap_irq_cause;
  wire mret_valid;
  wire sret_valid;
  wire real_mret_valid;
  wire priv_predictor_boundary;

  wire raw_trap;
  wire [`TRAP_CAUSE_W-1:0] raw_trap_cause;
  wire [`XLEN-1:0] raw_trap_pc;
  wire [`XLEN-1:0] raw_trap_tval;
  wire raw_exit;
  wire raw_exit_ecall;
  wire raw_exit_ebreak;
  wire trap_valid;
  wire [`TRAP_CAUSE_W-1:0] terminal_trap_cause;
  wire [`XLEN-1:0] terminal_trap_pc;
  wire [`XLEN-1:0] terminal_trap_tval;
  wire exit_valid;
  wire exit_ecall;
  wire exit_ebreak;
  wire halted;

  wire [`XLEN-1:0] csr_mepc;
  wire [`TRAP_CAUSE_W-1:0] csr_ecall_cause;
  wire [`XLEN-1:0] csr_trap_target;
  wire [`XLEN-1:0] csr_ret_target;
  wire [1:0] csr_priv_mode;
  wire [`XLEN-1:0] csr_mstatus;
  wire [`XLEN-1:0] csr_satp;
  wire csr_svpbmt_en;
  wire [2:0] csr_frm;
  wire [`PMP_CFG_BUS_W-1:0] csr_pmpcfg;
  wire [`PMP_ADDR_BUS_W-1:0] csr_pmpaddr;

  integer pending_arch_request_count_q;
  integer csr_arch_accept_count_q;
  integer csr_mem_accept_count_q;
  integer blocked_kind_count_q;
  integer raw_exit_count_q;
  integer raw_trap_count_q;

  wire [3:0] pending_system_kind_count =
      {3'b000, pending_system_csr} +
      {3'b000, pending_system_ecall} +
      {3'b000, pending_system_mret} +
      {3'b000, pending_system_wfi} +
      {3'b000, pending_system_sfence} +
      {3'b000, pending_system_fencei} +
      {3'b000, pending_system_fence} +
      {3'b000, pending_system_irq};

  wire pending_system_owner_birth =
      !pending_system &&
      !pending_system_producer_valid &&
      !pending_system_clear &&
      (pending_system_capture_irq ||
       pending_system_capture_head0 ||
       pending_system_capture_lane1);
  wire pending_trap_owner_birth =
      !trap_mem_valid &&
      !direct_frontend_flush &&
      ((pending_trap_capture_exit &&
        pending_trap_capture_exit_valid &&
        !(pending_trap_clear_exit &&
          pending_trap_clear_arch_squash)) ||
       (pending_trap_capture_arch &&
        pending_trap_capture_arch_valid &&
        !(pending_trap_clear_arch &&
          pending_trap_clear_arch_squash)));
  wire pending_owner_birth =
      pending_system_owner_birth || pending_trap_owner_birth;
  wire pending_owner_live =
      pending_system || pending_exit || pending_arch_trap;

  OooFrontendRunGate u_run_gate (
    .run_i(1'b1),
    .core_trap_flush_i(1'b0),
    .core_serial_flush_i(1'b0),
    .stop_pending_i(stop_pending),
    .pending_exit_i(pending_exit),
    .pending_branch_i(1'b0),
    .pending_jump_i(1'b0),
    .pending_mem_i(1'b0),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_system_i(pending_system),
    .synth_lane1_ret_pending_i(1'b0),
    .synth_lane1_branch_drop_pending_i(1'b0),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .branch_spec_active_i(branch_spec_active),
    .head0_csr_inflight_i(1'b0),
    .halted_i(halted),
    .trap_valid_i(trap_valid),
    .exit_valid_i(exit_valid),
    .fifo_storage_head_valid_i(fifo_has_packet),
    .outstanding_valid_i(1'b0),
    .fifo_count_i(3'd0),
    .fifo_depth_i(3'd4),
    .orphan_stop_pending_o(orphan_stop_pending),
    .stop_pending_busy_o(stop_pending_busy),
    .can_run_o(can_run),
    .fifo_empty_storage_o(),
    .outstanding_count_o(),
    .fifo_reserve_available_o()
  );

  OooPendingDispatchArbiter u_dispatch_arbiter (
    .csr_trap_mem_valid_i(trap_mem_valid),
    .direct_frontend_flush_i(direct_frontend_flush),
    .can_run_i(can_run),
    .fifo_has_packet_i(fifo_has_packet),
    .csr_irq_pending_i(csr_irq_pending),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(1'b0),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_nolink_commit_i(1'b0),
    .pending_jump_redirect_after_dispatch_i(1'b0),
    .pending_system_csr_commit_i(1'b0),
    .head0_csr_commit_i(1'b0),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .direct_branch0_fire_i(1'b0),
    .direct_branch1_fire_i(1'b0),
    .head_fetch_fault0_i(1'b0),
    .head_fetch_fault1_i(1'b0),
    .head_fetch_fault_tval_i({`XLEN{1'b0}}),
    .head_resp0_i(2'b00),
    .head_resp1_i(2'b00),
    .head_pc0_i(head_pc0),
    .head_pc1_i(head_pc1),
    .head_inst0_i(head_inst0),
    .head_inst1_i(head_inst1),
    .dispatch0_facts_i(head0_facts),
    .head1_facts_i(head1_facts),
    .direct_branch0_dispatch_valid_i(1'b0),
    .direct_jal0_dispatch_valid_i(1'b0),
    .dispatch0_return_i(1'b0),
    .dispatch0_unsupported_i(1'b0),
    .dispatch_unsupported_i(1'b0),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .head0_csr_illegal_i(1'b0),
    .head1_csr_illegal_i(1'b0),
    .rob_walk_mode_i(1'b1),
    .pending_system_capture_irq_o(pending_system_capture_irq),
    .pending_system_capture_head0_o(pending_system_capture_head0),
    .pending_system_capture_lane1_o(pending_system_capture_lane1),
    .pending_system_clear_o(pending_system_clear),
    .pending_trap_exit_clear_exit_o(pending_trap_clear_exit),
    .pending_trap_exit_clear_arch_o(pending_trap_clear_arch),
    .pending_trap_exit_clear_arch_squash_o(
        pending_trap_clear_arch_squash),
    .pending_trap_exit_capture_exit_o(pending_trap_capture_exit),
    .pending_trap_exit_capture_exit_valid_o(
        pending_trap_capture_exit_valid),
    .pending_trap_exit_capture_exit_ecall_o(
        pending_trap_capture_exit_ecall),
    .pending_trap_exit_capture_exit_ebreak_o(
        pending_trap_capture_exit_ebreak),
    .pending_trap_exit_capture_arch_o(pending_trap_capture_arch),
    .pending_trap_exit_capture_arch_valid_o(
        pending_trap_capture_arch_valid),
    .pending_trap_exit_capture_cause_o(pending_trap_capture_cause),
    .pending_trap_exit_capture_pc_o(pending_trap_capture_pc),
    .pending_trap_exit_capture_tval_o(pending_trap_capture_tval)
  );

  OooPendingTrapExitSequencer u_trap_sequencer (
    .clk(clk),
    .rst(rst || core_local_flush),
    .late_clear_i(trap_mem_valid),
    .clear_exit_i(pending_trap_clear_exit),
    .clear_arch_i(pending_trap_clear_arch),
    .clear_arch_squash_i(pending_trap_clear_arch_squash),
    .capture_exit_i(pending_trap_capture_exit),
    .capture_exit_valid_i(pending_trap_capture_exit_valid),
    .capture_exit_is_ecall_i(pending_trap_capture_exit_ecall),
    .capture_exit_is_ebreak_i(pending_trap_capture_exit_ebreak),
    .capture_arch_i(pending_trap_capture_arch),
    .capture_arch_valid_i(pending_trap_capture_arch_valid),
    .capture_trap_cause_i(pending_trap_capture_cause),
    .capture_trap_pc_i(pending_trap_capture_pc),
    .capture_trap_tval_i(pending_trap_capture_tval),
    .pending_exit_o(pending_exit),
    .pending_exit_is_ecall_o(pending_exit_ecall),
    .pending_exit_is_ebreak_o(pending_exit_ebreak),
    .pending_arch_trap_o(pending_arch_trap),
    .pending_trap_cause_o(pending_trap_cause),
    .pending_trap_pc_o(pending_trap_pc),
    .pending_trap_tval_o(pending_trap_tval)
  );

  OooPendingSystemSequencer u_system_sequencer (
    .clk(clk),
    .rst(rst || core_local_flush),
    .clear_i(pending_system_clear),
    .clear_dispatched_i(orphan_stop_pending),
    .dispatch_fire_i(system_csr_dispatch_fire),
    .producer_death_i(1'b0),
    .dispatch_producer_id_i({PRODUCER_ID_W{1'b0}}),
    .refresh_rdata_i(1'b0),
    .refresh_rdata_value_i({`XLEN{1'b0}}),
    .capture_irq_i(pending_system_capture_irq),
    .capture_irq_pc_i(head_pc0),
    .capture_irq_cause_i(`IRQ_CAUSE_MTI),
    .capture_head0_i(pending_system_capture_head0),
    .capture_head0_csr_i(head0_csr),
    .capture_head0_ecall_i(head0_ecall),
    .capture_head0_mret_i(head0_mret),
    .capture_head0_wfi_i(head0_wfi),
    .capture_head0_sfence_i(head0_sfence),
    .capture_head0_fencei_i(head0_fencei),
    .capture_head0_pc_i(head_pc0),
    .capture_head0_inst_i(head_inst0),
    .capture_head0_next_pc_i(head_pc0 + 64'd4),
    .capture_head0_csr_rdata_i({`XLEN{1'b0}}),
    .capture_lane1_i(pending_system_capture_lane1),
    .capture_lane1_csr_i(head1_csr),
    .capture_lane1_ecall_i(head1_ecall),
    .capture_lane1_mret_i(head1_mret),
    .capture_lane1_wfi_i(head1_wfi),
    .capture_lane1_sfence_i(head1_sfence),
    .capture_lane1_fencei_i(head1_fencei),
    .capture_lane1_pc_i(head_pc1),
    .capture_lane1_inst_i(head_inst1),
    .capture_lane1_next_pc_i(head_pc1 + 64'd4),
    .capture_lane1_csr_rdata_i({`XLEN{1'b0}}),
    .valid_o(pending_system),
    .dispatched_o(pending_system_dispatched),
    .csr_o(pending_system_csr),
    .ecall_o(pending_system_ecall),
    .mret_o(pending_system_mret),
    .wfi_o(pending_system_wfi),
    .sfence_o(pending_system_sfence),
    .fencei_o(pending_system_fencei),
    .fence_o(pending_system_fence),
    .irq_o(pending_system_irq),
    .pc_o(pending_system_pc),
    .inst_o(pending_system_inst),
    .next_pc_o(pending_system_next_pc),
    .csr_rdata_o(pending_system_csr_rdata),
    .irq_cause_o(pending_system_irq_cause),
    .producer_valid_o(pending_system_producer_valid),
    .producer_id_o(pending_system_producer_id)
  );

  OooPendingDrainResolveGate u_drain_gate (
    .rob_count_i({`OOO_ROB_COUNT_W{1'b0}}),
    .issue_count_i({`OOO_ISSUE_COUNT_W{1'b0}}),
    .synth_lane1_ret_pending_i(1'b0),
    .synth_lane1_branch_drop_pending_i(1'b0),
    .direct_frontend_flush_i(direct_frontend_flush),
    .stop_pending_i(stop_pending),
    .backend_drained_q_i(1'b1),
    .pending_control_ready_i(1'b1),
    .dispatch0_ready_i(1'b1),
    .branch_resolve_pending_match_i(1'b0),
    .branch_spec_active_i(branch_spec_active),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_exit_i(pending_exit),
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
    .pending_system_i(pending_system),
    .pending_system_fence_i(pending_system_fence),
    .pending_system_csr_i(pending_system_csr),
    .pending_system_dispatched_i(pending_system_dispatched),
    .system_csr_dispatch_cancel_i(1'b0),
    .backend_drained_o(backend_drained),
    .jump_dispatch_valid_o(),
    .system_csr_dispatch_valid_o(system_csr_dispatch_valid),
    .system_csr_dispatch_fire_o(system_csr_dispatch_fire),
    .pending_branch_commit_resolve_o(),
    .pending_branch_match_clear_o(),
    .pending_replay_wait_o(pending_replay_wait),
    .drain_complete_o(drain_complete)
  );

  OooStopPendingSequencer u_stop_sequencer (
    .clk(clk),
    .rst(rst),
    .flush_i(1'b0),
    .csr_trap_mem_valid_i(trap_mem_valid),
    .direct_frontend_flush_i(direct_frontend_flush),
    .direct_branch0_fire_i(1'b0),
    .direct_branch1_fire_i(1'b0),
    .direct_branch_resolve_redirect_i(1'b0),
    .branch_spec_checkpoint_capture_i(1'b0),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid),
    .orphan_stop_pending_i(orphan_stop_pending),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(1'b0),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_nolink_commit_i(1'b0),
    .pending_jump_redirect_after_dispatch_i(1'b0),
    .jump_dispatch_fire_i(1'b0),
    .pending_mem_resolve_ready_i(1'b0),
    .system_csr_dispatch_fire_i(system_csr_dispatch_fire),
    .pending_system_csr_commit_i(1'b0),
    .head0_csr_commit_i(1'b0),
    .head0_csr_inflight_i(1'b0),
    .head0_csr_owner_birth_i(1'b0),
    .head0_csr_owner_kill_i(1'b0),
    .pending_owner_birth_i(pending_owner_birth),
    .pending_owner_live_i(pending_owner_live),
    .pending_system_producer_valid_i(pending_system_producer_valid),
    .core_local_flush_i(core_local_flush),
    .drain_complete_i(drain_complete),
    .rob_walk_mode_i(1'b1),
    .stop_pending_o(stop_pending)
  );

  OooCsrTrapRequestMux u_trap_request_mux (
    .core_commit0_valid_i(core_commit0_valid),
    .core_commit0_exception_i(core_commit0_exception),
    .core_commit0_pc_i(core_commit0_pc),
    .core_commit0_cause_i(core_commit0_cause),
    .core_commit0_tval_i(core_commit0_tval),
    .core_commit1_valid_i(1'b0),
    .core_commit1_exception_i(1'b0),
    .core_commit1_pc_i({`XLEN{1'b0}}),
    .core_commit1_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .core_commit1_tval_i({`XLEN{1'b0}}),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_trap_cause_i(pending_trap_cause),
    .pending_trap_pc_i(pending_trap_pc),
    .pending_trap_tval_i(pending_trap_tval),
    .pending_system_i(pending_system),
    .pending_system_ecall_i(pending_system_ecall),
    .pending_system_mret_i(pending_system_mret),
    .pending_system_irq_i(pending_system_irq),
    .pending_system_pc_i(pending_system_pc),
    .pending_system_inst_i(pending_system_inst),
    .pending_system_irq_cause_i(pending_system_irq_cause),
    .csr_ecall_cause_i(csr_ecall_cause),
    .pending_system_satp_write_commit_i(1'b0),
    .pending_system_sfence_commit_i(1'b0),
    .core_commit_exception_trap_o(core_commit_exception_trap),
    .trap_mem_valid_o(trap_mem_valid),
    .trap_mem_pc_o(trap_mem_pc),
    .trap_mem_cause_o(trap_mem_cause),
    .trap_mem_tval_o(trap_mem_tval),
    .pending_system_ecall_trap_o(pending_system_ecall_trap),
    .pending_arch_trap_fire_o(pending_arch_trap_fire),
    .trap_ex_valid_o(trap_ex_valid),
    .trap_ex_pc_o(trap_ex_pc),
    .trap_ex_cause_o(trap_ex_cause),
    .trap_ex_tval_o(trap_ex_tval),
    .trap_irq_valid_o(trap_irq_valid),
    .trap_irq_pc_o(trap_irq_pc),
    .trap_irq_cause_o(trap_irq_cause),
    .mret_valid_o(mret_valid),
    .sret_valid_o(sret_valid),
    .real_mret_valid_o(real_mret_valid),
    .priv_predictor_boundary_o(priv_predictor_boundary)
  );

  OooTrapExitEventMux u_trap_exit_event_mux (
    .csr_trap_mem_valid_i(trap_mem_valid),
    .direct_frontend_flush_i(direct_frontend_flush),
    .stop_pending_i(stop_pending),
    .drain_complete_i(drain_complete),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid),
    .branch_spec_restore_i(branch_spec_restore),
    .core_branch_resolve_misaligned_i(branch_spec_misaligned),
    .core_branch_resolve_pc_i(ARCH_PC),
    .core_branch_resolve_next_pc_i(ARCH_PC + 64'd2),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(1'b0),
    .pending_branch_misaligned_i(1'b0),
    .pending_branch_pc_i({`XLEN{1'b0}}),
    .pending_branch_target_i({`XLEN{1'b0}}),
    .pending_branch_valid_i(1'b0),
    .pending_branch_dispatched_i(1'b0),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_pc_i({`XLEN{1'b0}}),
    .pending_jump_resolved_target_i({`XLEN{1'b0}}),
    .pending_mem_resolve_ready_i(1'b0),
    .system_csr_dispatch_fire_i(system_csr_dispatch_fire),
    .pending_system_csr_commit_i(1'b0),
    .pending_arch_trap_i(pending_arch_trap),
    .pending_system_i(pending_system),
    .pending_jump_i(1'b0),
    .pending_mem_i(1'b0),
    .pending_exit_i(pending_exit),
    .pending_exit_is_ecall_i(pending_exit_ecall),
    .pending_exit_is_ebreak_i(pending_exit_ebreak),
    .pending_trap_cause_i(pending_trap_cause),
    .pending_trap_pc_i(pending_trap_pc),
    .pending_trap_tval_i(pending_trap_tval),
    .trap_o(raw_trap),
    .trap_cause_o(raw_trap_cause),
    .trap_pc_o(raw_trap_pc),
    .trap_tval_o(raw_trap_tval),
    .exit_o(raw_exit),
    .exit_is_ecall_o(raw_exit_ecall),
    .exit_is_ebreak_o(raw_exit_ebreak)
  );

  OooTrapExitOutputSequencer u_trap_exit_output_sequencer (
    .clk(clk),
    .rst(rst),
    .trap_i(raw_trap),
    .trap_cause_i(raw_trap_cause),
    .trap_pc_i(raw_trap_pc),
    .trap_tval_i(raw_trap_tval),
    .exit_i(raw_exit),
    .exit_is_ecall_i(raw_exit_ecall),
    .exit_is_ebreak_i(raw_exit_ebreak),
    .trap_valid_o(trap_valid),
    .trap_cause_o(terminal_trap_cause),
    .trap_pc_o(terminal_trap_pc),
    .trap_tval_o(terminal_trap_tval),
    .exit_valid_o(exit_valid),
    .exit_is_ecall_o(exit_ecall),
    .exit_is_ebreak_o(exit_ebreak),
    .halted_o(halted)
  );

  CsrFile u_csr_file (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(1'b0),
    .time_i({`XLEN{1'b0}}),
    .instret_inc_i(2'b00),
    .csr_valid_i(1'b0),
    .csr_addr_i(12'h000),
    .csr_funct3_i(3'b000),
    .csr_rs1_idx_i({`REG_ADDR_W{1'b0}}),
    .csr_rs1_data_i({`XLEN{1'b0}}),
    .csr_zimm_i(5'd0),
    .csr_commit_i(1'b0),
    .csr_probe_valid_i(1'b0),
    .csr_probe_addr_i(12'h000),
    .csr_probe_funct3_i(3'b000),
    .csr_probe_rs1_idx_i({`REG_ADDR_W{1'b0}}),
    .csr_rdata_o(),
    .csr_illegal_o(),
    .fp_fflags_valid_i(1'b0),
    .fp_fflags_i(5'b00000),
    .fp_dirty_i(1'b0),
    .trap_mem_valid_i(trap_mem_valid),
    .trap_mem_pc_i(trap_mem_pc),
    .trap_mem_cause_i(trap_mem_cause),
    .trap_mem_tval_i(trap_mem_tval),
    .trap_ex_valid_i(trap_ex_valid),
    .trap_ex_pc_i(trap_ex_pc),
    .trap_ex_cause_i(trap_ex_cause),
    .trap_ex_tval_i(trap_ex_tval),
    .irq_software_i(1'b0),
    .irq_timer_i(1'b0),
    .irq_external_i(1'b0),
    .irq_pending_o(),
    .irq_cause_o(),
    .trap_irq_valid_i(trap_irq_valid),
    .trap_irq_pc_i(trap_irq_pc),
    .trap_irq_cause_i(trap_irq_cause),
    .mret_valid_i(real_mret_valid),
    .sret_valid_i(sret_valid),
    .trap_target_o(csr_trap_target),
    .mepc_o(csr_mepc),
    .ret_target_o(csr_ret_target),
    .priv_mode_o(csr_priv_mode),
    .ecall_cause_o(csr_ecall_cause),
    .mstatus_o(csr_mstatus),
    .satp_o(csr_satp),
    .svpbmt_en_o(csr_svpbmt_en),
    .frm_o(csr_frm),
    .pmpcfg_o(csr_pmpcfg),
    .pmpaddr_o(csr_pmpaddr)
  );

  always @(posedge clk) begin
    if (rst) begin
      pending_arch_request_count_q <= 0;
      csr_arch_accept_count_q <= 0;
      csr_mem_accept_count_q <= 0;
      raw_exit_count_q <= 0;
      raw_trap_count_q <= 0;
    end else begin
      if (pending_arch_trap_fire)
        pending_arch_request_count_q <=
            pending_arch_request_count_q + 1;
      if (trap_ex_valid && !trap_mem_valid)
        csr_arch_accept_count_q <= csr_arch_accept_count_q + 1;
      if (trap_mem_valid)
        csr_mem_accept_count_q <= csr_mem_accept_count_q + 1;
      if (raw_exit)
        raw_exit_count_q <= raw_exit_count_q + 1;
      if (raw_trap)
        raw_trap_count_q <= raw_trap_count_q + 1;
    end
  end

  task automatic check_int;
    input [1023:0] what;
    input integer got;
    input integer exp;
    begin
      if (got != exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=%0d expected=%0d",
                 what, got, exp);
      end
    end
  endtask

  task automatic check_xlen;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=%h expected=%h",
                 what, got, exp);
      end
    end
  endtask

  task automatic clear_inputs;
    begin
      fifo_has_packet = 1'b0;
      csr_irq_pending = 1'b0;
      direct_frontend_flush = 1'b0;
      dispatch1_barrier_fire = 1'b0;
      head0_facts = {`OOO_SLOT_FACTS_W{1'b0}};
      head1_facts = {`OOO_SLOT_FACTS_W{1'b0}};
      head_pc0 = ARCH_PC;
      head_pc1 = ARCH_PC + 64'd4;
      head_inst0 = INST_ADDI;
      head_inst1 = INST_ADDI;
      head0_csr = 1'b0;
      head0_ecall = 1'b0;
      head0_mret = 1'b0;
      head0_wfi = 1'b0;
      head0_sfence = 1'b0;
      head0_fencei = 1'b0;
      head1_csr = 1'b0;
      head1_ecall = 1'b0;
      head1_mret = 1'b0;
      head1_wfi = 1'b0;
      head1_sfence = 1'b0;
      head1_fencei = 1'b0;
      mem_owner_terminalized = 1'b0;
      mem_idle = 1'b1;
      core_local_flush = 1'b0;
      branch_spec_active = 1'b0;
      branch_spec_checkpoint_pending = 1'b0;
      branch_spec_resolve_valid = 1'b0;
      branch_spec_restore = 1'b0;
      branch_spec_misaligned = 1'b0;
      core_commit0_valid = 1'b0;
      core_commit0_exception = 1'b0;
      core_commit0_pc = MEM_PC;
      core_commit0_cause = `EXC_LOAD_ACCESS_FAULT;
      core_commit0_tval = MEM_PC + 64'h80;
    end
  endtask

  task automatic reset_case;
    begin
      clear_inputs();
      rst = 1'b1;
      `TB_TICK(clk);
      rst = 1'b0;
      `TB_TICK(clk);
    end
  endtask

  task automatic drive_arch_candidate;
    begin
      clear_inputs();
      fifo_has_packet = 1'b1;
      head_inst0 = INST_BAD;
      head0_facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
    end
  endtask

  task automatic drive_exit_candidate;
    input integer lane;
    input integer is_ecall;
    begin
      clear_inputs();
      fifo_has_packet = 1'b1;
      if (lane == 0) begin
        head0_facts[`OOO_SLOT_FACT_EXIT] = 1'b1;
        head0_facts[`OOO_SLOT_FACT_ECALL] = is_ecall != 0;
        head0_facts[`OOO_SLOT_FACT_EBREAK] = is_ecall == 0;
        head_inst0 = is_ecall ? INST_ECALL : INST_EBREAK;
      end else begin
        dispatch1_barrier_fire = 1'b1;
        head1_facts[`OOO_SLOT_FACT_EXIT] = 1'b1;
        head1_facts[`OOO_SLOT_FACT_ECALL] = is_ecall != 0;
        head1_facts[`OOO_SLOT_FACT_EBREAK] = is_ecall == 0;
        head_inst1 = is_ecall ? INST_ECALL : INST_EBREAK;
      end
    end
  endtask

  task automatic drive_system_candidate;
    input integer kind;
    begin
      clear_inputs();
      fifo_has_packet = 1'b1;
      case (kind)
        KIND_ECALL: begin
          head0_facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
          head0_ecall = 1'b1;
          head_inst0 = INST_ECALL;
        end
        KIND_IRQ: begin
          csr_irq_pending = 1'b1;
        end
        KIND_XRET: begin
          head0_facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
          head0_mret = 1'b1;
          head_inst0 = INST_MRET;
        end
        KIND_CSR: begin
          dispatch1_barrier_fire = 1'b1;
          head1_facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
          head1_facts[`OOO_SLOT_FACT_CSR] = 1'b1;
          head1_csr = 1'b1;
          head_inst1 = INST_CSR;
        end
        KIND_FENCE: begin
          head0_facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
          head_inst0 = INST_FENCE;
        end
        default: begin end
      endcase
    end
  endtask

  task automatic check_pending_kind;
    input integer kind;
    begin
      tb_check1("V10A standalone system owner valid",
                pending_system, 1'b1);
      tb_check1("V10A standalone owner excludes arch",
                pending_arch_trap, 1'b0);
      tb_check1("V10A standalone owner holds stop",
                stop_pending, 1'b1);
      tb_check1("V10A standalone system kind exact-one",
                pending_system_kind_count == 4'd1, 1'b1);
      case (kind)
        KIND_ECALL:
          tb_check1("V10A ECALL kind", pending_system_ecall, 1'b1);
        KIND_IRQ:
          tb_check1("V10A IRQ kind", pending_system_irq, 1'b1);
        KIND_XRET:
          tb_check1("V10A xRET kind", pending_system_mret, 1'b1);
        KIND_CSR:
          tb_check1("V10A CSR kind", pending_system_csr, 1'b1);
        KIND_FENCE:
          tb_check1("V10A FENCE kind", pending_system_fence, 1'b1);
        default:
          tb_check1("V10A invalid kind", 1'b0, 1'b1);
      endcase
    end
  endtask

  task automatic test_same_edge_birth_priority;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_arch_candidate();
      head0_facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
      head0_ecall = 1'b1;
      #1;
      tb_check1("V10A head0 arch wins system birth",
                pending_trap_capture_arch, 1'b1);
      tb_check1("V10A head0 system birth suppressed",
                pending_system_capture_head0, 1'b0);
      `TB_TICK(clk);
      tb_check1("V10A head0 registered arch owner",
                pending_arch_trap, 1'b1);
      tb_check1("V10A head0 registered system absent",
                pending_system, 1'b0);
      tb_check1("V10A head0 registered stop",
                stop_pending, 1'b1);

      reset_case();
      clear_inputs();
      fifo_has_packet = 1'b1;
      dispatch1_barrier_fire = 1'b1;
      head1_facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
      head1_facts[`OOO_SLOT_FACT_ILLEGAL] = 1'b1;
      head1_facts[`OOO_SLOT_FACT_SYSTEM] = 1'b1;
      head1_facts[`OOO_SLOT_FACT_CSR] = 1'b1;
      head1_csr = 1'b1;
      head_inst1 = INST_BAD;
      #1;
      tb_check1("V10A lane1 arch wins system birth",
                pending_trap_capture_arch, 1'b1);
      tb_check1("V10A lane1 system birth suppressed",
                pending_system_capture_lane1, 1'b0);
      `TB_TICK(clk);
      tb_check1("V10A lane1 registered arch owner",
                pending_arch_trap, 1'b1);
      tb_check1("V10A lane1 registered system absent",
                pending_system, 1'b0);
      tb_check1("V10A lane1 registered stop",
                stop_pending, 1'b1);

      reset_case();
      drive_arch_candidate();
      csr_irq_pending = 1'b1;
      #1;
      tb_check1("V10A IRQ birth accepted",
                pending_system_capture_irq, 1'b1);
      tb_check1("V10A IRQ suppresses arch birth",
                pending_trap_capture_arch, 1'b0);
      `TB_TICK(clk);
      tb_check1("V10A IRQ registered owner",
                pending_system_irq, 1'b1);
      tb_check1("V10A IRQ registered arch absent",
                pending_arch_trap, 1'b0);
      tb_check1("V10A IRQ registered stop",
                stop_pending, 1'b1);
      if (tb_errors == errors_before)
        $display("[V10A-BIRTH-ONEHOT-PASS] head0-arch=1 lane1-arch=1 irq-priority=1");
      else
        $display("[V10A-BIRTH-ONEHOT-RED] errors=%0d",
                 tb_errors - errors_before);
    end
  endtask

  task automatic test_standalone_system_kinds;
    integer kind;
    integer errors_before;
    begin
      for (kind = KIND_ECALL; kind <= KIND_FENCE; kind = kind + 1) begin
        errors_before = tb_errors;
        reset_case();
        drive_system_candidate(kind);
        #1;
        tb_check1("V10A standalone system candidate can run",
                  can_run, 1'b1);
        case (kind)
          KIND_IRQ:
            tb_check1("V10A standalone IRQ capture",
                      pending_system_capture_irq, 1'b1);
          KIND_CSR:
            tb_check1("V10A standalone lane1 CSR capture",
                      pending_system_capture_lane1, 1'b1);
          default:
            tb_check1("V10A standalone head0 system capture",
                      pending_system_capture_head0, 1'b1);
        endcase
        `TB_TICK(clk);
        check_pending_kind(kind);
        if (tb_errors == errors_before)
          $display("[V10A-SYSTEM-KIND-PASS] kind=%0d exact-one=1", kind);
        else
          $display("[V10A-SYSTEM-KIND-RED] kind=%0d errors=%0d",
                   kind, tb_errors - errors_before);
      end
    end
  endtask

  task automatic test_live_arch_blocks_system_kinds;
    integer kind;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_arch_candidate();
      #1;
      tb_check1("V10A arch capture request",
                pending_trap_capture_arch, 1'b1);
      `TB_TICK(clk);
      tb_check1("V10A live arch owner", pending_arch_trap, 1'b1);
      tb_check1("V10A live arch stop", stop_pending, 1'b1);

      blocked_kind_count_q = 0;
      for (kind = KIND_ECALL; kind <= KIND_FENCE; kind = kind + 1) begin
        drive_system_candidate(kind);
        #1;
        tb_check1("V10A live arch blocks frontend run",
                  can_run, 1'b0);
        tb_check1("V10A live arch blocks IRQ capture",
                  pending_system_capture_irq, 1'b0);
        tb_check1("V10A live arch blocks head0 system capture",
                  pending_system_capture_head0, 1'b0);
        tb_check1("V10A live arch blocks lane1 system capture",
                  pending_system_capture_lane1, 1'b0);
        tb_check1("V10A live arch excludes system owner",
                  pending_system, 1'b0);
        `TB_TICK(clk);
        tb_check1("V10A blocked attempt preserves arch owner",
                  pending_arch_trap, 1'b1);
        tb_check1("V10A blocked attempt preserves stop",
                  stop_pending, 1'b1);
        blocked_kind_count_q = blocked_kind_count_q + 1;
      end
      check_int("V10A blocked ECALL/IRQ/xRET/CSR/FENCE count",
                blocked_kind_count_q, 5);
      if (tb_errors == errors_before)
        $display("[V10A-LIVE-OWNER-OVERLAP-PASS] ECALL=blocked IRQ=blocked xRET=blocked CSR=blocked FENCE=blocked");
      else
        $display("[V10A-LIVE-OWNER-OVERLAP-RED] errors=%0d",
                 tb_errors - errors_before);
    end
  endtask

  task automatic test_commit_trap_priority;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_arch_candidate();
      `TB_TICK(clk);
      clear_inputs();
      mem_owner_terminalized = 1'b1;
      core_commit0_valid = 1'b1;
      core_commit0_exception = 1'b1;
      #1;
      tb_check1("V10A commit trap overlap reaches drain",
                drain_complete, 1'b1);
      tb_check1("V10A commit trap request selected",
                trap_mem_valid, 1'b1);
      // A lower-priority pending architectural trap is not an accepted
      // CsrFile request while the commit trap owns the same edge.
      tb_check1("V10A commit trap masks pending arch request",
                pending_arch_trap_fire, 1'b0);
      tb_check1("V10A commit trap masks trap-ex request",
                trap_ex_valid, 1'b0);
      `TB_TICK(clk);
      check_int("V10A commit overlap raw arch request count",
                pending_arch_request_count_q, 0);
      check_int("V10A commit overlap accepted arch count",
                csr_arch_accept_count_q, 0);
      check_int("V10A commit overlap accepted mem count",
                csr_mem_accept_count_q, 1);
      check_xlen("V10A commit trap owns CsrFile mepc",
                 csr_mepc, MEM_PC);
      tb_check1("V10A commit trap late-clears arch owner",
                pending_arch_trap, 1'b0);
      tb_check1("V10A commit trap clears stop owner",
                stop_pending, 1'b0);
      clear_inputs();
      `TB_TICK(clk);
      check_int("V10A commit overlap remains no-repeat",
                pending_arch_request_count_q, 0);
      if (tb_errors == errors_before)
        $display("[V10A-COMMIT-TRAP-PRIORITY-PASS] mem-selected=1 arch-request=0 C1-clear=1 C2-repeat=0");
      else
        $display("[V10A-COMMIT-TRAP-PRIORITY-RED] errors=%0d",
                 tb_errors - errors_before);
    end
  endtask

  task automatic test_clocked_arch_exactly_once;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_arch_candidate();
      #1;
      tb_check1("V10A exact-once arch birth request",
                pending_trap_capture_arch, 1'b1);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("V10A active memory holder blocks drain",
                drain_complete, 1'b0);
      tb_check1("V10A active memory holder blocks arch fire",
                pending_arch_trap_fire, 1'b0);
      `TB_TICK(clk);
      tb_check1("V10A blocked cycle retains arch owner",
                pending_arch_trap, 1'b1);
      tb_check1("V10A blocked cycle retains stop",
                stop_pending, 1'b1);
      check_int("V10A blocked cycle arch request count",
                pending_arch_request_count_q, 0);

      mem_owner_terminalized = 1'b1;
      #1;
      tb_check1("V10A C0 exact terminal completes drain",
                drain_complete, 1'b1);
      tb_check1("V10A C0 arch request fires",
                pending_arch_trap_fire, 1'b1);
      tb_check1("V10A C0 trap-ex reaches CsrFile",
                trap_ex_valid, 1'b1);
      tb_check1("V10A C0 has no commit trap",
                trap_mem_valid, 1'b0);
      tb_check1("V10A C0 has no IRQ request",
                trap_irq_valid, 1'b0);
      tb_check1("V10A C0 has no xRET request",
                mret_valid, 1'b0);
      check_xlen("V10A C0 arch PC payload",
                 trap_ex_pc, ARCH_PC);
      check_xlen("V10A C0 arch tval payload",
                 trap_ex_tval, INST_BAD);
      `TB_TICK(clk);

      check_int("V10A C1 raw arch request exactly once",
                pending_arch_request_count_q, 1);
      check_int("V10A C1 CsrFile accepted arch exactly once",
                csr_arch_accept_count_q, 1);
      check_int("V10A C1 no commit trap sample",
                csr_mem_accept_count_q, 0);
      check_xlen("V10A C1 CsrFile mepc",
                 csr_mepc, ARCH_PC);
      tb_check1("V10A C1 clears arch owner",
                pending_arch_trap, 1'b0);
      tb_check1("V10A C1 clears system owner",
                pending_system, 1'b0);
      tb_check1("V10A C1 clears stop",
                stop_pending, 1'b0);
      tb_check1("V10A C1 request is low",
                pending_arch_trap_fire, 1'b0);

      `TB_TICK(clk);
      `TB_TICK(clk);
      check_int("V10A C2 raw arch request no-repeat",
                pending_arch_request_count_q, 1);
      check_int("V10A C2 CsrFile sample no-repeat",
                csr_arch_accept_count_q, 1);
      check_xlen("V10A C2 CsrFile mepc stable",
                 csr_mepc, ARCH_PC);
      tb_check1("V10A C2 arch owner remains clear",
                pending_arch_trap, 1'b0);
      tb_check1("V10A C2 stop remains clear",
                stop_pending, 1'b0);
      if (tb_errors == errors_before)
        $display("[V10A-CLOCKED-EXACTLY-ONCE-PASS] C0-fire=1 C1-owner-clear=1 C1-stop-clear=1 CsrFile-samples=1 C2-repeat=0");
      else
        $display("[V10A-CLOCKED-EXACTLY-ONCE-RED] errors=%0d",
                 tb_errors - errors_before);
    end
  endtask

  task automatic test_exit_lane_exactly_once;
    input integer lane;
    input integer is_ecall;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_exit_candidate(lane, is_ecall);
      #1;
      tb_check1("V10D exit candidate can run", can_run, 1'b1);
      tb_check1("V10D exit capture request",
                pending_trap_capture_exit, 1'b1);
      tb_check1("V10D exit capture valid",
                pending_trap_capture_exit_valid, 1'b1);
      tb_check1("V10D exit capture ecall kind",
                pending_trap_capture_exit_ecall, is_ecall != 0);
      tb_check1("V10D exit capture ebreak kind",
                pending_trap_capture_exit_ebreak, is_ecall == 0);
      `TB_TICK(clk);

      clear_inputs();
      #1;
      tb_check1("V10D registered exit owner", pending_exit, 1'b1);
      tb_check1("V10D registered exit ecall kind",
                pending_exit_ecall, is_ecall != 0);
      tb_check1("V10D registered exit ebreak kind",
                pending_exit_ebreak, is_ecall == 0);
      tb_check1("V10D registered exit stop", stop_pending, 1'b1);
      tb_check1("V10D active memory holder blocks drain",
                drain_complete, 1'b0);
      tb_check1("V10D active memory holder blocks raw exit",
                raw_exit, 1'b0);
      `TB_TICK(clk);
      tb_check1("V10D blocked cycle retains exit owner",
                pending_exit, 1'b1);
      tb_check1("V10D blocked cycle retains stop",
                stop_pending, 1'b1);
      check_int("V10D blocked cycle raw exit count",
                raw_exit_count_q, 0);

      // mem_idle intentionally stays low: simulation exit consumes the V9Y
      // exact terminal scalar, not the stronger ordinary-FENCE full-idle
      // predicate.
      mem_idle = 1'b0;
      mem_owner_terminalized = 1'b1;
      #1;
      tb_check1("V10D C0 exact terminal completes drain",
                drain_complete, 1'b1);
      tb_check1("V10D C0 raw exit pulse", raw_exit, 1'b1);
      tb_check1("V10D C0 raw trap excluded", raw_trap, 1'b0);
      tb_check1("V10D C0 raw exit ecall kind",
                raw_exit_ecall, is_ecall != 0);
      tb_check1("V10D C0 raw exit ebreak kind",
                raw_exit_ebreak, is_ecall == 0);
      `TB_TICK(clk);

      check_int("V10D C1 raw exit exactly once",
                raw_exit_count_q, 1);
      check_int("V10D C1 raw trap count",
                raw_trap_count_q, 0);
      tb_check1("V10D C1 clears exit owner", pending_exit, 1'b0);
      tb_check1("V10D C1 clears stop", stop_pending, 1'b0);
      tb_check1("V10D C1 raw exit is low", raw_exit, 1'b0);
      tb_check1("V10D C1 latches exit status", exit_valid, 1'b1);
      tb_check1("V10D C1 latches halted status", halted, 1'b1);
      tb_check1("V10D C1 output ecall kind",
                exit_ecall, is_ecall != 0);
      tb_check1("V10D C1 output ebreak kind",
                exit_ebreak, is_ecall == 0);

      `TB_TICK(clk);
      `TB_TICK(clk);
      check_int("V10D C2 raw exit no-repeat",
                raw_exit_count_q, 1);
      tb_check1("V10D C2 exit owner remains clear",
                pending_exit, 1'b0);
      tb_check1("V10D C2 stop remains clear",
                stop_pending, 1'b0);
      tb_check1("V10D C2 raw exit remains low", raw_exit, 1'b0);
      tb_check1("V10D C2 latched exit remains high",
                exit_valid, 1'b1);
      if (tb_errors == errors_before)
        $display("[V10D-EXIT-EXACTLY-ONCE-PASS] lane=%0d kind=%0s C0-raw=1 C1-owner-stop-clear=1 C2-repeat=0",
                 lane, is_ecall ? "ECALL" : "EBREAK");
      else
        $display("[V10D-EXIT-EXACTLY-ONCE-RED] lane=%0d errors=%0d",
                 lane, tb_errors - errors_before);
    end
  endtask

  task automatic test_exit_core_local_flush_kill;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_exit_candidate(0, 0);
      `TB_TICK(clk);
      clear_inputs();
      core_local_flush = 1'b1;
      mem_owner_terminalized = 1'b0;
      #1;
      tb_check1("V10D local flush active-holder raw exit blocked",
                raw_exit, 1'b0);
      `TB_TICK(clk);
      tb_check1("V10D local flush clears exit owner",
                pending_exit, 1'b0);
      tb_check1("V10D local flush clears stop owner",
                stop_pending, 1'b0);
      tb_check1("V10D local flush does not latch exit",
                exit_valid, 1'b0);
      tb_check1("V10D local flush does not halt", halted, 1'b0);
      check_int("V10D local flush raw exit count",
                raw_exit_count_q, 0);
      core_local_flush = 1'b0;
      mem_owner_terminalized = 1'b1;
      `TB_TICK(clk);
      tb_check1("V10D killed exit cannot revive", raw_exit, 1'b0);
      check_int("V10D killed exit remains no-event",
                raw_exit_count_q, 0);
      if (tb_errors == errors_before)
        $display("[V10D-EXIT-LOCAL-FLUSH-PASS] owner=0 stop=0 raw-exit=0 output=0");
      else
        $display("[V10D-EXIT-LOCAL-FLUSH-RED] errors=%0d",
                 tb_errors - errors_before);
    end
  endtask

  task automatic test_exit_branch_spec_priority;
    integer errors_before;
    begin
      errors_before = tb_errors;
      reset_case();
      drive_exit_candidate(0, 0);
      // The speculative branch remains older while the younger exit obtains
      // its registered holder/stop lease.  branch_spec_active alone does not
      // stall fetch; the accepted exit owner does so from the next cycle.
      branch_spec_active = 1'b1;
      #1;
      tb_check1("V10D younger exit capture below older branch",
                pending_trap_capture_exit, 1'b1);
      `TB_TICK(clk);
      tb_check1("V10D younger exit owner registered",
                pending_exit, 1'b1);
      tb_check1("V10D younger exit stop registered",
                stop_pending, 1'b1);

      clear_inputs();
      branch_spec_active = 1'b1;
      branch_spec_checkpoint_pending = 1'b1;
      branch_spec_resolve_valid = 1'b1;
      branch_spec_restore = 1'b1;
      branch_spec_misaligned = 1'b1;
      mem_owner_terminalized = 1'b1;
      #1;
      tb_check1("V10D exit lease blocks frontend on recovery",
                can_run, 1'b0);
      tb_check1("V10D recovery cycle has no exit recapture",
                pending_trap_capture_exit, 1'b0);
      tb_check1("V10D older branch recovery emits trap", raw_trap, 1'b1);
      tb_check1("V10D older branch recovery excludes raw exit",
                raw_exit, 1'b0);
      `TB_TICK(clk);
      clear_inputs();
      #1;
      tb_check1("V10D branch recovery latches trap", trap_valid, 1'b1);
      tb_check1("V10D branch recovery does not latch exit",
                exit_valid, 1'b0);
      tb_check1("V10D branch recovery creates no exit owner",
                pending_exit, 1'b0);
      tb_check1("V10D branch recovery creates no stop owner",
                stop_pending, 1'b0);
      check_int("V10D branch recovery raw trap count",
                raw_trap_count_q, 1);
      check_int("V10D branch recovery raw exit count",
                raw_exit_count_q, 0);
      if (tb_errors == errors_before)
        $display("[V10D-EXIT-RECOVERY-PRIORITY-PASS] branch-trap=1 raw-exit=0 dual-latch=0");
      else
        $display("[V10D-EXIT-RECOVERY-PRIORITY-RED] errors=%0d",
                 tb_errors - errors_before);
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    blocked_kind_count_q = 0;
    clear_inputs();

    if (!$test$plusargs("V10D_ONLY")) begin
      test_same_edge_birth_priority();
      test_standalone_system_kinds();
      test_live_arch_blocks_system_kinds();
      test_commit_trap_priority();
      test_clocked_arch_exactly_once();
    end
    test_exit_lane_exactly_once(0, 0);
    test_exit_lane_exactly_once(1, 1);
    test_exit_core_local_flush_kill();
    test_exit_branch_spec_priority();

    tb_finish("tb_ooo_serialized_owner_exactly_once");
  end

endmodule
