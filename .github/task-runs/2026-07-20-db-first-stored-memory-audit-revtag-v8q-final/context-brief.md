# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: db first stored memory audit
- `focus_scope`: non-history
- `token_estimate`: 1922 / 2400

## Profile Suggestions
- `github-index` score=22 matched=audit, db, first, memory, requested-profile, stored command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=6 matched=audit, db, first, memory, stored command=`scripts/agent-e2e.sh --profile agent-system`
- `contracts` score=3 matched=db, first, memory command=`scripts/agent-e2e.sh --profile contracts`
- `nemu` score=3 matched=audit, db, memory command=`scripts/agent-e2e.sh --profile nemu`
- `software-flow` score=3 matched=db, memory command=`scripts/agent-e2e.sh --profile software-flow`

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
- `lines`: 137-141
- `tokens`: 1437
- `heading`: 当前状态
- `summary`: - 2026-06-15：修复 `audit-db-first` 误用 SQLite 旧 `file_text` 判定 live 状态的维护 bug。此前删除 live task-run 日志或修改 live memory 后，只要索引缓存未刷新，audit 仍可能按旧内容判断；反过来历史 manual log 缺失、旧 evidence-index/shim 漂移又会污染当前门禁。现在 `scripts/dev_memory/maintenance.py` 在 audit 时实时读取工作区文件，并把 `me...

- 2026-06-15：修复 `audit-db-first` 误用 SQLite 旧 `file_text` 判定 live 状态的维护 bug。此前删除 live task-run 日志或修改 live memory 后，只要索引缓存未刷新，audit 仍可能按旧内容判断；反过来历史 manual log 缺失、旧 evidence-index/shim 漂移又会污染当前门禁。现在 `scripts/dev_memory/maintenance.py` 在 audit 时实时读取工作区文件，并把 `memory`/`memory-module` 作为 strict live kinds：缺失、读失败或内容漂移仍失败；历史 task-run/report/evidence stored-only 归入 `archived_stored_only`，历史 evidence-index 内容漂移归入 `live_content_drift`，可见但不阻塞。github-index e2e mini repo 同步覆盖“历史 stored-only task-run 不失败”和“strict memory live drift 必须失败”。验证：py_compile、bash -n、`doctor --fail-on-drift`、`audit-db-first`、`audit-markdown-coverage --fail-on-live-evidence` PASS；`scripts/agent-e2e.sh --profile github-index --task-slug 2026-06-15-db-doctor-historical-drift-contract-rerun --stop-on-fail` PASS。期间 WSL 出现 `Wsl/Service/E_UNEXPECTED`，已通过重启 WSL 会话恢复，未从 `.github/db-backup` 绕路取结论。
- 2026-06-15：修复 `index-evidence --write-index` 生成索引文档后未同步刷新 DB 的维护 bug。此前命令会写出 `.github/task-runs/*/evidence-index.md`，但 SQLite `files/file_text/chunks` 仍保留旧 mtime/hash，下一次 `doctor --fail-on-drift` 会把刚生成的索引文档报成 stale，需要手工 `refresh`。现在 `scripts/dev_memory/maintenance.py::index_evidence_assets()` 在写出每个 `evidence-index.md` 后立即调用 `refresh_one()`，并在输出/JSON 中报告 `index-doc refreshed status=indexed`。验证：重新运行 `python3 scripts/github_index_db.py index-evidence --write-index --yes --limit 0 ...opcode-mix...` 显示两个 index doc 均 refreshed；随后直接 `python3 scripts/github_index_db.py doctor --fail-on-drift` 退出 0，只剩历史 raw binary/encoding skip 说明项，不再出现 missing/stale。
- 2026-06-15：完成 NEMU/NPC AI 开发环境隔离性检查，并将“可同时推进但不应混跑同一资源”作为当前使用边界。`scripts/agent-e2e.sh --list-profiles` 可见 `nemu-dev`、`npc-dev` 与跨栈 `nemu-ubuntu-integrated`；`python3 scripts/github_index_db.py resolve-profile nemu-dev` 显示闭包仅含 `software-flow` 与 `nemu` 3 个节点，`resolve-profile npc-dev` 仅含 `software-flow` 与 `npc` 5 个节点，`resolve-profile nemu-ubuntu-integrated` 才同时含 `npc`/`rv64-linux`/`nemu`。真实轻量 e2e 验证：`.github/task-runs/2026-06-15-2026-06-15-nemu-npc-env-isolation-nemu-dev/` 中 `profile-boundary=nemu-dev mode=NEMU-only`、NEMU-only closure PASS、3 节点全 PASS；`.github/task-runs/2026-06-15-2026-06-15-nemu-npc-env-isolation-npc-dev/` 中 `profile-boundary=npc-dev mode=NPC-only`、NPC-only closure PASS、5 节点全 PASS。结论：AI 调度/profile 层不会把 NEMU-only 与 NPC-only 任务互相污染；风险主要来自同一工作树的物理共享资源，例如并发 WSL 工程命令、同一 `.config`/build 目录、`.github/memory`/task-run 写入、`Linux/env` 镜像/日志/rootfs 产物或明确选择 `nemu-ubuntu-integrated`。
- 2026-06-15：修复 DB doctor 噪声与 evidence-index 文本安全问题。未从 `.github/db-backup` 读取或恢复内容；对 5 条已不存在的历史 NPC manual `make-dry-run.log` 只执行 `remove` 的 index-only 清理，对 `.github/agent-env-policy.json`、`.github/agent-env-rebuild-matrix.json` 和本轮 NEMU profile run 的 `evidence-index.md` 执行 targeted refresh。另修正 `index-evidence` 生成器：raw evidence 摘要进入 DB/Markdown 前会替换 NUL/控制字符，避免大型 `rootfs-overlay.raw` 的 tail 把 `evidence-index.md` 变成 `skipped_binary`。验证：`doctor` 与 `doctor --fail-on-drift` 均不再报告 `missing`/`stale`，本轮 profile run 的 `evidence-index.md` 为 UTF-8 且 DB status=`indexed`。
- 2026-06-15：按用户偏好将开发记忆数据库从“DB-first 大量 shim”收缩为“live-first 文件 + retained memory/log DB”。本轮 `materialize --prune-non-retained` 已把 2349 个 stored documents 写回原路径，DB 仅保留 `.github/memory/**` 与 `.github/task-runs/**` 日志/报告类 2247 个 stored documents，且 `audit-db-first` 显示 materialized=2247、shims=0；agent、instruction、e2e profile/module、contract、说明文档和 skills 都回到 live 文件。代码侧 `DB_RETAINED_KINDS` 限定 memory/log，`profiles/resolve-profile/brief` 支持 live-or-stored fallback，`policy-audit` 改查 live indexed agents，`archive-markdown` 默认保留 live file，`update-stored` 默认同步写回原文件；AI_ENVIRONMENT、AGENTS、Copilot 规则、layer/state instructions、agent-env-maintenance skill、schema/runtime/review contracts 与 github-index/agent-system e2e 文案已同步。验证：py_compile、bash -n、JSON parse、schema-audit、policy-audit、report-audit、artifact-audit、delivery-audit、branch-health-audit、trace-audit、skill-audit、audit-db-first、audit-markdown-coverage、profiles/resolve-profile/brief 均 PASS。边界：全量 `rebuild` 因物化后的 task-run 文本规模超过当前交互预算而两次超时，已终止残留进程；本轮采用 targeted refresh 和审计验证当前 DB/index 可用。

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
