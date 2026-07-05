`include "define.v"
`include "common/OooSlotFacts.v"

// 单槽 fetch head 分类器：只生成组合 facts，不持有 fetch/CSR/pending 状态。
module OooFetchHeadClassifyGate (
  input decode_valid_i,
  input fetch_fault_i,
  input [`INST_W-1:0] inst_i,
  input [`INST_W-1:0] semihost_peer_inst_i,
  input semihost_peer_is_enter_i,
  input [`CTRL_BUS_W-1:0] ctrl_i,
  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  input [2:0] frm_i,
  output illegal_raw_o,
  output branch_raw_o,
  output jal_raw_o,
  output jalr_raw_o,
  output jump_raw_o,
  output mem_raw_o,
  output control_raw_o,
  output fp_load_raw_o,
  output fp_store_raw_o,
  output fp_move_to_fpr_raw_o,
  output fp_move_to_gpr_raw_o,
  output fp_class_raw_o,
  output fp_sgnj_raw_o,
  output fp_addsub_raw_o,
  output fp_mul_raw_o,
  output fp_fma_raw_o,
  output fp_div_raw_o,
  output fp_sqrt_raw_o,
  output fp_minmax_raw_o,
  output fp_compare_raw_o,
  output fp_convert_to_fpr_raw_o,
  output fp_convert_to_gpr_raw_o,
  output fp_raw_o,
  output fp_double_o,
  output fp_gpr_write_o,
  output fp_disabled_o,
  output fp_enabled_o,
  output ecall_raw_o,
  output ebreak_raw_o,
  output semihost_ebreak_o,
  output csr_raw_o,
  output mret_raw_o,
  output sret_raw_o,
  output xret_raw_o,
  output wfi_raw_o,
  output sfence_raw_o,
  output fencei_raw_o,
  output priv_system_illegal_o,
  output exit_raw_o,
  output system_raw_o,
  output arch_trap_raw_o,
  output stop_raw_o,
  output [`OOO_SLOT_FACTS_W-1:0] facts_o
);

  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f0_1013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST  = 32'h4070_5013;

  wire decode_ok_w = decode_valid_i && !fetch_fault_i;
  wire decode_illegal_w = decode_ok_w && ctrl_i[`CTRL_ILLEGAL_BIT];
  wire ctrl_legal_w = decode_ok_w && !ctrl_i[`CTRL_ILLEGAL_BIT];
  // 【正确性修复 2026-07-03: §3.1 #4 unsupported-trap-exit】译码合法却不需 EXEC 的残差
  // (当前 ISA 恒 0: DecodeUnit 仅 :758/:763 置 NEED_EXEC=0 且都保持 ILLEGAL=1 → ctrl_legal=0)。
  // 折入 arch_trap → head0 精确出口(受 squash 保护、不受 rob_walk 门控), 补齐 mode=1 下
  // dispatch_unsupported 置 stop 却无 payload 的死路(OooPendingDispatchArbiter:308 rob_walk 门死), 结构性零回归。
  wire unsupported_residual_w = ctrl_legal_w && !ctrl_i[`CTRL_NEED_EXEC_BIT];

  OooFpDecode u_fp_decode (
    .decode_valid_i(decode_ok_w),
    .inst_i(inst_i),
    .fp_load_o(fp_load_raw_o),
    .fp_store_o(fp_store_raw_o),
    .fp_move_to_fpr_o(fp_move_to_fpr_raw_o),
    .fp_move_to_gpr_o(fp_move_to_gpr_raw_o),
    .fp_class_o(fp_class_raw_o),
    .fp_sgnj_o(fp_sgnj_raw_o),
    .fp_addsub_o(fp_addsub_raw_o),
    .fp_mul_o(fp_mul_raw_o),
    .fp_fma_o(fp_fma_raw_o),
    .fp_div_o(fp_div_raw_o),
    .fp_sqrt_o(fp_sqrt_raw_o),
    .fp_minmax_o(fp_minmax_raw_o),
    .fp_compare_o(fp_compare_raw_o),
    .fp_convert_to_fpr_o(fp_convert_to_fpr_raw_o),
    .fp_convert_to_gpr_o(fp_convert_to_gpr_raw_o),
    .fp_o(fp_raw_o),
    .fp_double_o(fp_double_o),
    .fp_gpr_write_o(fp_gpr_write_o)
  );

  // 【正确性修复 2026-07-03: §3.2 frm-DYN】DYN(rm=111) FP 算术在发射侧用 committed frm 解析
  // (OooFpBackend:524), 但 frm=5/6/7 保留值不 trap → 静默错误。与 fp_disabled 同类("该 trap
  // 却在执行的 FP"), 复用精确-illegal 整机: 前端 classify 拿 committed frm 判非法, 折入 illegal
  // 并同步关 fp_enabled(否则既 trap 又派 FP 簇)。静态 reserved rm(101/110)已由 OooFpDecode:59 排除。
  wire fp_dyn_rm_bearing_w =
      fp_addsub_raw_o || fp_mul_raw_o || fp_fma_raw_o || fp_div_raw_o ||
      fp_sqrt_raw_o || fp_convert_to_fpr_raw_o || fp_convert_to_gpr_raw_o;
  wire fp_dyn_frm_illegal_w =
      fp_dyn_rm_bearing_w && (inst_i[14:12] == 3'b111) &&
      ((frm_i == 3'b101) || (frm_i == 3'b110) || (frm_i == 3'b111));

  assign illegal_raw_o = (decode_illegal_w && !fp_raw_o) || fp_dyn_frm_illegal_w;

  assign branch_raw_o = ctrl_legal_w && ctrl_i[`CTRL_BRANCH_BIT];
  assign jal_raw_o = ctrl_legal_w && ctrl_i[`CTRL_JAL_BIT];
  assign jalr_raw_o = ctrl_legal_w && ctrl_i[`CTRL_JALR_BIT];
  assign jump_raw_o = jal_raw_o || jalr_raw_o;
  assign mem_raw_o = ctrl_legal_w &&
                     (ctrl_i[`CTRL_LOAD_BIT] || ctrl_i[`CTRL_STORE_BIT]);
  assign control_raw_o = branch_raw_o || jal_raw_o || jalr_raw_o;

  assign ecall_raw_o = ctrl_legal_w && ctrl_i[`CTRL_ECALL_BIT];
  assign ebreak_raw_o = ctrl_legal_w && ctrl_i[`CTRL_EBREAK_BIT];
  assign semihost_ebreak_o =
      ebreak_raw_o &&
      (semihost_peer_is_enter_i ?
       (semihost_peer_inst_i == SEMIHOST_ENTER_INST) :
       (semihost_peer_inst_i == SEMIHOST_EXIT_INST));
  assign csr_raw_o = ctrl_legal_w && ctrl_i[`CTRL_CSR_BIT];
  assign mret_raw_o = ctrl_legal_w && ctrl_i[`CTRL_MRET_BIT];
  assign sret_raw_o = ctrl_legal_w && ctrl_i[`CTRL_SRET_BIT];
  assign xret_raw_o = mret_raw_o || sret_raw_o;
  assign wfi_raw_o = ctrl_legal_w && ctrl_i[`CTRL_WFI_BIT];
  assign sfence_raw_o = ctrl_legal_w && ctrl_i[`CTRL_SFENCE_VMA_BIT];
  // fence.i(真 flush): 全特权合法(不进 priv_system_illegal), 折进 system_raw 使其 stop→退休拍 mmu_flush+redirect
  assign fencei_raw_o = ctrl_legal_w && ctrl_i[`CTRL_FENCEI_BIT];

  wire sfence_u_illegal_w = sfence_raw_o && (priv_mode_i == `PRIV_U);
  wire sfence_tvm_illegal_w =
      sfence_raw_o && ctrl_i[`CTRL_SFENCE_TVM_BIT] &&
      (priv_mode_i == `PRIV_S) &&
      ((mstatus_i & `MSTATUS_TVM) != {`XLEN{1'b0}});
  wire sret_tsr_illegal_w =
      sret_raw_o && (priv_mode_i == `PRIV_S) &&
      ((mstatus_i & `MSTATUS_TSR) != {`XLEN{1'b0}});
  // 【合规修复 2026-07-03: §3.2 wfi-TW】mstatus.TW=1 时 priv<M 的 WFI 应 illegal(规范:
  // TW=1 下低特权 WFI 超 bounded time 即非法, 本核 WFI=立即 no-op 故立即 illegal)。
  // 与 sfence-TVM/sret-TSR 同构走 priv_system_illegal → arch_trap → 精确 trap。
  // 现有测试全 TW=0(rv64si-p-wfi/rv64mi 明确"WFI doesn't trap when TW=0"), TW=0 时本项恒 0 → 零回归。
  wire wfi_tw_illegal_w =
      wfi_raw_o && (priv_mode_i != `PRIV_M) &&
      ((mstatus_i & `MSTATUS_TW) != {`XLEN{1'b0}});

  assign priv_system_illegal_o =
      sfence_u_illegal_w || sfence_tvm_illegal_w || sret_tsr_illegal_w ||
      wfi_tw_illegal_w;
  assign exit_raw_o = ebreak_raw_o && !semihost_ebreak_o;
  assign system_raw_o =
      ecall_raw_o || csr_raw_o || xret_raw_o || wfi_raw_o || sfence_raw_o ||
      fencei_raw_o;
  assign fp_disabled_o =
      fp_raw_o && ((mstatus_i & `MSTATUS_FS_MASK) == {`XLEN{1'b0}});
  assign fp_enabled_o = fp_raw_o && !fp_disabled_o && !fp_dyn_frm_illegal_w;
  assign arch_trap_raw_o =
      fetch_fault_i || illegal_raw_o || semihost_ebreak_o ||
      fp_disabled_o || priv_system_illegal_o || unsupported_residual_w;
  // 【B-FP 簇】FP 迁域 A: fp_raw 不再是 stop 类(普通 dispatch 进 ROB/FP 簇)。
  // 旧 fp_raw 臂使 head0=FP 时 head1 不 decode(facts 全 0), 与 FP 同包的
  // lane1 CSR/system 指令被当无害指令双发成 NOP。FS=off 走 arch_trap 仍 stop。
  assign stop_raw_o =
      fetch_fault_i || exit_raw_o || system_raw_o ||
      arch_trap_raw_o;

  assign facts_o[`OOO_SLOT_FACT_ILLEGAL] = illegal_raw_o;
  assign facts_o[`OOO_SLOT_FACT_BRANCH] = branch_raw_o;
  assign facts_o[`OOO_SLOT_FACT_JAL] = jal_raw_o;
  assign facts_o[`OOO_SLOT_FACT_JALR] = jalr_raw_o;
  assign facts_o[`OOO_SLOT_FACT_JUMP] = jump_raw_o;
  assign facts_o[`OOO_SLOT_FACT_MEM] = mem_raw_o;
  assign facts_o[`OOO_SLOT_FACT_CONTROL] = control_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_LOAD] = fp_load_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_STORE] = fp_store_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_MOVE_TO_FPR] = fp_move_to_fpr_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_MOVE_TO_GPR] = fp_move_to_gpr_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_CLASS] = fp_class_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_SGNJ] = fp_sgnj_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_ADDSUB] = fp_addsub_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_MUL] = fp_mul_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_FMA] = fp_fma_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_DIV] = fp_div_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_SQRT] = fp_sqrt_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_MINMAX] = fp_minmax_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_COMPARE] = fp_compare_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_CONVERT_TO_FPR] = fp_convert_to_fpr_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_CONVERT_TO_GPR] = fp_convert_to_gpr_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_RAW] = fp_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FP_DOUBLE] = fp_double_o;
  assign facts_o[`OOO_SLOT_FACT_FP_GPR_WRITE] = fp_gpr_write_o;
  assign facts_o[`OOO_SLOT_FACT_FP_DISABLED] = fp_disabled_o;
  assign facts_o[`OOO_SLOT_FACT_FP_ENABLED] = fp_enabled_o;
  assign facts_o[`OOO_SLOT_FACT_ECALL] = ecall_raw_o;
  assign facts_o[`OOO_SLOT_FACT_EBREAK] = ebreak_raw_o;
  assign facts_o[`OOO_SLOT_FACT_SEMIHOST_EBREAK] = semihost_ebreak_o;
  assign facts_o[`OOO_SLOT_FACT_CSR] = csr_raw_o;
  assign facts_o[`OOO_SLOT_FACT_MRET] = mret_raw_o;
  assign facts_o[`OOO_SLOT_FACT_SRET] = sret_raw_o;
  assign facts_o[`OOO_SLOT_FACT_XRET] = xret_raw_o;
  assign facts_o[`OOO_SLOT_FACT_WFI] = wfi_raw_o;
  assign facts_o[`OOO_SLOT_FACT_SFENCE] = sfence_raw_o;
  assign facts_o[`OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL] = priv_system_illegal_o;
  assign facts_o[`OOO_SLOT_FACT_EXIT] = exit_raw_o;
  assign facts_o[`OOO_SLOT_FACT_SYSTEM] = system_raw_o;
  assign facts_o[`OOO_SLOT_FACT_ARCH_TRAP] = arch_trap_raw_o;
  assign facts_o[`OOO_SLOT_FACT_STOP] = stop_raw_o;
  assign facts_o[`OOO_SLOT_FACT_FENCEI] = fencei_raw_o;

endmodule
