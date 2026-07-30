# V11B 独立终审

## 合同

- task：`v11b-holder-semantic-coverage-final-review`
- mode：read-only review
- contract SHA-256：
  `49177c45a363d2953e59387018e8d82675543ab3415cba89b1e5f90368a18f80`
- design-id：
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## 结论

`OooMemOwnerTerminalCollector` 的三个 collector 语义单元批准 bounded
PASS；全局其余 41/44 保持 GAP。

复核观测：

- 12 ingress + 2 tracker-free lane 映射 PASS；
- accepted-only authority PASS；
- duplicate ingress 不合并；
- assert/release 2/2 PASS；
- 双 output 非对称 turnover/hold PASS；
- unknown negative 由
  `[V11B-TCOLL-INGRESS-TUPLE-KNOWN]` 拒绝；
- 3/3 compile-success RTL mutation 被预期 marker 拒绝；
- 146-file RTL pre/post 与 10-file runner pre/post 相同；
- ledger 为 44 units / 17 instances / 50 bindings /
  3 PASS / 41 GAP。

## Reviewer 反例与纠偏

reviewer 指出：`v11b_terminal_collector` 的 closure evidence 原先由 policy
`unit_ids` 关联，checker 未显式限制 exact collector unit set。当前 policy
虽正确，但未来可能把同一 closure 改绑无关的单实例 unit。

纠偏：

- checker 新增 exact set：
  `terminal-output0-token`、`terminal-output1-token`、
  `terminal-pending-set`；
- 新增负向测试，把第三项改绑
  `pending-system-producer`，必须以
  `exact collector unit set` 失败；
- 修订后 semantic/lane tests 16/16 PASS；
- ledger 重建/verify 仍为 3 PASS / 41 GAP。

## 未知项与边界

reviewer 未重新运行仿真；其结论消费 attempt-3 的 source-bound artifact。
collector integration 之外的 raw ingress consumer、其余 41 个语义单元、
full-core currentness、系统级 replay、综合、STA、功耗和 PPA 均不在本次
bounded PASS 内。

reviewer 未修改文件，并已归还 Windows→WSL single-flight shell ownership。
