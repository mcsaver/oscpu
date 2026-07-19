# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl
- `focus_scope`: non-history
- `token_estimate`: 2234 / 2400

## Profile Suggestions
- `agent-system` score=16 matched=requested-profile command=`scripts/agent-e2e.sh --profile agent-system`
- `verilator-tapeout` score=1 matched=rtl command=`scripts/agent-e2e.sh --profile verilator-tapeout`
- `yosys-sta` score=1 matched=rtl command=`scripts/agent-e2e.sh --profile yosys-sta`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile agent-system`

## Chunks

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

### .github/e2e/profiles/agent-system.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-7
- `tokens`: 344
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/S...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/Skill/Agent 三层契约与维护入口
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/memory/modules/npc.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-2
- `tokens`: 9
- `heading`: NPC (RTL CPU) 模块笔记
- `summary`: NPC (RTL CPU) 模块笔记

# NPC (RTL CPU) 模块笔记

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 643
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile>` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境 e2e、自检或降低不确定性，读取 `.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，先用 `scripts/agent-e2e.sh --list-profiles` 选 profile，再生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式切换“实现者人格”和“审查者人格”：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；冲突未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。

请直接打开 [`.github/AGENTS.md`](./.github/AGENTS.md)。

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
- `lines`: 1-1
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记

### .github/memory/decisions.md#chunk-0047

- `kind`: memory
- `lines`: 387-394
- `tokens`: 313
- `heading`: [20] NPC RTL 源码采用功能目录 + 统一 filelist 管理
- `summary`: - **日期**: 2026-05-22 / - **状态**: 已决定 / - **上下文**: `npc/single/vsrc` 的 RTL 模块数量已经增长到 30+，继续把所有 `.v/.sv` 平铺在同一目录会让新增模块、综合边界、仿真壳和 testbench 路径维护变得混乱。 / - **决策**: `vsrc` 按功能域划分为 `include/core/frontend/decode/execute/memory/cache/bus/common/pipeline/writeback/si...

### [20] NPC RTL 源码采用功能目录 + 统一 filelist 管理

- **日期**: 2026-05-22
- **状态**: 已决定
- **上下文**: `npc/single/vsrc` 的 RTL 模块数量已经增长到 30+，继续把所有 `.v/.sv` 平铺在同一目录会让新增模块、综合边界、仿真壳和 testbench 路径维护变得混乱。
- **决策**: `vsrc` 按功能域划分为 `include/core/frontend/decode/execute/memory/cache/bus/common/pipeline/writeback/sim`，并新增 `vsrc/filelist.mk` 集中维护各模块路径变量、`RTL_CORE_SRCS`、`SIM_TOP_SRCS` 和 `VSRCS`；主 Makefile、模块 testbench 与 STA 入口共享这份清单。
- **理由**: 这是商业 RTL 工程中常见的组织方式：目录表达架构职责，filelist 表达工具入口，避免每个构建脚本各自散落一份路径清单，也能继续明确区分可综合核心和 DPI 仿真壳。
- **影响**: 后续新增或移动 RTL 文件时，应先选择对应功能目录，再更新 `vsrc/filelist.mk`；不要重新在 `Makefile` 或 testbench 中直接写平铺文件路径。

### .github/memory/modules/npc.md#chunk-0121

- `kind`: memory-module
- `lines`: 628-635
- `tokens`: 347
- `heading`: 2026-07-11 RV64 OoO 文档权威刷新
- `summary`: - 当前入口改为 `design/arch/rtl-ground-truth-2026-07-11.md`；旧 07-03 快照已归档到 `design/arch/history/`，不再裁决当前 RTL。`design/arch/ROADMAP.md` 已改为 living backlog，优先关闭现有合同后再扩窗口或 memory MLP。 / - 当前拓扑口径：双 dispatch/commit、ROB16、int/FP PRF64、int/FP IQ8、SQ/MIQ4；DecodeStage 共 4...

## 2026-07-11 RV64 OoO 文档权威刷新

- 当前入口改为 `design/arch/rtl-ground-truth-2026-07-11.md`；旧 07-03 快照已归档到 `design/arch/history/`，不再裁决当前 RTL。`design/arch/ROADMAP.md` 已改为 living backlog，优先关闭现有合同后再扩窗口或 memory MLP。
- 当前拓扑口径：双 dispatch/commit、ROB16、int/FP PRF64、int/FP IQ8、SQ/MIQ4；DecodeStage 共 4 实例，int PRF 5R2W；pending branch/jump/memory 与 synthetic lane1-ret 已删除；fetch redirect PC 已由生产 `OooRedirectArbiter` 单源化，但后端 kill/reason/flush 尚未完全统一。
- 关键 active spec 已补齐：`arch_trap -> no backend dispatch`、xRET current-mode、IFU A-update write-drain、page-end C fault、唯一 ISA-retirement/minstret 等开放合同；硬件 A/D 实施计划已归档，其 PTE write PMP 边界重新打开。
- 验证勘误：177 项 official riscv-tests 逐项 PASS；AM 实际 58/59；module 的 86/86 仅是聚合摘要，三份原始日志与其冲突。修复 runner/TB 前不得将该轮称为 module/AM 全绿。详见 `audit-results/2026-07-11-rv64-ooo-blind/VALIDATION_ERRATUM.txt`。
- 本轮只更新文档、索引、注释指针与 DB memory，没有修改 RTL 行为。
