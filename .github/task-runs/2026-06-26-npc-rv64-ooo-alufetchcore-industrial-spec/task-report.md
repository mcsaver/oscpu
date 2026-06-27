# Task Report

## 基本信息

- `task_id`: `2026-06-26-npc-rv64-ooo-alufetchcore-industrial-spec`
- `task_slug`: `npc-rv64-ooo-alufetchcore-industrial-spec`
- `graph_template`: `custom`
- `graph_mode`: `dynamic`
- `status`: `completed-slice`
- `owner`: `codex`
- `started_at`: `2026-06-26`
- `updated_at`: `2026-06-27`

## 任务目标

- `source_request`: 按工业级标准审核 `OooAluFetchCore`，划分模块，写明 spec，并按 spec 边界完成 RTL 编写。
- `goal`: 先完成一个可验证的工业化 RTL 拆分切片，降低 `OooAluFetchCore` 的职责混杂度。
- `scope`: `npc/rv64` RTL、front-end/execute focused regression、module regression、FP smoke、official riscv-tests core suites；不声明完整 CPU signoff。

## RECALL 摘要

- 已读取 `.github/AGENTS.md`、`.github/copilot-instructions.md`、`.github/memory/project-status.md`、`.github/memory/known-issues.md`、`.github/memory/modules/npc.md`。
- 已读取 `.github/instructions/rtl-generation-workflow.instructions.md` 与 `npc/rv64/README.md`、`npc/rv64/design/study/README.md`、`npc/rv64/vsrc/README.md`。
- 关键约束：RTL 改动必须按“需求 -> 协议/状态机/不变量/数据通路 -> RTL”留痕；新增 module 要同名文件并更新 `vsrc/filelist.mk`；本轮不能越级声明完整工业 CPU signoff。

## RTL 推导摘要

### 阶段 1 - 需求

- 把 `OooAluFetchCore` 中 FP pending 执行数据通路抽到 `execute/OooFpPendingExec.v`。
- 父模块继续持有 pending/FPR/commit/flush 时序所有权，新模块只输出组合结果、fflags、FP mem 地址数据和 FDIV/FSQRT done。
- 不处理 fetch FIFO、redirect、CSR/trap/interrupt 总控拆分。

### 阶段 2a - 协议规则

- `compute_value_o/compute_fflags_o` 与 `mem_*` 组合返回，父模块在原 `pending_fp_compute_start_w` 和 mem request fire 时采样。
- `long_start_i` 为父模块单拍 start，内部 `OooFpDivIter/OooFpSqrtIter` 返回 `long_done_o`。
- `flush_i` 只传给内部迭代单元；父模块仍清自己的 pending/done 寄存器。

### 阶段 2b - 状态机

- 新模块本身无新增架构状态。
- 时序状态仅来自既有 FDIV/FSQRT 迭代器：idle -> busy -> done，`rst/flush_i` 回 idle。

### 阶段 2c - 不变量

- `long_op_o` 只覆盖 FDIV/FSQRT 且目的为 FPR 的 OP-FP 指令。
- `compute_op_o` 只覆盖非 load/store、非 long-op 的 pending FP 指令。
- 单精度 FPR 写回保持 NaN-box；FP load/store 保留 exact byte address 与 aligned 8B bus window 两个地址。
- 新模块不得写 GPR/FPR/CSR，不直接产生 commit/trap/flush。

### 阶段 2d - 数据通路骨架

- `inst_i` opcode/funct7/funct3 选择 class/compare/sgnj/addsub/mul/fma/minmax/convert/move。
- `int_rs1_value_i` 只供 FP load/store 地址、int-to-FPR 和 move-to-FPR。
- `frs1/frs2/frs3` 供 FP 算法 helper；FDIV/FSQRT 先规整为迭代器输入，再在 done 时组合成结果/fflags。

## 关键产物

- `npc/rv64/design/specs/ooo-alufetchcore-boundary.md`
- `npc/rv64/design/specs/ooo-fp-pending-exec.md`
- `npc/rv64/design/specs/ooo-frontend-uop-safety.md`
- `npc/rv64/design/specs/ooo-frontend-dispatch-gate.md`
- `npc/rv64/design/specs/ooo-branch-prefetch-buffer.md`
- `npc/rv64/design/specs/ooo-direct-branch-wait-buffer.md`
- `npc/rv64/design/specs/ooo-backend-drain-tracker.md`
- `npc/rv64/design/specs/ooo-fetch-packet-hit-mux.md`
- `npc/rv64/design/specs/ooo-fetch-packet-head-mux.md`
- `npc/rv64/design/specs/ooo-fetch-packet-seed-mux.md`
- `npc/rv64/design/specs/ooo-fetch-packet-decode.md`
- `npc/rv64/design/specs/ooo-fetch-packet-fifo.md`
- `npc/rv64/design/specs/ooo-fetch-flow-control.md`
- `npc/rv64/design/specs/ooo-memory-request-gate.md`
- `npc/rv64/design/specs/ooo-commit-output-mux.md`
- `npc/rv64/design/specs/ooo-frontend-backend-dispatch-mux.md`
- `npc/rv64/design/specs/ooo-pending-system-sequencer.md`
- `npc/rv64/design/specs/ooo-pending-memory-sequencer.md`
- `npc/rv64/design/specs/ooo-pending-branch-sequencer.md`
- `npc/rv64/design/specs/ooo-pending-jump-sequencer.md`
- `npc/rv64/design/specs/ooo-pending-fp-sequencer.md`
- `npc/rv64/vsrc/execute/OooFpPendingExec.v`
- `npc/rv64/vsrc/execute/OooPendingFpSequencer.v`
- `npc/rv64/vsrc/memory/OooMemoryRequestGate.v`
- `npc/rv64/vsrc/memory/OooPendingMemorySequencer.v`
- `npc/rv64/vsrc/writeback/OooCommitOutputMux.v`
- `npc/rv64/vsrc/frontend/OooFrontendUopSafety.v`
- `npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v`
- `npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v`
- `npc/rv64/vsrc/frontend/OooPendingBranchSequencer.v`
- `npc/rv64/vsrc/frontend/OooPendingJumpSequencer.v`
- `npc/rv64/vsrc/control/OooPendingSystemSequencer.v`
- `npc/rv64/vsrc/frontend/OooBranchPrefetchBuffer.v`
- `npc/rv64/vsrc/frontend/OooDirectBranchWaitBuffer.v`
- `npc/rv64/vsrc/frontend/OooBackendDrainTracker.v`
- `npc/rv64/vsrc/frontend/OooFetchPacketHitMux.v`
- `npc/rv64/vsrc/frontend/OooFetchPacketHeadMux.v`
- `npc/rv64/vsrc/frontend/OooFetchPacketSeedMux.v`
- `npc/rv64/vsrc/frontend/OooFetchPacketDecode.v`
- `npc/rv64/vsrc/frontend/OooFetchPacketFifo.v`
- `npc/rv64/vsrc/frontend/OooFetchFlowControl.v`
- `npc/rv64/vsrc/frontend/OooAluFetchCore.v`
- `npc/rv64/vsrc/filelist.mk`
- `npc/rv64/testbench/tests/tb_ooo_frontend_uop_safety.sv`
- `npc/rv64/testbench/tests/tb_ooo_frontend_dispatch_gate.sv`
- `npc/rv64/testbench/tests/tb_ooo_branch_prefetch_buffer.sv`
- `npc/rv64/testbench/tests/tb_ooo_direct_branch_wait_buffer.sv`
- `npc/rv64/testbench/tests/tb_ooo_backend_drain_tracker.sv`
- `npc/rv64/testbench/tests/tb_ooo_fetch_packet_hit_mux.sv`
- `npc/rv64/testbench/tests/tb_ooo_fetch_packet_head_mux.sv`
- `npc/rv64/testbench/tests/tb_ooo_fetch_packet_seed_mux.sv`
- `npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv`
- `npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv`
- `npc/rv64/testbench/tests/tb_ooo_fetch_flow_control.sv`
- `npc/rv64/testbench/tests/tb_ooo_memory_request_gate.sv`
- `npc/rv64/testbench/tests/tb_ooo_commit_output_mux.sv`
- `npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv`
- `npc/rv64/testbench/tests/tb_ooo_pending_memory_sequencer.sv`
- `npc/rv64/testbench/tests/tb_ooo_pending_branch_sequencer.sv`
- `npc/rv64/testbench/tests/tb_ooo_pending_jump_sequencer.sv`
- `npc/rv64/testbench/tests/tb_ooo_pending_fp_sequencer.sv`
- `npc/rv64/testbench/tests/tb_ooo_frontend_backend_dispatch_mux.sv`
- `Linux/tools/fp-*-smoke.S` 的 FS enable 与 `FCVT.WU.*` sign-extension 期望修正。

## VERIFY

- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fp-pending-exec/focused run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fp-pending-exec/full-module-testbench run`: PASS 53/53。
- `make -C Linux/tools smoke-fp-convert smoke-fp-compare-sgnj smoke-fp-minmax smoke-fp-addsub smoke-fp-mul smoke-fp-fma smoke-fp-div smoke-fp-sqrt`: PASS。
- `make -C Linux/tools smoke-fp-loadstore smoke-fp-fcsr smoke-fp-fmv-fclass`: PASS。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64uf,rv64ud`: PASS，23 official FP tests。
- `git diff --check -- <本轮相关文件>`: PASS。

## 第二切片 - Fetch Packet FIFO

### 需求

- 把 `OooAluFetchCore` 中 fetch packet FIFO 的存储状态抽成独立前端 helper。
- 新模块只持有 head/tail/count 和 packet storage；父模块继续持有 response bypass、outstanding/stale response、redirect/flush/seed 仲裁和 `next_fetch_pc` 更新。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-packet-fifo.md`。
- `OooFetchPacketFifo` 支持 `enqueue_i`、`pop_i`、`clear_i`、`seed_valid_i`。
- `seed_valid_i` 表示清空旧内容并在 slot0 写入一个 packet，用于 fallthrough response、branch prefetch hit、JALR prefetch hit 三类父模块仲裁后的转正路径。
- `count_o == 0` 等价于 `head_valid_o == 0`；simultaneous enqueue/pop 保持 count，seed 创建单 entry，clear/seed 覆盖普通 enqueue/pop。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchPacketFifo.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除内联 FIFO 指针/数组/计数器，新增组合 action encoder 和 `u_fetch_packet_fifo` 实例。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_packet_fifo.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_packet_fifo RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-fifo/fifo-unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-fifo/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-fifo/full-module-testbench run`: PASS 54/54。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，证据 `npc/rv64/perf/results/core-regress/20260626-193707-415746/`。
- `git diff --check -- <fetch FIFO 切片相关文件>`: PASS。

## 第三切片 - Fetch Flow Control

### 需求

- 把 `OooAluFetchCore` 中 fetch request/response ready-valid 的纯组合决策抽成独立前端 helper。
- 新模块不持有状态；父模块继续持有 PC 选择、`next_fetch_pc`、outstanding/discard response、redirect/trap recovery、FIFO seed 仲裁和 fetch packet FIFO 实例。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-flow-control.md`。
- 输入为父模块已计算好的 redirect、dispatch、FIFO、response bypass、outstanding 和 drop predicates。
- 输出仅为握手/动作信号：`fetch_req_valid_o`、`fetch_rsp_ready_o`、`fetch_rsp_fire_o`、`fetch_rsp_enqueue_o`、`fetch_rsp_can_drop_o`、`fetch_rsp_bypass_consumed_o`、`fifo_storage_pop_o` 与 `can_issue_request_o`。
- 新模块无寄存器、无 PC 加法、无 payload 选择、无 trap/flush 优先级重排；同一输入下输出必须与原父模块内联组合表达式等价。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchFlowControl.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除对应内联 ready/valid/drop/pop 组合赋值，改接 `u_fetch_flow_control`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_flow_control.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_flow_control RESULT_DIR=../perf/results/20260626-ooo-fetch-flow-control/flow-unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fetch-flow-control/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fetch-flow-control/full-module-testbench run`: PASS 55/55。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，证据 `npc/rv64/perf/results/core-regress/20260626-194831-432963/`。
- `git diff --check -- <fetch flow-control 切片相关文件>`: PASS。

## 第四切片 - Fetch Packet Decode

### 需求

- 把 `OooAluFetchCore` 中 fetch response packet 的 RVC 半字拼接和 slot decode 事实抽成独立前端 helper。
- 新模块只输出 slot0/slot1 的 PC、next PC、解压后指令、response、control-stop 和 packet next PC；父模块继续负责 dispatch、FIFO、ready-valid、redirect、trap/flush 和 outstanding 状态。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-packet-decode.md`。
- 输入为 `rsp_pc_i`、两个 32-bit fetch word 和两个 response code。
- slot0 从 `rsp_inst0_i[15:0]` 判定 compressed；slot1 起点由 slot0 长度决定。
- slot1 完全落在 word0 内时继承 `rsp_resp0_i`；slot1 需要 word1 任意半字时使用 `rsp_resp1_i`。
- 本模块无寄存器、无 ready/valid、无 illegal/trap/flush 判定；同一输入下输出必须与原父模块半字/RVC 组合逻辑等价。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchPacketDecode.v`，内部复用两个 `OooRvcDecompressor` 实例。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除内联 `fetch_half*`、`fetch_dec*_compressed`、`fetch_dec*_rvc_inst`、`fetch_dec1_raw32` 等组合逻辑，改接 `u_fetch_packet_decode`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_packet_decode.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_packet_decode RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-decode/decode-unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-decode/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-decode/full-module-testbench run`: PASS 56/56。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，证据 `npc/rv64/perf/results/core-regress/20260626-195747-449939/`。
- `rg -n "fetch_half|fetch_dec0_compressed|fetch_dec1_compressed|fetch_dec1_needs_word1|fetch_dec0_rvc|fetch_dec1_rvc|fetch_dec1_raw32|u_fetch_dec[01]_rvc" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <fetch packet decode 切片相关文件>`: PASS。

## 第五切片 - Frontend Uop Safety Policy

### 需求

- 把 `OooAluFetchCore` 中多处重复的普通 uop 安全白名单抽成参数化前端 helper。
- 新模块只判断组合安全谓词；父模块继续负责 dispatch、branch append、prefetch 转正、redirect 和 precise recovery 的时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-frontend-uop-safety.md`。
- `OooFrontendUopSafety` 输入为 `ctrl_i`、`resp_i`、`inst_i`、`rd_i`、`hazard_rs_i`，输出 `safe_o`。
- 参数定义是否要求 response OK、是否排除 semihost marker、是否允许 load/store/muldiv/bitmanip/sfence/sret/amo、是否启用 rd hazard 检查。
- 模块必须始终要求 valid、非 illegal、need-exec，并始终拒绝 branch/JAL/JALR、ecall/ebreak/system/CSR/fence/misc-mem/mret/wfi。
- 本模块无状态、无 ready/valid、无 trap/flush/redirect 动作。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFrontendUopSafety.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：用具体参数实例替换 lane0-before-ret、return-continuation、branch fallthrough、branch target capture、branch prefetch buffer/rsp slot 的内联白名单；删除旧 `branch_prefetch_plain_uop_safe` function。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_frontend_uop_safety.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_frontend_uop_safety RESULT_DIR=../perf/results/20260626-ooo-frontend-uop-safety/uop-safety-unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-frontend-uop-safety/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-frontend-uop-safety/full-module-testbench run`: PASS 57/57。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，证据 `npc/rv64/perf/results/core-regress/20260626-200912-467183/`。
- `rg -n "branch_prefetch_plain_uop_safe|CTRL_LOAD_BIT\\]|CTRL_STORE_BIT\\]|CTRL_MULDIV_BIT\\]|CTRL_BITMANIP_BIT\\]|CTRL_SFENCE_VMA_BIT\\]|CTRL_SRET_BIT\\]|CTRL_AMO_BIT\\]" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no old prefetch function; remaining matches are decode classification only。
- `git diff --check -- <frontend uop safety 切片相关文件>`: PASS。

## 第六切片 - Frontend Dispatch Gate

### 需求

- 把 `OooAluFetchCore` 中 front-end dispatch 入口的纯组合 gating 抽成独立 helper。
- 新模块只负责 lane1 direct JAL/return/branch 候选、lane1 barrier/control unsupported、normal dispatch fire、direct JAL0/JAL1/ret1/branch1 fire 等组合判断。
- 父模块继续持有 slot0 branch fast path、pending branch/jump/mem/fp/system sequencer、commit/trap/redirect 和 precise recovery 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-frontend-dispatch-gate.md`。
- `OooFrontendDispatchGate` 输入为父模块已生成的 dispatch valid、slot0/slot1 decode predicates、FP raw mask、return candidate、lane0 safety 和 backend ready。
- 输出仅为 dispatch/direct-path fire 与 lane1 barrier/unsupported predicates；模块无寄存器、无 ready/valid 存储、无 PC/target 选择、无 trap/flush/redirect 副作用。
- 保留旧语义：`dispatch_unsupported` 排除 slot0 branch/JALR，但不排除 slot0 JAL；slot0 JAL 仍由 direct JAL0 path 处理。
- `dispatch_fire_o` 只描述普通 dispatch path 消费，不吞掉 direct JAL/return/branch fast path 的优先级所有权。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFrontendDispatchGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除对应内联 dispatch gate 组合赋值，改接 `u_frontend_dispatch_gate`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_frontend_dispatch_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_frontend_dispatch_gate RESULT_DIR=../perf/results/20260626-ooo-frontend-dispatch-gate/dispatch-gate-unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-frontend-dispatch-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-frontend-dispatch-gate/full-module-testbench run`: PASS 58/58。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-201950-484386/`。
- `rg -n "wire dispatch1_direct_jal_w =|wire dispatch1_return_w =|wire direct_branch1_dispatch_valid_w =|wire dispatch1_barrier_w =|wire dispatch1_control_unsupported_w =|wire dispatch_unsupported_w =|wire dispatch_fire_w =|wire direct_jal0_fire_w =|wire direct_jal1_fire_w =|wire direct_ret1_fire_w =|wire direct_branch1_fire_w =|assign dispatch1_barrier_fire_w" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <frontend dispatch gate 切片相关文件>`: PASS。

## 第七切片 - Branch Prefetch Buffer

### 需求

- 把 `OooAluFetchCore` 中 branch prefetch 影子包状态抽成独立 front-end helper。
- 新模块只持有 active/request PC、buffer valid 和 packet payload。
- 父模块继续负责 request/capture/clear 条件生成、branch resolve match、FIFO seed、redirect PC、outstanding/discard 和 precise recovery 仲裁。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-prefetch-buffer.md`。
- `OooBranchPrefetchBuffer` 输入为 `clear_i`、`req_fire_i/req_pc_i`、`rsp_capture_i` 和 response packet payload。
- 状态优先级为 reset > clear > request/capture；request 与 capture 同拍时 capture 后写 `buffer_valid/payload`，保留旧 nonblocking 赋值顺序。
- 非 reset clear 只清 active、buffer valid 和 request PC，不清 payload；payload 只有 reset 或 capture 改写。
- 新模块不发起 fetch request、不判断 resolve match、不决定 FIFO seed、不修改 `next_fetch_pc`、outstanding、trap、commit 或 pending 状态。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchPrefetchBuffer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 `branch_prefetch_* <=` 内联状态赋值，新增 `branch_prefetch_clear_w` 和 `u_branch_prefetch_buffer`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_prefetch_buffer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_prefetch_buffer RESULT_DIR=../perf/results/20260626-ooo-branch-prefetch-buffer/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-branch-prefetch-buffer/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-branch-prefetch-buffer/full-module-testbench run`: PASS 59/59。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-203320-502387/`。
- `rg -n "branch_prefetch_(active_q|buffer_valid_q|pc_q|buf_).*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <branch prefetch buffer 切片相关文件>`: PASS。

## 第八切片 - Direct Branch Wait Buffer

