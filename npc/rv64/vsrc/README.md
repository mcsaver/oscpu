# RV64 RTL 目录

`vsrc/` 是唯一 RTL 功能分层入口，不再额外套 `ooo/` 外壳。`Ooo*` 模块名只表示
它属于当前乱序核实现，物理目录按职责和现有外层目录合并：

- `frontend/`：PC 生成、分支预测、pending branch/jump sequencer、BPU update gate、RAS、direct control-flow gate、predictor update gate、return-continuation、branch target capture、branch append dispatch gate、branch prefetch request/clear gate、branch prefetch buffer、direct branch wait buffer、backend drain tracker、front-end uop safety policy、front-end dispatch gate、front-end/backend dispatch mux、front-end run gate、front-end action gate、fetch request mux、fetch packet decode、fetch head classify、fetch head pair gate、fetch packet FIFO、fetch flow-control、取指 AXI bridge、前端控制壳。
- `common/`：跨阶段共享的 packed bus/header 定义；当前 `OooSlotFacts.v` 维护 fetch/decode slot facts，
  `OooRedirect*Facts.vh`、`OooBranchDirectionPredictorFacts.vh`、
  `OooFetchPacketCacheFacts.vh` 与 `OooDataWordCacheFacts.vh` 维护 debug 观测层 facts bit
  layout，用于审核 RTL 是否符合 spec 语义。
- `decode/`：基础 decode、立即数生成、RVC 预译码、FP decode、OoO decode glue。
- `cache/`：取指包 cache（4096 项直接映射 VIVT、1RW 同步读，物理读窗与语义 accept
  分离）与 data word cache（32KB 直接映射 PIPT dcache，write-through/no-allocate）。
- `rename_allocate/`：rename map、free list、busy table、dispatch/ROB/IQ 分配。
- `scheduling/`：issue queue、wakeup/select 相关调度状态。
- `regread_bypass/`：整数物理寄存器堆、FP 架构/物理寄存器堆（由
  `execute/OooFpBackend.v` 例化）、pending operand read gate 与后续旁路网络落点。
- `execute/`：基础 ALU/Compare、OoO ALU slice、整数后端（含 AMO/bitmanip gate）、MUL/DIV、CLMUL，以及 FP 真乱序簇——`OooFpBackend` 装配壳（内部例化架构/物理 FPR 与 FP IQ）、FP 运算 gate 族（FADD/FMUL 3 级、FMA 5 级流水）与 FDIV/FSQRT 迭代单元；旧 pending FP sequencer 与 FP pending 执行数据通路已拆除。
- `memory/`：LSU、Sv39 TLB、store queue（SQ，probe→commit→drain，store-to-load 前递已落地）、mem 在飞队列（MIQ）、PMP checker、具体 NpcTop 地址图的 fail-closed PMA checker、memory request gate、memory AXI bridge、LSU logical-window→standard-lane adapter；pending memory sequencer 已证死，MSHR 未做。
- `writeback/`：WBU、ROB、退休、synthetic lane1 retire commit gate（已证死）、commit output mux 和 commit 侧架构寄存器观测镜像；旧 FP commit gate 已随 pending-FP 拆除。
- `control/`：flush/recovery/pending SYSTEM/CSR/interrupt/pending trap-exit、
  pending drain/resolve gate、CSR illegal probe gate、core slice control gate、final trap/debug/CSR observable output、PMU 等跨阶段控制的落点。
- `core/`：顶层装配（`NpcTop.v`/`NpcCoreTop.v`/`OooCoreTopGlue.v`）与 CSR 状态实现 `CsrFile.v`。
- `bus/`：SoC AXI/AXI-Lite 互连与外设（crossbar、CLINT、PLIC、UART、default slave）。
- `include/`：`define.v` 全局宏（`XLEN`、`OOO_*` 容量、模式开关）。
- `sim/`：仿真专用壳（`NpcSimTop.sv`、AXI DPI slave、virtio-blk）；`.sv` 仅限验证侧。
- `debug/`：旁挂仿真 checker，配合 `common/*Facts*` 审核 RTL 是否符合 spec 语义；不进入
  `RTL_CORE_SRCS`，当前 BPU、取指包 cache 与 D-cache checker 先由 focused TB 覆盖。

