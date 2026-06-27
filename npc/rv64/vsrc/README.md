# RV64 RTL 目录

`vsrc/` 是唯一 RTL 功能分层入口，不再额外套 `ooo/` 外壳。`Ooo*` 模块名只表示
它属于当前乱序核实现，物理目录按职责和现有外层目录合并：

- `frontend/`：PC 生成、分支预测、pending branch/jump sequencer、BPU update gate、RAS、return-continuation、branch target capture、branch append dispatch gate、branch prefetch request gate、branch prefetch buffer、direct branch wait buffer、backend drain tracker、front-end uop safety policy、front-end dispatch gate、front-end/backend dispatch mux、front-end run gate、front-end action gate、fetch request mux、fetch packet decode、fetch head classify、fetch head pair gate、fetch packet FIFO、fetch flow-control、取指 AXI bridge、前端控制壳。
- `common/`：跨阶段共享的 packed bus/header 定义；当前 `OooSlotFacts.vh` 统一维护 fetch/decode slot facts bit layout。
- `decode/`：基础 decode、立即数生成、RVC 预译码、FP decode、OoO decode glue。
- `cache/`：取指包 cache、data word cache，以及后续真实 I/D cache 落点。
- `rename_allocate/`：rename map、free list、busy table、dispatch/ROB/IQ 分配。
- `scheduling/`：issue queue、wakeup/select 相关调度状态。
- `regread_bypass/`：物理寄存器堆、FP 寄存器堆与后续旁路网络落点。
- `execute/`：基础 ALU/Compare、OoO ALU slice、整数后端、MUL/DIV、CLMUL、pending FP sequencer、FP pending 执行数据通路与 FP 迭代单元。
- `memory/`：LSU、Sv39 TLB、pending memory sequencer、memory request gate、memory AXI bridge、后续 LSQ/store-forward/MSHR 落点。
- `writeback/`：WBU、ROB、退休、commit output mux 和 commit 侧架构寄存器观测镜像。
- `control/`：flush/recovery/pending SYSTEM/CSR/interrupt/pending trap-exit、
  final trap/exit output、PMU 等跨阶段控制的落点。

当前 `control/` 仍是目标分类：大部分全局控制尚集中在
`frontend/OooAluFetchCore.v` 和 `core/CsrFile.v`，后续拆分应优先向这里收敛。

当前 RV64 LSU/仿真 AXI 数据侧采用 byte-addressed 64-bit window：普通
load/store 的请求地址保持 exact effective address，`wdata/wstrb` 从 lane0
开始表达访问宽度；非对齐普通 load/store 由 DPI PMEM 连续字节窗口完成。
AMO/LR/SC 仍在执行后端保留对齐异常约束。

OoO 结构容量默认值统一由 `include/define.v` 中的 `OOO_*` 宏维护：
`OOO_PHY_REG_ADDR_W/OOO_PHY_REG_COUNT/OOO_FREE_COUNT_W`、`OOO_ROB_INDEX_W/OOO_ROB_COUNT_W`、
`OOO_ISSUE_INDEX_W/OOO_ISSUE_COUNT_W` 和 `OOO_FETCH_PACKET_COUNT_W`。顶层调试计数端口和
PRF/FreeList/ROB/IQ/fetch FIFO 默认参数必须引用这组宏；实际改变容量后需要重新跑
module/core 回归和性能样本分析。

当前 privileged/core-regress 相关边界：

- `core/CsrFile.v` 提供最小 debug trigger no-op CSR、`pmpcfg0/pmpaddr0`
  CSR 存储、`misa` WARL no-op 写入，以及 `mstatus.TVM/TW/TSR` 可写位。
- `frontend/OooFetchHeadClassifyGate.v` 承接单个 fetch head 的 decoder illegal、
  branch/jump/memory、FP decode、FS-off FP、semihost EBREAK、ECALL/CSR/xRET/WFI、
  supervisor fence/TVM/TSR privilege illegal、stop 和 architectural trap 组合事实；
  同时输出 `common/OooSlotFacts.vh` 定义的 `facts_o` packed bus，作为旧散线的
  等价 alias；
  父模块仍保留 fetch FIFO、pending owner、CSR side effect、trap capture 和 precise
  recovery 时序所有权。
