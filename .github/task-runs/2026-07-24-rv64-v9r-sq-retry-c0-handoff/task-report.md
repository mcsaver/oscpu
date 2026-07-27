# V9R SQ-query retry C0 交接报告

## 根因与 RTL 修正

C0 周期内 `control_full_flush_barrier_w=1` 已经关闭 dispatch、memory issue、
response credit 与 bridge pre-owner launch，但 backend 两个 SQ-query retry
READY 方程和 bridge 的 `sq_query_retry_fire_w` 方程没有读取该 barrier。精确
replay query 因而可能在 C0 建立 MIQ→retry holder 交接，而 bridge
`S_SQ_QUERY` 的 edge-old owner 同时保持。

- `OooIntBackend`：bank0/bank1 retry READY 增加
  `!control_full_flush_barrier_w`；V8T progress assertion 排除该合法暂停；
  V9R assertion 拒绝 C0 上的 READY/capture 暴露。
- `OooMemAxiBridge`：retry fire 增加
  `!control_full_flush_barrier_i`；V9R assertion 拒绝 C0 上的 owner release。
- 该修正不新增寄存器、队列项、owner token、AXI channel gate 或仲裁级，
  因而不单独宣称面积、频率或功耗收益。

## 全顶层 EDA 收口

当前完整 `NpcSimTop + OOO_ASSERT` 构建最初把 121 条 Verilator warning
视为 fatal：112 条模块 timebase、4 条 assertion scratch-counter blocking
assignment、1 条仿真计数器 declaration initializer，以及 SQ forwarding
组合块的 4 条真实 latch 诊断。

- `npc/rv64/Makefile` 对完整构建和 lint 统一指定 `--timescale 1ns/1ps`。
- 两个 SQ forwarding 组合块为属性局部量补齐默认赋值，消除真实 latch。
- `OooMemOwnerTracker` 用无状态计数函数替代时钟过程内的 blocking scratch
  counter；`NpcSimTop` 用显式 sim-only `initial` 保留确定的 time-0 初值。
- `OooSv39Tlb` 与 `OooDataWordCache` 的私有函数采用模块限定命名，消除全顶层
  名称遮蔽诊断；跨段 net 声明前置但保持原驱动关系。
- `make -C npc/rv64 lint` 以及完整 `NpcSimTop + OOO_ASSERT` 生成、编译、链接
  均通过；没有用全局 `-Wno-fatal` 掩盖 RTL 诊断。

## 当前设计与可重放证据

- 完整 RTL design-id：
  `sha256:c358ce6d3ef0fe1cb4cd8337bd4dd4f35c44d713b54d047c2ea9a51d38c07e8d`。
- V9R baseline 2/2 通过；bank0 READY-open、bank1 READY-open、bridge
  retry-fire-open 三份可编译 RTL 反例 3/3 被对应 V9R assertion 拒绝。
  V9R summary SHA-256：
  `35f2337f15acdfcc77ef20a1b536e7edfe86aa901068c743cc5b53c312f041b5`。
- V9O focused 10/10、`OOO_CSR_QUEUE_HEAD=1` 3/3、module 110/110、
  compile-success RTL variants 11/11、architecture hard gates 9/9、
  negative tests 30/30 全部通过。verification source-id 为
  `sha256:9fc91cc36818947105e5ba4ab8f44d6ad49f22134fae34ce54724c910d2d3d50`。
- V9O evidence index 共 164 个 artifact，SHA-256
  `5496f331833d5f7ab8834bad333d9ff6078e0c683f2eff5b0c2be2dabfbd5374`；
  mutation summary SHA-256
  `33335402765cba4a42e38df5274346ed928b5f078bf593caa4e5b089e2089c26`；
  final architecture hard-gates SHA-256
  `6c5d6567671a72a352522e9ae861afc629d5501874ac1b3427fd08ea83ee8061`。
- 十组语义门全部在当前 design-id 重放：FDG、XRET、INSTRET、memory issue
  lifecycle、FENCE、IFU AXI flush/drain、IFU provenance、IFU access、
  IFU precise tval、PTW/PMP；最后一组 PTW/PMP 为 focused 2/2、
  module 110/110、compile-success variants 28/28 动态拒绝。
- debt ledger 的 14 项历史条目已重绑当前设计；`F0-G1` 和
  `CONTROL-EVENT-G1` 均为 `CLOSED/current_design_bound=true`，
  `SERIALIZE-G1` 保持 OPEN。ledger SHA-256：
  `6a2088b68cbb98dcd52e8f604e437b1f166b26f2b0bcd66814f7b3677f3533cb`。

V9R 规范回放入口：

```bash
.github/task-runs/2026-07-24-rv64-v9r-sq-retry-c0-handoff/run-v9r-evidence.sh
```

## 功能、Linux 与 PPA 边界

- 当前设计功能聚合为 module 110/110、official 177/177、AM cpu-tests
  59/59、DiffTest mismatch 0、CoreMark 10 次迭代且 CRC `0xfcaf`、
  Dhrystone 10000；aggregate SHA-256：
  `842f5ce79b73dd2e7d1393e61f14013a6e40b27d43fa9c93b7b2dcb7c22a988f`。
- `rv64-linux` current-design profile 为 7 PASS / 1 FAIL。Sv39/SRET/U-mode、
  Linux focused smoke 与 UART RX 动态链通过；Sv39 日志 SHA-256：
  `d1313e7b5ece0af010aed17557ede6cd6d8270d8b818a8e1cb30f032af9fc538`。
- rootfs 节点在 1200 秒窗口内从 OpenSBI 进入 S-mode 和 Linux 6.6，
  建立 earlycon、reserved memory、zone/initmem，解析
  `console=ttyS0`、`root=/dev/vda` 与 systemd wrapper，随后到达
  dentry/inode cache、258048 pages 和 heap init；未到达 virtio/VFS mount
  或 systemd banner，返回 `exit=124`。这是当前设计的有界未完成，不是
  rootfs PASS，也没有观察到 RTL assertion failure。rootfs 日志 SHA-256：
  `fd857874c17dbce587c60a66be60e06d75b1843cdbf5c6769a1774a70f55bbda`。
- arch-stable validator 140/140 通过，但 full-core candidate 仍绑定旧
  `sha256:2eff867b20012e0c004fb03431a2f0604f22c471d0b115fd2e02eb5a51b2c8b2`。
  最终 audit 因证据代际与开放范围项报告 `architecture_freeze=GAP`、
  71 blockers、`PPA=UNQUALIFIED`、`promotion_eligible=false`；
  arch-stable result SHA-256：
  `607ca4c88a5da79d4156525021564e869fcfc2daf76d0a88ae06a367dd0fd7b4`。
- strict guard 中 `agent-system`、`npc-dev`、`difftest` 已有 current-source
  PASS；`rv64-linux` 因上述 rootfs 节点保持非零。收尾显式豁免重复同一
  1200 秒窗口，不把该项记为 PASS；后续需扩大有效仿真进展或形成新的
  RTL 定位假设后再执行。

前序六小时 rootfs 运行绑定更早 RTL，只形成 pre-fix 有界未复现：既未命中
目标 assertion marker，也未到达 guest-ready，不能绑定到当前 design-id。

## 本地 RTL 协作规则

任务合同和用户可见进度以 RV64 module、signal、pipeline stage、transaction、
cycle、testbench、EDA、evidence 与 PPA 组织；真实文件名、RTL 标识符、命令、
断言和可编译负向变体保持原样。该规则不建立关键词黑名单，不自动改写工程
语义，也不减少源码读取、shell、实现、反例搜索、验证或 PPA 分析能力。
