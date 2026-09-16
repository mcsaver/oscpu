# OooFrontend 子系统 wrapper Spec

## 1. 目标

子系统 wrapper 分层战线的最大一刀：把 `frontend/` 目录的 49 个取指/分支预测 owner
连同 6 个服务于前端的 `DecodeStage` 解码器，聚合到 `frontend/OooFrontend.v`，让
`OooCoreTopGlue` 只对前端子系统做一次实例化。纯结构聚合，不新增逻辑、不改行为。

## 2. 责任边界（内部 owner，行为不变）

| 子域 | 内部 owner |
| --- | --- |
| 运行/动作准入 | `OooFrontendRunGate`、`OooFrontendActionGate`、`OooFrontendUopSafety`(×多) |
| 取指请求/流控/FIFO/PC outstanding | `OooFetchRequestMux`、`OooFetchFlowControl`、`OooFetchPacketFifo`、`OooFetchPacketSeedMux/HeadMux/HitMux/Decode`、`OooFetchPcOutstandingSequencer` |
| fetch head 分类/配对 | `OooFetchHeadPairGate`（内含 classify gate）、`OooFrontendDispatchGate`、`OooFrontendBackendDispatchMux` |
| 分支方向预测/BPU/BTB/JALR | `OooBranchDirectionPredictor`、`OooBranchBpuUpdateGate`、`OooPredictorUpdateGate`、`OooBranchTargetCache(+ControlGate+CaptureBuffer)`、`OooJalrBtb`、`OooJalrPrefetchStatusGate` |
| RAS/return continuation | `OooRasStack`、`OooRasUpdateGate`、`OooDirectRasCandidateGate`、`OooReturnContBuffer`、`OooDirectControlFlowGate` |
| branch prefetch | `OooBranchPrefetch{Source,Request,Status,Clear}Gate`、`OooBranchPrefetchBuffer` |
| 分支解析/恢复/spec | `OooDirectBranchResolveGate`、`OooDirectBranchWaitBuffer`、`OooBranchResolveRecoveryGate`、`OooBranchSpecTracker`、`OooBranchAppendDispatchGate`、`OooPendingControlResolveGate`、`OooPendingBranchSequencer`、`OooPendingJumpSequencer`、`OooBackendDrainTracker` |
| 前端解码 | 6×`DecodeStage`（head0/head1、branch target capture、branch prefetch0/1/rsp1） |

## 3. 接口与不变量

- wrapper 端口 = 49+6 个内部实例与 glue 其余部分跨边界的全部信号（270 个），
  方向由"谁驱动"决定（owner 输出且被外部消费→输出；外部/顶层输入驱动且被内部消费→输入）。
- glue 顶层 wire 名全部保留：所有被 testbench / `NpcSimTop` trace 探测的前端信号
  （`fifo_has_packet_w`、`branch_resolve_redirect_w`、`stop_pending_q` 经由相邻子系统等）
  仍以同名 glue wire 形式存在（wrapper 端口连线），保证 `dut.<sig>` / `u_ooo_core.<sig>`
  探针不失效。
- **深层探针路径更新**：`tb_ooo_fetch_trap_gate.sv` 对 `u_branch_resolve_recovery_gate`
  与 `u_direct_branch_resolve_gate` 的内部 `force/release` 探针，路径前缀加 `u_frontend.`
  （`dut.u_frontend.u_branch_resolve_recovery_gate.*`），因为这两个实例已下沉到 wrapper 内。
- wrapper 参数只保留实际被内部实例使用的结构参数（`PHY_REG_ADDR_W`/`ROB_*`/
  `ISSUE_COUNT_W`/`FETCH_PACKET_COUNT_W` 等），并在内部重算用到的 localparam
  （`FETCH_COUNT_W`/`FETCH_PACKET_COUNT_VALUE`/`ENABLE_DIRECT_RAS_RET`/
  `BRANCH_TARGET_CACHE_INDEX_W`）；glue 顶层不再保留这些 localparam。

## 4. 验证

- `make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` build PASS。
- 默认 module testbench 103/103 PASS（含 `tb_ooo_core_top_glue`、更新探针后的
  `tb_ooo_fetch_trap_gate`、`tb_ooo_priv_system`、`tb_ooo_sv39_boot`）。
- official riscv-tests（default+A+FP+privileged，177 项）0 FAIL。

## 5. 边界

本刀只完成 frontend 子系统 wrapper 抽取；不改变取指/预测/RAS/BPU/pending control
任何状态机、redirect/recovery 语义或时序。
