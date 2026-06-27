# Dispatch Log

## 基本信息

- `task_id`: `2026-06-26-npc-rv64-ooo-alufetchcore-industrial-spec`
- `task_slug`: `npc-rv64-ooo-alufetchcore-industrial-spec`
- `graph_template`: `custom`
- `log_policy`: `append-only`

---

### [2026-06-26] `recall-audit` - `completed`

- `owner_agent`: `codex`
- `action`: 读取项目规则、NPC/RV64 记忆、RTL workflow、RV64 README/study/vsrc README，并审计 `OooAluFetchCore` 端口/状态/实例/always/function 分布。
- `outputs`: 确认 `OooAluFetchCore` 混合 front-end、pending control、FP datapath、CSR/trap/commit glue；FP helper 函数和组合数据通路是第一低风险拆分候选。

### [2026-06-26] `spec` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `ooo-alufetchcore-boundary.md` 与 `ooo-fp-pending-exec.md`。
- `outputs`: 明确父模块/子模块责任、不变量、协议、状态机和数据通路。

### [2026-06-26] `rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `execute/OooFpPendingExec.v`，更新 `frontend/OooAluFetchCore.v` 和 `vsrc/filelist.mk`。
- `outputs`: `OooAluFetchCore` 行数 7631 -> 3963；FP pending 算法数据通路进入 execute 目录。

### [2026-06-26] `verify` - `completed`

- `owner_agent`: `codex`
- `action`: focused TB、lint、build、full module TB、FP smoke、official FP riscv-tests。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fp-pending-exec/` 与 `npc/rv64/perf/results/core-regress/20260626-191816-407165/`。
- `notes`: 验证中暴露 FP smoke 旧假设：部分裸机 FP smoke 未打开 `mstatus.FS`，`fp-convert` 对 `FCVT.WU.*` 期望未按 RV64 sign-extension；已修并复验。

### [2026-06-26] `fetch-fifo-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 fetch FIFO enqueue/pop/clear/seed/bypass 数据流，新增 `npc/rv64/design/specs/ooo-fetch-packet-fifo.md`。
- `outputs`: 明确新模块只负责 FIFO storage，父模块保留 bypass、outstanding、redirect、flush、seed 仲裁。

### [2026-06-26] `fetch-fifo-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchPacketFifo.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_packet_fifo.sv`。
- `outputs`: `OooAluFetchCore` 删除旧 FIFO 指针/数组/计数器和内联 payload 写入，改用组合 action encoder + FIFO 实例；当前行数 3952。

### [2026-06-26] `fetch-fifo-verify` - `completed`

- `owner_agent`: `codex`
- `action`: FIFO 单测、fetch core focused、lint、build、full module TB、official riscv-tests。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fetch-packet-fifo/` 与 `npc/rv64/perf/results/core-regress/20260626-193707-415746/`。
- `notes`: 默认 module regression 从 53 项扩展为 54 项，新增 `tb_ooo_fetch_packet_fifo`。

### [2026-06-26] `fetch-flow-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 fetch request/response ready-valid、bypass、enqueue/drop、FIFO pop 与 dispatch stall 数据流，新增 `npc/rv64/design/specs/ooo-fetch-flow-control.md`。
- `outputs`: 明确新模块只负责纯组合 flow-control；父模块继续持有 PC/outstanding/discard/redirect/trap 状态和 FIFO seed 仲裁。

### [2026-06-26] `fetch-flow-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchFlowControl.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_flow_control.sv`。
- `outputs`: `OooAluFetchCore` 删除对应内联 ready/valid/drop/pop 组合赋值，改由 `u_fetch_flow_control` 生成；当前行数 3968。

### [2026-06-26] `fetch-flow-verify` - `completed`

- `owner_agent`: `codex`
- `action`: flow-control 单测、fetch core focused、lint、build、full module TB、official riscv-tests。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fetch-flow-control/` 与 `npc/rv64/perf/results/core-regress/20260626-194831-432963/`。
- `notes`: 默认 module regression 从 54 项扩展为 55 项，新增 `tb_ooo_fetch_flow_control`。

### [2026-06-26] `fetch-packet-decode-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 fetch response word/halfword/RVC 拼接、slot response 归属和 control-stop 数据流，新增 `npc/rv64/design/specs/ooo-fetch-packet-decode.md`。
- `outputs`: 明确新模块只负责 packet decode 组合事实；父模块继续持有 dispatch、FIFO、ready-valid、redirect、trap/flush 和 outstanding 状态。

### [2026-06-26] `fetch-packet-decode-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchPacketDecode.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_packet_decode.sv`。
- `outputs`: `OooAluFetchCore` 删除内联 half/RVC packet decode 组合逻辑，改由 `u_fetch_packet_decode` 生成 slot PC/inst/resp/control-stop；当前行数 3943。

### [2026-06-26] `fetch-packet-decode-verify` - `completed`

- `owner_agent`: `codex`
- `action`: packet decode 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联信号扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fetch-packet-decode/` 与 `npc/rv64/perf/results/core-regress/20260626-195747-449939/`。
- `notes`: 默认 module regression 从 55 项扩展为 56 项，新增 `tb_ooo_fetch_packet_decode`；`rv64uc-p-rvc` 在官方回归中 PASS。

### [2026-06-26] `frontend-uop-safety-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 lane0-before-ret、return-continuation、branch fallthrough/target capture、branch prefetch packet 转正候选的普通 uop 白名单差异，新增 `npc/rv64/design/specs/ooo-frontend-uop-safety.md`。
- `outputs`: 明确新 helper 只负责组合安全谓词；父模块继续持有 dispatch、branch append、prefetch 转正、redirect 和 precise recovery 时序所有权。

### [2026-06-26] `frontend-uop-safety-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFrontendUopSafety.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_frontend_uop_safety.sv`。
- `outputs`: 删除旧 `branch_prefetch_plain_uop_safe` function，用参数化策略实例保留旧 fast path 间的差异；当前 `OooAluFetchCore` 行数 3994。

### [2026-06-26] `frontend-uop-safety-verify` - `completed`

- `owner_agent`: `codex`
- `action`: uop safety 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧函数扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-frontend-uop-safety/` 与 `npc/rv64/perf/results/core-regress/20260626-200912-467183/`。
- `notes`: 默认 module regression 从 56 项扩展为 57 项，新增 `tb_ooo_frontend_uop_safety`；本切片提升策略所有权清晰度，不以减少父模块行数为唯一目标。

### [2026-06-26] `frontend-dispatch-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 front-end dispatch 入口中 lane1 direct JAL/return/branch、barrier/unsupported、normal dispatch fire 和 direct-path fire 组合逻辑，新增 `npc/rv64/design/specs/ooo-frontend-dispatch-gate.md`。
- `outputs`: 明确新 helper 只负责纯组合 dispatch gate；父模块继续持有 slot0 branch fast path、pending sequencer、commit/trap/redirect 和 precise recovery 时序所有权。

### [2026-06-26] `frontend-dispatch-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFrontendDispatchGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_frontend_dispatch_gate.sv`。
- `outputs`: 删除对应旧内联 dispatch gate 组合赋值，保留 slot0 JAL 不计入 `dispatch_unsupported` 的历史语义；当前 `OooAluFetchCore` 行数 3957。

### [2026-06-26] `frontend-dispatch-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: dispatch gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-frontend-dispatch-gate/` 与 `npc/rv64/perf/results/core-regress/20260626-201950-484386/`。
- `notes`: 默认 module regression 从 57 项扩展为 58 项，新增 `tb_ooo_frontend_dispatch_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-26] `branch-prefetch-buffer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 branch prefetch request/capture/clear、buffer payload、resolve hit 和 FIFO seed 数据流，新增 `npc/rv64/design/specs/ooo-branch-prefetch-buffer.md`。
- `outputs`: 明确新 helper 只持有影子包状态；父模块继续决定 request/capture/clear、branch resolve match、FIFO seed、redirect PC 和 outstanding/discard。

### [2026-06-26] `branch-prefetch-buffer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchPrefetchBuffer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_prefetch_buffer.sv`。
- `outputs`: 删除父模块中 `branch_prefetch_* <=` 内联状态赋值，新增 `branch_prefetch_clear_w` 作为父模块保留的 recovery 仲裁输出；当前 `OooAluFetchCore` 行数 3929。

### [2026-06-26] `branch-prefetch-buffer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch prefetch buffer 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-branch-prefetch-buffer/` 与 `npc/rv64/perf/results/core-regress/20260626-203320-502387/`。
- `notes`: 默认 module regression 从 58 项扩展为 59 项，新增 `tb_ooo_branch_prefetch_buffer`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-26] `direct-branch-wait-buffer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 direct branch fire、same-cycle resolve、wait resolve match 和 trap clear 数据流，新增 `npc/rv64/design/specs/ooo-direct-branch-wait-buffer.md`。
- `outputs`: 明确新 helper 只持有 direct branch wait pending/PC；父模块继续决定 resolve match/untracked、redirect、trap 和 BPU update。

### [2026-06-26] `direct-branch-wait-buffer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooDirectBranchWaitBuffer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_direct_branch_wait_buffer.sv`。
- `outputs`: 删除父模块中 `direct_branch_wait_* <=` 内联状态赋值；当前 `OooAluFetchCore` 行数 3926。

### [2026-06-26] `direct-branch-wait-buffer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: direct branch wait buffer 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-direct-branch-wait-buffer/` 与 `npc/rv64/perf/results/core-regress/20260626-204020-518686/`。
- `notes`: 默认 module regression 从 59 项扩展为 60 项，新增 `tb_ooo_direct_branch_wait_buffer`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-26] `backend-drain-tracker-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 backend drained 打拍状态、backend empty 组合判定、普通 dispatch fire 和 CSR trap 强制 drain 完成路径，新增 `npc/rv64/design/specs/ooo-backend-drain-tracker.md`。
- `outputs`: 明确新 helper 只持有前端视角下的 drained 状态位；父模块继续生成 backend empty、dispatch fire、force drained 和所有 trap/interrupt/commit 仲裁。

### [2026-06-26] `backend-drain-tracker-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBackendDrainTracker.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_backend_drain_tracker.sv`。
- `outputs`: 删除父模块中 `backend_drained_q <=` 内联状态赋值，改由 `u_backend_drain_tracker` 输出；当前 `OooAluFetchCore` 行数 3932。

### [2026-06-26] `backend-drain-tracker-verify` - `completed`

- `owner_agent`: `codex`
- `action`: backend drain tracker 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-backend-drain-tracker/` 与 `npc/rv64/perf/results/core-regress/20260626-213051-543151/`。
- `notes`: 默认 module regression 从 60 项扩展为 61 项，新增 `tb_ooo_backend_drain_tracker`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-26] `fetch-packet-head-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 response dispatch bypass 与 FIFO head packet 之间的 head payload 选择，新增 `npc/rv64/design/specs/ooo-fetch-packet-head-mux.md`。
- `outputs`: 明确新 helper 只做组合 payload mux 和 `head_has_packet` 生成；父模块继续持有 bypass 合法性、FIFO pop/enqueue/seed、packet decode、redirect/trap recovery。

### [2026-06-26] `fetch-packet-head-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchPacketHeadMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_packet_head_mux.sv`。
- `outputs`: 删除父模块中 head packet payload 的内联 ternary mux，改由 `u_fetch_packet_head_mux` 输出；当前 `OooAluFetchCore` 行数 3946。

### [2026-06-26] `fetch-packet-head-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: head mux 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联 mux 扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fetch-packet-head-mux/` 与 `npc/rv64/perf/results/core-regress/20260626-213915-559886/`。
- `notes`: 默认 module regression 从 61 项扩展为 62 项，新增 `tb_ooo_fetch_packet_head_mux`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-26] `fetch-packet-seed-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 redirect/recovery、branch/JALR prefetch hit、CSR trap/commit、memory replay、drain-complete owner 到 FIFO clear/seed 的组合 action encoder，新增 `npc/rv64/design/specs/ooo-fetch-packet-seed-mux.md`。
- `outputs`: 明确新 helper 只负责 FIFO clear/seed 动作和 seed payload 选择；父模块继续生成所有 event predicate、验证 prefetch hit、维护 FIFO storage 和更新 `next_fetch_pc`。

### [2026-06-26] `fetch-packet-seed-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchPacketSeedMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_packet_seed_mux.sv`。
- `outputs`: 删除父模块中 FIFO clear/seed 内联 `always @*` action encoder，`fifo_clear_w` 与 `fifo_seed_*_w` 改由 `u_fetch_packet_seed_mux` 输出；当前 `OooAluFetchCore` 行数 3877。

### [2026-06-26] `fetch-packet-seed-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: seed mux 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fetch-packet-seed-mux/` 与 `npc/rv64/perf/results/core-regress/20260626-231828-593642/`。
- `notes`: 默认 module regression 从 62 项扩展为 63 项，新增 `tb_ooo_fetch_packet_seed_mux`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-26] `fetch-packet-hit-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 branch/JALR prefetch hit payload 在 response capture 与 buffer payload 之间的重复组合选择，新增 `npc/rv64/design/specs/ooo-fetch-packet-hit-mux.md`。
- `outputs`: 明确新 helper 只负责 hit packet payload mux；父模块继续负责 hit/match 判定、target validation、prefetch buffer state、redirect 和 FIFO seed 策略。

### [2026-06-26] `fetch-packet-hit-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchPacketHitMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_packet_hit_mux.sv`。
- `outputs`: 删除父模块中 branch/JALR prefetch hit payload 两组内联 ternary mux，改用 `u_branch_prefetch_hit_mux` 和 `u_jalr_prefetch_hit_mux`；当前 `OooAluFetchCore` 行数 3903。

### [2026-06-26] `fetch-packet-hit-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: hit mux 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联 mux 扫描。
- `evidence`: `npc/rv64/perf/results/20260626-ooo-fetch-packet-hit-mux/` 与 `npc/rv64/perf/results/core-regress/20260626-232509-609814/`。
- `notes`: 默认 module regression 从 63 项扩展为 64 项，新增 `tb_ooo_fetch_packet_hit_mux`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `frontend-run-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计前端 `stop_pending` owner/orphan、`can_run`、response dispatch bypass 和 FIFO/outstanding credit 判定，新增 `npc/rv64/design/specs/ooo-frontend-run-gate.md`。
- `outputs`: 明确新 helper 只负责运行许可、orphan/busy stop、bypass predicate 和 reserve credit 组合事实；父模块继续负责 stop pending 清理、PC/outstanding/discard、FIFO storage 与 redirect/trap recovery。

### [2026-06-27] `frontend-run-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFrontendRunGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_frontend_run_gate.sv`。
- `outputs`: 删除父模块中 run/stop/bypass/credit 的内联组合表达式，改由 `u_frontend_run_gate` 输出；当前 `OooAluFetchCore` 行数 3927。

### [2026-06-27] `frontend-run-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: frontend run gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联组合赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-frontend-run-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-001053-633515/`。
- `notes`: 默认 module regression 从 64 项扩展为 65 项，新增 `tb_ooo_frontend_run_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `frontend-action-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 direct frontend flush、stop-head、FIFO pop、fetch response control-stop 和 trap-blocked request 的组合动作谓词，新增 `npc/rv64/design/specs/ooo-frontend-action-gate.md`。
- `outputs`: 明确新 helper 只负责动作 predicate；父模块继续负责 PC 选择、response ready-valid、FIFO storage、dispatch sequencer、pending/redirect/trap/commit 时序所有权。

### [2026-06-27] `frontend-action-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFrontendActionGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_frontend_action_gate.sv`。
- `outputs`: 删除父模块中 direct flush、stop-head、FIFO pop、control-stop 和 trap-blocked request 的内联组合表达式，改由 `u_frontend_action_gate` 输出；当前 `OooAluFetchCore` 行数 3948。

### [2026-06-27] `frontend-action-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: frontend action gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联组合赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-frontend-action-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-001820-649962/`。
- `notes`: 默认 module regression 从 65 项扩展为 66 项，新增 `tb_ooo_frontend_action_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `fetch-request-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 fetch request PC/source 选择链，包括顺序 PC、redirect request valid/target、branch prefetch fallback 和 outstanding/fallthrough suppression，新增 `npc/rv64/design/specs/ooo-fetch-request-mux.md`。
- `outputs`: 明确新 helper 只负责组合 PC/source mux；父模块继续负责 `next_fetch_pc_q`、outstanding/discard、response ready-valid、redirect recovery 和 request ready-valid 时序所有权。

### [2026-06-27] `fetch-request-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchRequestMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_request_mux.sv`。
- `outputs`: 删除父模块中 fetch request seq PC、direct redirect aggregate、redirect request valid、redirect PC 和 final request PC 的内联组合表达式，改由 `u_fetch_request_mux` 输出；当前 `OooAluFetchCore` 行数 3958。

### [2026-06-27] `fetch-request-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: fetch request mux 单测、fetch core focused、lint、build、full module TB、official riscv-tests。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-fetch-request-mux/` 与 `npc/rv64/perf/results/core-regress/20260627-003343-667911/`。
- `notes`: 默认 module regression 从 66 项扩展为 67 项，新增 `tb_ooo_fetch_request_mux`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-prefetch-request-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 pending branch 与 JALR BTB hit 发起 branch prefetch request 的组合 gating，新增 `npc/rv64/design/specs/ooo-branch-prefetch-request-gate.md`。
- `outputs`: 明确新 helper 只负责 branch/JALR request valid 与 request PC 选择；父模块继续负责 BTB/RAS lookup、branch resolve、prefetch buffer、outstanding/discard 和 fetch request ready-valid。

### [2026-06-27] `branch-prefetch-request-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchPrefetchRequestGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_prefetch_request_gate.sv`。
- `outputs`: 删除父模块中 branch/JALR prefetch request valid 和 request PC 的内联组合表达式，改由 `u_branch_prefetch_request_gate` 输出；当前 `OooAluFetchCore` 行数 3969。

### [2026-06-27] `branch-prefetch-request-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch prefetch request gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests 和旧内联组合赋值扫描。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-prefetch-request-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-004106-684352/`。
- `notes`: 默认 module regression 从 67 项扩展为 68 项，新增 `tb_ooo_branch_prefetch_request_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-prefetch-status-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 branch prefetch response capture、resolve PC match、buffer/same-cycle hit 和 pending match 的组合 status 边界，新增 `npc/rv64/design/specs/ooo-branch-prefetch-status-gate.md`。
- `outputs`: 明确新 helper 只负责 response capture 与 hit/pending status predicate；父模块继续负责 prefetch buffer 写入/清空、hit packet 选择、JALR 专用 hit status、request/outstanding 和 recovery 时序。

### [2026-06-27] `branch-prefetch-status-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchPrefetchStatusGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_prefetch_status_gate.sv`。
- `outputs`: 删除父模块中 branch prefetch response capture、match、buffer match、response match、hit available 和 pending match 的内联组合表达式，改由 `u_branch_prefetch_status_gate` 输出；当前 `OooAluFetchCore` 行数 3977。

### [2026-06-27] `branch-prefetch-status-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch prefetch status gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-prefetch-status-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-004920-701721/`。
- `notes`: 默认 module regression 从 68 项扩展为 69 项，新增 `tb_ooo_branch_prefetch_status_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `jalr-prefetch-status-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 JALR branch-prefetch target-ready、target mux、match、buffer/same-cycle hit 和 pending match 的组合 status 边界，新增 `npc/rv64/design/specs/ooo-jalr-prefetch-status-gate.md`。
- `outputs`: 明确新 helper 只负责 JALR prefetch status predicate；父模块继续负责 JALR target 计算、BTB update、hit packet mux、prefetch buffer 状态和 PC/outstanding/discard 时序。

### [2026-06-27] `jalr-prefetch-status-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooJalrPrefetchStatusGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_jalr_prefetch_status_gate.sv`。
- `outputs`: 删除父模块中 JALR prefetch target-ready、target mux、match、buffer match、response match、hit available 和 pending match 的内联组合表达式，改由 `u_jalr_prefetch_status_gate` 输出；当前 `OooAluFetchCore` 行数 3984。

### [2026-06-27] `jalr-prefetch-status-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: JALR prefetch status gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-jalr-prefetch-status-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-005750-718571/`。
- `notes`: 默认 module regression 从 69 项扩展为 70 项，新增 `tb_ooo_jalr_prefetch_status_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-prefetch-source-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 pending branch target/predicted PC、JALR return hint 和 JALR BTB lookup 的组合 source facts，新增 `npc/rv64/design/specs/ooo-branch-prefetch-source-gate.md`。
- `outputs`: 明确新 helper 只负责 branch/JALR prefetch source facts；父模块继续负责 pending 状态、RAS/BTB 表项、request gate、branch resolve 和 recovery 时序。

### [2026-06-27] `branch-prefetch-source-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchPrefetchSourceGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_prefetch_source_gate.sv`。
- `outputs`: 删除父模块中 pending branch target、branch prefetch predicted PC、JALR return hint 和 JALR BTB lookup 的内联组合表达式，改由 `u_branch_prefetch_source_gate` 输出；当前 `OooAluFetchCore` 行数 3992。

### [2026-06-27] `branch-prefetch-source-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch prefetch source gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-prefetch-source-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-010712-735629/`。
- `notes`: 默认 module regression 从 70 项扩展为 71 项，新增 `tb_ooo_branch_prefetch_source_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `direct-branch-resolve-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 direct branch lane 选择、BHT payload、预测 PC、dispatch/issue resolve、redirect/taken 和 lane1 return capture 的组合边界，新增 `npc/rv64/design/specs/ooo-direct-branch-resolve-gate.md`。
- `outputs`: 明确新 helper 只负责 direct branch resolve gate 组合事实；父模块继续负责 BPU/RAS 表项、pending 状态、trap squash、PC/outstanding/discard 和 branch/RAS update 时序。

### [2026-06-27] `direct-branch-resolve-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooDirectBranchResolveGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_direct_branch_resolve_gate.sv`，并修正 `tb_ooo_fetch_trap_gate.sv` 对拆分后 raw redirect wire 的层次引用。
- `outputs`: 删除父模块中 direct branch fire/payload 选择、BHT payload 选择、预测 PC、resolve 优先级、redirect/taken 和 lane1 return capture 的内联组合表达式，改由 `u_direct_branch_resolve_gate` 输出；当前 `OooAluFetchCore` 行数 3992。

### [2026-06-27] `direct-branch-resolve-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: direct branch resolve gate 单测、fetch core focused、fetch trap focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-direct-branch-resolve-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-012111-753582/`。
- `notes`: 默认 module regression 从 71 项扩展为 72 项，新增 `tb_ooo_direct_branch_resolve_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-resolve-recovery-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 pending branch resolve match、tracked/untracked redirect、branch-spec checkpoint/restore/redirect 和 direct branch wait untracked 的组合恢复谓词，新增 `npc/rv64/design/specs/ooo-branch-resolve-recovery-gate.md`。
- `outputs`: 明确新 helper 只负责 branch resolve recovery predicates；父模块继续负责 pending/spec/wait 状态、PC/outstanding/discard、BPU/RAS update 和 trap/CSR 时序。

### [2026-06-27] `branch-resolve-recovery-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchResolveRecoveryGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_resolve_recovery_gate.sv`，并修正 `tb_ooo_fetch_trap_gate.sv` 中 tracked/untracked/branch-spec raw redirect force 路径。
- `outputs`: 删除父模块中 pending branch resolve、tracked redirect、backend quiet、branch-spec checkpoint/restore/redirect、direct wait untracked 和 generic untracked redirect 的内联组合表达式，改由 `u_branch_resolve_recovery_gate` 输出；当前 `OooAluFetchCore` 行数 3990。

### [2026-06-27] `branch-resolve-recovery-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch resolve recovery gate 单测、fetch core focused、fetch trap focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-resolve-recovery-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-013017-770497/`。
- `notes`: 默认 module regression 从 72 项扩展为 73 项，新增 `tb_ooo_branch_resolve_recovery_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `pending-control-resolve-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 pending branch next/misaligned、pending JAL/JALR resolved target、JALR sum LSB、pending jump resolve-ready、return/call/no-link/fire/commit/redirect-after-dispatch 和 pending-control-ready 的组合事实，新增 `npc/rv64/design/specs/ooo-pending-control-resolve-gate.md`。
- `outputs`: 明确新 helper 只负责 pending control resolve facts；父模块继续负责 pending 状态、`CompareUnit`、RAS/BTB 表项、trap/commit 和 PC/outstanding/discard 时序。

### [2026-06-27] `pending-control-resolve-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooPendingControlResolveGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_control_resolve_gate.sv`。
- `outputs`: 删除父模块中 pending branch next/misaligned、pending jump target/ready、return/call/no-link/fire/commit/redirect 和 pending-control-ready 的内联组合表达式，改由 `u_pending_control_resolve_gate` 输出；当前 `OooAluFetchCore` 行数 3996。

### [2026-06-27] `pending-control-resolve-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: pending control resolve gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-pending-control-resolve-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-014016-787548/`。
- `notes`: 默认 module regression 从 73 项扩展为 74 项，新增 `tb_ooo_pending_control_resolve_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-append-dispatch-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 return-cont optional/attempt-ready、branch target/fallthrough lane1 append、fallthrough outstanding keep/capture、branch prefetch direct-dispatch dead-path 和 `dispatch1_optional` 的组合门控边界，新增 `npc/rv64/design/specs/ooo-branch-append-dispatch-gate.md`。
- `outputs`: 明确新 helper 只负责 branch append dispatch predicates；父模块继续负责相关状态寄存器、dispatch payload mux、FIFO seed/enqueue 和 PC/outstanding/discard 时序。

### [2026-06-27] `branch-append-dispatch-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchAppendDispatchGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_append_dispatch_gate.sv`。
- `outputs`: 删除父模块中 return-cont/branch append、fallthrough outstanding、branch prefetch direct-dispatch 和 `dispatch1_optional` 的内联组合表达式，改由 `u_branch_append_dispatch_gate` 输出；当前 `OooAluFetchCore` 行数 4009。

### [2026-06-27] `branch-append-dispatch-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch append dispatch gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描、line count 和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-append-dispatch-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-015236-805280/`。
- `notes`: 默认 module regression 从 74 项扩展为 75 项，新增 `tb_ooo_branch_append_dispatch_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-bpu-update-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 branch direction predictor 的 pending lookup capture、lookup sideband、direct/pending/drained/commit update class、actual/predicted taken 选择、update PC/BHT index 选择和 correctness 组合边界，新增 `npc/rv64/design/specs/ooo-branch-bpu-update-gate.md`。
- `outputs`: 明确新 helper 只负责 BPU lookup/update sideband 与 update mux；父模块继续负责 predictor table 实例、branch pending/spec/wait 状态、resolve/recovery sequencer、RAS/BTB update 和 PC/outstanding 时序。

### [2026-06-27] `branch-bpu-update-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchBpuUpdateGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_bpu_update_gate.sv`。
- `outputs`: 删除父模块中 branch BPU pending capture、lookup sideband、update class、update taken/pred/correct/PC/BHT index 的内联组合表达式，改由 `u_branch_bpu_update_gate` 输出；当前 `OooAluFetchCore` 行数 4026。

