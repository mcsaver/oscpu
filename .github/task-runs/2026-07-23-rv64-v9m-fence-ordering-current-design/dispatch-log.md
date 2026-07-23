# V9M dispatch log

## fence-evidence-review-v1

- task kind：本地 RV64 RTL/证据只读复核。
- contract JSON：`.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/subagent-contracts/fence-evidence-review-v1.json`
- contract JSON SHA-256：
  `2f0e7c5166e8334db4fb3a47eb7aa5b802803a3544cc154e8ca172823775e6cd`
- contract pipeline：`create → validate → render` PASS。
- write paths：空。
- shell ownership：派发期间由主 agent 交给该只读节点；主 agent 不并发运行 WSL 工程命令。
- status：`INCONCLUSIVE`；reviewer 正确指出 v1 未包含 `mem_idle_o`
  生产与跨模块传递链，因此该轮不得进入硬证据。
- scope extension：已冻结为 v2，不在 v1 后口头追加路径。

## fence-evidence-review-v2

- task kind：本地 RV64 RTL/证据只读复核。
- contract JSON：`.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/subagent-contracts/fence-evidence-review-v2.json`
- contract JSON SHA-256：
  `3a2a8b62b204f8b7315b16c9c1a0f2e8c9c09cac1d11448498cac926f4611f40`
- contract pipeline：`create → validate → render` PASS。
- scope extension：加入 `mem_idle_o` 在 `OooIntBackend` 的完整 owner/holder
  条件、execute/decode/core/control 传递链、MIQ/bridge station 关联、result/raw
  与 `architecture_hard_gates.py`。
- write paths：空。
- shell ownership：派发期间由主 agent 交给该只读节点；主 agent 不并发运行 WSL 工程命令。
- initial status：`GAP`；reviewer 找出 5 项可构造假绿边界：编译成功自报、额外
  `[CHECK-FAIL]`、正向日志失败诊断、旧日志重新绑定 design-id、CoreGlue→ControlPlane
  `mem_idle` 连接未被 full-core 反例覆盖。
- re-review：前述 1/3/4/5 已关闭；唯一残余是目标检查行、`errors` 与 `status` 仍为前缀/子串
  匹配。实现者随后改成 exact-line，并增加三个 validator 反例。
- current technical state：当前 RTL 功能链未发现新缺口；reviewer 明确归还 shell ownership。

## implementation closure

- canonical command：`make -C npc/rv64 check-fence-ordering`，PASS。
- focused/module/variants/unittest：2/2、109/109、2/2、12/12。
- dependent provenance refresh：9/9 canonical targets PASS。
- nine-gate architecture aggregate：GREEN；PPA UNQUALIFIED。
- ARCH_STABLE audit/verify：PASS；honest GAP，38 blockers。
- ledger：`FENCE-G1=CLOSED`，仅绑定当前 design-id。

## fence-arch-stable-review-v3

- task kind：本地 RV64 架构汇总证据只读复核。
- contract JSON：`.github/task-runs/2026-07-23-rv64-v9m-fence-ordering-current-design/subagent-contracts/fence-arch-stable-review-v3.json`
- contract JSON SHA-256：
  `e8b72460c796e474b233a2be12ecbf59998dfd6361cd8f77cdd5696f38db9723`
- contract pipeline：`create → validate → render` PASS。
- scope extension：仅新增直接读取 `arch-stable-current.json`，并保留 FENCE
  证据、ledger 与架构 validator 作为一致性对照。
- write paths：空。
- shell ownership：派发期间由主 agent 交给该只读节点；主 agent 不并发运行 WSL 工程命令。
- status：`PASS`，仅指当前 design-id 下 FENCE-G1 的证据绑定一致性。
- direct result：design-id 五侧一致；result/raw SHA 与 ledger/task-report 一致；
  FENCE-G1 八项语义检查 PASS；focused/module/variants/unittest 为
  2/2、109/109、2/2、12/12。
- claim boundary：full-core `architecture_freeze=GAP`、38 blockers，PPA
  `UNQUALIFIED`、promotion=false；未从局部 FENCE-G1 外推全核或 PPA 结论。
- scope extension：无；节点未写文件并已归还 shell ownership。
