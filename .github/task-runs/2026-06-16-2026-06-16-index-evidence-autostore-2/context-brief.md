# Agent Brief

- `source`: live-or-stored
- `profile`: github-index
- `terms`: github-index 2026-06-16-index-evidence-autostore
- `token_estimate`: 1712 / 1800

## Profile Suggestions
- `github-index` score=22 matched=github-index, requested-profile command=`scripts/agent-e2e.sh --profile github-index`
- `contracts` score=1 matched=github-index command=`scripts/agent-e2e.sh --profile contracts`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile github-index`

## Missing Paths
- `.github/agents/github-index.agent.md`
- `.github/memory/modules/github-index.md`

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

### .github/e2e/profiles/github-index.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 67
- `heading`: node_id|module|function|owner_agent|inputs|outputs
- `summary`: github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

# node_id|module|function|owner_agent|inputs|outputs
github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/dispatch-log.md#chunk-0002

- `kind`: dispatch-log
- `lines`: 3-13
- `tokens`: 75
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-16-2026-06-16-index-evidence-autostore / - `trace_id`: e2e:2026-06-16-2026-06-16-index-evidence-autostore / - `task_slug`: 2026-06-16-index-evidence-autostore / - `graph_template`: modular-agent-e2e / - `profile`: github-index / - `log_...

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-index-evidence-autostore
- `trace_id`: e2e:2026-06-16-2026-06-16-index-evidence-autostore
- `task_slug`: 2026-06-16-index-evidence-autostore
- `graph_template`: modular-agent-e2e
- `profile`: github-index
- `log_policy`: append-only

---

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/evidence-index.md#chunk-0002

- `kind`: task-run
- `lines`: 3-10
- `tokens`: 55
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-16-2026-06-16-index-evidence-autostore / - `task_slug`: 2026-06-16-index-evidence-autostore / - `profile`: github-index / - `asset_count`: 3 / - `total_size_bytes`: 51864

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-index-evidence-autostore
- `task_slug`: 2026-06-16-index-evidence-autostore
- `profile`: github-index
- `asset_count`: 3
- `total_size_bytes`: 51864

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/context-brief.md#chunk-0001

- `kind`: task-run
- `lines`: 1-7
- `tokens`: 47
- `heading`: Agent Brief
- `summary`: - `source`: live-or-stored / - `profile`: github-index / - `terms`: github-index 2026-06-16-index-evidence-autostore / - `token_estimate`: 806 / 1800

# Agent Brief

- `source`: live-or-stored
- `profile`: github-index
- `terms`: github-index 2026-06-16-index-evidence-autostore
- `token_estimate`: 806 / 1800

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/task-report.md#chunk-0002

- `kind`: task-report
- `lines`: 3-15
- `tokens`: 122
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-06-16-2026-06-16-index-evidence-autostore / - `trace_id`: e2e:2026-06-16-2026-06-16-index-evidence-autostore / - `task_slug`: 2026-06-16-index-evidence-autostore / - `graph_template`: modular-agent-e2e / - `profile`: github-index / - `grap...

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-index-evidence-autostore
- `trace_id`: e2e:2026-06-16-2026-06-16-index-evidence-autostore
- `task_slug`: 2026-06-16-index-evidence-autostore
- `graph_template`: modular-agent-e2e
- `profile`: github-index
- `graph_mode`: static
- `status`: blocked
- `owner`: agent-system + hardware-flow + module agents
- `started_at`: 2026-06-16 10:15:01 +0800
- `updated_at`: 2026-06-16 10:15:06 +0800

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/task-report.md#chunk-0007

- `kind`: task-report
- `lines`: 46-56
- `tokens`: 167
- `heading`: 关键产物
- `summary`: - `artifacts`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore / - `logs_or_traces`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/evidence / - `context_brief`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autos...

## 关键产物

- `artifacts`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore
- `logs_or_traces`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/evidence
- `context_brief`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/context-brief.md
- `profile_resolve`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/profile-resolve.md
- `evidence_index`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/evidence-index.md
- `run_manifest`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/run-manifest.json
- `profile_manifest`: .github/e2e/profiles/github-index.tsv
- `linked_memory_updates`: 由 agent 在收尾阶段按本轮稳定结论更新 memory

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/evidence-index.md#chunk-0005

- `kind`: task-run
- `lines`: 24-34
- `tokens`: 148
- `heading`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/nodes.tsv
- `summary`: - `kind`: tsv / - `size_bytes`: 203 / - `line_count`: 1 / - `sha256`: c5c130710624969d1511b2704e5df4e4c504ea81e6e2e8a07bd2366031c8649a / - `encoding`: utf-8 / - `indexed_at`: 2026-06-16T02:15:06+00:00 / - `markers`: {"FAIL": 2} / - `summary`: tsv evidence;...

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/nodes.tsv

- `kind`: tsv
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: c5c130710624969d1511b2704e5df4e4c504ea81e6e2e8a07bd2366031c8649a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T02:15:06+00:00
- `markers`: {"FAIL": 2}
- `summary`: tsv evidence; size=203 bytes; lines=1; FAIL=2; tail=github-index-contract agent-system github-index FAIL scripts/github_index_db.py + .github files exit=1 .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/evidence/github-index-contract.log

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/dispatch-log.md#chunk-0004

- `kind`: dispatch-log
- `lines`: 28-41
- `tokens`: 147
- `heading`: [2026-06-16 10:15:02 +0800] `profile-resolve` - `PASS`
- `summary`: - `owner_agent`: agent-system / - `module`: github-index / - `trigger`: e2e:github-index / - `depends_on`: / - `inputs`: .github/e2e/profiles/github-index.tsv / - `action`: github-index resolve-profile / - `outputs`: .github/task-runs/2026-06-16-2026-06-16-...

### [2026-06-16 10:15:02 +0800] `profile-resolve` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:github-index
- `depends_on`:
- `inputs`: .github/e2e/profiles/github-index.tsv
- `action`: github-index resolve-profile
- `outputs`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/profile-resolve.md
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/profile-resolve.md
- `handoff_to`:
- `next_step`: live/indexed e2e profile include closure generated before dispatch
- `notes`:

### .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/dispatch-log.md#chunk-0003

- `kind`: dispatch-log
- `lines`: 14-27
- `tokens`: 145
- `heading`: [2026-06-16 10:15:02 +0800] `context-brief` - `PASS`
- `summary`: - `owner_agent`: agent-system / - `module`: github-index / - `trigger`: e2e:github-index / - `depends_on`: / - `inputs`: .github live index + retained memory/log / - `action`: github-index brief / - `outputs`: .github/task-runs/2026-06-16-2026-06-16-index-e...

### [2026-06-16 10:15:02 +0800] `context-brief` - `PASS`

- `owner_agent`: agent-system
- `module`: github-index
- `trigger`: e2e:github-index
- `depends_on`:
- `inputs`: .github live index + retained memory/log
- `action`: github-index brief
- `outputs`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/context-brief.md
- `evidence`: .github/task-runs/2026-06-16-2026-06-16-index-evidence-autostore/context-brief.md
- `handoff_to`:
- `next_step`: DB-indexed startup context generated before dispatch
- `notes`:

