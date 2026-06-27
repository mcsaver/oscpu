`include "define.v"
`include "common/OooSlotFacts.vh"

// 受控 ALU-only OoO 核心壳：前端一次取回 PC/PC+4 两条 32-bit 指令，
// 通过小 fetch FIFO 连续喂给 OooAluCoreSlice，避免旧版串行取两次指令的前端空泡。
module OooAluFetchCore #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter FREE_COUNT_W = `OOO_FREE_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter FETCH_PACKET_COUNT_W = `OOO_FETCH_PACKET_COUNT_W
) (
  input clk,
  input rst,
  input flush_i,
  input run_i,
  input [`XLEN-1:0] reset_pc_i,
  input [`XLEN-1:0] time_i,
  input irq_software_i,
  input irq_timer_i,
  input irq_external_i,

  output fetch_req_valid_o,
  input fetch_req_ready_i,
  output [`XLEN-1:0] fetch_req_pc_o,
  input fetch_rsp_valid_i,
  output fetch_rsp_ready_o,
  input [`INST_W-1:0] fetch_rsp_inst0_i,
  input [1:0] fetch_rsp_resp0_i,
  input [`INST_W-1:0] fetch_rsp_inst1_i,
  input [1:0] fetch_rsp_resp1_i,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  output mem1_req_valid_o,
  input mem1_req_ready_i,
  output mem1_req_write_o,
  output [`XLEN-1:0] mem1_req_addr_o,
  output [`XLEN-1:0] mem1_req_wdata_o,
  output [`STRB_W-1:0] mem1_req_wstrb_o,
  input mem1_rsp_valid_i,
  output mem1_rsp_ready_o,
  input [`XLEN-1:0] mem1_rsp_rdata_i,
  input mem1_rsp_error_i,
  input mem1_rsp_page_fault_i,
  output mem_flush_o,
  output mmu_flush_o,

  input commit_ready_i,

  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_rd_addr_o,
  output [`XLEN-1:0] commit0_rd_data_o,
  output commit0_exception_o,
  output commit0_write_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_rd_addr_o,
  output [`XLEN-1:0] commit1_rd_data_o,
  output commit1_exception_o,
  output commit1_write_o,

  output trap_valid_o,
  output [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output [`XLEN-1:0] trap_pc_o,
  output [`XLEN-1:0] trap_tval_o,
  output exit_valid_o,
  output exit_is_ecall_o,
  output exit_is_ebreak_o,
  output [`XLEN-1:0] exit_code_o,
  output halted_o,
  output [1:0] priv_mode_o,
  output [`XLEN-1:0] mstatus_o,
  output [`XLEN-1:0] satp_o,
  output svpbmt_en_o,
  output [`PMP_CFG_BUS_W-1:0] pmpcfg_o,
  output [`PMP_ADDR_BUS_W-1:0] pmpaddr_o,

  output [`XLEN-1:0] debug_pc_o,
  output [`CORE_STATE_W-1:0] debug_state_o,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o,
  output [1:0] retire_count_o,
  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o
);

  localparam FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1;
  localparam [FETCH_COUNT_W-1:0] FETCH_PACKET_COUNT_VALUE =
      (1 << FETCH_PACKET_COUNT_W);
  localparam ENABLE_DIRECT_RAS_RET = 1'b1;
  localparam BRANCH_TARGET_CACHE_INDEX_W = 4;

  wire [`XLEN-1:0] next_fetch_pc_q;
  wire outstanding_valid_q;
  wire [`XLEN-1:0] outstanding_pc_q;
  wire discard_fetch_rsp_q;

  wire [FETCH_COUNT_W-1:0] fifo_count_q;
  wire fifo_storage_head_valid_w;
  wire [`XLEN-1:0] fifo_head_pc0_w;
  wire [`XLEN-1:0] fifo_head_pc1_w;
  wire [`XLEN-1:0] fifo_head_next_pc0_w;
  wire [`XLEN-1:0] fifo_head_next_pc1_w;
  wire [`XLEN-1:0] fifo_head_packet_next_pc_w;
  wire [`INST_W-1:0] fifo_head_inst0_w;
  wire [`INST_W-1:0] fifo_head_inst1_w;
  wire [1:0] fifo_head_resp0_w;
  wire [1:0] fifo_head_resp1_w;
  wire fifo_clear_w;
  wire fifo_seed_valid_w;
  wire [`XLEN-1:0] fifo_seed_pc0_w;
  wire [`XLEN-1:0] fifo_seed_pc1_w;
  wire [`XLEN-1:0] fifo_seed_next_pc0_w;
  wire [`XLEN-1:0] fifo_seed_next_pc1_w;
  wire [`XLEN-1:0] fifo_seed_packet_next_pc_w;
  wire [`INST_W-1:0] fifo_seed_inst0_w;
  wire [`INST_W-1:0] fifo_seed_inst1_w;
  wire [1:0] fifo_seed_resp0_w;
  wire [1:0] fifo_seed_resp1_w;
  wire branch_prefetch_active_q;
  wire branch_prefetch_buffer_valid_q;
  wire [`XLEN-1:0] branch_prefetch_pc_q;
  wire [`XLEN-1:0] branch_prefetch_buf_pc0_q;
  wire [`XLEN-1:0] branch_prefetch_buf_pc1_q;
  wire [`XLEN-1:0] branch_prefetch_buf_next_pc0_q;
  wire [`XLEN-1:0] branch_prefetch_buf_next_pc1_q;
  wire [`XLEN-1:0] branch_prefetch_buf_packet_next_pc_q;
  wire [`INST_W-1:0] branch_prefetch_buf_inst0_q;
  wire [`INST_W-1:0] branch_prefetch_buf_inst1_q;
  wire [1:0] branch_prefetch_buf_resp0_q;
  wire [1:0] branch_prefetch_buf_resp1_q;
  wire branch_prefetch_clear_w;
  wire branch_spec_active_q;
  wire branch_spec_checkpoint_pending_q;
  wire [`XLEN-1:0] branch_spec_pred_pc_q;
  wire branch_target_capture_pending_q;
  wire [`XLEN-1:0] branch_target_capture_branch_pc_q;
  wire [`XLEN-1:0] branch_target_capture_target_pc_q;

  wire trap_valid_q;
  wire [`TRAP_CAUSE_W-1:0] trap_cause_q;
  wire [`XLEN-1:0] trap_pc_q;
  wire [`XLEN-1:0] trap_tval_q;
  wire exit_valid_q;
  wire exit_is_ecall_q;
  wire exit_is_ebreak_q;
  wire halted_q;
  wire stop_pending_q;
  wire pending_exit_q;
  wire pending_exit_is_ecall_q;
  wire pending_exit_is_ebreak_q;
  wire pending_branch_q;
  wire pending_branch_dispatched_q;
  wire pending_jump_q;
  wire pending_jump_dispatched_q;
  wire pending_jump_jalr_q;
  wire pending_mem_q;
  wire pending_mem_dispatched_q;
  wire pending_fp_q;
  wire pending_fp_mem_pending_q;
  wire pending_fp_mem_done_q;
  wire pending_fp_long_pending_q;
  wire pending_fp_long_done_q;
  wire [`XLEN-1:0] pending_fp_long_result_q;
  wire [4:0] pending_fp_long_fflags_q;
  wire pending_fp_compute_done_q;
  wire [`XLEN-1:0] pending_fp_compute_result_q;
  wire [4:0] pending_fp_compute_fflags_q;
  wire pending_fp_load_q;
  wire pending_fp_store_q;
  wire pending_fp_double_q;
  wire pending_fp_gpr_write_q;
  wire pending_arch_trap_q;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_cause_q;
  wire [`XLEN-1:0] pending_trap_pc_q;
  wire [`XLEN-1:0] pending_trap_tval_q;
  wire [`XLEN-1:0] pending_branch_pc_q;
  wire [`XLEN-1:0] pending_branch_next_pc_q;
  wire [`INST_W-1:0] pending_branch_inst_q;
  wire [`REG_ADDR_W-1:0] pending_branch_rs1_q;
  wire [`REG_ADDR_W-1:0] pending_branch_rs2_q;
  wire [`XLEN-1:0] pending_branch_imm_q;
  wire [2:0] pending_branch_cmp_op_q;
  wire pending_branch_pred_taken_q;
  wire pending_branch_bht_valid_q;
  wire [`BPU_BHT_INDEX_W-1:0] pending_branch_bht_idx_q;
  wire direct_branch_wait_q;
  wire [`XLEN-1:0] direct_branch_wait_pc_q;
  wire [`XLEN-1:0] pending_jump_pc_q;
  wire [`XLEN-1:0] pending_jump_next_pc_q;
  wire [`INST_W-1:0] pending_jump_inst_q;
  wire [`REG_ADDR_W-1:0] pending_jump_rs1_q;
  wire [`XLEN-1:0] pending_jump_imm_q;
  wire [`XLEN-1:0] pending_jump_target_q;
  wire return_cont_valid_q;
  wire [`XLEN-1:0] return_cont_pc_q;
  wire [`XLEN-1:0] return_cont_next_pc_q;
  wire [`INST_W-1:0] return_cont_inst_q;
  wire synth_lane1_ret_pending_q;
  wire synth_lane1_ret_branch_seen_q;
  wire [`XLEN-1:0] synth_lane1_ret_branch_pc_q;
  wire [`XLEN-1:0] synth_lane1_ret_pc_q;
  wire [`XLEN-1:0] synth_lane1_ret_next_pc_q;
  wire [`INST_W-1:0] synth_lane1_ret_inst_q;
  wire synth_lane1_branch_drop_pending_q;
  wire [`XLEN-1:0] synth_lane1_branch_drop_pc_q;
  wire [`XLEN-1:0] pending_mem_pc_q;
  wire [`INST_W-1:0] pending_mem_inst_q;
  wire [`XLEN-1:0] pending_mem_next_pc_q;
  wire [`XLEN-1:0] pending_fp_pc_q;
  wire [`INST_W-1:0] pending_fp_inst_q;
  wire [`XLEN-1:0] pending_fp_next_pc_q;
  wire [`XLEN-1:0] pending_fp_addr_q;
  wire [`XLEN-1:0] pending_fp_wdata_q;
  wire [`STRB_W-1:0] pending_fp_wstrb_q;
  wire [`REG_ADDR_W-1:0] pending_fp_rd_q;
  wire pending_system_q;
  wire pending_system_dispatched_q;
  wire pending_system_csr_q;
  wire pending_system_ecall_q;
  wire pending_system_mret_q;
  wire pending_system_wfi_q;
  wire pending_system_sfence_q;
  wire pending_system_irq_q;
  wire [`XLEN-1:0] pending_system_pc_q;
  wire [`INST_W-1:0] pending_system_inst_q;
  wire [`XLEN-1:0] pending_system_next_pc_q;
  wire [`XLEN-1:0] pending_system_csr_rdata_q;
  wire [`TRAP_CAUSE_W-1:0] pending_system_irq_cause_q;
  wire ctrl_commit_valid_q;
  wire [`XLEN-1:0] ctrl_commit_pc_q;
  wire [`INST_W-1:0] ctrl_commit_inst_q;
  wire [`XLEN-1:0] ctrl_commit_next_pc_q;
  wire ctrl_commit_rd_en_q;
  wire [`REG_ADDR_W-1:0] ctrl_commit_rd_addr_q;
  wire [`XLEN-1:0] ctrl_commit_rd_data_q;
  wire ctrl_commit_write_q;
  wire backend_drained_q;
  wire core_trap_flush_q;
  wire trap_redirect_squash_q;
  wire core_serial_flush_q;
  wire checkpoint_mem_flush_q;

  wire orphan_stop_pending_w;
  wire stop_pending_busy_w;
  wire can_run_w;
  wire fifo_empty_storage_w;
  wire fetch_rsp_dispatch_bypass_w;
  wire fifo_has_packet_w;
  wire [FETCH_COUNT_W-1:0] outstanding_count_w;
  wire fifo_reserve_available_w;
  wire ras_empty_w;
  wire ras_full_w;
  wire ras_reliable_q;
  wire [`XLEN-1:0] ras_top_w;
  wire pending_system_csr_commit_w;
  wire csr_irq_pending_w;
  wire [`TRAP_CAUSE_W-1:0] csr_irq_cause_w;

  OooFrontendRunGate #(
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) u_frontend_run_gate (
    .run_i(run_i),
    .core_trap_flush_i(core_trap_flush_q),
    .core_serial_flush_i(core_serial_flush_q),
    .stop_pending_i(stop_pending_q),
    .pending_exit_i(pending_exit_q),
    .pending_branch_i(pending_branch_q),
    .pending_jump_i(pending_jump_q),
    .pending_mem_i(pending_mem_q),
    .pending_fp_i(pending_fp_q),
    .pending_arch_trap_i(pending_arch_trap_q),
    .pending_system_i(pending_system_q),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending_q),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending_q),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending_q),
    .branch_spec_active_i(branch_spec_active_q),
    .halted_i(halted_q),
    .trap_valid_i(trap_valid_q),
    .exit_valid_i(exit_valid_q),
    .fifo_storage_head_valid_i(fifo_storage_head_valid_w),
    .outstanding_valid_i(outstanding_valid_q),
    .fetch_rsp_valid_i(fetch_rsp_valid_i),
    .discard_fetch_rsp_i(discard_fetch_rsp_q),
    .fifo_count_i(fifo_count_q),
    .fifo_depth_i(FETCH_PACKET_COUNT_VALUE),
    .orphan_stop_pending_o(orphan_stop_pending_w),
    .stop_pending_busy_o(stop_pending_busy_w),
    .can_run_o(can_run_w),
    .fifo_empty_storage_o(fifo_empty_storage_w),
    .fetch_rsp_dispatch_bypass_o(fetch_rsp_dispatch_bypass_w),
    .outstanding_count_o(outstanding_count_w),
    .fifo_reserve_available_o(fifo_reserve_available_w)
  );

  wire [`XLEN-1:0] head_pc_w;
  wire [`XLEN-1:0] head_pc1_w;
  wire [`XLEN-1:0] head_next_pc0_w;
  wire [`XLEN-1:0] head_next_pc1_w;
  wire [`XLEN-1:0] head_packet_next_pc_w;
  wire [`INST_W-1:0] head_inst0_w;
  wire [`INST_W-1:0] head_inst1_w;
  wire [1:0] head_resp0_w;
  wire [1:0] head_resp1_w;
  wire head_fetch_fault0_w;
  wire [`CTRL_BUS_W-1:0] head0_ctrl_w;
  wire [`REG_ADDR_W-1:0] head0_rs1_w;
  wire [`REG_ADDR_W-1:0] head0_rs2_w;
  wire [`REG_ADDR_W-1:0] head0_rd_unused_w;
  wire [`XLEN-1:0] head0_imm_w;
  wire [`CTRL_BUS_W-1:0] head1_ctrl_w;
  wire [`REG_ADDR_W-1:0] head1_rs1_w;
  wire [`REG_ADDR_W-1:0] head1_rs2_w;
  wire [`REG_ADDR_W-1:0] head1_rd_unused_w;
  wire [`XLEN-1:0] head1_imm_w;
  wire [`CTRL_BUS_W-1:0] branch_target_capture_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rd_unused_w;
  wire [`XLEN-1:0] branch_target_capture_imm_unused_w;
  wire [`CTRL_BUS_W-1:0] branch_prefetch0_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch0_imm_unused_w;
  wire [`CTRL_BUS_W-1:0] branch_prefetch1_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch1_imm_unused_w;
  wire [`CTRL_BUS_W-1:0] branch_prefetch_rsp1_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch_rsp1_imm_unused_w;
  wire head0_illegal_raw_w;
  wire head0_branch_raw_w;
  wire head0_jal_raw_w;
  wire head0_jalr_raw_w;
  wire head0_jump_raw_w;
  wire head0_mem_raw_w;
  wire head0_fp_load_raw_w;
  wire head0_fp_store_raw_w;
  wire head0_fp_move_to_fpr_raw_w;
  wire head0_fp_move_to_gpr_raw_w;
  wire head0_fp_class_raw_w;
  wire head0_fp_sgnj_raw_w;
  wire head0_fp_addsub_raw_w;
  wire head0_fp_mul_raw_w;
  wire head0_fp_fma_raw_w;
  wire head0_fp_div_raw_w;
  wire head0_fp_sqrt_raw_w;
  wire head0_fp_minmax_raw_w;
  wire head0_fp_compare_raw_w;
  wire head0_fp_convert_to_fpr_raw_w;
  wire head0_fp_convert_to_gpr_raw_w;
  wire head0_fp_raw_w;
  wire head0_fp_double_w;
  wire head0_fp_gpr_write_w;
  wire head0_fp_disabled_w;
  wire head0_fp_enabled_w;
  wire head0_ecall_raw_w;
  wire head0_ebreak_raw_w;
  wire head0_semihost_ebreak_w;
  wire head0_csr_raw_w;
  wire head0_mret_raw_w;
  wire head0_sret_raw_w;
  wire head0_xret_raw_w;
  wire head0_wfi_raw_w;
  wire head0_sfence_raw_w;
  wire head0_priv_system_illegal_w;
  wire head0_exit_raw_w;
  wire head0_system_raw_w;
  wire head0_arch_trap_raw_w;
  wire head0_stop_raw_w;
  wire [`OOO_SLOT_FACTS_W-1:0] head0_facts_w;

  wire head_fetch_fault1_w;
  wire head_fetch_fault_w;
  wire head1_illegal_raw_w;
  wire head1_control_raw_w;
  wire head1_branch_raw_w;
  wire head1_jal_raw_w;
  wire head1_jalr_raw_w;
  wire head1_jump_raw_w;
  wire head1_mem_raw_w;
  wire head1_fp_load_raw_w;
  wire head1_fp_store_raw_w;
  wire head1_fp_move_to_fpr_raw_w;
  wire head1_fp_move_to_gpr_raw_w;
  wire head1_fp_class_raw_w;
  wire head1_fp_sgnj_raw_w;
  wire head1_fp_addsub_raw_w;
  wire head1_fp_mul_raw_w;
  wire head1_fp_fma_raw_w;
  wire head1_fp_div_raw_w;
  wire head1_fp_sqrt_raw_w;
  wire head1_fp_minmax_raw_w;
  wire head1_fp_compare_raw_w;
  wire head1_fp_convert_to_fpr_raw_w;
  wire head1_fp_convert_to_gpr_raw_w;
  wire head1_fp_raw_w;
  wire head1_fp_double_w;
  wire head1_fp_gpr_write_w;
  wire head1_fp_disabled_w;
  wire head1_fp_enabled_w;
  wire head1_ecall_raw_w;
  wire head1_ebreak_raw_w;
  wire head1_semihost_ebreak_w;
  wire head1_csr_raw_w;
  wire head1_mret_raw_w;
  wire head1_sret_raw_w;
  wire head1_xret_raw_w;
  wire head1_wfi_raw_w;
  wire head1_sfence_raw_w;
  wire head1_priv_system_illegal_w;
  wire head1_exit_raw_w;
  wire head1_system_raw_w;
  wire head1_arch_trap_raw_w;
  wire head1_stop_raw_w;
  wire [`OOO_SLOT_FACTS_W-1:0] head1_facts_w;

  wire branch_spec_dispatch_block_w;
  wire dispatch0_ready_w;
  wire dispatch1_ready_w;
  wire dispatch0_unsupported_w;
  wire dispatch1_unsupported_w;
  wire dispatch_valid_w;
  wire dispatch0_ecall_w;
  wire dispatch0_ebreak_w;
  wire dispatch0_exit_w;
  wire dispatch0_arch_trap_w;
  wire dispatch0_system_w;
  wire dispatch0_fp_w;
  wire dispatch0_branch_w;
  wire direct_branch0_dispatch_valid_w;
  wire dispatch0_jal_w;
  wire dispatch0_jump_w;
  wire [`OOO_SLOT_FACTS_W-1:0] dispatch0_facts_w =
      dispatch_valid_w ? head0_facts_w : {`OOO_SLOT_FACTS_W{1'b0}};

  OooFetchHeadPairGate u_fetch_head_pair_gate (
    .fifo_has_packet_i(fifo_has_packet_w),
    .head_resp0_i(head_resp0_w),
    .head_resp1_i(head_resp1_w),
    .head_inst0_i(head_inst0_w),
    .head_inst1_i(head_inst1_w),
    .head0_ctrl_i(head0_ctrl_w),
    .head1_ctrl_i(head1_ctrl_w),
    .priv_mode_i(csr_priv_mode_w),
    .mstatus_i(csr_mstatus_w),
    .branch_spec_active_i(branch_spec_active_q),
    .can_run_i(can_run_w),
    .csr_irq_pending_i(csr_irq_pending_w),
    .head_fetch_fault0_o(head_fetch_fault0_w),
    .head_fetch_fault1_o(head_fetch_fault1_w),
    .head_fetch_fault_o(head_fetch_fault_w),
    .head0_illegal_raw_o(head0_illegal_raw_w),
    .head0_branch_raw_o(head0_branch_raw_w),
    .head0_jal_raw_o(head0_jal_raw_w),
    .head0_jalr_raw_o(head0_jalr_raw_w),
    .head0_jump_raw_o(head0_jump_raw_w),
    .head0_mem_raw_o(head0_mem_raw_w),
    .head0_fp_load_raw_o(head0_fp_load_raw_w),
    .head0_fp_store_raw_o(head0_fp_store_raw_w),
    .head0_fp_move_to_fpr_raw_o(head0_fp_move_to_fpr_raw_w),
    .head0_fp_move_to_gpr_raw_o(head0_fp_move_to_gpr_raw_w),
    .head0_fp_class_raw_o(head0_fp_class_raw_w),
    .head0_fp_sgnj_raw_o(head0_fp_sgnj_raw_w),
    .head0_fp_addsub_raw_o(head0_fp_addsub_raw_w),
    .head0_fp_mul_raw_o(head0_fp_mul_raw_w),
    .head0_fp_fma_raw_o(head0_fp_fma_raw_w),
    .head0_fp_div_raw_o(head0_fp_div_raw_w),
    .head0_fp_sqrt_raw_o(head0_fp_sqrt_raw_w),
    .head0_fp_minmax_raw_o(head0_fp_minmax_raw_w),
    .head0_fp_compare_raw_o(head0_fp_compare_raw_w),
    .head0_fp_convert_to_fpr_raw_o(head0_fp_convert_to_fpr_raw_w),
    .head0_fp_convert_to_gpr_raw_o(head0_fp_convert_to_gpr_raw_w),
    .head0_fp_raw_o(head0_fp_raw_w),
    .head0_fp_double_o(head0_fp_double_w),
    .head0_fp_gpr_write_o(head0_fp_gpr_write_w),
    .head0_fp_disabled_o(head0_fp_disabled_w),
    .head0_fp_enabled_o(head0_fp_enabled_w),
    .head0_ecall_raw_o(head0_ecall_raw_w),
    .head0_ebreak_raw_o(head0_ebreak_raw_w),
    .head0_semihost_ebreak_o(head0_semihost_ebreak_w),
    .head0_csr_raw_o(head0_csr_raw_w),
    .head0_mret_raw_o(head0_mret_raw_w),
    .head0_sret_raw_o(head0_sret_raw_w),
    .head0_xret_raw_o(head0_xret_raw_w),
    .head0_wfi_raw_o(head0_wfi_raw_w),
    .head0_sfence_raw_o(head0_sfence_raw_w),
    .head0_priv_system_illegal_o(head0_priv_system_illegal_w),
    .head0_exit_raw_o(head0_exit_raw_w),
    .head0_system_raw_o(head0_system_raw_w),
    .head0_arch_trap_raw_o(head0_arch_trap_raw_w),
    .head0_stop_raw_o(head0_stop_raw_w),
    .head0_facts_o(head0_facts_w),
    .head1_illegal_raw_o(head1_illegal_raw_w),
    .head1_control_raw_o(head1_control_raw_w),
    .head1_branch_raw_o(head1_branch_raw_w),
    .head1_jal_raw_o(head1_jal_raw_w),
    .head1_jalr_raw_o(head1_jalr_raw_w),
    .head1_jump_raw_o(head1_jump_raw_w),
    .head1_mem_raw_o(head1_mem_raw_w),
    .head1_fp_load_raw_o(head1_fp_load_raw_w),
    .head1_fp_store_raw_o(head1_fp_store_raw_w),
    .head1_fp_move_to_fpr_raw_o(head1_fp_move_to_fpr_raw_w),
    .head1_fp_move_to_gpr_raw_o(head1_fp_move_to_gpr_raw_w),
    .head1_fp_class_raw_o(head1_fp_class_raw_w),
    .head1_fp_sgnj_raw_o(head1_fp_sgnj_raw_w),
    .head1_fp_addsub_raw_o(head1_fp_addsub_raw_w),
    .head1_fp_mul_raw_o(head1_fp_mul_raw_w),
    .head1_fp_fma_raw_o(head1_fp_fma_raw_w),
    .head1_fp_div_raw_o(head1_fp_div_raw_w),
    .head1_fp_sqrt_raw_o(head1_fp_sqrt_raw_w),
    .head1_fp_minmax_raw_o(head1_fp_minmax_raw_w),
    .head1_fp_compare_raw_o(head1_fp_compare_raw_w),
    .head1_fp_convert_to_fpr_raw_o(head1_fp_convert_to_fpr_raw_w),
    .head1_fp_convert_to_gpr_raw_o(head1_fp_convert_to_gpr_raw_w),
    .head1_fp_raw_o(head1_fp_raw_w),
    .head1_fp_double_o(head1_fp_double_w),
    .head1_fp_gpr_write_o(head1_fp_gpr_write_w),
    .head1_fp_disabled_o(head1_fp_disabled_w),
    .head1_fp_enabled_o(head1_fp_enabled_w),
    .head1_ecall_raw_o(head1_ecall_raw_w),
    .head1_ebreak_raw_o(head1_ebreak_raw_w),
    .head1_semihost_ebreak_o(head1_semihost_ebreak_w),
    .head1_csr_raw_o(head1_csr_raw_w),
    .head1_mret_raw_o(head1_mret_raw_w),
    .head1_sret_raw_o(head1_sret_raw_w),
    .head1_xret_raw_o(head1_xret_raw_w),
    .head1_wfi_raw_o(head1_wfi_raw_w),
    .head1_sfence_raw_o(head1_sfence_raw_w),
    .head1_priv_system_illegal_o(head1_priv_system_illegal_w),
    .head1_exit_raw_o(head1_exit_raw_w),
    .head1_system_raw_o(head1_system_raw_w),
    .head1_arch_trap_raw_o(head1_arch_trap_raw_w),
    .head1_stop_raw_o(head1_stop_raw_w),
    .head1_facts_o(head1_facts_w),
    .branch_spec_dispatch_block_o(branch_spec_dispatch_block_w),
    .dispatch_valid_o(dispatch_valid_w),
    .dispatch0_ecall_o(dispatch0_ecall_w),
    .dispatch0_ebreak_o(dispatch0_ebreak_w),
    .dispatch0_exit_o(dispatch0_exit_w),
    .dispatch0_arch_trap_o(dispatch0_arch_trap_w),
    .dispatch0_system_o(dispatch0_system_w),
    .dispatch0_fp_o(dispatch0_fp_w),
    .dispatch0_branch_o(dispatch0_branch_w),
    .dispatch0_jal_o(dispatch0_jal_w),
    .dispatch0_jump_o(dispatch0_jump_w),
    .direct_branch0_dispatch_valid_o(direct_branch0_dispatch_valid_w)
  );

  wire direct_branch0_fire_w = dispatch0_branch_w &&
                               !dispatch0_unsupported_w &&
                               dispatch0_ready_w;
  wire head0_jal_call_raw_w;
  wire head1_jal_call_raw_w;
  wire ras_direct_update_safe_w;
  wire dispatch0_return_w;
  wire head1_return_candidate_w;

  OooDirectRasCandidateGate #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .ENABLE_DIRECT_RAS_RET(ENABLE_DIRECT_RAS_RET)
  ) u_direct_ras_candidate_gate (
    .head0_jal_raw_i(head0_jal_raw_w),
    .head0_rd_i(head0_rd_unused_w),
    .head1_jal_raw_i(head1_jal_raw_w),
    .head1_rd_i(head1_rd_unused_w),
    .rob_count_i(rob_count_o),
    .stop_pending_i(stop_pending_q),
    .branch_spec_active_i(branch_spec_active_q),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending_q),
    .dispatch0_jump_i(dispatch0_jump_w),
    .head0_rs1_i(head0_rs1_w),
    .head0_imm_i(head0_imm_w),
    .head1_jalr_raw_i(head1_jalr_raw_w),
    .head1_rs1_i(head1_rs1_w),
    .head1_imm_i(head1_imm_w),
    .ras_reliable_i(ras_reliable_q),
    .ras_empty_i(ras_empty_w),
    .head0_jal_call_raw_o(head0_jal_call_raw_w),
    .head1_jal_call_raw_o(head1_jal_call_raw_w),
    .ras_direct_update_safe_o(ras_direct_update_safe_w),
    .dispatch0_return_o(dispatch0_return_w),
    .head1_return_candidate_o(head1_return_candidate_w)
  );
  // lane1 ret 在 lane0 不改写 ret 源寄存器、且不是控制/CSR/AMO 时可直接走 RAS。
  // 普通 load/store 由 ROB 精确异常和 IQ/LSU 的 store-order 规则约束，不需要退化成 drain 边界。
  wire lane0_before_ret_safe_w;

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b0),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b1),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b1)
  ) u_lane0_before_ret_safety (
    .ctrl_i(head0_ctrl_w),
    .resp_i(2'b00),
    .inst_i(32'h0000_0013),
    .rd_i(head0_rd_unused_w),
    .hazard_rs_i(head1_rs1_w),
    .safe_o(lane0_before_ret_safe_w)
  );
  wire dispatch1_direct_jal_w;
  wire dispatch1_return_w;
  wire direct_branch1_dispatch_valid_w;
  wire dispatch1_barrier_w;
  wire dispatch1_control_unsupported_w;
  wire dispatch1_mem_unsupported_w;
  wire dispatch_unsupported_w;
  wire dispatch_fire_w;
  wire dispatch1_barrier_fire_w;
  wire direct_jal0_fire_w;
  wire direct_jal1_fire_w;
  wire direct_ret1_fire_w;
  wire direct_branch1_fire_w;

  OooFrontendDispatchGate u_frontend_dispatch_gate (
    .dispatch_valid_i(dispatch_valid_w),
    .dispatch0_exit_i(dispatch0_exit_w),
    .dispatch0_arch_trap_i(dispatch0_arch_trap_w),
    .dispatch0_system_i(dispatch0_system_w),
    .dispatch0_fp_i(dispatch0_fp_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .dispatch0_jump_i(dispatch0_jump_w),
    .dispatch0_unsupported_i(dispatch0_unsupported_w),
    .dispatch1_unsupported_i(dispatch1_unsupported_w),
    .dispatch0_ready_i(dispatch0_ready_w),
    .dispatch1_ready_i(dispatch1_ready_w),
    .head0_fp_raw_i(head0_fp_raw_w),
    .head1_fp_raw_i(head1_fp_raw_w),
    .head_fetch_fault1_i(head_fetch_fault1_w),
    .head1_exit_raw_i(head1_exit_raw_w),
    .head1_system_raw_i(head1_system_raw_w),
    .head1_arch_trap_raw_i(head1_arch_trap_raw_w),
    .head1_control_raw_i(head1_control_raw_w),
    .head1_branch_raw_i(head1_branch_raw_w),
    .head1_jal_raw_i(head1_jal_raw_w),
    .head1_jalr_raw_i(head1_jalr_raw_w),
    .head1_jal_call_raw_i(head1_jal_call_raw_w),
    .head1_return_candidate_i(head1_return_candidate_w),
    .lane0_before_ret_safe_i(lane0_before_ret_safe_w),
    .dispatch1_direct_jal_o(dispatch1_direct_jal_w),
    .dispatch1_return_o(dispatch1_return_w),
    .direct_branch1_dispatch_valid_o(direct_branch1_dispatch_valid_w),
    .dispatch1_barrier_o(dispatch1_barrier_w),
    .dispatch1_control_unsupported_o(dispatch1_control_unsupported_w),
    .dispatch1_mem_unsupported_o(dispatch1_mem_unsupported_w),
    .dispatch_unsupported_o(dispatch_unsupported_w),
    .dispatch_fire_o(dispatch_fire_w),
    .dispatch1_barrier_fire_o(dispatch1_barrier_fire_w),
    .direct_jal0_fire_o(direct_jal0_fire_w),
    .direct_jal1_fire_o(direct_jal1_fire_w),
    .direct_ret1_fire_o(direct_ret1_fire_w),
    .direct_branch1_fire_o(direct_branch1_fire_w)
  );
  wire direct_jal0_dispatch_valid_w = dispatch0_jal_w;
  wire direct_jal_fire_w = direct_jal0_fire_w || direct_jal1_fire_w;
  wire [`BPU_BHT_INDEX_W-1:0] head0_branch_bht_idx_w;
  wire head0_branch_bht_valid_w;
  wire head0_branch_predict_strong_w;
  wire head0_branch_pred_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] head1_branch_bht_idx_w;
  wire head1_branch_bht_valid_w;
  wire head1_branch_predict_strong_w;
  wire head1_branch_pred_taken_w;
  wire direct_branch_fire_w;
  wire [`XLEN-1:0] direct_branch_pc_w;
  wire [`XLEN-1:0] direct_branch_next_pc_w;
  wire [`XLEN-1:0] direct_branch_imm_w;
  wire [`XLEN-1:0] head0_branch_target_w;
  wire [`XLEN-1:0] direct_branch_target_w;
  wire [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx_w;
  wire direct_branch_bht_valid_w;
  wire direct_branch_predict_taken_w;
  wire [`XLEN-1:0] direct_branch_pred_pc_w;
  wire direct_branch_resolve_valid_w;
  wire [`XLEN-1:0] direct_branch_resolve_next_pc_w;
  wire direct_branch_resolve_misaligned_w;
  wire direct_branch_resolve_redirect_w;
  wire direct_branch_resolve_taken_w;
  wire direct_branch0_lane1_ret_w;

  OooDirectBranchResolveGate u_direct_branch_resolve_gate (
    .direct_branch0_fire_i(direct_branch0_fire_w),
    .direct_branch1_fire_i(direct_branch1_fire_w),
    .head0_pc_i(head_pc_w),
    .head1_pc_i(head_pc1_w),
    .head0_next_pc_i(head_next_pc0_w),
    .head1_next_pc_i(head_next_pc1_w),
    .head0_imm_i(head0_imm_w),
    .head1_imm_i(head1_imm_w),
    .head0_bht_idx_i(head0_branch_bht_idx_w),
    .head0_bht_valid_i(head0_branch_bht_valid_w),
    .head0_pred_taken_i(head0_branch_pred_taken_w),
    .head1_bht_idx_i(head1_branch_bht_idx_w),
    .head1_bht_valid_i(head1_branch_bht_valid_w),
    .head1_pred_taken_i(head1_branch_pred_taken_w),
    .dispatch_resolve_valid_i(core_dispatch_branch_resolve_valid_w),
    .dispatch_resolve_pc_i(core_dispatch_branch_resolve_pc_w),
    .dispatch_resolve_next_pc_i(core_dispatch_branch_resolve_next_pc_w),
    .dispatch_resolve_misaligned_i(core_dispatch_branch_resolve_misaligned_w),
    .issue_resolve_valid_i(core_branch_resolve_valid_w),
    .issue_resolve_pc_i(core_branch_resolve_pc_w),
    .issue_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .issue_resolve_misaligned_i(core_branch_resolve_misaligned_w),
    .trap_redirect_squash_i(trap_redirect_squash_q),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending_q),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending_q),
    .head1_return_candidate_i(head1_return_candidate_w),
    .direct_branch_fire_o(direct_branch_fire_w),
    .direct_branch_pc_o(direct_branch_pc_w),
    .direct_branch_next_pc_o(direct_branch_next_pc_w),
    .direct_branch_imm_o(direct_branch_imm_w),
    .head0_branch_target_o(head0_branch_target_w),
    .direct_branch_target_o(direct_branch_target_w),
    .direct_branch_bht_idx_o(direct_branch_bht_idx_w),
    .direct_branch_bht_valid_o(direct_branch_bht_valid_w),
    .direct_branch_predict_taken_o(direct_branch_predict_taken_w),
    .direct_branch_pred_pc_o(direct_branch_pred_pc_w),
    .direct_branch_resolve_valid_o(direct_branch_resolve_valid_w),
    .direct_branch_resolve_next_pc_o(direct_branch_resolve_next_pc_w),
    .direct_branch_resolve_misaligned_o(direct_branch_resolve_misaligned_w),
    .direct_branch_resolve_redirect_o(direct_branch_resolve_redirect_w),
    .direct_branch_resolve_taken_o(direct_branch_resolve_taken_w),
    .direct_branch0_lane1_ret_o(direct_branch0_lane1_ret_w)
  );
  wire direct_ret0_dispatch_valid_w = dispatch0_return_w;
  wire direct_ret0_fire_w = dispatch0_return_w &&
                            !dispatch0_unsupported_w &&
                            dispatch0_ready_w;
  wire direct_frontend_flush_w;
  wire [`XLEN-1:0] direct_jal_target_w =
      direct_jal0_fire_w ? (head_pc_w + head0_imm_w) :
                           (head_pc1_w + head1_imm_w);
  wire [`XLEN-1:0] direct_ret_target_w = ras_top_w;
  wire direct_jal0_call_w = direct_jal0_fire_w &&
                            ((head0_rd_unused_w == 5'd1) ||
                             (head0_rd_unused_w == 5'd5));
  wire direct_jal1_call_w = direct_jal1_fire_w &&
                            ((head1_rd_unused_w == 5'd1) ||
                             (head1_rd_unused_w == 5'd5));
  wire direct_jal_call_raw_w = direct_jal0_call_w || direct_jal1_call_w;
  wire direct_jal_call_w =
      ras_direct_update_safe_w && direct_jal_call_raw_w;
  wire direct_jal_call_unsafe_w =
      ENABLE_DIRECT_RAS_RET && direct_jal_call_raw_w &&
      !ras_direct_update_safe_w;
  wire [`XLEN-1:0] direct_jal_link_w =
      direct_jal0_call_w ? head_next_pc0_w : head_next_pc1_w;
  wire return_cont_uop_safe_w;
  wire return_cont_safe_w = !head_fetch_fault1_w &&
                            return_cont_uop_safe_w;

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b0),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b0),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b1),
    .ALLOW_SRET(1'b1),
    .ALLOW_AMO(1'b1),
    .CHECK_RD_HAZARD(1'b0)
  ) u_return_cont_safety (
    .ctrl_i(head1_ctrl_w),
    .resp_i(2'b00),
    .inst_i(32'h0000_0013),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(return_cont_uop_safe_w)
  );
  wire return_cont_capture_w =
      direct_jal0_call_w && return_cont_safe_w;
  wire return_cont_match_w =
      return_cont_valid_q && (return_cont_pc_q == ras_top_w);
  wire branch_fallthrough_safe_w;

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b1),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b1),
    .ALLOW_SRET(1'b1),
    .ALLOW_AMO(1'b1),
    .CHECK_RD_HAZARD(1'b0)
  ) u_branch_fallthrough_safety (
    .ctrl_i(head1_ctrl_w),
    .resp_i(head_resp1_w),
    .inst_i(head_inst1_w),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(branch_fallthrough_safe_w)
  );
  wire stop_head_w;
  wire fifo_pop_w;
  wire fetch_rsp_bypass_consumed_w;
  wire fifo_storage_pop_w;
  wire fifo_can_accept_rsp_w;
  wire fetch_rsp_can_enqueue_w;
  wire fetch_rsp_can_drop_w;
  wire direct_fetch_drop_w;
  wire fetch_rsp_fire_w;
  wire fetch_rsp_enqueue_w;
  wire [`XLEN-1:0] fetch_dec0_pc_w;
  wire [`XLEN-1:0] fetch_dec0_next_pc_w;
  wire [`INST_W-1:0] fetch_dec0_inst_w;
  wire [1:0] fetch_dec0_resp_w;
  wire fetch_dec0_control_stop_w;
  wire [`XLEN-1:0] fetch_dec1_pc_w;
  wire [`XLEN-1:0] fetch_dec1_next_pc_w;
  wire [`INST_W-1:0] fetch_dec1_inst_w;
  wire [1:0] fetch_dec1_resp_w;
  wire fetch_dec1_control_stop_w;
  wire [`XLEN-1:0] fetch_rsp_packet_next_pc_w;

  OooFetchPacketDecode u_fetch_packet_decode (
    .rsp_pc_i(outstanding_pc_q),
    .rsp_inst0_i(fetch_rsp_inst0_i),
    .rsp_resp0_i(fetch_rsp_resp0_i),
    .rsp_inst1_i(fetch_rsp_inst1_i),
    .rsp_resp1_i(fetch_rsp_resp1_i),
    .dec0_pc_o(fetch_dec0_pc_w),
    .dec0_next_pc_o(fetch_dec0_next_pc_w),
    .dec0_inst_o(fetch_dec0_inst_w),
    .dec0_resp_o(fetch_dec0_resp_w),
    .dec0_control_stop_o(fetch_dec0_control_stop_w),
    .dec1_pc_o(fetch_dec1_pc_w),
    .dec1_next_pc_o(fetch_dec1_next_pc_w),
    .dec1_inst_o(fetch_dec1_inst_w),
    .dec1_resp_o(fetch_dec1_resp_w),
    .dec1_control_stop_o(fetch_dec1_control_stop_w),
    .packet_next_pc_o(fetch_rsp_packet_next_pc_w)
  );

  OooFetchPacketHeadMux u_fetch_packet_head_mux (
    .bypass_valid_i(fetch_rsp_dispatch_bypass_w),
    .fifo_head_valid_i(fifo_storage_head_valid_w),
    .bypass_pc0_i(fetch_dec0_pc_w),
    .bypass_pc1_i(fetch_dec1_pc_w),
    .bypass_next_pc0_i(fetch_dec0_next_pc_w),
    .bypass_next_pc1_i(fetch_dec1_next_pc_w),
    .bypass_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .bypass_inst0_i(fetch_dec0_inst_w),
    .bypass_inst1_i(fetch_dec1_inst_w),
    .bypass_resp0_i(fetch_dec0_resp_w),
    .bypass_resp1_i(fetch_dec1_resp_w),
    .fifo_pc0_i(fifo_head_pc0_w),
    .fifo_pc1_i(fifo_head_pc1_w),
    .fifo_next_pc0_i(fifo_head_next_pc0_w),
    .fifo_next_pc1_i(fifo_head_next_pc1_w),
    .fifo_packet_next_pc_i(fifo_head_packet_next_pc_w),
    .fifo_inst0_i(fifo_head_inst0_w),
    .fifo_inst1_i(fifo_head_inst1_w),
    .fifo_resp0_i(fifo_head_resp0_w),
    .fifo_resp1_i(fifo_head_resp1_w),
    .head_has_packet_o(fifo_has_packet_w),
    .head_pc0_o(head_pc_w),
    .head_pc1_o(head_pc1_w),
    .head_next_pc0_o(head_next_pc0_w),
    .head_next_pc1_o(head_next_pc1_w),
    .head_packet_next_pc_o(head_packet_next_pc_w),
    .head_inst0_o(head_inst0_w),
    .head_inst1_o(head_inst1_w),
    .head_resp0_o(head_resp0_w),
    .head_resp1_o(head_resp1_w)
  );

  wire fetch_rsp_control_stop_w;
  wire branch_target_capture_safe_w;

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b1),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b0),
    .ALLOW_BITMANIP(1'b0),
    .ALLOW_SFENCE(1'b1),
    .ALLOW_SRET(1'b1),
    .ALLOW_AMO(1'b1),
    .CHECK_RD_HAZARD(1'b0)
  ) u_branch_target_capture_safety (
    .ctrl_i(branch_target_capture_ctrl_w),
    .resp_i(fetch_dec0_resp_w),
    .inst_i(fetch_dec0_inst_w),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(branch_target_capture_safe_w)
  );
  wire branch_target_capture_hit_w;
  wire branch_target_cache_capture_w =
      branch_target_capture_hit_w && branch_target_capture_safe_w;
  wire [`XLEN-1:0] pending_branch_target_w;
  wire [`XLEN-1:0] branch_prefetch_branch_pred_pc_w;
  wire pending_jump_jalr_ret_hint_w;
  wire pending_jump_jalr_btb_lookup_w;

  OooBranchPrefetchSourceGate u_branch_prefetch_source_gate (
    .pending_branch_pc_i(pending_branch_pc_q),
    .pending_branch_imm_i(pending_branch_imm_q),
    .pending_branch_next_pc_i(pending_branch_next_pc_q),
    .pending_branch_pred_taken_i(pending_branch_pred_taken_q),
    .stop_pending_i(stop_pending_q),
    .pending_jump_i(pending_jump_q),
    .pending_jump_jalr_i(pending_jump_jalr_q),
    .pending_jump_rd_i(pending_jump_inst_q[11:7]),
    .pending_jump_rs1_i(pending_jump_rs1_q),
    .pending_jump_imm_i(pending_jump_imm_q),
    .ras_empty_i(ras_empty_w),
    .pending_branch_target_o(pending_branch_target_w),
    .branch_pred_pc_o(branch_prefetch_branch_pred_pc_w),
    .jalr_ret_hint_o(pending_jump_jalr_ret_hint_w),
    .jalr_btb_lookup_o(pending_jump_jalr_btb_lookup_w)
  );
  wire [`BPU_BTB_INDEX_W-1:0] pending_jump_jalr_btb_idx_w;
  wire pending_jump_jalr_btb_entry_hit_w;
  wire pending_jump_jalr_btb_hit_w;
  wire [`XLEN-1:0] pending_jump_jalr_btb_target_w;
  wire branch_prefetch_branch_req_valid_w;
  wire branch_prefetch_jalr_req_valid_w;
  wire branch_prefetch_req_valid_w;
  wire [`XLEN-1:0] branch_prefetch_req_pc_w;
  wire branch_resolve_pending_pc_match_w;
  wire branch_resolve_pending_match_w;
  wire branch_resolve_redirect_w;
  wire backend_execute_quiet_w;
  wire branch_spec_checkpoint_capture_w;
  wire branch_spec_resolve_valid_w;
  wire branch_spec_pred_match_w;
  wire branch_spec_restore_w;
  wire branch_spec_redirect_w;
  wire direct_branch_wait_resolve_match_w;
  wire direct_branch_wait_untracked_w;
  wire branch_resolve_untracked_w;
  wire branch_resolve_untracked_redirect_w;

  OooBranchPrefetchRequestGate u_branch_prefetch_request_gate (
    .stop_pending_i(stop_pending_q),
    .pending_branch_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .branch_resolve_pending_match_i(branch_resolve_pending_match_w),
    .jalr_btb_hit_i(pending_jump_jalr_btb_hit_w),
    .pending_jump_dispatched_i(pending_jump_dispatched_q),
    .branch_prefetch_active_i(branch_prefetch_active_q),
    .outstanding_valid_i(outstanding_valid_q),
    .discard_fetch_rsp_i(discard_fetch_rsp_q),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending_q),
    .branch_spec_active_i(branch_spec_active_q),
    .halted_i(halted_q),
    .trap_valid_i(trap_valid_q),
    .exit_valid_i(exit_valid_q),
    .branch_pred_pc_i(branch_prefetch_branch_pred_pc_w),
    .jalr_btb_target_i(pending_jump_jalr_btb_target_w),
    .branch_req_valid_o(branch_prefetch_branch_req_valid_w),
    .jalr_req_valid_o(branch_prefetch_jalr_req_valid_w),
    .req_valid_o(branch_prefetch_req_valid_w),
    .req_pc_o(branch_prefetch_req_pc_w)
  );
  wire branch_prefetch_rsp_capture_w;
  wire branch_prefetch_match_w;
  wire branch_prefetch_buffer_match_w;
  wire branch_prefetch_rsp_match_w;
  wire branch_prefetch_hit_available_w;
  wire branch_prefetch_pending_match_w;

  OooBranchPrefetchStatusGate u_branch_prefetch_status_gate (
    .branch_prefetch_active_i(branch_prefetch_active_q),
    .branch_prefetch_buffer_valid_i(branch_prefetch_buffer_valid_q),
    .stop_pending_i(stop_pending_q),
    .pending_branch_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .pending_jump_i(pending_jump_q),
    .pending_jump_jalr_i(pending_jump_jalr_q),
    .fetch_rsp_fire_i(fetch_rsp_fire_w),
    .branch_prefetch_pc_i(branch_prefetch_pc_q),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .rsp_capture_o(branch_prefetch_rsp_capture_w),
    .match_o(branch_prefetch_match_w),
    .buffer_match_o(branch_prefetch_buffer_match_w),
    .rsp_match_o(branch_prefetch_rsp_match_w),
    .hit_available_o(branch_prefetch_hit_available_w),
    .pending_match_o(branch_prefetch_pending_match_w)
  );
  wire branch_prefetch_req_fire_w =
      branch_prefetch_req_valid_w && fetch_req_ready_i;
  wire [`XLEN-1:0] branch_prefetch_hit_pc0_w;
  wire [`XLEN-1:0] branch_prefetch_hit_pc1_w;
  wire [`XLEN-1:0] branch_prefetch_hit_next_pc0_w;
  wire [`XLEN-1:0] branch_prefetch_hit_next_pc1_w;
  wire [`XLEN-1:0] branch_prefetch_hit_packet_next_pc_w;
  wire [`INST_W-1:0] branch_prefetch_hit_inst0_w;
  wire [`INST_W-1:0] branch_prefetch_hit_inst1_w;
  wire [1:0] branch_prefetch_hit_resp0_w;
  wire [1:0] branch_prefetch_hit_resp1_w;

  OooFetchPacketHitMux u_branch_prefetch_hit_mux (
    .rsp_select_i(branch_prefetch_rsp_match_w),
    .rsp_pc0_i(fetch_dec0_pc_w),
    .rsp_pc1_i(fetch_dec1_pc_w),
    .rsp_next_pc0_i(fetch_dec0_next_pc_w),
    .rsp_next_pc1_i(fetch_dec1_next_pc_w),
    .rsp_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .rsp_inst0_i(fetch_dec0_inst_w),
    .rsp_inst1_i(fetch_dec1_inst_w),
    .rsp_resp0_i(fetch_dec0_resp_w),
    .rsp_resp1_i(fetch_dec1_resp_w),
    .buf_pc0_i(branch_prefetch_buf_pc0_q),
    .buf_pc1_i(branch_prefetch_buf_pc1_q),
    .buf_next_pc0_i(branch_prefetch_buf_next_pc0_q),
    .buf_next_pc1_i(branch_prefetch_buf_next_pc1_q),
    .buf_packet_next_pc_i(branch_prefetch_buf_packet_next_pc_q),
    .buf_inst0_i(branch_prefetch_buf_inst0_q),
    .buf_inst1_i(branch_prefetch_buf_inst1_q),
    .buf_resp0_i(branch_prefetch_buf_resp0_q),
    .buf_resp1_i(branch_prefetch_buf_resp1_q),
    .hit_pc0_o(branch_prefetch_hit_pc0_w),
    .hit_pc1_o(branch_prefetch_hit_pc1_w),
    .hit_next_pc0_o(branch_prefetch_hit_next_pc0_w),
    .hit_next_pc1_o(branch_prefetch_hit_next_pc1_w),
    .hit_packet_next_pc_o(branch_prefetch_hit_packet_next_pc_w),
    .hit_inst0_o(branch_prefetch_hit_inst0_w),
    .hit_inst1_o(branch_prefetch_hit_inst1_w),
    .hit_resp0_o(branch_prefetch_hit_resp0_w),
    .hit_resp1_o(branch_prefetch_hit_resp1_w)
  );
  OooBranchResolveRecoveryGate u_branch_resolve_recovery_gate (
    .stop_pending_i(stop_pending_q),
    .pending_branch_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .pending_branch_pc_i(pending_branch_pc_q),
    .branch_prefetch_match_i(branch_prefetch_match_w),
    .core_branch_resolve_valid_i(core_branch_resolve_valid_w),
    .core_branch_resolve_pc_i(core_branch_resolve_pc_w),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned_w),
    .trap_redirect_squash_i(trap_redirect_squash_q),
    .execute0_valid_i(execute0_valid_unused_w),
    .execute1_valid_i(execute1_valid_unused_w),
    .mem_rsp_ready_i(mem_rsp_ready_o),
    .mem1_rsp_ready_i(mem1_rsp_ready_o),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending_q),
    .branch_spec_active_i(branch_spec_active_q),
    .branch_spec_pred_pc_i(branch_spec_pred_pc_q),
    .core_mem_idle_i(core_mem_idle_w),
    .core_pending_load_branch_dep_i(core_pending_load_branch_dep_w),
    .direct_branch_wait_pending_i(direct_branch_wait_q),
    .direct_branch_wait_pc_i(direct_branch_wait_pc_q),
    .direct_branch_resolve_valid_i(direct_branch_resolve_valid_w),
    .branch_resolve_pending_pc_match_o(branch_resolve_pending_pc_match_w),
    .branch_resolve_pending_match_o(branch_resolve_pending_match_w),
    .branch_resolve_redirect_o(branch_resolve_redirect_w),
    .backend_execute_quiet_o(backend_execute_quiet_w),
    .branch_spec_checkpoint_capture_o(branch_spec_checkpoint_capture_w),
    .branch_spec_resolve_valid_o(branch_spec_resolve_valid_w),
    .branch_spec_pred_match_o(branch_spec_pred_match_w),
    .branch_spec_restore_o(branch_spec_restore_w),
    .branch_spec_redirect_o(branch_spec_redirect_w),
    .direct_branch_wait_resolve_match_o(direct_branch_wait_resolve_match_w),
    .direct_branch_wait_untracked_o(direct_branch_wait_untracked_w),
    .branch_resolve_untracked_o(branch_resolve_untracked_w),
    .branch_resolve_untracked_redirect_o(branch_resolve_untracked_redirect_w)
  );

  OooDirectBranchWaitBuffer u_direct_branch_wait_buffer (
    .clk(clk),
    .rst(rst || flush_i),
    .clear_i(csr_trap_mem_valid_w),
    .resolve_match_i(direct_branch_wait_resolve_match_w),
    .branch_fire_i(direct_branch_fire_w),
    .branch_resolve_valid_i(direct_branch_resolve_valid_w),
    .branch_pc_i(direct_branch_pc_w),
    .pending_o(direct_branch_wait_q),
    .pc_o(direct_branch_wait_pc_q)
  );

  wire direct_redirect_fetch_w;
  wire redirect_fetch_req_valid_w;
  wire [`XLEN-1:0] redirect_fetch_pc_w;
  wire [`XLEN-1:0] fetch_req_pc_w;
  wire can_issue_request_w;
  wire fetch_request_blocked_by_trap_w;
  wire fetch_req_fire_w;

  OooFetchRequestMux u_fetch_request_mux (
    .outstanding_valid_i(outstanding_valid_q),
    .fetch_rsp_fire_i(fetch_rsp_fire_w),
    .fetch_rsp_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .next_fetch_pc_i(next_fetch_pc_q),
    .direct_jal_fire_i(direct_jal_fire_w),
    .direct_ret0_fire_i(direct_ret0_fire_w),
    .direct_ret1_fire_i(direct_ret1_fire_w),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret_w),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit_w),
    .pending_jump_redirect_after_dispatch_i(
        pending_jump_redirect_after_dispatch_w),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect_w),
    .branch_resolve_redirect_i(branch_resolve_redirect_w),
    .branch_spec_redirect_i(branch_spec_redirect_w),
    .branch_resolve_untracked_redirect_i(
        branch_resolve_untracked_redirect_w),
    .branch_fallthrough_dispatch_i(branch_fallthrough_dispatch_w),
    .branch_fallthrough_outstanding_match_i(
        branch_fallthrough_outstanding_match_w),
    .return_cont_dispatch_i(return_cont_dispatch_w),
    .return_cont_next_pc_i(return_cont_next_pc_q),
    .ras_top_i(ras_top_w),
    .branch_target_dispatch_i(branch_target_dispatch_w),
    .branch_target_cache_next_pc_i(branch_target_cache_next_pc_w),
    .head_next_pc1_i(head_next_pc1_w),
    .direct_jal_target_i(direct_jal_target_w),
    .direct_ret_target_i(direct_ret_target_w),
    .direct_branch_resolve_next_pc_i(direct_branch_resolve_next_pc_w),
    .pending_jump_resolved_target_i(pending_jump_resolved_target_w),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .branch_prefetch_req_valid_i(branch_prefetch_req_valid_w),
    .branch_prefetch_req_pc_i(branch_prefetch_req_pc_w),
    .direct_redirect_fetch_o(direct_redirect_fetch_w),
    .redirect_fetch_req_valid_o(redirect_fetch_req_valid_w),
    .redirect_fetch_pc_o(redirect_fetch_pc_w),
    .fetch_req_pc_o(fetch_req_pc_w)
  );

  OooFrontendActionGate u_frontend_action_gate (
    .direct_jal_fire_i(direct_jal_fire_w),
    .direct_branch0_fire_i(direct_branch0_fire_w),
    .direct_branch1_fire_i(direct_branch1_fire_w),
    .direct_ret0_fire_i(direct_ret0_fire_w),
    .direct_ret1_fire_i(direct_ret1_fire_w),
    .can_run_i(can_run_w),
    .fifo_has_packet_i(fifo_has_packet_w),
    .branch_spec_dispatch_block_i(branch_spec_dispatch_block_w),
    .head_fetch_fault0_i(head_fetch_fault0_w),
    .dispatch0_exit_i(dispatch0_exit_w),
    .dispatch0_arch_trap_i(dispatch0_arch_trap_w),
    .dispatch0_system_i(dispatch0_system_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .dispatch0_jump_i(dispatch0_jump_w),
    .dispatch1_barrier_i(dispatch1_barrier_w),
    .dispatch1_direct_jal_i(dispatch1_direct_jal_w),
    .direct_branch1_dispatch_valid_i(direct_branch1_dispatch_valid_w),
    .dispatch_unsupported_i(dispatch_unsupported_w),
    .dispatch_fire_i(dispatch_fire_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .direct_jal0_fire_i(direct_jal0_fire_w),
    .fetch_rsp_fire_i(fetch_rsp_fire_w),
    .fetch_rsp_can_enqueue_i(fetch_rsp_can_enqueue_w),
    .fetch_dec0_control_stop_i(fetch_dec0_control_stop_w),
    .fetch_dec1_control_stop_i(fetch_dec1_control_stop_w),
    .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
    .csr_trap_ex_valid_i(csr_trap_ex_valid_w),
    .csr_trap_irq_valid_i(csr_trap_irq_valid_w),
    .core_trap_flush_i(core_trap_flush_q),
    .core_serial_flush_i(core_serial_flush_q),
    .direct_frontend_flush_o(direct_frontend_flush_w),
    .stop_head_o(stop_head_w),
    .fifo_pop_o(fifo_pop_w),
    .fetch_rsp_control_stop_o(fetch_rsp_control_stop_w),
    .fetch_request_blocked_by_trap_o(fetch_request_blocked_by_trap_w)
  );

  OooFetchFlowControl #(
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) u_fetch_flow_control (
    .fetch_rsp_valid_i(fetch_rsp_valid_i),
    .fetch_req_ready_i(fetch_req_ready_i),
    .fetch_request_blocked_by_trap_i(fetch_request_blocked_by_trap_w),
    .redirect_fetch_req_valid_i(redirect_fetch_req_valid_w),
    .branch_prefetch_req_valid_i(branch_prefetch_req_valid_w),
    .can_run_i(can_run_w),
    .stop_head_i(stop_head_w),
    .fetch_rsp_control_stop_i(fetch_rsp_control_stop_w),
    .discard_fetch_rsp_i(discard_fetch_rsp_q),
    .fifo_reserve_available_i(fifo_reserve_available_w),
    .outstanding_valid_i(outstanding_valid_q),
    .fifo_count_i(fifo_count_q),
    .fifo_depth_i(FETCH_PACKET_COUNT_VALUE),
    .fifo_pop_i(fifo_pop_w),
    .fetch_rsp_dispatch_bypass_i(fetch_rsp_dispatch_bypass_w),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .stop_pending_busy_i(stop_pending_busy_w),
    .halted_i(halted_q),
    .trap_valid_i(trap_valid_q),
    .exit_valid_i(exit_valid_q),
    .can_issue_request_o(can_issue_request_w),
    .fetch_req_valid_o(fetch_req_valid_o),
    .fetch_req_fire_o(fetch_req_fire_w),
    .fetch_rsp_ready_o(fetch_rsp_ready_o),
    .fetch_rsp_fire_o(fetch_rsp_fire_w),
    .fifo_storage_pop_o(fifo_storage_pop_w),
    .fifo_can_accept_rsp_o(fifo_can_accept_rsp_w),
    .fetch_rsp_can_enqueue_o(fetch_rsp_can_enqueue_w),
    .fetch_rsp_can_drop_o(fetch_rsp_can_drop_w),
    .direct_fetch_drop_o(direct_fetch_drop_w),
    .fetch_rsp_bypass_consumed_o(fetch_rsp_bypass_consumed_w),
    .fetch_rsp_enqueue_o(fetch_rsp_enqueue_w)
  );

  wire frontend_dispatch_to_backend_valid_w =
      dispatch_valid_w && !dispatch0_branch_w && !dispatch0_jal_w &&
      !dispatch0_jump_w && !dispatch0_exit_w && !dispatch0_system_w &&
      !dispatch0_fp_w &&
      !dispatch1_barrier_w &&
      !dispatch1_control_unsupported_w &&
      !dispatch1_mem_unsupported_w;
  wire lane1_barrier_dispatch0_valid_w =
      dispatch1_barrier_w;

  wire execute0_valid_unused_w;
  wire execute1_valid_unused_w;
  wire core_mem_idle_w;
  wire core_mem_req_valid_w;
  wire core_mem_req_write_w;
  wire [`XLEN-1:0] core_mem_req_addr_w;
  wire [`XLEN-1:0] core_mem_req_wdata_w;
  wire [`STRB_W-1:0] core_mem_req_wstrb_w;
  wire core_mem_rsp_ready_w;
  wire core_mem1_req_valid_w;
  wire core_mem1_req_write_w;
  wire [`XLEN-1:0] core_mem1_req_addr_w;
  wire [`XLEN-1:0] core_mem1_req_wdata_w;
  wire [`STRB_W-1:0] core_mem1_req_wstrb_w;
  wire core_mem1_rsp_ready_w;
  wire core_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_branch_resolve_next_pc_w;
  wire core_branch_resolve_misaligned_w;
  wire core_dispatch_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_next_pc_w;
  wire core_dispatch_branch_resolve_misaligned_w;
  wire core_pending_load_branch_dep_w;
  wire [`XLEN-1:0] a0_data_w;
  wire core_commit0_valid_w;
  wire [`XLEN-1:0] core_commit0_pc_w;
  wire [`XLEN-1:0] core_commit0_next_pc_w;
  wire [`INST_W-1:0] core_commit0_inst_w;
  wire core_commit0_rd_en_w;
  wire [`REG_ADDR_W-1:0] core_commit0_rd_addr_w;
  wire [`XLEN-1:0] core_commit0_rd_data_w;
  wire core_commit0_exception_w;
  wire [`TRAP_CAUSE_W-1:0] core_commit0_cause_w;
  wire [`XLEN-1:0] core_commit0_tval_w;
  wire core_commit0_write_w;
  wire core_commit1_valid_w;
  wire [`XLEN-1:0] core_commit1_pc_w;
  wire [`XLEN-1:0] core_commit1_next_pc_w;
  wire [`INST_W-1:0] core_commit1_inst_w;
  wire core_commit1_rd_en_w;
  wire [`REG_ADDR_W-1:0] core_commit1_rd_addr_w;
  wire [`XLEN-1:0] core_commit1_rd_data_w;
  wire core_commit1_exception_w;
  wire [`TRAP_CAUSE_W-1:0] core_commit1_cause_w;
  wire [`XLEN-1:0] core_commit1_tval_w;
  wire core_commit1_write_w;
  wire [1:0] core_retire_count_w;
  wire [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w;
  wire core_commit0_csr_w;
  wire core_commit_exception_trap_w;
  wire csr_trap_mem_valid_w;
  wire [`XLEN-1:0] csr_trap_mem_pc_w;
  wire [`TRAP_CAUSE_W-1:0] csr_trap_mem_cause_w;
  wire [`XLEN-1:0] csr_trap_mem_tval_w;
  wire head1_csr_probe_w;
  wire [`INST_W-1:0] csr_access_inst_w;
  wire [11:0] csr_access_addr_w;
  wire [2:0] csr_access_funct3_w;
  wire [`REG_ADDR_W-1:0] csr_access_rs1_idx_w;
  wire [`XLEN-1:0] csr_access_rs1_data_w;
  wire csr_access_set_clear_noop_w;
  wire csr_access_need_write_w;
  wire csr_access_valid_w;
  wire pending_system_satp_write_commit_w;
  wire pending_system_sfence_commit_w;

  OooCsrAccessRequestMux u_csr_access_request_mux (
    .core_commit0_valid_i(core_commit0_valid_w),
    .core_commit0_exception_i(core_commit0_exception_w),
    .core_commit0_pc_i(core_commit0_pc_w),
    .core_commit0_inst_i(core_commit0_inst_w),
    .pending_system_i(pending_system_q),
    .pending_system_csr_i(pending_system_csr_q),
    .pending_system_dispatched_i(pending_system_dispatched_q),
    .pending_system_sfence_i(pending_system_sfence_q),
    .pending_system_pc_i(pending_system_pc_q),
    .pending_system_inst_i(pending_system_inst_q),
    .dispatch_valid_i(dispatch_valid_w),
    .dispatch0_system_i(dispatch0_system_w),
    .dispatch1_barrier_i(dispatch1_barrier_w),
    .head0_csr_raw_i(head0_csr_raw_w),
    .head1_csr_raw_i(head1_csr_raw_w),
    .head_inst0_i(head_inst0_w),
    .head_inst1_i(head_inst1_w),
    .stop_pending_i(stop_pending_q),
    .drain_complete_i(drain_complete_w),
    .debug_gprs_i(core_debug_gprs_w),
    .core_commit0_csr_o(core_commit0_csr_w),
    .pending_system_csr_commit_o(pending_system_csr_commit_w),
    .head1_csr_probe_o(head1_csr_probe_w),
    .csr_access_valid_o(csr_access_valid_w),
    .csr_access_inst_o(csr_access_inst_w),
    .csr_access_addr_o(csr_access_addr_w),
    .csr_access_funct3_o(csr_access_funct3_w),
    .csr_access_rs1_idx_o(csr_access_rs1_idx_w),
    .csr_access_rs1_data_o(csr_access_rs1_data_w),
    .csr_access_set_clear_noop_o(csr_access_set_clear_noop_w),
    .csr_access_need_write_o(csr_access_need_write_w),
    .pending_system_satp_write_commit_o(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_o(pending_system_sfence_commit_w)
  );
  wire [`TRAP_CAUSE_W-1:0] csr_ecall_cause_w;
  wire pending_system_ecall_trap_w;
  wire pending_arch_trap_fire_w;
  wire csr_trap_ex_valid_w;
  wire [`XLEN-1:0] csr_trap_ex_pc_w;
  wire [`TRAP_CAUSE_W-1:0] csr_trap_ex_cause_w;
  wire [`XLEN-1:0] csr_trap_ex_tval_w;
  wire csr_trap_irq_valid_w;
  wire [`XLEN-1:0] csr_trap_irq_pc_w;
  wire [`TRAP_CAUSE_W-1:0] csr_trap_irq_cause_w;
  wire csr_mret_valid_w;
  wire csr_sret_valid_w;
  wire csr_real_mret_valid_w;
  wire priv_predictor_boundary_w;

  OooCsrTrapRequestMux u_csr_trap_request_mux (
    .core_commit0_valid_i(core_commit0_valid_w),
    .core_commit0_exception_i(core_commit0_exception_w),
    .core_commit0_pc_i(core_commit0_pc_w),
    .core_commit0_cause_i(core_commit0_cause_w),
    .core_commit0_tval_i(core_commit0_tval_w),
    .core_commit1_valid_i(core_commit1_valid_w),
    .core_commit1_exception_i(core_commit1_exception_w),
    .core_commit1_pc_i(core_commit1_pc_w),
    .core_commit1_cause_i(core_commit1_cause_w),
    .core_commit1_tval_i(core_commit1_tval_w),
    .stop_pending_i(stop_pending_q),
    .drain_complete_i(drain_complete_w),
    .pending_arch_trap_i(pending_arch_trap_q),
    .pending_trap_cause_i(pending_trap_cause_q),
    .pending_trap_pc_i(pending_trap_pc_q),
    .pending_trap_tval_i(pending_trap_tval_q),
    .pending_system_i(pending_system_q),
    .pending_system_ecall_i(pending_system_ecall_q),
    .pending_system_mret_i(pending_system_mret_q),
    .pending_system_irq_i(pending_system_irq_q),
    .pending_system_pc_i(pending_system_pc_q),
    .pending_system_inst_i(pending_system_inst_q),
    .pending_system_irq_cause_i(pending_system_irq_cause_q),
    .csr_ecall_cause_i(csr_ecall_cause_w),
    .pending_system_satp_write_commit_i(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_i(pending_system_sfence_commit_w),
    .core_commit_exception_trap_o(core_commit_exception_trap_w),
    .trap_mem_valid_o(csr_trap_mem_valid_w),
    .trap_mem_pc_o(csr_trap_mem_pc_w),
    .trap_mem_cause_o(csr_trap_mem_cause_w),
    .trap_mem_tval_o(csr_trap_mem_tval_w),
    .pending_system_ecall_trap_o(pending_system_ecall_trap_w),
    .pending_arch_trap_fire_o(pending_arch_trap_fire_w),
    .trap_ex_valid_o(csr_trap_ex_valid_w),
    .trap_ex_pc_o(csr_trap_ex_pc_w),
    .trap_ex_cause_o(csr_trap_ex_cause_w),
    .trap_ex_tval_o(csr_trap_ex_tval_w),
    .trap_irq_valid_o(csr_trap_irq_valid_w),
    .trap_irq_pc_o(csr_trap_irq_pc_w),
    .trap_irq_cause_o(csr_trap_irq_cause_w),
    .mret_valid_o(csr_mret_valid_w),
    .sret_valid_o(csr_sret_valid_w),
    .real_mret_valid_o(csr_real_mret_valid_w),
    .priv_predictor_boundary_o(priv_predictor_boundary_w)
  );
  wire [`XLEN-1:0] csr_rdata_w;
  wire csr_illegal_w;
  wire [`XLEN-1:0] csr_trap_target_w;
  wire [`XLEN-1:0] csr_mepc_w;
  wire [`XLEN-1:0] csr_ret_target_w;
  wire [1:0] csr_priv_mode_w;
  wire [`XLEN-1:0] csr_mstatus_w;
  wire [`XLEN-1:0] csr_satp_w;
  wire csr_svpbmt_en_w;
  wire [`PMP_CFG_BUS_W-1:0] csr_pmpcfg_w;
  wire [`PMP_ADDR_BUS_W-1:0] csr_pmpaddr_w;
  wire head0_csr_illegal_w = head0_csr_raw_w && !head1_csr_probe_w &&
                             csr_illegal_w;
  wire head1_csr_illegal_w = head1_csr_probe_w && csr_illegal_w;
  wire [`XLEN-1:0] pending_branch_rs1_data_w;
  wire [`XLEN-1:0] pending_branch_rs2_data_w;
  wire [`XLEN-1:0] pending_jump_rs1_data_w;
  wire pending_branch_taken_w;
  wire [`XLEN-1:0] pending_branch_fallthrough_w;
  wire [`XLEN-1:0] pending_branch_next_pc_w;
  wire pending_branch_misaligned_w;
  wire pending_jump_jalr_sum_lsb_unused_w;
  wire [`XLEN-1:0] pending_jump_resolved_target_w;
  wire pending_jump_misaligned_w;
  wire pending_jump_resolve_ready_w;
  wire pending_jump_return_w;
  wire pending_jump_return_fire_w;
  wire pending_jump_call_w;
  wire pending_jump_call_fire_w;
  wire pending_jump_nolink_w;
  wire pending_jump_nolink_commit_w;
  wire pending_jump_redirect_after_dispatch_w;
  wire pending_control_ready_w;

  OooPendingControlResolveGate u_pending_control_resolve_gate (
    .pending_branch_i(pending_branch_q),
    .pending_branch_taken_i(pending_branch_taken_w),
    .pending_branch_target_i(pending_branch_target_w),
    .pending_branch_next_pc_i(pending_branch_next_pc_q),
    .stop_pending_i(stop_pending_q),
    .pending_jump_i(pending_jump_q),
    .pending_jump_jalr_i(pending_jump_jalr_q),
    .pending_jump_dispatched_i(pending_jump_dispatched_q),
    .backend_drained_i(backend_drained_q),
    .pending_jump_pc_i(pending_jump_pc_q),
    .pending_jump_imm_i(pending_jump_imm_q),
    .pending_jump_rs1_data_i(pending_jump_rs1_data_w),
    .pending_jump_inst_i(pending_jump_inst_q),
    .pending_jump_rs1_i(pending_jump_rs1_q),
    .ras_empty_i(ras_empty_w),
    .jump_dispatch_fire_i(jump_dispatch_fire_w),
    .commit_ready_i(commit_ready_i),
    .pending_branch_fallthrough_o(pending_branch_fallthrough_w),
    .pending_branch_next_pc_o(pending_branch_next_pc_w),
    .pending_branch_misaligned_o(pending_branch_misaligned_w),
    .pending_jump_jalr_sum_lsb_o(pending_jump_jalr_sum_lsb_unused_w),
    .pending_jump_resolved_target_o(pending_jump_resolved_target_w),
    .pending_jump_misaligned_o(pending_jump_misaligned_w),
    .pending_jump_resolve_ready_o(pending_jump_resolve_ready_w),
    .pending_jump_return_o(pending_jump_return_w),
    .pending_jump_return_fire_o(pending_jump_return_fire_w),
    .pending_jump_call_o(pending_jump_call_w),
    .pending_jump_call_fire_o(pending_jump_call_fire_w),
    .pending_jump_nolink_o(pending_jump_nolink_w),
    .pending_jump_nolink_commit_o(pending_jump_nolink_commit_w),
    .pending_jump_redirect_after_dispatch_o(
        pending_jump_redirect_after_dispatch_w),
    .pending_control_ready_o(pending_control_ready_w)
  );
  wire jalr_prefetch_match_w;
  wire jalr_prefetch_buffer_match_w;
  wire jalr_prefetch_rsp_match_w;
  wire jalr_prefetch_hit_available_w;
  wire jalr_prefetch_pending_match_w;

  OooJalrPrefetchStatusGate u_jalr_prefetch_status_gate (
    .branch_prefetch_active_i(branch_prefetch_active_q),
    .branch_prefetch_buffer_valid_i(branch_prefetch_buffer_valid_q),
    .branch_prefetch_rsp_capture_i(branch_prefetch_rsp_capture_w),
    .stop_pending_i(stop_pending_q),
    .pending_jump_i(pending_jump_q),
    .pending_jump_jalr_i(pending_jump_jalr_q),
    .pending_jump_dispatched_i(pending_jump_dispatched_q),
    .pending_jump_target_i(pending_jump_target_q),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_w),
    .pending_jump_resolved_target_i(pending_jump_resolved_target_w),
    .pending_jump_misaligned_i(pending_jump_misaligned_w),
    .branch_prefetch_pc_i(branch_prefetch_pc_q),
    .match_o(jalr_prefetch_match_w),
    .buffer_match_o(jalr_prefetch_buffer_match_w),
    .rsp_match_o(jalr_prefetch_rsp_match_w),
    .hit_available_o(jalr_prefetch_hit_available_w),
    .pending_match_o(jalr_prefetch_pending_match_w)
  );
  wire [`XLEN-1:0] jalr_prefetch_hit_pc0_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_pc1_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_next_pc0_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_next_pc1_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_packet_next_pc_w;
  wire [`INST_W-1:0] jalr_prefetch_hit_inst0_w;
  wire [`INST_W-1:0] jalr_prefetch_hit_inst1_w;
  wire [1:0] jalr_prefetch_hit_resp0_w;
  wire [1:0] jalr_prefetch_hit_resp1_w;

  OooFetchPacketHitMux u_jalr_prefetch_hit_mux (
    .rsp_select_i(jalr_prefetch_rsp_match_w),
    .rsp_pc0_i(fetch_dec0_pc_w),
    .rsp_pc1_i(fetch_dec1_pc_w),
    .rsp_next_pc0_i(fetch_dec0_next_pc_w),
    .rsp_next_pc1_i(fetch_dec1_next_pc_w),
    .rsp_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .rsp_inst0_i(fetch_dec0_inst_w),
    .rsp_inst1_i(fetch_dec1_inst_w),
    .rsp_resp0_i(fetch_dec0_resp_w),
    .rsp_resp1_i(fetch_dec1_resp_w),
    .buf_pc0_i(branch_prefetch_buf_pc0_q),
    .buf_pc1_i(branch_prefetch_buf_pc1_q),
    .buf_next_pc0_i(branch_prefetch_buf_next_pc0_q),
    .buf_next_pc1_i(branch_prefetch_buf_next_pc1_q),
    .buf_packet_next_pc_i(branch_prefetch_buf_packet_next_pc_q),
    .buf_inst0_i(branch_prefetch_buf_inst0_q),
    .buf_inst1_i(branch_prefetch_buf_inst1_q),
    .buf_resp0_i(branch_prefetch_buf_resp0_q),
    .buf_resp1_i(branch_prefetch_buf_resp1_q),
    .hit_pc0_o(jalr_prefetch_hit_pc0_w),
    .hit_pc1_o(jalr_prefetch_hit_pc1_w),
    .hit_next_pc0_o(jalr_prefetch_hit_next_pc0_w),
    .hit_next_pc1_o(jalr_prefetch_hit_next_pc1_w),
    .hit_packet_next_pc_o(jalr_prefetch_hit_packet_next_pc_w),
    .hit_inst0_o(jalr_prefetch_hit_inst0_w),
    .hit_inst1_o(jalr_prefetch_hit_inst1_w),
    .hit_resp0_o(jalr_prefetch_hit_resp0_w),
    .hit_resp1_o(jalr_prefetch_hit_resp1_w)
  );
  wire jalr_btb_update_w =
      pending_jump_resolve_ready_w && pending_jump_jalr_q &&
      !pending_jump_misaligned_w;

  OooJalrBtb u_jalr_btb (
    .clk(clk),
    .rst(rst),
    .clear_i(flush_i || pending_system_satp_write_commit_w),
    .lookup_enable_i(pending_jump_jalr_btb_lookup_w),
    .lookup_pc_i(pending_jump_pc_q),
    .lookup_idx_o(pending_jump_jalr_btb_idx_w),
    .lookup_entry_hit_o(pending_jump_jalr_btb_entry_hit_w),
    .lookup_hit_o(pending_jump_jalr_btb_hit_w),
    .lookup_target_o(pending_jump_jalr_btb_target_w),
    .update_valid_i(jalr_btb_update_w),
    .update_pc_i(pending_jump_pc_q),
    .update_target_i(pending_jump_resolved_target_w)
  );

  wire synth_lane1_ret_branch_commit0_w =
      synth_lane1_ret_pending_q && !synth_lane1_ret_branch_seen_q &&
      core_commit0_valid_w &&
      (core_commit0_pc_w == synth_lane1_ret_branch_pc_q);
  wire synth_lane1_ret_branch_commit1_w =
      synth_lane1_ret_pending_q && !synth_lane1_ret_branch_seen_q &&
      core_commit1_valid_w &&
      (core_commit1_pc_w == synth_lane1_ret_branch_pc_q);
  wire return_cont_optional_w;
  wire branch_target_cache_hit_w;
  wire [BRANCH_TARGET_CACHE_INDEX_W-1:0] branch_target_cache_idx_unused_w;
  wire [`XLEN-1:0] branch_target_cache_target_pc_w;
  wire [`XLEN-1:0] branch_target_cache_next_pc_w;
  wire [`INST_W-1:0] branch_target_cache_inst_w;

  wire branch_prefetch_dispatch0_safe_w;
  wire branch_prefetch_dispatch1_safe_w;
  wire branch_prefetch_rsp_dispatch0_safe_w;
  wire branch_prefetch_rsp_dispatch1_safe_w;

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b1),
    .ALLOW_BITMANIP(1'b1),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b0)
  ) u_branch_prefetch_buf0_safety (
    .ctrl_i(branch_prefetch0_ctrl_w),
    .resp_i(branch_prefetch_buf_resp0_q),
    .inst_i(32'h0000_0013),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(branch_prefetch_dispatch0_safe_w)
  );

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b1),
    .ALLOW_BITMANIP(1'b1),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b0)
  ) u_branch_prefetch_buf1_safety (
    .ctrl_i(branch_prefetch1_ctrl_w),
    .resp_i(branch_prefetch_buf_resp1_q),
    .inst_i(32'h0000_0013),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(branch_prefetch_dispatch1_safe_w)
  );

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b1),
    .ALLOW_BITMANIP(1'b1),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b0)
  ) u_branch_prefetch_rsp0_safety (
    .ctrl_i(branch_target_capture_ctrl_w),
    .resp_i(fetch_dec0_resp_w),
    .inst_i(32'h0000_0013),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(branch_prefetch_rsp_dispatch0_safe_w)
  );

  OooFrontendUopSafety #(
    .REQUIRE_RESP_OK(1'b1),
    .REJECT_SEMIHOST_ENTER(1'b0),
    .ALLOW_LOAD(1'b1),
    .ALLOW_STORE(1'b0),
    .ALLOW_MULDIV(1'b1),
    .ALLOW_BITMANIP(1'b1),
    .ALLOW_SFENCE(1'b0),
    .ALLOW_SRET(1'b0),
    .ALLOW_AMO(1'b0),
    .CHECK_RD_HAZARD(1'b0)
  ) u_branch_prefetch_rsp1_safety (
    .ctrl_i(branch_prefetch_rsp1_ctrl_w),
    .resp_i(fetch_dec1_resp_w),
    .inst_i(32'h0000_0013),
    .rd_i({`REG_ADDR_W{1'b0}}),
    .hazard_rs_i({`REG_ADDR_W{1'b0}}),
    .safe_o(branch_prefetch_rsp_dispatch1_safe_w)
  );

  wire branch_target_store_fire_w;
  wire [`XLEN-1:0] branch_target_store_addr_w;
  wire branch_target_cache_invalidate_all_w;
  wire branch_target_capture_arm_w;
  wire [`XLEN-1:0] branch_target_capture_arm_branch_pc_w;
  wire branch_target_dispatch_w;

  OooBranchTargetCacheControlGate u_branch_target_cache_control_gate (
    .mem_req_valid_i(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_i(mem_req_write_o),
    .mem_req_addr_i(mem_req_addr_o),
    .mem1_req_valid_i(mem1_req_valid_o),
    .mem1_req_ready_i(mem1_req_ready_i),
    .mem1_req_write_i(mem1_req_write_o),
    .mem1_req_addr_i(mem1_req_addr_o),
    .core_commit0_valid_i(core_commit0_valid_w),
    .core_commit0_inst_i(core_commit0_inst_w),
    .core_commit1_valid_i(core_commit1_valid_w),
    .core_commit1_inst_i(core_commit1_inst_w),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect_w),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret_w),
    .branch_target_dispatch_i(branch_target_dispatch_w),
    .direct_branch_resolve_taken_i(direct_branch_resolve_taken_w),
    .direct_branch1_fire_i(direct_branch1_fire_w),
    .head_pc0_i(head_pc_w),
    .head_pc1_i(head_pc1_w),
    .branch_target_store_fire_o(branch_target_store_fire_w),
    .branch_target_store_addr_o(branch_target_store_addr_w),
    .branch_target_cache_invalidate_all_o(
        branch_target_cache_invalidate_all_w),
    .branch_target_capture_arm_o(branch_target_capture_arm_w),
    .branch_target_capture_arm_branch_pc_o(
        branch_target_capture_arm_branch_pc_w)
  );

  OooBranchTargetCaptureBuffer u_branch_target_capture_buffer (
    .clk(clk),
    .rst(rst || flush_i),
    .global_clear_i(csr_trap_mem_valid_w),
    .frontend_clear_i(direct_frontend_flush_w),
    .hit_clear_enable_i(!branch_target_cache_invalidate_all_w),
    .arm_i(branch_target_capture_arm_w),
    .arm_branch_pc_i(branch_target_capture_arm_branch_pc_w),
    .arm_target_pc_i(direct_branch_resolve_next_pc_w),
    .rsp_valid_i(fetch_rsp_fire_w),
    .rsp_pc_i(fetch_dec0_pc_w),
    .pending_o(branch_target_capture_pending_q),
    .branch_pc_o(branch_target_capture_branch_pc_q),
    .target_pc_o(branch_target_capture_target_pc_q),
    .hit_o(branch_target_capture_hit_w)
  );

  OooBranchTargetCache #(
    .INDEX_W(BRANCH_TARGET_CACHE_INDEX_W)
  ) u_branch_target_cache (
    .clk(clk),
    .rst(rst),
    .clear_i(flush_i || pending_system_satp_write_commit_w),
    .lookup_branch_pc_i(head_pc_w),
    .lookup_target_pc_i(head0_branch_target_w),
    .lookup_idx_o(branch_target_cache_idx_unused_w),
    .lookup_hit_o(branch_target_cache_hit_w),
    .lookup_target_pc_o(branch_target_cache_target_pc_w),
    .lookup_next_pc_o(branch_target_cache_next_pc_w),
    .lookup_inst_o(branch_target_cache_inst_w),
    .invalidate_all_i(branch_target_cache_invalidate_all_w),
    .store_fire_i(branch_target_store_fire_w),
    .store_addr_i(branch_target_store_addr_w),
    .capture_valid_i(branch_target_cache_capture_w),
    .capture_branch_pc_i(branch_target_capture_branch_pc_q),
    .capture_target_pc_i(branch_target_capture_target_pc_q),
    .capture_next_pc_i(fetch_dec0_next_pc_w),
    .capture_inst_i(fetch_dec0_inst_w)
  );

  wire return_cont_attempt_ready_w;
  wire return_cont_attempt_w;
  wire branch_fallthrough_outstanding_match_w;
  wire branch_target_append_candidate_w;
  wire branch_fallthrough_append_safe_w;
  wire branch_fallthrough_append_candidate_w;
  wire branch_target_append_attempt_w;
  wire branch_fallthrough_append_attempt_w;
  wire synth_lane1_branch_append_w;
  wire branch_target_append_w;
  wire branch_fallthrough_append_w;
  wire return_cont_dispatch_w;
  wire branch_fallthrough_dispatch_w;
  wire branch_fallthrough_keep_outstanding_w;
  wire branch_fallthrough_capture_rsp_w;
  wire branch_prefetch_rsp_raw_match_w;
  wire branch_prefetch_dispatch_buffer_w;
  wire branch_prefetch_dispatch_rsp_w;
  wire branch_prefetch_dispatch_attempt_w;
  wire branch_prefetch_dispatch_fire_w;
  wire branch_prefetch_hit_to_fifo_w;
  wire dispatch1_optional_w;

  OooBranchAppendDispatchGate #(
    .ROB_COUNT_W(ROB_COUNT_W)
  ) u_branch_append_dispatch_gate (
    .dispatch0_branch_i(dispatch0_branch_w),
    .return_cont_match_i(return_cont_match_w),
    .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret_w),
    .ctrl_commit_valid_i(ctrl_commit_valid_q),
    .commit_ready_i(commit_ready_i),
    .core_commit0_valid_i(core_commit0_valid_w),
    .core_commit1_valid_i(core_commit1_valid_w),
    .rob_count_i(rob_count_o),
    .outstanding_valid_i(outstanding_valid_q),
    .outstanding_pc_i(outstanding_pc_q),
    .head_next_pc1_i(head_next_pc1_w),
    .fetch_rsp_dispatch_bypass_i(fetch_rsp_dispatch_bypass_w),
    .branch_fallthrough_safe_i(branch_fallthrough_safe_w),
    .branch_target_cache_hit_i(branch_target_cache_hit_w),
    .direct_branch0_fire_i(direct_branch0_fire_w),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect_w),
    .direct_branch_resolve_taken_i(direct_branch_resolve_taken_w),
    .dispatch1_ready_i(dispatch1_ready_w),
    .fetch_rsp_fire_i(fetch_rsp_fire_w),
    .branch_prefetch_active_i(branch_prefetch_active_q),
    .branch_prefetch_buffer_valid_i(branch_prefetch_buffer_valid_q),
    .stop_pending_i(stop_pending_q),
    .pending_branch_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .fetch_rsp_valid_i(fetch_rsp_valid_i),
    .branch_prefetch_pc_i(branch_prefetch_pc_q),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .branch_resolve_pending_match_i(branch_resolve_pending_match_w),
    .branch_spec_active_i(branch_spec_active_q),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned_w),
    .branch_prefetch_buffer_match_i(branch_prefetch_buffer_match_w),
    .branch_prefetch_dispatch0_safe_i(branch_prefetch_dispatch0_safe_w),
    .branch_prefetch_dispatch1_safe_i(branch_prefetch_dispatch1_safe_w),
    .branch_prefetch_rsp_dispatch0_safe_i(
        branch_prefetch_rsp_dispatch0_safe_w),
    .branch_prefetch_rsp_dispatch1_safe_i(
        branch_prefetch_rsp_dispatch1_safe_w),
    .branch_prefetch_hit_available_i(branch_prefetch_hit_available_w),
    .return_cont_optional_o(return_cont_optional_w),
    .return_cont_attempt_ready_o(return_cont_attempt_ready_w),
    .return_cont_attempt_o(return_cont_attempt_w),
    .branch_fallthrough_outstanding_match_o(
        branch_fallthrough_outstanding_match_w),
    .branch_target_append_candidate_o(branch_target_append_candidate_w),
    .branch_fallthrough_append_safe_o(branch_fallthrough_append_safe_w),
    .branch_fallthrough_append_candidate_o(
        branch_fallthrough_append_candidate_w),
    .branch_target_append_attempt_o(branch_target_append_attempt_w),
    .branch_fallthrough_append_attempt_o(branch_fallthrough_append_attempt_w),
    .synth_lane1_branch_append_o(synth_lane1_branch_append_w),
    .branch_target_append_o(branch_target_append_w),
    .branch_fallthrough_append_o(branch_fallthrough_append_w),
    .return_cont_dispatch_o(return_cont_dispatch_w),
    .branch_target_dispatch_o(branch_target_dispatch_w),
    .branch_fallthrough_dispatch_o(branch_fallthrough_dispatch_w),
    .branch_fallthrough_keep_outstanding_o(
        branch_fallthrough_keep_outstanding_w),
    .branch_fallthrough_capture_rsp_o(branch_fallthrough_capture_rsp_w),
    .branch_prefetch_rsp_raw_match_o(branch_prefetch_rsp_raw_match_w),
    .branch_prefetch_dispatch_buffer_o(branch_prefetch_dispatch_buffer_w),
    .branch_prefetch_dispatch_rsp_o(branch_prefetch_dispatch_rsp_w),
    .branch_prefetch_dispatch_attempt_o(branch_prefetch_dispatch_attempt_w),
    .branch_prefetch_dispatch_fire_o(branch_prefetch_dispatch_fire_w),
    .branch_prefetch_hit_to_fifo_o(branch_prefetch_hit_to_fifo_w),
    .dispatch1_optional_o(dispatch1_optional_w)
  );
  wire synth_lane1_branch_drop_match_w =
      synth_lane1_branch_drop_pending_q &&
      core_commit0_valid_w &&
      (core_commit0_pc_w == synth_lane1_branch_drop_pc_q);
  wire synth_lane1_ret_drop_branch_w =
      synth_lane1_branch_drop_match_w &&
      synth_lane1_ret_pending_q && synth_lane1_ret_branch_seen_q &&
      !ctrl_commit_valid_q && commit_ready_i;
  wire synth_lane1_ret_before_core0_w =
      synth_lane1_ret_pending_q && synth_lane1_ret_branch_seen_q &&
      !synth_lane1_branch_drop_match_w &&
      !ctrl_commit_valid_q && commit_ready_i;
  wire synth_lane1_ret_after_core0_w =
      !ctrl_commit_valid_q && synth_lane1_ret_branch_commit0_w;
  wire synth_lane1_ret_commit_w =
      synth_lane1_ret_before_core0_w ||
      synth_lane1_ret_after_core0_w ||
      synth_lane1_ret_drop_branch_w;
  OooSyntheticLane1RetSequencer u_synthetic_lane1_ret_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .ret_commit_i(synth_lane1_ret_commit_w),
    .branch_drop_match_i(synth_lane1_branch_drop_match_w),
    .branch_commit1_i(synth_lane1_ret_branch_commit1_w),
    .capture_i(direct_frontend_flush_w &&
               (direct_branch0_fire_w || direct_branch1_fire_w) &&
               direct_branch0_lane1_ret_w),
    .capture_branch_seen_i(synth_lane1_branch_append_w),
    .capture_branch_drop_i(synth_lane1_branch_append_w),
    .capture_branch_pc_i(head_pc_w),
    .capture_ret_pc_i(head_pc1_w),
    .capture_ret_next_pc_i(head_next_pc1_w),
    .capture_ret_inst_i(head_inst1_w),
    .satp_clear_i(pending_system_satp_write_commit_w),
    .trap_clear_i(csr_trap_mem_valid_w),
    .ret_pending_o(synth_lane1_ret_pending_q),
    .ret_branch_seen_o(synth_lane1_ret_branch_seen_q),
    .ret_branch_pc_o(synth_lane1_ret_branch_pc_q),
    .ret_pc_o(synth_lane1_ret_pc_q),
    .ret_next_pc_o(synth_lane1_ret_next_pc_q),
    .ret_inst_o(synth_lane1_ret_inst_q),
    .branch_drop_pending_o(synth_lane1_branch_drop_pending_q),
    .branch_drop_pc_o(synth_lane1_branch_drop_pc_q)
  );

  wire backend_drained_w = (rob_count_o == {ROB_COUNT_W{1'b0}}) &&
                           (issue_count_o == {ISSUE_COUNT_W{1'b0}}) &&
                           (core_retire_count_w == 2'b00) &&
                           !synth_lane1_ret_pending_q &&
                           !synth_lane1_branch_drop_pending_q;
  wire direct_branch_spec_start_w = 1'b0;
  wire jump_dispatch_valid_w = pending_jump_resolve_ready_w &&
                               !pending_jump_nolink_w &&
                               !pending_jump_misaligned_w;
  wire system_csr_dispatch_valid_w =
      stop_pending_q && pending_system_q && pending_system_csr_q &&
      !pending_system_dispatched_q && backend_drained_q;
  wire system_csr_dispatch_fire_w =
      system_csr_dispatch_valid_w && dispatch0_ready_w;
  wire pending_system_capture_irq_w;
  wire pending_system_capture_head0_w;
  wire pending_system_capture_lane1_w;
  wire pending_system_clear_w;
  wire pending_branch_capture_direct_w;
  wire pending_branch_capture_head0_w;
  wire pending_branch_capture_lane1_w;
  wire pending_branch_clear_w;
  wire pending_jump_capture_head0_w;
  wire pending_jump_capture_lane1_w;
  wire pending_jump_clear_w;
  wire pending_fp_capture_head0_w;
  wire pending_fp_capture_lane1_w;
  wire pending_fp_clear_w;
  wire pending_mem_capture_lane1_w;
  wire pending_mem_clear_w;
  wire pending_trap_exit_clear_exit_w;
  wire pending_trap_exit_clear_arch_w;
  wire pending_trap_exit_capture_exit_w;
  wire pending_trap_exit_capture_exit_valid_w;
  wire pending_trap_exit_capture_exit_ecall_w;
  wire pending_trap_exit_capture_exit_ebreak_w;
  wire pending_trap_exit_capture_arch_w;
  wire pending_trap_exit_capture_arch_valid_w;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_exit_capture_cause_w;
  wire [`XLEN-1:0] pending_trap_exit_capture_pc_w;
  wire [`XLEN-1:0] pending_trap_exit_capture_tval_w;
  wire pending_mem_resolve_ready_w = stop_pending_q && pending_mem_q &&
                                     !pending_mem_dispatched_q &&
                                     backend_drained_q;
  wire mem_dispatch_valid_w = pending_mem_resolve_ready_w;
  wire pending_fp_long_op_w;
  wire pending_fp_compute_op_w;
  wire pending_fp_long_wait_w =
      pending_fp_long_op_w && !pending_fp_long_done_q;
  wire pending_fp_compute_wait_w =
      pending_fp_compute_op_w && !pending_fp_compute_done_q;
  wire pending_fp_long_start_w =
      stop_pending_q && pending_fp_q && backend_drained_q &&
      pending_fp_mem_done_q && pending_fp_long_op_w &&
      !pending_fp_long_pending_q && !pending_fp_long_done_q;
  wire pending_fp_compute_start_w =
      stop_pending_q && pending_fp_q && backend_drained_q &&
      pending_fp_mem_done_q && pending_fp_compute_op_w &&
      !pending_fp_compute_done_q;
  wire pending_branch_commit_resolve_w =
      !direct_frontend_flush_w && stop_pending_q && backend_drained_w &&
      pending_branch_q && pending_branch_dispatched_q &&
      !branch_resolve_pending_match_w && !branch_spec_active_q &&
      !branch_spec_checkpoint_pending_q && !pending_jump_q &&
      !pending_mem_q && !pending_fp_q && !pending_arch_trap_q &&
      !pending_system_q;
  wire pending_branch_match_clear_w =
      !direct_frontend_flush_w && stop_pending_q && pending_branch_q &&
      pending_branch_dispatched_q && branch_resolve_pending_match_w &&
      !branch_spec_active_q;
  wire pending_branch_resolve_wait_w =
      pending_branch_q && pending_branch_dispatched_q &&
      !branch_resolve_pending_match_w && !pending_branch_commit_resolve_w;
  wire pending_replay_wait_w =
      pending_branch_resolve_wait_w ||
      (pending_jump_q && !pending_jump_dispatched_q) ||
      (pending_mem_q && !pending_mem_dispatched_q) ||
      (pending_fp_q && (!pending_fp_mem_done_q || pending_fp_long_wait_w ||
                        pending_fp_compute_wait_w)) ||
      (pending_system_q && pending_system_csr_q);
  wire drain_complete_w = stop_pending_q && backend_drained_w &&
                          pending_control_ready_w &&
                          !pending_replay_wait_w;

  OooPendingDispatchArbiter u_pending_dispatch_arbiter (
    .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .can_run_i(can_run_w),
    .fifo_has_packet_i(fifo_has_packet_w),
    .csr_irq_pending_i(csr_irq_pending_w),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid_w),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
    .pending_branch_match_clear_i(pending_branch_match_clear_w),
    .branch_resolve_untracked_i(branch_resolve_untracked_w),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_w),
    .pending_jump_misaligned_i(pending_jump_misaligned_w),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit_w),
    .pending_jump_redirect_after_dispatch_i(
        pending_jump_redirect_after_dispatch_w),
    .pending_system_csr_commit_i(pending_system_csr_commit_w),
    .stop_pending_i(stop_pending_q),
    .drain_complete_i(drain_complete_w),
    .direct_branch0_fire_i(direct_branch0_fire_w),
    .direct_branch1_fire_i(direct_branch1_fire_w),
    .head_fetch_fault0_i(head_fetch_fault0_w),
    .head_fetch_fault1_i(head_fetch_fault1_w),
    .head_resp0_i(head_resp0_w),
    .head_resp1_i(head_resp1_w),
    .head_pc0_i(head_pc_w),
    .head_pc1_i(head_pc1_w),
    .head_inst0_i(head_inst0_w),
    .head_inst1_i(head_inst1_w),
    .dispatch0_facts_i(dispatch0_facts_w),
    .head1_facts_i(head1_facts_w),
    .dispatch0_arch_trap_i(dispatch0_arch_trap_w),
    .dispatch0_exit_i(dispatch0_exit_w),
    .dispatch0_ecall_i(dispatch0_ecall_w),
    .dispatch0_ebreak_i(dispatch0_ebreak_w),
    .dispatch0_fp_i(dispatch0_fp_w),
    .dispatch0_system_i(dispatch0_system_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .direct_jal0_dispatch_valid_i(direct_jal0_dispatch_valid_w),
    .dispatch0_jump_i(dispatch0_jump_w),
    .dispatch0_return_i(dispatch0_return_w),
    .dispatch0_unsupported_i(dispatch0_unsupported_w),
    .dispatch_unsupported_i(dispatch_unsupported_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .head0_csr_illegal_i(head0_csr_illegal_w),
    .head0_semihost_ebreak_i(head0_semihost_ebreak_w),
    .head1_system_raw_i(head1_system_raw_w),
    .head1_exit_raw_i(head1_exit_raw_w),
    .head1_ecall_raw_i(head1_ecall_raw_w),
    .head1_ebreak_raw_i(head1_ebreak_raw_w),
    .head1_arch_trap_raw_i(head1_arch_trap_raw_w),
    .head1_illegal_raw_i(head1_illegal_raw_w),
    .head1_fp_disabled_i(head1_fp_disabled_w),
    .head1_priv_system_illegal_i(head1_priv_system_illegal_w),
    .head1_csr_illegal_i(head1_csr_illegal_w),
    .head1_semihost_ebreak_i(head1_semihost_ebreak_w),
    .pending_system_capture_irq_o(pending_system_capture_irq_w),
    .pending_system_capture_head0_o(pending_system_capture_head0_w),
    .pending_system_capture_lane1_o(pending_system_capture_lane1_w),
    .pending_system_clear_o(pending_system_clear_w),
    .pending_branch_capture_direct_o(pending_branch_capture_direct_w),
    .pending_branch_capture_head0_o(pending_branch_capture_head0_w),
    .pending_branch_capture_lane1_o(pending_branch_capture_lane1_w),
    .pending_branch_clear_o(pending_branch_clear_w),
    .pending_jump_capture_head0_o(pending_jump_capture_head0_w),
    .pending_jump_capture_lane1_o(pending_jump_capture_lane1_w),
    .pending_jump_clear_o(pending_jump_clear_w),
    .pending_fp_capture_head0_o(pending_fp_capture_head0_w),
    .pending_fp_capture_lane1_o(pending_fp_capture_lane1_w),
    .pending_fp_clear_o(pending_fp_clear_w),
    .pending_mem_capture_lane1_o(pending_mem_capture_lane1_w),
    .pending_mem_clear_o(pending_mem_clear_w),
    .pending_trap_exit_clear_exit_o(pending_trap_exit_clear_exit_w),
    .pending_trap_exit_clear_arch_o(pending_trap_exit_clear_arch_w),
    .pending_trap_exit_capture_exit_o(pending_trap_exit_capture_exit_w),
    .pending_trap_exit_capture_exit_valid_o(
        pending_trap_exit_capture_exit_valid_w),
    .pending_trap_exit_capture_exit_ecall_o(
        pending_trap_exit_capture_exit_ecall_w),
    .pending_trap_exit_capture_exit_ebreak_o(
        pending_trap_exit_capture_exit_ebreak_w),
    .pending_trap_exit_capture_arch_o(pending_trap_exit_capture_arch_w),
    .pending_trap_exit_capture_arch_valid_o(
        pending_trap_exit_capture_arch_valid_w),
    .pending_trap_exit_capture_cause_o(pending_trap_exit_capture_cause_w),
    .pending_trap_exit_capture_pc_o(pending_trap_exit_capture_pc_w),
    .pending_trap_exit_capture_tval_o(pending_trap_exit_capture_tval_w)
  );

  wire trap_exit_output_trap_w;
  wire [`TRAP_CAUSE_W-1:0] trap_exit_output_cause_w;
  wire [`XLEN-1:0] trap_exit_output_pc_w;
  wire [`XLEN-1:0] trap_exit_output_tval_w;
  wire trap_exit_output_exit_w;
  wire trap_exit_output_exit_is_ecall_w;
  wire trap_exit_output_exit_is_ebreak_w;

  assign branch_prefetch_clear_w =
      csr_trap_mem_valid_w ||
      direct_frontend_flush_w ||
      (!direct_frontend_flush_w && branch_spec_resolve_valid_w) ||
      pending_branch_commit_resolve_w ||
      pending_branch_match_clear_w ||
      (!direct_frontend_flush_w && branch_resolve_untracked_w) ||
      (!direct_frontend_flush_w && pending_jump_resolve_ready_w &&
       (pending_jump_misaligned_w || pending_jump_nolink_commit_w ||
        pending_jump_redirect_after_dispatch_w)) ||
      (!direct_frontend_flush_w && pending_system_csr_commit_w) ||
      (!csr_trap_mem_valid_w && !direct_frontend_flush_w && stop_pending_q &&
       drain_complete_w &&
       (pending_arch_trap_q || pending_system_q || pending_jump_q ||
        pending_fp_q));

  OooBranchPrefetchBuffer u_branch_prefetch_buffer (
    .clk(clk),
    .rst(rst || flush_i),
    .clear_i(branch_prefetch_clear_w),
    .req_fire_i(branch_prefetch_req_fire_w),
    .req_pc_i(branch_prefetch_req_pc_w),
    .rsp_capture_i(branch_prefetch_rsp_capture_w),
    .rsp_pc0_i(fetch_dec0_pc_w),
    .rsp_pc1_i(fetch_dec1_pc_w),
    .rsp_next_pc0_i(fetch_dec0_next_pc_w),
    .rsp_next_pc1_i(fetch_dec1_next_pc_w),
    .rsp_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .rsp_inst0_i(fetch_dec0_inst_w),
    .rsp_inst1_i(fetch_dec1_inst_w),
    .rsp_resp0_i(fetch_dec0_resp_w),
    .rsp_resp1_i(fetch_dec1_resp_w),
    .active_o(branch_prefetch_active_q),
    .buffer_valid_o(branch_prefetch_buffer_valid_q),
    .pc_o(branch_prefetch_pc_q),
    .buf_pc0_o(branch_prefetch_buf_pc0_q),
    .buf_pc1_o(branch_prefetch_buf_pc1_q),
    .buf_next_pc0_o(branch_prefetch_buf_next_pc0_q),
    .buf_next_pc1_o(branch_prefetch_buf_next_pc1_q),
    .buf_packet_next_pc_o(branch_prefetch_buf_packet_next_pc_q),
    .buf_inst0_o(branch_prefetch_buf_inst0_q),
    .buf_inst1_o(branch_prefetch_buf_inst1_q),
    .buf_resp0_o(branch_prefetch_buf_resp0_q),
    .buf_resp1_o(branch_prefetch_buf_resp1_q)
  );

  OooFetchPacketSeedMux u_fetch_packet_seed_mux (
    .csr_trap_i(csr_trap_mem_valid_w),
    .direct_flush_i(direct_frontend_flush_w),
    .fallthrough_capture_i(branch_fallthrough_capture_rsp_w),
    .branch_spec_restore_i(branch_spec_resolve_valid_w &&
                           branch_spec_restore_w),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
    .pending_branch_match_i(pending_branch_match_clear_w),
    .pending_branch_misaligned_i(core_branch_resolve_misaligned_w),
    .branch_prefetch_hit_i(branch_prefetch_hit_to_fifo_w),
    .branch_resolve_untracked_i(branch_resolve_untracked_w),
    .pending_jump_resolve_i(pending_jump_resolve_ready_w),
    .pending_jump_misaligned_i(pending_jump_misaligned_w),
    .pending_jump_redirect_i(pending_jump_nolink_commit_w ||
                             pending_jump_redirect_after_dispatch_w),
    .pending_mem_resolve_i(pending_mem_resolve_ready_w),
    .system_csr_dispatch_i(system_csr_dispatch_fire_w),
    .pending_system_csr_commit_i(pending_system_csr_commit_w),
    .drain_complete_i(stop_pending_q && drain_complete_w),
    .drain_pending_arch_trap_i(pending_arch_trap_q),
    .drain_pending_system_i(pending_system_q),
    .drain_pending_branch_undispatched_i(pending_branch_q &&
                                         !pending_branch_dispatched_q),
    .drain_pending_jump_i(pending_jump_q),
    .drain_pending_mem_i(pending_mem_q),
    .drain_pending_fp_i(pending_fp_q),
    .jalr_prefetch_hit_i(jalr_prefetch_hit_available_w),
    .fallthrough_pc0_i(fetch_dec0_pc_w),
    .fallthrough_pc1_i(fetch_dec1_pc_w),
    .fallthrough_next_pc0_i(fetch_dec0_next_pc_w),
    .fallthrough_next_pc1_i(fetch_dec1_next_pc_w),
    .fallthrough_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .fallthrough_inst0_i(fetch_dec0_inst_w),
    .fallthrough_inst1_i(fetch_dec1_inst_w),
    .fallthrough_resp0_i(fetch_dec0_resp_w),
    .fallthrough_resp1_i(fetch_dec1_resp_w),
    .branch_pc0_i(branch_prefetch_hit_pc0_w),
    .branch_pc1_i(branch_prefetch_hit_pc1_w),
    .branch_next_pc0_i(branch_prefetch_hit_next_pc0_w),
    .branch_next_pc1_i(branch_prefetch_hit_next_pc1_w),
    .branch_packet_next_pc_i(branch_prefetch_hit_packet_next_pc_w),
    .branch_inst0_i(branch_prefetch_hit_inst0_w),
    .branch_inst1_i(branch_prefetch_hit_inst1_w),
    .branch_resp0_i(branch_prefetch_hit_resp0_w),
    .branch_resp1_i(branch_prefetch_hit_resp1_w),
    .jalr_pc0_i(jalr_prefetch_hit_pc0_w),
    .jalr_pc1_i(jalr_prefetch_hit_pc1_w),
    .jalr_next_pc0_i(jalr_prefetch_hit_next_pc0_w),
    .jalr_next_pc1_i(jalr_prefetch_hit_next_pc1_w),
    .jalr_packet_next_pc_i(jalr_prefetch_hit_packet_next_pc_w),
    .jalr_inst0_i(jalr_prefetch_hit_inst0_w),
    .jalr_inst1_i(jalr_prefetch_hit_inst1_w),
    .jalr_resp0_i(jalr_prefetch_hit_resp0_w),
    .jalr_resp1_i(jalr_prefetch_hit_resp1_w),
    .clear_o(fifo_clear_w),
    .seed_valid_o(fifo_seed_valid_w),
    .seed_pc0_o(fifo_seed_pc0_w),
    .seed_pc1_o(fifo_seed_pc1_w),
    .seed_next_pc0_o(fifo_seed_next_pc0_w),
    .seed_next_pc1_o(fifo_seed_next_pc1_w),
    .seed_packet_next_pc_o(fifo_seed_packet_next_pc_w),
    .seed_inst0_o(fifo_seed_inst0_w),
    .seed_inst1_o(fifo_seed_inst1_w),
    .seed_resp0_o(fifo_seed_resp0_w),
    .seed_resp1_o(fifo_seed_resp1_w)
  );

  OooFetchPacketFifo #(
    .FETCH_PACKET_COUNT_W(FETCH_PACKET_COUNT_W),
    .FETCH_COUNT_W(FETCH_COUNT_W)
  ) u_fetch_packet_fifo (
    .clk(clk),
    .rst(rst || flush_i),
    .clear_i(fifo_clear_w),
    .seed_valid_i(fifo_seed_valid_w),
    .seed_pc0_i(fifo_seed_pc0_w),
    .seed_pc1_i(fifo_seed_pc1_w),
    .seed_next_pc0_i(fifo_seed_next_pc0_w),
    .seed_next_pc1_i(fifo_seed_next_pc1_w),
    .seed_packet_next_pc_i(fifo_seed_packet_next_pc_w),
    .seed_inst0_i(fifo_seed_inst0_w),
    .seed_inst1_i(fifo_seed_inst1_w),
    .seed_resp0_i(fifo_seed_resp0_w),
    .seed_resp1_i(fifo_seed_resp1_w),
    .enqueue_i(fetch_rsp_enqueue_w),
    .enqueue_pc0_i(fetch_dec0_pc_w),
    .enqueue_pc1_i(fetch_dec1_pc_w),
    .enqueue_next_pc0_i(fetch_dec0_next_pc_w),
    .enqueue_next_pc1_i(fetch_dec1_next_pc_w),
    .enqueue_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
    .enqueue_inst0_i(fetch_dec0_inst_w),
    .enqueue_inst1_i(fetch_dec1_inst_w),
    .enqueue_resp0_i(fetch_dec0_resp_w),
    .enqueue_resp1_i(fetch_dec1_resp_w),
    .pop_i(fifo_storage_pop_w),
    .head_valid_o(fifo_storage_head_valid_w),
    .head_pc0_o(fifo_head_pc0_w),
    .head_pc1_o(fifo_head_pc1_w),
    .head_next_pc0_o(fifo_head_next_pc0_w),
    .head_next_pc1_o(fifo_head_next_pc1_w),
    .head_packet_next_pc_o(fifo_head_packet_next_pc_w),
    .head_inst0_o(fifo_head_inst0_w),
    .head_inst1_o(fifo_head_inst1_w),
    .head_resp0_o(fifo_head_resp0_w),
    .head_resp1_o(fifo_head_resp1_w),
    .count_o(fifo_count_q)
  );

  wire branch_bpu_pending0_capture_w;
  wire branch_bpu_pending1_capture_w;
  wire branch_bpu_lookup_event_w;
  wire branch_bpu_lookup_bht_valid_w;
  wire branch_bpu_direct_update_w;
  wire branch_bpu_pending_update_w;
  wire branch_bpu_drained_update_w;
  wire branch_bpu_commit_update_w;
  wire branch_bpu_update_valid_w;
  wire branch_bpu_pending_like_update_w;
  wire branch_bpu_update_taken_w;
  wire branch_bpu_update_pred_taken_w;
  wire branch_bpu_update_correct_w;
  wire [`XLEN-1:0] branch_bpu_update_pc_w;
  wire [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx_w;

  OooBranchBpuUpdateGate u_branch_bpu_update_gate (
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .can_run_i(can_run_w),
    .fifo_has_packet_i(fifo_has_packet_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .head1_branch_raw_i(head1_branch_raw_w),
    .direct_branch_fire_i(direct_branch_fire_w),
    .direct_branch_bht_valid_i(direct_branch_bht_valid_w),
    .head0_branch_bht_valid_i(head0_branch_bht_valid_w),
    .head1_branch_bht_valid_i(head1_branch_bht_valid_w),
    .direct_branch_resolve_valid_i(direct_branch_resolve_valid_w),
    .stop_pending_i(stop_pending_q),
    .pending_branch_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .branch_resolve_pending_match_i(branch_resolve_pending_match_w),
    .drain_complete_i(drain_complete_w),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned_w),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .pending_branch_target_i(pending_branch_target_w),
    .pending_branch_taken_i(pending_branch_taken_w),
    .direct_branch_resolve_taken_i(direct_branch_resolve_taken_w),
    .pending_branch_pred_taken_i(pending_branch_pred_taken_q),
    .direct_branch_predict_taken_i(direct_branch_predict_taken_w),
    .pending_branch_pc_i(pending_branch_pc_q),
    .direct_branch_pc_i(direct_branch_pc_w),
    .pending_branch_bht_idx_i(pending_branch_bht_idx_q),
    .direct_branch_bht_idx_i(direct_branch_bht_idx_w),
    .branch_bpu_pending0_capture_o(branch_bpu_pending0_capture_w),
    .branch_bpu_pending1_capture_o(branch_bpu_pending1_capture_w),
    .branch_bpu_lookup_event_o(branch_bpu_lookup_event_w),
    .branch_bpu_lookup_bht_valid_o(branch_bpu_lookup_bht_valid_w),
    .branch_bpu_direct_update_o(branch_bpu_direct_update_w),
    .branch_bpu_pending_update_o(branch_bpu_pending_update_w),
    .branch_bpu_drained_update_o(branch_bpu_drained_update_w),
    .branch_bpu_commit_update_o(branch_bpu_commit_update_w),
    .branch_bpu_update_valid_o(branch_bpu_update_valid_w),
    .branch_bpu_pending_like_update_o(branch_bpu_pending_like_update_w),
    .branch_bpu_update_taken_o(branch_bpu_update_taken_w),
    .branch_bpu_update_pred_taken_o(branch_bpu_update_pred_taken_w),
    .branch_bpu_update_correct_o(branch_bpu_update_correct_w),
    .branch_bpu_update_pc_o(branch_bpu_update_pc_w),
    .branch_bpu_update_bht_idx_o(branch_bpu_update_bht_idx_w)
  );

  OooBranchDirectionPredictor u_branch_direction_predictor (
    .clk(clk),
    .rst(rst),
    .clear_i(flush_i),
    .lookup0_pc_i(head_pc_w),
    .lookup0_imm_i(head0_imm_w),
    .lookup0_bht_idx_o(head0_branch_bht_idx_w),
    .lookup0_bht_valid_o(head0_branch_bht_valid_w),
    .lookup0_pred_taken_o(head0_branch_pred_taken_w),
    .lookup0_predict_strong_o(head0_branch_predict_strong_w),
    .lookup1_pc_i(head_pc1_w),
    .lookup1_imm_i(head1_imm_w),
    .lookup1_bht_idx_o(head1_branch_bht_idx_w),
    .lookup1_bht_valid_o(head1_branch_bht_valid_w),
    .lookup1_pred_taken_o(head1_branch_pred_taken_w),
    .lookup1_predict_strong_o(head1_branch_predict_strong_w),
    .update_valid_i(branch_bpu_update_valid_w),
    .update_pc_i(branch_bpu_update_pc_w),
    .update_bht_idx_i(branch_bpu_update_bht_idx_w),
    .update_taken_i(branch_bpu_update_taken_w)
  );

  wire core_checkpoint_capture_w = branch_spec_checkpoint_capture_w;
  wire core_checkpoint_restore_w = branch_spec_restore_w;
  wire core_checkpoint_quiesce_w =
      branch_spec_checkpoint_pending_q && !core_checkpoint_capture_w;
  wire core_mem_issue_block_w = branch_spec_active_q;
  OooControlFlushSequencer u_control_flush_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .trap_flush_req_i(csr_trap_mem_valid_w),
    .priv_predictor_boundary_i(priv_predictor_boundary_w),
    .backend_drained_i(backend_drained_w),
    .checkpoint_restore_i(core_checkpoint_restore_w),
    .core_trap_flush_o(core_trap_flush_q),
    .trap_redirect_squash_o(trap_redirect_squash_q),
    .checkpoint_mem_flush_o(checkpoint_mem_flush_q)
  );

  wire pending_fp_gpr_commit_w =
      !direct_frontend_flush_w && stop_pending_q && drain_complete_w &&
      pending_fp_q && pending_fp_gpr_write_q;
  wire core_local_flush_w = flush_i || core_trap_flush_q || core_serial_flush_q;
  wire core_commit_ready_w =
      commit_ready_i && !core_trap_flush_q && !core_serial_flush_q &&
      !branch_spec_checkpoint_pending_q &&
      !branch_spec_active_q && !core_checkpoint_restore_w;
  wire core_commit1_block_w =
      !ctrl_commit_valid_q && synth_lane1_ret_pending_q &&
      !synth_lane1_branch_drop_match_w &&
      (synth_lane1_ret_branch_seen_q ||
       synth_lane1_ret_branch_commit0_w);
  wire core_dispatch0_valid_w;
  wire core_dispatch1_valid_w;
  wire core_dispatch0_fire_w;
  wire jump_dispatch_fire_w;
  wire mem_dispatch_fire_w;
  wire [`XLEN-1:0] core_dispatch0_pc_w;
  wire [`XLEN-1:0] core_dispatch0_next_pc_w;
  wire [`INST_W-1:0] core_dispatch0_inst_w;
  wire [`XLEN-1:0] core_dispatch0_csr_rdata_w;
  wire [`XLEN-1:0] core_dispatch1_pc_w;
  wire [`XLEN-1:0] core_dispatch1_next_pc_w;
  wire [`INST_W-1:0] core_dispatch1_inst_w;

  OooFrontendBackendDispatchMux u_frontend_backend_dispatch_mux (
    .branch_prefetch_dispatch_attempt_i(branch_prefetch_dispatch_attempt_w),
    .branch_prefetch_dispatch_buffer_i(branch_prefetch_dispatch_buffer_w),
    .branch_prefetch_dispatch_rsp_i(branch_prefetch_dispatch_rsp_w),
    .system_csr_dispatch_valid_i(system_csr_dispatch_valid_w),
    .frontend_dispatch_to_backend_valid_i(
        frontend_dispatch_to_backend_valid_w),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid_w),
    .direct_jal0_dispatch_valid_i(direct_jal0_dispatch_valid_w),
    .direct_ret0_dispatch_valid_i(direct_ret0_dispatch_valid_w),
    .lane1_barrier_dispatch0_valid_i(lane1_barrier_dispatch0_valid_w),
    .jump_dispatch_valid_i(jump_dispatch_valid_w),
    .mem_dispatch_valid_i(mem_dispatch_valid_w),
    .return_cont_attempt_i(return_cont_attempt_w),
    .branch_target_append_attempt_i(branch_target_append_attempt_w),
    .branch_fallthrough_append_attempt_i(branch_fallthrough_append_attempt_w),
    .direct_jal1_fire_i(direct_jal1_fire_w),
    .direct_ret1_fire_i(direct_ret1_fire_w),
    .dispatch0_ready_i(dispatch0_ready_w),
    .branch_prefetch_buf_pc0_i(branch_prefetch_buf_pc0_q),
    .branch_prefetch_buf_next_pc0_i(branch_prefetch_buf_next_pc0_q),
    .branch_prefetch_buf_inst0_i(branch_prefetch_buf_inst0_q),
    .branch_prefetch_buf_pc1_i(branch_prefetch_buf_pc1_q),
    .branch_prefetch_buf_next_pc1_i(branch_prefetch_buf_next_pc1_q),
    .branch_prefetch_buf_inst1_i(branch_prefetch_buf_inst1_q),
    .fetch_dec0_pc_i(fetch_dec0_pc_w),
    .fetch_dec0_next_pc_i(fetch_dec0_next_pc_w),
    .fetch_dec0_inst_i(fetch_dec0_inst_w),
    .fetch_dec1_pc_i(fetch_dec1_pc_w),
    .fetch_dec1_next_pc_i(fetch_dec1_next_pc_w),
    .fetch_dec1_inst_i(fetch_dec1_inst_w),
    .pending_system_pc_i(pending_system_pc_q),
    .pending_system_next_pc_i(pending_system_next_pc_q),
    .pending_system_inst_i(pending_system_inst_q),
    .pending_system_csr_rdata_i(pending_system_csr_rdata_q),
    .pending_jump_pc_i(pending_jump_pc_q),
    .pending_jump_next_pc_i(pending_jump_next_pc_q),
    .pending_jump_inst_i(pending_jump_inst_q),
    .pending_mem_pc_i(pending_mem_pc_q),
    .pending_mem_next_pc_i(pending_mem_next_pc_q),
    .pending_mem_inst_i(pending_mem_inst_q),
    .head_pc0_i(head_pc_w),
    .head_next_pc0_i(head_next_pc0_w),
    .head_inst0_i(head_inst0_w),
    .head_pc1_i(head_pc1_w),
    .head_next_pc1_i(head_next_pc1_w),
    .head_inst1_i(head_inst1_w),
    .return_cont_pc_i(return_cont_pc_q),
    .return_cont_next_pc_i(return_cont_next_pc_q),
    .return_cont_inst_i(return_cont_inst_q),
    .branch_target_cache_target_pc_i(branch_target_cache_target_pc_w),
    .branch_target_cache_next_pc_i(branch_target_cache_next_pc_w),
    .branch_target_cache_inst_i(branch_target_cache_inst_w),
    .direct_ret_target_i(direct_ret_target_w),
    .core_dispatch0_valid_o(core_dispatch0_valid_w),
    .core_dispatch1_valid_o(core_dispatch1_valid_w),
    .core_dispatch0_fire_o(core_dispatch0_fire_w),
    .jump_dispatch_fire_o(jump_dispatch_fire_w),
    .mem_dispatch_fire_o(mem_dispatch_fire_w),
    .core_dispatch0_pc_o(core_dispatch0_pc_w),
    .core_dispatch0_next_pc_o(core_dispatch0_next_pc_w),
    .core_dispatch0_inst_o(core_dispatch0_inst_w),
    .core_dispatch0_csr_rdata_o(core_dispatch0_csr_rdata_w),
    .core_dispatch1_pc_o(core_dispatch1_pc_w),
    .core_dispatch1_next_pc_o(core_dispatch1_next_pc_w),
    .core_dispatch1_inst_o(core_dispatch1_inst_w)
  );

  OooBackendDrainTracker u_backend_drain_tracker (
    .clk(clk),
    .rst(rst || flush_i),
    .backend_empty_i(backend_drained_w),
    .dispatch_fire_i(core_dispatch0_fire_w),
    .force_drained_i(csr_trap_mem_valid_w),
    .drained_o(backend_drained_q)
  );

  assign fetch_req_pc_o = fetch_req_pc_w;

  function [`XLEN-1:0] arch_gpr;
    input [`XLEN * `REG_NUM - 1:0] gprs;
    input [`REG_ADDR_W-1:0] idx;
    begin
      arch_gpr = gprs[idx * `XLEN +: `XLEN];
    end
  endfunction

  wire [`REG_ADDR_W-1:0] pending_fp_rs1_idx_w = pending_fp_inst_q[19:15];
  wire [`REG_ADDR_W-1:0] pending_fp_rs2_idx_w = pending_fp_inst_q[24:20];
  wire [`REG_ADDR_W-1:0] pending_fp_rs3_idx_w = pending_fp_inst_q[31:27];
  wire [`XLEN-1:0] pending_fp_int_rs1_value_w =
      arch_gpr(core_debug_gprs_w, pending_fp_rs1_idx_w);
  wire [`XLEN-1:0] pending_fp_frs1_value_w;
  wire [`XLEN-1:0] pending_fp_frs2_value_w;
  wire [`XLEN-1:0] pending_fp_frs3_value_w;
  wire pending_fp_div_busy_w;
  wire pending_fp_sqrt_busy_w;
  wire pending_fp_long_done_w;
  wire [`XLEN-1:0] pending_fp_long_done_result_w;
  wire [4:0] pending_fp_long_done_fflags_w;
  wire [`XLEN-1:0] pending_fp_mem_addr_w;
  wire [`XLEN-1:0] pending_fp_mem_aligned_addr_w;
  wire [`XLEN-1:0] pending_fp_mem_wdata_w;
  wire [`STRB_W-1:0] pending_fp_mem_wstrb_w;
  wire [`XLEN-1:0] pending_fp_compute_value_w;
  wire [4:0] pending_fp_compute_fflags_w;

  OooFpPendingExec u_fp_pending_exec (
    .clk(clk),
    .rst(rst),
    .flush_i(core_local_flush_w),
    .pending_valid_i(pending_fp_q),
    .inst_i(pending_fp_inst_q),
    .load_i(pending_fp_load_q),
    .store_i(pending_fp_store_q),
    .double_i(pending_fp_double_q),
    .gpr_write_i(pending_fp_gpr_write_q),
    .int_rs1_value_i(pending_fp_int_rs1_value_w),
    .frs1_value_i(pending_fp_frs1_value_w),
    .frs2_value_i(pending_fp_frs2_value_w),
    .frs3_value_i(pending_fp_frs3_value_w),
    .long_start_i(pending_fp_long_start_w),
    .long_op_o(pending_fp_long_op_w),
    .compute_op_o(pending_fp_compute_op_w),
    .div_busy_o(pending_fp_div_busy_w),
    .sqrt_busy_o(pending_fp_sqrt_busy_w),
    .long_done_o(pending_fp_long_done_w),
    .long_done_result_o(pending_fp_long_done_result_w),
    .long_done_fflags_o(pending_fp_long_done_fflags_w),
    .mem_addr_o(pending_fp_mem_addr_w),
    .mem_aligned_addr_o(pending_fp_mem_aligned_addr_w),
    .mem_wdata_o(pending_fp_mem_wdata_w),
    .mem_wstrb_o(pending_fp_mem_wstrb_w),
    .compute_value_o(pending_fp_compute_value_w),
    .compute_fflags_o(pending_fp_compute_fflags_w)
  );

  // FP pending owner 移入 execute helper；父模块仍负责 FPR、fflags 和精确提交边界。
  OooPendingFpSequencer u_pending_fp_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .late_clear_i(csr_trap_mem_valid_w),
    .clear_i(pending_fp_clear_w),
    .capture_head0_i(pending_fp_capture_head0_w),
    .capture_head0_load_i(head0_fp_load_raw_w),
    .capture_head0_store_i(head0_fp_store_raw_w),
    .capture_head0_double_i(head0_fp_double_w),
    .capture_head0_gpr_write_i(head0_fp_gpr_write_w),
    .capture_head0_pc_i(head_pc_w),
    .capture_head0_inst_i(head_inst0_w),
    .capture_head0_next_pc_i(head_next_pc0_w),
    .capture_head0_rd_i(head_inst0_w[11:7]),
    .capture_lane1_i(pending_fp_capture_lane1_w),
    .capture_lane1_valid_i(head1_fp_enabled_w),
    .capture_lane1_load_i(head1_fp_load_raw_w),
    .capture_lane1_store_i(head1_fp_store_raw_w),
    .capture_lane1_double_i(head1_fp_double_w),
    .capture_lane1_gpr_write_i(head1_fp_gpr_write_w),
    .capture_lane1_pc_i(head_pc1_w),
    .capture_lane1_inst_i(head_inst1_w),
    .capture_lane1_next_pc_i(head_next_pc1_w),
    .capture_lane1_rd_i(head_inst1_w[11:7]),
    .mem_req_fire_i(pending_fp_mem_req_fire_w),
    .mem_req_addr_i(pending_fp_mem_addr_w),
    .mem_req_wdata_i(pending_fp_mem_wdata_w),
    .mem_req_wstrb_i(pending_fp_mem_wstrb_w),
    .mem_rsp_fire_i(pending_fp_mem_rsp_fire_w),
    .long_start_i(pending_fp_long_start_w),
    .long_done_i(pending_fp_long_done_w),
    .long_done_result_i(pending_fp_long_done_result_w),
    .long_done_fflags_i(pending_fp_long_done_fflags_w),
    .compute_start_i(pending_fp_compute_start_w),
    .compute_result_i(pending_fp_compute_value_w),
    .compute_fflags_i(pending_fp_compute_fflags_w),
    .valid_o(pending_fp_q),
    .mem_pending_o(pending_fp_mem_pending_q),
    .mem_done_o(pending_fp_mem_done_q),
    .long_pending_o(pending_fp_long_pending_q),
    .long_done_o(pending_fp_long_done_q),
    .long_result_o(pending_fp_long_result_q),
    .long_fflags_o(pending_fp_long_fflags_q),
    .compute_done_o(pending_fp_compute_done_q),
    .compute_result_o(pending_fp_compute_result_q),
    .compute_fflags_o(pending_fp_compute_fflags_q),
    .load_o(pending_fp_load_q),
    .store_o(pending_fp_store_q),
    .double_o(pending_fp_double_q),
    .gpr_write_o(pending_fp_gpr_write_q),
    .pc_o(pending_fp_pc_q),
    .inst_o(pending_fp_inst_q),
    .next_pc_o(pending_fp_next_pc_q),
    .addr_o(pending_fp_addr_q),
    .wdata_o(pending_fp_wdata_q),
    .wstrb_o(pending_fp_wstrb_q),
    .rd_o(pending_fp_rd_q)
  );

  wire [`XLEN-1:0] pending_fp_result_value_w =
      pending_fp_long_op_w ? pending_fp_long_result_q :
                             pending_fp_compute_result_q;

  // Branch pending owner 移入 frontend helper；父模块仍负责 compare/BPU/recovery。
  OooPendingBranchSequencer u_pending_branch_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .late_clear_i(csr_trap_mem_valid_w),
    .clear_i(pending_branch_clear_w),
    .clear_dispatched_i(orphan_stop_pending_w),
    .capture_direct_i(pending_branch_capture_direct_w),
    .capture_direct_valid_i(!direct_branch_resolve_redirect_w),
    .capture_direct_pc_i(direct_branch1_fire_w ? head_pc1_w : head_pc_w),
    .capture_direct_next_pc_i(direct_branch1_fire_w ? head_next_pc1_w :
                              head_next_pc0_w),
    .capture_direct_inst_i(direct_branch1_fire_w ? head_inst1_w :
                           head_inst0_w),
    .capture_direct_rs1_i(direct_branch1_fire_w ? head1_rs1_w : head0_rs1_w),
    .capture_direct_rs2_i(direct_branch1_fire_w ? head1_rs2_w : head0_rs2_w),
    .capture_direct_imm_i(direct_branch1_fire_w ? head1_imm_w : head0_imm_w),
    .capture_direct_cmp_op_i(direct_branch1_fire_w ?
                             head1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] :
                             head0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .capture_direct_pred_taken_i(direct_branch_predict_taken_w),
    .capture_direct_bht_valid_i(direct_branch_bht_valid_w),
    .capture_direct_bht_idx_i(direct_branch_bht_idx_w),
    .capture_head0_i(pending_branch_capture_head0_w),
    .capture_head0_pc_i(head_pc_w),
    .capture_head0_next_pc_i(head_next_pc0_w),
    .capture_head0_inst_i(head_inst0_w),
    .capture_head0_rs1_i(head0_rs1_w),
    .capture_head0_rs2_i(head0_rs2_w),
    .capture_head0_imm_i(head0_imm_w),
    .capture_head0_cmp_op_i(head0_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .capture_head0_pred_taken_i(head0_branch_pred_taken_w),
    .capture_head0_bht_valid_i(head0_branch_bht_valid_w),
    .capture_head0_bht_idx_i(head0_branch_bht_idx_w),
    .capture_lane1_i(pending_branch_capture_lane1_w),
    .capture_lane1_valid_i(head1_branch_raw_w),
    .capture_lane1_pc_i(head_pc1_w),
    .capture_lane1_next_pc_i(head_next_pc1_w),
    .capture_lane1_inst_i(head_inst1_w),
    .capture_lane1_rs1_i(head1_rs1_w),
    .capture_lane1_rs2_i(head1_rs2_w),
    .capture_lane1_imm_i(head1_imm_w),
    .capture_lane1_cmp_op_i(head1_ctrl_w[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB]),
    .capture_lane1_pred_taken_i(head1_branch_pred_taken_w),
    .capture_lane1_bht_valid_i(head1_branch_bht_valid_w),
    .capture_lane1_bht_idx_i(head1_branch_bht_idx_w),
    .valid_o(pending_branch_q),
    .dispatched_o(pending_branch_dispatched_q),
    .pc_o(pending_branch_pc_q),
    .next_pc_o(pending_branch_next_pc_q),
    .inst_o(pending_branch_inst_q),
    .rs1_o(pending_branch_rs1_q),
    .rs2_o(pending_branch_rs2_q),
    .imm_o(pending_branch_imm_q),
    .cmp_op_o(pending_branch_cmp_op_q),
    .pred_taken_o(pending_branch_pred_taken_q),
    .bht_valid_o(pending_branch_bht_valid_q),
    .bht_idx_o(pending_branch_bht_idx_q)
  );

  // JAL/JALR pending owner 移入 frontend helper；父模块仍负责 target/RAS/BTB/trap/redirect。
  OooPendingJumpSequencer u_pending_jump_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .late_clear_i(csr_trap_mem_valid_w),
    .clear_i(pending_jump_clear_w),
    .clear_dispatched_i(orphan_stop_pending_w),
    .dispatch_fire_i(jump_dispatch_fire_w),
    .dispatch_target_i(pending_jump_resolved_target_w),
    .capture_head0_i(pending_jump_capture_head0_w),
    .capture_head0_jalr_i(head0_jalr_raw_w),
    .capture_head0_pc_i(head_pc_w),
    .capture_head0_next_pc_i(head_next_pc0_w),
    .capture_head0_inst_i(head_inst0_w),
    .capture_head0_rs1_i(head0_rs1_w),
    .capture_head0_imm_i(head0_imm_w),
    .capture_lane1_i(pending_jump_capture_lane1_w),
    .capture_lane1_valid_i(head1_jump_raw_w),
    .capture_lane1_jalr_i(head1_jalr_raw_w),
    .capture_lane1_pc_i(head_pc1_w),
    .capture_lane1_next_pc_i(head_next_pc1_w),
    .capture_lane1_inst_i(head_inst1_w),
    .capture_lane1_rs1_i(head1_rs1_w),
    .capture_lane1_imm_i(head1_imm_w),
    .valid_o(pending_jump_q),
    .dispatched_o(pending_jump_dispatched_q),
    .jalr_o(pending_jump_jalr_q),
    .pc_o(pending_jump_pc_q),
    .next_pc_o(pending_jump_next_pc_q),
    .inst_o(pending_jump_inst_q),
    .rs1_o(pending_jump_rs1_q),
    .imm_o(pending_jump_imm_q),
    .target_o(pending_jump_target_q)
  );

  // lane1 memory barrier pending owner 移入 memory helper，父模块仍负责全局仲裁。
  OooPendingMemorySequencer u_pending_memory_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .late_clear_i(csr_trap_mem_valid_w),
    .clear_i(pending_mem_clear_w),
    .clear_dispatched_i(orphan_stop_pending_w),
    .dispatch_fire_i(mem_dispatch_fire_w),
    .capture_lane1_i(pending_mem_capture_lane1_w),
    .capture_valid_i(head1_mem_raw_w),
    .capture_pc_i(head_pc1_w),
    .capture_inst_i(head_inst1_w),
    .capture_next_pc_i(head_next_pc1_w),
    .valid_o(pending_mem_q),
    .dispatched_o(pending_mem_dispatched_q),
    .pc_o(pending_mem_pc_q),
    .inst_o(pending_mem_inst_q),
    .next_pc_o(pending_mem_next_pc_q)
  );

  // SYSTEM/CSR/IRQ pending owner 移入 control helper，父模块只生成事件和消费状态。
  OooPendingSystemSequencer u_pending_system_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .clear_i(pending_system_clear_w),
    .clear_dispatched_i(orphan_stop_pending_w),
    .dispatch_fire_i(system_csr_dispatch_fire_w),
    .capture_irq_i(pending_system_capture_irq_w),
    .capture_irq_pc_i(head_pc_w),
    .capture_irq_cause_i(csr_irq_cause_w),
    .capture_head0_i(pending_system_capture_head0_w),
    .capture_head0_csr_i(head0_csr_raw_w),
    .capture_head0_ecall_i(head0_ecall_raw_w),
    .capture_head0_mret_i(head0_xret_raw_w),
    .capture_head0_wfi_i(head0_wfi_raw_w),
    .capture_head0_sfence_i(head0_sfence_raw_w),
    .capture_head0_pc_i(head_pc_w),
    .capture_head0_inst_i(head_inst0_w),
    .capture_head0_next_pc_i(head_next_pc0_w),
    .capture_head0_csr_rdata_i(csr_rdata_w),
    .capture_lane1_i(pending_system_capture_lane1_w),
    .capture_lane1_csr_i(head1_csr_raw_w && !head1_csr_illegal_w),
    .capture_lane1_ecall_i(head1_ecall_raw_w),
    .capture_lane1_mret_i(head1_xret_raw_w),
    .capture_lane1_wfi_i(head1_wfi_raw_w),
    .capture_lane1_sfence_i(head1_sfence_raw_w),
    .capture_lane1_pc_i(head_pc1_w),
    .capture_lane1_inst_i(head_inst1_w),
    .capture_lane1_next_pc_i(head_next_pc1_w),
    .capture_lane1_csr_rdata_i(csr_rdata_w),
    .valid_o(pending_system_q),
    .dispatched_o(pending_system_dispatched_q),
    .csr_o(pending_system_csr_q),
    .ecall_o(pending_system_ecall_q),
    .mret_o(pending_system_mret_q),
    .wfi_o(pending_system_wfi_q),
    .sfence_o(pending_system_sfence_q),
    .irq_o(pending_system_irq_q),
    .pc_o(pending_system_pc_q),
    .inst_o(pending_system_inst_q),
    .next_pc_o(pending_system_next_pc_q),
    .csr_rdata_o(pending_system_csr_rdata_q),
    .irq_cause_o(pending_system_irq_cause_q)
  );

  OooPendingTrapExitSequencer u_pending_trap_exit_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .late_clear_i(csr_trap_mem_valid_w),
    .clear_exit_i(pending_trap_exit_clear_exit_w),
    .clear_arch_i(pending_trap_exit_clear_arch_w),
    .capture_exit_i(pending_trap_exit_capture_exit_w),
    .capture_exit_valid_i(pending_trap_exit_capture_exit_valid_w),
    .capture_exit_is_ecall_i(pending_trap_exit_capture_exit_ecall_w),
    .capture_exit_is_ebreak_i(pending_trap_exit_capture_exit_ebreak_w),
    .capture_arch_i(pending_trap_exit_capture_arch_w),
    .capture_arch_valid_i(pending_trap_exit_capture_arch_valid_w),
    .capture_trap_cause_i(pending_trap_exit_capture_cause_w),
    .capture_trap_pc_i(pending_trap_exit_capture_pc_w),
    .capture_trap_tval_i(pending_trap_exit_capture_tval_w),
    .pending_exit_o(pending_exit_q),
    .pending_exit_is_ecall_o(pending_exit_is_ecall_q),
    .pending_exit_is_ebreak_o(pending_exit_is_ebreak_q),
    .pending_arch_trap_o(pending_arch_trap_q),
    .pending_trap_cause_o(pending_trap_cause_q),
    .pending_trap_pc_o(pending_trap_pc_q),
    .pending_trap_tval_o(pending_trap_tval_q)
  );

  OooTrapExitEventMux u_trap_exit_event_mux (
    .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .stop_pending_i(stop_pending_q),
    .drain_complete_i(drain_complete_w),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid_w),
    .branch_spec_restore_i(branch_spec_restore_w),
    .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned_w),
    .core_branch_resolve_pc_i(core_branch_resolve_pc_w),
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
    .pending_branch_match_clear_i(pending_branch_match_clear_w),
    .branch_resolve_untracked_i(branch_resolve_untracked_w),
    .pending_branch_misaligned_i(pending_branch_misaligned_w),
    .pending_branch_pc_i(pending_branch_pc_q),
    .pending_branch_target_i(pending_branch_target_w),
    .pending_branch_valid_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_w),
    .pending_jump_misaligned_i(pending_jump_misaligned_w),
    .pending_jump_pc_i(pending_jump_pc_q),
    .pending_jump_resolved_target_i(pending_jump_resolved_target_w),
    .pending_mem_resolve_ready_i(pending_mem_resolve_ready_w),
    .system_csr_dispatch_fire_i(system_csr_dispatch_fire_w),
    .pending_system_csr_commit_i(pending_system_csr_commit_w),
    .pending_arch_trap_i(pending_arch_trap_q),
    .pending_system_i(pending_system_q),
    .pending_jump_i(pending_jump_q),
    .pending_mem_i(pending_mem_q),
    .pending_fp_i(pending_fp_q),
    .pending_exit_i(pending_exit_q),
    .pending_exit_is_ecall_i(pending_exit_is_ecall_q),
    .pending_exit_is_ebreak_i(pending_exit_is_ebreak_q),
    .pending_trap_cause_i(pending_trap_cause_q),
    .pending_trap_pc_i(pending_trap_pc_q),
    .pending_trap_tval_i(pending_trap_tval_q),
    .trap_o(trap_exit_output_trap_w),
    .trap_cause_o(trap_exit_output_cause_w),
    .trap_pc_o(trap_exit_output_pc_w),
    .trap_tval_o(trap_exit_output_tval_w),
    .exit_o(trap_exit_output_exit_w),
    .exit_is_ecall_o(trap_exit_output_exit_is_ecall_w),
    .exit_is_ebreak_o(trap_exit_output_exit_is_ebreak_w)
  );

  OooTrapExitOutputSequencer u_trap_exit_output_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .trap_i(trap_exit_output_trap_w),
    .trap_cause_i(trap_exit_output_cause_w),
    .trap_pc_i(trap_exit_output_pc_w),
    .trap_tval_i(trap_exit_output_tval_w),
    .exit_i(trap_exit_output_exit_w),
    .exit_is_ecall_i(trap_exit_output_exit_is_ecall_w),
    .exit_is_ebreak_i(trap_exit_output_exit_is_ebreak_w),
    .trap_valid_o(trap_valid_q),
    .trap_cause_o(trap_cause_q),
    .trap_pc_o(trap_pc_q),
    .trap_tval_o(trap_tval_q),
    .exit_valid_o(exit_valid_q),
    .exit_is_ecall_o(exit_is_ecall_q),
    .exit_is_ebreak_o(exit_is_ebreak_q),
    .halted_o(halted_q)
  );

  // 控制类伪提交由 writeback 侧 sequencer 统一打拍，父模块只保留 pending/trap owner。
  OooControlCommitSequencer u_control_commit_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit_w),
    .pending_jump_pc_i(pending_jump_pc_q),
    .pending_jump_inst_i(pending_jump_inst_q),
    .pending_jump_target_i(pending_jump_resolved_target_w),
    .drain_complete_i(!csr_trap_mem_valid_w && !direct_frontend_flush_w &&
                      stop_pending_q && drain_complete_w),
    .drain_pending_arch_trap_i(pending_arch_trap_q),
    .drain_pending_system_i(pending_system_q),
    .drain_pending_system_ecall_i(pending_system_ecall_q),
    .drain_pending_system_irq_i(pending_system_irq_q),
    .drain_pending_system_mret_i(pending_system_mret_q),
    .pending_system_pc_i(pending_system_pc_q),
    .pending_system_inst_i(pending_system_inst_q),
    .pending_system_next_pc_i(pending_system_next_pc_q),
    .csr_ret_target_i(csr_ret_target_w),
    .drain_pending_branch_undispatched_i(pending_branch_q &&
                                         !pending_branch_dispatched_q),
    .drain_pending_branch_misaligned_i(pending_branch_misaligned_w),
    .pending_branch_pc_i(pending_branch_pc_q),
    .pending_branch_inst_i(pending_branch_inst_q),
    .pending_branch_next_pc_i(pending_branch_next_pc_w),
    .drain_pending_jump_i(pending_jump_q),
    .drain_pending_mem_i(pending_mem_q),
    .drain_pending_fp_i(pending_fp_q),
    .pending_fp_gpr_write_i(pending_fp_gpr_write_q),
    .pending_fp_pc_i(pending_fp_pc_q),
    .pending_fp_inst_i(pending_fp_inst_q),
    .pending_fp_next_pc_i(pending_fp_next_pc_q),
    .pending_fp_rd_i(pending_fp_rd_q),
    .pending_fp_result_value_i(pending_fp_result_value_w),
    .ctrl_commit_valid_o(ctrl_commit_valid_q),
    .ctrl_commit_pc_o(ctrl_commit_pc_q),
    .ctrl_commit_inst_o(ctrl_commit_inst_q),
    .ctrl_commit_next_pc_o(ctrl_commit_next_pc_q),
    .ctrl_commit_rd_en_o(ctrl_commit_rd_en_q),
    .ctrl_commit_rd_addr_o(ctrl_commit_rd_addr_q),
    .ctrl_commit_rd_data_o(ctrl_commit_rd_data_q),
    .ctrl_commit_write_o(ctrl_commit_write_q),
    .core_serial_flush_o(core_serial_flush_q)
  );

  wire [4:0] pending_fp_commit_fflags_w =
      pending_fp_long_op_w ? pending_fp_long_fflags_q :
                             pending_fp_compute_fflags_q;
  wire pending_fp_commit_fire_w =
      !csr_trap_mem_valid_w && !direct_frontend_flush_w &&
      stop_pending_q && drain_complete_w && pending_fp_q;
  wire pending_fp_fflags_commit_w =
      pending_fp_commit_fire_w && (pending_fp_commit_fflags_w != 5'b00000);
  wire [`XLEN-1:0] pending_fp_shifted_rdata_w =
      mem_rsp_rdata_i >> {pending_fp_addr_q[`XLEN_BYTE_W-1:0], 3'b000};
  wire [`XLEN-1:0] pending_fp_load_value_w =
      pending_fp_double_q ? pending_fp_shifted_rdata_w :
      {32'hffff_ffff, pending_fp_shifted_rdata_w[31:0]};

  wire pending_fp_fpr_commit_w =
      !csr_trap_mem_valid_w && !direct_frontend_flush_w &&
      stop_pending_q && drain_complete_w && !pending_arch_trap_q &&
      !pending_system_q && !(pending_branch_q && !pending_branch_dispatched_q) &&
      !pending_jump_q && !pending_mem_q && pending_fp_q &&
      !pending_fp_load_q && !pending_fp_store_q && !pending_fp_gpr_write_q;

  OooFpRegFile u_fp_reg_file (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .read0_addr_i(pending_fp_rs1_idx_w),
    .read0_data_o(pending_fp_frs1_value_w),
    .read1_addr_i(pending_fp_rs2_idx_w),
    .read1_data_o(pending_fp_frs2_value_w),
    .read2_addr_i(pending_fp_rs3_idx_w),
    .read2_data_o(pending_fp_frs3_value_w),
    .load_write_valid_i(pending_fp_mem_rsp_fire_w && pending_fp_load_q),
    .load_write_addr_i(pending_fp_rd_q),
    .load_write_data_i(pending_fp_load_value_w),
    .result_write_valid_i(pending_fp_fpr_commit_w),
    .result_write_addr_i(pending_fp_rd_q),
    .result_write_data_i(pending_fp_result_value_w)
  );

  wire pending_fp_mem_req_valid_w;
  wire pending_fp_mem_req_fire_w;
  wire pending_fp_mem_rsp_fire_w;

  OooMemoryRequestGate u_memory_request_gate (
    .core_local_flush_i(core_local_flush_w),
    .checkpoint_mem_flush_i(checkpoint_mem_flush_q),
    .pending_system_satp_write_commit_i(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_i(pending_system_sfence_commit_w),
    .stop_pending_i(stop_pending_q),
    .pending_fp_i(pending_fp_q),
    .backend_drained_i(backend_drained_q),
    .pending_fp_mem_pending_i(pending_fp_mem_pending_q),
    .pending_fp_mem_done_i(pending_fp_mem_done_q),
    .pending_fp_store_i(pending_fp_store_q),
    .pending_fp_mem_aligned_addr_i(pending_fp_mem_aligned_addr_w),
    .pending_fp_mem_wdata_i(pending_fp_mem_wdata_w),
    .pending_fp_mem_wstrb_i(pending_fp_mem_wstrb_w),
    .core_mem_req_valid_i(core_mem_req_valid_w),
    .core_mem_req_write_i(core_mem_req_write_w),
    .core_mem_req_addr_i(core_mem_req_addr_w),
    .core_mem_req_wdata_i(core_mem_req_wdata_w),
    .core_mem_req_wstrb_i(core_mem_req_wstrb_w),
    .core_mem_rsp_ready_i(core_mem_rsp_ready_w),
    .core_mem1_req_valid_i(core_mem1_req_valid_w),
    .core_mem1_req_write_i(core_mem1_req_write_w),
    .core_mem1_req_addr_i(core_mem1_req_addr_w),
    .core_mem1_req_wdata_i(core_mem1_req_wdata_w),
    .core_mem1_req_wstrb_i(core_mem1_req_wstrb_w),
    .core_mem1_rsp_ready_i(core_mem1_rsp_ready_w),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .pending_fp_mem_req_valid_o(pending_fp_mem_req_valid_w),
    .pending_fp_mem_req_fire_o(pending_fp_mem_req_fire_w),
    .pending_fp_mem_rsp_fire_o(pending_fp_mem_rsp_fire_w),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem1_req_valid_o(mem1_req_valid_o),
    .mem1_req_write_o(mem1_req_write_o),
    .mem1_req_addr_o(mem1_req_addr_o),
    .mem1_req_wdata_o(mem1_req_wdata_o),
    .mem1_req_wstrb_o(mem1_req_wstrb_o),
    .mem1_rsp_ready_o(mem1_rsp_ready_o),
    .mem_flush_o(mem_flush_o),
    .mmu_flush_o(mmu_flush_o)
  );

  assign pending_branch_rs1_data_w =
      arch_gpr(core_debug_gprs_w, pending_branch_rs1_q);
  assign pending_branch_rs2_data_w =
      arch_gpr(core_debug_gprs_w, pending_branch_rs2_q);
  assign pending_jump_rs1_data_w =
      arch_gpr(core_debug_gprs_w, pending_jump_rs1_q);
  CsrFile u_csr_file (
    .clk(clk),
    .rst(rst),
    .cycle_count_enable_i(run_i && !halted_q),
    .time_i(time_i),
    .instret_inc_i(core_retire_count_w),
    .csr_valid_i(csr_access_valid_w),
    .csr_addr_i(csr_access_addr_w),
    .csr_funct3_i(csr_access_funct3_w),
    .csr_rs1_idx_i(csr_access_rs1_idx_w),
    .csr_rs1_data_i(csr_access_rs1_data_w),
    .csr_zimm_i(csr_access_rs1_idx_w),
    .csr_commit_i(pending_system_csr_commit_w),
    .csr_rdata_o(csr_rdata_w),
    .csr_illegal_o(csr_illegal_w),
    .fp_fflags_valid_i(pending_fp_fflags_commit_w),
    .fp_fflags_i(pending_fp_commit_fflags_w),
    .trap_mem_valid_i(csr_trap_mem_valid_w),
    .trap_mem_pc_i(csr_trap_mem_pc_w),
    .trap_mem_cause_i(csr_trap_mem_cause_w),
    .trap_mem_tval_i(csr_trap_mem_tval_w),
    .trap_ex_valid_i(csr_trap_ex_valid_w),
    .trap_ex_pc_i(csr_trap_ex_pc_w),
    .trap_ex_cause_i(csr_trap_ex_cause_w),
    .trap_ex_tval_i(csr_trap_ex_tval_w),
    .irq_software_i(irq_software_i),
    .irq_timer_i(irq_timer_i),
    .irq_external_i(irq_external_i),
    .irq_pending_o(csr_irq_pending_w),
    .irq_cause_o(csr_irq_cause_w),
    .trap_irq_valid_i(csr_trap_irq_valid_w),
    .trap_irq_pc_i(csr_trap_irq_pc_w),
    .trap_irq_cause_i(csr_trap_irq_cause_w),
    .mret_valid_i(csr_real_mret_valid_w),
    .sret_valid_i(csr_sret_valid_w),
    .trap_target_o(csr_trap_target_w),
    .mepc_o(csr_mepc_w),
    .ret_target_o(csr_ret_target_w),
    .priv_mode_o(csr_priv_mode_w),
    .ecall_cause_o(csr_ecall_cause_w),
    .mstatus_o(csr_mstatus_w),
    .satp_o(csr_satp_w),
    .svpbmt_en_o(csr_svpbmt_en_w),
    .pmpcfg_o(csr_pmpcfg_w),
    .pmpaddr_o(csr_pmpaddr_w)
  );

  DecodeStage u_head0_decode (
    .inst_i(head_inst0_w),
    .ctrl_o(head0_ctrl_w),
    .rs1_idx_o(head0_rs1_w),
    .rs2_idx_o(head0_rs2_w),
    .rd_idx_o(head0_rd_unused_w),
    .imm_o(head0_imm_w)
  );

  DecodeStage u_head1_decode (
    .inst_i(head_inst1_w),
    .ctrl_o(head1_ctrl_w),
    .rs1_idx_o(head1_rs1_w),
    .rs2_idx_o(head1_rs2_w),
    .rd_idx_o(head1_rd_unused_w),
    .imm_o(head1_imm_w)
  );

  DecodeStage u_branch_target_capture_decode (
    .inst_i(fetch_dec0_inst_w),
    .ctrl_o(branch_target_capture_ctrl_w),
    .rs1_idx_o(branch_target_capture_rs1_unused_w),
    .rs2_idx_o(branch_target_capture_rs2_unused_w),
    .rd_idx_o(branch_target_capture_rd_unused_w),
    .imm_o(branch_target_capture_imm_unused_w)
  );

  DecodeStage u_branch_prefetch0_decode (
    .inst_i(branch_prefetch_buf_inst0_q),
    .ctrl_o(branch_prefetch0_ctrl_w),
    .rs1_idx_o(branch_prefetch0_rs1_unused_w),
    .rs2_idx_o(branch_prefetch0_rs2_unused_w),
    .rd_idx_o(branch_prefetch0_rd_unused_w),
    .imm_o(branch_prefetch0_imm_unused_w)
  );

  DecodeStage u_branch_prefetch1_decode (
    .inst_i(branch_prefetch_buf_inst1_q),
    .ctrl_o(branch_prefetch1_ctrl_w),
    .rs1_idx_o(branch_prefetch1_rs1_unused_w),
    .rs2_idx_o(branch_prefetch1_rs2_unused_w),
    .rd_idx_o(branch_prefetch1_rd_unused_w),
    .imm_o(branch_prefetch1_imm_unused_w)
  );

  DecodeStage u_branch_prefetch_rsp1_decode (
    .inst_i(fetch_dec1_inst_w),
    .ctrl_o(branch_prefetch_rsp1_ctrl_w),
    .rs1_idx_o(branch_prefetch_rsp1_rs1_unused_w),
    .rs2_idx_o(branch_prefetch_rsp1_rs2_unused_w),
    .rd_idx_o(branch_prefetch_rsp1_rd_unused_w),
    .imm_o(branch_prefetch_rsp1_imm_unused_w)
  );

  CompareUnit u_pending_branch_compare (
    .lhs_i(pending_branch_rs1_data_w),
    .rhs_i(pending_branch_rs2_data_w),
    .cmp_op_i(pending_branch_cmp_op_q),
    .cmp_true_o(pending_branch_taken_w)
  );

  OooAluCoreSlice #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_core_slice (
    .clk(clk),
    .rst(rst),
    .flush_i(core_local_flush_w),
    .checkpoint_capture_i(core_checkpoint_capture_w),
    .checkpoint_restore_i(core_checkpoint_restore_w),
    .checkpoint_quiesce_i(core_checkpoint_quiesce_w),
    .mem_issue_block_i(core_mem_issue_block_w),
    .pending_branch_fast_valid_i(stop_pending_q && pending_branch_q &&
                                 pending_branch_dispatched_q),
    .pending_branch_fast_pc_i(pending_branch_pc_q),
    .serial_write_valid_i(pending_fp_gpr_commit_w),
    .serial_write_arch_rd_i(pending_fp_rd_q),
    .serial_write_data_i(pending_fp_result_value_w),
    .dispatch0_valid_i(core_dispatch0_valid_w),
    .dispatch0_ready_o(dispatch0_ready_w),
    .dispatch0_pc_i(core_dispatch0_pc_w),
    .dispatch0_next_pc_i(core_dispatch0_next_pc_w),
    .dispatch0_inst_i(core_dispatch0_inst_w),
    .dispatch0_csr_rdata_i(core_dispatch0_csr_rdata_w),
    .dispatch0_unsupported_o(dispatch0_unsupported_w),
    .dispatch1_valid_i(core_dispatch1_valid_w),
    .dispatch1_optional_i(dispatch1_optional_w),
    .dispatch1_ready_o(dispatch1_ready_w),
    .dispatch1_pc_i(core_dispatch1_pc_w),
    .dispatch1_next_pc_i(core_dispatch1_next_pc_w),
    .dispatch1_inst_i(core_dispatch1_inst_w),
    .dispatch1_csr_rdata_i({`XLEN{1'b0}}),
    .dispatch1_unsupported_o(dispatch1_unsupported_w),
    .mem_req_valid_o(core_mem_req_valid_w),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_o(core_mem_req_write_w),
    .mem_req_addr_o(core_mem_req_addr_w),
    .mem_req_wdata_o(core_mem_req_wdata_w),
    .mem_req_wstrb_o(core_mem_req_wstrb_w),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(core_mem_rsp_ready_w),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem_rsp_page_fault_i(mem_rsp_page_fault_i),
    .mem1_req_valid_o(core_mem1_req_valid_w),
    .mem1_req_ready_i(mem1_req_ready_i),
    .mem1_req_write_o(core_mem1_req_write_w),
    .mem1_req_addr_o(core_mem1_req_addr_w),
    .mem1_req_wdata_o(core_mem1_req_wdata_w),
    .mem1_req_wstrb_o(core_mem1_req_wstrb_w),
    .mem1_rsp_valid_i(mem1_rsp_valid_i),
    .mem1_rsp_ready_o(core_mem1_rsp_ready_w),
    .mem1_rsp_rdata_i(mem1_rsp_rdata_i),
    .mem1_rsp_error_i(mem1_rsp_error_i),
    .mem1_rsp_page_fault_i(mem1_rsp_page_fault_i),
    .commit_ready_i(core_commit_ready_w),
    .commit1_block_i(core_commit1_block_w),
    .commit0_valid_o(core_commit0_valid_w),
    .commit0_pc_o(core_commit0_pc_w),
    .commit0_next_pc_o(core_commit0_next_pc_w),
    .commit0_inst_o(core_commit0_inst_w),
    .commit0_rd_en_o(core_commit0_rd_en_w),
    .commit0_arch_rd_o(core_commit0_rd_addr_w),
    .commit0_data_o(core_commit0_rd_data_w),
    .commit0_exception_o(core_commit0_exception_w),
    .commit0_cause_o(core_commit0_cause_w),
    .commit0_tval_o(core_commit0_tval_w),
    .commit0_write_o(core_commit0_write_w),
    .commit1_valid_o(core_commit1_valid_w),
    .commit1_pc_o(core_commit1_pc_w),
    .commit1_next_pc_o(core_commit1_next_pc_w),
    .commit1_inst_o(core_commit1_inst_w),
    .commit1_rd_en_o(core_commit1_rd_en_w),
    .commit1_arch_rd_o(core_commit1_rd_addr_w),
    .commit1_data_o(core_commit1_rd_data_w),
    .commit1_exception_o(core_commit1_exception_w),
    .commit1_cause_o(core_commit1_cause_w),
    .commit1_tval_o(core_commit1_tval_w),
    .commit1_write_o(core_commit1_write_w),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
	    .issue_count_o(issue_count_o),
	    .mem_idle_o(core_mem_idle_w),
	    .execute0_valid_o(execute0_valid_unused_w),
	    .execute1_valid_o(execute1_valid_unused_w),
	    .branch_resolve_valid_o(core_branch_resolve_valid_w),
	    .branch_resolve_pc_o(core_branch_resolve_pc_w),
	    .branch_resolve_next_pc_o(core_branch_resolve_next_pc_w),
	    .branch_resolve_misaligned_o(core_branch_resolve_misaligned_w),
	    .dispatch_branch_resolve_valid_o(core_dispatch_branch_resolve_valid_w),
	    .dispatch_branch_resolve_pc_o(core_dispatch_branch_resolve_pc_w),
	    .dispatch_branch_resolve_next_pc_o(core_dispatch_branch_resolve_next_pc_w),
	    .dispatch_branch_resolve_misaligned_o(core_dispatch_branch_resolve_misaligned_w),
	    .pending_load_branch_dep_o(core_pending_load_branch_dep_w),
	    .retire_count_o(core_retire_count_w),
    .a0_data_o(a0_data_w),
    .debug_gprs_o(core_debug_gprs_w)
  );

  OooCommitOutputMux u_commit_output_mux (
    .ctrl_commit_valid_i(ctrl_commit_valid_q),
    .ctrl_commit_pc_i(ctrl_commit_pc_q),
    .ctrl_commit_inst_i(ctrl_commit_inst_q),
    .ctrl_commit_next_pc_i(ctrl_commit_next_pc_q),
    .ctrl_commit_rd_en_i(ctrl_commit_rd_en_q),
    .ctrl_commit_rd_addr_i(ctrl_commit_rd_addr_q),
    .ctrl_commit_rd_data_i(ctrl_commit_rd_data_q),
    .ctrl_commit_write_i(ctrl_commit_write_q),
    .synth_lane1_branch_append_i(synth_lane1_branch_append_w),
    .synth_branch_append_pc_i(head_pc_w),
    .synth_branch_append_inst_i(head_inst0_w),
    .synth_branch_append_next_pc_i(core_dispatch_branch_resolve_next_pc_w),
    .synth_lane1_ret_before_core0_i(synth_lane1_ret_before_core0_w),
    .synth_lane1_ret_after_core0_i(synth_lane1_ret_after_core0_w),
    .synth_lane1_ret_drop_branch_i(synth_lane1_ret_drop_branch_w),
    .synth_lane1_ret_pc_i(synth_lane1_ret_pc_q),
    .synth_lane1_ret_inst_i(synth_lane1_ret_inst_q),
    .synth_lane1_ret_next_pc_i(synth_lane1_ret_next_pc_q),
    .core_commit0_valid_i(core_commit0_valid_w),
    .core_commit0_pc_i(core_commit0_pc_w),
    .core_commit0_next_pc_i(core_commit0_next_pc_w),
    .core_commit0_inst_i(core_commit0_inst_w),
    .core_commit0_rd_en_i(core_commit0_rd_en_w),
    .core_commit0_rd_addr_i(core_commit0_rd_addr_w),
    .core_commit0_rd_data_i(core_commit0_rd_data_w),
    .core_commit0_exception_i(core_commit0_exception_w),
    .core_commit0_write_i(core_commit0_write_w),
    .core_commit1_valid_i(core_commit1_valid_w),
    .core_commit1_pc_i(core_commit1_pc_w),
    .core_commit1_next_pc_i(core_commit1_next_pc_w),
    .core_commit1_inst_i(core_commit1_inst_w),
    .core_commit1_rd_en_i(core_commit1_rd_en_w),
    .core_commit1_rd_addr_i(core_commit1_rd_addr_w),
    .core_commit1_rd_data_i(core_commit1_rd_data_w),
    .core_commit1_exception_i(core_commit1_exception_w),
    .core_commit1_write_i(core_commit1_write_w),
    .core_retire_count_i(core_retire_count_w),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_rd_addr_o(commit0_rd_addr_o),
    .commit0_rd_data_o(commit0_rd_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_write_o(commit0_write_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_rd_addr_o(commit1_rd_addr_o),
    .commit1_rd_data_o(commit1_rd_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_write_o(commit1_write_o),
    .retire_count_o(retire_count_o)
  );

  assign trap_valid_o = trap_valid_q;
  assign trap_cause_o = trap_cause_q;
  assign trap_pc_o = trap_pc_q;
  assign trap_tval_o = trap_tval_q;
  assign exit_valid_o = exit_valid_q;
  assign exit_is_ecall_o = exit_is_ecall_q;
  assign exit_is_ebreak_o = exit_is_ebreak_q;
  assign exit_code_o = a0_data_w;
  assign halted_o = halted_q ||
                    (stop_pending_q && !pending_branch_q && !pending_jump_q &&
                     !pending_mem_q && !pending_fp_q && !pending_system_q &&
                     !synth_lane1_ret_pending_q &&
                     !synth_lane1_branch_drop_pending_q);
  assign priv_mode_o = csr_priv_mode_w;
  assign mstatus_o = csr_mstatus_w;
  assign satp_o = csr_satp_w;
  assign svpbmt_en_o = csr_svpbmt_en_w;
  assign pmpcfg_o = csr_pmpcfg_w;
  assign pmpaddr_o = csr_pmpaddr_w;
  assign debug_gprs_o = core_debug_gprs_w;
  assign debug_pc_o = trap_valid_q ? trap_pc_q :
                      fifo_has_packet_w ? head_pc_w :
                      outstanding_valid_q ? outstanding_pc_q :
                      next_fetch_pc_q;
  assign debug_state_o =
      trap_valid_q ? `CORE_STATE_TRAP :
      halted_q ? `CORE_STATE_HALT :
      fifo_has_packet_w ? `CORE_STATE_DECODE :
      outstanding_valid_q ? `CORE_STATE_FETCH_WAIT :
      fetch_req_valid_o ? `CORE_STATE_FETCH_REQ :
      `CORE_STATE_FETCH_REQ;

  wire unused_core_slice_observe_w =
      execute0_valid_unused_w | execute1_valid_unused_w |
      (|head0_ctrl_w) | (|head0_rd_unused_w) |
      (|head1_ctrl_w) | (|head1_rd_unused_w) |
      (|branch_target_capture_ctrl_w) |
      (|branch_target_capture_rs1_unused_w) |
      (|branch_target_capture_rs2_unused_w) |
      (|branch_target_capture_rd_unused_w) |
      (|branch_target_capture_imm_unused_w) |
      (|branch_prefetch0_rs1_unused_w) |
      (|branch_prefetch0_rs2_unused_w) |
      (|branch_prefetch0_rd_unused_w) |
      (|branch_prefetch0_imm_unused_w) |
      (|branch_prefetch1_rs1_unused_w) |
      (|branch_prefetch1_rs2_unused_w) |
      (|branch_prefetch1_rd_unused_w) |
      (|branch_prefetch1_imm_unused_w) |
      (|branch_prefetch_rsp1_rs1_unused_w) |
      (|branch_prefetch_rsp1_rs2_unused_w) |
      (|branch_prefetch_rsp1_rd_unused_w) |
      (|branch_prefetch_rsp1_imm_unused_w) |
      branch_fallthrough_safe_w | branch_target_cache_hit_w |
      pending_fp_div_busy_w | pending_fp_sqrt_busy_w |
      return_cont_attempt_ready_w |
      pending_jump_jalr_sum_lsb_unused_w | head_fetch_fault_w |
      pending_branch_bht_valid_q |
      branch_bpu_lookup_event_w | branch_bpu_lookup_bht_valid_w |
      branch_bpu_update_correct_w |
      csr_irq_pending_w | (|csr_irq_cause_w) | (|csr_trap_target_w) |
      (|csr_mepc_w) | (|csr_priv_mode_w) | (|csr_satp_w) |
      (|head_packet_next_pc_w);

  wire ras_clear_w;
  wire ras_pop_w;
  wire ras_push_w;
  wire [`XLEN-1:0] ras_push_value_w;

  OooRasUpdateGate u_ras_update_gate (
      .priv_predictor_boundary_i(priv_predictor_boundary_w),
      .branch_spec_restore_i(branch_spec_restore_w),
      .branch_resolve_untracked_i(branch_resolve_untracked_w),
      .direct_jal_call_unsafe_i(direct_jal_call_unsafe_w),
      .direct_ret0_fire_i(direct_ret0_fire_w),
      .direct_ret1_fire_i(direct_ret1_fire_w),
      .pending_jump_return_fire_i(pending_jump_return_fire_w),
      .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret_w),
      .direct_jal_call_i(direct_jal_call_w),
      .pending_jump_call_fire_i(pending_jump_call_fire_w),
      .pending_jump_next_pc_i(pending_jump_next_pc_q),
      .direct_jal_link_i(direct_jal_link_w),
      .ras_clear_o(ras_clear_w),
      .ras_pop_o(ras_pop_w),
      .ras_push_o(ras_push_w),
      .ras_push_value_o(ras_push_value_w)
  );

  OooBranchSpecTracker u_branch_spec_tracker (
      .clk(clk),
      .rst(rst || flush_i),
      .csr_trap_clear_i(csr_trap_mem_valid_w),
      .direct_frontend_flush_i(direct_frontend_flush_w),
      .direct_branch_fire_i(direct_branch0_fire_w || direct_branch1_fire_w),
      .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect_w),
      .direct_branch_spec_start_i(direct_branch_spec_start_w),
      .direct_branch_pred_pc_i(direct_branch_pred_pc_w),
      .checkpoint_capture_i(branch_spec_checkpoint_capture_w),
      .resolve_valid_i(branch_spec_resolve_valid_w),
      .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
      .pending_branch_match_clear_i(pending_branch_match_clear_w),
      .branch_resolve_untracked_i(branch_resolve_untracked_w),
      .active_o(branch_spec_active_q),
      .checkpoint_pending_o(branch_spec_checkpoint_pending_q),
      .pred_pc_o(branch_spec_pred_pc_q)
  );

  OooFetchPcOutstandingSequencer u_fetch_pc_outstanding (
      .clk(clk),
      .rst(rst || flush_i),
      .reset_pc_i(reset_pc_i),
      .fetch_rsp_enqueue_i(fetch_rsp_enqueue_w),
      .fetch_rsp_bypass_consumed_i(fetch_rsp_bypass_consumed_w),
      .fetch_rsp_fire_i(fetch_rsp_fire_w),
      .fetch_rsp_packet_next_pc_i(fetch_rsp_packet_next_pc_w),
      .fetch_req_fire_i(fetch_req_fire_w),
      .fetch_req_pc_i(fetch_req_pc_w),
      .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
      .csr_trap_target_i(csr_trap_target_w),
      .csr_ret_target_i(csr_ret_target_w),
      .direct_frontend_flush_i(direct_frontend_flush_w),
      .branch_fallthrough_keep_outstanding_i(branch_fallthrough_keep_outstanding_w),
      .direct_jal_fire_i(direct_jal_fire_w),
      .direct_jal_target_i(direct_jal_target_w),
      .direct_ret_fire_i(direct_ret0_fire_w || direct_ret1_fire_w),
      .direct_ret_target_i(direct_ret_target_w),
      .direct_branch_fire_i(direct_branch0_fire_w || direct_branch1_fire_w),
      .direct_branch1_fire_i(direct_branch1_fire_w),
      .direct_branch0_lane1_ret_i(direct_branch0_lane1_ret_w),
      .return_cont_dispatch_i(return_cont_dispatch_w),
      .return_cont_next_pc_i(return_cont_next_pc_q),
      .ras_top_i(ras_top_w),
      .branch_target_dispatch_i(branch_target_dispatch_w),
      .branch_target_cache_next_pc_i(branch_target_cache_next_pc_w),
      .branch_fallthrough_dispatch_i(branch_fallthrough_dispatch_w),
      .head_next_pc1_i(head_next_pc1_w),
      .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect_w),
      .direct_branch_resolve_next_pc_i(direct_branch_resolve_next_pc_w),
      .direct_branch_spec_start_i(direct_branch_spec_start_w),
      .direct_branch_pred_pc_i(direct_branch_pred_pc_w),
      .head_next_pc0_i(head_next_pc0_w),
      .branch_fallthrough_capture_rsp_i(branch_fallthrough_capture_rsp_w),
      .branch_spec_resolve_valid_i(branch_spec_resolve_valid_w),
      .branch_spec_restore_i(branch_spec_restore_w),
      .core_branch_resolve_misaligned_i(core_branch_resolve_misaligned_w),
      .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
      .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
      .pending_branch_match_clear_i(pending_branch_match_clear_w),
      .pending_branch_misaligned_i(pending_branch_misaligned_w),
      .pending_branch_next_pc_i(pending_branch_next_pc_w),
      .branch_prefetch_pending_match_i(branch_prefetch_pending_match_w),
      .branch_prefetch_pc_i(branch_prefetch_pc_q),
      .branch_prefetch_hit_available_i(branch_prefetch_hit_available_w),
      .branch_prefetch_hit_packet_next_pc_i(branch_prefetch_hit_packet_next_pc_w),
      .branch_resolve_untracked_i(branch_resolve_untracked_w),
      .pending_jump_resolve_ready_i(pending_jump_resolve_ready_w),
      .pending_jump_misaligned_i(pending_jump_misaligned_w),
      .pending_jump_nolink_commit_i(pending_jump_nolink_commit_w),
      .pending_jump_redirect_after_dispatch_i(pending_jump_redirect_after_dispatch_w),
      .jalr_prefetch_pending_match_i(jalr_prefetch_pending_match_w),
      .jalr_prefetch_hit_available_i(jalr_prefetch_hit_available_w),
      .jalr_prefetch_hit_packet_next_pc_i(jalr_prefetch_hit_packet_next_pc_w),
      .pending_jump_resolved_target_i(pending_jump_resolved_target_w),
      .pending_system_csr_commit_i(pending_system_csr_commit_w),
      .pending_system_next_pc_i(pending_system_next_pc_q),
      .drain_complete_i(stop_pending_q && drain_complete_w),
      .pending_arch_trap_i(pending_arch_trap_q),
      .pending_system_i(pending_system_q),
      .pending_system_ecall_i(pending_system_ecall_q),
      .pending_system_irq_i(pending_system_irq_q),
      .pending_system_mret_i(pending_system_mret_q),
      .pending_branch_i(pending_branch_q),
      .pending_branch_dispatched_i(pending_branch_dispatched_q),
      .pending_jump_i(pending_jump_q),
      .pending_jump_target_i(pending_jump_target_q),
      .pending_mem_i(pending_mem_q),
      .pending_mem_next_pc_i(pending_mem_next_pc_q),
      .pending_fp_i(pending_fp_q),
      .pending_fp_next_pc_i(pending_fp_next_pc_q),
      .next_fetch_pc_o(next_fetch_pc_q),
      .outstanding_valid_o(outstanding_valid_q),
      .outstanding_pc_o(outstanding_pc_q),
      .discard_fetch_rsp_o(discard_fetch_rsp_q)
  );

  OooRasStack u_ras_stack (
      .clk(clk),
      .rst(rst || flush_i),
      .clear_i(ras_clear_w),
      .pop_i(ras_pop_w),
      .push_i(ras_push_w),
      .push_value_i(ras_push_value_w),
      .empty_o(ras_empty_w),
      .full_o(ras_full_w),
      .reliable_o(ras_reliable_q),
      .top_o(ras_top_w)
  );

  OooReturnContBuffer u_return_cont_buffer (
      .clk(clk),
      .rst(rst || flush_i),
      .clear_i(ras_clear_w),
      .consume_i(return_cont_dispatch_w),
      .capture_i(direct_jal_call_w),
      .capture_valid_i(return_cont_capture_w),
      .capture_pc_i(head_pc1_w),
      .capture_next_pc_i(head_next_pc1_w),
      .capture_inst_i(head_inst1_w),
      .valid_o(return_cont_valid_q),
      .pc_o(return_cont_pc_q),
      .next_pc_o(return_cont_next_pc_q),
      .inst_o(return_cont_inst_q)
  );

  OooStopPendingSequencer u_stop_pending_sequencer (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .direct_branch0_fire_i(direct_branch0_fire_w),
    .direct_branch1_fire_i(direct_branch1_fire_w),
    .direct_branch_resolve_redirect_i(direct_branch_resolve_redirect_w),
    .branch_spec_checkpoint_capture_i(branch_spec_checkpoint_capture_w),
    .branch_spec_resolve_valid_i(branch_spec_resolve_valid_w),
    .orphan_stop_pending_i(orphan_stop_pending_w),
    .pending_branch_commit_resolve_i(pending_branch_commit_resolve_w),
    .pending_branch_match_clear_i(pending_branch_match_clear_w),
    .branch_resolve_untracked_i(branch_resolve_untracked_w),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_w),
    .pending_jump_misaligned_i(pending_jump_misaligned_w),
    .pending_jump_nolink_commit_i(pending_jump_nolink_commit_w),
    .pending_jump_redirect_after_dispatch_i(pending_jump_redirect_after_dispatch_w),
    .jump_dispatch_fire_i(jump_dispatch_fire_w),
    .pending_mem_resolve_ready_i(pending_mem_resolve_ready_w),
    .system_csr_dispatch_fire_i(system_csr_dispatch_fire_w),
    .pending_system_csr_commit_i(pending_system_csr_commit_w),
    .drain_complete_i(drain_complete_w),
    .can_run_i(can_run_w),
    .fifo_has_packet_i(fifo_has_packet_w),
    .csr_irq_pending_i(csr_irq_pending_w),
    .head_fetch_fault0_i(head_fetch_fault0_w),
    .dispatch0_arch_trap_i(dispatch0_arch_trap_w),
    .dispatch0_exit_i(dispatch0_exit_w),
    .dispatch0_fp_i(dispatch0_fp_w),
    .dispatch0_system_i(dispatch0_system_w),
    .head0_csr_illegal_i(head0_csr_illegal_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .direct_jal0_dispatch_valid_i(direct_jal0_dispatch_valid_w),
    .dispatch0_jump_i(dispatch0_jump_w),
    .dispatch0_return_i(dispatch0_return_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .dispatch_unsupported_i(dispatch_unsupported_w),
    .stop_pending_o(stop_pending_q)
  );

endmodule
