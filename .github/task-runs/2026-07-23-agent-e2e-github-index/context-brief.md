# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: github-index
- `terms`: github index
- `focus_scope`: non-history
- `token_estimate`: 2272 / 2400

## Profile Suggestions
- `github-index` score=28 matched=github, index, requested-profile command=`scripts/agent-e2e.sh --profile github-index`
- `agent-system` score=4 matched=github, index command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=3 matched=github, index command=`scripts/agent-e2e.sh --profile nemu`
- `abstract-machine` score=2 matched=github command=`scripts/agent-e2e.sh --profile abstract-machine`
- `am-kernels` score=2 matched=github command=`scripts/agent-e2e.sh --profile am-kernels`

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

### .github/memory/claude-auto-memory/doc-lifecycle-protocol.md#chunk-0001

- `kind`: memory
- `lines`: 1-26
- `tokens`: 472
- `heading`: doc-lifecycle-protocol.md
- `summary`: --- / name: doc-lifecycle-protocol / description: 工作区文档生命周期协议已固化——完成任务前必须推进受影响文档状态;全量重审有命名工作流 / metadata: / node_type: memory / type: project / originSessionId: 6df78c86-b219-41be-9245-66df2198fbd6 / --- / 用户要求(2026-07-03)把文档生命周期做成 agent 系统常备能力,已三层落地: / 1....

---
name: doc-lifecycle-protocol
description: 工作区文档生命周期协议已固化——完成任务前必须推进受影响文档状态;全量重审有命名工作流
metadata:
  node_type: memory
  type: project
  originSessionId: 6df78c86-b219-41be-9245-66df2198fbd6
---

用户要求(2026-07-03)把文档生命周期做成 agent 系统常备能力,已三层落地:

1. **规则单源**: `.github/instructions/doc-lifecycle.instructions.md` —— 文档类型分类
   (normative/spec/plan/snapshot/index/memory/task-run)、状态模型(ACTIVE→⚠️死硅注记→
   ARCHIVED{SUPERSEDED/ORPHAN})、**归档五步手续**(git mv→history README 登记表→悬空引用
   grep 清零→索引同步→task-run 固化)、§4 迁移触发点(删模块→spec 归档/机制判死→注记/
   计划落地→同刀归档/新快照→旧快照归档)。
2. **可执行**: `.claude/workflows/doc-lifecycle-audit.js` 命名工作流(盘点 agent 动态发现
   文档并分组→并行审计对照代码→就地校正+归档队列)。args={roots,truth,groupSize}。
   注意: 命名注册表会话启动时扫描,同会话新建文件用 scriptPath 调用。
3. **入口挂钩**: AGENTS.md §7 + CLAUDE.md 契约第 5 条——**声明任务完成前必须核对文档
   生命周期触发点**,这对我是硬义务。

**How to apply**: 每次改 RTL/删模块/落地计划后,同刀处置对应文档;归档后必跑悬空引用
grep(12 份归档曾产生 10 处悬空引用的实测教训);大改后跑
`Workflow({name:"doc-lifecycle-audit", args:{roots:[...]}})`。
关联 [[rv64core-audit-baseline]] [[ooo-core-architecture-constitution]]。
