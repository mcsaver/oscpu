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

1. 先用 brief 获取 bounded 上下文，并根据工作选择 npc、verilator-tapeout、yosys-sta
   profile；历史证据走 runs/evidence，不默认全量读取原始日志。
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
- config、generated headers、filelist 与工具版本；
- simulation binary、固定 benchmark image；
- 每次 raw performance log；
- fresh netlist、SDC/lib/macro inventory、STA/area/power report；
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
  不能换一个 seed 绕过。
- baseline replacement 与 archive membership 是不同裁决。非支配 trade-off 可以留档；自动替换
  accepted baseline 必须通过 normative dominance、per-axis floor、global front 和 promotion checker。

## 7. 每刀执行闭环

~~~text
RECALL
  -> freeze completion definition/cohort/contracts
  -> implement one reversible slice
  -> focused positive + mutation/negative
  -> full functional + representative performance evidence
  -> if complete: same-design synth/STA/Power qualification + global front
  -> implementer/reviewer conflict audit
  -> RECORD + strict guard
~~~

失败后先判断是实现根因、契约遗漏、量具/绑定错误还是搜索假设错误。负候选保留失败证据和拒绝
理由，不污染 canonical baseline；不得机械重复相同命令或通过缩小测试、放宽 checker 得到绿灯。

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
- source/evidence binding、mutation 结果和 profile/strict-guard 证据；
- 实现者结论、审查者反例、已关闭冲突与剩余风险；
- 下一轮补偿实验或 global-thaw 候选。
