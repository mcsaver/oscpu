# V13K changed-path guard 结果

- 显式路径输入：`agent-flow-changed-paths.tsv`，12 个路径；未使用 Git worktree 枚举。
- strict guard 推荐 profile：`npc-dev`。
- profile 结果目录：
  `.github/task-runs/2026-08-01-rv64-v13k-performance-region-final-guard/`。
- 五个合同节点均为 PASS：software-flow、npc-sim、npc-single、npc-soc、npc-rv64。
- 前置 `context-brief` 为 WARN，wrapper 按 fail-closed 规则记录 `status=blocked`，所以 strict guard
  不得写成 PASS。
- 处理：保留原始 blocked task-run，不重试、不运行 RTL/系统高成本 profile；在本报告、verification
  JSON、reviewer 结果和 DB-backed memory 中记录豁免边界。硬件交付只声明 V13K 定向范围 PASS。

