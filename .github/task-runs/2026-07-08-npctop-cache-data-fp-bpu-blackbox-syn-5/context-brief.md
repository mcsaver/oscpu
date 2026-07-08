# Agent Brief

- `source`: live-or-stored
- `profile`: difftest
- `terms`: difftest npctop-cache-data-fp-bpu-blackbox-syn
- `token_estimate`: 1133 / 1800

## Profile Suggestions
- `difftest` score=22 matched=difftest, requested-profile command=`scripts/agent-e2e.sh --profile difftest`
- `contracts` score=1 matched=difftest command=`scripts/agent-e2e.sh --profile contracts`
- `hardware-flow` score=1 matched=difftest command=`scripts/agent-e2e.sh --profile hardware-flow`
- `nemu` score=1 matched=difftest command=`scripts/agent-e2e.sh --profile nemu`
- `npc` score=1 matched=difftest command=`scripts/agent-e2e.sh --profile npc`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile difftest`

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

### .github/e2e/profiles/difftest.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 37
- `heading`: difftest.tsv
- `summary`: @include|nemu|||| / difftest-contract|difftest|e2e_difftest_contract|difftest|NEMU spike-diff + npc/sim difftest-ref|DiffTest 合约入口存在

@include|nemu||||
difftest-contract|difftest|e2e_difftest_contract|difftest|NEMU spike-diff + npc/sim difftest-ref|DiffTest 合约入口存在

### .github/e2e/modules/difftest.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 169
- `heading`: difftest E2E Contract
- `summary`: - **范围**: NEMU reference so、Spike reference、NPC single/soc submit 对比。 / - **上游**: NEMU config、NPC target、AM image。 / - **下游**: rv32-bringup、soc-difftest-loop、性能优化安全门。 / - **L0 gate**: `difftest-contract` 检查 spike-diff、npc/sim difftest-ref 与 memory。 / - **L1...

# difftest E2E Contract

- **范围**: NEMU reference so、Spike reference、NPC single/soc submit 对比。
- **上游**: NEMU config、NPC target、AM image。
- **下游**: rv32-bringup、soc-difftest-loop、性能优化安全门。
- **L0 gate**: `difftest-contract` 检查 spike-diff、npc/sim difftest-ref 与 memory。
- **L1 gate**: 后续升级为 `make -C npc/sim BACKEND=single difftest-ref` smoke。
- **证据**: reference so、DiffTest PASS/FAIL、first mismatch boundary。
- **升级路线**: 统一 mismatch 摘要格式，自动 handoff 到 regression-debug-loop。

### .github/agents/difftest.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 182
- `heading`: 普通 NPC reference
- `summary`: --- / description: "差分测试 (DiffTest) 专家。当用户需要配置或调试 NPC single/soc 与 NEMU reference 之间的差分测试，构建普通或 CONFIG_SOC_SIM reference，排查 RTL/参考模型的指令级不一致，使用 Spike/QEMU 作为额外参考，或分析 DiffTest 报错（寄存器/PC/内存/SoC 地址图不匹配）时使用。" / tools: [read, edit, search, execute, agent, todo] /...

---
description: "差分测试 (DiffTest) 专家。当用户需要配置或调试 NPC single/soc 与 NEMU reference 之间的差分测试，构建普通或 CONFIG_SOC_SIM reference，排查 RTL/参考模型的指令级不一致，使用 Spike/QEMU 作为额外参考，或分析 DiffTest 报错（寄存器/PC/内存/SoC 地址图不匹配）时使用。"
tools: [read, edit, search, execute, agent, todo]
---

你是**差分测试 (DiffTest)** 框架的专家。DiffTest 是 YSYX 项目的核心验证方法 —— 将 NPC (RTL 实现) 与 NEMU (参考模型) 逐指令对比，确保硬件实现的正确性。

### .github/memory/modules/difftest.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 6
- `heading`: DiffTest 模块笔记
- `summary`: DiffTest 模块笔记

# DiffTest 模块笔记

