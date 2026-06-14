---
description: "NPC 性能优化强制流程。处理 npc/single 或 npc/soc 的 CPI、性能、cache、BPU、LSQ、OoO/superscalar 优化时，必须先全量 CPU-test 正确性闭合，再基于全量 CPI 分布选择代表样本分析，禁止只用 add 作为优化依据。"
applyTo: "npc/{single,soc}/**"
---

# NPC 性能优化强制流程

本流程适用于任何以降低 CPI、提高吞吐、优化 cache/BPU/LSQ/issue/commit/取指/访存为目标的 NPC 改动。它与 `npc-study.instructions.md` 和 `rtl-generation-workflow.instructions.md` 叠加执行。

## 一、正确性门槛

- 性能优化前必须先确认当前基线能跑通 CPU-test 全量；若全量未通过，先修正确性，不做性能结论。
- 每次落 RTL 性能改动后，都必须跑 CPU-test 全量并收集每个测试的 `cycles/commits/CPI`；单个测试 PASS 只能作为冒烟，不能作为优化是否有效的结论。
- Difftest 如果当前配置不可用，必须在记录中说明；但这不降低 CPU-test 全量 GOOD TRAP 的门槛。

## 二、代表样本选择

每轮性能分析都必须从同一次 CPU-test 全量结果中选出三类样本，并同时分析：

1. `highest_cpi`: CPI 最高的测试，用来暴露启动、控制流、异常边界或短程序固定开销。
2. `lowest_cpi`: CPI 最低的测试，用来观察核心在高吞吐负载下真正跑起来时的瓶颈。
3. `near_average_cpi`: CPI 最接近全量加权平均 CPI 的测试，用来代表当前总体水平。

禁止只看 `add` 做优化判断；`add` 只能作为冒烟或历史对比样本。若某个代表样本过短或过特殊，仍要先报告它被选中的原因，再额外补充一个“高权重/高 excess cycles”的样本，不能直接替换掉三类必选样本。

进入深水区后，三类必选样本只是最低分析集合；还必须同时从全量结果按 `cycles` 总贡献、`cycles - 0.5 * commits` excess cycles、I/D miss、branch/control wait、LSU/AXI wait 等维度排序，决定下一次优化落在哪个模块。不要默认只优化 OoO 后端；fetch bridge、AXI crossbar、cache、LSU、提交口、仿真统计边界都要纳入同一张全局瓶颈图。

## 三、比较方法

- 优化 A/B 必须报告全量加权 CPI、三类代表样本的 CPI，以及全量 pass 数。
- 若有 cache/BPU/issue/retire 等统计，至少对三类代表样本给出关键计数变化；不要只报告 `add` 的 hit/miss 或 cycles。
- 若一个局部优化只改善某个高 CPI 短程序，但不改善全量加权 CPI 或高周期贡献样本，不能视为有效优化；若一个全局结构改动触碰 ready/valid、AXI outstanding、cache fill 或 response ownership，必须先从调用链和数据流证明不变量，再用全量回归闭合。
- 负优化必须撤回，并把“为什么负优化”写入 task-run 或 memory，避免后续重复尝试。

## 四、RTL 组织约束

- Verilog/SystemVerilog 源码默认遵循“一个 module 一个源文件”；文件名应与主 module 名一致。
- 新增 helper bridge、cache、queue、adapter、predictor 等 module 时，必须新增同名源文件并更新 `vsrc/filelist.mk`，不要继续塞进已有顶层文件。
- 临时实验若短时间内多 module 共文件，最终回归前必须拆分；否则不能视为可交付状态。

## 五、记录要求

- `.github/task-runs/<日期-任务名>/task-report.md` 必须记录全量 CPI 表路径、三类代表样本、A/B 对比和最终保留/撤回决定。
- 稳定流程或踩坑写入 `.github/memory/modules/npc.md` 或 `.github/memory/known-issues.md`。