> ⚠️ **状态（2026-07-03 RTL 重读）**：下文条目含大量历史演进记录。pending
> branch/jump/mem 三通道、dispatch 拍分支快解析、BTC/JALR-BTB 更新口/
> branch-prefetch 族、return-continuation、synthetic lane1-ret 族、checkpoint
> 影子阵列与 fetch 响应 bypass 直通已被形式化证死（编译在册、结构性不可达）；
> pending-FP 通道已物理拆除，FP 为真乱序簇。分支/JAL/JALR 现走 F2 真预测
> （pred_npc 单源随 uop 下行、issue 级
> 统一解析、ROB-walk 恢复），load/store/AMO 走 SQ+probe/drain+MIQ，域 B 只剩
> system/trap/IRQ 类。当前拓扑、开放合同与历史边界见
> `../design/arch/rtl-ground-truth-2026-07-11.md`
> §4，拆除计划见 `../design/arch/ooo-core-architecture.md` §8.3。涉及死硅的条目
> 仅保留设计语义描述。

跨阶段控制状态机已外置到 `control/`（子系统 wrapper 为 `control/OooControlPlane.v`），
全局装配壳位于 `core/OooCoreTopGlue.v`，CSR 状态实现仍是 `core/CsrFile.v`，其实例
已上提到 `core/NpcCoreTop.v`，由顶层直接连接 fetch/memory bridge 与 core glue 的
CSR 事件/状态边界；FPR 状态（架构 `regread_bypass/OooFpRegFile.v` 与物理
`OooFpPhysRegFile.v`）现由 `execute/OooFpBackend.v` 内部装配。后续拆分应继续把
功能规则向对应目录收敛，避免 core glue 重新膨胀。

`core/OooCoreTopGlue.v` 已按"目录即架构边界"做子系统 wrapper 分层：不再扁平例化
~80 个 owner，而是只例化 5 个目录对齐的子系统 wrapper —— `frontend/OooFrontend.v`
（含 6 个前端 `DecodeStage`）、`control/OooControlPlane.v`、`execute/OooExecuteBackend.v`、
`writeback/OooWriteback.v`、`memory/OooMemoryAccess.v` —— 外加单模块叶子
`regread_bypass/OooPendingOperandReadGate.v`。wrapper 抽取是纯结构变换：只把跨边界
信号导出为端口、把仅内部使用的信号下沉，不新增逻辑、不改行为，glue 顶层 wire 名
全部保留以兼容 testbench/trace 探针。各 wrapper 边界见
`design/specs/ooo-{control-plane,execute-backend,writeback,memory-access}.md`
与 `design/specs/ooo-core-top-glue.md`；frontend wrapper 的一次性抽取记录已归档至
`design/specs/history/ooo-frontend.md`(已归档)。经此分层 glue 降为 6 个实例、约 1.3k 行、0 个
`always`。

当前 RV64 LSU 在 core-private 边界使用 byte-addressed logical window：请求地址
保持 exact PA，`wdata/wstrb` 从 lane0 开始表达访问宽度。
`memory/OooLsuAxiLaneAdapter.v` 在 NpcCoreTop master 边界将自然对齐请求转为
标准 AXI byte lane，只对完整范围已通过 translation/PMP/PMA 的普通 PMEM
非对齐请求逐 byte split 并聚合 R/B。crossbar、设备、DPI 与对外 64-bit 端口
均只看标准 lane/AxSIZE；MMIO/PTE 不获得 split 授权。
AMO/LR/SC 仍在执行后端保留对齐异常约束。

