# NEMU virtio-rng/hwrng 平台真实性推进

## 背景

用户建议把当前“可启动 Ubuntu 22.04 rootfs 的最小 NEMU 机器”继续向更真实的平台推进。综合风险、收益和当前 gate 覆盖，本轮选择先补低风险设备真实性：运行期熵源 `virtio-rng`/`/dev/hwrng`。此前 DTB `/chosen/rng-seed` 只能给 Linux 早期随机池喂 seed，不能代表 systemd/ssh/apt 等用户态长期运行时有真实 hwrng。

## 实现

- 新增 `nemu/src/device/rng.c`，实现最小 modern virtio-mmio RNG：device id 4、vendor `0x58535959`、单队列、`VIRTIO_F_VERSION_1`、feature 子集校验、used-buffer interrupt 和 PLIC IRQ3。
- 随机字节优先来自 host `/dev/urandom`；不可用时记录日志并退到确定性 xorshift，避免宿主熵设备异常时直接破坏 bring-up。
- 在 NEMU Kconfig、filelist、device init 和 `riscv64-linux_{,debug_}defconfig` 接入 `CONFIG_HAS_VIRTIO_RNG`，默认 MMIO 为 `0x10002000`。
- `Linux/platform/gen_dts.py` 新增 `--virtio-rng`，只在 NEMU rootfs DTB 暴露 `virtio_rng0: virtio_mmio@10002000`，避免 NPC RTL 尚无该设备时 DTS 先行声明。
- Linux kernel 构建启用 `CONFIG_HW_RANDOM` 与 `CONFIG_HW_RANDOM_VIRTIO`。
- `check-nemu-systemd-guest.sh` 新增 hwrng gate：`/dev/hwrng` 字符设备、`/sys/class/misc/hw_random`、`rng_current/rng_available`、virtio-rng modalias 和 64B hwrng read。

## 验证

- `bash -n Linux/scripts/build-linux.sh Linux/scripts/check-nemu-systemd-guest.sh` PASS
- `python3 -m py_compile Linux/platform/gen_dts.py` PASS
- `make -C Linux ARCH=riscv64-nemu rootfs-dtb` PASS，`fdtget` 确认 `/soc/virtio_mmio@10002000` 为 `virtio,mmio` 且 IRQ 为 `3`
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu riscv64-linux_defconfig` PASS，`.config` 含 `CONFIG_HAS_VIRTIO_RNG=y`
- `make -C nemu NEMU_HOME=/home/lyg/PA/ysyx-workbench/nemu -j$(nproc)` PASS
- `make -C Linux ARCH=riscv64-nemu check-nemu-performance-config` PASS
- `JOBS=4 bash Linux/scripts/build-linux.sh` PASS，Linux `.config` 含 `CONFIG_HW_RANDOM=y` 与 `CONFIG_HW_RANDOM_VIRTIO=y`
- `make -C Linux ARCH=riscv64-nemu rootfs-dtb opensbi-rootfs` PASS
- focused gate PASS：`timeout 1500s make -C Linux check-nemu-systemd-guest ... NEMU_SYSTEMD_SOAK_SECONDS=0 ...`

## Focused Gate 结果

日志目录：`.github/task-runs/2026-06-06-nemu-virtio-rng`

- `perf.tsv`: `boot=244s`、`guest_check=596s`、`poweroff=20s`、`total=861s`
- hwrng marker:
  - `__NEMU_CHECK_HWRNG_CURRENT__:virtio_rng.0`
  - `__NEMU_CHECK_HWRNG_AVAILABLE__:virtio_rng.0`
  - `__NEMU_CHECK_VIRTIO_RNG_MODALIAS__:virtio:d00000004v58535959`
  - `__NEMU_CHECK_HWRNG_BYTES__:64`
- PASS marker:
  - `hwrng-node`
  - `hwrng-sysfs`
  - `hwrng-virtio-selected`
  - `virtio-rng-modalias`
  - `hwrng-read`
- 主链：systemd/rootfs guest check rc=0，自然 poweroff，NEMU `HIT GOOD TRAP`

## 边界

本轮闭合的是运行期熵源设备与 guest 内硬证据，不声明 RTC、virtio-net、SMP、多队列 virtio、virtio 错误注入或 QEMU 级完整虚拟机已经完成。
