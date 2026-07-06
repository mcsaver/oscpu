// ┌─ OoO 前端「取指重定向」时序仲裁器 OooFetchPcOutstandingSequencer 的外部观测 checker ─────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型 ② 投影层。redirect 双仲裁器之(B)。 │
// │ 作用: XMR 读 ① 真实信号 → 粗粒度 tier 投影(observability) + 两条**独立真理**断言。          │
// │       挂 SIM_TOP_SRCS, DCE 零面积; ① 电路一行不动。                                          │
// │ ★与组合 Mux checker 的关键区别: 本仲裁器是**时序件**(next_fetch_pc_q 打拍、later-wins),      │
// │   INV-S2 须【延迟一拍比较】——当拍仲裁条件决定下一拍 reg 值; 同拍读 next_fetch_pc_q 是旧值     │
// │   (Moore/Mealy 陷阱)。做法: 把条件+target 各寄一拍, 与 next_fetch_pc_q 同延迟对齐后比。       │
// │ 断言均是核内自带 INV-2(:280-294, 只查 onehot0)**未覆盖**的独立真理。rst 高有效。             │
// └──────────────────────────────────────────────────────────────────────────────────────────┘
`include "define.v"
`include "common/OooRedirectSeqFacts.vh"

module OooRedirectSeqChecker (
  input wire clk,
  input wire rst,                                 // 高有效

  // ── ① Seq 真实信号(经 NpcSimTop XMR 从 u_..u_frontend.u_fetch_pc_outstanding.* 连入)──
  input wire csr_trap_mem_valid_i,                // Seq:16 / :271 最后写(全局最高)
  input wire [`XLEN-1:0] csr_trap_target_i,       // Seq:17
  input wire direct_frontend_flush_i,             // Seq:20
  input wire branch_resolve_untracked_i,          // Seq:46
  input wire core_branch_resolve_misaligned_i,    // Seq:33
  input wire pending_jump_resolve_ready_i,        // Seq:48 (OooFrontend:1311 tie-0, reserved 死态)
  input wire [`XLEN-1:0] next_fetch_pc_q          // Seq:83 内部 reg(later-wins 打拍结果)
);

  // ── ② 粗粒度 tier 投影(observability; 只显式两个高优先 override 档, 细见 §4.1 B / Seq facts)──
  wire over_flush_w = !csr_trap_mem_valid_i && direct_frontend_flush_i &&
                      branch_resolve_untracked_i && !core_branch_resolve_misaligned_i;  // Seq:263
  wire [`OOO_RDSEQ_FACTS_W-1:0] facts_w;
  assign facts_w[`OOO_RDSEQ_CSR_TRAP]              = csr_trap_mem_valid_i;
  assign facts_w[`OOO_RDSEQ_UNTRACKED_OVER_FLUSH]  = over_flush_w;
  assign facts_w[`OOO_RDSEQ_OTHER]                 = !csr_trap_mem_valid_i && !over_flush_w;
  // observability sink(波形可观测; 房规 _unused_ 惯例避免 lint)。
  wire _unused_facts_w = |facts_w;

`ifdef OOO_ASSERT
  // ── INV-S1 (reserved 死态, Seq 路): pending_jump_resolve_ready 恒 0(OooFrontend:1311 tie-0,
  //    死硅块 :1305-1319)。复活即 Seq:188 死臂活化 → 前端重定向契约违约。纯组合、无打拍。──
  always @(posedge clk) begin
    if (!rst && pending_jump_resolve_ready_i) begin
      $error("[RDSEQ-DEAD] OooFetchPcOutstandingSequencer reserved pending_jump_resolve_ready 死态复活(OooFrontend:1311 tie-0 被破坏) @%0t",
             $time);
      $fatal;
    end
  end

  // ── INV-S2 (CSR_TRAP 全局最高优先, flush 契约 trap>一切): csr_trap_mem_valid 命中(Seq:271 最后写、
  //    无条件覆盖)⟹ 结果拍 next_fetch_pc_q == csr_trap_target。★时序件延迟对齐: seen_q 与 next_fetch_pc_q
  //    都是「上拍决定」的一拍延迟反映, 同拍比较即对齐(避免同拍读 reg 旧值的 Moore/Mealy 错)。──
  reg csr_trap_seen_q;
  reg [`XLEN-1:0] csr_trap_target_seen_q;
  always @(posedge clk) begin
    if (rst) begin
      csr_trap_seen_q        <= 1'b0;
      csr_trap_target_seen_q <= {`XLEN{1'b0}};
    end else begin
      csr_trap_seen_q        <= csr_trap_mem_valid_i;
      csr_trap_target_seen_q <= csr_trap_target_i;
    end
  end
  // 非真空已验(2026-07-06): csr_trap_mem_valid 是 mem 阶段 trap(page/access fault, 区别于
  // exec 阶段 csr_trap_ex); rv64mi/csr/illegal 不触发, 但 sv39-xpage-misalign 触发 1 次、
  // 延迟比较对齐、INV-S2 成立(真实断言静默)。故 INV-S2 是 mem-fault 类的 tripwire, 非常开 guard。
  always @(posedge clk) begin
    if (!rst && csr_trap_seen_q && (next_fetch_pc_q !== csr_trap_target_seen_q)) begin
      $error("[RDSEQ-CSRTRAP-PC] CSR_TRAP 全局最高优先不变量破坏: 上拍 csr_trap 命中但 next_fetch_pc_q=%h != csr_trap_target=%h @%0t",
             next_fetch_pc_q, csr_trap_target_seen_q, $time);
      $fatal;
    end
  end
`endif

endmodule
