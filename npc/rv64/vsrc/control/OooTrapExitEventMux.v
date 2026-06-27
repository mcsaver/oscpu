`include "include/define.v"

module OooTrapExitEventMux (
  input wire csr_trap_mem_valid_i,
  input wire direct_frontend_flush_i,
  input wire stop_pending_i,
  input wire drain_complete_i,

  input wire branch_spec_resolve_valid_i,
  input wire branch_spec_restore_i,
  input wire core_branch_resolve_misaligned_i,
  input wire [`XLEN-1:0] core_branch_resolve_pc_i,
  input wire [`XLEN-1:0] core_branch_resolve_next_pc_i,

  input wire pending_branch_commit_resolve_i,
  input wire pending_branch_match_clear_i,
  input wire branch_resolve_untracked_i,
  input wire pending_branch_misaligned_i,
  input wire [`XLEN-1:0] pending_branch_pc_i,
  input wire [`XLEN-1:0] pending_branch_target_i,
  input wire pending_branch_valid_i,
  input wire pending_branch_dispatched_i,

  input wire pending_jump_resolve_ready_i,
  input wire pending_jump_misaligned_i,
  input wire [`XLEN-1:0] pending_jump_pc_i,
  input wire [`XLEN-1:0] pending_jump_resolved_target_i,

  input wire pending_mem_resolve_ready_i,
  input wire system_csr_dispatch_fire_i,
  input wire pending_system_csr_commit_i,

  input wire pending_arch_trap_i,
  input wire pending_system_i,
  input wire pending_jump_i,
  input wire pending_mem_i,
  input wire pending_fp_i,
  input wire pending_exit_i,
  input wire pending_exit_is_ecall_i,
  input wire pending_exit_is_ebreak_i,
  input wire [`TRAP_CAUSE_W-1:0] pending_trap_cause_i,
  input wire [`XLEN-1:0] pending_trap_pc_i,
  input wire [`XLEN-1:0] pending_trap_tval_i,

  output wire trap_o,
  output wire [`TRAP_CAUSE_W-1:0] trap_cause_o,
  output wire [`XLEN-1:0] trap_pc_o,
  output wire [`XLEN-1:0] trap_tval_o,
  output wire exit_o,
  output wire exit_is_ecall_o,
  output wire exit_is_ebreak_o
);

  wire drain_reached_w =
      !csr_trap_mem_valid_i && !direct_frontend_flush_i &&
      stop_pending_i && drain_complete_i &&
      !pending_branch_commit_resolve_i &&
      !pending_branch_match_clear_i &&
      !branch_resolve_untracked_i &&
      !pending_jump_resolve_ready_i &&
      !pending_mem_resolve_ready_i &&
      !system_csr_dispatch_fire_i &&
      !pending_system_csr_commit_i;
  wire branch_spec_misaligned_w =
      !direct_frontend_flush_i && branch_spec_resolve_valid_i &&
      branch_spec_restore_i && core_branch_resolve_misaligned_i;
  wire branch_commit_misaligned_w =
      pending_branch_commit_resolve_i && pending_branch_misaligned_i;
  wire branch_match_misaligned_w =
      pending_branch_match_clear_i && core_branch_resolve_misaligned_i;
  wire untracked_branch_misaligned_w =
      !direct_frontend_flush_i && branch_resolve_untracked_i &&
      core_branch_resolve_misaligned_i;
  wire jump_misaligned_w =
      !direct_frontend_flush_i && pending_jump_resolve_ready_i &&
      pending_jump_misaligned_i;
  wire drain_branch_misaligned_w =
      drain_reached_w &&
      !pending_arch_trap_i &&
      !pending_system_i &&
      pending_branch_valid_i && !pending_branch_dispatched_i &&
      pending_branch_misaligned_i;
  wire drain_trap_payload_w =
      drain_reached_w &&
      !pending_arch_trap_i &&
      !pending_system_i &&
      !(pending_branch_valid_i && !pending_branch_dispatched_i) &&
      !pending_jump_i &&
      !pending_mem_i &&
      !pending_fp_i &&
      !pending_exit_i &&
      !branch_commit_misaligned_w &&
      !branch_match_misaligned_w &&
      !untracked_branch_misaligned_w &&
      !jump_misaligned_w &&
      !drain_branch_misaligned_w;

  assign trap_o =
      branch_commit_misaligned_w ||
      branch_match_misaligned_w ||
      untracked_branch_misaligned_w ||
      jump_misaligned_w ||
      drain_branch_misaligned_w ||
      drain_trap_payload_w ||
      branch_spec_misaligned_w;
  assign trap_cause_o =
      drain_trap_payload_w ? pending_trap_cause_i : `EXC_INST_ADDR_MISALIGN;
  assign trap_pc_o =
      branch_commit_misaligned_w ? pending_branch_pc_i :
      jump_misaligned_w ? pending_jump_pc_i :
      drain_branch_misaligned_w ? pending_branch_pc_i :
      drain_trap_payload_w ? pending_trap_pc_i :
      core_branch_resolve_pc_i;
  assign trap_tval_o =
      branch_commit_misaligned_w ? pending_branch_target_i :
      jump_misaligned_w ? pending_jump_resolved_target_i :
      drain_branch_misaligned_w ? pending_branch_target_i :
      drain_trap_payload_w ? pending_trap_tval_i :
      core_branch_resolve_next_pc_i;

  assign exit_o =
      drain_reached_w &&
      !pending_arch_trap_i &&
      !pending_system_i &&
      !(pending_branch_valid_i && !pending_branch_dispatched_i) &&
      !pending_jump_i &&
      !pending_mem_i &&
      !pending_fp_i &&
      pending_exit_i;
  assign exit_is_ecall_o = pending_exit_is_ecall_i;
  assign exit_is_ebreak_o = pending_exit_is_ebreak_i;

endmodule
