# Cross-cutting Control

这里用于承接 OoO core 的跨阶段控制逻辑，例如 flush、recovery、interrupt、
CSR 边界、terminal trap/exit 输出、PMU、power/clock gating 和未来 SMT 控制。

当前实现仍有不少全局控制集中在 `../frontend/OooAluFetchCore.v`，CSR 状态仍在
`../../core/CsrFile.v`。后续拆分时应先保持接口行为不变，再把独立的控制状态机移入
本目录。

- `OooTrapExitEventMux.v`：最终 trap/exit terminal event 的纯组合选择 owner；
  父模块只提供 branch/jump/drain/pending facts。
- `OooCsrAccessRequestMux.v`：commit0 CSR、pending SYSTEM CSR、lane1 CSR probe
  与 lane0 head 到 `CsrFile` CSR access request 的纯组合选择 owner；不写
  CSR 状态、不做 redirect/flush。
- `OooStopPendingSequencer.v`：`OooAluFetchCore` 的 `stop_pending` 注册状态
  owner；不持有 pending payload、fetch PC/outstanding、CSR 状态或 FPR 写回。
- `OooCsrTrapRequestMux.v`：commit exception、pending architectural trap、
  pending ECALL/IRQ/xRET 到 `CsrFile` trap/return 请求的纯组合选择 owner；
  不写 CSR 状态、不做 redirect/flush。
- `OooPendingDispatchArbiter.v`：当前 fetch head/dispatch facts 到
  branch/jump/memory/FP/SYSTEM/trap-exit pending capture/clear 事件的纯组合
  仲裁 owner；不持有 pending payload 或架构状态。
- `OooTrapExitOutputSequencer.v`：最终 `trap_valid/exit_valid/halted` sticky
  输出寄存器 owner。
