# F0 Truthful Regression Implementation Plan

> **生命周期：COMPLETED / SUPERSEDED（2026-07-11）**
> Task 1-7 已实施并由
> `.github/task-runs/2026-07-11-rv64-f0-truthful-regression/task-report.md` 收口；后续以
> parent design 的 F1/T0/T1 为 active backlog。本文件只保留 TDD 过程和历史验收口径。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 module TB、AM cpu-tests 与 core-regress 的退出码真实反映底层结果，修复当前三个陈旧 TB 合同以及 `fp-difftest-probe` 暴露的 FP 跨寄存器域假唤醒，使 F0 在 current RTL 上形成可重复的真绿基线。

**Architecture:** 把“仿真进程状态”“日志语义”“测试源退出语义”三层判据汇聚到一个小型 checker；AM 侧按完整测试名集合校验 `.result`。RTL 只修复已由反例闭合的 FP 结果域资格：GPR 目的的 FP completion 仍进入 ROB/GPR 写回，但不得清 FP busy、旁路 FP source 或广播 FP wakeup。

**Tech Stack:** GNU Make、Python 3 `unittest`、Icarus Verilog/vvp、Verilator、RV64 Verilator simulator、NEMU Difftest、现有 `npc-rv64-core-regress.sh`、task-run/evidence DB 工具。

**Parent design:** `npc/rv64/design/arch/rv64-200mhz-completion-design.md` §4 F0。

**Execution policy（历史）:** 开工时工作树已有用户改动；之后用户明确授予 `git add`/
`git commit` 权限，因此 Task 1-5 以精确路径独立提交。全过程未创建 worktree，WSL 工程命令
串行执行，未把既有暂存项混入 F0 提交。

---

## 0. 已闭合根因与不可改变的合同

### 0.1 三个 module TB 是合同漂移

1. `tb_ooo_control_commit_sequencer.sv` 未连接新增的 `head0_csr_commit_i`。DUT 每拍执行
   `serial_flush_q <= head0_csr_commit_i`，悬空输入使七个 serial 检查得到 `z`。
2. `tb_ooo_pending_system_sequencer.sv` 把带 bit63 的 64-bit interrupt mcause 写进
   `TRAP_CAUSE_W=5` 的 cause-code 接口；该 sequencer 只保存 code，bit63 由 `CsrFile` 写
   `mcause/scause` 时添加。TB 同时漏接 head0/lane1 `fencei` 端口。
3. `tb_ooo_stop_pending_sequencer.sv` 仍期望 direct branch 进入旧 direct+drain stop 模型；当前
   `OOO_DBRANCH_DOMAIN_A=1` 下 branch 进入 ROB-walk，正确期望为不置 stop。TB 同时漏接
   `head0_csr_commit_i` 与 `head0_csr_inflight_i`。

这些修复只能更新 TB 接线和期望，不允许为迎合旧 TB 回退 DUT 架构。

### 0.2 `fp-difftest-probe` 是已闭合 RTL 域资格错误

当前 Difftest 在 `fsqrt.d ft3,ft0` 后的 `fmv.x.d a3,ft3`（PC `0x80000120`）观察到：

- reference：`0x54d4547544d80e80`；
- DUT：`0xbab3d8aa9dc0b5b7`。

输入 `0x69b9d4e2feca80d8` 的正确平方根位型是 reference 值。DUT 值符号位为 1，而
`OooFpLongOpGate` 的有限正数 FSQRT 结果固定拼接 sign=0，因此错误值不是 sqrt 算法输出，而是陈旧
FPR 数据。

`OooFpBackend.v` 已经用 `fp_result_wb_frd_w` 正确资格化物理 FPR 写端口，却仍把未资格化的
`fp_result_wb_valid_w` 用于：

- 清 `fp_busy_q[fp_result_wb_preg_w]`；
- `fp_src_ready(...)` 的 completion bypass；
- `fp_wake0_valid_o`。

