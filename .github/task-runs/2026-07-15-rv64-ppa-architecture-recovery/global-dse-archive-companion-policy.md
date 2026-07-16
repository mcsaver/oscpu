# R4 全局 DSE archive 伴随策略

> **状态**：ACTIVE COMPANION POLICY / NON-NORMATIVE。本文只改变候选的生成、保留、
> 淘汰和证据组织方式，不修改架构能力或 PPA 晋级门。规范真源仍是
> `npc/rv64/design/arch/rv64-architecture-ppa-contract.md` v2。

## 0. 输入绑定与优先级

- 元策略原文：`design-inputs/global-dse-meta-strategy-input.txt`；SHA-256
  `9729C31ED3773AE233AA88C9CA908728C0023C6F47225F2FED7614A34A418A24`。
- 规范合同当前 SHA-256：
  `F29EA5568045EA5113214EAEF866A2E61731F9DA5F2919AED162124921AB0050`。
- 语义/时序实现底线：R4-P0A；性能/logic-area 测量锚：R3.6。
- hard gates 的优先级固定为：功能正确性、完整双发射、完整 OoO、精确异常/恢复、真实双
  memory datapath、exact-5ns 200 MHz；这些门不得由 archive、分数、预测值或 PPA 收益抵消。
- Power 在 workload activity coverage 和 macro internal/leakage 模型未闭合时保持
  `unqualified`；不得以 vectorless proxy 排名或宣称三轴冠军。
- 若本文与规范合同在架构能力、证据资格或 promotion 上发生冲突，规范合同优先。本文只能
  增加保守的搜索纪律，不能放宽合同。

本次不修改任何 baseline 哈希绑定的规范文件。未来确需更新规范合同时，必须在同一原子切片中
同步更新 contract/policy/baseline provenance、全部引用哈希、schema/checker 和 mutation/unit
tests；否则更新无效。

## 1. 设计点生命周期

| 类型 | 定义 | 允许的检查 | PPA/晋级资格 |
| --- | --- | --- | --- |
| `intermediate_checkpoint` | 一个完整架构变更中的可回退切片，尚未形成预先声明的完整配置 | 本切片 focused correctness、接口/状态不变量、必要 mutation；允许 PPA 暂时变差 | 永远不得进入 Pareto archive、seed、canonical、accepted baseline 或 champion；不得执行晋级裁决 |
| `complete_design_point` | 该分支预先声明的全部协同切片已集成，配置、source、binary、image、netlist 和证据可绑定为同一 design id | 先跑全部 hard gates，再跑完整 workload/PPA 评估 | 只有此类型可以接受 archive 或 promotion 裁决 |
| `architecture_feasible_seed` | 第一个满足 v2 合同一次性 R3.6 过渡的完整设计点 | 九项 DI/OOO、全部功能、固定 benchmark、fresh synth/STA 全绿 | Power/total area 未 qualified 时只证明 seed 存在，仍不得进入 formal front 或成为 champion |

`intermediate_checkpoint` 的暂时回退不是对 R4-P0A/R3.6 floor 的豁免。它只是把裁决推迟到
完整配置；若分支无法完成或完整点不能恢复全部 floor，分支必须关闭并保留失败证据。

每个分支在首个切片前必须声明 `completion_definition`：联合修改块、预期补偿关系、完成条件和
最大验证边界。不得在看到局部坏结果后任意扩大“尚未完成”的定义。

## 2. 持久候选集合

不再用单一 `current_best` 覆盖搜索历史。持久状态至少分为四类：

1. **feasible Pareto archive**：只包含 `complete_design_point`，且功能、九项 DI/OOO、timing
   hard gates 全绿；只使用 qualified axes 做 nondominated sorting。
2. **development branches**：允许保存架构尚未完成的中间切片，或暂时被支配但有明确跨模块
   补偿假设的完整点。它们没有 archive/promotion 资格，必须记录下一步补偿实验和复核期限。
3. **high-uncertainty candidates**：缺测量、代理误差大或结构假设尚未验证的候选。当前没有校准
   surrogate，因此这里只能记录“证据不确定度”，不得伪称模型 uncertainty。
4. **diversity/far candidates**：在架构 knob、修改 footprint 或 objective space 上远离现有点的
   候选，用于避免所有分支聚集到同一局部结构。

