# YSYX 项目状态总览

## 2026-07-30 RV64 V11H LoadQueue terminal-history architecture closure

- `OooLoadQueue` 的 legal-interface pre-fix 反例为 normal terminal 先于
  completion，下一拍 recovery 后观测
  `count=1/live=1/killed=1`。独立预审确认 H2：旧 RTL 将已经发生精确
  terminal 的 entry 变成永远等不到第二个 terminal 的 killed tombstone。
- production RTL 新增 `terminal_seen_q[0:3]`。normal terminal 保留
  retire residency 但关闭 issue/query/response；terminal-seen recovery
  直接 clear；重复 exact terminal 由 `[V11H-LQ-DUP-TERMINAL]` fatal
  assertion 拒绝。每个 live entry 的完整 PID knownness 由
  `[V11H-LQ-PID-KNOWN]` 直接断言。没有增加 event dedup，也没有削弱断言。
- 当前 146-file design-id 为
  `sha256:78f154580593b5a3442ed6cf5ca2159ef18779a3903a70e816f34a7e1aff481f`；
  production LQ SHA-256 为
  `4287aa7c746391d522bebcfceb481c01127d35f248da3cc025b5efdef15cf427`。
  V11H fresh Yosys instance graph 为 15 holder modules、17 instances、
  194 reachable instances，五类 canonical 产物逐字节 replay PASS。
- focused attempt-4 完成 GEN_W=1/4 × assert/release 4/4 positive PASS、
  1 个 raw-Q PID knownness assertion probe 与 31 个 compile-success
  variants 的 62 次 assertion-off 仿真；probe 命中 production marker，
  62/62 均由 stimulus-owned raw-Q oracle 拒绝。原 runner 状态永久保留
  `FAIL@semantic-ledger-unit`；独立 frozen-input checker replay 不重跑
  RTL，取得 replay builder 5/5、evidence checker 10/10、semantic ledger
  24/24 PASS。exact system-rerun schema 的缺字段/弱化反例均被拒绝。
- 语义 checker 不再把旧 full design-id 偷改为当前值。V11B–V11G 仅在
  exact RTL/include/filelist/TB closure 仍匹配时标记
  `CURRENT_SELECTED_SOURCE_AND_TB_BOUND`；V8L 降为
  `HISTORICAL_FULL_RTL_BOUND`。当前 ledger 为 11 PASS / 33 GAP / 44。
- ordinary attempt-1 因 runner 将合法 `[V8V-LQ-*] ... PASS` marker
  误判而保留 FAIL；attempt-2 的 `tb_ooo_load_queue` 与父级
  `tb_ooo_int_backend` 是旧 RTL PASS；current attempt-3 在
  `OOO_ASSERT`、GEN_W=4 下再次 PASS，PID-known 与 duplicate-terminal
  marker 均为 0，full RTL pre/post 无漂移。
- final-review v2 先以 GAP 找出 raw-Q assertion 和 system-rerun schema
  两个 blocker；versioned final-review v3 在二者闭合后给出
  `load-queue-producers` bounded APPROVE、blocker=0。
- architecture directed-suite 保持 overall RED：当前 design-id 与旧
  suite 不同，且 Makefile provenance 已更新。由于本轮确有 production
  core 语义变化，新的完整系统运行是后续 system promotion 前置条件；
  本轮未自动启动高成本 A4。PPA 保持 UNPROMOTED。
- current-source `npc-dev` 5/5 与 `agent-system` 11/11 均完成并发布；
  19-path scoped strict guard PASS。全工作树 strict 只保留共享
  `rv64-linux` evidence GAP。stored snapshot、DB-first、Markdown
  coverage 与两份 task-run 的 runtime-artifact audit 均 PASS；当前
  checker 单元 39/39 PASS。
- commit gate 为 `ai@af027d1bce085bace474b748dcd89113145f8772`；
  共享工作树有 258 个 tracked 修改、较多未跟踪证据文件和一个无关
  staged profile，未执行 stage/commit。精确文件数只记录在本轮
  post-review handoff，避免环境 e2e 自身新增 task-run 后使 retained
  memory 立即过期。
- canonical task-run：
  `.github/task-runs/2026-07-30-rv64-v11h-load-queue-producer-semantic-coverage/`。

## 2026-07-30 RV64 V11G StoreQueue resident holder 语义覆盖

- 当前 146-file RV64 RTL design-id 保持
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`；
  production `OooStoreQueue.v` 未修改，SHA-256 为
  `5a5179a0cbfa01048510cb842615b4f63e106816d06c15afdcec02a6b8c68241`。
- `+V11G_SQ_HOLDER_ONLY` 使用 stimulus-owned 四槽 raw-Q model，沿
  allocation→bind→OOO fill/request→terminal→release/flush 检查 full
  ProducerId、独立 `{kind,token,epoch}`、valid/owner-valid、
  head/tail/count 与 raw knownness。expected 不读取 DUT raw Q 或
  `snoop_*` 输出，并使用与 ROB index 不对称的 token/epoch。
- canonical attempt-1 的 assert/release × `PRODUCER_GEN_W=1/4` 正向
  4/4 PASS；二十四个 compile-success production-RTL variants 在两种
  width 下形成四十八次 `OOO_ASSERT` 关闭仿真，48/48 均由
  `[V11G-SQ-HOLDER-ORACLE][FAIL]` 拒绝。
- focused 16-source manifest 与 146-file RTL snapshot 的 pre/post
  identity 均无漂移；normal `tb_ooo_store_queue` 1/1 PASS；evidence
  tool 8/8、semantic-ledger 15/15 PASS。
- 独立预审裁决 H1，终审给出 bounded APPROVE、`blocker=0`。V11F→V11G
  仅 `store-queue-producers` 与 `store-queue-owner-tokens` 从 GAP
  晋级 PASS；semantic ledger 当前为 10 PASS / 34 GAP / 44。
- global no-live-reuse 保持 `SEMANTIC_COVERAGE_REQUIRED`，whole
  architecture 保持 RED，PPA 保持 UNPROMOTED。ARCH_STABLE 观测为
  51/53 expected GAP、V11G 新增失败 0；upstream illegal-input
  reachability、全局 holder collision fence、system、synthesis、STA
  与 power 均未闭合。
- 本轮没有 production/elaborated RTL、device model 或 simulator
  执行语义变化，也不缺 A3 原始输入、终端链或 post-hash 证据；A3
  继续保持“原始 FAIL、系统事务完成、旧 oracle 误判、
  checker-replay PASS”，不触发完整系统重跑。
- task-specific `npc-dev` 首轮因 DB 尚未保存新 V11G memory、bounded
  brief 缺独立 focus match 而 fail closed；该 blocked run 原样保留。
  将 project/NPC memory `update-stored` 后，第二轮
  `2026-07-30-store-queue-holder-semantic-revtag-v11g-2` 取得完整
  recall 与 5/5 completed，未放宽 recall 规则。
- 8-path scoped strict guard PASS；全工作树 strict guard 仅保留 shared
  `rv64-linux` missing-evidence GAP。final identity PASS，351 个 raw
  assets 已建立 index-only 索引；9 份技术 Markdown 与两份 memory
  已发布，DB-first、Markdown coverage 与 runtime-artifact audit PASS。
- commit gate 为 `ai@af027d1bce085bace474b748dcd89113145f8772`；
  共享工作树有 254 个 tracked 修改、1,688 个 untracked 文件与一个
  无关 staged profile，故未 stage/commit。
- canonical 证据入口：
  `.github/task-runs/2026-07-30-rv64-v11g-store-queue-holder-semantic-coverage/`。

## 2026-07-30 RV64 V11F integer IQ ProducerId 语义覆盖

- 当前 146-file RV64 RTL design-id 保持
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`；
  production `OooIntIssueQueue.v` 未修改，SHA-256 为
  `d8eb68b91fd971c3f8054280613c737f3cc951bf492888998e67ced94f9c218b`。
- `+V11F_INT_IQ_PRODUCER_ONLY` 使用 stimulus-owned 八槽
  `{valid, full ProducerId}` model，逐沿检查 birth、READY-low/recover
  hold、regular single/dual issue、memory pair、compaction、selective
  wrap kill、flush/reset、raw Q、full-P live mask、count 与 carriers。
  expected 不从 DUT `valid_q`、`producer_id_q` 或
  `producer_live_mask_o` 推导。
- canonical attempt-3 的 assert/release × `PRODUCER_GEN_W=1/4` 4/4
  baseline PASS；二十个 compile-success RTL variants 在两种 width 下
  形成 40 个 release 仿真，关闭 `OOO_ASSERT` 后全部由
  `[V11F-INT-IQ-ORACLE][FAIL]` 拒绝。三项 PID-X 变体分别覆盖 lane0、
  lane1 与 resident/compaction raw identity knownness。
- focused 16-source pre/post manifest 与 146-file RTL pre/post snapshot
  均无漂移；normal `tb_ooo_int_issue_queue` regression PASS；evidence
  tool 8/8 与 semantic ledger tests 合计 22/22 PASS。
- 独立终审给出 bounded APPROVE、`blocker=0`，仅将
  `integer-iq-producers` 从 GAP 晋级 PASS；semantic ledger 从
  7 PASS / 37 GAP 变为 8 PASS / 36 GAP。上游 kill/flush
  transaction barrier 自然可达性仍需 dispatch/backend 集成证据。
- global no-live-reuse 保持 `SEMANTIC_COVERAGE_REQUIRED`，whole
  architecture 保持 RED，PPA 保持 UNPROMOTED；system、synthesis、STA
  与 power 未运行。本轮没有 production/elaborated RTL、device model 或
  simulator 语义变化，A3 保持“原始 FAIL、系统事务完成、旧 oracle
  误判、checker-replay PASS”，不触发完整系统重跑。
- task-specific `npc-dev`
  `2026-07-30-integer-iq-producer-semantic-revtag-v11f` 为 completed 5/5；
  8-path scoped strict guard PASS。全工作树 strict guard 仅因 shared
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence 而保持
  GAP。ARCH_STABLE 为 51/53 expected GAP、V11F 新增失败 0；873 个 raw
  evidence assets 已索引，final identity PASS。9 份技术 Markdown 与
  project/NPC memory 已存储；snapshot-stored、DB-first、Markdown
  coverage 与 runtime-artifact audit 均 PASS。
- commit gate 为 `ai@af027d1bce085bace474b748dcd89113145f8772`；
  共享工作树有 253 个 tracked 修改、1,639 个 untracked 文件与一个无关
  staged profile，故未 stage/commit。
- canonical 证据入口：
  `.github/task-runs/2026-07-30-rv64-v11f-int-iq-producer-semantic-coverage/`。

## 2026-07-30 RV64 V11E ROB slot generation 语义覆盖

- 当前 146-file RV64 RTL design-id 保持
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`；
  production `OooRob.v` 未修改，SHA-256 为
  `bbb68a2a819bb8bfb005adfb8f2659e8037ea6280d9dc338415395aeab62c561`。
- V11E 以沿前独立 generation/valid/done/head/tail/count/recovery model
  每沿核对全部 16 个 slot，以及 lane0 actual、lane1 actual、lane1 pair
  candidate、head/commit/walk carrier 和 current/completion/resolve exact
  query。expected 只由 stimulus 与 model 状态产生，不复用 DUT
  generation 或 ProducerId。
- canonical attempt-3 的 `PRODUCER_GEN_W=1/4 × assert/release` 4/4
  baseline PASS；17 个 compile-success RTL variants 在两种 generation
  width 下形成 34 个 release 仿真，关闭 `OOO_ASSERT` 后仍全部由
  `[V11E-SLOT-GEN-ORACLE][FAIL]` 拒绝。attempt-1 的 walk zero-carrier
  与 attempt-2 的 recovery reset-to-ones 假绿原样保留；attempt-3 以
  generation 0/1 混合 recovery pair 同时关闭两类可判别性缺口。
- 独立终审给出 bounded APPROVE、`blocker=0`，只把
  `rob-slot-generation` 从 GAP 晋级 PASS；semantic ledger 当前为
  7 PASS / 37 GAP / 44。有限 generation 回绕仍依赖外部 holder
  collision fence，不能外推为 global no-live-reuse 或 whole
  architecture PASS。
- normal `tb_ooo_rob` regression PASS；evidence tool 9/9 与 ledger
  13/13 原始日志合计 22/22 PASS；ARCH_STABLE 为 51/53 expected GAP，
  `v11e_new_failures=0`。终审指出的 active spec 页首 v11c/5/39 旧值已
  同步为 v11e/7/37；该 documentation-only 变化由独立 publication
  receipt 记录，attempt-3 原始 summary/source hash 不重写，builder
  对 live 文档漂移继续 fail closed。
- task-specific `npc-dev` 的终审后 current-source run
  `2026-07-30-rob-slot-generation-final` 为 completed 5/5；7-path
  scoped strict guard PASS。全工作树 strict guard 仍只因共享
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence 而保持
  GAP。V11E 609 个 raw evidence assets 已索引，8 份技术 Markdown 与
  project/NPC memory 已存储；snapshot-stored、DB-first、Markdown
  coverage 与 runtime-artifact audit 均 PASS。本轮无
  production/elaboration/device-model/simulator 语义变化，
  A3 继续保持“原始 FAIL、系统事务完成、旧 oracle 误判、checker-replay
  PASS”，不触发完整系统重跑。
- commit gate 为 `ai@af027d1bce085bace474b748dcd89113145f8772`；
  共享工作树有 251 个 tracked 修改、1,611 个 untracked 文件与一个无关
  staged profile，故未 stage/commit，避免混入 mixed-origin provenance。
  证据入口：
  `.github/task-runs/2026-07-30-rv64-v11e-rob-slot-generation-semantic-coverage/`。

## 2026-07-30 RV64 V11D memory tracker cursor 语义覆盖

- 当前 146-file RV64 RTL design-id 保持
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`；
  production `OooMemOwnerTracker.v` 未修改，SHA-256 仍为
  `fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`。
