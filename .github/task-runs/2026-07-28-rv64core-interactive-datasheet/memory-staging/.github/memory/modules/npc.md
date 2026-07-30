# NPC (RTL CPU) 模块笔记

## RV64 Core 交互式 Datasheet（2026-07-28）

### 常驻入口与数据绑定

- 交互入口为 `docs/rv64core/study/index.html`；单文件离线 HTML 内嵌样式、脚本、
  WaveDrom 3.6.2 runtime/skin/license 和当前结构 payload。默认根为
  `NpcTop.u_core : NpcCoreTop`，可切到 `NpcTop` SoC 根。
- payload 当前精确计数为 150 个 `vsrc` 文件、136 个 module 定义、195 个
  `NpcTop` 实例、8 条 transaction、37 个 WaveDrom；module/file/instance 三种身份
  分栏显示，源码页提供全部生产实例反向索引。
- 实例树用于回答“谁例化谁”；transaction 图用于回答 fetch/dispatch/execute/
  memory/completion/commit/redirect 如何流动。transaction phase 只表达 module-definition
  flow，不猜 lane；点击阶段进入定义页，再选择完整实例路径。

### 学习与验证合同

- 模块页固定为 General Description、Features、Quick Facts、Functional Block Diagram、
  Theory of Operation、Interfaces、Timing、Invariants、Source Evidence、Self-check 和
  Revision History。实例路径、module 类型和源码路径不会混成一个名字。
- 8 条主线为 instruction life、fetch packet、integer completion、FP completion、
  load、store、branch recovery 和 precise trap；每条均显示 owner、terminal、
  backpressure、flush 与 architectural effect，并强调阶段编号表示相对先后而非固定拍数。
- 无 module-specific timing binding 时不展示其他模块波形；接口 filter 在 route
  切换时复位，transaction flow 不再通过 `firstInstanceForModule` 猜双 memory lane。
  print CSS 将长层次/事务图改为单列文档流。
- `build_interactive_datasheet.py` 最新生成 980947-byte HTML；交互审计为
  `150 files / 136 modules / 195 instances / 8 transactions / 37 wavedrom /
  external_resources=0 / PASS`。原讲义 atlas 为 150/150 PASS；JavaScript `vm.Script`
  和四个 Python 工具语法检查 PASS。
- 独立 reviewer 修正前发现 4 个 P1，修正后给出静态 0 P0/P1。浏览器视觉、触控、
  打印预览以及 RTL TB/综合/STA/PPA 未执行，均保持 GAP；本任务未修改
  `npc/rv64/vsrc/**`。证据见
  `.github/task-runs/2026-07-28-rv64core-interactive-datasheet/`。
- 全工作树 strict guard 因 711 个共享 dirty paths 要求 `agent-system/rv64-linux/npc-dev`
  新 evidence；这些触发路径不是本 HTML 任务产生，故显式豁免，不运行越出文档范围的
  Linux/RTL profile。以 10 个实际交付路径运行 scoped strict guard 为
  `required_profiles=0`、PASS；这不证明当前脏工作树里的生产 RTL 或 Linux 改动。

## RV64 Core 学习讲义与当前拓扑基线（2026-07-28）

### 常驻入口与清册

- 学习入口为 `docs/rv64core/study/README.md`；00–10 按 transaction/周期讲解，11 为
  `npc/rv64/vsrc` 全部 150 文件逐项地图，12 为可复核实验。覆盖门
  `tools/audit_vsrc_coverage.py` 当前为 150 个结构化 atlas row、150/150 路径、
  37 WaveDrom、全部本地链接与严格 JSON PASS；每路径必须恰好一次，六类身份计数
  必须精确为 124/6/3/3/9/5。
- `extract_vsrc_inventory.py` 结合当前 `NpcTop`、`NpcSimTop` Verilator XML 的分类：
  `NpcTop-reachable=124`、`simulation-only=6`、`focused-checker=3`、
  `catalog-only=3`、`header/include=9`、`document/build=5`。
- 3 个 catalog-only memory leaf 是 `OooMmuEpochOwner`、`OooPmaChecker`、
  `OooPostTranslateMemoryClass`；当前 typed production 路径使用
  `OooTypedPmaChecker/OooTypedMemoryClassifier`。源码存在或进入 filelist 均不能替代
  顶层实例证明。

### 当前结构与周期合同

- 真实层次：
  `NpcTop → NpcCoreTop → {OooFetchAxiBridge,
  OooDualMemBridgeWrapper, OooLsuAxiLaneAdapter, OooCoreTopGlue, CsrFile}`。
  `OooCoreTopGlue` 下接 `OooFrontend/OooExecuteBackend/OooControlPlane/
  OooMemoryAccess/OooWriteback`；`OooExecuteBackend → OooAluCoreSlice →
  OooAluDecodeBackend → OooIntBackend → OooDispatchBackend`。
- 双 memory production 路径已经启用：2×bridge/DTLB/D-cache 在 raw AXI 层经
  `OooDualMemAxiArbiter` 锁 owner；旧 README/filelist 的 F2 “未实例化”说明过期。
  `AxiXbar` 是 2-master/16-slave single-outstanding 子集，R 有 registered response
  slice，AW/W 分别 capture。
- 前端 packet FIFO 是 4 个 packet，不是 8 个独立 slot；cache-hit C0 request、
  C1/H1 response/enqueue、C2 registered head dispatch。当前无 response bypass、
  full+pop look-through 或同拍 redirect request；redirect 后旧响应仍由
  `discard_fetch_rsp_q` 物理消费，但禁止进入 FIFO，这不是 epoch 丢弃。BPU 为
  gshare1024/GHR10 + local-history256×8/local-PHT4096；RAS 为 32 entry。
- Decode、rename、resource-ready 和 dispatch 是组合融合；dispatch fire 上升沿同时写
  RAT/FreeList/Busy/ROB/IQ。IQ 无 dispatch bypass，新 entry 下一周期才选择；PRF
  stored-only，`early_wakeup` 只改 IQ sticky-ready，值来自 registered EX forwarding。
- ProducerId 为 generation4+ROB-index4；完整 holder live-mask 与 exact-open 才是
  防止槽复用/晚到结果的安全合同，generation 单独不是安全证明。ROB 16 entry，
  formal WB 沿写 done，最早下一周期 commit；异常 entry 可从 head dequeue，但不写架构
  状态、不计 `instret`，head0/head1 exception 均阻止 commit1。
