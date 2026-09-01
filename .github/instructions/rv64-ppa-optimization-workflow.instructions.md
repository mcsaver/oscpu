---
description: "仅用于 RV64 完整 design point 的正式 Architecture/Pareto/PPA promotion 或 signoff；普通 focused 性能实验不自动进入本流程。"
applyTo: "npc/rv64/design/arch/rv64-architecture-ppa-contract.md,npc/rv64/eval/ppa/README.md,npc/rv64/eval/ppa/policies/**,npc/rv64/eval/ppa/baselines/**"
---

# RV64 完整 OoO 与 PPA 优化工作流

本流程只在 acceptance criteria 明确要求完整 design point、formal promotion 或 signoff 时，把 RV64 OoO
correctness、性能、综合/STA 和功耗资格化收敛为 fail-closed 闭环。普通局部优化使用
`npc-optimization-workflow.instructions.md` 的 focused 路径，不需要 task-run、完整 provenance、全量 gate
或本文的裁决顺序。进入正式边界时再按需结合：

- .github/instructions/rtl-generation-workflow.instructions.md
- .github/instructions/interface-contract-first.instructions.md
- .github/instructions/npc-optimization-workflow.instructions.md
- .github/instructions/verilator-tapeout-realism.instructions.md

架构能力、当前阈值与 promotion 资格的规范单一真源是
npc/rv64/design/arch/rv64-architecture-ppa-contract.md；机器入口和证据 schema 以
npc/rv64/eval/ppa/README.md、policies/、baselines/index.json 和 tools/ 为准。本工作流规定
“怎样搜索、何时裁决、证据放哪里”，不得降低规范合同的任何硬门。

## 0. 公开 SoC 方法论基线与本地裁剪

本仓库参考公开、可核验的方法，而不声称复制任何厂商内部流程：

