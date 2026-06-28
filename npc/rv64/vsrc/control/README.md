# Cross-cutting Control

这里用于承接 OoO core 的跨阶段控制逻辑，例如 flush、recovery、interrupt、
CSR 边界、terminal trap/exit 输出、PMU、power/clock gating 和未来 SMT 控制。

当前全局控制装配已经迁到 `../core/OooCoreTopGlue.v`，CSR 状态实现仍是
`../core/CsrFile.v`，但实例层级已经上提到 `../core/NpcCoreTop.v`。core glue 只导出
CSR access/trap/fflags/retire 事件并消费外部 CSR 状态；后续拆分时应先保持接口行为
不变，再把独立的控制状态机移入本目录，避免 core glue 重新承载功能语义。

- `OooTrapExitEventMux.v`：最终 trap/exit terminal event 的纯组合选择 owner；
  父模块只提供 branch/jump/drain/pending facts。
- `OooCsrAccessRequestMux.v`：commit0 CSR、pending SYSTEM CSR、lane1 CSR probe
  与 lane0 head 到 `CsrFile` CSR access request 的纯组合选择 owner；不写
  CSR 状态、不做 redirect/flush。
- `OooStopPendingSequencer.v`：`OooCoreTopGlue` 的 `stop_pending` 注册状态
  owner；不持有 pending payload、fetch PC/outstanding、CSR 状态或 FPR 写回。
- `OooPendingDrainResolveGate.v`：stop-pending 后的 backend drained、pending replay
  wait、drain complete、branch commit resolve/match clear、jump/system/mem dispatch
  valid/fire 和 FP start 组合中枢；不持有 pending payload 或状态寄存器。
- `OooCoreObservableOutputGate.v`：最终对外 trap/exit/halt、CSR state passthrough、
  debug PC/state/GPR 和 exit code 的纯组合输出选择；不写 CSR/trap sticky 状态。
- `OooCoreSliceControlGate.v`：branch checkpoint capture/restore/quiesce、branch-spec
  memory issue block、core local flush、core commit ready 和 commit1 block 的纯组合准入
  owner；不持有 backend/ROB 状态。
- `OooCsrIllegalProbeGate.v`：lane0/lane1 CSR illegal probe 归属选择 owner；不访问
  CSR 文件、不做 trap side effect。
- `OooCsrTrapRequestMux.v`：commit exception、pending architectural trap、
  pending ECALL/IRQ/xRET 到 `CsrFile` trap/return 请求的纯组合选择 owner；
  不写 CSR 状态、不做 redirect/flush。
- `OooPendingLane1CaptureGate.v`：lane1 barrier 后的局部 owner 分型和
  trap/exit payload 组合计算 owner；不判断 lane0/global priority，不持有状态。
- `OooPendingDispatchArbiter.v`：当前 fetch head/dispatch facts 到
  branch/jump/memory/FP/SYSTEM/trap-exit pending capture/clear 事件的纯组合
  仲裁 owner；slot 事实只通过 `dispatch0_facts_i/head1_facts_i` packed bus 进入，
  不持有 pending payload 或架构状态。
- `OooTrapExitOutputSequencer.v`：最终 `trap_valid/exit_valid/halted` sticky
  输出寄存器 owner。
