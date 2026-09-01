# Packaging Manifest

## Active Delivery Surface

| path | purpose |
| --- | --- |
| `.github/AGENTS.md` | 目标优先、最小充分验证与安全边界的通用真源 |
| `.github/ai-env/contracts/agent-env-policy.json` | 可选设施、retention、PR/release 入口的机器说明 |
| `.github/ai-env/contracts/agent-env-schema-contract.json` | SQLite schema/API contract |
| `.github/ai-env/contracts/agent-env-runtime-artifacts.json` | 源码面与运行态 artifact 边界 |
| `.github/ai-env/contracts/agent-env-delivery.json` | 商业交付 readiness contract |
| `.github/ai-env/contracts/agent-env-rtl-task-contract.json` | legacy RTL handoff 的可选机器交换格式 |
| `.github/skills/agent-env-maintenance/SKILL.md` | 标准化维护规则 |
| `.github/skills/prepare-rtl-task-contract/` | RTL 子任务契约生成、校验、渲染与前向使用规则 |
| `.github/e2e/profiles/agent-system.tsv` | 交付验收 profile |
| `scripts/agent-flow.c` / `scripts/agent-flow.sh` | 显式 opt-in 的任务记录与 selected-check controller |
| `scripts/agent-maintain.sh` | 轻量 PR 检查与显式 commercial release 入口 |
| `scripts/package-ai-dev-env.sh` | 可交付包生成器 |
| `deliverables/ai-dev-env-commercial-v1/` | 当前商业交付源文档、模板和验收定义 |
| `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/` | 本地生成包输出目录，不进入 Git |

## Excluded From Package

- `.github/task-runs/YYYY-*` 历史原始证据：保留在源工作区，用 DB/API 查询，不默认打包。
- `.github/cache/` SQLite runtime cache：可由备份或源环境重建。
- `.github/runtime-artifacts/` 重型运行态 payload：只保留 manifest/index 指针。
- `.github/archive/legacy-ai-dev-env-2026-06-13/` 旧手工包备份：不进入新版 active package。

## Package Build Rule

`scripts/package-ai-dev-env.sh` 从当前 live source 生成 `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/`。
包内包含根合同、领域规则、可选工具、release profile、模板和交付文档，不携带历史 task-run、旧手工输出
或本机调试日志。
