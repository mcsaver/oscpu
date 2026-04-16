# Yosys-STA 模块笔记

## 综合结果历史
<!-- 面积、时序、功耗数据 -->
- 2026-04-14: `npc/single` 的 `NpcCore` 已通过 `yosys-sta` 接入 `icsprout55`，约束为 `clk @ 500MHz`。结果目录：`npc/single/build/sta/NpcCore-500MHz/`。
- 2026-04-14: `NpcCore` 映射后标准单元数约 `7100`，面积约 `21437.92`，功耗报告总功耗约 `2.035e-01 W`。
- 2026-04-14: `NpcCore.rpt` 显示 `core_clock` 的 `max/min TNS` 均为 `0.000`，最差 setup slack 约 `0.963ns`，报告中按 slack 反推的等效频率约 `964.459MHz`。

## 关键路径分析
<!-- 瓶颈模块和优化方向 -->
- 2026-04-14: 当前最差 setup 路径延迟约 `0.991ns`，报告里的主要观察点集中在 `load_data_q/next_pc_q/trap_pc_o/debug_gprs_o` 一带，说明现阶段瓶颈更多来自核心内部寄存器到寄存器的数据通路，而不是顶层 IO 约束。
- 2026-04-14: 当前时序路径里 cell delay 几乎占满全部延迟，net delay 接近 `0`；这更像是“综合后、未布局布线”的逻辑级 STA 特征，后续若接物理实现，净延迟和时钟树影响会重新改变路径排名。

## 踩坑记录
<!-- 本模块特有的问题和经验 -->
- 2026-04-14: 把 `npc/single` 的 RTL 直接喂给 `yosys-sta` 时，不应该把 `NpcSimTop.sv` 混进去；它含有 `import "DPI-C"` 的宿主桥接任务，只适合 Verilator 仿真。当前应把综合对象收敛为 `NpcCore` 及其纯 RTL 子模块。
- 2026-04-14: `WNS/TNS` 过关不代表报告全清；本轮 `NpcCore` 在 500MHz 下时序满足，但 `NpcCore.cap` 仍出现 `ICGX0P5H7L/ECK` 最大电容违规，因此做综合复盘时必须同时看 `synth_check.txt`、`NpcCore.rpt` 和 `NpcCore.cap/trans/fanout`。
