# V9F AI e2e manifest/state 审计接线独立复核

## 合同

- `task`: `/root/v9f_ai_e2e_final_review`
- `contract`: `.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/subagent-contracts/v9f-ai-e2e-audit-final-review.json`
- `contract_sha256`: `61220627819dec28e25d1d05ee24a1ed36cab46fff627f4b30016c3e6233d05c`
- `mode`: `prompt-supplied-self-contained`、`read-only-review`
- `authority`: `allowed_commands=[]`、`write_paths=[]`；无 shell、filesystem、
  network、accounts、credentials 或 external services

早期 `/root/ai_trace_state_fix_review` 没有先绑定 task-local JSON 合同，只作为
candidate review 保留；其首次 GAP 驱动了集合精确性、幂等、metadata refresh、
删除/peer-run 隔离、finalization 顺序和历史边界补证，后续结果不追认为正式 PASS。

## 最终 verdict

`PASS`，`blocker_counterexamples=[]`。

审查者接受的精确命题为：仅对 manifest 已写定、随后按
`render manifest → index → validate` 完成重新索引并通过验证的规范 final-state
run，DB `evidence_assets` 才可声明为 ordinary assets 与唯一 canonical
`.github/task-runs/<run>/run-manifest.json` 的并集；canonical manifest 只是 trace
pointer，不进入 ordinary count、bytes、kind 或 list 聚合。

冻结材料已覆盖重复路径、额外顶层 pointer、metadata 更新、manifest 删除清理、
peer-run 隔离，以及 `run_id` 到 task-run root 的 state-report 路径反例；没有形成
范围内 blocker。

## 保留风险与拒绝外推

- 最后一次索引后若再次修改或删除 manifest，DB metadata 可暂时陈旧；必须
  重新索引和验证后才能恢复不变量。
- 历史、blocked、non-final run 不自动迁移；单个 DB-only backfill 不能推广为
  全历史迁移保证。
- 当前 probe 不证明并发写入、索引中断或崩溃中间态的原子性。
- 不接受一般性的 `DB count >= manifest asset_count` 作为一致性证明，也不允许
  canonical manifest 之外的其它顶层 DB pointer。
- 本结论不外推生产 RV64 Verilog、full-core arch-stable、PPA qualification 或
  promotion eligibility；这些状态仍分别为 production RTL unchanged、
  `GAP/41 blockers`、`UNQUALIFIED`、`false`。
