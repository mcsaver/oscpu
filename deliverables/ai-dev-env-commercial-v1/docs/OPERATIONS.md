# Operations

## Ordinary engineering

普通任务直接遵循 `.github/AGENTS.md`：检查相关调用链，实施改动，运行能判断 acceptance criterion 的
focused validation，然后报告结果。无需先运行 agent-flow、DB refresh、task-run 或 E2E profile。

## After changing maintenance scripts

```bash
scripts/agent-maintain.sh --mode final
```

## Before Delivery

```bash
scripts/agent-maintain.sh --mode release
```

## Memory Update Rule

- 只有稳定、跨会话仍有价值的事实才更新 `.github/memory/`。
- 整体替换 DB-backed stored document 时使用受保护的 update 路径，避免覆盖真实数据。
- 普通任务默认不创建 task-run；persistent/published 长跑与 release 才使用 durable evidence。

## Archive Rule

- 旧手工产物进入 `.github/archive/legacy-ai-dev-env-2026-06-13/`。
- `.github/task-runs` 不硬搬；需要历史 run 时再用索引或 API 查询。
- 大体积运行态 payload 进入 `.github/runtime-artifacts` 或外部 object store。