### [2026-06-27] `branch-bpu-update-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch BPU update gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描、line count 和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-bpu-update-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-020401-822717/`。
- `notes`: 默认 module regression 从 75 项扩展为 76 项，新增 `tb_ooo_branch_bpu_update_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-target-cache-control-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 branch target cache/capture buffer 上游的 store fire/address、commit `MISC-MEM` 全失效、direct branch redirect 后 capture arm 和 branch PC 选择组合边界，新增 `npc/rv64/design/specs/ooo-branch-target-cache-control-gate.md`。
- `outputs`: 明确新 helper 只负责 branch target cache control predicates；父模块继续负责 branch target cache/capture buffer 实例、direct branch resolve、dispatch/FIFO 和 PC/outstanding 时序。

### [2026-06-27] `branch-target-cache-control-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchTargetCacheControlGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_target_cache_control_gate.sv`。
- `outputs`: 删除父模块中 branch target store/invalidate/capture arm 的内联组合表达式，改由 `u_branch_target_cache_control_gate` 输出；当前 `OooAluFetchCore` 行数 4043。

### [2026-06-27] `branch-target-cache-control-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: branch target cache control gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描、line count 和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-target-cache-control-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-021514-840370/`。
- `notes`: 默认 module regression 从 76 项扩展为 77 项，新增 `tb_ooo_branch_target_cache_control_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `direct-ras-candidate-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 lane0/lane1 JAL call-like raw、RAS direct update safe、lane0 direct return 和 lane1 return candidate 组合边界，新增 `npc/rv64/design/specs/ooo-direct-ras-candidate-gate.md`。
- `outputs`: 明确新 helper 只负责 direct RAS/RAS-ret candidate predicates；父模块继续负责 RAS 栈、return-cont buffer、direct jump/ret fire、PC redirect 和 dispatch/FIFO 时序。

### [2026-06-27] `direct-ras-candidate-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooDirectRasCandidateGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_direct_ras_candidate_gate.sv`。
- `outputs`: 删除父模块中 direct RAS candidate 的内联组合表达式，改由 `u_direct_ras_candidate_gate` 输出；当前 `OooAluFetchCore` 行数 4048。

### [2026-06-27] `direct-ras-candidate-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: direct RAS candidate gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-direct-ras-candidate-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-022308-857075/`。
- `notes`: 默认 module regression 从 77 项扩展为 78 项，新增 `tb_ooo_direct_ras_candidate_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `ras-update-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 RAS 栈上游 clear/pop/push/push-value 的组合更新控制边界，新增 `npc/rv64/design/specs/ooo-ras-update-gate.md`。
- `outputs`: 明确新 helper 只负责 RAS update control predicates；父模块和 `OooRasStack` 继续负责 RAS 状态、可靠性、栈顶和同周期 clear/pop/push 的时序优先级。

### [2026-06-27] `ras-update-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooRasUpdateGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_ras_update_gate.sv`。
- `outputs`: 删除父模块中 RAS clear/pop/push/push-value 的内联组合表达式，改由 `u_ras_update_gate` 输出；当前 `OooAluFetchCore` 行数 4060。

### [2026-06-27] `ras-update-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: RAS update gate 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联组合赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-ras-update-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-022947-873479/`。
- `notes`: 默认 module regression 从 78 项扩展为 79 项，新增 `tb_ooo_ras_update_gate`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `branch-spec-tracker-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 branch-spec checkpoint 的 active/checkpoint-pending/pred-PC 状态边界，新增 `npc/rv64/design/specs/ooo-branch-spec-tracker.md`。
- `outputs`: 明确新 helper 只负责 branch-spec checkpoint 注册状态；父模块继续负责 checkpoint/resolve 事件、PC/outstanding/discard、pending payload、FIFO seed/clear、BPU/RAS update 和 precise recovery 仲裁。

### [2026-06-27] `branch-spec-tracker-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooBranchSpecTracker.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_branch_spec_tracker.sv`。
- `outputs`: 删除父模块 always 块中 branch-spec 三个状态寄存器的全部赋值，改由 `u_branch_spec_tracker` 输出；新增 `pending_branch_match_clear_w` 共享 predicate；当前 `OooAluFetchCore` 行数 4040。

### [2026-06-27] `branch-spec-tracker-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Branch spec tracker 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联状态赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-ooo-branch-spec-tracker/` 与 `npc/rv64/perf/results/core-regress/20260627-024643-892850/`。
- `notes`: 默认 module regression 从 79 项扩展为 80 项，新增 `tb_ooo_branch_spec_tracker`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS。

### [2026-06-27] `fetch-pc-outstanding-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `next_fetch_pc/outstanding_valid/outstanding_pc/discard_fetch_rsp` 的生产消费、同拍覆盖顺序和 direct/branch-spec/pending/drain/CSR trap 恢复优先级，新增 `npc/rv64/design/specs/ooo-fetch-pc-outstanding-sequencer.md`。
- `outputs`: 明确新 helper 只负责 fetch PC/outstanding/discard 注册状态；父模块继续负责 fetch request mux、FIFO storage、branch/pending/trap 事件生成、CSR/trap side effect、BPU/RAS/BTB 表项和 commit/pending payload 状态。

### [2026-06-27] `fetch-pc-outstanding-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFetchPcOutstandingSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_fetch_pc_outstanding_sequencer.sv`。
- `outputs`: 删除父模块 always 块中 `next_fetch_pc_q/outstanding_valid_q/outstanding_pc_q/discard_fetch_rsp_q` 的全部赋值，改由 `u_fetch_pc_outstanding` 输出；当前 `OooAluFetchCore` 行数 3961。

### [2026-06-27] `fetch-pc-outstanding-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Fetch PC/outstanding sequencer 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联状态赋值扫描、line count、行尾空白扫描、`git diff --check` 和误生成 provider 前缀目录清理。
- `evidence`: `npc/rv64/perf/results/20260627-fetch-pc-outstanding-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-030427-912678/`。
- `notes`: 默认 module regression 从 80 项扩展为 81 项，新增 `tb_ooo_fetch_pc_outstanding_sequencer`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS；父模块旧四状态赋值扫描为空。

### [2026-06-27] `control-commit-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `ctrl_commit_valid/payload/rd/write` 与 `core_serial_flush` 的生产消费、jump no-link、drained system/branch/FP control commit 和 trap/CSR 排除边界，新增 `npc/rv64/design/specs/ooo-control-commit-sequencer.md`。
- `outputs`: 明确新 helper 只负责控制类伪提交与 FP GPR serial flush 的注册状态；父模块继续负责 pending owner 捕获/清理、CSR/trap side effect、FPR 写入、ROB commit mux 和 PC/outstanding 时序。

### [2026-06-27] `control-commit-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `writeback/OooControlCommitSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_control_commit_sequencer.sv`。
- `outputs`: 删除父模块 always 块中 `ctrl_commit_*` 和 `core_serial_flush_q` 的全部赋值，改由 `u_control_commit_sequencer` 输出；当前 `OooAluFetchCore` 行数 3961。

### [2026-06-27] `control-commit-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Control commit sequencer 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联状态赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-control-commit-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-032108-933272/`。
- `notes`: 默认 module regression 从 81 项扩展为 82 项，新增 `tb_ooo_control_commit_sequencer`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS；父模块旧 `ctrl_commit_*`/`core_serial_flush_q` 赋值扫描为空。

### [2026-06-27] `control-flush-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `core_trap_flush/trap_redirect_squash/checkpoint_mem_flush` 的生产消费、trap flush pulse、privileged boundary sticky squash、checkpoint restore memory flush 和 backend drained clear 边界，新增 `npc/rv64/design/specs/ooo-control-flush-sequencer.md`。
- `outputs`: 明确新 helper 只负责全局 flush 注册状态；父模块继续负责 CSR/trap side effect、pending owner 清理、branch checkpoint 事件、PC/outstanding、memory request arbitration 和 commit mux。

### [2026-06-27] `control-flush-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooControlFlushSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_control_flush_sequencer.sv`。
- `outputs`: 删除父模块 always 块中 `core_trap_flush_q/trap_redirect_squash_q/checkpoint_mem_flush_q` 的全部赋值，改由 `u_control_flush_sequencer` 输出；当前 `OooAluFetchCore` 行数 3962。

### [2026-06-27] `control-flush-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Control flush sequencer 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联状态赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-control-flush-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-033432-951944/`。
- `notes`: 默认 module regression 从 82 项扩展为 83 项，新增 `tb_ooo_control_flush_sequencer`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS；父模块旧三个 flush 状态赋值扫描为空。

### [2026-06-27] `synthetic-lane1-ret-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `synth_lane1_ret_*` 与 `synth_lane1_branch_drop_*` 的生产消费、lane1 return synthetic retire、branch-drop clear、satp/trap clear 和同拍覆盖顺序，新增 `npc/rv64/design/specs/ooo-synthetic-lane1-ret-sequencer.md`。
- `outputs`: 明确新 helper 只负责 lane1 return synthetic retire 与 branch-drop 注册状态；父模块继续负责 pending owner 捕获/清理、`pending_lane1_ret`、branch/RAS/BTB 判定、CSR/trap side effect、commit0/commit1 mux、retire count 和 backend-drain policy。

### [2026-06-27] `synthetic-lane1-ret-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `writeback/OooSyntheticLane1RetSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_synthetic_lane1_ret_sequencer.sv`。
- `outputs`: 删除父模块 always 块中 `synth_lane1_ret_*` 和 `synth_lane1_branch_drop_*` 的全部赋值，改由 `u_synthetic_lane1_ret_sequencer` 输出；当前 `OooAluFetchCore` 行数 3935。

### [2026-06-27] `synthetic-lane1-ret-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Synthetic lane1 return sequencer 单测、fetch core focused、lint、build、full module TB、official riscv-tests、旧内联状态赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-synthetic-lane1-ret-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-034740-971227/`。
- `notes`: 默认 module regression 从 83 项扩展为 84 项，新增 `tb_ooo_synthetic_lane1_ret_sequencer`；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS；父模块旧 synthetic lane1 return/drop 状态赋值扫描为空。

### [2026-06-27] `pending-lane1-ret-dead-cleanup-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计旧 `pending_lane1_ret_*` dispatch replay 的生产者/消费者，确认当前 RTL 只有 reset/clear、无置位生产者；新增 `npc/rv64/design/specs/ooo-pending-lane1-ret-dead-cleanup.md`。
- `outputs`: 明确 lane1 return delayed visibility 由 synthetic retire sequencer 与 direct RAS event 承担，旧 pending replay 不再是有效协议。

### [2026-06-27] `pending-lane1-ret-dead-cleanup-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 更新 `OooAluFetchCore.v`、`OooRasUpdateGate.v`、`tb_ooo_alu_fetch_core.sv`、`tb_ooo_ras_update_gate.sv`、相关 specs 和 `vsrc/README.md`。
- `outputs`: 删除 `pending_lane1_ret_q/pc/next_pc/inst` 四个死寄存器、不可达 dispatch valid/payload mux 分支、RAS gate 旧输入端口和 testbench 层次引用；当前 `OooAluFetchCore` 行数 3902，`OooRasUpdateGate` 行数 41。

