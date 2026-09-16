`include "define.v"

// 对外 trap/debug/CSR 可观察输出由 control 边界统一选择，core glue 不再内联状态语义。
module OooCoreObservableOutputGate(
  input trap_valid_i,
  input [`TRAP_CAUSE_W-1:0] trap_cause_i,
  input [`XLEN-1:0] trap_pc_i,
  input [`XLEN-1:0] trap_tval_i,
  input exit_valid_i,
  input exit_is_ecall_i,
  input exit_is_ebreak_i,
  input [`XLEN-1:0] exit_code_i,
  input halted_i,
  input stop_pending_i,
  input pending_branch_i,
  input pending_jump_i,
  input pending_mem_i,
  input pending_system_i,
  input synth_lane1_ret_pending_i,
  input synth_lane1_branch_drop_pending_i,
  input [1:0] csr_priv_mode_i,
  input [`XLEN-1:0] csr_mstatus_i,
  input [`XLEN-1:0] csr_satp_i,
  input csr_svpbmt_en_i,
  input [`PMP_CFG_BUS_W-1:0] csr_pmpcfg_i,
  input [`PMP_ADDR_BUS_W-1:0] csr_pmpaddr_i,
  input [`XLEN * `REG_NUM - 1:0] debug_gprs_i,
  input fifo_has_packet_i,
  input [`XLEN-1:0] head_pc_i,
  input outstanding_valid_i,
  input [`XLEN-1:0] outstanding_pc_i,
  input [`XLEN-1:0] next_fetch_pc_i,
  input fetch_req_valid_i,
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
  output [`XLEN * `REG_NUM - 1:0] debug_gprs_o
);

  assign trap_valid_o = trap_valid_i;
  assign trap_cause_o = trap_cause_i;
  assign trap_pc_o = trap_pc_i;
  assign trap_tval_o = trap_tval_i;
  assign exit_valid_o = exit_valid_i;
  assign exit_is_ecall_o = exit_is_ecall_i;
  assign exit_is_ebreak_o = exit_is_ebreak_i;
  assign exit_code_o = exit_code_i;
  assign halted_o = halted_i ||
                    (stop_pending_i && !pending_branch_i && !pending_jump_i &&
                     !pending_mem_i && !pending_system_i &&
                     !synth_lane1_ret_pending_i &&
                     !synth_lane1_branch_drop_pending_i);
  assign priv_mode_o = csr_priv_mode_i;
  assign mstatus_o = csr_mstatus_i;
  assign satp_o = csr_satp_i;
  assign svpbmt_en_o = csr_svpbmt_en_i;
  assign pmpcfg_o = csr_pmpcfg_i;
  assign pmpaddr_o = csr_pmpaddr_i;
  assign debug_gprs_o = debug_gprs_i;
  assign debug_pc_o = trap_valid_i ? trap_pc_i :
                      fifo_has_packet_i ? head_pc_i :
                      outstanding_valid_i ? outstanding_pc_i :
                      next_fetch_pc_i;
  assign debug_state_o =
      trap_valid_i ? `CORE_STATE_TRAP :
      halted_i ? `CORE_STATE_HALT :
      fifo_has_packet_i ? `CORE_STATE_DECODE :
      outstanding_valid_i ? `CORE_STATE_FETCH_WAIT :
      fetch_req_valid_i ? `CORE_STATE_FETCH_REQ :
      `CORE_STATE_FETCH_REQ;

endmodule
