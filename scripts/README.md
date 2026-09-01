# Scripts

`scripts/` 保留稳定入口和必要的内部实现。外部 agent 优先调用稳定入口，不直接依赖内部函数路径。

## 稳定入口

- `scripts/agent-flow.c` / `scripts/agent-flow.sh`：可选的任务生命周期、显式检查和结果留档工具。路径只做
  记录，不自动选择检查；archive 默认 `none`，零检查完成明确为 `FINISHED_NO_GATES`，不宣称工程 PASS。
- `scripts/agent-maintain.sh`：`quick` 只做维护入口与定向测试的 shell 语法检查；`final` 是 AI 环境 PR 的
  代表性测试集，覆盖 operating contract 场景/mutation、controller、persistent 状态、硬件/release
  hard invariant、专家路由、可选 RTL handoff、JSON 与 profile 绑定；`release/full` 才进入 DB、publication
  和商业交付边界。
- `scripts/agent-e2e.sh`：显式 e2e/release profile 调度器和 validator；默认 compact/direct，不刷新 DB、
  不用 task slug 做 recall gate、不生成 SHA/publication。`--publish` 才启用 durable 发布闭包；strict guard
  只用于 release/迁移并显式提供 paths-file/path，不扫描 Git 工作树。
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

## 常用入口

```bash
scripts/agent-flow.sh begin --task <id> --class development
scripts/agent-flow.sh record --task <id> --path <changed-path>
scripts/agent-flow.sh finish --task <id>
scripts/agent-flow.sh record --task <id> --gate <explicit-check>
scripts/agent-maintain.sh --mode quick
scripts/agent-maintain.sh --mode final
scripts/agent-maintain.sh --mode release
scripts/agent-e2e.sh --profile <profile>
scripts/agent-e2e.sh --profile <profile> --publish
scripts/agent-e2e.sh --guard --paths-file <paths.log>
scripts/agent-e2e.sh --guard --guard-mode strict --paths-file <paths.log>
```

普通开发不需要使用这些 lifecycle/profile 入口。只有明确需要所选检查的 scoped PASS 时才登记 `--gate`；
`--candidate` 用于显式高风险或发布候选复核，不能对零检查记录生成 PASS。guard 默认 warn；最后一条
strict 示例只用于 release/migration/security/forensic。

`scripts/tests/test-agent-operating-contract.py` 使用 10 个代表性行为场景和 10 个定向 mutation 检查通用
合同；每个 mutation 都对应一次可能把普通任务重新变成 gate-heavy，或把 destructive、RTL/PPA、release
等真实硬边界削弱的 false PASS。它只在 AI 环境维护套件中运行，不是普通业务任务的前置门。

不要把运行日志、包输出、cache DB 或大体积 evidence 写入 `scripts/`。