### [2026-06-27] `pending-lane1-ret-dead-cleanup-verify` - `completed`

- `owner_agent`: `codex`
- `action`: RAS update gate 与 fetch core focused、lint、build、full module TB、official riscv-tests、`pending_lane1_ret` 全 RTL/TB 静态扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-pending-lane1-ret-cleanup/` 与 `npc/rv64/perf/results/core-regress/20260627-040113-989706/`。
- `notes`: 默认 module regression 保持 84/84 PASS；官方 `rv64ui/rv64um/rv64uc/rv64mi/rv64uf/rv64ud` 108 项 PASS；RTL/TB 源文件中 `pending_lane1_ret` 扫描为空。

### [2026-06-27] `broad-isa-privileged-regression` - `completed`

- `owner_agent`: `codex`
- `action`: 在第三十三切片后补跑 default+FP+privileged official riscv-tests sweep，不新增 RTL 改动。
- `evidence`: `npc/rv64/perf/results/core-regress/20260627-040934-1005598/`。
- `notes`: suites 为 `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si`；test-only `rv64*-p-*` 共 158 项 PASS，non-pass 行为空，`overall_rc=0`。该验证门不替代 Linux/full-system、formal、PPA、timing、CDC、reset 或物理签核。

### [2026-06-27] `memory-request-gate-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` 外部 data-memory request/response、pending FP memory 序列化、core lane0/lane1 request mux、`mem_flush` 和 `mmu_flush` 组合边界，新增 `npc/rv64/design/specs/ooo-memory-request-gate.md`。
- `outputs`: 明确新 helper 只负责 memory request/flush 纯组合边界；父模块继续持有 pending FP memory 状态、FPR load 写入、core LSU 状态和 precise trap/flush/checkpoint 状态。

### [2026-06-27] `memory-request-gate-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `memory/OooMemoryRequestGate.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_memory_request_gate.sv`。
- `outputs`: 删除父模块内联 `pending_fp_mem_req_valid/fire/rsp_fire`、`mem_req*`/`mem1_req*`、`mem_flush_o` 和 `mmu_flush_o` 组合 assign，改由 `u_memory_request_gate` 输出；当前 `OooAluFetchCore` 行数 3926，`OooMemoryRequestGate` 行数 95。

### [2026-06-27] `memory-request-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Memory request gate 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、旧内联 memory mux/flush 表达式扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-memory-request-gate/` 与 `npc/rv64/perf/results/core-regress/20260627-042108-1030309/`。
- `notes`: 默认 module regression 从 84 项扩展为 85 项，新增 `tb_ooo_memory_request_gate`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；旧内联 memory mux/flush 表达式扫描为空。

### [2026-06-27] `commit-output-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` 对外 `commit0/commit1` 与 `retire_count` 输出组合 mux，新增 `npc/rv64/design/specs/ooo-commit-output-mux.md`。
- `outputs`: 明确新 helper 只负责 control pseudo-commit、synthetic lane1 return/branch append、ROB commit0/commit1 到外部 commit/retire 端口的纯组合选择；父模块继续持有 ROB/CSR/trap side effect、synthetic ret 状态和 pending owner 清理。

### [2026-06-27] `commit-output-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `writeback/OooCommitOutputMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_commit_output_mux.sv`。
- `outputs`: 删除父模块内联 `rv32_imm_j`、`assign commit0_*`、`assign commit1_*` 和 `assign retire_count_o`，改由 `u_commit_output_mux` 输出；当前 `OooAluFetchCore` 行数 3857，`OooCommitOutputMux` 行数 206。

### [2026-06-27] `commit-output-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Commit output mux 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、旧内联 commit mux 表达式扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-commit-output-mux/` 与 `npc/rv64/perf/results/core-regress/20260627-043339-1054578/`。
- `notes`: 默认 module regression 从 85 项扩展为 86 项，新增 `tb_ooo_commit_output_mux`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；旧内联 `rv32_imm_j`、`assign commit0_*`、`assign commit1_*` 和 `assign retire_count_o` 扫描为空。

### [2026-06-27] `frontend-backend-dispatch-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` front-end/pending 源到 `OooAluCoreSlice` dispatch0/dispatch1 端口的 valid/payload/fire 组合选择，新增 `npc/rv64/design/specs/ooo-frontend-backend-dispatch-mux.md`。
- `outputs`: 明确新 helper 只负责 branch prefetch buffer/rsp、pending system/jump/mem、direct RET next-PC override、normal fetch packet、return-cont 和 branch append 到 dispatch 端口的纯组合 mux；父模块继续持有 pending owner、CSR/trap side effect、backend allocation 和 precise recovery 时序所有权。

### [2026-06-27] `frontend-backend-dispatch-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooFrontendBackendDispatchMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_frontend_backend_dispatch_mux.sv`。
- `outputs`: 删除父模块内联 dispatch valid/fire、dispatch0/dispatch1 payload mux、pending jump/mem fire 和 CSR rdata mux 组合表达式，改由 `u_frontend_backend_dispatch_mux` 输出；当前 `OooAluFetchCore` 行数 3870，`OooFrontendBackendDispatchMux` 行数 158。

### [2026-06-27] `frontend-backend-dispatch-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Frontend/backend dispatch mux 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、旧内联 dispatch mux 表达式扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-frontend-backend-dispatch-mux/` 与 `npc/rv64/perf/results/core-regress/20260627-044512-1078572/`。
- `notes`: 默认 module regression 从 86 项扩展为 87 项，新增 `tb_ooo_frontend_backend_dispatch_mux`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；旧内联 dispatch mux 表达式扫描为空。

### [2026-06-27] `pending-system-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` pending SYSTEM/CSR/IRQ registered state、IRQ capture、lane0/lane1 system capture、dispatch fire 和 clear/clear-dispatched 优先级，新增 `npc/rv64/design/specs/ooo-pending-system-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 `pending_system_*` 状态保持；父模块继续持有 CSR side effect、trap/return target 选择、pending owner arbitration、backend drain、fetch redirect 和 precise recovery。

### [2026-06-27] `pending-system-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooPendingSystemSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_system_sequencer.sv`。
- `outputs`: 父模块 `pending_system_*_q` 改由 sequencer 输出 wire 驱动，capture/clear 事件谓词留在父模块，旧 `pending_system_* <=` 内联状态赋值扫描为空；当前 `OooAluFetchCore` 行数 3759，`OooPendingSystemSequencer` 行数 153。

### [2026-06-27] `pending-system-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Pending system sequencer 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、父模块旧 pending system 赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-pending-system-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-050546-1104880/`。
- `notes`: 默认 module regression 从 87 项扩展为 88 项，新增 `tb_ooo_pending_system_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；父模块 `pending_system <=` 残留赋值扫描为空。

### [2026-06-27] `pending-memory-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` lane1 memory barrier pending state、capture/clear/dispatch 事件优先级和普通 clear payload 语义，新增 `npc/rv64/design/specs/ooo-pending-memory-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 `pending_mem_valid/dispatched/pc/inst/next_pc` 状态保持；父模块继续持有 pending owner arbitration、LSU/MMU request、memory trap、backend drain、fetch redirect 和 precise recovery。

### [2026-06-27] `pending-memory-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `memory/OooPendingMemorySequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_memory_sequencer.sv`。
- `outputs`: 父模块 `pending_mem_*_q` 改由 sequencer 输出 wire 驱动，lane1 capture、capture clear、normal clear、late clear 和 dispatch fire 事件留在父模块；旧 `pending_mem_* <=` 内联状态赋值扫描为空；当前 `OooAluFetchCore` 行数 3718，`OooPendingMemorySequencer` 行数 65。

### [2026-06-27] `pending-memory-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Pending memory sequencer 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、父模块旧 pending memory 赋值扫描、line count、行尾空白扫描和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-pending-memory-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-051941-1129604/`。
- `notes`: 默认 module regression 从 88 项扩展为 89 项，新增 `tb_ooo_pending_memory_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；父模块 `pending_mem <=` 残留赋值扫描为空。

### [2026-06-27] `pending-jump-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` JAL/JALR pending jump registered state、head0/lane1 capture、dispatch target、clear/late-clear/clear-dispatched 优先级，新增 `npc/rv64/design/specs/ooo-pending-jump-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 `pending_jump_valid/dispatched/jalr/pc/next_pc/inst/rs1/imm/target` 状态保持；父模块继续持有 target 计算、RAS/BTB、misaligned trap、backend drain、fetch redirect 和 precise recovery。

### [2026-06-27] `pending-jump-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooPendingJumpSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_jump_sequencer.sv`。
- `outputs`: 父模块 `pending_jump_*_q` 改由 sequencer 输出 wire 驱动，head0 capture、lane1 barrier capture、normal clear、late clear 和 dispatch target 事件留在父模块；旧 `pending_jump_* <=` 内联状态赋值扫描为空；当前 `OooAluFetchCore` 行数 3708，`OooPendingJumpSequencer` 行数 108。

### [2026-06-27] `pending-jump-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Pending jump sequencer 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、父模块旧 pending jump 赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-pending-jump-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-053402-1154250/`。
- `notes`: 默认 module regression 从 89 项扩展为 90 项，新增 `tb_ooo_pending_jump_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；父模块 `pending_jump <=` 残留赋值扫描为空。

### [2026-06-27] `pending-branch-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` pending branch registered state、direct/head0/lane1 capture、clear/late-clear/clear-dispatched 优先级，新增 `npc/rv64/design/specs/ooo-pending-branch-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 `pending_branch_valid/dispatched/pc/next_pc/inst/rs1/rs2/imm/cmp_op/pred_taken/bht_valid/bht_idx` 状态保持；父模块继续持有 branch compare、target 计算、BPU update、branch-spec recovery、misaligned trap、backend drain、fetch redirect 和 precise recovery。

