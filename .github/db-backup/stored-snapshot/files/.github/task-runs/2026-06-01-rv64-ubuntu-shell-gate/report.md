# Task Report

## 基本信息

- `task_id`: 2026-06-01-rv64-ubuntu-shell-gate
- `task_slug`: rv64-ubuntu-shell-gate
- `graph_template`: `rv64gc-userland-loop`
- `graph_mode`: `static`
- `status`: `completed`
- `owner`: Codex
- `started_at`: 2026-06-01
- `updated_at`: 2026-06-01

## 任务目标

- `source_request`: 按完整 Ubuntu 22.04 / Verilator / 流片水准要求继续配置和校准 agent 环境。
- `goal`: 给官方 Ubuntu `/bin/sh` 建立独立 gate，避免把 syscall-only probe 误判成 rv64gc/lp64d 用户态闭合。
- `scope`: `npc/rv64` Ubuntu Base initramfs 构建脚本、QEMU runner、OpenSBI shell DTB 入口、tools/top-level Makefile。

## 选图说明

- `selected_template`: `rv64gc-userland-loop`
- `why_this_graph`: 官方 Ubuntu riscv64 `/bin/sh` 依赖 rv64gc/lp64d 动态用户态，必须区别于 rv64imac/lp64 probe。
- `dynamic_nodes_added`: 无。
- `why_dynamic_nodes_were_needed`: 不需要。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| shell-gate-config | rv64-linux | completed | Ubuntu Base full cpio, existing probe gate | `qemu-ubuntu-shell-initramfs`, `smoke-ubuntu-shell-watch`, shell DTB/OpenSBI target | `make -C npc/rv64 qemu-ubuntu-shell-initramfs QEMU_TIMEOUT=30s` PASS |
| qemu-reference | rv64-linux | completed | full Ubuntu Base cpio | `/bin/sh -c` marker visible | `[ysyx-sh] /bin/sh -c marker`, `/bin/sh -c exit=0` |
| npc-artifacts | rv64-linux | completed | shell DTB path | `opensbi-npc-ubuntu-shell-initramfs/fw_jump.bin` | `make -C npc/rv64 opensbi-ubuntu-shell-initramfs` PASS |
| fp-frontier | rv64gc-userland | completed | Ubuntu `/bin/dash`, `libc.so.6`, current FP smoke | F/D gap recorded | `smoke-fp-loadstore` PASS; objdump shows `/bin/dash` has `fdiv.d/fcvt/fmv.x.d`, libc has `fmul/fmv/frrm/fsflags/fclass` |

## 关键产物

- `artifacts`:
  - `npc/rv64/env/images/ubuntu2204/ubuntu-22.04-riscv64.cpio` rebuilt as full shell initramfs with `/bin/sh -c` marker.
  - `npc/rv64/tools/build/npc-rv64-ubuntu-shell-initramfs.dtb`.
  - `npc/rv64/env/build/opensbi-npc-ubuntu-shell-initramfs/platform/generic/firmware/fw_jump.bin`.
- `logs_or_traces`:
  - `npc/rv64/env/logs/qemu/ubuntu-shell-initramfs.log` from `qemu-ubuntu-shell-initramfs`, contains `[ysyx-sh] /bin/sh -c marker`.
  - `npc/rv64/tools/build/linux-logs/npc-linux.log` from `smoke-fp-loadstore`, exits GOOD TRAP with `cycles=219`, `commits=34`.
- `linked_memory_updates`:
  - `.github/memory/project-status.md`
  - `.github/memory/modules/npc.md`
  - `.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: NPC 尚未通过 full-shell `[ysyx-sh]` gate。当前 core 只证明 F/D CSR、FPR load/store 和部分 GPR->FPR move；官方 Ubuntu 用户态包含更广 F/D 指令。
- `missing_dependencies`: FPR->GPR move、`fclass`、FP compare、FP arithmetic/convert、rounding/exception flag 语义，以及后续 rootfs/virtio。
- `risk_assessment`: 不能把 QEMU `/bin/sh` PASS 或 NPC syscall-only probe PASS 升级成 NPC 官方 Ubuntu `/bin/sh` PASS。

## 下一步建议

1. 增加并闭合 `fcsr/fmv/fclass` focused gate，优先处理 FPR->GPR move 与 `fclass.{s,d}`。
2. 再推进 `fp-arith-convert`，覆盖 `/bin/dash` 和 `libc.so.6` 中可见的 `fdiv/fmul/fcvt/feq/flt/fle` 路径。
3. 运行 NPC `smoke-ubuntu-shell-watch`，目标 `[ysyx-sh] /bin/sh -c marker`；若失败，用 trapwatch 或 guest SIGILL 日志定位首个真实缺口。

## 模板升级候选

- `repeated_dynamic_subgraph`: full-shell QEMU reference + NPC shell watch + F/D objdump frontier。
- `should_promote_to_static_template`: 是。
- `reason`: 这是 L4 probe 到 L5 Ubuntu shell 的固定防误判门槛。

## 收尾结论

- `final_result`: 已新增官方 Ubuntu Base full-shell gate，并在 QEMU 上证明 `/bin/sh -c` 实际执行；NPC 侧产物已生成，但尚未声明 full shell 通过。
- `evidence_summary`: QEMU full shell marker PASS；默认 QEMU probe marker 仍 PASS；NPC `smoke-fp-loadstore` 仍 GOOD TRAP；shell DTB initrd 范围 `0x84000000..0x87afac00`。
- `notes`: `/bin/dash` 中可见 `fdiv.d/fcvt.* / fmv.x.d`，`libc.so.6` 中可见 `fmul/fmv/frrm/fsflags/fclass/feq/flt/fle`，下一层应按 `rv64gc-userland.instructions.md` 的 ladder 推进。