### 需求

- 把 `OooAluFetchCore` 中 direct branch 等待后端 resolve 的单 entry 状态抽成独立 front-end helper。
- 新模块只持有 pending 和 branch PC。
- 父模块继续负责 direct branch fire/PC、resolve match/untracked、redirect、trap、BPU update 和 precise recovery 仲裁。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-direct-branch-wait-buffer.md`。
- `OooDirectBranchWaitBuffer` 输入为 `clear_i`、`resolve_match_i`、`branch_fire_i`、`branch_resolve_valid_i` 和 `branch_pc_i`。
- 状态优先级为 reset/clear > resolve match > branch fire；在普通周期里 match 与 new branch fire 同拍时，新 branch fire 覆盖旧 match clear。
- `branch_fire_i && branch_resolve_valid_i` 同拍 resolved 时不置 pending，并清 PC。
- 新模块不判断方向、不选择 redirect PC、不更新 BPU/RAS/FIFO/ROB/CSR，也不修改 stop-pending 或 trap/commit 状态。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooDirectBranchWaitBuffer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 `direct_branch_wait_* <=` 内联状态赋值，新增 `u_direct_branch_wait_buffer`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_direct_branch_wait_buffer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_direct_branch_wait_buffer RESULT_DIR=../perf/results/20260626-ooo-direct-branch-wait-buffer/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-direct-branch-wait-buffer/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-direct-branch-wait-buffer/full-module-testbench run`: PASS 60/60。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-204020-518686/`。
- `rg -n "direct_branch_wait_(q|pc_q)\\s*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <direct branch wait buffer 切片相关文件>`: PASS。

## 第九切片 - Backend Drain Tracker

### 需求

- 把 `OooAluFetchCore` 中前端视角下的 backend drained 打拍状态抽成独立 front-end helper。
- 新模块只持有 `drained_o` 一个状态位，用来记录“上一拍后端为空且没有普通 dispatch fire”的稳定事实。
- 父模块继续负责 ROB/IQ/pending/retire empty 组合判定、dispatch fire 生成、CSR trap drain 强制完成、stop-pending、trap/interrupt/redirect 和 commit/writeback 仲裁。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-backend-drain-tracker.md`。
- `OooBackendDrainTracker` 输入为 `backend_empty_i`、`dispatch_fire_i` 和 `force_drained_i`，输出 `drained_o`。
- 状态优先级为 reset > force drained > normal update；normal update 等价于 `backend_empty_i && !dispatch_fire_i`。
- reset 后默认为 drained；CSR trap commit 这类父模块已判定的强制 drain 完成事件通过 `force_drained_i` 置位。
- 新模块不判断 ROB/IQ/LSQ/FP pending 是否为空，不直接发起 flush/trap/commit，也不修改任何后端资源。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBackendDrainTracker.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：将 `backend_drained_q` 从父模块寄存器改为子模块输出 wire，删除父模块内联 `backend_drained_q <= ...` 赋值，新增 `u_backend_drain_tracker`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_backend_drain_tracker.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_backend_drain_tracker RESULT_DIR=../perf/results/20260626-ooo-backend-drain-tracker/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-backend-drain-tracker/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-backend-drain-tracker/full-module-testbench run`: PASS 61/61。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-213051-543151/`。
- `rg -n "backend_drained_q\\s*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <backend drain tracker 切片相关文件>`: PASS。

## 第十切片 - Fetch Packet Head Mux

### 需求

- 把 `OooAluFetchCore` 中 dispatch 可见 fetch packet head 的来源选择抽成独立前端 helper。
- 新模块只在 response bypass packet 与 FIFO head packet 之间做组合 mux，并输出 `head_has_packet_o`。
- 父模块继续负责 bypass 条件生成、FIFO pop/enqueue/seed、packet decode、response ready-valid、redirect/trap recovery 和 `next_fetch_pc` 更新。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-packet-head-mux.md`。
- `OooFetchPacketHeadMux` 输入为 `bypass_valid_i`、`fifo_head_valid_i`、decoded bypass packet payload 和 FIFO head packet payload。
- `head_has_packet_o = bypass_valid_i || fifo_head_valid_i`。
- `bypass_valid_i` 为真时所有 payload 输出来自 bypass；否则来自 FIFO head。
- 新模块不检查 instruction opcode、不解释 response code、不产生 FIFO pop，也不决定 bypass 是否合法。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchPacketHeadMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 head packet payload 的内联 ternary mux，改由 `u_fetch_packet_head_mux` 输出 `fifo_has_packet_w` 和 slot0/slot1 head fields。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_packet_head_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_packet_head_mux RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-head-mux/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-head-mux/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-head-mux/full-module-testbench run`: PASS 62/62。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-213915-559886/`。
- `rg -n "fetch_rsp_dispatch_bypass_w \\? fetch_dec|fetch_rsp_dispatch_bypass_w \\? fetch_rsp_packet" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <fetch packet head mux 切片相关文件>`: PASS。

## 第十一切片 - Fetch Packet Seed Mux

### 需求

- 把 `OooAluFetchCore` 中 redirect/recovery 事件到 fetch packet FIFO `clear/seed` 输入的组合 action encoder 抽成独立前端 helper。
- 新模块只负责 `fifo_clear_w`、`fifo_seed_valid_w` 和 seed packet payload 的优先级选择。
- 父模块继续负责生成 CSR trap、direct flush、branch/JALR resolve、pending drain、prefetch hit、packet decode、FIFO storage 和 `next_fetch_pc` 更新。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-packet-seed-mux.md`。
- `OooFetchPacketSeedMux` 输入为父模块已判定的 event predicates 与三类 packet payload：fallthrough response、branch prefetch hit、JALR prefetch hit。
- 组合优先级保留旧语义：CSR trap 最终覆盖；direct flush 可被 fallthrough capture seed；branch commit/resolve、untracked branch、JALR redirect、CSR commit 和 drain owner 产生 clear/seed；memory replay dispatch 与 CSR dispatch 是 no-op blocker。
- 新模块不判断 prefetch hit 是否真实、不产生 FIFO pop/enqueue、不解释 instruction/response，不更新 PC。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchPacketSeedMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：将 `fifo_clear_w` 和 `fifo_seed_*_w` 从父模块组合 `reg` 改为 helper 输出 `wire`，删除内联 `always @*` seed encoder，改接 `u_fetch_packet_seed_mux`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_packet_seed_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_packet_seed_mux RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-seed-mux/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-seed-mux/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-seed-mux/full-module-testbench run`: PASS 63/63。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-231828-593642/`。
- `rg -n "fifo_(clear_w|seed_[a-z0-9_]+_w)\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <fetch packet seed mux 切片相关文件>`: PASS。

## 第十二切片 - Fetch Packet Hit Mux

### 需求

- 把 `OooAluFetchCore` 中 branch/JALR prefetch hit payload 在 same-cycle response capture 与 buffered packet 之间的重复组合选择抽成独立 helper。
- 新模块只负责 packet payload mux；父模块继续负责 hit/match 判定、target validation、prefetch buffer state、redirect 和 FIFO seed 策略。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-packet-hit-mux.md`。
- `OooFetchPacketHitMux` 输入为 `rsp_select_i`、response packet payload 和 buffered packet payload。
- `rsp_select_i` 为真时所有输出来自 response capture，否则全部来自 buffer。
- 新模块不判断 hit 是否 available、不比较 PC、不解释 opcode/response、不修改任何状态。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchPacketHitMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 branch 与 JALR prefetch hit payload 的两组内联 ternary mux，改用 `u_branch_prefetch_hit_mux` 与 `u_jalr_prefetch_hit_mux`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_packet_hit_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_packet_hit_mux RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-hit-mux/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-hit-mux/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260626-ooo-fetch-packet-hit-mux/full-module-testbench run`: PASS 64/64。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260626-232509-609814/`。
- `rg -n "(branch|jalr)_prefetch_rsp_match_w \\? fetch_dec|(branch|jalr)_prefetch_rsp_match_w \\? fetch_rsp_packet" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <fetch packet hit mux 切片相关文件>`: PASS。

## 第十三切片 - Frontend Run Gate

### 需求

- 把 `OooAluFetchCore` 中前端 `can_run`、`stop_pending` owner/orphan、response bypass 和 fetch FIFO/outstanding credit 的纯组合判定抽成独立 helper。
- 新模块只负责运行许可和 credit/bypass predicate；父模块继续负责所有时序状态，包括 stop pending 清理、PC/outstanding/discard、FIFO storage 和 redirect/trap recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-frontend-run-gate.md`。
- `OooFrontendRunGate` 输入为 run/flush/halt/trap/exit、stop pending owner predicates、FIFO storage head、outstanding/response/discard 和 FIFO count/depth。
- Orphan stop 不阻塞 `can_run_o`；owned/busy stop 必须阻塞。
- Trap flush、serial flush、halted、trap valid、exit valid 任一为真时 `can_run_o` 必须为假。
- Response bypass 只在 FIFO storage head 为空、前端可运行、有 outstanding、response valid 且未 discard 时成立。
- Reserve credit 只由 FIFO resident packet 与 outstanding request 共同消耗。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFrontendRunGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 `stop_pending_owner_w`、`orphan_stop_pending_w`、`stop_pending_busy_w`、`can_run_w`、`fifo_empty_storage_w`、`fetch_rsp_dispatch_bypass_w`、`outstanding_count_w` 与 `fifo_reserve_available_w` 的内联组合表达式，改由 `u_frontend_run_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_frontend_run_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_frontend_run_gate RESULT_DIR=../perf/results/20260627-ooo-frontend-run-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-frontend-run-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-frontend-run-gate/full-module-testbench run`: PASS 65/65。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-001053-633515/`。
- `rg -n "stop_pending_owner_w|orphan_stop_pending_w =|stop_pending_busy_w =|can_run_w =|fifo_empty_storage_w =|fetch_rsp_dispatch_bypass_w =|outstanding_count_w =|fifo_reserve_available_w =" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <frontend run gate 切片相关文件>`: PASS。

## 第十四切片 - Frontend Action Gate

### 需求

- 把 `OooAluFetchCore` 中 direct frontend flush、stop-head、FIFO pop、fetch response control-stop 和 trap-blocked request 的纯组合动作谓词抽成独立 helper。
- 新模块只负责组合 predicate；父模块继续负责 PC 选择、response ready-valid、FIFO storage、dispatch sequencer、pending/redirect/trap/commit 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-frontend-action-gate.md`。
- `OooFrontendActionGate` 输入为父模块已经解码或仲裁后的 direct fast-path fire、dispatch head predicate、FIFO pop fire、response control-stop 和 trap request blocker predicate。
- `direct_frontend_flush_o` 是 direct JAL/branch/return fast path fire 的 OR。
- `stop_head_o` 只在 `can_run_i && fifo_has_packet_i && !branch_spec_dispatch_block_i` 且当前 head 需要 barrier/unsupported/direct 处理时为真。
- `fifo_pop_o` 仅由 normal dispatch fire、lane1 barrier fire 和 lane0 direct JAL fire 产生。
- `fetch_rsp_control_stop_o` 只在 response fire、可 enqueue 且 decoded packet 含 control-stop 时为真。
- `fetch_request_blocked_by_trap_o` 只由 CSR trap pending 或 core-local trap/serial flush 产生。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFrontendActionGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 `direct_frontend_flush_w`、`stop_head_w`、`fifo_pop_w`、`fetch_rsp_control_stop_w` 与 `fetch_request_blocked_by_trap_w` 的内联组合表达式，改由 `u_frontend_action_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_frontend_action_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_frontend_action_gate RESULT_DIR=../perf/results/20260627-ooo-frontend-action-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-frontend-action-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-frontend-action-gate/full-module-testbench run`: PASS 66/66。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-001820-649962/`。
- `rg -n "direct_frontend_flush_w =|stop_head_w =|fifo_pop_w =|fetch_rsp_control_stop_w =|fetch_request_blocked_by_trap_w =" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <frontend action gate 切片相关文件>`: PASS。

## 第十五切片 - Fetch Request Mux

### 需求

- 把 `OooAluFetchCore` 中 fetch request PC/source 的组合选择抽成独立 helper。
- 新模块只负责顺序 PC、redirect request valid/target 和 redirect/prefetch/seq 三类 fetch request PC 选择。
- 父模块继续负责 `next_fetch_pc_q`、outstanding/discard、response ready-valid、redirect recovery 和 request ready-valid 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-request-mux.md`。
- `OooFetchRequestMux` 输入为顺序 PC facts、direct/branch/spec redirect predicates、redirect target candidates、branch fallthrough outstanding suppression 以及 branch prefetch request。
- Redirect request 优先级高于 branch prefetch，高于顺序取指。
- Outstanding 未返回且本拍 response 未 fire 时，redirect request valid 必须为假。
- Branch fallthrough 已有匹配 outstanding 时，redirect request valid 必须为假。
- Redirect target 优先级保留旧语义：direct JAL、direct return、lane0 branch to lane1 return、branch target cache、fallthrough、direct branch resolve、pending jump、branch speculation/default branch resolve。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchRequestMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 `fetch_req_seq_pc_w`、`direct_redirect_fetch_w`、`redirect_fetch_req_valid_w`、`redirect_fetch_pc_w` 与 `fetch_req_pc_w` 的内联组合表达式，改由 `u_fetch_request_mux` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_request_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_request_mux RESULT_DIR=../perf/results/20260627-ooo-fetch-request-mux/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-fetch-request-mux/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-fetch-request-mux/full-module-testbench run`: PASS 67/67。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-003343-667911/`。
- `rg -n "\\bfetch_req_seq_pc_w\\b|\\bdirect_redirect_fetch_w\\s*=|\\bredirect_fetch_req_valid_w\\s*=|\\bredirect_fetch_pc_w\\s*=|\\bfetch_req_pc_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <fetch request mux 切片相关文件>`: PASS。

## 第十六切片 - Branch Prefetch Request Gate

### 需求

- 把 `OooAluFetchCore` 中 pending branch 与 JALR BTB hit 发起 branch prefetch request 的组合 gating 抽成独立 helper。
- 新模块只负责 branch/JALR prefetch request valid 和 request PC 选择；父模块继续负责 BTB/RAS lookup、branch resolve、prefetch buffer、outstanding/discard 和 fetch request ready-valid 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-prefetch-request-gate.md`。
- `OooBranchPrefetchRequestGate` 输入为 branch source、JALR source 和 shared blockers。
- 任一 shared blocker 为真时，branch/JALR request 都必须无效。
- Branch request 必须要求 stop pending、pending branch、branch dispatched，且当前 resolve 尚未命中同一 pending branch。
- JALR request 必须要求 BTB hit 且 pending jump 尚未 dispatched。
- 当 branch 与 JALR request 同时为真时，`req_pc_o` 选择 JALR BTB target，保持旧 PC mux 优先级。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchPrefetchRequestGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 `branch_prefetch_branch_req_valid_w`、`branch_prefetch_jalr_req_valid_w`、`branch_prefetch_req_valid_w` 和 `branch_prefetch_req_pc_w` 的内联组合表达式，改由 `u_branch_prefetch_request_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_prefetch_request_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_prefetch_request_gate RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-request-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-request-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-request-gate/full-module-testbench run`: PASS 68/68。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-004106-684352/`。
- `rg -n "branch_prefetch_branch_req_valid_w\\s*=|branch_prefetch_jalr_req_valid_w\\s*=|branch_prefetch_req_valid_w\\s*=|branch_prefetch_req_pc_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <branch prefetch request gate 切片相关文件>`: PASS。

## 第十七切片 - Branch Prefetch Status Gate

### 需求

- 把 `OooAluFetchCore` 中 branch prefetch response capture、resolve PC
  match、buffer/same-cycle hit 和 pending match 的纯组合判定抽成独立 helper。
- 新模块只负责 status predicate；父模块继续负责 prefetch buffer 写入/清空、hit
  packet 选择、JALR 专用 hit status、request/outstanding 和 recovery 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-prefetch-status-gate.md`。
- `OooBranchPrefetchStatusGate` 输入为 capture source、match source 和 buffer
  source。
- Response capture 必须要求 active、buffer 尚未 valid、stop pending、response
  fire，且 owner 为 dispatched pending branch 或 pending JALR。
- Match 必须要求 active 且 prefetch PC 等于 branch resolve next PC。
- `buffer_match_o = match_o && buffer_valid`，`rsp_match_o = match_o &&
  rsp_capture_o`，`hit_available_o` 为二者 OR。
- Match 成立但没有 buffered hit 或 same-cycle response hit 时，必须产生
  `pending_match_o`。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchPrefetchStatusGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除
  `branch_prefetch_rsp_capture_w`、`branch_prefetch_match_w`、
  `branch_prefetch_buffer_match_w`、`branch_prefetch_rsp_match_w`、
  `branch_prefetch_hit_available_w` 和 `branch_prefetch_pending_match_w` 的内联组合表达式，
  改由 `u_branch_prefetch_status_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_prefetch_status_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_prefetch_status_gate RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-status-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-status-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-status-gate/full-module-testbench-rerun run`: PASS 69/69。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-004920-701721/`。
- `rg -n "branch_prefetch_rsp_capture_w\\s*=|branch_prefetch_match_w\\s*=|branch_prefetch_buffer_match_w\\s*=|branch_prefetch_rsp_match_w\\s*=|branch_prefetch_hit_available_w\\s*=|branch_prefetch_pending_match_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <branch prefetch status gate 切片相关文件>`: PASS。

## 第十八切片 - JALR Prefetch Status Gate

### 需求

- 把 `OooAluFetchCore` 中 JALR branch-prefetch target-ready、target mux、
  match、buffer/same-cycle hit 和 pending match 的纯组合判定抽成独立 helper。
- 新模块只负责 JALR prefetch status predicate；父模块继续负责 JALR target 计算、
  JALR BTB update、hit packet mux、prefetch buffer 状态和 PC/outstanding/discard
  时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-jalr-prefetch-status-gate.md`。
- `OooJalrPrefetchStatusGate` 输入为 JALR owner、target source、prefetch source
  和 hit source。
- Target ready 来自已 dispatch JALR target 或当前 resolve-ready target；已
  dispatch target 优先于当前 resolve target。
- JALR match 必须要求 active、stop pending、pending jump、JALR 类型、target
  ready、非 misaligned，且 prefetch PC 等于所选 target。
- `buffer_match_o = match_o && buffer_valid`，`rsp_match_o = match_o &&
  rsp_capture`，`hit_available_o` 为二者 OR。
- Match 成立但没有 buffered hit 或 same-cycle response hit 时，必须产生
  `pending_match_o`。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooJalrPrefetchStatusGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除
  `jalr_prefetch_target_ready_w`、`jalr_prefetch_target_w`、
  `jalr_prefetch_match_w`、`jalr_prefetch_buffer_match_w`、
  `jalr_prefetch_rsp_match_w`、`jalr_prefetch_hit_available_w` 和
  `jalr_prefetch_pending_match_w` 的内联组合表达式，改由
  `u_jalr_prefetch_status_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_jalr_prefetch_status_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_jalr_prefetch_status_gate RESULT_DIR=../perf/results/20260627-ooo-jalr-prefetch-status-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-jalr-prefetch-status-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-jalr-prefetch-status-gate/full-module-testbench run`: PASS 70/70。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-005750-718571/`。
- `rg -n "jalr_prefetch_target_ready_w\\s*=|jalr_prefetch_target_w\\s*=|jalr_prefetch_match_w\\s*=|jalr_prefetch_buffer_match_w\\s*=|jalr_prefetch_rsp_match_w\\s*=|jalr_prefetch_hit_available_w\\s*=|jalr_prefetch_pending_match_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <jalr prefetch status gate 切片相关文件>`: PASS。

## 第十九切片 - Branch Prefetch Source Gate

### 需求

- 把 `OooAluFetchCore` 中 pending branch target、branch prefetch predicted PC、
  JALR return hint 和 JALR BTB lookup 的纯组合 source facts 抽成独立 helper。