- FP 使用独立 RAT/FreeList/IQ8/PRF64。FADD2/FMUL3/FMA5 内部深度统一对齐
  meta-stage5；authorized raw result 可先写 FP PRF/wake，并进入 8-entry done FIFO；
  FIFO head 获 formal FPWB 后 ROB 才 done，架构 FPR/fflags 在 commit 更新。
- SQ 为 4-entry 程序序 owner：allocate/bind/fill/forwarding 后，只在 SQ head 匹配
  ROB head 且 `rob_head_launch_open` 时发物理 Store，AW/W 可异步，B terminal 后精确
  释放。LQ16 对已 launch 后被 kill 的 Load 仍等 terminal；MIQ0/1 各 4 entry，
  LOAD/PROBE 可 kill，DRAIN 存活。
- serialized SYSTEM/trap/exit 必须等 exact `mem_owner_terminalized`，普通 FENCE 额外
  等 `mem_idle`。`OooControlEventApplySequencer` 将 request 的 reason/kill-index 延迟
  一拍 apply；redirect arbiter 先按 ROB 年龄，平龄 `trap > branch > direct`。

### 证据边界

- 三个领域隔离只读 reviewer 分别复核 frontend/decode、backend/FP/retire、
  memory/control/integration；第四个最终隔离 reviewer 对抗式复核全讲义，得到
  0 个 P0、2 个 P1、2 个 P2。四项已分别修正 IFU discard、Store B-terminal
  精确链、branch resolve/formal-WB 语义和 atlas 结构性防假绿；实现者用当前
  XML/路径清册和机械门重验。
- 本轮未修改 RTL，未运行 TB/仿真/综合/STA/PPA；学习讲义对静态 owner/周期合同给出
  高置信解释，对动态功能、性能、Linux 与 physical timing 保持 GAP。bounded
  non-history recall 与 strict guard 已 PASS。
- task-run：`.github/task-runs/2026-07-28-rv64core-study-manual/`。

## RV64 simulation-exit exactly-once V10D

### 稳定微架构合同

- `pending_exit` 与 pending SYSTEM、pending architectural trap 共用
  exact memory-owner terminal 边界：
  `!(pending_system_i || pending_arch_trap_i || pending_exit_i) ||
  mem_owner_terminalized_i`。ROB/issue drain 不能替代 older memory
  holder 的 accepted terminal handoff。
- lane0/lane1 accepted exit birth 进入唯一 registered holder；
  active-holder 周期 raw exit 必须为 0。exact terminal C0 只产生一个
  `OooTrapExitEventMux.exit_o`，同沿清 exit holder/stop 并由 output
  sequencer 锁存 status；无新 capture 时 C1/C2 raw exit 为 0。
- `core_local_flush` kill 必须同时清 exit owner 与 stop，不产生 raw
  exit 或新 output latch。older terminal trap/recovery 在 raw mux 与
  sticky output 两个边界都优先于 exit，禁止同事务双 terminal latch。
- `OooIntBackend.mem_owner_terminalized_o` 只消费
  `OooMemOwnerTerminalCollector.ingress_accept_o` 等价 mask与 exact SQ
  release；production predicate 位于 `OOO_ASSERT` 外。raw ingress、
  tuple mismatch、duplicate 或 same-edge dequeue/re-enqueue 不能授权
  serialized exit。
- exactly-once oracle 直接计 raw mux pulse，不使用
  `NpcSimTop.exit_reported_q` 或其它 seen/report 去重；不得削弱
  owner/stop/memory-terminal/C1/C2 assertion。

### 当前证据与边界

- current design-id 为
  `sha256:c1b5317212bfe47e507eac83a28dff405527f50493e3709e96ffbec2dc3bb594`。
  assertion-on/off focused 各 5/5，七个 compile-success RTL variant
  7/7 拒绝，module 113/113、functional
  113/113+177/177+59/59 且 DiffTest mismatch 0、architecture 9/9
  GREEN、closed currentness 15/35/0。
- 独立 reviewer 给出 `APPROVED_FOR_CURRENT_SCOPE`，未发现当前
  simulation-exit transaction 的 blocking RTL 反例。standalone output
  sequencer 的人工跨周期 trap→exit 双 sticky 尚无专门 adversarial
  TB；批准依赖 integrated halted/run-gate 与 holder clear 的不可达性，
  该项是非阻断增强候选。
- V10C replay stage-order 现把 index build 与
  `control-event-index-verify` 都置于 ledger/currentness 之前；无条件
  preflight 以 candidate-before-architecture、missing-index-verify、
  verify-after-ledger 三个负向 fixture fail closed。attempt 13 持久化
  marker 后 currentness PASS。
- `npc-dev` task-specific e2e
  `.github/task-runs/2026-07-27-simulation-exit-exactly-once-revtag-v10d/`
  completed 5/5 并完成 DB marker publication；最终 strict guard 对
  `npc-dev` current evidence 判 PASS。该工作流证据只闭合 V10D
  记录层，不替代 Linux/rootfs、综合、STA 或 PPA 证据。
- `SERIALIZE-G1` 仍为 P1/OPEN。历史 V9Q rootfs 是旧设计 405M commit
  timeout、空 terminal marker，不是 current-design system evidence。
  当前 `architecture_freeze=GAP`、PPA `UNQUALIFIED`、promotion=false；
  本节不外推 Linux/rootfs、synthesis、STA、power 或长期目标完成。
- canonical task-run：
  `.github/task-runs/2026-07-27-rv64-v10d-simulation-exit-exactly-once/`。

## RV64 serialized SYSTEM post-fire V10B

### 稳定微架构合同

- `OooPendingSystemSequencer.kind_q` 的八类 canonical transaction
  继续是 `CSR/ECALL/XRET/WFI/SFENCE_FAMILY/FENCEI/FENCE/IRQ`。非 CSR
  transaction 在 exact memory-owner terminal 的 C0 产生唯一 raw
  action，C1 清 holder/stop 并提交对应架构或控制 side effect；无新
  capture 时 C2 不得重复。
- CSR 在 dispatch 后建立 exact ProducerId/PC lease；错误 PID 或 PC
  不得写 `CsrFile`、不得产生 CSR commit redirect，也不得杀 lease。
  exact commit 才能写 CSR、产生 `CSR_COMMIT/NONE` redirect 并清
  holder/stop。SATP write 的注册 MMU pulse与 CSR write phase 对齐。
- ECALL/IRQ 只允许 selected trap record 写 xEPC/xCAUSE/xTVAL 并产生
  TRAP redirect；XRET 只允许真实 MRET/SRET state transition；WFI 按
  frozen cohort 执行 immediate-resume SERIAL transaction，且不得制造
  CSR/trap/MMU action。
