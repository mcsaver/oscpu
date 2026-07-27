`include "include/define.v"

module OooCsrTrapRequestMux (
  input wire core_commit0_valid_i,
  input wire core_commit0_exception_i,
  input wire [`XLEN-1:0] core_commit0_pc_i,
  input wire [`TRAP_CAUSE_W-1:0] core_commit0_cause_i,
  input wire [`XLEN-1:0] core_commit0_tval_i,
  input wire core_commit1_valid_i,
  input wire core_commit1_exception_i,
  input wire [`XLEN-1:0] core_commit1_pc_i,
  input wire [`TRAP_CAUSE_W-1:0] core_commit1_cause_i,
  input wire [`XLEN-1:0] core_commit1_tval_i,

  input wire stop_pending_i,
  input wire drain_complete_i,
  input wire pending_arch_trap_i,
  input wire [`TRAP_CAUSE_W-1:0] pending_trap_cause_i,
  input wire [`XLEN-1:0] pending_trap_pc_i,
  input wire [`XLEN-1:0] pending_trap_tval_i,

  input wire pending_system_i,
  input wire pending_system_ecall_i,
  input wire pending_system_mret_i,
  input wire pending_system_irq_i,
  input wire [`XLEN-1:0] pending_system_pc_i,
  input wire [`INST_W-1:0] pending_system_inst_i,
  input wire [`TRAP_CAUSE_W-1:0] pending_system_irq_cause_i,
  input wire [`TRAP_CAUSE_W-1:0] csr_ecall_cause_i,

  input wire pending_system_satp_write_commit_i,
  input wire pending_system_sfence_commit_i,

  output wire core_commit_exception_trap_o,
  output wire trap_mem_valid_o,
  output wire [`XLEN-1:0] trap_mem_pc_o,
  output wire [`TRAP_CAUSE_W-1:0] trap_mem_cause_o,
  output wire [`XLEN-1:0] trap_mem_tval_o,

  output wire pending_system_ecall_trap_o,
  output wire pending_arch_trap_fire_o,
  output wire trap_ex_valid_o,
  output wire [`XLEN-1:0] trap_ex_pc_o,
  output wire [`TRAP_CAUSE_W-1:0] trap_ex_cause_o,
  output wire [`XLEN-1:0] trap_ex_tval_o,

  output wire trap_irq_valid_o,
  output wire [`XLEN-1:0] trap_irq_pc_o,
  output wire [`TRAP_CAUSE_W-1:0] trap_irq_cause_o,

  output wire mret_valid_o,
  output wire sret_valid_o,
  output wire real_mret_valid_o,
  output wire priv_predictor_boundary_o
);

  assign core_commit_exception_trap_o =
      (core_commit0_valid_i && core_commit0_exception_i) ||
      (core_commit1_valid_i && core_commit1_exception_i);
  // V10A: these are accepted requests into CsrFile, not unqualified pending
  // levels.  A same-edge ROB-head exception owns CsrFile's mem>ex>irq
  // priority and clears the younger pending owner through the control plane;
  // suppress the lower-priority raw requests so request counts and downstream
  // boundary pulses describe the single selected architectural transaction.
  wire drained_pending_control_w =
      stop_pending_i && drain_complete_i;
  wire drained_pending_system_w =
      drained_pending_control_w && pending_system_i;
  assign trap_mem_valid_o = core_commit_exception_trap_o;
  assign trap_mem_pc_o =
      (core_commit0_valid_i && core_commit0_exception_i) ?
      core_commit0_pc_i : core_commit1_pc_i;
  assign trap_mem_cause_o =
      (core_commit0_valid_i && core_commit0_exception_i) ?
      core_commit0_cause_i : core_commit1_cause_i;
  assign trap_mem_tval_o =
      (core_commit0_valid_i && core_commit0_exception_i) ?
      core_commit0_tval_i : core_commit1_tval_i;

  assign pending_system_ecall_trap_o =
      drained_pending_system_w && pending_system_ecall_i;
  assign pending_arch_trap_fire_o =
      drained_pending_control_w && pending_arch_trap_i;
  assign trap_ex_valid_o =
      pending_system_ecall_trap_o || pending_arch_trap_fire_o;
  assign trap_ex_pc_o =
      pending_arch_trap_fire_o ? pending_trap_pc_i : pending_system_pc_i;
  assign trap_ex_cause_o =
      pending_arch_trap_fire_o ? pending_trap_cause_i : csr_ecall_cause_i;
  assign trap_ex_tval_o =
      pending_arch_trap_fire_o ? pending_trap_tval_i : {`XLEN{1'b0}};

  assign trap_irq_valid_o =
      drained_pending_system_w && pending_system_irq_i;
  assign trap_irq_pc_o = pending_system_pc_i;
  assign trap_irq_cause_o = pending_system_irq_cause_i;

  assign mret_valid_o = drained_pending_system_w && pending_system_mret_i;
  assign sret_valid_o =
      mret_valid_o && (pending_system_inst_i[31:20] == `SYSTEM_FUNCT12_SRET);
  assign real_mret_valid_o = mret_valid_o && !sret_valid_o;

  assign priv_predictor_boundary_o =
      trap_mem_valid_o || trap_ex_valid_o || trap_irq_valid_o ||
      mret_valid_o || pending_system_satp_write_commit_i ||
      pending_system_sfence_commit_i;

endmodule
