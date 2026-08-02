# V13I OooIntIssueQueue 独立终审

RV64 RTL 结论｜对象=`OooIntIssueQueue` normal compaction 与 V13I 本地证据｜周期/配置=8-entry，N 拍 Q-only select→N 沿 compaction/append→N+1 resident；200 MHz/flatten=1/share=0｜TB/EDA 观测=37 remove+5 append、独立 scan reference、backend 3/3、局部 mapped/OpenSTA PASS｜范围=PASS（仅 `APPROVED_DEVELOPMENT_CHECKPOINT`；promotion GAP）

合同范围内未发现可操作 RTL 反例。V13I 可批准为 `APPROVED_DEVELOPMENT_CHECKPOINT`，但不得提升为完整架构或 PPA promotion，`promotion_eligible=false`。

- 对目的槽 `d`，RTL 分别以 `prefix[d]==0`、`prefix[d]==1 && !remove[d+1]`、`prefix[d+1]==2 && !remove[d+2]` 选择 `d/d+1/d+2`；在 packed-age、known remove、popcount≤2 前提下互斥且完备。
- `ENTRY_STATE_W` 覆盖 PC/prediction/inst/ctrl/full ProducerId/source preg+ready/destination/FP store/imm/capability 字段，打包与解包顺序一致；resident 与 dispatch payload 在 N 沿吸收 integer/FP sticky wake，最早 N+1 发射。
- dispatch0 先占 first-free，dispatch1 在 dispatch0 fire 时占下一槽，否则占同一 first-free；`count_next=count_q-popcount(remove)+dispatch0_fire+dispatch1_fire`。
- 优先级保持 `rst || flush > kill_valid > normal`；kill survivor 同拍吸收 wake，normal compaction 未增加寄存器或流水拍。
- `[V13I-SURVIVOR-MATRIX] remove_cases=37 append_cases=5 payload/order/prefix PASS`；selector source1 负向扰动命中 `[IQ-V13I-SURVIVOR-VALID]` 和 `[IQ-V13I-SURVIVOR-PAYLOAD]` 并以非零返回结束。
- 三个 backend TB 均 PASS；当前设计 module 113/113、official 177/177、AM 61/61、DiffTest mismatch=0。
- 同配置局部 mapped cells `33,284→29,354`、area `74,917.64→66,764.88`、sequential area 不变；5 ns worst positive slack 改善 `+0.078514099 ns`，两侧 synthesis check 均 0 problems。
- CoreMark 与 Dhrystone 的 cycles/commits/CPI 相对冻结 V13H 精确零差，只能裁决 CPI-neutral。

保留 GAP：full-core mapped synthesis、full-core STA、qualified power、新完整系统事务均 NOT_RUN；局部 ideal-clock OpenSTA 不能证明全核 200 MHz。source0/source2/append 未逐路做负向变异，但 37+5 正向矩阵与逐槽完整 reference 覆盖合法状态空间。结论假设 `ENTRY_COUNT=8`、packed-age、remove mask known/subset-of-valid/popcount≤2，以及上游遵守 `IQ-KILL-NO-DISPATCH`。

合同 JSON：`.github/task-runs/2026-08-01-rv64-v13i-int-iq-survivor-map/subagent-contracts/v13i-int-iq-survivor-map-final-review-v1.json`

合同 SHA-256：`45454002f2b3e0f280d1ebc4db2f22be36ae0ffcc3830ede1cb36494ec1374e9`

置信度：RTL 等价性高；开发检查点证据中高；完整 PPA/promotion 结论不成立。