- V11D 用独立沿前 model 闭合 `tracker-next-token-cursor`：lane0 从 cursor
  取第一 FREE，lane1 只在合法 lane0 claim 后排除其 token，atomic pair
  单 credit 零出生，同沿 exact/bulk death 不参与 scan，cursor 按
  lane1 fire、lane0 fire、零 fire 的优先级推进或保持，并覆盖 4/32-token
  自然回绕。
- canonical `cursor-attempt-2` 为 4/32-token × assert/release 4/4 PASS；
  9 个 32-token、`OOO_ASSERT` 关闭配置的 compile-success RTL variants
  9/9 被拒绝。expected token/ready/fire/live/PID/cursor 不使用 DUT token
  反喂；直接 `dut.next_token_q` 比较是第二个 oracle。attempt-1 因
  invalid-lane token 输出过约束而保留但不晋级。
- V11C compatibility、V11D evidence 与 semantic ledger 定向复核
  24/24 PASS。ledger 仅把 cursor 从 GAP 晋级，当前为
  6 PASS / 38 GAP / 44，整体仍 `GAP`。独立终审给出 bounded
  `APPROVE`、blocker=0，并保留 valid-qualified 而非 fire-qualified
  token 合同边界。
- ARCH_STABLE current-workspace 观测为 51/53；V11D 接线没有新增失败，
  其余两项仍是 V11C 已记录的 V9R identity/status 漂移与旧 full-core
  candidate dynamic-inventory 缺口，不能宣称全核、ARCH_STABLE 或 PPA
  PASS。本轮没有 production/elaboration/device-model/simulator 语义变化，
  因而不触发 A3 完整系统重跑；A3 原始 FAIL 与 checker-replay 分类保持不变。
- task-specific `npc-dev`
  `2026-07-30-memory-tracker-cursor-semantic-revtag-v11d` 为 completed
  5/5；10-path scoped strict guard PASS。全工作树 strict guard 仅因共享
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence 而 FAIL，
  保持范围外 GAP。V11D 141 个 raw evidence assets 已索引，ARCH_STABLE
  51/53 原始日志已保存；8 份技术 Markdown 与两份 memory 已存储，
  snapshot-stored、DB-first、Markdown coverage 与 runtime-artifact audit
  均 PASS；final identity helper 重算的 146-file RTL binding 与 canonical
  attempt-2 一致。共享工作树有 249 个 tracked 修改、1,564 个 untracked
  文件及一个无关 staged profile，故 V11D 未 stage/commit，避免混入
  mixed-origin provenance。证据入口：
  `.github/task-runs/2026-07-30-rv64-v11d-memory-tracker-cursor-semantic-coverage/`。

## 2026-07-29 RV64 V11C memory tracker 语义覆盖

- 当前 146-file RV64 RTL design-id 保持
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`；
  production `OooMemOwnerTracker.v` SHA-256 仍为
  `fd7e0a1bcdd1fd12f35b07bb655db67a512c9a30c3ca0aae6bd5a41903f889c8`，
  本轮没有修改综合网表语义。
- 预审确认合法二态输入下未发现 tracker map/live-set RTL 反例，但旧 TB
  不直接检查 `live_mask_o[token]`，也没有用不同 PID 隔离 dying-token
  same-edge no-reuse，V8L 的 9 个 mutation 又不针对 tracker，因此原 3/44
  ledger 保持 GAP 是正确的。
- 新 TB 使用独立 expected live/PID/kind/epoch 数组逐沿核对 birth、hold、
  exact death、STORE bulk death、满表同沿不复用与下一周期复用；验证专用
  `OooMemOwnerTrackerSemanticChecker` 明确拒绝 allocation tuple、
  release mask、live map 与 live set 的 X 状态，不进入 production RTL。
- canonical attempt-2 为 assert/release 2/2 PASS、X-known negative 4/4
  精确拒绝、9/9 compile-success RTL variant 动态拒绝。9 个 variant 的
  vvp 均生成，编译时同时关闭 checker 与 `OOO_ASSERT`，所以 rejection
  来自 TB 独立 scoreboard。attempt-1 因不必要的 Makefile source coupling
  后续漂移而保留原始 PASS、但不晋级。
- 独立 final reviewer 给出 bounded `APPROVE`、blocker=0；语义 ledger
  现为 5 PASS / 39 GAP / 44，新增 PASS 仅
  `memory-tracker-producer-map` 与 `memory-tracker-live-set`。
  `tracker-next-token-cursor`、生产尺寸特有扫描/公平性、其它 holder、
  whole architecture、系统重放与 PPA 均未闭合。
- V11C evidence tool、unit test 与 runner 已加入 ARCH_STABLE workflow
  exact binding；verification-only checker 保持由 `test_sources` 精确绑定。
  该更新会让未重绑的 full-core
  candidate 继续 fail closed，不把局部 tracker PASS 外推为架构冻结。
  定向 Python 复核 16/16 PASS；ARCH_STABLE 53 项自检为 51/53，V11C
  fixture 无新增失败，剩余项仅为既有 V9R identity/status 漂移与旧
  full-core candidate dynamic-inventory 重绑缺口。
  task-specific `npc-dev` 5/5 completed 且 DB publication 可召回；
  V11C 12-path scoped strict guard PASS。全工作树 strict guard 的
  `agent-system`、`rv64-systemd-contract`、`npc-dev` PASS，唯一
  `rv64-linux` 缺证据来自共享 `Linux/scripts/check-ubuntu-rootfs.sh`，
  保持范围外 GAP。V11C 165 个 raw evidence asset 已索引，8 份 task-run
  Markdown 已同步；snapshot-stored、DB-first 与全局 artifact audit PASS。
  A3 的 production/elaboration/device-model/simulator 语义未变化，不触发完整
  rootfs 重跑。证据入口：
  `.github/task-runs/2026-07-29-rv64-v11c-memory-tracker-semantic-coverage/`。

## 2026-07-29 RV64 V11B ProducerId holder 语义覆盖

- 当前 146-file RV64 RTL design-id 为
  `sha256:b27ac45028e2b1261a93463b030e6f7953dfc3b9a071ee83bea1a2b11234c375`。
  V11A product graph 已重新绑定：15 个 holder module、17 个 exact
  instance path、194 个 reachable user-module instance；两个 MIQ 与两个
  AXI bridge 路径不合并。
- 新的 fail-closed ledger 将 44 个语义单元展开成 50 条 unit×instance
  binding。当前 candidate=34、no-candidate=10、ledger-only=0；只有
  `terminal-output0-token`、`terminal-output1-token`、
  `terminal-pending-set` 三项为 current semantic PASS，其余 41 项保持
  GAP。字段 census 与 instance graph PASS 均不再被误写成 semantic
  completion。
- `OooMemOwnerTerminalCollector` 只在 assertion 区新增 pending、valid
  ingress、tracker truth 与 output tuple 的二态性检查；release 功能逻辑未改，
  duplicate/same-edge/owner/hold/conservation 断言未删除或放宽。TB 新增
  output0/output1 非对称 turnover/hold 与 valid ingress unknown negative，
  raw dequeue fire 直接计数，不使用 seen/reported 去重。
- terminal collector attempt-3 为 assert/release 2/2、unknown negative
  rejected、3/3 compile-success RTL mutation rejected、12 ingress + 2
  tracker-free lane contract PASS，且 146-file RTL pre/post binding 相同。
  attempt-1/2 原始失败保留；currentness attempt-21 的 10 项
  `semantic_evidence:GAP` 也保持 FAIL，不被新账本覆盖。
- 独立 reviewer 批准 collector 3-unit bounded PASS，并指出 closure
  evidence 可被 policy 改绑无关单实例 unit 的工具反例。checker 已新增
  exact collector unit-set 约束及改绑 `pending-system-producer` 的负向
  单测；修订后 semantic/lane tests 16/16 PASS，3 PASS / 41 GAP 不变。
- V8L lifecycle 重新绑定当前设计并保留 5 个 marker、9/9 mutation
  rejection；V9R retry C0 为 2/2 baseline、3/3 mutation rejection。
  `arch_stable_freeze.py` 已把 semantic checker、lane checker、policy、
  collector evidence runner/builder/mutator 与对应 tests 纳入 workflow
  exact binding；旧 closed-debt/full-core evidence 因 source identity
  未整体重绑继续 fail closed。
- 本轮 assertion-only production source 变化不改变 release profile 的
  product 功能语义，不满足 A3 完整 rootfs 重跑条件。global no-live-reuse
  与 whole architecture 保持 RED/GAP，PPA 保持
  `UNPROMOTED/UNQUALIFIED`。task-specific `npc-dev` 为 5/5 completed；
  strict guard 的 agent-system/systemd/npc-dev PASS，唯一剩余 FAIL 是
  本轮范围外 `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux`
  evidence，按 mixed-origin guard GAP 保留。长期 goal 继续 active。证据入口：
  `.github/task-runs/2026-07-29-rv64-v11b-producer-holder-semantic-coverage/`。

## 2026-07-29 RV64 V11A ProducerId holder elaborated instance graph

- 当前 product `NpcTop`、127-file Yosys source list 与 design-id
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`
  已绑定。fresh elaboration 观察 194 个 reachable user-module instances、
  15 个 holder-bearing modules 与 17 条 exact holder paths；
  `OooMemInflightQueue`、`OooMemAxiBridge` 均保留 2 个物理实例。
- V11A 证据升级为 result/receipt/canonical-full-json/script/log 五件套。
  receipt 与 reachable graph 直接从完整 Yosys JSON 重算；canonicalizer
  只规范化 map key 内进程局部 `$0x<hex>:` token，碰撞 fail closed，
  values 和其它 keys 不变。五件套 SHA-256 分别为
  `87b5a1fb…9ed06`、`dc483c6d…d4c71`、`464c04dc…09416`、
  `be9ba9f9…7890`、`3869b0fe…ddde`。
- 定向验证为 instance/runner 23/23、census 15/15、task-status PASS、
  fresh byte-identity PASS、ARCH_STABLE 50/50。Makefile 变化使
  `STORE-BRESP-G1` 的 owner-residency provenance 先 fail closed；补跑 V9N
  后 currentness 为 16 entries / 38 artifacts / 32 semantic checks /
  0 failures，postflight 保持 `production_rtl_unchanged=true`。
- 独立 reviewer v1/v2 两轮反例已由完整 JSON、canonical path、fresh
  predecessor、原始 ARCH_STABLE log 和动态 stale-PASS fixtures 关闭；
  v3 给出 `APPROVED_FOR_CURRENT_SCOPE`。本轮没有修改
  `npc/rv64/vsrc/**`。
