# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: npc-dev
- `terms`: npc-dev q2
- `token_estimate`: 2385 / 2400

## Profile Suggestions
- `npc-dev` score=11 matched=npc-dev, requested-profile command=`scripts/agent-e2e.sh --profile npc-dev`
- `agent-system` score=1 matched=npc-dev command=`scripts/agent-e2e.sh --profile agent-system`
- `nemu` score=1 matched=q2 command=`scripts/agent-e2e.sh --profile nemu`
- `software-flow` score=1 matched=npc-dev command=`scripts/agent-e2e.sh --profile software-flow`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile>`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile npc-dev`

## Missing Paths
- `.github/e2e/modules/npc-dev.md`
- `.github/agents/npc-dev.agent.md`
- `.github/memory/modules/npc-dev.md`

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

### .github/e2e/profiles/npc-dev.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-5
- `tokens`: 148
- `heading`: npc-dev.tsv
- `summary`: @include|software-flow|||| / npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同 / npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在 / npc-soc-contrac...

@include|software-flow||||
npc-sim-contract|npc|e2e_npc_sim_contract|npc|npc/sim + backend manifests|NPC 开发环境入口只检查 NPC 仿真后端合同
npc-single-contract|npc|e2e_npc_single_contract|npc|npc/single Makefile/Kconfig/vsrc/csrc|NPC single 后端合约入口存在
npc-soc-contract|npc|e2e_npc_soc_contract|npc|npc/soc + ysyxSoC CPU ABI|NPC SoC 后端合约入口存在
npc-rv64-contract|npc|e2e_npc_rv64_contract|npc|npc/rv64 + Linux README|NPC RV64 Linux 入口合约存在但不跑 NEMU Ubuntu gate

### .github/memory/modules/agent-system.md#chunk-0002

- `kind`: memory-module
- `lines`: 2-8
- `tokens`: 1584
- `heading`: 当前状态
- `summary`: - 2026-07-19：Q2 合同实战新增一条可复用的 AI 工作流规则：**历史证据自洽不等于合同可满足，跨 owner/时序合同在写 RTL 前必须由独立反例审查；发现 P0 后保留旧证据字节，另建窄范围 schema，而不是滚动旧锁掩盖矛盾**。本轮三个只读审查视角分别做 checker RED taxonomy、真实调用链和合同反例，识别 IFU 反向依赖、ROB/pending-system owner 混配、payload/identity provenance、FENCE generation...

## 当前状态

