# YSYX AI 驱动硬件开发环境蓝图

## 定位

这份蓝图是工作区工程对象、真实依赖和可复用方法的导航图，不是 agent 的权限状态机。规范优先级与默认
operating model 以 `.github/AGENTS.md` 为准；任何静态图、profile、skill、DB、memory 或 task-run 都
不能扩大用户权限，也不能在安全本地工程步骤之间新增许可。

目标是让 agent 直接推进 NEMU、AbstractMachine、am-kernels、NPC/Verilator、DiffTest、RV64 Linux、
ysyxSoC 与综合/STA/PPA 的真实工程结论，同时保留必要的协议、安全、长跑和发布边界。

## 默认工作方式

1. 恢复 primary objective、可观察 acceptance criteria、当前 repository state 和 hard constraints。
2. 读取直接相关源码、spec、filelist、配置、调用者/消费者与测试入口。
3. 复杂或跨模块任务先画清真实调用链、数据流和产物依赖；简单任务直接实现。
4. 在正确抽象层做最小完整修改，保留用户改动与现有接口。
5. 运行能判断 acceptance criteria 的最短可信验证；从失败或新不确定性向外扩证据。
6. 报告实际行为变化、命令/配置/返回结果、未运行层级和 GAP。

这些动作属于同一安全本地授权范围，可以合并、跳过或迭代。文件数、路径、任务类别、agent 名称和
compaction 都不会自动创建 gate、reviewer、task-run 或 memory 更新要求。

## 当前真实工程面

| 工程对象 | 主要入口 | 能支持的结论 |
| --- | --- | --- |
| am-kernels | tests、benchmarks、guest probes | workload 与目标程序行为 |
| AbstractMachine | platform、klib、IOE、image/link scripts | 平台 ABI 与镜像产物 |
| NEMU | reference、device model、monitor、QMP/GDB、Linux guest | reference/系统模型行为 |
| npc/sim | Kconfig 与 backend manifests | 统一选择 single、soc、rv64 后端 |
| npc/single | Verilator harness、RTL、DiffTest 接口 | NPC single target 行为 |
| npc/soc + ysyxSoC | CPU ABI、SoC address map、generated RTL | SoC 集成行为 |
| npc/rv64 | RV64 core、testbench、Verilator target | RV64 RTL correctness 与性能输入 |
| DiffTest | NEMU/Spike reference 与 NPC retirement stream | 可比配置下的提交级差异 |
| Linux/ | OpenSBI、kernel、rootfs、guest check、platform configs | 分层系统 bring-up |
| yosys-sta / PPA eval | filelist、mapped design、constraints、corner | 综合、STA、面积/性能证据 |
| NVBoard / display / devices | board glue、UART/CLINT/PLIC/virtio/framebuffer | 外设与可见 I/O 行为 |

模块 README、Makefile、Kconfig、spec 与生产 test 是直接上下文。DB/memory 只在需要历史决定时辅助，不是
这些生产入口的上游。

## 真实依赖

常见 reference/target 链可以写成：

```text
workload → AM image ──→ NEMU reference
                    └─→ NPC/Verilator target ──→ optional DiffTest
```

只有以下关系需要排序：

- consumer 必须等待 producer 生成镜像、RTL、配置、filelist 或报告；
- compare/DiffTest 必须等待两侧同一 workload/config 的可比较产物；
- 两个动作写同一文件、build/scratch、current artifact 或数据库；
- 两个动作竞争同一仿真进程、端口、设备、许可证或不可复制资源；
- promotion/signoff 明确消费前级 correctness 或 PPA evidence。

其余读取、分析、实现与独立 scratch 构建可以并行。Windows 启动 WSL 时复杂 shell 逻辑仍放在仓库脚本或
单个 Bash 进程中，避免 PowerShell 预展开；这不是 workspace-wide single-flight shell 规则。

## 可选任务模式

这些模式用于帮助思考，不是固定图、必填节点或完成许可：

| 场景 | 最小有用结构 |
| --- | --- |
| 局部 bug | reproduce/direct evidence → root cause → fix → focused test |
| refactor | callers/consumer contract → change → consumer-focused test |
| reference | workload/image → NEMU run → relevant result |
| target bring-up | image/config → NPC/Verilator → log/wave/marker |
| compare | comparable reference + target → DiffTest/oracle → mismatch localization |
| Linux/device | affected layer → guest/device transaction → terminal/negative evidence |
| PPA experiment | comparable baseline/candidate → mapped/STA/perf measurement → bounded decision |
| AI environment | affected contract/tool → direct self-test or syntax/profile validation |

出现失败时才按需要增加 trace、wave、config bisect、negative case 或更小 reproducer。不要预先为每个任务
创建 planner、implementer、reviewer、recorder、publication 和 verifier 链。

## 委派与 handoff

委派时提供有界 objective、acceptance criteria、直接相关输入、写文件 ownership、建议命令与预期产物。
提醒协作者代码库中还有其他修改，不得回滚他人工作。一个 agent 能安全完成时不为角色齐全额外派发；
多个独立问题或 ownership 清楚的文件组可以并行。

复杂、并行或跨会话的 RV64 RTL 任务可以使用
`.github/instructions/rtl-agent-task-contract.instructions.md` 与
`.github/skills/prepare-rtl-task-contract/` 作为结构化 handoff。旧 schema 中的 path/command 字段是
focus、ownership 与建议动作，不是权限白名单；JSON hash 只表示兼容工具消费的 byte identity，不证明
RTL 正确性。局部任务可以直接派发，不要求固定 `fork_turns`、逐字 render、candidate/reviewer 或 SHA
收据。

