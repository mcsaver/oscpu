# RV64 PPA 架构恢复任务报告

## 基本信息

- task_id: `2026-07-15-rv64-ppa-architecture-recovery`
- status: in_progress
- base_head: `31e90c679050a3a9138c967151b240f0fa2ab158`
- scope: 完整双发射、真 OoO 与 200 MHz proxy hard gate 下的 PPA Pareto 优化
- Linux: 按用户要求延后，不作为本轮候选晋级证据

## 不可交换的架构约束

- frontend cache-hit 稳态 initiation interval 必须为 1 packet/cycle。
- fetch/decode/rename/dispatch/issue/execute/retire 保持双宽；独立 ALU IPC≥1.90。
- ALU+ALU、ALU+branch/jump、ALU+load/store 两种程序序均须动态配对；lane 编号不得成为永久能力边界。
- 老 load miss/Mul/Div 未完成时，至少 8 条年轻独立 ALU 可先 complete，ROB peak≥9（1 条老指令 + 8 条年轻指令），retire 仍按序。
- memory ordering、selective squash、AXI drain、exactly-once complete/retire 不得退化。
- store 只在 ROB-head irrevocable/commit-authorized 后 exactly-once 发出真实写，ROB 退休
  等待聚合 AXI-B；`SLVERR/DECERR` 保持精确异常，不能降级成 retire 后 machine-check。
- 功能、架构、5 ns timing tier 任一失败，候选不进入 Pareto front。

规范入口：`npc/rv64/design/arch/rv64-architecture-ppa-contract.md`。
机器策略：`npc/rv64/eval/ppa/policies/proxy-200mhz-v1.json`。

## 合取式基线

| 锚点 | 作用 | 已知值 | 资格 |
| --- | --- | --- | --- |
| T4T proxy seed | 当前功能/logic-area/5ns proxy 种子 | CoreMark CPI 2.037237784182；Dhrystone10k CPI 2.796797448286；worst slack +0.179479554ns；logic area 1622367.04 | provisional；架构/同源/total area/power 不合格 |
| G2 performance | 历史取指吞吐恢复目标 | CoreMark 2852201 cycles / 3218573 retired，CPI 0.886169429744175 | timing 失败，仅作性能锚点 |
| R3.6 measurement anchor | 首个完整架构的性能/面积恢复比较锚 | CoreMark `4,904,511/3,183,617`；Dhrystone `9,481,620/4,250,000`；slack `+0.131591633ns`；area `1,605,803.92` | architecture-infeasible，永不晋级 canonical/front/champion |
| R4-P0A implementation floor | 当前不可回退 semantic/timing floor | 两 benchmark 与 R3.6 cycle-exact；slack `+0.103599802ns`；area `1,606,094.84` | correctness checkpoint；九门 RED、Power unqualified、not seed/front/champion |
| architecture floor | 防止以功能退化换 PPA | DI/OOO directed gates 全部 PASS | 当前尚未闭合 |

不存在一个点同时满足完整架构、qualified total area/Power 与最终功能闭合，禁止把不同设计的
绿点拼成“已达标基线”。新候选必须同时保留 R4-P0A 的 semantic/timing floor、对 R3.6 的
逐 benchmark 性能门，以及 architecture floor；不能任选其中最容易的一项比较。

### 历史工程基线（R2.5，已被 R3.6/P0-A supersede）

R2.5 曾是早期刀法的工程比较基线，不是当前优化起点或最终合格架构：

- 功能：module regression `102/102 PASS`；独立 `rv64si-p-icache-alias`
  `PASS`（2739 cycles / 224 commits）。普通 store 不再错误地全量失效 I-cache，
  仅 `FENCE.I`、`SFENCE.VMA`、`satp` 等序列化边界执行规定的 flush。
- 固定区间性能：CoreMark `5,384,674 cycles / 3,183,617 commits`；
  Dhrystone `9,581,693 cycles / 4,250,000 commits`。只允许同一 policy、同一镜像、
  同一固定区间比较，whole-run 计数不得混入 CPI 裁决。
- fresh 物理代理：logic area `1,617,113.96`，sequential area `446,322.80`；
  exact-5ns worst slack `+0.179479554 ns`、TNS `0`、violations `0`、loops `0`。
  两次综合输入与结果 bit-identical，netlist SHA256 以 evidence manifest 为准。
- 功耗仍为不合格证据：当前为 vectorless 且 macro internal/leakage 不完整；activity
  coverage `<95%` 或 macro 库不完整时，只报告 proxy P/A，不得宣称功耗或全 PPA 最优。
- 架构资格仍为 RED：当前只有一个完整 LSU/cache admission owner，DI-3/DI-5、
  OOO-2/OOO-3 尚未用 design-bound directed evidence 闭合。因此 R2.5 只能作为
  “正确且能过 200MHz proxy 的比较点”，不能作为最终交付冠军。

后续每个候选先做功能与九项架构 hard gate；任一 RED 立即淘汰。通过后再要求
`WNS >= 0 @ 5.000 ns`，最后才比较同源吞吐、macro-aware total area 与合格 activity
power。三轴互不支配者保留为 Pareto front；加权分只用于合格 Pareto 点之间决胜，
不得用性能收益抵消功能、架构或 200MHz 失败。

## 候选顺序

1. 后端 T4S：registered memory reservation 作为虚拟 lane0 owner 时，允许最老 independent simple ALU 从 lane1 独立发射。
2. 前端 PPA-R1：在保留 immutable context、flush/drop/drain 与 no-snoop 合同下恢复 cache-hit II=1。
3. 每刀按 directed TB → backend/module regression → fixed-image benchmark → fresh synth/STA 顺序裁决。
4. 无合格 workload activity 与 macro power 前，只能选 proxy P/A champion，不宣称完整三轴 PPA 最优。

## 当前状态

- S2-Q1 `OooMmuEpochOwner` 已完成 source-catalog adoption，无条件 GREEN：canonical 正例 2/2、
  assertion negatives 4/4、compile-success exact mutations 7/7、lint/style/Yosys/adoption 全绿，
  fresh module aggregate 104/104；但尚无 live instance，因此 live integration、双 memory、Linux、
  200 MHz 与 PPA 均保持 RED/unqualified。
- S2-Q2 仍是 mem0-only live implementation RED；v7 executable contract/checker 已收口到
  release/`OOO_ASSERT` 双变体 162/162 self-test、各 931/聚合 1862 项预期 live RED，contract/baseline/RED
  digest 分离锁定。结构门只证明
  下一原子实现的缺口清单可自动发现与审计，不证明 selective squash/full quiet/atomic grant、
  dynamic epoch/wrap、双 memory、Linux 或 PPA。
- AI 开发环境 v10 已闭合 live-profile-bound completion 与 transactional DB publication：节点前八元组
  现场回绑当前 profile include closure，首要 evidence 固定为 canonical node-owned log；dispatch 全序、
  11 字段 payload、逐资产 index 与七 artifact marker 均 fail-closed。generic sync 不得制造或撤销
  publication，只有 `publish-task-run` 可在单 SQLite 事务提交严格 EOF 完成记录；DB-first audit 将该不可恢复事务记录从 backup 必需项中精确豁免并反向禁止备份，普通 backup/snapshot 也不得吸收 publication，真实回归 14/14。brief 默认预算已与 CLI/API 对齐为 2400，1906 exact/少 1 token 边界仍 fail-closed。
  正式证据 `.github/task-runs/2026-07-18-github-index-5/`（agent-system 9/9）、
  `.github/task-runs/2026-07-18-agent-system-5/`（github-index 1/1）与
  `.github/task-runs/2026-07-18-rv64-ppa-3/`（npc-dev 5/5）均 completed 且
  `publication_valid=true`。这只证明 AI 工作流可信度，不改变 Q1/Q2 或 PPA 的 RED 边界。