- `frontend/OooFetchHeadPairGate.v` 承接双槽 fetch head 可见性、head0/head1
  classifier 实例、fetch fault 汇总、branch-spec dispatch block 和 dispatch0
  ECALL/EBREAK/exit/arch-trap/system/FP/branch/JAL/JALR 组合 facts；内部局部判断已
  优先消费 `head0_facts_o/head1_facts_o` packed bus，但旧散线端口继续保留；父模块仍保留
  ready/unsupported fire、direct JAL/ret、RAS/BPU、pending owner、CSR side effect、
  fetch FIFO、PC/outstanding 和 precise recovery 时序所有权。
- `frontend/OooAluFetchCore.v` 通过 `OooFetchHeadPairGate` 获取
  decoder illegal、FS-off FP illegal、`sfence.vma` under TVM、`sret` under TSR 等
  精确前端 trap facts；被 `OooFpDecode` 识别的 OP-FP 指令不能再被整数 decoder 的
  illegal 位抢先 trap。
- `control/OooPendingDispatchArbiter.v` 承接 fetch/dispatch facts 到 pending
  branch/jump/memory/FP/SYSTEM/trap-exit capture/clear 的纯组合仲裁；当前已接入
  `dispatch0_facts_i/head1_facts_i` packed bus 作为内部判定主路径，旧散线端口仍保留
  作为渐进迁移兼容层。
- `memory/OooMemAxiBridge.v` 与 `frontend/OooFetchAxiBridge.v` 已按 Sv39
  leaf PTE 检查 A/D 位：A=0 或 store 且 D=0 返回 page fault，不把该 PTE
  填入 TLB。
- `execute/OooIntBackend.v` 的 buffered memory drain 保持 exact effective
  address，避免正常窄 load/store 在缓冲路径被错误对齐到 8B 边界。
- `execute/OooFpPendingExec.v` 承接 pending FP 的组合结果、fflags、FP mem
  地址数据和 FDIV/FSQRT 迭代包装；父模块仍保留 fflags/GPR serial commit
  副作用边界。
- `regread_bypass/OooFpRegFile.v` 承接 FPR 状态、3 读端口、FP load 写回和
  FP compute/long 结果写回；父模块只生成写回条件和数据选择，不再直接持有
  `fpr_q` 数组。
- `execute/OooPendingFpSequencer.v` 承接 pending FP 单 entry 的 valid、memory
  进度、long-op 进度、compute result/fflags、指令 payload 和 memory request
  payload 注册状态；父模块仍负责 fflags commit、GPR serial write、FPR 写回条件、
  pending owner arbitration、backend drain、fetch redirect 和 precise recovery。
- `memory/OooMemoryRequestGate.v` 承接 pending FP memory request、OoO core
  lane0/lane1 memory request、response ready、`mem_flush` 和 `mmu_flush` 的纯组合
  边界；pending FP memory 状态由 `OooPendingFpSequencer` 持有，父模块仍保留 core
  LSU 状态和 precise trap/flush 时序所有权。
- `memory/OooPendingMemorySequencer.v` 承接 lane1 memory barrier 的 pending memory
  单 entry 注册状态；父模块仍负责 pending owner arbitration、LSU/MMU request、
  memory trap、backend drain、fetch redirect 和 precise recovery。
- `frontend/OooPendingBranchSequencer.v` 承接 pending branch 单 entry 注册状态；
  父模块仍负责 branch compare、target 计算、BPU update、branch-spec recovery、
  misaligned trap、backend drain、fetch redirect 和 precise recovery。
- `frontend/OooPendingJumpSequencer.v` 承接 JAL/JALR pending jump 单 entry 注册状态；
  父模块仍负责 target 计算、RAS/BTB、misaligned trap、backend drain、fetch redirect
  和 precise recovery。
- `frontend/OooDirectRasCandidateGate.v` 承接 direct RAS/RAS-ret 候选组合事实：
  lane0/lane1 JAL call-like raw、RAS direct update safe、lane0 direct return 和
  lane1 return candidate；父模块仍保留 RAS 栈、return-cont buffer、direct jump/ret
  fire、PC redirect 和 dispatch/FIFO 时序所有权。
