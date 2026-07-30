# OooStopPendingSequencer

## 1. 范围

`OooStopPendingSequencer` 是 registered `stop_pending_o` 的唯一状态写入者。
pending payload、owner 的 lane/type/recovery 仲裁、fetch FIFO、queue-head CSR
inflight、backend drain、CSR C0/C1 apply 以及 trap/exit 输出均由相邻模块拥有；
本模块只保存“当前存在 serialization stop lease”这一位状态。

`OooFrontendRunGate` 不写该状态，但负责把已登记 owner 映射为
`stop_pending_busy_o`，因此它与 sequencer 共同构成前端停发合同。两者不能只按
单个寄存器局部理解。

## 2. 状态优先级

单一 `always @(posedge clk)` 优先级从高到低为：

1. `rst || flush_i || core_local_flush_i` 清零；
2. `pending_system_csr_commit_i || head0_csr_commit_i` 在 exact terminal
   C0 清零；
3. `pending_system_producer_valid_i` 为 post-dispatch CSR lease 保持 1；
4. `head0_csr_inflight_i && !head0_csr_owner_kill_i` 为 queue-head CSR
   从 dispatch 到 C0 保持 1；
5. `csr_trap_mem_valid_i` 清零；
6. direct branch fire 按 `OOO_DBRANCH_DOMAIN_A` 决定是否建立 legacy
   drain-stop；当前 domain-A 配置写 0；
7. `pending_owner_birth_i || head0_csr_owner_birth_i` 已经过上游
   lane/type/recovery 仲裁，置 1；
8. branch-spec/branch/jump exact clear、`head0_csr_owner_kill_i` 与
   `orphan_stop_pending_i` 清零；
9. ordinary `drain_complete_i` 清零；
10. 没有命中任何分支时保持原状态。

`jump_dispatch_fire_i`、`pending_mem_resolve_ready_i`、
`system_csr_dispatch_fire_i` 与 `rob_walk_mode_i` 是待相邻 dead-owner 清理时再
删除的 legacy interface；它们不再改变状态。

## 3. RunGate owner 合同

`OooFrontendRunGate.stop_pending_owner_w` 必须包含所有 registered owner，
其中 queue-head CSR 的项为：

```verilog
`OOO_CSR_QUEUE_HEAD && head0_csr_inflight_i
```

组合关系为：

```text
orphan_stop_pending = stop_pending && !stop_pending_owner
stop_pending_busy   = stop_pending && !orphan_stop_pending
can_run             = run && ... && !stop_pending_busy
```

因此：

- sequencer 的 inflight 保持保证 stop 状态贯穿 owner lifetime；
- RunGate 的 inflight owner 保证这一个 stop 不被解释成 orphan，并实际阻塞
  `can_run`；
- `stop_pending_o=1` 本身不等价于前端已停发；必须同时证明
  `stop_pending_busy_o=1`；
- queue-head CSR C0 前不得出现
  `head0_csr_inflight && (orphan_stop_pending || !stop_pending_busy || can_run)`。

## 4. Queue-head CSR 周期合同

- birth：真实 `head0_csr_dispatch_fire_w` 建立
  `head0_csr_inflight_q` 与 `head0_csr_owner_birth`；同 packet lane1 不得
  backend fire。
- hold：C0 前每个 inflight 周期均须满足
  `stop_pending=1, stop_pending_busy=1, can_run=0`。下一 packet 的 younger
  lane1 CSR 不得进入 `pending_system_capture_lane1_w`。
- C0：queue-head CSR commit、CSR barrier 与 CsrFile request 对该 transaction
  各发生一次；exact commit 释放 stop/inflight owner。
- C1：typed CSR apply/serial flush 对该 transaction 发生一次，holder 与
  frontend 状态完成清理。
- C2：commit、barrier、CsrFile request、typed apply 均 quiet；不得用
  `seen/reported` 去重掩盖重复 raw event。
- older-control kill 与 local/top flush 是合法 owner death；相关 stop 释放不得
  误计为提前 drop。

## 5. 历史根因边界

历史源码 `7f66f9d9d4badc08e0c51dc65c4db2b99683de46^` 同时缺少：

1. `OooStopPendingSequencer` 的 queue-head inflight 保持臂；
2. `OooFrontendRunGate` 的 queue-head inflight owner 项。

`7f66f9d9...` 只补入第 1 项；后续
`2a77fd4b6b69b75f45f651722e17a7c214a2d55c` 才补入第 2 项。当前 product
拓扑的定向重构表明：

- 只删除 sequencer 保持臂时，RunGate owner 仍阻止 orphan clear，当前
  bounded sequence 不发生 stop drop 或 lane1 overlap；
- 只删除 RunGate owner 时，`stop_pending` 虽保持为 1，却被解释为 orphan，
  `can_run` 提前打开并发生真实 younger lane1 CSR capture；
- 同时删除两项时，orphan clear 进一步令 stop drop，完整重构 pre-T3U
  owner gap。

当前 `OooPendingDrainResolveGate.backend_drained_o` 要求 ROB empty，所以本
product sequence 在 queue-head CSR 尚 inflight 时没有 ordinary drain root。
历史记录中的 “drain clears stop” 仍作为历史症状材料保留，但不能替代当前
拓扑的 raw owner/orphan/capture 证据。

上述 bounded mutation survival 不能直接证明 sequencer 保持臂可删除，也不构成
PPA 等价、综合或 STA 结论；production 两项合同均保持不变。

## 6. 断言与验证

production assertion 必须保留：

- `[V9X-STOP-BIRTH-WITNESS]`
- `[V9X-STOP-LEASE-HOLD]`
- `[V9X-STOP-QCSR-HOLD]`
- `[V9X-STOP-OWNER-LIVE]`
- frontend `[T3U-CSR-STOP-OWNER]`

验证分三层：

1. standalone `tb_ooo_stop_pending_sequencer` 在 assertion on/off 下覆盖状态
   优先级；
2. `tb_ooo_core_top_glue_v9o_csr_qh` 在 assertion on/off 下覆盖既有
   queue-head CSR positive/kill/C0/C1/C2；
3. `tb_ooo_core_top_glue_hist_ser_qh_stop_hold` 使用同一自然程序与逐拍 raw
   scoreboard，比较 current、drop-stop-hold、drop-RunGate-owner 与
   historical-pre-T3U 四种语义，各跑 assertion on/off。所有 8 个版本必须
   compile-success；negative case 必须由 owner gap、`can_run` 或真实 lane1
   capture 拒绝，不能靠编译失败、force 内部 owner 或削弱断言获得结论。
