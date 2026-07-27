# Agent Brief

- `recall_status`: failed
- `profile`: github-index

WARN context brief generation failed; profile dispatch is not green.

## Diagnostic

```text
# Agent Brief

- `ok`: false
- `recall_status`: failed
- `source`: live-or-stored
- `profile`: github-index
- `terms`: rv64 v9u github index token chunks
- `focus_scope`: non-history
- `token_estimate`: 2125 / 2400
- `error`: no independent primary focus match outside required/core/profile/optional paths: rv64 v9u github index token chunks

## Profile Suggestions
- `github-index` score=30 matched=chunks, github, index, requested-profile, token command=`scripts/agent-e2e.sh --profile github-index`
- `rv64-linux` score=8 matched=github, rv64 command=`scripts/agent-e2e.sh --profile rv64-linux`
- `agent-system` score=7 matched=chunks, github, index, rv64, token command=`scripts/agent-e2e.sh --profile agent-system`
- `display-vga` score=4 matched=github, rv64 command=`scripts/agent-e2e.sh --profile display-vga`
- `linux-device` score=4 matched=github, rv64 command=`scripts/agent-e2e.sh --profile linux-device`

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

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-18
- `tokens`: 972
- `heading`: AGENTS.md
- `summary`: > 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。 / > / > 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。 / 1. 使用中文；复杂任务先分析再动手。 / 2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues...

# AGENTS.md

> 完整规范统一维护在 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 兼容说明：若当前 agent 只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 开工前读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md` 以及相关 `modules/*.md` / `instructions/*.instructions.md`；AI 环境入口见 `AI_ENVIRONMENT.md`；非平凡任务优先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 完成任务后必须更新 `.github/memory/project-status.md` 和相关 `.github/memory/modules/*.md`；若任务属于跨模块、图任务或长链调试，还应同步更新 `.github/task-runs/`。
6. 若任务是 AI 开发环境整理、e2e、自检或降低不确定性，先读取 `AI_ENVIRONMENT.md`、`.github/instructions/agent-env-layer-contract.instructions.md`、`.github/instructions/agent-e2e-workflow.instructions.md` 和 `.github/e2e/README.md`，再用 `scripts/agent-e2e.sh --list-profiles` 选 profile 并生成 task-run 证据包。
7. Windows 侧访问本 WSL 工作区时，PowerShell 只作为 `wsl.exe` 启动器，工程命令统一交给 Ubuntu：`wsl.exe -d Ubuntu --cd /home/lyg/PA/ysyx-workbench -- bash -lc '<cmd>'`；若 agent/CLI 已在 WSL/Linux 原生 shell 内运行，则直接使用原生命令，不再套 `wsl.exe`。Windows/Codex→WSL 工程命令默认 single-flight：主 agent 可以把当前唯一 shell ownership 交给一个契约授权的子 agent，但该节点执行期间其它 agent 不得并发运行工程命令；无 shell 推理或自包含材料复核仍可并行。复杂控制流、管道和 Bash 变量放入仓库脚本，避免被 PowerShell 预先解释。
8. 历史 task-run/evidence 回查使用 `python3 scripts/github_index_db.py runs --profile <profile>` 和 `python3 scripts/github_index_db.py evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志。
9. 交付前必须显式执行“实现者 / 审查者”双角色复核：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；分歧未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。
12. 本地 RV64 RTL 子 agent 使用 `fork_turns="none"`，初始提示只采用已校验的合同 `render` 输出；所需设计事实写入合同路径或随附材料，不继承父任务完整对话历史。该上下文隔离不降低模型、源码探索、实现、验证或 PPA 能力。

### .github/copilot-instructions.md#chunk-0001

- `kind`: instruction
- `lines`: 1-2
- `tokens`: 11
- `heading`: YSYX 工作区 — 全局指导规范
- `summary`: YSYX 工作区 — 全局指导规范

# YSYX 工作区 — 全局指导规范

### .github/memory/project-status.md#chunk-0001

- `kind`: memory
- `lines`: 1-2
- `tokens`: 8
- `heading`: YSYX 项目状态总览
- `summary`: YSYX 项目状态总览

# YSYX 项目状态总览

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

### .github/e2e/modules/github-index.md#chunk-0001

- `kind`: e2e-module
- `lines`: 1-7
- `tokens`: 698
- `heading`: github-index E2E Contract
- `summary`: - **范围**: `scripts/dev_memory/` 开发记忆系统工程目录、`scripts/github_index_db.py` 兼容 wrapper、`.github/` 下 agent/instructions/memory/e2e profile/module/task-run 文本证据，以及根目录/多 AI 入口 shim（`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`CONVENTIONS.md`、`.windsurfrules`、`.cursor/rule...

# github-index E2E Contract

- **范围**: `scripts/dev_memory/` 开发记忆系统工程目录、`scripts/github_index_db.py` 兼容 wrapper、`.github/` 下 agent/instructions/memory/e2e profile/module/task-run 文本证据，以及根目录/多 AI 入口 shim（`AGENTS.md`、`CLAUDE.md`、`GEMINI.md`、`CONVENTIONS.md`、`.windsurfrules`、`.cursor/rules/agents.mdc`）的本地检索索引、目录式浏览、摘要压缩、按需 chunk 加载、外部 AI JSON/JSONL 只读 API、DB-owned stored documents、raw evidence asset 结构化摘要、stored 原文更新、DB-first audit、备份/迁移/物化/恢复和安全维护入口。
- **上游**: 文件系统中的 `.github/**` 原始文件、根目录/多 AI 入口 shim、`software-flow` 软件开发闭环、`agent-system` e2e 规则发现。
- **下游**: agent 开工前 recall、规则/记忆检索、profile 选择、task-run 证据定位和状态巡检。
- **L0 gate**: `e2e_github_index_contract` 检查 `scripts/dev_memory/{core,queries,api,maintenance,cli,__main__}.py` 包布局、`scripts/github_index_db.py` 兼容 wrapper、本模块合约、profile、Git 跟踪状态、默认 `.github` 源目录、默认额外 agent shim 源、默认 `.github/cache/github-index.sqlite` 数据库路径、`.gitignore` 忽略边界、`file_chunks/chunk_fts` 片段表、`db_documents/db_document_chunks` stored document 表、`access_log` 使用时间表、`evidence_assets` 原始证据摘要表、`summary/compact`、`load`、`brief/context-pack`、`profile_suggestions`、`profiles/profile-catalog`、`resolve-profile`、`runs/run-catalog`、`evidence/evidence-assets`、`usage/access-log`、`api`、`promote`、`update-stored`、`backup`、`migrate`、`archive-markdown`、`index-evidence`、`snapshot-stored`、`rehydrate/import-backup`、`materialize`、`restore`、`audit-db-first` 与 `audit-markdown-coverage` CLI、e2e runner 派发前 context brief hook、e2e runner 派发前 resolved profile hook、e2e report 层 raw evidence asset 索引和 task-run Markdown 自动归档 hook、`doctor` 内部调用缺省隐藏非阻塞历史漂移/普通样例，以及 Python 语法。
- **遍历剪枝 gate**: monkeypatch 反例要求显式 exclude、`.github/db-backup` 与 raw evidence 目录在目录遍历阶段就被剪枝；索引器不得先逐文件访问海量 retained 历史，再依赖文件级 skip 丢弃结果。另一个真实 SQLite 反例要求 scoped rebuild 只把“本次扫描范围内且未被排除”的旧行标成 missing，显式排除的 retained live-index 行必须保持原状态。

```
