# 任务报告

## 目标

继续拆分 `npc/rv64/vsrc/frontend/OooAluFetchCore.v`，让 RTL 边界更接近按 CPU Core 八类职责划分的工业化结构，同时保留可验证行为。

## 本轮改动

- 新增 `npc/rv64/vsrc/control/OooPendingDispatchArbiter.v` 与 spec，承接 pending branch/jump/memory/FP/SYSTEM/trap-exit capture/clear 的纯组合仲裁。
- 新增 `npc/rv64/vsrc/regread_bypass/OooFpRegFile.v` 与 spec，承接 FPR 状态、3 读端口、FP load 写回和 FP compute/long 写回。
- `OooAluFetchCore.v` 不再直接持有 `fpr_q`，父模块只保留 FPR 写回条件、pending/CSR/trap/fetch glue。
- `tb_ooo_sv39_boot.sv` 在 M-mode 进入 S-mode 前显式配置 PMP0 NAPOT RWX，修复测试缺少 PMP 前置条件导致的 S-mode fetch fault。
- 新增/登记 `tb_ooo_pending_dispatch_arbiter`、`tb_ooo_fp_reg_file`，测试文件位于 `npc/rv64/testbench/tests/`，没有放入 `.github`。

## 根因记录

`tb_ooo_sv39_boot` 失败不是新 pending dispatch 拆分导致 MRET/SATP 行为错误。trace 显示 MRET 后已经进入 S-mode 并跳到 `0x80000080`，随后 IFU 因 PMP no-match deny 报取指 fault。当前 `PmpChecker` 对无 PMP 命中的 S/U 访问拒绝是有意的 privileged 语义，因此修复放在测试程序：进入 S-mode 前先配置 PMP 授权。

## 验证

- `make -C npc/rv64/testbench TESTS="tb_ooo_fp_reg_file tb_ooo_alu_fetch_core tb_ooo_pending_dispatch_arbiter tb_ooo_sv39_boot" RESULT_DIR=../perf/results/20260627-ooo-fp-regfile/focused run`：4/4 PASS。
- `make -C npc/rv64 lint`：PASS。
- `make -C npc/rv64 -j2`：PASS。
- `make -C npc/rv64/testbench RESULT_DIR=../perf/results/20260627-ooo-fp-regfile/full-module-testbench run`：100/100 PASS。
- `npc/rv64/testsuites/scripts/npc-rv64-core-regress.sh --skip-module --skip-lint --skip-build --riscv-tests --riscv-suites rv64ui,rv64um,rv64ua,rv64uf,rv64ud --riscv-privileged --log-base npc/rv64/perf/results/20260627-ooo-fp-regfile/core-regress-official`：overall_rc=0，`rv64ui/um/ua/uf/ud/mi/si` 共 133 项 PASS。

## 边界

本轮是 `OooAluFetchCore` 拆分和核级回归切片，不声明完整工业 CPU sign-off。Linux/full-system、formal/property、PPA/timing/CDC/reset/物理实现签核仍未完成。
