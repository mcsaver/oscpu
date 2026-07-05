---
name: module-level-implementation
description: "用户要求按模块/子系统整体实现(FP 整体/前端 F2 整体/LSQ 整体),不要一刀一刀切片"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

rv64core 的架构改造按**模块/子系统粒度整体实现**:FP 簇一次成型(rename+IQ+执行+commit+拆 pending 全家)、前端 F2 整体重构、LSQ 整体实现——不要按小切片(Phase 0/1/2、地基/接线/切换)多刀推进。

**Why:** 用户明确指出(2026-07-02):一刀一刀太慢,且可能"局部实现而整体架构没有实现"——陷入局部最优、中间态脚手架拖累整体(例:FP Phase 0 会让 FP 挂在 pending 上进 ROB 的过渡态存在数天)。

**How to apply:** 动手前把子系统的目标态(宪法 §8.4)一次设计定型,实现按依赖内聚推进(基础件→接入→拆除旧路径),中间用编译点控质量,**最终一次性全绿验证+一次 commit**(最多基础件/接入两次);不为中间态写行为中性开关/影子层,除非验证策略必需。相关 [[lsq-sq-switch-landed]] [[ooo-core-architecture-constitution]]。