- 新模块只负责 branch/JALR prefetch source facts；父模块继续负责 pending 状态、
  RAS/BTB 表项、request gate、branch resolve 和 recovery 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-prefetch-source-gate.md`。
- `OooBranchPrefetchSourceGate` 输入为 branch source、JALR source 和 RAS source。
- `pending_branch_target_o = pending_branch_pc_i + pending_branch_imm_i`。
- `branch_pred_pc_o` 在 predicted-taken 时选择 branch target，否则选择 branch
  fallthrough next PC。
- Return hint 必须要求 pending jump、JALR、`rd=x0`、`rs1=x1/x5`、`imm=0`。
- JALR BTB lookup 必须要求 `stop_pending && pending_jump && pending_jump_jalr`；
  return hint 且 RAS 非空时由 RAS path 抑制 BTB lookup，RAS 为空时仍允许 BTB fallback。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchPrefetchSourceGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除
  `pending_branch_target_w`、`branch_prefetch_branch_predict_taken_w`、
  `branch_prefetch_branch_pred_pc_w`、`pending_jump_jalr_ret_hint_w` 和
  `pending_jump_jalr_btb_lookup_w` 的内联组合表达式，改由
  `u_branch_prefetch_source_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_prefetch_source_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_prefetch_source_gate RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-source-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-source-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-prefetch-source-gate/full-module-testbench run`: PASS 71/71。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-010712-735629/`。
- `rg -n "pending_branch_target_w\\s*=|branch_prefetch_branch_predict_taken_w\\s*=|branch_prefetch_branch_pred_pc_w\\s*=|pending_jump_jalr_ret_hint_w\\s*=|pending_jump_jalr_btb_lookup_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <branch prefetch source gate 切片相关文件>`: PASS。

## 第二十切片 - Direct Branch Resolve Gate

### 需求

- 把 `OooAluFetchCore` 中 direct branch lane 选择、branch target、
  BHT payload 选择、预测 PC、dispatch/issue resolve 优先级、redirect/taken
  判定和 lane1 return capture 的纯组合事实抽成独立 helper。
- 新模块只负责 direct branch resolve gate 的组合事实；父模块继续负责 BPU/RAS
  表项、pending 状态、trap squash、PC/outstanding/discard 和 branch/RAS update
  时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-direct-branch-resolve-gate.md`。
- `OooDirectBranchResolveGate` 输入为 direct branch fire、lane0/lane1 payload、
  BHT payload、dispatch resolve、issue resolve、trap squash 和 synthetic lane1
  return blocker。
- Lane1 fire 优先选择 lane1 payload；否则选择 lane0 payload。
- Dispatch resolve 只在 resolve PC 匹配 active direct branch lane 时有效，且优先于
  issue resolve；issue resolve 只在 resolve PC 匹配所选 direct branch PC 时有效。
- Misaligned resolve 不产生 redirect；trap squash 只屏蔽 redirect/taken，不抹掉
  resolve payload 本身。
- Lane1 return capture 必须要求 lane0 direct branch fire、resolve valid、非 misaligned、
  resolve next PC 等于 lane1 PC、lane1 是 return candidate，且没有 synthetic lane1
  return/branch-drop pending。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooDirectBranchResolveGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 direct branch fire/payload
  选择、BHT payload 选择、预测 PC、dispatch/issue resolve、redirect/taken 和
  lane1 return capture 的内联组合表达式，改由 `u_direct_branch_resolve_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_direct_branch_resolve_gate.sv`。
- 更新 `npc/rv64/testbench/tests/tb_ooo_fetch_trap_gate.sv`：原测试层次化引用
  `dut.direct_branch_resolve_redirect_raw_w`，拆分后该 raw wire 归属
  `u_direct_branch_resolve_gate`，测试改为 force/release 新模块内部 raw wire，
  父模块继续只观察正式 masked redirect 输出。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_direct_branch_resolve_gate RESULT_DIR=../perf/results/20260627-ooo-direct-branch-resolve-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-direct-branch-resolve-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_trap_gate RESULT_DIR=../perf/results/20260627-ooo-direct-branch-resolve-gate/fetch-trap run`: PASS 1/1。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-direct-branch-resolve-gate/full-module-testbench run`: PASS 72/72。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-012111-753582/`。
- `rg -n "direct_branch_fire_w\\s*=|direct_branch_pc_w\\s*=|direct_branch_next_pc_w\\s*=|direct_branch_imm_w\\s*=|head0_branch_target_w\\s*=|direct_branch_target_w\\s*=|direct_branch_bht_idx_w\\s*=|direct_branch_bht_valid_w\\s*=|direct_branch_predict_strong_w\\s*=|direct_branch_predict_taken_w\\s*=|direct_branch_pred_pc_w\\s*=|direct_branch0_dispatch_resolve_valid_w\\s*=|direct_branch1_dispatch_resolve_valid_w\\s*=|direct_branch_dispatch_resolve_valid_w\\s*=|direct_branch_issue_resolve_valid_w\\s*=|direct_branch_resolve_valid_w\\s*=|direct_branch_resolve_next_pc_w\\s*=|direct_branch_resolve_misaligned_w\\s*=|direct_branch_resolve_redirect_raw_w\\s*=|direct_branch_resolve_redirect_w\\s*=|direct_branch_resolve_taken_w\\s*=|direct_branch0_lane1_ret_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <direct branch resolve gate 切片相关文件>`: PASS。

## 第二十一切片 - Branch Resolve Recovery Gate

### 需求

- 把 `OooAluFetchCore` 中 pending branch resolve match、tracked redirect、
  backend execute quiet、branch-spec checkpoint/restore/redirect、direct branch
  wait untracked 和 generic untracked redirect 的纯组合恢复谓词抽成独立 helper。
- 新模块只负责 branch resolve recovery predicates；父模块继续负责 pending/spec/wait
  状态、PC/outstanding/discard、BPU/RAS update 和 trap/CSR 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-resolve-recovery-gate.md`。
- `branch_resolve_pending_pc_match_o` 只检查 branch resolve valid 与 pending branch
  PC 相等；`branch_resolve_pending_match_o` 额外要求 stop-pending、pending branch 和
  pending branch dispatched ownership。
- Tracked branch redirect 必须要求 pending match、非 misaligned、没有 branch
  prefetch match 且未被 trap redirect squash。
- Branch-spec checkpoint capture 必须要求 checkpoint pending、pending branch ownership、
  backend execute quiet，且 memory idle 或 pending-load branch dependency 成立。
- Branch-spec restore 在 branch-spec resolve valid 且 resolved next PC 不等于 predicted
  PC 时成立；misaligned resolve 可以暴露 restore，但不能产生 redirect。
- Direct-branch-wait untracked 必须要求 wait-buffer PC match、没有 pending-branch match
  且没有 same-cycle direct branch resolve。
- Generic untracked resolve 在 branch-spec resolve valid 时被抑制；trap redirect squash
  只屏蔽 redirect 输出，不抹掉 raw match/status。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchResolveRecoveryGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 pending branch resolve、
  tracked redirect、backend quiet、branch-spec checkpoint/restore/redirect、direct wait
  untracked 和 generic untracked redirect 的内联组合表达式，改由
  `u_branch_resolve_recovery_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_resolve_recovery_gate.sv`。
- 更新 `npc/rv64/testbench/tests/tb_ooo_fetch_trap_gate.sv`：tracked/untracked/branch-spec
  raw redirect force/release 路径迁到 `u_branch_resolve_recovery_gate` 内部 raw wire。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_resolve_recovery_gate RESULT_DIR=../perf/results/20260627-ooo-branch-resolve-recovery-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-resolve-recovery-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_trap_gate RESULT_DIR=../perf/results/20260627-ooo-branch-resolve-recovery-gate/fetch-trap run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-resolve-recovery-gate/full-module-testbench run`: PASS 73/73。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-013017-770497/`。
- `rg -n "branch_resolve_pending_pc_match_w\\s*=|branch_resolve_pending_match_w\\s*=|branch_resolve_redirect_raw_w\\s*=|branch_resolve_redirect_w\\s*=|backend_execute_quiet_w\\s*=|branch_spec_checkpoint_capture_w\\s*=|branch_spec_resolve_valid_w\\s*=|branch_spec_pred_match_w\\s*=|branch_spec_restore_w\\s*=|branch_spec_redirect_raw_w\\s*=|branch_spec_redirect_w\\s*=|direct_branch_wait_resolve_match_w\\s*=|direct_branch_wait_untracked_w\\s*=|branch_resolve_untracked_raw_w\\s*=|branch_resolve_untracked_w\\s*=|branch_resolve_untracked_redirect_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <branch resolve recovery gate 切片相关文件>`: PASS。

## 第二十二切片 - Pending Control Resolve Gate

### 需求

- 把 `OooAluFetchCore` 中 pending branch next/misaligned、pending JAL/JALR
  resolved target、JALR sum LSB、pending jump resolve-ready、return/call/no-link
  分类、fire/commit/redirect-after-dispatch 和 pending-control-ready 的纯组合事实抽成
  独立 helper。
- 新模块只负责 pending control resolve facts；父模块继续负责 pending 状态、
  `CompareUnit`、RAS/BTB 表项、trap/commit 和 PC/outstanding/discard 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-control-resolve-gate.md`。
- Pending branch next PC 在 taken 时选择 target，否则选择 fallthrough。
- Pending branch misaligned 只在 taken 且 target bit0 为 1 时成立。
- Pending jump resolve-ready 必须要求 `stop_pending && pending_jump &&
  !pending_jump_dispatched && backend_drained`。
- JALR resolved target 使用 `rs1 + imm` 并清 bit0；JAL resolved target 使用
  `pc + imm`。
- Return hint 要求 pending JALR、`rd=x0`、`rs1=x1/x5`、`imm=0` 且 RAS 非空。
- Call hint 要求 pending jump 且 `rd=x1/x5`。
- No-link JALR 要求 pending JALR、非 return hint 且 `rd=x0`。
- Return/call fire 要求 resolve-ready、`jump_dispatch_fire` 且非 misaligned；
  no-link commit 要求 resolve-ready、非 misaligned 且 `commit_ready`；
  redirect-after-dispatch 要求 resolve-ready、非 misaligned、非 no-link 且
  `jump_dispatch_fire`。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooPendingControlResolveGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 pending branch next/misaligned、
  pending jump target/ready、return/call/no-link/fire/commit/redirect 和
  pending-control-ready 的内联组合表达式，改由 `u_pending_control_resolve_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_control_resolve_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_pending_control_resolve_gate RESULT_DIR=../perf/results/20260627-ooo-pending-control-resolve-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-pending-control-resolve-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-control-resolve-gate/full-module-testbench run`: PASS 74/74。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-014016-787548/`。
- `rg -n "pending_branch_fallthrough_w\\s*=|pending_branch_next_pc_w\\s*=|pending_branch_misaligned_w\\s*=|pending_jump_jal_target_w\\s*=|pending_jump_jalr_sum_w\\s*=|pending_jump_jalr_sum_lsb_unused_w\\s*=|pending_jump_resolved_target_w\\s*=|pending_jump_misaligned_w\\s*=|pending_jump_resolve_ready_w\\s*=|pending_jump_return_w\\s*=|pending_jump_return_fire_w\\s*=|pending_jump_call_w\\s*=|pending_jump_call_fire_w\\s*=|pending_jump_nolink_w\\s*=|pending_jump_nolink_commit_w\\s*=|pending_jump_redirect_after_dispatch_w\\s*=|pending_control_ready_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `git diff --check -- <pending control resolve gate 切片相关文件>`: PASS。

## 第二十三切片 - Branch Append Dispatch Gate

### 需求

- 把 `OooAluFetchCore` 中 return-cont optional/attempt-ready、branch target/
  fallthrough lane1 append candidate/attempt/dispatch、fallthrough outstanding
  keep/capture、branch prefetch direct-dispatch dead-path 和 `dispatch1_optional`
  的纯组合门控抽成独立 helper。
- 新模块只负责 branch append dispatch predicates；父模块继续负责相关状态寄存器、
  dispatch payload mux、FIFO seed/enqueue 和 PC/outstanding/discard 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-append-dispatch-gate.md`。
- Return-cont optional 只要求 lane0 branch 与 return-cont match。
- Return-cont same-cycle append 仍显式关闭；即使 attempt-ready 为真，
  `return_cont_attempt` 也必须为 0。
- Branch target candidate 只要求 lane0 branch 与 branch target cache hit。
- Branch fallthrough candidate 只要求 lane0 branch 与 fallthrough append safe；
  outstanding fetch 存在时，只有 response bypass 或 outstanding PC 等于 lane1
  fallthrough PC 才允许 safe。
- Branch target/fallthrough append attempts 仍显式关闭，避免未打拍 fast path
  参与 ready/resolve 组合环。
- Branch prefetch direct dispatch 仍显式关闭；buffer/rsp dispatch attempt 和
  dispatch fire 必须为 0。
- Branch prefetch hit 在 direct dispatch 未 fire 时进入 FIFO。
- `dispatch1_optional` 只聚合 return-cont、branch target append 和 branch
  fallthrough append 三类 optional candidate。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchAppendDispatchGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 return-cont/branch
  append、fallthrough outstanding、branch prefetch direct-dispatch 和
  `dispatch1_optional` 的内联组合表达式，改由 `u_branch_append_dispatch_gate`
  输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_append_dispatch_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_append_dispatch_gate RESULT_DIR=../perf/results/20260627-ooo-branch-append-dispatch-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-append-dispatch-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-append-dispatch-gate/full-module-testbench run`: PASS 75/75。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-015236-805280/`。
- `rg -n "return_cont_optional_w\\s*=|return_cont_attempt_ready_w\\s*=|return_cont_attempt_w\\s*=|branch_fallthrough_outstanding_match_w\\s*=|branch_target_append_candidate_w\\s*=|branch_fallthrough_append_safe_w\\s*=|branch_fallthrough_append_candidate_w\\s*=|branch_target_append_attempt_w\\s*=|branch_fallthrough_append_attempt_w\\s*=|synth_lane1_branch_append_w\\s*=|branch_target_append_w\\s*=|branch_fallthrough_append_w\\s*=|return_cont_dispatch_w\\s*=|branch_target_dispatch_w\\s*=|branch_fallthrough_dispatch_w\\s*=|branch_fallthrough_keep_outstanding_w\\s*=|branch_fallthrough_capture_rsp_w\\s*=|branch_prefetch_rsp_raw_match_w\\s*=|branch_prefetch_dispatch_buffer_w\\s*=|branch_prefetch_dispatch_rsp_w\\s*=|branch_prefetch_dispatch_attempt_w\\s*=|branch_prefetch_dispatch_fire_w\\s*=|branch_prefetch_hit_to_fifo_w\\s*=|dispatch1_optional_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooBranchAppendDispatchGate.v`: `OooAluFetchCore.v` 4009 行，`OooBranchAppendDispatchGate.v` 153 行。
- `git diff --check -- <branch append dispatch gate 切片相关文件>`: PASS。

## 第二十四切片 - Branch BPU Update Gate

### 需求

- 把 `OooAluFetchCore` 中 branch direction predictor 的 pending lookup capture、
  lookup sideband、direct/pending/drained/commit update class、actual/predicted
  taken 选择、update PC/BHT index 选择和 correctness 的纯组合事实抽成独立 helper。
- 新模块只负责 BPU lookup/update sideband 与 update mux；父模块继续负责 predictor
  table 实例、branch pending/spec/wait 状态、resolve/recovery sequencer、RAS/BTB
  update 和 PC/outstanding 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-bpu-update-gate.md`。
- Pending lane0 capture 要求前端未 flush、可运行、有 packet、lane0 branch，且没有
  direct lane0 branch dispatch。
- Pending lane1 capture 要求前端未 flush、可运行、有 packet、lane1 barrier fire，
  且 lane1 raw branch。
- Lookup event 是 direct branch fire 或任一 pending capture；lookup BHT valid 是触发
  事件所携带 BHT valid 的 OR。
- Direct update 直接镜像 direct branch resolve valid。
- Pending update 要求 stop-pending branch ownership、pending branch 已 dispatched，
  且 branch resolve pending-match。
- Drained update 要求 stop-pending branch ownership、drain complete 和未 dispatched
  pending branch。
- Commit update 镜像 pending branch commit-resolve。
- Pending-like update 聚合 pending/drained/commit，并选择 pending PC/BHT/prediction。
- Pending resolve actual-taken 只有在 resolve target 等于 pending target 且非
  misaligned 时为真；drained/commit 使用存储 pending taken；direct 使用 direct
  resolved taken。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchBpuUpdateGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 branch BPU pending capture、
  lookup sideband、update class、update taken/pred/correct/PC/BHT index 的内联组合
  表达式，改由 `u_branch_bpu_update_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_bpu_update_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_bpu_update_gate RESULT_DIR=../perf/results/20260627-ooo-branch-bpu-update-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-bpu-update-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-bpu-update-gate/full-module-testbench run`: PASS 76/76。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-020401-822717/`。
- `rg -n "branch_bpu_pending0_capture_w\\s*=|branch_bpu_pending1_capture_w\\s*=|branch_bpu_lookup_event_w\\s*=|branch_bpu_lookup_bht_valid_w\\s*=|branch_bpu_direct_update_w\\s*=|branch_bpu_pending_update_w\\s*=|branch_bpu_drained_update_w\\s*=|branch_bpu_commit_update_w\\s*=|branch_bpu_update_valid_w\\s*=|branch_bpu_pending_like_update_w\\s*=|branch_bpu_update_taken_w\\s*=|branch_bpu_update_pred_taken_w\\s*=|branch_bpu_update_correct_w\\s*=|branch_bpu_update_pc_w\\s*=|branch_bpu_update_bht_idx_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooBranchBpuUpdateGate.v`: `OooAluFetchCore.v` 4026 行，`OooBranchBpuUpdateGate.v` 98 行。
- `git diff --check -- <branch BPU update gate 切片相关文件>`: PASS。

## 第二十五切片 - Branch Target Cache Control Gate

### 需求

- 把 `OooAluFetchCore` 中 branch target cache/capture buffer 上游的 store
  fire/address、commit `MISC-MEM` 全失效、direct branch redirect 后 capture
  arm 和 branch PC 选择的纯组合事实抽成独立 helper。
- 新模块只负责 branch target cache control predicates；父模块继续负责 branch
  target cache/capture buffer 实例、direct branch resolve、dispatch/FIFO 和
  PC/outstanding 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-target-cache-control-gate.md`。
- Store fire 使用父模块已完成握手后的 `valid && ready && write` 事实，lane0/lane1
  取 OR。
- Store address 保持旧语义：lane0 store fire 优先，否则透传 lane1 address；当
  store fire 为 0 时 address 为 don't-care。
- `invalidate_all` 只由 commit0/commit1 valid 且 opcode 为 `OPCODE_MISC_MEM`
  置位，保持旧 `fence/fence.i` 粗粒度失效策略。
- Capture arm 要求 direct frontend flush、direct branch redirect、resolved taken、
  非 lane1-return capture，且 branch target dispatch 未消费该目标。
- Capture arm branch PC 只由 `direct_branch1_fire` 在 head PC0/head PC1 间选择。
- 新模块无内部状态机，是纯 Mealy 组合网络。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchTargetCacheControlGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 branch target store/
  invalidate/capture arm 的内联组合表达式，改由
  `u_branch_target_cache_control_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_target_cache_control_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_target_cache_control_gate RESULT_DIR=../perf/results/20260627-ooo-branch-target-cache-control-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-target-cache-control-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-target-cache-control-gate/full-module-testbench run`: PASS 77/77。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-021514-840370/`。
