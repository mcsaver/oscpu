# Agent Brief

- `source`: live-or-stored
- `profile`: am-kernels
- `terms`: am-kernels 2026-07-08-iverilog14-tb-gate-restore
- `token_estimate`: 1241 / 1800

## Profile Suggestions
- `am-kernels` score=22 matched=am-kernels, requested-profile command=`scripts/agent-e2e.sh --profile am-kernels`
- `fceux-am` score=2 matched=am-kernels command=`scripts/agent-e2e.sh --profile fceux-am`
- `npc` score=2 matched=am-kernels command=`scripts/agent-e2e.sh --profile npc`
- `abstract-machine` score=1 matched=am-kernels command=`scripts/agent-e2e.sh --profile abstract-machine`
- `contracts` score=1 matched=am-kernels command=`scripts/agent-e2e.sh --profile contracts`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile am-kernels`

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

### .github/e2e/profiles/am-kernels.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 41
- `heading`: am-kernels.tsv
- `summary`: @include|abstract-machine|||| / am-kernels-contract|am-kernels|e2e_am_kernels_contract|am-kernels|cpu-tests/am-tests/klib-tests/benchmarks|测试与 benchmark 合约入口存在

@include|abstract-machine||||
am-kernels-contract|am-kernels|e2e_am_kernels_contract|am-kernels|cpu-tests/am-tests/klib-tests/benchmarks|测试与 benchmark 合约入口存在

### .github/e2e/modules/am-kernels.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 141
- `heading`: am-kernels E2E Contract
- `summary`: - **范围**: CPU/ALU/KLIB/AM tests、benchmarks、回归脚本。 / - **上游**: abstract-machine。 / - **下游**: NEMU reference、NPC target、性能 profile。 / - **L0 gate**: `am-kernels-contract` 检查测试目录、benchmark 和 `scripts/am-regression.sh`。 / - **L1 gate**: `quick/reference/full` pr...

# am-kernels E2E Contract

- **范围**: CPU/ALU/KLIB/AM tests、benchmarks、回归脚本。
- **上游**: abstract-machine。
- **下游**: NEMU reference、NPC target、性能 profile。
- **L0 gate**: `am-kernels-contract` 检查测试目录、benchmark 和 `scripts/am-regression.sh`。
- **L1 gate**: `quick/reference/full` profile。
- **证据**: `.result`、benchmark marks、regression status。
- **升级路线**: 汇总 PASS/FAIL marker 为机器可读 TSV/JSON，避免只读 exit code。

### .github/agents/am-kernels.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 147
- `heading`: 运行 CPU 指令测试 (在 NEMU 上)
- `summary`: --- / description: "AM-Kernels 测试与基准程序专家。当用户需要编写 CPU 指令测试、AM API/klib 测试，运行 CoreMark/Dhrystone/MicroBench，验证 riscv32-nemu/riscv32-npc（含 npc/sim single/soc 后端）镜像，编写或调试 AM 应用程序，或排查测试失败原因时使用。" / tools: [read, edit, search, execute, agent, todo] / --- / 你是 **AM...

---
description: "AM-Kernels 测试与基准程序专家。当用户需要编写 CPU 指令测试、AM API/klib 测试，运行 CoreMark/Dhrystone/MicroBench，验证 riscv32-nemu/riscv32-npc（含 npc/sim single/soc 后端）镜像，编写或调试 AM 应用程序，或排查测试失败原因时使用。"
tools: [read, edit, search, execute, agent, todo]
---

你是 **AM-Kernels** 测试程序与基准测试的专家。am-kernels 包含运行在 AbstractMachine 上的各类测试、基准程序和演示应用。

### .github/memory/modules/am-kernels.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 7
- `heading`: AM-Kernels 模块笔记
- `summary`: AM-Kernels 模块笔记

# AM-Kernels 模块笔记

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore/evidence-index.md#chunk-0006

- `kind`: task-run
- `lines`: 35-45
- `tokens`: 166
- `heading`: .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore/evidence/profile-index.log
- `summary`: - `kind`: log / - `size_bytes`: 678 / - `line_count`: 40 / - `sha256`: 2dd8c0ad697f04ab2a4aa487ec998b572dac84a8fd455abe8398a54f96645b1c / - `encoding`: utf-8 / - `indexed_at`: 2026-07-08T03:37:02+00:00 / - `markers`: {} / - `summary`: log evidence; size=678...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 678
- `line_count`: 40
- `sha256`: 2dd8c0ad697f04ab2a4aa487ec998b572dac84a8fd455abe8398a54f96645b1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:37:02+00:00
- `markers`: {}
- `summary`: log evidence; size=678 bytes; lines=40; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

