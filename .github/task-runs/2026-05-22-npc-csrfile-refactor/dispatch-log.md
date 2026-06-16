# Dispatch Log

- 2026-05-22: 读取工程约束、NPC 模块记忆和 RTL 工作流说明，确认该任务属于跨模块 RTL 重构，需要先给出派生边界再改文件。
- 2026-05-22: 推导 CSR 抽离方案：`NpcCore` 保留流水线控制与异常事件，`CsrFile` 接管 CSR 状态、CSR 指令语义和 trap/MRET CSR side effect。
- 2026-05-22: 新增 `CsrFile.v` 并修改 `NpcCore.v`，把 CSR 读写路径和 trap target/mepc 输出接回核心。
- 2026-05-22: 同步 Makefile/testbench 源列表，先跑模块回归，再修正 Verilator unused-bit lint。
- 2026-05-22: 完成 `testbench run`、`lint`、`build` 和全量 `cpu-tests` 验证，结果均通过。