在 total area 或 Power 未 qualified 时，只允许建立明确标注的
`engineering_proxy_archive`。它可以记录架构可行完整点在 Performance/logic-area 两个已合格轴上的
非支配关系，但必须同时保持：`front_accepted=false`、`canonical=false`、
`ppa_champion=false`。只有规范合同要求的全部轴闭合后，才能迁移为 formal feasible archive。

archive membership 与 baseline replacement 是两个不同判定：

- 非支配 trade-off 点可以留在 archive，即使它没有支配 accepted baseline；
- `require_candidate_dominates=true`、`minimum_balanced_score` 和 v2 promotion checker 继续决定
  accepted/canonical/champion，不能被 archive membership 绕过；
- balanced score 只在同一 Pareto front 内给出推荐顺序，不得逐出其他非支配 archive 成员。

## 3. 完整点裁决顺序

每个 `complete_design_point` 必须按以下顺序 fail closed：

```text
1. same-design provenance / completion_definition
2. functional hard gates
3. DI-1..DI-5 and OOO-1..OOO-4
4. exact-5ns timing hard gate
5. per-workload floor and worst-workload check
6. Area and qualified-Power evidence qualification
7. Pareto dominance / archive contribution
8. scalar ordering inside the same front only
9. normative promotion checker, if baseline replacement is requested
```

步骤 1～5 任一失败，设计点不得进入任何 Pareto 比较。Power 未合格时该轴必须是
`unqualified`，既不能填 0，也不能被均值、估计或 vectorless proxy 代替。

每个完整点还必须绑定不可变、内容寻址的 source snapshot/worktree bundle。九项架构 evaluator、
功能回归、仿真、综合和 STA 必须在该候选自己的快照上运行。当前 `check.py/front.py` 会用 live
`npc/rv64/vsrc` 重新计算架构门，因此不能用一个当前工作树严格复核多个历史 RTL 候选；在
snapshot-aware evaluator 完成前，多点结果只能留作 development evidence，不能宣称已完成严格
archive audit。

当前 required module-test inventory 也存在显式版本漂移：testbench `TESTS` 已加入
`tb_ooo_typed_memory_classifier` 并展开为 103 项，而 v2 合同和机器 policy 仍固定为 102。
S1 focused/full development regression 必须运行新增测试；但在合同、policy、required-test
inventory、全部引用哈希和回归测试按原子切片同步更新前，任何 102/103 混用的结果都不得用于
promotion。未来 required count 应由 hash-bound inventory 推导，不能继续由 manifest 自报常数。

## 4. 同源三分支与组合候选

Performance、Power、Area/timing 三支必须从同一个、哈希冻结的
`architecture_feasible_seed` 独立分叉。当前 `baselines/index.json` 的 seed 仍为 `null`，因此 S1/S2
期间所有切片都只是 development checkpoints，不能各自宣称获胜。

独立分支通过完整点评估后，才允许建立组合候选。组合候选必须拥有新的 design id 并重跑全部
hard gates、workload、synth/STA 和 qualified-Power 证据；不得继承父分支绿点或把不同不完整设计
的优势拼接为一个虚假设计。

## 5. Global thaw

`K=4`：每完成并裁决四个 `complete_design_point`，强制执行一次 global thaw；
`intermediate_checkpoint` 不计入 K。若连续两个完整点暴露同一跨块瓶颈，可以提前 thaw，但不得
跳过下一次正式计数。

每次 thaw 至少从两个不同 archive/development 父点生成联合候选，并重新允许修改早期参数。
联合块固定为：

```text
{frontend width, fetch queue, predictor}
{ROB, PRF, IQ, commit width}
{dual AGU, translation, LSQ, cache banks, MSHR}
{issue width, FU, ports, bypass}
```

thaw 记录必须包含：父点 SHA、选择的块、单项假设、联合补偿假设、完成定义、完整点结果和
交互增益。离散交互增益优先按下式记录：

```text
I(i,j) = J(x+i+j) - J(x+i) - J(x+j) + J(x)
```

在没有合格单一标量 `J` 时，对 Performance/Area/qualified-Power 分别记录增量和 Pareto 关系，
不得先行压成一个分数。Attention/SHAP 只能作为未来搜索启发，不能替代联合扰动证据。

## 6. Workload 稳健性

