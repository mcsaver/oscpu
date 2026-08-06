# V14I independent review dispatch

- rendered contract path: `.github/runtime-artifacts/agent-flow/rv64-v14i-system-recertification-replay-v1/review/rv64-v14i-independent-review-v1.json`
- durable contract copy: `.github/task-runs/2026-08-03-rv64-v14i-system-recertification-replay-v1/subagent-contracts/rv64-v14i-independent-review-v1.json`
- contract SHA-256: `92a42783e096e9e58a8720e08fcf35d9da133f19e6788e228fba262888073d57`
- mode: `read-only-review`, `workspace-files`, `fork_turns=none`
- allowed commands: `rg`, `sed`, `git diff`, `sha256sum`

## Review sequence

1. 主节点交付唯一 WSL command ownership；review v1 返回 GAP，证明 TSV marker 未逐 tier 绑定。
2. 主节点修复 exact-row checker 并增加字段级负例；review v2 中间检查发现两个 mutation 结构失真。
3. 主节点改为单字段 `awk` mutation，并在 checker 前强制 4 行×9 列；generation=6 门禁重新执行。
4. reviewer 最终 PASS，`scope_extension_request=none`，并明确归还 WSL ownership。
