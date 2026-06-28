// Pure combinational dispatch gating for the OoO front-end.
module OooFrontendDispatchGate (
  input dispatch_valid_i,
  input dispatch0_exit_i,
  input dispatch0_arch_trap_i,
  input dispatch0_system_i,
  input dispatch0_fp_i,
  input dispatch0_branch_i,
  input dispatch0_jal_i,
  input dispatch0_jump_i,
  input dispatch0_unsupported_i,
  input dispatch1_unsupported_i,
  input dispatch0_ready_i,
  input dispatch1_ready_i,
  input head0_fp_raw_i,
  input head1_fp_raw_i,
  input head_fetch_fault1_i,
  input head1_exit_raw_i,
  input head1_system_raw_i,
  input head1_arch_trap_raw_i,
  input head1_control_raw_i,
  input head1_branch_raw_i,
  input head1_jal_raw_i,
  input head1_jalr_raw_i,
  input head1_jal_call_raw_i,
  input head1_return_candidate_i,
  input lane0_before_ret_safe_i,

  output dispatch1_direct_jal_o,
  output dispatch1_return_o,
  output direct_branch1_dispatch_valid_o,
  output dispatch1_barrier_o,
  output dispatch1_control_unsupported_o,
  output dispatch1_mem_unsupported_o,
  output dispatch_unsupported_o,
  output dispatch_fire_o,
  output dispatch1_barrier_fire_o,
  output frontend_dispatch_to_backend_valid_o,
  output lane1_barrier_dispatch0_valid_o,
  output direct_jal0_fire_o,
  output direct_jal1_fire_o,
  output direct_ret1_fire_o,
  output direct_branch1_fire_o
);

  wire lane1_base_w =
      dispatch_valid_i &&
      !dispatch0_exit_i &&
      !dispatch0_arch_trap_i &&
      !dispatch0_system_i &&
      !dispatch0_fp_i &&
      !dispatch0_branch_i &&
      !dispatch0_jal_i &&
      !dispatch0_jump_i;

  wire unsupported_base_w =
      dispatch_valid_i &&
      !dispatch0_exit_i &&
      !dispatch0_arch_trap_i &&
      !dispatch0_system_i &&
      !dispatch0_fp_i &&
      !dispatch0_branch_i &&
      !dispatch0_jump_i;

  assign dispatch1_direct_jal_o =
      lane1_base_w && head1_jal_raw_i && !head1_jal_call_raw_i;

  assign dispatch1_return_o =
      lane1_base_w && head1_return_candidate_i && lane0_before_ret_safe_i;

  assign direct_branch1_dispatch_valid_o =
      lane1_base_w && head1_branch_raw_i && !head_fetch_fault1_i;

  assign dispatch1_barrier_o =
      lane1_base_w &&
      (head_fetch_fault1_i ||
       head1_exit_raw_i ||
       head1_system_raw_i ||
       head1_fp_raw_i ||
       head1_arch_trap_raw_i ||
       (head1_branch_raw_i && !direct_branch1_dispatch_valid_o) ||
       (head1_jalr_raw_i && !dispatch1_return_o));

  assign dispatch1_control_unsupported_o =
      lane1_base_w &&
      !dispatch1_barrier_o &&
      !direct_branch1_dispatch_valid_o &&
      !dispatch1_return_o &&
      head1_control_raw_i &&
      !head1_jal_raw_i;

  assign dispatch1_mem_unsupported_o = 1'b0;

  assign dispatch_unsupported_o =
      unsupported_base_w &&
      ((dispatch0_unsupported_i && !head0_fp_raw_i) ||
       (dispatch1_unsupported_i && !head1_fp_raw_i) ||
       dispatch1_control_unsupported_o ||
       dispatch1_mem_unsupported_o);

  assign dispatch_fire_o =
      lane1_base_w &&
      !dispatch1_barrier_o &&
      !dispatch_unsupported_o &&
      dispatch0_ready_i &&
      dispatch1_ready_i;

  assign dispatch1_barrier_fire_o =
      dispatch1_barrier_o && !dispatch0_unsupported_i && dispatch0_ready_i;
  assign frontend_dispatch_to_backend_valid_o =
      dispatch_valid_i && !dispatch0_branch_i && !dispatch0_jal_i &&
      !dispatch0_jump_i && !dispatch0_exit_i && !dispatch0_system_i &&
      !dispatch0_fp_i && !dispatch1_barrier_o &&
      !dispatch1_control_unsupported_o && !dispatch1_mem_unsupported_o;
  assign lane1_barrier_dispatch0_valid_o = dispatch1_barrier_o;

  assign direct_jal0_fire_o =
      dispatch0_jal_i && !dispatch0_unsupported_i && dispatch0_ready_i;
  assign direct_jal1_fire_o = dispatch_fire_o && head1_jal_raw_i;
  assign direct_ret1_fire_o = dispatch_fire_o && dispatch1_return_o;
  assign direct_branch1_fire_o = dispatch_fire_o && head1_branch_raw_i;

endmodule
