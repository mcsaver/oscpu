---
name: coremark-10-iterations
description: "用户要求 CoreMark 测试仅跑 10 次迭代即可,不必跑太多次"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2308cc05-b4f1-42ae-9110-1dbbdc38b531
---

CoreMark 验证时只运行 10 次迭代(iterations=10),不要跑完整/大量迭代。

**Why:** 完整 CoreMark 迭代数在 RTL 仿真下耗时过长;10 次已足以覆盖正确性(difftest/GOOD TRAP)与稳态性能采样。

**How to apply:** 跑 npc/rv64 的 CoreMark 验证(正确性或 IPC 对比)时,把迭代次数设为 10(CoreMark 的 ITERATIONS 编译参数或运行配置),PASS + 计数器采样即可收工。相关 [[coremark-mode1-spec-wrongpath]]。