OoO 结构容量默认值统一由 `include/define.v` 中的 `OOO_*` 宏维护：
`OOO_PHY_REG_ADDR_W/OOO_PHY_REG_COUNT/OOO_FREE_COUNT_W`、`OOO_ROB_INDEX_W/OOO_ROB_COUNT_W`、
`OOO_ISSUE_INDEX_W/OOO_ISSUE_COUNT_W` 和 `OOO_FETCH_PACKET_COUNT_W`。顶层调试计数端口和
PRF/FreeList/ROB/IQ/fetch FIFO 默认参数必须引用这组宏；实际改变容量后需要重新跑
module/core 回归和性能样本分析。

当前 privileged/core-regress 相关边界：

- `core/CsrFile.v` 提供最小 debug trigger no-op CSR、`pmpcfg0/2`+`pmpaddr0-15`
  CSR 存储（TOR/NA4/NAPOT + lock 链）、`misa` WARL no-op 写入，以及
  `mstatus.TVM/TW/TSR` 可写位；
  当前由 `core/NpcCoreTop.v` 直接例化，`OooCoreTopGlue` 只导出 CSR access/trap/
  fflags/retire 事件并消费 CSR 状态。T3K 起 CSR 接口分为 commit/pending/readback
  使用的 `csr_access_*` 与 current-head-only、无副作用的 `csr_probe_*`；两者在
  `CsrFile` 内复用唯一 legality predicate，但 probe 结果不参与架构状态更新。
- `frontend/OooFetchStaticClassify.v` 在 fault-sanitized response 指令上一次性生成每槽
  18-bit 静态 facts（15 类 FP、raw double、DYN-rm-bearing、semihost peer signature），
  不读取 privilege/CSR/fault/visibility 等 head-time 状态。
- `frontend/OooFetchHeadClassifyGate.v` 承接单个 fetch head 的 decoder illegal、
  branch/jump/memory、已存静态 FP facts 的可见性重组、FS-off FP、semihost EBREAK、ECALL/CSR/xRET/WFI、
  supervisor fence/TVM/TSR privilege illegal、stop 和 architectural trap 组合事实；
  同时输出 `common/OooSlotFacts.v` 定义的 `facts_o` packed bus，作为旧散线的
  等价 alias；
  父模块仍保留 fetch FIFO、pending owner、CSR side effect、trap capture 和 precise
  recovery 时序所有权。
- `frontend/OooFetchHeadPairGate.v` 承接双槽 fetch head 可见性、head0/head1
  classifier 实例、fetch fault 汇总、branch-spec dispatch block 和 dispatch0
  ECALL/EBREAK/exit/arch-trap/system/FP/branch/JAL/JALR 组合 facts；内部局部判断已
  优先消费 `head0_facts_o/head1_facts_o` packed bus，但旧散线端口继续保留；父模块仍保留
  ready/unsupported fire、direct JAL/ret、RAS/BPU、pending owner、CSR side effect、
  fetch FIFO、PC/outstanding 和 precise recovery 时序所有权。
- `core/OooCoreTopGlue.v` 通过 `OooFetchHeadPairGate` 获取
  decoder illegal、FS-off FP illegal、`sfence.vma` under TVM、`sret` under TSR 等
  精确前端 trap facts；被 `OooFpDecode` 识别的 OP-FP 指令不能再被整数 decoder 的
  illegal 位抢先 trap。
- `control/OooPendingLane1CaptureGate.v` 承接 lane1 barrier 后的局部 owner
  分型和 trap/exit payload 组合计算；它不判断 lane0/IRQ/resolve/global clear，
  只消费 `head1_facts_i`、fetch fault/resp、PC/inst 和 CSR illegal probe。
