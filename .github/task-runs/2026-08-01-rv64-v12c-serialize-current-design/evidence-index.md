# V12C 证据索引

- currentness decision：`currentness-decision.json`
- queue-head 最终证据：`evidence/qh-current-attempt-3/summary.json`
- pending-SYSTEM 最终证据：`evidence/system-current-attempt-3/summary.json`
- queue-head oracle 修正轨迹：`evidence/qh-current-attempt-2/failure.json`
- pending-owner oracle 修正轨迹：`evidence/system-current-attempt-2/failure.json`
- independent review：`reviewer-result.md`
- reviewer contract：`subagent-contracts/v12c-serialize-current-review.json`
- verification summary：`verification-result.md`

各 attempt 只保留结果、make/testbench 日志与 JSON 收据；`.vvp/.deps/.argv/.compile.rc`、临时 wrapper 和完整负向 RTL 文件均已删除。
