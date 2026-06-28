# 任务报告

## 任务

把 `core/OooCoreTopGlue.v` 从“改名后的功能壳”继续拆成真实装配层，把剩余关键功能规则迁到对应目录。

## RTL 推导摘要

### 需求

- `OooCoreTopGlue` 不再拥有 pending/drain、FP commit、pending operand read、branch prefetch clear、final observable output 语义。
- 新 owner 按职责目录落盘并由 filelist 纳入构建：
  - `frontend/OooBranchPrefetchClearGate.v`
  - `control/OooPendingDrainResolveGate.v`
  - `control/OooCoreObservableOutputGate.v`
  - `writeback/OooFpCommitGate.v`
  - `regread_bypass/OooPendingOperandReadGate.v`
- 接口保持等价，父模块只实例化并转接 wire。

### 协议规则

- 本轮新增模块均为组合 gate，不新增 ready/valid 握手、不新增寄存器、不改变 reset/flush 时序。
- 输入均来自既有 pending sequencer、frontend helper、CSR/commit 状态或 memory response。
- 输出仍消费于原有位置：prefetch buffer clear、pending dispatch/control mux、CSR fflags、FPR/GPR writeback、外部 trap/debug/CSR 端口。

### 状态机

- 无新增状态机。
- 状态仍由既有 `OooStopPendingSequencer`、pending branch/jump/mem/FP/system sequencer、`OooTrapExitOutputSequencer`、`OooBackendDrainTracker` 等 owner 持有。
- `OooPendingDrainResolveGate` 只组合读取当前状态和 tracked backend-drained 状态，生成 resolve/drain 事件。

### 不变量

- `OooCoreTopGlue` 不含顶层 `assign`，不含 `arch_gpr()`。
- `drain_complete` 只能在 `stop_pending`、当前 backend drained、pending control ready 且无 replay wait 时成立。
- FP result/fflags/GPR serial commit/FPR 写回条件由 `OooFpCommitGate` 统一产生，core 不重复计算。
- pending operand read 只能由 `OooPendingOperandReadGate` 解包 `core_debug_gprs_w`。
- final trap/exit/halt/debug/CSR observable output 只能由 `OooCoreObservableOutputGate` 选择。

### 数据通路骨架

- `OooPendingOperandReadGate`: flattened GPR bus -> pending branch rs1/rs2、pending jump rs1、FP rs index/int rs1 value。
- `OooFpCommitGate`: pending FP long/compute result + memory response -> result value、fflags、GPR commit、FPR load/result write。
- `OooPendingDrainResolveGate`: ROB/IQ/retire/pending states -> backend drained、replay wait、drain complete、branch/jump/mem/system/FP resolve events。
- `OooBranchPrefetchClearGate`: trap/flush/resolve/drain events -> prefetch clear。
- `OooCoreObservableOutputGate`: sticky trap/exit/halt + CSR/debug inputs -> public observable outputs。

## 改动摘要

- 新增 5 个 owner 模块并接入 `vsrc/filelist.mk`。
- `OooCoreTopGlue` 删除内联 branch prefetch clear、pending/drain、FP commit、pending operand read、final output 规则。
- `OooFpCommitGate` 覆盖 FP GPR/FPR/fflags commit gate，`OooPendingOperandReadGate` 覆盖 `arch_gpr()`，`OooPendingDrainResolveGate` 覆盖用户点名的 pending/drain 中枢。
- 更新 `npc/rv64/vsrc/README.md`、`npc/rv64/vsrc/control/README.md`、`npc/rv64/design/specs/ooo-core-top-glue.md` 和 memory。

## 验证

- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-core-logic-decompose/focused-rerun TESTS="tb_ooo_core_top_glue tb_ooo_fetch_trap_gate tb_ooo_priv_system tb_ooo_pending_dispatch_arbiter tb_decode_unit" run`
  - 5/5 PASS
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-core-logic-decompose/all-rerun run`
  - 103/103 PASS
- `make -C npc/rv64 lint`
  - PASS
- `make -C npc/rv64 -j2`
  - PASS
- 静态检查：
  - `OooCoreTopGlue.v` 中顶层 `assign`、`arch_gpr`、pending/drain/FP commit 旧内联规则扫描无输出。
  - 旧 `OooAluFetchCore` 名称残留扫描无输出。
  - scoped `git diff --check` PASS。

## 边界

本切片完成 core glue 的关键功能规则下沉，尤其是用户点名的 pending/drain 中枢；但尚未新增更大粒度的 `frontend/OooFrontend.v` 或 `control/OooControlPlane.v` wrapper，也未完成 fetch packet、pending owner、commit event 的全面 packed bus 化。