- `frontend/OooRasUpdateGate.v` 承接 RAS 栈上游 clear/pop/push/push-value
  组合更新控制；父模块和 `OooRasStack` 仍保留 RAS 状态、可靠性、栈顶以及
  同周期 clear/pop/push 的时序优先级；旧 pending lane1-ret dispatch replay
  已删除，不再作为 RAS pop 输入。
- `frontend/OooFetchPacketDecode.v` 承接取指 response packet 的 RVC 半字拼接、
  解压、slot PC/next PC、slot response 和 control-stop 组合事实；父模块仍保留
  response ready-valid、FIFO、redirect 和 trap/flush 策略。
- `frontend/OooFrontendUopSafety.v` 承接前端 fast path 使用的普通 uop 安全白名单
  组合策略；父模块仍保留 dispatch payload、prefetch 转正和 precise recovery
  的时序所有权。
- `frontend/OooFrontendDispatchGate.v` 承接前端 dispatch 入口的 lane1/direct
  fast-path、barrier、unsupported 和 normal dispatch fire 组合 gating；父模块仍保留
  slot0 branch fast path、pending sequencer、commit/trap/redirect 时序所有权。
- `frontend/OooFrontendBackendDispatchMux.v` 承接前端/pending 控制源到
  `OooAluCoreSlice` 双 dispatch 端口的 valid、payload、dispatch0 fire、pending jump
  fire 和 pending memory fire 纯组合选择；父模块仍保留 pending owner、CSR/trap
  side effect、backend allocation 和 precise recovery 时序所有权。
- `frontend/OooDirectBranchResolveGate.v` 承接 direct branch lane 选择、BHT
  payload 选择、预测 PC、dispatch/issue resolve 优先级、redirect/taken 判定和
  lane1 return capture 组合事实；父模块仍保留 BPU/RAS 表项、pending 状态、trap squash
  和 PC/outstanding/discard 时序所有权。
- `frontend/OooBranchResolveRecoveryGate.v` 承接 pending branch resolve match、
  tracked/untracked redirect、branch-spec checkpoint/restore/redirect 和 direct
  branch wait untracked 的组合恢复谓词；父模块仍保留 pending/spec/wait 状态、
  PC/outstanding/discard、BPU/RAS update 和 trap/CSR 时序所有权。
- `frontend/OooBranchSpecTracker.v` 承接 branch-spec checkpoint 的
  active/checkpoint-pending/pred-PC 注册状态；父模块仍负责 checkpoint/resolve
  事件生成、PC/outstanding/discard 和 precise recovery 仲裁。
- `frontend/OooFetchPcOutstandingSequencer.v` 承接前端 `next_fetch_pc`、
  `outstanding_valid/outstanding_pc` 和 `discard_fetch_rsp` 注册状态；父模块仍负责
  fetch request mux、FIFO 存储、branch/pending/trap 事件生成、CSR/trap side
  effect 和 commit 状态。
- `writeback/OooControlCommitSequencer.v` 承接控制类伪提交的
  `ctrl_commit_valid/payload/rd/write` 和 `core_serial_flush` 注册状态；父模块仍负责
  pending owner 捕获/清理、CSR/trap side effect、FPR 写回条件、ROB commit mux 和
  PC/outstanding 时序。
- `writeback/OooCommitOutputMux.v` 承接 control pseudo-commit、synthetic
  lane1 return/branch append 与 ROB commit0/commit1 到外部 commit/retire 端口的
  纯组合 mux；父模块仍负责 ROB/CSR/trap side effect、synthetic ret 状态和
  pending owner 清理。
- `control/OooControlFlushSequencer.v` 承接 `core_trap_flush`、
  `trap_redirect_squash` 和 `checkpoint_mem_flush` 注册状态；父模块仍负责 CSR/trap
  side effect、pending owner 清理、branch checkpoint 事件和 PC/outstanding 时序。
- `control/OooCsrAccessRequestMux.v` 承接 commit0 CSR、pending SYSTEM CSR、
  lane1 CSR probe 与 lane0 head 到 `CsrFile` CSR access request 的纯组合选择；
  父模块仍负责 CSR 文件实例、CSR legality/side effect、pending owner 和 precise
  recovery。
