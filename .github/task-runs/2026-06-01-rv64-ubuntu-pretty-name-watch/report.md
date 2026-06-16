# RV64 Ubuntu probe PRETTY_NAME gate

## 目标

在上轮 `[ysyx-init]` marker 已可见的基础上，验证 NPC/Verilator 能否完整输出 Ubuntu 22.04 probe 的 `/etc/os-release` 关键字段，把证据推进到 L4 `ubuntu-probe-visible`。

## 输入产物

- OpenSBI: `npc/rv64/env/build/opensbi-npc-ubuntu-initramfs/platform/generic/firmware/fw_jump.bin`
- Linux Image: `npc/rv64/env/src/linux/arch/riscv/boot/Image`
- DTB: `npc/rv64/tools/build/npc-rv64-ubuntu-initramfs.dtb`
- initramfs: `npc/rv64/env/images/ubuntu2204/ubuntu-22.04-riscv64-probe.cpio`

## NPC/Verilator 验证

命令：

```bash
make -C npc/rv64/tools smoke-ubuntu-probe-watch \
  LOG_DIR=../env/logs/codex-ubuntu-pretty-name-watch \
  UBUNTU_INITRAMFS_MAX_CYCLES=1200000000
```

默认 `UBUNTU_PROBE_EXPECT` 为 `PRETTY_NAME="Ubuntu 22.04.5 LTS"`。

关键证据：

- `Kernel command line: console=ttyS0,115200n8 earlycon=sbi loglevel=8 ignore_loglevel rdinit=/init ...`
- `10000000.serial: ttyS0 at MMIO 0x10000000 ... is a 16550A`
- `Run /init as init process`
- `[ysyx-init] early-entry`
- `[ysyx-init] after-mkdir`
- `[ysyx-init] after-mount`
- `[ysyx-init] Ubuntu 22.04 initramfs reached on NPC rv64imac core`
- `[ysyx-init] /etc/os-release follows:`
- `PRETTY_NAME="Ubuntu 22.04.5 LTS"`
- `GUEST EXPECT MATCH`

统计：

- `exit via guest-watch, code=0`
- `cycles=948286162`
- `commits=148231451`
- `CPI=6.397`
- `simulation frequency=58508 inst/s`
- `CLINT mtime = 948286162 (mtime-cycles=+0, match=yes)`

性能/真实度观察：

- BPU branch accuracy: `91.0%`
- icache: `access=83765818, hit=60393869, miss=23371949`
- dcache load miss: `29382046`
- retire hist `0/1/2 = 839990695/68359481/39935986`
- control wait `stop=380180792, branch=182049140, jump=171298445`

## QEMU reference

命令：

```bash
make -C npc/rv64 qemu-ubuntu-initramfs QEMU_TIMEOUT=20s
```

结果：PASS。QEMU 使用同一 probe 路线完整打印：

- `PRETTY_NAME="Ubuntu 22.04.5 LTS"`
- `NAME="Ubuntu"`
- `VERSION_ID="22.04"`
- `VERSION="22.04.5 LTS (Jammy Jellyfish)"`
- `UBUNTU_CODENAME=jammy`
- `[ysyx-init] syscall-only init is alive; Ubuntu /bin/sh needs F/D (rv64gc/lp64d)`

## 结论

当前 NPC/Verilator 已达到 L4 `ubuntu-probe-visible`：syscall-only Ubuntu probe 的 `/etc/os-release` 关键字段可见。

仍未达到：

- L5 `ubuntu-shell-initramfs`: 官方 Ubuntu `/bin/sh` 或等价 lp64d 用户态运行。
- L6 `ubuntu-rootfs`: virtio/rootfs mount、`/dev/vda`、shell/init 证据。

下一步应进入 `rv64gc-userland-loop` 与 `rv64-ubuntu-rootfs-loop`：补官方 rv64gc/lp64d 用户态所需 F/D 路径、动态链接器验证，以及 virtio-mmio block、多源 PLIC、rootfs mount。
