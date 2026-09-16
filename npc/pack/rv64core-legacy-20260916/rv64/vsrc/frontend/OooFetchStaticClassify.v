`include "define.v"
`include "common/OooSlotFacts.v"

// Instruction-only fetch facts, computed once from the fault-sanitized
// response packet and stored with that packet.  No head-time architectural
// state is consumed here.
module OooFetchStaticClassify (
  input [`INST_W-1:0] inst_i,
  input [`INST_W-1:0] semihost_peer_inst_i,
  input semihost_peer_is_enter_i,
  output [`OOO_SLOT_STATIC_FACTS_W-1:0] static_facts_o
);

  localparam [`INST_W-1:0] SEMIHOST_ENTER_INST = 32'h01f0_1013;
  localparam [`INST_W-1:0] SEMIHOST_EXIT_INST  = 32'h4070_5013;

  wire fp_load_w;
  wire fp_store_w;
  wire fp_move_to_fpr_w;
  wire fp_move_to_gpr_w;
  wire fp_class_w;
  wire fp_sgnj_w;
  wire fp_addsub_w;
  wire fp_mul_w;
  wire fp_fma_w;
  wire fp_div_w;
  wire fp_sqrt_w;
  wire fp_minmax_w;
  wire fp_compare_w;
  wire fp_convert_to_fpr_w;
  wire fp_convert_to_gpr_w;
  wire fp_unused_w;
  wire fp_double_w;
  wire fp_gpr_write_unused_w;

  OooFpDecode u_fp_decode (
    .decode_valid_i(1'b1),
    .inst_i(inst_i),
    .fp_load_o(fp_load_w),
    .fp_store_o(fp_store_w),
    .fp_move_to_fpr_o(fp_move_to_fpr_w),
    .fp_move_to_gpr_o(fp_move_to_gpr_w),
    .fp_class_o(fp_class_w),
    .fp_sgnj_o(fp_sgnj_w),
    .fp_addsub_o(fp_addsub_w),
    .fp_mul_o(fp_mul_w),
    .fp_fma_o(fp_fma_w),
    .fp_div_o(fp_div_w),
    .fp_sqrt_o(fp_sqrt_w),
    .fp_minmax_o(fp_minmax_w),
    .fp_compare_o(fp_compare_w),
    .fp_convert_to_fpr_o(fp_convert_to_fpr_w),
    .fp_convert_to_gpr_o(fp_convert_to_gpr_w),
    .fp_o(fp_unused_w),
    .fp_double_o(fp_double_w),
    .fp_gpr_write_o(fp_gpr_write_unused_w)
  );

  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_LOAD] = fp_load_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_STORE] = fp_store_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_MOVE_TO_FPR] = fp_move_to_fpr_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_MOVE_TO_GPR] = fp_move_to_gpr_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_CLASS] = fp_class_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_SGNJ] = fp_sgnj_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_ADDSUB] = fp_addsub_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_MUL] = fp_mul_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_FMA] = fp_fma_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_DIV] = fp_div_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_SQRT] = fp_sqrt_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_MINMAX] = fp_minmax_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_COMPARE] = fp_compare_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_CONVERT_TO_FPR] = fp_convert_to_fpr_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_CONVERT_TO_GPR] = fp_convert_to_gpr_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_DOUBLE_RAW] = fp_double_w;
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_FP_DYN_RM_BEARING] =
      (fp_addsub_w || fp_mul_w || fp_fma_w || fp_div_w || fp_sqrt_w ||
       fp_convert_to_fpr_w || fp_convert_to_gpr_w) &&
      (inst_i[14:12] == 3'b111);
  assign static_facts_o[`OOO_SLOT_STATIC_FACT_SEMIHOST_PEER_SIGNATURE] =
      semihost_peer_is_enter_i ?
          (semihost_peer_inst_i == SEMIHOST_ENTER_INST) :
          (semihost_peer_inst_i == SEMIHOST_EXIT_INST);

endmodule
