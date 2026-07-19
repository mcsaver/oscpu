# Agent Brief

- `ok`: true
- `recall_status`: complete
- `source`: live-or-stored
- `profile`: agent-system
- `terms`: slug recall
- `focus_scope`: non-history
- `token_estimate`: 2267 / 2400

## Profile Suggestions
- `agent-system` score=16 matched=requested-profile command=`scripts/agent-e2e.sh --profile agent-system`
- `discovery` score=1 matched=recall command=`scripts/agent-e2e.sh --profile discovery`
- `github-index` score=1 matched=recall command=`scripts/agent-e2e.sh --profile github-index`

## Commands
- `python3 scripts/github_index_db.py brief <terms> --profile <profile> --focus-scope non-history`
- `python3 scripts/github_index_db.py load --source auto --path <path>`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --list-profiles`
- `scripts/agent-e2e.sh --profile agent-system`

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

### .github/e2e/profiles/agent-system.tsv#chunk-0001

- `kind`: e2e-profile
- `lines`: 1-7
- `tokens`: 344
- `heading`: agent-system.tsv
- `summary`: @include|discovery|||| / three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/S...

@include|discovery||||
three-layer-contract|agent-system|e2e_agent_system_three_layer_contract|agent-system|.github/instructions/agent-env-layer-contract.instructions.md;.github/skills/agent-env-maintenance/SKILL.md;scripts/agent-maintain.sh|验证 Database/Skill/Agent 三层契约与维护入口
runtime-artifact-boundary|agent-system|e2e_agent_system_runtime_artifact_boundary|agent-system|.github/ai-env/contracts/agent-env-runtime-artifacts.json;.github/ai-env/contracts/agent-env-policy.json;scripts/agent-maintain.sh|验证源码面与运行态 artifact/store 分层边界
state-machine-traceback|agent-system|e2e_agent_system_state_traceback|agent-system|.github/instructions/agent-env-state-machine.instructions.md;.github/ai-env/contracts/agent-env-state-traceability.json;scripts/e2e/lib/report.sh|验证状态机回退和 task-run state_traceback 字段
reviewer-inspector-gate|agent-system|e2e_agent_system_reviewer_inspector_gate|agent-system|.github/ai-env/contracts/agent-env-review-routing.json;.github/ai-env/contracts/agent-env-policy.json;.github/e2e/profiles/agent-system.tsv|验证 Reviewer/Inspector 路由已落成 profile 执行节点
commercial-delivery-readiness|agent-system|e2e_agent_system_commercial_delivery_readiness|agent-system|.github/ai-env/contracts/agent-env-delivery.json;deliverables/ai-dev-env-commercial-v1;scripts/package-ai-dev-env.sh|验证商业交付包装、旧产物归档和 delivery audit
profile-index|agent-system|e2e_agent_system_profile_index|agent-system|.github/e2e/profiles|列出所有可执行 profile

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

### .github/agents/agent-system.agent.md#chunk-0001

- `kind`: agent
- `lines`: 1-7
- `tokens`: 152
- `heading`: agent-system.agent.md
- `summary`: --- / description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。" / tools: [read, edit, search, agent, todo] / --- / 你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，...

---
description: "工作区 agent 架构专家。当用户需要重构 .github/agents、.github/instructions、.github/skills、copilot-instructions、记忆协议、任务图、工作流 agent 或 AI 驱动硬件开发环境三层架构时使用。"
tools: [read, edit, search, agent, todo]
---

你是 **YSYX 工作区 agent 架构专家**。你的职责不是修改业务 RTL 或 C 逻辑，而是把 `.github/` 下的 Database、Skill、Agent 三层设计成一个真正可持续演化的 AI 驱动硬件开发环境。

### .github/memory/modules/agent-system.md#chunk-0001

- `kind`: memory-module
- `lines`: 1-1
- `tokens`: 8
- `heading`: Agent System 模块笔记
- `summary`: Agent System 模块笔记

# Agent System 模块笔记
