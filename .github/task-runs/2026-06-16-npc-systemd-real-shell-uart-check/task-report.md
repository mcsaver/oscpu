# Task Report

## 基本信息

- `task_id`: `2026-06-16-npc-systemd-real-shell-uart-check`
- `task_slug`: `npc-systemd-real-shell-uart-check`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `codex`
- `started_at`: `2026-06-16`
- `updated_at`: `2026-06-16`

## 任务目标

- `source_request`: 继续推进 NPC 到完整 Ubuntu 22.04，并同步开发环境证据链。
- `goal`: 把 NPC Ubuntu 22.04 gate 从 wrapper/banner 阶段推进到真实 PID1 systemd 管理的 guest-side 检查。
- `scope`: `Linux/scripts/build-ubuntu-rootfs.sh`、`Linux/scripts/check-ubuntu-rootfs.sh`、`Linux/scripts/check-npc-systemd-guest.sh`、`Linux/Makefile`、本 task-run 证据。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: 本轮目标围绕 RV64 NPC、Ubuntu 22.04 rootfs、systemd PID1 与 UART/guest-watch gate。
- `dynamic_nodes_added`: `npc-systemd-autocheck-real-marker`, `npc-systemd-uart-ping-slow-loop2`, `npc-systemd-tty-reader-loop`, `npc-systemd-tty-reader-access-trace`
- `why_dynamic_nodes_were_needed`: 旧 gate 会被 wrapper preflight marker 或 Ubuntu banner 误判，需要新增真实 systemd oneshot 的独立 marker；UART 输入链路还需要 byte-pop、guest shell 执行、guest tty reader、UART access/IRQ trace 分层诊断。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| rebuild-rootfs | codex | pass | systemd-minimal rootfs build | rootfs static checks pass | `rebuild.rc=0`; `make -C Linux ARCH=riscv64-npc check-ubuntu-rootfs-systemd` PASS |
| ready-marker-long | codex | fail-diagnostic | UART command mode, wait `__NPC_CONSOLE_SHELL_READY__` | shell ready marker appears, command injection still corrupted/missing | `ready-marker-long.rc=2` |
| systemd-autocheck-real-marker | codex | pass | autocheck mode, wait `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0` | PID1 systemd starts service and guest-side checks pass | `autocheck-real-marker.rc=0` |
| npc-systemd-uart-ping-slow-loop2 | codex | fail-diagnostic | preserved minimal UART ping after `__NPC_CONSOLE_SHELL_READY__`, 100000-cycle byte gap | wait matched and all 94 bytes popped, but no guest ping marker before 900M-cycle abort | `uart-ping-slow-loop2.rc=2`; evidence `evidence/npc-systemd-uart-ping-slow-loop2/` |
| npc-systemd-tty-reader-loop | codex | fail-diagnostic | independent diagnostic rootfs with `ysyx-npc-tty-reader.service`, preserved 24-byte ping after `__NPC_TTY_READER_READY__` | reader service started and all bytes popped, but blocking `read` never returned before 900M cycles | `tty-reader-loop.rc=1`; evidence `evidence/npc-systemd-tty-reader-loop/` |
| npc-systemd-tty-reader-access-trace | codex | fail-diagnostic | reused tty-reader rootfs, UART access trace and IRQ trace enabled, 24-byte ping after `__NPC_TTY_READER_READY__` | each byte raised UART/PLIC IRQ and was read by Linux from RBR offset 0 with exact low-byte data, but reader still emitted no line/done marker before 700M cycles | `tty-reader-access-trace.rc=1`; evidence `evidence/npc-systemd-tty-reader-access-trace/` |

## 关键产物