- `rg -n "branch_target_store_fire_w\\s*=|branch_target_store_addr_w\\s*=|branch_target_cache_invalidate_all_w\\s*=|branch_target_capture_arm_w\\s*=|branch_target_capture_arm_branch_pc_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooBranchTargetCacheControlGate.v`: `OooAluFetchCore.v` 4043 行，`OooBranchTargetCacheControlGate.v` 61 行。
- `git diff --check -- <branch target cache control gate 切片相关文件>`: PASS。

## 第二十六切片 - Direct RAS Candidate Gate

### 需求

- 把 `OooAluFetchCore` 中 lane0/lane1 JAL call-like raw、RAS direct update safe、
  lane0 direct return 和 lane1 return candidate 的纯组合事实抽成独立 helper。
- 新模块只负责 direct RAS/RAS-ret candidate predicates；父模块继续负责 RAS 栈、
  return-cont buffer、direct jump/ret fire、PC redirect 和 dispatch/FIFO 时序所有权。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-direct-ras-candidate-gate.md`。
- Call-like JAL 只看 JAL raw 和 `rd in {x1,x5}`，不受 RAS safe 影响。
- RAS direct update safe 要求 ROB 为空、没有 stop-pending、没有 branch-spec active，
  且没有 branch-spec checkpoint pending。
- Direct return candidate 仅在 `ENABLE_DIRECT_RAS_RET` 为真时允许。
- lane0 return 要求 dispatch0 jump、RAS safe、RAS reliable、RAS 非空、`rd=x0`、
  `rs1 in {x1,x5}`、`imm=0`。
- lane1 return candidate 要求 lane1 raw JALR、RAS safe、RAS reliable、RAS 非空、
  `rd=x0`、`rs1 in {x1,x5}`、`imm=0`。
- 新模块无内部状态机，是纯 Mealy 组合网络。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooDirectRasCandidateGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 direct RAS candidate 的内联
  组合表达式，改由 `u_direct_ras_candidate_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_direct_ras_candidate_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_direct_ras_candidate_gate RESULT_DIR=../perf/results/20260627-ooo-direct-ras-candidate-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-direct-ras-candidate-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-direct-ras-candidate-gate/full-module-testbench run`: PASS 78/78。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-022308-857075/`。
- `rg -n "head0_jal_call_raw_w\\s*=|head1_jal_call_raw_w\\s*=|ras_direct_update_safe_w\\s*=|dispatch0_return_w\\s*=|head1_return_candidate_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooDirectRasCandidateGate.v`: `OooAluFetchCore.v` 4048 行，`OooDirectRasCandidateGate.v` 65 行。
- `rg -n "[ \\t]+$" <direct RAS candidate gate 切片相关文件>`: no matches。
- `git diff --check -- <direct RAS candidate gate 已跟踪切片相关文件>`: PASS。

## 第二十七切片 - RAS Update Gate

### 需求

- 把 `OooAluFetchCore` 中 RAS 栈上游 clear/pop/push/push-value 的纯组合更新控制抽成独立 helper。
- 新模块只负责 RAS update control predicates；父模块和 `OooRasStack` 继续负责 RAS 状态、可靠性、栈顶和同周期 clear/pop/push 的时序优先级。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-ras-update-gate.md`。
- `ras_clear` 是 predictor boundary、branch-spec restore、untracked recovery 和 unsafe direct JAL call 的 OR。
- `ras_pop` 覆盖 direct ret0、direct ret1、pending lane1 ret、pending jump return 和 direct branch lane1-ret capture。
- `ras_push` 是 direct JAL call 和 pending jump call 的 OR。
- `ras_push_value` 在 pending jump call fire 时选择 pending jump next PC，否则选择 direct JAL link；`ras_push=0` 时 value 为 don't-care。
- 新模块无内部状态机，是纯 Mealy 组合网络；同周期 clear/pop/push 仲裁仍由 `OooRasStack` 负责。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooRasUpdateGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除 RAS update 的内联组合表达式，改由 `u_ras_update_gate` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_ras_update_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_ras_update_gate RESULT_DIR=../perf/results/20260627-ooo-ras-update-gate/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-ras-update-gate/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-ras-update-gate/full-module-testbench run`: PASS 79/79。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-022947-873479/`。
- `rg -n "ras_clear_w\\s*=|ras_pop_w\\s*=|ras_push_w\\s*=|ras_push_value_w\\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooRasUpdateGate.v`: `OooAluFetchCore.v` 4060 行，`OooRasUpdateGate.v` 43 行。
- `rg -n "[ \\t]+$" <RAS update gate 切片相关文件>`: no matches。
- `git diff --check -- <RAS update gate 已跟踪切片相关文件>`: PASS。

## 第二十八切片 - Branch Spec Tracker

### 需求

- 把 `OooAluFetchCore` 中 branch-spec checkpoint 的
  `active/checkpoint_pending/pred_pc` 注册状态抽成独立状态 owner。
- 新模块只负责 branch-spec checkpoint 状态；父模块继续负责 checkpoint/resolve
  事件生成、pending branch payload、PC/outstanding/discard、FIFO seed/clear、
  BPU/RAS update、trap/CSR recovery 和后端 issue 阻塞决策。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-branch-spec-tracker.md`。
- 新模块是单时钟同步状态机，无 ready/valid 握手；`rst || flush_i` 清空所有状态。
- 状态机为 `IDLE -> CHECKPOINT_PENDING -> SPEC_ACTIVE -> IDLE`。
- Direct branch spec start 只在 direct flush 周期、branch fire、未直接 redirect 且
  `direct_branch_spec_start` 有效时创建 checkpoint pending 并保存 predicted PC。
- `checkpoint_capture` 在没有 same-cycle direct flush 时把 pending 提升为 active，并保留
  predicted PC 供 restore 比较。
- `resolve_valid`、`pending_branch_commit_resolve`、`pending_branch_match_clear`、
  `branch_resolve_untracked` 和 CSR/trap clear 清空状态；CSR/trap clear 最高优先级。
- 不变量：`active` 与 `checkpoint_pending` 不同时为 1；pred PC 只在 pending/active
  生命周期内保留；direct flush 抑制同拍 capture/resolve；新模块不写 PC/FIFO/RAS/BPU/CSR/commit 状态。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooBranchSpecTracker.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把 `branch_spec_active_q`、
  `branch_spec_checkpoint_pending_q`、`branch_spec_pred_pc_q` 从父模块 reg 改为
  `u_branch_spec_tracker` 输出 wire；删除父模块 always 块中的全部 branch-spec 状态赋值。
- 新增 `pending_branch_match_clear_w` 命名谓词，供 prefetch/FIFO seed 和状态 tracker
  共用，避免重复长条件。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_branch_spec_tracker.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_branch_spec_tracker RESULT_DIR=../perf/results/20260627-ooo-branch-spec-tracker/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-ooo-branch-spec-tracker/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-branch-spec-tracker/full-module-testbench run`: PASS 80/80。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-024643-892850/`。
- `rg -n "branch_spec_(active_q|checkpoint_pending_q|pred_pc_q)\\s*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooBranchSpecTracker.v`: `OooAluFetchCore.v` 4040 行，`OooBranchSpecTracker.v` 79 行。
- `rg -n "[ \\t]+$" <Branch Spec Tracker 切片相关文件>`: no matches。
- `git diff --check -- <Branch Spec Tracker 已跟踪切片相关文件>`: PASS。

## 第二十九切片 - Fetch PC Outstanding Sequencer

### 需求

- 把 `OooAluFetchCore` 中 `next_fetch_pc_q`、`outstanding_valid_q`、
  `outstanding_pc_q` 和 `discard_fetch_rsp_q` 的注册状态抽成独立时序 owner。
- 新模块只负责前端取指 PC、单 outstanding credit 和 stale response discard 状态；
  父模块继续负责 fetch request mux、FIFO storage、branch/pending/trap 事件生成、
  CSR/trap side effect、BPU/RAS/BTB 表项和 commit/pending payload 状态。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-fetch-pc-outstanding-sequencer.md`。
- 新模块是单时钟同步状态 owner，无 ready/valid 输出握手；`rst || flush_i`
  把 `next_fetch_pc` 置为 `reset_pc_i` 并清空 outstanding/discard。
- 状态机为 `IDLE`、`WAIT_RSP`、`DROP_STALE`；`WAIT_RSP` 与 `DROP_STALE`
  可重叠，用于“新请求已采用、旧响应仍需丢弃”的 redirect 场景。
- 同拍覆盖顺序保持父模块原 nonblocking 语义：
  normal fetch progress -> direct frontend flush -> branch-spec restore ->
  pending branch commit/match -> untracked branch recovery -> pending jump ->
  pending system CSR commit -> drained pending owner -> late CSR trap。
- 不变量：任意周期最多一个 fetch outstanding credit；`outstanding_pc` 只在
  outstanding valid 时有意义；misaligned control transfer 不采用新 request；
  CSR trap late priority 覆盖所有低优先级 PC/outstanding/discard 更新。
- 新模块不写 FIFO、pending payload、CSR/trap 寄存器、BPU/RAS/BTB 或 commit 输出。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把
  `next_fetch_pc_q/outstanding_valid_q/outstanding_pc_q/discard_fetch_rsp_q`
  从父模块 reg 改为 `u_fetch_pc_outstanding` 输出 wire；删除父模块 always 块中的
  全部四类状态赋值。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_fetch_pc_outstanding_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_fetch_pc_outstanding_sequencer RESULT_DIR=../perf/results/20260627-fetch-pc-outstanding-sequencer/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-fetch-pc-outstanding-sequencer/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-fetch-pc-outstanding-sequencer/full-module-testbench run`: PASS 81/81。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-030427-912678/`。
- `rg -n "next_fetch_pc_q\\s*<=|outstanding_valid_q\\s*<=|outstanding_pc_q\\s*<=|discard_fetch_rsp_q\\s*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooFetchPcOutstandingSequencer.v npc/rv64/testbench/tests/tb_ooo_fetch_pc_outstanding_sequencer.sv`: `OooAluFetchCore.v` 3961 行，`OooFetchPcOutstandingSequencer.v` 294 行，testbench 434 行。
- `rg -n "[ \\t]+$" <Fetch PC Outstanding Sequencer 切片相关文件>`: no matches。
- `git diff --check`: PASS。

## 第三十切片 - Control Commit Sequencer

### 需求

- 把 `OooAluFetchCore` 中 `ctrl_commit_valid/payload/rd/write` 与
  `core_serial_flush` 的注册状态抽成独立 writeback/control 时序 owner。
- 新模块只负责控制类伪提交打一拍和 FP GPR serial flush 脉冲；父模块继续负责
  pending owner 捕获/清理、CSR/trap side effect、FPR 写入、ROB commit mux 和
  PC/outstanding 时序。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-control-commit-sequencer.md`。
- 新模块是单时钟同步状态 owner，无 ready/valid 输出握手；`rst || flush_i`
  清空全部输出状态。
- 状态机为 `IDLE`、`PULSE_COMMIT`、`PULSE_FLUSH`；FP GPR commit 可同时处于
  `PULSE_COMMIT` 和 `PULSE_FLUSH`。
- `pending_jump_nolink_commit` 生成 no-link JAL/JALR 控制提交；drained MRET/SRET、
  非 trap system control、未派发 branch fallback 和 drained FP 生成伪提交。
- ECALL、IRQ、pending arch trap、misaligned pending branch、pending jump 和 pending
  memory 不产生 `ctrl_commit_valid`，仍由 CSR/trap/redirect 路径拥有。
- 不变量：`ctrl_commit_valid` 和 `core_serial_flush` 都是单周期脉冲；FP GPR 写 x0
  仍可退休但 `ctrl_commit_write=0`；新模块不写 CSR、trap、FPR、ROB、FIFO、
  BPU/RAS/BTB 或 fetch PC 状态。

### RTL

- 新增 `npc/rv64/vsrc/writeback/OooControlCommitSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把 `ctrl_commit_*` 和
  `core_serial_flush_q` 从父模块 reg 改为 `u_control_commit_sequencer` 输出 wire；
  删除父模块 always 块中的全部相关赋值。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_control_commit_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_control_commit_sequencer RESULT_DIR=../perf/results/20260627-control-commit-sequencer/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-control-commit-sequencer/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-control-commit-sequencer/full-module-testbench run`: PASS 82/82。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-032108-933272/`。
- `rg -n "ctrl_commit_.*<=|core_serial_flush_q\\s*<=|reg ctrl_commit|reg core_serial_flush" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/writeback/OooControlCommitSequencer.v npc/rv64/testbench/tests/tb_ooo_control_commit_sequencer.sv`: `OooAluFetchCore.v` 3961 行，`OooControlCommitSequencer.v` 142 行，testbench 344 行。
- `rg -n "[ \\t]+$" <Control Commit Sequencer 切片相关文件>`: no matches。
- `git diff --check`: PASS。

## 第三十一切片 - Control Flush Sequencer

### 需求

- 把 `OooAluFetchCore` 中 `core_trap_flush`、`trap_redirect_squash` 和
  `checkpoint_mem_flush` 三个全局 flush 注册状态抽成独立 control 时序 owner。
- 新模块只负责 precise trap flush 脉冲、privileged/predictor boundary sticky squash
  和 checkpoint restore memory flush 脉冲；父模块继续负责 CSR/trap side effect、
  pending owner 清理、branch checkpoint 事件、fetch PC/outstanding、memory request
  arbitration 和 commit mux。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-control-flush-sequencer.md`。
- 新模块是单时钟同步状态 owner，无 ready/valid 输出握手；父模块用
  `rst || flush_i` 清空全部输出状态。
- 状态机为 `IDLE`、`PULSE_TRAP_FLUSH`、`PULSE_CHECKPOINT_MEM_FLUSH` 和
  `SQUASH_HELD`；两类 pulse 可与 sticky squash 重叠。
- `trap_flush_req_i` 当前由 `csr_trap_mem_valid_w` 驱动，打一拍生成
  `core_trap_flush`；`checkpoint_restore_i` 打一拍生成 `checkpoint_mem_flush`。
- `trap_redirect_squash` 在 `priv_predictor_boundary` 时置位，在 backend drained 且
  没有新 boundary 时清零；同拍 boundary 与 drained 同时为 1 时 boundary set 优先。
- 不变量：trap flush 和 checkpoint mem flush 都是注册脉冲；trap redirect squash
  在 backend 未 drain 前不能清零；新模块不写 FIFO、RAS、BPU、BTB、CSR、ROB、
  register-file、memory payload 或 fetch PC 状态。

### RTL

- 新增 `npc/rv64/vsrc/control/OooControlFlushSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把
  `core_trap_flush_q/trap_redirect_squash_q/checkpoint_mem_flush_q` 从父模块 reg 改为
  `u_control_flush_sequencer` 输出 wire；删除父模块 always 块中的全部相关赋值。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_control_flush_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_control_flush_sequencer RESULT_DIR=../perf/results/20260627-control-flush-sequencer/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-control-flush-sequencer/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-control-flush-sequencer/full-module-testbench run`: PASS 83/83。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-033432-951944/`。
- `rg -n "core_trap_flush_q\\s*<=|trap_redirect_squash_q\\s*<=|checkpoint_mem_flush_q\\s*<=|reg core_trap_flush|reg trap_redirect|reg checkpoint_mem" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooControlFlushSequencer.v npc/rv64/testbench/tests/tb_ooo_control_flush_sequencer.sv npc/rv64/design/specs/ooo-control-flush-sequencer.md`: `OooAluFetchCore.v` 3962 行，`OooControlFlushSequencer.v` 37 行，testbench 154 行，spec 72 行。
- `rg -n "[ \\t]+$" <Control Flush Sequencer 切片相关文件>`: no matches。
- `git diff --check`: PASS。

## 第三十二切片 - Synthetic Lane1 Return Sequencer

### 需求

- 把 `OooAluFetchCore` 中 `synth_lane1_ret_*` 与
  `synth_lane1_branch_drop_*` 注册状态抽成独立 writeback sequencer。
- 新模块只负责 lane1 return synthetic retire payload、branch-seen marker 和
  branch-drop pending/PC 状态；父模块继续负责 pending owner 捕获/清理、
  `pending_lane1_ret`、branch/RAS/BTB 判定、CSR/trap side effect、commit0/commit1
  mux、retire count 和 backend-drain policy。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-synthetic-lane1-ret-sequencer.md`。
- 新模块是单时钟同步状态 owner，无 ready/valid 输出握手；父模块用
  `rst || flush_i` 清空全部输出状态。
- 状态机为 `IDLE`、`RET_PENDING`、`RET_PENDING_BRANCH_SEEN` 和
  `BRANCH_DROP_PENDING`；drop 状态可与 return pending 并存。
- 同拍优先级保持旧父模块非阻塞赋值顺序：ret commit clear、branch drop match
  clear、branch commit1 seen、capture overwrite，最后 satp/trap clear。
- 不变量：capture 只在 direct branch0 lane1 return flush 事件上发生；branch drop
  match 只清 drop 状态，不清 return payload；satp/trap clear 清空所有 synthetic
  lane1 状态；新模块不写 FIFO、RAS、BPU、BTB、CSR、ROB、register-file、retire
  count、fetch PC/outstanding 或 pending owner 状态。

### RTL

- 新增 `npc/rv64/vsrc/writeback/OooSyntheticLane1RetSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把
  `synth_lane1_ret_pending_q/synth_lane1_ret_branch_seen_q/
  synth_lane1_ret_branch_pc_q/synth_lane1_ret_pc_q/synth_lane1_ret_next_pc_q/
  synth_lane1_ret_inst_q/synth_lane1_branch_drop_pending_q/
  synth_lane1_branch_drop_pc_q` 从父模块 reg 改为
  `u_synthetic_lane1_ret_sequencer` 输出 wire；删除父模块 always 块中的全部相关赋值。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_synthetic_lane1_ret_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS=tb_ooo_synthetic_lane1_ret_sequencer RESULT_DIR=../perf/results/20260627-synthetic-lane1-ret-sequencer/unit run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS=tb_ooo_alu_fetch_core RESULT_DIR=../perf/results/20260627-synthetic-lane1-ret-sequencer/fetch-core run`: PASS 1/1。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-synthetic-lane1-ret-sequencer/full-module-testbench run`: PASS 84/84。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-034740-971227/`。
- `rg -n "synth_lane1_ret_.*<=|synth_lane1_branch_drop_.*<=|reg synth_lane1" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/writeback/OooSyntheticLane1RetSequencer.v npc/rv64/testbench/tests/tb_ooo_synthetic_lane1_ret_sequencer.sv npc/rv64/design/specs/ooo-synthetic-lane1-ret-sequencer.md`: `OooAluFetchCore.v` 3935 行，`OooSyntheticLane1RetSequencer.v` 95 行，testbench 240 行，spec 83 行。
- `rg -n "[ \\t]+$" <Synthetic Lane1 Return Sequencer 切片相关文件>`: no matches。
- `git diff --check`: PASS。

## 第三十三切片 - Pending Lane1 Return Dead-State Cleanup

### 需求

- 删除 `OooAluFetchCore` 中旧 `pending_lane1_ret_*` dispatch replay 状态。
- 该路径当前没有任何置位/捕获生产者；lane1 return 延迟可见性已经由
  `OooSyntheticLane1RetSequencer` 承接，direct lane1 return 的 RAS pop 仍走 direct
  event。
- 同步删除 `OooRasUpdateGate` 的旧 pending lane1-ret pop 输入，避免保留一个永远
  接 0 的迷惑性接口。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-lane1-ret-dead-cleanup.md`。
- 旧状态机只有可达 `IDLE`：reset 为 0，当前 RTL 无生产者进入 pending。
- 清理后不再存在 pending lane1-ret valid/ready 或 dispatch replay 协议。
- `OooRasUpdateGate` 的 pop 来源只保留真实事件：direct ret0、direct ret1、
  pending jump return 和 direct branch0 lane1 return。
- 不变量：`npc/rv64/vsrc` 和 `npc/rv64/testbench/tests` 中不应再出现
  `pending_lane1_ret` 标识；synthetic lane1 return commit 仍是唯一的 lane1 return
  delayed retire 状态 owner。