- S1 typed correctness 已闭合；S2-G1 compatibility token/tuple + effective-kill
  子阶段为 intermediate GREEN，整个 R4-S1-ID 因真实 epoch 未完成仍为 RED：
  backend effective-kill/AMO restore/stale-drain、bridge killed escaped-write
  invalidate-only、以及 decode→slice→execute→glue→NpcCoreTop→bridge 的完整
  request/response/expected/query/drop/residency ABI 均已落地。bridge focused 在
  release/assert 两种构建覆盖真实 Sv39 A/D late-B、owner-mismatch fail-closed 与
  prewrite kill；wrapper checker `228/228`，constant-token mutation 预期失败，
  `tb_ooo_core_top_glue` 动态 exact-owner roundtrip PASS；`tb_ooo_sv39_boot` 只作为真实
  `NpcCoreTop + OooMemAxiBridge` module smoke PASS，不冒充整链 exact-owner 动态证明。
  source-bound leaf 证据为 `evidence/r4-s1-id-{owner-tracker,miq,sq,
  terminal-collector}-green/`，integration 证据为
  `evidence/r4-s2-g1-{backend-effective-kill,bridge-effective-kill,
  wrapper-exact-owner}-green/`；三份 integration manifest 的 198 个 source-hash 条目
  全部复核通过。全部 64 个 `/tmp/s2-g1*`
  顶层对象已原样复制到
  `tmp/2026-07-15-rv64-ppa-architecture-recovery/s2-exact-owner/system-tmp/`，
  788 文件、303,240,349 bytes 逐路径/类型/大小/SHA-256 对等。精确 17-path
  `npc-dev` strict guard 已由
  `.github/task-runs/2026-07-17-s2-g1-checkpoint-guard/` 证明 PASS；该 profile 只检查
  NPC/software-flow 入口合同，没有运行 Linux/NEMU Ubuntu。该子阶段仍是
  intermediate，不是 architecture-feasible seed；真实 effective MMU epoch、LQ4、
  双 AGU/translation/cache admission/completion、qualified power 与 200MHz 均待后续。
- 架构/PPA 合同、policy、T4T/G2 manifests 与 fail-closed checker/comparator 已落地。
- T4T checker：STRUCTURAL PASS、PROMOTABLE NO；默认 comparator 拒绝 provisional seed。
- 后端 virtual-lane0-owner 候选已完成 102/177/59 功能、A-B-B-A-A-B benchmark、
  fresh synthesis 与 exact-5ns STA。其 weighted perf +0.0457025%、logic area
  -0.0681030%、worst slack 不变，balanced score 100.056925，低于 100.2 门槛；
  同源/架构/功耗资格仍不完整，已作为 equivalent negative candidate 留档并回退 canonical RTL。
- frontend R2.5 已晋升为上述工程基线；fresh synthesis/STA 两次可复现。
- R3.1 已把 Universal/ALU terminal 改为逐 entry capability metadata + dynamic swap，
  消除程序 lane 到执行能力的静态绑定；`rv64si-p-icache-alias` 仍 PASS。它没有增加
  第二 LSU，故只使 DI-4 的结构证据转绿，不代表完整双发射内存。
- R3.2 actual-fire early wake + registered EX forward 的固定区间 proxy 相对 R2.5
  几何吞吐 `+5.3323%`（CoreMark `4,904,511/3,183,617`，Dhrystone
  `9,481,620/4,250,000`）。它最初在 official+privileged 的
  `rv64si-p-icache-alias` 暴露 `176/177 PASS`；逐周期证据定位到
  `clear_arch && clear_arch_squash && capture_arch` 同拍时，sequencer 的后写 NBA
  把 wrong-path illegal trap（PC=`0x8000031c`、tval=`0xc0001073`）在 squash 后重新
  置活，随后抢占合法 M-mode `SFENCE.VMA`。修复显式规定 squash/capture collision
  中 squash 胜出，并增加定向测试与 `GAP-6-COLLISION` 立即断言；没有回退 early
  wakeup、恢复普通 store I-cache flush 或禁用完整设计。修后 module regression
  `102/102 PASS`、official+privileged `177/177 PASS`、AM cpu-tests `59/59 PASS`
  且逐项 Difftest ON、alias clean binary 连续 `3/3 PASS`。功能门现为 GREEN；fresh
  synthesis run1 已完成：logic area `1,621,159.40`、sequential area `446,433.68`，
  相对 R2.5 分别 `+0.250164%` / `+0.024843%`；netlist SHA256
  `8f10c60f6f3caaa5d534d05432abc5c883d0e59adeb8dbeb429000ae0306bcb1`。但同一
  netlist 的 exact-5ns STA 为 WNS `-0.433356017 ns`、TNS `-26.716503143 ns`、
  top40 `40/40 VIOLATED`、loops `0`，故 run1 **timing hard-gate FAIL**，不启动无意义的
  promotion run2，也不得晋级 PPA front。
- 独立 PPA 审查还指出：R3.2 的 `base_area/candidate_area=0.9975046`，低于 policy
  `minimum_area_efficiency_ratio=0.999`；即使后续单独修到 5 ns，它也不能原样成为
  Pareto champion。其 balanced score 约 `102.503` 虽高于 `100.2`，但 score 不能洗掉
  timing、area-efficiency、architecture 或 power hard gate。R3.1 相对 R2.5 的几何吞吐
  仅 `+0.9187%`，R3.2 early-wake 相对 R3.1 为 `+4.3734%`，因此保留 early-wake 语义、
  优先压缩 selector 的 delay/area 是当前正确方向。
- R3.2 的失败已按同 Liberty、同 `valid_q[0]` 起点做 R2.5/R3.2 定向 STA。R2.5 最差
  issue→EX0 为 `+0.661019683 ns`，R3.2 为 `-0.433356017 ns`；R2.5 issue→EX1 为
  `+0.948570132 ns`，R3.2 为 `-0.424952984 ns`。top40 全部从 IQ entry0 valid Q 出发，
  先经 capability/oldest select，再过异步 PRF、registered-EX forward、整数结果网络，落到
  EX0/EX1 stage D。首条 EX0 路径中，IQ 内最后一级从 R2.5 的 `0.995739281 ns` 退到
  R3.2 的 `2.196393013 ns`（`+1.200654 ns`），已经超过总路径退化 `+1.093676 ns`；
  EX1 的 IQ 边界也从 `1.179801583 ns` 退到 `2.333209991 ns`。因此当前根因是 R3/R3.1
  逐 entry 串行 scan 中动态 swap/owner/memory 特例的组合深度，R3.2 registered forward
  不是主导根因。下一刀 R3.3 只重构为 packed-age 的并行 ready + balanced prefix
  first/second/first-ALU select，不增流水级、不撤 early wake、不恢复静态 lane 语义。
  定向报告在 `evidence/ppa-r3p2-early-wake/issue-ex-timing-diagnostic/`；首版诊断脚本因
  OpenSTA 不支持 `sizeof_collection` 被 fail-closed 并移入 workspace
  `tmp/2026-07-15-rv64-ppa-architecture-recovery/invalid-issue-ex-diagnostic-sizeof-collection/`，
  修正后两份报告均正常生成。
- R4 双银行 D-cache hit-path 已形成 isolated candidate：focused `1/1`、related `3/3`、
  full module `103/103`、negative mutations `4/4`，结构综合恰有两个
  `Sram4096x113`。该切片尚未接双 AGU/DTLB/LQ/SQ/completion/miss replay；现有宏形态
  物理位数 `925,696` 且半数 row 闲置，面积/漏电风险不可接受，故暂不合并。
- 双 AGU/翻译/物理查询/cache admission/completion frontend 已形成 isolated candidate，
  canonical 未改：wrapper 恰有 `2 x OooMemoryIssueLane + 2 x LSU`，64-cycle alternating-bank
  memory issue IPC=`2.000`，两路 AGU/translation/physical/cache/completion 均有非空计数；
  unsupported/misaligned、nonzero-offset full-forward、partial-block、same-bank retry、
  flush-after-fire drain/drop、store-preview miss、delayed lane0 PTW 不阻塞 lane1 等 directed
  均通过，mutation `4/4`、Verilator zero-warning、轻量 Yosys check0。manifest SHA256
  `1b8a4b11695ebe27cdac1aaba3cd98f2fc724b52f58d4f3e30bc321fdd9d46d2`，patch SHA256
  `145c80ccd209bad6907486c1e55d283a02a30a6e2d0ccdbbaa546bc08b0f21d9`。该 wrapper 尚未
  接 canonical IQ/backend、真实 LQ/ordering、双 bank cache、MIQ/commit-B/recovery，且现双 bank
  cache flush 会吞已接受 lookup response；因此 DI-3/DI-5、OOO-3/4 继续 RED，不把模块 2.0 IPC
  冒充整核 CPI。只有修复 response drain 并完成上述端到端集成后才进入全核 PPA 对抗。
