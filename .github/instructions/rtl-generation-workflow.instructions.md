---
description: "RTL 实现与修改原则。要求在真实接口/时序/状态不变量上做 root-cause 级修改，并按变更风险选择最小充分验证；不强制固定阶段、九项拓扑文档或每次全量回归。"
applyTo: "**/*.{v,sv,vh,svh}"
---

# RTL Generation Workflow

目标是生成可综合、可验证、符合现有接口与微架构意图的 RTL。需求、协议、状态机、不变量和数据通路是
理解设计的维度，不是必须逐段输出后才能写代码的 permission phase。

## Understand the affected hardware

修改前读取足以回答当前问题的 RTL、调用者/被调用者、spec、filelist 和 testbench。局部组合逻辑不要求
画完整核拓扑；跨模块或触碰控制路径时，必须真正理解受影响的 transaction lifecycle。

涉及 ready/valid、stall、flush/redirect/trap、异常序、访存序、投机恢复或跨 module 接口时，至少确认：

- transaction 在哪一拍被接受，producer/consumer 分别拥有什么；
- backpressure 时 valid 和 payload 如何保持，何时允许撤销；
- reset、flush、redirect、trap、stall 与正常推进的同拍优先级；
- 哪些状态/owner/tag 在 capture、pending、completion、drain 中保持一致；
- 异常、重放、取消和退休不会丢失、重复或错误归属；
- 位宽、符号扩展、对齐、byte enable 和地址边界与 spec 一致。

这些事实可来自已有 contract、源码结构、断言或 testbench。只有当前接口含义不清楚时，才补充或修订
interface contract；不要为了模板完整机械填写与本次改动无关的表格。理解不足时继续 inspect 或提出 GAP，
不是等待某个 agent 生成形式化“冻结收据”。

## Express the hardware directly

- 时序状态只在时序块更新；组合决策完整赋值，避免锁存器和多驱动。
- 状态机、仲裁、ready/valid、flush/kill、issue/select、ROB/LSQ 更新和共享资源控制应在 RTL 结构中可见，
  不隐藏在大型 function 中。
- function 仅用于小型纯组合 helper，例如编码、shift/jam、predicate 或饱和/舍入辅助逻辑。
- for-loop 应对应可解释的综合硬件，例如并行比较、优先编码、mux tree 或复制单元；关注规模和关键路径。
- 共享资源明确给出 mux、enable、owner 与冲突处理；跨周期结果必须有清楚的有效性/归属状态。
- 明确常数位宽与 signedness，避免无尺寸 literal、隐式截断/扩展和有符号比较漂移。
- 不为了减少 diff 复制已有 bug，也不把多个不同职责继续塞进顶层；新增可复用 module 时更新真实 filelist。

## Source-format and toolchain constraints

- 进入 npc/rv64 可综合 filelist 的硬件使用 `.v` 和 Verilog-2001 风格：`wire`/`reg`、
  `always @(posedge clk)`、`always @(*)`。
- `.sv` 用于 testbench、DPI、仿真顶层和断言环境。不要把验证-only DPI/SV 文件混入综合网表。
- 当前 Icarus 模块 TB 对 `always_comb` 中常量位选存在兼容风险，因此可综合 `.v` 不使用
  `always_comb`、`always_ff` 或 `logic`；Verilator/Vivado 能解析不代表 Icarus 行为等价。
- 一个主 module 一个同名源文件是默认组织方式；短期实验可例外，但交付前应避免不透明的多 module 堆叠。

这些是本地工具链和可综合结构约束，不要求把每个 always/assign 映射到人工编号，也不要求写 RTL 前先
输出固定九项电路拓扑。复杂状态或接口容易误解时，应留下足够的 spec/注释/断言帮助未来维护者。

## Choose validation by the claim

修改后以 acceptance criteria 为中心选择验证：

1. 运行直接覆盖 root cause 的定向 module TB、assertion 或负向 mutation；
2. 确认改动进入实际 filelist/elaboration，并运行与目标后端直接相关的 lint/compile/sim；
3. 触碰跨模块控制/事务不变量时运行 `make -C npc/rv64 check-contract` 或对应 contract test；
4. 使用了 Icarus/Verilator 语义敏感构造时，运行相关工具的直接编译/TB；
5. 准备作出全核、DiffTest、Linux、综合、STA、PPA 或 promotion 结论时，再运行该层级的完整配置与
   workload。

`make -C npc/rv64 check-rtl-style` 适合修改可综合 RV64 源码或 style checker 时运行。Vivado OOC 只在
目标包含其 elaboration/synthesis 语义、工具兼容风险或后续 PPA 时运行。不要在每次局部编辑后机械执行
style + Verilator + Icarus + Vivado + full-core 全套，也不要只用其中一个低层 smoke 越级证明完整系统。

固定输入、固定命令和确定 oracle 默认一次。失败时先读取最接近根因的编译、波形、assertion 或 mismatch，
再增加定向检查；不先重验未修改且有自身测试的 runner/verifier。

## Result boundary

最终报告用真实 module/signal/transaction、周期/配置、TB/EDA 观测和 PASS/GAP 范围说明结果。保留反例、
未知项和未运行层级。普通 RTL 修改不要求 task-run、memory、contract SHA、candidate-only 或独立 reviewer；
正式 Architecture/Pareto promotion、release/security、难恢复操作或用户明确要求时，再使用相应专项复核和
provenance。