- `control/OooStopPendingSequencer.v` 承接 `stop_pending` 注册状态；父模块仍
  负责 pending payload、fetch PC/outstanding、CSR side effect、FPR 写回条件和
  precise recovery。
- `control/OooCsrTrapRequestMux.v` 承接 commit exception、pending architectural
  trap、pending ECALL/IRQ/xRET 到 `CsrFile` trap/return 请求的纯组合选择，并保留
  父模块原有 debug-observable wire 名称；父模块仍负责 CSR 文件实例、pending owner、
  fetch redirect、flush/recovery 和 final terminal output。
- `control/OooPendingSystemSequencer.v` 承接 pending SYSTEM/CSR/IRQ 注册状态；
  父模块仍负责 CSR side effect、trap/return target 选择、pending owner arbitration、
  backend drain、fetch redirect 和 precise recovery。
- `control/OooPendingTrapExitSequencer.v` 承接 pending architectural trap 与
  simulation-exit 的 valid/payload 注册状态；父模块仍负责 `stop_pending`、
  drain complete、CSR trap mux/side effect、terminal event 形成、fetch redirect
  和 precise recovery。
- `control/OooTrapExitOutputSequencer.v` 承接最终 `trap_valid/exit_valid/halted`
  sticky 输出寄存器与 payload；父模块仍负责 CSR/trap side effect、exit-code
  选择、fetch redirect 和 precise recovery。
- `control/OooTrapExitEventMux.v` 承接最终 trap/exit terminal event 与 payload
  的纯组合选择；父模块仍负责提供 branch/jump/drain/pending facts、CSR/trap side
  effect、exit-code 选择、fetch redirect 和 precise recovery。
- `writeback/OooSyntheticLane1RetSequencer.v` 承接 lane1 return synthetic retire
  与 branch-drop 注册状态；父模块仍负责 branch/RAS/BTB 判定、pending owner、
  commit0/commit1 mux、retire count 和 CSR/trap side effect。
- `frontend/OooAluFetchCore.v` 中旧 `pending_lane1_ret_*` dispatch replay 状态已删除；
  当前 lane1 return 延迟可见性由 synthetic retire sequencer 与 direct RAS 事件承担。
- `frontend/OooPendingControlResolveGate.v` 承接 pending branch next/misaligned、
  pending JAL/JALR resolved target、return/call/no-link 分类、jump resolve-ready 和
  redirect-after-dispatch 组合事实；父模块仍保留 pending 状态、CompareUnit、RAS/BTB
  表项、trap/commit 和 PC/outstanding/discard 时序所有权。
- `frontend/OooBranchAppendDispatchGate.v` 承接 return-cont、branch target/
  fallthrough lane1 append candidate/attempt/dispatch、fallthrough outstanding
  keep/capture、branch prefetch direct-dispatch dead-path 和 `dispatch1_optional`
  组合门控；父模块仍保留相关状态寄存器、dispatch payload mux、FIFO seed/enqueue
  和 PC/outstanding/discard 时序所有权。
- `frontend/OooBranchBpuUpdateGate.v` 承接 branch direction predictor 的
  pending lookup capture、lookup sideband、direct/pending/drained/commit update
  class、actual/predicted taken 选择、update PC/BHT index 选择和 correctness
  组合事实；父模块仍保留 predictor table 实例、branch pending/spec/wait 状态、
  resolve/recovery sequencer、RAS/BTB update 和 PC/outstanding 时序所有权。
- `frontend/OooBranchTargetCacheControlGate.v` 承接 branch target cache/capture
  buffer 上游的 store fire/address、commit `MISC-MEM` 全失效、direct branch
  redirect 后 capture arm 和 branch PC 选择组合事实；父模块仍保留 branch target
  cache/capture buffer 实例、direct branch resolve、dispatch/FIFO 和 PC/outstanding
  时序所有权。
- `frontend/OooFrontendRunGate.v` 承接前端运行许可、stop pending owner/orphan
  判定、response bypass 条件和 fetch FIFO/outstanding credit 组合 gating；父模块仍保留
  stop pending 清理、PC/outstanding/discard、FIFO 存储和 redirect/trap 时序所有权。
