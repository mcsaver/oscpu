# RV64 Fetch Head Classify Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从 `OooAluFetchCore` 抽出单槽 fetch head 分类纯组合模块，并保持现有行为不变。

**Architecture:** 新增 `frontend/OooFetchHeadClassifyGate.v`，内部复用 `OooFpDecode`，输出当前 head0/head1 已消费的分类 facts。父模块只替换两段重复组合逻辑，不移动 pending、CSR、fetch FIFO、PC/outstanding 或 commit 状态。

**Tech Stack:** Verilog/SystemVerilog、Verilator、现有 `npc/rv64/testbench`、GNU Make。

---

### Task 1: 项目记录与规格落盘

**Files:**
- Create: `npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`
- Create: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/task-report.md`
- Create: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/dispatch-log.md`
- Create: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/implementation-plan.md`
- Delete: `docs/superpowers/specs/2026-06-27-rv64-fetch-head-classify-gate-design.md`

- [x] **Step 1: 写入项目内 spec**

文件已写入：`npc/rv64/design/specs/ooo-fetch-head-classify-gate.md`

- [x] **Step 2: 写入 task-run 初始记录**

文件已写入：`.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/task-report.md`

- [x] **Step 3: 删除临时 Superpowers 草稿**

临时草稿已删除，后续以 `npc/rv64/design/specs/` 和 `.github/task-runs/` 为准。

### Task 2: 新增 failing module testbench

**Files:**
- Create: `npc/rv64/testbench/tests/tb_ooo_fetch_head_classify_gate.sv`
- Modify: `npc/rv64/testbench/Makefile`

- [x] **Step 1: 登记新 testbench 目标**

在 `npc/rv64/testbench/Makefile` 的测试列表中加入：

```make
tb_ooo_fetch_head_classify_gate
```

- [x] **Step 2: 写入 focused testbench**

创建 `tb_ooo_fetch_head_classify_gate.sv`，至少覆盖普通 ALU、base illegal、合法 FP 豁免、FS-off FP、CSR、ECALL、普通/semihost EBREAK、MRET/SRET、TSR、U-mode SFENCE/SINVAL、S-mode TVM 和 fetch fault。

- [x] **Step 3: 运行并确认失败**

Run:

```bash
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate" RESULT_DIR=../perf/results/20260627-fetch-head-classify/failing run
```

Expected: FAIL，原因是 `OooFetchHeadClassifyGate` 尚不存在。

### Task 3: 新增 classifier RTL

**Files:**
- Create: `npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v`
- Modify: `npc/rv64/vsrc/filelist.mk`

- [x] **Step 1: 创建纯组合 classifier**

新增模块接口包含：

```verilog
module OooFetchHeadClassifyGate (
  input decode_valid_i,
  input fetch_fault_i,
  input [`INST_W-1:0] inst_i,
  input [`INST_W-1:0] semihost_peer_inst_i,
  input semihost_peer_is_enter_i,
  input [`CTRL_BUS_W-1:0] ctrl_i,
  input [1:0] priv_mode_i,
  input [`XLEN-1:0] mstatus_i,
  output illegal_raw_o,
  output branch_raw_o,
  output jal_raw_o,
  output jalr_raw_o,
  output jump_raw_o,
  output mem_raw_o,
  output control_raw_o,
  output fp_load_raw_o,
  output fp_store_raw_o,
  output fp_move_to_fpr_raw_o,
  output fp_move_to_gpr_raw_o,
  output fp_class_raw_o,
  output fp_sgnj_raw_o,
  output fp_addsub_raw_o,
  output fp_mul_raw_o,
  output fp_fma_raw_o,
  output fp_div_raw_o,
  output fp_sqrt_raw_o,
  output fp_minmax_raw_o,
  output fp_compare_raw_o,
  output fp_convert_to_fpr_raw_o,
  output fp_convert_to_gpr_raw_o,
  output fp_raw_o,
  output fp_double_o,
  output fp_gpr_write_o,
  output fp_disabled_o,
  output fp_enabled_o,
  output ecall_raw_o,
  output ebreak_raw_o,
  output semihost_ebreak_o,
  output csr_raw_o,
  output mret_raw_o,
  output sret_raw_o,
  output xret_raw_o,
  output wfi_raw_o,
  output sfence_raw_o,
  output priv_system_illegal_o,
  output exit_raw_o,
  output system_raw_o,
  output arch_trap_raw_o,
  output stop_raw_o
);
```

- [x] **Step 2: 登记 filelist**

在 `npc/rv64/vsrc/filelist.mk` 的 frontend 段加入：

```make
RTL_OOO_FETCH_HEAD_CLASSIFY_GATE := $(RTL_FRONTEND_DIR)/OooFetchHeadClassifyGate.v
```

- [x] **Step 3: 运行单测并确认通过**

Run:

```bash
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate" RESULT_DIR=../perf/results/20260627-fetch-head-classify/classifier run
```

Expected: PASS。

### Task 4: 替换 `OooAluFetchCore` head0/head1 内联分类

**Files:**
- Modify: `npc/rv64/vsrc/frontend/OooAluFetchCore.v`

- [x] **Step 1: head0 接入 classifier**

用 `OooFetchHeadClassifyGate u_head0_classify_gate` 替换 head0 的内联分类与 `u_head0_fp_decode`。

- [x] **Step 2: head1 接入 classifier**

用 `OooFetchHeadClassifyGate u_head1_classify_gate` 替换 head1 的内联分类与 `u_head1_fp_decode`。

- [x] **Step 3: 保留父模块派生逻辑**

保留 `head_fetch_fault1_w`、`head1_decode_valid_w`、`branch_spec_dispatch_block_w` 和 dispatch fire 逻辑在父模块中。

- [x] **Step 4: 运行 focused 回归**

Run:

```bash
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit" RESULT_DIR=../perf/results/20260627-fetch-head-classify/focused run
```

Expected: 3/3 PASS。

### Task 5: 回归、文档和 memory

**Files:**
- Modify: `npc/rv64/vsrc/README.md`
- Modify: `.github/memory/modules/npc.md`
- Modify: `.github/memory/project-status.md`
- Modify: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/task-report.md`
- Modify: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-classify-gate/dispatch-log.md`

- [x] **Step 1: 运行 lint/build**

Run:

```bash
make -C npc/rv64 lint
make -C npc/rv64 -j2
```

Expected: both PASS。

- [x] **Step 2: 运行 full module testbench**

Run:

```bash
make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-fetch-head-classify/full-module-testbench run
```

Expected: all PASS。

- [x] **Step 3: 预算允许时运行 official smoke**

Run:

```bash
npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --riscv-tests --riscv-suites rv64ui --riscv-privileged --log-base npc/rv64/perf/results/20260627-fetch-head-classify/core-regress-official
```

Expected: overall_rc=0。

- [x] **Step 4: 更新项目记录**

在 `vsrc/README.md` 记录 classifier owner；在 memory 与 task-run 记录改动、验证和边界。

## 自检

- Spec 覆盖：每条范围与不变量都有 Task 2 单测或 Task 4 父模块回归覆盖。
- 占位扫描：未留下待办占位符。
- 类型一致性：接口名称直接来自当前 `OooAluFetchCore` head0/head1 facts，后续实现不得引入不同命名。
