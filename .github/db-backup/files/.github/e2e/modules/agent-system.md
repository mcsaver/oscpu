# agent-system E2E Contract

- **范围**: `.github/AGENTS.md`、入口 shim、agents、instructions、memory、task-runs、e2e profile、非交互软环境入口。
- **上游**: 用户目标、已有 memory、蓝图。
- **下游**: 所有模块 profile 与跨模块图。
- **L0 gate**: `e2e_agent_system_discovery` 检查规则入口、e2e 目录、task-run 模板、memory、`scripts/agent-env.sh` 与 runner source hook、半初始化 `YSYX_AGENT_ENV_SOURCED` 继承自修复钩子、外层工具控制符命令卫生文档钩子（例如 `rg -e` 替代正则中的 `|`）、Codex/WSL single-flight 文档钩子（不要并发启动多个 `wsl.exe` 做工程命令；`Wsl/Service/E_UNEXPECTED` 先按宿主 WSL 健康问题处理；工程命令回到 `scripts/agent-run.sh` 入口）、持久 agent/e2e 源文件是否已被 Git 跟踪，以及 `report.sh` 的 context brief、task-run 文本 artifact sanitizer 和 Markdown DB 归档 hook 是否定义、调用并限制在当前 run dir。
- **L1 gate**: `agent-system` profile 列出全部 profile，证明配置可发现。
- **证据**: task-run context-brief、report、dispatch-log、profile 列表、agent-env PASS marker、sanitizer PASS marker、task-run Markdown DB 归档 marker、diff check。
- **升级路线**: 增加 profile schema 校验、重复 node 检测、agent/module 覆盖率检查。