### RTL

- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除
  `pending_lane1_ret_q/pc/next_pc/inst` 四个寄存器、reset/clear 赋值、
  `pending_lane1_ret_fire` 清理块、dispatch valid block 和 dispatch0 payload mux
  的不可达分支。
- 更新 `npc/rv64/vsrc/frontend/OooRasUpdateGate.v`：删除
  `pending_lane1_ret_fire_i` 端口及 pop OR 输入。
- 更新 `npc/rv64/testbench/tests/tb_ooo_alu_fetch_core.sv` 和
  `tb_ooo_ras_update_gate.sv`，移除旧内部 wire/端口引用。
- 更新 `npc/rv64/design/specs/ooo-synthetic-lane1-ret-sequencer.md`、
  `npc/rv64/design/specs/ooo-ras-update-gate.md` 和 `npc/rv64/vsrc/README.md`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_ras_update_gate tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-pending-lane1-ret-cleanup/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-pending-lane1-ret-cleanup/full-module-testbench run`: PASS 84/84。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64mi,rv64uf,rv64ud`: PASS，108 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-040113-989706/`。
- `rg -n "pending_lane1_ret" -g "*.v" -g "*.sv" npc/rv64/vsrc npc/rv64/testbench/tests`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooRasUpdateGate.v npc/rv64/testbench/tests/tb_ooo_ras_update_gate.sv npc/rv64/design/specs/ooo-pending-lane1-ret-dead-cleanup.md`: `OooAluFetchCore.v` 3902 行，`OooRasUpdateGate.v` 41 行，testbench 140 行，spec 77 行。
- `rg -n "[ \\t]+$" <Pending Lane1 Return Dead-State Cleanup 切片相关文件>`: no matches。
- `git diff --check`: PASS。

## 第三十四验证门 - Broad ISA/Privileged Regression Sweep

### 需求

- 在第三十三切片后，不继续扩大 RTL 改动面，先补强更接近 sign-off 的功能回归证据。
- 覆盖默认整数/M/C/bitmanip suites、FP single/double suites，以及 machine/supervisor privileged suites。
- 本验证门只声明 official riscv-tests 层面的 ISA/privileged sweep 通过，不声明 Linux/full-system、formal、PPA 或物理签核完成。

### 覆盖范围

- suites: `rv64ui`、`rv64um`、`rv64uc`、`rv64uzba`、`rv64uzbb`、`rv64uzbc`、`rv64uzbs`、`rv64uf`、`rv64ud`、`rv64mi`、`rv64si`。
- test-only PASS 统计：158 项。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、`rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、`rv64ud` 12、`rv64mi` 17、`rv64si` 7。

### 验证

- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS。
- 证据目录：`npc/rv64/perf/results/core-regress/20260627-040934-1005598/`。
- `status.txt` 汇总：`PASS 317`、`INFO 1`；其中 PASS 包含 build item、`riscv-clean` 和 test item。
- test-only `rv64*-p-*` 项：158/158 PASS；non-pass 行为空。
- `summary.txt` 末尾确认 `rv64si-p-csr/dirty/icache-alias/ma_fetch/sbreak/scall/wfi` 全部 PASS，`overall_rc=0`。

## 第三十五切片 - Memory Request Gate

### 需求

- 把 `OooAluFetchCore` 中 data-memory 外部请求边界的纯组合 mux/gate 抽到
  `memory/OooMemoryRequestGate.v`。
- 新模块只负责 pending FP memory request valid/fire/rsp-fire、pending FP 与 core
  lane0 memory request 优先级 mux、core lane1 memory request 直通、`mem_flush`
  与 `mmu_flush` 输出。
- 父模块继续持有 pending FP memory pending/done 状态、FPR load 写入、core LSU
  状态、CSR/trap/flush/checkpoint 状态和 precise recovery 仲裁。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-memory-request-gate.md`。
- 本模块无内部状态机、无寄存器，是纯组合 Mealy 网络。
- pending FP memory request 仅在 `stop_pending && pending_fp && backend_drained`
  且没有已发请求、没有已完成 memory 操作时有效。
- pending FP request 优先于 core lane0 request；lane1 request 不受 pending FP
  request 影响。
- pending FP memory pending 时 `mem_rsp_ready` 强制为 1，否则直通 core lane0
  response ready。
- `mem_flush == core_local_flush || checkpoint_mem_flush`；
  `mmu_flush == satp_write_commit || sfence_commit`。

### RTL

- 新增 `npc/rv64/vsrc/memory/OooMemoryRequestGate.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除父模块内联
  `pending_fp_mem_req_valid/fire/rsp_fire` 组合表达式、`mem_req*`/`mem1_req*`
  输出 assign、`mem_flush_o` 和 `mmu_flush_o` assign，改由 `u_memory_request_gate`
  输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_memory_request_gate.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_memory_request_gate tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-memory-request-gate/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-memory-request-gate/full-module-testbench run`: PASS 85/85。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-042108-1030309/`。
- `Select-String ... 'assign mem_req_valid_o|assign mem_req_write_o|assign mem_req_addr_o|assign mem_req_wdata_o|assign mem_req_wstrb_o|assign mem_rsp_ready_o|assign mem1_req_valid_o|assign mem_flush_o|assign mmu_flush_o|wire pending_fp_mem_req_valid_w ='`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/memory/OooMemoryRequestGate.v npc/rv64/testbench/tests/tb_ooo_memory_request_gate.sv npc/rv64/design/specs/ooo-memory-request-gate.md`: `OooAluFetchCore.v` 3926 行，`OooMemoryRequestGate.v` 95 行，testbench 263 行，spec 61 行。
- `rg -n "[ \t]+$" <Memory Request Gate 切片相关文件>`: no matches。
- `git diff --check -- <Memory Request Gate 切片相关文件>`: PASS。

## 第三十六切片 - Commit Output Mux

### 需求

- 把 `OooAluFetchCore` 中 writeback/commit 对外可见端口的纯组合 mux 抽到
  `writeback/OooCommitOutputMux.v`。
- 新模块只负责 control pseudo-commit、synthetic lane1 return/branch append、
  ROB commit0/commit1 到 `commit0/commit1` 与 `retire_count` 的输出选择。
- 父模块继续持有 ROB/CSR/trap side effect、synthetic ret 状态、pending owner
  捕获/清理和 precise recovery 仲裁。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-commit-output-mux.md`。
- 本模块无内部状态机、无寄存器，是纯组合 mux。
- `commit0` 优先级保持旧实现：control pseudo-commit > synthetic lane1 ret
  before/drop > core commit0。
- `commit1` 优先级保持旧实现：control commit 抑制 lane1 > synthetic branch
  append > synthetic lane1 ret after > core0 shift > branch-drop core1 > core1。
- core commit JAL 的 architectural next-PC 仍由 mux 内部按 J immediate 修正。
- `retire_count_o` 保持旧两位表达式：
  `core_retire + ctrl_commit + synth_branch_append + synth_ret_commit -
  synth_ret_drop_branch`。

### RTL

- 新增 `npc/rv64/vsrc/writeback/OooCommitOutputMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除父模块内联
  `rv32_imm_j`、`assign commit0_*`、`assign commit1_*` 和
  `assign retire_count_o`，改由 `u_commit_output_mux` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_commit_output_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_commit_output_mux tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-commit-output-mux/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-commit-output-mux/full-module-testbench run`: PASS 86/86。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-043339-1054578/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `rg -n "rv32_imm_j|assign commit0_|assign commit1_|assign retire_count_o" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/writeback/OooCommitOutputMux.v npc/rv64/testbench/tests/tb_ooo_commit_output_mux.sv npc/rv64/design/specs/ooo-commit-output-mux.md`: `OooAluFetchCore.v` 3857 行，`OooCommitOutputMux.v` 206 行，testbench 388 行，spec 49 行。
- `rg -n "[ \t]+$" <Commit Output Mux 切片相关文件>`: no matches。
- `git diff --check -- <Commit Output Mux 切片相关文件>`: PASS。

## 第三十七切片 - Frontend Backend Dispatch Mux

### 需求

- 把 `OooAluFetchCore` 中 front-end/pending 控制源到
  `OooAluCoreSlice` 双 dispatch 端口的纯组合选择抽到
  `frontend/OooFrontendBackendDispatchMux.v`。
- 新模块只负责 branch prefetch buffer/response、pending system/jump/mem、
  direct RET next-PC override、normal fetch packet、return-cont、branch
  target/fallthrough append 到 dispatch0/dispatch1 valid/payload/fire 的组合
  mux。
- 父模块继续持有 pending owner 捕获/清理、CSR/trap side effect、backend
  allocation、branch/RAS/BTB/FIFO/PC/outstanding 时序和 precise recovery 仲裁。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-frontend-backend-dispatch-mux.md`。
- 本模块无内部状态机、无寄存器，是纯组合 mux。
- dispatch0 优先级保持旧实现：branch prefetch buffer > branch prefetch
  response > pending system > pending jump > pending mem > direct RET0
  next-PC override > fetch head0。
- dispatch1 优先级保持旧实现：branch prefetch buffer > branch prefetch
  response > return-cont > branch target append > direct RET1 next-PC override
  > fetch head1。
- branch fallthrough append 只拉高 dispatch1 valid，payload 仍沿用 fetch head1。
- `core_dispatch0_fire` 仍只由 `core_dispatch0_valid && dispatch0_ready` 产生；
  pending jump/mem fire 仍分别要求对应 pending valid、未被更高优先级阻塞且
  dispatch0 ready。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除父模块内联
  `core_dispatch0_valid_w/core_dispatch1_valid_w/core_dispatch0_fire_w`、
  dispatch0/dispatch1 payload mux、`jump_dispatch_fire_w`、
  `mem_dispatch_fire_w` 和 `core_dispatch0_csr_rdata_w` 组合表达式，改由
  `u_frontend_backend_dispatch_mux` 输出。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_frontend_backend_dispatch_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_frontend_backend_dispatch_mux tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-frontend-backend-dispatch-mux/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-frontend-backend-dispatch-mux/full-module-testbench run`: PASS 87/87。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-044512-1078572/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-044512-1078572/status.txt`: no matches。
- `rg -n "core_dispatch0_valid_w =|core_dispatch1_valid_w =|core_dispatch0_fire_w =|core_dispatch0_pc_w =|core_dispatch1_pc_w =|jump_dispatch_fire_w =|mem_dispatch_fire_w =|core_dispatch0_csr_rdata_w =" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooFrontendBackendDispatchMux.v npc/rv64/testbench/tests/tb_ooo_frontend_backend_dispatch_mux.sv npc/rv64/design/specs/ooo-frontend-backend-dispatch-mux.md`: `OooAluFetchCore.v` 3870 行，`OooFrontendBackendDispatchMux.v` 158 行，testbench 369 行，spec 66 行。
- `rg -n "[ \t]+$" <Frontend Backend Dispatch Mux 切片相关文件>`: no matches。
- `git diff --check -- <Frontend Backend Dispatch Mux 切片相关文件>`: PASS。

## 第三十八切片 - Pending System Sequencer

### 需求

- 把 `OooAluFetchCore` 中 pending SYSTEM/CSR/IRQ 的 registered owner 抽到
  `control/OooPendingSystemSequencer.v`。
- 新模块只负责 `pending_system_*` valid/dispatched/type/payload/irq-cause
  状态保持；不执行 CSR side effect，不决定 trap/return target，不仲裁 backend drain
  或 fetch redirect。
- 父模块继续持有 CSR side effect、trap/return target 选择、pending owner
  arbitration、backend drain、fetch redirect、PC/outstanding/FIFO 和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-system-sequencer.md`。
- 状态抽象为 `IDLE/HELD/DISPATCHED`：capture 进入 `HELD`，dispatch fire
  进入 `DISPATCHED`，clear 或 clear-dispatched 返回 `IDLE`。
- 同拍优先级保持旧父模块语义：reset > clear > IRQ capture > lane0 system
  capture > lane1 system capture > dispatch fire > clear-dispatched。
- clear 只清 valid/dispatched/type bits，不重写 payload；reset 清所有 state/payload。
- IRQ capture 固定 `inst=0`、`next_pc=pc`、`csr_rdata=0`，并保存 IRQ cause。

### RTL

- 新增 `npc/rv64/vsrc/control/OooPendingSystemSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把 `pending_system_*_q`
  从父模块寄存器改为 sequencer 输出 wire，抽出 capture/clear 事件谓词，删除父模块
  内联 `pending_system_* <=` 状态赋值。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_pending_system_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-pending-system-sequencer/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-pending-system-sequencer/full-module-testbench run`: PASS 88/88。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-050546-1104880/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-050546-1104880/status.txt`: no matches。
- `rg -n "pending_system[^\n]*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooPendingSystemSequencer.v npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv npc/rv64/design/specs/ooo-pending-system-sequencer.md`: `OooAluFetchCore.v` 3759 行，`OooPendingSystemSequencer.v` 153 行，testbench 296 行，spec 53 行。
- `rg -n "[ \t]+$" <Pending System Sequencer 切片相关文件>`: no matches。
- `git diff --check -- <Pending System Sequencer 切片相关文件>`: PASS。

## 第三十九切片 - Pending Memory Sequencer

### 需求

- 把 `OooAluFetchCore` 中 lane1 memory barrier 的 pending memory 单 entry
  registered owner 抽到 `memory/OooPendingMemorySequencer.v`。
- 新模块只负责 `pending_mem_valid/dispatched/pc/inst/next_pc` 状态保持；不执行
  LSU/MMU request，不产生 memory trap，不决定 fetch redirect。
- 父模块继续持有 pending owner arbitration、LSU/MMU request、memory trap、
  backend drain、fetch redirect 和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-memory-sequencer.md`。
- 状态抽象为 `IDLE/HELD/DISPATCHED`：lane1 memory capture 进入 `HELD`，
  dispatch fire 进入 `DISPATCHED`，clear 返回 `IDLE`。
- 优先级保持旧父模块语义：`rst > late_clear > capture_lane1 > clear >
  dispatch_fire > clear_dispatched`。
- `late_clear` 覆盖 capture，用于 CSR trap precise boundary；普通 clear 清
  valid/dispatched/next_pc，但不重写 pc/inst。
- `capture_lane1` 可带 `capture_valid=0` 更新 payload 并保持 invalid，对齐旧
  lane1 barrier 分支无条件写 memory payload 的行为。

### RTL

- 新增 `npc/rv64/vsrc/memory/OooPendingMemorySequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把 `pending_mem_*_q`
  从父模块寄存器改为 sequencer 输出 wire，抽出 lane1 capture、capture clear、
  normal clear、late clear 和 dispatch fire 事件；删除父模块内联
  `pending_mem_* <=` 状态赋值。
- 保留 `pending_mem_resolve_ready` 空分支，以维持旧优先级对后续
  system/drain cases 的阻断；dispatched bit 已由 sequencer 接收
  `mem_dispatch_fire_w` 打拍。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_memory_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_pending_memory_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-pending-memory-sequencer/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-pending-memory-sequencer/full-module-testbench run`: PASS 89/89。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-051941-1129604/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-051941-1129604/status.txt`: no matches。
- `rg -n "pending_mem[^\n]*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/memory/OooPendingMemorySequencer.v npc/rv64/testbench/tests/tb_ooo_pending_memory_sequencer.sv npc/rv64/design/specs/ooo-pending-memory-sequencer.md`: `OooAluFetchCore.v` 3718 行，`OooPendingMemorySequencer.v` 65 行，testbench 198 行，spec 66 行。
- `rg -n "[ \t]+$" <Pending Memory Sequencer 切片相关文件>`: no matches。
- `git diff --check -- <Pending Memory Sequencer 切片相关文件>`: PASS。

## 第四十切片 - Pending Jump Sequencer

### 需求

- 把 `OooAluFetchCore` 中 JAL/JALR pending jump 的单 entry 注册状态抽成独立
  front-end helper。
- 新模块只持有 `valid/dispatched/jalr/pc/next_pc/inst/rs1/imm/target`；
  父模块继续负责 target 计算、RAS/BTB、misaligned trap、backend drain、
  fetch redirect 和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-jump-sequencer.md`。
- `capture_head0_i` 采样 lane0 JAL/JALR pending payload 并强制 valid。
- `capture_lane1_i` 采样 lane1 barrier payload；`capture_lane1_valid_i` 决定是否为
  jump entry。
- `dispatch_fire_i` 只设置 dispatched 并记录 resolved target，不改变
  `jalr/pc/next_pc/inst/rs1/imm`。
- 普通 `clear_i` 清 `valid/dispatched/next_pc`，保留 payload；`late_clear_i`
  高于 capture，用于 CSR trap precise boundary。
- 实现优先级为 `rst > late_clear > capture_head0 > capture_lane1 > clear >
  dispatch_fire > clear_dispatched`。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooPendingJumpSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：`pending_jump_*_q` 改由 sequencer
  输出 wire 驱动；父模块只保留 capture/clear/dispatch 事件、target/RAS/BTB/trap
  逻辑。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_jump_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_pending_jump_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-pending-jump-sequencer/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-pending-jump-sequencer/full-module-testbench run`: PASS 90/90。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-053402-1154250/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-053402-1154250/status.txt`: no matches。
- `rg -n "pending_jump[^\n]*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooPendingJumpSequencer.v npc/rv64/testbench/tests/tb_ooo_pending_jump_sequencer.sv npc/rv64/design/specs/ooo-pending-jump-sequencer.md`: `OooAluFetchCore.v` 3708 行，`OooPendingJumpSequencer.v` 108 行，testbench 305 行，spec 81 行。

## 第四十一切片 - Pending Branch Sequencer

### 需求

- 把 `OooAluFetchCore` 中 pending branch 单 entry 注册状态抽成独立 front-end helper。
- 新模块只持有 `valid/dispatched/pc/next_pc/inst/rs1/rs2/imm/cmp_op/
  pred_taken/bht_valid/bht_idx`；父模块继续负责 branch compare、target 计算、
  BPU update、branch-spec recovery、misaligned trap、backend drain、fetch redirect
  和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-branch-sequencer.md`。
- `capture_direct_i` 采样 direct branch payload，并令
  `valid/dispatched = capture_direct_valid_i`，保留 redirect direct branch 写 payload
  但不建立 pending entry 的旧行为。
- `capture_head0_i` 用于 lane0 branch fast-dispatch 不可用的 precise drain fallback。
- `capture_lane1_i` 用于 lane1 barrier，`capture_lane1_valid_i` 决定是否为 branch
  entry。
- 普通 `clear_i` 清 `valid/dispatched/next_pc` 并保留其余 payload；
  `clear_dispatched_i` 只清 dispatched；`late_clear_i` 高于 capture。
- 实现优先级为 `rst > late_clear > capture_direct > capture_head0 >
  capture_lane1 > clear > clear_dispatched`。

### RTL

- 新增 `npc/rv64/vsrc/frontend/OooPendingBranchSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：`pending_branch_*_q` 改由
  sequencer 输出 wire 驱动；父模块只保留 capture/clear 事件、compare/BPU/recovery
  逻辑。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_branch_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_pending_branch_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-pending-branch-sequencer/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-pending-branch-sequencer/full-module-testbench run`: PASS 91/91。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-054924-1179014/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-054924-1179014/status.txt`: no matches。
- `rg -n "pending_branch[^\n]*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/frontend/OooPendingBranchSequencer.v npc/rv64/testbench/tests/tb_ooo_pending_branch_sequencer.sv npc/rv64/design/specs/ooo-pending-branch-sequencer.md`: `OooAluFetchCore.v` 3695 行，`OooPendingBranchSequencer.v` 155 行，testbench 378 行，spec 77 行。

## 第四十二切片 - Pending FP Sequencer

### 需求

- 把 `OooAluFetchCore` 中 pending FP 单 entry 的 registered owner 抽到
  `execute/OooPendingFpSequencer.v`。