- DB-first memory 已发布；task-specific `npc-dev`
  `.github/task-runs/2026-07-29-producerid-holder-revtag-v11a/` 为 5/5
  completed，12-path scoped strict guard PASS。更宽 focus 的首次 run
  保持 blocked，不因节点 5/5 被追认。全工作树 guard 仅保留本轮范围外
  `Linux/scripts/check-ubuntu-rootfs.sh` 缺 `rv64-linux` evidence 的全局
  GAP。
- 该 PASS 只闭合 holder instance multiplicity：
  `semantic_complete=false`、
  `global_no_live_reuse=SEMANTIC_COVERAGE_REQUIRED`、whole architecture
  `RED`、PPA `UNPROMOTED/UNQUALIFIED`；长期 RV64 OoO/PPA goal 继续。

## 2026-07-29 RV64core interactive datasheet Rev C refresh

- `docs/rv64core/study/index.html` 已按当前 product RTL 配置重建为 Rev. C。产品真源 `npc/rv64/configs/product-rtl-defaults.mk` 与 `define.v` fallback 均启用 `OOO_CSR_QUEUE_HEAD=1`：合法非 FP head0 CSR 走 ROB queue-head，lane1/FP CSR 与非 CSR SYSTEM/trap 保持 pending full-drain；本轮未修改 production RTL。
- 新增 `tools/generate_elaboration_xml.sh`，分别生成 production `NpcTop` 与带 `OOO_ASSERT` 的 `NpcSimTop` XML；builder 对 Makefile、product config、filelist 和全部 HDL 输入执行 mtime freshness gate，旧 XML 负向测试被拒绝且没有生成输出。最终 NpcTop XML SHA-256 为 `6cf2f322655e8a49cae0a57aa58bcbb25ba432a6e7804809d985c32057829ead`。
- 单文件 HTML 为 1,066,834 bytes，SHA-256 `73e6975aa440160c61531ce4a3cea236457d58ac2e7592e2ba0a5f8e63752002`，source fingerprint `e7ee837ab46b329793bc53600b3809e2617649667f825ab79b36af71f4200add`。静态 inventory 为 150 files、136 modules、195 elaborated instances、9 transactions、38 WaveDrom、58 primary phases、2 sidePaths、240 data fields、975 self-check answers、1218 sequential targets、0 external resources。
- 独立 HTML reviewer 发现并关闭一项 P1：`serial_flush_q` 侧支路已从 C1 apply 模块移回 C0 `CsrFile`，审计器新增 parent-module 负向门。最终 reviewer closure 为 PASS；浏览器动态布局、RTL testbench、综合、STA 与 PPA 本轮均未执行，不从静态文档审计外推。
- `docs/rv64core/study` scoped strict guard 为 PASS 且不触发 e2e profile。全工作树 strict guard 因大量既有/并发变更要求 `rv64-linux` 与 `npc-dev` 新证据而 FAIL；该全局 GAP 不属于本轮只改本地教学文档的范围，不能改写为 RTL 或系统验证 PASS。

## 2026-07-29 RV64 V9R current-source evidence closure