- `artifacts`: updated rootfs/check scripts, `run-autocheck-real-marker.sh`, `run-guest-uart-ping-slow.sh`, and `run-guest-tty-reader.sh`
- `logs_or_traces`: `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-autocheck-real-marker/console.log`; `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-uart-ping-slow-loop2/run.log`; `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-loop/run.log`; `.github/task-runs/2026-06-16-npc-systemd-real-shell-uart-check/evidence/npc-systemd-tty-reader-access-trace/run.log`
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`

## 当前阻塞点

- `blockers`: UART root shell command injection still does not execute after `__NPC_CONSOLE_SHELL_READY__`. The slow minimal ping proved host-side release and byte-pop are working (`pop=1..94`). The independent tty reader proved the issue is below bash foreground/controlling-TTY setup, and the access/IRQ trace now proves the UART/PLIC/8250 RBR path is working: every injected byte raised IRQ and was read from RBR offset 0 with the expected low byte. The remaining blocker is below Linux 8250 RX consumption, likely tty line discipline / termios / reader wakeup or competing console ownership.
- `missing_dependencies`: Full Ubuntu completion still needs later sysinit/multi-user/root shell or stronger service graph coverage with generators restored.
- `risk_assessment`: Current PASS is a staged systemd early-autocheck gate. It proves PID1 systemd can run an NPC-provided oneshot on ttyS0, but it deliberately disables systemd generators and does not prove a complete Ubuntu 22.04 login/session.

## 下一步建议

1. Debug the Linux tty consumer side: try a raw/non-canonical reader (`stty raw -echo min 1 time 5`, `dd bs=1 count=N`, or a tiny C reader) and log termios/fd/session state before blocking.
2. Audit `ysyx-npc-tty-reader.service` ownership of `/dev/ttyS0` versus console/getty/shell units: test `StandardInput=tty-force`, `TTYReset=`, `TTYVHangup=`, `TTYVTDisallocate=`, and whether another process drains the same tty.
3. If raw reader still receives nothing despite RBR reads, inspect the Linux 8250 -> tty flip buffer / line discipline wakeup path rather than the UART RTL or PLIC first.
4. Keep the distinct `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0` marker as the completion signal for systemd-managed checks; do not reuse the wrapper `__NPC_SYSTEMD_CHECK_DONE__ rc=0` marker.

## 模板升级候选

- `repeated_dynamic_subgraph`: wrapper preflight -> systemd PID1 banner -> early oneshot autocheck -> UART command injection
- `should_promote_to_static_template`: `yes`
- `reason`: NPC Ubuntu progress now needs separate gates for wrapper, PID1, service execution, UART input, and later sysinit; collapsing them into one marker caused false positives.

## 收尾结论

- `final_result`: PASS for real PID1/systemd early autocheck on NPC Ubuntu 22.04 rootfs.
- `evidence_summary`: Latest run matched `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0`; console shows `systemd 249.11-0ubuntu3.21`, `Welcome to Ubuntu 22.04.5 LTS`, `Started YSYX NPC automated root console shell`, `__NPC_CONSOLE_SHELL_READY__`, `__NPC_CHECK_UNAME__:riscv64`, `__NPC_CHECK_SYSTEMD_STATE__:pid1-systemd`, and guest-watch exit at `cycles=672770774`, `commits=382891061`. Follow-up static readiness `make -C Linux ARCH=riscv64-npc check-ubuntu-rootfs-systemd` also passed and checked the autocheck done marker plus early ttyS0 ordering.
- `followup_diagnostic`: Minimal UART ping `npc-systemd-uart-ping-slow-loop2` waited for `__NPC_CONSOLE_SHELL_READY__`, released input at `cycle=610235789` / `commit=353017335`, and popped all 94 bytes through `cycle=619535789` / `commit=357015048`. No `__NPC_UART_PING_BEGIN__` or `__NPC_UART_PING_DONE__ rc=0` guest output appeared; the run hit `cycles=900000000`, `commits=489409228`, `simulation frequency=242123 inst/s`, and `run.rc=2`.
- `followup_tty_reader`: Diagnostic rootfs `npc-systemd-tty-reader-loop` built and statically checked an independent `ysyx-npc-tty-reader.service`. Runtime reached `Started YSYX NPC ttyS0 input reader diagnostic`, printed `__NPC_TTY_READER_READY__`, released input at `cycle=630481653` / `commit=363595928`, popped all 24 bytes through `cycle=632781653` / `commit=364613617`, and still completed `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0`. No `__NPC_TTY_READER_LINE__` or `__NPC_TTY_READER_DONE__ rc=0` appeared; the run hit `cycles=900000000`, `commits=493735689`, `simulation frequency=250089 inst/s`, and `run.rc=1`.
- `followup_access_trace`: Reused tty-reader image `npc-systemd-tty-reader-access-trace` with `NPC_UART_ACCESS_TRACE=1`, `NPC_IRQ_TRACE=1`, min commit `340000000`, 100000-cycle byte gap, and 700M-cycle budget. The wait released at `cycle=669940140` / `commit=371798789`; host popped all 24 bytes through `cycle=672240140` / `commit=372773436`. UART access trace showed matching RBR reads at offset `0x000`, including low bytes `0x5f 0x5f 0x4e ... 0x0a`, and IRQ trace showed UART IRQ + PLIC IRQ assertion/clear around each byte. The systemd autocheck still reached `__NPC_SYSTEMD_AUTOCHECK_DONE__ rc=0`, but no tty reader line/done marker appeared; the run hit `cycles=700000000`, `commits=386235726`, `simulation frequency=232740 inst/s`, and `run.rc=1`.
- `notes`: This is not full Ubuntu 22.04 completion. It is reliable evidence that the check ran under systemd PID1 rather than in the wrapper before `exec /lib/systemd/systemd`; the UART diagnostics now narrow the remaining command-injection issue to Linux tty line discipline / process read wakeup / console ownership after 8250 RBR consumption, not bash foreground setup, host command-file loading, wait matching, byte pacing, UART IRQ, PLIC IRQ, or RBR data visibility.