- 新模块持有 `pending_fp_*` valid、memory pending/done、long-op pending/done/result/
  fflags、compute done/result/fflags、load/store/double/gpr-write、pc/inst/next-pc、
  memory request payload 和 rd。
- 父模块继续负责 FPR 文件、FP load response 写 FPR、FP arithmetic commit 写 FPR、
  fflags commit、GPR serial write、pending owner arbitration、backend drain、fetch
  redirect 和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-fp-sequencer.md`。
- 状态抽象为 `IDLE/HELD/MEM_WAIT/LONG_WAIT`，其中 compute result 是 held entry
  的打一拍完成标志。
- 可观察优先级复制旧父模块非阻塞赋值顺序：
  `late_clear > capture_head0 > capture_lane1 > clear > progress events`。
- `capture_head0` 总是创建 valid FP entry；`capture_lane1` 只在
  `capture_lane1_valid` 为 1 时创建 entry，但仍更新 payload。
- `mem_req_fire` 只置 pending 并锁存 request payload，`mem_rsp_fire` 才置
  mem done；long start 清旧 result/fflags，long done 锁存 result/fflags。
- 普通 clear 不重写 payload；CSR trap late clear 覆盖 capture/progress，只清
  valid/progress/next_pc，避免 stale user FP entry 越过 privilege boundary。

### RTL

- 新增 `npc/rv64/vsrc/execute/OooPendingFpSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把 `pending_fp_*_q` 从父模块
  寄存器改为 sequencer 输出 wire，抽出 head0 capture、lane1 capture、drain-complete
  clear、CSR trap late clear 和 progress event 输入。
- 父模块旧 `pending_fp_*_q <=` 状态赋值已删除；保留两处 FPR 写入：
  FP load response 写 FPR 与 FP arithmetic commit 写 FPR。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_fp_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_pending_fp_sequencer" RESULT_DIR=../perf/results/20260627-pending-fp-sequencer/standalone run`: PASS 1/1。
- `make -C npc/rv64/testbench TESTS="tb_ooo_pending_fp_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-pending-fp-sequencer/focused run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-pending-fp-sequencer/full-module-testbench run`: PASS 92/92。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-060547-1204187/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-060547-1204187/status.txt`: no matches。
- `rg -n "pending_fp_[a-z0-9_]+_q[[:space:]]*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/execute/OooPendingFpSequencer.v npc/rv64/testbench/tests/tb_ooo_pending_fp_sequencer.sv npc/rv64/design/specs/ooo-pending-fp-sequencer.md`: `OooAluFetchCore.v` 3649 行，`OooPendingFpSequencer.v` 206 行，testbench 380 行，spec 97 行。

## 第四十三切片 - Pending Trap/Exit Sequencer

### 需求

- 把 `OooAluFetchCore` 中 pending architectural trap 与 simulation exit 的 registered owner 抽到
  `control/OooPendingTrapExitSequencer.v`。
- 新模块持有 `pending_exit_q/pending_exit_is_ecall_q/pending_exit_is_ebreak_q`、
  `pending_arch_trap_q/pending_trap_cause_q/pending_trap_pc_q/pending_trap_tval_q`。
- 父模块继续负责 `stop_pending_q`、backend drain complete、CSR trap entry mux/
  side effect、final `trap_valid/exit_valid/halted` 输出、fetch redirect 和 precise
  recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-pending-trap-exit-sequencer.md`。
- 状态抽象为两个独立 valid：`pending_exit` 与 `pending_arch_trap`，payload 只在
  valid 时由父模块消费。
- 普通 `clear_exit_i/clear_arch_i` 清 valid；`capture_exit_i/capture_arch_i`
  写 valid 与 payload；同周期 clear+capture 时 capture 生效。
- `late_clear_i` 最高优先级，清 valid 与 payload，用于 committed backend trap
  privilege boundary。
- 若 exit 与 arch trap 同时 valid，父模块的 drain policy 保持 architectural trap
  优先于 simulation exit。

### RTL

- 新增 `npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：把 pending trap/exit 状态寄存器
  改为 sequencer 输出 wire；父模块保留 lane0 fetch fault、lane0 decode trap、
  lane0 exit、lane1 barrier、unsupported、resolve/drain clear 和 late clear 事件生成。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_pending_trap_exit_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench run TESTS="tb_ooo_pending_trap_exit_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-062248-pending-trap-exit-focused/module-testbench`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench run RESULT_DIR=../perf/results/20260627-062356-pending-trap-exit-full/module-testbench`: PASS 93/93。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-062542-1246095/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `grep -E 'FAIL|TIMEOUT|ERROR' npc/rv64/perf/results/core-regress/20260627-062542-1246095/status.txt`: no matches。
- `rg -n "pending_exit_q <=|pending_exit_is_ecall_q <=|pending_exit_is_ebreak_q <=|pending_arch_trap_q <=|pending_trap_cause_q <=|pending_trap_pc_q <=|pending_trap_tval_q <=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v npc/rv64/testbench/tests/tb_ooo_pending_trap_exit_sequencer.sv npc/rv64/design/specs/ooo-pending-trap-exit-sequencer.md`: `OooAluFetchCore.v` 3710 行，`OooPendingTrapExitSequencer.v` 76 行，testbench 188 行，spec 59 行。

## 第四十四切片 - Trap/Exit Output Sequencer

### 需求

- 把 `OooAluFetchCore` 中最终用户可见的 trap/exit/halt sticky 输出寄存器抽到
  `control/OooTrapExitOutputSequencer.v`。
- 新模块持有 `trap_valid/trap_cause/trap_pc/trap_tval`、
  `exit_valid/exit_is_ecall/exit_is_ebreak` 和 `halted`。
- 父模块继续负责 `stop_pending`、backend drain/resolve 到达判定、terminal event
  mux、CSR trap mux/side effect、exit-code 选择、fetch redirect 和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-trap-exit-output-sequencer.md`。
- 状态是 reset 清零、非 reset sticky 的 terminal 输出寄存器。
- `trap_i` 捕获 trap payload 并置 `halted`；`exit_i` 捕获 exit payload 并置
  `halted`。
- trap 与 exit 捕获独立；若父模块同拍同时给出，两个 valid 位确定性并存。
- 父模块 terminal event mux 保持旧 always 块赋值到达/覆盖顺序：pending branch
  commit、tracked branch match、untracked branch、pending jump、drain branch、
  drain generic trap、branch-spec restore。
- drain terminal event 只在旧 `else if` 链真实到达 drain 分支时产生，避免被更早的
  branch/jump/memory/system resolve 分支截住时提前输出。

### RTL

- 新增 `npc/rv64/vsrc/control/OooTrapExitOutputSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：最终输出寄存器改为 sequencer
  输出 wire，父模块新增 terminal event mux，并删除旧 final output `<=` 赋值点。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/vsrc/control/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_trap_exit_output_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_trap_exit_output_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-trap-exit-output-focused/module-testbench run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-trap-exit-output-full/module-testbench run`: PASS 94/94。
- `make -C npc/rv64 core-regress`: PASS，含 module-testbench、lint、build、AM cpu-tests 与基础 official 111 项，证据 `npc/rv64/perf/results/core-regress/20260627-064145-1273648/`。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-064451-1333640/`。
- 分 suite：`rv64ui` 54、`rv64um` 13、`rv64uc` 1、`rv64uzba` 8、
  `rv64uzbb` 24、`rv64uzbc` 3、`rv64uzbs` 8、`rv64uf` 11、
  `rv64ud` 12、`rv64mi` 17、`rv64si` 7。
- `rg -n "FAIL|TIMEOUT|ERROR" npc/rv64/perf/results/core-regress/20260627-064451-1333640/status.txt`: no matches。
- `rg -n "(trap_valid_q|trap_cause_q|trap_pc_q|trap_tval_q|exit_valid_q|exit_is_ecall_q|exit_is_ebreak_q|halted_q)\s*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `rg -n "[ \t]+$" ...本轮新增/修改文件...`: no matches。
- scoped `git diff --check -- ...本轮已跟踪路径...`: no whitespace errors；Windows Git 仅输出 CRLF warning。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooTrapExitOutputSequencer.v npc/rv64/testbench/tests/tb_ooo_trap_exit_output_sequencer.sv npc/rv64/design/specs/ooo-trap-exit-output-sequencer.md`: `OooAluFetchCore.v` 3752 行，`OooTrapExitOutputSequencer.v` 54 行，testbench 162 行，spec 53 行。

## 第四十五切片 - Trap/Exit Event Mux

### 需求

- 把上一切片留在 `OooAluFetchCore` 中的 final trap/exit terminal event 纯组合 mux
  抽到 `control/OooTrapExitEventMux.v`。
- 新模块负责 branch-spec、pending branch、pending jump、drain branch、drain generic
  trap 和 drain exit 到 final event/payload 的选择。
- 父模块继续负责 `stop_pending` 状态、pending owner 状态、CSR trap side effect、
  exit-code 选择、fetch redirect 和 precise recovery。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-trap-exit-event-mux.md`。
- 纯组合，无内部状态。
- trap payload 优先级保持旧 always 块赋值到达/覆盖顺序：
  pending branch commit、tracked branch match、untracked branch、pending jump、
  drain branch、drain generic trap、branch-spec restore。
- drain terminal event 只在旧 `else if` 链真实到达 drain 分支时有效；若更早的
  branch/jump/memory/system resolve 分支为真，则 drain exit/trap 不输出。
- trap 与 exit event 独立，保留 branch-spec trap 与 later drain exit 同拍并存语义。

### RTL

- 新增 `npc/rv64/vsrc/control/OooTrapExitEventMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：删除内联
  `trap_exit_output_*` event mux 组合表达式，改为实例化 `u_trap_exit_event_mux`。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/vsrc/control/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_trap_exit_event_mux.sv`。

### 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_trap_exit_event_mux tb_ooo_trap_exit_output_sequencer tb_ooo_alu_fetch_core" RESULT_DIR=../perf/results/20260627-trap-exit-event-mux-focused/module-testbench run`: PASS 3/3。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-trap-exit-event-mux-full/module-testbench run`: PASS 95/95。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-065349-1357299/`。
- `rg -n "FAIL|TIMEOUT|ERROR" npc/rv64/perf/results/core-regress/20260627-065349-1357299/status.txt`: no matches。
- `rg -n "trap_exit_output_drain_reached|trap_exit_output_branch_spec|trap_exit_output_drain_exit|trap_exit_output_drain_trap|trap_exit_output_jump" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooTrapExitEventMux.v npc/rv64/testbench/tests/tb_ooo_trap_exit_event_mux.sv npc/rv64/design/specs/ooo-trap-exit-event-mux.md`: `OooAluFetchCore.v` 3729 行，`OooTrapExitEventMux.v` 133 行，testbench 246 行，spec 49 行。

## 第四十六切片 - CSR Trap Request Mux

### 需求

- 把 `OooAluFetchCore` 中 commit exception、pending architectural trap、pending
  ECALL/IRQ/xRET、SATP write/SFENCE boundary 到 `CsrFile` trap/return 请求线的
  纯组合选择抽到 `control/OooCsrTrapRequestMux.v`。
- 保留父模块原有 debug-observable wire 名称，避免破坏 `NpcSimTop` 层次路径统计和
  debug ports。
- 父模块继续负责 CSR 文件实例、CSR architectural side effect、pending owner、
  fetch redirect、flush/recovery、PC/outstanding/FIFO 和 final terminal output。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-csr-trap-request-mux.md`。
- 纯组合，无内部状态。
- Commit exception trap valid 为 lane0 exception OR lane1 exception；两 lane 同时
  exception 时 lane0 payload 优先。
- Pending architectural trap、pending ECALL、pending IRQ 和 xRET 都必须经过
  `stop_pending && drain_complete` 精确边界。
- Execute trap valid 为 pending architectural trap fire OR pending ECALL trap；
  二者同拍为真时 architectural trap payload 优先，保持旧 mux 语义。
- `mret_valid_o` 保留 generic xRET boundary；`real_mret_valid_o` 排除 SRET，
  `sret_valid_o` 由 `pending_system_inst[31:20] == SYSTEM_FUNCT12_SRET` 判定。
- `priv_predictor_boundary_o` 覆盖 CSR trap、xRET、SATP write commit 和 SFENCE
  commit。

### RTL

- 新增 `npc/rv64/vsrc/control/OooCsrTrapRequestMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：旧内联 CSR trap request
  组合赋值改为 `u_csr_trap_request_mux` 实例，保留
  `pending_system_ecall_trap_w`、`pending_arch_trap_fire_w`、`csr_trap_mem_*`、
  `csr_trap_ex_*`、`csr_trap_irq_valid_w`、`csr_mret_valid_w`、
  `csr_sret_valid_w`、`csr_real_mret_valid_w` 和 `priv_predictor_boundary_w`
  wire 名称。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/vsrc/control/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_csr_trap_request_mux.sv`。

### 验证

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-csr-trap-request-focused/module-testbench TESTS="tb_ooo_csr_trap_request_mux tb_ooo_alu_fetch_core" run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-csr-trap-request-full/module-testbench run`: PASS 96/96。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-070927-1384715/`。
- `rg -n "FAIL|TIMEOUT|ERROR" npc/rv64/perf/results/core-regress/20260627-070927-1384715/status.txt`: no matches。
- `tail -n 8 npc/rv64/perf/results/core-regress/20260627-070927-1384715/status.txt`: 末尾包含 `riscv-tests-count INFO 158 tests attempted`。
- `rg -n "pending_system_ecall_trap_w\s*=|pending_arch_trap_fire_w\s*=|csr_trap_ex_valid_w\s*=|csr_trap_irq_valid_w\s*=|csr_mret_valid_w\s*=|priv_predictor_boundary_w\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooCsrTrapRequestMux.v npc/rv64/testbench/tests/tb_ooo_csr_trap_request_mux.sv npc/rv64/design/specs/ooo-csr-trap-request-mux.md`: `OooAluFetchCore.v` 3633 行，`OooCsrTrapRequestMux.v` 87 行，testbench 271 行，spec 45 行。
- 已知 WSL 并发读异常在一次并行 status/summary 查询中复现
  `Wsl/Service/0x8007274c`；回归 status 已用 PowerShell/UNC 单命令复核，未影响
  test result。

## 第四十七切片 - CSR Access Request Mux

### 需求

- 把 `OooAluFetchCore` 中 commit0 CSR、pending SYSTEM CSR、lane1 CSR probe、
  head0 CSR 到 `CsrFile` access 端口的纯组合选择抽到
  `control/OooCsrAccessRequestMux.v`。
- 保留父模块原有 debug-observable wire 名称，尤其是
  `pending_system_csr_commit_w`，避免破坏 `NpcSimTop` 层次路径统计和 debug ports。
- 父模块继续负责 CSR 文件实例、CSR side effect、pending owner、trap/return
  request、fetch redirect、flush/recovery、PC/outstanding/FIFO 和 final terminal
  output。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-csr-access-request-mux.md`。
- 纯组合，无内部状态。
- CSR access inst 优先级保持旧父模块语义：commit0 CSR > pending SYSTEM CSR >
  lane1 CSR probe > head0 CSR。
- `core_commit0_csr` 必须满足 commit0 valid、非 exception、SYSTEM opcode 且
  `funct3 != 0`。
- `pending_system_csr_commit` 必须满足 pending valid/csr/dispatched、commit0 CSR 且
  pending PC 与 commit0 PC 匹配。
- lane1 CSR probe 只在 dispatch valid、lane0 不是 SYSTEM、lane1 barrier 且 head1
  CSR raw 时成立。
- CSRRS/CSRRC immediate 或 register source 为 0 时是 set/clear no-op，不触发
  `need_write`；SATP write commit 只在 pending SYSTEM CSR commit、CSR addr 为 SATP
  且 `need_write` 时成立。
- SFENCE commit 保持旧精确边界：`stop_pending && drain_complete` 后才允许输出。

### RTL

- 新增 `npc/rv64/vsrc/control/OooCsrAccessRequestMux.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：旧内联 CSR access request
  组合赋值改为 `u_csr_access_request_mux` 实例，保留
  `core_commit0_csr_w`、`pending_system_csr_commit_w`、`head1_csr_probe_w`、
  `csr_access_*`、`pending_system_satp_write_commit_w` 和
  `pending_system_sfence_commit_w` wire 名称。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/vsrc/control/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv`。

### 验证

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-csr-access-request-focused/module-testbench TESTS="tb_ooo_csr_access_request_mux tb_ooo_csr_trap_request_mux tb_ooo_alu_fetch_core" run`: PASS 3/3。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-csr-access-request-full/module-testbench run`: PASS 97/97。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-072038-1410358/`。
- `rg -n "FAIL|TIMEOUT|ERROR" npc/rv64/perf/results/core-regress/20260627-072038-1410358/status.txt`: no matches。
- `tail -n 20 npc/rv64/perf/results/core-regress/20260627-072038-1410358/status.txt`: 末尾包含 `riscv-tests-count INFO 158 tests attempted`。
- `rg -n "core_commit0_csr_w\s*=|pending_system_csr_commit_w\s*=|head1_csr_probe_w\s*=|csr_access_inst_w\s*=|csr_access_addr_w\s*=|csr_access_funct3_w\s*=|csr_access_rs1_idx_w\s*=|csr_access_rs1_data_w\s*=|csr_access_set_clear_noop_w\s*=|csr_access_need_write_w\s*=|csr_access_valid_w\s*=|pending_system_satp_write_commit_w\s*=|pending_system_sfence_commit_w\s*=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooCsrAccessRequestMux.v npc/rv64/testbench/tests/tb_ooo_csr_access_request_mux.sv npc/rv64/design/specs/ooo-csr-access-request-mux.md`: `OooAluFetchCore.v` 3643 行，`OooCsrAccessRequestMux.v` 78 行，testbench 224 行，spec 31 行。

## 第四十八切片 - Stop Pending Sequencer

### 需求

- 把 `OooAluFetchCore` 中 `stop_pending_q` 的注册状态 owner 抽到
  `control/OooStopPendingSequencer.v`。
- 新模块只负责 direct flush、branch-spec、orphan cleanup、pending
  branch/jump/memory/system resolve、pending CSR commit、drain completion、
  decode-side stop request 和 late CSR trap clear 对 `stop_pending` 的时序更新。
- 父模块继续负责 pending payload、fetch PC/outstanding、FIFO、CSR 文件/side
  effect、FPR 文件写回和 final terminal output。

### 协议/状态机/不变量

- 新增 `npc/rv64/design/specs/ooo-stop-pending-sequencer.md`。
- `stop_pending` 是单 bit 注册状态。
- reset/flush 清零；direct branch fire 且没有 redirect 时可置位。
- branch-spec checkpoint/resolve、orphan cleanup、branch resolve、pending CSR commit
  和 drain complete 清零。
- pending jump dispatch、pending memory resolve 和 SYSTEM CSR dispatch 是 hold-only
  priority slot，且不能覆盖同拍更早的独立 clear。
- decode-side stop request 只在 can-run 且 FIFO 有 packet 时置位。
- late CSR trap clear 最后覆盖同拍 decode-side capture。
- 父模块 pending FP arithmetic 写 FPR 条件显式为 `pending_fp_fpr_commit_w`，并保留
  旧 drain 分支中 arch trap/system/未派发 branch/jump/mem 优先于 FP commit 的顺序。

### RTL

