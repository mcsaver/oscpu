# Quality Gates

## Pull-request checks

AI 环境相关 PR 运行 shell syntax、C controller 定向自测、contract JSON 解析和 profile 绑定校验。它不刷新
DB、不打包、不发布 evidence，也不运行业务 RTL/Linux/PPA gate。

## Explicit release checks

| gate | proves |
| --- | --- |
| `agent-maintain final` | shell、controller、JSON 与 profile 绑定健康 |
| `report-audit` | 显式交付报告合同可解释 |
| `schema-audit` | DB runtime schema/API 与契约一致 |
| `artifact-audit` | 源码面与运行态 artifact 边界一致 |
| `delivery-audit` | 归档、交付目录、包脚本和 package surface 一致 |
| `trace-audit` | run-manifest、trace_id、DB evidence asset 链接一致 |
| `policy-audit` | 工具权限、MCP、retention、CI/nightly 一致 |
| `skill-audit` | Skill live rule pack 可读取且结构健康 |
| `branch-health-audit` | review routing 与 branch dashboard 一致 |
| published `agent-system` profile | release 支撑系统真实可调度并发布 |

## Completion Rule

不能只看单个 PASS。商业交付完成必须同时满足：

- 旧手工产物已归档，active roots 不再混杂旧 package。
- `dist/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/` 可重新生成。
- `scripts/agent-maintain.sh --mode release` PASS；该单一入口恰好执行一次 published `agent-system` profile，
  然后完成 package 与 `delivery-audit`。