- 当前 RV64 design-id 保持 `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。`OooIntBackend.v` 与 `OooMemAxiBridge.v` production SHA-256 在 current-source replay 前后不变；V9R SQ-query retry C0 baseline 2/2 PASS，bank0/bank1/bridge 三个 compile-success RTL 负向版本分别由 `@18/@39/@24` raw assertion 拒绝。
- V9O evidence-index 为 167/167 PASS，verification-id 为 `sha256:5e8107e641f459131fc86220a84ef206870ebc773cc6931ecc65921d8b1c4a92`。16 个 CLOSED debt 当前绑定 38 个 artifact 和 32 个 canonical semantic check，failures=0。
- `SERIALIZE-G1` publisher/currentness 已改为 schema-aware exact tuple：candidate、independent contract、review report 的 kind/path/order/fixed SHA-256 必须逐项相等，missing/extra/remapped evidence 均在 ledger hash refresh 前 fail closed。泛化的非 JSON 例外不能绕过该 tuple identity。
- postflight 在开始校验时先发布 `GAP validation_not_completed`，仅在 architecture currentness 48/48、historical backfill 4/4、task-local workflow 20/20、V9O index 与 SERIALIZE verifier 的日志、返回码、测试数和终端 marker 全部通过后重新发布 PASS。v1 reviewer 准确发现旧 48-test rc=1、缺少 task-local receipt 和 bridge TB 合同；修复后的隔离 v2 reviewer 给出 `APPROVED_FOR_CURRENT_SCOPE`。
- A3 原始 published state 仍为 `FAIL rc=1`；其 execution/DUT terminal/binding/raw input/RTL assertion 为 `COMPLETE/COMPLETE/NO_DRIFT/VALID/CLEAN`，旧 dmesg oracle 把 `printk: debug:` 误判。frozen-input checker replay 为 PASS 且正向接受该行、负向拒绝真正 `BUG:`；没有修改 A3 历史状态，也没有触发 production/elaboration/device-model/simulator-semantics/required-input 的完整重跑条件。
- historical backfill 当前 `VD0=0, VD1=0, selected=NONE`，但 full architecture freeze 仍有 33 个 inventory/census/proof-depth blocker；因此 `ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`、promotion=false。当前 PASS 只闭合 source/evidence workflow 子范围。

## 2026-07-29 RV64 queue-head CSR stop-owner historical VD3

- `HIST-SER-QH-STOP-HOLD-DROP` 已由 VD1 提升为限域 VD3。根因从旧的
  “单一 sequencer hold + ordinary drain”修正为双合同：
  `OooStopPendingSequencer` 保存 queue-head CSR inflight stop state，
  `OooFrontendRunGate` 把同一 inflight owner 映射为
  `orphan=0/busy=1/can_run=0`。当前 topology 要求 ROB empty 才能
  backend drained，所以实测 `ordinary_drain_root=0`，combined negative
  的 stop drop 来自 orphan cleanup。
- current、drop-stop-hold、drop-RunGate-owner、historical-pre-T3U
  四种可编译语义均跑 assertion on/off，`8/8 compile-success`。current 与
  hold-only 为 zero gap/drop/run/overlap；drop-RunGate-owner 得到
  `gap=2, run=2, real lane1 overlap=1`；combined assertion-off 得到
  `gap=1, drop=1, run=2, real lane1 overlap=1`，assertion-on 保留并触发
  T3U/V9X 既有断言。
- raw scoreboard 由真实 `head0_csr_dispatch_fire`、inflight、RunGate 与
  lane1 pending-system capture 驱动，不 force owner，也不做事件去重；
  current/hold-only 均观察 `hold_cycles=6, C0=2, C1=2, C2_quiet=2`。
  runner/oracle 单测 7/7、重放 summary/log/normalized VVP identity 稳定，
  V9O 与 standalone assertion on/off PASS，module aggregate 113/113 PASS。
- 独立 reviewer 合同 SHA-256 为
  `f585e77a3b99d950897d91c527f1c542cb5008445c0eaf26ad1ebce9ca693988`，
  结论为 bounded VD3 PASS。reviewer 指出的 BNE “competing clear”注释已
  修正，并对最终 TB 重新完成 8-case replay 与 113/113 aggregate。
- ledger 审计为 `VD0×0, VD1×0, VD3×3, VD4×2`，
  `selected_id=NONE, status=PASS`，只表示 historical backfill
  `ELIGIBLE_FOR_REVIEW`；arch-stable 仍受独立 currentness/debt 条目约束，
  `PPA=UNQUALIFIED`、promotion=false。hold-only bounded survival 不是
  production 删除、综合、STA 或 PPA 等价证据。
- production `OooStopPendingSequencer.v` 与 `OooFrontendRunGate.v` 未改，
  146-file design-id 保持
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。
  本轮不改变 production/elaborated system RTL、device model 或 simulator
  语义，也不缺 A3 terminal/post-hash，因此 A3 原始 FAIL 保持且无需完整重跑。
- task-specific `npc-dev` run
  `2026-07-29-rv64-queue-head-stop-owner-historical` completed 5/5，7 个
  evidence asset 已索引；20 条本轮路径的 scoped strict guard PASS。
  DB-first 的两份本轮 memory 已无 hash mismatch；全局 audit 仅剩 8 个既有
  历史 task-run `missing_backup`，保持显式环境 GAP。
- 该单项完成不代表长期 RV64 OoO/PPA goal 完成。证据入口：
  `.github/task-runs/2026-07-29-rv64-hist-ser-qh-stop-hold-drop/`。

## 2026-07-29 RV64 queue-head younger-store historical VD3

- `HIST-SER-QH-YOUNGER-STORE-CYCLE` 已由 VD1 提升为限域 VD3。产品 glue
  路径直接观察 3 个 committed 与 2 个 selectively killed queue-head CSR
  transaction，均为 `birth=1, lane1_fire=0`；因此 backend CSR+younger
  STORE 双派发只作为历史 root-cone 判别输入，不代表当前 frontend 可达。
- 三种可编译语义在相同原始计数器输入上完成 assertion-on/off 六组对照：
  current owner guard 2/2 PASS；历史 transport-idle fixed 2/2 在
  `root_window=1` 产生唯一 C0/C1、C2 无重复且 physical write=0；恢复历史
  `mem_idle && mem_retire_quiet` 的 cycle 版本 2/2 在
  `root_window=4, mem_idle=1, mem_retire_quiet=0, hold=1, SQ=1,
  owner=1` 被专用 oracle 拒绝。6/6 均编译成功，不依赖 assertion-only
  行为，也未用 sticky/去重掩盖重复 terminal。
- 收尾重放曾因 Icarus VVP 内部 allocator-derived 符号地址导致 raw image
  SHA 漂移，ledger 正确 fail-closed。runner v2 现在保留每次 raw receipt，
  ledger-bound summary 使用地址归一化后的 elaboration SHA；2/2 正负向
  单测与连续两次六 case replay 的字节相等检查均 PASS。
- production `OooIntBackend.v` 前后 SHA-256 保持
  `49ec3d7e…cca5a`；146-file design-id 仍为
  `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`。
  `tb_ooo_int_backend` PASS，ledger audit `valid=true/errors=[]`，定向单测
  4/4 PASS。
- 独立 reviewer v3/v4 均裁决为 `APPROVED_FOR_BOUNDED_VD3`；v4 额外确认
  normalized VVP SHA 未替代 RTL source、compile log、专用 oracle 或最终
  raw image receipt。两轮共同保留 backend
  C1 为 TB 注入、两个版本只是 root-cone reconstruction、T3U 仅为诊断失败、
  四拍观测不是无限期形式证明，以及 normalizer 单测不是未来所有 VVP 语法
  的完备证明等边界。整体账本现在为
  `VD4×2, VD3×2, VD1×1`；唯一 blocker 与下一选择是
  `HIST-SER-QH-STOP-HOLD-DROP`。
- 本轮没有 production core、实际 elaborated RTL 或 simulator/device
  执行语义变化，也不缺 A3 原始输入/终端/post-hash，因此不触发完整 A3
  重跑。A3 原始 FAIL 保持不变，仍定义为“系统 transaction 完成、旧
  oracle 误判”。
- 可发现/可执行闭环已重放：non-history bounded brief 独立命中
  `rv64-historical-defect-backfill-loop`；task-specific `npc-dev`
  completed 5/5；17 路径 scoped strict guard PASS。DB-first 当前
  memory 没有 missing/mismatch；全局 rc=1 仅剩 183 个本轮范围外的历史
  task-run live-content drift，保持显式 workflow GAP/豁免。
- 该单项完成不授予 architecture freeze 或 PPA promotion；
  `ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`，长期 RV64 OoO/PPA goal
  继续 active。证据入口：
  `.github/task-runs/2026-07-29-rv64-hist-ser-qh-younger-store-cycle/`。

## 2026-07-28 RV64 V10G queue-head serialization currentness

- 当前 product-default RV64 design-id 为 `sha256:04c5458ff274b7b30e0629fc20ccef4ffa958dee3b80595ee4b46faf17a73897`，产品配置固定 `OOO_CSR_QUEUE_HEAD=1` 与 holder assertion=1。合法非 FP lane0/head0 CSR 使用 queue-head retirement；lane1/FP CSR、其余 SYSTEM、architectural trap 与 simulation exit 保留 pending/full-drain owner。
- queue-head CSR assertion/release C0/C1/C2 均 PASS；每种配置观察 3 个 committed 与 2 个 killed transaction。两份 compile-success C2 RTL 版本均被动态拒绝。SYSTEM product-default 为 3/3 baseline 与 14/14 compile-success RTL version；current replay 为 26/26、module 113/113、official 177/177、AM 59/59、DiffTest mismatch 0、architecture 9/9 GREEN。
- 隔离 final reviewer v2/v3 均给出 `APPROVED_FOR_CURRENT_SCOPE`；v3 额外核验 historical depth、9/9 checker replay、XRET holder-onehot、4 份 cohort contract、V9O 167/167 与 A3/A4 状态边界，未发现当前范围可复现 false-green。`SERIALIZE-G1` 仅对 Phase1 split-domain CLOSED；Phase2–5、whole-core holder census、正式 freeze-input inventory 与 PPA promotion 均未关闭。
- A3 原始 published state 保持 FAIL；其 execution/DUT terminal/binding/raw artifact/RTL assertion 为 `COMPLETE/COMPLETE/NO_DRIFT/VALID/CLEAN`，旧 dmesg oracle 为 INVALID。A4 保持 TERM/FAIL，不作为 PASS。当前没有 production/elaborated RTL、device model 或 simulator semantics 变化，因此不需要完整系统重跑。
- historical-defect backfill 已成为 freeze gate。当前 5 项中 VD4×2、VD3×1、VD1×2；两个 VD1 会阻止 architecture freeze，选择 `HIST-SER-QH-YOUNGER-STORE-CYCLE` 为下一项。
- checker identity 维护从冻结日志/RTL-version summary 重放 9 个 closed-debt checker，9/9 PASS 且输入前后哈希不变；XRET 8 个 RTL version + 2 个 observer probe 全部编译成功并被拒绝；V9O index 167/167、arch-stable 单测 48/48。当前 audit 仅保留 32 个真实边界 blocker，`ARCH_STABLE=GAP`、`PPA=UNQUALIFIED`、promotion=false。
- AI 环境已增加通用 `rv64-historical-defect-backfill-loop`；非历史 bounded brief 可独立命中蓝图。`npc-dev` 5/5、`agent-system` 11/11 与双 profile strict guard 均 PASS；最初含 `v10g` 的无独立 focus task-run 保持 blocked，不改写为完成。

## 2026-07-28 RV64 A3 checker replay V10F

- A3 原始状态保持
  `FAIL rc=1 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`；
  本轮未改写历史 run。冻结事务完成 5,071,521,696 cycles、
  1,223,536,213 commits；strict-done、poweroff-begin、kernel power-down、
  syscon poweroff、`GOOD TRAP`、system-reset clean exit 在 SHA-bound raw
  guest console 中各一次且有序，RTL assertion 文件为空，设计/仿真器/配置/
  启动产物前后哈希无漂移。
- 从 A3 rootfs 只读提取的实际 strict checker SHA-256 为
  `83b6a5384bc92a0b6c4977832a5e882c06684de554a8a09e0391a7acff053f9a`，
  与 A3 `strict_checker_sha256` 完全一致。旧未限定 `BUG:` 正则在冻结
  console 中只命中两条 `printk: debug:`；当前限定 token 的正则命中 0
  条，3/3 定向单测同时证明接受 benign debug 文本并拒绝真实 `BUG:`。
- canonical V2 replay 为 PASS，独立合同审查给出
  `APPROVED_NOT_PROMOTION_ELIGIBLE`。A3 因而定义为
  `SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`，但原始
  strict 16/17、唯一 `dmesg-no-critical` FAIL 与 rc=1 全部保留。A4
  保持 `FAIL rc=143 ... signal=TERM`，不是 PASS 证据。
- 四项完整重跑触发条件均未成立：production core RTL 语义、实际
  elaborated RTL、device/simulator 执行语义均未变化，A3 原始输入、终端链
  和 post-hash 证据齐全。reviewer 记录的低风险工具债务是未来对 A3/A4
  generated filename set 做双向相等检查；不追改已批准 V2。
- checker/transaction-evidence 的七个精确脚本、单测与 fixture 路径在
  strict guard 中只路由到 `rv64-systemd-contract`；`Linux/` 的其它变更继续
  路由到 `rv64-linux`。该 exact-path 规则已由 agent-system 自检约束，
  checker 两个实际 changed paths 的 scoped strict guard 为 PASS，不替代
  production RTL、rootfs、device model 或 simulator 语义变化所需的完整验证。
- task-specific `rv64-systemd-contract` 与 `agent-system` run 均 completed；
  后者 11/11 节点 PASS。本轮八个实现/说明路径的 strict guard 精确要求并
  通过这两个 profile。全 dirty worktree guard 仍因既有
  `check-ubuntu-rootfs.sh` 与 NPC/RTL/PPA/testbench 变化缺
  `rv64-linux`、`npc-dev` evidence 而 FAIL；该结果作为 mixed-origin
  范围豁免原样保留，不被写成 PASS，也不触发本 checker-only 切片的无关长跑。
- 本切片只关闭 checker oracle 分类；`SERIALIZE-G1` 保持 OPEN，
  architecture freeze 保持 GAP，PPA 保持 UNQUALIFIED，长期 RV64 OoO/PPA
  goal 继续 active。证据入口：
  `.github/task-runs/2026-07-28-rv64-v10f-a3-checker-replay-v2/`。

## 2026-07-28 RV64 Core 交互式 Datasheet

- 新增单文件离线入口 `docs/rv64core/study/index.html`，以半导体 datasheet 的
  General Description、Features、Quick Facts、Functional Block Diagram、Interfaces、
  Timing、Source Evidence 与 Revision History 结构组织当前 RV64 Core；没有复制厂商
  商标或专有版式。
- 交互数据绑定当前讲义与 `NpcTop` elaboration：150 个 `vsrc` 文件、136 个 module
  定义、195 个生产实例、8 条关键 transaction 和 37 个 WaveDrom。默认从
  `NpcTop.u_core : NpcCoreTop` 进入，也可切到 SoC 根；实例树明确显示
  `instance_name : ModuleType`，支持父/子钻取、面包屑、hash deep-link、浏览器历史、
  全局搜索、源码反向索引、键盘导航、移动侧栏和打印布局。
- 实例层次与 transaction 拓扑严格分开：树边表示例化/包含；transaction phase 是
  自上而下的 module-definition/data flow，先进入源码定义页，再从完整反向索引选择
  lane0/lane1 等精确实例，禁止按 module 类型猜实例。8 条 transaction 共 51 个主阶段、
  1 条 owner-lifetime sidePath 和 208 个 Data In/State/Data Out/Guard 字段。无模块
  专属 WaveDrom 时明确显示 `NO MODULE-SPECIFIC TIMING`，不借用无关波形。
- 生成器 `build_interactive_datasheet.py` 将 CSS、JavaScript、payload、WaveDrom
  3.6.2 runtime/skin 与 MIT notice 全部内嵌；最新产物 1054123 bytes，
  `source_sha256=0da5f044d36a50580d0fa3943f2dd4e5b455743811fee8b6310e5cc6476809f8`。
  `audit_interactive_datasheet.py` 校验层次 parent/child 互反、计数、transaction/timing
  引用、固定 datasheet 章节、深链接 marker、无外部资源和旧错误实现 forbidden marker；
  当前 975 个 Self-check answer slots、1218 个 sequential targets、
  `external_resources=0`、PASS。原讲义 150/150 覆盖门与 JavaScript/Python 语法门
  同样 PASS。
- 用户截图暴露的两项视觉缺陷已从源头关闭：9 章 71 个 WaveDrom `"wave"` 字段把
  重复显式 `0`/`1` 改为保持符号 `.`，字符数和周期位置不变；transaction phase 从
  固定宽横排、独立箭头/绝对定位标签改为全宽纵向有序列表，handoff 文本和四类数据
  位于所属卡片内部。Features、lead-grid、callout 使用 container-adaptive grid 与强制
  断词，不再在 sidebar 后的临界宽度强挤两栏。`normalize_wavedrom_levels.py`、Markdown audit、
  generator 防御性规范化和最终 payload audit 形成三层防回归闭环；当前 37/37
  WaveDrom、8/8 transaction 均通过。
- 每个生产实例的 Self-check 已从只有问题升级为 5 个原生可展开答案，共 975 个；
  答案绑定父实例、握手对、状态 owner、kill/drain 与 completion/commit。状态机械提取
  同时识别 `always` 与 `always_ff`；`AxiDpiSlave=1/11`、
  `AxiVirtioBlk=2/16`（posedge blocks/sequential targets），不再误判为组合模块。
  ADD/DIV 教学例明确 `DIV(older) → ADD(younger)`，ADD 可先 formal-WB，但 commit0
  必须是 older DIV，commit1 才可在同一顺序窗口携带 younger ADD。
- Store 数据流明确拆成两条 RTL 事实链：bridge B response 含
  `{kind,token,mmu_epoch,fault_tval}+error/page_fault`；`OooIntBackend` exact-match
  MIQ/live table 后才按 token 恢复 ProducerId/ROB，形成 formal WB 与 SQ terminal。
  并行 `OooMemOwnerTerminalCollector` 分支只携带 `{kind,token,epoch}` 并回收 live owner，

不承载异常/PID，也不向 ROB 供数。
- 独立 HTML reviewer 首轮发现错 lane 猜测、筛选跨 route 泄漏、无关 timing 回退和
  A4 越界 4 个 P1；全部修正后复读为 0 P0/P1。用户截图修复的第二轮定点复核又得到
  0 P0/P1/P2。Rev. B 对抗复核继续发现 always_ff 漏识别、Store B 回程缺口、
  lead-grid 临界宽度及 owner tuple/completion payload 混画；全部修正并由同一 reviewer
  回归为 0 P0/P1/P2。已尝试以 Codex 内置浏览器打开本地单文件，但 `file://` 被 URL 安全
  策略拒绝且未绕过，因此真实 320/375 px、触控和打印预览保持 GAP；动态 RTL TB、
  综合、STA 或 PPA 也未运行，production RTL 未修改。
  证据入口：`.github/task-runs/2026-07-28-rv64core-interactive-datasheet/`。
- 全工作树 strict guard 已再次按规则执行，但当前共享脏工作树 764 个 changed paths 中含本任务
  未触碰的 agent-system、Linux 和 NPC 开发改动，因此缺少 `agent-system`、`rv64-linux`、
  `npc-dev` 本轮 profile evidence。为避免把文档交付扩权成耗时 RTL/Linux 回归，本任务对
  这些外部路径显式豁免；对 docs、task-run 与两份 memory 共 4 个真实交付 path root
  运行 scoped strict guard，结果为 `required_profiles=0`、PASS。该豁免只覆盖 guard
  归因，不把外部脏改动或动态硬件状态判为 PASS。

## 2026-07-28 RV64 Core 源码学习讲义与逐文件地图

- 新增常驻学习入口 `docs/rv64core/study/README.md`，按 00–12 章从状态 owner、
  transaction、valid-ready 和精确时相讲解当前 RV64 双发射 OoO Core；正文共
  4335 行、37 个严格 JSON WaveDrom。用户可先读全局拓扑，再沿前端、rename/ROB、
  整数/FP、memory/MMU/cache/AXI、退休/CSR、控制、SoC/仿真进入逐文件地图与实验。
- 当前 `npc/rv64/vsrc/` 共 150 个文件。`NpcTop`/`NpcSimTop` Verilator XML 合并清册为
  124 个生产实例树可达、6 个仿真专用、3 个 focused checker、3 个 catalog-only、
  9 个 header/include、5 个 document/build；第 11 章逐项解释全部 150 个真实路径。
- 当前实例真源确认 `NpcCoreTop` 已生产例化 `OooDualMemBridgeWrapper`，内部为
  2×`OooMemAxiBridge`、2×DTLB、2×D-cache 和共享 `OooDualMemAxiArbiter`；旧
  `vsrc/README.md`/`filelist.mk` 的“未实例化”注释过期。前端生产 DecodeStage 为 2，
  另有 2 个 `OOO_ASSERT` reference；不存在旧文档所述 6 个前端实例。
- 讲义已绑定四条高风险周期合同：Decode→rename→dispatch 为组合融合、dispatch 沿
  原子写 RAT/FreeList/Busy/ROB/IQ；普通整数 ALU 从 dispatch 到架构 GPR 更新的局部
  最短路径至少跨 3 个后续上升沿；FP raw result 先 PRF/wake→8-entry done FIFO→
  formal FPWB→ROB done→commit；Store 只在 SQ head 匹配 ROB head 且 launch-open 时
  发物理请求，等 B terminal 后才释放 ROB/SQ owner。
