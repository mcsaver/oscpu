# NEMU rootfs stage1/init 任务报告

## 目标

继续把 `make -C Linux ARCH=riscv64-nemu run` 的 Ubuntu 22.04 rootfs 路线从“能挂载 rootfs”推进到更完整的 stage1/init 边界，并保留后续 systemd gate 的可诊断入口。

## 结果

- `Linux/scripts/build-ubuntu-rootfs.sh` 的 rootfs `/init` 已把 `[ysyx-rootfs] stage1 begin` 放到第一条 shell 命令，后续按顺序准备 `/dev`、`/proc`、`/sys`、`/run`、`/dev/pts`、`/dev/shm`、`/sys/fs/cgroup`，并打印每个 mount 阶段 marker。
- `/etc/fstab` 已包含 devtmpfs、proc、sysfs、tmpfs `/run`、devpts、tmpfs `/dev/shm`、cgroup2。
- `/init` 保留 `ysyx_init=systemd|auto` 检测：若镜像中有 `/lib/systemd/systemd`、`/usr/lib/systemd/systemd`、`/sbin/init` 或 `/usr/sbin/init`，可尝试 exec；当前 fakeroot Ubuntu Base 镜像没有 systemd binary。
- 新增 `UBUNTU_ROOTFS_PROBE=1` opt-in 静态 PID1 probe，默认不安装，避免改变普通 rootfs ext4 布局。
- 修复 `Linux/scripts/build-opensbi.sh` 的 no-PMU 构建：`OPENSBI_DISABLE_PMU=1` 现在通过 `ysyx_nopmu_defconfig` 输入 OpenSBI Kconfig，最终 `.config` 可验证 `# CONFIG_SBI_ECALL_PMU is not set`。
- 后续改为静态 PID1 C 版本 `Linux/tools/ysyx-rootfs-init.c`，并加入 breadcrumbs：`static stage1 begin`、`mount proc`、`read cmdline`、`systemd gate checked`、`exec /bin/sh fallback`。shell fallback 暂时跳过 sysfs，systemd gate 仍保留完整 pseudo-fs 挂载。
- 新增 NEMU debug 配置 `nemu/configs/riscv64-linux_debug_defconfig`，`Linux/Makefile` 支持 `NEMU_DEFCONFIG=...` 切换；debug 配置保留 syscall trace 和 PLIC IRQ trace，关闭 Etrace。
- 按官方 RV64F/D OP-FP 补齐 `fmv.{w,d}.x`、`fmv.x.{w,d}`、`fclass.{s,d}`、`fsgnj/fsgnjn/fsgnjx.{s,d}`，用于继续推进 Ubuntu 动态用户态。
- 新增 rootfs readiness 检查：`Linux/scripts/check-ubuntu-rootfs.sh` 使用 `debugfs` 检查 ext4 镜像中的 `/init`、`/bin/sh`、`/etc/os-release` 和 systemd 候选入口；`Linux/Makefile` 提供 `check-ubuntu-rootfs` 与 `check-ubuntu-rootfs-systemd`。
- `Linux/scripts/build-ubuntu-rootfs.sh` 新增 `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1`；当前缺 sudo+debootstrap+qemu-riscv64-static 时，脚本会拒绝用 Ubuntu Base + fakeroot 生成 shell-only rootfs 冒充 systemd-ready 镜像。
- 按用户最新约束，把 NEMU RV32/RV64 非 AM system `ebreak/c.ebreak` 从旧 PA 退出协议收窄为官方 `CAUSE_BREAKPOINT` trap；AM/裸机目标仍保留 `NEMUTRAP`。

## 验证证据

- `bash -n Linux/scripts/build-ubuntu-rootfs.sh && bash Linux/scripts/build-ubuntu-rootfs.sh` PASS。
- `debugfs -R "stat /ysyx-rootfs-probe" Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64.ext4` 显示默认镜像中该文件不存在。
- `fdtget Linux/build/npc-rv64-rootfs.dtb /chosen bootargs` 输出 `console=ttyS0,115200n8 earlycon=sbi loglevel=8 ignore_loglevel root=/dev/vda rw init=/init`。
- `grep CONFIG_SBI_ECALL_PMU Linux/env/build/opensbi-nemu-rootfs/platform/generic/kconfig/.config` 输出 `# CONFIG_SBI_ECALL_PMU is not set`。
- `timeout 950s make -C Linux ARCH=riscv64-nemu MAX_CYCLES=8000000000 LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-rootfs-default-restored-8b run` PASS/按预算停止；日志出现：
  - `virtio_blk virtio0: [vda] 4194304 512-byte logical blocks`
  - `EXT4-fs (vda): mounted filesystem ...`
  - `VFS: Mounted root (ext4 filesystem) on device 254:0`
  - `Run /init as init process`
  - 未在 8B 预算内出现 `[ysyx-rootfs] stage1 begin`
