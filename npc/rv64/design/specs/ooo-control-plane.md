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

- wrapper 端口 = 13 个内部实例跨边界信号（2026-07 现状 211 个；pending-FP 通道拆除前为 222 个）。
- glue 顶层 wire 名保留，含被 `NpcSimTop` trace 探测的控制信号（`stop_pending_q`、
  `pending_system_*`、`drain_complete_w`、`csr_trap_*` 等）→ `u_ooo_core.<sig>` 探针不失效。
- 关键边界 case：`dispatch0_facts_w` 由 glue 级连续赋值 `wire [\`OOO_SLOT_FACTS_W-1:0]
  dispatch0_facts_w = <packing>;` 驱动，作为 wrapper **输入**（41 位，按声明位宽传入，
  不可截断为 1 位）；该 packing 赋值仍留在 glue 顶层。
- wrapper 参数只保留内部实例实际使用的结构参数。

## 4. 验证

- `make -C npc/rv64 lint` / build PASS；module testbench 103/103 PASS；
  official riscv-tests（177 项）0 FAIL。

## 5. 边界

只完成 control 子系统 wrapper 抽取；不改变 CSR/trap/interrupt precise control、
pending 状态机、drain/flush/recovery 语义。
