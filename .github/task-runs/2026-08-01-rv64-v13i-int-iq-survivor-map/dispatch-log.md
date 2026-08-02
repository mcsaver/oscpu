# Dispatch log

- 2026-08-01：派发本地 RV64 `OooIntIssueQueue` V13I 只读独立终审。
  - 合同 JSON：`.github/task-runs/2026-08-01-rv64-v13i-int-iq-survivor-map/subagent-contracts/v13i-int-iq-survivor-map-final-review-v1.json`
  - 合同 JSON SHA-256：`45454002f2b3e0f280d1ebc4db2f22be36ae0ffcc3830ede1cb36494ec1374e9`
  - 渲染提示：`.github/task-runs/2026-08-01-rv64-v13i-int-iq-survivor-map/subagent-contracts/v13i-int-iq-survivor-map-final-review-v1.rendered.txt`
  - 执行模式：`workspace-files`、只读 `rg/sed/sha256sum`、WSL single-flight。
  - 结果：`APPROVED_DEVELOPMENT_CHECKPOINT`；`promotion_eligible=false`；无合同内可操作 RTL 反例。
  - 可操作复核意见：CPI-neutral 摘要补入 V13H/V13I design-id 与两侧 benchmark 日志 SHA-256；已落实到 `evidence/functional/cpi-neutral.json`。
  - 保留边界：full-core mapped/STA、qualified power、新完整系统事务 NOT_RUN。
