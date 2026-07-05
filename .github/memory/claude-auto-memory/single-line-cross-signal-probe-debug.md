---
name: single-line-cross-signal-probe-debug
description: RTL 调试——多轮分散探针无法定位时，改用「单行对照表」探针把一条数据通路上下游信号排同一时间轴
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f1fe0282-f035-4090-8cb2-559e132112ac
---

RTL 仿真调试定位 bug 时，**在加了几轮分散 `$display` 探针仍无法定位的情况下，改用「单行对照表」探针**：
把同一条数据通路（如 dispatch present 链、fetch redirect 链、wakeup 链）的**上下游信号排在同一时间轴的一行**
`$display`——valid/ready/fire + 上游 source + 下游 gate + 相关 state/count——在触发条件下逐拍打印（限量避免刷屏）。
这是 VCD 波形「同一时间轴对照」的**文本等价物**，且在纯 CLI 下可直接 grep/diff（图形波形看不了）。

**Why**：分散探针只能看单点，看不出上下游因果（到底谁=0 谁=1 导致卡死）；单行对照把因果排在一行，一眼定位。
用户 2026-06-30 明确提出此方法优于继续加分散探针。

**How to apply**：① 选定卡点的数据通路；② 列出该链的 valid/ready/fire + 上游产生信号 + 下游消费 gate + 相关
state/count；③ 用一个 `always @(posedge clk)` 在触发条件（如 `head 是目标指令类型 && !fire`）下打印**一行**，
带 `reg [N:0] cnt` 限量（如前 24 拍）防刷屏。**实测**：RV64 OoO mode=1 的 jalr dispatch 卡死，分散探针查了
ROB/IQ/CF/DISP 五轮没定位；换成一行 `[FE] hpc=.. jmp=1 ret=0 d0v=0 d0f=0 dfire=0 jdv=0 jspecS=0 canrun=1 fifo=1 ..`
**一行立刻定位**=前端没把 jalr present 给后端（`core_dispatch0_valid=0 && jump_dispatch_valid=0`，de-pend 遗漏 jalr
的 dispatch-present 路径）。相关：[[ooo-core-architecture-constitution]] [[rtl-coding-standard]]。
