// Pure combinational action predicates for the OoO front-end shell.
`include "define.v"
module OooFrontendActionGate (
  input direct_jal_fire_i,
  input direct_branch0_fire_i,
  input direct_branch1_fire_i,
  input direct_ret0_fire_i,
  input direct_ret1_fire_i,
  input can_run_i,
  input fifo_has_packet_i,
  input branch_spec_dispatch_block_i,
  input head_fetch_fault0_i,
  input dispatch0_exit_i,
  input dispatch0_arch_trap_i,
  input dispatch0_system_i,
  input dispatch0_csr_i,              // 【serialize Phase1 §4#2a】合法 head0-CSR 不停头(走正常 dispatch)
  input head0_csr_dispatch_fire_i,   // 【serialize Phase1 §4#2b】head0-CSR 单发 fire → FIFO 单发 pop
  input dispatch0_branch_i,
  input dispatch0_jal_i,
  input dispatch0_jump_i,
  input dispatch1_barrier_i,
  input dispatch1_direct_jal_i,
  input direct_branch1_dispatch_valid_i,
  input dispatch_unsupported_i,
  input dispatch_fire_i,
  input dbranch_dispatch_fire_i,  // domain-A: 分支普通 dispatch fire(pop 源)
  input dispatch1_barrier_fire_i,
  input direct_jal0_fire_i,
  input direct_jump_spec_fire_i,   // B2: 非返回 JALR 投机续取 → 触发前端 flush 重定向
  input fetch_rsp_fire_i,
  input fetch_rsp_can_enqueue_i,
  input fetch_dec0_control_stop_i,
  input fetch_dec1_control_stop_i,
  input csr_trap_mem_valid_i,
  input csr_trap_ex_valid_i,
  input csr_trap_irq_valid_i,
  input core_trap_flush_i,
  input core_serial_flush_i,

  output direct_frontend_flush_o,
  output stop_head_o,
  output fifo_pop_o,
  output fetch_rsp_control_stop_o,
  output fetch_request_blocked_by_trap_o
);

  assign direct_frontend_flush_o =
      direct_jal_fire_i ||
      direct_branch0_fire_i ||
      direct_branch1_fire_i ||
      direct_ret0_fire_i ||
      direct_ret1_fire_i ||
      direct_jump_spec_fire_i;

  assign stop_head_o =
      can_run_i &&
      fifo_has_packet_i &&
      !branch_spec_dispatch_block_i &&
      (head_fetch_fault0_i ||
       dispatch0_exit_i ||
       dispatch0_arch_trap_i ||
       (dispatch0_system_i && !dispatch0_csr_i) ||
       (dispatch0_branch_i && !(`OOO_DBRANCH_DOMAIN_A)) ||
       dispatch0_jal_i ||
       dispatch0_jump_i ||
       dispatch1_barrier_i ||
       dispatch1_direct_jal_i ||
       direct_branch1_dispatch_valid_i ||
       dispatch_unsupported_i);

  assign fifo_pop_o =
      dispatch_fire_i ||
      dbranch_dispatch_fire_i ||
      dispatch1_barrier_fire_i ||
      direct_jal0_fire_i ||
      head0_csr_dispatch_fire_i;   // 【serialize Phase1 §4#2b】head0-CSR 单发 pop(其余 4 项对 CSR 均不 fire)

  assign fetch_rsp_control_stop_o =
      fetch_rsp_fire_i &&
      fetch_rsp_can_enqueue_i &&
      (fetch_dec0_control_stop_i || fetch_dec1_control_stop_i);

  assign fetch_request_blocked_by_trap_o =
      csr_trap_mem_valid_i ||
      csr_trap_ex_valid_i ||
      csr_trap_irq_valid_i ||
      core_trap_flush_i ||
      core_serial_flush_i;

endmodule
