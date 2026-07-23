`timescale 1ns/1ps
`include "define.v"
`include "common/OooSlotFacts.v"

// IFU-ACCESS-G1 / IFU-LANE1-OWNER permanent contract:
// 可见的 lane1 PF/AF 必须先成为 precise pending trap；只有随后证实 branch
// actual-taken 时才 squash。fetch-time pred-taken 截断的 poison slot1 从未成为 owner。
module tb_ooo_ifu_lane1_fault_owner;
  `include "tb_common.svh"

  localparam [`XLEN-1:0] PC0 = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] PC1 = 64'h0000_0000_8000_1004;
  localparam [`XLEN-1:0] FAULT_TVAL = 64'h0000_0000_8000_1006;
  localparam [`INST_W-1:0] INST_ADDI = 32'h0000_0093;
  localparam [`INST_W-1:0] INST_BNE_X0_X0 = 32'h0000_1063;
  localparam [`INST_W-1:0] INST_BEQ_X0_X0 = 32'h0000_0063;
  localparam [`XLEN-1:0] STREAM_CC = 64'h0000_0000_0001_0001;
  localparam [`XLEN-1:0] STREAM_CU = 64'h0000_0000_0093_0001;
  localparam [`XLEN-1:0] STREAM_UC = 64'h0000_0001_0000_0093;
  localparam [`XLEN-1:0] STREAM_UU = 64'h0000_0093_0000_0093;
  // c.beqz x8,-4 followed by a 32-bit ADDI.  At F=4 the conditional
  // control instruction starts at PC0, lane1 starts at PC0+2, and the
  // failing upper halfword belongs to PC0+4.
  localparam [`XLEN-1:0] STREAM_CBR_U = 64'h0000_0000_0093_dc75;

  reg clk;
  reg rst;

  reg fifo_has_packet;
  reg head_slot1_valid;
  reg [1:0] head_resp0;
  reg [1:0] head_resp1;
  reg [`INST_W-1:0] head_inst0;
  reg [`INST_W-1:0] head_inst1;
  reg [`CTRL_BUS_W-1:0] head0_ctrl;
  reg [`CTRL_BUS_W-1:0] head1_ctrl;
  reg head0_branch_pred_taken;
  reg dispatch0_ready;
  reg dispatch1_ready;
  reg branch_resolve_untracked;
  reg drain_complete;
  reg decoder_owner_mode;
  reg [`XLEN-1:0] decoder_rsp_pc;
  reg [`INST_W-1:0] decoder_rsp_inst0;
  reg [`INST_W-1:0] decoder_rsp_inst1;
  reg [1:0] decoder_rsp_resp0;
  reg [1:0] decoder_rsp_resp1;
  reg [2:0] decoder_rsp_resp0_bytes;
  integer row_count_q;
  integer terminal_rows_q;
  integer squash_rows_q;
  integer poison_rows_q;
  integer pseudo_rows_q;
  integer owner_map_rows_q;
  integer owner_map_lane0_rows_q;
  integer owner_map_lane1_rows_q;
  integer tval_rows_q;
  integer tval_pf_rows_q;
  integer tval_af_rows_q;
  integer tval_lane0_rows_q;
  integer tval_lane1_rows_q;
  integer tval_f0_rows_q;
  integer tval_f2_rows_q;
  integer tval_f4_rows_q;
  integer tval_f6_rows_q;
  integer tval_capture_rows_q;
  integer tval_pending_rows_q;
  integer tval_drain_rows_q;
  integer tval_control_rows_q;
  integer tval_control_terminal_rows_q;
  integer tval_control_squash_rows_q;
  integer tval_control_poison_rows_q;
  integer tval_dispatch_stall_rows_q;

  // 这一路只用于锁住旧 ROB-walk 伪 ACCESS 过滤：arch_trap fact 存在、但没有
  // head_fetch_fault1 provenance 时，默认 cause=ACCESS 不得被误当成真实 IFU AF。
  reg pseudo_default_access;
  reg [`OOO_SLOT_FACTS_W-1:0] pseudo_head1_facts;

  wire head_fetch_fault0;
  wire head_fetch_fault1;
  wire head_fetch_fault;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts0;
  wire [`OOO_SLOT_STATIC_FACTS_W-1:0] head_static_facts1;
  wire head0_fp_raw;
  wire head0_csr_raw;
  wire head1_fp_raw;
  wire head1_control_raw;
  wire head1_branch_raw;
  wire head1_jal_raw;
  wire head1_jalr_raw;
  wire head1_exit_raw;
  wire head1_system_raw;
  wire head1_arch_trap_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] head0_facts;
  wire [`OOO_SLOT_FACTS_W-1:0] head1_facts;
  wire dispatch_valid;
  wire dispatch0_exit;
  wire dispatch0_arch_trap;
  wire dispatch0_system;
  wire dispatch0_fp;
  wire dispatch0_branch;
  wire dispatch0_jal;
  wire dispatch0_jump;
  wire direct_branch0_dispatch_valid;

  wire effective_head1_arch_trap =
      pseudo_default_access ? 1'b1 : head1_arch_trap_raw;
  wire [`OOO_SLOT_FACTS_W-1:0] effective_head1_facts =
      pseudo_default_access ? pseudo_head1_facts : head1_facts;

  wire dispatch_unsupported;
  wire dispatch_fire;
  wire dispatch1_barrier;
  wire dispatch1_barrier_fire;
  wire frontend_dispatch_to_backend_valid;
  wire dbranch_dual_go;

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
  wire stop_pending;

  wire pending_arch_trap_fire;
  wire trap_ex_valid;
  wire [`TRAP_CAUSE_W-1:0] trap_ex_cause;
  wire [`XLEN-1:0] trap_ex_pc;
  wire [`XLEN-1:0] trap_ex_tval;

  wire [`XLEN-1:0] decoder_dec0_pc;
  wire [`XLEN-1:0] decoder_dec0_next_pc;
  wire [`INST_W-1:0] decoder_dec0_inst;
  wire [1:0] decoder_dec0_resp;
  wire decoder_dec0_control_stop;
  wire [`XLEN-1:0] decoder_dec1_pc;
  wire [`XLEN-1:0] decoder_dec1_next_pc;
  wire [`INST_W-1:0] decoder_dec1_inst;
  wire [1:0] decoder_dec1_resp;
  wire decoder_dec1_control_stop;
  wire decoder_dec0_branch;
  wire [12:0] decoder_dec0_bimm;
  wire decoder_dec1_branch;
  wire [12:0] decoder_dec1_bimm;
  wire [`XLEN-1:0] decoder_packet_next_pc;
  wire [`XLEN-1:0] decoder_packet_raw_next_pc;
  wire [`XLEN-1:0] decoder_fault_tval;

  wire [1:0] active_head_resp0 =
      decoder_owner_mode ? decoder_dec0_resp : head_resp0;
  wire [1:0] active_head_resp1 =
      decoder_owner_mode ? decoder_dec1_resp : head_resp1;
  wire [`INST_W-1:0] active_head_inst0 =
      decoder_owner_mode ? decoder_dec0_inst : head_inst0;
  wire [`INST_W-1:0] active_head_inst1 =
      decoder_owner_mode ? decoder_dec1_inst : head_inst1;
  wire [`XLEN-1:0] active_head_pc0 =
      decoder_owner_mode ? decoder_dec0_pc : PC0;
  wire [`XLEN-1:0] active_head_pc1 =
      decoder_owner_mode ? decoder_dec1_pc : PC1;
  wire [`XLEN-1:0] active_fault_tval =
      decoder_owner_mode ? decoder_fault_tval : FAULT_TVAL;

  OooFetchPacketDecode u_packet_decode (
    .rsp_pc_i(decoder_rsp_pc),
    .rsp_inst0_i(decoder_rsp_inst0),
    .rsp_resp0_i(decoder_rsp_resp0),
    .rsp_inst1_i(decoder_rsp_inst1),
    .rsp_resp1_i(decoder_rsp_resp1),
    .rsp_resp0_bytes_i(decoder_rsp_resp0_bytes),
    .dec0_pc_o(decoder_dec0_pc),
    .dec0_next_pc_o(decoder_dec0_next_pc),
    .dec0_inst_o(decoder_dec0_inst),
    .dec0_resp_o(decoder_dec0_resp),
    .dec0_control_stop_o(decoder_dec0_control_stop),
    .dec1_pc_o(decoder_dec1_pc),
    .dec1_next_pc_o(decoder_dec1_next_pc),
    .dec1_inst_o(decoder_dec1_inst),
    .dec1_resp_o(decoder_dec1_resp),
    .dec1_control_stop_o(decoder_dec1_control_stop),
    .dec0_branch_o(decoder_dec0_branch),
    .dec0_bimm_o(decoder_dec0_bimm),
    .dec1_branch_o(decoder_dec1_branch),
    .dec1_bimm_o(decoder_dec1_bimm),
    .packet_next_pc_o(decoder_packet_next_pc),
    .packet_raw_next_pc_o(decoder_packet_raw_next_pc),
    .fault_tval_o(decoder_fault_tval)
  );

  OooFetchStaticClassify u_static0 (
    .inst_i(active_head_inst0),
    .semihost_peer_inst_i(active_head_inst1),
    .semihost_peer_is_enter_i(1'b0),
    .static_facts_o(head_static_facts0)
  );

  OooFetchStaticClassify u_static1 (
    .inst_i(active_head_inst1),
    .semihost_peer_inst_i(active_head_inst0),
    .semihost_peer_is_enter_i(1'b1),
    .static_facts_o(head_static_facts1)
  );

  OooFetchHeadPairGate u_pair (
    .fifo_has_packet_i(fifo_has_packet),
    .head_slot1_valid_i(head_slot1_valid),
    .head_resp0_i(active_head_resp0),
    .head_resp1_i(active_head_resp1),
    .head_static_facts0_i(head_static_facts0),
    .head_static_facts1_i(head_static_facts1),
    .head0_ctrl_i(head0_ctrl),
    .head1_ctrl_i(head1_ctrl),
    .priv_mode_i(`PRIV_M),
    .mstatus_i(`MSTATUS_FS_CLEAN),
    .frm_i(3'b000),
    .branch_spec_active_i(1'b0),
    .can_run_i(1'b1),
    .csr_irq_pending_i(1'b0),
    .head_fetch_fault0_o(head_fetch_fault0),
    .head_fetch_fault1_o(head_fetch_fault1),
    .head_fetch_fault_o(head_fetch_fault),
    .head0_fp_raw_o(head0_fp_raw),
    .head0_csr_raw_o(head0_csr_raw),
    .head0_facts_o(head0_facts),
    .head1_control_raw_o(head1_control_raw),
    .head1_branch_raw_o(head1_branch_raw),
    .head1_jal_raw_o(head1_jal_raw),
    .head1_jalr_raw_o(head1_jalr_raw),
    .head1_fp_raw_o(head1_fp_raw),
    .head1_exit_raw_o(head1_exit_raw),
    .head1_system_raw_o(head1_system_raw),
    .head1_arch_trap_raw_o(head1_arch_trap_raw),
    .head1_facts_o(head1_facts),
    .dispatch_valid_o(dispatch_valid),
    .dispatch0_exit_o(dispatch0_exit),
    .dispatch0_arch_trap_o(dispatch0_arch_trap),
    .dispatch0_system_o(dispatch0_system),
    .dispatch0_fp_o(dispatch0_fp),
    .dispatch0_branch_o(dispatch0_branch),
    .dispatch0_jal_o(dispatch0_jal),
    .dispatch0_jump_o(dispatch0_jump),
    .direct_branch0_dispatch_valid_o(direct_branch0_dispatch_valid)
  );

  OooFrontendDispatchGate u_dispatch (
    .dispatch_valid_i(dispatch_valid),
    .dispatch0_exit_i(dispatch0_exit),
    .dispatch0_arch_trap_i(dispatch0_arch_trap),
    .dispatch0_system_i(dispatch0_system),
    .dispatch0_csr_i(head0_csr_raw),
    .dispatch0_fp_i(dispatch0_fp),
    .head0_branch_pred_taken_i(head0_branch_pred_taken),
    .head_slot1_valid_i(head_slot1_valid),
    .dispatch0_branch_i(dispatch0_branch),
    .dispatch0_jal_i(dispatch0_jal),
    .dispatch0_jump_i(dispatch0_jump),
    .dispatch0_return_i(1'b0),
    .dispatch0_unsupported_i(1'b0),
    .dispatch1_unsupported_i(1'b0),
    .dispatch0_unsupported_raw_i(1'b0),
    .dispatch1_unsupported_raw_i(1'b0),
    .dispatch0_ready_i(dispatch0_ready),
    .dispatch1_ready_i(dispatch1_ready),
    .head0_fp_raw_i(head0_fp_raw),
    .head1_fp_raw_i(head1_fp_raw),
    .head_fetch_fault1_i(head_fetch_fault1),
    .head1_exit_raw_i(head1_exit_raw),
    .head1_system_raw_i(head1_system_raw),
    .head1_arch_trap_raw_i(effective_head1_arch_trap),
    .head1_control_raw_i(head1_control_raw),
    .head1_branch_raw_i(head1_branch_raw),
    .head1_jal_raw_i(head1_jal_raw),
    .head1_jalr_raw_i(head1_jalr_raw),
    .head1_jal_call_raw_i(1'b0),
    .head1_return_candidate_i(1'b0),
    .lane0_before_ret_safe_i(1'b1),
    .dispatch1_barrier_o(dispatch1_barrier),
    .dispatch_unsupported_o(dispatch_unsupported),
    .dispatch_fire_o(dispatch_fire),
    .dispatch1_barrier_fire_o(dispatch1_barrier_fire),
    .frontend_dispatch_to_backend_valid_o(
        frontend_dispatch_to_backend_valid),
    .dbranch_dual_go_o(dbranch_dual_go)
  );

  OooPendingDispatchArbiter u_pending_arbiter (
    .csr_trap_mem_valid_i(1'b0),
    .direct_frontend_flush_i(1'b0),
    .can_run_i(1'b1),
    .fifo_has_packet_i(fifo_has_packet),
    .csr_irq_pending_i(1'b0),
    .branch_spec_resolve_valid_i(1'b0),
    .pending_branch_commit_resolve_i(1'b0),
    .pending_branch_match_clear_i(1'b0),
    .branch_resolve_untracked_i(branch_resolve_untracked),
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
    .head_fetch_fault0_i(head_fetch_fault0),
    .head_fetch_fault1_i(head_fetch_fault1),
    .head_fetch_fault_tval_i(active_fault_tval),
    .head_resp0_i(active_head_resp0),
    .head_resp1_i(active_head_resp1),
    .head_pc0_i(active_head_pc0),
    .head_pc1_i(active_head_pc1),
    .head_inst0_i(active_head_inst0),
    .head_inst1_i(active_head_inst1),
    .dispatch0_facts_i(head0_facts),
    .head1_facts_i(effective_head1_facts),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .direct_jal0_dispatch_valid_i(1'b0),
    .dispatch0_return_i(1'b0),
    .dispatch0_unsupported_i(1'b0),
    .dispatch_unsupported_i(dispatch_unsupported),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .head0_csr_illegal_i(1'b0),
    .head1_csr_illegal_i(1'b0),
    .rob_walk_mode_i(1'b1),
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

  OooPendingTrapExitSequencer u_pending_trap (
    .clk(clk),
    .rst(rst),
    .late_clear_i(1'b0),
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

  OooStopPendingSequencer u_stop (
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
    .branch_resolve_untracked_i(branch_resolve_untracked),
    .pending_jump_resolve_ready_i(1'b0),
    .pending_jump_misaligned_i(1'b0),
    .pending_jump_nolink_commit_i(1'b0),
    .pending_jump_redirect_after_dispatch_i(1'b0),
    .jump_dispatch_fire_i(1'b0),
    .pending_mem_resolve_ready_i(1'b0),
    .system_csr_dispatch_fire_i(1'b0),
    .pending_system_csr_commit_i(1'b0),
    .head0_csr_commit_i(1'b0),
    .head0_csr_inflight_i(1'b0),
    .drain_complete_i(drain_complete),
    .can_run_i(1'b1),
    .fifo_has_packet_i(fifo_has_packet),
    .csr_irq_pending_i(1'b0),
    .head_fetch_fault0_i(head_fetch_fault0),
    .dispatch0_arch_trap_i(dispatch0_arch_trap),
    .dispatch0_exit_i(dispatch0_exit),
    .dispatch0_fp_i(dispatch0_fp),
    .dispatch0_system_i(dispatch0_system),
    .head0_csr_illegal_i(1'b0),
    .dispatch0_branch_i(dispatch0_branch),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid),
    .dispatch0_jal_i(dispatch0_jal),
    .direct_jal0_dispatch_valid_i(1'b0),
    .dispatch0_jump_i(dispatch0_jump),
    .dispatch0_return_i(1'b0),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire),
    .dispatch_unsupported_i(dispatch_unsupported),
    .rob_walk_mode_i(1'b1),
    .stop_pending_o(stop_pending)
  );

  OooCsrTrapRequestMux u_trap_request (
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
    .pending_trap_cause_i(pending_trap_cause),
    .pending_trap_pc_i(pending_trap_pc),
    .pending_trap_tval_i(pending_trap_tval),
    .pending_system_i(1'b0),
    .pending_system_ecall_i(1'b0),
    .pending_system_mret_i(1'b0),
    .pending_system_irq_i(1'b0),
    .pending_system_pc_i({`XLEN{1'b0}}),
    .pending_system_inst_i({`INST_W{1'b0}}),
    .pending_system_irq_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .csr_ecall_cause_i({`TRAP_CAUSE_W{1'b0}}),
    .pending_system_satp_write_commit_i(1'b0),
    .pending_system_sfence_commit_i(1'b0),
    .pending_arch_trap_fire_o(pending_arch_trap_fire),
    .trap_ex_valid_o(trap_ex_valid),
    .trap_ex_pc_o(trap_ex_pc),
    .trap_ex_cause_o(trap_ex_cause),
    .trap_ex_tval_o(trap_ex_tval)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic tick;
    begin
      @(posedge clk);
      #1;
    end
  endtask

  task automatic clear_drive;
    begin
      fifo_has_packet = 1'b0;
      head_slot1_valid = 1'b1;
      head_resp0 = 2'b00;
      head_resp1 = 2'b00;
      head_inst0 = INST_ADDI;
      head_inst1 = INST_ADDI;
      head0_ctrl = {`CTRL_BUS_W{1'b0}};
      head1_ctrl = {`CTRL_BUS_W{1'b0}};
      // 合法普通指令必须带 NEED_EXEC，避免 unsupported residual 干扰 owner 矩阵。
      head0_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      head1_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      head0_branch_pred_taken = 1'b0;
      dispatch0_ready = 1'b1;
      dispatch1_ready = 1'b1;
      branch_resolve_untracked = 1'b0;
      drain_complete = 1'b0;
      decoder_owner_mode = 1'b0;
      decoder_rsp_pc = PC0;
      decoder_rsp_inst0 = INST_ADDI;
      decoder_rsp_inst1 = INST_ADDI;
      decoder_rsp_resp0 = 2'b00;
      decoder_rsp_resp1 = 2'b00;
      decoder_rsp_resp0_bytes = 3'd4;
      pseudo_default_access = 1'b0;
      pseudo_head1_facts = {`OOO_SLOT_FACTS_W{1'b0}};
    end
  endtask

  // The dispatch gate carries no tval payload; its IFU-TVAL responsibility is
  // to make the lane1 barrier fire the acceptance event for the current FIFO
  // head.  Under dispatch0 backpressure the exact PF tuple must remain
  // uncaptured.  Releasing READY captures one atomic cause/PC/tval tuple and
  // the subsequent drain presents that same tuple to the CSR request mux.
  task automatic run_dispatch_stall_tval_row;
    reg blocked_ok;
    reg blocked_hold_ok;
    reg accepted_ok;
    reg captured_ok;
    reg drained_ok;
    begin
      tval_dispatch_stall_rows_q = tval_dispatch_stall_rows_q + 1;
      reset_case();
      clear_drive();
      decoder_owner_mode = 1'b1;
      decoder_rsp_pc = PC0;
      decoder_rsp_inst0 = STREAM_CU[31:0];
      decoder_rsp_inst1 = STREAM_CU[63:32];
      decoder_rsp_resp0 = 2'b00;
      decoder_rsp_resp1 = 2'b10;
      decoder_rsp_resp0_bytes = 3'd4;
      fifo_has_packet = 1'b1;
      head_slot1_valid = 1'b1;
      dispatch0_ready = 1'b0;
      #1;

      blocked_ok =
          (head_fetch_fault1 === 1'b1) &&
          (dispatch1_barrier === 1'b1) &&
          (dispatch1_barrier_fire === 1'b0) &&
          (pending_trap_capture_arch === 1'b0);
      tick();
      blocked_hold_ok =
          (pending_arch_trap === 1'b0) &&
          (stop_pending === 1'b0) &&
          (pending_trap_cause === {`TRAP_CAUSE_W{1'b0}}) &&
          (pending_trap_pc === {`XLEN{1'b0}}) &&
          (pending_trap_tval === {`XLEN{1'b0}});

      dispatch0_ready = 1'b1;
      #1;
      accepted_ok =
          (dispatch1_barrier_fire === 1'b1) &&
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_arch_valid === 1'b1) &&
          (pending_trap_capture_cause === `EXC_INST_PAGE_FAULT) &&
          (pending_trap_capture_pc === (PC0 + 64'd2)) &&
          (pending_trap_capture_tval === (PC0 + 64'd4));
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === `EXC_INST_PAGE_FAULT) &&
          (pending_trap_pc === (PC0 + 64'd2)) &&
          (pending_trap_tval === (PC0 + 64'd4));

      fifo_has_packet = 1'b0;
      drain_complete = 1'b1;
      #1;
      drained_ok =
          (pending_arch_trap_fire === 1'b1) &&
          (trap_ex_valid === 1'b1) &&
          (trap_ex_cause === `EXC_INST_PAGE_FAULT) &&
          (trap_ex_pc === (PC0 + 64'd2)) &&
          (trap_ex_tval === (PC0 + 64'd4));
      if (blocked_ok && blocked_hold_ok && accepted_ok && captured_ok &&
          drained_ok) begin
        $display("[TVAL-G1-DISPATCH-STALL] rows=1 blocked=1 accepted=1 pending=1 drain=1 xepc=PC+2 tval=PC+4 PASS");
      end else begin
        tb_errors = tb_errors + 1;
        $display("[TVAL-G1-DISPATCH-STALL-RED] blocked=%b hold=%b accepted=%b pending=%b drain=%b fire=%b cause=%h xepc=%h tval=%h",
                 blocked_ok, blocked_hold_ok, accepted_ok, captured_ok,
                 drained_ok, dispatch1_barrier_fire, pending_trap_cause,
                 pending_trap_pc, pending_trap_tval);
      end
    end
  endtask

  task automatic reset_case;
    begin
      clear_drive();
      rst = 1'b1;
      tick();
      rst = 1'b0;
      tick();
    end
  endtask

  task automatic arm_fault_packet;
    input is_branch;
    input predicted_taken;
    input slot1_valid;
    input [1:0] response;
    input actual_taken_encoding;
    begin
      clear_drive();
      fifo_has_packet = 1'b1;
      head_slot1_valid = slot1_valid;
      head_resp1 = response;
      head0_branch_pred_taken = predicted_taken;
      if (is_branch) begin
        head_inst0 = actual_taken_encoding ? INST_BEQ_X0_X0 :
                                             INST_BNE_X0_X0;
        head0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
      end
      #1;
    end
  endtask

  // 每个 matrix row 只累计一个 verdict，避免同一断链造成级联 error 数膨胀。
  task automatic check_row;
    input [1023:0] name;
    input row_ok;
    begin
      row_count_q = row_count_q + 1;
      if (row_ok === 1'b1) begin
        $display("[ROW-PASS] %0s", name);
      end else begin
        tb_errors = tb_errors + 1;
        $display("[ROW-FAIL] %0s fault1=%b dual=%b barrier=%b fire=%b capture=%b/%b pending=%b stop=%b cause=%h pc=%h tval=%h trap_ex=%b",
                 name, head_fetch_fault1, dbranch_dual_go,
                 dispatch1_barrier, dispatch1_barrier_fire,
                 pending_trap_capture_arch, pending_trap_capture_arch_valid,
                 pending_arch_trap, stop_pending, pending_trap_cause,
                 pending_trap_pc, pending_trap_tval, trap_ex_valid);
      end
    end
  endtask

  task automatic run_decoder_owner_row;
    input [1023:0] name;
    input [`XLEN-1:0] stream;
    input integer lane0_bytes;
    input integer fault_offset;
    input expected_lane0;
    reg [`XLEN-1:0] expected_pc;
    reg [`XLEN-1:0] expected_tval;
    reg [`XLEN-1:0] expected_dec1_pc;
    reg decode_owner_ok;
    reg capture_request_ok;
    reg captured_ok;
    reg drained_ok;
    reg row_ok;
    begin
      owner_map_rows_q = owner_map_rows_q + 1;
      if (expected_lane0)
        owner_map_lane0_rows_q = owner_map_lane0_rows_q + 1;
      else
        owner_map_lane1_rows_q = owner_map_lane1_rows_q + 1;

      reset_case();
      clear_drive();
      decoder_owner_mode = 1'b1;
      decoder_rsp_pc = PC0;
      decoder_rsp_inst0 = stream[31:0];
      decoder_rsp_inst1 = stream[63:32];
      decoder_rsp_resp0 = 2'b00;
      decoder_rsp_resp1 = 2'b01;
      decoder_rsp_resp0_bytes = fault_offset[2:0];
      fifo_has_packet = 1'b1;
      head_slot1_valid = 1'b1;
      expected_pc = expected_lane0 ? PC0 : (PC0 + lane0_bytes);
      expected_tval = PC0 + fault_offset;
      // 首个 2B prefix 已 fault 时长度不可读取，decoder 以安全 C.NOP 形状
      // 计算被 lane0 owner 压制的 dec1_pc；F>=2 后才使用真实 lane0 长度。
      expected_dec1_pc = PC0 + ((fault_offset == 0) ? 2 : lane0_bytes);
      #1;

      decode_owner_ok =
          (decoder_dec0_pc === PC0) &&
          (decoder_dec1_pc === expected_dec1_pc) &&
          (decoder_fault_tval === expected_tval) &&
          (decoder_dec0_resp === (expected_lane0 ? 2'b01 : 2'b00)) &&
          (decoder_dec1_resp === 2'b01) &&
          (head_fetch_fault0 === expected_lane0) &&
          (head_fetch_fault1 === !expected_lane0) &&
          (dispatch1_barrier_fire === !expected_lane0);
      capture_request_ok =
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_arch_valid === 1'b1) &&
          (pending_trap_capture_cause === `EXC_INST_ACCESS_FAULT) &&
          (pending_trap_capture_pc === expected_pc) &&
          (pending_trap_capture_tval === expected_tval);
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === `EXC_INST_ACCESS_FAULT) &&
          (pending_trap_pc === expected_pc) &&
          (pending_trap_tval === expected_tval);

      fifo_has_packet = 1'b0;
      drain_complete = 1'b1;
      #1;
      drained_ok =
          (pending_arch_trap_fire === 1'b1) &&
          (trap_ex_valid === 1'b1) &&
          (trap_ex_cause === `EXC_INST_ACCESS_FAULT) &&
          (trap_ex_pc === expected_pc) &&
          (trap_ex_tval === expected_tval);
      row_ok = decode_owner_ok && capture_request_ok && captured_ok &&
               drained_ok;
      if (row_ok === 1'b1) begin
        $display("[ACCESS-G1-OWNER-MAP-PASS] %0s F=%0d owner=%0s pc=%h tval=%h",
                 name, fault_offset, expected_lane0 ? "L0" : "L1",
                 expected_pc, expected_tval);
      end else begin
        tb_errors = tb_errors + 1;
        $display("[ACCESS-G1-OWNER-MAP-RED] %0s F=%0d expected_owner=%0s decode=%b capture=%b pending=%b drain=%b dec_resp=%b/%b head_fault=%b/%b pc=%h tval=%h",
                 name, fault_offset, expected_lane0 ? "L0" : "L1",
                 decode_owner_ok, capture_request_ok, captured_ok, drained_ok,
                 decoder_dec0_resp, decoder_dec1_resp,
                 head_fetch_fault0, head_fetch_fault1,
                 pending_trap_pc, pending_trap_tval);
      end
    end
  endtask

  // IFU-TVAL-G1 current-design matrix.  This is deliberately separate from
  // the IFU-ACCESS-G1 owner inventory above so each debt keeps an independent
  // exact row count.  The same packet-derived frontier must survive decoder,
  // lane selection, capture, pending storage and the drained CSR request for
  // both instruction page fault and instruction access fault causes.
  task automatic run_tval_lifecycle_row;
    input [1023:0] name;
    input [`XLEN-1:0] stream;
    input integer lane0_bytes;
    input integer fault_offset;
    input [1:0] response;
    input expected_lane0;
    reg [`TRAP_CAUSE_W-1:0] expected_cause;
    reg [`XLEN-1:0] expected_pc;
    reg [`XLEN-1:0] expected_tval;
    reg [`XLEN-1:0] expected_dec1_pc;
    reg decode_owner_ok;
    reg capture_request_ok;
    reg captured_ok;
    reg drained_ok;
    reg row_ok;
    begin
      tval_rows_q = tval_rows_q + 1;
      if (response == 2'b10)
        tval_pf_rows_q = tval_pf_rows_q + 1;
      else
        tval_af_rows_q = tval_af_rows_q + 1;
      if (expected_lane0)
        tval_lane0_rows_q = tval_lane0_rows_q + 1;
      else
        tval_lane1_rows_q = tval_lane1_rows_q + 1;
      case (fault_offset)
        0: tval_f0_rows_q = tval_f0_rows_q + 1;
        2: tval_f2_rows_q = tval_f2_rows_q + 1;
        4: tval_f4_rows_q = tval_f4_rows_q + 1;
        6: tval_f6_rows_q = tval_f6_rows_q + 1;
        default: begin end
      endcase

      reset_case();
      clear_drive();
      decoder_owner_mode = 1'b1;
      decoder_rsp_pc = PC0;
      decoder_rsp_inst0 = stream[31:0];
      decoder_rsp_inst1 = stream[63:32];
      decoder_rsp_resp0 = 2'b00;
      decoder_rsp_resp1 = response;
      decoder_rsp_resp0_bytes = fault_offset[2:0];
      fifo_has_packet = 1'b1;
      head_slot1_valid = 1'b1;
      expected_cause = (response == 2'b10) ?
                       `EXC_INST_PAGE_FAULT : `EXC_INST_ACCESS_FAULT;
      expected_pc = expected_lane0 ? PC0 : (PC0 + lane0_bytes);
      expected_tval = PC0 + fault_offset;
      expected_dec1_pc = PC0 + ((fault_offset == 0) ? 2 : lane0_bytes);
      #1;

      decode_owner_ok =
          (decoder_dec0_pc === PC0) &&
          (decoder_dec1_pc === expected_dec1_pc) &&
          (decoder_fault_tval === expected_tval) &&
          (decoder_dec0_resp === (expected_lane0 ? response : 2'b00)) &&
          (decoder_dec1_resp === response) &&
          (head_fetch_fault0 === expected_lane0) &&
          (head_fetch_fault1 === !expected_lane0) &&
          (dispatch1_barrier_fire === !expected_lane0);
      capture_request_ok =
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_arch_valid === 1'b1) &&
          (pending_trap_capture_cause === expected_cause) &&
          (pending_trap_capture_pc === expected_pc) &&
          (pending_trap_capture_tval === expected_tval);
      if (capture_request_ok)
        tval_capture_rows_q = tval_capture_rows_q + 1;
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === expected_cause) &&
          (pending_trap_pc === expected_pc) &&
          (pending_trap_tval === expected_tval);
      if (captured_ok)
        tval_pending_rows_q = tval_pending_rows_q + 1;

      fifo_has_packet = 1'b0;
      drain_complete = 1'b1;
      #1;
      drained_ok =
          (pending_arch_trap_fire === 1'b1) &&
          (trap_ex_valid === 1'b1) &&
          (trap_ex_cause === expected_cause) &&
          (trap_ex_pc === expected_pc) &&
          (trap_ex_tval === expected_tval);
      if (drained_ok)
        tval_drain_rows_q = tval_drain_rows_q + 1;
      row_ok = decode_owner_ok && capture_request_ok && captured_ok &&
               drained_ok;
      if (row_ok === 1'b1) begin
        $display("[TVAL-G1-LIFECYCLE-PASS] %0s F=%0d cause=%0s owner=%0s xepc=%h tval=%h",
                 name, fault_offset,
                 (response == 2'b10) ? "PF" : "AF",
                 expected_lane0 ? "L0" : "L1",
                 expected_pc, expected_tval);
      end else begin
        tb_errors = tb_errors + 1;
        $display("[TVAL-G1-LIFECYCLE-RED] %0s F=%0d cause=%0s owner=%0s decode=%b capture=%b pending=%b drain=%b xepc=%h tval=%h",
                 name, fault_offset,
                 (response == 2'b10) ? "PF" : "AF",
                 expected_lane0 ? "L0" : "L1",
                 decode_owner_ok, capture_request_ok, captured_ok, drained_ok,
                 pending_trap_pc, pending_trap_tval);
      end
    end
  endtask

  // c.beqz is the 16-bit control owner.  Its visible fall-through lane1
  // fault uses xEPC=PC0+2 and tval=PC0+4.  An actual-taken resolution must
  // clear the speculative payload, while a fetch-time predicted-taken packet
  // never gives lane1 a fault owner.
  task automatic run_compressed_control_tval_row;
    input [1023:0] name;
    input [1:0] response;
    input [1:0] mode;
    reg [`TRAP_CAUSE_W-1:0] expected_cause;
    reg row_ok;
    begin
      tval_control_rows_q = tval_control_rows_q + 1;
      case (mode)
        2'd0: tval_control_terminal_rows_q =
                  tval_control_terminal_rows_q + 1;
        2'd1: tval_control_squash_rows_q =
                  tval_control_squash_rows_q + 1;
        default: tval_control_poison_rows_q =
                     tval_control_poison_rows_q + 1;
      endcase

      reset_case();
      clear_drive();
      decoder_owner_mode = 1'b1;
      decoder_rsp_pc = PC0;
      decoder_rsp_inst0 = STREAM_CBR_U[31:0];
      decoder_rsp_inst1 = STREAM_CBR_U[63:32];
      decoder_rsp_resp0 = 2'b00;
      decoder_rsp_resp1 = response;
      decoder_rsp_resp0_bytes = 3'd4;
      fifo_has_packet = 1'b1;
      head0_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
      head_slot1_valid = (mode == 2'd2) ? 1'b0 : 1'b1;
      head0_branch_pred_taken = (mode == 2'd2) ? 1'b1 : 1'b0;
      expected_cause = (response == 2'b10) ?
                       `EXC_INST_PAGE_FAULT : `EXC_INST_ACCESS_FAULT;
      #1;

      if (mode == 2'd2) begin
        row_ok =
            (decoder_dec0_branch === 1'b1) &&
            (decoder_dec1_pc === (PC0 + 64'd2)) &&
            (decoder_fault_tval === (PC0 + 64'd4)) &&
            (decoder_dec1_resp === response) &&
            (head_fetch_fault1 === 1'b0) &&
            (dispatch1_barrier === 1'b0) &&
            (dispatch1_barrier_fire === 1'b0) &&
            (pending_trap_capture_arch === 1'b0);
        tick();
        row_ok = row_ok &&
            (pending_arch_trap === 1'b0) &&
            (stop_pending === 1'b0) &&
            (pending_trap_tval === {`XLEN{1'b0}}) &&
            (trap_ex_valid === 1'b0);
      end else begin
        row_ok =
            (decoder_dec0_branch === 1'b1) &&
            (decoder_dec1_pc === (PC0 + 64'd2)) &&
            (decoder_fault_tval === (PC0 + 64'd4)) &&
            (decoder_dec1_resp === response) &&
            (head_fetch_fault0 === 1'b0) &&
            (head_fetch_fault1 === 1'b1) &&
            (dispatch1_barrier_fire === 1'b1) &&
            (pending_trap_capture_arch === 1'b1) &&
            (pending_trap_capture_arch_valid === 1'b1) &&
            (pending_trap_capture_cause === expected_cause) &&
            (pending_trap_capture_pc === (PC0 + 64'd2)) &&
            (pending_trap_capture_tval === (PC0 + 64'd4));
        tick();
        row_ok = row_ok &&
            (pending_arch_trap === 1'b1) &&
            (stop_pending === 1'b1) &&
            (pending_trap_cause === expected_cause) &&
            (pending_trap_pc === (PC0 + 64'd2)) &&
            (pending_trap_tval === (PC0 + 64'd4));
        fifo_has_packet = 1'b0;
        if (mode == 2'd1) begin
          branch_resolve_untracked = 1'b1;
          tick();
          row_ok = row_ok &&
              (pending_arch_trap === 1'b0) &&
              (stop_pending === 1'b0) &&
              (pending_trap_cause === {`TRAP_CAUSE_W{1'b0}}) &&
              (pending_trap_pc === {`XLEN{1'b0}}) &&
              (pending_trap_tval === {`XLEN{1'b0}}) &&
              (trap_ex_valid === 1'b0);
        end else begin
          drain_complete = 1'b1;
          #1;
          row_ok = row_ok &&
              (pending_arch_trap_fire === 1'b1) &&
              (trap_ex_valid === 1'b1) &&
              (trap_ex_cause === expected_cause) &&
              (trap_ex_pc === (PC0 + 64'd2)) &&
              (trap_ex_tval === (PC0 + 64'd4));
        end
      end

      if (row_ok === 1'b1) begin
        $display("[TVAL-G1-CONTROL-PASS] %0s mode=%0d cause=%0s F=4 xepc=%h tval=%h",
                 name, mode, (response == 2'b10) ? "PF" : "AF",
                 PC0 + 64'd2, PC0 + 64'd4);
      end else begin
        tb_errors = tb_errors + 1;
        $display("[TVAL-G1-CONTROL-RED] %0s mode=%0d cause=%0s fault=%b/%b capture=%b pending=%b stop=%b xepc=%h tval=%h trap_ex=%b",
                 name, mode, (response == 2'b10) ? "PF" : "AF",
                 head_fetch_fault0, head_fetch_fault1,
                 pending_trap_capture_arch, pending_arch_trap, stop_pending,
                 pending_trap_pc, pending_trap_tval, trap_ex_valid);
      end
    end
  endtask

  task automatic run_terminal_fault_row;
    input [1023:0] name;
    input is_branch;
    input [1:0] response;
    input [`TRAP_CAUSE_W-1:0] expected_cause;
    reg pair_ok;
    reg dispatch_ok;
    reg capture_request_ok;
    reg captured_ok;
    reg drained_ok;
    begin
      terminal_rows_q = terminal_rows_q + 1;
      reset_case();
      arm_fault_packet(is_branch, 1'b0, 1'b1, response, 1'b0);
      pair_ok = (head_fetch_fault1 === 1'b1);
      dispatch_ok =
          (dbranch_dual_go === 1'b0) &&
          (dispatch_fire === 1'b0) &&
          (dispatch1_barrier === 1'b1) &&
          (dispatch1_barrier_fire === 1'b1) &&
          (frontend_dispatch_to_backend_valid === 1'b0);
      capture_request_ok =
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_arch_valid === 1'b1) &&
          (pending_trap_capture_cause === expected_cause) &&
          (pending_trap_capture_pc === PC1) &&
          (pending_trap_capture_tval === FAULT_TVAL);
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === expected_cause) &&
          (pending_trap_pc === PC1) &&
          (pending_trap_tval === FAULT_TVAL);
      // barrier fire 后 packet 已 pop；drain 点必须把 pending owner 变成 CSR trap request。
      fifo_has_packet = 1'b0;
      drain_complete = 1'b1;
      #1;
      drained_ok =
          (pending_arch_trap_fire === 1'b1) &&
          (trap_ex_valid === 1'b1) &&
          (trap_ex_cause === expected_cause) &&
          (trap_ex_pc === PC1) &&
          (trap_ex_tval === FAULT_TVAL);
      $display("[ROW-STAGES] %0s pair=%b dispatch=%b capture_req=%b pending=%b drain=%b",
               name, pair_ok, dispatch_ok, capture_request_ok, captured_ok,
               drained_ok);
      check_row(name, pair_ok && dispatch_ok && capture_request_ok &&
                      captured_ok && drained_ok);
    end
  endtask

  task automatic run_actual_taken_squash_row;
    input [1023:0] name;
    input [1:0] response;
    input [`TRAP_CAUSE_W-1:0] expected_cause;
    reg captured_ok;
    reg squashed_ok;
    reg pair_ok;
    reg dispatch_ok;
    reg capture_request_ok;
    begin
      squash_rows_q = squash_rows_q + 1;
      reset_case();
      arm_fault_packet(1'b1, 1'b0, 1'b1, response, 1'b1);
      pair_ok = (head_fetch_fault1 === 1'b1);
      dispatch_ok =
          (dbranch_dual_go === 1'b0) &&
          (dispatch1_barrier_fire === 1'b1);
      capture_request_ok =
          (pending_trap_capture_arch === 1'b1) &&
          (pending_trap_capture_cause === expected_cause);
      tick();
      captured_ok =
          (pending_arch_trap === 1'b1) &&
          (stop_pending === 1'b1) &&
          (pending_trap_cause === expected_cause);

      // actual-taken resolve 将此前 pred-NT 可见的 lane1 fault 认定为 wrong-path。
      fifo_has_packet = 1'b0;
      branch_resolve_untracked = 1'b1;
      tick();
      squashed_ok =
          (pending_arch_trap === 1'b0) &&
          (stop_pending === 1'b0) &&
          (pending_trap_cause === {`TRAP_CAUSE_W{1'b0}}) &&
          (pending_trap_pc === {`XLEN{1'b0}}) &&
          (pending_trap_tval === {`XLEN{1'b0}}) &&
          (trap_ex_valid === 1'b0);
      $display("[ROW-STAGES] %0s pair=%b dispatch=%b capture_req=%b pending=%b squash=%b",
               name, pair_ok, dispatch_ok, capture_request_ok, captured_ok,
               squashed_ok);
      check_row(name, pair_ok && dispatch_ok && capture_request_ok &&
                      captured_ok && squashed_ok);
    end
  endtask

  task automatic run_pred_taken_poison_row;
    input [1023:0] name;
    input [1:0] response;
    reg row_ok;
    begin
      poison_rows_q = poison_rows_q + 1;
      reset_case();
      arm_fault_packet(1'b1, 1'b1, 1'b0, response, 1'b1);
      row_ok =
          (head_fetch_fault1 === 1'b0) &&
          (dbranch_dual_go === 1'b0) &&
          (dispatch1_barrier === 1'b0) &&
          (dispatch1_barrier_fire === 1'b0) &&
          (pending_trap_capture_arch === 1'b0);
      tick();
      row_ok = row_ok &&
          (pending_arch_trap === 1'b0) &&
          (stop_pending === 1'b0) &&
          (trap_ex_valid === 1'b0);
      check_row(name, row_ok);
    end
  endtask

  task automatic run_pseudo_default_access_row;
    reg row_ok;
    begin
      pseudo_rows_q = pseudo_rows_q + 1;
      reset_case();
      clear_drive();
      fifo_has_packet = 1'b1;
      pseudo_default_access = 1'b1;
      pseudo_head1_facts[`OOO_SLOT_FACT_ARCH_TRAP] = 1'b1;
      #1;
      row_ok =
          (head_fetch_fault1 === 1'b0) &&
          (dispatch1_barrier_fire === 1'b1) &&
          (pending_trap_capture_cause === `EXC_INST_ACCESS_FAULT) &&
          (pending_trap_capture_arch === 1'b0) &&
          (pending_trap_capture_arch_valid === 1'b0);
      tick();
      row_ok = row_ok && (pending_arch_trap === 1'b0);

      // barrier 的 stop 仍需随 squash 清掉；不能用“永远 stop”伪装成 no-trap。
      fifo_has_packet = 1'b0;
      branch_resolve_untracked = 1'b1;
      tick();
      row_ok = row_ok &&
          (stop_pending === 1'b0) &&
          (pending_trap_pc === {`XLEN{1'b0}}) &&
          (trap_ex_valid === 1'b0);
      check_row("pseudo arch_trap default ACCESS without fault provenance",
                row_ok);
    end
  endtask

  initial begin
    tb_errors = 0;
    row_count_q = 0;
    terminal_rows_q = 0;
    squash_rows_q = 0;
    poison_rows_q = 0;
    pseudo_rows_q = 0;
    owner_map_rows_q = 0;
    owner_map_lane0_rows_q = 0;
    owner_map_lane1_rows_q = 0;
    tval_rows_q = 0;
    tval_pf_rows_q = 0;
    tval_af_rows_q = 0;
    tval_lane0_rows_q = 0;
    tval_lane1_rows_q = 0;
    tval_f0_rows_q = 0;
    tval_f2_rows_q = 0;
    tval_f4_rows_q = 0;
    tval_f6_rows_q = 0;
    tval_capture_rows_q = 0;
    tval_pending_rows_q = 0;
    tval_drain_rows_q = 0;
    tval_control_rows_q = 0;
    tval_control_terminal_rows_q = 0;
    tval_control_squash_rows_q = 0;
    tval_control_poison_rows_q = 0;
    tval_dispatch_stall_rows_q = 0;
    rst = 1'b1;
    clear_drive();

    run_terminal_fault_row("ordinary head0 + lane1 PF",
                           1'b0, 2'b10, `EXC_INST_PAGE_FAULT);
    run_terminal_fault_row("ordinary head0 + lane1 AF",
                           1'b0, 2'b01, `EXC_INST_ACCESS_FAULT);
    run_terminal_fault_row("pred-NT correct-NT branch + lane1 PF",
                           1'b1, 2'b10, `EXC_INST_PAGE_FAULT);
    run_terminal_fault_row("pred-NT correct-NT branch + lane1 AF",
                           1'b1, 2'b01, `EXC_INST_ACCESS_FAULT);
    run_actual_taken_squash_row("pred-NT actual-taken branch squashes PF",
                                2'b10, `EXC_INST_PAGE_FAULT);
    run_actual_taken_squash_row("pred-NT actual-taken branch squashes AF",
                                2'b01, `EXC_INST_ACCESS_FAULT);
    run_pred_taken_poison_row("pred-taken poison lane1 PF is invisible",
                              2'b10);
    run_pred_taken_poison_row("pred-taken poison lane1 AF is invisible",
                              2'b01);
    run_pseudo_default_access_row();
    $display("[T4G-IFU-LANE1-FAULT-TVAL] PC=%h tval=%h survives capture/pending/drain",
             PC1, FAULT_TVAL);

    if ((row_count_q == 9) && (terminal_rows_q == 4) &&
        (squash_rows_q == 2) && (poison_rows_q == 2) &&
        (pseudo_rows_q == 1) && (tb_errors == 0)) begin
      $display("[ACCESS-G1-LANE1] rows=9 terminal=4 squash=2 poison=2 pseudo=1 tval_terminal=4 PASS");
    end else begin
      tb_errors = tb_errors + 1;
      $display("[ACCESS-G1-LANE1-FAIL] rows=%0d terminal=%0d squash=%0d poison=%0d pseudo=%0d",
               row_count_q, terminal_rows_q, squash_rows_q, poison_rows_q,
               pseudo_rows_q);
    end

    run_decoder_owner_row("C/C", STREAM_CC, 2, 0, 1'b1);
    run_decoder_owner_row("C/C", STREAM_CC, 2, 2, 1'b0);
    run_decoder_owner_row("C/U", STREAM_CU, 2, 0, 1'b1);
    run_decoder_owner_row("C/U", STREAM_CU, 2, 2, 1'b0);
    run_decoder_owner_row("C/U", STREAM_CU, 2, 4, 1'b0);
    run_decoder_owner_row("U/C", STREAM_UC, 4, 0, 1'b1);
    run_decoder_owner_row("U/C", STREAM_UC, 4, 2, 1'b1);
    run_decoder_owner_row("U/C", STREAM_UC, 4, 4, 1'b0);
    run_decoder_owner_row("U/U", STREAM_UU, 4, 0, 1'b1);
    run_decoder_owner_row("U/U", STREAM_UU, 4, 2, 1'b1);
    run_decoder_owner_row("U/U", STREAM_UU, 4, 4, 1'b0);
    run_decoder_owner_row("U/U", STREAM_UU, 4, 6, 1'b0);
    if ((owner_map_rows_q == 12) && (owner_map_lane0_rows_q == 6) &&
        (owner_map_lane1_rows_q == 6) && (tb_errors == 0)) begin
      $display("[ACCESS-G1-OWNER-MAP] rows=12 lane0=6 lane1=6 capture=12 pending=12 drain=12 PASS");
    end else begin
      tb_errors = tb_errors + 1;
      $display("[ACCESS-G1-OWNER-MAP-FAIL] rows=%0d lane0=%0d lane1=%0d",
               owner_map_rows_q, owner_map_lane0_rows_q,
               owner_map_lane1_rows_q);
    end

    run_tval_lifecycle_row("PF C/C F0", STREAM_CC, 2, 0, 2'b10, 1'b1);
    run_tval_lifecycle_row("PF C/C F2", STREAM_CC, 2, 2, 2'b10, 1'b0);
    run_tval_lifecycle_row("PF C/U F0", STREAM_CU, 2, 0, 2'b10, 1'b1);
    run_tval_lifecycle_row("PF C/U F2", STREAM_CU, 2, 2, 2'b10, 1'b0);
    run_tval_lifecycle_row("PF C/U F4", STREAM_CU, 2, 4, 2'b10, 1'b0);
    run_tval_lifecycle_row("PF U/C F0", STREAM_UC, 4, 0, 2'b10, 1'b1);
    run_tval_lifecycle_row("PF U/C F2", STREAM_UC, 4, 2, 2'b10, 1'b1);
    run_tval_lifecycle_row("PF U/C F4", STREAM_UC, 4, 4, 2'b10, 1'b0);
    run_tval_lifecycle_row("PF U/U F0", STREAM_UU, 4, 0, 2'b10, 1'b1);
    run_tval_lifecycle_row("PF U/U F2", STREAM_UU, 4, 2, 2'b10, 1'b1);
    run_tval_lifecycle_row("PF U/U F4", STREAM_UU, 4, 4, 2'b10, 1'b0);
    run_tval_lifecycle_row("PF U/U F6", STREAM_UU, 4, 6, 2'b10, 1'b0);
    run_tval_lifecycle_row("AF C/C F0", STREAM_CC, 2, 0, 2'b01, 1'b1);
    run_tval_lifecycle_row("AF C/C F2", STREAM_CC, 2, 2, 2'b01, 1'b0);
    run_tval_lifecycle_row("AF C/U F0", STREAM_CU, 2, 0, 2'b01, 1'b1);
    run_tval_lifecycle_row("AF C/U F2", STREAM_CU, 2, 2, 2'b01, 1'b0);
    run_tval_lifecycle_row("AF C/U F4", STREAM_CU, 2, 4, 2'b01, 1'b0);
    run_tval_lifecycle_row("AF U/C F0", STREAM_UC, 4, 0, 2'b01, 1'b1);
    run_tval_lifecycle_row("AF U/C F2", STREAM_UC, 4, 2, 2'b01, 1'b1);
    run_tval_lifecycle_row("AF U/C F4", STREAM_UC, 4, 4, 2'b01, 1'b0);
    run_tval_lifecycle_row("AF U/U F0", STREAM_UU, 4, 0, 2'b01, 1'b1);
    run_tval_lifecycle_row("AF U/U F2", STREAM_UU, 4, 2, 2'b01, 1'b1);
    run_tval_lifecycle_row("AF U/U F4", STREAM_UU, 4, 4, 2'b01, 1'b0);
    run_tval_lifecycle_row("AF U/U F6", STREAM_UU, 4, 6, 2'b01, 1'b0);
    if ((tval_rows_q == 24) && (tval_pf_rows_q == 12) &&
        (tval_af_rows_q == 12) && (tval_lane0_rows_q == 12) &&
        (tval_lane1_rows_q == 12) && (tval_f0_rows_q == 8) &&
        (tval_f2_rows_q == 8) && (tval_f4_rows_q == 6) &&
        (tval_f6_rows_q == 2) && (tval_capture_rows_q == 24) &&
        (tval_pending_rows_q == 24) && (tval_drain_rows_q == 24) &&
        (tb_errors == 0)) begin
      $display("[TVAL-G1-LIFECYCLE] rows=24 pf=12 af=12 lane0=12 lane1=12 F0=8 F2=8 F4=6 F6=2 capture=24 pending=24 drain=24 PASS");
    end else begin
      tb_errors = tb_errors + 1;
      $display("[TVAL-G1-LIFECYCLE-FAIL] rows=%0d pf=%0d af=%0d lane0=%0d lane1=%0d F0=%0d F2=%0d F4=%0d F6=%0d capture=%0d pending=%0d drain=%0d",
               tval_rows_q, tval_pf_rows_q, tval_af_rows_q,
               tval_lane0_rows_q, tval_lane1_rows_q,
               tval_f0_rows_q, tval_f2_rows_q, tval_f4_rows_q,
               tval_f6_rows_q, tval_capture_rows_q,
               tval_pending_rows_q, tval_drain_rows_q);
    end

    run_compressed_control_tval_row("c.beqz terminal PF", 2'b10, 2'd0);
    run_compressed_control_tval_row("c.beqz terminal AF", 2'b01, 2'd0);
    run_compressed_control_tval_row("c.beqz squash PF", 2'b10, 2'd1);
    run_compressed_control_tval_row("c.beqz squash AF", 2'b01, 2'd1);
    run_compressed_control_tval_row("c.beqz pred-taken PF", 2'b10, 2'd2);
    run_compressed_control_tval_row("c.beqz pred-taken AF", 2'b01, 2'd2);
    if ((tval_control_rows_q == 6) &&
        (tval_control_terminal_rows_q == 2) &&
        (tval_control_squash_rows_q == 2) &&
        (tval_control_poison_rows_q == 2) && (tb_errors == 0)) begin
      $display("[TVAL-G1-COMPRESSED-CONTROL] rows=6 terminal=2 squash=2 poison=2 F=4 xepc=PC+2 tval=PC+4 PASS");
    end else begin
      tb_errors = tb_errors + 1;
      $display("[TVAL-G1-COMPRESSED-CONTROL-FAIL] rows=%0d terminal=%0d squash=%0d poison=%0d",
               tval_control_rows_q, tval_control_terminal_rows_q,
               tval_control_squash_rows_q, tval_control_poison_rows_q);
    end

    run_dispatch_stall_tval_row();
    if ((tval_dispatch_stall_rows_q != 1) && (tb_errors == 0)) begin
      tb_errors = tb_errors + 1;
      $display("[TVAL-G1-DISPATCH-STALL-COUNT-RED] rows=%0d",
               tval_dispatch_stall_rows_q);
    end

    tb_finish("tb_ooo_ifu_lane1_fault_owner");
  end
endmodule
