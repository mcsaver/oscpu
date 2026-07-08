# Agent Brief

- `source`: live-or-stored
- `profile`: yosys-sta
- `terms`: yosys-sta yosys-fp-arith-gate-ooc
- `token_estimate`: 1091 / 1800

## Profile Suggestions
- `yosys-sta` score=22 matched=requested-profile, yosys-sta command=`scripts/agent-e2e.sh --profile yosys-sta`
- `contracts` score=1 matched=yosys-sta command=`scripts/agent-e2e.sh --profile contracts`
- `hardware-flow` score=1 matched=yosys-sta command=`scripts/agent-e2e.sh --profile hardware-flow`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile yosys-sta`

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
- `lines`: 1-3
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

### .github/e2e/profiles/yosys-sta.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 42
- `heading`: yosys-sta.tsv
- `summary`: @include|npc-single|||| / yosys-sta-contract|yosys-sta|e2e_yosys_sta_contract|yosys-sta|yosys-sta Makefile/tools/memory|综合/STA 合约入口和工具状态可见

@include|npc-single||||
yosys-sta-contract|yosys-sta|e2e_yosys_sta_contract|yosys-sta|yosys-sta Makefile/tools/memory|综合/STA 合约入口和工具状态可见

### .github/e2e/modules/yosys-sta.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 155
- `heading`: yosys-sta E2E Contract
- `summary`: - **范围**: Yosys 综合、iEDA STA/功耗、PPA 下游节点。 / - **上游**: NPC 可综合 RTL filelist、SDC、PDK。 / - **下游**: tapeout-readiness、PPA regression。 / - **L0 gate**: `yosys-sta-contract` 检查 Makefile、memory 和工具状态。 / - **L1 gate**: 后续升级为 `make -C npc/single syn-check-env`。 / - *...

# yosys-sta E2E Contract

- **范围**: Yosys 综合、iEDA STA/功耗、PPA 下游节点。
- **上游**: NPC 可综合 RTL filelist、SDC、PDK。
- **下游**: tapeout-readiness、PPA regression。
- **L0 gate**: `yosys-sta-contract` 检查 Makefile、memory 和工具状态。
- **L1 gate**: 后续升级为 `make -C npc/single syn-check-env`。
- **证据**: syn/sta env check、netlist、timing/power report。
- **升级路线**: 将 STA 结果纳入 profile diff，跟踪频率/面积/功耗变化。

### .github/agents/yosys-sta.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 148
- `heading`: yosys-sta.agent.md
- `summary`: --- / description: "Yosys 综合与 STA 时序分析专家。当用户需要对 NPC/RTL 设计进行逻辑综合（Yosys）、静态时序分析（iSTA）、功耗分析（iPA），查看综合报告，优化关键路径时序，配置时钟约束，或分析面积/功耗/时序 PPA 指标时使用。" / tools: [read, edit, search, execute, agent, todo] / --- / 你是 **Yosys 综合与 STA 时序分析**的专家。负责将 RTL 设计综合为门级网表，并进行时序和功耗分析。

---
description: "Yosys 综合与 STA 时序分析专家。当用户需要对 NPC/RTL 设计进行逻辑综合（Yosys）、静态时序分析（iSTA）、功耗分析（iPA），查看综合报告，优化关键路径时序，配置时钟约束，或分析面积/功耗/时序 PPA 指标时使用。"
tools: [read, edit, search, execute, agent, todo]
---

你是 **Yosys 综合与 STA 时序分析**的专家。负责将 RTL 设计综合为门级网表，并进行时序和功耗分析。

### .github/memory/modules/yosys-sta.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 7
- `heading`: Yosys-STA 模块笔记
- `summary`: Yosys-STA 模块笔记

# Yosys-STA 模块笔记