- `riscv64-nemu-rootfs-syscall-trace-12b`：syscall trace 显示静态 PID1 完成 `mount(proc)`、`read(/proc/cmdline)`，并到 `[ysyx-rootfs-sh] /bin/sh -c marker`；随后 `/bin/sleep` 触发 user illegal，kernel `badaddr/stval=0xf2000453`，反汇编为 `fmv.d.x fs0,zero`。
- `riscv64-nemu-rootfs-shell-skip-sysfs-fmvd-14b`：补 `FMV.D.X` 后 performance 路线再次到 shell marker；下一条 user illegal 为 `0x228404d3`，反汇编为 `fmv.d fs1,fs0`，即 `fsgnj.d` 伪指令。
- `riscv64-nemu-rootfs-irq-trace-fsgnj-12b`：补 `FSGNJ.{S,D}` 后，debug IRQ trace 显示 PLIC IRQ1/IRQ2 claim/complete 后 `level=0`，未见典型不清线 storm；该轮因墙钟截断停在 `execve("/bin/sh", ...)` 之后。
- `riscv64-nemu-rootfs-shell-fsgnj-performance-20b`：默认 performance 构建可到 `exec /bin/sh fallback`，但 700s/20B 截止仍未重新出现 shell marker。
- 构建验证：`make -C nemu ... riscv64-linux_debug_defconfig && make -C nemu ... -j4` PASS；`make -C nemu ... riscv64-linux_defconfig && make -C nemu ... -j4` PASS。
- 2026-06-05 继续验证：
  - 修正 virtio-blk QueueNotify：只有实际处理新 descriptor 后才触发 used-buffer IRQ。
  - 新增 syscall debug 下 execve 后 U-mode PC 采样，定位 `/bin/sh` 已能执行 `/bin/sleep`，真实缺口依次为 `feq.d`、`fadd.d`、`fcvt.l.d/fcvt.d.l`。
  - 补齐 NEMU RV64F/D 的 compare、基础算术、min/max、F/D 与 W/WU/L/LU 的 FCVT。
  - `make -C nemu NEMU_HOME=... riscv64-linux_defconfig && make -C nemu NEMU_HOME=... -j4` PASS。
  - `timeout 300s make -C Linux ARCH=riscv64-nemu MAX_CYCLES=12000000000 LOG_DIR=$PWD/Linux/env/logs/linux-front/riscv64-nemu-rootfs-fcvt-performance-12b run` 到 `[ysyx-rootfs-sh] /bin/sh -c marker` 后保持安静等待；`grep -a -E "ysyx-rootfs-sh|Illegal instruction|unhandled signal|badaddr:" .../console.log` 只命中 marker，无 SIGILL/oops/badaddr。
- 2026-06-05 systemd readiness 与 ebreak 语义验证：
  - `bash -n Linux/scripts/build-ubuntu-rootfs.sh && bash -n Linux/scripts/check-ubuntu-rootfs.sh` PASS。
  - `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs` PASS：`/init`、`/bin/sh`、`/etc/os-release` 均 OK，同时报告 `MISSING systemd candidate`。
  - `make -C Linux ARCH=riscv64-nemu check-ubuntu-rootfs-systemd` 按预期失败，证明当前镜像不是 systemd-ready rootfs。
  - `UBUNTU_ROOTFS_REQUIRE_SYSTEMD=1 bash Linux/scripts/build-ubuntu-rootfs.sh` 在当前缺 sudo+debootstrap+qemu-riscv64-static 环境下按预期拒绝 shell-only 构建。
  - `make -C Linux ARCH=riscv64-nemu check` PASS，并串接 rootfs readiness 检查。
  - `make -C nemu NEMU_HOME=... riscv64-linux_defconfig && make -C nemu NEMU_HOME=... -j4` PASS；最终 `.config` 已恢复为 `CONFIG_RV64=y`、`CONFIG_MODE_SYSTEM=y`、`CONFIG_TARGET_NATIVE_ELF=y`、`CONFIG_PERFORMANCE=y`。
  - 裸 RV64 system `ebreak` 烟测不再输出 `HIT GOOD/BAD TRAP`；它进入 breakpoint trap 后因 `mtvec=0` 取指 0 地址 abort，证明 system/Linux 配置不再把 `ebreak` 当作 NEMUTRAP 退出。

## 未闭合边界

- 默认 rootfs 8B gate 到 `Run /init` 后预算耗尽，还未看到 stage1 第一条 marker；下一步需要更高预算或更细的 PID1/动态链接器诊断。
- opt-in 静态 probe 安装进 rootfs 后，`BOOTARGS_EXTRA='init=/ysyx-rootfs-probe'` 的 9B/12B 诊断跑到 virtio-blk 识别后，没有到 EXT4 mount，停止点在 PLIC IRQ 路径附近；说明当前最小 virtio-blk/PLIC 对 ext4 布局或请求压力仍有敏感边界。
- 当前 fakeroot Ubuntu Base 镜像没有 systemd，不能声明 systemd/完整多进程 Ubuntu 已启动。
- 当前已能自动检查并硬性区分 shell-only rootfs 与 systemd-ready rootfs；但系统缺少构建 systemd rootfs 所需的 sudo+debootstrap+qemu-riscv64-static，因此还没有生成完整 systemd 镜像。
- sysfs mount 仍是独立等待点；当前只在 shell fallback 跳过 sysfs，systemd gate 未绕过。
- 动态 `/bin/sh`/ld-linux 已闭合到 shell marker 和 `/bin/sleep 60` 正常等待；更高层的长期多进程 session、TTY 输入和 systemd 仍未闭合。

## 下一步

1. 对 `execve("/bin/sh")` 后的动态链接器路径加更窄的 PC/syscall/缺页窗口，继续定位是否为性能预算、下一条 OP-FP 缺口，还是 virtio/page-cache 压力。
2. 给 sysfs mount 单独做 debug window；确认是 syscall 没返回、缺页/中断等待，还是 Linux sysfs 枚举依赖缺失设备。
3. 若要推进 systemd，需要通过 debootstrap/qemu-user 或预制镜像把 `systemd-sysv/udev/dbus` 等包放入 rootfs，而不是用当前 Ubuntu Base fakeroot 镜像越级验证。
