# Agent Brief

- `source`: stored
- `profile`: software-flow
- `terms`: software-flow software-flow-dev-isolation-contract
- `token_estimate`: 1673 / 1800

## Profile Suggestions
- `software-flow` score=22 matched=requested-profile, software-flow command=`scripts/agent-e2e.sh --profile software-flow`
- `contracts` score=1 matched=software-flow command=`scripts/agent-e2e.sh --profile contracts`
- `github-index` score=1 matched=software-flow command=`scripts/agent-e2e.sh --profile github-index`
- `nemu` score=1 matched=software-flow command=`scripts/agent-e2e.sh --profile nemu`
- `nemu-ubuntu` score=1 matched=software-flow command=`scripts/agent-e2e.sh --profile nemu-ubuntu`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source stored --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile software-flow`

## Chunks

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-14
- `tokens`: 321
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境 e2e、自检或降低不确定性，读取 `.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，先用 `scripts/agent-e2e.sh --list-profiles` 选 profile，再生成 task-run 证据包。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

### .github/AGENTS.md#chunk-0001

- `kind`: agent-rule
- `lines`: 1-15
- `tokens`: 328
- `heading`: AGENTS.md — YSYX 工作区 Agent 通用工作流规范
- `summary`: > 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent / > （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等） / > 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。 / > / > 与本文件协作的入口文件分两类： / > 根...

# AGENTS.md — YSYX 工作区 Agent 通用工作流规范