- 新增 `npc/rv64/vsrc/control/OooStopPendingSequencer.v`。
- 更新 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`：`stop_pending_q` 由 reg 改为
  sequencer 输出 wire；父模块 always 块只保留 FPR reset、FP load 写回和 FP arithmetic
  commit 写回。
- 更新 `npc/rv64/vsrc/filelist.mk`、`npc/rv64/vsrc/README.md`、
  `npc/rv64/vsrc/control/README.md`、`npc/rv64/testbench/Makefile`。
- 新增 `npc/rv64/testbench/tests/tb_ooo_stop_pending_sequencer.sv`。

### 验证

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-stop-pending-focused-v2/module-testbench TESTS="tb_ooo_stop_pending_sequencer tb_ooo_alu_fetch_core" run`: PASS 2/2。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-stop-pending-full-v2/module-testbench run`: PASS 98/98。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui,rv64um,rv64uc,rv64uzba,rv64uzbb,rv64uzbc,rv64uzbs,rv64uf,rv64ud --riscv-privileged`: PASS，158 official tests，证据 `npc/rv64/perf/results/core-regress/20260627-073713-1458263/`。
- `rg -n "FAIL|TIMEOUT|ERROR" npc/rv64/perf/results/core-regress/20260627-073713-1458263/status.txt`: no matches。
- `tail -n 20 npc/rv64/perf/results/core-regress/20260627-073713-1458263/status.txt`: 末尾包含 `riscv-tests-count INFO 158 tests attempted`。
- `rg -n "stop_pending_q\s*<=" npc/rv64/vsrc/frontend/OooAluFetchCore.v`: no matches。
- `wc -l npc/rv64/vsrc/frontend/OooAluFetchCore.v npc/rv64/vsrc/control/OooStopPendingSequencer.v npc/rv64/testbench/tests/tb_ooo_stop_pending_sequencer.sv npc/rv64/design/specs/ooo-stop-pending-sequencer.md`: `OooAluFetchCore.v` 3577 行，`OooStopPendingSequencer.v` 121 行，testbench 288 行，spec 29 行。

## 第四十九切片 - ACT4 Final ELF I/M Gate

### 需求

- 在上一轮 `stop_pending` 拆分后，重新闭合比 module testbench 和 legacy
  `riscv-tests` 更接近 architecture-test 的 ACT4 final self-checking ELF gate。
- 测试资产继续放在 `npc/rv64/testsuites/core-tests/`，不写入 `.github`。
- 修复 ACT4 preflight `--workdir` 相对路径语义：相对路径必须按仓库根目录解析，
  不能因为 `make -C riscv-arch-test` 而生成到 ACT4 源码 checkout 内的嵌套路径。

### 协议/不变量

- `npc-rv64-act4-preflight.sh --final-elfs` 生成 `elfs/.../*.elf` final DUT
  ELF；`build/.../*.sig.elf` 仍只是参考 signature 中间 ELF，不能喂给 NPC。
- `npc-rv64-act4-run.sh` 逐项解析 `tohost`、`objcopy -O binary`，并用
  `NpcSimTop -b --no-diff --tohost=ADDR` 的 `TOHOST PASS/FAIL` 判定结果。
- `--workdir DIR` 支持绝对路径和相对仓库根目录路径，和 runner 的路径规约保持一致。
- 当前 gate 只声明 ACT4 `rv64i/I` 与 `rv64i/M` final ELF 通过；不代表完整 ACT4
  sweep、UDB 全覆盖、Linux/full-system 或工业 sign-off 完成。

### 实现

- 更新 `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh`：新增
  `abspath_from_root()`，`--workdir` 解析为绝对路径。
- 更新 `npc/rv64/README.md` 与 `npc/rv64/testsuites/README.md`：补充 ACT4 M
  final ELF 生成/执行命令、`--workdir` 相对仓库根目录语义和本轮 I/M evidence。
- 未改 RTL。

### 验证

- `bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh`: PASS。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --list-suites`: 修复前只列
  `rv64i/I`；相对 `--workdir` 生成 M 后列出 `rv64i/I,rv64i/M`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites rv64i/I --filter 'I-(add|addi|sub)-00' --limit 3 --timeout-sec 60 --max-cycles 20000000 --log-base npc/rv64/perf/results/20260627-act4-final-smoke`: PASS 3/3，证据 `npc/rv64/perf/results/20260627-act4-final-smoke/20260627-074507-1515040/`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites rv64i/I --timeout-sec 60 --max-cycles 20000000 --log-base npc/rv64/perf/results/20260627-act4-final-rv64i`: PASS 51/51，证据 `npc/rv64/perf/results/20260627-act4-final-rv64i/20260627-074515-1515239/`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions M --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script`: PASS，`Build complete: 65 succeeded`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites rv64i/M --timeout-sec 60 --max-cycles 20000000 --log-base npc/rv64/perf/results/20260627-act4-final-rv64m`: PASS 13/13，证据 `npc/rv64/perf/results/20260627-act4-final-rv64m/20260627-074811-1517820/`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions C --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script`: PASS 但 `Build complete:` 数量为空，`--list-suites` 未新增 C suite。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions A --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script`: PASS 但 `Build complete:` 数量为空，`--list-suites` 未新增 A suite。
- `find npc/rv64/testsuites/core-tests/src/riscv-arch-test/tests -maxdepth 3 -type d`: 当前本地 ACT4 checkout 的 unprivileged RV64 目录只有 `rv64i/I` 和 `rv64i/M`，另有 privileged 目录；C/A 未产出 suite 是测试资产覆盖缺口，不能解释为 RTL 执行失败。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites rv64i/I,rv64i/M --timeout-sec 60 --max-cycles 20000000 --log-base npc/rv64/perf/results/20260627-act4-final-rv64im`: PASS 64/64，证据 `npc/rv64/perf/results/20260627-act4-final-rv64im/20260627-075540-1520228/`。
- `Select-String -CaseSensitive -Pattern 'FAIL|TIMEOUT|ERROR'` 扫描 combined I/M `status.txt`: no matches，末尾 `attempted=64 pass=64 fail=0 skip=0`。
- `Select-String -CaseSensitive -Pattern 'FAIL|TIMEOUT|ERROR'` 扫描本轮 ACT4 I/M `status.txt`: no matches。
- `rg -n "[ \t]+$"` 扫描本轮 touched 文件：no matches。
- `git diff --check -- <本轮 tracked/touched files>`: PASS。

## 第五十切片 - ACT4 Privileged Sv Probe

### 需求

- 在 ACT4 I/M final ELF gate 之后，探测当前 ACT4 privileged `Sv` suite 是否能进入
  NPC runner，作为 supervisor/虚拟内存方向的更高层 sign-off 前沿。
- 区分三种状态：测试资产无法生成、final ELF 能运行且 PASS、长预算仍未闭合。

### 协议/不变量

- `priv/Sv` 使用同一 final ELF/tohost runner，不启用 diff，不引入 Linux/rootfs。
- 小规模 smoke 先限制 5 项，避免直接跑 485 项造成长时间不可控。
- timeout 只说明该 host/cycle 预算下未到 `TOHOST PASS`；若日志仍有 progress 且无
  `TOHOST FAIL`/BAD TRAP，需要记录为未闭合前沿，不能直接归因成 RTL 功能错误。

### 验证

- `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh --final-elfs --extensions Sv --workdir npc/rv64/testsuites/core-tests/act4-npc-final-work-script`: PASS，`Build complete: 485 succeeded`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --list-suites`: 新增 `priv/Sv`，当前列表 `priv/Sv,rv64i/I,rv64i/M`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites priv/Sv --limit 5 --timeout-sec 60 --max-cycles 50000000 --log-base npc/rv64/perf/results/20260627-act4-final-priv-sv-smoke`: attempted=5 pass=3 fail=2，证据 `npc/rv64/perf/results/20260627-act4-final-priv-sv-smoke/20260627-075821-1523834/`。
- 通过项：`sv39_VA_all_ones_Smode` PASS、`sv39_VA_all_zeros_Smode` PASS、`sv39_global_pte_Smode` PASS。
- timeout 项：`sv39_canonical_Smode` 与 `sv39_canonical_Umode` 在 60s host timeout 下未到 `TOHOST PASS`，日志有 progress 到 10M commits 左右，无 `TOHOST FAIL`。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh --suites priv/Sv --filter '^sv39_canonical_Smode$' --limit 1 --timeout-sec 300 --max-cycles 200000000 --log-base npc/rv64/perf/results/20260627-act4-final-priv-sv-canonical-smode`: attempted=1 pass=0 fail=1，host timeout，证据 `npc/rv64/perf/results/20260627-act4-final-priv-sv-canonical-smode/20260627-080043-1524561/`。
- `sv39_canonical_Smode` 300s 日志显示 progress 到 50M commits，PC 从 `0x80001a00`
  推进到 `0x80001a44`，没有 `TOHOST FAIL`、BAD TRAP 或异常；该项当前归类为
  “privileged ACT4 Sv canonical 长预算未闭合”，不是已定位 RTL root cause。
- `riscv-none-elf-nm -n .../sv39_canonical_Smode.elf` 与定点 `objdump
  --start-address=0x80001980 --stop-address=0x80001af0`：timeout PC 落在
  `sv_Svect` S-mode trap signature checker，`0x80001a44` 为 `ld s1,0(t1)`，
  随后比较构造出的 sstatus/signature 字段，不匹配会跳
  `failedtest_trap_x7_x9`。后续定位应围绕 `sv_Svect` 的 trap signature、
  `sstatus/scause/sepc/stval` 和 expected signature memory，而不是继续盲目加大
  host timeout。
- 本轮两次只读 `objdump` 期间复现已知 WSL read 异常 `0x8007274c` /
  `E_UNEXPECTED`；已用后续窄窗口重试拿到关键反汇编，不影响 ACT4 runner 结果。

## 第五十一切片 - ACT4 RVA22S64 Privileged Sv Closure

### 需求

- 把上一切片中 ACT4 privileged `Sv` 的 canonical timeout/partial fail 前沿收敛为可解释、可复跑的核级 gate。
- 避免把 `sail-rv64-max` 的 V/VS profile 期望误判为当前核 RTL 缺陷。
- 修复当前 `sail-RVA22S64` 下真正暴露的 Sv39 PTE 合法性、PBMT disabled CSR 探测和 `mstatus/sstatus` 可见位缺口。

### 协议/状态机/不变量/数据通路摘要

- ACT4 runner 协议：`--config-name` 选择 workdir 下的 `elfs` 配置目录，`--config-src` 可显式指定配置源；`--build-final` 时把配置透传给 preflight。runner 仍只执行 final self-checking ELF、objcopy 成 bin，并通过 `tohost` 判定 PASS/FAIL。
- PTE 合法性协议：ITLB/DTLB hit、TLB fill 和 page-walk fault 必须共用 `pte_reserved_fault()`；hard-reserved 位 fault 覆盖 bit63、PBMT[62:61] 和 [58:54]，当前 ACT4/Sail 期望允许 PTE[60:59] 软件位；non-leaf PTE 的 D/A/U 必须 fault。
- CSR 状态机：`menvcfg` 不新增寄存器状态，按 WARL-zero 读零/写 no-op；CSR commit 状态机仍是原单拍 write case。
- CSR 不变量：PBMTE/FIOM 等环境配置位在当前核中始终为 0；`mstatus.SD/sstatus.SD` 是读出派生位，不写入 `csr_mstatus_q`，当前未实现 VS/XS，因此只由 `FS==Dirty` 派生。
- 数据通路：`csr_mstatus_visible_w = csr_mstatus_q | SXL/UXL | SD_if_FS_dirty`，`csr_sstatus_visible_w = csr_mstatus_visible_w & SSTATUS_MASK`；PTE reserved fault 是纯组合 helper，接入 fault guard/fill valid/page-walk branch。

### 根因定位

- `sail-rv64-max` commitwatch 看到 canonical signature 差异落在 `sstatus.VS[10:9]`，该 profile 启用 V/VS 期望；当前核 `misa`/CSR 未实现 V/VS，不能作为默认 privileged Sv profile。
- `sail-RVA22S64 priv/Sv` 初跑为 attempted=33 pass=27 fail=6，失败项是 non-leaf PTE D/A/U、reserved PTE、Svnapot disabled、Svpbmt disabled 和 TVM。
- focused PTE 修复后 5 项中 3 PASS，剩余 `sv39_pte_reserved_field_Smode` 与 `sv39_svpbmt_disabled_Smode` 指向两个边界：ACT4/Sail 当前允许 PTE[60:59] 软件位；PBMT disabled 探测需要 `menvcfg` 可访问但读零。
- TVM 单项 commitwatch 显示失败发生在测试主体第一条 `mstatus` signature：expected `0x8000000a00107800`，actual `0x0000000a00107800`，差异是 SD bit63；根因是 `CsrFile` 未按 FS Dirty 派生 SD。

### RTL/脚本改动

- `npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh`: 新增 `CONFIG_NAME`、`--config-name`、`ACT4_CONFIG_SRC_DIR`、`--config-src` 和 probe config dir 参数，配置源可从 ACT4 `config/sail`、`config/cores/cvw`、`qemu`、`spike`、`imperas`、`whisper` 自动解析。
- `npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh`: 新增 `--config-name`、`--config-src`，按配置名选择 `ELF_ROOT`，`--build-final` 时把配置传给 preflight。
- `npc/rv64/vsrc/include/define.v`: 新增 `CSR_MENVCFG`、`MSTATUS_SD`，`SSTATUS_MASK` 纳入 SD，调整 `SV39_PTE_RESERVED_MASK`。
- `npc/rv64/vsrc/core/CsrFile.v`: `menvcfg` 加入 known/writable/read mux/write no-op；`mstatus/sstatus` 读口增加 SD 派生。
- `npc/rv64/vsrc/memory/OooMemAxiBridge.v` 与 `npc/rv64/vsrc/frontend/OooFetchAxiBridge.v`: 增加 `pte_reserved_fault()`，接入 TLB hit fault、TLB fill valid 和 walk fault。

### 验证

- `git diff --check -- <本轮 touched files>`: PASS。
- `bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-preflight.sh && bash -n npc/rv64/testsuites/scripts/npc-rv64-act4-run.sh`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- `make -C npc/rv64 lint`: PASS。
- focused module TB `tb_csr_file tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge tb_ooo_alu_fetch_core`: PASS 4/4，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-sv-fixes/module-focused/`。
- `sail-RVA20S64` canonical S/U 与 smoke：`sv39_canonical_Smode` PASS、`sv39_canonical_Umode` PASS、`priv/Sv --limit 5` PASS 5/5；但该 profile 全量包含 Sv48/Svnapot，超出当前 Sv39-only 边界。
- `sail-RVA22S64 priv/Sv --limit 5`: PASS 5/5，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-smoke5/20260627-082426-1535068/`。
- 修复前 `sail-RVA22S64 priv/Sv`: attempted=33 pass=27 fail=6，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-full/20260627-082459-1535860/`。
- focused PTE set after reserved/menvcfg fix: PASS 5/5，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-pte-reserved-fix2/20260627-084640-1550329/`。
- `sv_mstatus_tvm_test` after SD fix: PASS，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-tvm-sd-fix/20260627-085144-1553449/`。
- final `sail-RVA22S64 priv/Sv`: attempted=33 pass=33 fail=0 skip=0，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-full-after-sd/20260627-085153-1553580/`。
- official riscv-tests default+FP+A+privileged test-only sweep: PASS，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-sv-fixes/core-regress-official/20260627-085300-1554892/`。

### 边界

- 已闭合的是 `sail-RVA22S64 priv/Sv` 核级 Sv39 gate；`sail-rv64-max` 的 V/VS 期望仍不是当前核实现边界。
- 未闭合：ACT4 全配置/UDB 全覆盖、Linux/full-system、完整 precise ROB/retirement/formal/PPA/timing/CDC/reset/物理签核和完整工业 CPU sign-off。

## 第五十二切片 - ACT4 RVA22S64 Svpbmt / PBMTE Closure

### 目标

把上一切片闭合的 `sail-RVA22S64 priv/Sv` base Sv39 gate 继续扩展到 Svpbmt 边界，按 spec 区分 PBMTE disabled/enabled、leaf/non-leaf PTE.PBMT 和 reserved encoding。

### 四阶段推导

1. **Spec 边界**: `menvcfg.PBMTE` 是 Svpbmt 开关。PBMTE=0 时 PTE.PBMT[62:61] 对当前 base Sv39 测试仍是 hard-reserved；PBMTE=1 时 leaf PBMT=1/2 合法，leaf PBMT=3 为保留编码 page fault；non-leaf PBMT 非零仍 page fault。当前核不建模 cacheability/ordering 属性，只需要在功能层把合法 PBMT=1/2 当作普通 PMA 内存处理。
2. **现状审计**: `CsrFile` 上一切片把 `menvcfg` 做成 WARL-zero，`OooFetchAxiBridge`/`OooMemAxiBridge` 的 PTE reserved mask 始终包含 PBMT 位。`Svpbmt` leaf S/U 两项在 trap framework 中 host timeout，nonleaf 两项 PASS，符合“PBMTE 写不生效 + leaf PBMT 被错误 fault”的症状。
3. **实现决策**: `CsrFile` 只实现 `MENVCFG_PBMTE` bit62，其它 `menvcfg` 位继续 WARL-zero；新增窄接口 `svpbmt_en_o`，经 `OooAluFetchCore`/`NpcCoreTop` 传给 I/D page walker。walker 在 request 上捕获 PBMTE 上下文，TLB hit 权限复核用当前 PBMTE，fill/walk 用请求上下文 PBMTE。
4. **验证策略**: 用模块白盒锁定 PTE reserved policy，用 ACT4 `priv/Svpbmt` 定点复现/闭合原 timeout，再用 combined Sv 族和 official riscv-tests 做回归。

### RTL/测试改动

- `npc/rv64/vsrc/include/define.v`: 新增 `MENVCFG_PBMTE`、`SV39_PTE_RESERVED_MASK_SVPBMT` 和 PTE PBMT bit 索引宏。
- `npc/rv64/vsrc/core/CsrFile.v`: 增加 `csr_menvcfg_q`，读回和写入仅保留 PBMTE bit；导出 `svpbmt_en_o`。
- `npc/rv64/vsrc/frontend/OooAluFetchCore.v`、`npc/rv64/vsrc/core/NpcCoreTop.v`: 新增 `svpbmt_en` 透传。
- `npc/rv64/vsrc/frontend/OooFetchAxiBridge.v`、`npc/rv64/vsrc/memory/OooMemAxiBridge.v`: `pte_reserved_fault(pte, svpbmt_en)` 按 PBMTE 切换 reserved mask；PBMTE=1 时显式 fault leaf PBMT=3 和 non-leaf PBMT 非零。
- `npc/rv64/testbench/tests/tb_csr_file.sv`: 增加 PBMTE set/clear/readback/output smoke。
- `npc/rv64/testbench/tests/tb_ooo_fetch_axi_bridge.sv`、`npc/rv64/testbench/tests/tb_ooo_mem_axi_bridge.sv`: 增加 PBMT reserved policy 白盒检查。

### 验证