- R4 physical SQ ordering 已在 `tmp/r4-memory-ordering-sandbox/` 形成隔离原型，canonical
  未改：双 valid/ready、SQ4 physical-byte/ROB-age query、两路 fill bypass、youngest
  winner、full-cover-only forward 的 directed scenarios `17/17 PASS`，可编译 mutation
  `7/7` 被杀，Verilator `-Wall` 与 Yosys check0 通过；manifest SHA256
  `e04f807a3ad4bfc9e3111cd6a3a76dcd1bae81e05e43f31e348ed76cb59c1c0a`。该 641 generic
  cell 结果不是 mapped PPA；canonical 仍缺 LQ/tagged transaction table/双 cache admission/
  flush-drain 集成，所以 DI-5、OOO-3/4 保持 RED。审查同时确认当前 SQ data/strb 已是
  request-relative，真正接口缺口是现有 snoop 仍导出 `vaddr_q` 而非已保存的 `paddr_q`。

## R3.3 RTL 推导摘要（接口冻结，候选实现中）

- **阶段 1 / 需求**：回收 R3/R3.1 dynamic steering 在 IQ→EX 路径新增的至少 `0.6 ns`，
  保持 8-entry、双 dispatch/双 issue、动态 capability swap、registered owner、R3.2 N→N+1
  RAW latency；不以静态 lane、删复杂能力、增流水拍或放宽 memory 顺序换时序。
- **阶段 2a / 协议**：外部端口和 valid/ready/fire 公式不变；选择只读 Q，wake 只写
  next-state；swapped memory capture 继续以 older ALU fire 为原子前件。
- **阶段 2b / 状态机**：不新增 FSM/寄存器。现有 reset/flush、kill-suffix、normal
  compaction+append 三类时序分支和优先级保持不变。
- **阶段 2c / 不变量**：新增 packed valid-prefix 与 balanced A/B/S 对 reference scan 的
  cycle-exact 等价；保留 IQ-I1..I16、双向 RAW、owner exclusive、sticky wake 与 no-bypass。
- **阶段 2d/2e / 数据通路拓扑**：8 路本地 eligibility → 3 级 associative prefix
  (`any`,`multiple`) → `first-ready/second-ready/first-ALU` one-hot → 固定真值表 terminal
  steering → one-hot payload/index；共享资源仍是一个 Universal 与一个 ALU terminal，
  mux enable 来自 terminal one-hot。预计关键路径不再穿过 8 次可变 index 的串行状态依赖。
  function 仅允许小型纯组合 one-hot helper；仲裁主体保持显式组合网络。
- **验证门**：reference-scan cycle compare、完整 pair permutation/owner/memory ready
  `00/01/10/11`、packed-hole negative、focused/module/full functionality、fixed benchmark，
  最后 fresh synth/STA 两轮。任何功能/架构失败或 slack `<+0.10 ns` 均拒绝。

## R3.4 RTL 推导与预验证（接口冻结，canonical 已实现）

- **需求**：在不削弱 dynamic capability steering 的前提下，让物理 ALU terminal 与其
  simple-ALU/IMM allow-list 一致，删除当前语义不可达但仍被综合保留的第二 bitmanip 与
  通用结果臂，至少消除 R3.2 `0.9975046 < 0.999` 的 area-efficiency blocker。
- **协议/FSM**：无接口和状态变化；issue1 actual fire、EX register、formal WB/ROB/PRF 与
  early wake 拍点不变。非 capable uop 永远由 Universal 接收；若越界到 issue1，立即断言失败。
- **不变量**：ALU terminal control 必须满足 capability；其 WB 仅 ALU/IMM，exception/cause/tval
  恒零；删掉的 complex 资源在 Universal 上仍有非空 directed 证据。
- **拓扑**：issue1 PRF/registered-forward → operand mux → RV64I ALU → ALU/IMM 二选一 → EX1
  register；不再经过 `OooBitmanipGate` 或通用 WBU。资源复制保留两套 ordinary ALU，只删除
  capability 合同禁止的第二套 complex gate。
- **验证门**：capability pair/permutation、forced-violation negative、bitmanip/CLMUL 走
  Universal、module/full benchmark、mapped hierarchy instance count/area 与 exact-5ns STA。
- **当前预验证**：focused `tb_ooo_int_issue_queue/tb_ooo_int_backend/
  tb_ooo_alu_decode_backend` 为 `3/3 PASS`，全核 Verilator lint 与 RTL style PASS。独立
  capability mutation 从真实双 simple issue window 分别强制 BITMANIP 与 `WB_SEL_PC4`，
  backend/IQ 两级 marker 均精确命中（两种 mutation 共四个 expected assertion，脚本
  PASS）；首版结果检查只预期 backend 两条 error，因同时命中 IQ carrying-contract 而
  fail-closed，原始日志已移入
  `tmp/2026-07-15-rv64-ppa-architecture-recovery/invalid-r3p4-negative-error-count/`。
- **结构证据**：轻量 Yosys `prep; check; stat` 为 check0，`OooIntBackend` 下恰有
  `2 x ALU`、`1 x OooBitmanipGate`、`1 x WBU`，证明第二 complex/WBU 实例已从 RTL
  hierarchy 删除；这不是 mapped area 或 STA 结果，仍必须与 R3.3 合并后做 fresh exact-5ns
  synthesis/OpenSTA。独立 R3.2/R3.4 审计 SHA256 为
  `106da00e450a4e3f97040b64f9a07aae6595ea981aea5d8bfcf4ec072b9d366d`；按 R3.2 mapped
  单实例面积 proxy，删除一套 bitmanip 的毛潜力约为本轮最低面积回收需求的 `5.25x`，
  但在 fresh mapped netlist 前不宣称净面积改善。

## R3.5/R3.6 时序恢复裁决

- R3.3 balanced selector 与 R3.4 单 complex terminal 合并后，完整功能和固定区间性能均
  保持 R3.2 水平；fresh mapped area 为 `1,605,903.32`。但 exact-5ns 最差裕量仍为
  `-0.194234863 ns`、TNS `-2.918693304 ns`、30 条违例，不能晋级。
- top30 全部从 `IntIQ.valid_q[0]` 出发并落到 EX0 result；路径分解表明 selector one-hot
  已经形成后，又经过 onehot→index→indexed payload mux→异步 PRF。最差路径组成约为
  selector `0.977 ns`、payload mux `0.632 ns`、PRF `0.814 ns`、forward `0.180 ns`、
  bitmanip/CPOP `1.931 ns`、尾部 `0.278 ns`。因此优先消除重复编解码，而不是删除完整
  complex 能力或恢复静态 lane。
- R3.5 把 rotate 改为显式分级 mux；独立验证覆盖 47,880 个动态向量、六种模式 SAT、
  226/226 等价。fresh area `1,604,736.28` 略降，但最差裕量反而退到
  `-0.293579847 ns`、34 条违例，按 timing hard gate 拒绝并回退 canonical RTL。首版
  directed RORI 激励编码错误的结果已明确标为 INVALID，不进入证据链。
- R3.6 只让 issue0 的两个整数 PRF 源读直接使用已有 one-hot winner 的平衡 AND/OR 树；
  issue1、age/pop/compaction、capability steering、memory owner 和 fire 协议均不变。独立
  sandbox 覆盖 entry0..7、invalid、packed-hole fail-closed 与 `5/5` mutation，组合锥深度
  `25 -> 23`；focused `6/6`、module `102/102`、lint/style 全部 PASS。
- CoreMark 固定区间连续三次均为 `4,904,511 / 3,183,617`，CPI
  `1.540546805724`；Dhrystone 连续三次均为 `9,481,620 / 4,250,000`，CPI
  `2.230969411765`，且二进制/配置/RTL 前后 binding 与语义签名一致。相对 R2.5 的
  几何吞吐改善为 `5.332333%`。
- 两次 fresh synthesis bit-identical：logic area `1,605,803.92`、sequential area
  `446,433.68`、netlist bytes `64,978,328`、SHA256
  `2bc1376369265693d0268f93828002b9ead04a81a1d6946243d260f85d0ddf7d`。两次 exact-5ns
  STA 也完全复现：worst slack `+0.131591633 ns`、TNS `0`、violations `0`、loops `0`。
  相对 R2.5 area 降 `0.699397%`，相对 R3.3/R3.4 area 再降 `99.40`，并回收
  `0.325826496 ns` 裕量。
- 因此同时满足性能重复性、mapped area 改善和 `+0.10 ns` timing reserve，R3.6 晋升为
  **下一轮 P/A+5ns proxy 工程基线**。它仍不是最终冠军：canonical 双内存端到端尚未
  闭合，Power 仍为 vectorless 且缺 workload activity/macro internal+leakage model，
  5 ns 也只是 partial-constraint RTL proxy、不是 post-route sign-off。

## 合同加固与下一架构切片

- policy 现在强制归档 architecture directed suite、硬门总结果以及 DI1..DI5、OOO1..OOO4
  九个逐门 artifact；directed suite 名称必须与九项清单精确一致，不能靠额外/缺失测试
  或手写布尔值绕过。
- `check.py` 在 artifacts 存在时重新对 live RTL 执行 architecture evaluator，并比较归档
  semantic projection；`architecture_hard_gates.py` 明确要求 long-latency 场景
  `ROB peak >= 9`。加入恢复基线 fail-closed 检查后，合同单测 `50/50 PASS`。
- 双内存 causality checker 隔离候选已覆盖 64 周期双 owner（IPC `2.0`）、cacheable
  `OKAY/SLVERR`、device `DECERR`、精确 trap/recovery 与 `8/8` mutations；但尚未绑定
  canonical 信号，因此只能证明 checker 能杀错，不能把 DI5/OOO3/OOO4 标绿。
- corrected dual-bank、post-translation physical SQ/precise-store authorization 和双 lane
  frontend 均已在 workspace `tmp/` 留档并各自通过 directed/mutation/lint。下一步必须按
  同一个 canonical image 依次接入双 AGU/翻译/final-PA ordering、双 cache admission、tagged
  completion、ROB-head store authorization 与聚合 B；在这条因果链闭合前不跑 Linux，
  也不把几个 isolated green point 拼成全核架构通过。

## R4-S0 post-translation correctness checkpoint

### 身份与允许宣称

- candidate：`r4-s0-posttranslate-memory-semantics`
- parent measurement anchor：`r3p6-onehot-prf-recovery-20260715`
- disposition：`correctness_checkpoint / ppa_diagnostic_only`
- promotable：`false`
- 允许宣称：最终 PA/PMA/PBMT cacheability、SQ 保存/回传、B-terminal D-cache alias
  维护已闭合；在 fail-closed partial-constraint STA 下达到 200 MHz proxy。
- 禁止宣称：typed NC/IO ABI、完整双 memory issue、architecture-feasible seed、Pareto/front、
  qualified power 或三轴 PPA champion。

机器记录：`npc/rv64/eval/ppa/baselines/r4-s0-correctness-checkpoint.json`。baseline index 的
`canonical` 与 `architecture_feasible_seed` 继续为 `null`，R3.6 仍是不可晋级的工程测量锚。

### 接口冻结与 RTL 推导

1. **需求**：修复“translated PMEM PA + leaf PBMT NC/IO 仍按 PMEM 进入 D-cache”以及
   store B-terminal 仅按地址猜 cacheability 的语义洞；不降低现有 R3.6 性能，不新增
   静态 lane，不在 S0 冒充 typed ordering。
2. **协议**：Bare/DTLB-hit 与 PTW-leaf 成功路径统一进入
   `OooPostTranslateMemoryClass`；最终 `access_cacheable_q` 与 response 同 owner 输出。
   probe success 将 `{original VA, final PA, final cacheability}` 写入 SQ；physical
   `pretrans+nokill` drain 只读 SQ 保存值，不重新看 PTE/PBMT/地址范围。
3. **状态/FSM**：不增加 transaction FSM。`access_cacheable_q` 在最终分类点锁存，保持到
   response；SQ `cacheable_q[entry]` 从 fill 到 release 稳定。B terminal 与 B OK 分离：
   terminal 负责 alias maintenance，只有 all-OK final-cacheable ordinary store 允许 RMW。
4. **不变量**：PMA/PBMT fault 与 success class 互斥；PBMT NC/IO PMEM 不得 lookup/fill/RMW；
   NC/IO、A/D、B error 必须失效可能存在的 PMEM alias；cross-line 同时失效 p1；aggregate
   B error 即便只有后一 split beat 失败也保守失效；store 外部写仍须 ROB-head 精确授权。
5. **数据通路拓扑**：classifier → bridge `access_cacheable_q` → response sideband →
   backend → SQ entry → physical drain sideband → bridge request station → B terminal D-cache
   maintenance。审查证明该 sideband 只落 SQ 状态，不组合返回 load-hit/WB 关键锥。

S0 的 Boolean `cacheable` 故意仍合并 NC 与 IO；S1 的 normative 编码是
`attr_valid + class[1:0]`（CACHED/NC/IO，fault 独立），S2 才接两个独立
AGU/translation/final-PA/order/cache-admission/tagged-completion owner。

### 功能与非真空证据

| 门 | 结果 | 裁决 |
| --- | --- | --- |
| focused classifier/PBMT/alias/B-error/backend E2E | PASS | 覆盖 2x2x4 分类、hot alias bypass、SQ 保存/回传、cross-line 与 aggregate B error |
| full module | `102/102 PASS` | summary SHA256 `4e9fd71dc53eaac92ffdb661b886e573db43a6ceaeb9eb10dbbf05e480956709` |
| assertion negative | `4/4 PASS` | 三个 classifier marker 各精确一次；D-cache retained alias 精确命中且 `rc=1` |
| lint/style/fresh sim build | PASS | 无功能 RTL warning 回退 |
| official / AM / Difftest same-image | 未运行 | S0 不是 promotion candidate；保持 blocker，不用历史绿点拼接 |
| Linux | deferred | 按用户要求不跑 |

九项 architecture evaluator 对当前 136 个 RTL source、design id
`sha256:9764d762d08c96cd2858e77a9c72ab415704f316bd57623c1edd4fb977c22e92`
实时退出 `1`；DI-1..DI-5、OOO-1..OOO-4 全部 RED，且缺 directed manifest。这个 RED 是
正确的 fail-closed 归档，不是测试失败待隐藏。

### 性能、面积、时序、功耗对抗

| 轴 | R3.6 anchor | R4-S0 | 对抗结论 |
| --- | ---: | ---: | --- |
| CoreMark | `4,904,511 / 3,183,617`，CPI `1.540546805724` | 三次逐计数相同 | throughput ratio `1.000000` |
| Dhrystone10k | `9,481,620 / 4,250,000`，CPI `2.230969411765` | 三次逐计数相同 | throughput ratio `1.000000` |
| logic area | `1,605,803.92` | `1,606,423.28` | `+619.36 / +0.038570%`，过 2% checkpoint guard，也仍在 0.999 strict area-efficiency 上限内 |
| sequential area | `446,433.68` | `446,470.64` | `+36.96 / +0.008279%` |
| exact 5ns slack | `+0.131591633 ns` | `+0.059167784 ns` | 200 MHz PASS；`+0.10 ns` promotion reserve FAIL |
| TNS / violations / loops | `0 / 0 / 0` | `0 / 0 / 0`，top40 `40/40` | 两份 v2 fail-closed STA semantic-exact |
| power | unqualified | vectorless diagnostic `0.121 W` | activity/macro incomplete，轴保持 RED |

性能六轮虽然 counters bit-exact，但不是 A-B-B-A-A-B，且 image 未进入每轮 runtime pre/post
binding；当前 image SHA 只作为 `posthoc_current_image_inventory`，所以这些计数只支持 S0
diagnostic，不支持 promotion。若未来候选晋级，必须将 image 纳入运行时冻结后重跑。

两次 fresh synth 的输入、工具、面积、模块数与 65,026,141B 网表大小完全相同；raw SHA
分别为 `e163cca3...` 与 `6a93fb3f...`，不能写 bit-identical。逐 module 的 structural
statement multiset 完全相同，canonical SHA256 都为
`a7b29effd9bbf25223a2aeffa235c8d6fbdaf4ec64d5215e8b2cb394370a2140`；6291 个物理行差异
仅是 Yosys serialization order。两份独立 v2 STA 均严格绑定各自 netlist 并得到同一时序投影。

### 实施者 / PPA 审查者对抗裁决

- 实施者：S0 必要语义全部保留，功能与性能无回退，面积代价仅 0.03857%，应保留。
- Performance 审查：两 benchmark 无变化；该切片不解释低 CPI，也不冒充双 memory 吞吐。
- Area 审查：classifier 两实例仅约 22.4 area，净增主要来自 backend/bridge/SQ 状态与映射；
  总增量小于 strict 0.999 预算余量。
