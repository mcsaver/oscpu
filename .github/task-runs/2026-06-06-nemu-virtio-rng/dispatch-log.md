# 调度日志

## 目标

继续按照用户粘贴建议优化 NEMU，使其从“最小可启动 Ubuntu 22.04 rootfs 的 Linux bring-up 机器”向完整规模 Ubuntu 运行所需的更真实平台推进。

## 决策

用户建议覆盖两个方向：

- 阶段 A：补设备真实性，例如 virtio-rng、RTC、virtio-blk feature 与更完整 DTB。
- 阶段 B：提速，例如 basic-block cache、decode cache、host-pointer TLB、serial buffering、virtio-blk pread/pwrite。

本轮选择阶段 A 的 `virtio-rng/hwrng` 作为切入点，原因是：

- Ubuntu/systemd 长跑、ssh key、apt、dbus 等路径都依赖运行期熵源，只有 `/chosen/rng-seed` 不足以代表真实机器。
- virtio-rng 设备面小、风险低，适合在现有单 hart virtio-mmio 平台上闭合。
- 能直接加入 guest-check，形成 `/dev/hwrng`、sysfs、modalias 和读取字节数的硬证据。

## 执行路径

1. 读取项目 agent 规范、NEMU/RV64 Linux/virtio-rootfs 相关说明和用户粘贴建议。
2. 检查当前 NEMU 设备初始化、Kconfig、virtio-blk 实现、DTB 生成和 Linux 构建脚本。
3. 新增 NEMU virtio-rng 设备并接入默认 rootfs defconfig。
4. 让 NEMU 专用 rootfs DTB 暴露 `virtio_mmio@10002000`，同时保持 NPC rootfs DTB 不声明尚未实现的设备。
5. 打开 Linux `CONFIG_HW_RANDOM` 与 `CONFIG_HW_RANDOM_VIRTIO`。
6. 扩展 `check-nemu-systemd-guest.sh`，把 hwrng 作为默认 hard gate。
7. 构建 NEMU/Linux/OpenSBI/rootfs DTB，运行 focused Ubuntu systemd gate。
8. 更新 project memory、NEMU module memory、known issues、README 和本 task-run。

## 验证摘要

- 静态脚本与生成器检查 PASS。
- NEMU performance defconfig 与构建 PASS。
- Linux Image 增量构建 PASS，OpenSBI rootfs 重建 PASS。
- DTB 中 `virtio_mmio@10002000` 兼容串为 `virtio,mmio`，IRQ 为 `3`。
- focused Ubuntu systemd guest gate PASS，关键 hwrng marker、systemd rc=0、poweroff 和 GOOD TRAP 全部闭合。

## 后续建议

下一步仍应沿用户建议继续推进设备真实性或性能：

- 设备真实性：RTC、virtio-net、virtio-blk 错误路径/更多 feature、多设备 IRQ 压力。
- 性能：先做低侵入的 decode/basic-block cache 或 hot TLB/host pointer 缓存，再对比 `perf.tsv`。
