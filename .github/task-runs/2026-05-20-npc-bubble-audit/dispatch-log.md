# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-bubble-audit`
- `task_slug`: `npc-bubble-audit`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-20] `recall` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求逐模块分析并减少不必要空泡。
- `depends_on`: none
- `inputs`: `.github/AGENTS.md`, `.github/copilot-instructions.md`, `.github/memory/project-status.md`, `.github/memory/known-issues.md`, `.github/memory/modules/npc.md`, `npc/single/design/study/README.md`, `RV32I-ai-notes.md`, `RV32I-implementation-checklist.md`
- `action`: 读取项目约束和 NPC 当前状态。
- `outputs`: 当前已具备流水线、RTL I/D cache、BPU、difftest 闭环；分析类任务不直接改 RTL。
- `evidence`: 读取文件完成。
- `handoff_to`: `static-audit`
- `next_step`: 审查 IF/ID/EX/MEM 相关模块。
- `notes`: RTL 修改若发生需补四段式推导。

### [2026-05-20] `static-audit` - `completed`

- `owner_agent`: `codex`
- `trigger`: `recall` 完成。
- `depends_on`: `recall`
- `inputs`: `BranchPredictor.v`, `IfStage.v`, `PipelineControl.v`, `MemoryStageControl.v`, `LSUControl.v`, `LSUDataPath.v`, `DCache.v`, `ICache.v`, `CompareUnit.v`, `NpcCore.v`
- `action`: 按模块标注空泡来源。
- `outputs`: DCache hit/MemoryStage 同拍响应/store write-through/BPU RAS 与缺计数器是主要后续方向。
- `evidence`: 源码静态审查。
- `handoff_to`: `verify-sample`
- `next_step`: 跑短 difftest 样本确认当前基线。
- `notes`: `LSUControl/LSUDataPath/CompareUnit` 本身为组合模块，不是直接 bubble 来源。

### [2026-05-20] `verify-sample` - `completed`

- `owner_agent`: `codex`
- `trigger`: `static-audit` 完成。
- `depends_on`: `static-audit`
- `inputs`: `make -C npc/single lint`, `cpu-tests add/load-store/if-else/switch`
- `action`: 执行 lint 与短回归。
- `outputs`: 当前基线全部 PASS。
- `evidence`: `add CPI=2.136`, `load-store CPI=2.811`, `if-else CPI=2.620`, `switch CPI=2.835`。
- `handoff_to`: none
- `next_step`: 后续若落 RTL，先补计数器或直接推进 DCache hit 同拍响应。
- `notes`: 本轮未修改 RTL。
