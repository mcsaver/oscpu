`ifndef __NPC_RV64_OOO_REDIRECT_SEQ_FACTS_VH__
`define __NPC_RV64_OOO_REDIRECT_SEQ_FACTS_VH__

// ┌─ OoO 前端「取指重定向」时序汇合点 OooFetchPcOutstandingSequencer 的抽象状态映射 ──────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型的 ③ 层。redirect 汇合点之(B)。   │
// │ 【P4 切消费点(2026-07-09)】redirect PC 真源 = OooRedirectArbiter(年龄律, OooFrontend 内);   │
// │ Sequencer 的 E1/E3/E4/E5/E6 六处 PC 写已删、换 always 块末尾唯一 arb 终写。本表投影的      │
// │ 是「当拍哪类事件决定了下一拍 next_fetch_pc_q」——CSR_TRAP/UNTRACKED_OVER_FLUSH 两档如今     │
// │ 物理上都经 arb 终写落盘(pre-mux E1 最高档 / branch 口年龄胜 direct), 观测语义不变。        │
// │ ⚠ 与组合 Mux(§OooRedirectMuxFacts.vh)不同: 本汇合点是**时序件**(打拍、下一拍生效),          │
// │    checker 断言须【延迟一拍比较】(Moore/Mealy)。                                             │
// │ ⚠ 本表是**粗粒度投影**(只显式两个高优先档 + OTHER 合并), 细粒度臂表见 spec §4.1(B)。        │
// └──────────────────────────────────────────────────────────────────────────────────────────┘

`define OOO_RDSEQ_CSR_TRAP              0  // E1 csr_trap_mem_valid — pre-mux 最高档+age0 恒胜(P4 经 arb 终写)
`define OOO_RDSEQ_UNTRACKED_OVER_FLUSH  1  // E3 flush&untracked&!misaligned — 年龄律 branch 胜 direct(P4 经 arb 终写)
`define OOO_RDSEQ_OTHER                 2  // 保留臂(E7/E8/E9)/E4-E6 记账拍/顺序 base(粗合并; 细见 §4.1 B)
`define OOO_RDSEQ_FACTS_W               3

`endif
