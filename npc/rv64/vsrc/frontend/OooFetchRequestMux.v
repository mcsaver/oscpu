// Pure combinational fetch request PC/source mux for the OoO front-end.
//
// 【P4 切消费点(2026-07-09)】redirect PC 真源已收敛到 OooRedirectArbiter(年龄律,
// OooFrontend 内实例)——本模块原 :66-82 的 first-match 三元链(untracked>jump_spec>
// jal>ret>lane1_ret>branch_target>fallthrough>direct_resolve>pending_jump>spec)整链
// 删除, redirect_fetch_pc_o = arbiter 赢家 PC 透传; 非 arbiter 拍(E7 branch_resolve_redirect
// /E9 branch_spec_redirect 保留臂)兜底 core_branch_resolve_next_pc(与原链默认档一致)。
// valid/流控职责(direct_redirect_fetch_o/redirect_fetch_req_valid_o/fetch_req_pc_o 三段)
// 原样保留——它们不是 PC 真源。
// 【刀 K1(2026-07-10)→B2 S2 取代】K1 曾把 branch0/1_fire 加进 redirect_fetch_req_valid
// 或集(taken 分支 fire 同拍重取, 空窗 3→2 拍); B2 S2 预测介入点前移 fetch resp 拍后
// 分支 fire 物理死化, 两项随之删除——taken 重取降格为"顺序流地址选择"(rsp 拍
// Sequencer 顺序推进臂写包 pred_next_pc, 次拍顺序臂发 target), 不再经 redirect 臂。
// 顺序臂 rsp 项保持 fetch_rsp_packet_next_pc(fall-through): pred-taken 拍顺序请求被
// OooFetchFlowControl.pred_taken_block 关断, not-taken 拍 pred_next_pc≡packet_next_pc
// ——语义等价且 BPU/imm 加法锥不进 fetch_req_pc(刀 F WNS 家族禁令)。
`include "define.v"

module OooFetchRequestMux (
  input outstanding_valid_i,
  input fetch_rsp_valid_i,
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
  // 【时序 T1】resolve 族 redirect(E3 untracked/E7 resolve/E9 spec)不再同拍发取指
  // (砍 dcache-rdata→…→resolve→fetch SRAM addr 全流水贯通链的尾段 ~2.5ns);
  // 本口=当拍封顺序臂(next_fetch_pc_q 拍尾才写 target, 防旧值 wrong-path 请求
  // ——F2 障碍①同族), 次拍顺序臂发 arb 终写的 target(+1 拍 mispredict penalty,
  // 低频 ~8% 分支)。direct fire(预测, 高频)保持同拍(K1 收益不动)。
  output resolve_redirect_block_o,
  output [`XLEN-1:0] redirect_fetch_pc_o,
  output [`XLEN-1:0] fetch_req_pc_o
);

  wire [`XLEN-1:0] fetch_req_seq_pc_w =
      // T3Z: response presence is registered by the Bridge and is sufficient
      // to preload the normal replacement candidate.  Waiting for fire would
      // feed downstream ready back into the next immutable-context bank D.
      (outstanding_valid_i && fetch_rsp_valid_i) ?
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

  assign resolve_redirect_block_o =
      branch_resolve_redirect_i ||
      branch_spec_redirect_i ||
      branch_resolve_untracked_redirect_i;
  // 【redirect 防火墙(2026-07-11 拓扑重划)】同拍 redirect 取指发射全体退役:
  // backend→frontend 的唯一控制交叉点立强制拍界, 全部 redirect(direct jal/ret/
  // jump_spec/pending_jump/trap 族)次拍经顺序臂发 arb 终写 target——切断
  // dcache-rdata→direct fire→redirect→fetch fire 的跨域传递闭包(25ns 链)。
  // direct fire 拍顺序臂由 direct_redirect_fetch_o 作 block 信号封死
  // (F2 障碍①同族, FlowControl 侧)。CPI 代价=jal/ret 重取 +1 拍(~+0.05-0.10)。
  assign redirect_fetch_req_valid_o = 1'b0;

  // 【P4 单源】arbiter 赢家 PC 透传; 无赢家拍(E7/E9 保留臂进 valid 但不进 arbiter)
  // 兜底 core_branch_resolve_next_pc——与原链 :81-82 默认档相同目标, 语义等价。
  assign redirect_fetch_pc_o =
      redirect_valid_i ? redirect_pc_i : core_branch_resolve_next_pc_i;

  assign fetch_req_pc_o =
      redirect_fetch_req_valid_o ? redirect_fetch_pc_o :
      branch_prefetch_req_valid_i ? branch_prefetch_req_pc_i :
                                    fetch_req_seq_pc_w;

endmodule
