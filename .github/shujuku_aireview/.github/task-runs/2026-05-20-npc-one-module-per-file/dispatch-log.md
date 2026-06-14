# 调度日志

## 节点

- `recall`
  - 输入：`.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、RTL 生成约束。
  - 输出：确认本轮为 RTL 源文件组织拆分，需要记录四段式推导与验证证据。

- `inspect-cache-source`
  - 输入：`npc/single/vsrc/IDCache.v`、`npc/single/Makefile`。
  - 输出：确认旧文件只包含 `ICache` 和 `DCache` 两个顶层 module，构建清单只需要替换源文件路径。

- `inspect-remaining-multimodule`
  - 输入：`npc/single/vsrc/*.v`、`npc/single/vsrc/*.sv`。
  - 输出：确认 `PipelineRegs.v` 仍聚合 4 个流水线寄存器 module，需要同样拆分。

- `split-files`
  - 输入：旧 `IDCache.v` 内容。
  - 输出：新增 `ICache.v`、`DCache.v`，删除 `IDCache.v`，更新 `RTL_CORE_SRCS`。

- `split-pipeline-regs`
  - 输入：旧 `PipelineRegs.v` 内容。
  - 输出：新增 `IfIdPipeReg.v`、`IdExPipeReg.v`、`ExMemPipeReg.v`、`MemWbPipeReg.v`，删除 `PipelineRegs.v`，更新 `RTL_CORE_SRCS`。

- `verify`
  - 输入：修改后的 RTL 与 Makefile。
  - 输出：静态多 module 扫描清零，lint/build/fence-i/load-store difftest 均通过。

- `record`
  - 输入：最终变更与验证结果。
  - 输出：更新本任务记录与 `.github/memory/`。
