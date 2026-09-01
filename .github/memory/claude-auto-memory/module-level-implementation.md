---
name: module-level-implementation
description: "架构级重构应围绕完整子系统目标态；局部修复可按最小正确边界落地，不绑定 commit 数"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

rv64core 的**架构级改造**应先定义模块/子系统目标态，并按依赖内聚地实现，避免长期留下行为开关、影子
层或职责一半新一半旧的中间架构。FP 簇、前端 F2、LSQ 的历史改造体现了这一经验。

**Why:** 用户明确指出(2026-07-02):一刀一刀太慢,且可能"局部实现而整体架构没有实现"——陷入局部最优、中间态脚手架拖累整体(例:FP Phase 0 会让 FP 挂在 pending 上进 ROB 的过渡态存在数天)。

**How to apply:** 跨流水/跨事务生命周期的架构重构先定义目标态与接口不变量，再按可验证依赖推进；局部
bug、单模块修复或 focused experiment 可以在最小正确边界完成。验证规模由 acceptance 与影响面决定，
commit 的数量、时机和 ownership 由当前用户工作流决定，不是工程 correctness gate。相关
[[lsq-sq-switch-landed]] [[ooo-core-architecture-constitution]]。
