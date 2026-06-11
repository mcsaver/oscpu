# RV64 FP Compare / Sign-Inject Focused Gate

## 目标

继续推进完整 Ubuntu 22.04 on NPC/Verilator 的 rv64gc/lp64d 用户态前沿，在 `fp-convert` 之后补一层可综合、低风险的 OP-FP 能力：`FSGNJ.{S,D}` 与 `FEQ/FLT/FLE.{S,D}`。本轮不把结果扩写成完整 FPU 或官方 `/bin/sh` 通过。

## RTL 推导摘要

- 需求：支持 sign-inject 与 compare 这两类 Ubuntu libc/动态用户态常见 FP 指令；`FSGNJ` 输出 FPR，`FCMP` 输出 GPR。
- 协议：复用现有 `pending_fp_q` 串行通道，等待 backend drain 后读取已稳定 FPR/GPR；不发 LSU；GPR 结果继续经 ArchRegFile 串行写入口。
- 状态机：不新增状态；decode 进入 pending FP，非 memory 指令直接置 `pending_fp_mem_done_q`，drain-complete 时一次提交。
- 不变量：一次 pending FP 只提交一次；compare 不写 FPR；sign-inject 不写 GPR；single 结果 NaN-boxed；NaN compare 返回 false；本轮不更新 fflags。
- 数据通路：新增 `pending_fp_frs2_value_w`、`fp_sgnj_value`、`fp_compare_value`，扩展 `pending_fp_gpr_value_w` 与 `pending_fp_result_value_w` mux。

## 修改

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `FSGNJ.{S,D}` 与 `FCMP.{S,D}` decode。
  - 新增 sign-inject 与 compare 组合函数。
  - 将 compare 纳入 FP->GPR 串行写路径，sign-inject 纳入 FPR 写路径。
- `npc/rv64/tools/Makefile`
  - 新增 `smoke-fp-compare-sgnj`。
- `npc/rv64/tools/fp-compare-sgnj-smoke.S`
  - 覆盖 double/single sign-inject、compare、zero equality 和 NaN compare false。

## 验证

- `make -C npc/rv64 -j1`: PASS。
- `make -C npc/rv64/tools smoke-fp-compare-sgnj`: GOOD TRAP，`cycles=361`，`commits=65`。
- `make -C npc/rv64/tools smoke-fp-loadstore`: GOOD TRAP，`cycles=216`，`commits=34`。
- `make -C npc/rv64/tools smoke-fp-fmv-fclass`: GOOD TRAP，`cycles=463`，`commits=95`。
- `make -C npc/rv64/tools smoke-fp-convert`: GOOD TRAP，`cycles=320`，`commits=65`。
- `git diff --check`: PASS。

## 边界

- 仍未实现 `fadd/fsub/fmul/fdiv/fsqrt/fmin/fmax`。
- 仍未把 FP 操作产生的 invalid/inexact 等异常接入 fflags。
- 仍不能声明 NPC 官方 Ubuntu `/bin/sh`、dynamic linker 或 rootfs 已通过。
