# Agent Brief

- `source`: stored
- `profile`: rv64-linux
- `terms`: rv64-linux rv64-sv39-u-pagefault
- `token_estimate`: 1641 / 1800

## Profile Suggestions
- `rv64-linux` score=22 matched=requested-profile, rv64-linux command=`scripts/agent-e2e.sh --profile rv64-linux`
- `display-vga` score=2 matched=rv64-linux command=`scripts/agent-e2e.sh --profile display-vga`
- `linux-device` score=2 matched=rv64-linux command=`scripts/agent-e2e.sh --profile linux-device`
- `contracts` score=1 matched=rv64-linux command=`scripts/agent-e2e.sh --profile contracts`
- `nemu-ubuntu` score=1 matched=rv64-linux command=`scripts/agent-e2e.sh --profile nemu-ubuntu`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source stored --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile rv64-linux`

## Missing Paths
- `.github/memory/modules/rv64-linux.md`

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

### .github/e2e/profiles/rv64-linux.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-5
- `tokens`: 197
- `heading`: rv64-linux.tsv
- `summary`: @include|discovery|||| / npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在 / npc-rv64-sv39-sret-u-mode|npc|e2e_npc_rv64_sv39_sret_u_mode|npc|npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB|NPC RV64 SRET 到 U-...

@include|discovery||||
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|RV64 core/Linux 入口合约存在
npc-rv64-sv39-sret-u-mode|npc|e2e_npc_rv64_sv39_sret_u_mode|npc|npc/rv64 Sv39 + SRET U-mode + U pagefault focused TB|NPC RV64 SRET 到 U-mode、U 页取指、U ecall、U load page fault 回 S 并 sret 回 U 的回归 PASS
npc-rv64-linux-focused-smokes|npc|e2e_npc_rv64_linux_focused_smokes|npc|Linux/tools SRET/Sv39/pagefault/virtio focused smokes on NPC|NPC RV64 Linux focused smokes 覆盖 SRET/Sv39、ret_from_exception、U pagefault 与 virtio-blk
rv64-linux-contract|rv64-linux|e2e_rv64_linux_contract|rv64-linux|Linux Makefile/env/platform/instructions|RV64 Linux/Ubuntu 合约入口存在

### .github/e2e/modules/rv64-linux.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-9
- `tokens`: 157
- `heading`: rv64-linux E2E Contract
- `summary`: - **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。 / - **上游**: npc/rv64 core、Linux env、device contracts。 / - **下游**: linux-device、display-vga、verilator-tapeout。 / - **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 i...

# rv64-linux E2E Contract

- **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。
- **上游**: npc/rv64 core、Linux env、device contracts。
- **下游**: linux-device、display-vga、verilator-tapeout。
- **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 instructions。
- **L1 gate**: 后续按 `rv64-ubuntu-probe-loop` 跑 QEMU/NPC probe。
- **证据**: `/init`、`/etc/os-release`、`/bin/sh`、rootfs mount、poweroff。
- **升级路线**: 按 gate 分层生成机器可读 boot status。

### .github/agents/rv64-linux.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 172
- `heading`: rv64-linux.agent.md
- `summary`: --- / description: "RV64 Linux/Ubuntu 22.04 bring-up 专家。当任务涉及 npc/rv64、OpenSBI、Linux kernel、DTB、initramfs/rootfs、Ubuntu Base、QEMU reference 或 Verilator 上的完整 Linux 启动证据时使用。" / tools: [read, edit, search, execute, agent, todo] / --- / 你是 **RV64 Linux / Ubuntu...

---
description: "RV64 Linux/Ubuntu 22.04 bring-up 专家。当任务涉及 npc/rv64、OpenSBI、Linux kernel、DTB、initramfs/rootfs、Ubuntu Base、QEMU reference 或 Verilator 上的完整 Linux 启动证据时使用。"
tools: [read, edit, search, execute, agent, todo]
---

你是 **RV64 Linux / Ubuntu bring-up 专家**。你的职责是把 `Linux/` 中的真实 OpenSBI、Linux kernel、DTB、initramfs/rootfs、QEMU reference 与 `npc/rv64` Verilator target 组织成可验证闭环，避免把“构建了镜像”“进入 kernel high-half”“进入 `/init`”“完整 Ubuntu shell/rootfs”混为一谈。

### .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/dispatch-log.md#chunk-0002

- `kind`: dispatch-log
- `lines`: 3-12
- `tokens`: 55
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-12-rv64-sv39-u-pagefault-2 / - `task_slug`: rv64-sv39-u-pagefault / - `graph_template`: modular-agent-e2e / - `profile`: rv64-linux / - `log_policy`: append-only / ---

## 基本信息

- `task_id`: 2026-06-12-rv64-sv39-u-pagefault-2
- `task_slug`: rv64-sv39-u-pagefault
- `graph_template`: modular-agent-e2e
- `profile`: rv64-linux
- `log_policy`: append-only

---

### .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/context-brief.md#chunk-0001

- `kind`: task-run
- `lines`: 1-7
- `tokens`: 43
- `heading`: Agent Brief
- `summary`: - `source`: stored / - `profile`: rv64-linux / - `terms`: rv64-linux rv64-sv39-u-pagefault / - `token_estimate`: 1308 / 1800

# Agent Brief

- `source`: stored
- `profile`: rv64-linux
- `terms`: rv64-linux rv64-sv39-u-pagefault
- `token_estimate`: 1308 / 1800

### .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/task-report.md#chunk-0002

- `kind`: task-report
- `lines`: 3-14
- `tokens`: 103
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-12-rv64-sv39-u-pagefault-2 / - `task_slug`: rv64-sv39-u-pagefault / - `graph_template`: modular-agent-e2e / - `profile`: rv64-linux / - `graph_mode`: static / - `status`: completed / - `owner`: agent-system + hardware-flow + module agen...

## 基本信息

- `task_id`: 2026-06-12-rv64-sv39-u-pagefault-2
- `task_slug`: rv64-sv39-u-pagefault
- `graph_template`: modular-agent-e2e
- `profile`: rv64-linux
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-12 01:37:11 +0800
- `updated_at`: 2026-06-12 01:37:13 +0800

### .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/task-report.md#chunk-0006

- `kind`: task-report
- `lines`: 40-48
- `tokens`: 116
- `heading`: 关键产物
- `summary`: - `artifacts`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2 / - `logs_or_traces`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/evidence / - `context_brief`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/context-brief.md / - `profile_r...

## 关键产物

- `artifacts`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2
- `logs_or_traces`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/evidence
- `context_brief`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/context-brief.md
- `profile_resolve`: .github/task-runs/2026-06-12-rv64-sv39-u-pagefault-2/profile-resolve.md
- `profile_manifest`: .github/e2e/profiles/rv64-linux.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