- Timing 审查：`72.424 ps` slack 回退不经过 classifier/cacheability sideband；关键锥是
  SRAM tag compare → hit fusion → MIQ pop/WB1 → PRF write decode，属于 ABC 对原控制锥的
  area-for-delay 重映射。不能以删除 S0 语义“修时序”。
- Power 审查：没有 workload activity 与 macro internal/leakage，拒绝给 Power 绿灯。
- 终局裁决：保留 S0 为 correctness checkpoint；R3.6 仍为 P/A+5ns 工程测量锚；下一刀
  先在保持一拍 hit fusion 下恢复至少 `40.833 ps` reserve，再进入 S1 typed ABI。

## R4-S0 时点的最优与未闭合项（历史，已由 P0-A 更新）

- R4-S0 时点可诚实给出的最优是 R3.6：功能回归通过、吞吐优于 R2.5、面积更小且两次满足
  exact-5ns proxy；P0-A 随后成为当前不可回退的 semantic/timing implementation floor，
  R3.6 继续作为性能/面积 measurement anchor。
- 当前 formal Pareto/PPA champion：**无**。architecture feasible set 仍为空，Power 轴
  也不合格；任何“完整 PPA 最优”结论都会违反本任务的 fail-closed 合同。
- R4-S0 达到 200 MHz proxy 但 reserve 只有 `+0.059167784 ns`，并且九项架构门全 RED；
  它是语义 floor，不替代 R3.6，也不是 architecture-feasible seed。
- P0-A 之后的对抗必须从其 semantic/timing floor 继续，并同时相对 R3.6 守住逐 benchmark
  性能门；每一刀按功能/九项架构门 → 5 ns → 同源 performance/area/activity-qualified power
  顺序裁决，任一硬门失败即回退。

## R4-P0A distributed write-valid timing recovery checkpoint

### 改动与不变量

P0-A 只把 `OooIntBackend` 两个 GPR 写端口的 `wen` 从集中式 WB mux 后判定，改为由最终
WB owner 的 `valid && pdest!=0`（FP 额外要求 `rd_en`）直接产生。两 lane 的 EX、MEM、
MULDIV、CLMUL 与 FPWB owner 均有非零覆盖；WB data、ROB completion、exception、execute-valid、
pipeline/FSM、PRF port 数和 capability steering 均未改变。该刀不删除复杂能力、不创建静态
lane 语义，也不触碰 S0 post-translation correctness floor。

### 冻结证据与三轴对抗

| 轴 | R4-S0 | R4-P0A | 裁决 |
| --- | ---: | ---: | --- |
| CoreMark | `4,904,511 / 3,183,617` | A-B-B-A-A-B 共六窗逐计数相同 | ratio `1.000000` |
| Dhrystone10k | `9,481,620 / 4,250,000` | A-B-B-A-A-B 共六窗逐计数相同 | ratio `1.000000` |
| logic area | `1,606,423.28` | `1,606,094.84` | `-328.44 / -0.020445%` |
| sequential area | `446,470.64` | `446,470.64` | 不变 |
| exact 5ns slack | `+0.059167784 ns` | `+0.103599802 ns` | `+44.432018 ps`，重新满足 `+0.10 ns` reserve |
| TNS / violations / loops | `0 / 0 / 0` | `0 / 0 / 0` | PASS |
| power | unqualified | vectorless diagnostic `0.121 W` | 仍 unqualified，不参与三轴冠军裁决 |

- focused matrix `22/22 PASS`，覆盖 2 lane × 5 owner 的 `pdest!=0/pdest=0` 及两路 FP
  `rd_en=0,pdest!=0`；标准 backend、equivalence/onehot mutation-negative、lint/style/contract
  均 PASS。full module 为 `102/102 PASS`。
- 性能 runner 把 CoreMark/Dhrystone image、A/B RTL、sim binary 以及
  `cpu-exec.cpp -> depfile -> object -> binary` 编译依赖链全部放入每窗 pre/post freeze；两
  benchmark 各执行 `A-B-B-A-A-B`，12 个窗口全部 PASS，避免 S0 的 post-hoc image 缺口。
- 两次 fresh synthesis 的 117-file elaborated source closure 逐文件 hash 相同；面积、模块数、
  网表大小与 netlist SHA256
  `460ff75ae20e66a5aad58103507aabe63f1c7c09072137c55ce9f70720c45937`
  byte-identical。两次 STA 的 timing semantic projection 也完全相同。
- 加固后的 aggregate checker 不只比较 pre/post manifest 文本，还实时重算两次 run 各 117 个
  synthesis input；`checkpoint-audit-v2.json` PASS，SHA256
  `2847ae2e1b075ba7743cc8affb1220f185eed4e0dbe176fda0fe2aac6ba54fb8`。
- P0-A live architecture snapshot 的 design id 为
  `sha256:5ab313435529cc263bde93704983ea233afc99f327342310086e7b18d8f520da`；九项
  DI/OOO gate 仍全部 RED。这是正确的 fail-closed 状态，因此 P0-A 只能是
  `timing_recovery_correctness_checkpoint`，不能成为 architecture seed、Pareto front、
  canonical 或 PPA champion。

关键路径已从 S0 的 D-cache tag→WB/PRF 控制锥移到 DTLB/PMP bridge 锥；因此预研的
P0-B balanced D-cache tag candidate 不会改善新的全局最差路径，已带 replay patch 与哈希
归档为 deferred candidate，没有合并进 canonical RTL。

## R4-S1.0 typed memory ABI contract freeze

S1.0 先冻结、后实现，规范真源为 `design/specs/ooo-memory-typed-abi.md`：

- class 编码固定为 CACHED=`00`、NC=`01`、IO=`10`、RSVD=`11`；`attr_valid` 资格与 fault
  terminal 分离，pre-target fault 无 attr，已发出的 AXI R/B post-target fault 保留 class/PA provenance；
- PMEM=CACHED，PSRAM residual/SDRAM=NC，真实 device=IO；PMEM 对重叠 PSRAM decode 优先。
  PBMT 在 final PA 后只合并一次，PBMTE disabled 的非零 PBMT 与 PBMT=`11` 均形成 page fault；
- owner identity 固定为 `{owner_kind[1:0], owner_token[4:0], mmu_epoch[1:0]}`，原始 VA
  `fault_tval`、final PA/class/token/epoch 从 owner 创建保持到 release；store probe 与 physical
  drain 是同一个 STORE owner；
- NC 与 IO target ordering 分开，但所有 store 的真实外部副作用仍只能由 ROB-head
  `commit_authorized` owner 按程序序 exactly-once 发出；
- S1 只允许形成 typed single-owner correctness checkpoint。第二 AGU、双 translation slot、
  双物理 order query、双 cache admission 与 tagged completion 在 S2 前继续 RED，不能把规范字段
  或兼容 adapter 当成双 memory 实现。

下一实施顺序为 PMA/classifier 真值表 → bridge request/response attr/fault → backend/SQ 保存与
回传 → token/epoch 生命周期 → NC/IO ordering 分流；每个切片都必须保持 P0-A 的性能、面积预算与
`+0.10 ns` timing reserve，若某一维退化则与保持完整架构的替代实现对抗，而不是删除必要语义。

## R4-S1.1 typed PMA/classifier leaves

S1.1 已实现 typed 真值叶模块，但故意没有改变 live bridge：

- `OooTypedPmaChecker` 对完整 byte range 输出 CACHED/NC/IO/RSVD，PMEM 优先于重叠
  PSRAM；PSRAM residual/SDRAM 为 NC，真实设备为 IO；跨属性边界、wrap、stub/default
  fail closed。
- `OooTypedMemoryClassifier` 分开 `pbmt_valid` 与 `pbmte`，覆盖 PBMTE enabled 的
  PMA `{CACHED,NC,IO,DENY}` × PBMT `{00,01,10,11}` 16/16，以及 PBMTE disabled
  translated leaf 同一矩阵 16/16；包括 DENY+nonzero PBMT 的 page-fault 优先级。
- 三个非法 producer/RSVD poison 输入在无断言 build 中仍 fail closed，三个 OOO_ASSERT
  negative marker 各精确命中；PMEM-over-PSRAM priority 与 PBMTE 判据两种 mutation 均被
  directed TB 转 RED。
