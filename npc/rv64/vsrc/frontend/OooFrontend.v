`include "define.v"
`include "common/OooSlotFacts.v"

// OooFrontend: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 55 个实例）。
// 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。
module OooFrontend #(
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter FETCH_PACKET_COUNT_W = `OOO_FETCH_PACKET_COUNT_W
) (
  input backend_drained_w,
  input clk,
  input commit_ready_i,
  input core_branch_resolve_misaligned_w,
  input core_branch_resolve_mispredict_w,
  // 【F2】issue-resolve BPU 回训随行载荷(后端 resolve 总线导出)
  input core_branch_resolve_is_branch_w,
  input core_branch_resolve_taken_w,
  input core_branch_resolve_pred_taken_w,
  input [`BPU_BHT_INDEX_W-1:0] core_branch_resolve_bht_idx_w,
  input [`XLEN-1:0] core_branch_resolve_next_pc_w,
  input [`XLEN-1:0] core_branch_resolve_pc_w,
  input core_branch_resolve_valid_w,
  input [`INST_W-1:0] core_commit0_inst_w,
  input core_commit0_valid_w,
  input [`INST_W-1:0] core_commit1_inst_w,
  input core_commit1_valid_w,
  input core_dispatch_branch_resolve_misaligned_w,
  input [`XLEN-1:0] core_dispatch_branch_resolve_next_pc_w,
  input [`XLEN-1:0] core_dispatch_branch_resolve_pc_w,
  input core_dispatch_branch_resolve_valid_w,
  input core_mem_idle_w,
  input core_pending_load_branch_dep_w,
  input core_serial_flush_q,
  input core_trap_flush_q,
  input csr_irq_pending_w,
  input [`XLEN-1:0] csr_mstatus_w,
  input [2:0] csr_frm_w,
  input [1:0] csr_priv_mode_w,
  input [`XLEN-1:0] csr_ret_target_w,
  input csr_trap_ex_valid_w,
  input csr_trap_irq_valid_w,
  input csr_trap_mem_valid_w,
  input [`XLEN-1:0] csr_trap_target_w,
  input ctrl_commit_valid_q,
  input direct_branch_spec_start_w,
  input dispatch0_ready_w,
  input dispatch0_unsupported_w,
  input dispatch0_unsupported_raw_w,
  input dispatch1_ready_w,
  input dispatch1_unsupported_w,
  input dispatch1_unsupported_raw_w,
  input drain_complete_w,
  input execute0_valid_unused_w,
  input execute1_valid_unused_w,
  input exit_valid_q,
  input fetch_req_ready_i,
  input [`INST_W-1:0] fetch_rsp_inst0_i,
  input [`INST_W-1:0] fetch_rsp_inst1_i,
  input [1:0] fetch_rsp_resp0_i,
  input [1:0] fetch_rsp_resp1_i,
  input fetch_rsp_valid_i,
  input flush_i,
  input halted_q,
  input jump_dispatch_valid_w,
  input [`XLEN-1:0] mem_req_addr_o,
  input mem_req_ready_i,
  input mem_req_valid_o,
  input mem_req_write_o,
  input mem_rsp_ready_o,
  input pending_arch_trap_q,
  input pending_branch_capture_direct_w,
  input pending_branch_capture_head0_w,
  input pending_branch_capture_lane1_w,
  input pending_branch_clear_w,
  input pending_branch_commit_resolve_w,
  input pending_branch_match_clear_w,
  input pending_branch_taken_w,
  input pending_exit_q,
  input pending_jump_capture_head0_w,
  input pending_jump_capture_lane1_w,
  input pending_jump_clear_w,
  input [`XLEN-1:0] pending_jump_rs1_data_w,
  // pending_mem 全链已删除；下述二信号仅供活的 fetch/run 端 sensor 读取（恒 0，父模块 tie-off）。
  input [`XLEN-1:0] pending_mem_next_pc_q,
  input pending_mem_q,
  input pending_mem_resolve_ready_w,
  input pending_system_csr_commit_w,
  input [`XLEN-1:0] pending_system_csr_rdata_q,
  input pending_system_ecall_q,
  input [`INST_W-1:0] pending_system_inst_q,
  input pending_system_irq_q,
  input pending_system_mret_q,
  input [`XLEN-1:0] pending_system_next_pc_q,
  input [`XLEN-1:0] pending_system_pc_q,
  input pending_system_q,
  input pending_system_satp_write_commit_w,
  input priv_predictor_boundary_w,
  input [`XLEN-1:0] reset_pc_i,
  input [ROB_COUNT_W-1:0] rob_count_o,
  input rst,
  input run_i,
  input stop_pending_q,
  input synth_lane1_branch_drop_pending_q,
  input synth_lane1_ret_pending_q,
  input system_csr_dispatch_fire_w,
  input system_csr_dispatch_valid_w,
  input trap_redirect_squash_q,
  input trap_valid_q,
  output backend_drained_q,
  output branch_bpu_lookup_bht_valid_w,
  output branch_bpu_lookup_event_w,
  output branch_bpu_update_correct_w,
  output [`XLEN-1:0] branch_bpu_update_pc_w,
  output branch_bpu_update_pred_taken_w,
  output branch_bpu_update_taken_w,
  output branch_bpu_update_valid_w,
  output branch_fallthrough_safe_w,
  output [`XLEN-1:0] branch_prefetch0_imm_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch0_rd_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch0_rs1_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch0_rs2_unused_w,
  output [`XLEN-1:0] branch_prefetch1_imm_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch1_rd_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch1_rs1_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch1_rs2_unused_w,
  output branch_prefetch_hit_available_w,
  output branch_prefetch_req_fire_w,
  output [`XLEN-1:0] branch_prefetch_rsp1_imm_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rd_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs1_unused_w,
  output [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs2_unused_w,
  output branch_resolve_pending_match_w,
  output branch_resolve_redirect_w,
  output branch_resolve_untracked_redirect_w,
  output branch_resolve_untracked_w,
  output branch_spec_active_q,
  output branch_spec_checkpoint_capture_w,
  output branch_spec_checkpoint_pending_q,
  output branch_spec_dispatch_block_w,
  output branch_spec_pred_match_w,
  output branch_spec_redirect_w,
  output branch_spec_resolve_valid_w,
  output branch_spec_restore_w,
  output branch_target_cache_hit_w,
  output [`CTRL_BUS_W-1:0] branch_target_capture_ctrl_w,
  output [`XLEN-1:0] branch_target_capture_imm_unused_w,
  output [`REG_ADDR_W-1:0] branch_target_capture_rd_unused_w,
  output [`REG_ADDR_W-1:0] branch_target_capture_rs1_unused_w,
  output [`REG_ADDR_W-1:0] branch_target_capture_rs2_unused_w,
  output can_run_w,
  output [`XLEN-1:0] core_dispatch0_csr_rdata_w,
  output core_dispatch0_fire_w,
  output [`INST_W-1:0] core_dispatch0_inst_w,
  output [`XLEN-1:0] core_dispatch0_next_pc_w,
  output [`XLEN-1:0] core_dispatch0_pc_w,
  output core_dispatch0_valid_w,
  output [`INST_W-1:0] core_dispatch1_inst_w,
  output [`XLEN-1:0] core_dispatch1_next_pc_w,
  output [`XLEN-1:0] core_dispatch1_pc_w,
  output core_dispatch1_valid_w,
  output [`XLEN-1:0] core_dispatch0_pred_npc_w,
  output [`XLEN-1:0] core_dispatch1_pred_npc_w,
  // 【F2】dispatch 载荷: head0/head1 的 BHT 查询快照(bht_idx=lookup 拍 pc^ghr, 必须
  // 随行——update 拍 ghr 已变), 后端 thread 进 IQ、resolve 拍随 resolve 总线回前端回训。
  output [`BPU_BHT_INDEX_W-1:0] core_dispatch0_bht_idx_w,
  output core_dispatch0_pred_taken_w,
  output [`BPU_BHT_INDEX_W-1:0] core_dispatch1_bht_idx_w,
  output core_dispatch1_pred_taken_w,
  output direct_branch0_dispatch_valid_w,
  output direct_branch0_fire_w,
  output direct_branch0_lane1_ret_w,
  output direct_branch1_fire_w,
  output [`XLEN-1:0] direct_branch_resolve_next_pc_w,
  output direct_branch_resolve_redirect_w,
  output direct_frontend_flush_w,
  output direct_jal0_dispatch_valid_w,
  output direct_jal_call_w,
  output direct_redirect_fetch_w,
  output direct_ret0_fire_w,
  output direct_ret1_fire_w,
  output discard_fetch_rsp_q,
  output dispatch0_arch_trap_w,
  output dispatch0_branch_w,
  output dispatch0_exit_w,
  output dispatch0_fp_w,
  output dispatch0_jal_w,
  output dispatch0_jump_w,
  output dispatch0_return_w,
  output dispatch0_system_w,
  output dispatch1_barrier_fire_w,
  output dispatch1_barrier_w,
  output dispatch1_optional_w,
  output dispatch_fire_w,
  output dispatch_unsupported_w,
  output dispatch_valid_w,
  output fetch_req_fire_w,
  output [`XLEN-1:0] fetch_req_pc_o,
  output fetch_req_valid_o,
  output fetch_rsp_bypass_consumed_w,
  output fetch_rsp_enqueue_w,
  output fetch_rsp_fire_w,
  output fetch_rsp_ready_o,
  output fifo_has_packet_w,
  output head0_arch_trap_raw_w,
  output head0_csr_raw_w,
  output [`CTRL_BUS_W-1:0] head0_ctrl_w,
  output head0_ecall_raw_w,
  output [`OOO_SLOT_FACTS_W-1:0] head0_facts_w,
  output [`REG_ADDR_W-1:0] head0_rd_unused_w,
  output head0_sfence_raw_w,
  output head0_stop_raw_w,
  output head0_system_raw_w,
  output head0_wfi_raw_w,
  output head0_xret_raw_w,
  output head1_control_raw_w,
  output head1_csr_raw_w,
  output [`CTRL_BUS_W-1:0] head1_ctrl_w,
  output head1_ecall_raw_w,
  output [`OOO_SLOT_FACTS_W-1:0] head1_facts_w,
  output head1_mem_raw_w,
  output [`REG_ADDR_W-1:0] head1_rd_unused_w,
  output head1_sfence_raw_w,
  output head1_stop_raw_w,
  output head1_wfi_raw_w,
  output head1_xret_raw_w,
  output head_fetch_fault0_w,
  output head_fetch_fault1_w,
  output head_fetch_fault_w,
  output [`INST_W-1:0] head_inst0_w,
  output [`INST_W-1:0] head_inst1_w,
  output [`XLEN-1:0] head_next_pc0_w,
  output [`XLEN-1:0] head_next_pc1_w,
  output [`XLEN-1:0] head_packet_next_pc_w,
  output [`XLEN-1:0] head_pc1_w,
  output [`XLEN-1:0] head_pc_w,
  output [1:0] head_resp0_w,
  output [1:0] head_resp1_w,
  output jalr_prefetch_hit_available_w,
  output jump_dispatch_fire_w,
  output [`XLEN-1:0] next_fetch_pc_q,
  output orphan_stop_pending_w,
  output [`XLEN-1:0] outstanding_pc_q,
  output outstanding_valid_q,
  output pending_branch_bht_valid_q,
  output [2:0] pending_branch_cmp_op_q,
  output pending_branch_dispatched_q,
  output [`INST_W-1:0] pending_branch_inst_q,
  output pending_branch_misaligned_w,
  output [`XLEN-1:0] pending_branch_next_pc_w,
  output [`XLEN-1:0] pending_branch_pc_q,
  output pending_branch_q,
  output [`REG_ADDR_W-1:0] pending_branch_rs1_q,
  output [`REG_ADDR_W-1:0] pending_branch_rs2_q,
  output [`XLEN-1:0] pending_branch_target_w,
  output pending_control_ready_w,
  output pending_jump_call_fire_w,
  output pending_jump_dispatched_q,
  output [`XLEN-1:0] pending_jump_imm_q,
  output [`INST_W-1:0] pending_jump_inst_q,
  output pending_jump_jalr_btb_hit_w,
  output pending_jump_jalr_q,
  output pending_jump_jalr_sum_lsb_unused_w,
  output pending_jump_misaligned_w,
  output pending_jump_nolink_commit_w,
  output pending_jump_nolink_w,
  output [`XLEN-1:0] pending_jump_pc_q,
  output pending_jump_q,
  output pending_jump_redirect_after_dispatch_w,
  output pending_jump_resolve_ready_w,
  output [`XLEN-1:0] pending_jump_resolved_target_w,
  output pending_jump_return_fire_w,
  output [`REG_ADDR_W-1:0] pending_jump_rs1_q,
  output ras_empty_w,
  output ras_full_w,
  output redirect_fetch_req_valid_w,
  output return_cont_attempt_ready_w,
  output synth_lane1_branch_append_w
);

  localparam FETCH_COUNT_W = FETCH_PACKET_COUNT_W + 1;
  localparam [FETCH_COUNT_W-1:0] FETCH_PACKET_COUNT_VALUE =
      (1 << FETCH_PACKET_COUNT_W);
  localparam ENABLE_DIRECT_RAS_RET = 1'b1;

  wire backend_execute_quiet_w;
  wire branch_bpu_commit_update_w;
  wire branch_bpu_direct_update_w;
  wire branch_bpu_drained_update_w;
  wire branch_bpu_pending0_capture_w;
  wire branch_bpu_pending1_capture_w;
  wire branch_bpu_pending_like_update_w;
  wire branch_bpu_pending_update_w;
  wire [`BPU_BHT_INDEX_W-1:0] branch_bpu_update_bht_idx_w;
  wire branch_fallthrough_append_attempt_w;
  wire branch_fallthrough_append_candidate_w;
  wire branch_fallthrough_append_safe_w;
  wire branch_fallthrough_append_w;
  wire branch_fallthrough_capture_rsp_w;
  wire branch_fallthrough_dispatch_w;
  wire branch_fallthrough_keep_outstanding_w;
  wire branch_fallthrough_outstanding_match_w;
  wire branch_prefetch_active_q;
  wire [`INST_W-1:0] branch_prefetch_buf_inst0_q;
  wire [`INST_W-1:0] branch_prefetch_buf_inst1_q;
  wire [`XLEN-1:0] branch_prefetch_buf_next_pc0_q;
  wire [`XLEN-1:0] branch_prefetch_buf_next_pc1_q;
  wire [`XLEN-1:0] branch_prefetch_buf_pc0_q;
  wire [`XLEN-1:0] branch_prefetch_buf_pc1_q;
  wire branch_prefetch_buffer_match_w;
  wire branch_prefetch_buffer_valid_q;
  wire branch_prefetch_dispatch0_safe_w;
  wire branch_prefetch_dispatch1_safe_w;
  wire branch_prefetch_dispatch_attempt_w;
  wire branch_prefetch_dispatch_buffer_w;
  wire branch_prefetch_dispatch_fire_w;
  wire branch_prefetch_dispatch_rsp_w;
  wire [`INST_W-1:0] branch_prefetch_hit_inst0_w;
  wire [`INST_W-1:0] branch_prefetch_hit_inst1_w;
  wire [`XLEN-1:0] branch_prefetch_hit_next_pc0_w;
  wire [`XLEN-1:0] branch_prefetch_hit_next_pc1_w;
  wire [`XLEN-1:0] branch_prefetch_hit_packet_next_pc_w;
  wire [`XLEN-1:0] branch_prefetch_hit_pc0_w;
  wire [`XLEN-1:0] branch_prefetch_hit_pc1_w;
  wire [1:0] branch_prefetch_hit_resp0_w;
  wire [1:0] branch_prefetch_hit_resp1_w;
  wire branch_prefetch_hit_to_fifo_w;
  wire branch_prefetch_match_w;
  wire [`XLEN-1:0] branch_prefetch_pc_q;
  wire branch_prefetch_pending_match_w;
  wire [`XLEN-1:0] branch_prefetch_req_pc_w;
  wire branch_prefetch_req_valid_w;
  wire branch_prefetch_rsp_dispatch0_safe_w;
  wire branch_prefetch_rsp_dispatch1_safe_w;
  wire branch_prefetch_rsp_raw_match_w;
  wire branch_resolve_pending_pc_match_w;
  wire [`XLEN-1:0] branch_spec_pred_pc_q;
  wire branch_target_append_attempt_w;
  wire branch_target_append_candidate_w;
  wire branch_target_append_w;
  wire [`INST_W-1:0] branch_target_cache_inst_w;
  wire [`XLEN-1:0] branch_target_cache_next_pc_w;
  wire [`XLEN-1:0] branch_target_cache_target_pc_w;
  wire branch_target_dispatch_w;
  wire can_issue_request_w;
  wire direct_branch1_dispatch_valid_w;
  wire [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx_w;
  wire direct_branch_bht_valid_w;
  wire direct_branch_fire_w;
  wire [`XLEN-1:0] direct_branch_imm_w;
  wire [`XLEN-1:0] direct_branch_next_pc_w;
  wire [`XLEN-1:0] direct_branch_pc_w;
  wire [`XLEN-1:0] direct_branch_pred_pc_w;
  wire direct_branch_predict_taken_w;
  wire direct_branch_resolve_misaligned_w;
  wire direct_branch_resolve_taken_w;
  wire direct_branch_resolve_valid_w;
  wire [`XLEN-1:0] direct_branch_target_w;
  wire [`XLEN-1:0] direct_branch_wait_pc_q;
  wire direct_branch_wait_q;
  wire direct_branch_wait_resolve_match_w;
  wire direct_branch_wait_untracked_w;
  wire direct_fetch_drop_w;
  wire direct_jal0_call_w;
  wire direct_jal0_fire_w;
  wire direct_jal1_call_w;
  wire direct_jal1_fire_w;
  wire direct_jal_call_raw_w;
  wire direct_jal_call_unsafe_w;
  wire direct_jal_fire_w;
  wire [`XLEN-1:0] direct_jal_link_w;
  wire [`XLEN-1:0] direct_jal_target_w;
  wire direct_ret0_dispatch_valid_w;
  wire [`XLEN-1:0] direct_ret_target_w;
  wire dispatch0_ebreak_w;
  wire dispatch0_ecall_w;
  wire dispatch1_control_unsupported_w;
  wire dispatch1_direct_jal_w;
  wire dispatch1_mem_unsupported_w;
  wire dispatch1_return_w;
  wire fetch_dec0_control_stop_w;
  wire [`INST_W-1:0] fetch_dec0_inst_w;
  wire [`XLEN-1:0] fetch_dec0_next_pc_w;
  wire [`XLEN-1:0] fetch_dec0_pc_w;
  wire [1:0] fetch_dec0_resp_w;
  wire fetch_dec1_control_stop_w;
  wire [`INST_W-1:0] fetch_dec1_inst_w;
  wire [`XLEN-1:0] fetch_dec1_next_pc_w;
  wire [`XLEN-1:0] fetch_dec1_pc_w;
  wire [1:0] fetch_dec1_resp_w;
  wire fetch_request_blocked_by_trap_w;
  wire fetch_rsp_can_drop_w;
  wire fetch_rsp_can_enqueue_w;
  wire fetch_rsp_control_stop_w;
  wire fetch_rsp_dispatch_bypass_w;
  wire [`XLEN-1:0] fetch_rsp_packet_next_pc_w;
  wire fifo_can_accept_rsp_w;
  wire fifo_clear_w;
  wire [FETCH_COUNT_W-1:0] fifo_count_q;
  wire fifo_empty_storage_w;
  wire [`INST_W-1:0] fifo_head_inst0_w;
  wire [`INST_W-1:0] fifo_head_inst1_w;
  wire [`XLEN-1:0] fifo_head_next_pc0_w;
  wire [`XLEN-1:0] fifo_head_next_pc1_w;
  wire [`XLEN-1:0] fifo_head_packet_next_pc_w;
  wire [`XLEN-1:0] fifo_head_pc0_w;
  wire [`XLEN-1:0] fifo_head_pc1_w;
  wire [`XLEN-1:0] fifo_head1_pc0_w;
  wire [1:0] fifo_head_resp0_w;
  wire [1:0] fifo_head_resp1_w;
  wire fifo_pop_w;
  wire fifo_reserve_available_w;
  wire [`INST_W-1:0] fifo_seed_inst0_w;
  wire [`INST_W-1:0] fifo_seed_inst1_w;
  wire [`XLEN-1:0] fifo_seed_next_pc0_w;
  wire [`XLEN-1:0] fifo_seed_next_pc1_w;
  wire [`XLEN-1:0] fifo_seed_packet_next_pc_w;
  wire [`XLEN-1:0] fifo_seed_pc0_w;
  wire [`XLEN-1:0] fifo_seed_pc1_w;
  wire [1:0] fifo_seed_resp0_w;
  wire [1:0] fifo_seed_resp1_w;
  wire fifo_seed_valid_w;
  wire fifo_storage_head_valid_w;
  wire fifo_storage_pop_w;
  wire frontend_dispatch_to_backend_valid_w;
  wire [`BPU_BHT_INDEX_W-1:0] head0_branch_bht_idx_w;
  wire head0_branch_bht_valid_w;
  wire head0_branch_pred_taken_w;
  wire head0_branch_predict_strong_w;
  wire head0_branch_raw_w;
  wire [`XLEN-1:0] head0_branch_target_w;
  wire head0_ebreak_raw_w;
  wire head0_exit_raw_w;
  wire head0_fp_addsub_raw_w;
  wire head0_fp_class_raw_w;
  wire head0_fp_compare_raw_w;
  wire head0_fp_convert_to_fpr_raw_w;
  wire head0_fp_convert_to_gpr_raw_w;
  wire head0_fp_disabled_w;
  wire head0_fp_div_raw_w;
  wire head0_fp_enabled_w;
  wire head0_fp_fma_raw_w;
  wire head0_fp_minmax_raw_w;
  wire head0_fp_move_to_fpr_raw_w;
  wire head0_fp_move_to_gpr_raw_w;
  wire head0_fp_mul_raw_w;
  wire head0_fp_double_w;
  wire head0_fp_gpr_write_w;
  wire head0_fp_load_raw_w;
  wire head0_fp_store_raw_w;
  wire head1_fp_double_w;
  wire head1_fp_enabled_w;
  wire head1_fp_gpr_write_w;
  wire head1_fp_load_raw_w;
  wire head1_fp_store_raw_w;
  wire head0_fp_raw_w;
  wire head0_fp_sgnj_raw_w;
  wire head0_fp_sqrt_raw_w;
  wire head0_illegal_raw_w;
  wire [`XLEN-1:0] head0_imm_w;
  wire head0_jal_call_raw_w;
  wire head0_jal_raw_w;
  wire head0_jalr_raw_w;
  wire head0_jump_raw_w;
  wire head0_mem_raw_w;
  wire head0_mret_raw_w;
  wire head0_priv_system_illegal_w;
  wire [`REG_ADDR_W-1:0] head0_rs1_w;
  wire [`REG_ADDR_W-1:0] head0_rs2_w;
  wire head0_semihost_ebreak_w;
  wire head0_sret_raw_w;
  wire head1_arch_trap_raw_w;
  wire [`BPU_BHT_INDEX_W-1:0] head1_branch_bht_idx_w;
  wire head1_branch_bht_valid_w;
  wire head1_branch_pred_taken_w;
  wire head1_branch_predict_strong_w;
  wire head1_branch_raw_w;
  wire head1_ebreak_raw_w;
  wire head1_exit_raw_w;
  wire head1_fp_addsub_raw_w;
  wire head1_fp_class_raw_w;
  wire head1_fp_compare_raw_w;
  wire head1_fp_convert_to_fpr_raw_w;
  wire head1_fp_convert_to_gpr_raw_w;
  wire head1_fp_disabled_w;
  wire head1_fp_div_raw_w;
  wire head1_fp_fma_raw_w;
  wire head1_fp_minmax_raw_w;
  wire head1_fp_move_to_fpr_raw_w;
  wire head1_fp_move_to_gpr_raw_w;
  wire head1_fp_mul_raw_w;
  wire head1_fp_raw_w;
  wire head1_fp_sgnj_raw_w;
  wire head1_fp_sqrt_raw_w;
  wire head1_illegal_raw_w;
  wire [`XLEN-1:0] head1_imm_w;
  wire head1_jal_call_raw_w;
  wire head1_jal_raw_w;
  wire head1_jalr_raw_w;
  wire head1_jump_raw_w;
  wire head1_mret_raw_w;
  wire head1_priv_system_illegal_w;
  wire head1_return_candidate_w;
  wire [`REG_ADDR_W-1:0] head1_rs1_w;
  wire [`REG_ADDR_W-1:0] head1_rs2_w;
  wire head1_semihost_ebreak_w;
  wire head1_sret_raw_w;
  wire head1_system_raw_w;
  wire [`INST_W-1:0] jalr_prefetch_hit_inst0_w;
  wire [`INST_W-1:0] jalr_prefetch_hit_inst1_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_next_pc0_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_next_pc1_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_packet_next_pc_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_pc0_w;
  wire [`XLEN-1:0] jalr_prefetch_hit_pc1_w;
  wire [1:0] jalr_prefetch_hit_resp0_w;
  wire [1:0] jalr_prefetch_hit_resp1_w;
  wire jalr_prefetch_pending_match_w;
  wire lane0_before_ret_safe_w;
  wire lane1_barrier_dispatch0_valid_w;
  wire [FETCH_COUNT_W-1:0] outstanding_count_w;
  wire [`BPU_BHT_INDEX_W-1:0] pending_branch_bht_idx_q;
  wire [`XLEN-1:0] pending_branch_fallthrough_w;
  wire [`XLEN-1:0] pending_branch_imm_q;
  wire [`XLEN-1:0] pending_branch_next_pc_q;
  wire pending_branch_pred_taken_q;
  wire pending_jump_call_w;
  wire [`XLEN-1:0] pending_jump_next_pc_q;
  wire pending_jump_return_w;
  wire [`XLEN-1:0] pending_jump_target_q;
  wire ras_clear_w;
  wire ras_direct_update_safe_w;
  wire ras_pop_w;
  wire [`XLEN-1:0] ras_push_value_w;
  wire ras_push_w;
  wire ras_reliable_q;
  wire [`XLEN-1:0] ras_top_w;
  wire [`XLEN-1:0] redirect_fetch_pc_w;
  wire return_cont_attempt_w;
  wire return_cont_capture_w;
  wire return_cont_dispatch_w;
  wire [`INST_W-1:0] return_cont_inst_q;
  wire return_cont_match_w;
  wire [`XLEN-1:0] return_cont_next_pc_q;
  wire return_cont_optional_w;
  wire [`XLEN-1:0] return_cont_pc_q;
  wire return_cont_safe_w;
  wire return_cont_uop_safe_w;
  wire return_cont_valid_q;
  wire stop_head_w;
  wire dbranch_dispatch_fire_w;  // domain-A: head0 分支普通 dispatch fire(FIFO pop 源)
  wire stop_pending_busy_w;


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
    .frm_i(csr_frm_w),
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


  OooFrontendDispatchGate u_frontend_dispatch_gate (
    .dispatch_valid_i(dispatch_valid_w),
    .head0_branch_pred_taken_i(head0_branch_pred_taken_w),
    .head1_branch_pred_taken_i(head1_branch_pred_taken_w),
    .dispatch0_exit_i(dispatch0_exit_w),
    .dispatch0_arch_trap_i(dispatch0_arch_trap_w),
    .dispatch0_system_i(dispatch0_system_w),
    .dispatch0_fp_i(dispatch0_fp_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .dispatch0_jump_i(dispatch0_jump_w),
    .dispatch0_return_i(dispatch0_return_w),
    .dispatch0_unsupported_i(dispatch0_unsupported_w),
    .dispatch1_unsupported_i(dispatch1_unsupported_w),
    .dispatch0_unsupported_raw_i(dispatch0_unsupported_raw_w),
    .dispatch1_unsupported_raw_i(dispatch1_unsupported_raw_w),
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
    .frontend_dispatch_to_backend_valid_o(
        frontend_dispatch_to_backend_valid_w),
    .lane1_barrier_dispatch0_valid_o(lane1_barrier_dispatch0_valid_w),
    .direct_jal0_fire_o(direct_jal0_fire_w),
    .direct_jal1_fire_o(direct_jal1_fire_w),
    .direct_ret1_fire_o(direct_ret1_fire_w),
    .direct_branch1_fire_o(direct_branch1_fire_w),
    .dbranch_dispatch_fire_o(dbranch_dispatch_fire_w),
    .dbranch_dual_go_o(dbranch_dual_go_w)
  );


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


  OooDirectControlFlowGate #(
    .ENABLE_DIRECT_RAS_RET(ENABLE_DIRECT_RAS_RET)
  ) u_direct_control_flow_gate (
    .dispatch0_branch_i(dispatch0_branch_w),
    .dbranch_dual_go_i(dbranch_dual_go_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .dispatch0_return_i(dispatch0_return_w),
    .dispatch0_unsupported_i(dispatch0_unsupported_w),
    .dispatch0_ready_i(dispatch0_ready_w),
    .direct_jal0_fire_i(direct_jal0_fire_w),
    .direct_jal1_fire_i(direct_jal1_fire_w),
    .head0_pc_i(head_pc_w),
    .head1_pc_i(head_pc1_w),
    .head0_imm_i(head0_imm_w),
    .head1_imm_i(head1_imm_w),
    .head0_next_pc_i(head_next_pc0_w),
    .head1_next_pc_i(head_next_pc1_w),
    .head0_rd_i(head0_rd_unused_w),
    .head1_rd_i(head1_rd_unused_w),
    .ras_top_i(ras_top_w),
    .ras_direct_update_safe_i(ras_direct_update_safe_w),
    .head_fetch_fault1_i(head_fetch_fault1_w),
    .return_cont_uop_safe_i(return_cont_uop_safe_w),
    .return_cont_valid_i(return_cont_valid_q),
    .return_cont_pc_i(return_cont_pc_q),
    .direct_branch0_fire_o(direct_branch0_fire_w),
    .direct_jal0_dispatch_valid_o(direct_jal0_dispatch_valid_w),
    .direct_jal_fire_o(direct_jal_fire_w),
    .direct_ret0_dispatch_valid_o(direct_ret0_dispatch_valid_w),
    .direct_ret0_fire_o(direct_ret0_fire_w),
    .direct_jal_target_o(direct_jal_target_w),
    .direct_ret_target_o(direct_ret_target_w),
    .direct_jal0_call_o(direct_jal0_call_w),
    .direct_jal1_call_o(direct_jal1_call_w),
    .direct_jal_call_raw_o(direct_jal_call_raw_w),
    .direct_jal_call_o(direct_jal_call_w),
    .direct_jal_call_unsafe_o(direct_jal_call_unsafe_w),
    .direct_jal_link_o(direct_jal_link_w),
    .return_cont_safe_o(return_cont_safe_w),
    .return_cont_capture_o(return_cont_capture_w),
    .return_cont_match_o(return_cont_match_w)
  );


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


  // ================= 前端 prefetch / BTC / JALR-BTB / return-cont 死硅拆除后的行为中性 tie-off =================
  // 依据 rtl-ground-truth-2026-07-03.md §4 + report-1：这些结构在 OOO_ROB_WALK_MODE=1'b1 /
  // OOO_DBRANCH_DOMAIN_A=1'b1 下由编译常量证死——branch prefetch req 依赖 pending_branch(恒0)/jalr_btb_hit(恒0)；
  // BTC capture 依赖 direct_branch_resolve_taken(恒0) → 恒空 → hit 恒0，且消费端 BRANCH_APPEND_DISPATCH_ENABLE=1'b0；
  // JALR BTB update 依赖 pending_jump(恒0) → 表恒空 → 查询恒 miss；return_cont consume 依赖 return_cont_attempt=1'b0。
  // 全部消费端落在恒0谓词门后（FetchRequestMux/FetchFlowControl/SeedMux/BackendDispatchMux/ResolveRecoveryGate/
  // AppendDispatchGate/OutstandingSequencer/DirectControlFlowGate 均在对应 valid/attempt/hit=0 时不选该 payload），
  // 故以下常量替换对每拍 cycle 行为逐位中性。原模块实例 + TB + filelist 引用已删。

  // pending 分支目标：原 OooBranchPrefetchSourceGate 顺带算出，供仍保留的 pending 控制链消费 → 就地内联保持等价
  assign pending_branch_target_w = pending_branch_pc_q + pending_branch_imm_q;

  // OooBranchPrefetchRequestGate（req_valid 恒0）
  assign branch_prefetch_req_valid_w = 1'b0;
  assign branch_prefetch_req_fire_w  = 1'b0;
  assign branch_prefetch_req_pc_w    = {`XLEN{1'b0}};

  // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0）
  assign branch_prefetch_match_w         = 1'b0;
  assign branch_prefetch_buffer_match_w  = 1'b0;
  assign branch_prefetch_pending_match_w = 1'b0;
  assign branch_prefetch_hit_available_w = 1'b0;

  // branch prefetch hit-mux payload（rsp_select 恒0 → don't-care）
  assign branch_prefetch_hit_pc0_w            = {`XLEN{1'b0}};
  assign branch_prefetch_hit_pc1_w            = {`XLEN{1'b0}};
  assign branch_prefetch_hit_next_pc0_w       = {`XLEN{1'b0}};
  assign branch_prefetch_hit_next_pc1_w       = {`XLEN{1'b0}};
  assign branch_prefetch_hit_packet_next_pc_w = {`XLEN{1'b0}};
  assign branch_prefetch_hit_inst0_w          = {`INST_W{1'b0}};
  assign branch_prefetch_hit_inst1_w          = {`INST_W{1'b0}};
  assign branch_prefetch_hit_resp0_w          = 2'b00;
  assign branch_prefetch_hit_resp1_w          = 2'b00;

  // OooBranchPrefetchBuffer（req_fire/rsp_capture 恒0 → 恒复位 0）
  assign branch_prefetch_active_q       = 1'b0;
  assign branch_prefetch_buffer_valid_q = 1'b0;
  assign branch_prefetch_pc_q           = {`XLEN{1'b0}};
  assign branch_prefetch_buf_pc0_q      = {`XLEN{1'b0}};
  assign branch_prefetch_buf_pc1_q      = {`XLEN{1'b0}};
  assign branch_prefetch_buf_next_pc0_q = {`XLEN{1'b0}};
  assign branch_prefetch_buf_next_pc1_q = {`XLEN{1'b0}};
  assign branch_prefetch_buf_inst0_q    = {`INST_W{1'b0}};
  assign branch_prefetch_buf_inst1_q    = {`INST_W{1'b0}};

  // prefetch dispatch 安全谓词（消费端 BRANCH_PREFETCH_DISPATCH_ENABLE=1'b0 → don't-care）
  assign branch_prefetch_dispatch0_safe_w     = 1'b0;
  assign branch_prefetch_dispatch1_safe_w     = 1'b0;
  assign branch_prefetch_rsp_dispatch0_safe_w = 1'b0;
  assign branch_prefetch_rsp_dispatch1_safe_w = 1'b0;

  // OooJalrPrefetchStatusGate + jalr prefetch hit-mux
  assign jalr_prefetch_hit_available_w = 1'b0;
  assign jalr_prefetch_pending_match_w = 1'b0;
  assign jalr_prefetch_hit_pc0_w            = {`XLEN{1'b0}};
  assign jalr_prefetch_hit_pc1_w            = {`XLEN{1'b0}};
  assign jalr_prefetch_hit_next_pc0_w       = {`XLEN{1'b0}};
  assign jalr_prefetch_hit_next_pc1_w       = {`XLEN{1'b0}};
  assign jalr_prefetch_hit_packet_next_pc_w = {`XLEN{1'b0}};
  assign jalr_prefetch_hit_inst0_w          = {`INST_W{1'b0}};
  assign jalr_prefetch_hit_inst1_w          = {`INST_W{1'b0}};
  assign jalr_prefetch_hit_resp0_w          = 2'b00;
  assign jalr_prefetch_hit_resp1_w          = 2'b00;

  // OooJalrBtb（表恒空 → hit 恒0）
  assign pending_jump_jalr_btb_hit_w = 1'b0;

  // OooBranchTargetCache（capture 恒0 → hit 恒0；payload don't-care）
  assign branch_target_cache_hit_w       = 1'b0;
  assign branch_target_cache_target_pc_w = {`XLEN{1'b0}};
  assign branch_target_cache_next_pc_w   = {`XLEN{1'b0}};
  assign branch_target_cache_inst_w      = {`INST_W{1'b0}};

  // OooReturnContBuffer（consume 恒0；下游 return_cont_attempt/dispatch 恒0 → 全 gate 0）
  assign return_cont_valid_q   = 1'b0;
  assign return_cont_pc_q      = {`XLEN{1'b0}};
  assign return_cont_next_pc_q = {`XLEN{1'b0}};
  assign return_cont_inst_q    = {`INST_W{1'b0}};

  // prefetch/BTC 包解码残留字段（原 4 个 DecodeStage，仅进 glue unused-sink OR）
  assign branch_target_capture_ctrl_w       = {`CTRL_BUS_W{1'b0}};
  assign branch_target_capture_rs1_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_target_capture_rs2_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_target_capture_rd_unused_w  = {`REG_ADDR_W{1'b0}};
  assign branch_target_capture_imm_unused_w = {`XLEN{1'b0}};
  assign branch_prefetch0_rs1_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch0_rs2_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch0_rd_unused_w  = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch0_imm_unused_w = {`XLEN{1'b0}};
  assign branch_prefetch1_rs1_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch1_rs2_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch1_rd_unused_w  = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch1_imm_unused_w = {`XLEN{1'b0}};
  assign branch_prefetch_rsp1_rs1_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch_rsp1_rs2_unused_w = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch_rsp1_rd_unused_w  = {`REG_ADDR_W{1'b0}};
  assign branch_prefetch_rsp1_imm_unused_w = {`XLEN{1'b0}};
  // ==================================================================================================

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
    .core_branch_resolve_mispredict_i(core_branch_resolve_mispredict_w),
    .trap_redirect_squash_i(trap_redirect_squash_q),
    .execute0_valid_i(execute0_valid_unused_w),
    .execute1_valid_i(execute1_valid_unused_w),
    .mem_rsp_ready_i(mem_rsp_ready_o),
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
    .direct_jump_spec_fire_i(direct_jump_spec_fire_w),
    .direct_jump_spec_target_i(jalr_spec_pred_target_w),
    .direct_redirect_fetch_o(direct_redirect_fetch_w),
    .redirect_fetch_req_valid_o(redirect_fetch_req_valid_w),
    .redirect_fetch_pc_o(redirect_fetch_pc_w),
    .fetch_req_pc_o(fetch_req_pc_o)
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
    .dbranch_dispatch_fire_i(dbranch_dispatch_fire_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .direct_jal0_fire_i(direct_jal0_fire_w),
    .direct_jump_spec_fire_i(direct_jump_spec_fire_w),
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



  // ===== B2: dispatch 期非返回 JALR 投机续取（mode=1）=====
  // 让前端在遇到非返回 JALR 时不再等 pending_jump，而是用 RAS/BTB 预测目标立即续取；
  // 预测错由后端 per-JALR mispredict → ROB-walk + redirect 修正（片2/片4）。
  // 用 lane0 实际 fire（core_dispatch0_fire_w）触发投机续取，而非 dual-issue 的 dispatch_fire_w
  // （后者 lane1_base 含 !jump，JALR head 时恒 0 → 之前 JALR 既不续取也未 present，dispatch 卡死）。
  wire direct_jump_spec_start_w =
      direct_branch_spec_start_w && core_dispatch0_fire_w &&
      dispatch0_jump_w && !dispatch0_return_w;
  wire jalr_spec_ret_hint_w =
      head0_jalr_raw_w && (head0_rd_unused_w == {`REG_ADDR_W{1'b0}}) &&
      ((head0_rs1_w == 5'd1) || (head0_rs1_w == 5'd5)) &&
      (head0_imm_w == {`XLEN{1'b0}});
  wire jalr_spec_use_ras_w = jalr_spec_ret_hint_w && !ras_empty_w;
  wire jalr_spec_btb_hit_w = 1'b0;   // JALR-BTB 表恒空 → spec 查询恒 miss（死硅拆除 tie-off）
  wire [`XLEN-1:0] jalr_spec_btb_target_w = {`XLEN{1'b0}};  // 上同，miss 时 don't-care
  // 预测目标优先级：return-hint→RAS top；否则 BTB hit→BTB target；兜底=fallthrough(pc+ilen)。
  wire [`XLEN-1:0] jalr_spec_pred_target_w =
      jalr_spec_use_ras_w ? ras_top_w :
      jalr_spec_btb_hit_w ? jalr_spec_btb_target_w :
                            head_next_pc0_w;
  wire direct_jump_spec_fire_w = direct_jump_spec_start_w;







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
    .head1_pc0_o(fifo_head1_pc0_w),
    .count_o(fifo_count_q)
  );

  // B2: head packet 的「预测后继 PC」= 下一条 FIFO entry 的 pc0（前端按预测序取指，故 next entry 即预测后继）。
  // count>=2：next entry 正确且 loop-free。count==1：退回寄存 next_fetch_pc_q（前沿==head 后继，正确）。
  // 【已知遗留】count==0 bypass：next_fetch_pc_q 当拍尚未从本 packet pc 更新到后继 → pred 滞后指向本 packet 自身，
  //   使 bypass 的 predicted-taken 分支被判 mis 错误。正解=用「前端-only 的组合下一取指 PC」(去掉后端 redirect 项
  //   以免与 backend mispredict 成组合环)，待续。fetch_req_pc_o 含后端 redirect 不可直接用(UNOPTFLAT)。
  // head packet 的「预测后继 PC」= pred_npc 源。count>=2：下一条 FIFO entry pc0（前端按预测序取指，正确）。
  // count<2(含 bypass)：暂用寄存 next_fetch_pc_q——它滞后指向 head 自身 → 每分支伪 mispredict 但 redirect 恒指向
  //   架构后继（功能正确/慢），比「组合精确重建前端预测」更鲁棒（后者须逐 case 与前端实际取指一致，易漏）。
  // pred_npc 源:count>=2 用下一条 FIFO entry 的 pc0(=前端实际取指的下一包首 PC,含预测-taken
  //   重定向,正确);count<2 暂用寄存 next_fetch_pc_q(滞后,F2 count<2 缺口)。
  //   注意:packet_next_pc 是 fall-through(顺序后继),不含 taken 预测,故不能直接当 pred_npc。
  // 【F2·domain-A 哨兵版】pred_npc 语义 = 前端实际取指后继。domain-A 下前端对分支不再
  //   按 BHT 重定向(direct fire 关闭), 实际后继恒为顺序流: count>=2 时 = 下一 FIFO 包 pc0
  //   (真值, 可比对→not-taken 分支免 redirect); count<2 时下一包尚未取回、后继未知 →
  //   给非法哨兵值 64'h1(指令地址至少 2 对齐, 恒不等于任何架构 next_pc)→必判 mispredict
  //   →安全 redirect。取代旧 next_fetch_pc_q 滞后近似(其值可能凑巧等于 next_pc → 漏判
  //   wrong-path, 即 #105 旧 46/88 的根因)。
  // pred_npc 源(F2 foundation, 强制项下不生效): count>=2 = 下一 FIFO 包 pc0;
  // count<2 = 64'h1 哨兵(恒 mispredict 兜底, 取代旧 next_fetch_pc_q 滞后近似)。
  wire [`XLEN-1:0] head_pred_succ_w =
      (fifo_count_q >= {{(FETCH_COUNT_W-2){1'b0}}, 2'd2}) ? fifo_head1_pc0_w
                                                          : 64'h1;

  // ===== 【F2 单源化】本拍 direct fire 的实际重取目标 =====
  // 与 OooFetchPcOutstandingSequencer 的 next_fetch 更新共享同一 wire(该模块的内部
  // 重复 mux 已删), dispatch pred_npc 的 fired-控制流臂也取它——pred 与实际取指
  // 机械同源, 结构性消灭 #105 障碍②(拍内解析/spec 臂不同源错配)族。臂序保持
  // 原 OutstandingSequencer 优先级: jal > ret > branch(lane1_ret > target > fallthrough
  // > 拍内解析 > spec > 顺序) > jump_spec。
  wire dbranch_dual_go_w;
  wire [`XLEN-1:0] direct_fire_succ_w =
      direct_jal_fire_w ? direct_jal_target_w :
      (direct_ret0_fire_w || direct_ret1_fire_w) ? direct_ret_target_w :
      direct_branch_fire_w ? (
          direct_branch0_lane1_ret_w ?
              (return_cont_dispatch_w ? return_cont_next_pc_q : ras_top_w) :
          branch_target_dispatch_w ? branch_target_cache_next_pc_w :
          branch_fallthrough_dispatch_w ? head_next_pc1_w :
          direct_branch_resolve_redirect_w ? direct_branch_resolve_next_pc_w :
          direct_branch_spec_start_w ? direct_branch_pred_pc_w :
          (direct_branch1_fire_w ? head_next_pc1_w : head_next_pc0_w)) :
      direct_jump_spec_fire_w ? jalr_spec_pred_target_w :
      head_pred_succ_w;
  wire d0_ctrlflow_fired_w =
      direct_jal0_fire_w || direct_ret0_fire_w || direct_branch0_fire_w ||
      direct_jump_spec_fire_w;
  wire d1_ctrlflow_fired_w =
      direct_jal1_fire_w || direct_ret1_fire_w || direct_branch1_fire_w;
  // solo 分支(taken/!dual)与非返回 JALR 拍禁 d1 影子(谓词无 ready, 不与 pair-ready 成环)
  wire dispatch1_squash_w =
      (dispatch0_branch_w && !dbranch_dual_go_w) ||
      (dispatch0_jump_w && !dispatch0_return_w);

  // 【F2】dispatch 载荷: BHT 查询快照直通(prefetch/pending 臂非分支, 后端只在
  // is_branch 时消费, 载荷错位无害)
  assign core_dispatch0_bht_idx_w = head0_branch_bht_idx_w;
  assign core_dispatch0_pred_taken_w = head0_branch_pred_taken_w;
  assign core_dispatch1_bht_idx_w = head1_branch_bht_idx_w;
  assign core_dispatch1_pred_taken_w = head1_branch_pred_taken_w;


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
    .resolve_update_valid_i(core_branch_resolve_valid_w &&
                            core_branch_resolve_is_branch_w),
    .resolve_update_taken_i(core_branch_resolve_taken_w),
    .resolve_update_pred_taken_i(core_branch_resolve_pred_taken_w),
    .resolve_update_pc_i(core_branch_resolve_pc_w),
    .resolve_update_bht_idx_i(core_branch_resolve_bht_idx_w),
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
    .return_cont_attempt_i(return_cont_attempt_w),
    .branch_target_append_attempt_i(branch_target_append_attempt_w),
    .branch_fallthrough_append_attempt_i(branch_fallthrough_append_attempt_w),
    .direct_jal1_fire_i(direct_jal1_fire_w),
    .direct_ret1_fire_i(direct_ret1_fire_w),
    .dispatch0_ready_i(dispatch0_ready_w),
    .dispatch1_ready_i(dispatch1_ready_w),
    .dispatch1_squash_i(dispatch1_squash_w),
    .d0_ctrlflow_fired_i(d0_ctrlflow_fired_w),
    .d1_ctrlflow_fired_i(d1_ctrlflow_fired_w),
    .direct_fire_succ_i(direct_fire_succ_w),
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
    .head_pc0_i(head_pc_w),
    .head_next_pc0_i(head_next_pc0_w),
    .head_inst0_i(head_inst0_w),
    .head_pc1_i(head_pc1_w),
    .head_next_pc1_i(head_next_pc1_w),
    .head_inst1_i(head_inst1_w),
    .next_fetch_pc_i(head_pred_succ_w),
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
    .core_dispatch0_pc_o(core_dispatch0_pc_w),
    .core_dispatch0_next_pc_o(core_dispatch0_next_pc_w),
    .core_dispatch0_inst_o(core_dispatch0_inst_w),
    .core_dispatch0_csr_rdata_o(core_dispatch0_csr_rdata_w),
    .core_dispatch1_pc_o(core_dispatch1_pc_w),
    .core_dispatch1_next_pc_o(core_dispatch1_next_pc_w),
    .core_dispatch1_inst_o(core_dispatch1_inst_w),
    .core_dispatch0_pred_npc_o(core_dispatch0_pred_npc_w),
    .core_dispatch1_pred_npc_o(core_dispatch1_pred_npc_w)
  );


  OooBackendDrainTracker u_backend_drain_tracker (
    .clk(clk),
    .rst(rst || flush_i),
    .backend_empty_i(backend_drained_w),
    .dispatch_fire_i(core_dispatch0_fire_w),
    .force_drained_i(csr_trap_mem_valid_w),
    .drained_o(backend_drained_q)
  );

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
      .fetch_req_pc_i(fetch_req_pc_o),
      .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
      .csr_trap_target_i(csr_trap_target_w),
      .csr_ret_target_i(csr_ret_target_w),
      .direct_frontend_flush_i(direct_frontend_flush_w),
      .branch_fallthrough_keep_outstanding_i(branch_fallthrough_keep_outstanding_w),
      .direct_jal_fire_i(direct_jal_fire_w),
      .direct_ret_fire_i(direct_ret0_fire_w || direct_ret1_fire_w),
      .direct_branch_fire_i(direct_branch0_fire_w || direct_branch1_fire_w),
      .branch_fallthrough_capture_rsp_i(branch_fallthrough_capture_rsp_w),
      .direct_jump_spec_fire_i(direct_jump_spec_fire_w),
      .direct_fire_succ_i(direct_fire_succ_w),
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



`ifdef ROB_WALK_DEBUG
  // 单行对照表：jump(含 jalr) 在 head 时，把 dispatch 链上下游信号排在同一时间轴一行，便于定位卡点。
  reg [15:0] fe_dbg_cnt;
  always @(posedge clk) begin
    if (rst) fe_dbg_cnt <= 16'd0;
    else if (dispatch0_jump_w) begin
      fe_dbg_cnt <= fe_dbg_cnt + 16'd1;
      if (fe_dbg_cnt < 16'd24)
        $display("[FE] hpc=%h jmp=%b ret=%b d0v=%b d0f=%b dfire=%b jdv=%b jdf=%b jspecS=%b jspecF=%b canrun=%b fifo=%0d out=%b stoph=%b",
                 head_pc_w, dispatch0_jump_w, dispatch0_return_w, core_dispatch0_valid_w, core_dispatch0_fire_w, dispatch_fire_w,
                 jump_dispatch_valid_w, jump_dispatch_fire_w, direct_jump_spec_start_w, direct_jump_spec_fire_w, can_run_w, fifo_count_q, outstanding_valid_q, stop_head_w);
    end
  end
`endif


  // 【B-FP 簇】pending-FP capture 已拆, head facts 细分类仅存 facts 总线消费
  wire frontend_fp_facts_unused_w =
      head0_fp_double_w | head0_fp_gpr_write_w | head0_fp_load_raw_w |
      head0_fp_store_raw_w | head1_fp_double_w | head1_fp_enabled_w |
      head1_fp_gpr_write_w | head1_fp_load_raw_w | head1_fp_store_raw_w;

endmodule
