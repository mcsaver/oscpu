# RV64 FP FCSR Focused Gate

- `date`: 2026-06-01
- `graph_template`: `rv64gc-userland-loop`
- `source_request`: 继续朝完整 Ubuntu 22.04 / Verilator-first / 后续可流片水准目标推进。
- `goal`: 在不越级声明官方 `/bin/sh` 已通过的前提下，补齐 RV64GC/lp64d 用户态所需的 FCSR/FRM/FFLAGS CSR 软件读改写 focused gate。

## Scope

- In scope：`fflags`、`frm`、`fcsr` 的 CSR read/write、set/clear、immediate set/clear、旧值返回、`fcsr` 与子字段组合/拆分。
- Out of scope：FP 算术自动置 `fflags`、完整 IEEE 754 exception flags、动态 rounding 全矩阵、dynamic linker/libc、NPC 官方 Ubuntu `/bin/sh`、virtio/rootfs、Linux framebuffer/display。
- RTL：本轮不修改 RTL；复用 `CsrFile` 已有 CSR RMW 路径。

## 修改

- 新增 `npc/rv64/tools/fp-fcsr-smoke.S`。
- `npc/rv64/tools/Makefile` 新增 `FP_FCSR_ELF/BIN`、构建规则与 `smoke-fp-fcsr` phony target。

## 验证

| command | result |
| --- | --- |
| `make -C npc/rv64/tools smoke-fp-fcsr` | GOOD TRAP，`cycles=492/commits=88` |
| `make -C npc/rv64/tools smoke-fp-loadstore smoke-fp-fmv-fclass smoke-fp-convert smoke-fp-sqrt` | 全部 GOOD TRAP；分别为 `216/34`、`463/95`、`320/65`、`490/94` |
| `git diff --check` | PASS |

## 结论

`fp-fcsr` focused gate 证明 NPC 当前 FCSR CSR 软件可见路径能支撑 libc/dash 中常见的 CSR RMW 形态；但 full fflags 仍未闭合，因为当前 FP 算术 focused 实现尚未把 invalid/div-by-zero/inexact 等异常标志自动 OR 入 `fflags`。

## 下一步

- 继续在 `rv64gc-userland-loop` 中补 arithmetic exception flags 与动态 rounding 行为。
- 在 F/D 前沿足够后，运行较短窗口的 `smoke-ubuntu-shell-watch` 或先拆 dynamic linker/libc hello gate，避免直接用长跑 `/bin/sh` 掩盖 ISA 根因。
