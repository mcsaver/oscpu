# Commercial Readiness

## Product Shape

- `Core`: Database/Skill/Agent 三层 AI 开发环境。
- `Ops`: `agent-maintain`、branch-health、state/trace/artifact/delivery audit。
- `Evidence`: task-run report、dispatch log、run manifest、evidence index。
- `Packaging`: reproducible package script plus manifest and customer-facing docs。

## Delivery Tiers

| tier | scope | acceptance |
| --- | --- | --- |
| Starter | 规则发现、DB memory、Skill、基础 agent-system gate | `delivery-audit` + `agent-maintain --mode check` |
| Professional | 加入客户模块 profile、review routing、branch dashboard | Starter + 客户 profile smoke |
| Enterprise | 加入远端 object store、CI/nightly、审计报表和培训材料 | Professional + CI/nightly 绿灯 |

## Customer Handoff

1. 运行 `scripts/package-ai-dev-env.sh` 生成交付包。
2. 在交付包中阅读 `README.md`、`PACKAGING_MANIFEST.md`、`docs/OPERATIONS.md`。
3. 客户侧先跑 `scripts/agent-maintain.sh --mode check`，再按目标工程接入 domain-specific profile。
4. 所有客制化变更必须新增 task-run 证据并写入 memory。

## Non-Goals

- 不把历史调试日志、波形、rootfs、cache DB 或本地工具链作为默认交付物。
- 不承诺任意业务工程开箱即 full gate PASS；业务 profile 是交付后的 scoped add-on。
- 不用旧手工 PPT/便携包替代当前 DB/Skill/Agent 三层系统。
