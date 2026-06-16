# Dispatch Log

## 基本信息

- `task_id`: `2026-06-02-rv64-ubuntu-rootfs-virtio-crosspage`
- `task_slug`: `rv64-ubuntu-rootfs-virtio-crosspage`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `log_policy`: `append-only`

---

### [2026-06-02 18:00] `virtio-blk-mmio-device` - `completed`

- `owner_agent`: Codex
- `trigger`: rootfs DTB 已声明 virtio-mmio block，但 simulator 无设备后端。
- `depends_on`: Linux/Ubuntu 资源已迁到 `Linux/`。
- `inputs`: `Linux/platform/npc-rv64.yml`、Ubuntu ext4 rootfs image、`NpcSimTop` AXI-Lite xbar。
- `action`: 新增 `AxiLiteVirtioBlk` 与 host `virtio_blk.c`，`--block=` 挂载 ext4 image，rootfs route 自动传 block 参数。
- `outputs`: virtio-mmio register/queue/DMA/IRQ 最小 block device。
- `evidence`: `make -C Linux ARCH=riscv64-npc smoke-virtio-blk` GOOD TRAP，读取 ext4 superblock magic。
- `handoff_to`: `ubuntu-rootfs-run`
- `next_step`: rootfs 长跑。
- `notes`: 该设备是仿真专用 DPI，不声明可综合外设。

### [2026-06-02 18:20] `sv39-cross-page-fetch-debug` - `completed`

- `owner_agent`: Codex
- `trigger`: rootfs `/init` 后 `ld-linux` 在 `0x...8ffe` 报 illegal instruction，badaddr 低半字正确、高半字错误。
- `depends_on`: rootfs 已 mount，virtio-blk 可读。
- `inputs`: `ld-linux-riscv64-lp64d.so.1` file bytes、kernel panic log、`OooFetchAxiBridge` fetch packet logic。
- `action`: 确认正确指令 `0x00241693` 位于页尾 halfword；新增跨页 focused smoke，修复 bridge 跨页 packet 翻译/合并。
- `outputs`: `merge_cross_page_packet()`、`smoke-sret-user-sv39-halfword`、`tb_ooo_fetch_axi_bridge` 非连续物理页回归。
- `evidence`: 修复前 smoke BAD TRAP code=2；修复后 GOOD TRAP；`tb_ooo_fetch_axi_bridge` PASS。
- `handoff_to`: `ubuntu-rootfs-run`
- `next_step`: 重跑完整 rootfs。
- `notes`: 该问题不是缺 ISA 扩展，也不是关闭 RAS/spec return 可以接受的绕过项。

### [2026-06-02 18:50] `ubuntu-rootfs-run` - `completed`

- `owner_agent`: Codex
- `trigger`: focused gates 与 build 已通过。
- `depends_on`: `virtio-blk-mmio-device`、`plic-multi-source`、`sv39-cross-page-fetch-debug`
- `inputs`: OpenSBI rootfs firmware、Linux Image、rootfs DTB、Ubuntu ext4 image。
- `action`: 运行 `make -C Linux ARCH=riscv64-npc BOOT=ubuntu-rootfs MAX_CYCLES=300000000 PROGRESS=25000000 run`。
- `outputs`: Ubuntu 22.04 rootfs 到 `/bin/sh`。
- `evidence`: console log 打印 `EXT4-fs (vda)`、`Run /init as init process`、`PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`[ysyx-rootfs-sh] /bin/sh -c marker`、`#` shell prompt。
- `handoff_to`: memory update
- `next_step`: 可选 rootfs marker watch target、TTY/display 后续 gate。
- `notes`: 300M cycle ABORT 是 shell 等待输入时被 max-cycles 截断。