- `git diff --check -- <本轮 touched files>`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- focused module TB `tb_csr_file tb_ooo_fetch_axi_bridge tb_ooo_mem_axi_bridge tb_ooo_alu_fetch_core`: PASS 4/4，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-svpbmt/module-focused-after-whitebox/`。
- ACT4 `sail-RVA22S64 priv/Svpbmt`: PASS 4/4，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svpbmt-after-fix/20260627-091809-1584945/`。
- ACT4 combined `priv/ExceptionsSv,priv/Sv,priv/Svade,priv/Svbare,priv/Svpbmt`: PASS 46/46，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-combined-after-svpbmt/20260627-091842-1586160/`。
- `make -C npc/rv64 lint`: PASS。
- official riscv-tests default+FP+A+privileged sweep: PASS 177/177，证据 `npc/rv64/perf/results/20260627-act4-rva22s64-svpbmt/core-regress-official/20260627-091917-1587606/`。

### 边界

- `Svadu` 和 `Svnapot` 在当前 `sail-RVA22S64` profile 下未生成 final ELF，不能记为 RTL PASS/FAIL。
- PMP、Zicbo、Svinval、完整 ACT4/UDB、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核仍未完成。

## 第五十三切片 - ACT4 RVA22S64 Svinval / Supervisor Fence Privilege Closure

### 目标

把上一切片闭合到 Svpbmt 的 `sail-RVA22S64` privileged Sv 族继续扩展到
Svinval，按 spec 区分 supervisor fence 的序列化语义、U-mode illegal 语义和
`mstatus.TVM` 门控语义。

### 四阶段推导

1. **Spec 边界**: `sfence.vma` 与 `sinval.vma` 是地址转换 fence，在 S-mode 且
   `mstatus.TVM=1` 时必须 illegal；`sfence.w.inval` 与 `sfence.inval.ir`
   是 Svinval 的写缓冲/取指刷新 fence，在 S-mode+TVM 下仍 legal；四条
   supervisor fence 在 U-mode 下都必须 illegal；功能层当前不建模 cache/TLB
   真实刷新副作用，但必须作为 pending system 序列化点提交。
2. **现状审计**: `DecodeUnit` 只识别 `sfence.vma`，`sfence.w.inval`、
   `sinval.vma`、`sfence.inval.ir` 走 illegal/default；`OooAluFetchCore`
   只用 `CTRL_SFENCE_VMA_BIT` 同时表示序列化边界和 TVM 门控，且缺 U-mode
   supervisor fence illegal gate。
3. **RTL 改动**: 在 `define.v` 增加 Svinval funct7/rs2 编码和
   `CTRL_SFENCE_TVM_BIT`；`DecodeUnit` 精确译码四条 supervisor fence，
   继续用 `CTRL_SFENCE_VMA_BIT` 表示 pending system 序列化/flush 边界，
   仅 `sfence.vma/sinval.vma` 置 `CTRL_SFENCE_TVM_BIT`；`OooAluFetchCore`
   增加 U-mode supervisor fence illegal gate，并把 S-mode+TVM illegal 限定
   到 TVM bit。
4. **验证策略**: 用 `tb_decode_unit` 固化四条指令译码 contract，用
   `tb_ooo_priv_system` 覆盖前端 pending system/CSR/trap 长链，再用 ACT4
   `priv/Svinval` 定点复现/闭合，最后用 Sv 族 combined 与 official
   riscv-tests 防回归。

### Root Cause

- 修复前 ACT4 `priv/Svinval` 为 attempted=2 pass=0 fail=2，证据
  `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svinval/20260627-092959-1612918/`。
- `Svinval` 普通用例卡在 S-mode trap framework 且未写出 TOHOST PASS；
  `Svinval_mstatus_tvm` 直接 TOHOST FAIL。
- 根因不是 page walker，而是 SYSTEM decode/privilege 控制位粒度不足：缺少
  Svinval 编码识别，且一个 coarse `sfence` bit 无法同时承担序列化和 TVM
  illegal 条件。

### 改动

- `npc/rv64/vsrc/include/define.v`: 新增 `SYSTEM_FUNCT7_SINVAL_VMA`、
  `SYSTEM_FUNCT7_SFENCE_INVAL`、`SYSTEM_RS2_SFENCE_W_INVAL`、
  `SYSTEM_RS2_SFENCE_INVAL_IR` 和 `CTRL_SFENCE_TVM_BIT`，`CTRL_BUS_W`
  扩到 50。
- `npc/rv64/vsrc/decode/DecodeUnit.v`: 精确识别 `sfence.vma`、
  `sinval.vma`、`sfence.w.inval`、`sfence.inval.ir`；只让
  `sfence.vma/sinval.vma` 设置 TVM bit。
- `npc/rv64/vsrc/frontend/OooAluFetchCore.v`: 增加 U-mode supervisor fence
  illegal 判定；S-mode+TVM illegal 只对 `CTRL_SFENCE_TVM_BIT` 生效。
- `npc/rv64/testbench/tests/tb_decode_unit.sv`: 增加四条 Svinval/system fence
  译码 contract 和保留编码 illegal 检查。

### 验证

- focused `tb_decode_unit`: PASS，证据
  `npc/rv64/perf/results/20260627-act4-rva22s64-svinval/module-focused/logs/tb_decode_unit.log`。
- focused `tb_ooo_priv_system`: PASS，证据
  `npc/rv64/perf/results/20260627-act4-rva22s64-svinval/module-focused/logs/tb_ooo_priv_system.log`。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。
- ACT4 `sail-RVA22S64 priv/Svinval`: PASS 2/2，证据
  `npc/rv64/perf/results/20260627-act4-rva22s64-priv-svinval-after-fix/20260627-093545-1614756/`。
- ACT4 combined `priv/ExceptionsSv,priv/Sv,priv/Svade,priv/Svbare,priv/Svpbmt,priv/Svinval`:
  PASS 48/48，证据
  `npc/rv64/perf/results/20260627-act4-rva22s64-priv-sv-combined-after-svinval/20260627-093604-1614913/`。
- official riscv-tests default+FP+A+privileged sweep: PASS 177/177，证据
  `npc/rv64/perf/results/20260627-act4-rva22s64-svinval/core-regress-official/20260627-093617-1616308/`。

### 边界

- `Svadu` 和 `Svnapot` 在当前 `sail-RVA22S64` profile 下未生成 final ELF，不能记为 RTL PASS/FAIL。
- PMP、Zicbo、完整 ACT4/UDB、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核仍未完成。

## 收尾结论

- `OooAluFetchCore.v` 从 7631 行降到 3704 行；新增 `OooFpPendingExec.v` 3778 行，新增 `OooPendingFpSequencer.v` 206 行，新增 `OooStopPendingSequencer.v` 121 行，新增 `OooPendingTrapExitSequencer.v` 76 行，新增 `OooTrapExitOutputSequencer.v` 54 行，新增 `OooTrapExitEventMux.v` 133 行，新增 `OooCsrAccessRequestMux.v` 78 行，新增 `OooCsrTrapRequestMux.v` 87 行，新增 `OooMemoryRequestGate.v` 95 行，新增 `OooPendingMemorySequencer.v` 65 行，新增 `OooPendingBranchSequencer.v` 155 行，新增 `OooPendingJumpSequencer.v` 108 行，新增 `OooCommitOutputMux.v` 206 行，新增 `OooFrontendBackendDispatchMux.v` 158 行，新增 `OooPendingSystemSequencer.v` 153 行，新增 `OooDirectRasCandidateGate.v` 65 行，`OooRasUpdateGate.v` 当前 41 行，新增 `OooBranchSpecTracker.v` 79 行，新增 `OooFetchPcOutstandingSequencer.v` 294 行，新增 `OooControlCommitSequencer.v` 142 行，新增 `OooControlFlushSequencer.v` 37 行，新增 `OooSyntheticLane1RetSequencer.v` 95 行，新增 `OooFrontendUopSafety.v` 62 行，新增 `OooFrontendDispatchGate.v` 115 行，新增 `OooDirectBranchResolveGate.v` 113 行，新增 `OooBranchResolveRecoveryGate.v` 95 行，新增 `OooPendingControlResolveGate.v` 85 行，新增 `OooBranchAppendDispatchGate.v` 153 行，新增 `OooBranchBpuUpdateGate.v` 98 行，新增 `OooBranchTargetCacheControlGate.v` 61 行，新增 `OooFrontendRunGate.v` 75 行，新增 `OooFrontendActionGate.v` 82 行，新增 `OooFetchRequestMux.v` 81 行，新增 `OooBranchPrefetchSourceGate.v` 43 行，新增 `OooBranchPrefetchRequestGate.v` 53 行，新增 `OooBranchPrefetchStatusGate.v` 44 行，新增 `OooJalrPrefetchStatusGate.v` 45 行，新增 `OooBranchPrefetchBuffer.v` 102 行，新增 `OooDirectBranchWaitBuffer.v` 41 行，新增 `OooBackendDrainTracker.v` 24 行，新增 `OooFetchPacketHitMux.v` 50 行，新增 `OooFetchPacketHeadMux.v` 56 行，新增 `OooFetchPacketSeedMux.v` 195 行，新增 `OooFetchPacketDecode.v` 78 行，新增 `OooFetchPacketFifo.v` 153 行，新增 `OooFetchFlowControl.v` 75 行。
- 已闭合 FP pending execute datapath、pending FP sequencer、stop-pending sequencer、pending trap/exit sequencer、trap/exit output sequencer、trap/exit event mux、CSR access request mux、CSR trap request mux、memory request gate、pending memory sequencer、pending branch sequencer、pending jump sequencer、commit output mux、frontend/backend dispatch mux、pending system sequencer、direct RAS candidate gate、RAS update gate、branch spec tracker、fetch PC/outstanding sequencer、control commit sequencer、control flush sequencer、synthetic lane1 return sequencer、pending lane1 return dead-state cleanup、frontend uop safety policy、frontend dispatch gate、direct branch resolve gate、branch resolve recovery gate、pending control resolve gate、branch append dispatch gate、branch BPU update gate、branch target cache control gate、frontend run gate、frontend action gate、fetch request mux、branch prefetch source gate、branch prefetch request gate、branch prefetch status gate、JALR prefetch status gate、branch prefetch buffer、direct branch wait buffer、backend drain tracker、fetch packet hit mux、fetch packet head mux、fetch packet seed mux、fetch packet decode、fetch packet FIFO storage 和 fetch flow-control 四十八个工业化拆分/清理切片；第四十九切片闭合 ACT4 final ELF I/M gate 并修复 preflight workdir 路径规约。
- 第五切片为显式策略实例化，父模块行数相对第四切片略增；第六切片把 dispatch 入口纯组合 gate 从父模块抽离；第七切片把 branch prefetch 影子包状态从父模块抽离；第八切片把 direct branch wait 单 entry 状态从父模块抽离；第九切片把 backend drained 打拍状态从父模块抽离；第十切片把 dispatch-visible packet head source mux 从父模块抽离；第十一切片把 redirect/recovery 到 FIFO clear/seed 的组合 action encoder 从父模块抽离；第十二切片把 branch/JALR prefetch hit payload mux 从父模块抽离；第十三切片把 front-end run/stop/bypass/credit 组合判定从父模块抽离；第十四切片把 direct flush、stop-head、FIFO pop、control-stop 和 trap-blocked request 动作谓词从父模块抽离；第十五切片把 fetch request PC/source 组合选择从父模块抽离；第十六切片把 pending branch/JALR BTB prefetch request gate 从父模块抽离；第十七切片把 branch prefetch response capture/hit/pending status 判定从父模块抽离；第十八切片把 JALR branch-prefetch target/match/hit/pending status 判定从父模块抽离；第十九切片把 branch/JALR prefetch source facts 从父模块抽离；第二十切片把 direct branch lane select/BHT/predicted PC/resolve/redirect/lane1 return capture 组合事实从父模块抽离；第二十一切片把 pending/tracked/untracked/branch-spec resolve recovery 组合谓词从父模块抽离；第二十二切片把 pending branch/jump resolve、return/call/no-link 和 redirect-after-dispatch 组合事实从父模块抽离；第二十三切片把 branch append/branch prefetch direct-dispatch 组合门控从父模块抽离；第二十四切片把 branch direction predictor lookup/update sideband 与 update mux 从父模块抽离；第二十五切片把 branch target cache store/invalidate/capture control 从父模块抽离；第二十六切片把 direct RAS/RAS-ret candidate 组合事实从父模块抽离；第二十七切片把 RAS clear/pop/push/push-value 组合控制从父模块抽离，父模块继续保留真正的 pending/redirect/commit/outstanding/RAS 时序所有权。
- 第二十八切片把 branch-spec active/checkpoint-pending/pred-PC 注册状态从父模块抽离；父模块继续保留 checkpoint/resolve 事件生成、PC/outstanding/discard、pending payload、FIFO seed/clear、BPU/RAS update 和 precise recovery 仲裁。
- 第二十九切片把 fetch PC/outstanding/discard 注册状态从父模块抽离；父模块继续保留 fetch request mux、FIFO storage、branch/pending/trap 事件生成、CSR/trap side effect、BPU/RAS/BTB 表项和 commit/pending payload 状态。
- 第三十切片把控制类伪提交和 FP GPR serial flush 注册状态从父模块抽离到 `writeback/`；父模块继续保留 pending owner 捕获/清理、CSR/trap side effect、FPR 写入、ROB commit mux 和 PC/outstanding 时序。
- 第三十一切片把 `core_trap_flush`、`trap_redirect_squash` 和 `checkpoint_mem_flush` 注册状态从父模块抽离到 `control/`；父模块继续保留 CSR/trap side effect、pending owner 清理、branch checkpoint 事件、PC/outstanding、memory request arbitration 和 commit mux。
- 第三十二切片把 `synth_lane1_ret_*` 和 `synth_lane1_branch_drop_*` 注册状态从父模块抽离到 `writeback/`；父模块继续保留 pending owner 捕获/清理、`pending_lane1_ret`、branch/RAS/BTB 判定、CSR/trap side effect、commit0/commit1 mux、retire count 和 backend-drain policy。
- 第三十三切片删除无生产者的旧 `pending_lane1_ret_*` dispatch replay 状态和 RAS gate 旧输入；当前 RTL/TB 源文件中已无 `pending_lane1_ret` 标识。
- 第三十四验证门补跑 default+FP+privileged official riscv-tests sweep：`rv64ui/rv64um/rv64uc/rv64uzba/rv64uzbb/rv64uzbc/rv64uzbs/rv64uf/rv64ud/rv64mi/rv64si` 共 158 个 test-only 项 PASS，证据 `npc/rv64/perf/results/core-regress/20260627-040934-1005598/`。
- 第三十五切片把 pending FP memory request、core lane0/lane1 memory request、response ready、`mem_flush` 和 `mmu_flush` 组合边界抽离到 `memory/OooMemoryRequestGate.v`；父模块继续保留 pending FP memory 状态、core LSU 状态和 precise trap/flush 时序所有权。
- 第三十六切片把 control pseudo-commit、synthetic lane1 return/branch append、ROB commit0/commit1 到外部 commit/retire 端口的组合 mux 抽离到 `writeback/OooCommitOutputMux.v`；父模块继续保留 ROB/CSR/trap side effect、synthetic ret 状态和 pending owner 清理。
- 第三十七切片把 front-end/pending 控制源到 `OooAluCoreSlice` 双 dispatch 端口的 valid/payload/fire 组合选择抽离到 `frontend/OooFrontendBackendDispatchMux.v`；父模块继续保留 pending owner、CSR/trap side effect、backend allocation 和 precise recovery 时序所有权。
- 第三十八切片把 pending SYSTEM/CSR/IRQ 注册状态抽离到 `control/OooPendingSystemSequencer.v`；父模块继续保留 CSR side effect、trap/return target 选择、pending owner arbitration、backend drain、fetch redirect 和 precise recovery 仲裁。
- 第三十九切片把 lane1 memory barrier 的 pending memory 单 entry 注册状态抽离到 `memory/OooPendingMemorySequencer.v`；父模块继续保留 pending owner arbitration、LSU/MMU request、memory trap、backend drain、fetch redirect 和 precise recovery。
- 第四十切片把 JAL/JALR pending jump 单 entry 注册状态抽离到 `frontend/OooPendingJumpSequencer.v`；父模块继续保留 target 计算、RAS/BTB、misaligned trap、backend drain、fetch redirect 和 precise recovery。
- 第四十一切片把 pending branch 单 entry 注册状态抽离到 `frontend/OooPendingBranchSequencer.v`；父模块继续保留 branch compare、target 计算、BPU update、branch-spec recovery、misaligned trap、backend drain、fetch redirect 和 precise recovery。
- 第四十二切片把 pending FP 单 entry 注册状态抽离到 `execute/OooPendingFpSequencer.v`；父模块继续保留 FPR 文件、fflags commit、GPR serial write、pending owner arbitration、backend drain、fetch redirect 和 precise recovery。
- 第四十三切片把 pending architectural trap 与 simulation exit 注册状态抽离到 `control/OooPendingTrapExitSequencer.v`；父模块继续保留 `stop_pending`、CSR trap mux/side effect、terminal event 形成、fetch redirect 和 precise recovery。
- 第四十四切片把最终 `trap_valid/exit_valid/halted` sticky 输出寄存器抽离到 `control/OooTrapExitOutputSequencer.v`；父模块继续保留 `stop_pending`、backend drain/resolve 到达判定、terminal event mux、CSR trap mux/side effect、exit-code 选择、fetch redirect 和 precise recovery。
- 第四十五切片把 final trap/exit terminal event 纯组合 mux 抽离到 `control/OooTrapExitEventMux.v`；父模块继续保留 `stop_pending` 状态、pending owner 状态、CSR trap side effect、exit-code 选择、fetch redirect 和 precise recovery。
- 第四十六切片把 commit exception、pending architectural trap、pending ECALL/IRQ/xRET、SATP write/SFENCE boundary 到 `CsrFile` trap/return 请求线的纯组合选择抽离到 `control/OooCsrTrapRequestMux.v`；父模块继续保留 CSR 文件实例、CSR architectural side effect、pending owner、fetch redirect、flush/recovery 和 final terminal output。
- 第四十七切片把 commit0 CSR、pending SYSTEM CSR、lane1 CSR probe、head0 CSR 到 `CsrFile` access 端口的纯组合选择抽离到 `control/OooCsrAccessRequestMux.v`；父模块继续保留 CSR 文件实例、CSR side effect、pending owner、trap/return request、fetch redirect、flush/recovery 和 final terminal output。
- 第四十八切片把 `stop_pending` 注册状态抽离到 `control/OooStopPendingSequencer.v`；父模块继续保留 pending payload、fetch PC/outstanding、FIFO、CSR 文件/side effect、FPR 文件写回和 final terminal output。
- 第四十九切片重跑 ACT4 final self-checking ELF `rv64i/I` 和 `rv64i/M`，并修复 `npc-rv64-act4-preflight.sh --workdir` 相对路径误落到 ACT4 源码 checkout 的问题；当前 I suite 51/51 PASS，M suite 13/13 PASS，combined I/M 64/64 PASS。当前本地 ACT4 checkout 的 unprivileged RV64 final suite 只有 I/M，C/A 生成不产出 suite，属于测试资产覆盖缺口。
- 第五十切片生成 ACT4 privileged `priv/Sv` final ELF 485 项并完成 smoke：5 项中 3 PASS，`sv39_canonical_Smode/Umode` 在 60s timeout 下未闭合；`sv39_canonical_Smode` 放大到 300s / 200M cycles 仍 host timeout，但日志显示持续推进、无 TOHOST FAIL/BAD TRAP。
- 第五十一切片澄清 ACT4 profile 边界并闭合 `sail-RVA22S64 priv/Sv`：修复 ACT4 config-name/config-src、PTE reserved/non-leaf D/A/U、`menvcfg` WARL-zero 和 `mstatus/sstatus.SD` 派生，最终 `sail-RVA22S64 priv/Sv` 33/33 PASS，official default+FP+A+privileged riscv-tests test-only sweep PASS。
- 第五十二切片闭合 `sail-RVA22S64 priv/Svpbmt`：实现 `menvcfg.PBMTE` bit62、Svpbmt leaf/non-leaf PTE.PBMT reserved policy 和 I/D walker PBMTE 上下文，最终 `priv/Svpbmt` 4/4 PASS、当前已生成 Sv 族 combined 46/46 PASS、official default+FP+A+privileged riscv-tests 177/177 PASS。
- 第五十三切片闭合 `sail-RVA22S64 priv/Svinval`：实现 Svinval supervisor fence 精确 decode、独立 TVM 控制位和 U-mode fence illegal gate，最终 `priv/Svinval` 2/2 PASS、当前已生成 Sv 族 combined 48/48 PASS、official default+FP+A+privileged riscv-tests 177/177 PASS。
- 未闭合：ACT4 全配置/UDB 全覆盖、PMP/Zicbo、final CSR/trap/interrupt precise control、ROB/retirement/precise exception 更完整收敛、Linux/full-system、formal/PPA/timing/CDC/reset/物理签核。