- 2026-07-19：Q2 合同实战新增一条可复用的 AI 工作流规则：**历史证据自洽不等于合同可满足，跨 owner/时序合同在写 RTL 前必须由独立反例审查；发现 P0 后保留旧证据字节，另建窄范围 schema，而不是滚动旧锁掩盖矛盾**。本轮三个只读审查视角分别做 checker RED taxonomy、真实调用链和合同反例，识别 IFU 反向依赖、ROB/pending-system owner 混配、payload/identity provenance、FENCE generation、Q1 abort 与 support-module false RED。结果固化为 v8a 的 8 项机器 blocker、17 个 anti-false-green mutation、双 active-source 314 项 source-bound RED、pre/post source snapshot，并逐字节回查 v7 28-path evidence。经验边界：窄 schema 必须把延期项从 required scope/claim 中明确删除并写退出条件；否则“新版本”只是另一种假绿。该流程只提升合同可发现/可审计性，不替代 RTL、Linux、STA/PPA gate。
- 2026-07-18：**agent/e2e v10 已把自洽证据升级为 live source-bound completion，并关闭 DB 发布假绿**。`e2e_validate_task_run_bundle` 递归解析当前 profile TSV/include closure，把 node/source/module/owner/function/status/inputs/outputs 与 manifest/resolve/nodes/report/dispatch 精确同序比较；每节点首要证据必须是 canonical node-owned log，辅助指针也必须是 actual indexed ordinary asset。dispatch 只接受两个 startup PASS 后逐节点 `in-progress→PASS`，每事件恰好 11 字段；marker 绑定七 artifact。DB 采用 staged sync + 专用 `publish-task-run` 两阶段：generic archive 精确 prune DB/index/backup 却保护 committed publication，generic promote/update/migrate/rehydrate 不得写入任意 task-run 层级的 `completion-publication.md`，publisher/API/strict guard 对 publication 统一严格 EOF，completed API 还从唯一 canonical 收尾段恢复 `final_result`；audit 只豁免不可恢复的 canonical publication backup，并拒绝反向备份；普通 backup/snapshot 也过滤 publication。brief 默认 2400 与 CLI/API 对齐，又保留显式覆盖与必需 focus 的 fail-closed。真实 SQLite 回归 14/14；多产物一致 function 改写、错属真实 evidence、尾随 publication、post-publish sync 与失败 DB 路径均有负例。正式证据 `.github/task-runs/2026-07-18-github-index-5/`、`.github/task-runs/2026-07-18-agent-system-5/` 与 `.github/task-runs/2026-07-18-rv64-ppa-3/` 均 completed 且 publication_valid；本项不构成任何 RV64 功能、Linux、时序或 PPA 声明。
- 2026-07-11：**strict guard 已从文件 mtime 改为语义新鲜度，并关闭 raw Markdown evidence 进入全文库的边界漏洞**。旧实现用 `task-report.md` mtime 代表 profile 完成时间；格式化或归档报告即可让旧 run 看起来比源码新，形成 false pass。当前以 `manifest.json.updated_at` 为权威，manifest 缺失时才读取 report 中唯一、精确的 `profile/status/updated_at` 字段；候选按带时区的 UTC 微秒时间选最新，report mtime 不参与判定。非对象 JSON、重复 key/字段、NaN/Infinity、profile/status 不匹配、缺失/无时区时间以及 manifest symlink（含 dangling）均 fail closed 且不抛 traceback。raw `.github/task-runs/*/evidence/**` 与 `.github/runtime-artifacts/<run-id>/**` Markdown 只进入 bounded `evidence_assets`，不进入 `db_documents/file_text/chunks/FTS`；前缀清理改用精确 `substr`，避免 SQL LIKE 的 `_` 通配误删相邻 runtime root。TDD 覆盖 19 个 guard 正反例、raw/runtime 索引和相邻 root 隔离，独立复审最终 Critical=0/Important=0；完整 agent-system 与 strict guard 证据由 task slug `strict-guard-semantic-freshness-agent-system` 的追加式 task-run 家族承载。本项只修 AI 开发环境证据可信度，不代表 RV64 RTL 或物理 200 MHz 已完成。
- 2026-07-11：**strict guard 的 raw-evidence 生命周期阻塞已根因修复**。唯一失败项是历史 STA `topo40.rpt`（1,650,168 bytes）在 task-run evidence ignore 规则已存在时仍被 Git 跟踪；正确处置不是调高 `max_tracked_evidence_bytes=1048576`、新增 ignore、截断或删除报告，而是先用 `index-evidence --write-index` 登记原路径、尺寸、行数、SHA-256 和摘要，再用 `archive-markdown` 归档派生索引，最后 `git rm --cached` 仅解除 source tracking。raw 文件仍在本地 ignored runtime root，SHA-256 保持 `f2b292686adef90056a7fe0ea7977d6a0085d98a7d5aa9cf0c3b346ffe10d512`；legacy/manual run 不人工伪造完整 e2e manifest，新的 profile run 负责生成真实 trace。终态全局 `artifact-audit` PASS（5666 tracked runtime files、0 tracked heavy files），fresh `agent-system`/`npc-dev` completed，strict guard required profiles=2 全 PASS。
- 2026-07-08：**`debug`/`common` 目录职责纠偏：它们也是 RTL spec 语义审核层**。用户明确指出 `npc/rv64/vsrc/debug` 与 `npc/rv64/vsrc/common` 的作用之一是审核 RTL 是否符合 spec 语义，本轮将其固化为 RV64 RTL 工作习惯：跨模块、flush/redirect、抽象状态或协议语义变化时，先检查现有 common facts 与 debug checker 能否承接 spec/invariant 审核，必要时新增 `vsrc/common/*Facts*` 与 `vsrc/debug/*Checker.sv`；单模块纯组合边界可用 dedicated TB 和 `testbench/common/tb_common.svh` 覆盖同一类 spec 语义，但 task-run 必须说明为什么不用外部 XMR checker。本轮 `PmpChecker` 优化选择 dedicated `tb_pmp_checker` 审核 `pmp-checker.md` PMP-I1~I4，并在 task-run 记录该取舍。

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

