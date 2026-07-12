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
  // [wave5b 死硅拆除] pending_branch/jump capture+clear 输入口(direct/head0/lane1/clear ×branch,
  // head0/lane1/clear ×jump) 已删——上游 OooPendingDispatchArbiter 对应 capture 臂随本波删除。
  input pending_branch_commit_resolve_w,
  input pending_branch_match_clear_w,
  input pending_branch_taken_w,
  input pending_exit_q,
  input [`XLEN-1:0] pending_jump_rs1_data_w,
  // pending_mem 全链已删除；下述二信号仅供活的 fetch/run 端 sensor 读取（恒 0，父模块 tie-off）。
  input [`XLEN-1:0] pending_mem_next_pc_q,
  input pending_mem_q,
  input pending_mem_resolve_ready_w,
  input pending_system_csr_commit_w,
  // 【serialize Phase1】head0-CSR 队头提交拍 redirect: 脉冲 + CSR 的架构下条 PC(core_commit0_next_pc)。
  input head0_csr_commit_w,
  input [`XLEN-1:0] core_commit0_next_pc_w,
  // 【serialize Phase1 §4#1】head0-CSR 队头化: 只放行【合法】CSR 进 ROB(非法 CSR 如 S-mode 无 counteren 的
  // rdtime 仍走 stop→drain→csr_illegal arch-trap)。故需 head0_csr_illegal 在 dispatch 侧区分。
  input head0_csr_illegal_i,
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
  // 【P4 切消费点】统一 redirect 年龄律仲裁(OooRedirectArbiter 生产实例在本模块内):
  // ROB 队头指针(年龄基准+trap 口 rob_idx)与后端 resolve 分支 rob_idx(branch 口年龄)。
  input [`OOO_ROB_INDEX_W-1:0] rob_head_idx_i,
  input [`OOO_ROB_INDEX_W-1:0] core_branch_resolve_rob_idx_i,
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
  output head0_csr_inflight_w,   // 【serialize Phase1 §10.4】head0-CSR 在飞(→保持 stop_pending 阻 younger 越序捕获)
  output head0_csr_raw_w,
  output [`CTRL_BUS_W-1:0] head0_ctrl_w,
  output head0_ecall_raw_w,
  output [`OOO_SLOT_FACTS_W-1:0] head0_facts_w,
  output [`REG_ADDR_W-1:0] head0_rd_unused_w,
  output head0_sfence_raw_w,
  output head0_fencei_raw_w,
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
  output head1_fencei_raw_w,
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
  // [wave5b 死硅拆除] branch_bpu_commit/direct/drained/pending/pending_like_update_w 已删（旧四臂）
  wire branch_bpu_pending0_capture_w;
  wire branch_bpu_pending1_capture_w;
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
  // 【B2 S1】resp 拍(判决/enqueue 拍)BPU lookup: 分支识别+B-imm 从 PacketDecode
  // 组合出, BPU lookup 输入随之前移; 预测结果(pred_taken/bht_idx/bht_valid)当拍
  // 随包写入 FIFO——预测一次定格, dispatch 拍只消费存储位(head0/1_branch_* 改由
  // HeadMux 存储位驱动, BPU 的 head 拍活查询口物理断开=F2 #105 家族免疫)。
  wire fetch_dec0_branch_w;
  wire [`XLEN-1:0] fetch_dec0_bimm_w;
  wire fetch_dec1_branch_w;
  wire [`XLEN-1:0] fetch_dec1_bimm_w;
  wire [`BPU_BHT_INDEX_W-1:0] fetch_dec0_bht_idx_w;
  wire fetch_dec0_bht_valid_w;
  wire fetch_dec0_pred_taken_w;
  wire fetch_dec0_predict_strong_w;
  wire [`BPU_BHT_INDEX_W-1:0] fetch_dec1_bht_idx_w;
  wire fetch_dec1_bht_valid_w;
  wire fetch_dec1_pred_taken_w;
  wire fetch_dec1_predict_strong_w;
  // 【B2 S2】resp 拍包级预测判决(声明前置, assign 在 PacketDecode 实例后):
  // fault slot(resp!=OK)不预测; 双分支包 slot0 优先; slot0 taken → 包内截断
  // (slot1_valid=0)+pred_next_pc=pc0+bimm0; slot0 not-taken 且 slot1 taken →
  // 整包有效+pred_next_pc=pc1+bimm1; 均 not-taken → pred_next_pc=packet_next_pc。
  wire fetch_pred0_taken_w;
  wire fetch_pred1_taken_w;
  wire fetch_slot1_valid_w;
  wire [`XLEN-1:0] fetch_pred_next_pc_w;
  wire fetch_pred_taken_block_w;
  wire fetch_pred_taken_redirect_w;
  wire fetch_dec0_control_stop_nb_w;
  wire fetch_dec1_control_stop_nb_w;
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
  wire [1:0] fifo_head_resp0_w;
  wire [1:0] fifo_head_resp1_w;
  wire [`BPU_BHT_INDEX_W-1:0] fifo_head_bht_idx0_w;
  wire [`BPU_BHT_INDEX_W-1:0] fifo_head_bht_idx1_w;
  wire fifo_head_bht_valid0_w;
  wire fifo_head_bht_valid1_w;
  wire fifo_head_pred_taken0_w;
  wire fifo_head_pred_taken1_w;
  wire fifo_head_slot1_valid_w;
  wire head_slot1_valid_w;
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
  wire [`BPU_BHT_INDEX_W-1:0] fifo_seed_bht_idx0_w;
  wire [`BPU_BHT_INDEX_W-1:0] fifo_seed_bht_idx1_w;
  wire fifo_seed_bht_valid0_w;
  wire fifo_seed_bht_valid1_w;
  wire fifo_seed_pred_taken0_w;
  wire fifo_seed_pred_taken1_w;
  wire fifo_seed_slot1_valid_w;
  wire fifo_seed_valid_w;
  wire fifo_storage_head_valid_w;
  wire fifo_storage_pop_w;
  wire frontend_dispatch_to_backend_valid_w;
  // 【B2 S1】head0/1_branch_{bht_idx,bht_valid,pred_taken}: 包内存储位(FIFO 经
  // HeadMux 读出), 不再是 BPU head 拍活查询直通。
  wire [`BPU_BHT_INDEX_W-1:0] head0_branch_bht_idx_w;
  wire head0_branch_bht_valid_w;
  wire head0_branch_pred_taken_w;
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
    .head_slot1_valid_i(head_slot1_valid_w),
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
    .head0_fencei_raw_o(head0_fencei_raw_w),
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
    .head1_fencei_raw_o(head1_fencei_raw_w),
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


  // 【serialize Phase1 §4】合法 head0-CSR 判定(镜像 OooFetchHeadPairGate dispatch0_system_o 的切法):
  // dispatch_valid && facts[CSR] && !illegal。用于 §4#1 放行 / §4#2 不停头 / §4#3 squash lane1。
  // ★排除 FP CSR(fflags/frm/fcsr): 本阶段不队头化 FP CSR(serial_flush 会 squash 在飞多周期 FP → 活锁/
  //   fflags RAW 错), 让它们仍走 drain 路(§9 note)。fdiv/fmadd 读 fcsr 校验异常标志靠此保正确。
  wire head0_fp_csr_w =
      (head_inst0_w[31:20] == `CSR_FFLAGS) ||
      (head_inst0_w[31:20] == `CSR_FRM) ||
      (head_inst0_w[31:20] == `CSR_FCSR);
  wire dispatch0_csr_w =
      `OOO_CSR_QUEUE_HEAD &&
      dispatch_valid_w && head0_facts_w[`OOO_SLOT_FACT_CSR] &&
      !head0_csr_illegal_i && !head0_fp_csr_w;
  // head0-CSR 单发 fire(=进后端 valid 且 dispatch 就绪): 驱动 FIFO 单发 pop(否则前端卡死)。
  wire head0_csr_dispatch_fire_w =
      frontend_dispatch_to_backend_valid_w && dispatch0_csr_w && dispatch0_ready_w;
  // 【serialize Phase1 §10.4 修】head0-CSR 在飞锁存: dispatch 置、commit/flush 清。在飞期间(它在 ROB 未提交)
  // 须保持 stop_pending 阻止 younger 越序 dispatch/被捕获到 drain——否则 head0-CSR(ROB) 与 younger CSR
  // (lane1-drain) 共存, younger 越过在飞的 head0-CSR 被捕获, 覆写单个 pending 寄存器→drain 状态丢失死锁。
  // (根因: head0-CSR 单发 pop 后不再在 FIFO 头, dispatch0_system set 条件只 1 拍, stop 随即被 drain 清掉。)
  reg head0_csr_inflight_q;
  always @(posedge clk) begin
    if (rst || core_trap_flush_q || core_serial_flush_q || head0_csr_commit_w)
      head0_csr_inflight_q <= 1'b0;
    else if (head0_csr_dispatch_fire_w)
      head0_csr_inflight_q <= 1'b1;
  end
  assign head0_csr_inflight_w = head0_csr_inflight_q;

  // 声明前置(原在 direct_fire_succ_w 簇旁): iverilog 14 拒绝实例端口前向引用
  wire dbranch_dual_go_w;

  OooFrontendDispatchGate u_frontend_dispatch_gate (
    .dispatch_valid_i(dispatch_valid_w),
    .dispatch0_csr_i(dispatch0_csr_w),
    .head0_branch_pred_taken_i(head0_branch_pred_taken_w),
    .head_slot1_valid_i(head_slot1_valid_w),
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
    .dec0_branch_o(fetch_dec0_branch_w),
    .dec0_bimm_o(fetch_dec0_bimm_w),
    .dec1_branch_o(fetch_dec1_branch_w),
    .dec1_bimm_o(fetch_dec1_bimm_w),
    .packet_next_pc_o(fetch_rsp_packet_next_pc_w)
  );

  // ═══ 【B2 S2】resp 拍包级预测判决("包内预测位 + taken 拍断融合", spec §1) ═══
  // fault slot(resp!=OK)不预测; 双分支包 slot0 优先(slot0 taken 时 slot1 预测无意义)。
  assign fetch_pred0_taken_w =
      fetch_dec0_branch_w && (fetch_dec0_resp_w == 2'b00) &&
      fetch_dec0_pred_taken_w;
  assign fetch_pred1_taken_w =
      !fetch_pred0_taken_w &&
      fetch_dec1_branch_w && (fetch_dec1_resp_w == 2'b00) &&
      fetch_dec1_pred_taken_w;
  // slot0 taken → 包内截断: slot1=wrong-path, 随包存 0, head1 谓词族在
  // OooFetchHeadPairGate facts 生成处单点门控(禁用 resp 字段/NOP 替换编码——
  // resp 是 fault 通道, 混用撞 fetch-fault drain 路径)。
  assign fetch_slot1_valid_w = !fetch_pred0_taken_w;
  // 包级预测后继(随包存 FIFO packet_next_pc 字段=改造承载, 同时喂 Sequencer 顺序
  // 推进臂完成 resp 拍改流): taken=分支 target(pc+bimm), 否则=fall-through。
  // 该值只进寄存器 D 端(FIFO 表项/next_fetch_pc_q), 禁止组合进 fetch_req_pc
  // (刀 F WNS 家族: BPU 两级串联读+imm 加法器进取指回环)。
  assign fetch_pred_next_pc_w =
      fetch_pred0_taken_w ? (fetch_dec0_pc_w + fetch_dec0_bimm_w) :
      fetch_pred1_taken_w ? (fetch_dec1_pc_w + fetch_dec1_bimm_w) :
                            fetch_rsp_packet_next_pc_w;
  // taken 拍断融合关断(单 bit → OooFetchFlowControl.can_issue): 该拍融合连发的
  // 组合顺序地址是 fall-through 旧值(wrong-path), 压掉当拍顺序请求, target 拍尾
  // 写进 next_fetch_pc_q, 次拍顺序臂发出——仅 taken 包付 1 拍。门用 rsp_valid 而非
  // enqueue(FlowControl 输出), 避免输出→输入组合回绕; 多压集(discard/drop/满)拍
  // can_issue 本就被既有项压死, 逐位中性。
  assign fetch_pred_taken_block_w =
      fetch_rsp_valid_i && (fetch_pred0_taken_w || fetch_pred1_taken_w);
  // pred-taken 改流事件(精确口径: 包真实入队拍): 断言/观测消费(branch_flush 桶
  // 迁移口), 不进数据通路。
  assign fetch_pred_taken_redirect_w =
      fetch_rsp_enqueue_w && (fetch_pred0_taken_w || fetch_pred1_taken_w);
  // 非分支类 control stop(resp fault/JAL/JALR/SYSTEM): 纯分支包放行 rsp 拍融合
  // 连发(顺序地址=fall-through=not-taken 预测流; taken 拍由上面 block 关断)。
  // 分支项须以 resp==OK 限定——fault slot 的垃圾位形似 BRANCH 时仍必须 stop。
  assign fetch_dec0_control_stop_nb_w =
      fetch_dec0_control_stop_w &&
      !(fetch_dec0_branch_w && (fetch_dec0_resp_w == 2'b00));
  assign fetch_dec1_control_stop_nb_w =
      fetch_dec1_control_stop_w &&
      !(fetch_dec1_branch_w && (fetch_dec1_resp_w == 2'b00));


  OooFetchPacketHeadMux u_fetch_packet_head_mux (
    .bypass_valid_i(fetch_rsp_dispatch_bypass_w),
    .fifo_head_valid_i(fifo_storage_head_valid_w),
    .bypass_pc0_i(fetch_dec0_pc_w),
    .bypass_pc1_i(fetch_dec1_pc_w),
    .bypass_next_pc0_i(fetch_dec0_next_pc_w),
    .bypass_next_pc1_i(fetch_dec1_next_pc_w),
    // 【B2 S2】packet_next_pc 字段改造承载包级 pred_next_pc(bypass 臂死硅 tie-0,
    // 接同拍组合保同源)。
    .bypass_packet_next_pc_i(fetch_pred_next_pc_w),
    .bypass_inst0_i(fetch_dec0_inst_w),
    .bypass_inst1_i(fetch_dec1_inst_w),
    .bypass_resp0_i(fetch_dec0_resp_w),
    .bypass_resp1_i(fetch_dec1_resp_w),
    .bypass_pred_taken0_i(fetch_dec0_pred_taken_w),
    .bypass_pred_taken1_i(fetch_dec1_pred_taken_w),
    .bypass_bht_idx0_i(fetch_dec0_bht_idx_w),
    .bypass_bht_idx1_i(fetch_dec1_bht_idx_w),
    .bypass_bht_valid0_i(fetch_dec0_bht_valid_w),
    .bypass_bht_valid1_i(fetch_dec1_bht_valid_w),
    .bypass_slot1_valid_i(fetch_slot1_valid_w),
    .fifo_pc0_i(fifo_head_pc0_w),
    .fifo_pc1_i(fifo_head_pc1_w),
    .fifo_next_pc0_i(fifo_head_next_pc0_w),
    .fifo_next_pc1_i(fifo_head_next_pc1_w),
    .fifo_packet_next_pc_i(fifo_head_packet_next_pc_w),
    .fifo_inst0_i(fifo_head_inst0_w),
    .fifo_inst1_i(fifo_head_inst1_w),
    .fifo_resp0_i(fifo_head_resp0_w),
    .fifo_resp1_i(fifo_head_resp1_w),
    .fifo_pred_taken0_i(fifo_head_pred_taken0_w),
    .fifo_pred_taken1_i(fifo_head_pred_taken1_w),
    .fifo_bht_idx0_i(fifo_head_bht_idx0_w),
    .fifo_bht_idx1_i(fifo_head_bht_idx1_w),
    .fifo_bht_valid0_i(fifo_head_bht_valid0_w),
    .fifo_bht_valid1_i(fifo_head_bht_valid1_w),
    .fifo_slot1_valid_i(fifo_head_slot1_valid_w),
    .head_has_packet_o(fifo_has_packet_w),
    .head_pc0_o(head_pc_w),
    .head_pc1_o(head_pc1_w),
    .head_next_pc0_o(head_next_pc0_w),
    .head_next_pc1_o(head_next_pc1_w),
    .head_packet_next_pc_o(head_packet_next_pc_w),
    .head_inst0_o(head_inst0_w),
    .head_inst1_o(head_inst1_w),
    .head_resp0_o(head_resp0_w),
    .head_resp1_o(head_resp1_w),
    .head_pred_taken0_o(head0_branch_pred_taken_w),
    .head_pred_taken1_o(head1_branch_pred_taken_w),
    .head_bht_idx0_o(head0_branch_bht_idx_w),
    .head_bht_idx1_o(head1_branch_bht_idx_w),
    .head_bht_valid0_o(head0_branch_bht_valid_w),
    .head_bht_valid1_o(head1_branch_bht_valid_w),
    .head_slot1_valid_o(head_slot1_valid_w)
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


  // 声明前置(赋值仍在原 JALR-spec 簇内): iverilog 14 拒绝实例端口前向引用
  wire direct_jump_spec_fire_w;
  wire [`XLEN-1:0] jalr_spec_pred_target_w;
  // 声明前置(赋值在 direct_fire_succ 簇旁, 文件后部): E4 direct redirect 构造式。
  wire e4_redirect_valid_w;
  wire [`XLEN-1:0] e4_redirect_pc_w;

  // ═══ 【P4 切消费点(2026-07-09)】统一 redirect 年龄律仲裁器 生产实例 ═══
  // shadow 阶段(OooCoreTopGlue `ifdef OOO_ASSERT 影子段, 2026-07-08)等价证据闭合后,
  // OooRedirectArbiter 转正为 redirect PC 唯一真源: 输出喂两个原汇合点
  // (OooFetchRequestMux 组合链已删 / OooFetchPcOutstandingSequencer 六处 PC 写已删,
  // 换 arb 终写)。实例放本模块(不放 glue): 三源 fetch 侧信号全在本作用域, 放 glue
  // 会造 frontend→glue→frontend 跨层组合往返(UNOPTFLAT 家族, 见下 head_pred_succ 注释)。
  //
  // ── commit 家族 pre-mux(E1>E5>E6, 照 OooFetchPcOutstandingSequencer 原文本序) ──
  // E1/E5/E6 同为 commit-time、同 rob_idx(head, age≡0)——arbiter 年龄律无法区分家族内
  // 成员, 家族内序必须 pre-mux; arbiter 只仲裁家族间(trap 口 vs branch 口 vs direct 口)。
  // E1: commit trap/xret(恒 ROB head, 绝对最高)
  wire commit_e1_valid_w = csr_trap_mem_valid_w;
  // E5: CSR 提交 redirect。head0 支默认 OOO_CSR_QUEUE_HEAD=0 恒 0(零 exercise,
  // 幸存者偏差照契约 §0 标注; 翻 flag 时 INV-3/INV-3b 是哨兵)。
  // !direct_frontend_flush 门 = 现行 E4-压-E5/E6 序的忠实编码(drain 期 dispatch 停摆
  // 使该拍本不可达, 保留 = 零语义风险)。
  wire commit_e5_valid_w = !direct_frontend_flush_w &&
      (pending_system_csr_commit_w || head0_csr_commit_w);
  wire [`XLEN-1:0] commit_e5_pc_w =
      head0_csr_commit_w ? core_commit0_next_pc_w : pending_system_next_pc_q;
  // E6: drain 终态, owner 序 arch_trap>system>branch>jump>mem 照抄 Sequencer 原臂序。
  wire commit_e6_base_w = !csr_trap_mem_valid_w && !direct_frontend_flush_w &&
      stop_pending_q && drain_complete_w;
  wire commit_e6_branch_undisp_w = pending_branch_q && !pending_branch_dispatched_q;
  wire commit_e6_sel_arch_w = pending_arch_trap_q;
  wire commit_e6_sel_system_w = !pending_arch_trap_q && pending_system_q;
  wire commit_e6_sel_branch_w = !pending_arch_trap_q && !pending_system_q &&
      commit_e6_branch_undisp_w;
  wire commit_e6_sel_jump_w = !pending_arch_trap_q && !pending_system_q &&
      !commit_e6_branch_undisp_w && pending_jump_q;
  wire commit_e6_sel_mem_w = !pending_arch_trap_q && !pending_system_q &&
      !commit_e6_branch_undisp_w && !pending_jump_q && pending_mem_q; // 恒 0(死硅 tie-off)
  // misaligned 的 E6-branch 臂不写 next_fetch_pc(原 Sequencer 门)→ 不算 PC 赢家。
  wire commit_e6_valid_w = commit_e6_base_w &&
      (commit_e6_sel_arch_w || commit_e6_sel_system_w ||
       (commit_e6_sel_branch_w && !pending_branch_misaligned_w) ||
       commit_e6_sel_jump_w || commit_e6_sel_mem_w);
  // E6-jump 臂目标: 原 Sequencer 用 jalr_prefetch_hit ? hit_packet_next_pc :
  // pending_jump_target, 二者本模块内均为死硅 tie-0(wave5b 拆除块)→ 忠实镜像为常量 0
  // (该臂若真触发即是 bug, INV-1'/difftest 会连带暴露)。
  wire [`XLEN-1:0] commit_e6_pc_w =
      commit_e6_sel_arch_w ? csr_trap_target_w :
      commit_e6_sel_system_w ?
          ((pending_system_ecall_q || pending_system_irq_q) ? csr_trap_target_w :
           (pending_system_mret_q ? csr_ret_target_w : pending_system_next_pc_q)) :
      commit_e6_sel_branch_w ? pending_branch_next_pc_w :
      commit_e6_sel_jump_w ? {`XLEN{1'b0}} :
      pending_mem_next_pc_q;
  // 【GAP-2 甲门已删(行为变化面, 契约 §3)】shadow 阶段的 !branch_resolve_untracked_w
  // 门显式编码了现行"E3 压过 E5/E6"文本序; 切换后由年龄律给出 commit 家族(age0)恒胜
  // ——架构语义修复(队头 CSR/drain 提交后 younger 误预测分支本该被 squash)。该同拍
  // 在全部现有负载不可达(INV-3b 全程 0 fire 实证), flag=1 是唯一可能违反域(INV-3/
  // INV-3b 哨兵在位)。后端 kill(branch_resolve_mispredict_w 扇出)不经此路, 本刀零触碰。
  wire commit_trap_valid_w = commit_e1_valid_w ||
      commit_e5_valid_w || commit_e6_valid_w;
  wire [`XLEN-1:0] commit_trap_pc_w =
      commit_e1_valid_w ? csr_trap_target_w :
      commit_e5_valid_w ? commit_e5_pc_w : commit_e6_pc_w;

  wire redirect_valid_w;
  wire [`XLEN-1:0] redirect_pc_w;
  wire [`OOO_ROB_INDEX_W-1:0] redirect_kill_idx_w;
  wire [`REDIR_REASON_W-1:0] redirect_reason_w;
  wire redirect_flush_fetch_w;
  wire redirect_flush_backend_w;
  OooRedirectArbiter u_redirect_arbiter (
    .rob_head_idx_i(rob_head_idx_i),
    // trap 口 = commit 家族(E1/E5/E6 pre-mux): commit-time 源恒 ROB head(age≡0)
    .trap_valid_i(commit_trap_valid_w),
    .trap_pc_i(commit_trap_pc_w),
    .trap_rob_idx_i(rob_head_idx_i),
    .trap_reason_i(`REDIR_REASON_TRAP),
    .trap_flush_fetch_i(1'b1),
    .trap_flush_backend_i(1'b1),
    // branch 口 = E3(后端 resolve 已带真 rob_idx): valid 用现成
    // branch_resolve_untracked_redirect(RecoveryGate = untracked && !misaligned,
    // 已含 trap_redirect_squash 掩码)。
    .branch_valid_i(branch_resolve_untracked_redirect_w),
    .branch_pc_i(core_branch_resolve_next_pc_w),
    .branch_rob_idx_i(core_branch_resolve_rob_idx_i),
    .branch_reason_i(`REDIR_REASON_BRANCH_MISS),
    .branch_flush_fetch_i(1'b1),
    .branch_flush_backend_i(1'b1),
    // direct 口 = E4: 取指侧无 age, 喂 head-1 哨兵(age=2^W-1 恒最年轻——direct 是
    // dispatch 拍事件, 构造上严格年轻于任何本拍后端 resolve 分支; 同拍 E3+E4 年龄律
    // branch 胜 = 原 :263 untracked-over-flush override 语义, GAP-1 双落点随之消灭;
    // age15 平手拍不可达: 分支占 head+15 ⟹ ROB 满 ⟹ 无 dispatch ⟹ 无 direct fire)。
    .direct_valid_i(e4_redirect_valid_w),
    .direct_pc_i(e4_redirect_pc_w),
    .direct_rob_idx_i(rob_head_idx_i - {{(`OOO_ROB_INDEX_W-1){1'b0}}, 1'b1}),
    .direct_reason_i(`REDIR_REASON_DIRECT),
    .direct_flush_fetch_i(1'b1),
    .direct_flush_backend_i(1'b0),
    .redirect_valid_o(redirect_valid_w),
    .redirect_pc_o(redirect_pc_w),
    // kill_idx/reason/flush_* 本刀 unused sink(后端 kill/nuke 通道零触碰, 禁止项④);
    // reason 同时被下方 INV-1' 断言消费(守 branch 口接线)。GAP-4 后端收敛另立刀。
    .redirect_kill_idx_o(redirect_kill_idx_w),
    .redirect_reason_o(redirect_reason_w),
    .redirect_flush_fetch_o(redirect_flush_fetch_w),
    .redirect_flush_backend_o(redirect_flush_backend_w)
  );
  wire _unused_redirect_arb_w = (|redirect_kill_idx_w) |
      redirect_flush_fetch_w | redirect_flush_backend_w |
      (|redirect_reason_w);

  // 【时序 T1】resolve 族 redirect 当拍封顺序臂、次拍发 target(内部信号)
  wire resolve_redirect_block_w;
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
    .core_branch_resolve_next_pc_i(core_branch_resolve_next_pc_w),
    .branch_prefetch_req_valid_i(branch_prefetch_req_valid_w),
    .branch_prefetch_req_pc_i(branch_prefetch_req_pc_w),
    .direct_jump_spec_fire_i(direct_jump_spec_fire_w),
    .redirect_valid_i(redirect_valid_w),
    .redirect_pc_i(redirect_pc_w),
    .direct_redirect_fetch_o(direct_redirect_fetch_w),
    .redirect_fetch_req_valid_o(redirect_fetch_req_valid_w),
    .resolve_redirect_block_o(resolve_redirect_block_w),
    .redirect_fetch_pc_o(redirect_fetch_pc_w),
    .fetch_req_pc_o(fetch_req_pc_o)
  );


  OooFrontendActionGate u_frontend_action_gate (
    .direct_jal_fire_i(direct_jal_fire_w),
    .direct_ret0_fire_i(direct_ret0_fire_w),
    .direct_ret1_fire_i(direct_ret1_fire_w),
    .can_run_i(can_run_w),
    .fifo_has_packet_i(fifo_has_packet_w),
    .branch_spec_dispatch_block_i(branch_spec_dispatch_block_w),
    .head_fetch_fault0_i(head_fetch_fault0_w),
    .dispatch0_exit_i(dispatch0_exit_w),
    .dispatch0_arch_trap_i(dispatch0_arch_trap_w),
    .dispatch0_system_i(dispatch0_system_w),
    .dispatch0_csr_i(dispatch0_csr_w),
    .head0_csr_dispatch_fire_i(head0_csr_dispatch_fire_w),
    .dispatch0_branch_i(dispatch0_branch_w),
    .dispatch0_jal_i(dispatch0_jal_w),
    .dispatch0_jump_i(dispatch0_jump_w),
    .dispatch1_barrier_i(dispatch1_barrier_w),
    .dispatch1_direct_jal_i(dispatch1_direct_jal_w),
    .dispatch_unsupported_i(dispatch_unsupported_w),
    .dispatch_fire_i(dispatch_fire_w),
    .dbranch_dispatch_fire_i(dbranch_dispatch_fire_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .direct_jal0_fire_i(direct_jal0_fire_w),
    .direct_jump_spec_fire_i(direct_jump_spec_fire_w),
    .fetch_rsp_fire_i(fetch_rsp_fire_w),
    .fetch_rsp_can_enqueue_i(fetch_rsp_can_enqueue_w),
    // 【B2 S2】非分支类 stop(纯分支包放行融合连发, taken 拍由 pred block 关断)
    .fetch_dec0_control_stop_i(fetch_dec0_control_stop_nb_w),
    .fetch_dec1_control_stop_i(fetch_dec1_control_stop_nb_w),
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
    .resolve_redirect_block_i(resolve_redirect_block_w),
    .direct_redirect_block_i(direct_redirect_fetch_w),
    .pred_taken_block_i(fetch_pred_taken_block_w),
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


  // [wave5b 死硅拆除] OooPendingControlResolveGate 物理删除。该门纯组合，全部输出仅由
  // pending_branch_q / pending_jump_q（capture 恒 0 → 恒 0）派生：pending_branch_i=0 →
  // fallthrough/next_pc/misaligned=0；pending_jump_i=0 → resolve_ready/return/call/nolink 及
  // 其 *_fire/*_commit/resolved_target/redirect_after_dispatch 全 0；jalr_sum_lsb 口本就名带 unused。
  // 唯 pending_control_ready_o = (!pending_branch_i || commit_ready_i) 在 pending_branch_i=0 时
  // 恒 =1 → tie 1'b1（逐位等价）。供保留的 FetchRequestMux/SeedMux/RAS/OutstandingSeq 等 KEEP/活
  // F2 sensor 读常量。输入口 pending_jump_rs1_data_w / pending_branch_taken_w 转未读输入（容忍）。
  assign pending_branch_fallthrough_w = {`XLEN{1'b0}};
  assign pending_branch_next_pc_w = {`XLEN{1'b0}};
  assign pending_branch_misaligned_w = 1'b0;
  assign pending_jump_jalr_sum_lsb_unused_w = 1'b0;
  assign pending_jump_resolved_target_w = {`XLEN{1'b0}};
  assign pending_jump_misaligned_w = 1'b0;
  assign pending_jump_resolve_ready_w = 1'b0;
  assign pending_jump_return_w = 1'b0;
  assign pending_jump_return_fire_w = 1'b0;
  assign pending_jump_call_w = 1'b0;
  assign pending_jump_call_fire_w = 1'b0;
  assign pending_jump_nolink_w = 1'b0;
  assign pending_jump_nolink_commit_w = 1'b0;
  assign pending_jump_redirect_after_dispatch_w = 1'b0;
  assign pending_control_ready_w = 1'b1;



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
  assign jalr_spec_pred_target_w =
      jalr_spec_use_ras_w ? ras_top_w :
      jalr_spec_btb_hit_w ? jalr_spec_btb_target_w :
                            head_next_pc0_w;
  assign direct_jump_spec_fire_w = direct_jump_spec_start_w;







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
    .head0_csr_commit_i(head0_csr_commit_w),
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
    // 【B2 S2】packet_next_pc 字段改造承载包级 pred_next_pc(与 enqueue 同拍同源)
    .fallthrough_packet_next_pc_i(fetch_pred_next_pc_w),
    .fallthrough_inst0_i(fetch_dec0_inst_w),
    .fallthrough_inst1_i(fetch_dec1_inst_w),
    .fallthrough_resp0_i(fetch_dec0_resp_w),
    .fallthrough_resp1_i(fetch_dec1_resp_w),
    .fallthrough_pred_taken0_i(fetch_dec0_pred_taken_w),
    .fallthrough_pred_taken1_i(fetch_dec1_pred_taken_w),
    .fallthrough_bht_idx0_i(fetch_dec0_bht_idx_w),
    .fallthrough_bht_idx1_i(fetch_dec1_bht_idx_w),
    .fallthrough_bht_valid0_i(fetch_dec0_bht_valid_w),
    .fallthrough_bht_valid1_i(fetch_dec1_bht_valid_w),
    .fallthrough_slot1_valid_i(fetch_slot1_valid_w),
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
    .seed_resp1_o(fifo_seed_resp1_w),
    .seed_pred_taken0_o(fifo_seed_pred_taken0_w),
    .seed_pred_taken1_o(fifo_seed_pred_taken1_w),
    .seed_bht_idx0_o(fifo_seed_bht_idx0_w),
    .seed_bht_idx1_o(fifo_seed_bht_idx1_w),
    .seed_bht_valid0_o(fifo_seed_bht_valid0_w),
    .seed_bht_valid1_o(fifo_seed_bht_valid1_w),
    .seed_slot1_valid_o(fifo_seed_slot1_valid_w)
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
    .seed_pred_taken0_i(fifo_seed_pred_taken0_w),
    .seed_pred_taken1_i(fifo_seed_pred_taken1_w),
    .seed_bht_idx0_i(fifo_seed_bht_idx0_w),
    .seed_bht_idx1_i(fifo_seed_bht_idx1_w),
    .seed_bht_valid0_i(fifo_seed_bht_valid0_w),
    .seed_bht_valid1_i(fifo_seed_bht_valid1_w),
    .seed_slot1_valid_i(fifo_seed_slot1_valid_w),
    .enqueue_i(fetch_rsp_enqueue_w),
    .enqueue_pc0_i(fetch_dec0_pc_w),
    .enqueue_pc1_i(fetch_dec1_pc_w),
    .enqueue_next_pc0_i(fetch_dec0_next_pc_w),
    .enqueue_next_pc1_i(fetch_dec1_next_pc_w),
    // 【B2 S2】packet_next_pc 字段改造承载包级 pred_next_pc: head 侧消费者
    // (head_pred_succ→dispatch pred_npc)语义="前端实际取指后继"——含 taken 预测
    // 改流, 机械同源于 Sequencer 顺序推进臂输入, count<2 哨兵缺口消灭。
    .enqueue_packet_next_pc_i(fetch_pred_next_pc_w),
    .enqueue_inst0_i(fetch_dec0_inst_w),
    .enqueue_inst1_i(fetch_dec1_inst_w),
    .enqueue_resp0_i(fetch_dec0_resp_w),
    .enqueue_resp1_i(fetch_dec1_resp_w),
    .enqueue_pred_taken0_i(fetch_dec0_pred_taken_w),
    .enqueue_pred_taken1_i(fetch_dec1_pred_taken_w),
    .enqueue_bht_idx0_i(fetch_dec0_bht_idx_w),
    .enqueue_bht_idx1_i(fetch_dec1_bht_idx_w),
    .enqueue_bht_valid0_i(fetch_dec0_bht_valid_w),
    .enqueue_bht_valid1_i(fetch_dec1_bht_valid_w),
    .enqueue_slot1_valid_i(fetch_slot1_valid_w),
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
    .head_pred_taken0_o(fifo_head_pred_taken0_w),
    .head_pred_taken1_o(fifo_head_pred_taken1_w),
    .head_bht_idx0_o(fifo_head_bht_idx0_w),
    .head_bht_idx1_o(fifo_head_bht_idx1_w),
    .head_bht_valid0_o(fifo_head_bht_valid0_w),
    .head_bht_valid1_o(fifo_head_bht_valid1_w),
    .head_slot1_valid_o(fifo_head_slot1_valid_w),
    .count_o(fifo_count_q)
  );

  // 【B2 S2】pred_npc 源=包内 pred_next_pc(FIFO packet_next_pc 字段改造承载, 经
  // HeadMux 读出): resp 拍定格的"前端实际取指后继"——taken 预测=分支 target, 否则
  // =fall-through。与 Sequencer 顺序推进臂写入 next_fetch_pc_q 的值机械同源(同一
  // fetch_pred_next_pc_w), pred 与实际取指结构性一致(#105 障碍②族免疫)。
  // F2 count<2 哨兵臂(64'h1 恒 mispredict 兜底: "target 包未到→伪 mispredict 全代价
  // redirect")与 fifo_head1_pc0 下包读口随之消灭——包内直取不依赖下包是否到达。
  wire [`XLEN-1:0] head_pred_succ_w = head_packet_next_pc_w;

  // ===== 【F2 单源化】本拍 direct fire 的实际重取目标 =====
  // 与 OooFetchPcOutstandingSequencer 的 next_fetch 更新共享同一 wire(该模块的内部
  // 重复 mux 已删), dispatch pred_npc 的 fired-控制流臂也取它——pred 与实际取指
  // 机械同源, 结构性消灭 #105 障碍②(拍内解析/spec 臂不同源错配)族。臂序保持
  // 原 OutstandingSequencer 优先级: jal > ret > branch(lane1_ret > target > fallthrough
  // > 拍内解析 > spec > 顺序) > jump_spec。
  // 【B2 S2】direct_branch_fire_w 恒 0(分支 fire 物理死化)→ branch 整臂死硅, 证据化
  // 保留(B4 处置惯例); 分支重取目标现随包存 pred_next_pc(默认档 head_pred_succ_w)。
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
  // 【P4】E4 direct redirect 构造式(arbiter direct 口输入, 声明前置于 arbiter 实例旁):
  // 照原 OooFetchPcOutstandingSequencer E4 装载臂——valid = direct_frontend_flush 拍
  // 任一 direct fire; pc = direct_fire_succ。shadow 阶段为观测输出口, 切消费点
  // 后转为生产信号(原 Sequencer 内层 PC 写已删, 经 arbiter 终写回注)。
  // 【B2 S2】branch0/1_fire 项已去(分支 fire 物理死化, taken 降格为顺序流地址选择,
  // E4 只剩 jal/ret/jump_spec); 分支 fallthrough-capture 的 packet_next_pc 覆写臂
  // 随 capture 谓词(依赖 branch0_fire)死亡, 一并删除。
  assign e4_redirect_valid_w = direct_frontend_flush_w &&
      (direct_jal_fire_w || direct_ret0_fire_w || direct_ret1_fire_w ||
       direct_jump_spec_fire_w);
  assign e4_redirect_pc_w = direct_fire_succ_w;

  // 【B2 S2】branch0/1_fire 项恒 0(死化保留): 分支 lane 的 pred_npc 走非 fired 臂
  // = head_pred_succ_w(包内 pred_next_pc)——taken=target/not-taken=fall-through。
  wire d0_ctrlflow_fired_w =
      direct_jal0_fire_w || direct_ret0_fire_w || direct_branch0_fire_w ||
      direct_jump_spec_fire_w;
  wire d1_ctrlflow_fired_w =
      direct_jal1_fire_w || direct_ret1_fire_w || direct_branch1_fire_w;
  // solo 分支(taken/!dual)与非返回 JALR 拍禁 d1 影子(谓词无 ready, 不与 pair-ready 成环)
  wire dispatch1_squash_w =
      (dispatch0_branch_w && !dbranch_dual_go_w) ||
      (dispatch0_jump_w && !dispatch0_return_w) ||
      dispatch0_csr_w;   // 【serialize Phase1 §4#3】head0-CSR 单发, 禁 lane1 影子(younger 不与 CSR 同包进 ROB)

  // 【F2→B2 S1】dispatch 载荷: BHT 查询快照=包内存储位(fetch resp 拍定格, FIFO 经
  // HeadMux 读出; 不再是 head 拍活查询直通)。prefetch/pending 臂非分支, 后端只在
  // is_branch 时消费, 载荷错位无害。resolve 拍 BPU 回训用的 bht_idx 即此存储位
  // ——训 fetch 拍查过的表项。
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
    // [wave5b 死硅拆除] 旧四臂输入(direct_branch_resolve_valid/stop_pending/pending_branch*
    // /branch_resolve_pending_match/drain_complete/pending_branch_commit_resolve/
    // core_branch_resolve_misaligned/next_pc/pending_branch_target/taken/direct_branch_resolve_taken
    // /pending_branch_pred_taken/direct_branch_predict_taken/pending_branch_pc/direct_branch_pc
    // /pending_branch_bht_idx/direct_branch_bht_idx) 随四臂删除，只保留 issue-resolve 单源。
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
    .branch_bpu_update_valid_o(branch_bpu_update_valid_w),
    .branch_bpu_update_taken_o(branch_bpu_update_taken_w),
    .branch_bpu_update_pred_taken_o(branch_bpu_update_pred_taken_w),
    .branch_bpu_update_correct_o(branch_bpu_update_correct_w),
    .branch_bpu_update_pc_o(branch_bpu_update_pc_w),
    .branch_bpu_update_bht_idx_o(branch_bpu_update_bht_idx_w)
  );


  // 【B2 S1】BPU lookup 接线迁移: head 拍(FIFO head 活查询)→ fetch resp 拍(判决/
  // enqueue 拍)。lookup 输入=PacketDecode 组合输出(dec pc + B-imm, 分支时与
  // DecodeStage head imm 逐位同式); 输出当拍随包写 FIFO(enqueue/fallthrough-seed),
  // dispatch 拍全部消费存储位。BPU 本体零改动; head 拍活查询口物理断开(本实例是
  // lookup 唯一查询口, 无双查询)。GHR 演进时点差异(resp↔dispatch 间的 resolve
  // update)仅影响预测值, 不改任何架构行为路径(S1 行为语义等价台阶)。
  OooBranchDirectionPredictor u_branch_direction_predictor (
    .clk(clk),
    .rst(rst),
    .clear_i(flush_i),
    .lookup0_pc_i(fetch_dec0_pc_w),
    .lookup0_imm_i(fetch_dec0_bimm_w),
    .lookup0_bht_idx_o(fetch_dec0_bht_idx_w),
    .lookup0_bht_valid_o(fetch_dec0_bht_valid_w),
    .lookup0_pred_taken_o(fetch_dec0_pred_taken_w),
    .lookup0_predict_strong_o(fetch_dec0_predict_strong_w),
    .lookup1_pc_i(fetch_dec1_pc_w),
    .lookup1_imm_i(fetch_dec1_bimm_w),
    .lookup1_bht_idx_o(fetch_dec1_bht_idx_w),
    .lookup1_bht_valid_o(fetch_dec1_bht_valid_w),
    .lookup1_pred_taken_o(fetch_dec1_pred_taken_w),
    .lookup1_predict_strong_o(fetch_dec1_predict_strong_w),
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

  // [wave5b 死硅拆除] OooPendingBranchSequencer 物理删除。三条 capture 臂
  // (direct/head0/lane1) 全被 !rob_walk_mode_i(OOO_ROB_WALK_MODE=1'b1 → =0) 门死于
  // OooPendingDispatchArbiter → valid_q 永不置位 → 每个输出恒 = 复位值。tie-off 逐位等价：
  // 复位块中 cmp_op_q<=`CMP_OP_NONE，其余全 0（见原模块 reset）。
  assign pending_branch_q = 1'b0;
  assign pending_branch_dispatched_q = 1'b0;
  assign pending_branch_pc_q = {`XLEN{1'b0}};
  assign pending_branch_next_pc_q = {`XLEN{1'b0}};
  assign pending_branch_inst_q = {`INST_W{1'b0}};
  assign pending_branch_rs1_q = {`REG_ADDR_W{1'b0}};
  assign pending_branch_rs2_q = {`REG_ADDR_W{1'b0}};
  assign pending_branch_imm_q = {`XLEN{1'b0}};
  assign pending_branch_cmp_op_q = `CMP_OP_NONE;
  assign pending_branch_pred_taken_q = 1'b0;
  assign pending_branch_bht_valid_q = 1'b0;
  assign pending_branch_bht_idx_q = {`BPU_BHT_INDEX_W{1'b0}};

  // [wave5b 死硅拆除] OooPendingJumpSequencer 物理删除。capture_head0/lane1 同样被
  // !rob_walk_mode_i 门死；dispatch_fire 依赖 pending_jump_resolve_ready(恒0)。全输出恒 = 复位 0。
  assign pending_jump_q = 1'b0;
  assign pending_jump_dispatched_q = 1'b0;
  assign pending_jump_jalr_q = 1'b0;
  assign pending_jump_pc_q = {`XLEN{1'b0}};
  assign pending_jump_next_pc_q = {`XLEN{1'b0}};
  assign pending_jump_inst_q = {`INST_W{1'b0}};
  assign pending_jump_rs1_q = {`REG_ADDR_W{1'b0}};
  assign pending_jump_imm_q = {`XLEN{1'b0}};
  // 【P4】pending_jump_target_q tie-0 已删——唯一消费者(Sequencer E6-jump PC 写)随
  // 切消费点删除, PC 收敛 arbiter(E6-jump pre-mux 忠实镜像常量 0)。


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


  // 【P4 切消费点】redirect PC 载荷口(csr_trap_target/csr_ret_target/direct_fire_succ/
  // core_commit0_next_pc/pending_system_next_pc/pending_jump_target/pending_mem_next_pc
  // 与 E4 fire 家族/capture)已随六处 PC 写删除——PC 经 u_redirect_arbiter 赢家单点回注。
  OooFetchPcOutstandingSequencer u_fetch_pc_outstanding (
      .clk(clk),
      .rst(rst || flush_i),
      .reset_pc_i(reset_pc_i),
      .fetch_rsp_enqueue_i(fetch_rsp_enqueue_w),
      .fetch_rsp_bypass_consumed_i(fetch_rsp_bypass_consumed_w),
      .fetch_rsp_fire_i(fetch_rsp_fire_w),
      // 【B2 S2 改流落点】顺序推进臂输入换包级 pred_next_pc: taken 预测拍把分支
      // target 写进 next_fetch_pc_q(当拍融合请求被 pred_taken_block 关断), 次拍
      // 顺序臂发出——resp 拍改流, 断融合形态。其余拍逐位等于 packet_next_pc。
      .fetch_rsp_packet_next_pc_i(fetch_pred_next_pc_w),
      .fetch_req_fire_i(fetch_req_fire_w),
      .fetch_req_pc_i(fetch_req_pc_o),
      .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
      .direct_frontend_flush_i(direct_frontend_flush_w),
      .branch_fallthrough_keep_outstanding_i(branch_fallthrough_keep_outstanding_w),
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
      .head0_csr_commit_i(head0_csr_commit_w),
      .drain_complete_i(stop_pending_q && drain_complete_w),
      .pending_arch_trap_i(pending_arch_trap_q),
      .pending_system_i(pending_system_q),
      .pending_branch_i(pending_branch_q),
      .pending_branch_dispatched_i(pending_branch_dispatched_q),
      .pending_jump_i(pending_jump_q),
      .pending_mem_i(pending_mem_q),
      .redirect_valid_i(redirect_valid_w),
      .redirect_pc_i(redirect_pc_w),
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

  // 【B2 S2】dec*_branch 已被包级预测判决消费(S1 预留兑现); predict_strong 仍仅
  // checker 消费。
  wire frontend_fetch_dec_pred_unused_w =
      fetch_dec0_predict_strong_w | fetch_dec1_predict_strong_w;

`ifdef OOO_ASSERT
  // FDG-I1：classifier 已决定 head0 为精确 arch trap 时，普通 backend admission 必须关闭。
  // 真理来自精确异常边界；不重述 FP decode，故能覆盖 fetch fault/illegal/privileged 等所有来源。
  always @(posedge clk) if (!rst) begin
    if (dispatch0_arch_trap_w && frontend_dispatch_to_backend_valid_w)
      $error("[FDG-CONTRACT FDG-I1] head0 arch trap 同拍仍呈现 backend: pc=%h inst=%h @%0t",
             head_pc_w, head_inst0_w, $time);
  end

  // INV-1' (flush-redirect 契约 §4, GAP-1 后继, P4 切消费点改口径): arbiter branch 口
  // 赢家拍, 统一 redirect PC 必等于 core_branch_resolve_next_pc(branch 口 pc 源接线守卫)。
  // 旧 INV-1 守的是 mux 三元链「untracked 最高档」——该链已删, 单源化后改守 arbiter
  // branch 口不被错接(负测试实证过错接 pc 源会响的同款守卫; 刀0 探针 P4-KNIFE0-MUX-SUCC
  // 的职责由本断言 + 单源构造接替)。零误报。
  always @(posedge clk) if (!rst)
    if (redirect_valid_w && (redirect_reason_w == `REDIR_REASON_BRANCH_MISS) &&
        (redirect_pc_w !== core_branch_resolve_next_pc_w))
      $error("[FLUSH-CONTRACT INV-1] arbiter branch 口赢家 PC != core_branch_resolve_next_pc: arb=%h expect=%h @%0t",
             redirect_pc_w, core_branch_resolve_next_pc_w, $time);

  // GAP-3 (flush-redirect 契约 §4): mux 的 direct 重定向必蕴含 FE 的 direct_frontend_flush。
  // 二者同拍不一致时, 本拍 fetch_req 被 mux 重定向而 sequencer 未 latch next_fetch / 未 reset
  // outstanding → 两落点(fetch_req vs next_fetch)分叉。direct_redirect_fetch_w(:179)/
  // direct_frontend_flush_w(:176)已同 scope, 零 plumbing。当前恒静默(两 direct 定义差集
  // branch1 vs pending_jump* 结构对齐、恒不同拍); 制造违约=复活 tie-0 的
  // pending_jump_nolink_commit/redirect_after_dispatch 而漏同步进 FrontendActionGate → fire。
  always @(posedge clk) if (!rst)
    if (direct_redirect_fetch_w && !direct_frontend_flush_w)
      $error("[FLUSH-CONTRACT GAP-3] mux direct_redirect_fetch 置位而 FE direct_frontend_flush 未置位: fetch_req 被 mux 重定向但 sequencer 未 latch next_fetch/未 reset outstanding -> 两落点分叉 @%0t", $time);

  // 【B2 S2 契约】pred-taken 包改流拍 ⇒ 下一顺序取指请求 pc == 预测 target
  // (F2 障碍①家族: 改流拍顺序臂旧值泄漏)。改流拍寄存 target, 追踪至下一 req fire;
  // 途中任何 redirect/flush/FIFO clear 拍取消追踪(wrong-path 预测禁止改流——该拍
  // next_fetch_pc_q 已被文本更后的 arb 终写/req_fire 臂覆盖, 断言域随之关闭);
  // redirect/prefetch 臂请求不属顺序臂, 排除。立即断言形态(architecture-first)。
  reg b2s2_pred_redirect_pending_q;
  reg [`XLEN-1:0] b2s2_pred_target_q;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      b2s2_pred_redirect_pending_q <= 1'b0;
      b2s2_pred_target_q <= {`XLEN{1'b0}};
    end else if (redirect_valid_w || csr_trap_mem_valid_w ||
                 direct_frontend_flush_w || fifo_clear_w) begin
      b2s2_pred_redirect_pending_q <= 1'b0;
    end else if (fetch_pred_taken_redirect_w) begin
      b2s2_pred_redirect_pending_q <= 1'b1;
      b2s2_pred_target_q <= fetch_pred_next_pc_w;
    end else if (fetch_req_fire_w) begin
      b2s2_pred_redirect_pending_q <= 1'b0;
    end
  end
  always @(posedge clk) if (!rst) begin
    if (b2s2_pred_redirect_pending_q && fetch_req_fire_w &&
        !redirect_fetch_req_valid_w && !branch_prefetch_req_valid_w &&
        (fetch_req_pc_o !== b2s2_pred_target_q))
      $error("[B2S2-PRED-REDIRECT] pred-taken 改流后首个顺序取指请求 pc=%h != 预测 target=%h @%0t",
             fetch_req_pc_o, b2s2_pred_target_q, $time);
  end

  // 【B2 S2 契约】断融合等价性: pred-taken 拍(rsp 有效且包将入队)顺序臂请求必须被
  // 关断——can_issue 泄漏 = 融合连发以 fall-through 旧地址发出 wrong-path 请求并被
  // 登记为合法 outstanding(障碍①同族)。
  always @(posedge clk) if (!rst) begin
    if (fetch_pred_taken_redirect_w && can_issue_request_w)
      $error("[B2S2-PRED-BLOCK] pred-taken 改流拍顺序取指臂未被关断(can_issue 泄漏) @%0t", $time);
  end
`endif

endmodule