当 FP 指令的目的在 GPR（例如 `FMV.X.D`）时，`fp_result_wb_preg_w` 属于整数物理寄存器编号域；
该编号与 FPR preg 数值别名，因而会提前清另一个在飞 FPR 的 busy 并假唤醒消费者。最终
`FMV.X.D` 提前读取尚未被 FSQRT 写回的陈旧 FPR。

不可改变的修复合同：

```text
fp_fpr_complete = fp_result_wb_valid && fp_result_wb_frd

FP busy clear / FP source bypass / FP wake / FPR write <= fp_fpr_complete
ROB completion FIFO / GPR writeback                    <= fp_result_wb_valid
```

不得把 GPR 目的 completion 从 ROB done FIFO 删除，也不得通过延迟所有 FP issue 来掩盖域资格错误。

---

## Task 1：建立 module TB 结果判定器

**Files:**

- Create: `npc/rv64/testbench/scripts/__init__.py`
- Create: `npc/rv64/testbench/scripts/check_tb_result.py`
- Create: `npc/rv64/testbench/scripts/test_check_tb_result.py`

### 1.1 先写 checker 单元测试

- [ ] 创建 `scripts/__init__.py` 空包文件。
- [ ] 在 `test_check_tb_result.py` 用 `tempfile.TemporaryDirectory` 建立真实 source/log 文件，不 mock 文件系统。
- [ ] 覆盖以下判据：
  - compile rc 非零必须失败；
  - vvp rc 非零必须失败；
  - 日志有 `FAIL`、`[FAIL]`、`[CHECK-FAIL]` 或 `errors=N` 且 N 非零必须失败；
  - 日志缺少 `PASS <test>` 或 `[PASS] <test>` 必须失败；
  - source 含 `$finish(1)` 或其他非零常量必须失败；
  - `$finish;`、`$finish()` 与 `$finish(0)` 允许；
  - ANSI color 不影响 PASS/FAIL 解析；
  - 一份真 PASS fixture 返回成功。
- [ ] 运行 RED：

```bash
python3 -m unittest discover -s npc/rv64/testbench/scripts -p 'test_check_tb_result.py' -v
```

Expected: 因 `check_tb_result.py` 尚不存在而失败；保存该 RED 输出到 F0 task-run evidence。

### 1.2 实现纯函数与 CLI

- [ ] `check_tb_result.py` 实现 `strip_ansi(text)`。
- [ ] 实现 `legacy_failure_finish(source_text)`：允许 `$finish;`、`$finish()` 与
  `$finish(0)`；任何其他带参数形式（包括 `$finish(1)`、`$finish(2)` 与
  `$finish(errors == 0 ? 0 : 1)`）都必须失败。
- [ ] 实现 `classify(test_name, source_text, log_text, compile_rc, sim_rc) -> list[str]`；空列表表示成功，每个失败原因单独返回。
- [ ] PASS 只接受整行 `PASS <test>` 或 `[PASS] <test>`；不得接受 runner 自己追加的 `[RESULT] PASS`。
- [ ] CLI 参数固定为：

```text
--test NAME --source PATH --log PATH --compile-rc N --sim-rc N
```

- [ ] CLI 将失败原因逐行写 stderr，任一原因退出 1；参数/文件错误退出 2；成功退出 0。
- [ ] 运行 GREEN：

```bash
python3 -m unittest discover -s npc/rv64/testbench/scripts -p 'test_check_tb_result.py' -v
```

Expected: 所有 checker 单元测试 PASS。

---

## Task 2：把 module Makefile 接到真实判据

**Files:**

- Modify: `npc/rv64/testbench/Makefile`
- Create: `npc/rv64/testbench/scripts/fixtures/tb_false_green.sv`
- Create: `npc/rv64/testbench/scripts/fixtures/tb_true_green.sv`
- Modify: `npc/rv64/testbench/scripts/test_check_tb_result.py`

### 2.1 写 Make 集成 RED fixtures

