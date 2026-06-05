# NEMU Ubuntu systemd guest-check

## 目标
- 为 `make -C Linux ARCH=riscv64-nemu run` 当前完整 Ubuntu 22.04.5 rootfs 路线补一个可重复自动化 gate。
- 在 guest 内验证 systemd、伪文件系统、TTY、virtio rootfs、timer、proc/syscall 基础路径和 dmesg critical 状态。

## 根因与修复
- 首次 gate 失败时，systemd 还在 `starting`，但主要新根因是 `findmnt` 在 `fcvt.s.d` 上触发 `SIGILL`。
- `nemu/src/isa/riscv64/inst.c` 已补齐官方 RV64F/D `fcvt.s.d` 与 `fcvt.d.s`，避免对 Linux 用户态做特判。
- `Linux/scripts/check-nemu-systemd-guest.sh` 现在拿到 root prompt 后会轮询 systemd 到 `running`，并只把行首真实 `__NEMU_CHECK_FAIL__:` 作为失败标记。
- `nemu/src/device/serial.c` 支持 `NEMU_SERIAL_FIFO`，每次自动化运行可使用独立 FIFO，避免复用 `/tmp/nemu.serial` 污染输入。

## 验证
- `bash -n Linux/scripts/check-nemu-systemd-guest.sh`：PASS。
- `NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)`：PASS。
- `make -C Linux check-nemu-systemd-guest`：PASS。

关键日志：
- `Linux/env/logs/linux-front/riscv64-nemu-systemd-guest-check/console.log`
- 其中可见 `__NEMU_CHECK_SYSTEMD_WAIT__:8:running`、`__NEMU_CHECK_ROOT_SOURCE__:/dev/vda`、`__NEMU_CHECK_PASS__:dmesg-no-critical`、`__NEMU_SYSTEMD_CHECK_DONE__ rc=0`。

## 边界
- 该 gate 说明当前 NEMU 可自动化启动完整 Ubuntu 22.04.5 systemd 并完成基础 guest 内检查。
- 仍不声明 NEMU 已达到 QEMU 级完整虚拟机；virtio/UART/PLIC 仍是当前 Linux bring-up 需要的最小设备模型，后续还要做长期运行、virtio 压力、更多设备和交互语义验证。
