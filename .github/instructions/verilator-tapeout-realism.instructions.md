---
description: "Verilator 真实性能仿真与后续流片约束。处理 npc/rv64 性能仿真、Linux 长跑、设备模型、cache/LSQ/AXI 优化或可综合边界时使用。"
applyTo: "npc/rv64/**"
---

# Verilator 真实性能仿真与流片约束

## 当前阶段选择

近期主线是 **Verilator**，暂不使用 Vivado 作为功能 bring-up 前置。Vivado/FPGA 只能作为后续硬件原型或 PPA 下游节点，不应替代当前 Linux/Ubuntu 功能闭环。

## 仿真真实度原则

- core 内部必须走真实的 ready/valid、AXI、cache、LSQ、CSR、trap 和中断路径。
- DPI/host C++ 可以作为仿真平台外设或内存后端，但必须标注为 simulation-only。
- 不允许为跑快而在 core 内部加入不可综合后门或直接修改 guest 架构状态。
- 性能统计必须区分 guest cycles、guest commits、host time、CPI、设备等待、cache/mem wait。
- 长跑 Linux/Ubuntu 时优先用日志、progress、hang probe 的显式开关收集证据，不让调试输出污染默认性能路径。

## 后续流片水准要求

任何准备长期保留的 RTL 改动都需要：

1. 清楚的模块边界和一个 module 一个源文件。
2. RTL 四段式推导：需求、协议/状态机/不变量、数据通路、RTL。
3. module testbench 或 focused smoke。
4. 全量或代表性回归证据。
5. 可综合边界说明：哪些代码进入 core，哪些只属于 Verilator sim top。
6. PPA/STA 下游风险记录，至少不能明显制造不可收敛组合环或不可综合结构。

## 性能优化约束

触碰 CPI、cache、BPU、LSQ、issue/commit、AXI outstanding 等路径时，必须叠加 `.github/instructions/npc-optimization-workflow.instructions.md`。不能只用 `add` 或单个 Linux smoke 证明优化有效。
