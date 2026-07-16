# OooControlPlane 子系统 wrapper Spec

## 1. 目标

把 `control/` 目录的 13 个 CSR/trap/pending/drain/flush/stop/observable 控制 owner
聚合到 `control/OooControlPlane.v`，让 `OooCoreTopGlue` 只对控制子系统做一次实例化。
纯结构聚合，不新增逻辑、不改行为。

## 2. 责任边界（内部 owner，行为不变）

| 子域 | 内部 owner |
| --- | --- |
| pending dispatch 仲裁 | `OooPendingDispatchArbiter`（内含 lane1 capture gate） |
| CSR access/trap 请求 mux | `OooCsrAccessRequestMux`、`OooCsrTrapRequestMux`、`OooCsrIllegalProbeGate` |
| pending system / drain / trap-exit | `OooPendingSystemSequencer`、`OooPendingDrainResolveGate`、`OooPendingTrapExitSequencer`、`OooTrapExitEventMux`、`OooTrapExitOutputSequencer` |
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

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。

## 5. 边界

除已单独规范化的 T4L 普通 FENCE drain 条件外，本 wrapper 不改变
CSR/trap/interrupt precise control、pending 状态机或既有 flush/recovery 语义。