- [ ] `tb_false_green.sv` 输出 `FAIL tb_false_green errors=1` 后调用 `$finish(1)`。
- [ ] `tb_true_green.sv` 输出 `[PASS] tb_true_green` 后调用 `$finish;`。
- [ ] 在 Python 测试中用真实 subprocess 分别执行：

```bash
make -C npc/rv64/testbench \
  TESTS=tb_false_green \
  TB_SRCS_tb_false_green=scripts/fixtures/tb_false_green.sv \
  RESULT_DIR=<temporary-directory>/false run

make -C npc/rv64/testbench \
  TESTS=tb_true_green \
  TB_SRCS_tb_true_green=scripts/fixtures/tb_true_green.sv \
  RESULT_DIR=<temporary-directory>/true run
```

- [ ] 断言 false fixture 非零、日志 `[RESULT] FAIL`；true fixture 为零、日志 `[RESULT] PASS`。
- [ ] 运行 RED：

```bash
python3 -m unittest discover -s npc/rv64/testbench/scripts -p 'test_check_tb_result.py' -v
```

Expected: false fixture 当前被旧 Makefile 错判为成功，因此集成用例失败。

### 2.2 修改 RUN_TEST 状态机

- [ ] 为 Makefile 增加 `PYTHON ?= python3` 与 `TB_RESULT_CHECKER := scripts/check_tb_result.py`。
- [ ] 把 compile 与 vvp 分开执行，分别保存 `compile_rc`、`sim_rc`；compile 失败时不得启动 vvp。
- [ ] checker 输入的 source 必须是 `$(firstword $(TB_SRCS_<test>))`，即顶层 TB source。
- [ ] 仅当 checker 返回 0 时追加 `[RESULT] PASS`；否则追加 `[RESULT] FAIL status=<rc>`、原子移动 tmp log，并让该 make target 非零退出。
- [ ] 保留现有 temp-log 后原子 `mv` 行为，避免并行回归读到半份日志。
- [ ] 运行 GREEN：

```bash
python3 -m unittest discover -s npc/rv64/testbench/scripts -p 'test_check_tb_result.py' -v
```

Expected: false/true 两个 Make 集成 fixture 都按合同通过测试。

### 2.3 证明旧的三个失败现在会使顶层变红

- [ ] 运行：

```bash
make -C npc/rv64/testbench \
  TESTS='tb_ooo_control_commit_sequencer tb_ooo_pending_system_sequencer tb_ooo_stop_pending_sequencer' \
  RESULT_DIR=/tmp/ysyx-f0-module-red run
```

Expected: 命令非零；三个 log 都是 `[RESULT] FAIL`，summary 不得写 3/3 PASS。

---

## Task 3：建立 AM `.result` 完整性判定器

**Files:**

- Create: `am-kernels/tests/cpu-tests/scripts/__init__.py`
- Create: `am-kernels/tests/cpu-tests/scripts/check_results.py`
- Create: `am-kernels/tests/cpu-tests/scripts/test_check_results.py`
- Modify: `am-kernels/tests/cpu-tests/Makefile`

### 3.1 先写 parser RED

- [ ] 测试真实临时 `.result` 文件，覆盖：全部 PASS、ANSI PASS、单项 FAIL、缺项、重复项、未知项、空文件与损坏行。
- [ ] checker 接收 `--result PATH --expected TEST [TEST ...]`，要求每个 expected test 恰好出现一次，且不得出现 unexpected test。
- [ ] 运行 RED：

```bash
python3 -m unittest discover -s am-kernels/tests/cpu-tests/scripts -p 'test_check_results.py' -v
```

Expected: checker 尚未实现，测试失败。

### 3.2 实现 checker

- [ ] 解析 ANSI 清理后的整行：`[<name>] PASS` 或 `[<name>] ***FAIL***`。
- [ ] 所有异常都输出确定性摘要：failed、missing、duplicate、unexpected、malformed。
- [ ] 任一集合非空退出 1；文件/参数错误退出 2；完整全 PASS 退出 0。
- [ ] 运行 GREEN：

