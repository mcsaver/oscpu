# 调度日志

## 节点

- `recall`
  - 输入：`.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`、RTL 工作流、NPC study 笔记。
  - 输出：确认本轮需要按 RTL 四段式推导并更新 task-runs/memory。

- `inspect-memory-path`
  - 输入：`LSU.v`、`MemoryStage.v`、`NpcCore.v`、`DCache.v`、`Makefile`。
  - 输出：确认当前主要混合点是 LSU lane 控制与数据搬移、MemoryStage pending 控制与 LSU 数据路径。

- `split-lsu`
  - 输入：旧 `LSU.v` 组合逻辑。
  - 输出：新增 `LSUControl.v`、`LSUDataPath.v`，`LSU.v` 保留外部接口并实例化两个子模块。

- `split-memory-stage-control`
  - 输入：旧 `MemoryStage.v` pending/response 逻辑。
  - 输出：新增 `MemoryStageControl.v`，`MemoryStage.v` 保留数据接线和外部接口。

- `verify`
  - 输入：修改后的 RTL 与 Makefile。
  - 输出：lint/build/add/load-store difftest 均通过；并记录 cpu-tests 并行 `.result` 竞态。

- `record`
  - 输入：最终变更与验证结果。
  - 输出：更新本任务记录与 `.github/memory/`。
