# Quality Gates

## Required Gates

| gate | proves |
| --- | --- |
| `report-audit` | 研究报告/改造矩阵要求均有状态、证据、验证命令 |
| `schema-audit` | DB runtime schema/API 与契约一致 |
| `artifact-audit` | 源码面与运行态 artifact 边界一致 |
| `delivery-audit` | 归档、交付目录、包脚本和 package surface 一致 |
| `trace-audit` | run-manifest、trace_id、DB evidence asset 链接一致 |
| `state-audit` | FSM、Reviewer/Inspector、state_traceback 一致 |
| `policy-audit` | 工具权限、MCP、retention、CI/nightly 一致 |
| `skill-audit` | Skill live rule pack 可读取且结构健康 |
| `branch-health-audit` | review routing 与 branch dashboard 一致 |
| `agent-system` profile | 交付系统真实可调度执行 |

## Completion Rule

不能只看单个 PASS。商业交付完成必须同时满足：

- 旧手工产物已归档，active roots 不再混杂旧 package。
- `deliverables/ai-dev-env-commercial-v1/package/ysyx-ai-dev-env-commercial/` 可重新生成。
- `scripts/agent-maintain.sh --mode check` PASS。
- 至少两轮 `agent-system` delivery task-run PASS，并带 `delivery-audit` evidence。
