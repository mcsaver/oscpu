# NEMU Ubuntu IRQ 可见性 gate

## 目标
- 把 NEMU Ubuntu 22.04.5 的 interrupt 证据从 `/proc/stat intr` 总量推进到 `/proc/interrupts` 明细。
- 固化 Linux 视角下 ttyS0 UART、virtio-blk 和 riscv-timer 的中断可见性，并要求一次 `/dev/vda` direct read 后 virtio-blk IRQ 计数增长。
- 同步复核 UART 架构边界：当前实现保持公共 16550A core、bus profile、`SerialPort` 前端、SoC adapter 和 PLIC IRQ glue，不回到旧 mini UART。

## 实现
- `Linux/scripts/check-nemu-systemd-guest.sh` 新增 `interrupts_table_sum()` 和 `interrupts_match_sum()`，从 `/proc/interrupts` 按 CPU 计数列求和。
- guest-check 在 `/proc/partitions` 与 rootfs 来源检查之间打印 `/proc/interrupts` 明细，并硬检查：
  - 总中断数大于 0。
  - `ttyS0/serial/10000000` 匹配项大于 0。
  - `virtio/vda/10001000` 匹配项大于 0。
  - `/dev/vda` direct read 后总中断数单调，virtio-blk IRQ 计数增长。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `git diff --check -- Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- focused gate：

```sh
timeout 1500s make -C Linux check-nemu-systemd-guest \
  NEMU_SYSTEMD_CHECK_LOG_DIR=/home/lyg/PA/ysyx-workbench/Linux/env/logs/linux-front/riscv64-nemu-irq-visible-check \
  NEMU_SYSTEMD_SOAK_SECONDS=0 \
  NEMU_SYSTEMD_FS_STRESS_MIB=1 \
  NEMU_SYSTEMD_FS_TREE_FILES=16 \
  NEMU_SYSTEMD_PROCESS_LOOPS=4 \
  NEMU_SYSTEMD_BLOCK_PARALLEL_JOBS=2 \
  NEMU_SYSTEMD_BLOCK_JOB_MIB=1 \
  NEMU_SYSTEMD_UART_RX_STRESS_LINES=128
```

- 结果：PASS。
- `perf.tsv`: `boot_seconds=236`、`guest_check_seconds=238`、`poweroff_seconds=20`、`total_seconds=494`、`fs_tree_files=16`、`uart_rx_stress_lines=128`。

## 关键 marker
- `__NEMU_CHECK_INTERRUPTS_TOTAL__:130259`
- `__NEMU_CHECK_IRQ_SERIAL__:2070`
- `__NEMU_CHECK_IRQ_VIRTIO_BLK__:997`
- `__NEMU_CHECK_INTERRUPTS_LINE__: 2:       2090  SiFive PLIC   1 Edge      ttyS0`
- `__NEMU_CHECK_INTERRUPTS_LINE__: 3:       1002  SiFive PLIC   2 Edge      virtio0`
- `__NEMU_CHECK_INTERRUPTS_LINE__: 5:     127674  RISC-V INTC   5 Edge      riscv-timer`
- `__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__:997->1022`
- `__NEMU_CHECK_PASS__:proc-interrupts-total`
- `__NEMU_CHECK_PASS__:irq-serial-visible`
- `__NEMU_CHECK_PASS__:irq-virtio-blk-visible`
- `__NEMU_CHECK_PASS__:proc-interrupts-total-monotonic`
- `__NEMU_CHECK_PASS__:irq-virtio-blk-read-growth`
- `__NEMU_SYSTEMD_CHECK_DONE__ rc=0`
- `syscon-reset: poweroff requested value=0x00005555`
- `HIT GOOD TRAP`

## 边界
- 这证明当前单 hart Ubuntu/systemd 路线下 UART/PLIC、virtio-blk IRQ 与 riscv-timer 对 Linux 可见，并且 virtio-blk direct read 会产生可观测中断增长。
- 这仍不声明 virtio 多队列、malformed descriptor fuzz、多设备异常路径、多小时交互 session 或 QEMU 级完整虚拟机。
