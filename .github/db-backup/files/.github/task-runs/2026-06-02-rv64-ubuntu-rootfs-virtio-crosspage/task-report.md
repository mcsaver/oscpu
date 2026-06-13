# Task Report

## 基本信息

- `task_id`: `2026-06-02-rv64-ubuntu-rootfs-virtio-crosspage`
- `task_slug`: `rv64-ubuntu-rootfs-virtio-crosspage`
- `graph_template`: `rv64-ubuntu-rootfs-loop`
- `graph_mode`: `static+dynamic`
- `status`: `completed`
- `owner`: `Codex`
- `started_at`: `2026-06-02`
- `updated_at`: `2026-06-02`

## 任务目标

- `source_request`: 用户要求继续使用当前 rv64core 完成 Ubuntu 22.04 启动；Linux/Ubuntu 相关资源、脚本与 tools 迁到仓库根目录 `Linux/`，`make -C Linux ARCH=riscv64-npc run` 表示完整 Ubuntu rootfs；遇到问题要先定位并修真实 bug，不能通过关闭 RAS/speculative return 或跳过 SRET/Sv39/RVC gate 来“跑通”。
- `goal`: rootfs 路线补齐 virtio block/multi-source PLIC，定位 `/init` 后动态用户态崩溃 root cause，并推进 Ubuntu 22.04 rootfs 到 `/bin/sh`。
- `scope`: `Linux/` 顶层 Makefile/scripts/tools/platform，`npc/rv64` 仿真外设、PLIC、OoO fetch/mem bridge、focused testbench 与项目 memory。

## 选图说明

- `selected_template`: `rv64-ubuntu-rootfs-loop`
- `why_this_graph`: 任务跨 OpenSBI/Linux/DTB/rootfs/virtio/PLIC/OoO fetch，必须按系统 bring-up 分层验证。
- `dynamic_nodes_added`: `virtio-blk-mmio-device`、`sv39-cross-page-fetch-debug`
- `why_dynamic_nodes_were_needed`: rootfs 首次卡点不是已有 shell initramfs 问题，而是缺 virtio block 后端、多源 PLIC 与页尾跨页取指。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `linux-entry-migration-review` | Codex | completed | 迁移后的 `Linux/` 入口 | `BOOT=ubuntu-rootfs` 默认完整 rootfs，shell/probe 显式 `BOOT=` | `make -C Linux ARCH=riscv64-npc BOOT=ubuntu-rootfs check` PASS |
| `virtio-blk-mmio-device` | Codex | completed | rootfs DTB `virtio_mmio@10001000`、ext4 image | `AxiLiteVirtioBlk` + host `virtio_blk.c` + `--block=` | `make -C Linux ARCH=riscv64-npc smoke-virtio-blk` GOOD TRAP |
| `plic-multi-source` | Codex | completed | UART source1、virtio source2 | 32-source priority/pending/claim/complete PLIC | `tb_axi_lite_plic` PASS |
| `dma-cache-visibility` | Codex | completed | virtio DMA writes used ring/status/data | virtio MMIO notify 后清 OoO D-cache valid | `smoke-virtio-blk` 读取 ext4 superblock PASS |
| `sv39-cross-page-fetch-debug` | Codex | completed | `ld-linux` illegal `badaddr=0x97de1693` | `OooFetchAxiBridge` 跨页 packet 翻译与合并 | `tb_ooo_fetch_axi_bridge` PASS；`smoke-sret-user-sv39-halfword` GOOD TRAP |
| `ubuntu-rootfs-run` | Codex | completed | OpenSBI rootfs firmware、Linux Image、rootfs DTB、ext4 block | Ubuntu 22.04.5 rootfs `/init` 与 `/bin/sh` | `PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`[ysyx-rootfs-sh] /bin/sh -c marker` |

## 关键产物

- `artifacts`: `Linux/Makefile` rootfs route；`Linux/scripts/build-ubuntu-rootfs.sh`；`Linux/tools/virtio-blk-smoke.S`；`Linux/tools/sret-user-sv39-halfword-smoke.S`；`npc/rv64/csrc/device/virtio_blk.c`；`npc/rv64/vsrc/sim/AxiLiteVirtioBlk.sv`；`npc/rv64/vsrc/bus/AxiLitePlic.v`；`npc/rv64/vsrc/core/OooFetchAxiBridge.v`
- `logs_or_traces`: `Linux/env/logs/linux-front/riscv64-npc-ubuntu-rootfs/console.log`；`/tmp/rv64-linux-regression`
- `linked_memory_updates`: `.github/memory/project-status.md`；`.github/memory/modules/npc.md`；`.github/memory/known-issues.md`

## 当前阻塞点

- `blockers`: 无阻塞完整 rootfs 到 shell 的问题。
- `missing_dependencies`: 后续更高层仍需要 UART RX/TTY 交互、systemd 或真实多进程用户态、Linux-visible framebuffer/display、外设可综合边界与 PPA。
- `risk_assessment`: 目前 virtio-blk 是仿真专用 DPI 设备，适合系统 bring-up，不代表可综合 SoC 外设；rootfs `/bin/sh` 已进入但默认非交互运行会在 max-cycles 上限退出。

## 下一步建议

1. 为 `BOOT=ubuntu-rootfs` 增加可选 watch/expect target，让 CI 能在 `[ysyx-rootfs-sh]` marker 自动退出，同时保留交互 shell 路线。
2. 继续补 UART RX/console 交互或 Linux-visible framebuffer/display gate。
3. 对 virtio/PLIC/rootfs 长跑做更长窗口压力，观察是否存在 IRQ storm、DMA coherency 或 page-cache 边界问题。

## 模板升级候选

- `repeated_dynamic_subgraph`: `sv39-cross-page-fetch-debug`
- `should_promote_to_static_template`: `yes`
- `reason`: RVC + Sv39 用户态很容易在页尾形成 `PC%4==2` 的 32-bit 跨页指令，应成为 Linux/rootfs bring-up 的固定 focused gate。

## 收尾结论

- `final_result`: Ubuntu 22.04 rootfs 已在 NPC RV64 上通过 virtio-blk 挂载 ext4，进入 `/init`，执行动态 `/bin/sh -c`，打印 marker 并进入 `/bin/sh`。
- `evidence_summary`: `make -C npc/rv64 -j1` PASS；`tb_axi_lite_plic/tb_ooo_priv_system/tb_ooo_fetch_axi_bridge` PASS；`smoke-sret-user-sv39`、`smoke-sret-user-sv39-halfword`、`smoke-virtio-blk` GOOD TRAP；完整 rootfs run 打印 `PRETTY_NAME="Ubuntu 22.04.5 LTS"` 与 `[ysyx-rootfs-sh] /bin/sh -c marker`。
- `notes`: 300M cycle 末尾 ABORT 是 shell 等待输入的上限退出，不是本轮新 bug。
