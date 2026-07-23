# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: stored memory evidence index github
- `focus_scope`: non-history
- `token_estimate`: 1768 / 2400

## Profile Suggestions
- `github-index` score=31 matched=evidence, github, index, memory, requested-profile, stored command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=7 matched=evidence, github, index, memory, stored command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=5 matched=evidence, github, index, memory command=`scripts/agent-e2e.sh --profile nemu`
- `software-flow` score=5 matched=evidence, github, memory command=`scripts/agent-e2e.sh --profile software-flow`
- `yosys-sta` score=5 matched=evidence, github, memory command=`scripts/agent-e2e.sh --profile yosys-sta`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile github-index`

## Missing Paths
- `.github/agents/github-index.agent.md`
- `.github/memory/modules/github-index.md`

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

### .github/e2e/profiles/github-index.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-2
- `tokens`: 67
- `heading`: node_id|module|function|owner_agent|inputs|outputs
- `summary`: github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

# node_id|module|function|owner_agent|inputs|outputs
github-index-contract|github-index|e2e_github_index_contract|agent-system|scripts/github_index_db.py + .github files|SQLite index can build, query and doctor .github metadata without owning originals

### .github/memory/modules/agent-system.md#chunk-0026

- `kind`: memory-module
- `lines`: 136-139
- `tokens`: 1283
- `heading`: 当前状态
- `summary`: - 2026-06-16：修复 `doctor --fail-on-drift` 仍用旧全文件 hard-fail 语义的问题。当前 DB ownership 已收缩为 retained memory/log，但旧 doctor 只看 `files` 表的 size/mtime/hash，导致历史 task-run/manual log 缺失、旧 evidence/shim 或 live-first 文档 stale 会阻断本轮维护；同时 strict memory drift 又必须继续失败，不能一刀切放过...

- 2026-06-16：修复 `doctor --fail-on-drift` 仍用旧全文件 hard-fail 语义的问题。当前 DB ownership 已收缩为 retained memory/log，但旧 doctor 只看 `files` 表的 size/mtime/hash，导致历史 task-run/manual log 缺失、旧 evidence/shim 或 live-first 文档 stale 会阻断本轮维护；同时 strict memory drift 又必须继续失败，不能一刀切放过。现在 `scripts/dev_memory/maintenance.py` 将 raw drift 映射为可见状态：`memory`/`memory-module` 保留 `missing/stale/read_error` 并影响 rc，非 strict retained task-run/report/evidence 归为 `archived_*`，非 retained live-first 索引漂移归为 `live_index_*`；`--write-status` 仍按 raw drift 更新索引状态。`scripts/e2e/modules/github_index.sh` mini repo 覆盖历史 task-run missing/stale 不失败、strict memory live drift 必失败。验证：`python3 -m py_compile scripts/dev_memory/maintenance.py scripts/dev_memory/cli.py scripts/dev_memory/core.py` PASS；`bash -n scripts/e2e/modules/github_index.sh scripts/agent-e2e.sh scripts/agent-maintain.sh` PASS；同步 `.github/memory/modules/npc.md` 后 `doctor --fail-on-drift` PASS、`audit-db-first` PASS、`audit-markdown-coverage --fail-on-live-evidence` PASS；`.github/task-runs/2026-06-16-2026-06-16-db-doctor-nonblocking-drift-contract-pass/` 的 `github-index` profile PASS。后续复核 `.github/task-runs/2026-06-16-2026-06-16-db-doctor-current-nonblocking-drift-fix/` 继续 PASS，evidence 中同时看到 `archived_missing/archived_stale` 非阻塞、stored-only 历史日志归档可见、strict memory live drift 仍会被 doctor/audit 拒绝。过程中再次确认当前桌面线程不宜并发多个 `wsl -d Ubuntu` 命令，否则容易触发 `Wsl/Service/E_UNEXPECTED`；后续维护脚本和人工验证应尽量 single-flight。
- 2026-06-16：按用户要求取消 `.github` workflow 的 push 自动运行。根因是 `.github/workflows/agent-maintain.yml` 中仍有 `push: branches: [ai]`，导致直接推送到 GitHub 时触发维护门禁；现已删除该触发块，保留 `pull_request`、`schedule` 与 `workflow_dispatch`。验证：文本检查确认 `^  push:` 不存在且必需入口仍在；shell/Python 静态检查 PASS；`scripts/agent-e2e.sh --list-profiles` PASS；`python3 scripts/github_index_db.py policy-audit` PASS；`scripts/agent-e2e.sh --validate-profile --profile agent-system` PASS；完整 `scripts/agent-maintain.sh --mode check` 的 workflow/policy/profile 相关段落 PASS，但最终因既有 DB-first live drift 退出 1。同步本轮改过的 memory 到 retained DB 后，当前 `audit-db-first` 只剩 `.github/memory/modules/npc.md` 内容漂移，本轮未把该既有漂移误判为 workflow 修复失败。证据包：`.github/task-runs/2026-06-16-agent-maintain-no-push-trigger/`。
- 2026-06-15：修复 `audit-db-first` 误用 SQLite 旧 `file_text` 判定 live 状态的维护 bug。此前删除 live task-run 日志或修改 live memory 后，只要索引缓存未刷新，audit 仍可能按旧内容判断；反过来历史 manual log 缺失、旧 evidence-index/shim 漂移又会污染当前门禁。现在 `scripts/dev_memory/maintenance.py` 在 audit 时实时读取工作区文件，并把 `memory`/`memory-module` 作为 strict live kinds：缺失、读失败或内容漂移仍失败；历史 task-run/report/evidence stored-only 归入 `archived_stored_only`，历史 evidence-index 内容漂移归入 `live_content_drift`，可见但不阻塞。github-index e2e mini repo 同步覆盖“历史 stored-only task-run 不失败”和“strict memory live drift 必须失败”。验证：py_compile、bash -n、`doctor --fail-on-drift`、`audit-db-first`、`audit-markdown-coverage --fail-on-live-evidence` PASS；`scripts/agent-e2e.sh --profile github-index --task-slug 2026-06-15-db-doctor-historical-drift-contract-rerun --stop-on-fail` PASS。期间 WSL 出现 `Wsl/Service/E_UNEXPECTED`，已通过重启 WSL 会话恢复，未从 `.github/db-backup` 绕路取结论。
- 2026-06-15：修复 `index-evidence --write-index` 生成索引文档后未同步刷新 DB 的维护 bug。此前命令会写出 `.github/task-runs/*/evidence-index.md`，但 SQLite `files/file_text/chunks` 仍保留旧 mtime/hash，下一次 `doctor --fail-on-drift` 会把刚生成的索引文档报成 stale，需要手工 `refresh`。现在 `scripts/dev_memory/maintenance.py::index_evidence_assets()` 在写出每个 `evidence-index.md` 后立即调用 `refresh_one()`，并在输出/JSON 中报告 `index-doc refreshed status=indexed`。验证：重新运行 `python3 scripts/github_index_db.py index-evidence --write-index --yes --limit 0 ...opcode-mix...` 显示两个 index doc 均 refreshed；随后直接 `python3 scripts/github_index_db.py doctor --fail-on-drift` 退出 0，只剩历史 raw binary/encoding skip 说明项，不再出现 missing/stale。

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