技术说明优先写清本地 RV64 module/signal/transaction、周期或配置、TB/EDA 观测与 PASS/GAP 范围。
ready/valid、flush、redirect、trap、ROB/LSQ/SQ/MIQ、PMP 和异常/访存序等真实术语必须保留，不能被格式
validator 或措辞模板裁剪。

## Correctness 边界

### Reference、target 与系统

- NEMU PASS 证明对应 reference/workload，不证明 NPC/RTL。
- NPC smoke 只证明该 backend/config，不自动证明 DiffTest、Linux、综合或 PPA。
- DiffTest 只有在 ISA、image、initial state、配置和 observation point 可比时有效。
- Linux/Ubuntu 按 OpenSBI、kernel、PID1、设备事务、用户态能力和自然 poweroff 分层表达。
- focused marker 不外推到未运行的 full rootfs、SMP、PCI、网络、snapshot 或其它系统能力。

### RTL 与接口

- 触碰 handshake、stall、flush/redirect/trap、异常序、访存序或恢复时，确认 transaction acceptance、
  payload hold、owner/tag lifecycle 和同拍优先级。
- 已有 spec/contract 足够时直接使用；含义缺失或矛盾时才补 spec、assertion 或 directed case。
- 仿真专用 DPI/trace/debug 逻辑不得被误认为可综合生产设计。
- filelist → elaboration → dynamic → mapped → STA/PPA 可见性以
  `npc/rv64/ARCHITECTURE.md` 和 architecture registry 为入口。

### PPA 与 promotion

- A/B 必须绑定相同 RTL、filelist、parameter/define、tool/config、corner 和 workload。
- synthesis/mapped/STA/Power/性能证据不能由 AI policy test、文件存在性或低层 proxy 替代。
- 正式 Architecture/Pareto promotion、release candidate 或对外发布属于高风险复核边界；探索性迭代不
  自动进入 candidate/reviewer 流程。
- CPU Architect 只处理任务语义确认的开放跨流水或事务生命周期结构取舍；局部 RTL、已定位 bug、验证、
  工具、文档和 registry 维护不升级为架构任务。

## 验证预算

新增检查前回答：

1. 它判断哪个明确 acceptance criterion？
2. 它能唯一发现哪种现实 false PASS？
3. 不运行它是否会让工程结论不可靠？

固定输入、固定命令、固定 tool/seed/thread 且 oracle 确定时默认运行一次。只有随机、并发、flaky、未固定
seed/thread、测量噪声、机器异常、矛盾结果或用户明确要求时重复。

版本控制内未修改且有自身测试的 runner、checker、parser、schema validator 默认可信。只有本次修改了它、
观察到异常接受/拒绝、矛盾输出、缺失结果或可疑 fallback 时才运行其自测。验证器 PASS 不替代真实 DUT、
guest、mapped design 或 workload 行为。

## E2E、持久化与发布

`scripts/agent-e2e.sh` 只在显式 profile 场景使用。默认 compact 模式直接展开 live profile、运行节点并
保存直接日志；它不刷新 DB、不从 task slug 推导 recall gate、不生成 manifest/SHA marker，也不发布 DB。
业务 profile 不自动 include AI discovery 或 software-flow。

需要正式 release/security/forensic/publication 时显式使用 `--publish`；durable 兼容模式才启用 bounded
recall、manifest、evidence index、byte-identity marker 和 DB publication。strict guard 只消费明确的
path/paths-file，并只在上述边界运行。

普通任务默认不创建 task-run，不更新 memory。跨会话长跑可选择 compact/durable；稳定、可复用的 root
cause、接口决定或长期工程事实才进入 memory。archive、backup、rehydrate、report 或 DB 失败只影响对应
persistence/publication criterion，不得改写原始 workload 的 PASS/FAIL。

persistent/published 长跑仍必须 fail-closed：non-zero exit、timeout、HUP/INT/TERM、中断、缺 terminal
evidence 或 cleanup 未完成都不得记录 PASS。需要恢复状态时使用 `scripts/task-run-status.sh`，但普通
短命令不套长跑协议。

## 明确禁止的反模式

- 根据 changed paths 或文件数自动派生 gate；
- 把 safe local read/edit/build/test 拆成逐阶段许可；
- 先全量加载 memory/DB/旧 task-run，再读取当前源码；
- 用 task slug、SHA、marker、seal、review 状态或 profile resolve 证明业务正确性；
- 普通任务强制 task-run、memory 更新、独立 reviewer 或 release guard；
- 每轮预防性重验 verifier，随后才运行真实 DUT/workload；
- 用全局单 shell 或全局单 agent 代替具体资源冲突分析；
- compaction 后根据旧流程阶段推导新义务；
- 让 module ownership、agent 路由或 structured handoff 变成权限边界；
- 用 AI 环境自检 PASS 替代 RTL、DiffTest、Linux、综合、STA 或 PPA 证据。

## 稳定入口

- 规范：`.github/AGENTS.md`
- 环境说明：`AI_ENVIRONMENT.md`
- 可选生命周期工具：`scripts/agent-flow.sh`
- 显式 E2E：`scripts/agent-e2e.sh`
- release maintenance：`scripts/agent-maintain.sh --mode release`
- 长跑状态：`scripts/task-run-status.sh`
- RV64 架构入口：`npc/rv64/ARCHITECTURE.md`
- 架构机器查询：`python3 npc/rv64/eval/ppa/tools/architecture_registry.py query`

最终工程结论应先说明“哪个真实对象在什么配置下发生了什么”，再列修改、直接证据和未覆盖范围。图、
agent、DB 和记录系统只在它们确实减少歧义、支持协作或满足发布要求时出现。
