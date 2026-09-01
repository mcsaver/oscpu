---
name: doc-dependency-direction-law
description: "稳定规则不应只依赖易归档产物；旧绝对禁引与固定收尾动作已 superseded"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b32703f1-8f29-4fd8-b3c4-6fea520cb3a3
---

> **部分 superseded（2026-08-23）**：旧条目把文档分层写成绝对“铁律”并绑定固定 lifecycle 收尾；
> 当前只保留避免 active normative 规则悬空的工程原则。

稳定 instruction、架构 contract 或 active index 不应把唯一规范语义寄托在会归档的临时 plan/task-run 上。
需要长期生效的约束应在稳定文档中自包含；历史 task-run 可以作为来源或证据链接，但不能因此成为当前
授权、完成 gate 或必须复跑的流程。

**Why**: 文档分两层生命周期——常驻层伴随工作区**一直进化**; 任务层(spec/plan/task-run)任务完成后**释放归档进 history**。依赖方向只能「任务层 → 常驻层」; 反向 = 长命依赖短命, 被依赖件一归档、常驻层就留**悬空引用**(自相矛盾: 一边固化规则一边从源头制造悬空)。用户 2026-07-06 当场指正:"spec 里的东西是有生命周期的、完成后归 history, 而 interface-contract 这类 instructions 要一直伴随工作区进化"。

**How to apply**:
- 本轮若改变某项规范语义，把必要约束写进其稳定 owner 文档，并更新直接相关引用。
- 证据链接可指向历史 spec/task-run，但 active 规则应在链接失效时仍能说明核心不变量。
- 不为每次编辑机械执行全量依赖审计；只有实际移动/归档、文档 migration 或 publication scope 才扩大检查。

关联 [[doc-lifecycle-protocol]] · [[encoding-zero-area-debug-two-tier]] · [[workspace-artifacts-not-tool-dir]]。
