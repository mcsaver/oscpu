# 任务报告

## 基本信息

- `task_id`: `2026-06-27-npc-rv64-ooo-struct-params`
- `task_slug`: `npc-rv64-ooo-struct-params`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-06-27 12:58 +0800`
- `updated_at`: `2026-06-27 12:58 +0800`

## 任务目标

- `source_request`: 用户要求按 OoO RTL 优化路线落地，优先统一结构参数、收口边界。
- `goal`: 本切片完成第 0 步，把 OoO PRF/FreeList/ROB/IQ/fetch FIFO 默认结构参数统一到 `define.v`。
- `scope`: `npc/rv64/vsrc/include/define.v`、OoO 参数链相关 RTL、设计规格、memory/task-run 记录。

## 选图说明

- `selected_template`: `custom`
- `why_this_graph`: 任务是 RV64 OoO RTL 结构重构切片，已有拆分历史较多，适合按最小可验证 RTL 切片推进。
- `dynamic_nodes_added`: `recall-current-boundary`、`unify-struct-params`、`verify-focused`
- `why_dynamic_nodes_were_needed`: 用户给的是多阶段路线图；本轮只闭合其中第 0 步，避免越级声明整体优化完成。

## RTL 推导摘要

- 需求要点：集中定义 `OOO_PHY_REG_ADDR_W`、`OOO_FREE_COUNT_W`、`OOO_ROB_INDEX_W`、`OOO_ROB_COUNT_W`、`OOO_ISSUE_INDEX_W`、`OOO_ISSUE_COUNT_W`、`OOO_FETCH_PACKET_COUNT_W`，并让顶层和子模块默认参数引用。
- 协议规则：计数宽度比对应 index 宽一位；PRF count 从 physical register address width 派生；显式 parameter override 仍可覆盖默认宏。
- 状态机骨架：无新增状态机；FreeList/ROB/IQ/FIFO 原状态转移不变。
- 关键不变量：顶层 `free_count_o/rob_count_o/issue_count_o` 宽度和内部模块 count 宽度同源；vsrc 不再保留同类默认参数 magic number。
- 数据通路骨架：`NpcCoreTop` 通过完整宏参数组实例化 `OooAluFetchCore`，后级继续沿既有 parameter 链传递。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall-current-boundary` | Codex | completed | AGENTS/memory/rv64 README/vsrc README/现有 RTL | 确认已有 fetch/pending 拆分，选择第 0 步参数统一为本轮切片 | 读取记录与 `rg` 扫描 |
| `unify-struct-params` | Codex | completed | `define.v` 与 OoO 参数链 | 新增 OoO 结构宏，顶层和相关模块默认参数引用宏 | `rg` 残留扫描无同类默认硬编码 |
| `verify-focused` | Codex | completed | 修改后的 RTL | focused TB、lint、build 通过 | `npc/rv64/perf/results/20260627-ooo-struct-params/focused/`；`make -C npc/rv64 lint`；`make -C npc/rv64 -j2` |

## 关键产物

- `artifacts`: `npc/rv64/design/specs/ooo-structure-params.md`
- `logs_or_traces`: `npc/rv64/perf/results/20260627-ooo-struct-params/focused/summary.txt`
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 未跑官方 riscv-tests 全量和 CPU-test 全量，因为本切片不改变时序/功能语义，已用 focused + lint + build 覆盖参数链。
- `risk_assessment`: 当前只证明结构参数默认同源和构建通过；后续若实际改变容量，仍需跑完整 module/core 回归。

## 下一步建议

1. 继续用 `common/`/`pipeline/` 收口事实总线和阶段边界。
2. 对 `OooFpPendingExec` 做等价函数级拆分并建立 focused golden test。

## 收尾结论

- `final_result`: 本切片完成第 0 步结构参数统一。
- `evidence_summary`: focused 9/9 PASS，lint PASS，build PASS。
- `notes`: 这不是整条 OoO 优化路线完成；FP 巨石、IntBackend 拆分和更完整性能回归仍是后续工作。

