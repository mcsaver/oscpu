# Dispatch Log

## 2026-05-29

- 任务：补齐 ALU-only OoO lane0 `JAL/JALR` 精确屏障。
- 初始分析：直接在前端合成 jump commit 会绕过 rename map/PRF，后续消费者会读到 stale physical register；因此选择 jump 作为真实后端 uop 提交，前端只负责精确停顿、target 计算和提交后 redirect。
- 风险点：`JALR rd==rs1` target 必须在 link 写回前锁存；lane1 控制流不能因 decode backend 放行而误进入后端。
- 实现结论：`OooIntBackend` 改用 `WBU`，`OooAluFetchCore` 加入 jump pending/dispatched 两阶段，lane1 branch/jal/jalr 由前端手动 unsupported 并禁止送入后端。
- 调试结论：`JALR rd==rs1` 初次失败为 target=0，根因是 `arch_gpr()` 函数隐式依赖 `core_debug_gprs_w` 未触发 Icarus 重算；将 GPR 总线作为显式函数参数后通过。
- 验证结论：OoO 11/11、全量模块 38/38、实验/default lint/build、raw jump/4096 ALU smoke、`cpu-tests add` 均 PASS；4096 ALU CPI 保持 `0.502`。