```bash
python3 -m unittest discover -s am-kernels/tests/cpu-tests/scripts -p 'test_check_results.py' -v
```

### 3.3 消除 parse-time truncate 并传播 rc

- [ ] 删除 `$(shell > $(RESULT))`，避免只读 make 解析也清空结果。
- [ ] 新增 phony `prepare-result`，recipe 为 `@: > $(RESULT)`。
- [ ] 让每个 `Makefile.%` 对 `prepare-result` 建立 order-only prerequisite，确保并行 append 前结果文件只初始化一次。
- [ ] 新增 `check-results` target，调用 checker 并传入 `$(sort $(ALL))`。
- [ ] `run` 与 `c` 在 cat 后执行 checker，保存其 rc，删除 `.result`，最后以保存的 rc 退出。
- [ ] 用 fixture 文件验证 Make wiring：

```bash
printf '[            ok] PASS\n[           bad] ***FAIL***\n' >/tmp/ysyx-f0-am.result
make -C am-kernels/tests/cpu-tests \
  RESULT=/tmp/ysyx-f0-am.result ALL='ok bad' check-results
```

Expected: 命令非零并报告 `bad`；随后将 bad 改成 PASS，命令必须为零。

---

## Task 4：更新三个陈旧 TB 与非零 finish 退出语义

**Files:**

- Modify: `npc/rv64/testbench/tests/tb_ooo_control_commit_sequencer.sv`
- Modify: `npc/rv64/testbench/tests/tb_ooo_pending_system_sequencer.sv`
- Modify: `npc/rv64/testbench/tests/tb_ooo_stop_pending_sequencer.sv`
- Modify: `npc/rv64/testbench/tests/tb_ooo_control_flush_sequencer.sv`

### 4.1 control commit 接线与语义覆盖

- [ ] 声明、清零并连接 `head0_csr_commit` → `head0_csr_commit_i`。
- [ ] 增加定向场景：head0 CSR commit 一拍后 `core_serial_flush=1`，输入清零后下一拍恢复 0；同时确认不伪造 `ctrl_commit_valid`。
- [ ] 把尾部 `$finish(errors == 0 ? 0 : 1)` 改为：成功显示 PASS 并 `$finish;`，失败 `$fatal(1, "...")`。

### 4.2 pending system 使用 cause code 并覆盖 fence.i

- [ ] 新增 `capture_head0_fencei`、`capture_lane1_fencei` 与 `fencei` wire，连接三个相应端口。
- [ ] `clear_inputs` 清两个 fencei 输入；`expect_idle` 检查 fencei=0。
- [ ] `capture_irq_cause` 只赋 `TRAP_CAUSE_W` code（timer=7、external=11），新增 width-correct cause checker，IRQ 期望 `5'd11`，不再期望 bit63。
- [ ] head0 与 lane1 各至少一个 capture 场景验证 `fencei_o` 随 capture 保存。
- [ ] 失败尾部改为 `$fatal(1, "...")`。

### 4.3 stop pending 跟随 domain-A 与 CSR inflight 合同

- [ ] 声明、清零并连接 `head0_csr_commit`、`head0_csr_inflight`。
- [ ] direct branch/no redirect 的期望改为 `` `OOO_DBRANCH_DOMAIN_A ? 1'b0 : 1'b1 ``，测试名称明确“configured branch domain”。
- [ ] 新增 CSR 场景：inflight 强制保持 stop；commit 与 inflight 同拍时 commit 排除项清 stop。
- [ ] 失败尾部改为 `$fatal(1, "...")`。

### 4.4 清除剩余非零 `$finish`

- [ ] `tb_ooo_control_flush_sequencer.sv` 的失败尾部改为 `$fatal(1, "...")`。
- [ ] 运行静态门槛：

```bash
if rg -n '\$finish[[:space:]]*\([[:space:]]*[1-9]' npc/rv64/testbench/tests; then
  exit 1
