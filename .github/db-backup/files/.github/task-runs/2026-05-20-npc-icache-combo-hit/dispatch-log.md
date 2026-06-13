# Dispatch Log

## 基本信息

- `task_id`: `2026-05-20-npc-icache-combo-hit`
- `task_slug`: `npc-icache-combo-hit`
- `graph_template`: `custom`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-20] `inspect-icache` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求分析 ICache hit 路径，并说明 hit 应组合送出。
- `depends_on`: 无
- `inputs`: `npc/single/vsrc/ICache.v`、`npc/single/vsrc/IfStage.v`
- `action`: 静态阅读 ICache 状态机与 IfStage response 接收门控。
- `outputs`: 发现旧路径 hit 仍需 `S_IDLE -> S_LOOKUP -> S_RESP`，且 IfStage 只在 `fetch_pending_q` 为 1 时接收 response。
- `evidence`: 后续 RTL 修改围绕同拍 response 接收展开。
- `handoff_to`: `rtl-edit`
- `next_step`: 修改 ICache/IfStage。
- `notes`: 同拍 hit 返回必须同步改前端，否则会丢 response。

### [2026-05-20] `rtl-edit` - `completed`

- `owner_agent`: `codex`
- `trigger`: 用户要求 miss/fall 路径下一个周期立刻在 RAM 中找数据。
- `depends_on`: `inspect-icache`
- `inputs`: 现有 CPU-side 与 memory-side ready/valid 协议。
- `action`: `ICache.v` 新增当前请求组合 hit/data 网络，`S_IDLE` hit 组合响应、miss 直接准备 fill 并进入 `S_FILL_REQ`；`IfStage.v` 支持同拍 request/response。
- `outputs`: `npc/single/vsrc/ICache.v`、`npc/single/vsrc/IfStage.v`
- `evidence`: `git diff` 可见。
- `handoff_to`: `verify`
- `next_step`: lint/build/difftest/性能样本。
- `notes`: 保留 fill 完成后的 `S_LOOKUP`，用于跨 line 或补齐后的复查响应。

### [2026-05-20] `verify` - `completed`

- `owner_agent`: `codex`
- `trigger`: RTL 修改完成。
- `depends_on`: `rtl-edit`
- `inputs`: 修改后的 NPC RTL。
- `action`: 运行 lint、构建、定向 cpu-tests difftest，以及 `demo mainargs=8` 20M cycles 样本。
- `outputs`: PASS 结果和性能对比。
- `evidence`: `lint/build` PASS；`add/fence-i/load-store` PASS；`mainargs=8` 改后 `commits=6803429/CPI=2.940`。
- `handoff_to`: `memory-update`
- `next_step`: 更新 memory/task-run。
- `notes`: 一次并行 cpu-tests 因同目录 `.result` 竞争导致 make exit 2，顺序重跑目标测试均 PASS。

### [2026-05-20] `memory-update` - `completed`

- `owner_agent`: `codex`
- `trigger`: AGENTS 要求完成后更新 project/module memory 和 task-run。
- `depends_on`: `verify`
- `inputs`: 修改摘要、验证摘要、性能样本。
- `action`: 更新 `.github/memory/project-status.md`、`.github/memory/modules/npc.md`，新增本目录 `task-report.md` 与 `dispatch-log.md`。
- `outputs`: 文档记录完成。
- `evidence`: 本文件和 `task-report.md`。
- `handoff_to`: 无
- `next_step`: 最终回复用户。
- `notes`: 无。
