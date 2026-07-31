# V11K 独立复审 attempt 2

## 结论

`OooMemInflightQueue.owner_token_q`、完整 owner tuple 与
`occupancy_token_mask_o` 的 V11K attempt-3 证据获得局部 PASS。

合同：
`.github/task-runs/2026-07-30-rv64-v11k-holder-semantic-next/subagent-contracts/v11k-miq-holder-semantic-final-review-v2.json`

合同 SHA-256：
`d0f7816e66e3de3826e0aafd06bf421deab048f55088b1da996feeeca1d526cb`

## attempt-1 blocker 处置

1. push/pop tuple assertion sensitivity：CLOSED。
   - accepted-push X/Z 精确命中
     `[V11K-MIQ-PUSH-TUPLE-KNOWN]`；
   - valid-head-pop X/Z 精确命中
     `[V11K-MIQ-POP-TUPLE-KNOWN]`；
   - release profile 由
     `[V11K-MIQ-HOLDER-ORACLE][FAIL]` 拒绝；pop oracle 明确比较固定的
     count、head tuple 与 `occupancy_token_mask_o`。
2. ordinary regression execution binding：CLOSED。
   - 三个回归分别绑定 7/7/43 个输入，pre/post 完全相同；
   - `.vvp` 与日志哈希均由 reviewer 实算匹配 summary；
   - `.vvp` SHA-256 前缀：
     `33c7c8db`、`1369d16a`、`376d699d`；
   - 日志 SHA-256 前缀：
     `41dd4c44`、`70d75235`、`6e99c840`。

## 全量观测

- 34/34 profile PASS：
  2 个 production baseline、12×2 RTL 变体、4×2 interface probe。
- 12 个变体的 24 个编译均 rc=0，24 个预期负向仿真均被拒绝，无
  `[V11K-MIQ-NEGATIVE-ESCAPED][FAIL]`。
- MIQ SHA-256：`02d2e8a2…7147`。
- 双实例 TB SHA-256：`aa1f331c…e56c`。
- attempt-3 pre/post manifest 均为 `8bc44633…`。
- instance graph 精确包含 `u_mem_inflight_queue` 与
  `u_mem1_inflight_queue`。
- V11J/V11K Yosys 两态 elaboration 均为 130 modules、176087 cells，
  canonical logic SHA-256 均为 `c49ad65d…e5b`。

## 结论边界

- PASS 仅适用于两个列出的产品 MIQ 实例上的 `miq-owner-tokens`。
- release probe 的 fail-closed 指独立 testbench oracle 拒绝 X/Z 状态污染；
  不声称 assertion-off 生产 RTL 自身包含四态 X/Z 保护逻辑。
- `global_no_live_reuse` 未证明；ledger 保持 17/44 PASS、27/44 GAP；
  whole architecture RED；PPA UNPROMOTED。
- 未运行完整系统；V11K assertion-only 增量不新增系统重跑触发。
- `scope_extension_request`：无。
- `confidence_and_basis`：高；依据为 RTL/TB/checker 源码、真实日志
  marker、实算 artifact hashes、双实例 graph、ledger 与完整 Yosys
  identity。

WSL single-flight ownership 已归还。
