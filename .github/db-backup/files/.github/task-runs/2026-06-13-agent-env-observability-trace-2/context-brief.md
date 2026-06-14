# Agent Brief

- `source`: stored
- `profile`: agent-system
- `terms`: agent-system agent-env-observability-trace
- `token_estimate`: 1777 / 1800

## Profile Suggestions
- `agent-system` score=22 matched=agent-system, requested-profile command=`scripts/agent-e2e.sh --profile agent-system`
- `github-index` score=2 matched=agent-system command=`scripts/agent-e2e.sh --profile github-index`
- `contracts` score=1 matched=agent-system command=`scripts/agent-e2e.sh --profile contracts`
- `discovery` score=1 matched=agent-system command=`scripts/agent-e2e.sh --profile discovery`
- `toolchain` score=1 matched=agent-system command=`scripts/agent-e2e.sh --profile toolchain`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source stored --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile agent-system`

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
- `lines`: 1-2
- `tokens`: 6
- `heading`: Agent E2E Profiles
- `summary`: Agent E2E Profiles

# Agent E2E Profiles

### .github/e2e/profiles/agent-system.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-3
- `tokens`: 94
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/S...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/Skill/Agent 三层契约与维护入口
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/e2e/modules/agent-system.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-10
- `tokens`: 509
- `heading`: agent-system E2E Contract
- `summary`: - **范围**: `.github/AGENTS.md`、入口 shim、agents、instructions、memory、task-runs、e2e profile、review routing、branch-health dashboard、observability/run-manifest、非交互软环境入口。 / - **上游**: 用户目标、已有 memory、蓝图。 / - **下游**: 所有模块 profile 与跨模块图。 / - **L0 gate**: `e2e_agent_sys...

# agent-system E2E Contract

- **范围**: `.github/AGENTS.md`、入口 shim、agents、instructions、memory、task-runs、e2e profile、review routing、branch-health dashboard、observability/run-manifest、非交互软环境入口。
- **上游**: 用户目标、已有 memory、蓝图。
- **下游**: 所有模块 profile 与跨模块图。
- **L0 gate**: `e2e_agent_system_discovery` 检查规则入口、e2e 目录、task-run 模板、memory、`scripts/agent-env.sh` 与 runner source hook、半初始化 `YSYX_AGENT_ENV_SOURCED` 继承自修复钩子、外层工具控制符命令卫生文档钩子（例如 `rg -e` 替代正则中的 `|`）、Codex/WSL single-flight 文档钩子（不要并发启动多个 `wsl.exe` 做工程命令；`Wsl/Service/E_UNEXPECTED` 先按宿主 WSL 健康问题处理；工程命令回到 `scripts/agent-run.sh` 入口）、持久 agent/e2e/review-routing/branch-health/observability 源文件是否已被 Git 跟踪，以及 `report.sh` 的 context brief、run manifest、task-run 文本 artifact sanitizer 和 Markdown DB 归档 hook 是否定义、调用并限制在当前 run dir。
- **三层 gate**: `e2e_agent_system_three_layer_contract` 检查 Database/Skill/Agent 边界、report matrix、schema contract、observability contract、review routing、branch-health dashboard、policy、workflow、skill、`agent-maintain` 和对应 audit/report 命令。
- **L1 gate**: `agent-system` profile 列出全部 profile，证明配置可发现。
- **证据**: task-run context-brief、report、dispatch-log、`run-manifest.json`、profile 列表、agent-env PASS marker、sanitizer PASS marker、task-run Markdown DB 归档 marker、trace-audit PASS marker、branch-health-report 输出、branch-health-audit PASS marker、diff check。
- **升级路线**: 增加 profile schema 校验、重复 node 检测、agent/module 覆盖率检查。

### .github/agents/agent-system.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 152
- `heading`: agent-system.agent.md
- `summary`: --- / description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。" / tools: [read, edit, search, agent, todo] / --- / 你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，...

---
description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。"
tools: [read, edit, search, agent, todo]
---

你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，而是把 `.github/` 下的 Database、Skill、Agent 三层设计成一个真正可持续演化的 AI 驱动硬件开发环境。

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记

### .github/task-runs/2026-06-13-agent-env-observability-trace/dispatch-log.md#chunk-0002

- `kind`: dispatch-log
- `lines`: 3-13
- `tokens`: 72
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-13-agent-env-observability-trace / - `trace_id`: e2e:2026-06-13-agent-env-observability-trace / - `task_slug`: agent-env-observability-trace / - `graph_template`: modular-agent-e2e / - `profile`: agent-system / - `log_policy`: append-on...

## 基本信息

- `task_id`: 2026-06-13-agent-env-observability-trace
- `trace_id`: e2e:2026-06-13-agent-env-observability-trace
- `task_slug`: agent-env-observability-trace
- `graph_template`: modular-agent-e2e
- `profile`: agent-system
- `log_policy`: append-only

---

### .github/task-runs/2026-06-13-agent-env-observability-trace/evidence-index.md#chunk-0002

- `kind`: task-run
- `lines`: 3-10
- `tokens`: 53
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-13-agent-env-observability-trace / - `task_slug`: agent-env-observability-trace / - `profile`: agent-system / - `asset_count`: 7 / - `total_size_bytes`: 16887

## 基本信息

- `task_id`: 2026-06-13-agent-env-observability-trace
- `task_slug`: agent-env-observability-trace
- `profile`: agent-system
- `asset_count`: 7
- `total_size_bytes`: 16887

### .github/task-runs/2026-06-13-agent-env-observability-trace/task-report.md#chunk-0002

- `kind`: task-report
- `lines`: 3-14
- `tokens`: 105
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-13-agent-env-observability-trace / - `task_slug`: agent-env-observability-trace / - `graph_template`: modular-agent-e2e / - `profile`: agent-system / - `graph_mode`: static / - `status`: completed / - `owner`: agent-system + hardware-fl...

## 基本信息

- `task_id`: 2026-06-13-agent-env-observability-trace
- `task_slug`: agent-env-observability-trace
- `graph_template`: modular-agent-e2e
- `profile`: agent-system
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-13 21:28:59 +0800
- `updated_at`: 2026-06-13 21:29:02 +0800

### .github/task-runs/2026-06-13-agent-env-observability-trace/context-brief.md#chunk-0001

- `kind`: task-run
- `lines`: 1-7
- `tokens`: 45
- `heading`: Agent Brief
- `summary`: - `source`: stored / - `profile`: agent-system / - `terms`: agent-system agent-env-observability-trace / - `token_estimate`: 1502 / 1800

# Agent Brief

- `source`: stored
- `profile`: agent-system
- `terms`: agent-system agent-env-observability-trace
- `token_estimate`: 1502 / 1800

