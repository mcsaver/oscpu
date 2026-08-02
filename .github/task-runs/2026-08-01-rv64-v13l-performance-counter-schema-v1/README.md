# RV64 V13L performance counter schema v1

本 task-run 只保留可复核结果、driver 与小日志；两个 Verilator build/obj 目录均在 SHA/结果落盘后
删除。权威结论见 `verification-result.json`，反例审查见 `reviewer-result.md`，真实 CoreMark 原始输入
与解析结果位于 `evidence/coremark-current/`。
`evidence-index.md` 与 SQLite evidence asset 索引只保存路径、SHA、marker 和小摘要，不复制原始日志正文。

本轮属于 verification/performance-CPI 开发检查点，不是性能 baseline。`head_not_complete` 尚未完成
因果拆分，issue/occupancy/typed identity/3× cohort 均保持 GAP。
