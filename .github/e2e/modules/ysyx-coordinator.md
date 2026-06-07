# ysyx-coordinator E2E Contract

- **范围**: 总调度、静态图选择、动态图扩展、模块 handoff、完成判定。
- **上游**: 用户目标、AGENTS、蓝图、memory。
- **下游**: 所有模块 profile 与跨模块图。
- **L0 gate**: `ysyx-coordinator-contract` 检查 coordinator agent、蓝图和 profile root。
- **L1 gate**: 通过 `discovery` 和具体模块 profile 验证路由结果。
- **证据**: 选图说明、profile manifest、dispatch-log、完成前语义核对。
- **升级路线**: 增加“目标 -> profile”映射表和未覆盖 agent 检查。
