# Task Report

## 基本信息

- `task_id`: 2026-06-01-rv64-fp-fmv-fclass
- `task_slug`: rv64-fp-fmv-fclass
- `graph_template`: `rv64gc-userland-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-01
- `updated_at`: 2026-06-01

## 任务目标

- `source_request`: 按完整 Ubuntu 22.04 / Verilator / 流片水准要求继续配置和推进 agent 环境，避免后续错判。
- `goal`: 在 NPC/Verilator 侧闭合 Ubuntu rv64gc/lp64d 用户态 ladder 的 `fcsr/fmv/fclass` 层。
- `scope`: `npc/rv64` OoO FP 串行路径、架构 GPR 串行写回、focused FP smoke gate。

## RTL 推导摘要

1. 需求层：Ubuntu `/bin/dash` 已可见 `fmv.x.d`，`libc.so.6` 已可见 `fclass.*`；只通过 `fp-loadstore` 不足以支撑官方 `/bin/sh`。
2. 协议层：FP 指令作为精确串行边界，必须先停前端并等待 OoO 后端 drain，随后再读取已退休架构 GPR/FPR 并提交副作用。
3. 状态不变量：FPR 写可留在外层 `fpr_q`；FPR->GPR/FCLASS 写整数寄存器时，必须同时更新退休可见 ArchRegFile，并让后端 PRF/RenameMap 与 ArchRegFile 对齐。
4. 数据通路：新增 `FMV.X.{W,D}` 与 `FCLASS.{S,D}` 的 OP-FP raw 检测；`fclass` 组合分类覆盖 zero/subnormal/normal/inf/sNaN/qNaN；GPR 写回经 `OooArchRegFile.serial_write_*`，下一拍 `core_serial_flush_q` 触发 core-local flush，使 PRF 由最新 ArchRegFile 恢复。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| fp-frontier-audit | rv64gc-userland | completed | Ubuntu `/bin/dash`, `libc.so.6`, current FP load/store smoke | 下一个 focused gate 定义为 `fcsr/fmv/fclass` | `/bin/dash` has `fmv.x.d`; libc has `fclass.*` |
| rtl-fp-serialize | verilator-tapeout | completed | current `OooAluFetchCore` serialized FP path | drain 后解析 FP 操作数，修复提前读旧 GPR | `smoke-fp-loadstore` PASS |
| rtl-gpr-commit | verilator-tapeout | completed | FPR->GPR/FCLASS writeback requirement | `OooArchRegFile` serial write + core-local PRF/RenameMap recovery | `smoke-fp-fmv-fclass` PASS |
| focused-gate | rv64gc-userland | completed | `fp-fmv-fclass-smoke.S` | `smoke-fp-fmv-fclass` target | GOOD TRAP, `cycles=463`, `commits=95` |

## 关键产物

- `artifacts`:
  - `npc/rv64/tools/fp-fmv-fclass-smoke.S`
  - `npc/rv64/tools/Makefile` target `smoke-fp-fmv-fclass`
  - `npc/rv64/vsrc/ooo/OooAluFetchCore.v` FP operand/result resolution updates
  - `npc/rv64/vsrc/ooo/OooAluCoreSlice.v`
  - `npc/rv64/vsrc/ooo/OooArchRegFile.v`
- `logs_or_traces`:
  - `make -C npc/rv64 -j1` PASS
  - `make -C npc/rv64/tools smoke-fp-loadstore` GOOD TRAP, `cycles=216`, `commits=34`
  - `make -C npc/rv64/tools smoke-fp-fmv-fclass` GOOD TRAP, `cycles=463`, `commits=95`
  - `git diff --check` PASS
- `linked_memory_updates`:
  - `.github/memory/project-status.md`
  - `.github/memory/modules/npc.md`
  - `.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: NPC 仍未通过 official Ubuntu `/bin/sh` full-shell gate；FP arithmetic/convert/compare/rounding flags 仍未闭合。
- `missing_dependencies`: `fadd/fmul/fdiv/fsqrt/fcvt/feq/flt/fle`、rounding mode/fflags 行为、dynamic linker/libc shell path、后续 virtio/rootfs。
- `risk_assessment`: 不能把 `smoke-fp-fmv-fclass` PASS 扩大解释为完整 RV64GC F/D 或 Ubuntu shell PASS。

## 下一步建议

1. 增加 `fp-arith-convert` focused gate，优先覆盖 `/bin/dash` 与 `libc.so.6` 可见的 `fcvt.*`、`fdiv.d`、`fmul.*`。
2. 覆盖 `feq/flt/fle` 与 rounding/fflags/frrm/fsflags 的组合。
3. 运行 NPC `smoke-ubuntu-shell-watch`，目标 `[ysyx-sh] /bin/sh -c marker`，用首个 SIGILL/trap 或 guest 输出缺口回推下一条指令。

## 收尾结论

- `final_result`: 已闭合 `fcsr/fmv/fclass` 层，并修复 FP 串行路径提前抓取旧 GPR 的 root cause。
- `evidence_summary`: rv64 Verilator build、旧 FP load/store smoke、新 fmv/fclass smoke 与 diff check 均 PASS。
- `notes`: 本次变更继续保持 Verilator 主路径和可综合 RTL 边界，没有引入 host-only core hack；完整 Ubuntu 仍按 gate 分层表述。
