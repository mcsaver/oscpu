# AI Environment

本文件是 YSYX 工作区 AI 环境的一页架构、所有权和专项 playbook 索引。通用行为规则见
.github/AGENTS.md，日常闭环见 .github/instructions/agent-lightweight-workflow.instructions.md。

## Operating model

默认从用户目标和可观察 acceptance criteria 出发，读取实际代码与配置，完成安全本地动作，再做最小
充分验证。agent-flow、task-run、DB brief、memory、e2e、candidate、strict guard、hash/manifest 和
publication 都是按需设施，不是普通任务的固定前置或收尾许可。

所有下游 instruction、skill、agent、profile、contract 和脚本都不得扩大用户授权，也不得仅因路径、
文件数量、任务时长或“非平凡”创建新的 permission gate。真实 destructive/external boundary、
项目 correctness、release/security/production 约束仍然有效。

## Architecture and ownership

| 层 | 负责内容 | 稳定入口 |
| --- | --- | --- |
| 通用规则 | objective、hard invariants、验证与汇报原则 | .github/AGENTS.md |
| 日常工作流 | inspect → act → targeted validation → report | agent-lightweight-workflow.instructions.md |
| Database / memory | 稳定跨会话事实、显式留存的 task-run 索引 | scripts/dev_memory、github_index_db.py、.github/memory |
| Skill | 短小、可复用的定向处理方法 | .github/skills/*/SKILL.md |
| Agent / execution | 专家角色、可选 profile、维护和发布执行器 | .github/agents、.github/e2e、scripts/agent-* |
| Machine contract | 特定 release/security/schema/runner 的机器可判定接口 | .github/ai-env/contracts 与 domain policy |
| Runtime artifacts | 可再生成或较大的日志、波形、镜像、cache | .github/runtime-artifacts、.github/cache 或外部 store |

Database 不是 active instruction 真源；Skill 不保存长期事实；Agent/profile 不自行创造权限。机器 contract
只约束其声明的专项边界，不向普通开发传播额外流程。

## Daily path

1. 从 .github/AGENTS.md 恢复 objective、acceptance criteria 和 hard constraints。
2. 只读直接相关源码、spec、README 和 instruction；跨模块时先理清调用链和数据流。
3. 连续完成与目标相关的安全、本地、可逆动作。
4. 用最小充分的 domain validation 判断结果，异常时再定向加深。
5. 以累计 diff、行为变化、真实测试结果和剩余风险交付。

普通任务不需要 DB brief、memory 写回、agent-flow、task-run、profile 或 guard。已有版本化 verifier 默认
可信；只有真实异常才单独调查 verifier。memory 仅在产生稳定跨会话结论时更新。

## Specialized playbooks

- 历史召回或跨会话交接：使用 github_index_db.py brief/query/runs/evidence，并限制到当前问题；不要
  默认加载完整历史日志。
- archive、db-backup、task-runs、shujuku_aireview、dist 和 deliverables 中的规则副本是历史/证据/
  生成包数据，不参与当前 workspace 规则叠加；只有明确审计该快照或独立交付包时才读取其内部合同。
- 定向 AI 环境维护：使用 .github/skills/agent-env-maintenance/SKILL.md 和
  agent-env-layer-contract.instructions.md，只修改拥有该语义的真源并运行直接相关检查。
- 显式 persistent/published 长跑：使用 scripts/task-run-status.sh 和必要 task-run；中断、证据未完成
  或 cleanup 失败不能成为 PASS。
- release、migration、security、forensic、商业交付或 publication：按对应 contract 选择
  agent-maintain/e2e/strict guard、manifest、hash 和独立 reviewer。严格审计仅留在这一边界。
- 本地 RV64 RTL 子任务交接：使用 rtl-agent-task-contract.instructions.md 与
  .github/skills/prepare-rtl-task-contract；合同用于准确传递 RTL/spec/TB/evidence 范围，不是普通本地
  build/test 的授权门。
- RV64 正确性、系统签核与 PPA：从 npc/rv64/ARCHITECTURE.md 和相关 domain instruction 进入。完整
  full-core、L0-L3、replay、STA/PPA、promotion 的实现细节留在各自 policy/runner/spec，不在本页复制。

## Content placement

| 内容 | 放置位置 |
| --- | --- |
| 通用 hard invariants | .github/AGENTS.md |
| 项目构建与领域事实 | .github/copilot-instructions.md、模块 README/spec |
| 可复用处理方法 | .github/instructions 或 .github/skills |
| 当前稳定事实 | .github/memory |
| 显式专项运行结果 | .github/task-runs 与必要 evidence 指针 |
| 可判定专项合同 | .github/ai-env/contracts 或 domain policy/schema |
| 生成物与大体积 payload | runtime/cache/object store，不进入 tracked source |

旧 .github/agent-env-*.json 仅作兼容入口；新增规则应落到拥有该语义的现有真源。不要为了环境维护新建
policy framework、hash manifest、审批层或 meta-test。

## Platform and concurrency

Windows 侧只用 PowerShell 启动 wsl.exe，工程命令在 Ubuntu 内执行；已经位于 WSL/Linux 时直接运行。
仅对同一 build 目录、配置文件、数据库、服务、端口、设备等真实共享可变资源串行。互不冲突的读取、
分析和独立任务可以并行，不存在整个 workspace 的唯一 shell ownership。

## Recovery

上下文被压缩或旧记录可能过期时，按 primary objective、用户 acceptance criteria、实际 worktree、
hard constraints、当前验证结果的顺序恢复。旧 task-run、marker、SHA、临时 sequencing 和 agent 自创
gate 都不能凌驾于当前仓库状态；只有明确专项边界仍需要时才重新进入相应 playbook。