- 前端边界按当前 RTL 修正为 C0 request、C1/H1 packet response+FIFO enqueue、C2
  registered head dispatch；无 response→dispatch bypass，也无 full+pop look-through。
  redirect 在边沿更新 PC、下一拍再请求；已 handoff 的 IFU/LSU AXI transaction 只可
  drain，不能被 flush 撤回。
- 机械门 `docs/rv64core/study/tools/audit_vsrc_coverage.py` 强制所有 150 个路径进入
  第 11 章，并检查本地链接与全部 WaveDrom JSON；当前输出为
  `markdown_files=14`、`vsrc_files=150`、`atlas_rows=150`、
  `covered_vsrc_files=150`、`wavedrom_blocks=37`、`PASS`。该门只解析 marker
  内结构化 atlas row，并校验每个路径恰好一次、合法身份标签和 124/6/3/3/9/5
  精确计数；inventory 工具可从两个 XML 重建 parent/child、instance status 和
  posedge 清册。
- 最终隔离 reviewer 给出 0 个 P0，并指出 2 个 P1、2 个 P2；IFU redirect 旧响应
  已改为 `discard_fetch_rsp_q` 物理消费但不入 FIFO，Store 改为 SQ/ROB 双头
  launch→AW/W→B terminal 精确链，branch resolve 改为控制/恢复事件并对应 EX0
  formal WB，逐文件门补上结构性防假绿。四项均已修正并重跑审计。
- 本轮只写讲义、审计工具、task-run 与 DB-backed memory，没有修改 production RTL，
  没有运行动态 TB、综合、STA 或 PPA；静态拓扑/周期说明不外推为功能、Linux、
  architecture-freeze 或 PPA PASS。bounded non-history recall 与 strict guard 已
  PASS；证据入口：
  `.github/task-runs/2026-07-28-rv64core-study-manual/`。

## 2026-07-27 RV64 V10D simulation-exit exactly-once

- 当前本地 RV64 双发射 OoO RTL design-id 为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`。
  根因是 `OooPendingDrainResolveGate` 的 exact memory-owner terminal
  条件遗漏 `pending_exit_i`；在 ROB/issue 已排空但旧 memory holder
  仍 active 时，raw exit 可提前有效并同沿清 holder/stop、锁存
  `exit_valid/halted`。
- 最小 RTL 修复把 exit 纳入
  `pending_system_i || pending_arch_trap_i || pending_exit_i` 的 exact
  terminal gate；`OooTrapExitEventMux` 明确 older trap 压制 exit，
  `OooTrapExitOutputSequencer` 在 sticky 边界阻止同周期双 latch。
  `OooControlPlane` 新增 exit owner onehot、memory terminal、C1 clear
  与 C2 raw no-repeat 断言；未增加 terminal 去重，未削弱断言。
- production-module TB 直接计 raw mux pulse。assertion-on/off 各 5/5
  PASS，lane0 EBREAK、lane1 ECALL、active-holder block、C0 raw、C1
  holder/stop clear、C2 no-repeat、`core_local_flush` kill 与 older branch
  recovery priority 均有 marker；七个 compile-success RTL 版本 7/7
  被对应 oracle 拒绝，完整 module aggregate 为 113/113 PASS。
- current-design V10C replay 为 module 113/113、official 177/177、AM
  DiffTest 59/59 且 mismatch 0、CoreMark/Dhrystone PASS、architecture
  9/9 GREEN、closed currentness 15 entries/35 artifacts/0 failures。独立
  final reviewer verdict 为 `APPROVED_FOR_CURRENT_SCOPE`。
- reviewer 发现 V10C stage-order 自检遗漏
  `control-event-index-verify`。现已加入 required order、缺失/晚于 ledger
  两个负向 fixture，并把该合同设为每次 full/resume replay 的无条件
  preflight。attempt 13 持久化三项负向拒绝 marker、完整顺序 PASS 与
  currentness PASS；标准/详细状态均 PASS，仍明确
  `SERIALIZE-G1=OPEN`。
- 历史 V9Q rootfs 只绑定旧 design-id `4655…1380` 与 simulator
  `669c…6c87`，配置 queue-head/terminal-holder assertion 开启，最终
  `FAIL rc=2`、405,000,000 commits、PC `0xffffffff80002f68`、空 terminal
  marker。它不是当前设计系统 PASS。full-core candidate 的 nested
  claim 仍为 `architecture_freeze=GAP`、`ppa=UNQUALIFIED`、
  promotion=false；Linux/rootfs current-design recert 与长期 goal
  均保持 active。
- V10D 记录层已闭合：bounded non-history recall 对 simulation-exit 与
  stage-order/index-verify 均 complete；`npc-dev` task-specific e2e
  5/5、`agent-system` 11/11 completed，并通过 DB marker publication。
  最终 strict guard 为 PASS（536 changed paths、2 required profiles，
  `agent-system`/`npc-dev` 均命中 current evidence）；该结果不外推为
  Linux/rootfs、architecture freeze 或 PPA PASS。
- 证据入口：
  `.github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/`
  与
  `.github/task-runs/2026-07-27-rv64-v10c-current-design-evidence-replay/replay-attempt-13.log`。

## 2026-07-27 RV64 V10B serialized SYSTEM post-fire

- 当前本地 RV64 双发射 OoO RTL design-id 保持
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。
  V10B 未修改 production RTL；主要分类为 verification，补齐
  `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ` 从 C0 terminal
  到 C1 clear/architectural side effect、C2 no-repeat 的 raw scoreboard，
  CSR 另覆盖 enqueue 到 exact ProducerId/PC commit lease。
- pre-change `tb_ooo_priv_system` 在切断 FENCE.I MMU input 后仍 PASS，
  证明旧 oracle 不敏感。V3 最终为 3/3 baseline PASS、14/14
  compile-success 负向 RTL 版本被动态拒绝；四个 testbench path/SHA
  逐 case 绑定。切断 `OooFetchPacketCache.clear_i(mmu_flush_i)` 会出现
  stale response、无 AXI refetch 与旧 instruction packet，并由目标
  checker 失败。
- 同源分层证据为 module 113/113、official 177/177、AM 59/59、
  DiffTest mismatch 0、CoreMark/Dhrystone PASS、architecture
  DI-1..DI-5/OOO-1..OOO-4 共 9/9 GREEN。final-reviewer-v2 的标准化裁决
  为 `APPROVED_FOR_CURRENT_SCOPE`；v1 的 cohort identity、真实 Fetch
  bridge 路径、辅助 TB SHA 与局部 marker 四项反证均已关闭。
- FENCE.I 结论是 production MMU pulse、顶层静态连线与 fetch bridge
  动态 consumer 的 bounded 组合证明，不等价于 full-core
  self-modifying/Linux 证明。本轮没有形式穷举、综合、STA 或 power。
- `npc/rv64/eval/ppa/evidence/fdg-arch-trap-current.json` 仍绑定旧
  design-id 和 111-module inventory，full-core currentness 保持 GAP。
  `SERIALIZE-G1` 仍为 P1/OPEN；simulation exit、Linux terminal、
  architecture-stable 与 PPA 均未关闭，`ppa=UNQUALIFIED`、
  promotion=false。下一动作是重放 FDG current evidence 与 ledger
  updater，再继续 P1 serialize 主线；P0/P1 清零后才进入历史缺陷
  backfill 默认队列。
- 证据入口为
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/`；
  task-specific `npc-dev` run
  `.github/task-runs/2026-07-27-serialized-system-revtag-v10b/` 为
  completed 5/5，限定本轮 15 路径的 strict guard PASS。
  长期 goal 保持 active。

## 2026-07-27 RV64 V10A clocked serialized-owner exactly-once

