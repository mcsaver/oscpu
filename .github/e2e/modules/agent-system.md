# agent-system E2E Contract

- **范围**: `.github/AGENTS.md`、入口 shim、agents、instructions、memory、task-runs、e2e profile。
- **上游**: 用户目标、已有 memory、蓝图。
- **下游**: 所有模块 profile 与跨模块图。
- **L0 gate**: `e2e_agent_system_discovery` 检查规则入口、e2e 目录、task-run 模板和 memory。
- **L1 gate**: `agent-system` profile 列出全部 profile，证明配置可发现。
- **证据**: task-run report、dispatch-log、profile 列表、diff check。
- **升级路线**: 增加 profile schema 校验、重复 node 检测、agent/module 覆盖率检查。
