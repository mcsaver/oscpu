# Task Report

## 基本信息

- `task_id`: `2026-05-21-npc-dcache-8kb-profile`
- `task_slug`: `npc-dcache-8kb-profile`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-21`
- `updated_at`: `2026-05-21`

## 任务目标

- `source_request`: 用户给出 benchmark 截图后要求“按照建议进行优化”。
- `goal`: 试验 DCache 容量对 miss/writeback 的影响，并补足 load/store 明细统计，为后续 BPU/cache 精准调参提供证据。
- `scope`: `npc/single/vsrc/DCache.v`、`npc/single/vsrc/NpcSimTop.sv`、`npc/single/csrc/cpu/cpu-exec.cpp` 与项目记忆。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 本任务是单模块 RTL 性能优化加仿真统计增强，不属于完整 reference-loop 或回归调试闭环。
- `dynamic_nodes_added`: `env-verify`
- `why_dynamic_nodes_were_needed`: 当前 Codex Windows 侧无法直接调用 WSL/Linux 构建工具，需单独记录验证环境阻塞。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| recall | codex | completed | AGENTS、copilot instructions、project-status、known-issues、npc memory、study README、RTL workflow | 选定 DCache 容量与统计增强为第一轮优化 | 已读取相关文件 |
| rtl-derive | codex | completed | benchmark 指标、DCache 当前 4KB direct-mapped 参数 | RTL 推导摘要 | 本文件“RTL 推导摘要” |
| implement | codex | completed | DCache/NpcSimTop/cpu-exec | DCache 8KB 容量试验、DCache load/store 统计 | 修改文件已落盘；后续 benchmark 证明容量试验无收益并已回滚 |
| verify-static | codex | completed | 已改文件 | 静态一致性检查 | `git diff --check -- npc/single/vsrc/DCache.v npc/single/vsrc/NpcSimTop.sv npc/single/csrc/cpu/cpu-exec.cpp` 仅 LF/CRLF 提示 |
| env-verify | codex | blocked | 当前 PowerShell 环境 | 记录真实构建阻塞 | `make`/`verilator` 未找到，`wsl.exe -l -v` 看不到 Ubuntu |
| record | codex | completed | 本轮结论 | project-status、npc memory、task-runs | 本文件与 memory 更新 |

## RTL 推导摘要

### 阶段 1 — 需求

- 功能目标：降低 benchmark 中 DCache `miss=944075`、`writeback=771238` 暴露出的 direct-mapped 脏行换出压力。
- 接口目标：保持 `DCache` 现有 CPU-side ready/valid、AXI-like miss-side、flush/invalidate 端口不变。
- 性能目标：优先用低风险容量翻倍减少冲突/容量 miss；不在本轮引入 2-way/victim cache 的替换策略复杂度。
- 边界：`NpcSimTop` 只扩展仿真事件 payload，不改变 `NpcCore` 端口 ABI。

### 阶段 2a — 协议规则

- CPU-side 命中协议不变：`S_IDLE` 下 cacheable hit 可组合返回 `cpu_rsp_valid_o`。
- miss-side 协议不变：fill/writeback 仍通过现有 AXI-like valid/ready 单 word 通道完成。
- flush 协议不变：`flush_i` 触发逐 index 扫描 dirty line，`flush_done_o` 在 `S_FLUSH_DONE` 拉高。
- 统计协议扩展：`npc_dcache_event` 新增 `is_store`，仅在 `access=1` 时区分 load/store；writeback 事件仍独立计数。

### 阶段 2b — 状态机

- `S_IDLE`: 接受 CPU 请求；命中原地响应，miss 进入 `S_LOOKUP`。
- `S_LOOKUP`: 判断 hit/dirty victim，选择 `S_RESP`、`S_WB_AW` 或 `S_FILL_AR`。
- `S_WB_AW/S_WB_B`: 逐 word 写回 dirty victim，完成后 fill 或响应。
- `S_FILL_AR/S_FILL_R`: 逐 word refill line，完成后进入 `S_LOOKUP` 或 store allocate update。
- `S_FLUSH_SCAN/S_FLUSH_WB_*`: 用参数化 index 步进覆盖全部 cache line。

### 阶段 2c — 不变量

- 任意 cache line 仍只有一组 valid/tag/dirty/data 元数据。
- `flush_index_q` 的宽度必须等于 `INDEX_BITS`，扫描范围必须覆盖 `0 .. LINE_COUNT-1`。
- 容量变化不得改变 line offset 与 word offset：仍为 64B line、16 个 32-bit word。
- 统计 split 不影响架构行为；`is_store` 只由当前 CPU-side 写请求派生。

### 阶段 2d — 数据通路约束

- 本轮试验曾将 `LINE_COUNT` 从 64 改为 128，`INDEX_BITS` 从 6 改为 7。
- 后续用户复跑证明 `cycles/CPI/dcache miss/writeback` 几乎不变，容量参数已回滚为 `LINE_COUNT=64`、`INDEX_BITS=6`。
- flush index 递增保留 `INDEX_STEP` 参数化，不再依赖硬编码步进常量。

## 关键产物

- `artifacts`: DCache 8KB direct-mapped 试验记录；DCache load/store 明细统计。8KB 容量改动已在后续 BPU 轮次回滚到 4KB，统计保留。
- `logs_or_traces`: `git diff --check` 静态检查输出；环境阻塞输出。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 当前 Codex PowerShell 环境无 `make`、无 `verilator`，且 `wsl.exe -l -v` 看不到 Ubuntu 发行版。
- `missing_dependencies`: Linux/WSL 构建环境或可用 Verilator 工具链。
- `risk_assessment`: RTL 改动较小但未实际 lint/build，需在用户 WSL 环境补跑完整验证。

## 下一步建议

1. 在可用 WSL 环境运行 `make -C npc/single lint && make -C npc/single -j14`。
2. 重跑 benchmark，对比 `dcache load/store miss`、`dcache writeback`、CPI 与 inst/s，确认回滚后 DCache 指标回到 4KB 基线。
3. 若 writeback/miss 仍高，继续做 2-way 或小 victim cache；若 miss 代价仍高，推进 miss-side burst/line transfer。

## 模板升级候选

- `repeated_dynamic_subgraph`: cache-param-scan
- `should_promote_to_static_template`: `false`
- `reason`: 目前仅执行一次容量调参，还未形成稳定多轮模板。

## 收尾结论

- `final_result`: 第一轮 DCache 容量试验已完成并经用户复跑证明无收益；容量改动已回滚，DCache load/store 统计增强保留。
- `evidence_summary`: 静态检查无空白/冲突标记错误；真实 lint/build 因当前工具环境阻塞未执行。
- `notes`: 后续 DCache 不应继续盲目扩大 direct-mapped 容量，应基于明细统计评估 2-way/victim cache 或 miss-side burst。
