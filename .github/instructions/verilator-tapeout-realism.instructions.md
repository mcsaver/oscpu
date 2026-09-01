---
description: "显式 Verilator/tapeout/synthesizability 或正式 PPA 边界的真实性约束；不作为普通 RTL/testbench 修改的固定流程。"
applyTo: "npc/rv64/syn/**,yosys-sta/**"
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

当 acceptance criteria 包含 tapeout、可综合交付、正式 PPA 或长期 Verilator 系统行为时，按受影响范围确认：

1. 清楚的模块边界和一个 module 一个源文件。
2. 真实协议/状态机/owner/transaction lifecycle 与必须保持的不变量。
3. 能直接覆盖改动的 module testbench、assertion 或 focused smoke。
4. 与交付 claim 和风险相称的代表性回归；局部改动不机械升级为全量 signoff。
5. 可综合边界说明：哪些代码进入 core，哪些只属于 Verilator sim top。
6. 只有声称 physical/PPA 结果时才补齐同源综合/STA/PPA；任何改动都不得制造组合环或不可综合结构。

## 性能优化约束

触碰 CPI、cache、BPU、LSQ、issue/commit、AXI outstanding 等路径时，按
`.github/instructions/npc-optimization-workflow.instructions.md` 区分 focused 迭代与全局结论；局部实验不必
先跑完整 signoff。准备作出 `npc/rv64` Pareto/champion/promotion 结论时，再读取完整 PPA contract 并闭合
同源 correctness、综合、STA/PPA hard gates。不能用 `add`、单个 Linux smoke 或 vectorless/macro=0 proxy
证明全局优化有效。