fi
```

- [ ] 运行 focused GREEN：

```bash
make -C npc/rv64/testbench \
  TESTS='tb_ooo_control_commit_sequencer tb_ooo_pending_system_sequencer tb_ooo_stop_pending_sequencer tb_ooo_control_flush_sequencer' \
  RESULT_DIR=/tmp/ysyx-f0-module-contract-green run
```

Expected: 4/4 真 PASS；每个原始 log 在 `[RESULT] PASS` 前有自己的正向 PASS marker，且无 FAIL marker。

---

## Task 5：用 TDD 修复 FP GPR/FPR completion 域资格

**Files:**

- Modify: `npc/rv64/testbench/tests/tb_ooo_core_top_glue.sv`
- Modify: `npc/rv64/vsrc/execute/OooFpBackend.v`

### 5.1 添加非真空 RED 观察点

- [ ] 在 `tb_ooo_core_top_glue.sv` 为以下内部合同建立只读层次观察 wire：

```text
dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
   .u_fp_backend.fp_result_wb_valid_w
dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
   .u_fp_backend.fp_result_wb_frd_w
dut.u_execute_backend.u_core_slice.u_decode_backend.u_int_backend
   .u_fp_backend.fp_wake0_valid_o
```

- [ ] 增加 `saw_fp_gpr_completion` 与 `saw_fp_gpr_completion_wake`；每次 reset 清零。
- [ ] 仅在 `fp_result_wb_valid && !fp_result_wb_frd` 时置第一个观察位；若同拍 FP wake 有效，置第二个观察位。
- [ ] 现有 `MODE_FMV_W_X` 只有 `FMV.W.X`（GPR→FPR），本身不会产生 GPR 目的 FP
  completion。新增 `inst_fmv_x_w(rd, fs1)` encoder，并在该 mode 的 `FMV.W.X f0,x0`
  之后插入 `FMV.X.W x6,f0`；把后续 ADDI/EBREAK 顺延 4 bytes、退休计数期望从 4 改为 5，
  并检查 x6=0，证明反向搬运实际执行。
- [ ] 在扩展后的 `MODE_FMV_W_X` 场景后检查：GPR 目的 FP completion 必须实际出现，且不得
  广播 FP wake。第一个检查保证断言非真空；若没有观察到 completion，禁止把 wake=0 当作 GREEN。
- [ ] 运行 RED：

```bash
make -C npc/rv64/testbench \
  TESTS=tb_ooo_core_top_glue \
  RESULT_DIR=/tmp/ysyx-f0-fp-domain-red run
```

Expected: “GPR-destination FP completion does not wake FPR domain” 失败；“completion observed” 成功。

### 5.2 最小 RTL 修复

- [ ] 将 `wire fp_result_wb_frd_w;` 前移到 `fp_result_wb_valid_w/preg_w` 声明组。
- [ ] 定义唯一资格 wire：

```verilog
wire fp_fpr_complete_w = fp_result_wb_valid_w && fp_result_wb_frd_w;
```

- [ ] 只在以下位置把 `fp_result_wb_valid_w` 替换为 `fp_fpr_complete_w`：
  - `fp_busy_q` completion clear；
  - 八个 `fp_src_ready(...)` 调用的执行簇 wake 参数；
  - `fp_wake0_valid_o`；
  - `OooFpPhysRegFile.write0_valid_i`。
- [ ] 不修改 `df_push_w`、`done_in_*` 或 `fpwb_*`，保证 GPR 目的 FP 指令仍完成 ROB 并写整数域。
- [ ] 在 `OOO_ASSERT` 下增加即时合同：若 GPR 目的 completion 同拍 `fp_wake0_valid_o=1`，调用 `$fatal(1, ...)`。
- [ ] 运行 focused GREEN：

```bash
make -C npc/rv64/testbench \
  TESTS='tb_ooo_core_top_glue tb_ooo_fp_long_op_gate tb_ooo_fp_iter' \
  RESULT_DIR=/tmp/ysyx-f0-fp-domain-green run
