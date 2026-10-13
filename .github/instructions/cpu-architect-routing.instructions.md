---
description: "本地 RV64 CPU Architect 的架构专注路由：用户明确要求架构优化或存在有证据的开放结构选择时调用；独立取证、架构设计、RTL 实现分工，不直接向 Architect 输入 RTL。"
applyTo: "npc/rv64/design/arch/**,scripts/cpu_architect_*.py,.codex/agents/cpu-architect.toml,.github/agents/cpu-architect.agent.md"
---

# CPU Architect 语义路由与职责边界

本文件帮助主 agent 选择和组织 `cpu_architect`，不建立启动许可。分类看用户目标与开放的工程决策，
不看关键词、文件数量或 classifier PASS。Architect 只读架构材料和有来源的精简证据摘要，只做架构分析、
设计及范围内的文档修改；实现事实取证和 RTL 实现由独立角色负责。

## 1. 触发与职责

| route | 适用语义 | 默认 owner |
| --- | --- | --- |
| `ARCHITECT` | 用户明确要求本地 CPU 架构优化，或已有事实表明存在开放的流水/事务生命周期/资源拓扑/架构状态取舍 | `cpu_architect` |
| `EXPLORER` | 根因、owner、周期边界或资源竞争仍未知，需要实现事实 | built-in explorer / 对应 domain evidence 角色 |
| `WORKER` | 方案已明确，执行 RTL、TB、脚本或工具实现与验证 | worker / 对应 domain agent |
| `REVIEWER` | 候选已存在，审查不变量、证据边界或正式 promotion | 独立 reviewer |
| `CLARIFY` | 缺少无法从仓库发现、且会实质改变目标或授权的信息 | 主 agent |
| `NON_ARCH` | 普通文档、环境、CI、报表、软件、状态或概念解释 | 普通 agent |

用户明确要求架构优化时，主 agent 将设计工作交给 Architect，缺失事实可在同一授权内委派取证。
主 agent 自行发现架构需求时，应有具体结构选择，例如跨级周期边界、事务恢复责任、共享资源拓扑或
commit/precise trap/memory ordering 可见性。单纯“CoreMark 慢”或“timing FAIL”先取证，不能直接假定
需要重构；门控时钟过载、工具配置和局部已定位 bug 通常由对应角色处理。

方案已定转给 worker；只审现有候选转给 reviewer。仅讨论架构不启动 RTL 实现；用户已授权端到端优化时，
主 agent 在方案明确后接续 worker/验证，不新增人工批准、receipt 或阶段 gate。
架构相关文档设计属于 Architect；纯格式、命名、registry/schema/view 维护仍由普通角色处理。

## 2. 主 agent 如何派发

为 Architect 创建干净的上下文。调用接口支持时使用 `fork_turns="none"`，仅传入：

- 用户目标、可观察 acceptance criteria、实际 worktree、约束和允许的变更范围；
- 必要工作区规则及相关架构切片；
- 精简证据摘要、已知未知项和本轮待决定的问题。

不要完整继承 RTL 调试历史，不转发整段源码、代码截图、原始波形或大日志。若上下文已受大量实现材料
占用，应重建架构会话并传递必要摘要；口头要求忽略旧内容不等于清空上下文。无法控制继承时，说明这一
限制，不宣称已经隔离。该分工是行为和上下文约束，不是文件系统硬沙箱。

开放的结构选择需要同时权衡关键周期边界与 CPI/进度时，可并行派发两个干净上下文的 Architect：
两者使用同一份精简事实、约束和父点，一个关注关键周期边界及路径迁移，一个关注 CPI、容量/吞吐与进度；
都遵守第 3 节的架构输入边界。事实更新同步给双方，避免因输入不同而误判设计分歧。

采用该双路方式时，设计稿形成后交给新的独立架构评估上下文，只提供同一事实摘要和候选合同，不继承
作者对话。复核组合后的等待环/死锁、producer 身份来源与生命周期、容量和吞吐的区别、实验变量混杂，
提出最小反例并分清合同缺口与待实测项。该评估仍不读 RTL，也不替代实现侧独立审查。主 agent 根据
修订合同接续已授权的实现与验证；局部问题、既定方案或单一有界选择无需固定支付三 agent 的成本。

## 3. 架构输入与事实取证

Architect 从 `npc/rv64/ARCHITECTURE.md`、相关 spec/协议/拓扑/状态图和设计决策进入；可读
`vsrc/` 中的 `PROTOCOLS.md`、`TOPOLOGY.md`，不要按目录一刀切。有界 registry query 仅限已知返回
架构元数据的结果。混有 RTL 代码或原始日志的文档先由取证角色提炼。