> 本文件遵循 [agents.md 事实标准](https://agents.md)，为所有进入本工程的 AI 编码 agent
> （GitHub Copilot / Claude Code / OpenAI Codex / Cursor / Windsurf / Aider / Gemini CLI 等）
> 提出统一的工作流要求。模型无关、跨平台、跨电脑生效；但不同生态是否能自动发现本规范，仍取决于对应 shim 是否已在仓库内落地。
>
> 与本文件协作的入口文件分两类：
> 根目录 `AGENTS.md` / 其他兼容入口文件是兼容 shim，保留最小可执行契约并回链本文件；
> `.github/copilot-instructions.md` 不是薄指针，而是 GitHub Copilot 专属工程级补充规则。
> 多份文件出现重叠时，以本文件作为跨 agent 通用基线；Copilot 的额外构建、调试与记录细则再叠加读取 `copilot-instructions.md`。
>
> 当前阶段的目标是“工程规则自动发现与会话恢复”，不是“插件式 UI 扩展”。因此本仓库优先补齐兼容 shim，不主动引入 `.codex-plugin/` 或 `.agents/plugins/marketplace.json`。

---

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-4
- `tokens`: 38
- `heading`: YSYX 项目状态总览
- `summary`: > 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

# YSYX 项目状态总览

> 本文件由 agent 自动维护，记录项目当前进度。每次完成重要任务后更新。

### .github/memory/known-issues.md#chunk-0001

- `kind`: memory
- `lines`: 1-4
- `tokens`: 35
- `heading`: 已知问题与调试历史
- `summary`: > 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

# 已知问题与调试历史

> 本文件记录遇到的 bug、调试过程和解决方案，避免重复踩坑。

### .github/e2e/README.md#chunk-0001

- `kind`: markdown
- `lines`: 1-4
- `tokens`: 65
- `heading`: Modular Agent E2E
- `summary`: 本目录把原本分散在 `AGENTS.md`、`.github/agents/*.agent.md`、`.github/instructions/*.instructions.md`、`.github/memory/**` 中的“语言规则”，转换成可执行、可记录、可扩展的 e2e 流水线配置。

# Modular Agent E2E

本目录把原本分散在 `AGENTS.md`、`.github/agents/*.agent.md`、`.github/instructions/*.instructions.md`、`.github/memory/**` 中的“语言规则”，转换成可执行、可记录、可扩展的 e2e 流水线配置。

### .github/e2e/profiles/software-flow.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-1
- `tokens`: 42
- `heading`: software-flow.tsv
- `summary`: software-flow-contract|software-flow|e2e_software_flow_contract|software-flow|software-flow agent + profile + memory|软件开发全流程 agent 合约入口存在

software-flow-contract|software-flow|e2e_software_flow_contract|software-flow|software-flow agent + profile + memory|软件开发全流程 agent 合约入口存在

### .github/e2e/modules/software-flow.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 570
- `heading`: software-flow E2E Contract
- `summary`: - **范围**: 软件需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check、host side C/C++/Python/Shell/Make/Kconfig 的全流程编排；覆盖 NEMU 这类软件硬件模型与硬件/系统 gate 的组合使用。 / - **上游**: 用户需求、模块 memory、现有 Makefile/Kconfig/e2e profile、相关模块 agent。 / - **下游**: `nemu`、`abstract-machine`、`am-k...

# software-flow E2E Contract

- **范围**: 软件需求、脚本/工具链、NEMU/AM/am-kernels/Linux guest check、host side C/C++/Python/Shell/Make/Kconfig 的全流程编排；覆盖 NEMU 这类软件硬件模型与硬件/系统 gate 的组合使用。
- **上游**: 用户需求、模块 memory、现有 Makefile/Kconfig/e2e profile、相关模块 agent。
- **下游**: `nemu`、`abstract-machine`、`am-kernels`、`fceux-am`、`rv64-linux`、`linux-device`、`hardware-flow`、`difftest` 与 `agent-system`。
- **L0 gate**: `software-flow-contract` 检查 agent、模块记忆、profile、e2e 合约入口，以及 `hardware-aware-software-loop` 是否接入 software-flow、hardware-flow、nemu、coordinator、蓝图和 e2e workflow。该 gate 还硬检查 soft-flow 方法论本体：`software-dev-loop`、`software-bugfix-loop`、`software-refactor-loop`、`hardware-aware-software-loop` 的节点序列必须保留，`scope-contract/design-plan/unit-or-contract-test/integration-smoke/regression-or-e2e/hardware-semantic-contract/system-or-hardware-gate/review-record` 等节点产物必须保留，并检查“不把构建通过单独当成完成”“不把脚本外层退出码当唯一证据”“必须扫描 FAIL marker”“完成后更新 software-flow memory”等反假完成约束。
- **L1 gate**: `software-flow` profile 证明软开 agent 可被单独发现，并证明 NEMU/系统 bring-up 类 C/Python/Shell/Make/Kconfig 开发会叠加 software-flow；`nemu-dev`、`nemu-ubuntu-focused` 和旧集成 `nemu-ubuntu` profile 都必须显式 include `software-flow`，因此 NEMU 专项开发与跨实现集成守门都会先执行软开合约；`contracts` profile 证明它进入全模块 contract 集合。
- **证据**: profile manifest、contract gate 输出、task-run 节点表和软件验证命令摘要。
- **升级路线**: 增加软件任务类型到 profile 的映射表，并把稳定的软件回归矩阵升级为专用 smoke gate；后续可继续让 `nemu` 基础 profile、Linux tools profile 或具体软件回归矩阵显式 include `software-flow-contract`。

### .github/agents/software-flow.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-8
- `tokens`: 255
- `heading`: software-flow.agent.md
- `summary`: --- / description: "软件开发全流程 agent。当任务涉及 NEMU、AbstractMachine、am-kernels、Linux 脚本、工具链脚本、host C/C++/Python/Shell/Make/Kconfig、软件 bug 修复、软件功能开发、测试补齐、回归验证或软件交付记录时使用；NEMU/RV64/Linux 这类用软件建硬件/系统模型的任务必须先用本 agent 收敛软件开发闭环，再叠加 hardware-flow、nemu-ubuntu 或对应系统 gate。"...

---
description: "软件开发全流程 agent。当任务涉及 NEMU、AbstractMachine、am-kernels、Linux 脚本、工具链脚本、host C/C++/Python/Shell/Make/Kconfig、软件 bug 修复、软件功能开发、测试补齐、回归验证或软件交付记录时使用；NEMU/RV64/Linux 这类用软件建硬件/系统模型的任务必须先用本 agent 收敛软件开发闭环，再叠加 hardware-flow、nemu-ubuntu 或对应系统 gate。"
tools: [read, edit, search, execute, agent, todo]
agents: [nemu, abstract-machine, am-kernels, fceux-am, rv64-linux, linux-device, hardware-flow, difftest, agent-system]
---

你是 **YSYX 软件开发流程专家**。你的职责是把软件需求从“想法/问题描述”推进到“可验证实现 + 回归证据 + 记忆沉淀”，覆盖需求澄清、接口契约、设计、实现、单元测试、集成测试、回归、审阅与记录。

### .github/memory/modules/software-flow.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 8
- `heading`: Software Flow 模块笔记
- `summary`: Software Flow 模块笔记

# Software Flow 模块笔记