```

Expected: 3/3 真 PASS，层次观察的非真空检查成立。

### 5.3 用原始系统反例验证

- [ ] 保存当前 `npc/rv64/.config` 及 derived config hash 到 task-run evidence。用以下单个
  wrapper 保证任何中途失败都会恢复配置，并在 Difftest-ON 构建中运行原始反例：

```bash
bash -lc '
set -euo pipefail
backup=$(mktemp)
cp npc/rv64/.config "$backup"
restore_config() {
  cp "$backup" npc/rv64/.config
  (cd npc/rv64 && ../../tool/kconfig/build/conf -s --syncconfig Kconfig)
  rm -f "$backup"
}
trap restore_config EXIT
make -C npc/rv64 default_defconfig
make -C npc/rv64 difftest-ref
make -C npc/rv64 -j2 default
make -C am-kernels/tests/cpu-tests \
  ARCH=riscv64-npc ALL=fp-difftest-probe run \
  NPC_RUN_ARGS="--no-progress --max-cycles 20000000"
'
```

- [ ] 确认 wrapper 中前三条命令构建了 Difftest reference 与 NPC：

```bash
make -C npc/rv64 default_defconfig
make -C npc/rv64 difftest-ref
make -C npc/rv64 -j2 default
```

- [ ] 确认 wrapper 的最后一条命令只跑原始反例：

```bash
make -C am-kernels/tests/cpu-tests \
  ARCH=riscv64-npc ALL=fp-difftest-probe run \
  NPC_RUN_ARGS='--no-progress --max-cycles 20000000'
```

Expected: 控制台明确 `Difftest: ON`；PC `0x80000120` 不再 mismatch；test 与 make 均返回 0。

- [ ] wrapper 退出后核对进入任务前的 `.config` 与 derived config hash 完全一致。

---

## Task 6：F0 全量真绿验收

**Files:**

- No production changes unless a new failure is first reduced to a focused RED.
- Create evidence under: `.github/task-runs/2026-07-11-rv64-f0-truthful-regression/evidence/`

### 6.1 checker 与 fixture gate

- [ ] 串行运行：

```bash
python3 -m unittest discover -s npc/rv64/testbench/scripts -p 'test_check_tb_result.py' -v
python3 -m unittest discover -s am-kernels/tests/cpu-tests/scripts -p 'test_check_results.py' -v
```

- [ ] 记录测试数、PASS 数和命令 rc；不得只保存末行摘要。

### 6.2 module/structural gate

- [ ] 运行：

```bash
make -C npc/rv64/testbench \
  RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-11-rv64-f0-truthful-regression/evidence/module-testbench \
  run
make -C npc/rv64 check-rtl-style
make -C npc/rv64 check-contract
make -C npc/rv64 lint
```

Expected: module 86/86 真 PASS；86 份原始 log 均有自身 PASS marker、无 failure marker；三个结构 gate rc=0。

### 6.3 AM、Difftest 与 official tests gate

- [ ] 复用 Task 5.3 的 `set -euo pipefail`/`trap restore_config EXIT` wrapper，加载
  `default_defconfig` 后在同一个 wrapper 内运行：

```bash
make -C npc/rv64 difftest-ref
make -C npc/rv64 -j2 default
make -C am-kernels/tests/cpu-tests \
  ARCH=riscv64-npc run \
  NPC_RUN_ARGS='--no-progress --max-cycles 20000000'
npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh \
  --riscv-tests --riscv-privileged
