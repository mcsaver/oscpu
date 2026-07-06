// ┌─ OoO 前端「取指重定向」组合仲裁器 OooFetchRequestMux 的外部观测 checker ────────────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型的 ② 投影层。                     │
// │ 作用: 读 ① 层真实信号(经 NpcSimTop 的 XMR 连入本模块端口) → 投影成 ③ 抽象状态(facts_w)     │
// │        → 时钟块立即断言合法。挂 SIM_TOP_SRCS, 综合入口(RTL_CORE_SRCS)不吃它 → DCE 零面积。  │
// │ ① 层电路一行不动; 本模块纯旁挂观测, 不进数据通路。                                          │
// │ 断言纪律(§5.6): 编码「独立于 RTL 三元链的真理」(reserved 死态 / 跨模块优先级契约), 非重述。 │
// │ 双仿真器安全: 过程式 $error/$fatal, 非 SVA; 仅 `+define+OOO_ASSERT` 时编入。rst 高有效。    │
// └──────────────────────────────────────────────────────────────────────────────────────────┘
`include "define.v"
`include "common/OooRedirectMuxFacts.vh"

module OooRedirectMuxChecker (
  input wire clk,
  input wire rst,                        // 高有效

  // ── ① 层真实 select 条件(逐档对位 OooFetchRequestMux.v:70-81, first-match)──
  input wire untracked_i,                // Mux:70 branch_resolve_untracked_redirect_i
  input wire direct_jump_spec_i,         // Mux:71 direct_jump_spec_fire_i
  input wire direct_jal_i,               // Mux:72 direct_jal_fire_i
  input wire direct_ret0_i,              // Mux:73 direct_ret0_fire_i
  input wire direct_ret1_i,              // Mux:73 direct_ret1_fire_i
  input wire direct_lane1_ret_i,         // Mux:74 direct_branch0_lane1_ret_i
  input wire branch_target_i,            // Mux:76 branch_target_dispatch_i
  input wire branch_fallthru_i,          // Mux:77 branch_fallthrough_dispatch_i
  input wire direct_br_resolve_i,        // Mux:78 direct_branch_resolve_redirect_i
  input wire pending_jump_nolink_i,      // Mux:79 pending_jump_nolink_commit_i        (reserved 死态)
  input wire pending_jump_redir_i,       // Mux:80 pending_jump_redirect_after_dispatch_i (reserved 死态)
  input wire branch_spec_i,              // Mux:81 branch_spec_redirect_i

  // ── untracked 优先级不变量所需 ──
  input wire [`XLEN-1:0] redirect_fetch_pc_i,           // Mux 输出 redirect_fetch_pc_o
  input wire [`XLEN-1:0] core_branch_resolve_next_pc_i  // Mux:70/82 untracked 目标源
);

  // ── ② 投影: 三元链胜出档 → ③ one-hot 抽象态(first-match; 仅 observability, 非断言依据)──
  wire h0 = untracked_i;
  wire h1 = h0 | direct_jump_spec_i;
  wire h2 = h1 | direct_jal_i;
  wire h3 = h2 | (direct_ret0_i | direct_ret1_i);
  wire h4 = h3 | direct_lane1_ret_i;
  wire h5 = h4 | branch_target_i;
  wire h6 = h5 | branch_fallthru_i;
  wire h7 = h6 | direct_br_resolve_i;
  wire h8 = h7 | (pending_jump_nolink_i | pending_jump_redir_i);
  wire h9 = h8 | branch_spec_i;

  // facts_w = ③ 抽象态 one-hot 投影(observability, 波形可观测); 非断言依据。
  wire [`OOO_RDMUX_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_RDMUX_UNTRACKED]         = untracked_i;
  assign facts_w[`OOO_RDMUX_DIRECT_JUMP_SPEC]  = !h0 & direct_jump_spec_i;
  assign facts_w[`OOO_RDMUX_DIRECT_JAL]        = !h1 & direct_jal_i;
  assign facts_w[`OOO_RDMUX_DIRECT_RET]        = !h2 & (direct_ret0_i | direct_ret1_i);
  assign facts_w[`OOO_RDMUX_DIRECT_LANE1_RET]  = !h3 & direct_lane1_ret_i;
  assign facts_w[`OOO_RDMUX_BRANCH_TARGET]     = !h4 & branch_target_i;
  assign facts_w[`OOO_RDMUX_BRANCH_FALLTHRU]   = !h5 & branch_fallthru_i;
  assign facts_w[`OOO_RDMUX_DIRECT_BR_RESOLVE] = !h6 & direct_br_resolve_i;
  assign facts_w[`OOO_RDMUX_PENDING_JUMP]      = !h7 & (pending_jump_nolink_i | pending_jump_redir_i);
  assign facts_w[`OOO_RDMUX_BRANCH_SPEC]       = !h8 & branch_spec_i;
  assign facts_w[`OOO_RDMUX_NONE]              = !h9;

  // observability sink: facts_w 仅供波形观测, 命名 unused 避免 lint(房规 _unused_ 惯例)。
  wire _unused_facts_w = |facts_w;

`ifdef OOO_ASSERT
  // 非真空已验(2026-07-06): CoreMark 上 untracked 前件可达 126250 次、pc 不变量 126250/126250 成立;
  // 探针法见 task-run。$time 恒 0 是 harness 未推进 Verilator 时间的伪影, 不影响断言逻辑(仅打印)。
  // ── INV-1 (GAP-3 死态): reserved PENDING_JUMP 档的原始条件恒 0(上游 OooFrontend.v:1311/1317-1318
  //    的 wave5b 死硅 tie-0)。任一复活即前端取指重定向契约违约。独立真理来自「该路径已判死」。──
  always @(posedge clk) begin
    if (!rst && (pending_jump_nolink_i || pending_jump_redir_i)) begin
      $error("[RDMUX-DEAD] OooFetchRequestMux reserved PENDING_JUMP 死态复活(上游 tie-0 被破坏): nolink=%b redir=%b @%0t",
             pending_jump_nolink_i, pending_jump_redir_i, $time);
      $fatal;
    end
  end

  // ── INV-2 (untracked 最高优先档结构不变量): untracked 命中 ⟹ redirect_fetch_pc==core_branch_resolve_next_pc
  //    (Mux:70 结构保证)。下游 OooFrontend.v:1934 显式依赖此不变量; 若 Mux 优先级被改破坏, 此断言先响。──
  always @(posedge clk) begin
    if (!rst && untracked_i && (redirect_fetch_pc_i !== core_branch_resolve_next_pc_i)) begin
      $error("[RDMUX-UNTRACKED-PC] untracked 最高优先档不变量破坏(OooFrontend:1934 依赖): pc=%h expect=%h @%0t",
             redirect_fetch_pc_i, core_branch_resolve_next_pc_i, $time);
      $fatal;
    end
  end
`endif

endmodule
