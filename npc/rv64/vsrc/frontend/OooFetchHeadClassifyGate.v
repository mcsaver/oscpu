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

  assign illegal_raw_o = decode_illegal_w && !fp_raw_o;

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

  wire sfence_u_illegal_w = sfence_raw_o && (priv_mode_i == `PRIV_U);
  wire sfence_tvm_illegal_w =
      sfence_raw_o && ctrl_i[`CTRL_SFENCE_TVM_BIT] &&
      (priv_mode_i == `PRIV_S) &&
      ((mstatus_i & `MSTATUS_TVM) != {`XLEN{1'b0}});
  wire sret_tsr_illegal_w =
      sret_raw_o && (priv_mode_i == `PRIV_S) &&
      ((mstatus_i & `MSTATUS_TSR) != {`XLEN{1'b0}});

  assign priv_system_illegal_o =
      sfence_u_illegal_w || sfence_tvm_illegal_w || sret_tsr_illegal_w;
  assign exit_raw_o = ebreak_raw_o && !semihost_ebreak_o;
  assign system_raw_o =
      ecall_raw_o || csr_raw_o || xret_raw_o || wfi_raw_o || sfence_raw_o;
  assign fp_disabled_o =
      fp_raw_o && ((mstatus_i & `MSTATUS_FS_MASK) == {`XLEN{1'b0}});
  assign fp_enabled_o = fp_raw_o && !fp_disabled_o;
  assign arch_trap_raw_o =
      fetch_fault_i || illegal_raw_o || semihost_ebreak_o ||
      fp_disabled_o || priv_system_illegal_o;
  assign stop_raw_o =
      fetch_fault_i || exit_raw_o || system_raw_o || fp_raw_o ||
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

endmodule