### [2026-06-27] `pending-branch-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `frontend/OooPendingBranchSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_branch_sequencer.sv`。
- `outputs`: 父模块 `pending_branch_*_q` 改由 sequencer 输出 wire 驱动，direct/head0/lane1 capture、normal clear、late clear 和 clear-dispatched 事件留在父模块；旧 `pending_branch_* <=` 内联状态赋值扫描为空；当前 `OooAluFetchCore` 行数 3695，`OooPendingBranchSequencer` 行数 155。

### [2026-06-27] `pending-branch-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Pending branch sequencer 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、父模块旧 pending branch 赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-pending-branch-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-054924-1179014/`。
- `notes`: 默认 module regression 从 90 项扩展为 91 项，新增 `tb_ooo_pending_branch_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；父模块 `pending_branch <=` 残留赋值扫描为空。

### [2026-06-27] `pending-fp-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` pending FP registered state、memory/long/compute progress、head0/lane1 capture、drain clear 和 CSR trap late clear 优先级，新增 `npc/rv64/design/specs/ooo-pending-fp-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 pending FP 单 entry 状态和进度保持；父模块继续持有 FPR 文件、FP load/arithmetic 写入、fflags commit、GPR serial write、pending owner arbitration、backend drain、fetch redirect 和 precise recovery。

### [2026-06-27] `pending-fp-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `execute/OooPendingFpSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_fp_sequencer.sv`。
- `outputs`: 父模块 `pending_fp_*_q` 改由 sequencer 输出 wire 驱动，head0 capture、lane1 capture、drain clear、CSR trap late clear 和 progress events 留在父模块生成；旧 `pending_fp_*_q <=` 内联状态赋值扫描为空；当前 `OooAluFetchCore` 行数 3649，`OooPendingFpSequencer` 行数 206。

### [2026-06-27] `pending-fp-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Pending FP sequencer 单测、fetch core focused、lint、build、full module TB、改动后 default+FP+privileged official riscv-tests、父模块旧 pending FP 赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-pending-fp-sequencer/` 与 `npc/rv64/perf/results/core-regress/20260627-060547-1204187/`。
- `notes`: 默认 module regression 从 91 项扩展为 92 项，新增 `tb_ooo_pending_fp_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；父模块 `pending_fp_*_q <=` 残留赋值扫描为空，保留的两处 `fpr_q[pending_fp_rd_q] <=` 是 FPR 文件副作用，不属于 pending owner。

### [2026-06-27] `pending-trap-exit-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` pending architectural trap / simulation exit registered state、lane0/lane1 capture、resolve/drain clear 与 CSR trap late clear 优先级，新增 `npc/rv64/design/specs/ooo-pending-trap-exit-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 pending trap/exit valid 与 payload 状态保持；父模块继续持有 `stop_pending`、CSR trap mux/side effect、final trap/exit/halt 输出、fetch redirect 和 precise recovery。

### [2026-06-27] `pending-trap-exit-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooPendingTrapExitSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`testbench/Makefile`，新增 `tb_ooo_pending_trap_exit_sequencer.sv`。
- `outputs`: 父模块 pending trap/exit 状态改由 sequencer 输出 wire 驱动，lane0 fetch fault/decode trap/exit、lane1 barrier、unsupported、resolve/drain clear 和 late clear 事件留在父模块生成；旧 pending trap/exit 内联状态赋值扫描为空；当前 `OooAluFetchCore` 行数 3710，`OooPendingTrapExitSequencer` 行数 76。

### [2026-06-27] `pending-trap-exit-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Pending trap/exit sequencer 单测、fetch core focused、lint、build、full module TB、基础 108 项 ISA 回归、default+FP+privileged 158 项 official riscv-tests、父模块旧 pending trap/exit 赋值扫描、line count 和 `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-062248-pending-trap-exit-focused/`、`npc/rv64/perf/results/20260627-062356-pending-trap-exit-full/`、`npc/rv64/perf/results/core-regress/20260627-062420-1230181/` 与 `npc/rv64/perf/results/core-regress/20260627-062542-1246095/`。
- `notes`: 默认 module regression 从 92 项扩展为 93 项，新增 `tb_ooo_pending_trap_exit_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` test-only 158 项 PASS；父模块 pending trap/exit 状态赋值扫描为空。

### [2026-06-27] `trap-exit-output-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` 最终 `trap_valid/exit_valid/halted` 输出寄存器、branch/jump/drain terminal event 赋值到达顺序和 drain `else if` 可达条件，新增 `npc/rv64/design/specs/ooo-trap-exit-output-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 final sticky 输出状态；父模块继续持有 `stop_pending`、backend drain/resolve 到达判定、terminal event mux、CSR trap mux/side effect、exit-code 选择、fetch redirect 和 precise recovery。

### [2026-06-27] `trap-exit-output-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooTrapExitOutputSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`vsrc/control/README.md`、`testbench/Makefile`，新增 `tb_ooo_trap_exit_output_sequencer.sv`。
- `outputs`: 父模块 final output 状态改由 sequencer 输出 wire 驱动；父模块新增 terminal event mux，并删除旧 final output `<=` 赋值点；当前 `OooAluFetchCore` 行数 3752，`OooTrapExitOutputSequencer` 行数 54。

### [2026-06-27] `trap-exit-output-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Trap/exit output sequencer 单测、fetch core focused、lint、build、full module TB、默认 core-regress、default+FP+privileged 158 项 official riscv-tests、父模块旧 final output 赋值扫描、line count、行尾空白扫描和 scoped `git diff --check`。
- `evidence`: `npc/rv64/perf/results/20260627-trap-exit-output-focused/`、`npc/rv64/perf/results/20260627-trap-exit-output-full/`、`npc/rv64/perf/results/core-regress/20260627-064145-1273648/` 与 `npc/rv64/perf/results/core-regress/20260627-064451-1333640/`。
- `notes`: 默认 module regression 从 93 项扩展为 94 项，新增 `tb_ooo_trap_exit_output_sequencer`；默认 core-regress 基础 official 111 项 PASS，补跑 default+FP+privileged official 158 项 PASS；父模块 final output `<=` 赋值扫描为空；全仓库 `git diff --check` 因历史/外部目录特殊文件与大量 CRLF warning 不适合作为本 slice 证据，改用 scoped diff check 和本轮文件行尾空白扫描。

### [2026-06-27] `trap-exit-event-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 final trap/exit event mux 的 branch-spec、pending branch、pending jump、drain trap/exit 优先级和 early resolve blockers，新增 `npc/rv64/design/specs/ooo-trap-exit-event-mux.md`。
- `outputs`: 明确新 mux 只负责 terminal event/payload 纯组合选择；父模块继续持有 `stop_pending` 状态、pending owner 状态、CSR trap side effect、exit-code 选择、fetch redirect 和 precise recovery。

### [2026-06-27] `trap-exit-event-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooTrapExitEventMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`vsrc/control/README.md`、`testbench/Makefile`，新增 `tb_ooo_trap_exit_event_mux.sv`。
- `outputs`: 父模块内联 `trap_exit_output_*` event mux 表达式删除，改由 `u_trap_exit_event_mux` 输出 final trap/exit event；当前 `OooAluFetchCore` 行数 3729，`OooTrapExitEventMux` 行数 133。

### [2026-06-27] `trap-exit-event-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Trap/exit event mux 单测、output sequencer/fetch core focused、lint、build、full module TB、default+FP+privileged 158 项 official riscv-tests、父模块旧 event mux 关键词扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-trap-exit-event-mux-focused/`、`npc/rv64/perf/results/20260627-trap-exit-event-mux-full/` 与 `npc/rv64/perf/results/core-regress/20260627-065349-1357299/`。
- `notes`: 默认 module regression 从 94 项扩展为 95 项，新增 `tb_ooo_trap_exit_event_mux`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` 158 项 PASS；父模块旧 event mux 关键词扫描为空。

### [2026-06-27] `csr-trap-request-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` 中 commit exception、pending architectural trap、pending ECALL/IRQ/xRET、SATP write/SFENCE boundary 到 `CsrFile` trap/return 请求线的组合选择，新增 `npc/rv64/design/specs/ooo-csr-trap-request-mux.md`。
- `outputs`: 明确新 mux 只负责 CSR trap/return request 纯组合选择；父模块继续持有 CSR 文件实例、CSR architectural side effect、pending owner、fetch redirect、flush/recovery 和 final terminal output，并保留原 debug-observable wire 名称。

### [2026-06-27] `csr-trap-request-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooCsrTrapRequestMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`vsrc/control/README.md`、`testbench/Makefile`，新增 `tb_ooo_csr_trap_request_mux.sv`。
- `outputs`: 父模块内联 CSR trap request 表达式删除，改由 `u_csr_trap_request_mux` 输出 `pending_system_ecall_trap_w`、`pending_arch_trap_fire_w`、`csr_trap_mem_*`、`csr_trap_ex_*`、`csr_trap_irq_*`、`csr_mret_valid_w`、`csr_sret_valid_w`、`csr_real_mret_valid_w` 和 `priv_predictor_boundary_w`；当前 `OooAluFetchCore` 行数 3633，`OooCsrTrapRequestMux` 行数 87。

