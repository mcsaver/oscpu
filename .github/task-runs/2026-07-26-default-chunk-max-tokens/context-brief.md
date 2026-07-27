# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: default chunk max tokens
- `focus_scope`: non-history
- `token_estimate`: 2397 / 2400

## Profile Suggestions
- `github-index` score=19 matched=chunk, max, requested-profile, tokens command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=4 matched=chunk, default, max, tokens command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=3 matched=chunk, default, max command=`scripts/agent-e2e.sh --profile nemu`

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

### .github/e2e/modules/agent-system.md#chunk-0002

- `kind`: e2e-module
- `lines`: 7-10
- `tokens`: 976
- `heading`: agent-system E2E Contract
- `summary`: - **启动/终结 fail-closed gate**: runner 在生成 `context-brief.md` 前先 `rebuild` live 索引，通过目录级剪枝排除 DB-first 的 `.github/{memory,task-runs}/**` 与历史 `.github/{archive,shujuku_aireview}/**`，只刷新 active rules/profile/root shims，并保留 `evidence/context-live-index-refresh.lo...

- **启动/终结 fail-closed gate**: runner 在生成 `context-brief.md` 前先 `rebuild` live 索引，通过目录级剪枝排除 DB-first 的 `.github/{memory,task-runs}/**` 与历史 `.github/{archive,shujuku_aireview}/**`，只刷新 active rules/profile/root shims，并保留 `evidence/context-live-index-refresh.log`；scoped rebuild 的 missing 更新只覆盖实际扫描且未排除的旧行，排除区状态必须保持。刷新失败会阻止旧规则 chunk 形成 complete recall，同时避免为 active-rule 刷新重复扫描海量历史证据。`context-brief.md` 与 `profile-resolve.md` 必须是原子落盘的普通文件；前者绑定硬预算内 canonical+profile+独立 focus chunks，并要求逐 chunk 完整 metadata/非空正文；后者绑定连续编号、唯一 ID 的非空 Nodes 闭包。completed 只允许全节点 PASS，run/report/manifest/index/dispatch 身份与时间一致，resolve/manifest/report/dispatch/`nodes.tsv` 绑定节点全元组；validator 同时递归解析当前 live profile include closure，逐节点复核 `node/source/module/owner/function/status/inputs/outputs`，拒绝多产物一致改写。dispatch 保持 canonical 全局事件顺序与 11 字段 payload；节点首要 evidence 必须是 canonical `evidence/<node_id>.log`，辅助指针也必须属于 actual indexed ordinary asset。strict guard 拒绝 diagnostic/header 注入、header-only/空壳截断、profile/count mismatch、未来时间、未知 deletion baseline、symlink run/evidence/artifact；`evidence-index.md` 的路径/尺寸/SHA 与 actual ordinary evidence 逐项重算。recall、resolve、report render、sanitizer、index、marker、staged sync、publish 任一失败都传播为非零/blocked。completed 先精确同步 staged Markdown，再生成七 artifact marker 与严格 EOF 的 `completion-publication.md`，最后由 `publish-task-run` 在单 SQLite 事务内复核并提交；普通 archive/promote/migrate/backup/rehydrate 不得创建或撤销 completion publication。失败撤销本次 live marker/publication 并重渲染 blocked，既有已提交 publication 不会被通用同步误删；strict guard 同时复核 marker、publication 与 DB/live 精确集合。
- **Bounded recall/publication route lock**: CLI/API 与 runner 的 brief 默认硬预算统一为 2400 tokens，显式 `E2E_CONTEXT_BRIEF_MAX_TOKENS` 覆盖仍须传入 recall CLI 并保留 fail-closed；runner 将 task slug 拆为至多 8 个非泛化语义词、只用 `--profile` 绑定 profile，并固定 `focus_scope=non-history`，使旧 task-run/report/evidence 不能为同 slug 重跑提供独立 primary focus，纯生命周期 slug 必须失败；通用 brief 默认 `all` 以保留显式历史召回。普通 backup 和 snapshot-stored 对 task-run publication 的 direct/default 路由都必须过滤，audit 不得出现 publication backup violation。
- **三层 gate**: `e2e_agent_system_three_layer_contract` 检查一页导航、canonical contract 路径、Database/Skill/Agent 边界、report matrix、schema contract、observability contract、runtime artifact contract、delivery contract、state traceability contract、review routing、branch-health dashboard、policy、workflow、skill、`agent-maintain` 和对应 audit/report 命令。
- **R3 gate**: `runtime-artifact-boundary` 检查 `.github/ai-env/contracts/agent-env-runtime-artifacts.json`、`.gitignore` 重型 artifact pattern、`report.sh` 的 raw evidence index-only 钩子、`artifact-audit` 维护门禁和 `agent-system` profile 节点。

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
