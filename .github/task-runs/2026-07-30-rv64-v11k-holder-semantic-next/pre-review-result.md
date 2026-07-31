# V11K holder 候选预审

## 结论

预审选择只闭合 `miq-owner-tokens`，不同时宣称 `OooIntBackend` 其它
reservation、legacy 或 pending-system holder 已完成。该单元同时绑定
`u_mem_inflight_queue` 与 `u_mem1_inflight_queue` 两个产品实例。

## 预审发现的证据缺口

- 原 RTL 只显式检查有效 entry 的 `owner_token_q` knownness，没有覆盖
  完整 `{owner_kind_q, owner_token_q, mmu_epoch_q}`。
- 原单实例 testbench 没有 owner kind/token/epoch 的 X/Z 负向 profile。
- 原双 bank 场景没有形成聚焦的 swapped-tuple/cross-instance 拒绝证据。
- 需要证明 stall 期间身份保持、flush/kill survivor、exact consume 和
  精确 occupancy token 集合。

## 最小闭环建议

1. 增加完整 tuple knownness 与 idle-stability 断言。
2. 用两个直接实例和独立固定期望表构造双实例矩阵。
3. 在 assertion/release 两种编译配置中检出编译成功的负向 RTL 变体。
4. 只把 `miq-owner-tokens` 从 GAP 提升为 PASS；预期 ledger 从
   16/44 PASS、28/44 GAP 变为 17/44 PASS、27/44 GAP。

预审合同：
`.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/subagent-contracts/v11k-holder-semantic-candidate-pre-review.json`

合同 SHA-256：
`a044b39271759e835d012a24d3d32acee39ffa4078ea4acd00acbc6fd7dbfed0`
