# 派发日志

## [2026-07-15] baseline-and-contract — PASS

- owner: root
- action: 冻结 T4T proxy seed、G2 performance anchor 与完整双发射/真 OoO 架构下限。
- output: architecture/PPA contract、policy、manifest、checker、comparator。
- decision: T4T 只能 provisional；功耗与宏面积未合格时不得宣称三轴 PPA champion。

## [2026-07-15] performance-counter-audit — PASS

- owner: perf_counter_analysis
- action: 只读审计 CPI/IPC/throughput、证据绑定、PPA/Pareto 和工具 fail-open 风险。
- result: 发现并推动修复 required-evidence、raw-counter 重算、path containment、large-artifact hash、status/target 和 comparator pre-audit。

## [2026-07-15] dual-issue-structural-audit — PASS

- owner: dual_issue_structural_limits
- action: 只读分析 frontend II=3 与 single-outstanding 约束。
- result: 首选 single-outstanding elastic turnover；H1 fast hit + S_RESP skid，保留 slow-path exec context 与 AXI drop/drain。

## [2026-07-15] reservation-promotion-audit — PASS

- owner: t4s_dma_valid_arch
- action: 只读分析 memory reservation 对 lane0/raw issue 的冻结。
- result: 推荐 registered reservation Q 作为 virtual lane0 owner，复用现有 issue1 oldest-simple selector；不新增状态、PRF port、FU 或组合 bypass。

## [2026-07-15] backend-candidate-t4s — ARCHIVED_EQUIVALENT

- owner: root
- action: virtual lane0 owner + lane1-alone；完成定向 TB、102 module、177 official、59 AM、A-B-B-A-A-B benchmark、fresh synth/STA 后撤回 canonical RTL。
- result: weighted perf +0.0457025%，logic area -0.0681030%，worst slack 仍为 +0.179479554 ns，vectorless total 仍四舍五入为 0.118 W。
- decision: 两个收益轴均低于 0.1% epsilon，balanced score 100.056925 < 100.2；同源、架构与功耗门禁未闭合，作为 negative candidate 留档，不晋级。

## [2026-07-15] frontend-hit-turnover — IN_PROGRESS

- owner: dual_issue_structural_limits + root
- action: single-outstanding elastic turnover；H1 hit 直接形成响应，S_RESP 仅承载 skid/slow path，同拍响应消费与后继请求接收。
- accept: 连续 64 packet 最大 II=1，flush/invalidate/slow-path/AXI drain 合同保持，功能回归全绿且 PPA 对抗晋级。

## [2026-07-15] r3p6-measurement-anchor — PASS

- owner: root
- action: 冻结 R3.6 performance/logic-area/exact-5ns 测量锚，并明确 architecture-infeasible、nonpromotable。
- result: CoreMark `4,904,511/3,183,617`，Dhrystone `9,481,620/4,250,000`，area `1,605,803.92`，slack `+0.131591633 ns`。
- decision: 仅作工程测量锚；不能凭单 memory owner 进入 Pareto/front/canonical。

## [2026-07-15] architecture-feasible-seed-policy — PASS

- owner: r4_policy_seed + root
- action: 增加一次性从不可行 R3.6 到首个完整架构的 seed transition；首 seed 要求九门/功能全绿、每 benchmark≥0.995、slack≥+0.10ns、area≤1,766,384.312。
- result: policy/architecture 单测 `59/59 PASS`；未 qualified power 的点只能是 seed role，front/canonical/champion 均 false。
- decision: 首 seed 可豁免对不可行 anchor 的 dominance/0.999；首 seed 后立即恢复正常 dominance+0.999，第二次 seed 被拒绝。

## [2026-07-15] r4-s0-posttranslate-implementation — PASS

- owner: root
- action: 统一 final-PA PMA/PBMT 分类，传播 response/SQ/drain cacheability，修正 NC/IO、A/D、B error、cross-line D-cache alias maintenance。
- result: focused/full module/lint/style/build 全绿；四个新断言 deliberate negative `4/4 PASS`。
- decision: Boolean NC/IO 仍合并，保持 architecture RED，只作为 correctness checkpoint。

## [2026-07-15] r4-s0-ppa-verification — PASS_WITH_BLOCKERS

- owner: root + r4_ppa_tradeoff + r4_sta_hardening
- action: 三次 fixed-region counters、两次 fresh synth、结构语句可复现审计、两次 fail-closed exact-5ns STA。
- result: performance ratio `1.0`；area `1,606,423.28`（+0.03857%）；两份 slack 均 `+0.059167784 ns`，TNS/violations/loops `0/0/0`；vectorless diagnostic `0.121 W` 未资格化。
- decision: 200 MHz proxy PASS，但 +0.10ns reserve、九项架构门、同源功能/性能 promotion evidence 和 Power 全未闭合。

## [2026-07-15] r4-s0-checkpoint-decision — RETAIN_CORRECTNESS_ONLY

