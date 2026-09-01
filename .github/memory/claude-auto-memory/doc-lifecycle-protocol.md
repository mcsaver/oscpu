---
name: doc-lifecycle-protocol
description: 历史文档生命周期 workflow；普通任务只维护直接受影响文档，全量审计与固定归档手续按需
metadata: 
  node_type: memory
  type: project
  originSessionId: 6df78c86-b219-41be-9245-66df2198fbd6
---

> **历史 / 部分 superseded（2026-08-23）**：下面记录 2026-07-03 建立过的完整 workflow，不能作为
> 普通任务的收尾 gate、task-run 要求或全量文档审计授权。

当时把文档生命周期做成 agent 系统能力，曾三层落地：

1. **规则单源**: `.github/instructions/doc-lifecycle.instructions.md` —— 文档类型分类
   (normative/spec/plan/snapshot/index/memory/task-run)、状态模型(ACTIVE→⚠️死硅注记→
   ARCHIVED{SUPERSEDED/ORPHAN})、**归档五步手续**(git mv→history README 登记表→悬空引用
   grep 清零→索引同步→task-run 固化)、§4 迁移触发点(删模块→spec 归档/机制判死→注记/
   计划落地→同刀归档/新快照→旧快照归档)。
2. **可执行**: `.claude/workflows/doc-lifecycle-audit.js` 命名工作流(盘点 agent 动态发现
   文档并分组→并行审计对照代码→就地校正+归档队列)。args={roots,truth,groupSize}。
   注意: 命名注册表会话启动时扫描,同会话新建文件用 scriptPath 调用。
3. **入口挂钩（已取代）**: 旧 AGENTS/CLAUDE 合同曾把每次完成前的生命周期核对设为硬义务。

**当前适用方式**：修改、移动或删除实现时，维护直接依赖该事实的 active spec/index，并修复本次改动
实际造成的悬空引用；这属于工程 correctness。只有文档体系本身开发、显式 migration/release/publication、
大规模归档或用户要求时才运行全量 `doc-lifecycle-audit`。普通代码修复不需要固定五步、全仓 grep、
task-run 或额外 commit 才能完成。
关联 [[rv64core-audit-baseline]] [[ooo-core-architecture-constitution]]。
