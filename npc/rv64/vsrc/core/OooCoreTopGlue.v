`include "define.v"
`include "common/OooSlotFacts.v"

// OoO core 顶层装配壳：只实例化 frontend/control/execute/memory/writeback/
// regread_bypass 等子系统，功能规则继续归入对应目录，避免 core glue 再膨胀为 owner。
/* verilator lint_off UNOPTFLAT */
// 【B-FP 簇】FP 交叉 wakeup/ready 菱形使 Verilator 跨实例保守判环
// (__Vcellinp__ 端口注入形态)。行为正确性由全量测试守; 真伪甄别与
// 结构化真修(交叉唤醒打拍)列为 FP 簇收尾项。
module OooCoreTopGlue #(
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
  output mem_req_probe_o,
  output mem_req_pretrans_o,
  output mem_req_nokill_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  input mem_translate_active_i,
  output mem_flush_o,
  output mmu_flush_o,

  output csr_cycle_count_enable_w,
  output [1:0] core_retire_count_w,
  output pending_system_csr_commit_w,
  // 【serialize Phase1】head0-CSR 队头提交脉冲(→NpcCoreTop csr_commit / 内部各消费者)
  output head0_csr_commit_w,
  output csr_access_valid_w,
  output [11:0] csr_access_addr_w,
  output [2:0] csr_access_funct3_w,
  output [`REG_ADDR_W-1:0] csr_access_rs1_idx_w,
  output [`XLEN-1:0] csr_access_rs1_data_w,
  // 【B-FP 簇】fflags 提交脉冲(源=ROB commit; 名字保留 pending_ 前缀以稳住
  // NpcCoreTop 接线, pending-FP 壳已拆)。
  output pending_fp_fflags_commit_w,
  output [4:0] pending_fp_commit_fflags_w,
  output fp_dirty_commit_w,
  output csr_trap_mem_valid_w,
  output [`XLEN-1:0] csr_trap_mem_pc_w,
  output [`TRAP_CAUSE_W-1:0] csr_trap_mem_cause_w,
  output [`XLEN-1:0] csr_trap_mem_tval_w,
  output csr_trap_ex_valid_w,
  output [`XLEN-1:0] csr_trap_ex_pc_w,
  output [`TRAP_CAUSE_W-1:0] csr_trap_ex_cause_w,
  output [`XLEN-1:0] csr_trap_ex_tval_w,
  output csr_trap_irq_valid_w,
  output [`XLEN-1:0] csr_trap_irq_pc_w,
  output [`TRAP_CAUSE_W-1:0] csr_trap_irq_cause_w,
  output csr_real_mret_valid_w,
  output csr_sret_valid_w,
  input [`XLEN-1:0] csr_rdata_w,
  input csr_illegal_w,
  input csr_irq_pending_w,
  input [`TRAP_CAUSE_W-1:0] csr_irq_cause_w,
  input [`XLEN-1:0] csr_trap_target_w,
  input [`XLEN-1:0] csr_mepc_w,
  input [`XLEN-1:0] csr_ret_target_w,
  input [1:0] csr_priv_mode_w,
  input [`TRAP_CAUSE_W-1:0] csr_ecall_cause_w,
  input [`XLEN-1:0] csr_mstatus_w,
  input [2:0] csr_frm_w,  // FP#1: fcsr.frm 路由到 FP datapath
  input [`XLEN-1:0] csr_satp_w,
  input csr_svpbmt_en_w,
  input [`PMP_CFG_BUS_W-1:0] csr_pmpcfg_w,
  input [`PMP_ADDR_BUS_W-1:0] csr_pmpaddr_w,

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

  // 声明前置：iverilog 14 拒绝前向引用（下行 assign 引用 halted_q）
  wire halted_q;

  assign csr_cycle_count_enable_w = run_i && !halted_q;

  wire [`XLEN-1:0] next_fetch_pc_q;
  wire outstanding_valid_q;
  wire [`XLEN-1:0] outstanding_pc_q;
  wire discard_fetch_rsp_q;

  wire branch_spec_active_q;
  wire branch_spec_checkpoint_pending_q;

  wire trap_valid_q;
  wire exit_valid_q;
  wire stop_pending_q;
  wire pending_exit_q;
  wire pending_branch_q;
  wire pending_branch_dispatched_q;
  wire pending_jump_q;
  wire pending_jump_dispatched_q;
  wire pending_jump_jalr_q;
  // [死硅 tie-off] pending_mem 全链已删除(rtl-ground-truth §4：lane1 barrier 谓词与
  // FACT_MEM 严格互斥 → OooPendingMemorySequencer capture 恒 0，结构不可达)。valid/next_pc
  // 原本恒 0，改为显式常量 0，保持下游 KEEP sensor(RunGate/FetchPc/SeedMux/TrapExit/
  // Observable/Writeback)与 sim 探针(u_ooo_core.pending_mem_q)行为不变。
  wire pending_mem_q = 1'b0;
  wire pending_arch_trap_q;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_cause_q;
  wire [`XLEN-1:0] pending_branch_pc_q;
  wire [`INST_W-1:0] pending_branch_inst_q;
  wire [`REG_ADDR_W-1:0] pending_branch_rs1_q;
  wire [`REG_ADDR_W-1:0] pending_branch_rs2_q;
  wire [2:0] pending_branch_cmp_op_q;
  wire pending_branch_bht_valid_q;
  wire [`XLEN-1:0] pending_jump_pc_q;
  wire [`INST_W-1:0] pending_jump_inst_q;
  wire [`REG_ADDR_W-1:0] pending_jump_rs1_q;
  wire [`XLEN-1:0] pending_jump_imm_q;
  // [死硅 tie-off] OooSyntheticLane1Ret 家族(Sequencer/CommitGate)已删除
  // (rtl-ground-truth §4；capture 路径经 direct_branch0_lane1_ret_w 恒 0)。
  // 这些信号原本恒 0，改为显式常量 0，保持下游 OooControlPlane/OooFrontend/sim 探针行为不变。
  wire synth_lane1_ret_pending_q = 1'b0;
  wire synth_lane1_ret_branch_seen_q = 1'b0;
  wire synth_lane1_branch_drop_pending_q = 1'b0;
  wire [`XLEN-1:0] pending_mem_next_pc_q = {`XLEN{1'b0}};
  wire pending_system_q;
  wire pending_system_dispatched_q;
  wire pending_system_csr_q;
  wire pending_system_ecall_q;
  wire pending_system_mret_q;
  wire pending_system_irq_q;
  wire [`XLEN-1:0] pending_system_pc_q;
  wire [`INST_W-1:0] pending_system_inst_q;
  wire [`XLEN-1:0] pending_system_next_pc_q;
  wire [`XLEN-1:0] pending_system_csr_rdata_q;
  wire [`TRAP_CAUSE_W-1:0] pending_system_irq_cause_q;
  wire ctrl_commit_valid_q;
  wire backend_drained_q;
  wire core_trap_flush_q;
  wire trap_redirect_squash_q;
  wire core_serial_flush_q;
  wire checkpoint_mem_flush_q;

  wire orphan_stop_pending_w;
  wire can_run_w;
  wire fifo_has_packet_w;
  wire ras_empty_w;
  wire ras_full_w;

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
  wire [`REG_ADDR_W-1:0] head0_rd_unused_w;
  wire [`CTRL_BUS_W-1:0] head1_ctrl_w;
  wire [`REG_ADDR_W-1:0] head1_rd_unused_w;
  wire [`CTRL_BUS_W-1:0] branch_target_capture_ctrl_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_target_capture_rd_unused_w;
  wire [`XLEN-1:0] branch_target_capture_imm_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch0_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch0_imm_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch1_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch1_imm_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs1_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rs2_unused_w;
  wire [`REG_ADDR_W-1:0] branch_prefetch_rsp1_rd_unused_w;
  wire [`XLEN-1:0] branch_prefetch_rsp1_imm_unused_w;
  wire head0_fp_load_raw_w;
  wire head0_fp_store_raw_w;
  wire head0_fp_double_w;
  wire head0_fp_gpr_write_w;
  wire head0_ecall_raw_w;
  wire head0_csr_raw_w;
  wire head0_csr_inflight_w;   // 【serialize Phase1 §10.4】head0-CSR 在飞(u_frontend 出 → ControlPlane/stop)
  wire head0_xret_raw_w;
  wire head0_wfi_raw_w;
  wire head0_sfence_raw_w;
  wire head0_fencei_raw_w;
  wire head0_system_raw_w;
  wire head0_arch_trap_raw_w;
  wire head0_stop_raw_w;
  wire [`OOO_SLOT_FACTS_W-1:0] head0_facts_w;

  wire head_fetch_fault1_w;
  wire head_fetch_fault_w;
  wire head1_control_raw_w;
  wire head1_mem_raw_w;
  wire head1_fp_load_raw_w;
  wire head1_fp_store_raw_w;
  wire head1_fp_double_w;
  wire head1_fp_gpr_write_w;
  wire head1_fp_enabled_w;
  wire head1_ecall_raw_w;
  wire head1_csr_raw_w;
  wire head1_xret_raw_w;
  wire head1_wfi_raw_w;
  wire head1_sfence_raw_w;
  wire head1_fencei_raw_w;
  wire head1_stop_raw_w;
  wire [`OOO_SLOT_FACTS_W-1:0] head1_facts_w;

  wire branch_spec_dispatch_block_w;
  wire dispatch0_ready_w;
  wire dispatch1_ready_w;
  wire dispatch0_unsupported_w;
  wire dispatch1_unsupported_w;
  // 【F2】裸支持性(无 valid 项, 破 dual_go 环)
  wire dispatch0_unsupported_raw_w;
  wire dispatch1_unsupported_raw_w;
  wire dispatch_valid_w;
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

  wire direct_branch0_fire_w;
  wire dispatch0_return_w;
  // lane1 ret 在 lane0 不改写 ret 源寄存器、且不是控制/CSR/AMO 时可直接走 RAS。
  // 普通 load/store 由 ROB 精确异常和 IQ/LSU 的 store-order 规则约束，不需要退化成 drain 边界。
  wire dispatch1_barrier_w;
  wire dispatch_unsupported_w;
  wire dispatch_fire_w;
  wire dispatch1_barrier_fire_w;
  wire direct_ret1_fire_w;
  wire direct_branch1_fire_w;
  wire direct_jal0_dispatch_valid_w;
  wire [`XLEN-1:0] direct_branch_resolve_next_pc_w;
  wire direct_branch_resolve_redirect_w;
  wire direct_branch0_lane1_ret_w;
  wire direct_ret0_fire_w;
  wire direct_frontend_flush_w;
  wire direct_jal_call_w;
  wire branch_fallthrough_safe_w;
  wire fetch_rsp_bypass_consumed_w;
  wire fetch_rsp_fire_w;
  wire fetch_rsp_enqueue_w;
  wire pending_jump_misaligned_w;
  wire pending_jump_resolve_ready_w;
  wire [`XLEN-1:0] pending_branch_target_w;
  wire pending_jump_jalr_btb_hit_w;
  wire branch_prefetch_req_fire_w;
  wire branch_resolve_pending_match_w;
  wire branch_resolve_redirect_w;
  wire branch_spec_checkpoint_capture_w;
  wire branch_spec_resolve_valid_w;
  wire branch_spec_pred_match_w;
  wire branch_spec_restore_w;
  wire branch_spec_redirect_w;
  wire branch_resolve_untracked_w;
  wire branch_resolve_untracked_redirect_w;
  wire branch_prefetch_hit_available_w;

  wire direct_redirect_fetch_w;
  wire redirect_fetch_req_valid_w;
  wire fetch_req_fire_w;

  wire execute0_valid_unused_w;
  wire execute1_valid_unused_w;
  wire core_mem_idle_w;
  wire core_mem_retire_quiet_w;
  wire [4:0] core_commit0_fflags_w;
  wire core_commit0_is_fp_rd_w;
  wire core_commit1_is_fp_rd_w;
  wire [4:0] core_commit1_fflags_w;
  // 声明前置：iverilog 14 拒绝前向引用——commit0/commit1 字段组整体上移到下方 F8 assign 之前
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
  // F8: 写 FPR 或产生 fflags 的 FP 指令提交 → mstatus.FS=Dirty 脉冲
  assign fp_dirty_commit_w =
      (core_commit0_valid_w && !core_commit0_exception_w &&
       core_commit0_is_fp_rd_w) ||
      (core_commit1_valid_w && !core_commit1_exception_w &&
       core_commit1_is_fp_rd_w) ||
      pending_fp_fflags_commit_w;
  assign pending_fp_fflags_commit_w =
      (core_commit0_valid_w && !core_commit0_exception_w &&
       (core_commit0_fflags_w != 5'b00000)) ||
      (core_commit1_valid_w && !core_commit1_exception_w &&
       (core_commit1_fflags_w != 5'b00000));
  assign pending_fp_commit_fflags_w =
      ((core_commit0_valid_w && !core_commit0_exception_w) ?
       core_commit0_fflags_w : 5'b00000) |
      ((core_commit1_valid_w && !core_commit1_exception_w) ?
       core_commit1_fflags_w : 5'b00000);
  wire core_mem_req_valid_w;
  wire core_mem_req_write_w;
  wire core_mem_req_probe_w;
  wire core_mem_req_pretrans_w;
  wire core_mem_req_nokill_w;
  wire [`XLEN-1:0] core_mem_req_addr_w;
  wire [`XLEN-1:0] core_mem_req_wdata_w;
  wire [`STRB_W-1:0] core_mem_req_wstrb_w;
  wire core_mem_rsp_ready_w;
  wire core_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_branch_resolve_next_pc_w;
  wire core_branch_resolve_misaligned_w;
  // B2：解析分支 rob_idx（kill_younger_than 基准），随 branch_resolve_* 家族上送至此；
  // 后端内部已用于 ROB-walk kill；此 glue 导出份暂无消费者（原拟接统一 redirect arbiter，该地基已删档），
  // 保留为 driven-but-unused（Verilator UNUSEDSIGNAL 已全局抑制），若重启 redirect 收口可直接接。
  wire [`OOO_ROB_INDEX_W-1:0] core_branch_resolve_rob_idx_w;
  // 【P4 shadow】ROB 队头指针(经 ExecuteBackend←AluCoreSlice←AluDecodeBackend←IntBackend←OooRob
  // 透传)与前端 E4 观测口——shadow RedirectArbiter(见文末 `ifdef OOO_ASSERT 段)的年龄基准与
  // direct 口输入; 无 OOO_ASSERT 时为 driven-but-unused(UNUSEDSIGNAL 全局抑制), 零综合影响。
  wire [ROB_INDEX_W-1:0] core_rob_head_idx_w;
  wire e4_redirect_valid_w;
  wire [`XLEN-1:0] e4_redirect_pc_w;
  // B2 片4：后端 branch/JALR 显式 mispredict 脉冲，上送前端做 redirect。
  wire core_branch_resolve_mispredict_w;
  // 【F2】BPU issue-resolve 回训随行(execute → frontend)
  wire core_branch_resolve_is_branch_w;
  wire core_branch_resolve_taken_w;
  wire core_branch_resolve_pred_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] core_branch_resolve_bht_idx_w;
  wire core_dispatch_branch_resolve_valid_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_pc_w;
  wire [`XLEN-1:0] core_dispatch_branch_resolve_next_pc_w;
  wire core_dispatch_branch_resolve_misaligned_w;
  // IQ load-branch-fast 死硅整族删除：pending_load_branch_dep 生产链已摘除。
  // 其唯一消费者 OooBranchResolveRecoveryGate.branch_spec_checkpoint_capture_o 在
  // OOO_ROB_WALK_MODE=1 下恒 0（pending_branch 捕获被 !rob_walk_mode 门死），故此处
  // 常量 0 tie-off 逐位中性；下游 OooFrontend/RecoveryGate 端口保留读此 0。
  wire core_pending_load_branch_dep_w = 1'b0;
  wire [`XLEN-1:0] a0_data_w;
  wire [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w;
  wire pending_system_satp_write_commit_w;
  wire pending_system_sfence_commit_w;
  wire pending_system_fencei_commit_w;
  wire pending_system_ecall_trap_w;
  wire pending_arch_trap_fire_w;
  wire csr_mret_valid_w;
  wire priv_predictor_boundary_w;
  wire head0_csr_illegal_w;

  wire [`XLEN-1:0] pending_branch_rs1_data_w;
  wire [`XLEN-1:0] pending_branch_rs2_data_w;
  wire [`XLEN-1:0] pending_jump_rs1_data_w;
  wire pending_branch_taken_w;
  wire [`XLEN-1:0] pending_branch_next_pc_w;
  wire pending_branch_misaligned_w;
  wire pending_jump_jalr_sum_lsb_unused_w;
  wire [`XLEN-1:0] pending_jump_resolved_target_w;
  wire pending_jump_return_fire_w;
  wire pending_jump_call_fire_w;
  wire pending_jump_nolink_w;
  wire pending_jump_nolink_commit_w;
  wire pending_jump_redirect_after_dispatch_w;
  wire pending_control_ready_w;
  wire jalr_prefetch_hit_available_w;

  wire synth_lane1_ret_branch_commit0_w = 1'b0;  // [死硅 tie-off] synth lane1-ret 家族已删
  wire branch_target_cache_hit_w;

  wire return_cont_attempt_ready_w;
  wire synth_lane1_branch_append_w;
  wire dispatch1_optional_w;
  wire synth_lane1_branch_drop_match_w = 1'b0;  // [死硅 tie-off] synth lane1-ret 家族已删

  // 声明前置：iverilog 14 拒绝前向引用（u_writeback 端口引用 drain_complete_w）
  wire drain_complete_w;

  OooWriteback u_writeback (
    .clk(clk),
    .commit0_exception_o(commit0_exception_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_rd_addr_o(commit0_rd_addr_o),
    .commit0_rd_data_o(commit0_rd_data_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_valid_o(commit0_valid_o),
    .commit0_write_o(commit0_write_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_rd_addr_o(commit1_rd_addr_o),
    .commit1_rd_data_o(commit1_rd_data_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_write_o(commit1_write_o),
    .core_commit0_exception_w(core_commit0_exception_w),
    .core_commit0_inst_w(core_commit0_inst_w),
    .core_commit0_next_pc_w(core_commit0_next_pc_w),
    .core_commit0_pc_w(core_commit0_pc_w),
    .core_commit0_rd_addr_w(core_commit0_rd_addr_w),
    .core_commit0_rd_data_w(core_commit0_rd_data_w),
    .core_commit0_rd_en_w(core_commit0_rd_en_w),
    .core_commit0_valid_w(core_commit0_valid_w),
    .core_commit0_write_w(core_commit0_write_w),
    .core_commit1_exception_w(core_commit1_exception_w),
    .core_commit1_inst_w(core_commit1_inst_w),
    .core_commit1_next_pc_w(core_commit1_next_pc_w),
    .core_commit1_pc_w(core_commit1_pc_w),
    .core_commit1_rd_addr_w(core_commit1_rd_addr_w),
    .core_commit1_rd_data_w(core_commit1_rd_data_w),
    .core_commit1_rd_en_w(core_commit1_rd_en_w),
    .core_commit1_valid_w(core_commit1_valid_w),
    .core_commit1_write_w(core_commit1_write_w),
    .core_dispatch_branch_resolve_next_pc_w(core_dispatch_branch_resolve_next_pc_w),
    .core_retire_count_w(core_retire_count_w),
    .core_serial_flush_q(core_serial_flush_q),
    .csr_ret_target_w(csr_ret_target_w),
    .csr_trap_mem_valid_w(csr_trap_mem_valid_w),
    .ctrl_commit_valid_q(ctrl_commit_valid_q),
    .direct_frontend_flush_w(direct_frontend_flush_w),
    .drain_complete_w(drain_complete_w),
    .flush_i(flush_i),
    .head_inst0_w(head_inst0_w),
    .head_pc_w(head_pc_w),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .pending_arch_trap_q(pending_arch_trap_q),
    .pending_branch_dispatched_q(pending_branch_dispatched_q),
    .pending_branch_inst_q(pending_branch_inst_q),
    .pending_branch_misaligned_w(pending_branch_misaligned_w),
    .pending_branch_next_pc_w(pending_branch_next_pc_w),
    .pending_branch_pc_q(pending_branch_pc_q),
    .pending_branch_q(pending_branch_q),
    .pending_jump_inst_q(pending_jump_inst_q),
    .pending_jump_nolink_commit_w(pending_jump_nolink_commit_w),
    .pending_jump_pc_q(pending_jump_pc_q),
    .pending_jump_q(pending_jump_q),
    .pending_jump_resolved_target_w(pending_jump_resolved_target_w),
    .pending_mem_q(pending_mem_q),
    .pending_system_ecall_q(pending_system_ecall_q),
    .pending_system_inst_q(pending_system_inst_q),
    .pending_system_irq_q(pending_system_irq_q),
    .pending_system_mret_q(pending_system_mret_q),
    .pending_system_next_pc_q(pending_system_next_pc_q),
    .pending_system_pc_q(pending_system_pc_q),
    .pending_system_q(pending_system_q),
    .retire_count_o(retire_count_o),
    .rst(rst),
    .stop_pending_q(stop_pending_q),
    .head0_csr_commit_i(head0_csr_commit_w),
    .synth_lane1_branch_append_w(synth_lane1_branch_append_w)
  );

  wire backend_drained_w;
  // 休眠的单级 checkpoint 投机路径保持关闭（=分支走 pending）。
  // 验证负结论(2026-06-29)：置 1'b1 点火后功能 gate 大破——riscv 16 FAIL(store/div/clmul)、
  // AM 32 FAIL(分支程序活锁撞满 max-cycles)。该 weak 单 checkpoint 机器对多周期/访存在飞指令的
  // quiesce/capture 系统性损坏状态，是它被关死的根因。正解＝ROB-walk 多分支恢复(见 b2-branch-spec-redirect.md)，
  // 不复活此废弃路径。
  wire direct_branch_spec_start_w = `OOO_ROB_WALK_MODE;
  wire jump_dispatch_valid_w;
  wire system_csr_dispatch_valid_w;
  wire system_csr_dispatch_fire_w;
  wire pending_system_capture_head0_w;
  wire pending_system_capture_lane1_w;
  wire pending_system_clear_w;
  // [wave5b 死硅拆除] pending_branch/jump capture+clear 布线(7 根)已删——arbiter 臂 + 前端 sequencer 均删
  wire pending_mem_resolve_ready_w;
  wire pending_branch_commit_resolve_w;
  wire pending_branch_match_clear_w;
  wire pending_replay_wait_w;

  wire branch_bpu_lookup_event_w;
  wire branch_bpu_lookup_bht_valid_w;
  wire branch_bpu_update_valid_w;
  wire branch_bpu_update_taken_w;
  wire branch_bpu_update_pred_taken_w;
  wire branch_bpu_update_correct_w;
  wire [`XLEN-1:0] branch_bpu_update_pc_w;

  wire core_checkpoint_capture_w;
  wire core_checkpoint_restore_w;
  wire core_checkpoint_quiesce_w;
  wire core_mem_issue_block_w;

  wire core_local_flush_w;
  wire core_commit_ready_w;
  wire core_commit1_block_w;

  wire core_dispatch0_valid_w;
  wire core_dispatch1_valid_w;
  wire core_dispatch0_fire_w;
  wire jump_dispatch_fire_w;
  wire [`XLEN-1:0] core_dispatch0_pc_w;
  wire [`XLEN-1:0] core_dispatch0_next_pc_w;
  wire [`INST_W-1:0] core_dispatch0_inst_w;
  wire [`XLEN-1:0] core_dispatch0_csr_rdata_w;
  wire [`XLEN-1:0] core_dispatch1_pc_w;
  wire [`XLEN-1:0] core_dispatch1_next_pc_w;
  wire [`INST_W-1:0] core_dispatch1_inst_w;
  wire [`XLEN-1:0] core_dispatch0_pred_npc_w;
  wire [`XLEN-1:0] core_dispatch1_pred_npc_w;
  // 【F2】BHT 查询快照随行(frontend → execute, thread 进 IQ)
  wire [`BPU_BHT_INDEX_W-1:0] core_dispatch0_bht_idx_w;
  wire core_dispatch0_pred_taken_w;
  wire [`BPU_BHT_INDEX_W-1:0] core_dispatch1_bht_idx_w;
  wire core_dispatch1_pred_taken_w;


  OooExecuteBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_execute_backend (
    .a0_data_w(a0_data_w),
    .clk(clk),
    .core_branch_resolve_misaligned_w(core_branch_resolve_misaligned_w),
    .core_branch_resolve_rob_idx_w(core_branch_resolve_rob_idx_w),
    .core_branch_resolve_mispredict_w(core_branch_resolve_mispredict_w),
    .core_branch_resolve_is_branch_w(core_branch_resolve_is_branch_w),
    .core_branch_resolve_taken_w(core_branch_resolve_taken_w),
    .core_branch_resolve_pred_taken_w(core_branch_resolve_pred_taken_w),
    .core_branch_resolve_bht_idx_w(core_branch_resolve_bht_idx_w),
    .core_branch_resolve_next_pc_w(core_branch_resolve_next_pc_w),
    .core_branch_resolve_pc_w(core_branch_resolve_pc_w),
    .core_branch_resolve_valid_w(core_branch_resolve_valid_w),
    .core_checkpoint_capture_w(core_checkpoint_capture_w),
    .core_checkpoint_quiesce_w(core_checkpoint_quiesce_w),
    .core_checkpoint_restore_w(core_checkpoint_restore_w),
    .core_commit0_cause_w(core_commit0_cause_w),
    .core_commit0_exception_w(core_commit0_exception_w),
    .core_commit0_inst_w(core_commit0_inst_w),
    .core_commit0_next_pc_w(core_commit0_next_pc_w),
    .core_commit0_pc_w(core_commit0_pc_w),
    .core_commit0_rd_addr_w(core_commit0_rd_addr_w),
    .core_commit0_rd_data_w(core_commit0_rd_data_w),
    .core_commit0_rd_en_w(core_commit0_rd_en_w),
    .core_commit0_tval_w(core_commit0_tval_w),
    .core_commit0_valid_w(core_commit0_valid_w),
    .core_commit0_write_w(core_commit0_write_w),
    .core_commit1_block_w(core_commit1_block_w),
    .core_commit1_cause_w(core_commit1_cause_w),
    .core_commit1_exception_w(core_commit1_exception_w),
    .core_commit1_inst_w(core_commit1_inst_w),
    .core_commit1_next_pc_w(core_commit1_next_pc_w),
    .core_commit1_pc_w(core_commit1_pc_w),
    .core_commit1_rd_addr_w(core_commit1_rd_addr_w),
    .core_commit1_rd_data_w(core_commit1_rd_data_w),
    .core_commit1_rd_en_w(core_commit1_rd_en_w),
    .core_commit1_tval_w(core_commit1_tval_w),
    .core_commit1_valid_w(core_commit1_valid_w),
    .core_commit1_write_w(core_commit1_write_w),
    .core_commit_ready_w(core_commit_ready_w),
    .core_debug_gprs_w(core_debug_gprs_w),
    .core_dispatch0_csr_rdata_w(core_dispatch0_csr_rdata_w),
    // 【serialize Phase1】commit-time rd 覆写: head0-CSR 提交脉冲 + 架构 csr_rdata(组合旧值)。
    .head0_csr_commit_w(head0_csr_commit_w),
    .core_commit0_csr_rdata_w(csr_rdata_w),
    .frm_i(csr_frm_w),
    .core_dispatch0_inst_w(core_dispatch0_inst_w),
    .core_dispatch0_next_pc_w(core_dispatch0_next_pc_w),
    .core_dispatch0_pc_w(core_dispatch0_pc_w),
    .core_dispatch0_valid_w(core_dispatch0_valid_w),
    .core_dispatch0_pred_npc_w(core_dispatch0_pred_npc_w),
    .core_dispatch0_bht_idx_w(core_dispatch0_bht_idx_w),
    .core_dispatch0_pred_taken_w(core_dispatch0_pred_taken_w),
    .core_dispatch1_inst_w(core_dispatch1_inst_w),
    .core_dispatch1_next_pc_w(core_dispatch1_next_pc_w),
    .core_dispatch1_pc_w(core_dispatch1_pc_w),
    .core_dispatch1_valid_w(core_dispatch1_valid_w),
    .core_dispatch1_pred_npc_w(core_dispatch1_pred_npc_w),
    .core_dispatch1_bht_idx_w(core_dispatch1_bht_idx_w),
    .core_dispatch1_pred_taken_w(core_dispatch1_pred_taken_w),
    .core_dispatch_branch_resolve_misaligned_w(core_dispatch_branch_resolve_misaligned_w),
    .core_dispatch_branch_resolve_next_pc_w(core_dispatch_branch_resolve_next_pc_w),
    .core_dispatch_branch_resolve_pc_w(core_dispatch_branch_resolve_pc_w),
    .core_dispatch_branch_resolve_valid_w(core_dispatch_branch_resolve_valid_w),
    .core_local_flush_w(core_local_flush_w),
    .core_mem_idle_w(core_mem_idle_w),
    .core_mem_retire_quiet_w(core_mem_retire_quiet_w),
    .core_commit0_fflags_w(core_commit0_fflags_w),
    .core_commit0_is_fp_rd_w(core_commit0_is_fp_rd_w),
    .core_commit1_is_fp_rd_w(core_commit1_is_fp_rd_w),
    .core_commit1_fflags_w(core_commit1_fflags_w),
    .core_mem_issue_block_w(core_mem_issue_block_w),
    .core_mem_req_addr_w(core_mem_req_addr_w),
    .core_mem_req_valid_w(core_mem_req_valid_w),
    .core_mem_req_wdata_w(core_mem_req_wdata_w),
    .core_mem_req_write_w(core_mem_req_write_w),
    .core_mem_req_probe_w(core_mem_req_probe_w),
    .core_mem_req_pretrans_w(core_mem_req_pretrans_w),
    .core_mem_req_nokill_w(core_mem_req_nokill_w),
    .core_mem_req_wstrb_w(core_mem_req_wstrb_w),
    .core_mem_rsp_ready_w(core_mem_rsp_ready_w),
    .mem_translate_active_i(mem_translate_active_i),
    .core_retire_count_w(core_retire_count_w),
    .csr_trap_mem_valid_w(csr_trap_mem_valid_w),
    .dispatch0_ready_w(dispatch0_ready_w),
    .dispatch0_unsupported_raw_w(dispatch0_unsupported_raw_w),
    .dispatch0_unsupported_w(dispatch0_unsupported_w),
    .dispatch1_optional_w(dispatch1_optional_w),
    .dispatch1_ready_w(dispatch1_ready_w),
    .dispatch1_unsupported_raw_w(dispatch1_unsupported_raw_w),
    .dispatch1_unsupported_w(dispatch1_unsupported_w),
    .execute0_valid_unused_w(execute0_valid_unused_w),
    .execute1_valid_unused_w(execute1_valid_unused_w),
    .flush_i(flush_i),
    .free_count_o(free_count_o),
    .head_inst0_w(head_inst0_w),
    .head_inst1_w(head_inst1_w),
    .head_next_pc0_w(head_next_pc0_w),
    .head_next_pc1_w(head_next_pc1_w),
    .head_pc1_w(head_pc1_w),
    .head_pc_w(head_pc_w),
    .issue_count_o(issue_count_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem_rsp_page_fault_i(mem_rsp_page_fault_i),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .pending_branch_cmp_op_q(pending_branch_cmp_op_q),
    .pending_branch_dispatched_q(pending_branch_dispatched_q),
    .pending_branch_pc_q(pending_branch_pc_q),
    .pending_branch_q(pending_branch_q),
    .pending_branch_rs1_data_w(pending_branch_rs1_data_w),
    .pending_branch_rs2_data_w(pending_branch_rs2_data_w),
    .pending_branch_taken_w(pending_branch_taken_w),
    .rob_count_o(rob_count_o),
    .rob_head_idx_o(core_rob_head_idx_w),
    .rst(rst),
    .stop_pending_q(stop_pending_q)
  );

  // FP pending owner 移入 execute helper；父模块仍负责 FPR、fflags 和精确提交边界。


  // Branch pending owner 移入 frontend helper；父模块仍负责 compare/BPU/recovery。

  // JAL/JALR pending owner 移入 frontend helper；父模块仍负责 target/RAS/BTB/trap/redirect。

  // lane1 memory barrier pending owner 移入 memory helper，父模块仍负责全局仲裁。

  OooMemoryAccess u_memory_access (
    .backend_drained_q(backend_drained_q),
    .checkpoint_mem_flush_q(checkpoint_mem_flush_q),
    .core_local_flush_w(core_local_flush_w),
    .core_mem_req_addr_w(core_mem_req_addr_w),
    .core_mem_req_valid_w(core_mem_req_valid_w),
    .core_mem_req_wdata_w(core_mem_req_wdata_w),
    .core_mem_req_write_w(core_mem_req_write_w),
    .core_mem_req_probe_w(core_mem_req_probe_w),
    .core_mem_req_pretrans_w(core_mem_req_pretrans_w),
    .core_mem_req_nokill_w(core_mem_req_nokill_w),
    .core_mem_req_wstrb_w(core_mem_req_wstrb_w),
    .core_mem_rsp_ready_w(core_mem_rsp_ready_w),
    .mem_flush_o(mem_flush_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_probe_o(mem_req_probe_o),
    .mem_req_pretrans_o(mem_req_pretrans_o),
    .mem_req_nokill_o(mem_req_nokill_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mmu_flush_o(mmu_flush_o),
    .pending_system_satp_write_commit_w(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_w(pending_system_sfence_commit_w),
    .pending_system_fencei_commit_w(pending_system_fencei_commit_w),
    .stop_pending_q(stop_pending_q)
  );

  // SYSTEM/CSR/IRQ pending owner 移入 control helper，父模块只生成事件和消费状态。

  // 控制类伪提交由 writeback 侧 sequencer 统一打拍，父模块只保留 pending/trap owner。


  OooPendingOperandReadGate u_pending_operand_read_gate (
    .gprs_i(core_debug_gprs_w),
    .pending_branch_rs1_i(pending_branch_rs1_q),
    .pending_branch_rs2_i(pending_branch_rs2_q),
    .pending_jump_rs1_i(pending_jump_rs1_q),
    .pending_branch_rs1_data_o(pending_branch_rs1_data_w),
    .pending_branch_rs2_data_o(pending_branch_rs2_data_w),
    .pending_jump_rs1_data_o(pending_jump_rs1_data_w)
  );

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
      pending_replay_wait_w |
      return_cont_attempt_ready_w |
      pending_jump_jalr_sum_lsb_unused_w | head_fetch_fault_w |
      pending_branch_bht_valid_q |
      branch_bpu_lookup_event_w | branch_bpu_lookup_bht_valid_w |
      branch_bpu_update_correct_w |
      csr_irq_pending_w | (|csr_irq_cause_w) | (|csr_trap_target_w) |
      (|csr_mepc_w) | (|csr_priv_mode_w) | (|csr_satp_w) |
      (|head_packet_next_pc_w);


  OooControlPlane #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_control_plane (
    .a0_data_w(a0_data_w),
    .backend_drained_q(backend_drained_q),
    .backend_drained_w(backend_drained_w),
    .mem_retire_quiet_i(core_mem_retire_quiet_w),
    .branch_resolve_pending_match_w(branch_resolve_pending_match_w),
    .branch_resolve_untracked_w(branch_resolve_untracked_w),
    .branch_spec_active_q(branch_spec_active_q),
    .branch_spec_checkpoint_capture_w(branch_spec_checkpoint_capture_w),
    .branch_spec_checkpoint_pending_q(branch_spec_checkpoint_pending_q),
    .branch_spec_resolve_valid_w(branch_spec_resolve_valid_w),
    .branch_spec_restore_w(branch_spec_restore_w),
    .can_run_w(can_run_w),
    .checkpoint_mem_flush_q(checkpoint_mem_flush_q),
    .clk(clk),
    .commit_ready_i(commit_ready_i),
    .core_branch_resolve_misaligned_w(core_branch_resolve_misaligned_w),
    .core_branch_resolve_next_pc_w(core_branch_resolve_next_pc_w),
    .core_branch_resolve_pc_w(core_branch_resolve_pc_w),
    .core_checkpoint_capture_w(core_checkpoint_capture_w),
    .core_checkpoint_quiesce_w(core_checkpoint_quiesce_w),
    .core_checkpoint_restore_w(core_checkpoint_restore_w),
    .core_commit0_cause_w(core_commit0_cause_w),
    .core_commit0_exception_w(core_commit0_exception_w),
    .core_commit0_inst_w(core_commit0_inst_w),
    .core_commit0_pc_w(core_commit0_pc_w),
    .core_commit0_tval_w(core_commit0_tval_w),
    .core_commit0_valid_w(core_commit0_valid_w),
    .core_commit1_block_w(core_commit1_block_w),
    .core_commit1_cause_w(core_commit1_cause_w),
    .core_commit1_exception_w(core_commit1_exception_w),
    .core_commit1_pc_w(core_commit1_pc_w),
    .core_commit1_tval_w(core_commit1_tval_w),
    .core_commit1_valid_w(core_commit1_valid_w),
    .core_commit_ready_w(core_commit_ready_w),
    .core_debug_gprs_w(core_debug_gprs_w),
    .core_local_flush_w(core_local_flush_w),
    .core_mem_issue_block_w(core_mem_issue_block_w),
    .core_retire_count_w(core_retire_count_w),
    .core_serial_flush_q(core_serial_flush_q),
    .core_trap_flush_q(core_trap_flush_q),
    .csr_access_addr_w(csr_access_addr_w),
    .csr_access_funct3_w(csr_access_funct3_w),
    .csr_access_rs1_data_w(csr_access_rs1_data_w),
    .csr_access_rs1_idx_w(csr_access_rs1_idx_w),
    .csr_access_valid_w(csr_access_valid_w),
    .csr_ecall_cause_w(csr_ecall_cause_w),
    .csr_illegal_w(csr_illegal_w),
    .csr_irq_cause_w(csr_irq_cause_w),
    .csr_irq_pending_w(csr_irq_pending_w),
    .csr_mret_valid_w(csr_mret_valid_w),
    .csr_mstatus_w(csr_mstatus_w),
    .csr_pmpaddr_w(csr_pmpaddr_w),
    .csr_pmpcfg_w(csr_pmpcfg_w),
    .csr_priv_mode_w(csr_priv_mode_w),
    .csr_rdata_w(csr_rdata_w),
    .csr_real_mret_valid_w(csr_real_mret_valid_w),
    .csr_satp_w(csr_satp_w),
    .csr_sret_valid_w(csr_sret_valid_w),
    .csr_svpbmt_en_w(csr_svpbmt_en_w),
    .csr_trap_ex_cause_w(csr_trap_ex_cause_w),
    .csr_trap_ex_pc_w(csr_trap_ex_pc_w),
    .csr_trap_ex_tval_w(csr_trap_ex_tval_w),
    .csr_trap_ex_valid_w(csr_trap_ex_valid_w),
    .csr_trap_irq_cause_w(csr_trap_irq_cause_w),
    .csr_trap_irq_pc_w(csr_trap_irq_pc_w),
    .csr_trap_irq_valid_w(csr_trap_irq_valid_w),
    .csr_trap_mem_cause_w(csr_trap_mem_cause_w),
    .csr_trap_mem_pc_w(csr_trap_mem_pc_w),
    .csr_trap_mem_tval_w(csr_trap_mem_tval_w),
    .csr_trap_mem_valid_w(csr_trap_mem_valid_w),
    .ctrl_commit_valid_q(ctrl_commit_valid_q),
    .debug_gprs_o(debug_gprs_o),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .direct_branch0_dispatch_valid_w(direct_branch0_dispatch_valid_w),
    .direct_branch0_fire_w(direct_branch0_fire_w),
    .direct_branch1_fire_w(direct_branch1_fire_w),
    .direct_branch_resolve_redirect_w(direct_branch_resolve_redirect_w),
    .direct_frontend_flush_w(direct_frontend_flush_w),
    .direct_jal0_dispatch_valid_w(direct_jal0_dispatch_valid_w),
    .dispatch0_arch_trap_w(dispatch0_arch_trap_w),
    .dispatch0_branch_w(dispatch0_branch_w),
    .dispatch0_exit_w(dispatch0_exit_w),
    .dispatch0_facts_w(dispatch0_facts_w),
    .dispatch0_fp_w(dispatch0_fp_w),
    .dispatch0_jal_w(dispatch0_jal_w),
    .dispatch0_jump_w(dispatch0_jump_w),
    .dispatch0_ready_w(dispatch0_ready_w),
    .dispatch0_return_w(dispatch0_return_w),
    .dispatch0_system_w(dispatch0_system_w),
    .dispatch0_unsupported_w(dispatch0_unsupported_w),
    .dispatch1_barrier_fire_w(dispatch1_barrier_fire_w),
    .dispatch1_barrier_w(dispatch1_barrier_w),
    .dispatch_unsupported_w(dispatch_unsupported_w),
    .dispatch_valid_w(dispatch_valid_w),
    .drain_complete_w(drain_complete_w),
    .exit_code_o(exit_code_o),
    .exit_is_ebreak_o(exit_is_ebreak_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_valid_o(exit_valid_o),
    .exit_valid_q(exit_valid_q),
    .fetch_req_valid_o(fetch_req_valid_o),
    .fifo_has_packet_w(fifo_has_packet_w),
    .flush_i(flush_i),
    .halted_o(halted_o),
    .halted_q(halted_q),
    .head0_csr_illegal_w(head0_csr_illegal_w),
    .head0_csr_inflight_w(head0_csr_inflight_w),
    .head0_csr_raw_w(head0_csr_raw_w),
    .head0_ecall_raw_w(head0_ecall_raw_w),
    .head0_sfence_raw_w(head0_sfence_raw_w),
    .head0_fencei_raw_w(head0_fencei_raw_w),
    .head0_wfi_raw_w(head0_wfi_raw_w),
    .head0_xret_raw_w(head0_xret_raw_w),
    .head1_csr_raw_w(head1_csr_raw_w),
    .head1_ecall_raw_w(head1_ecall_raw_w),
    .head1_facts_w(head1_facts_w),
    .head1_sfence_raw_w(head1_sfence_raw_w),
    .head1_fencei_raw_w(head1_fencei_raw_w),
    .head1_wfi_raw_w(head1_wfi_raw_w),
    .head1_xret_raw_w(head1_xret_raw_w),
    .head_fetch_fault0_w(head_fetch_fault0_w),
    .head_fetch_fault1_w(head_fetch_fault1_w),
    .head_inst0_w(head_inst0_w),
    .head_inst1_w(head_inst1_w),
    .head_next_pc0_w(head_next_pc0_w),
    .head_next_pc1_w(head_next_pc1_w),
    .head_pc1_w(head_pc1_w),
    .head_pc_w(head_pc_w),
    .head_resp0_w(head_resp0_w),
    .head_resp1_w(head_resp1_w),
    .issue_count_o(issue_count_o),
    .jump_dispatch_fire_w(jump_dispatch_fire_w),
    .jump_dispatch_valid_w(jump_dispatch_valid_w),
    .mstatus_o(mstatus_o),
    .next_fetch_pc_q(next_fetch_pc_q),
    .orphan_stop_pending_w(orphan_stop_pending_w),
    .outstanding_pc_q(outstanding_pc_q),
    .outstanding_valid_q(outstanding_valid_q),
    .pending_arch_trap_fire_w(pending_arch_trap_fire_w),
    .pending_arch_trap_q(pending_arch_trap_q),
    .pending_branch_commit_resolve_w(pending_branch_commit_resolve_w),
    .pending_branch_dispatched_q(pending_branch_dispatched_q),
    .pending_branch_match_clear_w(pending_branch_match_clear_w),
    .pending_branch_misaligned_w(pending_branch_misaligned_w),
    .pending_branch_pc_q(pending_branch_pc_q),
    .pending_branch_q(pending_branch_q),
    .pending_branch_target_w(pending_branch_target_w),
    .pending_control_ready_w(pending_control_ready_w),
    .pending_exit_q(pending_exit_q),
    .pending_jump_dispatched_q(pending_jump_dispatched_q),
    .pending_jump_misaligned_w(pending_jump_misaligned_w),
    .pending_jump_nolink_commit_w(pending_jump_nolink_commit_w),
    .pending_jump_nolink_w(pending_jump_nolink_w),
    .pending_jump_pc_q(pending_jump_pc_q),
    .pending_jump_q(pending_jump_q),
    .pending_jump_redirect_after_dispatch_w(pending_jump_redirect_after_dispatch_w),
    .pending_jump_resolve_ready_w(pending_jump_resolve_ready_w),
    .pending_jump_resolved_target_w(pending_jump_resolved_target_w),
    .pending_mem_q(pending_mem_q),
    .pending_mem_resolve_ready_w(pending_mem_resolve_ready_w),
    .pending_replay_wait_w(pending_replay_wait_w),
    .pending_system_capture_head0_w(pending_system_capture_head0_w),
    .pending_system_capture_lane1_w(pending_system_capture_lane1_w),
    .pending_system_clear_w(pending_system_clear_w),
    .pending_system_csr_commit_w(pending_system_csr_commit_w),
    .head0_csr_commit_w(head0_csr_commit_w),
    .pending_system_csr_q(pending_system_csr_q),
    .pending_system_csr_rdata_q(pending_system_csr_rdata_q),
    .pending_system_dispatched_q(pending_system_dispatched_q),
    .pending_system_ecall_q(pending_system_ecall_q),
    .pending_system_ecall_trap_w(pending_system_ecall_trap_w),
    .pending_system_inst_q(pending_system_inst_q),
    .pending_system_irq_cause_q(pending_system_irq_cause_q),
    .pending_system_irq_q(pending_system_irq_q),
    .pending_system_mret_q(pending_system_mret_q),
    .pending_system_next_pc_q(pending_system_next_pc_q),
    .pending_system_pc_q(pending_system_pc_q),
    .pending_system_q(pending_system_q),
    .pending_system_satp_write_commit_w(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_w(pending_system_sfence_commit_w),
    .pending_system_fencei_commit_w(pending_system_fencei_commit_w),
    .pending_trap_cause_q(pending_trap_cause_q),
    .pmpaddr_o(pmpaddr_o),
    .pmpcfg_o(pmpcfg_o),
    .priv_mode_o(priv_mode_o),
    .priv_predictor_boundary_w(priv_predictor_boundary_w),
    .rob_count_o(rob_count_o),
    .rst(rst),
    .satp_o(satp_o),
    .stop_pending_q(stop_pending_q),
    .svpbmt_en_o(svpbmt_en_o),
    .synth_lane1_branch_drop_match_w(synth_lane1_branch_drop_match_w),
    .synth_lane1_branch_drop_pending_q(synth_lane1_branch_drop_pending_q),
    .synth_lane1_ret_branch_commit0_w(synth_lane1_ret_branch_commit0_w),
    .synth_lane1_ret_branch_seen_q(synth_lane1_ret_branch_seen_q),
    .synth_lane1_ret_pending_q(synth_lane1_ret_pending_q),
    .system_csr_dispatch_fire_w(system_csr_dispatch_fire_w),
    .system_csr_dispatch_valid_w(system_csr_dispatch_valid_w),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_redirect_squash_q(trap_redirect_squash_q),
    .trap_tval_o(trap_tval_o),
    .trap_valid_o(trap_valid_o),
    .trap_valid_q(trap_valid_q)
  );


  OooFrontend #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .FETCH_PACKET_COUNT_W(FETCH_PACKET_COUNT_W)
  ) u_frontend (
    .backend_drained_q(backend_drained_q),
    .backend_drained_w(backend_drained_w),
    .branch_bpu_lookup_bht_valid_w(branch_bpu_lookup_bht_valid_w),
    .branch_bpu_lookup_event_w(branch_bpu_lookup_event_w),
    .branch_bpu_update_correct_w(branch_bpu_update_correct_w),
    .branch_bpu_update_pc_w(branch_bpu_update_pc_w),
    .branch_bpu_update_pred_taken_w(branch_bpu_update_pred_taken_w),
    .branch_bpu_update_taken_w(branch_bpu_update_taken_w),
    .branch_bpu_update_valid_w(branch_bpu_update_valid_w),
    .branch_fallthrough_safe_w(branch_fallthrough_safe_w),
    .branch_prefetch0_imm_unused_w(branch_prefetch0_imm_unused_w),
    .branch_prefetch0_rd_unused_w(branch_prefetch0_rd_unused_w),
    .branch_prefetch0_rs1_unused_w(branch_prefetch0_rs1_unused_w),
    .branch_prefetch0_rs2_unused_w(branch_prefetch0_rs2_unused_w),
    .branch_prefetch1_imm_unused_w(branch_prefetch1_imm_unused_w),
    .branch_prefetch1_rd_unused_w(branch_prefetch1_rd_unused_w),
    .branch_prefetch1_rs1_unused_w(branch_prefetch1_rs1_unused_w),
    .branch_prefetch1_rs2_unused_w(branch_prefetch1_rs2_unused_w),
    .branch_prefetch_hit_available_w(branch_prefetch_hit_available_w),
    .branch_prefetch_req_fire_w(branch_prefetch_req_fire_w),
    .branch_prefetch_rsp1_imm_unused_w(branch_prefetch_rsp1_imm_unused_w),
    .branch_prefetch_rsp1_rd_unused_w(branch_prefetch_rsp1_rd_unused_w),
    .branch_prefetch_rsp1_rs1_unused_w(branch_prefetch_rsp1_rs1_unused_w),
    .branch_prefetch_rsp1_rs2_unused_w(branch_prefetch_rsp1_rs2_unused_w),
    .branch_resolve_pending_match_w(branch_resolve_pending_match_w),
    .branch_resolve_redirect_w(branch_resolve_redirect_w),
    .branch_resolve_untracked_redirect_w(branch_resolve_untracked_redirect_w),
    .branch_resolve_untracked_w(branch_resolve_untracked_w),
    .branch_spec_active_q(branch_spec_active_q),
    .branch_spec_checkpoint_capture_w(branch_spec_checkpoint_capture_w),
    .branch_spec_checkpoint_pending_q(branch_spec_checkpoint_pending_q),
    .branch_spec_dispatch_block_w(branch_spec_dispatch_block_w),
    .branch_spec_pred_match_w(branch_spec_pred_match_w),
    .branch_spec_redirect_w(branch_spec_redirect_w),
    .branch_spec_resolve_valid_w(branch_spec_resolve_valid_w),
    .branch_spec_restore_w(branch_spec_restore_w),
    .branch_target_cache_hit_w(branch_target_cache_hit_w),
    .branch_target_capture_ctrl_w(branch_target_capture_ctrl_w),
    .branch_target_capture_imm_unused_w(branch_target_capture_imm_unused_w),
    .branch_target_capture_rd_unused_w(branch_target_capture_rd_unused_w),
    .branch_target_capture_rs1_unused_w(branch_target_capture_rs1_unused_w),
    .branch_target_capture_rs2_unused_w(branch_target_capture_rs2_unused_w),
    .can_run_w(can_run_w),
    .clk(clk),
    .commit_ready_i(commit_ready_i),
    .core_branch_resolve_misaligned_w(core_branch_resolve_misaligned_w),
    .core_branch_resolve_mispredict_w(core_branch_resolve_mispredict_w),
    .core_branch_resolve_is_branch_w(core_branch_resolve_is_branch_w),
    .core_branch_resolve_taken_w(core_branch_resolve_taken_w),
    .core_branch_resolve_pred_taken_w(core_branch_resolve_pred_taken_w),
    .core_branch_resolve_bht_idx_w(core_branch_resolve_bht_idx_w),
    .core_branch_resolve_next_pc_w(core_branch_resolve_next_pc_w),
    .core_branch_resolve_pc_w(core_branch_resolve_pc_w),
    .core_branch_resolve_valid_w(core_branch_resolve_valid_w),
    .core_commit0_inst_w(core_commit0_inst_w),
    .core_commit0_valid_w(core_commit0_valid_w),
    .core_commit1_inst_w(core_commit1_inst_w),
    .core_commit1_valid_w(core_commit1_valid_w),
    .core_dispatch0_csr_rdata_w(core_dispatch0_csr_rdata_w),
    .core_dispatch0_fire_w(core_dispatch0_fire_w),
    .core_dispatch0_inst_w(core_dispatch0_inst_w),
    .core_dispatch0_next_pc_w(core_dispatch0_next_pc_w),
    .core_dispatch0_pc_w(core_dispatch0_pc_w),
    .core_dispatch0_valid_w(core_dispatch0_valid_w),
    .core_dispatch0_pred_npc_w(core_dispatch0_pred_npc_w),
    .core_dispatch0_bht_idx_w(core_dispatch0_bht_idx_w),
    .core_dispatch0_pred_taken_w(core_dispatch0_pred_taken_w),
    .core_dispatch1_inst_w(core_dispatch1_inst_w),
    .core_dispatch1_next_pc_w(core_dispatch1_next_pc_w),
    .core_dispatch1_pc_w(core_dispatch1_pc_w),
    .core_dispatch1_valid_w(core_dispatch1_valid_w),
    .core_dispatch1_pred_npc_w(core_dispatch1_pred_npc_w),
    .core_dispatch1_bht_idx_w(core_dispatch1_bht_idx_w),
    .core_dispatch1_pred_taken_w(core_dispatch1_pred_taken_w),
    .core_dispatch_branch_resolve_misaligned_w(core_dispatch_branch_resolve_misaligned_w),
    .core_dispatch_branch_resolve_next_pc_w(core_dispatch_branch_resolve_next_pc_w),
    .core_dispatch_branch_resolve_pc_w(core_dispatch_branch_resolve_pc_w),
    .core_dispatch_branch_resolve_valid_w(core_dispatch_branch_resolve_valid_w),
    .core_mem_idle_w(core_mem_idle_w),
    .core_pending_load_branch_dep_w(core_pending_load_branch_dep_w),
    .core_serial_flush_q(core_serial_flush_q),
    .core_trap_flush_q(core_trap_flush_q),
    .csr_irq_pending_w(csr_irq_pending_w),
    .csr_mstatus_w(csr_mstatus_w),
    .csr_frm_w(csr_frm_w),
    .csr_priv_mode_w(csr_priv_mode_w),
    .csr_ret_target_w(csr_ret_target_w),
    .csr_trap_ex_valid_w(csr_trap_ex_valid_w),
    .csr_trap_irq_valid_w(csr_trap_irq_valid_w),
    .csr_trap_mem_valid_w(csr_trap_mem_valid_w),
    .csr_trap_target_w(csr_trap_target_w),
    .ctrl_commit_valid_q(ctrl_commit_valid_q),
    .direct_branch0_dispatch_valid_w(direct_branch0_dispatch_valid_w),
    .direct_branch0_fire_w(direct_branch0_fire_w),
    .direct_branch0_lane1_ret_w(direct_branch0_lane1_ret_w),
    .direct_branch1_fire_w(direct_branch1_fire_w),
    .direct_branch_resolve_next_pc_w(direct_branch_resolve_next_pc_w),
    .direct_branch_resolve_redirect_w(direct_branch_resolve_redirect_w),
    .direct_branch_spec_start_w(direct_branch_spec_start_w),
    .direct_frontend_flush_w(direct_frontend_flush_w),
    .direct_jal0_dispatch_valid_w(direct_jal0_dispatch_valid_w),
    .direct_jal_call_w(direct_jal_call_w),
    .direct_redirect_fetch_w(direct_redirect_fetch_w),
    .direct_ret0_fire_w(direct_ret0_fire_w),
    .direct_ret1_fire_w(direct_ret1_fire_w),
    .discard_fetch_rsp_q(discard_fetch_rsp_q),
    .dispatch0_arch_trap_w(dispatch0_arch_trap_w),
    .dispatch0_branch_w(dispatch0_branch_w),
    .dispatch0_exit_w(dispatch0_exit_w),
    .dispatch0_fp_w(dispatch0_fp_w),
    .dispatch0_jal_w(dispatch0_jal_w),
    .dispatch0_jump_w(dispatch0_jump_w),
    .dispatch0_ready_w(dispatch0_ready_w),
    .dispatch0_return_w(dispatch0_return_w),
    .dispatch0_system_w(dispatch0_system_w),
    .dispatch0_unsupported_raw_w(dispatch0_unsupported_raw_w),
    .dispatch0_unsupported_w(dispatch0_unsupported_w),
    .dispatch1_barrier_fire_w(dispatch1_barrier_fire_w),
    .dispatch1_barrier_w(dispatch1_barrier_w),
    .dispatch1_optional_w(dispatch1_optional_w),
    .dispatch1_ready_w(dispatch1_ready_w),
    .dispatch1_unsupported_raw_w(dispatch1_unsupported_raw_w),
    .dispatch1_unsupported_w(dispatch1_unsupported_w),
    .dispatch_fire_w(dispatch_fire_w),
    .dispatch_unsupported_w(dispatch_unsupported_w),
    .dispatch_valid_w(dispatch_valid_w),
    .e4_redirect_valid_o(e4_redirect_valid_w),
    .e4_redirect_pc_o(e4_redirect_pc_w),
    .drain_complete_w(drain_complete_w),
    .execute0_valid_unused_w(execute0_valid_unused_w),
    .execute1_valid_unused_w(execute1_valid_unused_w),
    .exit_valid_q(exit_valid_q),
    .fetch_req_fire_w(fetch_req_fire_w),
    .fetch_req_pc_o(fetch_req_pc_o),
    .fetch_req_ready_i(fetch_req_ready_i),
    .fetch_req_valid_o(fetch_req_valid_o),
    .fetch_rsp_bypass_consumed_w(fetch_rsp_bypass_consumed_w),
    .fetch_rsp_enqueue_w(fetch_rsp_enqueue_w),
    .fetch_rsp_fire_w(fetch_rsp_fire_w),
    .fetch_rsp_inst0_i(fetch_rsp_inst0_i),
    .fetch_rsp_inst1_i(fetch_rsp_inst1_i),
    .fetch_rsp_ready_o(fetch_rsp_ready_o),
    .fetch_rsp_resp0_i(fetch_rsp_resp0_i),
    .fetch_rsp_resp1_i(fetch_rsp_resp1_i),
    .fetch_rsp_valid_i(fetch_rsp_valid_i),
    .fifo_has_packet_w(fifo_has_packet_w),
    .flush_i(flush_i),
    .halted_q(halted_q),
    .head0_arch_trap_raw_w(head0_arch_trap_raw_w),
    .head0_csr_inflight_w(head0_csr_inflight_w),
    .head0_csr_raw_w(head0_csr_raw_w),
    .head0_ctrl_w(head0_ctrl_w),
    .head0_ecall_raw_w(head0_ecall_raw_w),
    .head0_facts_w(head0_facts_w),
    .head0_rd_unused_w(head0_rd_unused_w),
    .head0_sfence_raw_w(head0_sfence_raw_w),
    .head0_fencei_raw_w(head0_fencei_raw_w),
    .head0_stop_raw_w(head0_stop_raw_w),
    .head0_system_raw_w(head0_system_raw_w),
    .head0_wfi_raw_w(head0_wfi_raw_w),
    .head0_xret_raw_w(head0_xret_raw_w),
    .head1_control_raw_w(head1_control_raw_w),
    .head1_csr_raw_w(head1_csr_raw_w),
    .head1_ctrl_w(head1_ctrl_w),
    .head1_ecall_raw_w(head1_ecall_raw_w),
    .head1_facts_w(head1_facts_w),
    .head1_mem_raw_w(head1_mem_raw_w),
    .head1_rd_unused_w(head1_rd_unused_w),
    .head1_sfence_raw_w(head1_sfence_raw_w),
    .head1_fencei_raw_w(head1_fencei_raw_w),
    .head1_stop_raw_w(head1_stop_raw_w),
    .head1_wfi_raw_w(head1_wfi_raw_w),
    .head1_xret_raw_w(head1_xret_raw_w),
    .head_fetch_fault0_w(head_fetch_fault0_w),
    .head_fetch_fault1_w(head_fetch_fault1_w),
    .head_fetch_fault_w(head_fetch_fault_w),
    .head_inst0_w(head_inst0_w),
    .head_inst1_w(head_inst1_w),
    .head_next_pc0_w(head_next_pc0_w),
    .head_next_pc1_w(head_next_pc1_w),
    .head_packet_next_pc_w(head_packet_next_pc_w),
    .head_pc1_w(head_pc1_w),
    .head_pc_w(head_pc_w),
    .head_resp0_w(head_resp0_w),
    .head_resp1_w(head_resp1_w),
    .jalr_prefetch_hit_available_w(jalr_prefetch_hit_available_w),
    .jump_dispatch_fire_w(jump_dispatch_fire_w),
    .jump_dispatch_valid_w(jump_dispatch_valid_w),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_write_o(mem_req_write_o),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .next_fetch_pc_q(next_fetch_pc_q),
    .orphan_stop_pending_w(orphan_stop_pending_w),
    .outstanding_pc_q(outstanding_pc_q),
    .outstanding_valid_q(outstanding_valid_q),
    .pending_arch_trap_q(pending_arch_trap_q),
    .pending_branch_bht_valid_q(pending_branch_bht_valid_q),
    .pending_branch_cmp_op_q(pending_branch_cmp_op_q),
    .pending_branch_commit_resolve_w(pending_branch_commit_resolve_w),
    .pending_branch_dispatched_q(pending_branch_dispatched_q),
    .pending_branch_inst_q(pending_branch_inst_q),
    .pending_branch_match_clear_w(pending_branch_match_clear_w),
    .pending_branch_misaligned_w(pending_branch_misaligned_w),
    .pending_branch_next_pc_w(pending_branch_next_pc_w),
    .pending_branch_pc_q(pending_branch_pc_q),
    .pending_branch_q(pending_branch_q),
    .pending_branch_rs1_q(pending_branch_rs1_q),
    .pending_branch_rs2_q(pending_branch_rs2_q),
    .pending_branch_taken_w(pending_branch_taken_w),
    .pending_branch_target_w(pending_branch_target_w),
    .pending_control_ready_w(pending_control_ready_w),
    .pending_exit_q(pending_exit_q),
    .pending_jump_call_fire_w(pending_jump_call_fire_w),
    .pending_jump_dispatched_q(pending_jump_dispatched_q),
    .pending_jump_imm_q(pending_jump_imm_q),
    .pending_jump_inst_q(pending_jump_inst_q),
    .pending_jump_jalr_btb_hit_w(pending_jump_jalr_btb_hit_w),
    .pending_jump_jalr_q(pending_jump_jalr_q),
    .pending_jump_jalr_sum_lsb_unused_w(pending_jump_jalr_sum_lsb_unused_w),
    .pending_jump_misaligned_w(pending_jump_misaligned_w),
    .pending_jump_nolink_commit_w(pending_jump_nolink_commit_w),
    .pending_jump_nolink_w(pending_jump_nolink_w),
    .pending_jump_pc_q(pending_jump_pc_q),
    .pending_jump_q(pending_jump_q),
    .pending_jump_redirect_after_dispatch_w(pending_jump_redirect_after_dispatch_w),
    .pending_jump_resolve_ready_w(pending_jump_resolve_ready_w),
    .pending_jump_resolved_target_w(pending_jump_resolved_target_w),
    .pending_jump_return_fire_w(pending_jump_return_fire_w),
    .pending_jump_rs1_data_w(pending_jump_rs1_data_w),
    .pending_jump_rs1_q(pending_jump_rs1_q),
    .pending_mem_next_pc_q(pending_mem_next_pc_q),
    .pending_mem_q(pending_mem_q),
    .pending_mem_resolve_ready_w(pending_mem_resolve_ready_w),
    .pending_system_csr_commit_w(pending_system_csr_commit_w),
    // 【serialize Phase1】head0-CSR 队头提交拍 redirect(seed 清 + pc-seq 重取) + §4#1 合法 CSR 放行判定。
    .head0_csr_commit_w(head0_csr_commit_w),
    .core_commit0_next_pc_w(core_commit0_next_pc_w),
    .head0_csr_illegal_i(head0_csr_illegal_w),
    .pending_system_csr_rdata_q(pending_system_csr_rdata_q),
    .pending_system_ecall_q(pending_system_ecall_q),
    .pending_system_inst_q(pending_system_inst_q),
    .pending_system_irq_q(pending_system_irq_q),
    .pending_system_mret_q(pending_system_mret_q),
    .pending_system_next_pc_q(pending_system_next_pc_q),
    .pending_system_pc_q(pending_system_pc_q),
    .pending_system_q(pending_system_q),
    .pending_system_satp_write_commit_w(pending_system_satp_write_commit_w),
    .priv_predictor_boundary_w(priv_predictor_boundary_w),
    .ras_empty_w(ras_empty_w),
    .ras_full_w(ras_full_w),
    .redirect_fetch_req_valid_w(redirect_fetch_req_valid_w),
    .reset_pc_i(reset_pc_i),
    .return_cont_attempt_ready_w(return_cont_attempt_ready_w),
    .rob_count_o(rob_count_o),
    .rst(rst),
    .run_i(run_i),
    .stop_pending_q(stop_pending_q),
    .synth_lane1_branch_append_w(synth_lane1_branch_append_w),
    .synth_lane1_branch_drop_pending_q(synth_lane1_branch_drop_pending_q),
    .synth_lane1_ret_pending_q(synth_lane1_ret_pending_q),
    .system_csr_dispatch_fire_w(system_csr_dispatch_fire_w),
    .system_csr_dispatch_valid_w(system_csr_dispatch_valid_w),
    .trap_redirect_squash_q(trap_redirect_squash_q),
    .trap_valid_q(trap_valid_q)
  );

`ifdef OOO_ASSERT
  // ════ 【P4 shadow】统一 redirect 年龄律仲裁器 影子等价段（pipeline-stage-boundary.md §5）════
  // assert-then-converge：复活的 OooRedirectArbiter 并行计算赢家，每拍断言与现行散落 redirect
  // 逻辑（OooFetchPcOutstandingSequencer 隐式文本序 + FetchRequestMux 优先级链）等价；全绿后
  // 才切消费点。本段仅 OOO_ASSERT 下编译，不驱动任何功能信号，零综合影响。
  // 事件族映射（ooo-flush-redirect-contract.md）：覆盖 E1/E3/E4/E5/E6——默认 flag 下
  // next_fetch_pc_q 的全部活跃终态写者（=Sequencer INV-2 的 cond_b/d/e/f 谓词集）。
  // E2/E5-head0 支 flag=0 零 exercise（幸存者偏差，shadow 全绿不构成其等价证据）；
  // E7/E8/E9 半死/影子臂进排除谓词；E10 掩码/E11 mmu_flush 与控制流正交，不并入。
  // 已知双写漂移风险：本段谓词与 Sequencer 内 INV-2 谓词是同一文本序的两份人工镜像，
  // 漂移方向=断言误报（fail-loud，可接受）。

  // ── commit 家族 pre-mux（E1>E5>E6，照 OooFetchPcOutstandingSequencer 文本序）──
  // E1: commit trap/xret（seq:271，文本最后=最高优先；恒 ROB head，age≡0）
  wire shadow_e1_valid_w = csr_trap_mem_valid_w;
  // E5: CSR 提交 redirect（seq:210-216）。head0 支默认 flag=0 恒 0（零 exercise）。
  wire shadow_e5_valid_w = !direct_frontend_flush_w &&
      (pending_system_csr_commit_w || head0_csr_commit_w);
  wire [`XLEN-1:0] shadow_e5_pc_w =
      head0_csr_commit_w ? core_commit0_next_pc_w : pending_system_next_pc_q;
  // E6: drain 终态（seq:217-255），owner 序 arch_trap>system>branch>jump>mem 照抄。
  // seq 的 drain_complete_i 在 u_frontend 内为 stop_pending_q && drain_complete_w。
  wire shadow_e6_base_w = !csr_trap_mem_valid_w && !direct_frontend_flush_w &&
      stop_pending_q && drain_complete_w;
  wire shadow_e6_branch_undisp_w = pending_branch_q && !pending_branch_dispatched_q;
  wire shadow_e6_sel_arch_w = pending_arch_trap_q;
  wire shadow_e6_sel_system_w = !pending_arch_trap_q && pending_system_q;
  wire shadow_e6_sel_branch_w = !pending_arch_trap_q && !pending_system_q &&
      shadow_e6_branch_undisp_w;
  wire shadow_e6_sel_jump_w = !pending_arch_trap_q && !pending_system_q &&
      !shadow_e6_branch_undisp_w && pending_jump_q;
  wire shadow_e6_sel_mem_w = !pending_arch_trap_q && !pending_system_q &&
      !shadow_e6_branch_undisp_w && !pending_jump_q && pending_mem_q;  // 恒 0（死硅 tie-off）
  // misaligned 的 E6-branch 臂不写 next_fetch_pc（seq:236 门）→ 不算 PC 赢家。
  wire shadow_e6_valid_w = shadow_e6_base_w &&
      (shadow_e6_sel_arch_w || shadow_e6_sel_system_w ||
       (shadow_e6_sel_branch_w && !pending_branch_misaligned_w) ||
       shadow_e6_sel_jump_w || shadow_e6_sel_mem_w);
  // E6-jump 臂目标：seq 用 jalr_prefetch_hit ? hit_packet_next_pc : pending_jump_target，
  // 二者在 u_frontend 内均为死硅 tie-0（OooFrontend.v jalr prefetch 家族/pending_jump_target_q）
  // → 此处忠实镜像为常量 0（该臂若真触发即是 bug，PC 断言会连带暴露）。
  wire [`XLEN-1:0] shadow_e6_pc_w =
      shadow_e6_sel_arch_w ? csr_trap_target_w :
      shadow_e6_sel_system_w ?
          ((pending_system_ecall_q || pending_system_irq_q) ? csr_trap_target_w :
           (pending_system_mret_q ? csr_ret_target_w : pending_system_next_pc_q)) :
      shadow_e6_sel_branch_w ? pending_branch_next_pc_w :
      shadow_e6_sel_jump_w ? {`XLEN{1'b0}} :
      pending_mem_next_pc_q;

  // ── E3 branch 口（契约 §5.2，rob_idx 已 plumb）── misaligned 拍现行不写 next_fetch_pc
  // （seq:145/:185/:264 门）→ valid 必须含 !misaligned，否则 shadow 单方有赢家而现行不写=误报。
  wire shadow_branch_valid_w =
      branch_resolve_untracked_w && !core_branch_resolve_misaligned_w;

  // ── GAP-2 甲门（现行序，切换时删除=行为变化单独验证）──
  // 现行 else-if 链让 E3-untracked（seq:178/:263）压过 E5（:210）/E6（:217）；纯年龄律则
  // commit 家族（age0 最老）应胜。把现行序显式编码进 shadow 输入端使等价断言全域可判；
  // 本门是 GAP-2 的可 grep 实体。用 raw untracked（不含 !misaligned）镜像 seq:178 的
  // arm-taken 抢占（其条件不含 misaligned，misaligned 拍同样吃掉 else-if 链后续臂）。
  // E1（seq:271 文本最后）不受此门。
  wire shadow_commit_gate_w = !branch_resolve_untracked_w;  // GAP-2 现行序，切换时删除
  wire shadow_trap_valid_w = shadow_e1_valid_w ||
      ((shadow_e5_valid_w || shadow_e6_valid_w) && shadow_commit_gate_w);
  wire [`XLEN-1:0] shadow_trap_pc_w =
      shadow_e1_valid_w ? csr_trap_target_w :
      shadow_e5_valid_w ? shadow_e5_pc_w : shadow_e6_pc_w;

  // ── 排除谓词：E7/E8/E9 臂（半死/影子态，契约排除集）在场的拍不作等价判定 ──
  // 漂移方向=断言少判（fail-safe）；这些臂若复活应回填 shadow 口而非扩大排除集。
  wire shadow_no_excluded_arm_w =
      !pending_branch_commit_resolve_w &&   // E7 commit-resolve 臂（seq:151）
      !pending_branch_match_clear_w &&      // E7 match-clear 臂（seq:159）
      !pending_jump_resolve_ready_w &&      // E8 jump resolve 臂（seq:188）
      !branch_spec_resolve_valid_w;         // E9 branch_spec restore 臂（seq:137）

  // ── shadow arbiter 实例（纯组合年龄律 argmin 单赢家，B2 共享地基复活件）──
  wire shadow_redirect_valid_w;
  wire [`XLEN-1:0] shadow_redirect_pc_w;
  wire [ROB_INDEX_W-1:0] shadow_redirect_kill_idx_w;
  wire [`REDIR_REASON_W-1:0] shadow_redirect_reason_w;
  wire shadow_redirect_flush_fetch_w;
  wire shadow_redirect_flush_backend_w;
  OooRedirectArbiter u_shadow_redirect_arbiter (
    .rob_head_idx_i(core_rob_head_idx_w),
    // trap 口 = commit 家族（E1/E5/E6 pre-mux）：commit-time 源恒 ROB head（age≡0）
    .trap_valid_i(shadow_trap_valid_w),
    .trap_pc_i(shadow_trap_pc_w),
    .trap_rob_idx_i(core_rob_head_idx_w),
    .trap_reason_i(`REDIR_REASON_TRAP),
    .trap_flush_fetch_i(1'b1),
    .trap_flush_backend_i(1'b1),
    // branch 口 = E3（后端 resolve 已带真 rob_idx）
    .branch_valid_i(shadow_branch_valid_w),
    .branch_pc_i(core_branch_resolve_next_pc_w),
    .branch_rob_idx_i(core_branch_resolve_rob_idx_w),
    .branch_reason_i(`REDIR_REASON_BRANCH_MISS),
    .branch_flush_fetch_i(1'b1),
    .branch_flush_backend_i(1'b1),
    // direct 口 = E4：取指侧无 age（契约"最大缺口"），喂 head-1 哨兵（age=2^W-1 恒最年轻——
    // dispatch 拍指令构造上年轻于任何后端已解析分支；tie 时类序 branch>direct 兜底仍正确）
    .direct_valid_i(e4_redirect_valid_w),
    .direct_pc_i(e4_redirect_pc_w),
    .direct_rob_idx_i(core_rob_head_idx_w - {{(ROB_INDEX_W-1){1'b0}}, 1'b1}),
    .direct_reason_i(`REDIR_REASON_DIRECT),
    .direct_flush_fetch_i(1'b1),
    .direct_flush_backend_i(1'b0),
    .redirect_valid_o(shadow_redirect_valid_w),
    .redirect_pc_o(shadow_redirect_pc_w),
    .redirect_kill_idx_o(shadow_redirect_kill_idx_w),
    .redirect_reason_o(shadow_redirect_reason_w),
    .redirect_flush_fetch_o(shadow_redirect_flush_fetch_w),
    .redirect_flush_backend_o(shadow_redirect_flush_backend_w)
  );
  wire shadow_win_branch_w = shadow_redirect_valid_w &&
      (shadow_redirect_reason_w == `REDIR_REASON_BRANCH_MISS);
  wire shadow_arb_unused_w = shadow_redirect_flush_fetch_w |
      shadow_redirect_flush_backend_w | (|shadow_redirect_kill_idx_w);

  // ── 赢家寄存：事件拍 t 组合算赢家 → 寄存 → t+1 与 nonblocking 落盘的现行决策对照。
  // 复位域镜像 u_fetch_pc_outstanding 的 rst||flush_i（flush 拍事件写不落盘）；
  // nuke 期望同镜像 FlushSequencer/CommitSequencer 的 rst||flush_i 域。
  reg shadow_valid_q;
  reg [`XLEN-1:0] shadow_pc_q;
  reg shadow_nuke_exp_q;
  always @(posedge clk) begin
    if (rst || flush_i) begin
      shadow_valid_q <= 1'b0;
      shadow_pc_q <= {`XLEN{1'b0}};
      shadow_nuke_exp_q <= 1'b0;
    end else begin
      shadow_valid_q <= shadow_redirect_valid_w && shadow_no_excluded_arm_w;
      shadow_pc_q <= shadow_redirect_pc_w;
      shadow_nuke_exp_q <= csr_trap_mem_valid_w || head0_csr_commit_w;
    end
  end

  always @(posedge clk) if (!rst) begin
    // SHADOW-EQ-PC（主证据断言）：上拍 shadow 有赢家（且非排除拍）→ 本拍 next_fetch_pc_q
    // 必等赢家 PC——现行机制隐式文本序 vs 年龄律（+GAP-2 甲门）全域等价。
    if (shadow_valid_q && (next_fetch_pc_q !== shadow_pc_q))
      $error("[P4-SHADOW-EQ-PC] shadow 赢家 PC 与现行 next_fetch_pc 不一致: shadow=%h rtl=%h @%0t",
             shadow_pc_q, next_fetch_pc_q, $time);
    // SHADOW-EQ-KILL：E3 组合同拍——shadow branch 口赢家 ⟺ 现行 untracked redirect fire。
    // E1 同拍排除进 oracle：E1 恒 age0 必胜 branch（现行文本序 seq:271 亦压过 :263），
    // 该拍后端 kill（ROB-walk）仍独立发出，不属本断言口径。
    if (shadow_no_excluded_arm_w &&
        (shadow_win_branch_w !== (branch_resolve_untracked_w &&
                                  !core_branch_resolve_misaligned_w &&
                                  !csr_trap_mem_valid_w)))
      $error("[P4-SHADOW-EQ-KILL] shadow branch 赢家与现行 untracked redirect 不一致: win=%b untracked=%b misalign=%b e1=%b @%0t",
             shadow_win_branch_w, branch_resolve_untracked_w,
             core_branch_resolve_misaligned_w, csr_trap_mem_valid_w, $time);
    // SHADOW-EQ-NUKE：上拍 E1/head0-CSR 类赢家 ⟺ 本拍 core_trap_flush_q∥core_serial_flush_q
    //（后端 nuke 晚 1 拍寄存：OooControlFlushSequencer/OooControlCommitSequencer）。
    // 诚实标注：与 E1 同源近恒真，价值=钉住 trap_flush_req/serial_flush 源不被改接。
    if (shadow_nuke_exp_q !== (core_trap_flush_q || core_serial_flush_q))
      $error("[P4-SHADOW-EQ-NUKE] E1/head0-CSR 赢家与后端 nuke 脉冲不一致: exp=%b trap_flush=%b serial_flush=%b @%0t",
             shadow_nuke_exp_q, core_trap_flush_q, core_serial_flush_q, $time);
  end
`endif

endmodule
/* verilator lint_on UNOPTFLAT */