- 四种 SFENCE-family encoding 统一产生 SFENCE typed redirect 与注册
  MMU pulse；FENCE.I 产生 FENCEI redirect、注册 MMU pulse并清
  `OooFetchPacketCache`/ITLB，使同 PC 下一次 fetch 重新发 AXI request。
  ordinary FENCE 额外等待 full `mem_idle_i`，并保持零 CSR/trap/MMU。
- 所有 checker 直接计 raw pulse 与周期，不使用 seen-bit 去重；不得用
  terminal-event 去重、静默丢弃或削弱 assertion 掩盖重复/幽灵事件。

### 当前证据与边界

- current design-id 为
  `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。
  V10B 未修改 production RTL；pre-change FENCE.I MMU 断线版本在旧
  TB 上仍 PASS，证明原 observation gap。
- V3 为 3/3 baseline PASS、14/14 compile-success RTL version 动态
  拒绝，四个 TB path/SHA 逐 case 绑定。切断
  `OooFetchPacketCache.clear_i(mmu_flush_i)` 的版本会出现 stale
  response、无 AXI refetch 与旧 packet，由 typed/local/final marker
  一致判 FAIL。
- module 113/113、functional 113/113+177/177+59/59 且 DiffTest
  mismatch 0、CoreMark/Dhrystone PASS、architecture 9/9 GREEN，
  全部绑定相同 design-id。final-reviewer-v2 标准化 verdict 为
  `APPROVED_FOR_CURRENT_SCOPE`。
- FENCE.I 是 production pulse、top wiring 与 bridge consumer 的组合
  证明，不是 full-core self-modifying/Linux 证明；未做形式穷举。
  `fdg-arch-trap-current.json` 仍绑定旧 design-id/111-module，
  `SERIALIZE-G1=P1/OPEN`。simulation exit、Linux terminal、
  architecture-stable、synthesis/STA/power/PPA 均为 GAP/UNQUALIFIED。
- canonical task-run：
  `.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/`。
  task-specific `npc-dev` 为 completed 5/5，限定本轮路径的 strict
  guard PASS；该 workflow 结果不替代未运行的 Linux/PPA 业务 gate。

## RV64 clocked serialized-owner exactly-once V10A

### 稳定微架构合同

- `OooCsrTrapRequestMux` 的 drained pending control authority 为 `!core_commit_exception_trap_o && stop_pending_i && drain_complete_i`。ROB-head commit exception 与 pending architectural trap 同沿时，生产 `CsrFile` 只采样 selected mem record，raw pending trap request、trap-ex request 与 predictor boundary 必须保持 0。
- registered architectural-trap owner 与 registered pending-system owner 必须 onehot。live serialized owner 必须保持 `stop_pending_o=1`，并通过 `OooFrontendRunGate.can_run=0` 构造性阻止 head0/lane1 ECALL、xRET、CSR、FENCE 类以及新 IRQ owner birth。
- exact memory-owner terminal 的 C0 只允许当前 pending owner 对应的一类 request；该沿由 `CsrFile` 采样一次，并使 trap/system holder 与 stop 在 C1 清除。无新 accepted capture 时，C1/C2 不得再次产生同一 transaction 的 raw request、CSR record 或 typed redirect。
- priority 保持 `rst/core_local_flush > selected trap > xRET > CSR write > ordinary clear/capture`。修复只增加组合 priority term；不得引入 terminal-event 去重，不得用静默丢弃或 assertion 降级掩盖合法 overlap。

### 当前证据与边界

- current design-id 为 `sha256:13d868334de2a0813f91af318f25434f8e93c581adc67d0b562fcc1f6f8dc951`。production clocked TB 覆盖 head0/lane1 birth onehot、IRQ-over-arch、五类 SYSTEM standalone exact-one、live arch owner 对五类 overlap、commit-trap priority、older memory holder 与 C0/C1/C2 no-repeat。
- assertion-on/off focused 均 PASS；6 个 compile-success variants 分别删除 commit mask、head0/lane1 exclusion、IRQ priority、arch holder clear 和 stop clear，均编译成功并被动态 oracle 拒绝。module 113/113、functional 113/113+177/177+59/59 且 DiffTest mismatch 0、architecture 9/9 GREEN，canonical aggregate 均绑定相同 design-id。
- 独立审查将 pending architectural-trap clocked exactly-once 子范围判 `PASS`，同时保留三项 provenance/coverage 边界：pre-fix RED 无完整历史源码快照，focused log 无内嵌 design-id，TB 未单独逐拍计数最终 frontend redirect / `priv_predictor_boundary`。本节不能外推为八类 SYSTEM post-fire、Linux terminal、architecture-stable 或 PPA。
- `SERIALIZE-G1=OPEN`，`ppa=UNQUALIFIED`。canonical task-run：`.github/task-runs/2026-07-27-rv64-v10a-serialize-clocked-owner-clear/`。

## RV64 pending architectural-trap memory terminal V9Z

### 稳定微架构合同

- `OooPendingDrainResolveGate` 对 pending SYSTEM 与 pending architectural trap 共用同一 exact memory-owner terminal 边界：`!(pending_system_i || pending_arch_trap_i) || mem_owner_terminalized_i`。旧 memory holder active 且没有 exact accepted terminal transfer 时，`drain_complete_o`、`pending_arch_trap_fire_o`、trap request 与 predictor boundary 必须保持 0。
- exact same-edge accepted transfer、collector-pending-only 与 full-idle phase 继续由 production `mem_owner_terminalized_i` 标量表达；没有 serialized owner 的无关 control cycle 不受该标量约束。ordinary FENCE 仍额外等待 full `mem_idle_i`。
- 该修复只增加组合 consumer term，不增加寄存器、terminal 去重或 collector filter；`OooMemOwnerTerminalCollector` 与 owner/tracker fail-loud 合同保持不变。

### 当前证据与边界

- current design-id 为 `sha256:bbb9c95199ada2e0e8160c235705a270f924240b28fde6e611bd9342398084c9`。原始 pre-fix 集成 TB 编译成功并在 active-holder case 精确拒绝 drain/fire/trap-request/predictor-boundary 四项观测；原日志不含 pre-fix RTL SHA，后续 hash-bound `drop-arch-trap-terminal-term` 是独立等价反例，不与原日志混写。
- assertion-on focused 3/3、assertion-off 2/2、compile-success RTL variants 4/4 动态拒绝、module 112/112、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark/Dhrystone PASS；DI-1..DI-5/OOO-1..OOO-4 共 9/9 GREEN。gate、mux、integrated TB 与 146-file architecture manifest 均绑定当前设计。
- V2 reviewer 将 gate→mux 的 V9Z 组合边界判 `PASS`，但 clocked owner clear、无新 capture 时副作用 exactly-once，以及 arch-trap 与 ECALL/IRQ/xRET/CSR/FENCE overlap 的 priority 或 constructive unreachability 尚未证明。
- `SERIALIZE-G1` 保持 `OPEN`。下一步应把 `OooPendingTrapExitSequencer`、`OooPendingSystemSequencer`、`OooControlEventApplySequencer` 与生产 `CsrFile` 纳入 clocked gate-to-owner-to-CSR testbench；七类 serialized exactly-once、完整 Linux terminal、architecture-stable 与 synthesis/STA/power/PPA 均保持 GAP/UNQUALIFIED。
- canonical task-run：`.github/task-runs/2026-07-27-rv64-v9z-serialize-arch-trap-terminal/`。

## RV64 accepted memory-owner terminal V9Y

### 稳定微架构合同

- `OooMemOwnerTerminalCollector.ingress_accept_o` 是 collector handoff 的唯一 current-edge authority：每一 lane 必须同时满足 edge-old tracker live、非 reserved kind、kind/epoch exact、无同批 token duplicate、无 edge-old pending 和无 same-edge dequeue/re-enqueue。raw `ingress_valid_i` 只表示事件到达，不能授权 `mem_owner_terminalized_o`。
- `OooIntBackend` 的 active-holder census 覆盖 MIQ0/1、bridge0/1 active+station residency、reservation0/1、legacy buffer、`mem_pending_q`、retry0/1、SQ owner、request-fire handoff与 same-edge reservation birth。terminal transfer 只取 accepted collector mask 或 `sq_owner_release_effective_mask_w`。
- production census 与 `mem_owner_terminalized_o` 必须位于 `OOO_ASSERT` 外；宏只保护 shadow/fail-loud checks。active/no-transfer 为 0，exact accepted transfer、collector-pending-only、full-idle 和 exact final SQ release为 1；wrong tuple/duplicate active raw ingress保持 0。
- 标量经 DecodeBackend→CoreSlice→ExecuteBackend→CoreGlue→ControlPlane 原值传递。CSR Cresolve 与非 CSR pending-system drain 都必须消费；ordinary FENCE 继续额外要求 full `mem_idle_i`。不得用 full idle 替代 exact phase predicate，也不得用去重/丢弃重复 terminal 制造 PASS。

### 当前证据与边界

- current design-id 为 `sha256:3c933ec82fd17c6038335f9208b496cacfb755dfd10b9e419c73f276b5e2a428`。assert/release V8W 与 collector 均 PASS；12-lane batch capture/drain exactly once、wrong-epoch、duplicate、same-edge reenqueue、SD/FSD exact SQ release均有 production marker。
- pre-fix CSR/non-CSR RED 保留。删除两个 gate、退化 full `mem_idle` 的三项 compile-success 变体 3/3 拒绝；raw-ingress authority、raw-valid acceptance、assertion-only predicate 的三项 `OOO_ASSERT=0` 变体 3/3 拒绝。live backend/collector/TB SHA 与 mutation summary 完全一致。
- module 111/111、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark/Dhrystone PASS；DI-1..DI-5/OOO-1..OOO-4 共 9/9 GREEN。V4 独立 reviewer 在 V3 RTL review 基础上完成最终 provenance PASS。
- task-specific `npc-dev` 为 bounded recall 完整、5/5、exit 0；V9Y evidence index 为 491 assets/296,521,308 bytes，SHA-256 `8e077496388028dff7f8ce4f3053a55be76a6cc9585cc5d3f586c13a2f39c50b`，包含 strict-guard status。strict guard 的 `agent-system/npc-dev/difftest/github-index` 均 PASS；`rv64-linux` 仍缺 17/17 guest checks、natural poweroff、reset-syscon、`GOOD TRAP` 与 terminal transaction 完成证据，按系统层 GAP/豁免记录。
- V9Y 只关闭 non-FENCE pending-system memory-owner terminalized 子范围。pending arch-trap、七类 transaction exactly-once、完整 Linux flag-on、`SERIALIZE-G1`、architecture-stable 与 synthesis/STA/power/PPA 保持 OPEN/UNQUALIFIED。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/`。

