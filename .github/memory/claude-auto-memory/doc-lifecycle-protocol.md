---
name: doc-lifecycle-protocol
description: 工作区文档生命周期协议已固化——完成任务前必须推进受影响文档状态;全量重审有命名工作流
metadata: 
  node_type: memory
  type: project
  originSessionId: 6df78c86-b219-41be-9245-66df2198fbd6
---

用户要求(2026-07-03)把文档生命周期做成 agent 系统常备能力,已三层落地:

1. **规则单源**: `.github/instructions/doc-lifecycle.instructions.md` —— 文档类型分类
   (normative/spec/plan/snapshot/index/memory/task-run)、状态模型(ACTIVE→⚠️死硅注记→
   ARCHIVED{SUPERSEDED/ORPHAN})、**归档五步手续**(git mv→history README 登记表→悬空引用
   grep 清零→索引同步→task-run 固化)、§4 迁移触发点(删模块→spec 归档/机制判死→注记/
   计划落地→同刀归档/新快照→旧快照归档)。
2. **可执行**: `.claude/workflows/doc-lifecycle-audit.js` 命名工作流(盘点 agent 动态发现
   文档并分组→并行审计对照代码→就地校正+归档队列)。args={roots,truth,groupSize}。
   注意: 命名注册表会话启动时扫描,同会话新建文件用 scriptPath 调用。
3. **入口挂钩**: AGENTS.md §7 + CLAUDE.md 契约第 5 条——**声明任务完成前必须核对文档
   生命周期触发点**,这对我是硬义务。

**How to apply**: 每次改 RTL/删模块/落地计划后,同刀处置对应文档;归档后必跑悬空引用
grep(12 份归档曾产生 10 处悬空引用的实测教训);大改后跑
`Workflow({name:"doc-lifecycle-audit", args:{roots:[...]}})`。
关联 [[rv64core-audit-baseline]] [[ooo-core-architecture-constitution]]。
