# NEMU UART RX stress gate

## 目标
- 为完整 Ubuntu 22.04.5 的 tty/console 支持补一个 host -> UART RX 的真实突发输入 gate。
- 证明宿主通过 `NEMU_SERIAL_FIFO` 一次性送入几百条 shell 输入行时，NEMU UART/TTY 不会丢行、截断或破坏后续 guest-check 脚本。

## 根因
- 新增 `NEMU_SYSTEMD_UART_RX_STRESS_LINES=512` 后，首次 focused gate 失败。
- 失败日志中出现 `pass: command not found`、`fail: command not found`、`dd: invalid number: ''`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=` 等输入损坏症状。
- 根因是 `UART16550_INGRESS_CAP` 只有 64KiB。host 侧 `cat guest-check.cmd > NEMU_SERIAL_FIFO` 会把 syscall probe base64、guest-check 脚本和新增 512 行 RX stress 一次性送入；Linux guest 还没 drain RBR 前，UART core 的 ingress staging 被填满，旧策略丢弃最早字节，导致 shell 函数和变量定义丢失。

## 修复
- `nemu/include/device/uart16550.h` 将 `UART16550_INGRESS_CAP` 从 64KiB 增大到 1MiB，并注明这是 host/FIFO 自动化突发输入 staging，不改变 guest-visible 16550 RX FIFO 仍为 16B。
- `Linux/scripts/check-nemu-systemd-guest.sh` 新增 `NEMU_SYSTEMD_UART_RX_STRESS_LINES`，默认 512；long gate 默认 768；soak gate 默认 1024。
- guest-check 会生成对应数量的独立 shell 输入行，每行经 UART RX 到 guest shell 后递增计数，最后校验 `__NEMU_UART_RX_STRESS_COUNT__:N/N` 并输出 `uart-rx-command-burst` PASS。
- `perf.tsv` 新增 `uart_rx_stress_lines` 列，便于后续比较不同压力参数。

## 验证
- `gcc -std=c11 -Wall -Wextra -Werror -I nemu/include nemu/tools/uart16550-smoke.c nemu/src/device/uart16550.c -o /tmp/uart16550-smoke && /tmp/uart16550-smoke`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS。
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/Makefile Linux/scripts/check-nemu-systemd-guest.sh nemu/include/device/uart16550.h`：PASS。
- Focused gate：
  `timeout 1400s make -C Linux check-nemu-systemd-guest NEMU_SYSTEMD_CHECK_LOG_DIR=.../riscv64-nemu-systemd-uart-rx-stress-check NEMU_SYSTEMD_SOAK_SECONDS=0 NEMU_SYSTEMD_FS_STRESS_MIB=1 NEMU_SYSTEMD_PROCESS_LOOPS=4 NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=2 NEMU_SYSTEMD_BLOCK_JOB_MIB=1 NEMU_SYSTEMD_UART_RX_STRESS_LINES=512`
  PASS。
- perf：`boot_seconds=239`、`guest_check_seconds=233`、`poweroff_seconds=21`、`total_seconds=493`、`uart_rx_stress_lines=512`。

## 关键 marker
- `__NEMU_UART_RX_STRESS_COUNT__:512/512`
- `__NEMU_CHECK_PASS__:uart-rx-command-burst`
- `__NEMU_CHECK_PASS__:systemd-running`
- `__NEMU_CHECK_PASS__:serial-getty-ttyS0-active`
- `__NEMU_SYSCALL_PROBE_DONE__ rc=0`
- `__NEMU_CHECK_BLOCK_PARALLEL_BYTES__:2097152/2097152`
- `__NEMU_CHECK_FS_STRESS_BYTES__:1048576/1048576`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `__NEMU_SYSTEMD_POWEROFF_BEGIN__`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

## 边界
- 这证明 host FIFO 到 UART RX/ttyS0 shell 的大突发输入已不再丢行。
- guest-visible 16550 RX FIFO 深度仍是 16B；1MiB 是 NEMU host ingress staging，用来弥补仿真自动化和真实 baud/backpressure 之间的模型差异。
- 仍不等同于复杂交互编辑、paste/flow-control、break、modem control 或多串口完整验证。
