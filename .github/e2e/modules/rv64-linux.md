# rv64-linux E2E Contract

- **范围**: `Linux/`、OpenSBI、Linux kernel、Ubuntu initramfs/rootfs、QEMU/NPC gate。
- **上游**: npc/rv64 core、Linux env、device contracts。
- **下游**: linux-device、display-vga、verilator-tapeout。
- **L0 gate**: `rv64-linux-contract` 检查 Linux 入口、platform yaml 和 instructions。
- **L1 gate**: 后续按 `rv64-ubuntu-probe-loop` 跑 QEMU/NPC probe。
- **证据**: `/init`、`/etc/os-release`、`/bin/sh`、rootfs mount、poweroff，以及只读模板/
  每轮可写 block-image 副本的 pre/post SHA-256；NPC systemd 严格事务由
  `Linux/scripts/npc_systemd_transaction_evidence.py` 对 preflight、autocheck、strict
  三个有序周期窗口做整行 marker 原始计数，并写出绑定 console SHA 的 JSON。
- **升级路线**: 按 gate 分层生成机器可读 boot status。
