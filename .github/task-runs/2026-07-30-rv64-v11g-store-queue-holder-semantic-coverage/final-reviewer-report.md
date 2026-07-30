# V11G independent final review

RV64 RTL 结论｜对象=`OooStoreQueue.producer_id_q`、owner tuple 与 V11G
本地证据｜周期/配置=allocation→bind→request→terminal→release/flush，
`PRODUCER_GEN_W=1/4`、`OOO_ASSERT` on/off｜TB/EDA 观测=4/4 正向
PASS、24×2 编译成功变体均被独立 oracle 拒绝、普通回归 1/1
PASS｜范围=PASS（bounded APPROVE）

## Findings

- blocker：`0`
- production `OooStoreQueue.v` scoped diff/status 均为空，SHA-256 为
  `5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241`；
  design-id 为
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`。
- allocation 捕获 full ProducerId；bind 捕获独立
  `{owner_kind_q, owner_token_q, mmu_epoch_q}`；request/terminal 后两类
  holder 继续 resident；exact terminal head release 才清除 holder。
- selective flush 保留 inclusive prefix；global flush 保留
  `request_sent_q` owner；terminal/release/flush 与
  bind/terminal/release bypass 未发现合法接口反例。

## Oracle independence and sensitivity

- 四槽 expected state 只由 accepted testbench stimulus 与显式 edge
  schedule 更新；DUT raw Q 只作为比较和 X-knownness 对象。
- expected 不读取 `snoop_producer_id_o`、`snoop_owner_token_o` 或 DUT
  raw Q。
- `assert-g1`、`release-g1`、`assert-g4`、`release-g4` 均含
  `[V11G-SQ-ALL]` 与最终 `[PASS]`，compile/sim RC 均为 0。
- 二十四个变体覆盖 birth/full-P、resident death、recovery、owner
  tuple/X、release mask 与 same-edge bypass；两种 generation width
  共四十八次均 `compile.rc=0`、未定义 `OOO_ASSERT`、`sim.rc=1`，
  并出现 `[V11G-SQ-HOLDER-ORACLE][FAIL]`。
- evidence-tool 单测 8/8、semantic-ledger 单测 15/15 均为 `OK`；
  普通 `tb_ooo_store_queue` 回归 1/1 PASS。

## Artifact binding and ledger boundary

- focused 16-source manifest pre/post SHA-256 均为
  `baa89689a63a464cbcad78a819ee021cf17e923687e1997d11537341bf3a9521`。
- 146-file RTL snapshot pre/post SHA-256 均为
  `665b19b3fddda5dad638d92867695e2a544c493c060ba483fe83c733b3e87cca`。
- summary SHA-256 为
  `cb6d3d9061b008cc716024202886529ebde2e18babcfec5751767f0d80cf817d`。
- V11F→V11G 唯一 semantic 状态迁移为
  `store-queue-producers` 与 `store-queue-owner-tokens` 从 GAP 到 PASS；
  总计从 8 PASS / 36 GAP 变为 10 PASS / 34 GAP。
- ledger 仍为 `status=GAP`，
  `global_no_live_reuse=SEMANTIC_COVERAGE_REQUIRED`、
  `whole_architecture=RED`、`ppa=UNPROMOTED`。

## Contract binding and remaining unknowns

- reviewer contract：
  `.github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage/subagent-contracts/v11g-store-queue-holder-final-review.json`
- reviewer contract SHA-256：
  `60ae84f5ea0a1b09a337ec6f71f2d0a284cc9f1f9e59f7a3eaca5780cc888dd5`
- 剩余 unknown 仅为合同已声明边界：不证明 upstream illegal-input
  reachability、全局 holder collision fence、whole architecture、
  system、综合、STA、power 或 PPA。
- 结论只适用于 production 四槽配置及 `GEN_W=1/4` 的本地
  legal-interface 语义；`scope_extension_request=none`。

终审只读命令已全部结束，唯一 Windows→WSL shell ownership 已归还。
