# RV64 V9W pending-system canonical kind 报告

## 结果

当前本地 RV64 RTL
`sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`
已完成 pending-system canonical type 与 typed redirect 局部闭合：

- `OooPendingSystemSequencer` 只注册一个 `kind_q`；
- CSR、ECALL、XRET、WFI、SFENCE family、FENCE.I、普通 FENCE、IRQ
  的公开类型均由该 holder 投影；
- 普通 FENCE 的强 drain 条件消费 `fence_o`；
- SINVAL family 和 FENCE.I 的 redirect reason 消费 holder-derived commit
  pulse。

本轮局部切片判定为 PASS。完整 `SERIALIZE-G1` 仍为 P1/OPEN，
full-core 保持 `architecture_freeze=GAP`、PPA `UNQUALIFIED`、
`promotion_eligible=false`；没有运行或声明正式 synthesis/STA/PPA。

## RTL 改动

- `npc/rv64/vsrc/control/OooPendingSystemSequencer.v`
  - 新增 `KIND_NONE..KIND_IRQ` 与 `classify_system_kind`；
  - 删除独立类型寄存器，所有 type output 从 `kind_q` 生成；
  - 新增 `fence_o`；
  - 保留 exact CSR ProducerId lease；
  - 新增 `[V9W-SERIAL-KIND-VALID]`、
    `[V9W-SERIAL-KIND-ONEHOT]` 及两条 capture-type assertion。
- `npc/rv64/vsrc/control/OooControlPlane.v`
  - 通过 `pending_system_fence_q` 消费 holder 类型，不再从 instruction
    重建普通 FENCE。
- `npc/rv64/vsrc/frontend/OooFrontend.v`
  - SFENCE/SINVAL 与 FENCE.I redirect reason 使用
    `pending_system_*_commit_w`。
- `npc/rv64/vsrc/core/OooCoreTopGlue.v`
  - 连接上述 holder-derived commit pulse。
- `npc/rv64/design/specs/ooo-pending-system-sequencer.md`
  - 冻结 canonical kind、Ccap/Cdrain/Cresolve/Ccommit、holder、lease 与
    recovery 边界。

## 正向与负向 RTL 证据

- focused：2/2 PASS。
  - `[V9W-SERIAL-KIND-MATRIX] kinds=8 lane-cases=14 onehot=1 hold=1
    clear=1 lease-scope=csr-only PASS`
  - `[V9W-SERIAL-TYPED-REDIRECT] sfence=1 sinval=1
    sinval_reason=SFENCE fencei=1 fencei_reason=FENCEI wfi=1 PASS`
- layered：6/6 PASS，覆盖 pending sequencer、dispatch arbiter、drain
  resolve、stop pending、control commit 与 priv-system。
- compile-success RTL variants：4/4 成功编译并由精确 oracle 拒绝。
  - XRET 驱动两个公开类型；
  - 普通 FENCE 丢失 registered kind；
  - SINVAL redirect 回退到窄 raw decode；
  - FENCE.I redirect 丢失 holder type。
- live RTL source set 在变体前后保持不变。

## 当前设计重放

- module aggregate：111/111 PASS。
- official ISA：177/177 PASS。
- AM：59/59 PASS。
- DiffTest：mismatch 0。
- CoreMark：10 iterations，CRC `0xfcaf`。
- Dhrystone：10000 iterations 完成。
- canonical architecture hard gates：9/9 GREEN。
- current-design refresh：
  `state=PASS stage=complete`。
- final arch-stable audit：32 blockers，包含
  `debt.SERIALIZE-G1.resolved=OPEN`、full-core census 与 freeze-input
  inventory/binding GAP；PPA 保持 UNQUALIFIED。

## AI 工作流与当前 rootfs 边界

- `npc-dev`：
  `.github/task-runs/2026-07-26-pending-system-sequencer-current`，
  5/5 PASS，manifest SHA-256
  `4198721d222aa5adc025b90422cfb7ea34b8dffd84714f8c124d3e2ee118cb37`。
- `agent-system`：
  `.github/task-runs/2026-07-26-pending-system-sequencer`，
  11/11 PASS，manifest SHA-256
  `4d764d43309f406564d62d01f7291466987d2a6e2ace9daa60d3c62c1d18fc41`。
  双角色文档检查已从单一固定短语改为
  `实现者`、`审查者`、`双角色复核` 三个语义锚点；
  `test-agent-system-dual-role-contract.sh` 的两个正向措辞与缺少复核锚点
  的负向反例均 PASS。这只消除表述形式假阴性，不降低工作流要求。