- owner: root
- action: 将 S0 写入 `implementation_correctness_checkpoints`，不修改 canonical 或 architecture seed。
- result: allowed claim、所有 blocker、raw-netlist serialization variance 与旧 fail-open STA archive 均机器留档。
- decision: 保留必要语义；下一刀优化原 D-cache-hit→WB/PRF 控制锥，禁止删除 classifier sideband 换时序。

## [2026-07-16] r4-p0a-distributed-wb-valid — PASS_CHECKPOINT_ONLY

- owner: root
- action: 将两路 GPR write-valid 下沉到最终 WB owner；完成 22 点矩阵、102 module、image-bound
  A-B-B-A-A-B、两轮 fresh synth 与两轮 fail-closed exact-5ns STA。
- result: 两 benchmark cycle exact；logic area `1,606,094.84`；worst slack
  `+0.103599802 ns`，TNS/violations/loops `0/0/0`；两轮 netlist byte-identical。
- decision: 保留为 timing/correctness checkpoint；九项架构门全 RED、Power unqualified，不能
  seed/front/canonical/champion。P0-B 因关键路径已移出 D-cache tag 锥而 deferred。

## [2026-07-16] r4-p0a-aggregate-hardening — PASS

- owner: root
- action: aggregate checker 对四份 synthesis pre/post manifest 的 117 个 elaborated inputs
  逐行实时重算，不再仅比较 manifest 文本。
- result: `checkpoint-audit-v2.json` PASS，SHA256
  `2847ae2e1b075ba7743cc8affb1220f185eed4e0dbe176fda0fe2aac6ba54fb8`。
- decision: v2 是 P0-A checkpoint 的 aggregate 绑定；旧 v1 仅为被加固版取代的历史输出。

## [2026-07-16] r4-s1p0-typed-memory-contract — PASS_SPEC_ONLY

- owner: s1_typed_arch_review + root
- action: 冻结 CACHED/NC/IO/RSVD、fault/attr、PMA/PBMT、owner token、MMU epoch、NC/IO
  ordering 以及 S1 single-owner/S2 dual-owner RED 边界。
- result: 5 份 design/spec Markdown 解析、链接与 whitespace checks PASS；未修改 RTL。
- decision: 只标记 `spec_frozen`；typed RTL、双 memory owner、DI-3/DI-5/OOO-3 均不得据此转绿。

## [2026-07-16] r4-s1p1-typed-leaves — PASS_LEAVES_ONLY

- owner: s1_typed_rtl + s1_leaf_review + root
- action: 新增 typed PMA/classifier；覆盖 enabled/disabled 两组完整 4×4、fail-closed、精确
  assertion negative、两种 mutation、full lint 与 Yosys check。
- result: 最终 `r4-s1p1-typed-leaves-v2` PASS；10 个 live source binding 与 evidence
  SHA 全 OK；旧 S0 checker byte-exact SHA `e197b137...c2b`。
- decision: 只接受 typed leaf truth table。bridge/backend/SQ、token/epoch 和第二 memory owner
  未实现，所有相关 architecture gates 保持 RED；失败 v1/v2 partial 全部移入 workspace `tmp/`。

## [2026-07-16] r4-ppa-tournament-baseline — PASS_PLAN_ONLY

- owner: root + p0_perf_abbaab/verfiles_semantics
- action: 在 R4-P0A semantic/timing floor 与 R3.6 performance/area anchor 上冻结下一轮
  `S1 typed -> frontend II=1 -> S2 dual memory -> architecture seed -> P/P/A independent branches`
  的执行顺序和逐轴淘汰线。
- result: policy 回归 `61/61 PASS`；Performance 候选锁定双 AGU/translation/order/banked-cache/
  tagged-completion，Power 候选锁定 shared PMP descriptor + exact isolated queries，Area/timing
  候选锁定 balanced first-match/共享 footprint；完整计划见 `ppa-r4-tournament-plan.md`。
- decision: 当前 S1 partial 不是 feasible seed，三候选不能从不同不完整设计各自宣称获胜；
  首个九门全绿 seed 之前所有 P/A/Power 数字只作诊断。

## [2026-07-16] r4-power-readiness-refresh — EXPECTED_RED

- owner: root
- action: 只读重跑 R3.6 workload-power readiness，并把 `/tmp` 输出逐字归档回 workspace `tmp/`。
- result: `qualified_for_promotion=false`，共 9 个 blocker：4 个 placeholder macro power model、
  VM_TRACE=0、无固定 power window、2 ps trace 时间基准未缩放到 5 ns、无 gate-level/映射活动
  binding、OpenSTA flow 未注入 workload activity；归档 JSON SHA256
  `a9fe8f391abe1647a0f004fe9facfa1952817ddc0dc150b6b2882f64cff55d2e`。
