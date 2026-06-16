# NEMU UART RX to Getty Gate

## 目标

让 `make -C Linux ARCH=riscv64-nemu run` 启动到 Ubuntu 22.04.5 systemd 登录门后，NEMU 不只输出 `login:`，还可以把宿主输入经 16550 UART RX 送到 Linux `serial-getty`。

本轮遵循用户更新的优先级：旧 PA/AM `ebreak` 退出协议或实验 gate 与 Linux/system 行为冲突时，以官方 RISC-V/Linux 启动语义为准。

## 根因

旧 `nemu/src/device/serial.c` 只有 UART TX/THRE 子集：

- `UART_RBR` 读固定返回 0。
- `UART_LSR` 固定为 `THRE/TEMT`，没有 `DR`。
- `UART_IIR` 只报告 THRE interrupt，不报告 receiver data available。
- PLIC IRQ1 只由 TX-ready 条件驱动。

因此 Linux 8250/serial-getty 可以打印 `ysyx-ubuntu2204 login:`，但 guest 不可能从串口收到用户名或命令。

## 修改

- `nemu/src/device/serial.c`
  - 增加 4096B RX FIFO。
  - 支持宿主 stdin 和 `/tmp/nemu.serial` FIFO 注入字节。
  - `LSR.DR` 随 RX FIFO 非空置位。
  - 读 `RBR` 消费一个 RX 字节。
  - `IER.RDI` 打开时，`IIR=0x04` 且 PLIC IRQ1 置线。
  - `FCR` bit1 清 RX FIFO。
- `nemu/src/device/device.c`
  - `device_update()` 周期调用 `serial_poll_input()`，保证 guest 睡在中断等待时也能被 UART RX 唤醒。
- `nemu/src/device/Kconfig`
  - 新增 `SERIAL_INPUT_STDIN`，batch 模式默认打开。
  - 已有 `SERIAL_INPUT_FIFO` 现在有实现。
- `nemu/configs/riscv64-linux_defconfig`
- `nemu/configs/riscv64-linux_debug_defconfig`
  - 打开 `CONFIG_SERIAL_INPUT_STDIN=y` 和 `CONFIG_SERIAL_INPUT_FIFO=y`。

## 验证

构建与静态检查：

```sh
make -C nemu NEMU_HOME=$PWD/nemu riscv64-linux_defconfig
make -C nemu NEMU_HOME=$PWD/nemu -j4
make -C nemu NEMU_HOME=$PWD/nemu riscv64-linux_debug_defconfig
make -C nemu NEMU_HOME=$PWD/nemu -j4
make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-systemd
git diff --check
```

完整 Ubuntu rootfs/systemd + UART RX 验证：

```sh
make -C Linux ARCH=riscv64-nemu MAX_CYCLES=7000000000 \
  LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-uart-rx-fifo-login run

printf 'root\n' > /tmp/nemu.serial
```

关键日志：

```text
Started Serial Getty on hvc0
Started Serial Getty on ttyS0
Reached target Login Prompts
ysyx-ubuntu2204 login:
ysyx-ubuntu2204 login: root
```

日志路径：

```text
Linux/env/logs/linux-front/riscv64-nemu-uart-rx-fifo-login/console.log
```

## 边界

本轮证明 ttyS0 RX 到 Linux `serial-getty` 已通。它还不等于完整交互登录 shell：

- 当前 rootfs 的 root 账号/登录策略未闭合，输入 `root` 后 getty 重启回登录提示。
- stdin 入口目前是行缓冲终端语义，不是 QEMU `-nographic` 那种完整 raw terminal/信号转发。
- virtio-blk 仍是最小 bring-up 模型，尚未做 descriptor 压力、错误路径和长期 IO 顺序验证。
- NEMU 仍不能宣称为 QEMU 级完整虚拟机。
