`include "define.v"

// 直跳/返回的组合策略属于 frontend 控制流边界，core glue 只接线消费事件。
module OooDirectControlFlowGate #(
  parameter ENABLE_DIRECT_RAS_RET = 1'b1
)(
  input dispatch0_branch_i,
  // 【F2】双发资格(OooFrontendDispatchGate.dbranch_dual_go): not-taken 预测且 head1
  // 平凡 → 分支不 fire(不 flush 不重取), 与 head1 原子双发走顺序流。
  input dbranch_dual_go_i,
  input dispatch0_jal_i,
  input dispatch0_return_i,
  input dispatch0_unsupported_i,
  input dispatch0_ready_i,
  input direct_jal0_fire_i,
  input direct_jal1_fire_i,
  input [`XLEN-1:0] head0_pc_i,
  input [`XLEN-1:0] head1_pc_i,
  input [`XLEN-1:0] head0_imm_i,
  input [`XLEN-1:0] head1_imm_i,
  input [`XLEN-1:0] head0_next_pc_i,
  input [`XLEN-1:0] head1_next_pc_i,
  input [`REG_ADDR_W-1:0] head0_rd_i,
  input [`REG_ADDR_W-1:0] head1_rd_i,
  input [`XLEN-1:0] ras_top_i,
  input ras_direct_update_safe_i,
  input head_fetch_fault1_i,
  input return_cont_uop_safe_i,
  input return_cont_valid_i,
  input [`XLEN-1:0] return_cont_pc_i,

  output direct_branch0_fire_o,
  output direct_jal0_dispatch_valid_o,
  output direct_jal_fire_o,
  output direct_ret0_dispatch_valid_o,
  output direct_ret0_fire_o,
  output [`XLEN-1:0] direct_jal_target_o,
  output [`XLEN-1:0] direct_ret_target_o,
  output direct_jal0_call_o,
  output direct_jal1_call_o,
  output direct_jal_call_raw_o,
  output direct_jal_call_o,
  output direct_jal_call_unsafe_o,
  output [`XLEN-1:0] direct_jal_link_o,
  output return_cont_safe_o,
  output return_cont_capture_o,
  output return_cont_match_o
);

  // domain-A: direct 分支 fire 保留(它驱动前端按 BHT 预测重定向取指 = 方向预测能力);
  // 总闸(stop_pending+全 drain)在 OooStopPendingSequencer 侧单独 gate 掉; dispatch 仍走
  // 普通路进 ROB, 后端 resolve 比对 pred_npc 纠错。
  // 【F2】dual_go(not-taken+head1 平凡)拍不 fire: 不 flush、顺序流双发, 零重取代价;
  // fire 只剩 taken 预测或 head1 不可双发(barrier/unsupported)的拍(flush+按 pred 重取)。
  assign direct_branch0_fire_o =
      dispatch0_branch_i && !dispatch0_unsupported_i && dispatch0_ready_i &&
      !dbranch_dual_go_i;
  assign direct_jal0_dispatch_valid_o = dispatch0_jal_i;
  assign direct_jal_fire_o = direct_jal0_fire_i || direct_jal1_fire_i;

  assign direct_ret0_dispatch_valid_o = dispatch0_return_i;
  assign direct_ret0_fire_o =
      dispatch0_return_i && !dispatch0_unsupported_i && dispatch0_ready_i;

  assign direct_jal_target_o =
      direct_jal0_fire_i ? (head0_pc_i + head0_imm_i) :
                           (head1_pc_i + head1_imm_i);
  assign direct_ret_target_o = ras_top_i;

  assign direct_jal0_call_o =
      direct_jal0_fire_i &&
      ((head0_rd_i == `REG_ADDR_W'd1) || (head0_rd_i == `REG_ADDR_W'd5));
  assign direct_jal1_call_o =
      direct_jal1_fire_i &&
      ((head1_rd_i == `REG_ADDR_W'd1) || (head1_rd_i == `REG_ADDR_W'd5));
  assign direct_jal_call_raw_o =
      direct_jal0_call_o || direct_jal1_call_o;
  assign direct_jal_call_o =
      ras_direct_update_safe_i && direct_jal_call_raw_o;
  assign direct_jal_call_unsafe_o =
      ENABLE_DIRECT_RAS_RET && direct_jal_call_raw_o &&
      !ras_direct_update_safe_i;
  assign direct_jal_link_o =
      direct_jal0_call_o ? head0_next_pc_i : head1_next_pc_i;

  assign return_cont_safe_o =
      !head_fetch_fault1_i && return_cont_uop_safe_i;
  assign return_cont_capture_o =
      direct_jal0_call_o && return_cont_safe_o;
  assign return_cont_match_o =
      return_cont_valid_i && (return_cont_pc_i == ras_top_i);

endmodule
