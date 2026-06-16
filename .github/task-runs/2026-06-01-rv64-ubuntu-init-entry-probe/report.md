# Task Report

## 基本信息

- `task_id`: `2026-06-01-rv64-ubuntu-init-entry-probe`
- `task_slug`: `rv64-ubuntu-init-entry-probe`
- `graph_template`: `rv64-ubuntu-probe-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-01`
- `updated_at`: `2026-06-01`

## 任务目标

- `source_request`: 继续按“完整 Ubuntu 22.04、Verilator-first、尽量真实且后续面向流片”的目标推进，并结合既有 agent 环境避免 future misjudgment。
- `goal`: 判断 NPC 已到 `/init` handoff 后，是否真正退休 Ubuntu probe `/init` 用户态入口指令。
- `scope`: `npc/rv64` probe init、host simulation commitwatch、QEMU/NPC 分层验证与项目记忆更新。

## 选图说明

- `selected_template`: `rv64-ubuntu-probe-loop`
- `why_this_graph`: 当前仍处在 Ubuntu probe gate，不是完整 rootfs/shell gate。
- `dynamic_nodes_added`: `init-early-marker`, `commitwatch-stop`
- `why_dynamic_nodes_were_needed`: guest UART 没有出现 early marker，需要提交级 PC 证据把用户态入口和 first syscall/output 路径拆开。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `init-early-marker` | `rv64-linux` | completed | `ysyx-ubuntu-init.c` | `_start` 最前 `early-entry`、`after-mkdir`、`after-mount` 标记 | QEMU 同镜像打印三段 marker |
| `image-rebuild` | `rv64-linux` | completed | init source、platform DTB | rebuilt cpio/DTB/OpenSBI embedded FDT | `make -C npc/rv64/tools ubuntu-initramfs-dtb` PASS；`make -C npc/rv64 opensbi-ubuntu-initramfs` PASS |
| `qemu-reference` | `rv64-linux` | completed | 同一 initramfs/DTB | Ubuntu probe reference | QEMU 打印 `early-entry/after-mkdir/after-mount` 与 Ubuntu 22.04.5 os-release |
| `commitwatch-stop` | `verilator-tapeout` | completed | `/init` LOAD range `0x10000..0x10658` | `COMMIT WATCH MATCH` | NPC 命中 `_start=0x10292`，`cycles=944336698/commits=147691154` |
| `memory-update` | `ysyx-coordinator` | completed | 本轮证据 | project/module/known-issues/decisions 更新 | `.github/memory/*` |

## 关键产物

- `artifacts`: `npc/rv64/tools/ysyx-ubuntu-init.c`, `npc/rv64/csrc/cpu/cpu-exec.cpp`
- `logs_or_traces`: `npc/rv64/env/logs/codex-qemu-early-init-check/`, `npc/rv64/env/logs/codex-ubuntu-early-entry-watch/`, `npc/rv64/env/logs/codex-ubuntu-init-commitwatch/`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/known-issues.md`, `.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: NPC 仍未通过 `[ysyx-init] early-entry` guest-watch。
- `missing_dependencies`: first user `ecall`/sys_write/console path 的更窄提交或 syscall trace。
- `risk_assessment`: 已排除“没有进入用户态”这一层；下一步若继续只看 UART 字符串，仍可能把 syscall/path 问题误判为启动问题。

## 下一步建议

1. 对 `/init` `_start -> putstr_stdout -> write_all -> ecall` 地址段做更窄 commitwatch，必要时增加 user `ecall` trap/syscall 参数日志。
2. 对 Linux `do_trap_ecall_u`/`sys_write`/`tty_write`/`serial8250_console_write` 路径做 PC watch，切分 syscall 是否进入、返回和 UART 输出是否发生。

## 模板升级候选

- `repeated_dynamic_subgraph`: `commitwatch-stop` 可作为 Linux probe debug 的固定诊断节点。
- `should_promote_to_static_template`: `yes`
- `reason`: 它能稳定区分 user-entry、first syscall 和 guest-output gate，避免把可见性问题误判为启动失败。

## 收尾结论

- `final_result`: NPC 已退休 Ubuntu probe `/init` 用户态入口；完整 Ubuntu guest 输出仍未闭合。
- `evidence_summary`: QEMU 同镜像打印 `early-entry/after-mkdir/after-mount`；NPC 到 `Run /init as init process` 后 commitwatch 命中 `_start=0x10292`，`exit via commit-watch, code=0, cycles=944336698, commits=147691154`。
- `notes`: `COMMIT WATCH MATCH` 是 Verilator harness 诊断证据，不是 GOOD TRAP，也不是 `ubuntu-probe-visible`。