```

Expected:

- AM 59/59，checker 与 `make run` rc=0；
- `fp-difftest-probe` 的原始 log 明确 Difftest ON；
- official riscv-tests 177/177；
- core-regress 中 module/lint/build/AM/riscv 的外层状态与子层 rc 一致；
- 若任何一项失败，F0 保持未完成，先按 systematic-debugging 建立新的 focused RED，禁止修改 checker 白名单隐藏失败。

- [ ] 恢复并核对进入任务前的 config hash。

### 6.4 独立审查

- [ ] 实现者列出：修改文件、RED 输出、GREEN 输出、完整回归计数、config/provenance hash。
- [ ] 独立审查者重点找四类反例：
  - checker 是否会把 `[RESULT] PASS` 当成 TB 自身 PASS；
  - AM 缺项或重复项是否仍可能返回 0；
  - FP GPR completion 是否仍在任何 bypass/wakeup 点进入 FPR 域；
  - Difftest OFF 的 `fp-difftest-probe` 是否被误写成数值正确性证据。
- [ ] 冲突未解决前只记录 F0 partial，不进入 T0/T1。

---

## Task 7：文档、memory、task-run 与 strict guard 收尾

**Files:**

- Create: `.github/task-runs/2026-07-11-rv64-f0-truthful-regression/task-report.md`
- Create: `.github/task-runs/2026-07-11-rv64-f0-truthful-regression/evidence-index.md`
- Modify: `.github/task-runs/2026-07-11-rv64-200mhz-program/task-report.md`
- Modify: `.github/task-runs/2026-07-11-rv64-200mhz-program/evidence-index.md`
- Modify: `npc/rv64/design/arch/rv64-200mhz-completion-design.md`
- Modify: `npc/rv64/README.md`
- Modify: `.github/memory/project-status.md`
- Modify: `.github/memory/modules/npc.md`
- Modify: `.github/memory/known-issues.md`

### 7.1 更新权威状态

- [ ] F0 task report 写明 `status: pass|partial`、`rtl_changed: true`、所有命令 rc、current commit/dirty manifest、config hash 与证据相对路径。
- [ ] 若 Task 6 全部通过，在 parent design F0 节增加完成日期和 evidence 链接；否则保留 ACTIVE/未完成并写唯一剩余阻塞。
- [ ] README 的 module/AM 口径改为新鲜真实计数；不得保留“summary 86/86 但三项假绿”的 current 描述。
- [ ] known-issues 将三个 TB 假绿和 FP 域资格项标为 resolved only if 对应 RED→GREEN 与全量 gate 均存在；历史根因保留。
- [ ] memory 记录稳定原则：GPR/FPR preg 数字相同不代表同一域，所有 wake/bypass 必须带 destination-domain qualifier。

### 7.2 索引 evidence 并运行 agent workflow

- [ ] 对 raw logs 建索引而不把大日志纳入 Git：

```bash
python3 scripts/github_index_db.py index-evidence \
  .github/task-runs/2026-07-11-rv64-f0-truthful-regression/evidence \
  --write-index --yes
scripts/agent-e2e.sh --profile npc-dev
```

- [ ] 确认 raw evidence 被 ignore，`evidence-index.md`/task report 是可追踪摘要。

### 7.3 完成前验证

- [ ] 以审查者人格重跑：

```bash
scripts/agent-e2e.sh --guard --guard-mode strict
git diff --check
git status --short
```

Expected: strict guard PASS；不存在意外 staged 文件；原用户改动仍保留；只新增/修改本计划列出的 F0 文件与证据摘要。

---

## F0 退出判据

只有以下条件同时成立，才可把 F0 标为完成并开始 T0/T1：

1. false-green fixtures 在 module 与 AM 两侧都可靠返回非零；
2. 三个陈旧 TB 合同更新后 4 个相关 TB 真绿，所有非零 `$finish` 清零；
3. FP GPR completion 的 FPR-domain wake 非真空反例由 RED 变 GREEN；
4. `fp-difftest-probe` 在 Difftest ON 下通过；
5. module 86/86、AM 59/59、official 177/177、lint/build/contract 全部使用真实 rc 通过；
6. current config/provenance、task-run evidence、memory 与 strict guard 全部闭合。

F0 完成不等于“完整功能”或“200 MHz 完成”。它只建立后续 F1–F3 与 T0–T4 可以信任的测量地基。
