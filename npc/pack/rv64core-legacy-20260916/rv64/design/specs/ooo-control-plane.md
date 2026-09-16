# OooControlPlane 子系统 wrapper Spec

## 1. 目标

把 `control/` 目录的 14 个 CSR/trap/pending/drain/flush/stop/observable 控制 owner
聚合到 `control/OooControlPlane.v`，让 `OooCoreTopGlue` 只对控制子系统做一次实例化。
除 V16A 明确定义的 owner-bound serialized-terminal permit 外，保持结构聚合，不把
memory token、CSR 状态或架构 payload 所有权移入 wrapper。

## 2. 责任边界（内部 owner，行为不变）

| 子域 | 内部 owner |
| --- | --- |
| pending dispatch 仲裁 | `OooPendingDispatchArbiter`（内含 lane1 capture gate） |
| CSR access/trap 请求 mux | `OooCsrAccessRequestMux`、`OooCsrTrapRequestMux`、`OooCsrIllegalProbeGate` |
| pending system / drain / trap-exit | `OooPendingSystemSequencer`、`OooSerializedMemTerminalPermit`、`OooPendingDrainResolveGate`、`OooPendingTrapExitSequencer`、`OooTrapExitEventMux`、`OooTrapExitOutputSequencer` |
| flush / stop / slice 准入 | `OooControlFlushSequencer`、`OooStopPendingSequencer`、`OooCoreSliceControlGate` |
| 对外观测输出 | `OooCoreObservableOutputGate` |

## 3. 接口与不变量

- wrapper 端口 = 13 个内部实例跨边界信号（T3K 后 215 个；新增 4 根
  head-only `csr_probe_*` 输出，T3K 前为 211 个；pending-FP 通道拆除前为 222 个）。
- glue 顶层 wire 名保留，含被 `NpcSimTop` trace 探测的控制信号（`stop_pending_q`、
  `pending_system_*`、`drain_complete_w`、`csr_trap_*` 等）→ `u_ooo_core.<sig>` 探针不失效。
- 关键边界 case：`dispatch0_facts_w` 由 glue 级连续赋值 `wire [\`OOO_SLOT_FACTS_W-1:0]
  dispatch0_facts_w = <packing>;` 驱动，作为 wrapper **输入**（41 位，按声明位宽传入，
  不可截断为 1 位）；该 packing 赋值仍留在 glue 顶层。
- wrapper 参数只保留内部实例实际使用的结构参数。
- `csr_access_*` 与 `csr_probe_*` 是两条不同组合视图：前者允许由
  commit/pending/head fallback 选择并服务 CsrFile 读回/副作用，后者只允许由
  current head0/head1 产生并服务 illegal pending 分类。wrapper 只接线，不得把
  两者重新 alias、打拍或增加选择器。
- T4G 精确 IFU fault payload：`head_fetch_fault_tval_w` 是 frontend FIFO
  提供的 packet-level portion frontier；`OooPendingDispatchArbiter` 对 lane0/lane1
  fetch PF/AF 均使用它写 pending tval，同时继续用对应 slot PC 写 xEPC。control
  wrapper 只透传该 owner，不允许从 `head_pc*` 重建 tval。
- T4L 普通 FENCE：wrapper 从已捕获的 `pending_system_inst_q` 识别
  `OPCODE_MISC_MEM/FUNCT3_FENCE`，并把 execute 侧 `mem_idle_i` 与该身份送入
  `OooPendingDrainResolveGate`。基础 `backend_drained` 仍只含 ROB/IQ/synthetic/SQ；
  仅普通 FENCE 的最终 `drain_complete` 额外要求 MIQ/bridge/reservation 全 idle。
  完整合同见 [`ooo-fence-drain-ordering.md`](./ooo-fence-drain-ordering.md)。
- V16A serialized terminal：non-CSR system、architectural trap 与 simulation
  exit 组成 exact-one owner 向量。`OooSerializedMemTerminalPermit` 只在
  `stop_pending_q && backend_drained_q && mem_owner_terminalized_i` 时采样并绑定
  当前 owner；feedback-free cancel 当拍封住 ready，且
  flush/cancel/consume/stop drop/owner mismatch 均 clear-dominant。
  `OooPendingDrainResolveGate` 消费 permit Q，但消费拍仍重查 raw
  `backend_drained_o`，普通 FENCE 仍重查 current `mem_idle_i`。CSR dispatch 的
  raw eligibility 继续直接使用 current `mem_owner_terminalized_i`。完整合同见
  [`ooo-serialized-mem-terminal-permit.md`](./ooo-serialized-mem-terminal-permit.md)。

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。
- V16A/V16B focused owner-permit/drain/arch-trap/exactly-once/core-glue 仿真、五个
  compile-success mutation、RTL style 与 lint PASS；PPA 与系统级再认证仍是候选门禁。

## 5. 边界

除已单独规范化的 T4L 普通 FENCE drain 条件与 V16A owner-bound terminal permit 外，
本 wrapper 不改变
CSR/trap/interrupt precise control、pending 状态机或既有 flush/recovery 语义。