- 叶模块 lint、全核 Verilator lint、三项 Yosys check、style/whitespace 均 PASS；正式 evidence
  的 SHA256SUMS 与 10 个 workspace-relative live source binding 全部复核通过。summary SHA256
  为 `b46900258a117bf851c79b33b97376fed7fc216391ae05f758ca18e3971a611c`，manifest SHA256
  为 `acb3013a2450e3badb958be05dc19e7d76384b75728dab67b5a8c28305f73224`。
- 独立审查发现并关闭两个真实 blocker：直接扩展旧 `OooPmaChecker` 会让全核 lint 出现
  `PINMISSING`；以 typed checker 包装旧 checker 会把跨 PMEM→PSRAM-residual footprint 从 S0
  allow 静默改成 deny。最终旧 checker 恢复为 P0-A byte-exact SHA256
  `e197b137bfe1126f9191eaf3b2cfce779d26bdce0ead4a94d831552fe5732c2b`，有意行为切换留给
  S1.2 原子 bridge 迁移。
- 所有被否决/partial runner 现场均原样移入 workspace
  `tmp/2026-07-15-rv64-ppa-architecture-recovery/invalid-r4-s1p1-*` 并带 README/hash，未混入
  正式 evidence namespace。

S1.1 不产生性能、面积或时序变化 claim，也不能解除任何架构门。bridge/D-cache/SQ/backend
尚未消费 typed attr，token/epoch 与第二 memory owner 均不存在，所以 S1、S2、DI-3、DI-5、
OOO-3 继续 RED。下一刀 S1.2 必须把 bridge station/active/response 作为一个原子接口组迁移，
不得用悬空输入、地址重分类或把 NC/IO 再合并成同一 routing authority。

## R4-S1.2 typed ABI focused integration

S1.2 已把 typed memory truth 从叶模块原子贯通当前单 owner 数据链，但仍保持
`intermediate_checkpoint`：

- bridge request station、active state 与 response 独立携带 `attr_valid/class/cacheable`；最终
  class 只由 final PA 的 typed PMA/PBMT 合并产生；PMP deny 只 poison 最终 attr，不得压掉更早的
  PBMT/PTE page fault；fault 顺序固定为 page > PMP access > PMA access；
- CACHED 才能发 D-cache lookup/fill/RMW；NC 走 exact AXI data read，IO 等精确 owner release/cancel；
  pre-target fault 输出 invalid/RSVD，已发出 R/B 的 post-target error 保留分类 provenance；
- backend 普通 VA load/store 请求固定 invalid/RSVD，删除 VA→PMEM/MMIO 推断；SQ 保存 probe 的
  PA/class 并在 physical drain 原样回放；AMO/LR/SC 继续沿既有 LEGACY precise path；
- 对 class 尚未知的 younger load，任意 older nonterminal SQ owner 是 blind barrier；完整覆盖且
  typed non-IO 的 store-to-load forwarding 仍可绕过，定向用例真实命中
  `sq_block=1 && sq_fwd=1`，无 younger bridge response而在 B 前形成 local WB，最终恰好一次提交；
- bridge、backend、SQ、typed classifier 与三个 wrapper focused 全绿；backend/bridge 独立复跑全绿；
  B `OKAY/SLVERR/DECERR` 在 terminal 初拍及 response backpressure hold 拍的公开
  `attr_valid/class/cacheable` 均稳定。forwarding 证据是公开激励/commit oracle 加分层时序 oracle，
  非纯黑盒，未将其夸大为纯黑盒证明。

S1.2 的 architecture evaluator RTL design id 为
`sha256:4a7d748a600096fa8010abbcef0245f6f524786fb0a2ab42857c7db6f81cf5fa`，共 138 个 RTL
source。内容寻址 bundle SHA256 为
`a80d45cb559652773c43fe6a765eff2bba7607e968b9565703b26c4a8a87adf1`；tar 内 138 个 member
已逐个与 source-set manifest 复核。所有 29 个相关 `/tmp/s1-*` 文件（含失败迭代、build 和独立
复跑）已归档到 workspace，并由 SHA256SUMS 逐文件验证。

本切片没有运行 Linux、完整 103 项 regression、benchmark、synthesis、STA 或 PPA；R4-P0A
仍是语义/时序实现底线而不是本 source 的新时序测量。102/103 inventory 漂移、九项 architecture
directed evidence、第二 AGU/translation/order/cache/completion、LQ4、single reservation 和 Power
资格均未闭合，因此 seed/front/canonical/champion 继续为空。

## Executable global DSE archive companion

附件元策略已转成非规范、fail-closed 的 executable archive 层：

- `dse-archive/check_archive.py` 与四份 schema 机器区分 intermediate/complete，维护
  feasible/development/high-uncertainty/diversity 四池；
- 完整点必须 `design_id=sha256:<immutable source bundle>`，绑定实算 test inventory、全部 hard
  gates、两个 workload 最差项、qualified area/power 和固定 evaluation order；
- Power activity coverage/macro model 未闭合时不得进入 formal 三轴 front；single scalar 只能排同一
  front；seed 不能直接成为 champion；P/A/Power role 的中间或完整点都必须绑定同一个 seed；
- append-only ledger 用 canonical-JSON SHA chain；每四个 complete design point 后下一 event 必须是
  至少两个完成父点的 global thaw；
- archive focused tests `12/12 PASS`，production registry checker PASS；102/103 drift 被机器编码成
  formal front/promotion blocker。

S1.2 已登记为 development + high-uncertainty，而不是 Pareto 点；point manifest SHA256
`3440827d275ae7443fc7f24490565efbd79a838d125a84d04e4869d5940abb19`，ledger head
`876339a2057f20afc1705b2c46917d1dd1713bc64998c563185fc1f6ab5014f6`。下一完整 correctness
checkpoint 是 `R4-S1-ID exact-owner-provenance`：先在现有单宽链闭合真实
`{owner_kind, owner_token, mmu_epoch}` 与 ABA/kill/drop 生命周期，再启用第二 AGU。

## R4-S2-Q0 local bridge registered-fact idle

Following the committed S2 exact-owner compatibility checkpoint, Q0 adds an
explicit local `mem0_idle_o` to `OooMemAxiBridge` and source-binds it through
`NpcCoreTop` without consuming it in control. The fact is a combinational
conjunction of registered FSM/station/drop/nokill/partial-write/D-cache-RMW and
owner-residency state. It intentionally excludes READY/fire/equality/context
inputs and is not re-registered, preventing both a quiet combinational loop and
a one-cycle false-idle window.

Focused release/assert runs are 2/2 PASS across station, AR/R, AW/W/B, S_RESP,
reachable RMW, and PTW A/D paths. The state-only and sticky-low mutations each
terminate at one exact expected fatal. The existing bridge compatibility and
133-entry wrapper source-bound integration runners both pass after rerun; all
15 + 18 + 133 live manifest entries recheck OK.

All ten related `/tmp` runner directories, including failed attempts and the
final wrapper main run, were copied path-for-path into the workspace. The
checker passed with 66 files, 17 directories, 0 links, and 146,778,084 file
bytes. The durable `system-tmp.tar.zst` SHA-256 is
`57ebc9ec18527051081131b359eb38f2745daf9e0f4d9af41bf8ba4e49af3ccb`.

This is only an intermediate Q0 GREEN. The standalone epoch owner, exact
effective context classifier, pre-transition lock/selective squash, full quiet,
grant-gated CSR/trap/xRET/SFENCE state update, true dual-memory datapath, and
200 MHz/PPA qualification remain RED/unqualified. It is not an
architecture-feasible seed or Pareto point.

## R4-S2-Q1 MMU epoch owner source-catalog closure

Q1 has advanced from leaf-only focused GREEN to a registered source-catalog checkpoint:

- the canonical runner is now the only runnable entry and binds release/assert positives,
  four full-message assertion negatives, seven compile-success unique-oracle source
  mutations, strict release/assert lint, style, Yosys, adoption contract, source hashes,
  and tool versions;
- the exact helper oracle checks the held pre-increment epoch, the formal module harness
  sees both the focused marker and exact shared PASS line, and the leaf appears exactly
  once in `print-synth-rtl`;
- fresh module regression is `104/104 PASS`. The first aggregate run exposed a
  pre-existing partial typed-ABI migration in `tb_ooo_priv_system`: new response
  provenance/owner ports floated and generated `X`. The TB now reuses
  `OooTypedPmaChecker`, latches request owner/epoch/tval into the response, and
  models drop/residency explicitly; its focused rerun and the full aggregate pass with
  assertions still enabled.