- `frontend/OooFrontendActionGate.v` 承接 direct frontend flush、stop-head、
  FIFO pop、fetch response control-stop 和 trap-blocked request 的组合动作谓词；
  父模块仍保留 PC 选择、response ready-valid、FIFO storage 和 pending/redirect/trap
  时序所有权。
- `frontend/OooFetchRequestMux.v` 承接 fetch request PC/source 的组合选择，
  在 redirect、branch prefetch 与顺序 PC 之间保持旧优先级；父模块仍保留
  `next_fetch_pc`、outstanding/discard、redirect recovery 和 request ready-valid
  时序所有权。
- `frontend/OooBranchPrefetchSourceGate.v` 承接 pending branch target/predicted
  PC 与 pending JALR return-hint/BTB-lookup 的组合 source facts；父模块仍保留
  pending 状态、RAS/BTB 表项、request gate、branch resolve 和 recovery 时序所有权。
- `frontend/OooBranchPrefetchRequestGate.v` 承接 pending branch 与 JALR BTB hit
  发起 prefetch request 的组合 gating 和 request PC 选择；父模块仍保留 BTB/RAS
  lookup、branch resolve、prefetch buffer、outstanding/discard 和 fetch request
  ready-valid 时序所有权。
- `frontend/OooBranchPrefetchStatusGate.v` 承接 branch prefetch response capture
  与 branch resolve hit/pending status 的组合判定；父模块仍保留 prefetch buffer
  写入/清空、hit packet 选择、JALR 专用 hit status 和 recovery 时序所有权。
- `frontend/OooJalrPrefetchStatusGate.v` 承接 JALR branch-prefetch target
  ready、target mux、hit/pending status 的组合判定；父模块仍保留 JALR resolve、
  BTB update、hit packet 选择和 PC/outstanding/discard 时序所有权。
- `frontend/OooBranchPrefetchBuffer.v` 承接 branch prefetch 影子包状态，只保存
  active/request PC、buffer valid 和 packet payload；父模块仍决定 request/capture/clear、
  branch resolve match、FIFO seed 和 redirect PC。
- `frontend/OooDirectBranchWaitBuffer.v` 承接 direct branch 等待后端 resolve 的单 entry
  状态，只保存 pending 和 branch PC；父模块仍负责 resolve match/untracked、redirect、
  trap 和 BPU 更新。
- `frontend/OooBackendDrainTracker.v` 承接前端视角下的 backend drained 打拍状态；
  父模块仍负责组合计算 ROB/IQ/retire/synthetic lane1 是否为空，以及 pending/trap
  控制使用该状态的策略。
- `frontend/OooFetchPacketHitMux.v` 承接 branch/JALR prefetch hit payload 在
  same-cycle response capture 与 buffered packet 之间的组合选择；父模块仍负责
  hit/match 判定和 redirect/FIFO seed 策略。
- `frontend/OooFetchPacketHeadMux.v` 承接 dispatch 可见 fetch packet head 的来源选择，
  只在 response bypass 与 FIFO head payload 之间做组合 mux；父模块仍决定 bypass
  条件、FIFO pop/seed 和 redirect/trap recovery。
- `frontend/OooFetchPacketSeedMux.v` 承接前端 redirect/recovery 事件到 FIFO
  clear/seed 动作的组合编码；父模块仍负责生成事件谓词、验证 prefetch hit 和更新
  `next_fetch_pc`。
- `frontend/OooFetchPacketFifo.v` 承接前端取指 packet FIFO 的 head/tail/count
  与 packet storage；父模块仍保留 response bypass、outstanding/stale response、
  redirect/flush/seed 仲裁和 `next_fetch_pc` 更新。
- `frontend/OooFetchFlowControl.v` 承接前端 fetch request/response ready-valid
  组合策略；父模块仍保留 PC 选择、outstanding/discard 状态和精确 redirect/trap
  状态更新。

新增 helper module 时优先放入对应外层目录，并在 `vsrc/filelist.mk` 中以
同名 `RTL_*` 变量显式登记，避免重新形成并行目录体系。