## RV64 recovery/owner-birth phase alignment V9X

### 稳定微架构合同

- `stop_pending_o` 的 birth 只能来自 holder 已接受的 owner event：pending SYSTEM/CSR/IRQ 使用 `pending_owner_birth_w`，trap/exit 使用 holder-valid transition，queue-head CSR 使用 canonical `head0_csr_dispatch_fire_w`。raw instruction classification 和 merged backend fire 都不是 owner-birth authority。
- edge-old exact CSR `ProducerId` lease 与 live queue-head inflight 都是 stop 的保持资格；普通 recovery 不能杀 exact lease，matching commit/death、older-control queue-head kill 或 C1 reset 才能按 owner phase 清除。reset/C1、exact death、lease/inflight hold、accepted clear/birth 的顺序由一个显式 next-state chain 决定。
- `OooPendingTrapExitSequencer` 与 `OooStopPendingSequencer` 必须同时消费 C1 `core_local_flush_w`；squash clear 与 same-edge wrong-path capture collision 由 clear-wins，payload/valid 不得复活。
- terminal collector 的 duplicate/conservation assertion 保持 fail-loud；V9X 没有增加 terminal-event 去重或事件丢弃逻辑。

### 当前证据与边界

- current design-id 为 `sha256:a2ccc0c2a61be3d8922245f7d145eadc186b701fca1f38ef534aafdd983e994b`。checkpoint recovery × 两 lane 与 exit-squash RED 均有对应 green；五项 assertion-negative 命中，最终 queue-head flag-on 同时观察 real-fire single-source 与 C1 holder reset。
- 两项 compile-success RTL mutation 2/2 拒绝；module 111/111、functional 111/111+177/177+59/59、DiffTest mismatch 0、architecture 9/9 GREEN。V4 reviewer 逐项核对相关 RTL SHA 与 final source map 后，将 owner-birth 子范围判 PASS。
- mutation summary 直接绑定 production `OooControlPlane.v` 的 before/after SHA，而不是完整 mutant cohort/TB 的统一 aggregate hash；保存的 mutant source/log hash、临时编译路径、V9P marker 与 return code 已独立复核。该项记录为证据强度 caveat，不是当前 blocker。
- `SERIALIZE-G1` 仍 OPEN。下一步必须沿 `OooMemOwnerTerminalCollector` 的实际 ingress lane 对追踪非 FENCE serialized transaction，从 registered owner/holder 到 bridge/MMU/commit/trap/return terminal 建立逐类 exactly-once 证据；不得用去重掩盖重复 terminal，也不得从 focused owner-birth PASS 外推完整 Linux、arch-stable 或 PPA。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/`。

## RV64 pending-system canonical type and typed redirect V9W

### 稳定微架构合同

- `OooPendingSystemSequencer.kind_q` 是 serialized SYSTEM/CSR/IRQ 类型的唯一注册真源；`valid_o` 当且仅当 kind 非 NONE，valid holder 的八个公开类型 exact-one。非空 holder 不接受 recapture，kind/payload 保持到授权 clear/death。
- 普通 FENCE 由 holder 输出 `fence_o`，`OooControlPlane` 不得再从 raw instruction 建立第二类型真源。SFENCE.VMA/SINVAL family 与 FENCE.I 的 redirect reason 必须消费 exact holder-derived commit pulse。
- CSR ProducerId lease 只在 CSR dispatch birth，必须由 matching PID+PC commit death 或 backend-global reset 终止；非 CSR serialized transaction 不制造 ProducerId。

### 当前证据与边界

- current design-id 为 `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`。两 lane × 七类非 IRQ capture/hold/clear 为 14/14；SINVAL 产生 SFENCE reason、FENCE.I 产生 FENCEI reason；四个 compile-success RTL 变体分别验证 onehot、kind-valid 与两条 typed redirect oracle。
- focused 2/2、layered 6/6、module 111/111、architecture 9/9 GREEN。该证据只关闭 canonical type/typed redirect 局部切片。
- 当前 `rv64-linux` 绑定相同 design-id 与 simulator SHA-256 `4b0be491fbe1305e79bbaf599787f1321c8ac7dcc8ea5236a23a735edda8441d`：7 个前置节点 PASS，rootfs 节点在 Linux 0.059199 秒、EFI 初始化后达到 1200 秒 host boundary；未看到 mount/systemd/terminal 或 RTL assertion-failure marker。因此它只增加 forward-progress 边界，不关闭 serialized terminal transaction。
- `SERIALIZE-G1` 仍为 OPEN：尚需七类 × 两 lane × holder phase × recovery source 的交叉反例、`core_mem_idle_w/core_mem_retire_quiet_w` 真实 owner 终态，以及 commit/trap/return、redirect、holder/stop clear、MMU flush、bridge terminal 的 exactly-once 联合观测。禁止用 terminal 去重或 assertion 降级掩盖重复/幽灵事件。
- full-core architecture freeze 保持 GAP/32 blockers，PPA UNQUALIFIED、promotion=false。

## RV64 full-core capability cohort V9V

### 稳定微架构合同

- `full-core-single-hart-rv64-dual-issue-ooo-v1` 是当前 full-core candidate 的规范 capability cohort，并严格绑定 design-id `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。cohort exclusion 不是因缺测试自动产生；必须有明确 rationale、当前 design/cohort、规范合同路径/hash 和 candidate/ledger 完全对称集合。
- A-extension 只承诺单 hart local reservation：successful LR 建立，SC consumption 与 hart-issued store/AMO write 清除；autonomous coherent/exclusive peer invalidation 不属于当前产品 cohort。
- WFI 是经过 pending-system drain 的 legal immediate-resume hint，`mstatus.TW` below M 的非法路径保留；不承诺 clock/power sleep、interrupt-only wakeup 或 wake latency。
- accepted `SFENCE.VMA` / Svinval-family encoding 统一进入 serialized pending-system，并形成 global `mmu_flush`；不承诺 address/ASID selective invalidation。reserved encoding 与 TVM legality 不变。
- simulation observability、`OOO_ASSERT` 与 semihost EBREAK 不是 architectural Debug。当前 cohort 不广告 Debug Module、debug mode、halt/resume transport 或 executable trigger action。

