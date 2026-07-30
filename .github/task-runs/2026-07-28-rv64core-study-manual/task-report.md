# 任务报告

## 基本信息

- `task_id`: `rv64core-study-manual-20260728`
- `task_slug`: `rv64core-study-manual`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: `Codex /root`
- `started_at`: `2026-07-28`
- `updated_at`: `2026-07-28`

## 任务目标

- `source_request`: 在 `docs/rv64core/study/` 新建“一生一芯讲义式”RV64 Core 学习资料，详细解释当前 Core 构成，覆盖 `npc/rv64/vsrc/` 每个文件，并为时序问题提供 WaveDrom。
- `goal`: 从当前本地 RTL 实例树、事务流和周期边界生成可逐章学习、可机械检查源码覆盖率的讲义。
- `scope`: `npc/rv64/vsrc/**` 只读；新增 `docs/rv64core/study/**`；同步本 task-run 与 NPC/project memory。

## 选图说明

- `selected_template`: `custom: recall -> inventory -> architecture-map -> write -> coverage/timing verify -> adversarial review -> record`
- `why_this_graph`: 任务同时跨越前端、乱序后端、FP、LSU/MMU、控制、总线、仿真与 150 文件源码清册，现有回归图不覆盖教学文档生成。
- `dynamic_nodes_added`: `source-inventory`、`hierarchy-elaboration`、`file-coverage-audit`、`wavedrom-json-audit`
- `why_dynamic_nodes_were_needed`: 用户要求“每个文件都讲到”和时序图，必须增加可判定覆盖门。

## 节点概览

| 节点ID (`node_id`) | 负责 Agent (`owner_agent`) | 状态 (`status`) | 输入 (`inputs`) | 输出 (`outputs`) | 证据 (`evidence`) |
| ------------------ | -------------------------- | --------------- | --------------- | --------------- | ----------------- |
| `recall` | `/root` | `completed` | AGENTS、memory、RV64 README/arch 资料 | 约束与现状基线 | 本报告、dispatch-log |
| `source-inventory` | `/root` | `completed` | `npc/rv64/vsrc/**`、`filelist.mk` | 150 文件清册、6 类实例状态 | `/tmp/rv64-study-inventory-current.tsv`、讲义第 11 章 |
| `hierarchy-elaboration` | `/root` | `completed` | `RTL_CORE_SRCS`、`NpcTop` | Verilator XML 实例树 | `/tmp/rv64-study-npctop.xml`（临时只读分析产物） |
| `manual-design` | `/root` | `completed` | 架构与清册 | 00–12 章节、学习路径、37 个时序场景 | `docs/rv64core/study/README.md` |
| `manual-write` | `/root` | `completed` | 当前 RTL 与章节设计 | 4335 行 Markdown 讲义与 2 个审计工具 | `docs/rv64core/study/**` |
| `coverage-verify` | `/root` | `completed` | 讲义与 150 个 `vsrc` 文件 | 150/150、链接、37 个 WaveDrom JSON PASS | `python3 docs/rv64core/study/tools/audit_vsrc_coverage.py` |
| `adversarial-review` | `reviewer` | `completed-gap` | 冻结讲义、当前 RTL、三份只读合同 | 0 个 P0；2 个 P1、2 个 P2 均已修正 | 四份隔离合同、reviewer verdict、修订后审计 PASS |
| `record` | `/root` | `completed` | 完整交付与验证 | task-run、project/NPC stored memory、bounded brief、strict guard | memory load/brief 与 guard PASS |

## 关键产物

- `artifacts`: `docs/rv64core/study/**`
- `logs_or_traces`: Verilator XML、inventory TSV、覆盖审计 PASS、Python py_compile PASS、strict guard PASS。
- `linked_memory_updates`: `.github/memory/project-status.md`、`.github/memory/modules/npc.md` 已按 full-content 协议发布到 stored DB 并刷新 shim。
- `subagent_contracts`: `frontend-decode-study-review.json`、`backend-fp-retire-study-review.json`、`memory-control-integration-study-review.json`、`final-study-manual-adversarial-review.json`。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: 无。
- `risk_assessment`: `vsrc/README.md` 和旧架构快照存在历史漂移；讲义已明确以当前 RTL 展开层次与端口流为准。未运行动态 TB、综合、STA 或 PPA，因此这些范围保持 GAP。

## 下一步建议

1. 按 `README.md` 的推荐路线从全局拓扑开始学习，再沿自己关注的 transaction 追到第 11 章真实路径。
2. 若要把静态时序合同升级为动态证据，按第 12 章实验逐项补 focused TB、波形 marker 和负向版本。

## 模板升级候选

- `repeated_dynamic_subgraph`: `RTL source inventory -> hierarchy -> file coverage -> teaching manual`
- `should_promote_to_static_template`: `false`
- `reason`: 当前为首次完整 RV64 教学讲义任务，尚不足以固化通用模板。

## 收尾结论

- `final_result`: `completed-with-dynamic-verification-gap`
- `evidence_summary`: 已完成规则召回、150 文件/6 类状态清册、NpcTop/NpcSimTop 层次展开、4335 行讲义、37 张严格 JSON WaveDrom、150/150 结构化文件地图与链接 PASS；终审无 P0，2 个 P1 与 2 个 P2 均已修正；project/NPC stored memory、成功 bounded brief 和 strict guard 均已闭环。
- `notes`: 不以文档生成证明 RTL 功能、综合、STA、PPA 或 Linux 系统 gate。