### [2026-06-27] `csr-trap-request-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: CSR trap request mux 单测、fetch core focused、lint、build、full module TB、default+FP+privileged 158 项 official riscv-tests、父模块旧 request 赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-csr-trap-request-focused/`、`npc/rv64/perf/results/20260627-csr-trap-request-full/` 与 `npc/rv64/perf/results/core-regress/20260627-070927-1384715/`。
- `notes`: 默认 module regression 从 95 项扩展为 96 项，新增 `tb_ooo_csr_trap_request_mux`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` 158 项 PASS；父模块旧 CSR trap request 内联赋值扫描为空；一次并行 WSL 读 status/summary 触发已知 `Wsl/Service/0x8007274c`，结果已用 PowerShell/UNC 单命令复核。

### [2026-06-27] `csr-access-request-mux-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` 中 commit0 CSR、pending SYSTEM CSR、lane1 CSR probe、head0 CSR 到 `CsrFile` access 端口的组合选择，新增 `npc/rv64/design/specs/ooo-csr-access-request-mux.md`。
- `outputs`: 明确新 mux 只负责 CSR access request 纯组合选择；父模块继续持有 CSR 文件实例、CSR side effect、pending owner、trap/return request、fetch redirect、flush/recovery 和 final terminal output，并保留 `pending_system_csr_commit_w` 等 debug-observable wire 名称。

### [2026-06-27] `csr-access-request-mux-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooCsrAccessRequestMux.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`vsrc/control/README.md`、`testbench/Makefile`，新增 `tb_ooo_csr_access_request_mux.sv`。
- `outputs`: 父模块内联 CSR access request 表达式删除，改由 `u_csr_access_request_mux` 输出 `core_commit0_csr_w`、`pending_system_csr_commit_w`、`head1_csr_probe_w`、`csr_access_*`、`pending_system_satp_write_commit_w` 和 `pending_system_sfence_commit_w`；当前 `OooAluFetchCore` 行数 3643，`OooCsrAccessRequestMux` 行数 78。

### [2026-06-27] `csr-access-request-mux-verify` - `completed`

- `owner_agent`: `codex`
- `action`: CSR access request mux 单测、trap request/fetch core focused、lint、build、full module TB、default+FP+privileged 158 项 official riscv-tests、父模块旧 request 赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-csr-access-request-focused/`、`npc/rv64/perf/results/20260627-csr-access-request-full/` 与 `npc/rv64/perf/results/core-regress/20260627-072038-1410358/`。
- `notes`: 默认 module regression 从 96 项扩展为 97 项，新增 `tb_ooo_csr_access_request_mux`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` 158 项 PASS；父模块旧 CSR access request 内联赋值扫描为空。

### [2026-06-27] `stop-pending-sequencer-spec` - `completed`

- `owner_agent`: `codex`
- `action`: 审计 `OooAluFetchCore` 中 `stop_pending_q` 的 direct flush、branch-spec、orphan cleanup、pending resolve、CSR commit、drain completion、decode-side capture、hold-only priority slot 和 late trap clear 非阻塞赋值顺序，新增 `npc/rv64/design/specs/ooo-stop-pending-sequencer.md`。
- `outputs`: 明确新 sequencer 只负责 `stop_pending` 注册状态；父模块继续持有 pending payload、fetch PC/outstanding、FIFO、CSR 文件/side effect、FPR 文件写回和 final terminal output。

### [2026-06-27] `stop-pending-sequencer-rtl` - `completed`

- `owner_agent`: `codex`
- `action`: 新增 `control/OooStopPendingSequencer.v`，更新 `OooAluFetchCore.v`、`vsrc/filelist.mk`、`vsrc/README.md`、`vsrc/control/README.md`、`testbench/Makefile`，新增 `tb_ooo_stop_pending_sequencer.sv`。
- `outputs`: 父模块 `stop_pending_q` 由 reg 改为 sequencer 输出 wire；父模块 always 块只保留 FPR reset、FP load 写回和 FP arithmetic commit 写回；`pending_fp_fpr_commit_w` 显式保留旧 drain 分支 owner 顺序；hold-only priority slot 不覆盖同拍更早 clear；当前 `OooAluFetchCore` 行数 3577，`OooStopPendingSequencer` 行数 121。

### [2026-06-27] `stop-pending-sequencer-verify` - `completed`

- `owner_agent`: `codex`
- `action`: Stop-pending sequencer 单测、fetch core focused、lint、build、full module TB、default+FP+privileged 158 项 official riscv-tests、父模块旧 stop-pending 赋值扫描和 line count。
- `evidence`: `npc/rv64/perf/results/20260627-stop-pending-focused-v2/`、`npc/rv64/perf/results/20260627-stop-pending-full-v2/` 与 `npc/rv64/perf/results/core-regress/20260627-073713-1458263/`。
- `notes`: 默认 module regression 从 97 项扩展为 98 项，新增 `tb_ooo_stop_pending_sequencer`；official `rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` 158 项 PASS；父模块 `stop_pending_q <=` 残留赋值扫描为空；单测补充同拍 clear+hold 覆盖。

### [2026-06-27] `act4-final-im-gate-audit` - `completed`

- `owner_agent`: `codex`
- `action`: 复核 ACT4 final ELF runner 当前 suite、重跑 RV64I smoke/full suite，并审计 M suite 缺失原因。
- `evidence`: `npc/rv64/perf/results/20260627-act4-final-smoke/20260627-074507-1515040/` 与 `npc/rv64/perf/results/20260627-act4-final-rv64i/20260627-074515-1515239/`。
- `notes`: 初始 `--list-suites` 只显示 `rv64i/I`；RV64I smoke `I-add/I-addi/I-sub` 3/3 PASS，RV64I full final ELF 51/51 PASS。

### [2026-06-27] `act4-preflight-workdir-fix` - `completed`

- `owner_agent`: `codex`
- `action`: 修复 `npc-rv64-act4-preflight.sh --workdir` 相对路径按 `make -C riscv-arch-test` 当前目录解析的问题，新增 `abspath_from_root()` 并同步 README。
- `evidence`: `bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh` PASS；相对 `--workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script` 生成 M final ELF 后，runner `--list-suites` 显示 `rv64i/I,rv64i/M`。
- `notes`: 修复前传相对 workdir 会把 M ELF 生成到 `npc/rv64/testsuites/core-tests/src/riscv-arch-test/npc/...` 嵌套 artifact；修复后测试资产回到 canonical `npc/rv64/testsuites/core-tests/act4-npc-final-work-script`。

### [2026-06-27] `act4-final-m-gate-verify` - `completed`

- `owner_agent`: `codex`
- `action`: 生成 ACT4 M final self-checking ELF 并执行 RV64M final ELF suite。
- `evidence`: `npc/rv64/perf/results/20260627-act4-final-rv64m/20260627-074811-1517820/`。
- `notes`: `npc-rv64-act4-preflight.sh --final-elfs --extensions M --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script` PASS，`Build complete: 65 succeeded`；`rv64i/M` 13/13 PASS。该 gate 不代表完整 ACT4 sweep 或 CPU sign-off。

### [2026-06-27] `act4-ca-asset-coverage-audit` - `completed`

- `owner_agent`: `codex`
- `action`: 尝试生成 ACT4 C/A final ELF，并审计 riscv-arch-test checkout 中实际存在的 test suite 目录。
- `evidence`: `npc-rv64-act4-preflight.sh --final-elfs --extensions C` 与 `--extensions A` 均退出 0 但 `Build complete:` 数量为空；随后 `npc-rv64-act4-run.sh --list-suites` 仍只显示 `rv64i/I,rv64i/M`；`find .../tests -maxdepth 3 -type d` 显示 unprivileged RV64 只有 `rv64i/I` 和 `rv64i/M`。
- `notes`: C/A 当前是测试资产覆盖缺口，不是 RTL 执行失败；需要后续引入包含 C/A/F/D/Z* final ELF 的 ACT4/UDB/其它 architecture-test 资产。

### [2026-06-27] `act4-final-im-combined-verify` - `completed`

- `owner_agent`: `codex`
- `action`: 执行 combined ACT4 `rv64i/I,rv64i/M` final ELF suite，形成单目录 64/64 gate。
- `evidence`: `npc/rv64/perf/results/20260627-act4-final-rv64im/20260627-075540-1520228/`。
- `notes`: attempted=64 pass=64 fail=0 skip=0；case-sensitive `FAIL|TIMEOUT|ERROR` status scan 为空。

### [2026-06-27] `act4-priv-sv-generation` - `completed`

- `owner_agent`: `codex`
- `action`: 生成 ACT4 privileged `Sv` final self-checking ELF suite，并刷新 runner suite 列表。
- `evidence`: `npc-rv64-act4-preflight.sh --final-elfs --extensions Sv --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script` PASS，`Build complete: 485 succeeded`；`npc-rv64-act4-run.sh --list-suites` 输出 `priv/Sv,rv64i/I,rv64i/M`。
- `notes`: 这说明当前 testsuite artifact 已能提供 privileged Sv final ELF 前沿，不再只有 unprivileged I/M。

### [2026-06-27] `act4-priv-sv-smoke` - `completed`

- `owner_agent`: `codex`
- `action`: 执行 ACT4 `priv/Sv` 前 5 项 smoke。
- `evidence`: `npc/rv64/perf/results/20260627-act4-final-priv-sv-smoke/20260627-075821-1523834/`。
- `notes`: attempted=5 pass=3 fail=2；`sv39_VA_all_ones_Smode`、`sv39_VA_all_zeros_Smode`、`sv39_global_pte_Smode` PASS；`sv39_canonical_Smode` 和 `sv39_canonical_Umode` 60s host timeout，日志有 progress 到 10M commits 左右，无 TOHOST FAIL。

### [2026-06-27] `act4-priv-sv-canonical-smode-long-budget` - `completed`

