# Task Report

## 基本信息

- `task_id`: `2026-05-21-npc-bpu-bht12-profile`
- `task_slug`: `npc-bpu-bht12-profile`
- `graph_template`: `custom`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-05-21`
- `updated_at`: `2026-05-21`

## 任务目标

- `source_request`: 用户复跑 DCache 8KB 优化后给出新 benchmark 截图。
- `goal`: 判断 DCache 容量优化是否有效，并继续压条件分支误预测或补充画像。
- `scope`: `NpcCore.v`、`DCache.v`、`NpcSimTop.sv`、`cpu-exec.cpp` 与项目记忆。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 这是 benchmark-driven 的微结构调参，不是完整回归模板。
- `dynamic_nodes_added`: `analyze-result`, `env-verify`
- `why_dynamic_nodes_were_needed`: 用户提供的新证据改变了优化方向；当前工具环境仍不能本地构建。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| analyze-result | codex | completed | 用户截图 | 8KB DCache 无明显收益，转向 BPU | `dcache miss=944073`、`writeback=771224`、`CPI=1.297` |
| implement-bpu | codex | completed | BPU 参数链、resolve event | BHT 12-bit、top miss PC 画像 | 文件修改 |
| rollback-dcache-exp | codex | completed | 用户复跑证明 8KB DCache 无收益 | DCache 容量回滚到 4KB，统计保留 | `DCache.v` 参数恢复为 `LINE_COUNT=64`、`INDEX_BITS=6` |
| verify-static | codex | completed | 已改文件 | 静态检查通过 | `git diff --check` 仅 LF/CRLF 提示 |
| env-verify | codex | blocked | 当前 PowerShell 环境 | 记录 lint/build 阻塞 | `make`/`verilator` 不可用，WSL Ubuntu 不可见 |
| record | codex | completed | 本轮结论 | project-status、npc memory、task-runs | 本文件与 memory 更新 |

## 关键产物

- `artifacts`: `BPU_BHT_INDEX_W=12`；branch mispredict top PC 统计；无收益的 DCache 8KB 容量试验回滚到 4KB。
- `logs_or_traces`: 用户 benchmark 截图；静态搜索与 `git diff --check`。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 当前 Codex PowerShell 环境没有 `make`/`verilator`，且无法进入用户 WSL Ubuntu。
- `missing_dependencies`: 可用 Linux/WSL 构建与 Verilator 工具链。
- `risk_assessment`: BHT 扩表会增加少量仿真/RTL状态；PC 画像只在 branch mispredict 上更新，可能带来轻微 host 统计开销。

## 下一步建议

1. 在 WSL 中运行 `make -C npc/single lint && make -C npc/single -j14`。
2. 重跑 CoreMark benchmark，对比 branch accuracy、BHT miss、top branch miss PCs。
3. 若误预测仍集中在少数 PC，优先做 loop predictor；若分散，考虑 local-history/tournament predictor。
4. DCache 方向不要继续只扩 direct-mapped 容量，应转向 2-way/victim cache 或 miss-side burst。

## 收尾结论

- `final_result`: 已落盘 BPU 12-bit gshare 扩表与 branch miss PC 画像，并回滚 DCache 8KB 容量试验、保留 DCache load/store 画像。
- `evidence_summary`: 静态一致性检查通过；实际 lint/build/benchmark 未在当前工具环境执行。
- `notes`: 用户新数据证明 8KB DCache 容量翻倍不是有效方向。
