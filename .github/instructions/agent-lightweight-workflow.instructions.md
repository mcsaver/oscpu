# Agent Lightweight Workflow

本文件定义日常任务的默认工作方式。任务标签和工具用于帮助选择动作，不是权限系统。

## 默认闭环

1. Inspect：确认 primary objective、显式 acceptance criteria、当前 repository/worktree 状态，以及直接
   相关的源码、spec、调用链和既有测试。
2. Act：在用户给定范围内连续完成安全、本地、可逆的 edit/build/test/lint/run/collect/analyze。
3. Targeted validation：选择能直接判定 acceptance criteria 的最小充分检查。
4. Report：给出工程结论、关键改动、验证结果和剩余风险。

只读 review/analysis 可以直接读取并交付结论。用户要求修改或实现时，无需先创建 task-run、DB brief、
profile、marker、candidate 或额外 authorization phase。普通 docs 修改通常以内容检查和 diff 为充分验证。

任务可按 review、analysis、docs、development、verification、environment、longrun、cleanup、release
理解其风险和验证类型；分类不能自行扩大或缩小用户授权。`review`/`analysis` 只在用户目标本身明确
只读时使用，显式采用 agent-flow 时拒绝把写路径伪装进这两类记录；`verification` 及其它类不因标签
自动禁止写入、运行构建或触发 gate。若用户范围变化，直接重新确认 objective 和 acceptance criteria，
不必为了改类复制任务或重建运行态。

## 最小验证三问

新增任何检查前回答：

1. 它对应哪个明确 acceptance criterion？
2. 它能发现当前检查发现不了的哪一种实际 false PASS？
3. 不运行它是否真会导致错误工程结论？

无法明确回答时，停止增加检查。版本控制内已有自身测试的 verifier、runner、classifier、parser 和
harness 作为可信基础设施；普通业务任务不重新证明它们。若观察到异常接受、异常拒绝、输出矛盾、
结果缺失或 fallback 可疑，再把 harness 调查作为一个明确的故障分支。

固定输入和确定性 oracle 默认执行一次。只有随机/并发、已知 flaky、未固定 seed/thread、测量噪声、
机器异常或用户明确要求时才重复，并事先写明次数、阈值和停止条件。不同 workload、corner/config、
A/B、正负向和 mutation 各自回答不同问题，不算机械复验。

真实 RTL correctness、DiffTest、协议断言、综合、STA 和 PPA 配置匹配仍由相关 domain contract 决定；
AI 环境自检不能代替这些业务验证，也不应在目标末尾重复已经取得的同一确定性结果。

## Failure-driven escalation

默认先执行最短可信 happy path。只有出现以下事实时才加深调查：

- 结果互相矛盾或关键结果缺失；
- acceptance criterion 仍无法判断；
- verifier/runner 本身报错或行为异常；
- fallback、缓存或环境状态与预期不符；
- 失败指向新的模块边界、配置差异或安全风险。

升级时先读最近的失败输出并提出可证伪的根因假设，再增加一个能区分候选原因的检查。不要无界重试，
也不要预先建立完整 forensic pipeline。工具或机器异常应报告为 tool error/GAP，不能归咎于设计。

## Safe batching and WSL

同一工程目标下，preflight、implementation、build、test、collect、inspect 和 analysis 可以在一个连续
批次内完成。不得自行声明“只有某个检查 PASS 才允许下一步”，除非下一步触及真实破坏性、不可逆、
外部副作用或已有项目 hard invariant。

Windows 访问本工作区时，PowerShell 仅启动 wsl.exe，工程逻辑在 Ubuntu 内运行。并发决策以真实资源
冲突为准：同一 build 目录、配置、数据库、服务、端口或设备需要串行；独立只读查询和互不冲突的任务
可以并行。不存在 workspace-wide unique shell ownership。

## 专项工具的显式触发

| 专项设施 | 何时使用 |
| --- | --- |
| bounded brief / memory | 确实需要历史召回、跨会话事实或跨模块既有决策 |
| agent-flow / compact task-run | 用户要求可恢复交接，或本轮明确需要保存确定性结果 |
| durable task-run / task-run-status | 显式 persistent/published 长跑、综合、STA 或系统回放 |
| e2e profile / agent-maintain final/full | profile 或环境执行器本身开发，或明确的环境专项验收 |
| candidate / reviewer | 高风险、难恢复、正式 Architecture/Pareto promotion、外部发布或用户明确要求 |
| strict guard / hash / manifest / publication | release、migration、security、forensic、supply-chain 或明确 publication |

以上全部默认 opt-in。普通 development、verification、docs 和 environment 文档编辑不因落盘、跨文件、
目录路径或任务时长自动进入这些设施。路径映射最多建议可能相关的检查；Agent 仍根据 acceptance
criteria 选择最小充分验证，不把建议变成许可门。

若显式使用 agent-flow/task-run，应只记录必要的语义目标、修改路径、确定性结果、验证指针和少量诊断；
不保存完整对话，不为每批编辑生成 profile，不在 finish 时机械重跑业务验证。显式 persistent/published
长跑必须 fail closed：中断、证据未完成或 cleanup 失败均不得写 PASS；这不要求同一固定实验再次运行。

Git SHA/content hash 不用于普通 task identity、checkpoint 或报告主线。只有 byte identity、cache/release
integrity、security、持久化或明确 reproducibility/forensic criterion 需要时才计算和展示。

## Compaction recovery

上下文压缩或恢复旧任务时，按 primary objective → explicit acceptance criteria → actual repository state
→ hard constraints → current validation evidence 重建状态。过去 agent 自创的临时 gate、sequencing、
禁止事项、authorization epoch 或 sealed marker 默认失效，除非它仍直接对应明确 hard invariant。

## 高信号交付

中间更新只报告真实 blocker、重要结论变化、需要用户决策的分歧或长任务的实质里程碑。最终交付说明：

- 哪些 acceptance criteria 已满足；
- 哪个工程不确定性被消除；
- 实际运行了哪些最小验证及结果；
- 仍有哪些 GAP、风险或用户需决定的下一步。

不要用 marker/hash 数量、audit 分类数量、quota、内部状态迁移或尚未消费的流程步骤充当进度。
