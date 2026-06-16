# RV64 Ubuntu post-write UART trace

## 目标

把 RV64 Ubuntu probe 当前 blocker 从“用户态 `write()` 返回成功但 guest 输出不可见”继续下切，确认是否只是 commitwatch 退出太早，或用户态输出确实没有到达 UART TX/DPI host capture。

## 改动

- `npc/rv64/csrc/cpu/cpu-exec.cpp`
  - 新增 `NPC_COMMITWATCH_POST_CYCLES`。
  - `NPC_COMMITWATCH_STOP[_AFTER]` 达成后若配置 post cycles，则先 armed post window，继续运行到 deadline；期间仍允许 `NPC_GUEST_EXPECT` 提前命中。
  - commitwatch 日志保留 `match=N`、`a6/a7` 和 post-window 退出证据。
- `npc/rv64/csrc/dpi.c`
  - 新增 `NPC_UART_TX_TRACE=1`。
  - 支持 `NPC_UART_TX_TRACE_MIN_COMMIT` 和 `NPC_UART_TX_TRACE_LIMIT`，在 `npc_uart_event()` 收到 `tx_valid` 时记录 cycle/commit/data/char。
  - 该能力只在 DPI/Verilator host 层生效，不改变 RTL UART 可综合逻辑。

## 验证

- `make -C npc/rv64 default`：PASS。
- 短跑 UART trace smoke：
  - 命令要点：`NPC_UART_TX_TRACE=1 NPC_UART_TX_TRACE_LIMIT=8 make -C npc/rv64/tools smoke-ubuntu-probe-watch ... UBUNTU_PROBE_EXPECT="OpenSBI v1.8" UBUNTU_INITRAMFS_MAX_CYCLES=5000000`
  - 结果：PASS，trace 记录 CR/LF/`OpenSB...`，`GUEST EXPECT MATCH`，证明 UART trace/log/guest-watch 链路有效。
- 长跑 post-write 诊断：
  - 命令要点：`NPC_COMMITWATCH_START=0x10130 NPC_COMMITWATCH_END=0x10130 NPC_COMMITWATCH_STOP=1 NPC_COMMITWATCH_STOP_AFTER=2 NPC_COMMITWATCH_POST_CYCLES=20000000 NPC_UART_TX_TRACE=1 NPC_UART_TX_TRACE_MIN_COMMIT=147700000 NPC_UART_TX_TRACE_LIMIT=256 make -C npc/rv64/tools smoke-ubuntu-probe-watch ... UBUNTU_PROBE_EXPECT=ysyx-init UBUNTU_INITRAMFS_MAX_CYCLES=980000000`
  - 日志目录：`npc/rv64/env/logs/codex-ubuntu-postwrite-uart-trace/`
  - 到达 `Run /init as init process`。
  - `pc=0x10130` 返回检查点共命中 7 次，均为 `a7=0x40` (`write`)。
  - 前三次分别对应 `early-entry`、`after-mkdir`、`after-mount` 24B marker；后续对应 console banner、`/etc/os-release` header、os-release 正文块和 alive 句子。
  - post window armed 后继续运行 20,000,000 cycles，最终 `exit via commit-watch, code=0, cycles=965372044, commits=151539191`。
  - `uart-trace tx=` 计数 0，`[ysyx-init]` 计数 0，guest-watch 计数 0。

## 结论

当前 blocker 已不应再描述为 `/init` 未执行、用户态入口未退休、或 first syscall 失败。NPC 已进入 Ubuntu probe `/init`，并且多次 `write()` 返回成功；但在返回后的 20M cycles 窗口内，用户态输出没有到达 DPI 层 UART TX。

下一步优先切分 Linux `sys_write` 返回后到 UART THR 写入之间的路径：fd 1 与 `/dev/console`、TTY/console queue、`serial8250_tx_chars`、AXI-Lite UART THR MMIO、PLIC/THRE 触发和 `tx_valid`。完整 Ubuntu `/etc/os-release`、官方 `/bin/sh` 和 rootfs shell 仍未在 NPC 上闭合。
