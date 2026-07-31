# Scripts

`scripts/` 保留稳定入口和必要的内部实现。外部 agent 优先调用稳定入口，不直接依赖内部函数路径。

## 稳定入口

- `scripts/agent-flow.c` / `scripts/agent-flow.sh`：日常任务分类、显式修改路径、工程决策轨迹、
  约 40% 非阻断占用观测和 compact/durable task-run 的默认入口；C 只调用固定 gate pointer。
- `scripts/agent-maintain.sh`：AI 环境 `quick/final/release/full` 分层门禁。
- `scripts/agent-e2e.sh`：真实 e2e profile 调度器和 validator；strict guard 只用于 release/迁移，
  必须显式提供 paths-file/path，不扫描 Git 工作树。
- `scripts/package-ai-dev-env.sh`：商业交付包生成器，输出到 `dist/ai-dev-env-commercial-v1/package/`。
- `scripts/github_index_db.py`：SQLite index、retained memory/log 和 evidence CLI wrapper。
- `scripts/agent-env.sh`、`scripts/agent-run.sh`：非交互运行环境入口。

## 内部实现

- `scripts/build.mk`：工作区级通用工具构建模板，供 `tool/kconfig`、`tool/fixdep` 等跨工程工具使用；
  不承载 NEMU 专有构建语义。
- `scripts/dev_memory/`：SQLite index、memory/log stored document、audit、rehydrate、evidence asset 实现。
- `scripts/e2e/`：e2e profile 执行库、模块 gate 和 task-run report 逻辑。
- `scripts/e2e/lib/common.sh` 的文件标记查询必须在 `pipefail` 下保持精确；不得使用会因 `grep -q`
  提前命中而把 producer `SIGPIPE` 误报成 false negative 的管道。

## 常用 Gate

```bash
scripts/agent-flow.sh classify
scripts/agent-flow.sh finish --task <id> --candidate
scripts/agent-maintain.sh --mode quick
scripts/agent-maintain.sh --mode final
scripts/agent-maintain.sh --mode release
scripts/agent-e2e.sh --guard --guard-mode strict --paths-file <paths.log>
```

不要把运行日志、包输出、cache DB 或大体积 evidence 写入 `scripts/`。