- 当前本地 RV64 双发射 OoO RTL design-id 为 `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。根因是 `OooCsrTrapRequestMux.pending_arch_trap_fire_o` 原先未被同沿 ROB-head commit exception 屏蔽；虽然生产 `CsrFile` 选择 `mem > ex > irq`，raw pending architectural-trap request 与 predictor boundary 仍会额外有效，因而不代表唯一被选中的 CSR transaction。
- 最小修复在 `OooCsrTrapRequestMux` 中以 `drained_pending_control_w = !core_commit_exception_trap_o && stop_pending_i && drain_complete_i` 统一限定 drained pending control request；没有增加 terminal 去重、状态寄存器或事件过滤。`OooControlPlane` 的 `OOO_ASSERT` 新增 registered arch/system owner onehot、live owner→stop、request overlap 与 C0 fire→C1 clear/no-repeat 检查，断言未被削弱。
- production clocked TB 直接计数 raw request：head0/lane1 arch-system birth 与 IRQ-over-arch priority PASS，ECALL/IRQ/xRET/CSR/FENCE 五类 standalone exact-one PASS，live arch owner 通过 `stop -> !can_run` 阻止五类 overlap，commit trap 同沿屏蔽 pending raw request，older memory holder 阻止 drain，C0 fire→C1 owner/stop clear 与 `CsrFile.mepc` 单次更新→C2 no-repeat 全部 PASS。
- focused assertion-on/off 均 PASS；6/6 compile-success RTL variants 被动态拒绝；module 113/113、official 177/177、AM 59/59、DiffTest mismatch 0，architecture DI-1..DI-5/OOO-1..OOO-4 全 GREEN，并与相同 design-id 绑定。独立终审将 V10A bounded sub-slice 判 `PASS`。
- 证据边界保持显式：pre-fix behavioral RED 未保存完整历史源码快照；focused 日志未内嵌 `[RTL-DESIGN-ID]`，身份由 live-file mutation hashes 与 canonical aggregate 交叉绑定；TB 未独立逐拍计数最终 frontend redirect / `priv_predictor_boundary`；本轮没有 synthesis/STA/power。
- `SERIALIZE-G1` 总体仍 `OPEN`；下一主线是八类 serialized SYSTEM 的 post-fire transaction、simulation exit 与 Linux terminal。full-core architecture-stable 未冻结，`ppa=UNQUALIFIED`、promotion=false。证据入口为 `.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/task-report.md`，长期 goal 保持 active。

## 2026-07-27 RV64 V9Z pending architectural-trap memory terminal

- 当前本地 RV64 双发射 OoO RTL design-id 为 `sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`。根因是 `OooPendingDrainResolveGate` 只在 `pending_system_i` 有效时等待 `mem_owner_terminalized_i`，使 `pending_arch_trap_i=1`、旧 memory holder 仍 active 的周期可提前产生 `drain_complete_o`，并经 `OooCsrTrapRequestMux` 提前形成 trap request 与 predictor boundary。
- 最小 RTL 修复把 exact memory terminal 条件统一为 `!(pending_system_i || pending_arch_trap_i) || mem_owner_terminalized_i`；ordinary FENCE 仍独立要求 `!pending_system_fence_i || mem_idle_i`。本轮没有增加 terminal-event 去重、状态寄存器或事件过滤，也没有削弱 assertion。
- 原始 pre-fix 集成 TB 编译成功并精确观察到 drain/fire/trap-request/predictor-boundary 四项提前有效；该日志未嵌入 pre-fix RTL SHA，故与后续 hash-bound `drop-arch-trap-terminal-term` 负向 RTL 版本分开陈述。最终 assertion-on 3/3、assertion-off 2/2、compile-success RTL variants 4/4 动态拒绝、module 112/112、functional 112/112+177/177+59/59 且 DiffTest mismatch 0、architecture 9/9 GREEN。
- V2 独立 reviewer 核对 gate/mux/TB SHA、146-file architecture manifest、功能聚合与九门架构结果后，将 V9Z 组合边界判 `PASS`；时钟化 fire→next-edge owner clear、无新 capture 时副作用不重复，以及 arch-trap 与 ECALL/IRQ/xRET/CSR/FENCE 的 overlap priority/unreachability 仍为 `GAP`。
- 一次前台功能聚合调用只达到调用器时限；其子进程尚未退出且未发布 AM/benchmark/final aggregate，因此不计完成。唯一 WSL 工程命令 lane 保持占用直至该进程退出，随后才从头执行一次受监控的 canonical 聚合。稳定规则是：前台工具超时不等于仿真/构建进程退出，分阶段日志也不等于 canonical final publication。
- `SERIALIZE-G1` 总体仍 `OPEN`；下一合同应覆盖 `OooPendingTrapExitSequencer`、`OooPendingSystemSequencer`、`OooControlEventApplySequencer`、生产 `CsrFile` 与 clocked gate-to-owner-to-CSR TB。七类 exactly-once、完整 Linux flag-on、architecture-stable 与 PPA 仍未关闭，`ppa=UNQUALIFIED`。证据入口为 `.github/task-runs/2026-07-27-rv64-v9z-serialize-arch-trap-terminal/task-report.md`，长期 goal 保持 active。

## 2026-07-26 RV64 V9Y accepted memory-owner terminal

- 当前本地 RV64 双发射 OoO RTL design-id 为 `sha256:3c933ec82fd17c6038335f9208b496cacfb755dfd10b9e419c73f276b5e2a428`。`OooMemOwnerTerminalCollector` 新增逐 lane `ingress_accept_o`，只在 edge-old live、kind/epoch exact、无 intra-batch duplicate、无 pending collision、无 same-edge dequeue/re-enqueue 时授权 handoff；raw terminal ingress 不再能授权 serialized control。
- `OooIntBackend.mem_owner_terminalized_o` 的 production holder census 已移出 `OOO_ASSERT`，覆盖双 MIQ、双 bridge residency、双 reservation、buffer、AMO pending、双 retry、SQ、request-fire handoff、same-edge birth、collector pending/tracker live 与 exact STORE release。标量原样传到 `OooPendingDrainResolveGate`，同时门控非 CSR drain 与 CSR Cresolve；ordinary FENCE 继续额外等待 full `mem_idle`。
- assert/release focused 均观察 active=0、accepted transfer=1、pending-only=1、full-idle=1；wrong-epoch、duplicate、same-edge reenqueue 均 accept=0，SD/FSD exact SQ release 在两配置均 PASS。gate mutations 3/3、release acceptance mutations 3/3 精确拒绝，module 111/111、functional 111/111+177/177+59/59 且 DiffTest mismatch 0、architecture 9/9 GREEN。
- V1/V2/V3 reviewer 依次发现原控制缺口、macro/raw-ingress blocker和 stale TB provenance；刷新 mutation 后 V4 reviewer 核对 live RTL/TB SHA 与同一 design-id，将 V9Y memory-owner terminalized 子范围判 PASS。未增加 terminal 去重、未削弱断言。
- task-specific `npc-dev` 最终 run `.github/task-runs/2026-07-27-serialize-memory-owner-terminal-current/` 为 bounded recall 完整、5/5、exit 0。前两次 run 虽节点均为 5/5，但分别因版本词未使用受控标签、V9Y module-memory 尚未增量刷新而在 context recall 阶段 fail-closed；刷新两份 current memory 后通过，未放宽召回门。V9Y evidence index 为 491 assets/296,521,308 bytes，SHA-256 `8e077496388028dff7f8ce4f3053a55be76a6cc9585cc5d3f586c13a2f39c50b`，包含 strict-guard status。strict guard 现仅 `rv64-linux` 缺完成证据；沿用既有 36,000 秒未达 17/17/natural-poweroff/`GOOD TRAP` 的显式豁免，不追认为系统 PASS。
- `SERIALIZE-G1` 总体仍 OPEN：pending arch-trap、七类 serialized exactly-once 联合观测、完整 Linux flag-on、architecture-stable 与 PPA 尚未关闭；`ppa=UNQUALIFIED`。证据入口为 `.github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/task-report.md`，长期 goal 保持 active。

## 2026-07-26 RV64 V9X recovery/owner-birth phase alignment

- 当前本地 RV64 双发射 OoO RTL design-id 为 `sha256:a2ccc0c2a61be3d8922245f7d145eadc186b701fca1f38ef534aafdd983e994b`。`OooStopPendingSequencer` 已删除 raw lane/type birth，只消费 accepted pending owner birth/live、exact CSR lease、canonical queue-head real-fire/inflight/kill、trap/exit holder 与 C1 reset，并由一个显式 next-state priority chain 更新 `stop_pending_o`。
- `OooFrontend.head0_csr_dispatch_fire_w` 现经 `OooCoreTopGlue` 原样送入 `OooControlPlane`；queue-head owner birth 不再由 merged backend fire 重构。`OooPendingTrapExitSequencer` reset 同源接入 `core_local_flush_w`，使 pre-ROB trap/exit holder 与 stop 在 C1 同沿死亡。
- RED 包含 checkpoint recovery × lane0/lane1 SYSTEM 的 orphan stop 与 exit squash/capture collision；五项 assertion-negative 均命中预期 ERROR/FATAL。最终 flag-on 明确观测 `merged=1 real=0 birth=0` 与 `holder=0 stop=0`；删除 C1 reset、恢复 merged-fire birth 的两个 compile-success RTL mutation 均被定向 oracle 拒绝。
- 最终 module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000、architecture DI-1..DI-5/OOO-1..OOO-4 共 9/9 GREEN。V4 独立 reviewer 核对最终 source-map identity 后，将 V9X owner-birth 子范围判 PASS。
- `SERIALIZE-G1` 总体继续 OPEN：下一主线是 `OooMemOwnerTerminalCollector` 入口 lane 对、owner/holder 合同和非 FENCE serialized transaction 的真实 memory-owner terminal；七类 exactly-once、完整 Linux flag-on、architecture-stable freeze 与 PPA 均未关闭。当前 `ppa=UNQUALIFIED`、promotion=false；未加入 terminal 去重，也未削弱 assertion。
- 证据入口为 `.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/task-report.md`；长期 RV64 OoO/PPA goal 保持 active。

## 2026-07-26 RV64 V9W pending-system canonical kind

- 当前本地 RV64 双发射 OoO RTL design-id 为 `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`。`OooPendingSystemSequencer` 已用单一 `kind_q` 保存 `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ`，公开类型、普通 FENCE drain 与 SFENCE/SINVAL/FENCE.I redirect 均从 holder 投影。
- 当前设计证据：双 lane 非 IRQ 类型矩阵 14/14、focused 2/2、layered 6/6、compile-success RTL variants 4/4 精确拒绝、module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、canonical architecture 9/9 GREEN。
- AI 工作流证据：`npc-dev` 5/5、`agent-system` 11/11 PASS；双角色检查以 `实现者`、`审查者`、`双角色复核` 三个语义锚点接受等价专业措辞，并保留缺失复核锚点的负向反例。strict guard 仅因 `rv64-linux` 没有完成态 PASS evidence 保持 FAIL。
- 当前 `rv64-linux` 为 7 PASS / 1 FAIL：同一 design-id 的 simulator SHA-256 为 `4b0be491fbe1305e79bbaf599787f1321c8ac7dcc8ea5236a23a735edda8441d`；rootfs 在 1200 秒内推进到 Linux 0.059199 秒的 EFI 初始化后 `exit=124`，未到 virtio/EXT4/VFS/systemd/Ubuntu/hostname/terminal marker，且没有 RTL assertion-failure marker。该记录是系统时限 GAP，不是 RTL FAIL 或 rootfs PASS。
- 实现者与独立 reviewer 均只给出 canonical kind、CSR ProducerId lease、typed redirect 的局部 PASS。`SERIALIZE-G1` 保持 P1/OPEN；recovery cross-product、真实 memory-owner terminal 与七类 transaction exactly-once 仍为 GAP。
- final arch-stable audit 有 32 blockers；PPA 保持 `UNQUALIFIED`、promotion=false。本轮未增加 terminal-event 去重、未削弱 assertion，也未从局部架构证据外推 synthesis/STA/PPA 结论。

## 2026-07-26 RV64 V9V full-core capability cohort

- 当前生产 RTL design-id 保持 `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。V9V 没有新增生产 `.v` 修改；当前 12-lane `OooMemOwnerTerminalCollector` 与 V9R producer/bridge C0 retry-holder 修复在定向仿真中为 8/8 PASS，collector 同拍捕获 12 个 exact tuple 并排空 12 个，bank0/bank1 与 bridge 三个 C0 handoff marker 全部成立。
- 历史 `rootfs-v9q-terminal-pair-a1` 已确认是旧设计 `sha256:4655...1380` 上的 `FAIL rc=2`：配置为 queue-head/terminal-holder assertion 开启，推进到 405,000,000 commits、PC `0xffffffff80002f68`，但 terminal marker 为空且没有 RTL assertion marker，最终因 reset-syscon 未自然完成而 host timeout。该记录只算有界未复现，不绑定当前设计。
- full-core cohort `full-core-single-hart-rv64-dual-issue-ooo-v1` 已由 `npc/rv64/design/arch/full-core-cohort-scope-v1.md` 与四份 machine-readable exclusion 合同冻结：single-hart local LR/SC、WFI immediate-resume、global SFENCE/Svinval、无 architectural Debug/trigger。四项 exclusion 与 candidate/ledger exact membership 均 PASS；任一 design-id 或 capability 边界变化都必须重审。
- 架构 provenance 已从 canonical roots 完整重放，DI-1..DI-5/OOO-1..OOO-4 为 9/9 GREEN；V9O index 为 165 artifacts，`test_arch_stable_freeze` 48/48 PASS，15 个 CLOSED debt current binding 全 PASS。
- full-core audit 仍诚实报告 `GAP`、32 blockers、PPA `UNQUALIFIED`、promotion=false。`SERIALIZE-G1=OPEN`、producer-holder census、cohort freeze-input inventory 与 systemd-strict 终态证据均未被本轮局部合同误闭合。
- `npc-dev` e2e 为 5/5 PASS，V9V evidence index 与 DB-first audit 均 PASS。strict guard 已执行；仅 `agent-system` 既有 Markdown coverage 和 `rv64-linux` V9S systemd-strict 仍为显式 GAP，未追认为全核或 Linux PASS。
- 证据入口为 `.github/task-runs/2026-07-26-rv64-v9v-full-core-cohort-scope/task-report.md`；长期 RV64 OoO/PPA goal 保持 active。

## 2026-07-26 RV64 V9U vectored trap / interrupt delegation

