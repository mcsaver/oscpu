# Agent Brief

- `source`: stored
- `profile`: quick
- `terms`: quick agent-e2e-quick
- `token_estimate`: 1549 / 1800

## Profile Suggestions
- `quick` score=11 matched=quick, requested-profile command=`scripts/agent-e2e.sh --profile quick`
- `am-kernels` score=1 matched=quick command=`scripts/agent-e2e.sh --profile am-kernels`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source stored --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile quick`

## Missing Paths
- `.github/e2e/modules/quick.md`
- `.github/agents/quick.agent.md`
- `.github/memory/modules/quick.md`

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

### .github/e2e/profiles/quick.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 49
- `heading`: quick.tsv
- `summary`: @include|discovery|||| / nemu-add-smoke|nemu|e2e_nemu_am_add_smoke|nemu|当前 NEMU AM-compatible 配置 + cpu-tests add|NEMU reference 最小 smoke PASS 或配置边界 SKIP

@include|discovery||||
nemu-add-smoke|nemu|e2e_nemu_am_add_smoke|nemu|当前 NEMU AM-compatible 配置 + cpu-tests add|NEMU reference 最小 smoke PASS 或配置边界 SKIP

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/dispatch-log.md#chunk-0002

- `kind`: dispatch-log
- `lines`: 3-11
- `tokens`: 48
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-06-agent-e2e-quick-bootstrap / - `task_slug`: agent-e2e-quick-bootstrap / - `graph_template`: agent-e2e-loop / - `log_policy`: append-only / ---

## 基本信息

- `task_id`: 2026-06-06-agent-e2e-quick-bootstrap
- `task_slug`: agent-e2e-quick-bootstrap
- `graph_template`: agent-e2e-loop
- `log_policy`: append-only

---

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/task-report.md#chunk-0006

- `kind`: task-report
- `lines`: 36-41
- `tokens`: 77
- `heading`: 关键产物
- `summary`: - `artifacts`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap / - `logs_or_traces`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence / - `linked_memory_updates`: 本脚本运行本身不自动改 memory；完成任务后由 agent 依据验证结果写入 memory。

## 关键产物

- `artifacts`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap
- `logs_or_traces`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence
- `linked_memory_updates`: 本脚本运行本身不自动改 memory；完成任务后由 agent 依据验证结果写入 memory。

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/dispatch-log.md#chunk-0008

- `kind`: dispatch-log
- `lines`: 77-89
- `tokens`: 146
- `heading`: [2026-06-06 17:00:46 +0800] `npc-sim-status` - `PASS`
- `summary`: - `owner_agent`: hardware-flow / - `trigger`: agent-e2e:quick / - `depends_on`: / - `inputs`: npc/sim/Makefile 与当前 Kconfig / - `action`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.cmd / - `outputs`: 输出 npc/sim 真实后端选择 / -...

### [2026-06-06 17:00:46 +0800] `npc-sim-status` - `PASS`

- `owner_agent`: hardware-flow
- `trigger`: agent-e2e:quick
- `depends_on`:
- `inputs`: npc/sim/Makefile 与当前 Kconfig
- `action`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.cmd
- `outputs`: 输出 npc/sim 真实后端选择
- `evidence`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.log, .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.cmd
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/dispatch-log.md#chunk-0007

- `kind`: dispatch-log
- `lines`: 64-76
- `tokens`: 147
- `heading`: [2026-06-06 17:00:46 +0800] `npc-sim-status` - `in-progress`
- `summary`: - `owner_agent`: hardware-flow / - `trigger`: agent-e2e:quick / - `depends_on`: / - `inputs`: npc/sim/Makefile 与当前 Kconfig / - `action`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.cmd / - `outputs`: 输出 npc/sim 真实后端选择 / -...

### [2026-06-06 17:00:46 +0800] `npc-sim-status` - `in-progress`

- `owner_agent`: hardware-flow
- `trigger`: agent-e2e:quick
- `depends_on`:
- `inputs`: npc/sim/Makefile 与当前 Kconfig
- `action`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.cmd
- `outputs`: 输出 npc/sim 真实后端选择
- `evidence`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.log, .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/npc-sim-status.cmd
- `handoff_to`:
- `next_step`: 等待命令完成
- `notes`:

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/task-report.md#chunk-0002

- `kind`: task-report
- `lines`: 3-13
- `tokens`: 90
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-06-agent-e2e-quick-bootstrap / - `task_slug`: agent-e2e-quick-bootstrap / - `graph_template`: agent-e2e-loop / - `graph_mode`: static / - `status`: completed / - `owner`: agent-system + hardware-flow / - `started_at`: 2026-06-06 17:00:4...

## 基本信息

- `task_id`: 2026-06-06-agent-e2e-quick-bootstrap
- `task_slug`: agent-e2e-quick-bootstrap
- `graph_template`: agent-e2e-loop
- `graph_mode`: static
- `status`: completed
- `owner`: agent-system + hardware-flow
- `started_at`: 2026-06-06 17:00:46 +0800
- `updated_at`: 2026-06-06 17:00:47 +0800

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/dispatch-log.md#chunk-0004

- `kind`: dispatch-log
- `lines`: 25-37
- `tokens`: 126
- `heading`: [2026-06-06 17:00:46 +0800] `recall-discovery` - `PASS`
- `summary`: - `owner_agent`: agent-system / - `trigger`: agent-e2e:quick / - `depends_on`: / - `inputs`: AGENTS/copilot/memory/task-run 模板 / - `action`: check_required_files / - `outputs`: 确认 AI 规则发现链和记录模板存在 / - `evidence`: .github/task-runs/2026-06-06-agent-e2e-quick-...

### [2026-06-06 17:00:46 +0800] `recall-discovery` - `PASS`

- `owner_agent`: agent-system
- `trigger`: agent-e2e:quick
- `depends_on`:
- `inputs`: AGENTS/copilot/memory/task-run 模板
- `action`: check_required_files
- `outputs`: 确认 AI 规则发现链和记录模板存在
- `evidence`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 进入下一节点
- `notes`:

### .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/dispatch-log.md#chunk-0003

- `kind`: dispatch-log
- `lines`: 12-24
- `tokens`: 127
- `heading`: [2026-06-06 17:00:46 +0800] `recall-discovery` - `in-progress`
- `summary`: - `owner_agent`: agent-system / - `trigger`: agent-e2e:quick / - `depends_on`: / - `inputs`: AGENTS/copilot/memory/task-run 模板 / - `action`: check_required_files / - `outputs`: 确认 AI 规则发现链和记录模板存在 / - `evidence`: .github/task-runs/2026-06-06-agent-e2e-quick-...

### [2026-06-06 17:00:46 +0800] `recall-discovery` - `in-progress`

- `owner_agent`: agent-system
- `trigger`: agent-e2e:quick
- `depends_on`:
- `inputs`: AGENTS/copilot/memory/task-run 模板
- `action`: check_required_files
- `outputs`: 确认 AI 规则发现链和记录模板存在
- `evidence`: .github/task-runs/2026-06-06-agent-e2e-quick-bootstrap/evidence/recall-discovery.log
- `handoff_to`:
- `next_step`: 等待节点结果
- `notes`:

