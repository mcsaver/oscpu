# RV64 V11B ProducerId holder 语义覆盖报告

## 状态

`COLLECTOR_BOUNDED_PASS / GLOBAL_SEMANTIC_GAP`。

当前设计标识：

`sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`

## 覆盖账本

- semantic units：44；
- holder instances：17；
- unit×instance bindings：50；
- current candidate units：34；
- no-candidate units：10；
- ledger-only units：0；
- semantic PASS：3；
- semantic GAP：41。

唯一局部 PASS 为：

- `terminal-output0-token`；
- `terminal-output1-token`；
- `terminal-pending-set`。

两个 `OooMemInflightQueue` 和两个 `OooMemAxiBridge` instance 均保持独立
路径，未按 module name 合并。

## Terminal collector 证据

- 12 路 ingress tuple 映射：PASS；
- 2 路 tracker-free lane 映射：PASS；
- accepted-only transfer authority：PASS；
- duplicate ingress merged：false；
- assert/release：2/2 PASS；
- valid ingress unknown negative：由
  `[V11B-TCOLL-INGRESS-TUPLE-KNOWN]` 拒绝；
- compile-success RTL mutations：3/3 rejected；
- 146-file RTL pre/post binding：相同；
- output0/output1 非对称 turnover/hold：PASS。

主要证据：

| 产物 | SHA-256 |
| --- | --- |
| `evidence/semantic-coverage-ledger.json` | `85e176b99816e4126b7e4a269af37a63eca82e3e58e345b4e4431b980405acf6` |
| `evidence/terminal-collector-lane-contract.json` | `1353ac2d876260dbb30ecdc69dcf812b65d6977082f87f4ef6bd77d1bc495f00` |
| `evidence/terminal-collector-attempt-3/summary.json` | `b41598a5ee849033080c1d870c4f3cac3dba83d171a6c4384758b3bf234b57e5` |

attempt-1 与 attempt-2 的失败产物原样保留；它们分别记录 mutator anchor
缺口和不具判别力的 same-edge 变异。attempt-3 只在修正反例合同后发布 PASS。

## 分层验证

- V11A runner fail-closed unit：6/6 PASS；
- V11A product instance graph：15 module / 17 instance / 194 reachable PASS；
- producer-holder census：20 direct / 5 packed / 15 token / 1 generation PASS；
- V8L lifecycle：5 个 marker、9/9 compile-success mutation rejection PASS；
- V9R retry C0：2/2 baseline、3/3 mutation rejection PASS；
- semantic coverage + lane contract unit：16/16 PASS；
- terminal collector focused attempt-3：PASS。

## 独立终审

合同 `v11b-holder-semantic-coverage-final-review`（SHA-256
`49177c45a363d2953e59387018e8d82675543ab3415cba89b1e5f90368a18f80`）
以只读方式复核 RTL、TB、lane contract、summary 与 ledger，批准 collector
三单元 bounded PASS，并明确保持其余 41/44 GAP、whole architecture RED、
PPA UNPROMOTED。

reviewer 发现 evaluator 未硬限定 V11B closure evidence 的 exact unit set。
该反例已转成
`test_v11b_closure_cannot_be_rebound_to_unrelated_unit`；checker 现在要求
`v11b_terminal_collector` 只能绑定三个 collector 单元，改绑
`pending-system-producer` 会 fail closed。修订后 semantic/lane tests
16/16 PASS，ledger 仍为 3 PASS / 41 GAP。

## 保留的当前缺口

`currentness-rebind-attempt-21` 原始 FAIL 不修改：10 个 canonical
closed debt 的 `semantic_evidence` 仍为 GAP。随后 workflow binding 新增
semantic ledger、lane checker、policy 与 collector runner 后，
`test_arch_stable_freeze` 为 51/53，两个失败分别是
`CONTROL-EVENT-G1` 的 V9O/V9R design/source identity 未整体重绑，以及
旧 current candidate 对新增 workflow/debt source 的 semantic evidence
保持 GAP。这些是证据身份未刷新，不是允许删除检查或追认假绿的理由。

## AI workflow 与 strict guard

- task-specific `npc-dev`
  `.github/task-runs/2026-07-29-rv64-v11b-holder-semantic-coverage/`
  为 completed，5 个展开节点全部 PASS。
- strict guard 的 `agent-system`、`rv64-systemd-contract` 与 `npc-dev`
  均 PASS。
- 唯一剩余 guard FAIL 为 mixed-origin
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺当前 `rv64-linux` profile
  evidence；该路径未被本 V11B collector/ledger 修改，也不属于本轮
  assertion/TB/checker 限域。保留显式豁免，不把它改写成 RTL PASS，
  也不为关闭文档门而启动无关 rootfs replay。
- DB-first audit 已消除本轮 memory mismatch、missing-stored 与 backup
  mismatch；仅保留 8 个其它历史 task-run 的 `missing_backup`，不属于
  V11B 证据目录。

当前结论保持：

- global no-live-reuse：RED；
- whole architecture：RED/GAP；
- PPA：UNPROMOTED / UNQUALIFIED；
- full-system A3 replay：本 assertion-only 改动不触发。

## 工作树边界

工作树包含 mixed-origin 既有改动。本轮未执行 reset、restore、clean、stash、
commit、push 或 rebase；证据按本 task-run 的精确路径、design ID 和 SHA-256
隔离。
