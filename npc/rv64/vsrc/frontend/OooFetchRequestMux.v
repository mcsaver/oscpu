// Pure combinational fetch request PC/source mux for the OoO front-end.
//
// 【P4 切消费点(2026-07-09)】redirect PC 真源已收敛到 OooRedirectArbiter(年龄律,
// OooFrontend 内实例)——本模块原 :66-82 的 first-match 三元链(untracked>jump_spec>
// jal>ret>lane1_ret>branch_target>fallthrough>direct_resolve>pending_jump>spec)整链
// 删除, redirect_fetch_pc_o = arbiter 赢家 PC 透传; 非 arbiter 拍(E7 branch_resolve_redirect
// /E9 branch_spec_redirect 保留臂)兜底 core_branch_resolve_next_pc(与原链默认档一致)。
// valid/流控职责(direct_redirect_fetch_o/redirect_fetch_req_valid_o/fetch_req_pc_o 三段)
// 原样保留——它们不是 PC 真源, 且 valid 成员集与 arbiter direct 口不同(e4 valid 含普通
// branch0/1_fire 而本 valid 不含), 改接 arbiter valid 会给预测-taken 分支新增同拍取指
// 请求 = 时序变化, 禁止(ooo-flush-redirect-contract.md GAP-3/切消费点契约禁止项①)。
`include "define.v"

module OooFetchRequestMux (
  input outstanding_valid_i,
  input fetch_rsp_fire_i,
  input [`XLEN-1:0] fetch_rsp_packet_next_pc_i,
  input [`XLEN-1:0] next_fetch_pc_i,
  input direct_jal_fire_i,
  input direct_ret0_fire_i,
  input direct_ret1_fire_i,
  input direct_branch0_lane1_ret_i,
  input pending_jump_nolink_commit_i,
  input pending_jump_redirect_after_dispatch_i,
  input direct_branch_resolve_redirect_i,
  input branch_resolve_redirect_i,
  input branch_spec_redirect_i,
  input branch_resolve_untracked_redirect_i,
  input branch_fallthrough_dispatch_i,
  input branch_fallthrough_outstanding_match_i,
  input [`XLEN-1:0] core_branch_resolve_next_pc_i,
  input branch_prefetch_req_valid_i,
  input [`XLEN-1:0] branch_prefetch_req_pc_i,
  input direct_jump_spec_fire_i,           // B2: 非返回 JALR 投机续取
  // 【P4】统一 redirect 仲裁赢家(OooRedirectArbiter 输出, 单一 PC 真源)
  input redirect_valid_i,
  input [`XLEN-1:0] redirect_pc_i,

  output direct_redirect_fetch_o,
  output redirect_fetch_req_valid_o,
  output [`XLEN-1:0] redirect_fetch_pc_o,
  output [`XLEN-1:0] fetch_req_pc_o
);

  wire [`XLEN-1:0] fetch_req_seq_pc_w =
      (outstanding_valid_i && fetch_rsp_fire_i) ?
      fetch_rsp_packet_next_pc_i : next_fetch_pc_i;

  assign direct_redirect_fetch_o =
      direct_jal_fire_i ||
      direct_ret0_fire_i ||
      direct_ret1_fire_i ||
      direct_branch0_lane1_ret_i ||
      pending_jump_nolink_commit_i ||
      pending_jump_redirect_after_dispatch_i ||
      direct_branch_resolve_redirect_i ||
      direct_jump_spec_fire_i;

  assign redirect_fetch_req_valid_o =
      (direct_redirect_fetch_o ||
       branch_resolve_redirect_i ||
       branch_spec_redirect_i ||
       branch_resolve_untracked_redirect_i) &&
      (!branch_fallthrough_dispatch_i ||
       !branch_fallthrough_outstanding_match_i) &&
      (!outstanding_valid_i || fetch_rsp_fire_i);

  // 【P4 单源】arbiter 赢家 PC 透传; 无赢家拍(E7/E9 保留臂进 valid 但不进 arbiter)
  // 兜底 core_branch_resolve_next_pc——与原链 :81-82 默认档相同目标, 语义等价。
  assign redirect_fetch_pc_o =
      redirect_valid_i ? redirect_pc_i : core_branch_resolve_next_pc_i;

  assign fetch_req_pc_o =
      redirect_fetch_req_valid_o ? redirect_fetch_pc_o :
      branch_prefetch_req_valid_i ? branch_prefetch_req_pc_i :
                                    fetch_req_seq_pc_w;

endmodule