### Terminal owner/holder 与验证边界

- `OooIntBackend` 的 collector ingress 0..11 仍依次为双 bank response、双 bank active/station drop、双 reservation、legacy buffer、AMO interphase、双 retry terminal。collector 只保存 exact `{kind,token,epoch}`，duplicate/pending/same-edge-reenqueue/conservation 继续 fail-loud；禁止以去重或丢弃重复 terminal 形成 PASS。
- 当前 8 个定向 testbench 8/8 PASS；collector 为 `pending=12` / `seen=12`，V9R backend 为 `banks=2 forced=2 natural_trap=1`，bridge 为 `S_SQ_QUERY held=1 release=1`。design-id 与 verification-source-id 前后稳定。
- canonical architecture gates 9/9 GREEN、V9O index 165 artifacts、arch-stable 单测 48/48，四项 cohort exclusion 与 exact membership PASS，15 个 CLOSED debt current binding PASS。
- historical rootfs terminal-pair 运行绑定旧设计并以 host timeout 结束，空 terminal marker 只算有界未复现。当前 full-core 仍为 `GAP`/32 blockers，`SERIALIZE-G1=OPEN`，census/freeze-input inventory 未完成，PPA `UNQUALIFIED`。
- `npc-dev` e2e 为 5/5 PASS，V9V evidence index 与 DB-first audit PASS；strict guard 的剩余项仅为 `agent-system` Markdown coverage 与 `rv64-linux` V9S systemd-strict，二者保持 GAP。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9v-full-core-cohort-scope/`。

## RV64 CsrFile vectored trap / interrupt delegation V9U

### 稳定微架构合同

- `mtvec/stvec` MODE=00/01 必须原样保存，MODE=10/11 写入时钳位为同 BASE 的 Direct。只有被 `mem > ex > irq` 选中的 interrupt 在 MODE=01 时加入 `4×cause`；同步 mem/ex trap 始终到 BASE。
- supervisor pending bit 的 cause 与目标特权级分离：未委派 SSI/STI/SEI 保留原 cause 并进入 M，已委派项只在当前 privilege 低于 M 时进入 S；M-mode 中已委派 supervisor interrupt 被屏蔽。标准优先级为 MEI>MSI>MTI>SEI>SSI>STI。
- A1/A2 独立重构 trap record/target，A3/A4 检查 tvec WARL，A5 独立重构 interrupt pending/cause。禁止以生产表达式自证或通过丢弃 terminal event 形成 PASS。

### 当前证据与边界

- current design-id `sha256:3460e14b8e06452017a20d0b35a552cf4e28966fcaeaf3dd747518760300df92`。V9U focused 13/13、full-core paths 3/3、CSR regression 1/1、compile-success negative RTL variants 7/7；定向 `rv64mi-p-illegal` 与完整 official 177/177 均通过。
- 完整 F0 为 module 111/111、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000；CONTROL/V9R 与 9 个 architecture gate 已在相同设计 SHA 重放。
- full-core candidate 仍为 `GAP`、36 blockers、PPA `UNQUALIFIED`、promotion=false。未完成项包括 SERIALIZE、scope decisions、完整 producer-holder census、cohort inventory 与 freeze inputs；V9S systemd-strict 仍为 RED。
- 配套 AI 环境的 `github-index` bounded chunk 修复已由 `.github/task-runs/2026-07-26-default-chunk-max-tokens/` 完成验证；它不改变 RTL design-id 或本节微架构结论。strict guard 的 `agent-system` Markdown coverage 与 `rv64-linux` V9S RED 继续按 GAP/豁免记录。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9u-vectored-trap-current-design/`。

