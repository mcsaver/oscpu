# agent-system E2E Contract

本 profile 是显式的 AI 环境/release 自检，不是普通开发、文档修改或环境编辑的默认收尾。

## Acceptance criteria

- 通用入口都回链 `.github/AGENTS.md`，且日常路径是 objective → acceptance criteria → safe local work →
  minimum sufficient validation → report。
- `agent-flow` 只执行显式 gate；路径不自动派生 gate，零 gate finish 不声明工程 PASS，task-run 默认关闭。
- PR 只做轻量入口检查；nightly/manual release 显式运行 release suite。
- runtime payload 不混入 active source；显式 persistent longrun 的中断或不完整结果不得 PASS。
- 商业 package/publication 被明确选择时，由 `scripts/agent-maintain.sh --mode release` 执行 manifest、完整性和交付检查。

## Nodes

- `operating-contract`：检查顶层规则、薄入口、轻量工作流、policy、controller 和 CI 的新默认语义，并用
  代表性场景覆盖普通修复、最小充分验证、硬件 correctness、verifier 异常、破坏性动作、compaction、
  hash/persistence、并发资源、严格例外和高信号汇报。
- `runtime-artifact-boundary`：检查显式持久化时的 source/runtime 分层。
- `rtl-task-contract`：仅在显式本地 RTL 交接工具被纳入 profile 时检查其生成/校验能力；它不授权普通
  RTL build/test。
- `task-run-status-fail-closed`：验证显式 persistent/published 长跑的完成状态。
- `profile-index`：列出可用 profile。

商业交付不属于基础 `agent-system` profile；它只在显式 release/商业发布命令中运行，避免 profile 与
release suite 重复构建和重复审计同一产物。

profile 内的 hash、manifest、publication 和完整 evidence bundle 只服务该显式 e2e/release 边界，不能
反向传播成普通任务的前置条件。每个节点只声明自身观察范围，不用低层 PASS 外推业务 RTL、Linux、
Ubuntu、系统签核或 PPA 结论。
