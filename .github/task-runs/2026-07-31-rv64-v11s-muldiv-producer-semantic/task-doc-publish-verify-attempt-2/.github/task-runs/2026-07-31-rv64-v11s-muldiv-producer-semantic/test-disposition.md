# V11S test disposition

## PASS

- `V11S_MULDIV_PRODUCER_FOCUSED`
  - `[V11S-MULDIV-BIRTH][PASS]`
  - `[V11S-MULDIV-HOLD][PASS]`
  - `[V11S-MULDIV-WRONG-GEN][PASS]`
  - `[V11S-MULDIV-TERMINAL][PASS]`
  - `[V11S-MULDIV-FLUSH][PASS]`
  - `[V11S-MULDIV-PRODUCER-MATRIX][PASS]`
- production baseline：4/4。
- compile-success mutation：9 类 × 2 generation width，18/18 均在声明
  stage 被独立 oracle 拒绝。
- ordinary regression：4/4。
- runner unit：10/10。
- instance-graph unit：19/19。
- V11H replay unit：6/6。
- semantic-ledger unit：85/85。
- combined graph/census/replay/ledger gate：`rc=0`，19/19、15/15、91/91。

## 保留的 GAP

- semantic ledger 仍为 `GAP`，35 PASS / 9 GAP。
- whole architecture=`RED`，PPA=`UNPROMOTED`。
- product-path 动态负测未单独枚举 exact-open 的 vacant/done-closed 全矩阵，
  也未让强制 wrong-generation response 完成真实 handshake。
- product-path 代表 opcode 为 MUL、DIVU；其它 MulDiv opcode 依赖共享身份
  控制结构与 leaf functional regression。
- selective kill 的细粒度场景主要由 leaf TB 覆盖；product instance 聚焦
  full flush。
- 未运行 formal、完整系统、综合、STA、功耗或 PPA。

## A3

- 原始 full-system `FAIL rc=1` 与 strict 16/17 保持不变。
- checker replay 只在冻结 dmesg/console 输入上证明旧 oracle 将
  `printk: debug:` 误判；真实 `BUG:` fixture 仍被拒绝。
- A3 只解释为
  `A3_SYSTEM_TRANSACTION_COMPLETE_LEGACY_ORACLE_FALSE_POSITIVE`。

