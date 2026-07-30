# HIST-SER-QH-STOP-HOLD-DROP 假设与判别实验

## 1. 初始假设

初始假设认为：

`head0_csr_inflight=1` 时，若从 `OooStopPendingSequencer` 删除 inflight
保持臂，ordinary `drain_complete` 会清除 stop，继而允许 younger lane1 CSR
进入 `pending_system_capture_lane1_w`。

该假设只把 sequencer 状态臂视为根因，原计划采用 current/hold-deleted ×
assertion on/off 四 case 判别。

## 2. 初始假设的反证

product glue TB 的自然程序先后尝试 older memory 与正确 BNE 前导，得到：

- `head0_csr_inflight && drain_complete && !head0_csr_commit` 周期数为 0；
- 正确 BNE resolve 时 `branch_spec_resolve_valid=0` 且
  `branch_resolve_untracked=0`，不是 stop clear root；
- current 与仅删除 sequencer hold 的版本均为
  `owner_gap=0, stop_drop=0, inflight_can_run=0, lane1_overlap=0`。

原因是当前 `OooPendingDrainResolveGate.backend_drained_o` 要求 ROB empty，
queue-head CSR 仍 inflight 时 ordinary drain 不可达；同时
`OooFrontendRunGate.stop_pending_owner_w` 已包含 queue-head inflight，
使 stop 不成为 orphan。

因此“删除 hold 臂即可动态重构历史缺陷”的初始假设被拒绝，不能据四 case 假绿
提升 ledger depth。

## 3. 修正后的双合同假设

queue-head CSR 前端停发由两项互补合同共同保证：

1. sequencer inflight hold 保持 registered `stop_pending`；
2. RunGate inflight owner 把该状态解释为 busy，阻止 orphan cleanup 与
   `can_run`。

历史源码核对进一步证明：

- `7f66f9d9...^` 同时缺少两项；
- `7f66f9d9...` 只补 sequencer hold；
- `2a77fd4b6...` 后续补 RunGate owner。

修正后的可证伪预测为：

- current：zero owner gap/drop/run/overlap；
- drop-stop-hold：在当前 bounded sequence 下仍由 RunGate owner 保持 zero
  gap/drop/run/overlap；这是 successor-contract witness，不是删除资格；
- drop-RunGate-owner：即使 stop 仍为 1，也出现 orphan owner gap、
  `can_run=1` 与真实 younger lane1 CSR capture；
- historical-pre-T3U（两项同时删除）：先出现 owner gap，再出现 stop drop；
  assertion-off 必须到达真实 lane1 overlap，assertion-on 必须保留并触发既有
  owner/hold assertion。

## 4. 判别程序与 raw 观测

自然程序的关键 PC：

- `0x80000000`：`auipc x2`；
- `0x80000008`：返回 0 的 older load；
- `0x8000000c`：正确 not-taken BNE；
- `0x80000010`：older queue-head CSR；
- `0x80000018`：successor packet ordinary lane0；
- `0x8000001c`：younger CSR lane1；
- 后续 ordinary witness 与 `ebreak`。

scoreboard 只计逐拍 raw event，不做 sticky 去重：

- qh CSR birth/hold；
- ordinary drain 与 non-kill resolve candidate root；
- orphan owner gap、stop drop、inflight `can_run`；
- successor packet、真实 lane1 system capture；
- C0 commit/barrier/CsrFile、C1 typed apply、C2 quiet。

lane1 overlap 还必须同时核对 older PC=`0x80000010`、younger
PC=`0x8000001c` 与 younger CSR decode fact，不能用 forced internal signal
替代产品数据流。

## 5. 实验结果

`run-stop-hold-matrix.py --refresh` 生成四种语义 × assertion on/off：

- compile-success：`8/8`；
- current：两个配置 PASS；
- drop-stop-hold：两个配置 PASS；
- drop-RunGate-owner：两个配置均被拒绝，
  `owner_gap=2, inflight_can_run=2, lane1_overlap=1`；
- historical-pre-T3U assertion-on：被既有 assertion 拒绝，
  `owner_gap=1, stop_drop=1`；
- historical-pre-T3U assertion-off：raw scoreboard 拒绝，
  `owner_gap=1, stop_drop=1, inflight_can_run=2, lane1_overlap=1`。

current 与 drop-stop-hold 的共同 positive marker 为：

```text
hold_cycles=6 nonkill_resolve_root=0 ordinary_drain_root=0
orphan_owner_gap=0 stop_drop=0 inflight_can_run=0
successor_packet_cycles=0 lane1_overlap=0 C0=2 C1=2 C2_quiet=2
```

矩阵摘要、case logs 与归一化 VVP identities 经完整重放保持稳定；raw VVP
字节因 allocator 标识变化不作为稳定 identity。

## 6. 结论与停止条件

- 原单臂/drain 假设：`REJECTED`；
- 修正后的 owner-state + owner-to-busy 双合同：`SUPPORTED`；
- historical-pre-T3U compile-success root-cone equivalent：`REJECTED`；
- production hold 删除/PPA promotion：`UNQUALIFIED`。

focused matrix 已区分 current、successor-contract survival 与真实负向 overlap，
因此本轮停止扩展，不运行 A3、Linux/rootfs、综合或 STA。只有 production core
RTL/elaboration/device/simulator 语义改变，或 A3 原始 terminal/post-hash 证据缺失，
才需要完整系统重跑。
