// ┌─ OoO 前端「取指重定向」两仲裁器合并视图 checker(跨 Mux/Seq 一致性) ──────────────────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型 ② 层 / redirect 双仲裁器"合并视图"。 │
// │ 作用: 同时 XMR 组合 Mux(OooFetchRequestMux)与时序 Seq(OooFetchPcOutstandingSequencer)两个     │
// │       仲裁器, 断言二者对 untracked 的**跨仲裁器一致性契约**(§4.1 Seq:262 注释声称"两器一致",     │
// │       本 checker 把该注释从散文变成运行时断言)。挂 SIM_TOP_SRCS, DCE 零面积; ① 电路一行不动。   │
// │ ★这是任一单仲裁器 checker(Mux/Seq)覆盖不到的**跨仲裁器**独立真理。rst 高有效。                 │
// └──────────────────────────────────────────────────────────────────────────────────────────┘
`include "define.v"

module OooRedirectMergeChecker (
  input wire clk,
  input wire rst,                                  // 高有效

  // ── 组合 Mux(OooFetchRequestMux)侧 ──
  input wire mux_untracked_redirect_i,             // Mux branch_resolve_untracked_redirect_i(:70 select)
  input wire [`XLEN-1:0] mux_redirect_fetch_pc_i,  // Mux redirect_fetch_pc_o(:66-82 输出)
  // ── 时序 Seq(OooFetchPcOutstandingSequencer)侧 ──
  input wire seq_direct_frontend_flush_i,          // Seq direct_frontend_flush_i(:263 guard)
  input wire seq_csr_trap_mem_valid_i,             // Seq csr_trap_mem_valid_i(:271 override, 须排除)
  input wire [`XLEN-1:0] seq_next_fetch_pc_q        // Seq next_fetch_pc_q(:83 reg, later-wins 打拍结果)
);

`ifdef OOO_ASSERT
  // ── INV-M1 (跨仲裁器 untracked 一致性, §4.1 Seq:262 契约): 当 flush && untracked_redirect && !csr_trap
  //    (即 Seq:263 胜出、未被 :271 csr_trap 覆盖)时, 组合 Mux 当拍 redirect_fetch_pc 必与时序 Seq 下一拍
  //    next_fetch_pc_q 一致(都 = core_branch_resolve_next_pc)。契约来源: OooFetchPcOutstandingSequencer.v
  //    :262 注释"fetch_req(Mux)已优先 untracked, 此处令 sequential next_fetch_pc 一致"——防 B2 wrong-path
  //    的 direct flush 盖掉 jr/jalr 真 target(否则续取 stale → load fault → CoreMark 卡死)。
  //    ★两器时序错位(Mux 纯组合当拍 / Seq nonblocking 打拍)由【延迟一拍比较】对齐: cond 与 mux_pc 各寄
  //    一拍, 与 Seq 的 reg 延迟同步后比。untracked_redirect = untracked && !misaligned(RecoveryGate:104)。──
  reg cond_seen_q;
  reg [`XLEN-1:0] mux_pc_seen_q;
  always @(posedge clk) begin
    if (rst) begin
      cond_seen_q   <= 1'b0;
      mux_pc_seen_q <= {`XLEN{1'b0}};
    end else begin
      cond_seen_q   <= seq_direct_frontend_flush_i && mux_untracked_redirect_i &&
                       !seq_csr_trap_mem_valid_i;
      mux_pc_seen_q <= mux_redirect_fetch_pc_i;
    end
  end
  // 非真空已验(2026-07-06): CoreMark 上 untracked-over-flush 前件可达 1417 次、两器目标 1417/1417 全一致
  // (真实断言静默)——Seq:262 注释声称的"两器一致"从散文变成运行时验证的事实。
  always @(posedge clk) begin
    if (!rst && cond_seen_q && (seq_next_fetch_pc_q !== mux_pc_seen_q)) begin
      $error("[RDMERGE-UNTRACKED] 两仲裁器 untracked 目标不一致(§4.1 Seq:262 契约破坏): Mux 当拍 redirect_fetch_pc=%h != Seq 下拍 next_fetch_pc_q=%h @%0t",
             mux_pc_seen_q, seq_next_fetch_pc_q, $time);
      $fatal;
    end
  end
`endif

endmodule