### .github/task-runs/2026-07-19-rv64-q2-v8a-contract/evidence-index.md#chunk-0002

- `kind`: task-run
- `lines`: 3-10
- `tokens`: 49
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-07-19-rv64-q2-v8a-contract / - `task_slug`: rv64-q2-v8a-contract / - `profile`: npc-dev / - `asset_count`: 5 / - `total_size_bytes`: 3307

## 基本信息

- `task_id`: 2026-07-19-rv64-q2-v8a-contract
- `task_slug`: rv64-q2-v8a-contract
- `profile`: npc-dev
- `asset_count`: 5
- `total_size_bytes`: 3307

### .github/task-runs/2026-07-19-rv64-q2-v8a-contract/dispatch-log.md#chunk-0002

- `kind`: dispatch-log
- `lines`: 3-13
- `tokens`: 66
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-07-19-rv64-q2-v8a-contract / - `trace_id`: e2e:2026-07-19-rv64-q2-v8a-contract / - `task_slug`: rv64-q2-v8a-contract / - `graph_template`: modular-agent-e2e / - `profile`: npc-dev / - `log_policy`: append-only / ---

## 基本信息

- `task_id`: 2026-07-19-rv64-q2-v8a-contract
- `trace_id`: e2e:2026-07-19-rv64-q2-v8a-contract
- `task_slug`: rv64-q2-v8a-contract
- `graph_template`: modular-agent-e2e
- `profile`: npc-dev
- `log_policy`: append-only

---

### .github/task-runs/2026-07-18-r4-s2-q1-q2-memory-closure/evidence-index.md#chunk-0002

- `kind`: task-run
- `lines`: 3-10
- `tokens`: 51
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-07-18-r4-s2-q1-q2-memory-closure / - `task_slug`: r4-s2-q1-q2-memory-closure / - `profile`: npc-dev / - `asset_count`: 5 / - `total_size_bytes`: 3307

## 基本信息

- `task_id`: 2026-07-18-r4-s2-q1-q2-memory-closure
- `task_slug`: r4-s2-q1-q2-memory-closure
- `profile`: npc-dev
- `asset_count`: 5
- `total_size_bytes`: 3307

### .github/task-runs/2026-07-18-r4-s2-q1-q2-memory-closure/dispatch-log.md#chunk-0002

- `kind`: dispatch-log
- `lines`: 3-13
- `tokens`: 69
- `heading`: 基本信息
- `summary`: - `task_id`: 2026-07-18-r4-s2-q1-q2-memory-closure / - `trace_id`: e2e:2026-07-18-r4-s2-q1-q2-memory-closure / - `task_slug`: r4-s2-q1-q2-memory-closure / - `graph_template`: modular-agent-e2e / - `profile`: npc-dev / - `log_policy`: append-only / ---

## 基本信息

- `task_id`: 2026-07-18-r4-s2-q1-q2-memory-closure
- `trace_id`: e2e:2026-07-18-r4-s2-q1-q2-memory-closure
- `task_slug`: r4-s2-q1-q2-memory-closure
- `graph_template`: modular-agent-e2e
- `profile`: npc-dev
- `log_policy`: append-only

---
