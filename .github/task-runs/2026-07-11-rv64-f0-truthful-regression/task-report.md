# 任务报告

- `task_id`: 2026-07-11-rv64-f0-truthful-regression
- `task_slug`: rv64-f0-truthful-regression
- `parent_task_id`: 2026-07-11-rv64-200mhz-program
- `profile`: npc-dev
- `status`: pass
- `rtl_changed`: true
- `goal_complete`: true（仅 F0；整体“完整功能 + 物理 200 MHz”仍未完成）

## Objective

恢复 module TB、AM cpu-tests 与 core-regress 的结果真实性，刷新三个陈旧 sequencer
TB 合同，并修复 FP 的 GPR 目的 completion 未经目的寄存器域资格便进入 FPR
busy/bypass/wakeup/write 路径的问题。

## Result

- module runner 现在同时检查 compile rc、simulation rc、TB 自身精确 PASS marker、失败
  marker、非零 error count 与非零/表达式 `$finish(...)`；外层 `[RESULT] PASS` 不能冒充
  TB 自身成功。
- AM 聚合器拒绝 FAIL、缺项、重复项、未知项与损坏行，`run`/`c` 保存并上传 checker rc。
- `tb_ooo_control_commit_sequencer`、`tb_ooo_pending_system_sequencer`、
  `tb_ooo_stop_pending_sequencer` 与 `tb_ooo_control_flush_sequencer` 已按 current RTL
  合同更新，失败出口统一为 `$fatal(1, ...)`。
- `OooFpBackend` 以唯一资格
  `fp_fpr_complete_w = fp_result_wb_valid_w && fp_result_wb_frd_w` 驱动 FPR 域；ROB/GPR
  completion 保留通用 valid。原 PC `0x80000120` 的 FSQRT/FMV 链 Difftest 分歧消失。

## Commits

- `415dd27e7` / `86a7b758f`: module result checker 与 source parser；
- `f57c26846`: module Makefile 真实 rc 传播；
- `d75d30caa`: AM 聚合结果真实 rc 传播；
- `ab99e7a40`: sequencer TB current-contract 刷新；
- `873f9b13f`: FP completion 目的寄存器域资格修复。

提交均使用精确路径范围；进入任务前已暂存的删除/重命名以及其他工作树改动未混入上述提交。

## Verification

| Gate | Result | Raw evidence |
| --- | --- | --- |
| module checker unit/integration | 17/17 PASS, rc=0 | `evidence/check-tb-result-unittest.log` |
| AM checker unit | 11/11 PASS, rc=0 | `evidence/check-am-results-unittest.log` |
| focused FP | 3/3 PASS | reviewer/task evidence + committed TB |
| full module | 86/86 PASS, failed=0, rc=0 | `evidence/module-testbench-summary.log`, `evidence/module-testbench/logs/` |
| RTL style / contract / lint | PASS / 34>=20 / PASS | `evidence/check-rtl-style.log`, `check-contract.log`, `lint-default.log` |
| FP system counterexample | Difftest ON, GOOD TRAP, 3179 commits, rc=0 | `evidence/am-fp-difftest-probe-green.log` |
| full AM | 59/59 PASS, rc=0 | `evidence/am-59-full.log` |
| core-regress | module/lint/build/AM PASS, overall_rc=0 | `evidence/core-regress/latest/{summary,status}.txt` |
| official riscv-tests | 177/177 PASS, 177 builds PASS | `evidence/core-regress/latest/status.txt` |
| independent review | Critical=0, Important=0, Ready=Yes | subagent review recorded in task handoff |
| npc-dev workflow | PASS（final closeout） | `../2026-07-11-rv64-f0-closeout-final-npc-dev/` |
| strict guard | agent-system PASS + final npc-dev PASS, rc=0 | `evidence/strict-guard-final.log` |

## Configuration and provenance

- 验证使用仓库 Verilator `5.051 devel`；系统 Verilator `5.020` 不支持 current
  `OOO_ASSERT` 路径中的 `PROCASSINIT` lint code，因此系统工具的原始失败没有被当成 RTL 失败。
- Difftest reference 使用本仓库 `nemu/build/riscv64-nemu-interpreter-so`；完整 AM 与定向
  FP 证据均明确打印 `Difftest: ON`。
- 进入任务、定向测试恢复后、AM 全量恢复后与 core-regress 后的 NPC 配置三件套哈希一致：
  - `.config`: `cb2cad6fba91f5db9be941ab72e107937c44f9b661d1a1d2b59e93204564f05d`
  - `include/generated/autoconf.h`: `eae3f78ce06757a174290a52490d48a1bc52cee0d1c8045c523b19a20772f7bc`
  - `include/config/auto.conf`: `0c77f306d14b0962fc49cffd4f845b88c1f30646a1da7172387a8487f15f827b`

## Remaining scope

F0 只关闭可信回归地基。F1 的接口正确性合同、F2 的 ISA/特权范围证明、F3 的新鲜
Linux/rootfs 证明，以及 T0-T4 的 5 ns pre-layout 到物理 200 MHz 闭合仍是 parent program
的活动范围；不得把本报告解释为整体目标完成。
