// Pure combinational direct-branch select and resolve facts.
`include "define.v"

module OooDirectBranchResolveGate (
  input direct_branch0_fire_i,
  input direct_branch1_fire_i,
  input [`XLEN-1:0] head0_pc_i,
  input [`XLEN-1:0] head1_pc_i,
  input [`XLEN-1:0] head0_next_pc_i,
  input [`XLEN-1:0] head1_next_pc_i,
  input [`XLEN-1:0] head0_imm_i,
  input [`XLEN-1:0] head1_imm_i,
  input [`BPU_BHT_INDEX_W-1:0] head0_bht_idx_i,
  input head0_bht_valid_i,
  input head0_pred_taken_i,
  input [`BPU_BHT_INDEX_W-1:0] head1_bht_idx_i,
  input head1_bht_valid_i,
  input head1_pred_taken_i,
  input dispatch_resolve_valid_i,
  input [`XLEN-1:0] dispatch_resolve_pc_i,
  input [`XLEN-1:0] dispatch_resolve_next_pc_i,
  input dispatch_resolve_misaligned_i,
  input issue_resolve_valid_i,
  input [`XLEN-1:0] issue_resolve_pc_i,
  input [`XLEN-1:0] issue_resolve_next_pc_i,
  input issue_resolve_misaligned_i,
  input trap_redirect_squash_i,
  input synth_lane1_ret_pending_i,
  input synth_lane1_branch_drop_pending_i,
  input head1_return_candidate_i,

  output direct_branch_fire_o,
  output [`XLEN-1:0] direct_branch_pc_o,
  output [`XLEN-1:0] direct_branch_next_pc_o,
  output [`XLEN-1:0] direct_branch_imm_o,
  output [`XLEN-1:0] head0_branch_target_o,
  output [`XLEN-1:0] direct_branch_target_o,
  output [`BPU_BHT_INDEX_W-1:0] direct_branch_bht_idx_o,
  output direct_branch_bht_valid_o,
  output direct_branch_predict_taken_o,
  output [`XLEN-1:0] direct_branch_pred_pc_o,
  output direct_branch_resolve_valid_o,
  output [`XLEN-1:0] direct_branch_resolve_next_pc_o,
  output direct_branch_resolve_misaligned_o,
  output direct_branch_resolve_redirect_o,
  output direct_branch_resolve_taken_o,
  output direct_branch0_lane1_ret_o
);

  wire direct_branch0_dispatch_resolve_valid_w =
      direct_branch0_fire_i &&
      dispatch_resolve_valid_i &&
      (dispatch_resolve_pc_i == head0_pc_i);
  wire direct_branch1_dispatch_resolve_valid_w =
      direct_branch1_fire_i &&
      dispatch_resolve_valid_i &&
      (dispatch_resolve_pc_i == head1_pc_i);
  wire direct_branch_dispatch_resolve_valid_w =
      direct_branch0_dispatch_resolve_valid_w ||
      direct_branch1_dispatch_resolve_valid_w;
  // [tie-off] F2(OOO_DBRANCH_DOMAIN_A=1)下 direct branch 的 issue 级解析归 OooIntBackend
  // 的 branch_resolve_valid_o(+ROB-walk kill / BPU issue-resolve 单源)所有；本前端快臂在 F2
  // 已无合法功能——direct branch 离开取指头之后才在 issue 解析，(issue_resolve_pc_i==direct_branch_pc_o)
  // 只能靠跨实例 PC 别名巧合匹配，一旦巧合会经下方 direct_branch0_lane1_ret_o 合成 lane1-ret
  // commit 造成该 ret 双提交(rtl-ground-truth-2026-07-03 §4 理论风险残留)。故在 F2 显式门死此臂
  // (dispatch 臂已由源头 dispatch_resolve_valid_i=0 门死),消除该理论双提交风险。
  wire direct_branch_issue_resolve_valid_w =
      !(`OOO_DBRANCH_DOMAIN_A) &&
      direct_branch_fire_o &&
      issue_resolve_valid_i &&
      (issue_resolve_pc_i == direct_branch_pc_o);
  wire direct_branch_resolve_redirect_raw_w =
      direct_branch_resolve_valid_o && !direct_branch_resolve_misaligned_o;

  assign direct_branch_fire_o =
      direct_branch0_fire_i || direct_branch1_fire_i;
  assign direct_branch_pc_o =
      direct_branch1_fire_i ? head1_pc_i : head0_pc_i;
  assign direct_branch_next_pc_o =
      direct_branch1_fire_i ? head1_next_pc_i : head0_next_pc_i;
  assign direct_branch_imm_o =
      direct_branch1_fire_i ? head1_imm_i : head0_imm_i;
  assign head0_branch_target_o = head0_pc_i + head0_imm_i;
  assign direct_branch_target_o =
      direct_branch_pc_o + direct_branch_imm_o;
  assign direct_branch_bht_idx_o =
      direct_branch1_fire_i ? head1_bht_idx_i : head0_bht_idx_i;
  assign direct_branch_bht_valid_o =
      direct_branch1_fire_i ? head1_bht_valid_i : head0_bht_valid_i;
  assign direct_branch_predict_taken_o =
      direct_branch1_fire_i ? head1_pred_taken_i : head0_pred_taken_i;
  assign direct_branch_pred_pc_o =
      direct_branch_predict_taken_o ? direct_branch_target_o :
                                      direct_branch_next_pc_o;

  assign direct_branch_resolve_valid_o =
      direct_branch_dispatch_resolve_valid_w ||
      direct_branch_issue_resolve_valid_w;
  assign direct_branch_resolve_next_pc_o =
      direct_branch_dispatch_resolve_valid_w ?
      dispatch_resolve_next_pc_i : issue_resolve_next_pc_i;
  assign direct_branch_resolve_misaligned_o =
      direct_branch_dispatch_resolve_valid_w ?
      dispatch_resolve_misaligned_i : issue_resolve_misaligned_i;
  assign direct_branch_resolve_redirect_o =
      direct_branch_resolve_redirect_raw_w && !trap_redirect_squash_i;
  assign direct_branch_resolve_taken_o =
      direct_branch_resolve_redirect_o &&
      (direct_branch_resolve_next_pc_o == direct_branch_target_o);

  assign direct_branch0_lane1_ret_o =
      direct_branch0_fire_i &&
      direct_branch_resolve_valid_o &&
      !synth_lane1_ret_pending_i &&
      !synth_lane1_branch_drop_pending_i &&
      !direct_branch_resolve_misaligned_o &&
      (direct_branch_resolve_next_pc_o == head1_pc_i) &&
      head1_return_candidate_i;

endmodule