| 公开来源 | 采用的工程原则 | 本地落点 |
| --- | --- | --- |
| [RISC-V ratified specifications](https://docs.riscv.org/reference/home/index.html) | ISA/特权行为以已批准规范为真源 | architecture contract、official/privileged tests |
| [RISC-V Architectural Certification Tests](https://github.com/riscv/riscv-arch-test) | 配置驱动适用用例、独立 workdir 与明确结果 marker；其结果不替代 OoO 内部验证 | ISA 配置绑定、official inventory、成功后中间物清理 |
| [Arm AXI Issue L](https://documentation-service.arm.com/static/68b03beb01ae952d9559f9eb) | channel/transaction、ordering 与 backpressure 按协议对象描述 | AXI bridge/Xbar RTL contract 与 assertion |
| [OpenTitan comportability](https://opentitan.org/book/doc/contributing/hw/comportability/index.html) 与 [signoff checklist](https://opentitan.org/book/doc/project_governance/checklist/index.html) | 可复用 IP 接口、分阶段 signoff、waiver 可审计 | module contract、候选交付清单 |
| [OpenTitan hardware development stages](https://opentitan.org/book/doc/project_governance/development_stages.html) | 设计、验证和签核成熟度分开跟踪；签核后语义修改回到开发态重新裁决 | 本地 design maturity 与 reopen 规则 |
| [OpenTitan DV methodology](https://opentitan.org/book/doc/contributing/dv/methodology/index.html) | testplan、scoreboard/assertion、coverage 与回归分层 | directed/mutation、scheduled regression、candidate signoff |
| [OpenTitan DVSim](https://opentitan.org/book/util/dvsim/index.html) | 统一入口、隔离 scratch、按需 purge；干净 scratch 仍须配合 source/config/tool 绑定 | 显式 PPA 入口、scratch 资源隔离、可再生产物清理 |
| [lowRISC SystemVerilog style guide](https://github.com/lowRISC/style-guides/blob/master/VerilogCodingStyle.md) | 可读、可 lint、显式时序/组合语义 | `check-rtl-style` 与 RTL review |
| [OpenHW CORE-V verification environment](https://docs.openhwgroup.org/projects/core-v-verif/en/latest/cv32_env.html) | reference-model step/compare 与 RVFI 类逐退休观测 | Difftest、retirement 定位、系统级反例 |
| [Arm PPA design-space analysis](https://documentation-service.arm.com/static/6322ff9edefc2c309b712454) | PPA 必须绑定同一实现条件并做多目标权衡，不能以单项预测值代替实现证据 | 冻结 PPA identity、Pareto front 与负优化回退 |
| [Cadence vManager methodology](https://www.cadence.com/en_US/home/resources/datasheets/vmanager-ds.html) | requirement、testplan、coverage 与结果追踪应形成可查询闭包 | contract → checker/test → run-id/result/hash 追踪 |
| [Synopsys formal signoff methodology](https://www.synopsys.com/verification/resources/whitepapers/formal-signoff-methodology.html) | formal 在适用状态空间承担证明或反例职责，并与 simulation 分工 | scheduled/candidate formal 或带范围的 explicit N/A |
| [Siemens formal/simulation coverage](https://resources.sw.siemens.com/de-CH/white-paper-comparing-formal-and-simulation-code-coverage/) | simulation 与 formal coverage 语义不同，closure 不能只看一个百分比 | coverage gap、不可达证明与 waiver 分开记录 |
| [ISO/IEC/IEEE 12207:2026](https://www.iso.org/standard/90219.html) 与 [15289:2019](https://www.iso.org/standard/74909.html) 公开摘要 | 生命周期允许迭代裁剪，信息项可按项目合并；不据此声称认证 | 任务分类、最小耐久证据、交付点集中审查 |

这里的“金标准”指公开方法中可迁移到本地 RV64 工程的五项不变量：版本化架构/接口合同、
合同到 checker/test/evidence 的双向追踪、按影响与风险升级的分层验证、同一 identity 下的 CPI/PPA
多目标裁决，以及实现者与签核审查者分离。它不表示获得任何厂商内部流程、工具认证或安全认证。
本地明确裁掉常驻全量回归、普通 review 门禁、以单一 coverage 百分比签核、精确流程时间硬门、
企业审批表单和永久保存可再生编译/综合中间物；这些裁剪不得削弱适用的 RTL assertion、负向版本、
formal、CDC/RDC、STA、Power 或系统终态证据。

本地流程采用三个正交轴，禁止把其中任一轴冒充另一个轴：

| 轴 | 决定的问题 | 机器/规范真源 |
| --- | --- | --- |
| 任务分类（task class） | 本轮是只读审查、RTL 开发、验证、长跑还是环境维护，是否需要 agent 流程 | `.github/instructions/agent-lightweight-workflow.instructions.md` |
| 执行层级（execution tier） | 当前确定性交付点需要 `fast`、`scheduled` 还是 `candidate` 证据 | `npc/rv64/design/arch/rv64-soc-delivery-gates.tsv` |
| 设计成熟度（design maturity） | 当前同源设计允许宣称到哪个阶段，以及什么变化会 reopen | `npc/rv64/design/arch/rv64-soc-maturity-stages.tsv` |

设计成熟度只允许沿下列顺序晋级；每一级必须由其机器配置指定的独立 authority 复核，不能用任务 class
或一次执行 tier 自动推导：

`ARCH_DISCOVERY -> ARCH_CLOSED -> ARCH_STABLE -> PERF_BASELINE -> PPA_QUALIFIED -> SYSTEM_RECERTIFIED -> PROMOTABLE`

例如，`candidate` 只是一次完整候选执行层级，不等于候选已达到 `PROMOTABLE`；`review` 是零门禁任务
分类，也不改变被审设计已有的 maturity。日常 RTL 修改只在确定性交付点登记一次相关 `fast` evidence，
`scheduled` 由客观风险触发，完整合取与独立审查只在 maturity 晋级候选上执行。

快速结构审计入口是 `scripts/check-rv64-soc-delivery-gates.sh`。它只审计上述分层配置、入口指针和
留存边界，不运行 RTL 仿真、综合或 STA，也不能签发 architecture/PPA PASS。

| tier | 触发点 | 最小范围 | 允许结论 |
| --- | --- | --- | --- |
| `fast` | 一批相关修改达到确定性交付点 | 受影响且已支持配置的 source closure elaboration/语义编译诊断、directed TB、assertion；checker/contract 变化时追加 known-good control 与“编译成功且被预期 marker 拒绝”的 mutation | 本地改动与对应合同通过；不晋级 |
| `scheduled` | nightly/weekly 或命中下述客观域/物理触发项 | 随机回归、coverage、适用 formal；按触发项追加 CDC/RDC 或快速综合 | 风险收敛趋势；不晋级 |
| `candidate` | complete design point 请求 promotion/release，或 signoff 后 RTL 修订 | 冻结完整 design/config/tool/workload identity 的全功能、架构、STA/PPA、waiver audit 和独立审查 | 仅在规范 contract 全部通过后可晋级 |

触发按影响面而不是按“文件数量”升级。只读 `review/analysis` 保持零门禁；普通说明/交付摘要类
`docs` 不运行 domain gate，但 `npc/rv64/design/arch/` 下的承重 architecture contract 不适用该豁免；
`development` 对每个不可变 design/config identity 运行并登记一次相关 `fast` evidence，
不在同一身份的收尾重复。RTL/generated RTL/package、filelist、parameter/define、约束、工具执行语义或
workload/input 身份变化会使相应 evidence 失效。仅验证 replay 且 production RTL、active device model、
simulator 执行语义和冻结输入均未变化时，优先重放冻结输入。任务分类、compact/durable task-run 与 C
指针调度仍以
`.github/instructions/agent-lightweight-workflow.instructions.md` 为真源。

`scheduled` 的客观触发边界如下；没有适用路径时可以记录带时钟/复位/电源域清单的 `N/A`，不得只写
主观“低风险”：

- clock/reset topology、synchronizer、异步接口、SDC clock relation、reset release 或 power intent 变化：
  运行适用的 CDC/RDC；单时钟设计也要检查异步复位释放路径。
- pipeline/retime、clock gating、memory inference、关键算术结构、SDC、library/macro 或 EDA tool 版本变化：
  运行快速综合；若破坏基线可比身份则重建 baseline。
- checker、assertion、reference model、ISS 或 test contract 变化：在 `fast` 中同时证明原版 PASS，且
  compile-success 负向版本触发预期 checker FAIL；只证明负向版本可编译不构成 oracle 证据。
- baseline promotion、正式 performance/PPA 声明、release、未签核参数集或 signoff 后 RTL 修订：进入
  `candidate`，不能由 scheduled 结果直接晋级。

### 0.1 执行证据、oracle 与重跑决策

长仿真、系统事务和 PPA 结果必须把
`execution_state / terminal_state / artifact_state / assertion_state / oracle_state / replay_state`
分开记录。外层退出码、checker 结论或报告渲染状态都不能替代其它状态。原始 PASS/FAIL 状态不可改写；
checker 修订后只需保留独立 replay 结果，并绑定原始输入、checker 版本和旧状态，不要求额外 receipt。

| 变化或证据状态 | 默认动作 | 允许结论 |
| --- | --- | --- |
| production RTL、实际 elaborated RTL、active device model、host harness 或 simulator 执行语义变化 | 对受影响配置重新执行 DUT | 新执行绑定范围内重新裁决 |
| config、filelist、parameter/define、guest/boot/workload/input、SDC/library/corner/activity/ROI 变化 | 重新取得受影响 domain evidence | 只绑定新 identity |
| 仅 checker/parser/report/collector/status 语义变化，且原始输入、终态、assertion、post-hash 与绑定完整 | 对冻结输入做 versioned replay，并运行 known-good/expected-fail checker 单测 | 可修正 oracle 判定，不改写原始执行状态 |
| 仅文档或证据指针变化，承重内容与工具语义均不变 | 重算路径、哈希和 schema，不重跑 DUT | 保持原 claim boundary |
| 缺原始输入、终端事务、assertion、post-hash、工具/配置绑定或当前问题所需观测 | fail closed 并重跑或补采 | 不得 promotion |

复用以不可变 identity 为单位，而不是“曾经 PASS”即可永久复用。聚合账本可以同时记录
`execution complete + old oracle invalid + current replay pass`，但不得把它简写成历史运行本身 PASS。
本规则直接减少无意义全量重跑，同时保留 RTL、testbench、EDA 与系统终态的签核强度。

#### 0.1.1 全核功能证据与发布

正式全核 cohort 使用
`npc/rv64/design/arch/full-core-functional-run-policy-v1.json` 和
`npc/rv64/eval/ppa/run-full-core-current.sh`。普通 focused 开发不需要该入口；完整 design point、正式
publication 或 promotion 才按 runner 帮助选择运行目录、并发和发布选项。

runner、policy、schema 与 semantic checker 是 marker、inventory、binding、mutation 和 publication
transaction 的机器真源。agent 运行 canonical 入口并解释结果，不在 instruction 中手工重建内部
receipt/hash/marker 链。正式发布仍必须绑定同一 production RTL、配置、工具和冻结输入，区分执行与发布
状态，并在 signal、早退、阶段失败、cleanup 失败或 binding 不一致时 fail closed。一次功能 PASS 不自动
签发 ARCH_STABLE、系统再认证或 PPA 资格；checker-only 变化按 0.1 replay，production RTL、elaboration、
simulator/device 语义或必要输入变化时重跑受影响 cohort。

#### 0.1.2 默认分层系统签核与可选 Ubuntu 22.04 再认证

默认 `SYSTEM_RECERTIFIED` 不再以一次完整 Ubuntu 22.04/systemd 长跑为必要条件，而采用机器策略
`npc/rv64/design/arch/layered-system-signoff-policy-v1.json` 中的四层合取：

| 层 | 当前入口/对象 | 必须闭合的主要观测 |
| --- | --- | --- |
| L0 | module/transaction directed TB | owner/holder、ready/valid、flush/replay、异常/访存序、启用的 RTL assertion 与 oracle mutation |
| L1 | `run-full-core-current.sh` | official/AM/DiffTest、完整核提交链与 bounded benchmark guardrail |
| L2 | `run-mini-system-current.sh` | OpenSBI + S/U payload 的 M→S→U、Sv39 fault/recovery、timer/PLIC/UART、AMO/LRSC、MMIO 与自然 poweroff |
| L3 | `run-lightweight-linux-current.sh` | Linux 6.6、OpenSBI、PID1、COW/process、timer/tmpfs、用户态原子操作、UART IRQ 与终端 exact-once |

各层的 case inventory、terminal/oracle 规则、binding 和 replay 语义以该 policy、对应 runner 与 canonical
checker 为机器真源。定向 case 只证明它实际覆盖的事务；只有 policy 定义的完整 case 才能声明完整层。
agent 不在 instruction 中复制 case 数量、marker 基数、hash 或 evidence seal 细节。L2/L3 的正式 evidence
仍须来自真实 guest 回放，绑定同一 production RTL、simulator/device、boot artifact、config/tool/input，
并满足对应终态、设备事务、自然 poweroff、零 RTL assertion failure 和 fail-closed cleanup。

L3 runner 复用 production `NpcSimTop` 与设备模型。写入 current guest artifact 或复用 current simulator
cache 时，只锁住这些真实共享资源；独立 scratch/cache 可以并行。静态 contract/checker 单测不能替代
guest 回放，也不在收尾阶段机械重启已经取得有效 evidence 的同一确定性 workload。

完整 Ubuntu 22.04/systemd 保留为可选的高成本再认证，canonical 入口是
`npc/rv64/eval/ppa/run-system-recertification-current.sh`，但真实执行必须增加
`--user-authorized-full-ubuntu`。该 flag 表示本轮目标已经选择高成本 workload/cost，不是安全本地工程动作
的第二次授权；acceptance criteria 已明确要求完整 Ubuntu 时可以直接传入。普通 RTL 变化、
candidate/release、自动化唤醒、L0-L3 任一失败或旧 Ubuntu evidence 失效都不得自动启动它；
`--validate-only` 可在不启动 guest 的情况下检查入口合同。原始执行与 oracle 判定保持可区分、不可改写；
缺少新的可选 Ubuntu 运行不阻断默认 L0/L1/L2/L3 分层签核。

四层证据仍必须绑定同一 current production RTL identity 及各自冻结的 config/tool/input；任一层缺失、
过期或 FAIL 时，`SYSTEM_RECERTIFIED` 保持 GAP。该系统层结论不自动签发 ARCH_STABLE、PPA_QUALIFIED、
historical root cause 或 PROMOTABLE。checker/parser/report-only 变化按 0.1 生成独立 replay；production/
elaborated RTL 或相关 simulator/device/guest 输入语义变化只重跑受影响层，不以全量 Ubuntu 代替分层定位。
checker-only replay 使用 canonical replay 入口，只能纠正 oracle 对冻结输入的解释，不能改写原始执行状态
或扩大原 case 的 signoff scope；identity/binding 不一致时 fail closed。current simulator cache 仍须绑定
production RTL 与实际 vsrc/csrc/build config，按项目缓存策略清理可再生中间物。

### 0.2 角色、变更控制与 waiver

- implementer 负责 completion definition、可证伪假设、RTL/constraint 改动和正负向开发证据；
- verification owner 负责 testplan、scoreboard/assertion、coverage gap 和 checker mutation 敏感性；
- candidate/signoff reviewer 独立检查设计身份、反例、证据缺口与越级结论，不重复执行日常零风险门；
- methodology/flow owner 维护固定入口、schema 和留存策略，但其 flow PASS 无权替代 architecture/PPA PASS。

waiver 只允许处理工具不可用、明确 N/A 或已知非产品配置等受限情形，不能豁免功能正确性、精确异常、
事务 owner、断言失败、timing violation 或伪造证据。每个 waiver 必须记录
owner、scope、rationale、expiry、compensating evidence 与 reopen trigger；过期、范围漂移或 signoff 后
RTL 修订时自动失效。日常 `fast` 不要求建立 waiver 流程，只有实际缺口进入 scheduled/candidate 裁决时才使用。

### 0.3 架构债务、历史缺陷与完整签核

架构债务、历史缺陷和 ARCH_STABLE 的机器真源分别是现有 ledger、current evidence、policy/schema、
canonical checker 与 freeze 工具。agent 不复制其精确条目数、marker、sidefile、hash 或内部调度顺序；
修改这些工具时运行对应定向单测，正式候选时运行 canonical 入口。

必须保留以下语义边界：

- ledger/schema 健康只证明库存可解释，不证明 current RTL 已闭合；
- current receipt 必须绑定当前 design/config/tool/input 与直接正向/反例证据；checker-only replay 不得改写
  原始执行状态；
- architecture-debt、historical-defect、DI/OOO、L0-L3 系统证据、timing 与 PPA 是独立结论，任何单项
  PASS 都不能越级代替其它项；
- ARCH_STABLE 只能由同一候选 identity 下的 static、semantic、dynamic、功能、DI/OOO、历史缺陷与独立
  审查合取签发，并继续保持 `ppa=UNQUALIFIED`，直到独立 PPA qualification 完成；
- published/canonical evidence 缺 binding、存在 open blocker/unknown 或与当前 identity 不一致时 fail closed。

普通只读分析不生成 current receipt。focused 修改只重跑受影响 cone；完整 inventory、冻结和独立审查只在
acceptance criteria 要求 current closure、maturity promotion 或 release 时执行。

## 1. 优化对象：完整设计点，不是单刀即时收益

每条优化分支在第一刀前必须声明 completion_definition：

- parent design/source identity；
- 联合修改块与预期补偿关系；
- 哪些切片属于中间态；
- 形成完整设计点的明确条件；
- 最大验证边界、失败回退点和停止条件。

| 状态 | 含义 | 允许结论 |
| --- | --- | --- |
| intermediate_checkpoint | 完整协同改动中的可回退切片 | focused 正确性、契约、mutation、局部结构/PPA 诊断；允许暂时回退 |
| complete_design_point | completion definition 全部集成，source/config/binary/image/netlist/evidence 可绑定为同一 design-id | 才能执行全部硬门、完整 workload/PPA 和 Pareto/promotion 裁决 |

中间切片永远不得进入 Pareto front、architecture seed、canonical、accepted baseline 或
champion。局部优化可以生成候选，但不能同时负责淘汰候选；不得因单刀面积、CPI 或 slack 暂时
变差就剪掉具有明确跨模块补偿路径的分支，也不得在看到坏结果后无限扩大 completion definition。

## 2. 开工与基线冻结

1. 先按轻量工作流读取当前模块合同；只有确实需要历史召回或跨模块 profile 上下文时才生成 bounded
   brief，并按工作选择 npc、verilator-tapeout、yosys-sta profile。历史证据走 runs/evidence，不默认
   全量读取原始日志。
2. 读取 architecture/PPA contract、PPA machine README、baseline index，以及与当前候选直接相关的 live
   source/config/evidence；只有显式持久长跑或跨会话 promotion 才读取 task-run checkpoint。
3. 冻结本轮 cohort：ISA/特权/设备能力、DI/OOO 下限、时钟/timing tier、PDK/lib/macro inventory、
   benchmark image、计数区间、工具版本、seed/threads 和 required-test inventory。
4. 基线是合取式 floor，不允许候选从不同历史点各挑一个有利数字拼成“全绿 baseline”。
5. 修改 RTL 前理解受影响的协议、state owner、FSM、数据通路、拓扑和 transaction lifecycle；按当前
   false-PASS 风险选择直接 assertion、directed test 或负向 oracle，不要求固定四段式输出或机械制造
   故意违约证据。

## 3. Hard-gate-first 裁决顺序

每个 complete_design_point 必须按以下全序执行；前一步失败就停止 promotion，不进入后续评分：

~~~text
same-design provenance + completion_definition
  -> functional gates
  -> DI-1..DI-5 + OOO-1..OOO-4
  -> precise exception/recovery/memory side-effect gates
  -> exact timing-tier gate
  -> per-workload floor + worst-workload check
  -> Area/Power evidence qualification
  -> global Pareto/front contribution
  -> scalar ordering inside the same front only
  -> normative promotion checker
~~~

硬门是约束，不是 penalty。任何综合分、预测值、hypervolume、面积收益或平均 CPI 都不能抵消
功能、完整双发射、真 OoO、双 memory datapath、精确恢复、timing 或单 workload 回退。

功能门至少覆盖当前 policy-bound required module inventory、official/privileged、AM cpu-tests、适用
Difftest 和固定 CoreMark/Dhrystone 语义 oracle；具体数量必须从当前 inventory/policy 推导，禁止把
历史手写总数当作永恒常量。每次性能 RTL 改动仍须按通用 NPC 性能工作流给出全量正确性和
highest_cpi、lowest_cpi、near_average_cpi 三类样本；固定 promotion workload 不能替代全量正确性，
全量 cpu-tests 也不能替代 DI/OOO directed gates。

## 4. 同源证据与可复现性

一个可裁决 design-id 必须绑定：

- immutable source snapshot/source bundle；
- commit 与 dirty-state、config、generated headers、filelist、parameters/defines 与工具版本；
- simulation binary、固定 benchmark/ELF/input image；
- 每次 raw performance log；
- fresh netlist、PDK/library/macro inventory、SDC、corner、activity/ROI、STA/area/power report；
- architecture/functional gate result 与 required-test inventory。

具体 content-address、manifest、hash 和 schema 由 canonical policy/checker 在需要 byte identity 的正式
promotion、publication 或跨机器持久化边界内生成和核验。agent 不手工维护平行 hash 清单，也不把 hash
数量当作设计身份之外的独立 correctness 证据。

所有承重证据必须在工作区内使用相对路径或内容寻址 artifact store；系统 /tmp 只可作运行现场，
不能成为长期 claim 的唯一来源。live RTL 重算的 checker 不能严格复核多个历史候选；若 evaluator
尚不支持从每个 immutable bundle 恢复执行，多点结果只能标为 development evidence。

性能 A/B 使用 A-B-B-A-A-B（每设计至少三次）或 contract 明确允许的等价去漂移顺序；每次 raw
log 必须是独立执行并由 checker 解析，不能复制一份计数冒充多次。综合/STA 按 contract 取得足以判断
工具噪声和可重复性的 fresh run，固定 seed/threads，并核对 netlist identity、面积和 path member set。共享可变
build 目录、复用旧网表、修改 benchmark image、whole/region 计数混算、host wall time 代替 guest
cycles/retired 都是结构错误。

## 5. 多候选与全局搜索

当目标明确包含 design-space search 时，保留已经通过硬门的 Pareto 点、仍有可证伪补偿假设的 development
branch，以及能降低关键不确定性或保持架构多样性的候选。任何新单点都不得覆盖仍有工程价值的候选集合；
中间切片不能混入正式 Pareto archive。

候选比例、批次大小和何时重新探索早期参数由当前测量、信息价值、执行成本和可逆性决定，不设固定配额
或每若干候选强制 thaw。搜索停滞、候选过度集中或新 evidence 改变瓶颈判断时，可以从不同父点重新探索
以下强耦合块：

~~~text
{frontend width, fetch queue, predictor}
{ROB, PRF, IQ, commit width}
{dual AGU, translation, LSQ, cache banks, MSHR}
{issue width, FU, ports, bypass}
~~~

记录能区分当前假设的单项与联合实验；没有合格单一目标 J 时，分别报告
Performance/Area/qualified-Power 增量和 Pareto 关系，不先压成一个分数。没有经过校准、反例和高保真
复核时，不得宣称 EHVI、SHAP、attention、CVaR、可靠 surrogate uncertainty 或 RL policy 已存在。

### 5.1 可选的 CPI/PPA 切片辅助器

`npc/rv64/eval/ppa/tools/optimization_slice_selector.py` 可以根据 current measurements、catalog 和显式
约束建议下一项量测或可逆实验。它是 advisory：不能授权、撤销或阻止用户范围内的 focused experiment，
也不能把派生 decision 变成 architecture、PPA 或 promotion 事实。安全、本地、可逆的诊断可以不经过它。

使用辅助器时，以现有 policy、catalog、schema 和 verifier 为机器真源。状态冲突、证据不足或多个不可比
候选应暴露为 GAP/RESEARCH_REQUIRED，不用隐藏权重伪造唯一答案。只有同一 design-id 的实测完整候选
才能交给 `front.py` 做正式全局 Pareto/promotion 裁决；timing、functional correctness 和 qualified Power
仍是不可由 CPI/面积抵消的硬边界。未校准模型不得宣称可靠概率、置信区间或已实现的 RL/EHVI policy。

## 6. Performance / Area / Power 资格

- 性能必须跨冻结 workload 报告每项 ratio、最差 workload 和最小 ratio；几何平均不得掩盖单项
  回退。held-out/CVaR 只有在 workload 集与 provenance 冻结后才能声明。
- Timing 是硬门，不是可用其他轴补偿的第四个软分；必须明确 rtl_proxy_partial_constraints、
  prelayout_constrained 或 postroute_physical_signoff 层级。
- unknown macro 面积不能填 0；缺 macro-inclusive total area 时只能比较同口径 logic-area proxy。
- vectorless、macro=0 或 activity coverage 不足的功耗保持 unqualified；只有同 workload、合格
  activity coverage 和完整 macro internal/leakage 的功耗才能进入三轴 front。
- engineering_proxy_archive 可以保存架构可行点的 P/A 非支配关系，但必须保持
  front_accepted=false、canonical=false、ppa_champion=false。
- architecture_feasible_seed 只允许按 normative contract 从架构不可行测量锚发生一次；第二次
  seed 必须拒绝。seed 未补齐 qualified Power 和 total area 时，后续只能做 engineering comparison，
  必须保持同一 seed；更换 seed 的结果不能用于关闭该 gate。
- baseline replacement 与 archive membership 是不同裁决。非支配 trade-off 可以留档；自动替换
  accepted baseline 必须通过 normative dominance、per-axis floor、global front 和 promotion checker。

## 7. 每个确定性交付点的执行闭环

~~~text
read bounded current context when needed
  -> freeze completion definition/cohort/contracts
  -> implement one reversible slice
  -> focused correctness evidence; add mutation/negative only for an identified false-PASS risk
  -> record the selected fast domain evidence once
  -> if scheduled: run the explicit risk/profile set
  -> if complete candidate: same-design full functional + synth/STA/Power + global front
  -> implementer/reviewer conflict audit at the delivery point
  -> archive bounded result/log pointers when persistence is selected; run only explicitly selected environment checks
~~~

失败后先判断是实现根因、契约遗漏、量具/绑定错误还是搜索假设错误。负候选保留失败证据和拒绝
理由，不污染 canonical baseline；不得机械重复相同命令或通过缩小测试、放宽 checker 得到绿灯。
`fast`/`scheduled`/`candidate` 是触发层级，不是三个每轮都要串行执行的固定阶段。

## 8. 持久化与报告

只有稳定、跨会话仍有价值的架构/PPA 事实才更新 memory；只有显式 persistent、release、forensic 或
publication 工作才创建 task-run 或完整 evidence index。不要为每轮实验制造新 instruction、profile、
schema、marker 或环境 gate。真实 checker/policy 缺陷应修在其所属 domain，并用能杀死该 false PASS 的
定向测试验证；agent-system PASS 不能冒充 RV64/PPA PASS，反之亦然。

交付报告只覆盖当前 claim 所需信息：改动与 complete-design 边界、正确性结果、可比 identity、CPI/PPA
结果、未闭合 GAP、promotion 资格和剩余风险。具体 marker/hash/receipt 数量由 canonical machine result
承载，不复制为固定人类模板。
