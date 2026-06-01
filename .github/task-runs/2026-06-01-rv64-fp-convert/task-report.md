# RV64 FP Convert Focused Gate

## 目标

按 Ubuntu 22.04 full-shell 前沿继续推进 RV64GC 用户态 F/D ladder，在不引入 Vivado/FPGA 前置的前提下，用 Verilator focused smoke 固化 `FCVT` 子集能力，并明确不能越级声明官方 `/bin/sh` 已通过。

## RTL 推导

- 需求边界：本轮只覆盖 `FCVT.D.{W,WU,L,LU}` 与 `FCVT.{W,WU,L,LU}.D`，服务 Ubuntu full-shell 中常见 exact/RTZ 转换路径；不实现 FP arithmetic、compare、full fflags 或动态 rounding 全矩阵。
- 协议边界：OP-FP convert 复用现有 `stop_pending`/backend drain 串行 FP 通道；非 memory convert 不发 LSU 请求，FPR->GPR 结果仍走 ArchRegFile 串行写入口。
- 状态机边界：`pending_fp_q` 保存待串行化 FP 指令；convert 进入 pending 后直接标记 `pending_fp_mem_done_q`，drain 完成后一次性写 FPR 或 GPR。
- 一致性边界：FPR->GPR 写回后触发一拍 core-local flush，让 PRF/RenameMap 从 ArchRegFile 恢复；`x0` 不写；本轮 smoke 只声明 exact/RTZ 数值正确。

## 修改

- `npc/rv64/vsrc/ooo/OooAluFetchCore.v`
  - 新增 `FCVT` OP-FP decode、pending result mux 与 int/double helper。
  - 修正 `fclass` 判定必须同时看 `funct7`，避免 `fcvt.w.d ..., rtz` 被误识别为 `fclass`。
  - 修正 drain-complete 后 stale `pending_fp_q`/exit 状态未清的问题，避免旧 FP 重放覆盖后续 `ebreak`。
  - 修正 fast direct JAL lane0/lane1 入 ROB 的 `next_pc` 元数据，使用 jump target 而不是 fallthrough。
- `npc/rv64/tools/Makefile`
  - 新增 `smoke-fp-convert` target。
- `npc/rv64/tools/fp-convert-smoke.S`
  - 覆盖 int-to-double exact case 与 double-to-int RTZ case。

## 验证

- `make -C npc/rv64 -j1`: PASS。
- `make -C npc/rv64/tools smoke-fp-convert`: GOOD TRAP，`cycles=320`，`commits=65`。
- `make -C npc/rv64/tools smoke-fp-loadstore`: GOOD TRAP，`cycles=216`，`commits=34`。
- `make -C npc/rv64/tools smoke-fp-fmv-fclass`: GOOD TRAP，`cycles=463`，`commits=95`。
- `git diff --check`: PASS。

## 边界

- 仍未实现 FP arithmetic、compare、full fflags/dynamic rounding matrix。
- 仍不能声明 NPC 官方 Ubuntu `/bin/sh` 或 rv64gc/lp64d dynamic userland 已通过。
- 下一层应继续补 `fp-arith/compare/full fflags`，再回到 `smoke-ubuntu-shell-watch`。
