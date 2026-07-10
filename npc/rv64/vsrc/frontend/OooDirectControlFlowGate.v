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

  // 【B2 S2 死化】direct 分支 fire 物理关断——方向预测介入点已前移 fetch resp 拍
  // (taken 在包 enqueue 拍改流顺序取指, target 已在预测路径上), dispatch 拍 fire 只会
  // flush 掉已正确预取的 target 路径且破坏 pred_npc 机械一致性(spec §1, 不作兜底)。
  // taken 分支现走 solo 普通 dispatch(dbranch_dispatch_fire pop + dispatch1_squash 压
  // lane1 影子 + pred_npc=包内 pred_next_pc=target), 预测错由后端 mispredict→E3
  // untracked redirect+ROB-walk kill 纠错(F2 已高频演练通道)。
  // 输入 dispatch0_branch_i/dbranch_dual_go_i 端口证据化保留(死化对照口)。
  assign direct_branch0_fire_o = 1'b0;
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
