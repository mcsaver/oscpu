`ifndef __NPC_RV64_OOO_REDIRECT_SEQ_FACTS_VH__
`define __NPC_RV64_OOO_REDIRECT_SEQ_FACTS_VH__

// ┌─ OoO 前端「取指重定向」时序仲裁器 OooFetchPcOutstandingSequencer 的抽象状态映射 ──────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型的 ③ 层。redirect 双仲裁器之(B)。 │
// │ 真源: next_fetch_pc_q(:93-278) 的 later-wins(文本后写覆盖)优先级。**权威全档表见 spec §4.1(B)**。│
// │ ⚠ 与组合 Mux(§OooRedirectMuxFacts.vh)不同: 本仲裁器是**时序件**(打拍、下一拍生效),           │
// │    观测的是「当拍哪个 override 臂决定了下一拍 next_fetch_pc_q」——仲裁条件仍是无记忆组合,       │
// │    但结果打拍 → checker 断言须【延迟一拍比较】(Moore/Mealy)。                                 │
// │ ⚠ 本表是**粗粒度投影**(只显式两个高优先 override 档 + OTHER 合并), 细粒度 else-if 链各臂       │
// │    (PENDING_BRANCH/UNTRACKED/CSR_COMMIT/TRAP_EXIT/PENDING_MEM…)见 §4.1(B), 待需要时再细化。   │
// └──────────────────────────────────────────────────────────────────────────────────────────┘

`define OOO_RDSEQ_CSR_TRAP              0  // :271 csr_trap_mem_valid — later-wins 全局最高(最后写)
`define OOO_RDSEQ_UNTRACKED_OVER_FLUSH  1  // :263 flush&untracked&!misaligned — 覆盖 else-if 链的高档
`define OOO_RDSEQ_OTHER                 2  // else-if 链 / branch_spec / DIRECT 组 / 顺序 base(粗合并; 细见 §4.1 B)
`define OOO_RDSEQ_FACTS_W               3

`endif
