# Packaging Manifest

## Active Delivery Surface

| path | purpose |
| --- | --- |
| `.github/ai-env/contracts/agent-env-policy.json` | 三层策略、权限、retention、CI/nightly 入口 |
| `.github/ai-env/contracts/agent-env-schema-contract.json` | SQLite schema/API contract |
| `.github/ai-env/contracts/agent-env-runtime-artifacts.json` | 源码面与运行态 artifact 边界 |
| `.github/ai-env/contracts/agent-env-delivery.json` | 商业交付 readiness contract |
| `.github/skills/agent-env-maintenance/SKILL.md` | 标准化维护规则 |
| `.github/e2e/profiles/agent-system.tsv` | 交付验收 profile |
| `scripts/agent-maintain.sh` | 维护总门禁 |
| `scripts/package-ai-dev-env.sh` | 可交付包生成器 |
| `deliverables/ai-dev-env-commercial-v1/` | 当前商业交付源文档、模板和验收定义 |
| `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/` | 本地生成包输出目录，不进入 Git |

## Excluded From Package

- `.github/task-runs/YYYY-*` 历史原始证据：保留在源工作区，用 DB/API 查询，不默认打包。
- `.github/cache/` SQLite runtime cache：可由备份或源环境重建。
- `.github/runtime-artifacts/` 重型运行态 payload：只保留 manifest/index 指针。
- `.github/archive/legacy-ai-dev-env-2026-06-13/` 旧手工包备份：不进入新版 active package。

## Package Build Rule

`scripts/package-ai-dev-env.sh` 从当前 live source 和 retained memory/log 边界生成 `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/`。包内应包含可读规则、契约、脚本、e2e profile、模板和交付文档，不携带旧手工输出或本机调试日志。