Evidence is under
`evidence/r4-s2-q1-mmu-epoch-owner-adoption-green/`. This checkpoint still does
not instantiate Q1 in the live core. ROB precommit qualification, effective CsrFile
old→next classification, capture-only blocking, selective memory squash, complete quiet,
grant-gated apply/invalidate/LR-clear, live epoch propagation, dual memory, Linux,
200 MHz, and PPA remain RED or unqualified.

## R4-S2-Q2 live epoch atomic-slice contract/checker hardening checkpoint

Q2 remains an implementation RED. Its next atomic slice is captured as an executable,
machine-mapped hardening checkpoint rather than an informal wiring sketch; it is not yet called an
implementation-ready/final interface freeze:

- the barrier order is `CAPTURE -> SQUASH -> WAIT_QUIET -> GRANT`. Younger SQ/fetch work is
  selectively squashed by held ROB age before SQ quiet is sampled; the Q2 full-quiet result is
  forbidden from feeding the existing `OooRob.mem_quiet_i`, closing the head-boundary/younger-SQ
  deadlock found by independent review;
- every potential context/I-side boundary is forbidden from commit1. Q1 accepts only a stable
  head0 identity, and its request is generated from a commit-ready-independent precommit plus
  CsrFile legality/WARL/PMP-lock normalized old-to-next result;
- IFU uses generation-matched sticky drain-and-block: context/FENCE.I requests capture generation,
  ack only after fetch/PTW/FPC cancel-or-drain, and top rechecks returned generation. FENCE.I has a
  separate store-retire+mem-idle+IFU-drain retire permit and still cannot advance the data-MMU epoch;
- capture block gates only new owner creation. Existing reservation/buffer/MIQ/SQ nokill/AMO/
  AXI/PTW/RMW work must continue to drain, and bridge level flush cannot substitute for selective
  age-based squash;
- the interface manifest fixes the NpcCoreTop owner host, CsrFile/Q1 same-edge consumers, five-level
  wrapper bundle, ROB permit/precommit path, full-quiet dependencies, forbidden capture-block sinks,
  and valid-owner dynamic-epoch captures.
- v7 requires exact current-vs-held head equality plus one registered abort fire shared
  by the sticky Q1 owner and CsrFile reservation, exact canonical boolean equations, a registered
  CsrFile writer reservation with deferred competing trap/IRQ sources, unique-next writers for
  privilege/context/deferred payload plus six trap-envelope CSRs, LR and IFU/FENCE transaction state;
  canonical named DTLB/ITLB/FPC, redirect-arbiter/PC-writer and pending-clear leaves are exact-mapped;
- the checker now preprocesses the default active source and locks the full non-evidence manifest
  projection, exact `[WIDTH-1:0]` ranges, concrete payload/cause macro values, strict reset/unique-next
  control flow, all canonical instance names, registered quiet/memory ack, real IFU leaves, atomic
  grant consumers, valid epoch-capture next state, whole-module writer uniqueness, and the exact
  `sq_mode ? miq_head_epoch : reservation_epoch` SQ-fill route with canonical MIQ provenance, plus
  forbidden legacy `mmu_flush`/FENCE.I-to-data-epoch paths. v7 additionally rejects non-reset next writes under
  any path other than exact `rst:false`, live uppercase reset identifiers, nested event/delay/wait controls,
  embedded system/unknown output actuals, `always @ signal` procedural fakes, unknown child/primitive output
  drivers, task-local port direction/width shadows, and host/child-driven canonical `clk/rst`; required ports are
  included in the critical-symbol audit.

The upgraded checker self-test kills 162/162 parser/connectivity, inactive-source, same-host dummy,
partial/alias writers, lexical/generate shadowing, variable-initializer and procedural-continuous fake
drivers, escaped/imported/package/hierarchical/system task actuals, nested selectors/concatenated LHS,
inexact reset/clock/ancestor guards, polarity/equality, phase-enum, stale-generation/non-sticky ack,
typed-mask concrete value, exact-width/payload, producer-map, guarded MIQ/SQ/owner storage, true
memory-leaf and set-dominant completion cases. Both release and `OOO_ASSERT` variants intentionally
return `rc=1` with 931 structural RED items, for an aggregate 1862-item inventory; the runner locks the
RED-line SHA-256 `fc5baa96190e9bcac70248f912523f8ae9192045885d6023b6cb940f4675a592`,
the v7 contract lock `d830e31698425f431ad92fc907e2748b151399539e9736a0abfc0ee7d9d2d5fa`,
and the separately reviewed evidence-baseline lock
`abfe4e248f27e50d4f6cafc69f7429dba37e36544b3a5d6ec01248993ed1dc88`.
The runner removes the previous completion marker before work and recreates it only after all locked
checks and source hashes pass. It snapshots the exact 28-path inventory before checker reads and after
readiness, requires the two snapshots byte-identical, then binds self-test, readiness, rc, canonical/pre/post
source inventories, source-check and summary digests; an interrupted, drifting or partially replaced rerun
cannot masquerade as complete evidence.
This is an auditable missing-interface inventory, not a failed claim of integration. Evidence is in
`evidence/r4-s2-q2-live-epoch-readiness-red/`. Even a future structural PASS remains necessary-only;
lane1, SQ deadlock, IFU stale fill, grant-edge ingress, unused ports, effective no-op, atomic apply,
dynamic epoch, terminal exactly-once, stale response and wrap mutations must still pass before live
integration can turn GREEN.

## AI development workflow v10 audited closure

This round also hardened the workflow that discovers, executes and publishes the hardware evidence:

- the completed bundle is no longer merely self-consistent. The validator recursively reads the current
  live profile include closure and compares every node's ID, source profile, module, owner, function,
  status, inputs and outputs. The primary evidence is the canonical node-owned log; auxiliary pointers
  must still be actual indexed ordinary assets;
- dispatch is exact-order (`context-brief PASS`, `profile-resolve PASS`, then every node
  `in-progress -> PASS`) with all eleven payload fields bound. The evidence index recomputes the asset
  set, sizes and hashes, and the completion marker binds report, manifest, context, resolve, index,
  dispatch and `nodes.tsv`;
- staged Markdown synchronization is exact across retained DB/index/backup state while protecting an
  already committed publication. Only `publish-task-run` may submit a strict-EOF
  `completion-publication.md`, and it validates the snapshot and writes stored/index rows in one SQLite
  transaction. Generic archive/promote/update/migrate/backup/rehydrate paths cannot create or revoke it;
- the real-SQLite regression is 14/14 and covers pre-publication invisibility, idempotent publication and
  canonical final-result recovery, post-publication generic sync, trailing content, marker and staged-set
  mutation, DB-open failure, canonical publication backup ownership, all-shim stale pruning, rehydrate,
  direct/nested generic writes, ordinary backup/snapshot route isolation and contract/
  nested-report downgrade attempts. Independent reviewers' globally consistent tuple rewrite and
  wrong-owner real-evidence mutations are now explicit negatives.

The pre-memory completed evidence is `.github/task-runs/2026-07-18-github-index-5/` for the 9-node
agent-system profile, `.github/task-runs/2026-07-18-agent-system-5/` for the github-index profile and
`.github/task-runs/2026-07-18-rv64-ppa-3/` for the 5-node npc-dev profile; all are DB-published and report
`publication_valid=true`. This workflow result does not promote Q1 or
Q2 and makes no claim about live dual memory, Linux, 200 MHz, area, power or full PPA.

## R4-S2-Q2 v8a satisfiable shadow-foundation correction

Independent counterexample review invalidated the previous assumption that Q2 v7 could be
implemented directly. The v7 files and 28-path evidence remain byte-preserved, but v7 is now treated
as a historical missing-interface inventory rather than a satisfiable full-RTL contract. The blocking
counterexamples are:

- IFU `done` was required to depend on an ack-generation output while its exact RHS excluded that
  output;
- held-head equality omitted a live head-present fact and did not define global-flush ownership;
- the advertised 8-bit identity stopped at the ROB output while SQ/owner provenance remained a
  4-bit index with no reuse guard;
- CsrFile prepare carried identity but not the same owner's operation/CSR/SFENCE/trap/xRET payload;
- FENCE.I ANDed a ROB retirement candidate with a frontend head even though the real instruction is
  owned by the registered pending-system path;
- FENCE.I request/ack generation had no satisfiable allocation/held timing or independent capture
  block;
- the live Q1 spec/RTL had no abort although v7 relied on abort to leave sticky grant;
- v7's canonical clock/reset audit did not load twelve existing child direction definitions and thus
  produced six false RED items per variant.

