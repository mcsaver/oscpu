# 任务报告

## 基本信息

- `task_id`: 2026-07-05-rv64-debug-methodology-reflection
- `task_slug`: rv64-debug-methodology-reflection
- `graph_template`: `custom`（元分析/复盘，非代码改动）
- `graph_mode`: `dynamic`
- `status`: `completed`
- `owner`: Claude (Opus 4.8, ultracode workflow)
- `started_at`: 2026-07-05
- `updated_at`: 2026-07-05

## 任务目标

- `source_request`: 用户要求从历史对话记录中思考"为什么每次 debug 找 RTL bug 那么慢、为什么有了 spec 仍不断出 bug"；随后深化为"怎么像真正的 IC 工程师/IC 公司那样 architecture-first、把'更顶层更抽象'落成具体物"。
- `goal`: 用历史会话的量化证据 + 项目现有代码/文档，归因 debug 慢与 spec-bug 落差的根因，并给出可落地的方法论与改进路径。
- `scope`: 纯分析与文档沉淀，**不改任何 RTL/构建代码**。

## 选图说明

- `selected_template`: 两个动态 workflow 串联。
- `why_this_graph`: 材料是 21 个大会话（180MB）+ 492K/516K 沉淀文档，需并行读取 + 归纳 + 对抗审查，单上下文装不下。
- `dynamic_nodes_added`: ①复盘 workflow：9 会话解剖 + 3 文档/定量 + 综合 + 对抗审查 + 定稿；②architecture-first workflow：业界流程‖54-bug 证据审判‖现有 spec 粒度诊断‖契约清单‖诚实反面 → 综合 → 对抗审查 → 定稿。
- `why_dynamic_nodes_were_needed`: 会话规模与文档粒度事先未知，需先 digest 预处理再按大小分组分派。

## 节点概览

| 节点ID | 负责 Agent | 状态 | 输入 | 输出 | 证据 |
| --- | --- | --- | --- | --- |
| digest | 主控 | done | 21 会话 jsonl | 精简 timeline + metrics.tsv | Edit/COMPILE/RUNTEST/PROBE 计数 |
| dissect×9 | workflow | done | 会话 timeline | 54 bug 卡（spec_relation/root_cause 标签） | journal wf_76e0b4f6 |
| doc×3 | workflow | done | known-issues/project-status/metrics | bug 家族 + 方法学 + 定量画像 | — |
| synth+critique+report | workflow | done | 上述全部 | 复盘定稿（对抗审查纠偏伪精确/幸存者偏差） | postmortem-why-slow.md |
| arch 5路+综合+审查+定稿 | workflow | done | 54-bug journal + design/ + vsrc/ | architecture-first 定稿 | architecture-first.md |

## 关键产物

- `artifacts`: 同目录 `postmortem-why-slow.md`、`architecture-first.md`（两份定稿全文）；在线版 artifact `295a5802-...`（复盘）、`651a023e-...`（architecture-first）。
- `logs_or_traces`: workflow journal `subagents/workflows/wf_76e0b4f6-008/`、`wf_2fbc5e21-692/`（会话侧，不在仓库）。
- `linked_memory_updates`: `decisions.md` [38]；`project-status.md` 2026-07-05 条目；`modules/npc.md` 2026-07-05 指针；auto-memory `rv64-architecture-first-reflection`。

## 当前阻塞点

- `blockers`: 无。
- `missing_dependencies`: **缺 per-bug wall-clock / time-to-detection 数据** —— 这是唯一能把"慢是方法问题"与"慢是核本身极难验的必然"定量分开的证据，目前只能定性。数据可从后续 transcript 的 timestamp 抽取。
- `risk_assessment`: 归因受幸存者偏差限制（统计的是已逃逸成会话的 bug）；已在报告中诚实标注，不得当作定量因果结论使用。

## 下一步建议

1. 本周最小起步：把 `rv64ua/uf/ud` 加进默认回归；30 分钟 `--assert` 立即断言探针验证工具链可行性。
2. 若探针跑通：按六类契约优先冻结 flush「谁清谁保持」表，并评估 flush/redirect 单点仲裁器局部重写。
3. 补 per-bug 耗时抽取脚本，把本报告第三节的"合理假说"升级为定量结论。

## 收尾结论

- `final_result`: 两轮元复盘完成，结论沉淀为 decisions [38] + 必读链指针；核心洞察——"有 spec 仍出 bug"的根不在 spec 质量而在缺少把 spec 变成连续运行断言的强制装置；debug 慢一半是 RTL 媒介固有、一半是流程。
- `evidence_summary`: 已复核硬证据——Edit 1428/COMPILE 1353（比 1.06）、54 bug=9 agent 加总、全核 SVA 命中 0、Verilator 无 `--assert`、宪法 §7 自认 flush ≥12 源无优先级链、SPEC-TEMPLATE §2/§3 契约骨架从未填过。
- `notes`: 本任务不触碰 doc-lifecycle §4 的归档触发点（无删模块/无判死/无快照取代），仅新增稳定结论 + task-run，无悬空引用产生。

## 模板升级候选

- `repeated_dynamic_subgraph`: "digest 预处理 → 按大小分组并行解剖 → 综合 → 对抗审查"这套元分析子图可复用于未来的会话史归因。
- `should_promote_to_static_template`: 暂不；出现第二次同形需求再模板化。
- `reason`: 目前仅一次。