Architect 不直接读取或修改 RTL、TB、综合网表、波形、原始仿真/EDA 日志，不自行运行实现构建或测量；
搜索与脚本输出也不得绕过这一边界。必要的架构图、规格和实现契约可在既定范围内编辑。
源码和实际行为仍是真源，架构文档不能未经核实就被视作当前实现。

发现影响决策的事实缺口时，主 agent 或 Architect 委派独立 built-in explorer / domain evidence 角色，
围绕具体问题读取源码、报告或执行必要定向检查。回传只包含所需架构事实及来源指针，例如：

- 当前实现/设计意图/候选方案的区分，相关版本、配置、工况和 workload；
- 周期、延迟、启动间隔/吞吐、容量、资源竞争及 owner/recovery/可见性；
- 支持结论的简短观测与适用边界，测量事实、推断和 `UNKNOWN` 分开。

不要求固定 schema、完整 source manifest 或逐条 hash。Architect 不沿源码/波形/报告指针打开原始材料，
有疑问继续向取证角色提问，不让代理转发实现代码。未知项会影响选择时，明确假设、反证条件和需补证据；
不能从通用 CPU 例子补全当前实现。

## 4. 架构交付与验证

架构候选至少说明机制→观测→指标的因果链、竞争解释、周期/资源/事务变化、预测、反证与回滚条件，
并给出接口行为、state owner、冲突优先级和验证目标等实现契约。无需把信号名或 RTL 改法写进设计。

架构阶段给出计划和收益假设；实际实现与执行由 worker/domain agent 负责。验证后才能依据返回摘要声称
收益，必须分清计划、已实现与已验证。correctness 与至少一个目标指标都要有对应实际证据，不能用仿真
替代 STA、用 compile PASS 替代 CPI，或用不合格功耗结果作签核结论。

A/B 保持相关 workload、config、tool/version、corner/constraints、seed/thread 和测量口径可比，明确
baseline/candidate 差异与限制。确定性检查默认一次；随机、flaky、PPA 噪声、机器异常或用户明确要求时
才按原因决定重复。不同 corner/config、负向 oracle、mutation 与抽象层是互补证据，不是机械复验。

多轮实验明确每轮父点和主要改动，分别报告相对父点与原始基线的差异；容量、带宽和位置等可分离因素
分轮比较，必要伴随改动及其影响如实说明。由实现/取证角色核实真实 RTL、执行测量并回传精简事实。
原约束和完整 workload 保持可比，以真实新关键路径、目标锥变化和完整 CPI 反馈选择下一轮；不按预列
清单叠满候选，也不拼接不同父点的最好结果。局部 II、边界测试或 mock 行为不能外推全核 RAW/CPI。
并行测量使用独立产物目录，保持相关候选输入固定；输入变化按实际影响说明并保留原记录，不能静默归为同源。
互不竞争真实共享可变资源的工作可并行。结果分析结束、无运行或诊断依赖后，在已有授权范围内清理
本轮可再生的大产物，保留结果、关键诊断与可重建的小复现输入；失败证据也保留。

保持 ready/valid、backpressure、owner/epoch、cancel/flush、无丢失/重复、progress、precise trap、CSR/
FENCE、memory ordering 和 architectural visibility 等受影响不变量。不得通过降低频率目标、删约束、
缩减 workload、放宽 checker 或功能退化制造收益。

## 5. 可选正式流程与 classifier

- **ordinary architecture task**：无需 classifier receipt、固定 YAML 启动包、逐实验 IR/content manifest、
  Grounded Experience Loop 或固定字段最终报告。按用户目标取得最小充分证据。
- **formal Architecture/Pareto promotion**：由实现/取证角色保留 baseline/candidate source、production
  filelist/elaboration、workload/config、tool/version、corner/constraints 和原始证据 provenance；独立
  reviewer 复核身份、反例与 PASS/GAP。Architect 仍只接收摘要，不兼任最终审批者。
- **formal-research/learning**：仅在用户或任务明确 opt-in 时启用 CapabilityGraph、ExperienceRecord、
  Meta-Critic、KnowledgeGap、prediction calibration 和 unseen exam，且不解除本角色的输入边界。

`.github/ai-env/contracts/cpu-architect-routing-v1.json` 与
`python3 scripts/cpu_architect_route.py classify --input <task-packet.json>` 仅用于歧义任务、规则开发或回归。
机器 JSON 保留六路 taxonomy 和兼容字段；`architect_hard_gates` 是旧接口名，表示辅助分类信号，
`architecture_change_authorized` 描述已有任务范围。它们不生成授权，也不能阻止用户已明确要求的架构讨论
或同一授权内安全本地 inspect/edit/build/test/collect/analyze；实际执行仍按上述角色分工。
