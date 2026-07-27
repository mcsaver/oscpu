# V9P completion definition

## Parent

- parent RTL design-id:
  `sha256:08d3d8648251f8fd430d0a9bcac289335f5dfb99a0a235531766e3c7f8048c6a`
- parent architecture state:
  `CONTROL-EVENT-G1` current-design local CLOSED；full-core 仍为 GAP/PPA UNQUALIFIED。

## Complete design point

只有同时满足以下条件，才允许把 V9P 称为 SERIALIZE-G1 current-design 闭合：

1. `OOO_CSR_QUEUE_HEAD` 默认配置在 RTL、NPC 构建和 Linux 构建入口一致；
2. 合法 head0 非 FP CSR 的 dispatch→ROB→C0→C1→CSR write→younger refetch 周期合同
   在 spec 和立即断言中一致；
3. FP CSR 与其它 pending-system 类型的 owner/type/clear/recovery 路径没有被 queue-head 默认值破坏；
4. current-design focused、完整 module inventory、compile-success RTL 源码变体、330 项
   riscv-tests full-state DiffTest 和适用 Linux gate 均有同源证据；
5. SERIALIZE-G1 账本记录绑定 current design、验证来源与 evidence SHA；
6. full-core candidate、剩余 blocker 与 PPA 资格保持诚实边界。

## Intermediate checkpoints

- 只读架构复核；
- 默认值改动后的 focused/module 回归；
- 330 项 full-state 功能门（当前 PASS）与 Linux rootfs gate；
- evidence/ledger refresh。

任一中间 checkpoint 均不得单独进入 PPA promotion。
