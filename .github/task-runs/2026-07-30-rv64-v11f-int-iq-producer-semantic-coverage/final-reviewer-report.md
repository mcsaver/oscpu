# V11F independent final review

RV64 RTL 结论｜对象=`OooIntIssueQueue.producer_id_q`｜周期/配置=edge-old Q；
assert/release × `PRODUCER_GEN_W=1/4`｜TB/EDA 观测=4/4 正向 PASS、
20×2 变体 40/40 定向拒绝、normal regression PASS｜范围=PASS
（bounded APPROVE）

## Findings

- blocker：`0`
- 合法 IQ-I6 输入合同内未发现 production 周期反例。
- production `OooIntIssueQueue.v` scoped diff 为空，live SHA-256 为
  `d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b`。
- 16-source manifest pre/post SHA-256 均为
  `a63a63c07fffde49be62ebcfeeb6f02d97fc5141d7b61c9e7bbdfbb2b47c7747`。
- 146-file RTL snapshot pre/post SHA-256 均为
  `665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca`；
  design-id 为
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`。

## Oracle independence

- testbench-owned 八槽 model 只由 stimulus 与显式
  fire/pop/kill/flush/reset 日程推进。
- DUT `valid_q`、`producer_id_q` 和 `producer_live_mask_o` 仅作为比较对象，
  不参与 expected 构造。
- 每个 expected-valid 槽均检查 raw PID reduction-X；`dispatch0-pid-x`、
  `dispatch1-pid-x`、`compaction-pid-x` 在 g1/g4 release 配置中均首先命中
  raw PID unknown。

## Sensitivity and regression

- 四个 assert/release × `GEN_W=1/4` positive profiles 全部 PASS。
- 二十个 mutation 覆盖 birth/lane identity、compaction、issue/full-P、
  raw-index carrier、single/dual/pair death、kill/flush/reset、edge-old mask
  与 X-knownness。
- 40 个 mutation compile RC 全为 0，compile log 未定义 `OOO_ASSERT`，
  sim RC 全为 1，并出现 `[V11F-INT-IQ-ORACLE][FAIL]`。
- normal `tb_ooo_int_issue_queue` 得到 `[RESULT] PASS`。
- evidence-tool 8/8；semantic-ledger 22/22 单测 PASS。

## Ledger and boundary

- V11E→V11F 唯一 semantic unit 状态迁移为
  `integer-iq-producers: GAP -> PASS`。
- 账本总计从 7 PASS / 37 GAP 变为 8 PASS / 36 GAP。
- global no-live-reuse 保持 `SEMANTIC_COVERAGE_REQUIRED`，whole architecture
  保持 RED，PPA 保持 UNPROMOTED。
- 上游 kill/flush transaction-barrier 可达性、其余 36 个 semantic unit、
  system、synthesis、STA、power/PPA 均未闭合。
- 终审只读复核已有 Icarus/VVP 证据，未新跑仿真、综合或 STA。

## Contract binding

- reviewer contract：
  `.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/subagent-contracts/v11f-int-iq-producer-final-review.json`
- reviewer contract SHA-256：
  `b41dab889c477796f8397cde8dccf7eecc457524c70c193ea8c508e86bda9234`
- scope extension request：none for the bounded unit; upstream transaction-barrier
  closure remains a separately versioned integration task.
