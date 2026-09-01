# Commercial Readiness

## Product Shape

- `Core`: outcome-first operating contract、领域路由和真实 correctness invariant。
- `Optional Ops`: memory、agent-flow、E2E、branch/trace/artifact 支撑能力。
- `Evidence`: 普通任务的直接工程结果；persistent/release 场景的 task-run、manifest 和 evidence index。
- `Packaging`: reproducible package script plus manifest and customer-facing docs。

## Delivery Tiers

| tier | scope | acceptance |
| --- | --- | --- |
| Starter | 根合同、领域规则、focused validation 与 release 入口 | `agent-maintain --mode release` |
| Professional | 加入客户需要的 memory/profile/review routing | Starter + 客户显式 profile smoke |
| Enterprise | 加入远端 object store、CI/nightly、审计报表和培训材料 | Professional + CI/nightly 绿灯 |

## Customer Handoff

1. 运行 `scripts/package-ai-dev-env.sh` 生成交付包。
2. 在交付包中阅读 `README.md`、`PACKAGING_MANIFEST.md`、`docs/OPERATIONS.md`。
3. 客户侧日常直接按 objective/acceptance criteria 工作；需要记录、跨会话或发布时再显式使用可选设施。
4. 发布前运行 `scripts/agent-maintain.sh --mode release`；只有稳定结论写入 memory。

## Non-Goals

- 不把历史调试日志、波形、rootfs、cache DB 或本地工具链作为默认交付物。
- 不承诺任意业务工程开箱即 full gate PASS；业务 profile 是交付后的 scoped add-on。
- 不把 DB、task-run、profile 或流程 marker 变成普通工程任务的许可层。
