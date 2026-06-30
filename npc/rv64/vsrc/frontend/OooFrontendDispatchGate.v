// Pure combinational dispatch gating for the OoO front-end.
`include "define.v"
module OooFrontendDispatchGate (
  input dispatch_valid_i,
  input dispatch0_exit_i,
  input dispatch0_arch_trap_i,
  input dispatch0_system_i,
  input dispatch0_fp_i,
  input dispatch0_branch_i,
  input dispatch0_jal_i,
  input dispatch0_jump_i,
  input dispatch0_return_i,   // B2: 非返回 JALR 在 mode 下走普通 dispatch present（de-pend），return JALR 仍走 RAS
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

  // B2 de-pend：mode 下 lane1 非返回 JALR 复用 lane1-branch 的 dual-issue 投机 present（不再 barrier→pending_jump，
  // 后者在 mode 下 capture 被门控关 → lane1 JALR 会随 packet pop 永久丢失）。dual present 后 backend issue1
  // 强制 mispredict → ROB-walk + redirect 修正（与 lane1 branch 同机制）。
  wire dispatch1_depend_jump_w =
      `OOO_ROB_WALK_MODE && head1_jalr_raw_i && !dispatch1_return_o;
  assign dispatch1_barrier_o =
      lane1_base_w &&
      (head_fetch_fault1_i ||
       head1_exit_raw_i ||
       head1_system_raw_i ||
       head1_fp_raw_i ||
       head1_arch_trap_raw_i ||
       (head1_branch_raw_i && !direct_branch1_dispatch_valid_o) ||
       (head1_jalr_raw_i && !dispatch1_return_o && !dispatch1_depend_jump_w));

  assign dispatch1_control_unsupported_o =
      lane1_base_w &&
      !dispatch1_barrier_o &&
      !direct_branch1_dispatch_valid_o &&
      !dispatch1_return_o &&
      !dispatch1_depend_jump_w &&
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
  // B2 de-pend：mode 下非返回 JALR(dispatch0_jump && !return)走普通 dispatch present（不再依赖被门控的 pending-jump）；
  // branch 走 direct_branch0(投机)、jal 走 direct_jal0、return JALR 走 direct_ret——故此处只放行非返回 JALR。
  wire dispatch0_depend_jump_w =
      `OOO_ROB_WALK_MODE && dispatch0_jump_i && !dispatch0_return_i;
  assign frontend_dispatch_to_backend_valid_o =
      dispatch_valid_i && !dispatch0_branch_i && !dispatch0_jal_i &&
      (!dispatch0_jump_i || dispatch0_depend_jump_w) &&
      !dispatch0_exit_i && !dispatch0_system_i &&
      !dispatch0_fp_i && !dispatch1_barrier_o &&
      !dispatch1_control_unsupported_o && !dispatch1_mem_unsupported_o;
  assign lane1_barrier_dispatch0_valid_o = dispatch1_barrier_o;

  assign direct_jal0_fire_o =
      dispatch0_jal_i && !dispatch0_unsupported_i && dispatch0_ready_i;
  assign direct_jal1_fire_o = dispatch_fire_o && head1_jal_raw_i;
  assign direct_ret1_fire_o = dispatch_fire_o && dispatch1_return_o;
  assign direct_branch1_fire_o = dispatch_fire_o && head1_branch_raw_i;

endmodule
