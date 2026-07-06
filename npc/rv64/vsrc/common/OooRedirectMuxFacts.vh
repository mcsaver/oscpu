`ifndef __NPC_RV64_OOO_REDIRECT_MUX_FACTS_VH__
`define __NPC_RV64_OOO_REDIRECT_MUX_FACTS_VH__

// ┌─ OoO 前端「取指重定向」组合仲裁器 OooFetchRequestMux 的抽象状态映射 ──────────────────────┐
// │ 归属: ooo-debug-observability-architecture.md §5 三层模型的 ③ 层(外部抽象状态映射)。      │
// │ 用途: 面向人/debug 的外部观测层。语义部分综合不参与(仅 SIM_TOP_SRCS 的 checker 引用它,     │
// │        checker 挂 SIM_TOP 侧、DCE 零面积)。① 层电路一行不动。                              │
// │ 真源: OooFetchRequestMux.v:66-82 的 redirect_fetch_pc_o 三元优先级链(纯组合、当拍 wire)。  │
// │ 位号 = first-match 优先级(0=最高)。one-hot: 投影出的「胜出档」至多一位为 1。               │
// │ ⚠ 这是 ① 层电路真实编码的抽象投影, 不规定电路物理编码(电路里是散 wire 三元链, 非 one-hot)。│
// │ ⚠ 本表校正了旧散文档(spec §4.1)把「组合 Mux + 时序 Seq 两个仲裁器」压成单链、且多处次序    │
// │    记反的失真: 本表只描述「组合 Mux」这一个仲裁器的真实档位, 时序 Seq 另表(未来)。         │
// └──────────────────────────────────────────────────────────────────────────────────────────┘

// ── 优先级档位(高→低, 逐档对位 OooFetchRequestMux.v:70→82) ──
`define OOO_RDMUX_UNTRACKED          0   // Mux:70 后端 mispredict 真 target(架构真值, 最高优先) [is_arch]
`define OOO_RDMUX_DIRECT_JUMP_SPEC   1   // Mux:71 非返回 JALR 投机续取
`define OOO_RDMUX_DIRECT_JAL         2   // Mux:72 direct JAL 投机续取
`define OOO_RDMUX_DIRECT_RET         3   // Mux:73 direct RET(ret0/ret1)投机续取
`define OOO_RDMUX_DIRECT_LANE1_RET   4   // Mux:74 lane1 ret(return_cont / ras_top)投机续取
`define OOO_RDMUX_BRANCH_TARGET      5   // Mux:76 branch 预测 taken 续取(BTB target)
`define OOO_RDMUX_BRANCH_FALLTHRU    6   // Mux:77 branch fall-through 续取
`define OOO_RDMUX_DIRECT_BR_RESOLVE  7   // Mux:78 direct branch resolve redirect
`define OOO_RDMUX_PENDING_JUMP       8   // Mux:79-80 ⚠reserved 死态(上游 tie-0 恒 0; 复活=GAP-3 违约暴露点)
`define OOO_RDMUX_BRANCH_SPEC        9   // Mux:81 legacy 投机 checkpoint restore(最低有效档)
`define OOO_RDMUX_NONE              10   // Mux:82/84-87 无重定向, 顺序取(兜底)
`define OOO_RDMUX_FACTS_W          11

// ── 派生语义(observability, 非断言依据; is_architectural 划分见 §5.7) ──
// is_architectural = 仅 UNTRACKED(后端解析真值); 其余为前端投机预测续取。
`define OOO_RDMUX_IS_ARCH_MASK   (1 << `OOO_RDMUX_UNTRACKED)
// reserved 死态 mask(② checker 对其原始条件断言恒 0)。
`define OOO_RDMUX_DEAD_MASK      (1 << `OOO_RDMUX_PENDING_JUMP)

`endif
