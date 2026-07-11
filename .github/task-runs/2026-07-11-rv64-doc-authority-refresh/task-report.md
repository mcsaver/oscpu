# 任务报告

## 基本信息

- `task_id`: 2026-07-11-rv64-doc-authority-refresh
- `trace_id`: manual:2026-07-11-rv64-doc-authority-refresh
- `task_slug`: rv64-doc-authority-refresh
- `graph_template`: current-authority-and-archive-closure
- `profile`: npc-dev completed；agent-system explicit exemption
- `status`: completed
- `owner`: root + three read-only reviewers
- `started_at`: 2026-07-11
- `updated_at`: 2026-07-11 16:50 +0800

## 目标与边界

- 把代码优先审计结论写入当前文档权威，并归档被当前 RTL 超越的时点快照。
- 修正审计结果对 module/AM 聚合摘要的越级解释。
- 不修改 DUT 行为，不回写不可变旧 task-run，不提交或推送 Git。

## 交付结果

- 新建 2026-07-11 CURRENT snapshot；07-03 snapshot 已归档并登记 `SUPERSEDED`。
- README、架构宪法、ROADMAP、关键 active spec、history index 与 owner 注释已同步。
- 审计结果已撤回 module/AM 全绿结论，并新增 `VALIDATION_ERRATUM.txt`。
- project-status、modules/npc、known-issues 已按 stored-document 流程回写与 bounded readback。

## 验证

- Markdown local targets、old-reference closure、targeted stale wording、尾随空白、
  `git diff --check`、DB-first audit、markdown coverage audit：PASS。
- 三处 RTL 文件只有注释替换；无 DUT 行为变化。
- npc-dev profile fresh completed。
- strict guard **未 PASS**：agent-system 被既存 1.65 MiB `topo40.rpt` 的全局 artifact
  audit 阻断；根因、文件来源与显式豁免见 `evidence/final-verification.md`。

## 审查结果

- 独立终审最终未发现 P0/P1/P2 文档阻塞项。
- 不把 `overall_rc=0`、module summary 86/86 或 AM summary PASS 扩写为真实全绿。

## 剩余项（不在本任务授权范围）

- 修复 module/AM 结果聚合器、三个失败 TB 与 `fp-difftest-probe` 后重新运行回归。
- 逐项修复 FDG-G1、XRET-G1、IFU-AXI-G1、IFU-FETCH-G2、PTW-PMP-G1、MIQ-G1、INSTRET-G1。
- 由历史 evidence owner 处置超限 `topo40.rpt`，再补 agent-system completed profile。
