# Scripts

`scripts/` 保留稳定入口和必要的内部实现。外部 agent 优先调用稳定入口，不直接依赖内部函数路径。

## 稳定入口

- `scripts/agent-maintain.sh`：AI 环境维护总门禁。
- `scripts/agent-e2e.sh`：e2e profile 调度器、profile validator，以及收尾 evidence/DB recall guard（`--guard --guard-mode strict`，检查 completed report、`context-brief.md`、`profile-resolve.md`、`evidence-index.md`；拒绝冲突、重复、非有限数、无时区与 symlink manifest，并按 UTC 微秒选择最新的 manifest/report 语义完成时间，绝不使用文件 mtime）。
- `scripts/package-ai-dev-env.sh`：商业交付包生成器，输出到 `dist/ai-dev-env-commercial-v1/package/`。
- `scripts/github_index_db.py`：SQLite index、retained memory/log 和 evidence CLI wrapper。
- `scripts/agent-env.sh`、`scripts/agent-run.sh`：非交互运行环境入口。

## 内部实现

- `scripts/build.mk`：工作区级通用工具构建模板，供 `tool/kconfig`、`tool/fixdep` 等跨工程工具使用；
  不承载 NEMU 专有构建语义。
- `scripts/dev_memory/`：SQLite index、memory/log stored document、audit、rehydrate、evidence asset 实现。
- `scripts/e2e/`：e2e profile 执行库、模块 gate 和 task-run report 逻辑。

## 常用 Gate

```bash
python3 scripts/github_index_db.py audit-db-first
python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-e2e.sh --guard --guard-mode strict
scripts/agent-maintain.sh --mode check
```

不要把运行日志、包输出、cache DB 或大体积 evidence 写入 `scripts/`。