- decision: vectorless `0.121 W` 继续 unqualified，不参与冠军裁决；不运行 Linux 不构成阻塞，
  后续可使用固定 CoreMark/Dhrystone 区间，但真实同工艺 macro 模型仍是 final champion 外部 blocker。

## [2026-07-16] global-dse-meta-strategy-intake — PASS_INPUT_BOUND

- owner: root
- action: 将附件逐字归档为 `design-inputs/global-dse-meta-strategy-input.txt`，建立非规范伴随策略与
  第1～8节及五项优先修改的逐项 adoption matrix；不修改 hash-bound contract/policy/baseline。
- result: 原文与来源 byte-identical，SHA256
  `9729c31ed3773ae233aa88c9ca908728c0023c6f47225f2fed7614a34a418a24`；明确
  intermediate/complete、四类候选池、hard-gate-first、同 seed 三分支、`K=4` global thaw、
  worst-workload 与 RL/surrogate defer 边界。
- decision: archive membership 与 canonical promotion 分层；Power/total area 未 qualified 时只能
  建 engineering proxy，架构不完整点永不进入 Pareto/promotion。

## [2026-07-16] r4-s1p2-typed-abi-integration — PASS_FOCUSED_CHECKPOINT_ONLY

- owner: s1_typed_rtl + s1_fault_review + s1_attr_stall_coverage + root
- action: typed attr/class 原子贯通 bridge/backend/SQ/wrappers；删除 VA→target class 猜测；落实
  page>PMP>PMA fault priority、CACHED-only cache admission、NC/IO 分流、unknown-class load 对
  older nonterminal SQ blind barrier，以及完整覆盖 store-to-load forwarding bypass。
- result: typed classifier、bridge、SQ、backend、三个 wrapper focused 全绿；bridge/backend 独立复跑
  全绿；B `OKAY/SLVERR/DECERR` 的公开 attr/class 在 response stall 期间稳定；29 个相关
  `/tmp/s1-*` 文件含失败迭代和 build 已逐文件归档校验。
- decision: S1 focused 判 GREEN，但仍是 `intermediate_checkpoint`。未跑 Linux、103 项 full
  regression、benchmark、synth/STA/PPA；合同 102 与现状 103 漂移、九项架构 RED、Power
  unqualified 继续阻止 seed/front/canonical/champion。

## [2026-07-18] r4-s2-q1-mmu-epoch-owner-adoption — PASS_SOURCE_CATALOG_ONLY

- owner: root + independent reviewers
- action: 将 standalone `OooMmuEpochOwner` 纳入唯一 filelist/Makefile/spec/canonical runner，补齐
  release/assert 正例、完整 assertion negative、compile-success exact-oracle mutation、lint/style/Yosys
  与 adoption source manifest；并修复 full module 中 typed response provenance 的悬空 X。
- result: 正例 `2/2`、negative `4/4`、mutation `7/7`、fresh module aggregate `104/104`；
  `adoption-sources.sha256` 9/9 OK，adoption checker PASS，独立 source-catalog 审查无 P0/P1/P2。
- decision: Q1 只判 source-catalog adoption GREEN。leaf 尚未 live instantiate，不产生 selective squash、
  full quiet、dynamic epoch/wrap、双 memory、Linux、200 MHz 或 PPA 声明。

## [2026-07-18] r4-s2-q2-live-epoch-contract-hardening — EXPECTED_LIVE_RED

- owner: root + independent contract reviewers
- action: 冻结 mem0-only `CAPTURE→SQUASH→WAIT_QUIET→GRANT` executable manifest；v7 checker 同时覆盖
  release/`OOO_ASSERT` active source 与 elaborated generate，锁定 concrete macro/layout、exact
  width/instance/expression/payload、FENCE.I/MIQ/true memory-leaf producer、guarded epoch/ROB/irrevocable
  storage/reset-arm、set-dominant squash completion、全 writer 唯一性、任意深度 concat、unknown/system
  task actual、internal any-generate、module lexical scope、exact positive reset/clock event、唯一连续驱动、
  guarded full ancestor path 与 SQ fill epoch canonical provenance；并新增 exact non-reset path、内嵌 timing
  control/call actual、unparenthesized procedural span、unknown child/primitive driver、module lexical-only port
  direction/width、required-port critical symbols、canonical clk/rst ownership 与 runner pre/post source snapshot。
- result: v7 self-test `162/162`；release 与 `OOO_ASSERT` 各返回 `rc=1`、931 项 RED，聚合 1862 项；RED digest
  `fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592`，contract lock
  `d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa`，baseline lock
  `abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88`；completion marker 仅在全门通过后生成，
  28-path pre/post snapshot byte-identical，并绑定 self-test/readiness/rc/canonical+pre+post sources/source-check/
  summary 全部摘要。
- decision: 这是可审计 implementation gap inventory，不是 live integration 或 final freeze；structural
  future PASS 也只是 necessary-only，必须继续以 directed RTL/full regression/Linux/PPA 硬门闭合语义。
