# rv64-linux E2E Contract

- **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。
- **上游**: npc/rv64 core、Linux env、device contracts。
- **下游**: linux-device、display-vga、verilator-tapeout。
- **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 instructions。
- **L1 gate**: 后续按 `rv64-ubuntu-probe-loop` 跑 QEMU/NPC probe。
- **证据**: `/init`、`/etc/os-release`、`/bin/sh`、rootfs mount、poweroff。
- **升级路线**: 按 gate 分层生成机器可读 boot status。
