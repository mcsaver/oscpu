---
description: "本地 RV64 CPU Architect Agent 的语义路由。只有存在开放的跨流水/事务/架构状态设计决策，并能形成 correctness 与 CPI/PPA 可证伪闭环时才选择；classifier 仅为可选辅助。"
applyTo: "npc/rv64/design/arch/**,scripts/cpu_architect_*.py,.codex/agents/cpu-architect.toml,.github/agents/cpu-architect.agent.md"
---

# CPU Architect 语义路由与验证边界

本文件帮助选择 `cpu_architect` 的职责，不建立启动许可。分类看开放的工程决策及其语义深度，不看 CPU
关键词、文件数量、修改行数或“优化”字样。用户/父任务给出的目标与 ownership 足以完成角色选择。

`.github/ai-env/contracts/cpu-architect-routing-v1.json` 和下面的命令只用于歧义任务、路由规则开发或回归：

```bash
python3 scripts/cpu_architect_route.py classify --input <task-packet.json>
```

不要求普通任务生成 task packet 或保存 classifier receipt。命令输出是 advisory，不能授予、撤销或阻止
用户/父任务已放入范围的安全本地 inspect、edit、build、test、collect 与 analyze。

## 1. 语义职责

| route | 适用语义 | 默认 owner |
| --- | --- | --- |
| `ARCHITECT` | 开放的微架构结构决策、跨流水/事务生命周期变换或 correctness+CPI/PPA 取舍 | `cpu_architect` |
| `EXPLORER` | 根因、transaction、owner 或周期边界仍未知，以事实发现为主 | built-in explorer / `npc` |
| `WORKER` | 方案已经确定，执行局部 RTL、TB、脚本或工具实现 | worker / 对应 domain agent |
| `REVIEWER` | 候选已存在，只审查不变量、证据边界或正式 promotion | 独立 reviewer |
| `CLARIFY` | 缺少无法从仓库发现、且会实质改变目标或授权的信息 | 主 agent |
| `NON_ARCH` | 文档、环境、CI、报表、普通软件、状态汇报或概念解释 | 普通 agent |

选择 `ARCHITECT` 时应同时看到以下语义：

1. 对象是当前工作区的本地 RV64 CPU spec、production RTL、testbench 或性能/EDA 证据。
2. 存在尚未决定的结构选择，而不是已经批准的机械实现。
3. 触及跨 module transaction、backpressure/recovery/lifecycle、流水周期边界、共享资源拓扑，或 commit、
   precise trap、CSR/FENCE、memory ordering、redirect、architectural visibility 等架构不变量。
4. acceptance criteria 包含 correctness，并至少包含 CPI、timing、area、power 或可量化 complexity 一项。
5. 有本地事实支持一个可证伪的候选与 retain/rollback 实验；不足部分可以在同一授权范围内继续定向探索。
6. 架构级编辑位于用户/父任务给出的变更范围内；classifier 不提供这项授权。

若主要工作仍是定位根因，优先 `EXPLORER`；若 Architect 在进行中发现一个局部事实缺口，可以直接做安全、
定向的读取、仿真或计数收集，不需要停下来取得新 receipt。方案已经固定时切给 `WORKER`；只裁决现有候选
时使用 `REVIEWER`。

## 2. 本地证据与搜索范围

先从 `npc/rv64/ARCHITECTURE.md` 或有界 registry query 定位当前 owner、production filelist、elaboration、
dynamic、mapped 与 STA/PPA 边界，再读取直接相关的 spec/RTL/TB。通用大核结构只能提供搜索维度，不能替代
当前核事实。

可探索 frontend、rename/dispatch、scheduler/issue、execution/bypass、LSQ/cache/MMU/interconnect、
writeback/commit/trap/control 与 physical cone。结论按问题绑定到 source/spec、wave/assertion、counter、
仿真或 EDA 报告；复杂场景可建立 Architecture IR，简单有界切片可直接用时序图、表格或文字说明。

以下任务不因接近 CPU 而启动 Architect：README/格式/命名、普通 lint、无开放取舍的单点 bug、单个 TB 或
报表解析器、EDA 安装/CI 故障、registry/schema/view 维护、重复运行既有命令并汇总结果、只读状态和概念解释。
一行 `commit_valid` 若改变 precise trap 可见性仍可能是架构决策；跨二十个文件的纯重命名仍是 `WORKER`。

## 3. 最小充分验证

候选至少提供机制→观测→指标的因果链、竞争解释、预测、反证条件、保持的不变量与回滚点。correctness 与
至少一个可测指标都必须有直接证据；PPA 结论不能由 RTL 仿真代替，CPI 结论不能由 compile PASS 代替。

A/B 保持相同的相关 workload、config、tool/version、corner/constraints、seed/thread 与测量口径，并明确
baseline/candidate source 差异。普通切片只记录支撑比较的相关身份，不强制完整 source manifest。

确定性输入、命令和 oracle 默认执行一次。随机、并发、已知 flaky、未固定 seed/thread、variable-PPA 噪声、
机器异常或用户明确要求时才重复，并说明原因、次数、阈值和停止条件。A/B、正负向 oracle、不同 corner/
config、mutation 或抽象层是互补证据，不是机械复验。

始终保持 ready/valid、backpressure、owner/epoch、cancel/flush、无丢失/重复、progress、precise trap、CSR/
FENCE、memory ordering 与 architectural visibility 等受影响不变量。不得通过降低频率目标、删除约束、缩减
workload、放宽 checker 或功能退化制造收益。

## 4. Ordinary、promotion 与 formal research

- **ordinary architecture task**：无需 classifier receipt、固定 YAML 启动包、逐实验 Architecture IR/content
  manifest、Grounded Experience Loop 或固定字段最终报告。以满足 acceptance criteria 的最小证据闭环为准。
- **formal Architecture/Pareto promotion**：显式绑定真实 baseline/candidate source/source set、production
  filelist/elaboration、workload/config、tool/version、corner/constraints 和原始 wave/counter/EDA provenance；
  由独立 reviewer 复核身份、反例与 PASS/GAP，不机械重跑确定性命令。
- **formal-research/learning**：仅在用户或任务明确 opt-in 时启用 CapabilityGraph、ExperienceRecord、
  Meta-Critic、KnowledgeGap、prediction calibration 和 unseen exam；这些记录不能反向成为普通工程许可门。

## 5. 可选 classifier 的兼容语义

机器 JSON 保留现有字段和六路 taxonomy，以兼容 `scripts/cpu_architect_route.py` 及其测试。其中
`architect_hard_gates` 是旧接口名，表示 classifier 使用的语义信号，不是 agent 权限 gate；
`architecture_change_authorized` 只描述父任务现有范围，不会由 classifier 生成授权。

典型判断：已确认跨生命周期 critical cone 且要用 TB/CPI/STA 比较结构候选是 `ARCHITECT`；“CoreMark 慢”
但根因未知是 `EXPLORER`；按已批准方案实现寄存器是 `WORKER`；审查已有 Pareto 候选是 `REVIEWER`；修改
trace parser 或 CI timeout 是 `WORKER/NON_ARCH`。
