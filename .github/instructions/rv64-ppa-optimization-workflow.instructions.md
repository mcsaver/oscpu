---
description: "RV64 双发射完整 OoO 核的架构/PPA 强制工作流。先以同一 design-id 闭合功能、DI/OOO、精确恢复和 timing hard gates，再做 Performance/Area/qualified-Power Pareto 裁决；中间切片只作 development checkpoint。"
applyTo: "npc/rv64/**"
---

# RV64 完整 OoO 与 PPA 优化工作流

本流程把 RV64 OoO 架构恢复、性能优化、综合/STA、功耗资格化和 AI 开发环境反馈收敛为一个
fail-closed 闭环。它与以下常驻规则叠加：

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
| [OpenTitan DVSim](https://opentitan.org/book/util/dvsim/index.html) | 统一入口、隔离 scratch、按需 purge；干净 scratch 仍须配合 source/config/tool 绑定 | C 门指针、single-flight 执行、可再生产物清理 |
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
checker 修订后的结论必须生成独立、versioned receipt，并显式引用原始输入与旧状态。

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

#### 0.1.1 全核功能证据的唯一执行与发布入口

全核 module/official/AM/DiffTest/benchmark cohort 的机器策略是
`npc/rv64/design/arch/full-core-functional-run-policy-v1.json`，唯一 current-design 入口是：

```bash
npc/rv64/eval/ppa/run-full-core-current.sh \
  --run-dir .github/task-runs/<new-run-id> \
  --jobs 2
```

runner 只接受一个尚不存在的直接 task-run 子目录；不枚举 Git、不复用或重置旧 run。module 与 functional
阶段分别写入 task-owned evidence，前后绑定 production RTL、当前 NPC/NEMU 配置、工具、测试输入和
design-id；NPC `.config` 只读且必须已启用 DiffTest，Verilator、NEMU reference 与 AM program 的可再生
编译物进入临时根并在退出时清理；隔离 smoke 真实构建 NEMU reference、AM dummy、CoreMark 和
Dhrystone，并核验已知源码树二级产物路径前后无漂移。外层状态复用 `scripts/task-run-status.sh`，只有 durable result 复核
通过后才设置 evidence-complete；HUP/INT/TERM、早退、阶段非零或清理失败均保持带 stage 的 FAIL。

默认不发布 canonical current。只有明确追加 `--publish-current` 时，工具才先对 module、177 项 official、
完整 AM inventory、DiffTest、CoreMark、Dhrystone、mutation summary 和冻结输入做语义复核，并把
`full-core-current.status` 正式收敛为 PASS。之后才初始化独立的 `full-core-publication.status`，依次发布
三项 canonical data，最后原子提交
`npc/rv64/eval/ppa/evidence/functional-aggregate-current.binding.json`。消费方必须把该 binding 的
design-id、不可变 source run-result、执行 PASS 状态、三项 hash 和 publication PASS 状态一起核验；
进程在发布中途退出时，旧/缺失 binding 或 publication FAIL 会与数据不一致并 fail closed。发布阶段
不回写执行 result。历史 V9L 固定输出脚本仅作为 helper/provenance 保存，直接执行、无参数执行和
`--help` 均不得进入 reset/invalidation 路径。

外层执行状态除三个阶段返回码外，还必须观察 module、functional 与 semantic verifier 各自恰好一个
`[...][PASS]` marker，并拒绝重复 PASS 或同阶段 FAIL。module result 必须来自同一 run，绑定 complete PASS
状态、当前 exact test inventory 及非空 RTL/header/filelist/test/workflow 输入组；CoreMark 与 Dhrystone
次数、CRC 和 PASS 只从 guest 输出精确行取得，不能从命令参数推断。semantic verifier 精确重建 `functional-aggregate.log`（包括
`[F0-G1-GATE] PASS`、`ppa=UNQUALIFIED`、`promotion_eligible=false`），并要求 canonical 14 项 evidence
mutation inventory 全部按既定 schema 分类被拒绝，再从保留的 mutation input 做只读重放。下游 F0
consumer 必须重复核验 binding、source run-result、execution/publication PASS、source/canonical hash、
exact mutation inventory 和字节级终端收据；仅重算 JSON/hash 的空壳不能获得 publication 或 ARCH_STABLE 资格。

这套入口只标准化配置控制、执行状态、证据留存与 publication transaction，不把一次 F0 PASS 扩写为
ARCH_STABLE、系统再认证或 PPA 资格。checker-only 变化仍按 0.1 的冻结输入 replay 规则处理；production
RTL、elaboration、simulator/device 语义或必要输入身份变化时重跑受影响 cohort。

#### 0.1.2 默认分层系统签核与可选 Ubuntu 22.04 再认证

默认 `SYSTEM_RECERTIFIED` 不再以一次完整 Ubuntu 22.04/systemd 长跑为必要条件，而采用机器策略
`npc/rv64/design/arch/layered-system-signoff-policy-v1.json` 中的四层合取：

| 层 | 当前入口/对象 | 必须闭合的主要观测 |
| --- | --- | --- |
| L0 | module/transaction directed TB | owner/holder、ready/valid、flush/replay、异常/访存序、启用的 RTL assertion 与 oracle mutation |
| L1 | `run-full-core-current.sh` | official/AM/DiffTest、完整核提交链与 bounded benchmark guardrail |
| L2 | `run-mini-system-current.sh` | OpenSBI + S/U payload 的 M→S→U、Sv39 fault/recovery、timer/PLIC/UART、AMO/LRSC、MMIO 与自然 poweroff |
| L3 | `run-lightweight-linux-current.sh` | Linux 6.6、OpenSBI、PID1、COW/process、timer/tmpfs、用户态原子操作、UART IRQ 与终端 exact-once |

L2 提供 `privilege/sv39/timer/interrupt/atomic-mmio/shutdown/all` 七个入口；定向 case 只定位对应事务，
只有 `all` 满足完整 L2 合取。C 指针 `rv64-mini-system-runner-contract` 只执行静态合同和 checker mutation，
真实 guest 回放作为 domain evidence 显式运行一次。

L3 是当前系统验证最高优先级。其 runner 复用 production `NpcSimTop` 与设备模型，只使用最小内核配置、
静态 libc-free PID1/initramfs 和双 DTB；工作区内只保留一个身份绑定的当前 guest 产物集与一个当前
`NpcSimTop` 缓存。每次执行仍持有全局 RV64 single-flight lane，并要求当前 RTL/simulator/boot-artifact
绑定、Linux 与 simulator source content hash 一致、phase/terminal 基数正确、UART RX→PLIC 与
PASS→kernel power-down→syscon 的 cycle/commit 顺序成立、零 RTL assertion failure、semantic checker PASS、
runtime cleanup PASS、最终 evidence-file seal 与外层 fail-closed status PASS。C 指针
`rv64-lightweight-linux-runner-contract` 仅运行静态
合同和正负向 oracle 单测，不在收尾阶段重复启动 guest。L3 提供
`boot/mmu/process/timer/storage/atomic/interrupt/shutdown/all` 九个入口；只有 `all` 声明完整 L3。

完整 Ubuntu 22.04/systemd 保留为可选的高成本再认证，唯一入口仍是
`npc/rv64/eval/ppa/run-system-recertification-current.sh`，但真实执行必须增加
`--user-authorized-full-ubuntu`，且该授权只来自用户本轮明确请求。普通 RTL 变化、candidate/release、
自动化唤醒、L0-L3 任一失败或旧 Ubuntu 收据失效都不得自动启动它；`--validate-only` 可在不启动 guest
的情况下检查入口合同。其原始 PASS/FAIL、严格 17 项 oracle、终端、assertion 与 post-hash 证据保持
不可改写，缺少新的可选 Ubuntu 运行不阻断默认 L0/L1/L2/L3 分层签核。

四层证据仍必须绑定同一 current production RTL identity 及各自冻结的 config/tool/input；任一层缺失、
过期或 FAIL 时，`SYSTEM_RECERTIFIED` 保持 GAP。该系统层结论不自动签发 ARCH_STABLE、PPA_QUALIFIED、
historical root cause 或 PROMOTABLE。checker/parser/report-only 变化按 0.1 生成独立 replay；production/
elaborated RTL 或相关 simulator/device/guest 输入语义变化只重跑受影响层，不以全量 Ubuntu 代替分层定位。
L2/L3 冻结输入的 checker-only replay 统一使用 `npc/rv64/eval/ppa/replay-layer-checker-current.sh`；其
PASS 只纠正 oracle 对原日志的解释，不改写原运行 status，也不能扩大原 case 的 signoff scope。
replay 在运行 checker 前现场重算当前 RTL identity；冻结 binding、当前 identity 与 summary 任一不一致即 FAIL。
`build-current-simulator-cache.sh` 是当前仿真器的固定构建轮子，使用 `rv64-simulator-source-id.sh` 绑定
vsrc/csrc/Makefile/生效配置，发布后删除 Verilator `obj_dir`；其 C 指针只运行 `--validate-only`。

### 0.2 角色、变更控制与 waiver

- implementer 负责 completion definition、可证伪假设、RTL/constraint 改动和正负向开发证据；
- verification owner 负责 testplan、scoreboard/assertion、coverage gap 和 checker mutation 敏感性；
- candidate/signoff reviewer 独立检查设计身份、反例、证据缺口与越级结论，不重复执行日常零风险门；
- methodology/flow owner 维护固定入口、schema 和留存策略，但其 flow PASS 无权替代 architecture/PPA PASS。

waiver 只允许处理工具不可用、明确 N/A 或已知非产品配置等受限情形，不能豁免功能正确性、精确异常、
事务 owner、断言失败、timing violation 或伪造证据。每个 waiver 必须记录
owner、scope、rationale、expiry、compensating evidence 与 reopen trigger；过期、范围漂移或 signoff 后
RTL 修订时自动失效。日常 `fast` 不要求建立 waiver 流程，只有实际缺口进入 scheduled/candidate 裁决时才使用。

### 0.3 架构债务账本与完整签核分层

`npc/rv64/design/arch/architecture-debt-ledger.json` 是 P0/P1 debt 与 cohort capability decision 的
唯一机器账本；`npc/rv64/eval/ppa/evidence/architecture-debt-current.json` 是其当前 design-id 收据。
收据只能由哈希绑定的 directed/mutation、功能聚合、系统事务与 cohort 合同合取生成。某一层原始
执行为 FAIL、后续仅修正 checker 时，账本必须同时保留原状态和独立 replay PASS，不能把历史状态
回写为 PASS。

`architecture_debt_ledger=RESOLVED_CURRENT_DESIGN` 只说明账本内所有 debt 已在当前设计闭合或由当前
产品边界明确排除；它不等价于 DI/OOO、historical-defect、timing、PPA 或完整候选签核。固定入口
`rv64-architecture-debt-current` 因而必须同时守住 `whole_architecture=RED` 与 `ppa=UNPROMOTED`，
直到其它独立 hard-gate 层在同一 design/config/tool/workload identity 下完成。

高诊断成本的历史 RTL/oracle 缺陷统一登记在
`npc/rv64/design/arch/historical-defect-backfill-ledger.json`。库存完整性与当前设计闭合资格是两个
不同层次：固定 C 指针 `rv64-historical-defect-ledger-audit` 只运行 schema、路径/SHA-256、优先级、
`SELECTED` 规则和定向单测；它可以在账本域状态为 `GAP` 时执行成功，既不运行 RTL，也不生成
current-design receipt。只有 VD0/VD1 清零且 receipt 工具已经覆盖账本全部条目，才选择
`rv64-historical-defect-current`，并由
`npc/rv64/eval/ppa/evidence/historical-defect-current.json` 承载当前设计适用性。每项收据必须同时绑定不可改写的
历史反例、当前 design/config identity、当前正向观测和至少一个可编译且被预期 marker 拒绝的负向
版本；production/elaborated RTL 语义漂移时只重跑受影响的 directed cone，纯 checker 语义变化优先对
冻结输入做 versioned replay。当前库存为五项已回填条目加一项 V9P terminal-collector 入口重复
`SELECTED/VD1`；因此旧五项 receipt 保留为历史证据但不能宣称覆盖当前六项库存。账本、schema 或库存
审计工具达到确定性交付点时只运行轻量 ledger audit；receipt 工具、schema 或其单测变化只运行
`rv64-historical-defect-current-contract`，先证明开放 blocker 会在读取旧系统收据前快速拒绝。只有
current receipt 的设计源、配置、冻结输入或 evidence 路径变化才运行完整 current 指针。只读
review/analysis 三者都不运行。current 门 PASS 只表示
全部登记缺陷已重绑定同一当前设计，不得代替 DI/OOO、ARCH_STABLE、系统再认证、timing 或 PPA promotion。
由于收据使用全量 production RTL design-id，任一 `npc/rv64/vsrc/` 变化都会使其失效；C 指针把
architecture-debt、historical-defect 与 L0-L3 layered-system 作为三个独立 current receipt 管理。
共享输入变化只验证本轮直接交付的 receipt，并记录其它 receipt 的失效/重建指针；只有候选明确更新
architecture-debt 或 historical-defect 收据时才执行对应 current 门。testbench/build-control 只按收据
实际依赖路径触发。可再生 simulator image 在哈希收据形成后移除，
承重的顶层 receipt 与保留日志分别按 path/SHA-256/size 和 SHA-256 复核，二者不得混写成“全部中间物保留”。
V14E 一类已清理的 `compile.rc/.argv/.deps` sidefile 不作为长期产物恢复：零返回码内容哈希必须与 cleanup
manifest 精确相等，且同时由保留 result log 中唯一的编译命令标记、testbench 终态和正/负向 oracle marker
交叉证明；缺任一侧即 fail closed。`check-historical-defect-current` Make target 是可单独运行的组件检查，
只有 C 指针的交付调度才构成包含 architecture-debt 前置的集成顺序；直接运行组件 target 不得表述为完整
架构交付 PASS。显式选择历史缺陷指针与路径自动选择采用同一依赖正规化规则，不能绕过该前置。

ARCH_STABLE 的 holder closure 是分层合取，不要求静态 census 越权自报动态结论：

- `producer-holder-census.json` 只证明当前 design-id 的 field census 与 elaborated instance graph 完整，
  因而自身保持 `semantic_complete=false`、`whole_architecture=RED`；
- `producer-holder-semantic-coverage.json` 由 canonical evaluator 重算 17 个 holder instance、44/44 个
  semantic unit 与 50 个 unit-instance binding，并保持 PPA `UNPROMOTED`；
- `global-producer-no-live-reuse-current.json` 绑定 V14G 4/4 baseline、22/22 compile-success mutation、
  `GEN_W={1,4}` 以及完整 source/tool/product elaboration 身份；每个 baseline/mutation transcript 必须从
  durable task-run 路径重新核对 path/SHA-256/size，不能只信 compact receipt 中的 marker 计数；
- 只有 `arch_stable_freeze.py` 在同一 exact-input cohort 中合取 static、semantic、dynamic、功能、DI/OOO、
  历史缺陷和独立审查后，才可签发 `ARCH_STABLE`。签发时必须提供
  `arch-stable-independent-review-v1` receipt；receipt、合同和审查报告三者都绑定 exact candidate SHA、
  current design-id、无 open blocker/unknown，并明确保持 `ppa=UNQUALIFIED`。该签发不能提前跨入
  `PERF_BASELINE` 或 PPA promotion。普通只读 review 不产生该 receipt，也不增加门禁。

## 1. 优化对象：完整设计点，不是单刀即时收益

每条优化分支在第一刀前必须声明 completion_definition：

- parent design/source SHA；
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
2. 读取 architecture/PPA contract、PPA machine README、baseline index、当前 module memory 和
   当前活跃 task-run 的 checkpoint/下一步。
3. 冻结本轮 cohort：ISA/特权/设备能力、DI/OOO 下限、时钟/timing tier、PDK/lib/macro inventory、
   benchmark image、计数区间、工具版本、seed/threads 和 required-test inventory。
4. 基线是合取式 floor，不允许候选从不同历史点各挑一个有利数字拼成“全绿 baseline”。
5. 修改 RTL 前按接口契约先行和 RTL 四段式推导补齐协议、FSM、不变量、数据通路和拓扑；跨模块/
   控制路径必须有非真空立即断言与故意违约证据。

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

功能门至少覆盖当前 hash-bound required module inventory、official/privileged、AM cpu-tests、适用
Difftest、固定 CoreMark/Dhrystone 语义 marker；具体数量必须从当前 inventory/policy 推导，禁止把
历史手写总数当作永恒常量。每次性能 RTL 改动仍须按通用 NPC 性能工作流给出全量正确性和
highest_cpi、lowest_cpi、near_average_cpi 三类样本；固定 promotion workload 不能替代全量正确性，
全量 cpu-tests 也不能替代 DI/OOO directed gates。

## 4. 同源证据与可复现性

一个可裁决 design-id 必须内容寻址地绑定：

- immutable source snapshot/source bundle；
- commit 与 dirty-state、config、generated headers、filelist、parameters/defines 与工具版本；
- simulation binary、固定 benchmark/ELF/input image；
- 每次 raw performance log；
- fresh netlist、PDK/library/macro inventory、SDC、corner、activity/ROI、STA/area/power report；
- architecture/functional gate result、required-test inventory 和所有 evidence SHA-256。

所有承重证据必须在工作区内使用相对路径或内容寻址 artifact store；系统 /tmp 只可作运行现场，
不能成为长期 claim 的唯一来源。live RTL 重算的 checker 不能严格复核多个历史候选；若 evaluator
尚不支持从每个 immutable bundle 恢复执行，多点结果只能标为 development evidence。

性能 A/B 使用 A-B-B-A-A-B（每设计至少三次）或 contract 明确允许的等价去漂移顺序；每次 raw
log 必须独立 kind/path 绑定并由 checker 解析，不能复制一份计数冒充三次。综合/STA 每设计至少两次
fresh run，固定 seed/threads；优先要求 netlist SHA、面积和 path member set bit-exact。共享可变
build 目录、复用旧网表、修改 benchmark image、whole/region 计数混算、host wall time 代替 guest
cycles/retired 都是结构错误。

## 5. 多候选与全局搜索

持久候选集合至少分四池，任何新单点不得覆盖整个集合：

1. feasible Pareto archive：仅含全部硬门 GREEN 的完整点；
2. development branches：保存中间切片或有明确补偿假设的暂时被支配完整点；
3. high-uncertainty candidates：只记录证据缺口和有界降不确定度实验；没有校准模型时不得称
   surrogate uncertainty；
4. diversity/far candidates：在架构 knob、修改 footprint 或 objective space 上保持远距离。

没有合格 surrogate/RL 时，候选由证据化人工/规则驱动生成：约 50% 从不同父点做联合扰动，最多
20% 按真实 Pareto 缺口，至少 15% 降低证据不确定度，至少 15% 随机重启/远距离 mutation。批次
太小时也必须同时包含邻域、跨块补偿和 diversity 候选。不得伪称 EHVI、SHAP、attention、CVaR
或 RL policy 已存在；这些机制只有建立校准、反例和高保真复核后才可启用。

每裁决四个 complete_design_point 强制一次 global thaw；中间切片不计数。thaw 至少从两个不同
父点重新解冻早期参数，并优先联合以下强耦合块：

~~~text
{frontend width, fetch queue, predictor}
{ROB, PRF, IQ, commit width}
{dual AGU, translation, LSQ, cache banks, MSHR}
{issue width, FU, ports, bypass}
~~~

记录单项与联合实验；没有合格单一目标 J 时，分别报告 Performance/Area/qualified-Power 增量和
Pareto 关系，不先压成一个分数。

### 5.1 中型 CPI/PPA 下一切片选择器

`npc/rv64/eval/ppa/tools/optimization_slice_selector.py` 是优化环中从 current receipts、CPI census 和
active catalog 选择“下一次工程动作”的唯一机器入口。它属于优化控制面，不属于合同生产、task-run
归档或 complete design promotion；固定策略、活动目录和派生决策分别是：

- `npc/rv64/design/arch/optimization-slice-selector-policy-v1.json`：稳定的 authority、成熟度、决策类、
  不确定性和多目标规则；
- `npc/rv64/eval/ppa/optimization-slices-current.json`：当前可选的量测、资格化和可回退 RTL 实验；
- `npc/rv64/eval/ppa/evidence/optimization-slice-current.json`：绑定所有输入 SHA-256 的派生 current
  decision，不得反过来覆盖 ledger/receipt 或充当 promotion 事实。

选择器按以下全序工作：

~~~text
live RTL identity 与 current receipt 对账
  -> correctness/architecture blocker
  -> stale baseline/census reconciliation
  -> causal measurement
  -> current-design synth/STA/PPA reference qualification
  -> one reversible RTL experiment
  -> measured multiobjective disposition
  -> complete-design front.py promotion（独立入口）
~~~

同一决策类先做非支配比较。量测切片最大化 information gain、evidence confidence、reversibility，
最小化 execution cost、functional risk、scope width；若仍有多个非支配项，输出
`RESEARCH_REQUIRED`，禁止按 catalog 顺序、slice ID 或隐藏权重消歧。RTL/PPA 观测使用
Performance/Area/qualified-Power 区间做保守 Pareto：区间重叠不构成确定支配，Power 资格不同不可
放入同一三轴裁决。Timing 始终是 hard gate；slack 区间跨过门槛时先补 STA，确定低于门槛时直接拒绝，
不得把 CPI 或面积收益折算成 timing 分数。

中间 RTL slice 可以被选为“有界实验”，但必须预登记 success/stop/rollback，且始终保持
`selector_authorizes_promotion=false`。只有同 design-id 的实测候选才能进入 complete-design front；
`front.py` 仍是全局 Pareto/promotion 唯一权威。未校准的模型只能标记 `EXPERT_ESTIMATE` 或
`CALIBRATED_PREDICTION` 之前的研究缺口，不得宣称 EHVI、RL policy、成功概率或置信区间。

稳定入口为：

~~~bash
npc/rv64/eval/ppa/run-optimization-slice-selector.sh --validate-only
python3 -B npc/rv64/eval/ppa/tools/optimization_slice_selector.py build \
  --output npc/rv64/eval/ppa/evidence/optimization-slice-current.json
~~~

当 policy、catalog、live design-id、current receipt、baseline/census 或 research-state artifact 的
SHA-256 未变化时，直接复用 current decision，不重读长 goal 或重新生产子合同。输入变化后旧 decision
必须 canonical verify FAIL；状态冲突、零候选或多项非支配分别输出
`STATE_CONFLICT`、`NO_ELIGIBLE`、`RESEARCH_REQUIRED`，不得静默退到 ROADMAP 猜测。
research-state 不得直接覆盖 `causal_selection_authorized`、`causal_hypothesis` 或
`ppa_reference_available`；owner-timing 只能由同 design-id 且可 canonical rebuild 的 workload A/B receipt
派生为 measured，PPA reference 只能由既有 `check.py --require-accepted` 通过后派生。decision schema 与这些
verifier 的 hash 也是 current decision 输入，schema 或 verifier 变化必须使旧 decision 失效。

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
  -> focused positive + mutation/negative
  -> record the selected fast domain evidence once
  -> if scheduled: run the explicit risk/profile set
  -> if complete candidate: same-design full functional + synth/STA/Power + global front
  -> implementer/reviewer conflict audit at the delivery point
  -> archive bounded result/log pointers; run only path-selected environment gates
~~~

失败后先判断是实现根因、契约遗漏、量具/绑定错误还是搜索假设错误。负候选保留失败证据和拒绝
理由，不污染 canonical baseline；不得机械重复相同命令或通过缩小测试、放宽 checker 得到绿灯。
`fast`/`scheduled`/`candidate` 是触发层级，不是三个每轮都要串行执行的固定阶段。

## 8. AI 开发环境反馈回流

本工作流必须在实际优化中持续校正。每轮收尾把发现按职责落到唯一层：

| 发现 | 去向 |
| --- | --- |
| 当前架构/PPA事实、已知风险 | .github/memory/ retained document |
| 可复用的人类流程规则 | .github/instructions/；短小跨项目能力才放 Skill |
| 可判定的硬门/证据 schema | npc/rv64/eval/ppa/ checker/policy/schema 或 .github/ai-env/contracts/ |
| 自动执行与发现 | .github/e2e/profiles/、scripts/e2e/、agent 配置 |
| 单次过程、失败、原始证据摘要 | .github/task-runs/ + evidence index |

若规则只能靠最终回复记住，视为未固化；若规则已写但 profile/guard 找不到，视为未自动发现；若
profile 能跑却无法杀死故意构造的反例，视为假绿。修正环境时不得用 agent-system PASS 冒充
RV64/PPA PASS，反之也不得用 RTL 回归替代环境发现与证据生命周期 gate。

## 9. 交付模板

本轮报告至少列出：

- design state、parent、completion definition 与改动 footprint；
- 已闭合/未闭合 hard gates；
- full pass 数、三类 CPI 样本、固定 workload 每项 ratio 和最差项；
- timing tier、WNS/TNS/loops、area/power qualification；
- archive class、dominated-by/contribution、保留或拒绝理由；
- source/evidence binding、mutation 结果和本轮实际选择的 tier/profile/环境指针证据；
- 实现者结论、审查者反例、已关闭冲突与剩余风险；
- 下一轮补偿实验或 global-thaw 候选。
