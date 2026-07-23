# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: rtl contract single flight
- `focus_scope`: non-history
- `token_estimate`: 2096 / 2400

## Profile Suggestions
- `agent-system` score=21 matched=contract, flight, requested-profile, rtl, single command=`scripts/agent-e2e.sh --profile agent-system`
- `yosys-sta` score=5 matched=contract, rtl, single command=`scripts/agent-e2e.sh --profile yosys-sta`
- `contracts` score=4 matched=contract, single command=`scripts/agent-e2e.sh --profile contracts`
- `npc-single` score=4 matched=contract, single command=`scripts/agent-e2e.sh --profile npc-single`
- `difftest` score=3 matched=contract, single command=`scripts/agent-e2e.sh --profile difftest`

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
- `lines`: 1-8
- `tokens`: 439
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintai...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|AI_ENVIRONMENT.md;.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证一页导航、canonical 路径与 Database/Skill/Agent 三层契约
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
rtl-task-contract|agent-system|e2e_agent_system_rtl_task_contract|agent-system|.github/ai-env/contracts/agent-env-rtl-task-contract.json;.github/instructions/rtl-agent-task-contract.instructions.md;.github/skills/prepare-rtl-task-contract/SKILL.md;.github/skills/prepare-rtl-task-contract/scripts/rtl_task_contract.py|验证本地 RTL 子任务契约可生成、校验、渲染并拒绝越权 mutation
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

### .github/instructions/agent-e2e-workflow.instructions.md#chunk-0003

- `kind`: instruction
- `lines`: 14-31
- `tokens`: 1079
- `heading`: 执行卫生
- `summary`: 本地 RV64 RTL 子 agent 的派发先读取 `.github/instructions/rtl-agent-task-contract.instructions.md`， / 用 `.github/skills/prepare-rtl-task-contract/` 生成、校验并渲染 task contract；命令权限使用结构化 / `command/mode/purpose`，且 profile 必须运行真实 CLI `create/validate/render` 正负向自测。只读子任务必须明...

## 执行卫生

本地 RV64 RTL 子 agent 的派发先读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，
用 `.github/skills/prepare-rtl-task-contract/` 生成、校验并渲染 task contract；命令权限使用结构化
`command/mode/purpose`，且 profile 必须运行真实 CLI `create/validate/render` 正负向自测。只读子任务必须明确
不改文件、不联网、不访问账号、凭据或外部服务；平台 review 只记录当前节点为 `review_pending`，
不得自动关闭长期父目标。`agent-system` profile 的 `rtl-task-contract` 节点负责该接线与 mutation 反例。

- 开工先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包；未确定 profile 时只省略 `--profile`，仍保留 non-history focus，再看 `Profile Suggestions`。只有 `recall_status=complete` 才可继续派发；canonical/profile/独立 focus 缺失或必需 chunk 超出硬 token budget 时，CLI 必须非零、API 必须 `ok=false`，runner 不得降级为 WARN 假绿。回查历史 task-run/evidence 时使用 `runs --profile <profile>` 和 `evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志或直接加载 `.github/task-runs/**` 原始 evidence。
- CLI/API 与 e2e runner 的 bounded brief 默认预算统一为 2400 tokens，runner 可用 `E2E_CONTEXT_BRIEF_MAX_TOKENS` 显式覆盖；覆盖只改硬预算，不改必需 focus 的 fail-closed 契约。
- e2e runner 把 `task_slug` 仅作为身份输入：按字母/数字/CJK 边界拆出最多 8 个去重语义词，过滤日期、序号及 `agent/e2e/run/rerun/final/test/fix` 等生命周期噪声；profile 只通过 `--profile` 绑定，不得重复成为 AND focus term。默认 slug `agent-e2e-<profile>` 会退化为 profile 的非泛化语义词（例如 `agent-e2e-npc-dev` → `npc dev`），只作为 profile smoke 兼容入口，不等同于任务特异 focus；真实任务应显式给出可辨识 slug。若过滤后为空则 recall fail closed。runner 固定使用 `--focus-scope non-history`，所以旧 task-run/report/evidence 即使含同 slug 也不能充当独立 primary focus；历史回查仍走默认 `brief` 或更明确的 `runs`/`evidence`。
- 工程命令通过 WSL single-flight 执行，避免并发启动多个 `wsl.exe`。日常 NEMU/NPC 并行开发保持 runtime isolation 默认 `warn`；遇到 `Wsl/Service/E_UNEXPECTED` 或 NEMU profile 被 NPC 残留任务拖慢，先做 WSL 健康检查和 active scenario runtime isolation 判定；若看到超过 86400s 的历史对侧 task-run client，应清理该历史 client 后再补跑当前 NEMU/NPC gate，严谨复现实验再切到 `strict`。
- 真实构建/e2e 优先使用 `scripts/agent-run.sh`，让非交互环境加载 `scripts/agent-env.sh`。
- 外层工具控制符会污染命令字符串。多模式搜索优先使用 `rg -e foo -e bar`，不要依赖带 `|` 的单个正则穿过外层 shell。
- PowerShell 包裹 `wsl.exe -- bash -lc '...'` 时，不要在一次性命令中裸用 Bash `$var`；`$run`、`$p`、`$args` 等会被 PowerShell 先展开。优先写字面路径，或把复杂逻辑放进仓库脚本后调用。
- Windows `Start-Process wsl.exe` 传递复杂 Bash 命令时，必须把 `-- bash -lc "..."` 作为单个 argument string 保持完整；否则只会执行前半段命令，造成假 PASS/假退出。
- NEMU 慢速诊断 gate 若设置 `NEMU_INTERPRETER_BASIC_BLOCK=0`、`NEMU_INTERPRETER_WIDE_IFETCH=0`、`NEMU_INTERPRETER_DECODE_CACHE=0`、`NEMU_VADDR_HOST_FAST=0` 或 `NEMU_RISCV_MMU_TLB=0`，e2e 应自动提高 systemd start timeout，并使用较大的 serial input chunk，避免把上传过慢误判为 guest 行为。

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