- 当前生产 RTL design-id 为 `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。`CsrFile` 现在保存 mtvec/stvec MODE=00/01、将 MODE=10/11 钳位为 Direct，并由同一个 `mem > ex > irq` 记录派生 xEPC/xCAUSE/xTVAL、delegation 与 redirect target。
- 首次 F0 的唯一失败 `rv64mi-p-illegal` 定位到未委派 SSIP 未进入 M-mode：旧 M pending 只消费 machine interrupt mask，且 trap delegation 按 supervisor cause 类别推断。最小 RTL 修复把未委派 SSI/STI/SEI 以原 cause 路由到 M、只把 `mideleg` 命中的 supervisor pending 路由到 S，并增加独立 `[VECTORED-TRAP-A5-IRQ-ROUTING]` 参考断言。
- V9U 为 CsrFile 13/13、完整核 M interrupt/S interrupt/M synchronous exception 3/3、CSR regression 1/1、7/7 compile-success 负向 RTL 版本，raw duplicate terminal event 为 0。定向 `rv64mi-p-illegal` PASS；完整 F0 为 module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000。
- 当前 CONTROL 证据为 focused 10/10、queue-head config 3/3、RTL variants 11/11、V9R baseline 2/2 与负向 3/3、index 165 artifacts；9 个 directed architecture gates 全 GREEN，arch-stable/vectored 单测 56/56 PASS。15 个 CLOSED debt 已重绑当前设计。
- full-core candidate 已与 live RTL 同 SHA，但继续诚实报告 `GAP`、36 blockers、PPA `UNQUALIFIED`、promotion=false。剩余主线为 `SERIALIZE-G1=OPEN`，四个 scope 决议、producer-holder instance/semantic census、cohort inventory 与完整 freeze inputs；V9S systemd-strict 仍是 RED，不能由本轮官方/F0 PASS 外推为 Linux rootfs PASS。
- `github-index` 的根 shim 分块已改为 1000-token 上限；`AGENTS.md` 实测为 972/418-token 两块，单行超预算反例仍 fail-closed，`.github/task-runs/2026-07-26-default-chunk-max-tokens/` completed。strict guard 仍只缺 `agent-system`（既有 Markdown coverage 集合）与 `rv64-linux`（V9S RED）；两者均显式保留为豁免/GAP，不追认为 PASS。
- 证据入口为 `.github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design/task-report.md`；长期 RV64 OoO/PPA goal 保持 active。

## 2026-07-26 RV64 V9T 12-lane terminal collector

- 当前生产 RTL design-id 保持 `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`；V9T 未修改生产 `.v`。`OooIntBackend.u_mem_owner_terminal_collector` 的 12 个有序 terminal ingress 已与 standalone TB、pair-matrix parser 和 DI-3 source gate 对齐；release/assert 都观察到同拍 `pending=12`，随后 12 个 exact `{kind,token,epoch}` tuple 各 drain 一次。
- canonical pair matrix 为 baseline 8/8、pair keys 15/15、memory pairs 4/4、special exclusions 10/10、compile/elaborate-success variants 15/15 拒绝；hard-gate 单测 33/33，包含 lane10/lane11 次序交换使 `source.twelve_ingress_terminal_collector` 变 RED。DI-3 为 GREEN，完整 architecture inventory 仍诚实 RED。
- 当前 module aggregate 为 110/110 PASS；110 份日志均绑定 RTL SHA `c358...e8d` 与 verification SHA `73466b559c293cc34c9825aabca7c0f2490ce1e846f04a7d710af1e76daccca3`。V9R live source binding 仍匹配，baseline 2/2 与打开 bank0 READY、bank1 READY、bridge retry-fire 的可编译 RTL 反例 3/3 保持有效。
- V8P canonical runner 已去除“architecture manifest 只能含四个历史 sibling”的过时假设；现在允许 current-design 证据超集，但逐项保证 pair publication 不改变除 `pair_matrix` 外的既有记录，并仍要求 scoped gate GREEN、OOO-3/overall RED。
- V9S rerun3 在 36,000 秒 host window 后为 `FAIL rc=2 stage=systemd-strict-guest evidence_complete=0 cleanup_rc=0`：14/17 guest checks，最后 PC `0xffffffff8013e132`、640,000,001 commits；没有 `S2-G1-TCOLL`、`V9Q-` 或 `Assertion failed`，但缺少 direct-read、IRQ-growth、dmesg、natural poweroff、reset-syscon 与 `GOOD TRAP`，因此不是系统 PASS。历史 duplicate 的 exact ingress lane pair 因旧日志未打印 tuple 而仍为 GAP。
- 证据入口为 `.github/task-runs/2026-07-26-rv64-v9t-terminal-collector-12lane/task-report.md`。queue-head 默认值保持 0，等待新标签、更大 host window 的 17/17 + natural poweroff 同设计证据；full-core freeze、正式 PPA A/B 与 promotion 仍为 `UNQUALIFIED`，长期 goal 保持 active。

## 2026-07-24 RV64 V9R SQ-query retry C0 handoff

- 当前 RV64 双发射 OoO 生产 RTL design-id 为 `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`。V9R 修正 `OooIntBackend` 两个 retry READY 与 `OooMemAxiBridge.sq_query_retry_fire_w` 未受 full-flush C0 barrier 约束的交接缺口；C0 保持 MIQ/retry/bridge edge-old owner，barrier 解除后才允许正常 transfer，未新增寄存器、队列项、AXI channel gate 或仲裁级。
- 全顶层 EDA 收口不使用全局 `-Wno-fatal`：`--timescale 1ns/1ps` 消除模块 timebase 漂移，SQ forwarding 局部量补默认值消除真实 latch，owner assertion scratch counters 改为无状态函数，sim-only 计数器改显式 `initial`，TLB/cache 私有函数采用模块限定命名。`make -C npc/rv64 lint` 与完整 `NpcSimTop + OOO_ASSERT` 生成、编译、链接均通过。
- V9R baseline 2/2、可编译 RTL 反例 3/3；V9O focused 10/10、queue-head config 3/3、module 110/110、RTL variants 11/11、architecture hard gates 9/9、negative tests 30/30。V9R summary、V9O index、V9O mutation、hard-gates SHA-256 分别为 `35f2337f15acdfcc77ef20a1b536e7edfe86aa901068c743cc5b53c312f041b5`、`5496f331833d5f7ab8834bad333d9ff6078e0c683f2eff5b0c2be2dabfbd5374`、`33335402765cba4a42e38df5274346ed928b5f078bf593caa4e5b089e2089c26`、`6c5d6567671a72a352522e9ae861afc629d5501874ac1b3427fd08ea83ee8061`。
- 十组语义门均在当前 design-id 重放，最后的 PTW/PMP 为 focused 2/2、module 110/110、compile-success variants 28/28 动态拒绝。debt ledger 已重绑 14 项历史条目，`F0-G1` 与 `CONTROL-EVENT-G1` 均为 `CLOSED/current_design_bound=true`，`SERIALIZE-G1` 仍 OPEN；ledger SHA-256 为 `6a2088b68cbb98dcd52e8f604e437b1f166b26f2b0bcd66814f7b3677f3533cb`。
- 当前功能聚合为 module 110/110、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000，aggregate SHA-256 为 `842f5ce79b73dd2e7d1393e61f14013a6e40b27d43fa9c93b7b2dcb7c22a988f`。arch-stable validator 140/140 PASS，但 full-core candidate 仍绑定旧 `sha256:2eff...c8b2`，所以最终为 `GAP`、71 blockers、PPA `UNQUALIFIED`、promotion=false。
- current-design `rv64-linux` profile 为 7 PASS / 1 FAIL：Sv39/SRET/U-mode、focused Linux 与 UART RX 通过；rootfs 在 1200 秒内从 OpenSBI 进入 Linux 6.6，建立 earlycon、zone/initmem、kernel command line、dentry/inode cache 和 heap init，但未到达 virtio/VFS mount 或 systemd banner，`exit=124`。这是有界未完成，不是 rootfs PASS，也没有观察到 RTL assertion failure。前序六小时运行仍只属于 pre-fix 有界未复现。
- strict guard 的 `agent-system`、`npc-dev`、`difftest` profile 已有 current-source PASS；唯一剩余项是上述 `rv64-linux` rootfs 节点。对本轮收尾采用显式证据豁免：不重复执行输入、周期上限和 1200 秒窗口均相同的节点，不把豁免改写为 PASS，后续只有在扩大仿真吞吐/窗口或定位新的 RTL/平台进展点后才重跑。
- RV64 协作文本默认使用 module/signal/pipeline stage/transaction/cycle/testbench/EDA/evidence/PPA 专业上下文；保留精确 RTL 标识符、命令、断言、负向变体、unknown 与反例，不建立关键词黑名单，也不削减源码、shell、实现、验证或 PPA 能力。长期 RV64 OoO/PPA goal 保持 active。

## 2026-07-23 RV64 V9O unified control event current design

- 当前 RV64 双发射 OoO 生产 RTL design-id 为 `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`，verification source-id 为 `sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1`。`CONTROL-EVENT-G1` 已在该 current design 上局部关闭：ROB full pregrant 是唯一 C0 request，`OooControlEventApplySequencer` 是唯一 C0→C1 state owner，TRAP/CSR commit 与对应 typed reason 双向等价。
- C0 full barrier 覆盖 dispatch、INT/FP issue、8 类 completion authorization、memory station/pre-owner launch 与双 data bridge；strict-younger 环形年龄边界、pending CSR exact ProducerId、LQ edge-old permit 和 registered AXI owner drain 均由 RTL 断言与定向 TB 覆盖。
- current-design 证据为 focused 10/10、queue-head config 3/3、module 110/110、compile-success RTL variants 11/11、completion matrix 8/8、dual registered-AR 2 lanes/4 hold cycles/2 terminals、architecture hard gates 9/9 和 negative tests 30/30。evidence index 为 164 artifacts，SHA-256 `d73a69cdfd92f42ed87e9e60a0c5389c343e4261ab6cf8b6fddc957245124da0`；`check-contract` 为 471 assertions、13/13 tests。
- 三轮 ledger validator 复核把 exact provenance、mutation summary exact schema、动态 module inventory、live candidate identity、architecture result/manifest canonical path 与递归 boundary-reference 检查固化为共享门禁。最终 selected validator tests 5/5、evidence-index replay PASS。
- 完整核 candidate 仍绑定旧 design-id `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`，因此 full-core 仍为诚实 `GAP`、59 blockers、PPA `UNQUALIFIED`、promotion=false；局部 9/9 不外推为 full-core freeze 或正式 PPA。
- 子 agent 最终回复首段已固化为“RV64 RTL 对象/本地证据文件 → 周期或编译配置 → testbench/EDA 观测 → PASS/GAP/inconclusive 范围”。该规则不建立关键词黑名单，不减少源码、命令、负向 RTL 变体、断言、覆盖、未知项或范围扩展能力；长期 RV64 OoO/PPA goal 保持 active。

## 2026-07-23 RV64 V9N STORE/AMO owner next-edge residency

- 当前 RV64 双发射 OoO 生产 RTL design-id 保持 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`；本轮未修改生产 `.v` RTL，新增的是 verification wrapper、可编译 RTL 源码变体、证据生成/校验和组合回放规则。
- `STORE-BRESP-G1` 新增独立 next-edge owner residency 证据：STORE/AMO focused 2/2、compile-success source variants 2/2 动态拒绝、evidence 单测 8/8。result/raw SHA-256 分别为 `34090add201aece110bc3423fec7460e33cecb35ce2da1ac73ca788a7cb0d709` 与 `379d16ebbe790b80315943d2420581c9446c8690ffcd076ab1aba44b592e1746`。
- 最终 canonical 9 门架构链全 GREEN，模块聚合 109/109，受共享验证文件影响的 10 个局部架构债务 target 全部重放；arch-stable 135/135 单测 PASS，当前仍为诚实 `GAP`、38 blockers、PPA `UNQUALIFIED`、promotion=false。
- V2 独立 reviewer 未发现 STORE/AMO 局部 RTL 反例，但发现其 dispatch 记录在旧 owner evidence 之后追加且属于 provenance，因而旧证据必须判 freshness GAP。冻结终审记录后已从 9 门顶层完整 canonical 回放并重跑 arch-stable；稳定规则是 provenance 内协调记录必须先冻结，发生后置字节变化时重放叶证据及上层聚合，禁止仅更新 ledger hash。
- 长期 RV64 OoO/PPA goal 保持 active；本切片不外推为全核 freeze 或 PPA promotion。

## 2026-07-23 RV64 FENCE-G1 current-design V9M