## RV64 12-lane terminal collector V9T

### 稳定微架构合同

- `OooIntBackend.u_mem_owner_terminal_collector` 的 ingress 0..11 顺序为 bank0 response、bank1 response、bank0 active drop0、bank0 station drop1、bank1 active drop0、bank1 station drop1、reservation0、reservation1、legacy buffer、AMO interphase、retry0、retry1。结构门同时核对 `INGRESS_N=12`、每个 packed signal 的宽度与完整有序 concatenation。
- collector 只接受 edge-old tracker 中 live 的 exact `{kind,token,epoch}`；duplicate ingress、already-pending duplicate、same-edge re-enqueue、tuple mismatch、non-live owner、output duplicate/hold 与 conservation 继续 fail-loud。禁止用丢弃或去重 terminal event 的逻辑制造 PASS。
- V9R producer-side C0 barrier 仍是最小生产修复：full-flush C0 关闭 backend 两个 retry READY 和 bridge `sq_query_retry_fire_w`，保留 edge-old MIQ/retry/bridge owner，barrier 解除后恢复原 transfer。

### 当前证据与边界

- design-id `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`；focused release/assert 均为 12 ingress capture、12 exact drains、0 ghost，canonical DI-3 为 GREEN。hard-gate 单测 33/33 覆盖 lane10/lane11 顺序反例；pair matrix 的 15 个 compile-success variants 全部被 simulation/source checker 拒绝。
- module aggregate 110/110 PASS，verification SHA 为 `73466b559c293cc34c9825aabca7c0f2490ce1e846f04a7d710af1e76daccca3`。V9R baseline 2/2 与 C0 READY/fire 三个 compile-success variants 3/3 仍绑定 live source。
- V9S 当前最远到 640,000,001 commits、PC `0xffffffff8013e132`，没有 collector/V9Q/RTL assertion marker，但 36,000 秒后仍只完成 14/17 guest checks且没有 natural poweroff。该观察是有界不复现，不能识别历史 340M duplicate 的 exact lane pair，也不能关闭系统、full-core freeze 或 PPA gate。
- canonical task-run：`.github/task-runs/2026-07-26-rv64-v9t-terminal-collector-12lane/`。queue-head 默认值在系统 17/17 + reset-syscon + `GOOD TRAP` 前不翻转。

## RV64 SQ-query retry C0 handoff V9R

### 稳定微架构合同

- 当 `control_full_flush_barrier_w/i=1` 时，SQ-query retry 的 C0 传输必须暂停：`OooIntBackend` bank0/bank1 retry READY 均为 0，`OooMemAxiBridge.sq_query_retry_fire_w` 为 0。MIQ、retry holder 与 bridge `S_SQ_QUERY` 中已有的 exact owner 保持，不得在 barrier 周期制造新的跨 holder 所有权关系。
- barrier 解除后沿用原有 READY/fire 规则恢复传输；该修正不增加寄存器、队列深度、owner token、AXI channel gate 或仲裁级，因此没有独立面积/时序收益声明。
- V8T empty-slot progress assertion 必须把 C0 barrier pause 视为合法暂停；V9R assertion 则直接拒绝 C0 上的 backend capture exposure 与 bridge owner release，二者职责不能互换。

### 当前设计证据与边界

- current design-id 为 `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`。V9R baseline 2/2 覆盖 bank0/bank1 forced C0、natural ROB trap-head C0、bridge `S_SQ_QUERY` hold/release；三份可编译 RTL 反例 3/3 被精确 assertion marker 拒绝。V9R v2 summary SHA-256 为 `35f2337f15acdfcc77ef20a1b536e7edfe86aa901068c743cc5b53c312f041b5`。
- 完整顶层使用显式 `--timescale 1ns/1ps`；SQ forwarding 组合块补齐局部默认值，owner assertion 计数改为无状态函数，sim-only arm counter 改为显式 time-0 初始化，TLB/cache 私有函数采用模块限定命名。`make -C npc/rv64 lint` 与完整 `NpcSimTop + OOO_ASSERT` 构建通过，未用全局 warning-fatal 豁免掩盖 RTL latch 或名称诊断。
- V9O focused 10/10、queue-head config 3/3、module 110/110、RTL variants 11/11、architecture hard gates 9/9、negative tests 30/30 已在相同 design-id 重放；十组语义门也全部通过。debt ledger 的 `F0-G1` 与 `CONTROL-EVENT-G1` 为 `CLOSED/current_design_bound=true`，`SERIALIZE-G1` 保持 OPEN。
- 功能聚合为 module 110/110、official 177/177、AM 59/59、DiffTest mismatch 0、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000。current-design Linux profile 为 7 PASS / 1 FAIL：rootfs 在 1200 秒内进入 Linux 6.6 并到达 heap init，但未到达 virtio/VFS mount 或 systemd banner；这是有界未完成，不是 RTL assertion failure 或 rootfs PASS。
- arch-stable validator 140/140 PASS；完整核 candidate 仍是旧 `sha256:2eff...c8b2`，所以候选审计仍为 `GAP`、71 blockers、PPA `UNQUALIFIED`、promotion=false。该 cohort 差异不回退 V9R 局部结论，也不允许将其外推为 full-core freeze 或 PPA 晋级。

## RV64 unified control event current design V9O

### 稳定微架构合同

