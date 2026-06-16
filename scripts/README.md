# Scripts

`scripts/` 保留稳定入口和必要的内部实现。外部 agent 优先调用稳定入口，不直接依赖内部函数路径。

## 稳定入口

- `scripts/agent-maintain.sh`：AI 环境维护总门禁。
- `scripts/agent-e2e.sh`：e2e profile 调度器和 profile validator。
- `scripts/package-ai-dev-env.sh`：商业交付包生成器，输出到 `dist/ai-dev-env-commercial-v1/package/`。
- `scripts/github_index_db.py`：SQLite index、retained memory/log 和 evidence CLI wrapper。
- `scripts/agent-env.sh`、`scripts/agent-run.sh`：非交互运行环境入口。

## 内部实现

- `scripts/dev_memory/`：SQLite index、memory/log stored document、audit、rehydrate、evidence asset 实现。
- `scripts/e2e/`：e2e profile 执行库、模块 gate 和 task-run report 逻辑。

## 常用 Gate

```bash
python3 scripts/github_index_db.py audit-db-first
python3 scripts/github_index_db.py audit-markdown-coverage --fail-on-live-evidence
scripts/agent-e2e.sh --validate-all-profiles
scripts/agent-maintain.sh --mode check
```

不要把运行日志、包输出、cache DB 或大体积 evidence 写入 `scripts/`。