The replacement `s2-q2-shadow-foundation-interface-v8a` deliberately narrows the next implementation
atom to a reversible neutral shadow:

- all 26 ABI macros remain required;
- ROB precommit is independent of commit-ready, while a separate identity-valid fact observes whether
  the captured slot is still the live head;
- two permit inputs and three observation outputs traverse the exact seven-edge wrapper chain;
- both permits are exact tie-high at `NpcCoreTop`, so the slice cannot activate a barrier or FENCE.I;
- CSR/SFENCE/xRET/FENCE.I lane1 potential classification is frozen as shadow logic, and commit1 is
  explicitly forbidden from depending on that shadow in v8a;
- the eight deferred P0/P1 blockers and their machine-verifiable exit criteria are part of the contract
  lock. Full payload, FENCE.I transaction, Q1 instance, selective squash, dynamic epoch and identity
  safety are out of v8a scope.

The new checker reuses the reviewed v7 active-source parser helpers without modifying v7. Its 17/17
self-tests kill missing/wrong wrapper maps, active permit substitutions, commit-ready precommit,
done-aliased identity-valid, classifier shortcuts, commit1 activation, truncated identity, host override,
dummy Q1 and contract/provenance drift. Release and `OOO_ASSERT` each intentionally report 157
structural RED items; aggregate is 314 with RED SHA-256
`4099e530110b45c5c7948e5db0d0702402178c400157ad9699cd1ca70b4384b0`. The v8a contract lock is
`92c38c83fbd6cefd51921bc139b65acc965fb2e054c2f554086159c39bd160a3`; evidence-baseline lock is
`1dc0a5b68d8bfd9cc8e312cabe911236ee2ee2b3ec0b3f215ce132e6fbed98e9`.

Evidence is under `evidence/r4-s2-q2-shadow-foundation-v8a-red/`. The runner binds 18 pre/post source
hashes, self-test, readiness, rc and summary; the source inventory digest is
`595463ce58364ddad450699d30cbe0e2f47c764bcdaac28b3a7f1b4f4c1de951`. A separate historical check
reconfirmed v7 self-test 162/162, all 28 source hashes, and the exact four v7 task-run file hashes.

Implementer/reviewer conflict is resolved only for the **contract scope**: the reviewer counterexamples
are now explicit deferrals rather than hidden assumptions. RTL remains untouched and v8a readiness is
RED. The next safe implementation atom is the neutral wrapper/precommit shadow followed by focused
behavior-equivalence tests. Active identity/generation, full Q2, Linux, 200 MHz and PPA remain open.

## Compound-slug recall root-cause correction

The first real `npc-dev --task-slug rv64-q2-v8a-contract` run was correctly blocked before dispatch:
the runner had passed both the profile and the whole hyphenated slug as literal AND focus terms. Since
the shared query tokenizer intentionally splits only whitespace, a new identity string could not match
an independent current chunk. Retrying after archiving the failed run exposed a deeper counterexample:
the old failed `context-brief.md` or blocked task identity could itself satisfy the same terms and turn a
later run green without new current context.

The root fix keeps the general search contract intact and changes the runner boundary instead:

- task slugs are split into at most eight deduplicated alphanumeric/CJK semantic terms; numeric and
  lifecycle-only terms are removed, profile is carried only by `--profile`, and an empty semantic set
  fails closed;
- `brief` now has an explicit `focus_scope` with backward-compatible default `all`; the e2e runner and
  canonical startup commands require `non-history`;
- `task-report`, `dispatch-log`, `task-run` and `task-evidence` are excluded in both live/stored FTS and
  LIKE SQL before the result limit, so more than 128 historical hits cannot hide a current focus;
- the emitted context records `focus_scope=non-history`, and the bundle validator rejects a historical
  third/primary chunk even if the header is forged.

The database regression covers default historical compatibility, failed-context and blocked-report
identity, CLI/API failure under non-history scope, DB-first stored memory, FTS/LIKE parity and a 140-hit
historical saturation case. The runner regression locks `rv64-q2-v8a-contract-rerun-2 -> rv64 q2 v8a
contract`, `agent-e2e-npc-dev -> npc dev`, lifecycle-only failure, exact argv/profile separation and
history-primary artifact rejection. Successful development runs are
`.github/task-runs/2026-07-19-slug-recall-3/` (`github-index`) and
`.github/task-runs/2026-07-19-slug-recall-5/` (`agent-system`). Earlier blocked runs remain retained as
diagnostic evidence; they are not rewritten as completed. This workflow correction does not change the
v8a RED inventory or claim any RTL/PPA progress.

## R4-S2-Q2 v8a neutral shadow RTL implementation dispatch

The implementation atom is now contract-ready, but not yet claimed GREEN. The complete stage-0
interface freeze, six cross-module contracts, reset/flush priority table, requirements, protocol,
state-machine analysis, invariants, datapath constraints, nine-item RTL topology and completion
definition are recorded in `s2-q2-shadow-foundation-v8a-rtl-derivation.md` before any RTL edit.

The design remains an `intermediate_checkpoint`: only the exact tie-high wrapper/precommit shadow may
be implemented. Q1, active permits, full identity/payload, FENCE.I transaction, selective squash,
dynamic epoch, dual memory, Linux, timing and PPA promotion remain outside this dispatch.

## R4-S2-Q2 v8a tie-high scoped neutral shadow foundation GREEN

The dispatched v8a atom is now implemented and auditable. The 26 ABI macros, two downstream permit
inputs and three upstream observation outputs traverse the exact seven-edge wrapper chain. Both permits
are tied high only at `NpcCoreTop`; the observations have no active consumer. ROB exposes a
commit-ready/permit-independent candidate, a done/recovery-independent live-head fact and an exact
zero-extended ROB-index observation. The old head0 readiness equation is preserved as a named base and
only qualified by the two permits; lane1 CSR/SFENCE.VMA/xRET/FENCE.I classifiers remain shadow-only.

Independent review found two delivery-critical blind spots and they are now closed: `commit1_fire_w`
is exact-locked to its legacy RHS and asserted to imply `commit0_fire_w`; a two-ready-entry test lowers
each permit separately and proves neither lane retires and count remains 2. A whole-tree census finds
exactly 15 affected instances (7 RTL + 8 direct TB), with all five named ports present, nonempty permit
inputs and no positional connections. A supplemental checker also locks all six raw/potential/shadow
non-dependencies, exact identity zero extension, scalar ABI and base-ready confinement; its canonical
fixture and 4/4 targeted mutations pass, while the frozen checker remains byte-preserved and passes
17/17 mutations.

The canonical green runner passes release/`OOO_ASSERT` focused tests, explicit
`OOO_CSR_QUEUE_HEAD=0/1`, a candidate-live assertion negative, source stability and exact legacy
equivalence. Candidate and SHA-bound pre-edit source bundle each emit 1036-line legacy ABI traces in
both configurations and compare byte-identical. Fresh module regression is 104/104; RTL style and
contract pass with 289 immediate assertions against the 89 baseline.

Global strict lint and forced full default build remain RED on 115 Verilator warnings. This is not
waived: the latest normalized warning signature byte-matches the pre-edit snapshot (108
`TIMESCALEMOD`, 2 `PINCONNECTEMPTY`, 4 `LATCH`, 1 `UNOPTFLAT`) and `-Wno-fatal` parse/elaboration
passes, so no v8a-specific diagnostic was introduced. Evidence is under
`evidence/r5-s2-q2-shadow-foundation-v8a-green/`, with the independent disposition in
`s2-q2-shadow-foundation-v8a-final-review.md`.

A final reviewer-persona audit also caught a canonical-runner false-green: the supplemental checker
had accidentally been nested inside the structural-RED branch, so it was skipped on the normal PASS
path while stale logs remained available. The runner now deletes those logs and its marker first,
executes the supplemental gate unconditionally, exact-locks census=15, reruns every broad gate itself,
and SHA-locks the pre-lint baseline before resealing evidence. The corrected runner then passed from
scratch; this workflow correction is part of the delivered result rather than an undocumented manual
workaround.

The only allowed status is **v8a tie-high scoped neutral shadow foundation GREEN; global lint/build
RED**. Active permit/Q1/full identity/generation/epoch/FENCE.I transaction/formal equivalence/Linux/
200 MHz/area/power/PPA remain unproved and cannot be inferred from this checkpoint.
