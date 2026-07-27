`include "define.v"
`include "common/OooSlotFacts.v"

// OooControlPlane: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 13 个实例）。
// 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。
module OooControlPlane #(
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W,
  parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W
) (
  input [`XLEN-1:0] a0_data_w,
  input backend_drained_q,
  input branch_resolve_pending_match_w,
  input branch_resolve_untracked_w,
  input branch_spec_active_q,
  input branch_spec_checkpoint_capture_w,
  input branch_spec_checkpoint_pending_q,
  input branch_spec_resolve_valid_w,
  input branch_spec_restore_w,
  input can_run_w,
  input clk,
  input commit_ready_i,
  input core_branch_resolve_misaligned_w,
  input core_branch_resolve_mispredict_w,
  input [`XLEN-1:0] core_branch_resolve_next_pc_w,
  input [`XLEN-1:0] core_branch_resolve_pc_w,
  input core_branch_resolve_valid_w,
  input [`TRAP_CAUSE_W-1:0] core_commit0_cause_w,
  input core_commit0_exception_w,
  input [`INST_W-1:0] core_commit0_inst_w,
  input [`XLEN-1:0] core_commit0_pc_w,
  input [`XLEN-1:0] core_commit0_tval_w,
  input core_commit0_valid_w,
  input [PRODUCER_ID_W-1:0] core_commit0_producer_id_w,
  input [`TRAP_CAUSE_W-1:0] core_commit1_cause_w,
  input core_commit1_exception_w,
  input [`XLEN-1:0] core_commit1_pc_w,
  input [`XLEN-1:0] core_commit1_tval_w,
  input core_commit1_valid_w,
  input [`XLEN * `REG_NUM - 1:0] core_debug_gprs_w,
  input core_trap_flush_apply_i,
  input core_serial_flush_q,
  input [`TRAP_CAUSE_W-1:0] csr_ecall_cause_w,
  input csr_illegal_w,
  input [`TRAP_CAUSE_W-1:0] csr_irq_cause_w,
  input csr_irq_pending_w,
  input [`XLEN-1:0] csr_mstatus_w,
  input [`PMP_ADDR_BUS_W-1:0] csr_pmpaddr_w,
  input [`PMP_CFG_BUS_W-1:0] csr_pmpcfg_w,
  input [1:0] csr_priv_mode_w,
  input [`XLEN-1:0] csr_rdata_w,
  input [`XLEN-1:0] csr_satp_w,
  input csr_svpbmt_en_w,
  input ctrl_commit_valid_q,
  input direct_branch0_dispatch_valid_w,
  input direct_branch0_fire_w,
  input direct_branch1_fire_w,
  input direct_branch_resolve_redirect_w,
  input direct_frontend_flush_w,
  input direct_jal0_dispatch_valid_w,
  input dispatch0_arch_trap_w,
  input dispatch0_branch_w,
  input dispatch0_exit_w,
  input [`OOO_SLOT_FACTS_W-1:0] dispatch0_facts_w,
  input dispatch0_fp_w,
  input dispatch0_jal_w,
  input dispatch0_jump_w,
  input dispatch0_ready_w,
  input core_dispatch0_fire_w,
  input [PRODUCER_ID_W-1:0] core_dispatch0_producer_id_w,
  input dispatch0_return_w,
  input dispatch0_system_w,
  input dispatch0_unsupported_w,
  input dispatch1_barrier_fire_w,
  input dispatch1_barrier_w,
  input dispatch_unsupported_w,
  input dispatch_valid_w,
  input fetch_req_valid_o,
  input fifo_has_packet_w,
  input flush_i,
  input head0_csr_dispatch_fire_w,
  input head0_csr_inflight_w,   // 【serialize Phase1 §10.4】head0-CSR 在飞 → stop 保持
  input head0_csr_raw_w,
  input head0_ecall_raw_w,
  input head0_sfence_raw_w,
  input head0_fencei_raw_w,
  input head0_wfi_raw_w,
  input head0_xret_raw_w,
  input head1_csr_raw_w,
  input head1_ecall_raw_w,
  input [`OOO_SLOT_FACTS_W-1:0] head1_facts_w,
  input head1_sfence_raw_w,
  input head1_fencei_raw_w,
  input head1_wfi_raw_w,
  input head1_xret_raw_w,
  input head_fetch_fault0_w,
  input head_fetch_fault1_w,
  input [`XLEN-1:0] head_fetch_fault_tval_w,
  input [`INST_W-1:0] head_inst0_w,
  input [`INST_W-1:0] head_inst1_w,
  input [`XLEN-1:0] head_next_pc0_w,
  input [`XLEN-1:0] head_next_pc1_w,
  input [`XLEN-1:0] head_pc1_w,
  input [`XLEN-1:0] head_pc_w,
  input [1:0] head_resp0_w,
  input [1:0] head_resp1_w,
  input [ISSUE_COUNT_W-1:0] issue_count_o,
  input jump_dispatch_fire_w,
  input [`XLEN-1:0] next_fetch_pc_q,
  input orphan_stop_pending_w,
  input [`XLEN-1:0] outstanding_pc_q,
  input outstanding_valid_q,
  input pending_branch_dispatched_q,
  input pending_branch_misaligned_w,
  input [`XLEN-1:0] pending_branch_pc_q,
  input pending_branch_q,
  input [`XLEN-1:0] pending_branch_target_w,
  input pending_control_ready_w,
  input pending_jump_dispatched_q,
  input pending_jump_misaligned_w,
  input pending_jump_nolink_commit_w,
  input pending_jump_nolink_w,
  input [`XLEN-1:0] pending_jump_pc_q,
  input pending_jump_q,
  input pending_jump_redirect_after_dispatch_w,
  input pending_jump_resolve_ready_w,
  input [`XLEN-1:0] pending_jump_resolved_target_w,
  // pending_mem 全链已删除；本 sensor 仅供 trap-exit-mux/observable 读取（恒 0，父模块 tie-off）。
  input pending_mem_q,
  input [ROB_COUNT_W-1:0] rob_count_o,
  input rst,
  input synth_lane1_branch_drop_match_w,
  input synth_lane1_branch_drop_pending_q,
  input synth_lane1_ret_branch_commit0_w,
  input synth_lane1_ret_branch_seen_q,
  input synth_lane1_ret_pending_q,
  // 【LSQ·SQ 切换】退休侧访存静默(SQ 排空且无 drain 在飞), AND 进 backend_drained
  input mem_retire_quiet_i,
  // Complete memory-owner quiet (MIQ/bridge/reservation), used only by
  // ordinary FENCE's stronger ordering boundary.
  input mem_idle_i,
  // V9Y exact phase boundary: active holders are empty or make a verified
  // same-edge transfer; collector-pending tokens need not be tracker-freed.
  input mem_owner_terminalized_i,
  input core_checkpoint_restore_apply_i,
  output backend_drained_w,
  output checkpoint_mem_flush_q,
  output core_checkpoint_capture_w,
  output core_checkpoint_quiesce_w,
  output core_checkpoint_restore_w,
  output core_commit1_block_w,
  output core_commit_ready_w,
  output core_local_flush_w,
  output core_mem_issue_block_w,
  output core_trap_flush_q,
  output [11:0] csr_access_addr_w,
  output [2:0] csr_access_funct3_w,
  output [`XLEN-1:0] csr_access_rs1_data_w,
  output [`REG_ADDR_W-1:0] csr_access_rs1_idx_w,
  output csr_access_valid_w,
  output [11:0] csr_probe_addr_w,
  output [2:0] csr_probe_funct3_w,
  output [`REG_ADDR_W-1:0] csr_probe_rs1_idx_w,
  output csr_probe_valid_w,
  output csr_mret_valid_w,
  output csr_real_mret_valid_w,
  output csr_sret_valid_w,
  output [`TRAP_CAUSE_W-1:0] csr_trap_ex_cause_w,
  output [`XLEN-1:0] csr_trap_ex_pc_w,
  output [`XLEN-1:0] csr_trap_ex_tval_w,
  output csr_trap_ex_valid_w,
  output [`TRAP_CAUSE_W-1:0] csr_trap_irq_cause_w,
  output [`XLEN-1:0] csr_trap_irq_pc_w,
  output csr_trap_irq_valid_w,
  output [`TRAP_CAUSE_W-1:0] csr_trap_mem_cause_w,
  output [`XLEN-1:0] csr_trap_mem_pc_w,
  output [`XLEN-1:0] csr_trap_mem_tval_w,
  output csr_trap_mem_valid_w,
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o,
  output [`XLEN-1:0] debug_pc_o,
  output [`CORE_STATE_W-1:0] debug_state_o,
  output drain_complete_w,
  output [`XLEN-1:0] exit_code_o,
  output exit_is_ebreak_o,
  output exit_is_ecall_o,
  output exit_valid_o,
  output exit_valid_q,
  output halted_o,
  output halted_q,
  output head0_csr_illegal_w,
  output jump_dispatch_valid_w,
  output [`XLEN-1:0] mstatus_o,
  output pending_arch_trap_fire_w,
  output pending_arch_trap_q,
  // [wave5b 死硅拆除] pending_branch/jump capture+clear 输出口(7 根)已删——arbiter capture 臂删除。
  output pending_branch_commit_resolve_w,
  output pending_branch_match_clear_w,
  output pending_exit_q,
  // pending_mem 全链已删除；本信号恒 0（内部 assign tie-off），仅供 stop_pending/trap-exit/fetch sensor 读取。
  output pending_mem_resolve_ready_w,
  output pending_replay_wait_w,
  output pending_system_capture_head0_w,
  output pending_system_capture_lane1_w,
  output pending_system_clear_w,
  output pending_system_csr_commit_w,
  output pending_system_producer_valid_w,
  output [PRODUCER_ID_W-1:0] pending_system_producer_id_w,
  // 【serialize-at-retire Phase1】head0-CSR 队头退休脉冲(组合, 提交拍). 因 core_commit0_csr_w 依赖
  // core_commit0_valid=commit0_fire(已被 OooRob 的 mem_quiet 门控), 此信号天然只在 mem 静默拍拉高。
  // !pending_system_csr_q 区分: head0 路(CSR 进 ROB, =0) vs lane1-drain 路(=1, 走老机制)。
  // 驱动 serial_flush + rd 覆写 + csr 写 + 前端 redirect + stop 清。
  output head0_csr_commit_w,
  output pending_system_csr_q,
  output [`XLEN-1:0] pending_system_csr_rdata_q,
  output pending_system_dispatched_q,
  output pending_system_ecall_q,
  output pending_system_ecall_trap_w,
  output [`INST_W-1:0] pending_system_inst_q,
  output [`TRAP_CAUSE_W-1:0] pending_system_irq_cause_q,
  output pending_system_irq_q,
  output pending_system_mret_q,
  output [`XLEN-1:0] pending_system_next_pc_q,
  output [`XLEN-1:0] pending_system_pc_q,
  output pending_system_q,
  output pending_system_satp_write_commit_w,
  output pending_system_sfence_commit_w,
  output pending_system_fencei_commit_w,
  output [`TRAP_CAUSE_W-1:0] pending_trap_cause_q,
  output [`PMP_ADDR_BUS_W-1:0] pmpaddr_o,
  output [`PMP_CFG_BUS_W-1:0] pmpcfg_o,
  output [1:0] priv_mode_o,
  output priv_predictor_boundary_w,
  output [`XLEN-1:0] satp_o,
  output stop_pending_q,
  output svpbmt_en_o,
  output system_csr_dispatch_fire_w,
  output system_csr_dispatch_valid_w,
  output [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output [`XLEN-1:0] trap_pc_o,
  output trap_redirect_squash_q,
  output [`XLEN-1:0] trap_tval_o,
  output trap_valid_o,
  output trap_valid_q
);

  wire core_commit0_csr_w;
  wire core_commit_exception_trap_w;
  wire [`INST_W-1:0] csr_access_inst_w;
  wire csr_access_need_write_w;
  wire csr_access_set_clear_noop_w;
  wire exit_is_ebreak_q;
  wire exit_is_ecall_q;
  wire head1_csr_illegal_w;
  wire head1_csr_probe_w;
  wire pending_exit_is_ebreak_q;
  wire pending_exit_is_ecall_q;
  wire pending_system_capture_irq_w;
  wire pending_system_sfence_q;
  wire pending_system_fencei_q;
  wire pending_system_fence_q;
  // v8k：admission cancel 必须位于 holder/ready 组合边界之外。完整的
  // pending_system_clear_w 含 direct_frontend_flush_w，而 direct flush 又可读
  // backend dispatch ready；若把完整 clear 反喂 system CSR valid，会形成
  // valid -> ready -> direct fire -> clear -> valid 的组合环。
  //
  // pending-system owner 令 can_run=0，因此 direct frontend fire 与 system CSR
  // replay 在架构上互斥（下方 assertion 守护）。其余无反馈 clear witness
  // 统一在小门中精确限定；level-ready 本身不能获得取消权限，避免活性自锁。
  wire system_csr_admission_clear_w;
  wire system_csr_dispatch_cancel_w;
  OooPendingSystemAdmissionCancelGate
      u_pending_system_admission_cancel_gate (
    .rst_i(rst),
    .core_local_flush_i(core_local_flush_w),
    .csr_trap_mem_valid_i(csr_trap_mem_valid_w),
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
    .head0_csr_commit_i(head0_csr_commit_w),
    .system_csr_admission_clear_o(system_csr_admission_clear_w),
    .system_csr_dispatch_cancel_o(system_csr_dispatch_cancel_w)
  );
  // fence.i commit(镜像 sfence_commit，无 CSR 写)：stop+drain 完成且队头为 fencei → 退休拍拉 mmu_flush+redirect
  assign pending_system_fencei_commit_w =
      stop_pending_q && drain_complete_w && pending_system_q && pending_system_fencei_q;
  wire pending_system_wfi_q;
  wire pending_trap_exit_capture_arch_valid_w;
  wire pending_trap_exit_capture_arch_w;
  wire [`TRAP_CAUSE_W-1:0] pending_trap_exit_capture_cause_w;
  wire pending_trap_exit_capture_exit_ebreak_w;
  wire pending_trap_exit_capture_exit_ecall_w;
  wire pending_trap_exit_capture_exit_valid_w;
  wire pending_trap_exit_capture_exit_w;
  wire [`XLEN-1:0] pending_trap_exit_capture_pc_w;
  wire [`XLEN-1:0] pending_trap_exit_capture_tval_w;
  wire pending_trap_exit_clear_arch_w;
  wire pending_trap_exit_clear_arch_squash_w;
  wire pending_trap_exit_clear_exit_w;
  wire [`XLEN-1:0] pending_trap_pc_q;
  wire [`XLEN-1:0] pending_trap_tval_q;
  wire [`TRAP_CAUSE_W-1:0] trap_cause_q;
  wire [`TRAP_CAUSE_W-1:0] trap_exit_output_cause_w;
  wire trap_exit_output_exit_is_ebreak_w;
  wire trap_exit_output_exit_is_ecall_w;
  wire trap_exit_output_exit_w;
  wire [`XLEN-1:0] trap_exit_output_pc_w;
  wire trap_exit_output_trap_w;
  wire [`XLEN-1:0] trap_exit_output_tval_w;
  wire [`XLEN-1:0] trap_pc_q;
  wire [`XLEN-1:0] trap_tval_q;


  OooCsrAccessRequestMux #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_csr_access_request_mux (
    .core_commit0_valid_i(core_commit0_valid_w),
    .core_commit0_exception_i(core_commit0_exception_w),
    .core_commit0_pc_i(core_commit0_pc_w),
    .core_commit0_inst_i(core_commit0_inst_w),
    .core_commit0_producer_id_i(core_commit0_producer_id_w),
    .pending_system_i(pending_system_q),
    .pending_system_csr_i(pending_system_csr_q),
    .pending_system_dispatched_i(pending_system_dispatched_q),
    .pending_system_sfence_i(pending_system_sfence_q),
    .pending_system_pc_i(pending_system_pc_q),
    .pending_system_inst_i(pending_system_inst_q),
    .pending_system_producer_valid_i(pending_system_producer_valid_w),
    .pending_system_producer_id_i(pending_system_producer_id_w),
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
    .head0_csr_commit_o(head0_csr_commit_w),
    .head1_csr_probe_o(head1_csr_probe_w),
    .csr_access_valid_o(csr_access_valid_w),
    .csr_access_inst_o(csr_access_inst_w),
    .csr_access_addr_o(csr_access_addr_w),
    .csr_access_funct3_o(csr_access_funct3_w),
    .csr_access_rs1_idx_o(csr_access_rs1_idx_w),
    .csr_access_rs1_data_o(csr_access_rs1_data_w),
    .csr_access_set_clear_noop_o(csr_access_set_clear_noop_w),
    .csr_access_need_write_o(csr_access_need_write_w),
    .csr_probe_valid_o(csr_probe_valid_w),
    .csr_probe_addr_o(csr_probe_addr_w),
    .csr_probe_funct3_o(csr_probe_funct3_w),
    .csr_probe_rs1_idx_o(csr_probe_rs1_idx_w),
    .pending_system_satp_write_commit_o(pending_system_satp_write_commit_w),
    .pending_system_sfence_commit_o(pending_system_sfence_commit_w)
  );

  // v8k：head0 fallback 与 pending exact commit 必须共享同一个 claim seal。
  // OooCsrAccessRequestMux 用 raw lease || logical claim 封口；任何 PID/PC
  // mismatch 或 metadata 部分损坏都 fail closed，不能退化为普通队头 CSR。


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


  OooCsrIllegalProbeGate u_csr_illegal_probe_gate (
    .head0_csr_raw_i(head0_csr_raw_w),
    .head1_csr_probe_i(head1_csr_probe_w),
    .csr_illegal_i(csr_illegal_w),
    .head0_csr_illegal_o(head0_csr_illegal_w),
    .head1_csr_illegal_o(head1_csr_illegal_w)
  );


  OooPendingDrainResolveGate #(
    .ROB_COUNT_W(ROB_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_pending_drain_resolve_gate (
    .rob_count_i(rob_count_o),
    .issue_count_i(issue_count_o),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending_q),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending_q),
    .direct_frontend_flush_i(direct_frontend_flush_w),
    .stop_pending_i(stop_pending_q),
    .backend_drained_q_i(backend_drained_q),
    .pending_control_ready_i(pending_control_ready_w),
    .dispatch0_ready_i(dispatch0_ready_w),
    .branch_resolve_pending_match_i(branch_resolve_pending_match_w),
    .branch_spec_active_i(branch_spec_active_q),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending_q),
    .pending_arch_trap_i(pending_arch_trap_q),
    .pending_branch_i(pending_branch_q),
    .pending_branch_dispatched_i(pending_branch_dispatched_q),
    .pending_jump_i(pending_jump_q),
    .pending_jump_dispatched_i(pending_jump_dispatched_q),
    .pending_jump_resolve_ready_i(pending_jump_resolve_ready_w),
    .pending_jump_nolink_i(pending_jump_nolink_w),
    .pending_jump_misaligned_i(pending_jump_misaligned_w),
    .pending_system_i(pending_system_q),
    .pending_system_fence_i(pending_system_fence_q),
    .pending_system_csr_i(pending_system_csr_q),
    .pending_system_dispatched_i(pending_system_dispatched_q),
    .system_csr_dispatch_cancel_i(system_csr_dispatch_cancel_w),
    .mem_retire_quiet_i(mem_retire_quiet_i),
    .mem_idle_i(mem_idle_i),
    .mem_owner_terminalized_i(mem_owner_terminalized_i),
    .backend_drained_o(backend_drained_w),
    .jump_dispatch_valid_o(jump_dispatch_valid_w),
    .system_csr_dispatch_valid_o(system_csr_dispatch_valid_w),
    .system_csr_dispatch_fire_o(system_csr_dispatch_fire_w),
    .pending_branch_commit_resolve_o(pending_branch_commit_resolve_w),
    .pending_branch_match_clear_o(pending_branch_match_clear_w),
    .pending_replay_wait_o(pending_replay_wait_w),
    .drain_complete_o(drain_complete_w)
  );

  // 【pending_mem 全链已删除】lane1 barrier 谓词与 FACT_MEM 严格互斥 → capture 恒 0，
  // 整条 pending_mem 序列/仲裁/drain 臂退休。仍被 stop_pending/trap-exit/fetch sensor 读取的
  // resolve_ready 恒等常量 0（rtl-ground-truth §4）。
  assign pending_mem_resolve_ready_w = 1'b0;

  // B2: ROB-walk 模式开关——branch/jump 在 mode=1 改投机+ROB-walk 恢复，不再 pending+drain。
  wire rob_walk_mode_w = `OOO_ROB_WALK_MODE;

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
    .head0_csr_commit_i(head0_csr_commit_w),
    .stop_pending_i(stop_pending_q),
    .drain_complete_i(drain_complete_w),
    .direct_branch0_fire_i(direct_branch0_fire_w),
    .direct_branch1_fire_i(direct_branch1_fire_w),
    .head_fetch_fault0_i(head_fetch_fault0_w),
    .head_fetch_fault1_i(head_fetch_fault1_w),
    .head_fetch_fault_tval_i(head_fetch_fault_tval_w),
    .head_resp0_i(head_resp0_w),
    .head_resp1_i(head_resp1_w),
    .head_pc0_i(head_pc_w),
    .head_pc1_i(head_pc1_w),
    .head_inst0_i(head_inst0_w),
    .head_inst1_i(head_inst1_w),
    .dispatch0_facts_i(dispatch0_facts_w),
    .head1_facts_i(head1_facts_w),
    .direct_branch0_dispatch_valid_i(direct_branch0_dispatch_valid_w),
    .direct_jal0_dispatch_valid_i(direct_jal0_dispatch_valid_w),
    .dispatch0_return_i(dispatch0_return_w),
    .dispatch0_unsupported_i(dispatch0_unsupported_w),
    .dispatch_unsupported_i(dispatch_unsupported_w),
    .dispatch1_barrier_fire_i(dispatch1_barrier_fire_w),
    .head0_csr_illegal_i(head0_csr_illegal_w),
    .head1_csr_illegal_i(head1_csr_illegal_w),
    .rob_walk_mode_i(rob_walk_mode_w),
    .pending_system_capture_irq_o(pending_system_capture_irq_w),
    .pending_system_capture_head0_o(pending_system_capture_head0_w),
    .pending_system_capture_lane1_o(pending_system_capture_lane1_w),
    .pending_system_clear_o(pending_system_clear_w),
    // [wave5b 死硅拆除] arbiter 的 pending_branch/jump capture+clear 输出臂已删。
    .pending_trap_exit_clear_exit_o(pending_trap_exit_clear_exit_w),
    .pending_trap_exit_clear_arch_o(pending_trap_exit_clear_arch_w),
    .pending_trap_exit_clear_arch_squash_o(pending_trap_exit_clear_arch_squash_w),
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

  OooControlFlushSequencer u_control_flush_sequencer (
    .clk(clk),
    .rst(rst || flush_i),
    .trap_flush_req_i(csr_trap_mem_valid_w),
    .priv_predictor_boundary_i(priv_predictor_boundary_w),
    .backend_drained_i(backend_drained_w),
    // The memory bridge observes the same accepted recovery pulse as the
    // backend.  A raw branch restore may be held while an irrevocable write
    // reaches B/formal-WB/ROB-commit/SQ-release.
    .checkpoint_restore_i(core_checkpoint_restore_apply_i),
    .core_trap_flush_o(core_trap_flush_q),
    .trap_redirect_squash_o(trap_redirect_squash_q),
    .checkpoint_mem_flush_o(checkpoint_mem_flush_q)
  );


  OooCoreSliceControlGate u_core_slice_control_gate (
    .flush_i(flush_i),
    .core_trap_flush_i(core_trap_flush_apply_i),
    .core_serial_flush_i(core_serial_flush_q),
    .commit_ready_i(commit_ready_i),
    .branch_spec_checkpoint_capture_i(branch_spec_checkpoint_capture_w),
    .branch_spec_restore_i(branch_spec_restore_w),
    .branch_spec_checkpoint_pending_i(branch_spec_checkpoint_pending_q),
    .branch_spec_active_i(branch_spec_active_q),
    .ctrl_commit_valid_i(ctrl_commit_valid_q),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending_q),
    .synth_lane1_branch_drop_match_i(synth_lane1_branch_drop_match_w),
    .synth_lane1_ret_branch_seen_i(synth_lane1_ret_branch_seen_q),
    .synth_lane1_ret_branch_commit0_i(synth_lane1_ret_branch_commit0_w),
    .core_checkpoint_capture_o(core_checkpoint_capture_w),
    .core_checkpoint_restore_o(core_checkpoint_restore_w),
    .core_checkpoint_quiesce_o(core_checkpoint_quiesce_w),
    .core_mem_issue_block_o(core_mem_issue_block_w),
    .core_local_flush_o(core_local_flush_w),
    .core_commit_ready_o(core_commit_ready_w),
    .core_commit1_block_o(core_commit1_block_w)
  );

  wire pending_system_rdata_refresh_w =
      backend_drained_w && stop_pending_q && pending_system_q &&
      pending_system_csr_q && !pending_system_dispatched_q;

  OooPendingSystemSequencer #(
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_GEN_W(PRODUCER_GEN_W),
    .PRODUCER_ID_W(PRODUCER_ID_W)
  ) u_pending_system_sequencer (
    .clk(clk),
    // 与 OooExecuteBackend 收到的 ROB flush 使用同一 core_local_flush_w。
    .rst(rst || core_local_flush_w),
    .clear_i(pending_system_clear_w),
    .clear_dispatched_i(orphan_stop_pending_w),
    .refresh_rdata_i(pending_system_rdata_refresh_w),
    .refresh_rdata_value_i(csr_rdata_w),
    .dispatch_fire_i(system_csr_dispatch_fire_w),
    .producer_death_i(pending_system_csr_commit_w),
    .dispatch_producer_id_i(core_dispatch0_producer_id_w),
    .capture_irq_i(pending_system_capture_irq_w),
    .capture_irq_pc_i(head_pc_w),
    .capture_irq_cause_i(csr_irq_cause_w),
    .capture_head0_i(pending_system_capture_head0_w),
    .capture_head0_csr_i(head0_csr_raw_w),
    .capture_head0_ecall_i(head0_ecall_raw_w),
    .capture_head0_mret_i(head0_xret_raw_w),
    .capture_head0_wfi_i(head0_wfi_raw_w),
    .capture_head0_sfence_i(head0_sfence_raw_w),
    .capture_head0_fencei_i(head0_fencei_raw_w),
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
    .capture_lane1_fencei_i(head1_fencei_raw_w),
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
    .fencei_o(pending_system_fencei_q),
    .fence_o(pending_system_fence_q),
    .irq_o(pending_system_irq_q),
    .pc_o(pending_system_pc_q),
    .inst_o(pending_system_inst_q),
    .next_pc_o(pending_system_next_pc_q),
    .csr_rdata_o(pending_system_csr_rdata_q),
    .irq_cause_o(pending_system_irq_cause_q),
    .producer_valid_o(pending_system_producer_valid_w),
    .producer_id_o(pending_system_producer_id_w)
  );


  OooPendingTrapExitSequencer u_pending_trap_exit_sequencer (
    .clk(clk),
    .rst(rst || flush_i || core_local_flush_w),
    .late_clear_i(csr_trap_mem_valid_w),
    .clear_exit_i(pending_trap_exit_clear_exit_w),
    .clear_arch_i(pending_trap_exit_clear_arch_w),
    .clear_arch_squash_i(pending_trap_exit_clear_arch_squash_w),
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


  OooCoreObservableOutputGate u_core_observable_output_gate (
    .trap_valid_i(trap_valid_q),
    .trap_cause_i(trap_cause_q),
    .trap_pc_i(trap_pc_q),
    .trap_tval_i(trap_tval_q),
    .exit_valid_i(exit_valid_q),
    .exit_is_ecall_i(exit_is_ecall_q),
    .exit_is_ebreak_i(exit_is_ebreak_q),
    .exit_code_i(a0_data_w),
    .halted_i(halted_q),
    .stop_pending_i(stop_pending_q),
    .pending_branch_i(pending_branch_q),
    .pending_jump_i(pending_jump_q),
    .pending_mem_i(pending_mem_q),
    .pending_system_i(pending_system_q),
    .synth_lane1_ret_pending_i(synth_lane1_ret_pending_q),
    .synth_lane1_branch_drop_pending_i(synth_lane1_branch_drop_pending_q),
    .csr_priv_mode_i(csr_priv_mode_w),
    .csr_mstatus_i(csr_mstatus_w),
    .csr_satp_i(csr_satp_w),
    .csr_svpbmt_en_i(csr_svpbmt_en_w),
    .csr_pmpcfg_i(csr_pmpcfg_w),
    .csr_pmpaddr_i(csr_pmpaddr_w),
    .debug_gprs_i(core_debug_gprs_w),
    .fifo_has_packet_i(fifo_has_packet_w),
    .head_pc_i(head_pc_w),
    .outstanding_valid_i(outstanding_valid_q),
    .outstanding_pc_i(outstanding_pc_q),
    .next_fetch_pc_i(next_fetch_pc_q),
    .fetch_req_valid_i(fetch_req_valid_o),
    .trap_valid_o(trap_valid_o),
    .trap_cause_o(trap_cause_o),
    .trap_pc_o(trap_pc_o),
    .trap_tval_o(trap_tval_o),
    .exit_valid_o(exit_valid_o),
    .exit_is_ecall_o(exit_is_ecall_o),
    .exit_is_ebreak_o(exit_is_ebreak_o),
    .exit_code_o(exit_code_o),
    .halted_o(halted_o),
    .priv_mode_o(priv_mode_o),
    .mstatus_o(mstatus_o),
    .satp_o(satp_o),
    .svpbmt_en_o(svpbmt_en_o),
    .pmpcfg_o(pmpcfg_o),
    .pmpaddr_o(pmpaddr_o),
    .debug_pc_o(debug_pc_o),
    .debug_state_o(debug_state_o),
    .debug_gprs_o(debug_gprs_o)
  );

  // V9X accepted owner-birth facts.  These expressions model the state that
  // each holder will expose after this edge; stop_pending no longer repeats
  // raw lane/type classification.
  wire v9x_pending_system_owner_birth_w =
      !pending_system_q &&
      !pending_system_producer_valid_w &&
      !pending_system_clear_w &&
      (pending_system_capture_irq_w ||
       pending_system_capture_head0_w ||
       pending_system_capture_lane1_w);
  wire v9x_pending_trap_exit_owner_birth_w =
      !csr_trap_mem_valid_w &&
      !direct_frontend_flush_w &&
      ((pending_trap_exit_capture_exit_w &&
        pending_trap_exit_capture_exit_valid_w &&
        !(pending_trap_exit_clear_exit_w &&
          pending_trap_exit_clear_arch_squash_w)) ||
       (pending_trap_exit_capture_arch_w &&
        pending_trap_exit_capture_arch_valid_w &&
        !(pending_trap_exit_clear_arch_w &&
          pending_trap_exit_clear_arch_squash_w)));
  wire v9x_pending_owner_birth_w =
      v9x_pending_system_owner_birth_w ||
      v9x_pending_trap_exit_owner_birth_w;
  wire v9x_pending_owner_live_w =
      pending_system_q ||
      pending_exit_q ||
      pending_arch_trap_q ||
      pending_branch_q ||
      pending_jump_q ||
      pending_mem_q ||
      synth_lane1_ret_pending_q ||
      synth_lane1_branch_drop_pending_q ||
      branch_spec_checkpoint_pending_q ||
      branch_spec_active_q;

  // Queue-head CSR has no pending-system holder.  Consume the exact accepted
  // fire exported by OooFrontend instead of reconstructing it from the merged
  // backend lane0 fire and a potentially unrelated FIFO-head classification.
  wire v9x_head0_csr_owner_kill_w =
      core_branch_resolve_valid_w &&
      (core_branch_resolve_mispredict_w ||
       core_branch_resolve_misaligned_w);
  wire v9x_head0_csr_owner_birth_w =
      head0_csr_dispatch_fire_w &&
      !v9x_head0_csr_owner_kill_w &&
      !core_local_flush_w &&
      !head0_csr_commit_w;

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
    .head0_csr_commit_i(head0_csr_commit_w),
    .head0_csr_inflight_i(head0_csr_inflight_w),
    .head0_csr_owner_birth_i(v9x_head0_csr_owner_birth_w),
    .head0_csr_owner_kill_i(v9x_head0_csr_owner_kill_w),
    .pending_owner_birth_i(v9x_pending_owner_birth_w),
    .pending_owner_live_i(v9x_pending_owner_live_w),
    .pending_system_producer_valid_i(pending_system_producer_valid_w),
    .core_local_flush_i(core_local_flush_w),
    .drain_complete_i(drain_complete_w),
    .rob_walk_mode_i(rob_walk_mode_w),
    .stop_pending_o(stop_pending_q)
  );

`ifdef OOO_ASSERT
  wire v8k_pending_logical_claim_w =
      pending_system_q && pending_system_csr_q &&
      pending_system_dispatched_q;
  wire v8k_pending_claim_seal_w =
      pending_system_producer_valid_w || v8k_pending_logical_claim_w;
  wire v8k_commit_pid_match_w =
      core_commit0_producer_id_w == pending_system_producer_id_w;
  wire v8k_commit_pc_match_w =
      core_commit0_pc_w == pending_system_pc_q;
  reg v8k_system_fire_prev_q;
  reg [PRODUCER_ID_W-1:0] v8k_system_fire_pid_prev_q;
  reg v8k_lease_prev_q;
  reg v8k_death_prev_q;
  reg v8k_core_flush_prev_q;

  // v8k.1 ProducerId ownership proof at the control/backend boundary.  These
  // checks deliberately use the raw lease, not metadata-gated convenience
  // state, so partial metadata loss remains fail-closed and mutation-visible.
  always @(posedge clk) begin
    if (rst) begin
      v8k_system_fire_prev_q <= 1'b0;
      v8k_system_fire_pid_prev_q <= {PRODUCER_ID_W{1'b0}};
      v8k_lease_prev_q <= 1'b0;
      v8k_death_prev_q <= 1'b0;
      v8k_core_flush_prev_q <= 1'b0;
    end else begin
      if (v8k_pending_logical_claim_w &&
          !pending_system_producer_valid_w) begin
        $error("[V8K-PENDING-CSR-CLAIM-WITHOUT-LEASE] dispatched CSR lost raw ProducerId lease @%0t", $time);
        $fatal;
      end
      if (pending_system_producer_valid_w &&
          !v8k_pending_logical_claim_w && !core_local_flush_w) begin
        $error("[V8K-PENDING-CSR-LEASE-WITHOUT-CLAIM] raw ProducerId lease has malformed metadata @%0t", $time);
        $fatal;
      end
      if (v8k_pending_claim_seal_w && head0_csr_commit_w) begin
        $error("[V8K-PENDING-CSR-HEAD0-FAIL-CLOSED] queue-head fallback bypassed pending claim seal @%0t", $time);
        $fatal;
      end
      if (pending_system_csr_commit_w &&
          !(v8k_pending_logical_claim_w &&
            pending_system_producer_valid_w && core_commit0_csr_w &&
            v8k_commit_pid_match_w && v8k_commit_pc_match_w)) begin
        $error("[V8K-PENDING-CSR-EXACT-COMMIT] commit lacked exact PID/PC witness @%0t", $time);
        $fatal;
      end
      if (pending_system_csr_commit_w && head0_csr_commit_w) begin
        $error("[V8K-PENDING-CSR-ONE-WITNESS] pending and head0 commit both authorized @%0t", $time);
        $fatal;
      end
      if (system_csr_dispatch_fire_w &&
          (!core_dispatch0_fire_w || system_csr_dispatch_cancel_w ||
           !pending_system_q || !pending_system_csr_q ||
           pending_system_dispatched_q || pending_system_producer_valid_w)) begin
        $error("[V8K-PENDING-CSR-ENQUEUE-BIRTH] fire lacked uncancelled pre-ROB CSR witness core_fire=%b cancel=%b @%0t",
               core_dispatch0_fire_w, system_csr_dispatch_cancel_w, $time);
        $fatal;
      end
      if (system_csr_dispatch_fire_w && pending_system_clear_w) begin
        $error("[V8K-PENDING-CSR-FIRE-CLEAR-MUTEX] selected system enqueue overlapped a full pending clear @%0t", $time);
        $fatal;
      end
      if (!direct_frontend_flush_w && pending_jump_resolve_ready_w &&
          (pending_jump_misaligned_w || pending_jump_nolink_commit_w ||
           pending_jump_redirect_after_dispatch_w) &&
          !system_csr_admission_clear_w) begin
        $error("[V8K-PENDING-CSR-JUMP-CLEAR-COVER] reachable jump clear was omitted from admission cancel @%0t", $time);
        $fatal;
      end
      if (pending_system_q && direct_frontend_flush_w) begin
        $error("[V8K-PENDING-CSR-DIRECT-FLUSH-MUTEX] pending-system owner overlapped a frontend direct fire @%0t", $time);
        $fatal;
      end
      if (pending_system_producer_valid_w && pending_system_clear_w &&
          !pending_system_csr_commit_w && !core_local_flush_w) begin
        $error("[V8K-PENDING-CSR-DEATH-ALLOWLIST] ordinary clear attempted to kill live lease @%0t", $time);
        $fatal;
      end
      if (v8k_system_fire_prev_q &&
          (!pending_system_producer_valid_w ||
           (pending_system_producer_id_w != v8k_system_fire_pid_prev_q))) begin
        $error("[V8K-PENDING-CSR-BIRTH-MISSING] ROB enqueue did not produce the exact lease pid=%h held=%h valid=%b @%0t",
               v8k_system_fire_pid_prev_q, pending_system_producer_id_w,
               pending_system_producer_valid_w, $time);
        $fatal;
      end
      if (pending_system_producer_valid_w && !v8k_lease_prev_q &&
          !v8k_system_fire_prev_q) begin
        $error("[V8K-PENDING-CSR-BIRTH-SPURIOUS] lease rose without prior enqueue @%0t", $time);
        $fatal;
      end
      if (!pending_system_producer_valid_w && v8k_lease_prev_q &&
          !v8k_death_prev_q && !v8k_core_flush_prev_q) begin
        $error("[V8K-PENDING-CSR-DEATH-WITNESS] lease fell without exact commit or backend flush @%0t", $time);
        $fatal;
      end

      v8k_system_fire_prev_q <= system_csr_dispatch_fire_w;
      v8k_system_fire_pid_prev_q <= core_dispatch0_producer_id_w;
      v8k_lease_prev_q <= pending_system_producer_valid_w;
      v8k_death_prev_q <= pending_system_csr_commit_w;
      v8k_core_flush_prev_q <= core_local_flush_w;
    end
  end

  // V10A SERIALIZE-G1: the registered architectural-trap and system holders
  // share one stop lease and therefore must be exact-one across birth, drain
  // and clear.  The request mux now emits only the request selected below a
  // higher-priority ROB-head exception; direct redirects remain
  // constructively disjoint through can_run/stop_pending_busy.
  reg v10a_arch_fire_prev_q;
  always @(posedge clk) begin
    if (rst || flush_i || core_local_flush_w) begin
      v10a_arch_fire_prev_q <= 1'b0;
    end else begin
      if (pending_arch_trap_q && pending_system_q) begin
        $error("[V10A-SERIAL-OWNER-ONEHOT] arch and system holders overlap @%0t",
               $time);
        $fatal;
      end
      if ((pending_arch_trap_q || pending_system_q) &&
          !stop_pending_q) begin
        $error("[V10A-SERIAL-OWNER-STOP] live serialized holder lost stop lease arch=%b system=%b @%0t",
               pending_arch_trap_q, pending_system_q, $time);
        $fatal;
      end
      if (pending_arch_trap_fire_w && csr_trap_mem_valid_w) begin
        $error("[V10A-ARCH-REQUEST-PRIORITY] pending arch request overlapped selected ROB-head trap @%0t",
               $time);
        $fatal;
      end
      if (pending_arch_trap_fire_w && direct_frontend_flush_w) begin
        $error("[V10A-ARCH-DIRECT-DISJOINT] pending arch request overlapped direct redirect @%0t",
               $time);
        $fatal;
      end
      if (pending_arch_trap_fire_w &&
          (pending_system_ecall_trap_w ||
           csr_trap_irq_valid_w ||
           csr_mret_valid_w)) begin
        $error("[V10A-ARCH-SYSTEM-SIDE-EFFECT-ONEHOT] arch request overlapped ECALL/IRQ/xRET request @%0t",
               $time);
        $fatal;
      end
      if (v10a_arch_fire_prev_q &&
          (pending_arch_trap_q || stop_pending_q ||
           pending_arch_trap_fire_w)) begin
        $error("[V10A-ARCH-C1-CLEAR] accepted arch request did not clear owner/stop or repeated: arch=%b stop=%b fire=%b @%0t",
               pending_arch_trap_q, stop_pending_q,
               pending_arch_trap_fire_w, $time);
        $fatal;
      end
      v10a_arch_fire_prev_q <= pending_arch_trap_fire_w;
    end
  end

  // Mutation-sensitive contract guard: if the T4L memory-idle term is ever
  // removed from the functional drain equation, this fires on the exact
  // pending-FENCE/busy-memory completion edge.
  always @(posedge clk) begin
    if (!rst && !flush_i && drain_complete_w &&
        pending_system_fence_q && !mem_idle_i) begin
      $error("[FENCE-DRAIN-MEM-IDLE] ordinary FENCE completed with MIQ/bridge/reservation busy");
    end
  end

  // ── 契约 INV-3 (GAP-2 互斥): CSR-commit 队头退休 redirect ⊥ 同拍 younger-branch-mispredict redirect ──
  // 【P4 切消费点(2026-07-09)升格】GAP-2 甲门(shadow 段 !branch_resolve_untracked_w)已随
  // 统一 redirect 仲裁真源化删除——年龄律下 commit 家族(age0)构造性胜过 younger 分支。
  // 本断言从"收敛触发监测"升格为「甲门删除的不可达性哨兵」: fire = 该同拍在真实负载可达,
  // 行为面(此拍 next_fetch_pc 从 mispredict 目标改为 CSR/drain 目标)从"不可观测"变"可观测",
  // 须回 ooo-flush-redirect-contract.md §GAP-2 重审。逻辑不动。
  // 契约意图(独立于实现, 见 ooo-flush-redirect-contract.md §4/§5.2): head0-CSR 恒在 ROB 队头(age=0, 最老),
  // 其提交拍 head0_csr_commit_w 驱动 serial_flush + csr 写 + 前端 redirect(架构下条 PC)。任何 younger 分支的
  // mispredict/resolve redirect 都是更年轻指令的重定向请求。serialize-at-retire 声称二者同拍不可能(younger
  // 已被 drain), 但这是"未证明的兜底不变量"。断言把它钉成显式护栏: 若同拍两源都请求 → GAP-2 被违反。
  // 覆盖: 仅 OOO_CSR_QUEUE_HEAD=1 exercise(默认 head0_csr_commit_w≡0, 见 :307-308 + define.v:556)。
  // 注(忠实性): branch_spec_resolve+restore 与 head0_csr_commit 同拍时, 现状 nonblocking 顺序(:215>:146)
  //   让 CSR 目标胜出——behavior 当前正确, 但仍违反"co-request 互斥"契约, 属真发现(要么强化 serialize
  //   drain younger 分支, 要么把不变量降级为 co-steal 读法)。此处按契约忠实编码 co-request 互斥。
  always @(posedge clk) begin
    if (!rst && !flush_i && head0_csr_commit_w &&
        ((branch_spec_resolve_valid_w && branch_spec_restore_w) ||
         branch_resolve_untracked_w ||
         pending_branch_commit_resolve_w ||
         pending_branch_match_clear_w)) begin
      $error("[FLUSH-CONTRACT INV-3] CSR-commit 与 younger-branch-mispredict 同拍(GAP-2 互斥被违反): spec_restore=%b untracked=%b pend_resolve=%b pend_clear=%b",
             (branch_spec_resolve_valid_w && branch_spec_restore_w),
             branch_resolve_untracked_w, pending_branch_commit_resolve_w,
             pending_branch_match_clear_w);
      $fatal;
    end
  end

  // ── 契约 INV-3b (GAP-2 互斥推广, P4 乙断言): E5-pending_system / E6-drain 终态支 ──
  // 【P4 切消费点(2026-07-09)升格】从"收敛触发监测"升格为「GAP-2 甲门删除的不可达性哨兵」。
  // 切换前实证: module TB 86 + riscv 177 + AM + CoreMark 全程 0 fire → 该同拍在全部现有
  // 负载不可达 → 删甲门(年龄律 commit 家族恒胜取代现行"E3 压过 E5/E6"文本序)后回归逐拍
  // 不变。flag=1(OOO_CSR_QUEUE_HEAD, head0 支)是唯一可能违反域——本断言与 INV-3 在位作
  // 哨兵, 一旦 fire = 行为变化面从不可达变可达, 回契约 §GAP-2 重审。监测型(不 $fatal),
  // 谓词照抄 Sequencer E5/E6 臂条件(drain_complete_i = stop_pending_q && drain_complete_w,
  // 见 OooFrontend 实例), 与 u_frontend 内 commit 家族 pre-mux(E5/E6 valid)同一文本源。
  wire inv3b_commit_family_redirect_w =
      (pending_system_csr_commit_w || head0_csr_commit_w) ||             // E5
      (!csr_trap_mem_valid_w &&
       stop_pending_q && drain_complete_w &&
       (pending_arch_trap_q || pending_system_q ||
        (pending_branch_q && !pending_branch_dispatched_q) ||
        pending_jump_q || pending_mem_q));                               // E6
  always @(posedge clk) begin
    if (!rst && !flush_i &&
        inv3b_commit_family_redirect_w && branch_resolve_untracked_w) begin
      $error("[FLUSH-CONTRACT INV-3b] commit 家族(E5/E6) redirect 与 younger-branch untracked mispredict 同拍(GAP-2 互斥被违反): e5=%b e6=%b untracked=%b",
             (pending_system_csr_commit_w || head0_csr_commit_w),
             (stop_pending_q && drain_complete_w), branch_resolve_untracked_w);
    end
  end

  // T3Y：PendingDispatchArbiter 的 capture_base 已删除 late direct mask；合法
  // direct JAL/RET/JALR-spec 与 IRQ/head0/lane1 pending/trap capture 必须由分类与
  // dispatch-fire 构造性互斥。这里只统计 set/capture，不统计预期可与 direct 同拍
  // 的 squash/clear 输出。
  always @(posedge clk) begin
    if (!rst && !flush_i && direct_frontend_flush_w &&
        (pending_system_capture_irq_w ||
         pending_system_capture_head0_w ||
         pending_system_capture_lane1_w ||
         pending_trap_exit_capture_exit_w ||
         pending_trap_exit_capture_arch_w)) begin
      $error("[T3Y-DIRECT-CAPTURE-DISJOINT] direct flush collided with pending capture: irq=%b h0=%b l1=%b exit=%b arch=%b",
             pending_system_capture_irq_w, pending_system_capture_head0_w,
             pending_system_capture_lane1_w,
             pending_trap_exit_capture_exit_w,
             pending_trap_exit_capture_arch_w);
    end
  end

`endif

`ifdef OOO_ASSERT
  // ── 契约 INV-7 (GAP-7): stop_pending head0-system SET 谓词 单一真源护栏 ──
  // stop_pending 的 head0-system SET 臂(OooStopPendingSequencer.v:130-134)与 arbiter 授予
  // pending-system 队头所有权(OooPendingDispatchArbiter.v:158-164 → pending_system_capture_head0_o)
  // 是同一"队头 system 需停 younger"谓词的两处人工镜像(GAP-7: 无单一真源, 易漂移)。
  // 不变量(subset): arbiter 授予队头 system 所有权 ⟹ sequencer 必 arm head0-system SET 前件。
  // 任一侧改 capture_base 4 项 / irq|fault|arch|exit 门控而另一侧漏改, 即 fire。
  // 反向不作等价: sequencer 亦为 illegal-CSR 与 flag=1 队头化 CSR arm stop, 由 sibling channel
  //   拥有, 非 capture_head0, 故仅断 subset(oracle 比 capture_head0 宽松, capture_head0⟹oracle 恒真)。
  // oracle 是契约的第三份独立拷贝, 与两侧 RTL 交叉核对(§4/§5.7 防同盲区)。
  wire inv7_seq_head0_system_set_w =
      !csr_trap_mem_valid_w && !direct_frontend_flush_w &&
      can_run_w && fifo_has_packet_w &&
      !csr_irq_pending_w && !head_fetch_fault0_w &&
      !dispatch0_arch_trap_w && !dispatch0_exit_w &&
      dispatch0_system_w;
  always @(posedge clk) begin
    if (!rst && !flush_i &&
        pending_system_capture_head0_w && !inv7_seq_head0_system_set_w) begin
      $error("[FLUSH-CONTRACT INV-7] arbiter 授予 head0-system 队头所有权 但 sequencer 未 arm stop_pending SET 前件(GAP-7 SET 谓词两处镜像漂移): capture_head0=1 seq_set=%b [csr_trap=%b dflush=%b can_run=%b fifo=%b irq=%b fault0=%b arch=%b exit=%b sys=%b]",
             inv7_seq_head0_system_set_w,
             csr_trap_mem_valid_w, direct_frontend_flush_w, can_run_w,
             fifo_has_packet_w, csr_irq_pending_w, head_fetch_fault0_w,
             dispatch0_arch_trap_w, dispatch0_exit_w, dispatch0_system_w);
      $fatal;
    end
  end
`endif

endmodule
