# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: slug recall
- `focus_scope`: non-history
- `token_estimate`: 2400 / 2400

## Profile Suggestions
- `github-index` score=17 matched=recall, requested-profile command=`scripts/agent-e2e.sh --profile github-index`
- `discovery` score=1 matched=recall command=`scripts/agent-e2e.sh --profile discovery`

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

### .github/memory/modules/software-flow.md#chunk-0003

- `kind`: memory-module
- `lines`: 10-14
- `tokens`: 1345
- `heading`: 当前状态
- `summary`: - 2026-06-11：按 `software-dev-loop` + `modular-agent-e2e` 落地 `.github` 小型索引数据库系统，作为软件开发环境的 recall/query 辅助层。`scripts/github_index_db.py` 是纯 Python 标准库实现，默认读取 `.github` 文件系统原始产物，把 SQLite 索引放在 `.github/cache/github-index.sqlite`；数据库只保存索引、元数据、状态和可检索文本，不拥有原始文件。e...

- 2026-06-11：按 `software-dev-loop` + `modular-agent-e2e` 落地 `.github` 小型索引数据库系统，作为软件开发环境的 recall/query 辅助层。`scripts/github_index_db.py` 是纯 Python 标准库实现，默认读取 `.github` 文件系统原始产物，把 SQLite 索引放在 `.github/cache/github-index.sqlite`；数据库只保存索引、元数据、状态和可检索文本，不拥有原始文件。e2e 侧新增 `github-index` profile 并纳入 `contracts`，用临时 DB 实际跑 `rebuild/stat/query software-flow/doctor`，因此该工具不是“只存在于脚本”，而是被 agent-system contract 消费。验证：`python3 -m py_compile scripts/github_index_db.py` PASS；默认 `rebuild/stat/query/doctor` PASS；`scripts/agent-e2e.sh --validate-all-profiles` PASS；`.github/task-runs/2026-06-11-github-index-db-e2e-2/` 和 `.github/task-runs/2026-06-11-github-index-contracts-e2e/` PASS。边界：这是软件工具/开发环境索引能力，不替代具体 NEMU/AM/NPC/Linux 业务软件的 focused test、系统 gate 或人工审阅。
- 2026-06-10：`software-flow` 相关持久文件和早期证据包已从未跟踪状态纳入 Git 暂存，并由 agent-system 的新跟踪钩子覆盖。审计确认 `.github/agents/software-flow.agent.md`、`.github/e2e/profiles/software-flow.tsv` 以及 `.github/task-runs/2026-06-09-software-flow-*` 均为小型文本 evidence/profile/agent 文件，非大文件或编译中间产物；`git ls-files --others --exclude-standard` 清空后运行 `scripts/agent-e2e.sh --profile agent-system --task-slug agent-tracked-source-gate-e2e` PASS，`recall-discovery.log` 含 `PASS persistent agent/e2e source files are tracked`。意义：software-flow 不再只是当前会话内存在的 agent/profile，而是可跨会话恢复的工作区事实；后续新增软件流程 agent/profile/module 时，agent-system gate 会防止持久源文件漏跟踪。
- 2026-06-10：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 RV64 Sv39 page-table walk A/D 写回 PMP access-fault 切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-rv64-pmp-pagewalk-ad-e2e` PASS，`.github/task-runs/2026-06-10-nemu-rv64-pmp-pagewalk-ad-e2e/task-report.md` 显示 `tool-env-check`、`software-flow-contract`、`nemu-ubuntu-static`、`nemu-ubuntu-slice-contract` 全 PASS；`evidence/recall-discovery.log` 还证明 `agent-env repairs incomplete inherited marker` 已进入规则发现 gate，`tool-env-check.log` 证明 e2e 前置 source `scripts/agent-env.sh` 后 `YSYX_HOME/NEMU_HOME/AM_HOME/NPC_HOME/NVBOARD_HOME` 指向当前仓库；`evidence/nemu-ubuntu-static.log` 证明 `smoke-nemu-pmp-pagewalk-ad` 实际运行并 `HIT GOOD TRAP`，`evidence/nemu-ubuntu-slice-contract.log` 证明 `PMP_PAGEWALK_AD_BIN`、`NEMU_PMP_PAGEWALK_AD_LOG`、`PMP_CFG_R_NAPOT`、`PTE_VR` 等 marker 纳入 contract。意义：NEMU C/MMU/vaddr/Makefile/assembly smoke 侧硬件语义修复继续走软开闭环前置 + 系统语义 gate 收口；同时软开环境入口的半初始化问题也被 agent-system/toolchain 节点纳入同一生产证据链。
- 2026-06-10：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 RV64 Sv39 page-table walk PMP access-fault 切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-rv64-pmp-pagewalk-e2e` PASS，`.github/task-runs/2026-06-10-nemu-rv64-pmp-pagewalk-e2e/task-report.md` 显示 `software-flow-contract`、`nemu-ubuntu-static`、`nemu-ubuntu-slice-contract` 全 PASS；`evidence/tool-env-check.log` 证明 e2e 仍先 source `scripts/agent-env.sh`，`evidence/nemu-ubuntu-static.log` 证明 `smoke-nemu-pmp-pagewalk` 实际运行并 `HIT GOOD TRAP`，`evidence/nemu-ubuntu-slice-contract.log` 证明 `isa_riscv*_mmu_fault_cause`、`pmp-page-table-read/write`、Makefile target 与 smoke marker 全部纳入 contract。意义：NEMU C/MMU/vaddr/Makefile 侧硬件语义修复继续走软开闭环前置 + 系统语义 gate 收口；外层 Codex PowerShell 仍不等于工程 Linux shell，工程命令继续通过 WSL 显式 source `scripts/agent-env.sh`。
- 2026-06-10：通过 `nemu-ubuntu` 已 include `software-flow` 的链路，当前 RV64 basic PMP/access-fault 切片先执行 `software-flow-contract`，再执行 NEMU static/slice gate。验证：`scripts/agent-e2e.sh --profile nemu-ubuntu --task-slug nemu-rv64-pmp-access-e2e` PASS，`.github/task-runs/2026-06-10-nemu-rv64-pmp-access-e2e/task-report.md` 显示 `software-flow-contract`、`nemu-ubuntu-static`、`nemu-ubuntu-slice-contract` 全 PASS；`evidence/tool-env-check.log` 证明 e2e 前置 source `scripts/agent-env.sh` 并导出 `YSYX_HOME/NEMU_HOME`，`evidence/nemu-ubuntu-static.log` 证明 `smoke-nemu-pmp-access` 实际运行并 `HIT GOOD TRAP`，`evidence/nemu-ubuntu-slice-contract.log` 证明 PMP CSR/MMU/vaddr/RV32 stub/smoke marker 全部纳入 contract。意义：NEMU C/CSR/MMU/vaddr 侧硬件语义切片继续由软开闭环前置，再由系统语义 gate 收口；外层 Codex PowerShell 仍不等于工程 Linux shell，工程命令继续通过 WSL 显式 source `scripts/agent-env.sh`。

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

### .github/e2e/README.md#chunk-0001

- `kind`: markdown
- `lines`: 1-2
- `tokens`: 6
- `heading`: Agent E2E Profiles
- `summary`: Agent E2E Profiles

# Agent E2E Profiles
