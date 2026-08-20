# Cross-cutting Control

这里用于承接 OoO core 的跨阶段控制逻辑，例如 flush、recovery、interrupt、
CSR 边界、terminal trap/exit 输出、PMU、power/clock gating 和未来 SMT 控制。

本目录的子系统 wrapper 是 `OooControlPlane.v`，作为 `../core/OooCoreTopGlue.v`
六实例之一装配下列控制 owner；CSR 状态实现仍是 `../core/CsrFile.v`，实例层级已
上提到 `../core/NpcCoreTop.v`。core glue 只导出 CSR access/trap/fflags/retire 事件
并消费外部 CSR 状态；后续拆分应继续保持接口行为不变，避免 core glue 重新承载
功能语义。

> ⚠️ **状态（2026-07-03 RTL 重读）**：pending branch/jump/mem 通道整链证死——
> `OooPendingDispatchArbiter` 的 branch/jump/memory capture 被 `!rob_walk_mode`
> 门死，`OooPendingDrainResolveGate` 的 jump/mem dispatch 臂恒空转；
> `OooCoreSliceControlGate` 的 branch checkpoint 臂恒 gate 0。存活的域 B（stop_pending + 全后端 drain 串行化）
> 只剩 system/trap/IRQ 类。当前证据见 `../../design/arch/rtl-ground-truth-2026-07-11.md`
> §4，拆除计划见 `../../design/arch/ooo-core-architecture.md` §8.3。下文保留各
> owner 的设计语义描述。

- `OooTrapExitEventMux.v`：最终 trap/exit terminal event 的纯组合选择 owner；
  父模块只提供 branch/jump/drain/pending facts。
- `OooCsrAccessRequestMux.v`：commit0 CSR、pending SYSTEM CSR、lane1 CSR probe
  与 lane0 head 到 `CsrFile` CSR access request 的纯组合选择 owner；不写
  CSR 状态、不做 redirect/flush。
- `OooStopPendingSequencer.v`：`OooCoreTopGlue` 的 `stop_pending` 注册状态
  owner；不持有 pending payload、fetch PC/outstanding、CSR 状态或 FPR 写回。
- `OooPendingDrainResolveGate.v`：stop-pending 后的 backend drained、pending replay
  wait、drain complete、branch commit resolve/match clear、jump/system/mem dispatch
  valid/fire 组合中枢（FP start 臂已随 pending-FP 拆除）；non-CSR serialized owner
  消费 owner-bound terminal permit，仍在消费拍重查 raw backend drain 与普通 FENCE
  current `mem_idle`；不持有 pending payload 或状态寄存器。
- `OooSerializedMemTerminalPermit.v`：V16A/V16B non-CSR system/architectural-trap/exit
  exact-one owner 的 memory-terminal permit owner；只保存 valid + 3-bit owner，
  feedback-free cancel 当拍封住 ready 且 state clear-dominant，既不拥有 memory token，
  也不替代 CSR current eligibility、raw drain 或普通 FENCE current-idle。
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
- `OooControlFlushSequencer.v`：`core_trap_flush`、`trap_redirect_squash` 和
  `checkpoint_mem_flush` 注册状态 owner；CSR/trap side effect 仍在父模块。
- `OooPendingSystemSequencer.v`：pending SYSTEM/CSR/IRQ 注册状态 owner（域 B 存活
  主体）；CSR side effect、trap/return target 选择与 pending owner arbitration
  仍在父模块。
- `OooPendingTrapExitSequencer.v`：pending architectural trap 与 simulation-exit
  的 valid/payload 注册状态 owner。
<!-- OooRedirectArbiter.v（B2 统一控制流重定向仲裁器地基）已于 2026-07-03 删档减负：
     从未接入编译列表/零实例化；当前 redirect 仲裁由 OooFetchRequestMux 隐式优先级链承担。 -->
