# Task Report

## 基本信息

- `task_id`: `2026-06-01-rv64-ubuntu-first-write-syscall`
- `task_slug`: `rv64-ubuntu-first-write-syscall`
- `graph_template`: `rv64-ubuntu-probe-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-01`
- `updated_at`: `2026-06-01`

## 任务目标

- `source_request`: 继续按“完整 Ubuntu 22.04、Verilator-first、尽量真实且后续面向流片”的目标推进，并结合上传文档的 gate 分层避免错判。
- `goal`: 在已证明 `/init` 用户态入口退休之后，判断最早用户态 `write(1, ...)` syscall 是否返回，以及为什么 `[ysyx-init] early-entry` 仍不可见。
- `scope`: `npc/rv64` probe init ELF、host simulation commitwatch、NPC 长跑日志与项目记忆更新。

## 选图说明

- `selected_template`: `rv64-ubuntu-probe-loop`
- `why_this_graph`: 当前仍处在 Ubuntu probe initramfs gate；完整 rootfs、`/bin/sh`、framebuffer/VGA 仍是后续 gate。
- `dynamic_nodes_added`: `first-write-syscall-watch`, `commitwatch-stop-after`
- `why_dynamic_nodes_were_needed`: guest UART 未出现 `[ysyx-init]`，需要把 user entry、syscall 返回和 UART/console 可见性拆成独立证据。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `first-write-address` | `rv64-linux` | completed | `ysyx-ubuntu-init` ELF | `write_all` first `ecall=0x1012c`, return check `0x10130` | `riscv64-linux-gnu-objdump` |
| `commitwatch-stop-after` | `verilator-tapeout` | completed | `NPC_COMMITWATCH_STOP_AFTER=2` | 可在第 N 次匹配后停止，并打印 match 序号 | `make -C npc/rv64 default` PASS |
| `npc-first-write-run` | `rv64-linux` | completed | OpenSBI+Linux+DTB+probe cpio | `/init` 执行后两次 `write_all` 返回点命中 | `cycles=945372045`, `commits=147828189` |
| `uart-visible-check` | `linux-device` | completed | guest log/make out | 无 `[ysyx-init]` 可见输出 | `grep -a "ysyx-init"` 无输出 |
| `memory-update` | `ysyx-coordinator` | completed | 本轮证据 | project/module/known-issues/decisions 更新 | `.github/memory/*` |

## 关键产物

- `artifacts`: `npc/rv64/csrc/cpu/cpu-exec.cpp`
- `logs_or_traces`: `npc/rv64/env/logs/codex-ubuntu-first-write-syscall/`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/known-issues.md`, `.github/memory/decisions.md`

## 当前阻塞点

- `blockers`: Linux `write(1, "[ysyx-init] early-entry\n", 24)` 返回成功，但 guest UART/log 仍没有用户态 marker。
- `missing_dependencies`: 需要继续切分 kernel `sys_write`/TTY/8250 console path，或直接观测 UART THR MMIO/DPI TX event 是否接收到用户态字节。
- `risk_assessment`: 不能再把 `[ysyx-init]` 不可见解释成 `/init` 没执行或 syscall 失败；当前 blocker 更像 Linux console/UART 可见路径或 fd/console 重定向之后的输出呈现问题。

## 下一步建议

1. 加一个 UART TX/THR watch 或 host `npc_uart_event` 侧字节来源 trace，验证用户态写出的 24 字节是否到达 16550 THR。
2. 对 Linux kernel `ksys_write`/`tty_write`/`serial8250_console_write` 或 8250 TX MMIO 地址段做 PC/MMIO watch，区分 syscall/TTY/driver/host capture 四层。

## 模板升级候选

- `repeated_dynamic_subgraph`: `first-write-syscall-watch` 可固定加入 `rv64-ubuntu-probe-loop`。
- `should_promote_to_static_template`: `yes`
- `reason`: 它能稳定把 user entry、write syscall return 和 guest-visible UART gate 分开，避免未来误判。

## 收尾结论

- `final_result`: NPC 已证明 Ubuntu probe `/init` 的前两次 `write(1, ...)` 返回成功；`[ysyx-init]` guest 可见输出仍未闭合。
- `evidence_summary`: `Run /init as init process` 后，commitwatch 在 `write_all+0x10` (`pc=0x10130`) 命中两次，`a0=0x18`、`a2=0x18`、`a5=1`，分别对应 `.rodata` `0x10408` 的 `[ysyx-init] early-entry\n` 和 `0x10450` 的 `[ysyx-init] after-mkdir\n`；第二次匹配后 `exit via commit-watch, code=0, cycles=945372045, commits=147828189`。
- `notes`: `pc=0x1012c` 的 `ecall` 本身未作为普通提交命中，但 `pc=0x10130` 返回点和 `a0=24` 已证明 syscall 返回成功。commitwatch 是 Verilator harness 诊断证据，不是 guest-watch PASS、GOOD TRAP 或完整 Ubuntu shell/rootfs gate。
