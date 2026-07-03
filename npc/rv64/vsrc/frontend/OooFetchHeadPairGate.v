`include "define.v"
`include "common/OooSlotFacts.v"

// 双槽 fetch head 组合 owner：只收敛可见性、单槽分类实例和 lane0 dispatch facts。
module OooFetchHeadPairGate (
  input fifo_has_packet_i,
  input [1:0] head_resp0_i,
  input [1:0] head_resp1_i,
  input [`INST_W-1:0] head_inst0_i,
  input [`INST_W-1:0] head_inst1_i,
  input [`CTRL_BUS_W-1:0] head0_ctrl_i,
  input [`CTRL_BUS_W-1:0] head1_ctrl_i,
  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [2:0] frm_i,
  input branch_spec_active_i,
  input can_run_i,
  input csr_irq_pending_i,

  output head_fetch_fault0_o,
  output head_fetch_fault1_o,
  output head_fetch_fault_o,

  output head0_illegal_raw_o,
  output head0_branch_raw_o,
  output head0_jal_raw_o,
  output head0_jalr_raw_o,
  output head0_jump_raw_o,
  output head0_mem_raw_o,
  output head0_fp_load_raw_o,
  output head0_fp_store_raw_o,
  output head0_fp_move_to_fpr_raw_o,
  output head0_fp_move_to_gpr_raw_o,
  output head0_fp_class_raw_o,
  output head0_fp_sgnj_raw_o,
  output head0_fp_addsub_raw_o,
  output head0_fp_mul_raw_o,
  output head0_fp_fma_raw_o,
  output head0_fp_div_raw_o,
  output head0_fp_sqrt_raw_o,
  output head0_fp_minmax_raw_o,
  output head0_fp_compare_raw_o,
  output head0_fp_convert_to_fpr_raw_o,
  output head0_fp_convert_to_gpr_raw_o,
  output head0_fp_raw_o,
  output head0_fp_double_o,
  output head0_fp_gpr_write_o,
  output head0_fp_disabled_o,
  output head0_fp_enabled_o,
  output head0_ecall_raw_o,
  output head0_ebreak_raw_o,
  output head0_semihost_ebreak_o,
  output head0_csr_raw_o,
  output head0_mret_raw_o,
  output head0_sret_raw_o,
  output head0_xret_raw_o,
  output head0_wfi_raw_o,
  output head0_sfence_raw_o,
  output head0_priv_system_illegal_o,
  output head0_exit_raw_o,
  output head0_system_raw_o,
  output head0_arch_trap_raw_o,
  output head0_stop_raw_o,
  output [`OOO_SLOT_FACTS_W-1:0] head0_facts_o,

  output head1_illegal_raw_o,
  output head1_control_raw_o,
  output head1_branch_raw_o,
  output head1_jal_raw_o,
  output head1_jalr_raw_o,
  output head1_jump_raw_o,
  output head1_mem_raw_o,
  output head1_fp_load_raw_o,
  output head1_fp_store_raw_o,
  output head1_fp_move_to_fpr_raw_o,
  output head1_fp_move_to_gpr_raw_o,
  output head1_fp_class_raw_o,
  output head1_fp_sgnj_raw_o,
  output head1_fp_addsub_raw_o,
  output head1_fp_mul_raw_o,
  output head1_fp_fma_raw_o,
  output head1_fp_div_raw_o,
  output head1_fp_sqrt_raw_o,
  output head1_fp_minmax_raw_o,
  output head1_fp_compare_raw_o,
  output head1_fp_convert_to_fpr_raw_o,
  output head1_fp_convert_to_gpr_raw_o,
  output head1_fp_raw_o,
  output head1_fp_double_o,
  output head1_fp_gpr_write_o,
  output head1_fp_disabled_o,
  output head1_fp_enabled_o,
  output head1_ecall_raw_o,
  output head1_ebreak_raw_o,
  output head1_semihost_ebreak_o,
  output head1_csr_raw_o,
  output head1_mret_raw_o,
  output head1_sret_raw_o,
  output head1_xret_raw_o,
  output head1_wfi_raw_o,
  output head1_sfence_raw_o,
  output head1_priv_system_illegal_o,
  output head1_exit_raw_o,
  output head1_system_raw_o,
  output head1_arch_trap_raw_o,
  output head1_stop_raw_o,
  output [`OOO_SLOT_FACTS_W-1:0] head1_facts_o,

  output branch_spec_dispatch_block_o,
  output dispatch_valid_o,
  output dispatch0_ecall_o,
  output dispatch0_ebreak_o,
  output dispatch0_exit_o,
  output dispatch0_arch_trap_o,
  output dispatch0_system_o,
  output dispatch0_fp_o,
  output dispatch0_branch_o,
  output dispatch0_jal_o,
  output dispatch0_jump_o,
  output direct_branch0_dispatch_valid_o
);

  wire head0_decode_valid_w;
  wire head1_decode_valid_w;
  wire head0_control_raw_unused_w;

  assign head_fetch_fault0_o =
      fifo_has_packet_i && (head_resp0_i != 2'b00);
  assign head0_decode_valid_w =
      fifo_has_packet_i && !head_fetch_fault0_o;

  OooFetchHeadClassifyGate u_head0_classify_gate (
    .decode_valid_i(head0_decode_valid_w),
    .fetch_fault_i(head_fetch_fault0_o),
    .inst_i(head_inst0_i),
    .semihost_peer_inst_i(head_inst1_i),
    .semihost_peer_is_enter_i(1'b0),
    .ctrl_i(head0_ctrl_i),
    .priv_mode_i(priv_mode_i),
    .mstatus_i(mstatus_i),
    .frm_i(frm_i),
    .illegal_raw_o(head0_illegal_raw_o),
    .branch_raw_o(head0_branch_raw_o),
    .jal_raw_o(head0_jal_raw_o),
    .jalr_raw_o(head0_jalr_raw_o),
    .jump_raw_o(head0_jump_raw_o),
    .mem_raw_o(head0_mem_raw_o),
    .control_raw_o(head0_control_raw_unused_w),
    .fp_load_raw_o(head0_fp_load_raw_o),
    .fp_store_raw_o(head0_fp_store_raw_o),
    .fp_move_to_fpr_raw_o(head0_fp_move_to_fpr_raw_o),
    .fp_move_to_gpr_raw_o(head0_fp_move_to_gpr_raw_o),
    .fp_class_raw_o(head0_fp_class_raw_o),
    .fp_sgnj_raw_o(head0_fp_sgnj_raw_o),
    .fp_addsub_raw_o(head0_fp_addsub_raw_o),
    .fp_mul_raw_o(head0_fp_mul_raw_o),
    .fp_fma_raw_o(head0_fp_fma_raw_o),
    .fp_div_raw_o(head0_fp_div_raw_o),
    .fp_sqrt_raw_o(head0_fp_sqrt_raw_o),
    .fp_minmax_raw_o(head0_fp_minmax_raw_o),
    .fp_compare_raw_o(head0_fp_compare_raw_o),
    .fp_convert_to_fpr_raw_o(head0_fp_convert_to_fpr_raw_o),
    .fp_convert_to_gpr_raw_o(head0_fp_convert_to_gpr_raw_o),
    .fp_raw_o(head0_fp_raw_o),
    .fp_double_o(head0_fp_double_o),
    .fp_gpr_write_o(head0_fp_gpr_write_o),
    .fp_disabled_o(head0_fp_disabled_o),
    .fp_enabled_o(head0_fp_enabled_o),
    .ecall_raw_o(head0_ecall_raw_o),
    .ebreak_raw_o(head0_ebreak_raw_o),
    .semihost_ebreak_o(head0_semihost_ebreak_o),
    .csr_raw_o(head0_csr_raw_o),
    .mret_raw_o(head0_mret_raw_o),
    .sret_raw_o(head0_sret_raw_o),
    .xret_raw_o(head0_xret_raw_o),
    .wfi_raw_o(head0_wfi_raw_o),
    .sfence_raw_o(head0_sfence_raw_o),
    .priv_system_illegal_o(head0_priv_system_illegal_o),
    .exit_raw_o(head0_exit_raw_o),
    .system_raw_o(head0_system_raw_o),
    .arch_trap_raw_o(head0_arch_trap_raw_o),
    .stop_raw_o(head0_stop_raw_o),
    .facts_o(head0_facts_o)
  );

  assign head_fetch_fault1_o =
      fifo_has_packet_i && !head_fetch_fault0_o &&
      !head0_facts_o[`OOO_SLOT_FACT_BRANCH] &&
      !head0_facts_o[`OOO_SLOT_FACT_JUMP] &&
      !head0_facts_o[`OOO_SLOT_FACT_STOP] && (head_resp1_i != 2'b00);
  assign head_fetch_fault_o = head_fetch_fault0_o | head_fetch_fault1_o;
  // 【F2 修复 2026-07-03: rv64mi-p-illegal】head0=分支时不再压制 head1 译码。
  // F2 下 not-taken 分支与 head1 原子双发, head1 在正确路径上, 必须译码使 head1 的 facts
  // (尤其 system_raw/exit/arch_trap)正确 —— 否则 head0=分支 & head1=CSR/system 时 head1_system_raw=0,
  // dbranch_dual_go 看不到 head1 是 system, 把 CSR 当无害指令双发进 domain-A(CSR 在 domain-A 不执行→读回 0),
  // 导致 trap handler 的 `csrr t0,mepc` 读回 0 → 匹配失败 → j fail(rv64mi-p-illegal 既有失败根因)。
  // 修正后: head1=system → dbranch_dual_go=0 → 分支 fire+重取 head1 → head1 成 head0 走 domain-B(读对);
  // head1=普通指令 → facts 正确但 dbranch_dual_go 仍=1(正常双发, 行为不变)。
  // 与 OooFetchHeadClassifyGate 注释所述"head0=FP 压制 head1"的 FP 家族 bug 同类(FP 已修, 分支同理);
  // JUMP/STOP 的压制保留(不在本 bug 覆盖, 避免扩大改动面)。head_fetch_fault1 保持(与 resp1==0 互斥, 无关)。
  assign head1_decode_valid_w =
      fifo_has_packet_i && !head_fetch_fault0_o &&
      !head0_facts_o[`OOO_SLOT_FACT_JUMP] &&
      !head0_facts_o[`OOO_SLOT_FACT_STOP] && (head_resp1_i == 2'b00);

  OooFetchHeadClassifyGate u_head1_classify_gate (
    .decode_valid_i(head1_decode_valid_w),
    .fetch_fault_i(head_fetch_fault1_o),
    .inst_i(head_inst1_i),
    .semihost_peer_inst_i(head_inst0_i),
    .semihost_peer_is_enter_i(1'b1),
    .ctrl_i(head1_ctrl_i),
    .priv_mode_i(priv_mode_i),
    .mstatus_i(mstatus_i),
    .frm_i(frm_i),
    .illegal_raw_o(head1_illegal_raw_o),
    .branch_raw_o(head1_branch_raw_o),
    .jal_raw_o(head1_jal_raw_o),
    .jalr_raw_o(head1_jalr_raw_o),
    .jump_raw_o(head1_jump_raw_o),
    .mem_raw_o(head1_mem_raw_o),
    .control_raw_o(head1_control_raw_o),
    .fp_load_raw_o(head1_fp_load_raw_o),
    .fp_store_raw_o(head1_fp_store_raw_o),
    .fp_move_to_fpr_raw_o(head1_fp_move_to_fpr_raw_o),
    .fp_move_to_gpr_raw_o(head1_fp_move_to_gpr_raw_o),
    .fp_class_raw_o(head1_fp_class_raw_o),
    .fp_sgnj_raw_o(head1_fp_sgnj_raw_o),
    .fp_addsub_raw_o(head1_fp_addsub_raw_o),
    .fp_mul_raw_o(head1_fp_mul_raw_o),
    .fp_fma_raw_o(head1_fp_fma_raw_o),
    .fp_div_raw_o(head1_fp_div_raw_o),
    .fp_sqrt_raw_o(head1_fp_sqrt_raw_o),
    .fp_minmax_raw_o(head1_fp_minmax_raw_o),
    .fp_compare_raw_o(head1_fp_compare_raw_o),
    .fp_convert_to_fpr_raw_o(head1_fp_convert_to_fpr_raw_o),
    .fp_convert_to_gpr_raw_o(head1_fp_convert_to_gpr_raw_o),
    .fp_raw_o(head1_fp_raw_o),
    .fp_double_o(head1_fp_double_o),
    .fp_gpr_write_o(head1_fp_gpr_write_o),
    .fp_disabled_o(head1_fp_disabled_o),
    .fp_enabled_o(head1_fp_enabled_o),
    .ecall_raw_o(head1_ecall_raw_o),
    .ebreak_raw_o(head1_ebreak_raw_o),
    .semihost_ebreak_o(head1_semihost_ebreak_o),
    .csr_raw_o(head1_csr_raw_o),
    .mret_raw_o(head1_mret_raw_o),
    .sret_raw_o(head1_sret_raw_o),
    .xret_raw_o(head1_xret_raw_o),
    .wfi_raw_o(head1_wfi_raw_o),
    .sfence_raw_o(head1_sfence_raw_o),
    .priv_system_illegal_o(head1_priv_system_illegal_o),
    .exit_raw_o(head1_exit_raw_o),
    .system_raw_o(head1_system_raw_o),
    .arch_trap_raw_o(head1_arch_trap_raw_o),
    .stop_raw_o(head1_stop_raw_o),
    .facts_o(head1_facts_o)
  );

  assign branch_spec_dispatch_block_o =
      branch_spec_active_i && fifo_has_packet_i &&
      (head_fetch_fault0_o || head_fetch_fault1_o ||
       head0_facts_o[`OOO_SLOT_FACT_STOP] ||
       head0_facts_o[`OOO_SLOT_FACT_BRANCH] ||
       head0_facts_o[`OOO_SLOT_FACT_JUMP] ||
       head0_facts_o[`OOO_SLOT_FACT_MEM] ||
       head1_facts_o[`OOO_SLOT_FACT_STOP] ||
       head1_facts_o[`OOO_SLOT_FACT_CONTROL] ||
       head1_facts_o[`OOO_SLOT_FACT_MEM]);

  assign dispatch_valid_o =
      fifo_has_packet_i && can_run_i && !csr_irq_pending_i &&
      !head_fetch_fault0_o && !branch_spec_dispatch_block_o;
  assign dispatch0_ecall_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_ECALL];
  assign dispatch0_ebreak_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_EBREAK];
  assign dispatch0_exit_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_EXIT];
  assign dispatch0_arch_trap_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_ARCH_TRAP];
  assign dispatch0_system_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_SYSTEM];
  assign dispatch0_fp_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_FP_ENABLED];
  assign dispatch0_branch_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_BRANCH];
  assign dispatch0_jal_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_JAL];
  assign dispatch0_jump_o =
      dispatch_valid_o && head0_facts_o[`OOO_SLOT_FACT_JALR];
  // domain-A 第一刀: direct 分支 dispatch 资格关闭, 分支 dispatch 由 frontend_dispatch
  // 普通路覆盖(dispatch mux 的 pc/inst 同为 head0 default 臂, 语义不变)。
  assign direct_branch0_dispatch_valid_o =
      dispatch0_branch_o && !(`OOO_DBRANCH_DOMAIN_A);

endmodule
