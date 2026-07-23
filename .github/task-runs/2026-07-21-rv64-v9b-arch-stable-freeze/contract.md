# V9B full-core arch-stable freeze 合同

## 本地工程范围

工作对象是授权工作区内的本地 RV64 Verilog/SystemVerilog 双发射 OoO 处理器、架构规范、仿真与 EDA 证据。所有 holder、owner、stall、flush、流水取消、异常恢复、验证变异和 PPA 术语均限定为处理器 RTL/EDA 语义。本合同用于准确界定对象、层级、作用域和工程目的，不改变任何 RTL、验证、反例或审查能力。

## 目标

在当前同一 `design_id` 的 DI-1..DI-5 与 OOO-1..OOO-4 九项架构硬门全部 GREEN 后，建立 fail-closed 的 full-core 架构稳定冻结资格门。冻结签发前必须先完成机器可审计的 P0/P1 架构债务账本，并拒绝陈旧文档、缺失证据、不同设计混用或不完整工具/约束输入造成的假绿。

## 前置条件

1. 当前生产 RTL closure、architecture directed suite 和九项门绑定同一 `design_id`。
2. 所有纳入冻结的已知 P0/P1 条目状态均可由当前源文件、永久命令和内容哈希证明；`OPEN/UNKNOWN/STALE_EVIDENCE` 任一存在即不得签发。
3. holder/owner census、接口/状态合同、恢复/完成资格、focused assert/release、compile-success RTL 验证变异、模块 aggregate 与适用系统 gate 均有明确状态。
4. 冻结记录内容寻址地绑定 RTL source、config/generated headers/filelist、architecture/spec、required tests、工具版本、Liberty/macro inventory、约束和运行参数。
5. 冻结记录只授予后续正式 PPA 的“可建立同源基线”资格；不直接授予 performance/area/power、200 MHz、Pareto 或 promotion 结论。

## 本轮交付

- 机器可读 architecture debt ledger 及其 schema/静态审计。
- arch-stable freeze manifest schema、builder/checker 和定向反例。
- 永久 canonical 命令与 task-run evidence。
- 实现者/独立审查者结论、声明等级和剩余风险。

## Fail-closed 条件

- P0/P1 非零、状态缺证据或 ledger 与 active ROADMAP/spec 不一致。
- 九项架构 record 缺失、非 GREEN、design_id 不一致、命令/provenance/source hash 漂移。
- holder census、功能 aggregate、接口/恢复/完成合同或 required-test inventory 缺失。
- RTL/config/filelist/tool/lib/macro/constraint/run-parameter 任一冻结输入缺失、未哈希或路径越出工作区。
- 任何将 diagnostic/proxy/unqualified 结果写成正式 PPA、物理 200 MHz、Power 或 Pareto GREEN 的声明。

## 最终声明等级

检查工作流经 canonical runner 和 v3 独立审查后为 `WORKFLOW=PASS`；当前设计的资格结果仍为
`architecture_freeze=GAP`、`ppa=UNQUALIFIED`、`promotion_eligible=false`。工作流通过只表示
检查器能够可靠拒绝当前不完整候选，不得把本切片改写为 `ARCH_STABLE`。只有 P0/P1 债务、
census、功能 aggregate、cohort inventory 与全部冻结输入闭合后，才允许签发新的 full-core
arch-stable 记录；长期完整 OoO/PPA 目标继续 active。
