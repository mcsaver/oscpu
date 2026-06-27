# RV64 Fetch Head Pair Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从 `OooAluFetchCore` 抽出 fetch head pair 纯组合模块，并保持现有行为不变。

**Architecture:** 新增 `frontend/OooFetchHeadPairGate.v`，内部实例化两个 `OooFetchHeadClassifyGate`，统一输出 head0/head1 facts、fetch fault、branch-spec dispatch block 和 dispatch0 facts。父模块只替换前段组合逻辑，不移动 pending、CSR、fetch FIFO、PC/outstanding、RAS/BPU 或 commit 状态。

**Tech Stack:** Verilog/SystemVerilog、Icarus Verilog、Verilator、现有 `npc/rv64/testbench`、GNU Make。

---

### Task 1: 项目记录与规格落盘

**Files:**
- Create: `npc/rv64/design/specs/ooo-fetch-head-pair-gate.md`
- Create: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/task-report.md`
- Create: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/dispatch-log.md`
- Create: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/implementation-plan.md`

- [x] **Step 1: 写入项目内 spec**

文件已写入：`npc/rv64/design/specs/ooo-fetch-head-pair-gate.md`

- [x] **Step 2: 写入 task-run 初始记录**

文件已写入：`.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/`

### Task 2: 新增 failing module testbench

**Files:**
- Create: `npc/rv64/testbench/tests/tb_ooo_fetch_head_pair_gate.sv`
- Modify: `npc/rv64/testbench/Makefile`

- [x] **Step 1: 登记新 testbench 目标**

在 `TESTS` 中把 `tb_ooo_fetch_head_pair_gate` 放在 `tb_ooo_fetch_head_classify_gate` 附近。

- [x] **Step 2: 写入 focused testbench**

创建 testbench，覆盖 spec 中 idle、双槽 ALU、lane0 branch/stop/fault 抑制、lane1 fault、branch-spec block、IRQ/can-run、FS-off FP 和 direct branch0 alias。

- [x] **Step 3: 运行并确认失败**

Run:

```bash
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate" RESULT_DIR=../perf/results/20260627-fetch-head-pair/failing run
```

Expected: FAIL，原因是 `OooFetchHeadPairGate` 尚不存在。

### Task 3: 新增 pair gate RTL

**Files:**
- Create: `npc/rv64/vsrc/frontend/OooFetchHeadPairGate.v`
- Modify: `npc/rv64/vsrc/filelist.mk`

- [x] **Step 1: 创建纯组合 pair gate**

新增模块以 `fifo_has_packet/head_resp*/head_inst*/head_ctrl*/priv/mstatus/can_run/csr_irq/branch_spec_active` 为输入，输出 head0/head1 facts、fetch fault、dispatch block 和 dispatch0 facts。

- [x] **Step 2: 登记 filelist**

在 `filelist.mk` 中新增：

```make
RTL_OOO_FETCH_HEAD_PAIR_GATE := $(RTL_FRONTEND_DIR)/OooFetchHeadPairGate.v
```

并加入 `RTL_OOO_FRONTEND_HELPERS`。

- [x] **Step 3: 运行单测并确认通过**

Run:

```bash
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate" RESULT_DIR=../perf/results/20260627-fetch-head-pair/module run
```

Expected: PASS。

### Task 4: 替换 `OooAluFetchCore` head pair 前段组合逻辑

**Files:**
- Modify: `npc/rv64/vsrc/frontend/OooAluFetchCore.v`

- [x] **Step 1: 用 pair gate 替换 head0/head1 classifier 实例和可见性逻辑**

移除父模块内的 `head_fetch_fault0/1`、`head*_decode_valid`、两个 classifier 实例、branch-spec dispatch block、`dispatch_valid` 和 dispatch0 facts 内联赋值，改为 `OooFetchHeadPairGate u_fetch_head_pair_gate` 输出原 wire 名。

- [x] **Step 2: 保留父模块 fire/ready/unsupported 逻辑**

`direct_branch0_fire_w`、`direct_jal0_dispatch_valid_w`、`direct_ret0_dispatch_valid_w`、RAS/BPU/pending 相关逻辑继续留在父模块。

- [x] **Step 3: 运行 focused 回归**

Run:

```bash
make -C npc/rv64/testbench TESTS="tb_ooo_fetch_head_pair_gate tb_ooo_fetch_head_classify_gate tb_ooo_alu_fetch_core tb_decode_unit" RESULT_DIR=../perf/results/20260627-fetch-head-pair/focused run
```

Expected: 4/4 PASS。

### Task 5: 回归、文档和 memory

**Files:**
- Modify: `npc/rv64/vsrc/README.md`
- Modify: `.github/memory/modules/npc.md`
- Modify: `.github/memory/project-status.md`
- Modify: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/task-report.md`
- Modify: `.github/task-runs/2026-06-27-npc-rv64-fetch-head-pair-gate/dispatch-log.md`

- [x] **Step 1: 运行 lint/build**

Run:

```bash
make -C npc/rv64 lint
make -C npc/rv64
```

Expected: both PASS。

- [x] **Step 2: 运行 full module testbench**

Run:

```bash
make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-fetch-head-pair/full-rerun run
```

Expected: all PASS。

- [x] **Step 3: 预算允许时运行 official smoke**

Run:

```bash
npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --skip-am --riscv-tests --riscv-suites rv64ui --riscv-privileged --log-base npc/rv64/perf/results/20260627-fetch-head-pair/core-regress-official
```

Expected: overall_rc=0。

- [x] **Step 4: 更新项目记录**

在 `vsrc/README.md` 记录 pair gate owner；在 memory 与 task-run 记录改动、验证和边界。

## 自检

- Spec 覆盖：每条范围与不变量都有 Task 2 单测或 Task 4 父模块回归覆盖。
- 占位扫描：未留下待办占位符。
- 类型一致性：接口名称直接来自当前 `OooAluFetchCore` head pair facts，后续实现不得引入不同命名。
