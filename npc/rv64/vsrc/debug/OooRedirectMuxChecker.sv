// ┌─ OoO 前端「取指重定向」组合汇合点 OooFetchRequestMux 的外部观测 checker ─────────────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型的 ② 投影层。                     │
// │ 作用: 读 ① 层真实信号(经 NpcSimTop 的 XMR 连入本模块端口) → 投影成 ③ 抽象状态(facts_w)     │
// │        → 时钟块立即断言合法。挂 SIM_TOP_SRCS, 综合入口(RTL_CORE_SRCS)不吃它 → DCE 零面积。  │
// │ 【P4 切消费点(2026-07-09)】原 11 档链序投影随 mux 三元链删除而重写: mux PC 侧只剩         │
// │ 「arbiter 赢家透传 or 默认兜底」二择——INV-2 改守单源透传结构(重加链臂即 fire);            │
// │ INV-1(reserved PENDING_JUMP 死态)照旧(pending_jump* 仍是 mux valid 成员, tie-0 未动)。    │
// │ 双仿真器安全: 过程式 $error/$fatal, 非 SVA; 仅 `+define+OOO_ASSERT` 时编入。rst 高有效。    │
// └──────────────────────────────────────────────────────────────────────────────────────────┘
`include "define.v"
`include "common/OooRedirectMuxFacts.vh"

module OooRedirectMuxChecker (
  input wire clk,
  input wire rst,                        // 高有效

  // ── ① 层真实信号(XMR 自 OooFetchRequestMux 端口) ──
  input wire pending_jump_nolink_i,      // pending_jump_nolink_commit_i        (reserved 死态)
  input wire pending_jump_redir_i,       // pending_jump_redirect_after_dispatch_i (reserved 死态)
  input wire redirect_valid_i,           // OooRedirectArbiter 赢家 valid(经 mux redirect_valid_i)
  input wire [`XLEN-1:0] redirect_pc_i,  // arbiter 赢家 PC
  input wire [`XLEN-1:0] redirect_fetch_pc_i,           // Mux 输出 redirect_fetch_pc_o
  input wire [`XLEN-1:0] core_branch_resolve_next_pc_i  // 默认兜底源
);

  // ── ② 投影: 二择 → ③ 抽象态(observability; 非断言依据) ──
  wire [`OOO_RDMUX_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_RDMUX_ARB]     = redirect_valid_i;
  assign facts_w[`OOO_RDMUX_DEFAULT] = !redirect_valid_i;

  // observability sink: facts_w 仅供波形观测, 命名 unused 避免 lint(房规 _unused_ 惯例)。
  wire _unused_facts_w = |facts_w;

`ifdef OOO_ASSERT
  // ── INV-1 (GAP-3 死态): reserved PENDING_JUMP 档的原始条件恒 0(上游 OooFrontend
  //    wave5b 死硅 tie-0)。任一复活即前端取指重定向契约违约。独立真理来自「该路径已判死」。──
  always @(posedge clk) begin
    if (!rst && (pending_jump_nolink_i || pending_jump_redir_i)) begin
      $error("[RDMUX-DEAD] OooFetchRequestMux reserved PENDING_JUMP 死态复活(上游 tie-0 被破坏): nolink=%b redir=%b @%0t",
             pending_jump_nolink_i, pending_jump_redir_i, $time);
      $fatal;
    end
  end

  // ── INV-2 (P4 单源透传结构不变量): mux PC 落点 = 赢家透传 or 默认兜底, 无第三源。
  //    有人往 mux 重加优先级链臂(回退到双真源)即 fire——单源化的结构钉子。──
  always @(posedge clk) begin
    if (!rst && redirect_valid_i &&
        (redirect_fetch_pc_i !== redirect_pc_i)) begin
      $error("[RDMUX-ARB-PC] arbiter 赢家拍 mux 落点未透传赢家 PC(链臂复活?): pc=%h expect=%h @%0t",
             redirect_fetch_pc_i, redirect_pc_i, $time);
      $fatal;
    end
    if (!rst && !redirect_valid_i &&
        (redirect_fetch_pc_i !== core_branch_resolve_next_pc_i)) begin
      $error("[RDMUX-DEFAULT-PC] 无赢家拍 mux 落点未兜底 core_branch_resolve_next_pc: pc=%h expect=%h @%0t",
             redirect_fetch_pc_i, core_branch_resolve_next_pc_i, $time);
      $fatal;
    end
  end
`endif

endmodule
