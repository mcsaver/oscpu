# Agent Env Layer Contract

本文件定义当前工作区 AI 开发环境的三层边界。涉及 `.github/` agent 架构、数据库记忆、Skill、e2e profile、自检或自动维护流程时必须读取。

## 三层职责

### 1. Database = 长期记忆层

- 真实入口：`.github/cache/github-index.sqlite`、`scripts/dev_memory/`、`scripts/github_index_db.py`。
- 保存对象：固定格式的长期记忆、模块笔记、task-run Markdown、raw evidence asset 索引、run manifest、trace id、access log、备份 manifest。
- 文件语义：agent、instruction、e2e profile/module、contract 和说明文档保留为 live 原文件；数据库只 retained `.github/memory/**` 与 `.github/task-runs/**` 的日志/报告类 stored documents。读取普通文档用文件系统或 `load --source auto`；更新 retained memory/log 用 `update-stored`、`archive-markdown`、`snapshot-stored`。
- retention：task-run Markdown 可以进入 stored document 与 backup，但工作区仍保留可直接读取的原文件；raw evidence 只进入 `evidence_assets` 摘要索引，不把完整日志默认塞回长期上下文。
- schema/API：`.github/ai-env/contracts/agent-env-schema-contract.json` 是当前 SQLite 表、实体映射与只读 JSON API op 的显式契约；真实 DB 变更必须同步该契约并通过 `schema-audit`。
- observability：`.github/ai-env/contracts/agent-env-observability.json` 是 task-run trace id、`run-manifest.json`、artifact 链接和 DB evidence asset 索引的显式契约；真实报告链路变更必须同步该契约并通过 `trace-audit`。
- runtime artifact：`.github/ai-env/contracts/agent-env-runtime-artifacts.json` 是源码面与运行态 payload 的显式契约；大体积日志、波形、镜像和 volatile payload 进入 `.github/runtime-artifacts` 或外部 object store，并用 `evidence_assets`、`run-manifest.json`、`evidence-index.md` 保存指针与摘要；真实边界变更必须通过 `artifact-audit`。
- 不承担职责：不直接替代 active Skill；不把 `.github/db-backup/**` 当作当前答案来源；不把完整 raw log 默认加载进上下文。

### 2. Skill = 标准化处理规则层

- 真实入口：`.github/skills/*/SKILL.md`，当前默认 skill 为 `.github/skills/agent-env-maintenance/SKILL.md`。
- 保存对象：短小、可直接读取、可复用的流程规则；复杂细节转交 scripts、instructions 或 live reference。
- 文件语义：Skill 是 active rule pack，必须 live 可读，不迁成数据库 shim；用 `python3 scripts/github_index_db.py skill-audit` 检查 frontmatter、命名和体量。
- 不承担职责：不保存长期事实，不保存单次 task-run 证据，不隐藏重型执行逻辑。

### 3. Agent = 自动维护流程层

- 真实入口：`.github/agents/*.agent.md`、`ysyx-coordinator` 图任务模型、`agent-system` 架构 agent、`.github/ai-env/contracts/agent-env-policy.json`、`.github/ai-env/contracts/agent-env-review-routing.json`、`.github/ai-env/contracts/agent-env-branch-health.json`、`.github/ai-env/contracts/agent-env-observability.json`、`.github/ai-env/contracts/agent-env-state-traceability.json`、`.github/ai-env/contracts/agent-env-delivery.json`、`scripts/package-ai-dev-env.sh`、`scripts/agent-e2e.sh`、`scripts/agent-maintain.sh`。
- 保存对象：角色边界、调度图、review routing、branch-health dashboard、observability contract、state traceback contract、delivery contract、e2e profile、自动检查节点、task-run 证据包和商业交付包。
- 文件语义：Agent 负责把用户目标映射成图节点并收口验证；每个跨层任务至少留下 profile resolve、task report、dispatch log 或等价证据；权限、MCP、retention、CI/nightly 规则由 `.github/ai-env/contracts/agent-env-policy.json` 统一声明。
- 不承担职责：不绕过 Database 写回事实；不把 Skill 内容复制进每个 agent profile；不让单个 profile 承担所有维护逻辑。

## 维护闭环

`report-audit -> policy-audit -> blueprint -> skill/instruction/script edits -> validate-discovery -> inspect -> record`

最低验证：

```bash
scripts/agent-maintain.sh --mode check
```

其中 `scripts/agent-maintain.sh --mode check` 必须覆盖：

