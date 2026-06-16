# Dispatch Log

## 基本信息

- `task_id`: `2026-05-21-npc-bpu-bht12-profile`
- `task_slug`: `npc-bpu-bht12-profile`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-05-21 00:00] `analyze-result` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户提供复跑截图。
- `depends_on`: previous DCache 8KB task
- `inputs`: `cycles=394138841`、`CPI=1.297`、`dcache miss=944073`、`writeback=771224`。
- `action`: 对比 4KB 基线，判断 direct-mapped 容量翻倍无明显收益。
- `outputs`: 优化方向转向 BPU 扩表与 miss PC 画像。
- `evidence`: 用户截图。
- `handoff_to`: `implement-bpu`
- `next_step`: 修改 BPU 参数和统计事件。
- `notes`: DCache 后续应做 2-way/victim 或 burst，不再盲目扩容量。

### [2026-05-21 00:00] `implement-bpu` - `completed`

- `owner_agent`: `codex`
- `trigger`: 条件分支误预测仍约 428 万次。
- `depends_on`: `analyze-result`
- `inputs`: `NpcCore.v`、`NpcSimTop.sv`、`cpu-exec.cpp`
- `action`: `BPU_BHT_INDEX_W` 10 -> 12；`npc_bpu_resolve_event` 增加 PC；host 记录 branch mispredict top PC。
- `outputs`: 三个文件已修改。
- `evidence`: 静态搜索确认参数和函数签名/调用点一致。
- `handoff_to`: `verify-static`
- `next_step`: 静态检查。
- `notes`: BPU pipeline 已参数化，改动集中在顶层 localparam。

### [2026-05-21 00:00] `rollback-dcache-exp` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户复跑证明 8KB direct-mapped DCache 对 CoreMark cycles/CPI/miss/writeback 几乎无收益。
- `depends_on`: `analyze-result`
- `inputs`: `DCache.v`
- `action`: 将 DCache 容量参数恢复为 `LINE_COUNT=64`、`INDEX_BITS=6`，保留 `INDEX_STEP` 参数化和 load/store 统计。
- `outputs`: DCache 回到 4KB direct-mapped 基线。
- `evidence`: 用户截图中的 `dcache miss=944073`、`writeback=771224` 与 4KB 基线几乎一致。
- `handoff_to`: `verify-static`
- `next_step`: 静态检查。
- `notes`: DCache 后续转向 2-way/victim cache 或 miss-side burst，不再继续单纯扩容量。

### [2026-05-21 00:00] `verify-static` - `completed`

- `owner_agent`: `codex`
- `trigger`: 修改后检查。
- `depends_on`: `implement-bpu`
- `inputs`: 已改文件。
- `action`: 执行 `git diff --check -- npc/single/vsrc/DCache.v npc/single/vsrc/NpcCore.v npc/single/vsrc/NpcSimTop.sv npc/single/csrc/cpu/cpu-exec.cpp ...`。
- `outputs`: 无空白错误或冲突标记。
- `evidence`: 命令仅输出 LF/CRLF 提示。
- `handoff_to`: `env-verify`
- `next_step`: 真实 lint/build。
- `notes`: 静态检查不能替代 Verilator lint。

### [2026-05-21 00:00] `env-verify` - `blocked`

- `owner_agent`: `codex`
- `trigger`: 需要真实构建验证。
- `depends_on`: `verify-static`
- `inputs`: 当前 Codex PowerShell 环境。
- `action`: 复用前一轮环境检查结论。
- `outputs`: `make`/`verilator` 不可用，WSL Ubuntu 不可见。
- `evidence`: 本次对话已有终端输出。
- `handoff_to`: user/local WSL
- `next_step`: 用户本地复跑 lint/build/CoreMark。
- `notes`: 验证缺口已写入 task-report。

### [2026-05-21 00:00] `record` - `completed`

- `owner_agent`: `codex`
- `trigger`: 收尾记录。
- `depends_on`: `env-verify`
- `inputs`: 本轮改动和阻塞点。
- `action`: 更新 project-status、NPC memory 和 task-runs。
- `outputs`: 记录落盘。
- `evidence`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`、本目录。
- `handoff_to`: none
- `next_step`: 等待下一轮 benchmark 数据。
- `notes`: top miss PC 会决定下一步 BPU 结构。
