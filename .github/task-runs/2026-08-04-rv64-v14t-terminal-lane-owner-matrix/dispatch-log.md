# V14T dispatch log

- 本地 RV64 只读独立复核合同：`.github/task-runs/2026-08-04-rv64-v14t-terminal-lane-owner-matrix/subagent-contracts/v14t-terminal-lane-workflow-review.json`
- 合同 JSON SHA-256：`8c5a954002b3dc430ed144fbf784f0ef85d5da521d3376e77c5d9f0b2e2b3b4b`；该哈希只绑定此 JSON。
- 派发前候选：generation 3，五个轻量固定轮 PASS；审查对象仍保持 historical terminal duplicate `SELECTED/VD1`、`ARCH_STABLE=GAP`、PPA `UNQUALIFIED`。
- shell ownership：reviewer 仅使用合同内只读命令；派发期间主节点不运行 WSL 工程命令，节点返回后归还。
- 节点状态：平台已有三个 completed reviewer 槽位且拒绝创建新的 `fork_turns=none` 隔离节点；未复用继承旧上下文的节点，合同保留为 `review_pending`，不作为独立硬证据。
- 主节点审查者复核：把 pair JSON 的结论收窄为 pre-collector duplicate protection，并用冻结五项 closed-ledger view 修复 current receipt 三个会被新 blocker 提前拒绝的负向单测；相关定向测试 44/44 PASS。
