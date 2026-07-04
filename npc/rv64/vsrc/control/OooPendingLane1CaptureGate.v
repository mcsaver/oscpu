`include "include/define.v"
`include "common/OooSlotFacts.v"

// Lane1 barrier 的局部 owner 分型与 trap/exit payload 组合计算。
// 全局优先级仍属于 OooPendingDispatchArbiter，本模块不保存状态。
module OooPendingLane1CaptureGate (
  input barrier_base_i,
  input head_fetch_fault_i,
  input [1:0] head_resp_i,
  input [`XLEN-1:0] head_pc_i,
  input [`INST_W-1:0] head_inst_i,
  input [`OOO_SLOT_FACTS_W-1:0] facts_i,
  input csr_illegal_i,

  output system_capture_o,
  output branch_capture_o,
  output jump_capture_o,
  output fp_capture_o,

  output trap_exit_capture_o,
  output trap_exit_arch_valid_o,
  output trap_exit_exit_valid_o,
  output trap_exit_exit_ecall_o,
  output trap_exit_exit_ebreak_o,
  output [`TRAP_CAUSE_W-1:0] trap_exit_cause_o,
  output [`XLEN-1:0] trap_exit_tval_o
);

  wire system_raw_w = facts_i[`OOO_SLOT_FACT_SYSTEM];
  wire branch_raw_w = facts_i[`OOO_SLOT_FACT_BRANCH];
  wire jump_raw_w = facts_i[`OOO_SLOT_FACT_JUMP];
  wire fp_enabled_w = facts_i[`OOO_SLOT_FACT_FP_ENABLED];
  wire exit_raw_w = facts_i[`OOO_SLOT_FACT_EXIT];
  wire ecall_raw_w = facts_i[`OOO_SLOT_FACT_ECALL];
  wire ebreak_raw_w = facts_i[`OOO_SLOT_FACT_EBREAK];
  wire arch_trap_raw_w = facts_i[`OOO_SLOT_FACT_ARCH_TRAP];
  wire illegal_raw_w = facts_i[`OOO_SLOT_FACT_ILLEGAL];
  wire fp_disabled_w = facts_i[`OOO_SLOT_FACT_FP_DISABLED];
  wire priv_system_illegal_w = facts_i[`OOO_SLOT_FACT_PRIV_SYSTEM_ILLEGAL];
  wire semihost_ebreak_w = facts_i[`OOO_SLOT_FACT_SEMIHOST_EBREAK];

  assign system_capture_o =
      barrier_base_i && system_raw_w && !csr_illegal_i &&
      !arch_trap_raw_w;
  assign branch_capture_o = barrier_base_i && branch_raw_w;
  assign jump_capture_o = barrier_base_i && jump_raw_w;
  assign fp_capture_o = barrier_base_i && fp_enabled_w;

  assign trap_exit_capture_o = barrier_base_i;
  assign trap_exit_arch_valid_o =
      barrier_base_i &&
      (head_fetch_fault_i || csr_illegal_i || arch_trap_raw_w);
  assign trap_exit_exit_valid_o = barrier_base_i && exit_raw_w;
  assign trap_exit_exit_ecall_o = ecall_raw_w;
  assign trap_exit_exit_ebreak_o = ebreak_raw_w;

  assign trap_exit_cause_o =
      semihost_ebreak_w ? `EXC_BREAKPOINT :
      illegal_raw_w ? `EXC_ILLEGAL_INST :
      fp_disabled_w ? `EXC_ILLEGAL_INST :
      priv_system_illegal_w ? `EXC_ILLEGAL_INST :
      csr_illegal_i ? `EXC_ILLEGAL_INST :
      ((head_resp_i == 2'b10) ? `EXC_INST_PAGE_FAULT :
                                `EXC_INST_ACCESS_FAULT);

  assign trap_exit_tval_o =
      semihost_ebreak_w ? {`XLEN{1'b0}} :
      illegal_raw_w ? head_inst_i :
      fp_disabled_w ? head_inst_i :
      priv_system_illegal_w ? head_inst_i :
      csr_illegal_i ? head_inst_i :
      head_pc_i;

endmodule
