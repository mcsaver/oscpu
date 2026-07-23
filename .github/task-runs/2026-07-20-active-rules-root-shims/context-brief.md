# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: active rules root shims
- `focus_scope`: non-history
- `token_estimate`: 1719 / 2400

## Profile Suggestions
- `github-index` score=19 matched=active, requested-profile, root, rules command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=4 matched=active, root, rules, shims command=`scripts/agent-e2e.sh --profile agent-system`
- `linux-device` score=2 matched=root command=`scripts/agent-e2e.sh --profile linux-device`
- `nemu` score=2 matched=active, root command=`scripts/agent-e2e.sh --profile nemu`
- `rv64-linux` score=2 matched=root command=`scripts/agent-e2e.sh --profile rv64-linux`

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

### .github/instructions/agent-e2e-workflow.instructions.md#chunk-0003

- `kind`: instruction
- `lines`: 14-31
- `tokens`: 1234
- `heading`: 执行卫生
- `summary`: 本地 RV64 RTL 子 agent 的派发先读取 `.github/instructions/rtl-agent-task-contract.instructions.md`， / 用 `.github/skills/prepare-rtl-task-contract/` 生成、校验并渲染 task contract；命令权限使用结构化 / `command/mode/purpose`，且 profile 必须运行真实 CLI `create/validate/render` 正负向自测。只读子任务必须明...

## 执行卫生

本地 RV64 RTL 子 agent 的派发先读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，
用 `.github/skills/prepare-rtl-task-contract/` 生成、校验并渲染 task contract；命令权限使用结构化
`command/mode/purpose`，且 profile 必须运行真实 CLI `create/validate/render` 正负向自测。只读子任务必须明确
不改文件、不联网、不访问账号、凭据或外部服务；平台 review 只记录当前节点为 `review_pending`，
不得自动关闭长期父目标。`agent-system` profile 的 `rtl-task-contract` 节点负责该接线与 mutation 反例。

- 开工先用 `python3 scripts/github_index_db.py brief <关键词> --profile <profile> --focus-scope non-history` 生成 bounded 上下文包；未确定 profile 时只省略 `--profile`，仍保留 non-history focus，再看 `Profile Suggestions`。普通规则文件修改后，手工再次调用 brief 前先用 `python3 scripts/github_index_db.py refresh <路径...>` 更新 live 索引；`agent-e2e.sh` 正式派发则会在 context brief 前自动 `rebuild` live 索引，通过目录级剪枝排除 DB-first 的 `.github/{memory,task-runs}/**` 与历史 `.github/{archive,shujuku_aireview}/**`，只刷新 active rules/profile/root shims，并把结果保存在 `evidence/context-live-index-refresh.log`。刷新失败必须使本轮非零且不得继续生成看似 complete 的旧 brief。只有 `recall_status=complete` 才可继续派发；canonical/profile/独立 focus 缺失或必需 chunk 超出硬 token budget 时，CLI 必须非零、API 必须 `ok=false`，runner 不得降级为 WARN 假绿。回查历史 task-run/evidence 时使用 `runs --profile <profile>` 和 `evidence --run-id <run_id>`，不要默认手工 grep/cat 完整日志或直接加载 `.github/task-runs/**` 原始 evidence。
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
