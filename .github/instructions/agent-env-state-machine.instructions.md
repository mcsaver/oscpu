# Agent Environment State Compatibility

本文件为旧 state_traceback、agent-system profile 和已发布 task-run 提供兼容说明。日常工作不再要求
七状态 FSM、固定 traceback、Reviewer/Inspector 双角色或 rebuild matrix。

## Default recovery

新任务、上下文压缩或旧会话恢复时，按以下顺序重建状态：

1. primary objective；
2. 用户显式 acceptance criteria；
3. 实际 repository/worktree 状态；
4. 明确 hard constraints；
5. 当前 build/test/EDA evidence。

恢复后直接走 inspect → act → targeted validation → report。旧记录中的临时 plan_graph、authorization
phase、marker、seal、禁止继续或审计配额不会自动恢复；只有仍直接对应 hard invariant 的内容有效。

## Failure escalation

- 实现或验证失败：保留失败输出，提出一个可证伪的根因假设，回到最接近问题的源码、配置或输入。
- 结果矛盾、缺失或 verifier 异常：先隔离 runner/verifier 故障，再决定是否需要专项审计。
- acceptance criterion 仍不确定：增加一个能区分候选原因的定向检查，不无界扩图或重复命令。
- 范围扩大到破坏性、外部副作用、release/security 或用户选择：暂停并取得相应授权。
- 显式 persistent/published 长跑被中断、证据未完成或 cleanup 失败：记录 FAIL/GAP，不得推断 PASS。

普通失败不要求生成 task-run、state audit、独立 reviewer 或 inspector。

## Legacy artifacts

已存在的 durable/release/publication task-run 若其 schema 要求 state_traceback，可以继续写
state_sequence、current_state、failure_state、rollback_target 和 failure_reason；这些字段用于兼容旧
consumer，不是普通任务的 permission gate。

Reviewer/Inspector 只在高风险、难恢复、正式 Architecture/Pareto promotion、release、migration、
security、对外发布或用户明确要求时使用。审查者寻找实际反例、覆盖缺口和越级结论，不机械重跑同一
确定性命令。

agent-env-rebuild-matrix、state-traceability contract、state-audit 以及 agent-system 中对应节点只在明确
维护这些对象或兼容已发布证据时运行。它们不得阻止普通安全本地 inspect/edit/build/test/collect/analyze。