- `OooRob` 的 edge-old Q、commit permits、Q-only LQ terminal permit 和 exact pending CSR ProducerId 共同形成 full-event pregrant；`OooCoreTopGlue.control_event_request_valid_w` 只取该 full pregrant。trap commit 与 `TRAP` reason、queue-head CSR commit 与 `CSR_COMMIT` reason必须双向等价，不能在 C0 由 consequence pulse 重构 request。
- `OooControlEventApplySequencer` 是唯一 C0→C1 状态持有者。C0 full barrier 同拍阻止新的 dispatch、INT/FP issue、8 类 completion authorization、memory station/pre-owner launch；C1 再输出 typed apply。branch selective recovery 只在 authorized raw request 且没有 head full-event pregrant 时成立。
- ROB strict-younger 比较使用环形年龄而非 `>=`；pending CSR owner 同时匹配 full ProducerId 和 event type；LQ ordinary retirement 仍走普通 ready，只有 edge-old full-event pregrant 使用 Q-only terminal permit。已寄存的 AXI AR/AW/W owner 在 barrier 期间保持并 drain，未寄存的新 owner 不得建立。

### current-design 证据与边界

- RTL design-id `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`，146 RTL files；verification source-id `sha256:300da14d23d25c35168fa62277be014c255ab5198ef5d786ffe28348b700c3c1`，133 verification files。
- focused 10/10、`OOO_CSR_QUEUE_HEAD=1` config 3/3、module 110/110、compile-success RTL variants 11/11、full-C0 completion classes 8/8、dual registered AR 2 lanes/4 hold cycles/2 terminals、architecture gates 9/9、negative tests 30/30 均 PASS。`make -C npc/rv64 check-contract` 为 471 assertions、13/13 tests。
- evidence index 164 artifacts，SHA-256 `d73a69cdfd92f42ed87e9e60a0c5389c343e4261ab6cf8b6fddc957245124da0`；mutation summary SHA-256 `28d594c312a893acc250814f356fef23b03cac1991f84d8b34caf93fbf4f319d`。共享 validator 绑定 exact provenance、11-name mutation mapping、live 110-module inventory、canonical architecture result/manifest/refresh path 与 current source identity。
- `CONTROL-EVENT-G1.semantic_evidence=PASS` 只对 current design 局部成立。完整核 candidate 仍是旧 `sha256:2eff...c8b2`，所以 `closed_binding=GAP`、full-core 59 blockers、PPA `UNQUALIFIED`、promotion=false；这不回退局部 RTL 结论，也不允许外推为完整 OoO/PPA 完成。

## RV64 STORE/AMO next-edge owner residency V9N

### 稳定微架构合同

- `OooStoreQueue` 的 plain STORE 在 physical request fire 后、exact SQ terminal 接受前，下一拍必须保留 `valid/owner_valid/request_sent/!terminal`、full ProducerId、owner token 与 MMU epoch；SQ release、ROB early-done、checkpoint recovery 或无 terminal 的 holder 清除都不能结束该期待。
- `OooIntBackend` 的 AMO singleton 在 write fire 后、exact final response 前，下一拍必须保留 `mem_pending_q/mem_amo_q/mem_amo_write_sent_q` 与完整 owner tuple。canonical `NpcCoreTop.u_ooo_core.flush_i=1'b0` 静态排除 leaf global-flush 清除路径；该事实不得外推到其它装配。
- checker 必须在每个时钟沿先比较上一拍 shadow，再捕获本拍 launch，从而跨过 NBA 更新观察 Q；既有 holder-qualified same-edge assertion 不能替代该 next-edge 不变量。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。focused STORE/AMO 2/2；`sq_clear_owner_valid_on_request_fire` 与 `amo_clear_kind_on_write_fire` 两份 compile-success RTL 源码变体均只由 V9N checker 精确拒绝，旧 V9L 同沿 assertion 保持 quiet；证据单测 8/8。
- result/raw SHA-256 分别为 `34090add201aece110bc3423fec7460e33cecb35ce2da1ac73ca788a7cb0d709` 与 `379d16ebbe790b80315943d2420581c9446c8690ffcd076ab1aba44b592e1746`。`arch_stable_freeze.py` 从 live RTL 重构两份变体并独立校验唯一失败 oracle、source/artifact/provenance hash 与 top binding。
- canonical 9 门 architecture aggregate 为 GREEN，arch-stable 135/135 单测通过；full-core 仍为 GAP/38 blockers，PPA UNQUALIFIED、promotion=false。该动态证据不等价于全状态空间形式化证明，也不产生面积、频率或功耗改善结论。

## RV64 ordinary FENCE current-design V9M

### 稳定合同

- 普通 `OPCODE_MISC_MEM + FUNCT3_FENCE` 进入 pending-system drain；其完成条件除 backend/SQ quiet 外必须包含 `mem_idle_i`。非 FENCE pending-system 事件不额外依赖该条件。
- `OooIntBackend.mem_idle_o` 覆盖双 MIQ、pending/buffer、双 retry holder、双 memory issue reservation、owner-live 与 terminal-pending count，经 DecodeBackend→CoreSlice→ExecuteBackend→CoreGlue→ControlPlane 原值传到 `OooPendingDrainResolveGate`。
- full-core testbench 在 pending ordinary FENCE 且 `core_mem_idle_w=0` 周期直接要求 `u_control_plane.mem_idle_i === core_mem_idle_w`；older store 必须先 probe/drain，FENCE 才退休，younger device read 只能在两者之后观察。

### 当前证据与边界

- canonical `make -C npc/rv64 check-fence-ordering`：focused 2/2、module aggregate 109/109、compile-success negative RTL variants 2/2、validator unittest 12/12，design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。
- 两份 negative RTL variant 分别常量化 drain gate 的 FENCE memory-idle 条件与 CoreGlue→ControlPlane `mem_idle` 连接；日志必须精确只有目标 `[CHECK-FAIL]`、`errors=1` 与 `status=1`，不能用前缀/子串或 JSON 自报字段替代。
- `FENCE-G1=CLOSED` 只对当前 design-id 与 result `792b8c2c9454d01eb5143019136d6b3add734019ff20cd66cd36efef961e2ec0` 成立。九门 architecture aggregate 为 GREEN，但 full-core freeze 仍为 GAP/38 blockers，PPA UNQUALIFIED。
- STORE/AMO outstanding owner 的同沿清除仍需独立 `next(entry resident || terminal accepted)` 生命周期守恒证据，不由 FENCE closure 外推。

## RV64 V9L memory ownership and current functional aggregate

### 稳定微架构合同