- 当前冻结 workload 为 CoreMark 与 Dhrystone10k；两项各自 throughput ratio 必须
  `>=0.995`，retired instructions 必须与固定镜像锚相等。
- 淘汰和保留报告必须显式写出 `min_per_workload_ratio`、最差 workload 名称和退化值；几何平均、
  balanced score 或总体 IPC 不得掩盖单项失败。
- DI/OOO directed microbench 是 hard-gate workload，不得被 CoreMark/Dhrystone 平均掉。
- CVaR、尾部风险和 held-out workload 在 workload 集扩展并冻结 provenance 前保持 `defer`；
  现在不得用两个样本伪称统计 CVaR。

## 7. 候选生成纪律

在没有经过校准的 surrogate/RL 前，候选生成采用证据化人工/规则驱动方式：

- 约 50%：从不同 archive 或 development 父点做跨模块联合扰动；
- 最多 20%：在有真实完整点 PPA 数据时按 Pareto 缺口选择；没有 hypervolume 工具时不得伪称
  expected hypervolume improvement；
- 至少 15%：选择证据最不完整、但能够通过一次有界实验显著降低不确定度的候选；
- 至少 15%：随机重启或远距离 mutation，修改 footprint 不得与当前主分支同构。

初期批次不足以精确满足比例时，必须同时包含：一个 archive-neighborhood 候选、一个跨块补偿
候选和一个 diversity 候选。任何新单点都不能覆盖整个集合。

## 8. 多保真边界

- 低成本层只用于 `intermediate_checkpoint` focused correctness、lint、mutation 和局部结构计数；
  其 PPA 数字不得用于淘汰或晋级。
- 完整点评估必须包含同 design id 的九项架构门、全部功能门、每 workload 原始计数、fresh
  synthesis 和 exact-5ns STA。
- qualified Power 与 macro-inclusive total area 是 final three-axis front 的必需高保真证据。
- 代理模型、低/中保真 PPA 过滤器只有在建立校准误差、误杀保护和高保真复核后才能启用。

## 9. 当前执行顺序

1. 保留本元策略原文与采纳矩阵，不修改哈希绑定合同。
2. 完成当前 S1 typed correctness：final-PA CACHED/NC/IO 贯通 bridge/backend/SQ/wrappers，
   完成 focused verification；这些都是 `intermediate_checkpoint`。
3. 推进 S2 owner/token/epoch、双 AGU/translation/LSQ/cache admission，形成完整架构 seed 候选。
4. 只有 seed 九门、功能、benchmark、fresh synth/STA 全绿后，才从同一 seed 启动 P/Power/A-timing
   三分支与持久 archive。
5. 下一轮搜索开始前实现 archive registry/checker；在此之前用本文人工 fail-closed 执行，不得
   把计划状态写成已自动化。registry/checker 必须同时解决 per-candidate immutable source
   snapshot 和 required-test inventory 推导，不能继续复核 live RTL 或固定手写 102。

## 10. 最小 archive 记录

每个点或分支至少记录：

```text
design_id
parent_seed_id / parent_source_sha256
immutable_source_snapshot_path / immutable_source_snapshot_sha256
state = intermediate_checkpoint | complete_design_point
completion_definition
required_test_inventory_path / required_test_inventory_sha256 / derived_test_count
architecture_gate_vector
functional_gate_vector
timing_qualification
area_qualification
power_qualification
per_workload_metrics / min_per_workload_ratio
archive_class
dominated_by / contribution
uncertainty_kind / uncertainty_evidence
diversity_signature
next_compensation_experiment
all evidence paths and SHA-256
```

记录必须位于工作区、内容寻址并永久保留；不得依赖系统 `/tmp`。

## 11. 明确 defer / not-applicable

- 当前没有 RL pipeline：preference-conditioned policy、central critic、subsystem actors、entropy
  floor、policy ensemble 和 replay-buffer stratification 均为 `defer/not-applicable`。
- 当前没有校准 surrogate ensemble：预测 uncertainty、EHVI、SHAP/attention attribution 为
  `defer`；只记录可验证的证据不确定度与联合扰动。
- 当前没有合法参数化 knob schema：Sobol/Latin Hypercube 为 `defer`。
- 当前只有两个冻结性能 workload：CVaR/held-out statistical claim 为 `defer`。
