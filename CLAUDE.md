# CLAUDE.md

> Claude Code / Claude 模型完整规范见 [`.github/AGENTS.md`](./.github/AGENTS.md)。
>
> 若当前运行环境只读取本文件、不继续跟随链接，则以下最小契约立即生效。

1. 使用中文；复杂任务先分析再动手。
2. 先按 `.github/instructions/agent-lightweight-workflow.instructions.md` 分类；review/analysis 只读相关源码/spec，不强制 DB、memory、task-run 或 guard。有落盘修改时使用 `scripts/agent-flow.sh`。
3. 跨模块或涉及 `>= 3` 个文件的任务，先摸清调用链、依赖关系和数据流，再改文件。
4. 修 bug 先定位 root cause，禁止症状级补丁；真正修改后必须给出验证证据。
5. 只把稳定跨会话结论写入 memory；task-run 按 none/compact/durable 保存确定性结果、修改目录、验证指针、工程决策轨迹和 bounded 日志。目标轮次结束时由 C 调度器执行选中门禁；约 40% 流程占用是非阻断复盘目标。
6. 固定输入与确定性 oracle 默认执行一次；只在显式不确定性、机器异常证据或用户要求时重复。独立审查只由高风险/发布/迁移/破坏性操作/正式架构晋级/用户要求触发，不由落盘或文件数触发。
7. 本仓库当前不通过 plugin / marketplace 传播工程规则；若要增强 Codex 的通用能力，应单独走 skills，而不是把工程约束混进插件入口。

请继续读取 [`.github/AGENTS.md`](./.github/AGENTS.md)。