- `rv64-linux`：
  `.github/task-runs/2026-07-26-serialize-system-trap` 为 7 PASS / 1 FAIL。
  rootfs 节点按 1200 秒边界以 `exit=124` 结束；当前 RTL design-id 为
  `sha256:1252332b723017ab370ee6a49d945ad86dce1f2e5b585aaea4dccb7388a79702`，
  simulator SHA-256 为
  `4b0be491fbe1305e79bbaf599787f1321c8ac7dcc8ea5236a23a735edda8441d`。
  配置为 `OOO_CSR_QUEUE_HEAD=0`、
  `OOO_TERMINAL_HOLDER_ASSERT=0`、`--max=340000000`、`--progress=0`。
  控制台推进到 Linux 时间 0.059199 秒的 EFI 初始化；未出现
  virtio-blk/EXT4/VFS mount、systemd/Ubuntu/hostname、guest-expect 或
  syscon/OpenSBI terminal marker，也未出现 RTL assertion-failure marker。
- strict guard 对 `agent-system/npc-dev/difftest/github-index` 为 PASS，
  对 `rv64-linux` 因没有完成态 PASS evidence 保持 FAIL。该结果记录为系统
  时限 GAP，不映射成当前 RTL 失败，也不追认为 rootfs 或终端事务 PASS。
  结构化边界见 `evidence/rv64-linux-rootfs-boundary.json`。

## 历史 V9Q rootfs 终态核验

`.github/task-runs/2026-07-23-rv64-v9p-serialize-current-design/
rootfs-v9q-terminal-pair-a1.status` 已结束为 `FAIL rc=2`：

- 旧 RTL design-id：
  `sha256:4655eabea13d2ecce9ac94784bbcb0a8bd2151b65bcd7325f950c6abb9b91380`；
- simulator SHA-256：
  `669c983b22ce52beb433e50870e8950c522f8fd2a1072798fb86489bc2af6c87`；
- 配置包含 `OOO_CSR_QUEUE_HEAD=1`、
  `OOO_TERMINAL_HOLDER_ASSERT=1`、
  `NPC_COMMIT_GAP_LIMIT_CYCLES=1000000`；
- 最后 progress 为 405,000,000 committed instructions，
  `pc=0xffffffff80002f68`；
- `terminal-markers.txt` 为空，driver/guest 未出现 terminal-pair PASS 或
  RTL assertion-failure marker。

因此旧运行只表示旧设计上的有界未完成，不能绑定当前 design-id，也不能证明
terminal transaction 或系统完成。

## 实现者 / 审查者复核

实现者结论：

- canonical kind 是 pending-system 类型的唯一注册真源；
- 双 lane 正例、四个源码级负向版本、module aggregate、functional
  aggregate 与九项架构硬门均已重绑当前 design-id；
- 未增加 terminal 去重，未削弱断言。

独立审查者结论：

- 当前类型、CSR lease 与 typed redirect 局部切片为最小 PASS；
- 没有发现当前 RTL 的确定失败反例；
- 以下三类仍是 `SERIALIZE-G1` blocker：
  1. 七类 × 两 lane × holder phase × older branch/JALR/trap/local-flush
     的 recovery cross-product；
  2. CSR/ECALL/XRET/WFI/SFENCE/FENCE.I 的真实 memory-owner 终态证明；
  3. synthetic commit/trap/return、typed redirect、holder/stop clear、
     MMU flush 与 bridge terminal 的 exactly-once/无 ghost side effect
     联合观测。

下一最小切片应把 `core_mem_idle_w/core_mem_retire_quiet_w` 的真实 owner
生成链纳入合同，为七类 transaction 建立 recovery 与 terminal matrix；不得用
重复事件去重或 assertion 降级代替根因证明。

## 证据摘要

- `evidence/serialize-type-mutations.json` SHA-256：
  `fdfb0f2c1aad840cc9689e614a11e5ef6d52f763057134c027aeae875a48d2d9`。
- `architecture/final-architecture-hard-gates.json` SHA-256：
  `fc67e4b1ac5ad6cfb503ebf5a502c7e0deaeada1e3280aa1f34f077840393bef`。
- `evidence/final-arch-stable-audit.json` SHA-256：
  `6e73a4718945f938d8904a271360654cfc6dc2f722b716d906daac58866b9a9a`。
- `current-design-refresh.log` SHA-256：
  `d796d4c318ae8e647a6bbfe57ea330d36b2897f786482b5a4e790ab01a7139fd`。
- `evidence/rv64-linux-rootfs-boundary.json` 绑定当前 RTL、simulator、
  配置、已达/未达 marker 与 strict-guard 边界，SHA-256：
  `911c117886de722a1a66c8227e78b0c21027fe4a4f446c34aec73d7b3bcb6f76`。
