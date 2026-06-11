# NEMU Ubuntu 22.04 systemd running gate

## 目标

让 `make -C Linux ARCH=riscv64-nemu run` 在 NEMU 上启动完整 Ubuntu 22.04.5 rootfs，并从登录门推进到可自动化验证的 ttyS0 root shell 与 systemd `running`。

本轮继续遵循用户要求：当旧 PA/AM `ebreak` 退出协议或其它实验 gate 与 Linux/system 行为冲突时，以官方 RISC-V ISA/privileged 语义和启动 Linux 为准。

## 根因

本轮从“login prompt 可见、RX 到 getty”之后继续分层定位，实际闭合了四类问题：

- rootfs merged-/usr 兼容缺口：`agetty` 默认执行 `/bin/login`，root 账户 shell 是 `/bin/bash`，PAM 从 `/lib/riscv64-linux-gnu/security` 查模块；这些路径缺失会让 autologin/getty 循环或报 `Module is unknown`。
- systemd 设备/维护任务缺口：不存在的 `hvc0` 会被 systemd-getty-generator 拉起并等待，Ubuntu 的 e2scrub/systemd 路径需要 `/sbin/e2scrub_all` 与 kernel loop device。
- NEMU RV64D 官方指令缺口：`dbus-daemon` 在 `fmadd.d fa5,fa5,fs0,fa4` 处 SIGILL，说明解释器缺 fused multiply-add/sub，而 D-Bus 是 systemd running 的正常依赖。
- 早前 gate 仍需保留结论：Linux 路线必须优先官方 ISA 语义，不能用 PA/AM `ebreak` 或 guest 退出协议覆盖系统软件的真实行为。

## 修改

- `Linux/scripts/build-ubuntu-rootfs.sh`
  - 增加 ttyS0 root autologin drop-in。
  - 默认 mask 不存在的 `hvc0` getty。
  - 在 sudo/debootstrap 与 fakeroot/Ubuntu Base 两条路径中补齐 `/bin/login`、`/bin/bash`、`/lib/riscv64-linux-gnu/security`、`/sbin/e2scrub_all`、`/sbin/e2scrub` symlink。
- `Linux/scripts/check-ubuntu-rootfs.sh`
  - 严格 systemd check 增加 login/bash/PAM/e2scrub/hvc0 mask 检查。
- `Linux/scripts/build-linux.sh`
  - 恢复 `CONFIG_BLK_DEV_LOOP=y`，避免破坏 Ubuntu e2scrub/systemd 正常路径。
- `nemu/src/isa/riscv64/inst.c`
  - 按官方 RV64F/D 增加 `OPC_MADD/MSUB/NMSUB/NMADD` decode。
  - 实现 `fmadd/fmsub/fnmsub/fnmadd.{s,d}`。
  - `misa` 按 `CONFIG_RISCV_EXT_F/D` 声明 F/D。

## 验证

构建与静态检查：

```sh
bash -n Linux/scripts/build-ubuntu-rootfs.sh Linux/scripts/check-ubuntu-rootfs.sh Linux/scripts/build-linux.sh
make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-systemd
NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu make -C nemu -j$(nproc)
git diff --check
```

完整运行：

```sh
make -C Linux ARCH=riscv64-nemu MAX_CYCLES=9000000000 \
  LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-systemd-running-final run
```

最终日志证据：

```text
root@ysyx-ubuntu2204:~#
uid=0(root) gid=0(root) groups=0(root)
PRETTY_NAME="Ubuntu 22.04.5 LTS"
Linux ysyx-ubuntu2204 6.6.0 #14 Fri Jun  5 09:55:29 CST 2026 riscv64 riscv64 riscv64 GNU/Linux
systemctl is-system-running -> running
systemctl --failed -> 0 loaded units listed.
systemctl list-jobs -> No jobs running.
```

挂载与 rootfs 兼容检查在 guest 中也通过：

```text
MOUNT_OK:/dev
MOUNT_OK:/proc
MOUNT_OK:/sys
MOUNT_OK:/run
MOUNT_OK:/dev/pts
MOUNT_OK:/dev/shm
MOUNT_OK:/sys/fs/cgroup
/bin/bash -> ../usr/bin/bash
/bin/login -> ../usr/bin/login
/etc/systemd/system/serial-getty@hvc0.service -> /dev/null
/lib/riscv64-linux-gnu/security -> ../../usr/lib/riscv64-linux-gnu/security
/sbin/e2scrub_all -> ../usr/sbin/e2scrub_all
```

`dmesg | grep -i -E 'unhandled signal 4|illegal|sigill'` 在最终验收窗口没有输出。

日志路径：

```text
Linux/env/logs/linux-front/riscv64-nemu-systemd-running-final/console.log
```

## 边界

这次闭合的是 NEMU 上 Ubuntu 22.04.5 rootfs、systemd running、ttyS0 root shell gate。当前 NEMU 仍是最小 virtio-blk/UART/PLIC Linux bring-up 平台，不声明 QEMU 级完整虚拟机。

后续若继续向 QEMU 靠近，应单独做 virtio descriptor/ordering/压力测试、终端 raw/信号语义、长期 IO 与多设备组合压力，而不是把本轮 systemd running gate 外推成完整设备模型签核。
