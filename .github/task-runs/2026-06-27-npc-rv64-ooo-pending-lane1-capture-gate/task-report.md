# 任务报告

## 基本信息

- task_id: `2026-06-27-npc-rv64-ooo-pending-lane1-capture-gate`
- 日期: `2026-06-27`
- 目标: 继续优化 `npc/rv64` OoO RTL 架构，把 pending dispatch lane1 barrier 的局部 owner 分型和 trap/exit payload 计算从全局 arbiter 中抽出。
- 范围: `OooPendingLane1CaptureGate`、`OooPendingDispatchArbiter`、filelist、module testbench、pending specs、README、memory。

## RTL 推导摘要

- 需求: lane1 barrier 的 branch/jump/memory/FP/SYSTEM typed capture 和 trap/exit payload 是局部 facts 计算，不应继续混在 `OooPendingDispatchArbiter` 的全局优先级表里。
- 协议规则: 上游先生成 `lane1_barrier_base`；新模块只消费 lane1 facts、fetch fault/resp、PC/inst 和 CSR illegal probe；父 arbiter 继续处理 IRQ、lane0、direct flush、resolve、clear 和 unsupported 优先级。
- 状态机: 无状态机，新模块为纯组合 helper。
- 不变量: typed capture 必须被 barrier base 门控；SYSTEM capture 必须排除 CSR illegal 和 architectural trap；trap-exit capture 保留空 barrier scrub stale valid bit；cause/tval 优先级保持 semihost、illegal、FP disabled、priv-system illegal、CSR illegal、fetch page/access fault 的旧顺序。
- 数据通路约束: facts bit alias 进入 typed capture AND gate；arch/exit valid 分离；cause/tval 单层 priority mux；位宽由 `define.v` 和 `OooSlotFacts.vh` 提供。

## 修改摘要

- 新增 `npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v`。
- `OooPendingDispatchArbiter.v` 实例化新 gate，删除 lane1 facts 本地 alias 和内联 trap/exit lane1 payload mux。
- `npc/rv64/vsrc/filelist.mk` 和 `npc/rv64/testbench/Makefile` 接入新 RTL 与新 TB。
- 新增 `tb_ooo_pending_lane1_capture_gate.sv`。
- 新增 `ooo-pending-lane1-capture-gate.md`，更新 pending dispatch arbiter/facts bus specs、`vsrc` README、`control` README。

## 验证证据

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-capture-gate/focused TESTS="tb_ooo_pending_lane1_capture_gate" run`: 1/1 PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-capture-gate/focused TESTS="tb_ooo_pending_lane1_capture_gate tb_ooo_pending_dispatch_arbiter tb_ooo_fetch_head_classify_gate tb_ooo_fetch_head_pair_gate tb_ooo_alu_fetch_core tb_decode_unit" run`: 6/6 PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-pending-lane1-capture-gate/all run`: 103/103 PASS。
- `git diff --check -- npc/rv64/vsrc/control/OooPendingLane1CaptureGate.v npc/rv64/vsrc/control/OooPendingDispatchArbiter.v npc/rv64/vsrc/filelist.mk npc/rv64/testbench/Makefile npc/rv64/testbench/tests/tb_ooo_pending_lane1_capture_gate.sv`: PASS。
- `make -C npc/rv64 lint`: PASS。
- `make -C npc/rv64 -j2`: PASS。

## 风险与边界

- 本切片只抽取 lane1 局部组合 helper，不移动 pending sequencer 的 payload/state owner。
- 不改变 `OooPendingDispatchArbiter` 的全局 capture/clear 优先级。
- 不改变 CSR side effect、fetch redirect、backend drain、branch recovery 或 precise recovery。
- 后续仍可继续把 capture/clear/fire/blocked reason 收拢成更完整的 PendingCaptureGate/OwnerArbiter 协议。

