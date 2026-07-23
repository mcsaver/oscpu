# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: stored document snapshot audit
- `focus_scope`: non-history
- `token_estimate`: 2095 / 2400

## Profile Suggestions
- `github-index` score=20 matched=audit, document, requested-profile, snapshot, stored command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=4 matched=audit, snapshot, stored command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=2 matched=audit, snapshot command=`scripts/agent-e2e.sh --profile nemu`
- `ysyx-soc` score=1 matched=audit command=`scripts/agent-e2e.sh --profile ysyx-soc`

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

### .github/instructions/memory-protocol.instructions.md#chunk-0003

- `kind`: instruction
- `lines`: 10-55
- `tokens`: 714
- `heading`: 记忆文件位置
- `summary`: > **存储形态（2026-07-08 起 DB-backed）**：上列文件多数已提升为 stored document / > （`.github/cache/github-index.sqlite`），工作区内只留 8 行兼容 shim（开头为 / > `# DB-backed ...` 即是）。对 shim 文件： / > / > - **读原文**：`python3 scripts/github_index_db.py load --source stored --path <仓库相对路径>`； /...

## 记忆文件位置

```
.github/memory/
├── project-status.md        — 项目进度总览
├── decisions.md             — 设计决策记录
├── known-issues.md          — 已知问题与调试历史
└── modules/                 — 各模块专属笔记
    ├── agent-system.md      — agent 架构与工作流环境
    ├── software-flow.md     — 软件开发全流程
    ├── npc.md
    ├── nemu.md
    ├── abstract-machine.md
    ├── am-kernels.md
    ├── difftest.md
    ├── ysyx-soc.md
    └── yosys-sta.md
```

> **存储形态（2026-07-08 起 DB-backed）**：上列文件多数已提升为 stored document
> （`.github/cache/github-index.sqlite`），工作区内只留 8 行兼容 shim（开头为
> `# DB-backed ...` 即是）。对 shim 文件：
>
> - **读原文**：`python3 scripts/github_index_db.py load --source stored --path <仓库相对路径>`；
>   批量召回优先 `brief <关键词> --profile <profile>`。
> - **更新（铁律，违反=数据灾难）**：`update-stored` 是**整体替换**语义——你喂给它
>   什么，stored 全文就变成什么。因此追加条目 **必须** 三步走：
>   ① `load --source stored` 导出全文到临时文件；② 在临时文件中追加/修改；
>   ③ `update-stored <路径> --from-file <临时文件> --refresh-shim`。
>   **绝对禁止**把"只含新条目的短文"直接喂给 `update-stored`——那会把整份
>   文档（可能数百 KB 的项目史）替换成几行新内容。2026-07-09 实锤事故：
>   某实施 agent 跳过 ① 直接写入单条目，project-status.md（613KB）与
>   modules/npc.md（575KB）被整体覆盖为 8.4KB/528B，靠会话残留导出才恢复。
> - **写回后必须自检**：`update-stored` 输出的 `bytes=` 必须 **≥ 改前全文字节数**
>   （追加场景只增不减）。发现缩水立即停止后续写操作并从
>   `.github/db-backup/files/` 恢复。度量坑：直接查 sqlite 时 `LENGTH(content)`
>   返回**字符数**非字节数（中文 UTF-8 两者差 ~30%），勿跨单位比较。
> - **委托写回的责任划分**：主会话把任务派给子 agent 时，若允许其更新 memory，
>   prompt 中 **必须** 原文附上本三步协议；否则子 agent 只交回"待追加条目文本"，
>   由主会话统一执行写回。
> - **一致性审计**：`python3 scripts/github_index_db.py audit-db-first`。
>
> 完整 DB 工作流（`promote`/`materialize`/`restore`/`snapshot-stored` 等）见
> `.github/AGENTS.md` §0；非 shim 的 materialized 全文文件仍可直接编辑，但受
> strict 审计约束（live 必须等于 stored，编辑后需 `update-stored` 同步）。

### AGENTS.md#chunk-0001

- `kind`: agent-shim
- `lines`: 1-19
- `tokens`: 896
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
9. 交付前必须显式切换“实现者人格”和“审查者人格”：实现者给出交付证据，审查者优先寻找反例、覆盖洞、假绿和越级结论；冲突未解决时只能交付子任务状态和剩余风险。
10. 收尾前运行 `scripts/agent-e2e.sh --guard --guard-mode strict`；若提示缺少 profile evidence 或 DB 召回产物，必须运行建议的 profile 生成 `.github/task-runs/` 证据，或在回复和 memory 中写明豁免理由。
11. 派发本地 RV64 RTL 子 agent 前读取 `.github/instructions/rtl-agent-task-contract.instructions.md`，用 `.github/skills/prepare-rtl-task-contract/` 明确 RTL/spec/TB/evidence 输入、输出路径、结构化 `command/mode/purpose`、最小上下文、产物和成功条件；只读任务只消费合同列出的本地工程材料并使用不落盘命令，其它资料另建研究节点。

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
