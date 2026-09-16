`ifndef __NPC_RV64_OOO_REDIRECT_MUX_FACTS_VH__
`define __NPC_RV64_OOO_REDIRECT_MUX_FACTS_VH__

// ┌─ OoO 前端「取指重定向」组合汇合点 OooFetchRequestMux 的抽象状态映射 ──────────────────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型的 ③ 层(外部抽象状态映射)。      │
// │ 用途: 面向人/debug 的外部观测层。语义部分综合不参与(仅 SIM_TOP_SRCS 的 checker 引用它,     │
// │        checker 挂 SIM_TOP 侧、DCE 零面积)。① 层电路一行不动。                              │
// │ 【P4 切消费点(2026-07-09)】原 11 档 first-match 三元链(untracked>jump_spec>jal>ret>       │
// │ lane1_ret>branch_target>fallthru>direct_resolve>pending_jump>spec>NONE)已随单源化删除——   │
// │ redirect PC 真源 = OooRedirectArbiter(年龄律, OooFrontend 内), mux 只做「赢家透传 or       │
// │ core_branch_resolve_next_pc 兜底」二择。本表同步缩为 2 档投影。旧 11 档表见 git 史。        │
// └──────────────────────────────────────────────────────────────────────────────────────────┘

// ── 档位(对位 OooFetchRequestMux.v redirect_fetch_pc_o 二择) ──
`define OOO_RDMUX_ARB       0   // redirect_valid_i: OooRedirectArbiter 年龄律赢家 PC 透传
`define OOO_RDMUX_DEFAULT   1   // !redirect_valid_i: 兜底 core_branch_resolve_next_pc(E7/E9 保留臂拍)
`define OOO_RDMUX_FACTS_W   2

`endif
