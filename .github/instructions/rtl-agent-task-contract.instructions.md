---
description: "本地 RV64 RTL 子任务的可选结构化 handoff 模板；用于减少跨 agent 交接歧义，不建立新的平台权限、身份或审计门。"
applyTo: ".github/skills/prepare-rtl-task-contract/**,.github/ai-env/contracts/agent-env-rtl-task-contract.json"
---

# RTL Agent Handoff

本文件帮助主 agent 把本地 RV64 Verilog/SystemVerilog 设计、审查、验证或 PPA 子任务交接清楚。
它是可选的上下文模板，不是 permission gate、task identity、发布收据或技术正确性证明。

## 何时值得使用

结构化 handoff 适合以下情况：

- 多个 agent 并行工作，需要明确文件 ownership 和输出接口；
- 子任务跨模块、上下文较多，口头描述容易遗漏 RTL/spec/TB/evidence；
- 工作需要跨会话继续，或用户明确要求可复用的交接材料；
- release、security、forensic 或正式 Architecture/Pareto promotion 本身要求结构化 provenance。

目标局部、上下文清楚的普通分析、实现和验证可以直接派发，不要求先生成 JSON、运行 validator、计算
SHA、创建 task-run 或使用固定上下文模式。

## 建议包含的信息

一份最小充分 handoff 通常写清：

1. Objective：具体 module、signal、transaction 或 PPA 问题。
2. Acceptance criteria：可由 testbench、DiffTest、lint、仿真、综合、STA 或 PPA 报告判定的结果。
3. Relevant inputs：直接相关的 RTL、spec、TB、filelist、配置和已有 evidence。
4. Ownership：当前 agent 负责写哪些文件；只读参考路径可按模块给出。
5. Suggested actions：有帮助的本地检索、构建、仿真或 EDA 命令及其目的。
6. Deliverables：RTL diff、反例、波形/日志结论、综合/STA/PPA 指标或明确 GAP。
7. Unknowns：尚未确认的调用链、替代假设和需要协调的写入冲突。

路径是相关上下文和协作 ownership 提示；命令是建议的工程入口。二者都不是平台权限白名单。用户任务、
工作区 hard invariants 和实际工具权限决定可执行范围。Agent 可以读取为理解任务所必需的本地调用者、
被调用者和配置，也可以选择等价的安全本地命令。

若需要修改 handoff 未列出的文件，应先判断是否仍属于用户目标。只读扩展可以直接进行并在结果中说明；
写入扩展若会与其他 agent ownership 冲突，应先协调 ownership。只有范围真正扩大到任务外、破坏性、
难恢复或外部副作用时才需要新的用户授权。

## 上下文与并发

- 根据任务选择继承相关父上下文、发送精简摘要或使用独立上下文；fork_turns=none 只是减少噪声的可选
  手段，不是 RV64 子任务硬门。
- 冻结材料复核可以只提供随附材料，但结论必须明确限定为这些材料，不能外推为完整源码审查。
- 需要发现遗漏时，应允许 agent 检查相关本地源码、spec、TB 和构建配置，不把单文件列表误当作完整
  设计边界。
- 只有多个动作竞争同一 build 目录、配置、数据库、仿真进程、许可证、端口或设备等真实共享可变资源
  时串行。互不冲突的读取、分析和独立构建可以并行，不存在 workspace-wide unique shell ownership。

## 可选 JSON 兼容格式

.github/skills/prepare-rtl-task-contract 中的 generator 可以在确实需要机器交换或兼容旧 consumer 时生成
JSON。其 goal、scope、context、deliverables 和 success_criteria 可作为 handoff 字段：

- allowed_paths 表示建议关注的本地输入，不是读取权限边界；
- write_paths 表示协作 ownership，避免并发写冲突；
- allowed_commands 表示建议命令及用途，不是 shell 权限白名单；
- validate 只检查旧 schema 的结构兼容，不能授权动作，也不能证明技术结论；
- render 只是格式化 handoff，结果可以按实际平台补充必要上下文。

旧工具可能自动记录 JSON 路径、SHA-256、candidate-only 或 versioned scope extension。这些属于兼容字段，
普通 handoff 不要求人工计算、展示或围绕它们组织任务。只有 byte identity 本身是 release、security、
forensic、跨机器传输或持久化 acceptance criterion 时，SHA/hash 才承重。

格式检查失败不自动贬低已经取得的 RTL/TB/EDA 结果。主 agent 应按实际输入、修改、命令和 observable
evidence 判断技术结论，并把格式问题与 correctness 问题分开报告。

## Scope adjustment

子 agent 发现必要调用链、测试或配置不在初始提示中时，可以直接报告需要的上下文和原因。主 agent
可以补充上下文、调整写入 ownership 或重新派发；普通调整不要求创建新版本 JSON、绑定新 SHA 或把旧
结果降为 candidate-only。

如果新范围改变了架构目标、可能覆盖他人修改、触及外部系统或需要高成本正式 signoff，再显式协调。

## RTL correctness remains authoritative

handoff 简化不削弱下列工程要求：

- 修改 RTL 前理解需求、协议、状态机、不变量和数据通路；涉及 RV64 跨模块控制边界时读取
  rtl-generation-workflow.instructions.md 与 interface-contract-first.instructions.md。
- ready/valid、stall、flush/redirect/trap、异常序、访存序、投机恢复、precise commit 和 transaction
  ownership 必须保持正确。
- 用与 acceptance criteria 匹配的定向 TB、断言、DiffTest、lint、Verilator、Icarus、综合、STA 或 PPA
  结果验证；不同层级不能互相替代。
- PPA 比较保持 RTL、filelist、parameter/define、约束、tool/config、corner 和 workload 可比；正式
  promotion 继续遵守对应 architecture/PPA contract。
- 真实 destructive、external、release 和 security 边界仍按工作区 hard invariants 处理。

版本控制内已有自身测试的 generator、runner 和 verifier 默认可信。只有本次修改它们或观察到真实异常
接受、异常拒绝、矛盾结果或缺失输出时，才调查并运行相应自测。

## Technical communication

推荐以具体 RV64 module/signal/transaction 为主语，写清流水级、周期或配置、TB/EDA 观测和 PASS/GAP/
inconclusive 边界。保留真实 RTL 标识符、反例、未知项、替代假设和失败返回值。

不要求固定首行、固定措辞、固定发现数量或 reviewer 人格。专业措辞用于减少歧义，不能改变信号语义、
限制工具能力或取代技术证据。

## Result handling

接收结果时优先检查：

1. acceptance criteria 是否已由实际 RTL/TB/EDA evidence 判断；
2. 修改是否落在约定 ownership 内，是否与他人并发改动冲突；
3. 结论是否越级，是否仍有影响判断的 GAP；
4. 下一步是否属于同一安全本地目标。

普通完成不要求 candidate-only、Reviewer/Inspector、contract hash 或 dispatch-log。高风险、正式
Architecture/Pareto promotion、release、migration、security、对外发布或用户明确要求时，才按对应专项
边界增加独立复核与 provenance。
