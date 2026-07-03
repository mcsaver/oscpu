// Pure combinational dispatch gating for the OoO front-end.
`include "define.v"
module OooFrontendDispatchGate (
  input dispatch_valid_i,
  input dispatch0_exit_i,
  input dispatch0_arch_trap_i,
  input dispatch0_system_i,
  input dispatch0_fp_i,
  // 【F2】纯 BHT 寄存输出(不经 fire-mux, 不含 ready)——dual 资格/branch1 fire gate 用,
  // 谓词无 ready 依赖故不与 dispatch pair-ready 成组合环(#110 边界 3 的破环约束)。
  input head0_branch_pred_taken_i,
  input head1_branch_pred_taken_i,
  input dispatch0_branch_i,
  input dispatch0_jal_i,
  input dispatch0_jump_i,
  input dispatch0_return_i,   // B2: 非返回 JALR 在 mode 下走普通 dispatch present（de-pend），return JALR 仍走 RAS
  input dispatch0_unsupported_i,
  input dispatch1_unsupported_i,
  // 【F2】裸支持性(纯 inst 组合, 无 valid 项): dual_go 谓词专用——含 valid 版经
  // core_dispatch1_valid←dual_go 成 UNOPTFLAT 环(lint 实测)。
  input dispatch0_unsupported_raw_i,
  input dispatch1_unsupported_raw_i,
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
  output direct_branch1_fire_o,
  // domain-A: head0 分支经普通 dispatch 被后端接收的 fire(FIFO pop 源)
  output dbranch_dispatch_fire_o,
  // 【F2】head0 分支的双发资格: 预测 not-taken 且 head1 平凡可双发 → 不 fire 不 flush,
  // 分支按普通指令与 head1 原子双发(顺序流零代价)。谓词全为 head 侧事实, 无 ready。
  output dbranch_dual_go_o
);

  assign dbranch_dual_go_o =
      dispatch_valid_i && dispatch0_branch_i &&
      !head0_branch_pred_taken_i &&
      !head_fetch_fault1_i &&
      !head1_exit_raw_i &&
      !head1_system_raw_i &&
      !head1_arch_trap_raw_i &&
      !dispatch0_unsupported_raw_i &&
      !dispatch1_unsupported_raw_i;

  wire lane1_base_w =
      dispatch_valid_i &&
      !dispatch0_exit_i &&
      !dispatch0_arch_trap_i &&
      !dispatch0_system_i &&
      (!dispatch0_branch_i || dbranch_dual_go_o) &&
      !dispatch0_jal_i &&
      !dispatch0_jump_i;

  wire unsupported_base_w =
      dispatch_valid_i &&
      !dispatch0_exit_i &&
      !dispatch0_arch_trap_i &&
      !dispatch0_system_i &&
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

  assign dbranch_dispatch_fire_o =
      dbranch_domain_a_w && dispatch_valid_i && dispatch0_branch_i &&
      !dispatch0_unsupported_i && dispatch0_ready_i;

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
  // domain-A 第一刀: head0 条件分支改走普通 dispatch 进 ROB/IQ(与 head1 分支同构),
  // 不再被 direct 通路(前端解析+flush+全 drain 总闸)独占。
  wire dbranch_domain_a_w = `OOO_DBRANCH_DOMAIN_A;
  assign frontend_dispatch_to_backend_valid_o =
      dispatch_valid_i && (!dispatch0_branch_i || dbranch_domain_a_w) && !dispatch0_jal_i &&
      (!dispatch0_jump_i || dispatch0_depend_jump_w) &&
      !dispatch0_exit_i && !dispatch0_system_i &&
      // 【B-FP 簇】FP 迁域 A: head0 FP 走普通 dispatch 进 ROB/FP 簇, 不再 capture。
      !dispatch1_barrier_o &&
      !dispatch1_control_unsupported_o && !dispatch1_mem_unsupported_o;
  assign lane1_barrier_dispatch0_valid_o = dispatch1_barrier_o;

  assign direct_jal0_fire_o =
      dispatch0_jal_i && !dispatch0_unsupported_i && dispatch0_ready_i;
  assign direct_jal1_fire_o = dispatch_fire_o && head1_jal_raw_i;
  assign direct_ret1_fire_o = dispatch_fire_o && dispatch1_return_o;
  // 【F2】head1 分支同样只在预测 taken 时 fire(flush+重取 target);
  // not-taken 预测 → 不 fire, 顺序流继续, pred_npc(d1)=下包 pc0/哨兵。
  assign direct_branch1_fire_o = dispatch_fire_o && head1_branch_raw_i &&
                                 head1_branch_pred_taken_i;

endmodule
