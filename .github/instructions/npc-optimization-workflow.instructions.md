---
description: "NPC 性能优化方法。区分迭代期定向实验与候选 promotion，要求性能结论绑定可比 workload 和必要 correctness，不把每次编辑都升级为全量发布门。"
applyTo: "npc/rv64/perf/**,npc/rv64/eval/ppa/**,npc/rv64/syn/**,npc/single/design/ppa/**,npc/soc/design/ppa/**"
---

# NPC 性能优化流程

本流程适用于以降低 CPI、提高吞吐、优化 cache/BPU/LSQ/issue/commit/取指/访存为目标的 NPC 改动。
迭代期用能判断当前假设的 focused workload；准备作出全局性能、PPA 或 promotion 结论时，再叠加完整且
可比的回归。`npc/rv64` 的正式候选还需遵守 `rv64-ppa-optimization-workflow.instructions.md`。

## 一、正确性门槛

- 开始前确认一个与目标配置匹配的可用 correctness/performance baseline。若当前基线已知失败，先区分该失败
  是否影响当前假设；不能在受影响的错误基线上作性能 promotion 结论。
- 迭代中的 RTL 改动运行能覆盖所触碰事务和性能假设的 directed correctness test 与代表 workload；不在
  每次编辑后机械重跑全量。准备声称全局 CPI 改善或进入 RV64 promotion 时，才运行目标后端规定的完整
  CPU-test/official/AM/DiffTest/benchmark 合取，并收集可比的 `cycles/commits/CPI`。
- Difftest 或某个 workload 当前不可用时如实说明 GAP；不得用局部 PASS 外推未运行范围。

## 二、代表样本选择

当目标是全局 CPI 分布或候选 promotion 时，从同一次 CPU-test 全量结果中选择三类样本：

1. `highest_cpi`: CPI 最高的测试，用来暴露启动、控制流、异常边界或短程序固定开销。
2. `lowest_cpi`: CPI 最低的测试，用来观察核心在高吞吐负载下真正跑起来时的瓶颈。
3. `near_average_cpi`: CPI 最接近全量加权平均 CPI 的测试，用来代表当前总体水平。

禁止只看 `add` 作全局优化判断；`add` 可以作为冒烟或定向实验。局部假设允许使用直接相关 workload，
但结论必须限定范围；正式候选再补齐代表样本与高权重/excess-cycles 工作负载。

作出全局 improvement 或 promotion claim 时，三类必选样本只是最低分析集合；还应从全量结果按
`cycles` 总贡献、`cycles - 0.5 * commits` excess cycles、I/D miss、branch/control wait、LSU/AXI wait
等与目标相关的维度排序，形成足以支撑该全局结论的瓶颈图。focused experiment 只需覆盖当前假设的局部
调用链、正确性与性能指标，不必先建立全核瓶颈图；其结论必须明确限定 workload/config/模块范围。

## 三、比较方法

- focused A/B 报告直接相关 workload/config、指标、正确性结果与结论边界；它可以证明局部假设，但不能
  外推全局 CPI、PPA 或 promotion。
- 声称全局改善时，报告全量加权 CPI、三类代表样本 CPI、全量 pass 数，并按可用的
  cache/BPU/issue/retire 统计解释关键计数变化；不能只用 `add` 的 hit/miss 或 cycles 支撑全局结论。
- 若一个局部优化只改善某个高 CPI 短程序，可保留为该 workload 的定向结果，但不能称为全局有效优化；
  若全局结构改动触碰 ready/valid、AXI outstanding、cache fill 或 response ownership，必须先从调用链和
  数据流证明不变量，再用与全局 claim 匹配的完整回归闭合。
- 负优化不进入候选；在最终报告中说明原因。只有原因稳定且后续很可能复用时才写 memory，显式持久化
  任务才写 task-run。

## 四、RTL 组织约束

- Verilog/SystemVerilog 源码默认遵循“一个 module 一个源文件”；文件名应与主 module 名一致。
- 新增 helper bridge、cache、queue、adapter、predictor 等 module 时，必须新增同名源文件并更新 `vsrc/filelist.mk`，不要继续塞进已有顶层文件。
- 临时实验若短时间内多 module 共文件，最终回归前必须拆分；否则不能视为可交付状态。

## 五、记录要求

- 普通迭代在最终报告中给出 design/config/workload、A/B 指标、correctness 结果和保留/撤回决定。
- 正式 RV64 promotion 或跨会话长跑可显式创建 task-run，记录全量 CPI 表、design state、timing/area/
  power qualification 与 promotion 边界。
- 只有稳定流程、可复用 root cause 或长期决定才写 memory。