- `owner_agent`: `codex`
- `action`: 对 `sv39_canonical_Smode` 单项放大到 300s host timeout / 200M cycles 复跑。
- `evidence`: `npc/rv64/perf/results/20260627-act4-final-priv-sv-canonical-smode/20260627-080043-1524561/`。
- `notes`: attempted=1 pass=0 fail=1，仍为 host timeout；日志显示 progress 到 50M commits，PC 从 `0x80001a00` 推进到 `0x80001a44`，未见 TOHOST FAIL、BAD TRAP 或异常。当前归类为 privileged ACT4 Sv canonical 长预算未闭合前沿，后续需定位是测试本身长循环、CSR/Sv39 语义缺口、tohost 终止路径问题，还是性能预算不足。

### [2026-06-27] `act4-priv-sv-static-pc-localize` - `completed`

- `owner_agent`: `codex`
- `action`: 使用 `nm` 和定点 `objdump` 定位 `sv39_canonical_Smode` timeout PC 附近代码。
- `evidence`: `riscv-none-elf-nm -n .../sv39_canonical_Smode.elf`；`riscv-none-elf-objdump -d --start-address=0x80001980 --stop-address=0x80001af0 .../sv39_canonical_Smode.elf`。
- `notes`: PC `0x80001a00..0x80001a44` 落在 `sv_Svect` S-mode trap signature checker；`0x80001a44` 是 `ld s1,0(t1)`，随后将 expected signature 与构造出的 sstatus/scause 相关字段比较，不匹配会跳 `failedtest_trap_x7_x9`。本轮只读反汇编两次复现已知 WSL `0x8007274c`/`E_UNEXPECTED`，不影响 ACT4 run evidence。

### [2026-06-27] `act4-config-profile-audit` - `completed`

- `owner_agent`: `codex`
- `action`: 用 commitwatch 复核 `sail-rv64-max` canonical mismatch，并对比 `sail-RVA20S64`/`sail-RVA22S64` profile。
- `evidence`: `npc/rv64/perf/results/20260627-act4-priv-sv-commitwatch/commitwatch-svect-20260627-081445-1528890/`；`npc/rv64/perf/results/20260627-act4-rva20s64-priv-sv-canonical-smode/20260627-081943-1531905/`；`npc/rv64/perf/results/20260627-act4-rva20s64-priv-sv-canonical-umode/20260627-082011-1532990/`。
- `notes`: max 的 canonical mismatch 差异为 `sstatus.VS[10:9]`，当前核未实现 V/VS；`sail-RVA20S64` canonical S/U PASS，但 full profile 会进入 Sv48/Svnapot，不作为当前 Sv39-only 全量 gate。

### [2026-06-27] `act4-runner-config-support` - `completed`

- `owner_agent`: `codex`
- `action`: 为 ACT4 preflight/runner 增加 `--config-name` 与 `--config-src`，并让 runner 按配置名选择 ELF root。
- `evidence`: `bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh && bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh` PASS。
- `notes`: preflight 可从 ACT4 `config/sail`、`config/cores/cvw`、`qemu`、`spike`、`imperas`、`whisper` 解析配置源；`--build-final` 会把配置透传给 preflight。

### [2026-06-27] `sv39-pte-reserved-fix` - `completed`

- `owner_agent`: `codex`
- `action`: 在 I/D page walker 增加统一 `pte_reserved_fault()`，覆盖 TLB hit、fill valid 与 walk fault，并按当前 ACT4/Sail 期望调整 PTE hard-reserved mask。
- `evidence`: focused set `sv39_nleaf_pte_DAU_Smode/Umode`、`sv39_pte_reserved_field_Smode`、`sv39_svnapot_not_supported_Smode`、`sv39_svpbmt_disabled_Smode` PASS 5/5，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-pte-reserved-fix2/20260627-084640-1550329/`。
- `notes`: `SV39_PTE_RESERVED_MASK=64'he7c0_0000_0000_0000` fault bit63、PBMT[62:61]、[58:54]，允许 PTE[60:59] 软件位；`menvcfg` WARL-zero 使 PBMTE 清零探测不再 illegal。

### [2026-06-27] `mstatus-sd-tvm-fix` - `completed`

- `owner_agent`: `codex`
- `action`: 用 full commitwatch 定位 `sv_mstatus_tvm_test` 首个失败点，修复 `mstatus/sstatus` 读口 SD 派生。
- `evidence`: debug log `npc/rv64/perf/results/20260627-act4-rva22s64-tvm-debug/sv_mstatus_tvm_test.commitwatch-all.stdout`；单项 PASS 目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-tvm-sd-fix/20260627-085144-1553449/`。
- `notes`: 失败前 expected `mstatus=0x8000000a00107800`，actual `0x0000000a00107800`，差异为 SD bit63；修复后 SD 仅在 read mux 派生，不进入 `csr_mstatus_q`。

### [2026-06-27] `act4-rva22s64-priv-sv-full-verify` - `completed`

- `owner_agent`: `codex`
- `action`: 复跑完整 ACT4 `sail-RVA22S64 priv/Sv` final ELF suite。
- `evidence`: `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-full-after-sd/20260627-085153-1553580/`。
- `notes`: attempted=33 pass=33 fail=0 skip=0；该 gate 只代表当前 `sail-RVA22S64` profile 下的 Sv39 核级通过。

### [2026-06-27] `sv-fix-regression-suite` - `completed`

- `owner_agent`: `codex`
- `action`: 对本轮 Sv39/CSR 修复做静态、构建、局部 TB、lint 和官方 riscv-tests 回归。
- `evidence`: `git diff --check` PASS；`make -C npc/rv64 -j2` PASS；`make -C npc/rv64 lint` PASS；focused module TB 4/4 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-sv-fixes/module-focused/`；official test-only sweep PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-sv-fixes/core-regress-official/20260627-085300-1554892/`。
- `notes`: official sweep 覆盖 `rv64ui/rv64um/rv64ua/rv64uf/rv64ud/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64mi/rv64si`。

### [2026-06-27] `act4-rva22s64-svpbmt-closure` - `completed`

- `owner_agent`: `codex`
- `action`: 扩展 ACT4 `sail-RVA22S64` privileged Sv 覆盖到 `Svpbmt`，修复 `menvcfg.PBMTE` 与 leaf/non-leaf PTE.PBMT reserved policy。
- `evidence`: 修复前 `priv/Svpbmt` leaf S/U host timeout、nonleaf S/U PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svpbmt/20260627-090406-1580994/`；修复后 `priv/Svpbmt` 4/4 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svpbmt-after-fix/20260627-091809-1584945/`；combined `priv/ExceptionsSv,priv/Sv,priv/Svade,priv/Svbare,priv/Svpbmt` 46/46 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-combined-after-svpbmt/20260627-091842-1586160/`。
- `notes`: `Svadu`/`Svnapot` 在当前 profile 下不生成 final ELF；不把未生成 suite 记为 RTL PASS/FAIL。

### [2026-06-27] `svpbmt-regression-suite` - `completed`

- `owner_agent`: `codex`
- `action`: 对 Svpbmt RTL 变更执行构建、lint、focused module TB 和 official riscv-tests 回归。
- `evidence`: `git diff --check` PASS；`make -C npc/rv64 -j2` PASS；focused module TB 4/4 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-svpbmt/module-focused-after-whitebox/`；`make -C npc/rv64 lint` PASS；official default+FP+A+privileged sweep 177/177 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-svpbmt/core-regress-official/20260627-091917-1587606/`。
- `notes`: module TB 新增 `menvcfg.PBMTE` set/clear 和 I/D walker PBMT reserved policy 白盒检查。

### [2026-06-27] `act4-rva22s64-svinval-closure` - `completed`

- `owner_agent`: `codex`
- `action`: 扩展 ACT4 `sail-RVA22S64` privileged Sv 覆盖到 `Svinval`，修复 supervisor fence 精确 decode、独立 TVM 控制位和 U-mode illegal gate。
- `evidence`: 修复前 `priv/Svinval` attempted=2 pass=0 fail=2，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svinval/20260627-092959-1612918/`；修复后 `priv/Svinval` 2/2 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svinval-after-fix/20260627-093545-1614756/`；combined `priv/ExceptionsSv,priv/Sv,priv/Svade,priv/Svbare,priv/Svpbmt,priv/Svinval` 48/48 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-combined-after-svinval/20260627-093604-1614913/`。
- `notes`: `CTRL_SFENCE_VMA_BIT` 继续表示 pending system 序列化/flush 边界；新增 `CTRL_SFENCE_TVM_BIT` 只标记 `sfence.vma/sinval.vma`；`sfence.w.inval/sfence.inval.ir` 在 S-mode+TVM 下 legal，U-mode 下四条 supervisor fence 均 illegal。

### [2026-06-27] `svinval-regression-suite` - `completed`

- `owner_agent`: `codex`
- `action`: 对 Svinval RTL 变更执行 focused TB、lint、构建和 official riscv-tests 回归。
- `evidence`: `tb_decode_unit` PASS，日志 `npc/rv64/perf/results/20260627-act4-rva22s64-svinval/module-focused/logs/tb_decode_unit.log`；`tb_ooo_priv_system` PASS，日志 `npc/rv64/perf/results/20260627-act4-rva22s64-svinval/module-focused/logs/tb_ooo_priv_system.log`；`make -C npc/rv64 lint` PASS；`make -C npc/rv64 -j2` PASS；official default+FP+A+privileged sweep 177/177 PASS，目录 `npc/rv64/perf/results/20260627-act4-rva22s64-svinval/core-regress-official/20260627-093617-1616308/`。
- `notes`: 该回归只证明当前 Svinval/Sv 族核级 gate 和既有 official sweep 未倒退；不代表 PMP/Zicbo、完整 ACT4/UDB、Linux/full-system 或物理签核完成。