- `python3 scripts/github_index_db.py report-audit`
- `python3 scripts/github_index_db.py schema-audit`
- `python3 scripts/github_index_db.py artifact-audit`
- `python3 scripts/github_index_db.py delivery-audit`
- `python3 scripts/github_index_db.py trace-audit`
- `python3 scripts/github_index_db.py state-audit`
- `python3 scripts/github_index_db.py policy-audit`
- `python3 scripts/github_index_db.py skill-audit`
- `python3 scripts/github_index_db.py branch-health-report`
- `python3 scripts/github_index_db.py branch-health-audit`
- `python3 scripts/github_index_db.py audit-db-first`
- `python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence`
- `scripts/agent-e2e.sh --validate-all-profiles`

跨层任务还必须维护：

- `.github/ai-env/contracts/agent-env-rebuild-matrix.json`：把外部研究报告的问题、建议、状态、证据和下一步变成机器可读追踪矩阵。
- `.github/ai-env/contracts/agent-env-schema-contract.json`：把 SQLite runtime schema、实体映射、retention 和只读 API 操作变成机器可读契约。
- `.github/ai-env/contracts/agent-env-observability.json`：把 task-run trace id、`run-manifest.json`、artifact 链接、DB evidence asset 映射和 `trace-audit` 变成机器可读契约。
- `.github/ai-env/contracts/agent-env-runtime-artifacts.json`：把源码面、运行态 payload root、artifact store、heavy suffix ignore pattern、raw evidence index-only 和 `artifact-audit` 变成机器可读契约。
- `.github/ai-env/contracts/agent-env-delivery.json`：把商业交付目录、旧产物归档、包生成脚本、包内必需文件、敏感路径扫描和 `delivery-audit` 变成机器可读契约。
- `.github/ai-env/contracts/agent-env-state-traceability.json`：把 FSM 状态、`state_traceback` 字段、Reviewer/Inspector 执行节点和 `state-audit` 变成机器可读契约。
- `.github/ai-env/contracts/agent-env-review-routing.json`：把 R1-R9 和三层路径映射到 reviewer/inspector 路由，避免跨层改动无人复核。
- `.github/ai-env/contracts/agent-env-branch-health.json`：把当前分支、HEAD、upstream、git status、矩阵状态和维护 gate 变成轻量 dashboard 契约。
- `.github/instructions/agent-env-state-machine.instructions.md`：把 recall、classify、plan、implement、verify、inspect、persist 状态和回退规则固定下来。

触及 profile 或 e2e 节点时追加：

```bash
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --profile agent-system
```

## 判定规则

- retained DB audit 通过，只能说明 memory/log stored documents、活文件内容和备份一致；不能说明 Skill 规则可用。
- report-audit 通过，说明研究报告中的高/中优先级要求都有状态、证据、验证命令和下一步；不说明所有项目都已完成。
- schema-audit 通过，说明显式 schema/API 契约与当前 SQLite runtime schema、实体映射和只读 API op 一致。
- artifact-audit 通过，说明 runtime artifact 契约、policy/schema/observability 引用、`.gitignore` 重型 payload 边界、`report.sh` evidence index-only 钩子、`agent-maintain` 门禁和 DB 不存 raw payload 的规则一致；带 `--run-id` 时还必须验证指定 task-run 的 raw evidence 已有 `evidence_assets` 索引。
- delivery-audit 通过，说明旧 `outputs/` 与 `.github/e2e/_manual` 已离开 active surface、归档 manifest 和交付文档齐全、`scripts/package-ai-dev-env.sh` 可生成商业包、包清单为相对路径、包内必需文件齐全且未扫描到本机路径或私有标记。
- trace-audit 通过，说明 observability 契约、policy 开关、`report.sh` manifest 生成器和 `run-manifest.json`/DB evidence asset 链接一致；带 `--run-id` 时还必须验证指定 task-run 的 trace id 与 artifact 路径。
- state-audit 通过，说明状态机契约、policy、review routing、`agent-system` profile 节点、`report.sh` 的 `state_traceback` 字段和指定 run 的状态回溯证据一致。
- policy-audit 通过，说明 agent tool allowlist、MCP 禁用、retention 路径和 CI/nightly gate 的声明与工作区一致。
- skill-audit 通过，只能说明 Skill 文件结构健康；不能说明 Agent 自动流程闭合。
- branch-health-audit 通过，说明 review routing、branch-health dashboard、policy 引用和维护脚本接线一致；branch-health-report 只给出当前分支状态，不替代完整 e2e。
- agent-system profile 通过，才能说明 Database、Skill、Agent 三层的发现入口和轻量维护 gate 同时可执行。