- `control/OooPendingDispatchArbiter.v` 承接 fetch/dispatch facts 到 pending
  branch/jump/memory/FP/SYSTEM/trap-exit capture/clear 的纯组合仲裁；当前已接入
  `dispatch0_facts_i/head1_facts_i` packed bus 作为 slot 事实输入边界，旧事实散线
  兼容端口已删除；lane1 branch/jump/memory/FP/SYSTEM capture 与 trap/exit
  lane1 payload 已下沉到 `OooPendingLane1CaptureGate`，trap-exit lane1 capture 保留 scrub stale valid
  bit 的旧语义。
- `control/OooPendingDrainResolveGate.v` 承接 stop-pending 后的 backend drained、
  pending replay wait、drain complete、branch commit resolve/match clear、jump/system/mem
  dispatch valid/fire 组合中枢（FP start 臂已随 pending-FP 拆除；jump/mem 臂随
  pending 通道证死）；父模块只消费这些事件，不再内联 pending/drain 规则。backend
  drained 不再重复读取 core retire count：ROB-empty 已严格蕴含本拍无 ROB commit，
  `OooAluCoreSlice` 的 `[CORE-RETIRE-REQUIRES-ROB]` 守护该跨模块定理。
- `memory/OooMemAxiBridge.v` 与 `frontend/OooFetchAxiBridge.v` 已按 Sv39
  leaf PTE 检查 A/D 位：A=0 或 store 且 D=0 返回 page fault，不把该 PTE
  填入 TLB。
- `execute/OooIntBackend.v` 的 buffered memory drain 保持 exact effective
  address，避免正常窄 load/store 在缓冲路径被错误对齐到 8B 边界。
- pending FP 通道（原 `execute/OooFpPendingExec.v`、`execute/OooPendingFpSequencer.v`、
  `writeback/OooFpCommitGate.v`）已整体拆除：FP 现为真乱序簇，由
  `execute/OooFpBackend.v` 装配独立 rename/FP IQ/运算流水（FADD/FMUL 3 级、
  FMA 5 级）与 FDIV/FSQRT 迭代单元，fflags 随 ROB commit 架构序累积。
- `regread_bypass/OooFpRegFile.v` 承接架构 FPR 状态，现由 `execute/OooFpBackend.v`
  内部例化，与 `OooFpPhysRegFile.v` 共同构成 FP 簇寄存器状态。
- `regread_bypass/OooPendingOperandReadGate.v` 承接 pending branch/jump 需要的
  架构 GPR 解包（FP index 提取已随 pending-FP 拆除）；父模块不再定义 `arch_gpr()`
  或直接解包 `core_debug_gprs_w`。
- `memory/OooMemoryRequestGate.v` 承接 OoO core lane0/lane1 memory request、
  response ready、`mem_flush` 和 `mmu_flush` 的纯组合边界（pending FP memory
  request 臂已随 pending-FP 拆除）；父模块仍保留 core LSU 状态和 precise
  trap/flush 时序所有权。
- `memory/OooPendingMemorySequencer.v` 承接 lane1 memory barrier 的 pending memory
  单 entry 注册状态；父模块仍负责 pending owner arbitration、LSU/MMU request、
  memory trap、backend drain、fetch redirect 和 precise recovery。
