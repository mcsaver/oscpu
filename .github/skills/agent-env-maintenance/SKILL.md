---
name: agent-env-maintenance
description: 维护 YSYX AI 开发环境三层架构时使用：数据库长期记忆层、Skill 标准化规则层、Agent 自动维护流程；适用于 DB-first shim、stored document、e2e profile、task-run 证据、规则漂移、商业交付包、环境自检和 agent-system 重构。
---

# Agent Env Maintenance

使用本 skill 时，把工作区 AI 环境固定拆成三层：

- 数据库层：长期记忆、stored documents、task-run/evidence 索引、runtime artifact 指针、DB-first shim、schema/API contract 和 observability trace manifest。入口是 `scripts/github_index_db.py`、`scripts/dev_memory/`、`.github/agent-env-schema-contract.json`、`.github/agent-env-observability.json`、`.github/agent-env-runtime-artifacts.json`。
- Skill 层：可直接读取的标准化处理规则。入口是 `.github/skills/*/SKILL.md` 和必要的 `.github/instructions/*.instructions.md`。
- Agent 层：自动维护流程、profile 调度、图任务记录、review routing、branch-health dashboard、state traceback、Reviewer/Inspector gate、商业交付包和 e2e 证据包。入口是 `.github/agents/*.agent.md`、`.github/agent-env-policy.json`、`.github/agent-env-rebuild-matrix.json`、`.github/agent-env-review-routing.json`、`.github/agent-env-branch-health.json`、`.github/agent-env-state-traceability.json`、`.github/agent-env-delivery.json`、`scripts/package-ai-dev-env.sh`、`scripts/agent-e2e.sh`、`scripts/agent-maintain.sh`。

## 工作流

1. 先加载 DB-backed 基线：`.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/modules/agent-system.md`、`.github/agentic-hardware-blueprint.md`。
2. 判断改动属于哪一层。长期事实写入数据库/记忆；可复用流程写入 Skill 或 instruction；自动执行与证据收集写入 Agent/e2e/profile。
3. 修改 Skill 时保持 `SKILL.md` live 可读，不迁成 DB-backed shim；修改 instructions、agents、memory、e2e profile 时遵循仓库的 DB-first 写回流程。
4. 修改报告要求、验收状态或剩余路线图时同步 `.github/agent-env-rebuild-matrix.json`，并确认 `python3 scripts/github_index_db.py report-audit` 通过。
5. 修改数据库 schema、实体映射或 JSON API 时同步 `.github/agent-env-schema-contract.json`，并确认 `python3 scripts/github_index_db.py schema-audit` 通过。
6. 修改 trace-id、run manifest、telemetry 或 evidence 汇聚口径时同步 `.github/agent-env-observability.json`，并确认 `python3 scripts/github_index_db.py trace-audit` 通过；生成新 task-run 后用 `trace-audit --run-id <run_id>` 验证 manifest 已被 DB evidence asset 索引。
7. 修改 FSM、回退、Reviewer/Inspector、状态回溯或 profile 审稿节点时同步 `.github/agent-env-state-traceability.json`，并确认 `python3 scripts/github_index_db.py state-audit` 通过；生成新 task-run 后用 `state-audit --run-id <run_id>` 验证 `state_traceback`。
8. 修改 runtime artifact/source 边界、大体积日志、波形、镜像或 raw evidence retention 时同步 `.github/agent-env-runtime-artifacts.json`，并确认 `python3 scripts/github_index_db.py artifact-audit` 通过；生成新 task-run 后用 `artifact-audit --run-id <run_id>` 验证 raw evidence 只进入 `evidence_assets` 索引。
9. 修改商业交付面、旧产物归档、包内容或包内敏感路径规则时同步 `.github/agent-env-delivery.json`，运行 `scripts/package-ai-dev-env.sh`，并确认 `python3 scripts/github_index_db.py delivery-audit` 通过。
10. 修改 agent 权限、retention、CI/nightly、FSM、交付或证据策略时同步 `.github/agent-env-policy.json`，并确认 `python3 scripts/github_index_db.py policy-audit` 通过。
11. 修改 review 路由、分支健康或 dashboard 口径时同步 `.github/agent-env-review-routing.json` 与 `.github/agent-env-branch-health.json`，并确认 `python3 scripts/github_index_db.py branch-health-audit` 通过。
12. 维护完成后运行 `scripts/agent-maintain.sh --mode check`。若触及 e2e/profile/脚本，再运行相关 `scripts/agent-e2e.sh --profile <profile>`。
13. 最后更新 `project-status` 与 `memory/modules/agent-system.md`，并为跨层任务留下 `.github/task-runs/<日期-任务名>/` 证据包。

## 边界

- 不把数据库快照当作当前 active Skill。
- 不把 Skill 写成超长全局提示词；复杂细节放入 scripts、instructions 或 DB-backed reference。
- 不用单个 Agent profile 承担数据库、规则、执行、记录四类职责；需要拆成图节点。
- 不让 raw evidence Markdown 长期滞留在 live 工作区；保留摘要索引和 DB-backed task-run Markdown，原始日志只作为 evidence asset 被索引；大体积日志、波形、镜像和 volatile payload 必须进入 `.github/runtime-artifacts` 或外部 object store 指针边界。
- 不把历史 memory 全量、`__pycache__`、本机绝对路径、私有 token 前缀或手工旧产物放进商业交付包；商业包必须由 `scripts/package-ai-dev-env.sh` 生成并通过 `delivery-audit`。
- 不把 `partial` 或 `planned` 的报告矩阵项目描述成已经完成；最终完成前必须逐项对照矩阵审计。
