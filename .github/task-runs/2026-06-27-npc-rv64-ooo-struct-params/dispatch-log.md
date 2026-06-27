# 派发日志

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-struct-params`
- `task_slug`: `npc-rv64-ooo-struct-params`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-06-27 12:58] `recall-current-boundary` - `completed`

- `owner_agent`: Codex
- `trigger`: 用户要求完成 OoO RTL 优化。
- `depends_on`: 无
- `inputs`: `.github/AGENTS.md`、`.github/copilot-instructions.md`、memory、`npc/rv64/README.md`、`vsrc/README.md`
- `action`: 对齐当前已完成的 fetch/pending 拆分历史，选择第 0 步结构参数统一作为本轮最小闭环。
- `outputs`: 参数链扫描目标。
- `evidence`: `rg` 定位 `NpcCoreTop`、`OooAluFetchCore`、`OooIntBackend`、`OooDispatchBackend`、`OooRob`、`OooFreeList`、`OooIntIssueQueue`、`OooPhysRegFile` 等默认参数。
- `handoff_to`: 无
- `next_step`: 落 RTL 参数宏。
- `notes`: 工作树已有大量既有未提交改动，本轮只基于当前文件继续补丁，不回退用户改动。

### [2026-06-27 12:58] `unify-struct-params` - `completed`

- `owner_agent`: Codex
- `trigger`: 参数链存在 magic number 与顶层端口宽度硬编码。
- `depends_on`: `recall-current-boundary`
- `inputs`: OoO 参数链 RTL。
- `action`: 在 `define.v` 新增 OoO 结构宏；更新顶层计数端口和相关模块默认参数；删除 `NpcCoreTop` 重复 `localparam`。
- `outputs`: 统一结构参数 RTL 切片。
- `evidence`: vsrc 残留扫描未发现同类默认参数硬编码。
- `handoff_to`: 无
- `next_step`: focused 验证。
- `notes`: 未改变容量数值、时序和 ready/valid 行为。

### [2026-06-27 12:58] `verify-focused` - `completed`

- `owner_agent`: Codex
- `trigger`: RTL 参数化重构完成。
- `depends_on`: `unify-struct-params`
- `inputs`: 修改后的 RTL。
- `action`: 运行 OoO 参数链 focused testbench、lint 和默认构建。
- `outputs`: 验证证据。
- `evidence`: focused 9/9 PASS，`make -C npc/rv64 lint` PASS，`make -C npc/rv64 -j2` PASS。
- `handoff_to`: 无
- `next_step`: 写 memory 与最终回复。
- `notes`: 本轮不宣称整条优化路线完成。