- `rob_head_launch_open_o` 只授权新的 AMO/SQ request launch，包含 flush/recovery quiet 条件；`rob_head_owner_open_o` 表示当前 exact ROB head 仍 valid 且 unfinished，供已经 launch 的事务在 recovery 期间保持 owner。两者不能互换，post-launch owner 检查必须使用后者并同时比较 ROB index 与 full ProducerId。
- `OooMemAxiBridge` 的 station allow 与 lookup 必须由同一 `rsp_ready_w` response credit 决定；没有 response credit 时不得发起 lookup。retry bank 与 station 可以保存不同 token，禁止项仅是同一 exact retry token 同时出现在 retry Q 与 active/station owner 中。
- 对应生产断言为 `[V9L-SQ-POST-LAUNCH-OWNER]`、`[V9L-SQ-LOOKAHEAD-CREDIT]` 与 `[V9L-RETRY-OWNER-DISJOINT]`；V9L 四个 current-source 编译成功 RTL 变体分别切断这些合同并全部被动态拒绝。

### 当前证据与边界

- current design-id 为 `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。canonical functional aggregate 为模块 `109/109`、official `177/177`、AM `59/59`、DiffTest mismatch `0`、CoreMark 10/CRC `0xfcaf`、Dhrystone 10000，F0 evidence mutations `11/11`。
- `npc/sim/Makefile` 的递归 backend 调用显式传递 `NPC_HOME=$(BACKEND_DIR)`；外层 AM/NPC 环境中的 platform-root `NPC_HOME` 不再污染 rv64 backend 子 make。该修正属于构建入口绑定，不改变处理器 RTL。
- V8L holder evidence 在 assert/release 共 `8/8` 基线及 `9/9` 编译成功 RTL 变体上通过；汇总产物只替换 runner 自有随机临时目录，并经连续两轮 SHA 文件 `cmp` 验证确定性。producer-holder census 仍保留 `instance_graph_complete=false`、`semantic_complete=false` 和非 GREEN 状态，局部动态证据不提升整核 census。
- 九个 directed architecture gates 为当前 design-id 全 GREEN，arch-stable 审计 `134/134` 单测通过；完整冻结仍为 `GAP`、39 blockers，PPA `UNQUALIFIED`。长期 goal 继续 active。

## RV64 PTW PTE WRITE PMP current design V9K

### 稳定合同

- IFU 隐式 PTE A-bit write checker tuple 为 `(walk_pte_addr_q, 8B, PRIV_S, WRITE)`，LSU load-A/store-D checker tuple 为 `(walk_pte_addr_w, 8B, PRIV_S, WRITE)`；PTE READ grant 不能替代独立 PTE WRITE grant，只覆盖 PTE 前 4B 的 PMP entry 必须对 8B write fail closed。
- grant 后 IFU `AWADDR=walk_pte_addr_q`、`WDATA=ad_pte_q`；LSU `S_AD_UPDATE` 中 `AWADDR=walk_pte_addr_w`、`WDATA=ad_pte_q`。`AWVALID&&!AWREADY` 和 `WVALID&&!WREADY` 期间 payload 保持，AW/W 可以任意合法顺序各接受一次，同一 PTE owner 保持到 AW、W、B 均完成。
- deny 不进入 `S_AD_UPDATE`；IFU 形成 exact `resp0_bytes=F` 与 instruction access fault，LSU 形成原 load/store 的 access fault 而非 page fault。LSU response 反压期间 owner kind/token/MMU epoch/original VA `fault_tval` 和 fault class 保持，deny 到 response handshake 闭区间不得建立 PTE AW/W owner。
- PTW-PMP-G1 的 IFU 边界终止于 bridge successful-prefix/access-fault；lane owner、fault PC 与 `tval` 由 current-design `IFU-ACCESS-G1`/`IFU-TVAL-G1` 独立闭合。本地 PTE WRITE 接口无 `AWPROT` port，不虚构该字段。

### V9K 当前证据

- canonical command：`make -C npc/rv64 check-ptw-pmp`。
- focused 2/2、module aggregate 109/109、schema `npc-rv64-ptw-pmp-evidence-v4`、current-source compile-success RTL variants 28/28 动态拒绝、fail-closed 证据测试 13/13；production RTL SHA 前后一致。
- IFU allow 行阻塞 AW/W 两拍并以 AW-first 分离接受；LSU load-A 为 W-first、store-D 为 AW-first。每行直接检查 checker address-to-`AWADDR`、`AWSIZE=3`、`WDATA/WSTRB` 保持、accepted channel 不重发和 B-after-both。
- IFU deny 覆盖 F=0/2/4/6 与 8B partial-cover；LSU deny 覆盖 load-A readonly、store-D readonly、load-A partial8，在 response READY 延迟 0/1/2/3/5 下共 15 行、33 个 stalled-response 周期，逐拍检查 owner/fault/quiet tuple。
- 12 个 IFU 与 16 个 LSU 变体覆盖 checker WRITE/address/privilege/width、deny/grant polarity、fault class、deny-cycle AW/W、A/D `AWADDR`、split-handshake 后 pending channel 撤回、LSU response token 改接 live input，以及第三个 stalled-response 周期脉冲 AW、W 或 AW+W。
- 任意长 response stall 安全性由完整状态译码证书闭合：AW/W VALID 解码仅包含 `S_WRITE_REQ`/`S_AD_UPDATE`，deny 进入并自保持 `S_RESP` 直到 `rsp_ready_w` 或精确 drop terminal；将 `S_RESP` 加入 AWVALID 的证据变体会使证书 fail closed。response liveness 不从该 safety 证书外推。
- result SHA-256 为 `54d39545dea4a43310501499ad7a1e5d84c1af5e8244c859b0d868fb7774fc49`；raw log SHA-256 为 `1947a4c5f3ae713f28fcf0b19d29155955ee4f8cab5f086f0538877336611ea9`；V5 reviewer 合同 SHA-256 为 `7a01e924e4f5c8af71e425417404473506981bceac9afd245b8817a8da775cf9`，在同一 design_id 的限定范围内 PASS。

### 架构与协作边界

- `PTW-PMP-G1` 在 debt ledger 中为 `CLOSED` 且 `current_design_bound=true`；V9K-V4 字节证明来源重绑只改一份 LSU bridge TB 的 provenance，不改对应 directed record 的非来源语义。
- 共享 freeze validator 已纳入 IFU-TVAL 与 PTW-PMP 证据单测；所有相关 CLOSED result 经 canonical 本地 RTL 仿真重放，final 130 tests PASS。full-core audit 仍为 `GAP`、36 blockers，PPA `UNQUALIFIED`、promotion false。
- 长期 goal 继续 active；下一个直接架构项为 `F0-G1` current functional aggregate，继续使用 versioned RTL task contract 与 Windows→WSL single-flight。
