# 任务报告

- `task_id`: 2026-07-11-rv64-200mhz-program
- `profile`: manual-architecture-planning
- `status`: in_progress_f0_complete
- `rtl_changed`: true
- `goal_complete`: false

## Result

完成 current functional/timing baseline 的独立只读审计、总体设计与 F0 实施。设计保持
原始目标：功能完整与最终物理 200 MHz 必须同时闭合；pre-layout 5 ns 只是阶段 gate。

F0 已于 2026-07-11 闭合。三个 module TB 属于接线/期望漂移；AM 的 FP 反例来自
`OooFpBackend` 将 GPR 目的 FP completion 未经 destination-domain 资格就用于 FP busy clear、
source bypass 与 wakeup，整数/FPR preg 数字别名导致 FSQRT 消费者提前读取陈旧 FPR。修复后
module 86/86、AM 59/59（Difftest ON）、official 177/177、lint/build/contract 与 strict guard
全部使用真实 rc 通过；详细证据见子任务 `2026-07-11-rv64-f0-truthful-regression`。

## Next gate

进入 T0 可复现 5 ns flow 与 T1 frontend pipeline，同时继续 F1 正确性合同。每个后续 RTL
slice 都必须回跑 F0 gate。F2/F3 与 T-PRE/T-PHYS 尚未闭合，因此仍不声明整体目标完成。