- ~~`frontend/OooPendingBranchSequencer.v`~~ **已删（wave5b 死硅拆除）**：capture 三臂全被
  `!rob_walk_mode`(OOO_ROB_WALK_MODE=1'b1)门死 → 状态恒 0；分支恢复改走 issue-resolve+ROB-walk。
- ~~`frontend/OooPendingJumpSequencer.v`~~ **已删（wave5b 死硅拆除）**：capture 同样门死 → 状态恒 0；
  JAL/JALR 走 direct RAS/spec + issue-resolve。
- `frontend/OooDirectRasCandidateGate.v` 承接 direct RAS/RAS-ret 候选组合事实：
  lane0/lane1 JAL call-like raw、RAS direct update safe、lane0 direct return 和
  lane1 return candidate；父模块仍保留 RAS 栈、return-cont buffer、direct jump/ret
  fire、PC redirect 和 dispatch/FIFO 时序所有权。
- `frontend/OooDirectControlFlowGate.v` 承接 direct branch0 fire、direct JAL/RET
  fire 聚合、direct JAL target/link/call、return-cont capture/match 和 direct ret target
  组合事实；父模块仍保留 RAS 栈、return-cont buffer、dispatch payload、PC/outstanding
  和 redirect 时序所有权。
- `frontend/OooRasUpdateGate.v` 承接 RAS 栈上游 clear/pop/push/push-value
  组合更新控制；父模块和 `OooRasStack` 仍保留 RAS 状态、可靠性、栈顶以及
  同周期 clear/pop/push 的时序优先级；旧 pending lane1-ret dispatch replay
  已删除，不再作为 RAS pop 输入。
- `frontend/OooFetchPacketDecode.v` 承接取指 response packet 的 RVC 半字拼接、
  解压、slot PC/next PC、slot response 和 control-stop 组合事实；父模块仍保留
  response ready-valid、FIFO、redirect 和 trap/flush 策略。
- `frontend/OooFetchBranchTarget.v` 以 13-bit B-imm 和 4KiB 页内 carry/sign 修正计算
  RV64 条件分支目标，避免跨模块 XLEN-wide sign-extension；父模块仍保留预测选择、
  FIFO/outstanding 落账和 redirect 优先级。
- `frontend/OooFrontendUopSafety.v` 承接前端 fast path 使用的普通 uop 安全白名单
  组合策略；父模块仍保留 dispatch payload、prefetch 转正和 precise recovery
  的时序所有权。
- `frontend/OooFrontendDispatchGate.v` 承接前端 dispatch 入口的 lane1/direct
  fast-path、barrier、unsupported、normal dispatch fire、frontend-to-backend valid 和
  lane1 barrier dispatch0 valid 组合 gating；父模块仍保留
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
  pending owner 捕获/清理、CSR/trap side effect、ROB commit mux 和
  PC/outstanding 时序。
- `writeback/OooCommitOutputMux.v` 承接 control pseudo-commit、branch append
  与 ROB commit0/commit1 到外部 commit/retire 端口的纯组合 mux；父模块仍负责
  ROB/CSR/trap side effect 和 pending owner 清理。
  （旧 synthetic lane1 return 合成臂已随 OooSyntheticLane1Ret 家族删除，
  rtl-ground-truth §4：capture 路径恒 0。）
- `control/OooControlFlushSequencer.v` 承接 `core_trap_flush`、
  `trap_redirect_squash` 和 `checkpoint_mem_flush` 注册状态；父模块仍负责 CSR/trap
  side effect、pending owner 清理、branch checkpoint 事件和 PC/outstanding 时序。
- `control/OooCsrAccessRequestMux.v` 承接 commit0 CSR、pending SYSTEM CSR、
  lane1 CSR head 与 lane0 head 到 `CsrFile` main access request 的纯组合选择，
  并另行导出不依赖 commit/pending 的 head-only legality probe；
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
  sticky 输出寄存器与 payload；父模块仍负责 CSR/trap side effect、fetch redirect
  和 precise recovery。
- `control/OooCoreObservableOutputGate.v` 承接最终对外 trap/exit/halt、CSR state
  passthrough、debug PC/state/GPR 和 exit code 的纯组合输出选择；父模块不再内联
  terminal/debug observable 规则。
- `control/OooCoreSliceControlGate.v` 承接 branch checkpoint capture/restore/quiesce、
  branch-spec memory issue block、core local flush、core commit ready 和 commit1 block
  组合准入；父模块只把结果接到 `OooAluCoreSlice`、memory bridge 和 flush sequencer。
- `control/OooCsrIllegalProbeGate.v` 承接 lane0/lane1 CSR illegal probe 归属选择；
  父模块仍保留 CSR request mux、CSR 文件实例、pending owner 和 trap side effect。
- `control/OooTrapExitEventMux.v` 承接最终 trap/exit terminal event 与 payload
  的纯组合选择；父模块仍负责提供 branch/jump/drain/pending facts、CSR/trap side
  effect、exit-code 选择、fetch redirect 和 precise recovery。
- `core/OooCoreTopGlue.v` 中旧 `pending_lane1_ret_*` dispatch replay 状态已删除；
  OooSyntheticLane1Ret 家族（Sequencer/CommitGate）亦已删除（rtl-ground-truth §4：
  capture 依赖拍内解析同拍谓词，F2 下经 `direct_branch0_lane1_ret_w` 恒 0）。
  当前 lane1 return 延迟可见性由 direct RAS 事件与 issue-resolve/ROB-walk 承担。
- ~~`frontend/OooPendingControlResolveGate.v`~~ **已删（wave5b 死硅拆除）**：全部输出由
  pending_branch/pending_jump（capture 恒 0 → 恒 0）派生，纯组合恒 0（pending_control_ready 恒 1）；
  已就地 tie-off，随 pending_branch/jump sequencer 一并退休。
- `frontend/OooBranchAppendDispatchGate.v` 承接 return-cont、branch target/
  fallthrough lane1 append candidate/attempt/dispatch、fallthrough outstanding
  keep/capture、branch prefetch direct-dispatch dead-path 和 `dispatch1_optional`
  组合门控；父模块仍保留相关状态寄存器、dispatch payload mux、FIFO seed/enqueue
  和 PC/outstanding/discard 时序所有权。
- `frontend/OooBranchBpuUpdateGate.v` 承接 branch direction predictor 的
  pending lookup capture、lookup sideband、direct/pending/drained/commit update
  class、actual/predicted taken 选择、update PC/BHT index 选择和 correctness
  组合事实（F2 后 BPU 回训单源=issue-resolve，direct/pending/drained/commit
  旧四臂已证死）；父模块仍保留 predictor table 实例、branch pending/spec/wait 状态、
  resolve/recovery sequencer、RAS/BTB update 和 PC/outstanding 时序所有权。
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
- `frontend/OooDirectBranchWaitBuffer.v` 承接 direct branch 等待后端 resolve 的单 entry
  状态，只保存 pending 和 branch PC；父模块仍负责 resolve match/untracked、redirect、
  trap 和 BPU 更新。
- `frontend/OooBackendDrainTracker.v` 承接前端视角下的 backend drained 打拍状态；
  父模块仍负责组合计算 ROB/IQ/retire/synthetic lane1 是否为空，以及 pending/trap
  控制使用该状态的策略。
- `frontend/OooFetchPacketHeadMux.v` 承接 dispatch 可见 fetch packet head 的来源选择，
  当前是 registered FIFO head bundle（含双槽 static facts）的 identity view；父模块仍决定
  FIFO pop/seed 和 redirect/trap recovery。
- `frontend/OooFetchPacketSeedMux.v` 承接前端 redirect/recovery 事件到 FIFO
  clear/seed 动作的组合编码；父模块仍负责生成事件谓词、验证 prefetch hit 和更新
  `next_fetch_pc`。
- `frontend/OooFetchPacketFifo.v` 承接前端取指 packet FIFO 的 head/tail/count
  与 packet storage；T3W 要求每槽 18-bit static facts 与 inst/predecode/response 元数据
  同表项原子写读；父模块仍保留 outstanding/stale response、
  redirect/flush/seed 仲裁和 `next_fetch_pc` 更新。
- `frontend/OooFetchFlowControl.v` 承接前端 fetch request/response ready-valid
  组合策略；父模块仍保留 PC 选择、outstanding/discard 状态和精确 redirect/trap
  状态更新。

新增 helper module 时优先放入对应外层目录，并在 `vsrc/filelist.mk` 中以
同名 `RTL_*` 变量显式登记，避免重新形成并行目录体系。