- 当前 RV64 双发射 OoO 生产 RTL design-id 保持 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`；本轮未修改生产 `.v` RTL，修改集中在 full-core testbench、证据生成/校验与工作流规则。
- `FENCE-G1` 已关闭：普通 `FENCE` 的 pending-system drain 同时等待 backend/SQ quiet 与完整 `mem_idle_o`；full-core 程序覆盖 older store、lane1 FENCE、younger device read，并在等待周期运行时核对 CoreGlue→ControlPlane `mem_idle` 端口值。
- canonical `make -C npc/rv64 check-fence-ordering` 为 focused 2/2、module 109/109、两份 compile-success negative RTL variant 2/2、fail-closed validator unittest 12/12；所有正向日志绑定当前 `[RTL-DESIGN-ID]`。result/raw SHA-256 分别为 `792b8c2c9454d01eb5143019136d6b3add734019ff20cd66cd36efef961e2ec0` 与 `3481db6a72c52a786139231107d5ef6e8ba93f19a1018bbe33061ffb875e83c1`。
- 共享 Makefile/TB/freeze validator 的 provenance 变化通过 9 个既有 canonical target 与九门 architecture aggregate 实际重放恢复；最终 ARCH_STABLE audit/verify 和 134 项单测 PASS，当前仍为诚实 `GAP`、38 blockers、PPA `UNQUALIFIED`、promotion false。长期 goal 保持 active。
- 主/子 agent 的用户进度、终审和派发统一使用 `rv64-hardware-professional`：首句写明本地 module/signal/transaction、仿真/综合/STA 与证据产物，协调状态单独进入 task-run；该分层不使用关键词黑名单，也不减少源码探索、命令、负向 RTL 版本、断言、覆盖、独立复核或 PPA 能力。

## 2026-07-22 NEMU reference-smoke target contract

- `cpu-tests` 的 `ARCH=riscv*-nemu` reference smoke 必须由 `CONFIG_TARGET_NATIVE_ELF=y` 的宿主 NEMU 执行。旧 e2e 判定把 `CONFIG_TARGET_AM=y` 当作兼容配置；该 target 会把 NEMU 自身构建成 AM 镜像，并由 `platform/nemu.mk` 再次调用同一 NEMU `run` 入口，形成递归 make 链，而不是有效 reference smoke。
- `scripts/e2e/lib/common.sh`、`scripts/e2e/modules/nemu.sh`、`nemu.tsv`、`quick.tsv` 与 NEMU e2e 合同已统一为 host-native RISC-V 语义。新增 `nemu-reference-config-contract` 仅接受 native 加显式 `riscv32`/`riscv64` ISA，并对 AM、SHARE、native 非 RISC-V、native 缺失 ISA、缺失配置全部 fail closed；历史 `AGENT_E2E_FORCE_SMOKE=1` 不能绕过 target/ISA 类型。
- 修正后的真实 RV64 `add` smoke 执行 `844` 条 guest 指令并 `HIT GOOD TRAP`，汇总 `1/1 PASS`。`difftest` profile 的最终 run `2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2` 为 completed，8 个节点全 PASS；NEMU 配置前后 SHA-256 均为 `78fc4445c5ed41264d5b9688520b592f3265101d4a8ddd83bc40383ee9fc8a0d`。
- 先前 AM/SoftFloat、unused helper、UART assert 和递归构建失败 run 保留为 root-cause 反例，不作为完成证据；为错误 AM 路径试加的 NEMU 生产源码改动已逐项撤回。长期 RV64 OoO/PPA goal 仍 active，PPA 继续为 `UNQUALIFIED`。

## 2026-07-22 RV64 V9L functional aggregate and memory ownership

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。本轮生产 RTL 修正了三项同一内存所有权合同：ROB head 的“可发射”与“发射后仍持有精确 owner”分离；SQ 的 AMO post-launch 检查在 recovery 期间继续要求 exact head/full ProducerId owner；AXI bridge 的 station lookup 只在当前 response credit 可前进时允许，并把 retry residency 限定为同一 exact token，而不是禁止同 bank 的不同 token 同时驻留。
- `F0-G1` 已在当前 design-id 关闭：模块测试 `109/109`、official `177/177`、AM cpu-tests `59/59` 且 DiffTest mismatch `0`、CoreMark `ITERATIONS=10`/CRC `0xfcaf`/GOOD TRAP、Dhrystone `mainargs=10000`/GOOD TRAP；功能证据变体 `11/11` 编译并被拒绝。functional result/aggregate SHA-256 分别为 `3e632a4a8f00ab8d69fc880c8a1e3e8fbf0cbedf240b25a400a8a06f0c25f296` 与 `c09c03742fc26dd99ff638baaf2848496328ee264340f8c9f05f08a5df202793`。
- V9L current-source RTL 验证变体 `4/4` 编译成功并被对应断言拒绝；V8L holder 生命周期 `8/8` 正向基线和 `9/9` 编译成功 RTL 变体通过。V8L 汇总只规范化 runner 自有 `/tmp/v8l-global-lease.*` 路径，两次从零重放的 lifecycle/mutation 产物字节一致，SHA-256 分别为 `82143f9e166465572fc58cdf42c3d07b4a3e9d1d3a78224edb2b9748c6b43a97` 与 `494048b7248b2b1d3c76c3c034c91003fb102b1677ab4e0b0919cb8bc773b707`。
- 九个 directed architecture gates 已按当前清单重放并全 GREEN；`architecture-current.json` 与 hard-gate result SHA-256 分别为 `a364e78b6e7fbc92619cb8c09ee33e3732ad7186f84597db6f4c24d8c357c6b1`、`2e501a4cb367d02b77cecdfbb14f439ba8e02cf2707fab24aa2f721226e0ba70`。arch-stable 审计 `134/134` 单测通过，当前结果仍为诚实 `GAP`、`39` blockers、PPA `UNQUALIFIED`、`promotion_eligible=false`；其 SHA-256 为 `784b4953c1db766e4e8efa5a4189d770a6b88d886e86eecdd09e51a741966b00`。
- 12 个已关闭架构债务均已重绑当前 design-id；仍开放的是明确记录的架构语义/范围决策、完整 census、cohort inventory 与 freeze inputs。长期 goal 保持 active，不能把 F0 或 9 个定向门外推为 `ARCH_STABLE` 或 PPA 晋级。

## 2026-07-22 RV64 PTW PTE WRITE PMP current-design V9K

- 当前 RV64 双发射 OoO 生产 RTL design_id 保持 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮只增强 testbench、evidence parser、freeze validator 与当前源码负向变体，生产 `.v` RTL 未修改。
- `PTW-PMP-G1` 已由 V9K schema `npc-rv64-ptw-pmp-evidence-v4` current-design 证据关闭：focused 2/2、module aggregate 109/109、compile-success RTL variants 28/28 动态拒绝、fail-closed 证据测试 13/13。
- WRITE grant 证据把 PMP checker 的 registered PTE physical address 逐位绑定到 `AWADDR`；IFU 以 AW-first、LSU load-A 以 W-first、LSU store-D 以 AW-first 覆盖独立 READY/VALID，stall 期间保持 address/size/data/strobe，每个 channel 恰好接受一次并在 AW/W 均完成后等待 B。
- WRITE deny 证据覆盖 IFU F=0/2/4/6 exact successful prefix，以及 LSU load-A readonly、store-D readonly、load-A partial8 在 response READY 延迟 0/1/2/3/5 下的 15 行、33 个 stalled-response 周期；owner kind/token/MMU epoch/original VA `fault_tval` 与 access-fault class 保持到 response handshake，全区间 `AWVALID=WVALID=0`。
- 任意长 response stall 的安全性由完整状态译码证书独立闭合：生产 RTL 的 AW/W VALID 解码仅包含 `S_WRITE_REQ`/`S_AD_UPDATE`，deny 进入 `S_RESP`，并在 `rsp_ready_w` 之前自保持；3 个额外 LSU 变体在第三个 stalled-response 周期脉冲 AW、W 或 AW+W，均被动态拒绝。response liveness 不从该 safety 证书外推。
- result SHA-256 为 `54d39545dea4a43310501499ad7a1e5d84c1af5e8244c859b0d868fb7774fc49`；raw log SHA-256 为 `1947a4c5f3ae713f28fcf0b19d29155955ee4f8cab5f086f0538877336611ea9`；来源重绑 V4 审计 SHA-256 为 `6e852a89183f9078a101cf834b50a3ce721a99c4c4691d6a82e0960c9e1c02e9`，`pre=RED`、`post=GREEN`且 semantic projection 不变。
- V1/V2/V3/V4 限定材料复核逐步发现 current-source、F=2/4/6、owner snapshot、checker-to-`AWADDR`、split-ready、held-response、第三个 stall 周期与有界长度问题；这些问题均转化为可执行 TB、RTL 断言、compile-success variant 或状态证书。V5 在同一 design_id 的限定范围内 PASS，合同 SHA-256 为 `7a01e924e4f5c8af71e425417404473506981bceac9afd245b8817a8da775cf9`。
- 共享 freeze validator 变更后，所有相关 CLOSED result 已用 canonical 本地 RTL 仿真重放；final audit 的 130 个测试通过。`architecture-current.json` SHA-256 为 `a99bfa190f63ed6edac1e025e668e6a82db91321de746d8171e499e47c844fa4`，`arch-stable-current.json` SHA-256 为 `20a6be5a4e73035792004ccc0ef343866da43edbbc04766c4e8d37e910495912`；full-core `ARCH_STABLE` 仍为诚实 `GAP`、36 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 保持 active；下一个直接架构任务为 P1 `F0-G1` current functional aggregate，不把 PTW-PMP 局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU precise tval current-design V9J

- 当前 RV64 双发射 OoO 生产 RTL design_id 保持 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮只增强 testbench、证据提取器、验证变体与冻结门禁，生产 `.v` RTL 未修改。
- `IFU-TVAL-G1` 已由 V9J current-design 证据关闭：focused 8/8、module aggregate 109/109、current-source 可编译 RTL 变体 12/12 动态拒绝、fail-closed 证据单测 12/12。
- 精确证据包括按顺序解析的 24 行 `cause/layout/F/owner/xepc/tval/capture/pending/drain` 联合清单，以及 lane1 instruction page fault 在 `dispatch1_ready=0` 时不接受、READY 拉高后以 `xEPC=PC+2`、`tval=PC+4` 进入 capture/pending/drain 的直接周期行。
- 三个新增 RTL 变体分别切断 `OooFrontend` head `fault_tval` 投影、`OooFrontendDispatchGate` READY 接受条件和 `OooStopPendingSequencer` branch-squash 清除语义；均由对应 full-core/定向 oracle 动态拒绝。stop sequencer 的端口审计确认其只传递 stop pending，不携带 cause/PC/tval payload。
- result SHA-256 为 `cb26a1d249554758b110725536d3f0291668033dc2b8e58d91139957f8e304da`；raw log SHA-256 为 `7f6c32a09a86388636de3346942cd72a60e0fdc8fa9370b033b03ce03dc5192f`。V1 限定材料复核发现的四个证据缺口均已转为可执行证据；V2 复审 PASS，合同 SHA-256 为 `ccc091eaa009c44e934e2ed310f1527312ad9083b8adde505a31f1741e04378b`。
- 所有已关闭架构条目的 result/raw 哈希已重放并通过账本 `MATCH`；full-core `architecture_freeze` 仍为 `GAP`、37 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 继续 active；下一项 P0 为 `PTW-PMP-G1`，目标是把 PTE WRITE allow/deny、deny 时不产生 AXI `AW/W`、以及 current-source RTL 变体绑定到同一 design_id，不把 IFU-TVAL 局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU access current-design V9I

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`；本轮生产 `.v` RTL 未修改。
- `IFU-ACCESS-G1` 已由 V9I current-design 证据关闭：focused 4/4、module aggregate 109/109、PMEM 尾界 2B 读取、编译成功负向 RTL 变体 19/19、证据单测 10/10。
- 证据覆盖 4 个 instruction footprint、36 行 RRESP、14 行 2B EXEC PMP、`ARVALID && !ARREADY` 周期内的 `ARADDR/ARSIZE/ARPROT`、`ARPROT[2]` default-slave 选择，以及 12 行 lane0/lane1 PC/cause/tval owner 生命周期。
- result SHA-256 为 `bf6a81358d70d4b19e6a4ab5431d6e51d12f5c3bca61863d675e9c67f15c56ec`；raw log SHA-256 为 `1a7044ff18ff1df1942fc17863d51eb44668ade3b5559aa8a5d759c7954fd17a`。
- 九个 directed architecture gates 已按 DI-2 根依赖链重建并全 GREEN；full-core `architecture_freeze` 仍为 `GAP`、38 blockers，PPA 为 `UNQUALIFIED`、`promotion_eligible=false`。
- 长期 goal 继续 active；下一轮优先处理仍为 `STALE_EVIDENCE` 的 P0 `IFU-TVAL-G1`，随后处理 `PTW-PMP-G1`，不把局部闭包外推为全核或 PPA 完成。

## 2026-07-22 RV64 IFU fetch provenance V9H

- 当前 RV64 双发射 OoO 生产 RTL design_id 为 `sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc`。
- `IFU-FETCH-G2` 已由 V9H current-design 证据关闭：focused 2/2、module aggregate 109/109、current-source 可编译 RTL 验证变体 16/16、证据单测 10/10；生产 `.v` RTL 未修改。
- 覆盖 13 行 page-end 矩阵、9 条 F2/F4/F6 fault（5/3/1）、真实 invalid-PTE F0、两拍 response backpressure 事务 owner 保持、接受后两拍无年轻 instruction AR/cache fill/SRAM write，以及成功 packet 后无复位 stale-tail 反例。
- architecture directed gates 为 9/9 GREEN；公共验证入口变化触发的既有 CLOSED 证据已用 5 组 canonical 本地仿真重放恢复 current-design 绑定。
- full-core `architecture_freeze` 仍为 `GAP`，40 blockers；PPA 为 `UNQUALIFIED`，`promotion_eligible=false`。相较 V9G 的 41 blockers，净关闭一个架构债务条目。
- 长期 goal 继续 active；下一轮优先从仍为 `STALE_EVIDENCE` 的 P0（首选与本轮 IFU 数据流相邻的 `IFU-ACCESS-G1`）继续 current-design 重绑定，不把局部闭包外推为全核或 PPA 完成。
