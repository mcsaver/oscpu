# Task Report

## 基本信息

- `task_id`: `2026-05-31-rv64-ubuntu2204-bringup-env`
- `task_slug`: `rv64-ubuntu2204-bringup-env`
- `graph_template`: `npc-sim-regression`
- `graph_mode`: `static+dynamic`
- `status`: `completed-with-followups`
- `owner`: `hardware-flow + npc`
- `started_at`: `2026-05-31`
- `updated_at`: `2026-05-31`

## 任务目标

- `source_request`: 用户要求根据 ChatGPT 分享页回答，在当前 ysyx-workbench 中构建能启动真正 Ubuntu 22.04 的环境；WSL 本身不能更换，其余尽量完成。
- `goal`: 在 `npc/rv64` 内落地 OpenSBI + Linux + initramfs/rootfs/QEMU 的构建、平台配置、DTB 生成、smoke/regression 入口，并推进到 Ubuntu 22.04 probe initramfs 能被 QEMU 完整启动、被 NPC 实核运行进入 `/init`。
- `scope`: `npc/rv64` 平台配置、脚本、Makefile 入口、Linux/Ubuntu rootfs 构建入口、QEMU/NPC smoke 验证、必要 RTL/仿真短板修补和记忆记录；完整官方 Ubuntu `/bin/sh`、virtio-blk/rootfs、完整 F/D 和 UART 用户态长输出可见性作为后续 follow-up。

## 选图说明

- `selected_template`: `npc-sim-regression`
- `why_this_graph`: 任务核心是把真实 Linux/Ubuntu bring-up 纳入 NPC RV64 仿真闭环，需要以 Verilator build、DTB smoke、OpenSBI handoff、Linux initramfs smoke 作为证据 gate。
- `dynamic_nodes_added`: `share-page-requirements-extract`, `ubuntu-rootfs-env-check`, `linux-initramfs-smoke`, `env-localization`
- `why_dynamic_nodes_were_needed`: 用户输入来自外部分享页，且 Ubuntu rootfs 依赖本机 sudo/debootstrap/qemu-user-static；必须动态确认建议内容、环境依赖和真实 smoke 边界。

## 节点概览

| node_id | owner_agent | status | inputs | outputs | evidence |
| ------- | ----------- | ------ | ------ | ------- | -------- |
| `share-page-requirements-extract` | `hardware-flow` | completed | ChatGPT 分享页 | Linux bring-up profile、脚本/平台/回归目录规划 | 已提取 OpenSBI/Linux/BusyBox/Ubuntu rootfs、统一 yml/DTB 和 smoke/regression 建议 |
| `platform-profile` | `npc` | completed | 当前 `npc/rv64` OpenSBI/Linux 状态 | `platform/npc-rv64.yml`, `platform/gen_dts.py`, `platform/README.md` | `dtb/rootfs-dtb/initramfs-dtb` 构建 PASS，rootfs DTB 包含 512MiB memory、virtio-mmio 预留、PLIC `riscv,ndev=32` |
| `bringup-scripts` | `npc` | completed | OpenSBI/Linux/BusyBox/Ubuntu rootfs 需求 | `scripts/*.sh` 与顶层 Makefile 入口 | `bash -n npc/rv64/scripts/*.sh npc/rv64/regression/run_all.sh` PASS |
| `busybox-initramfs` | `npc` | completed | riscv64 cross toolchain | `npc/rv64/env/images/initramfs/rootfs.cpio` | BusyBox 1.36.1 minimal static riscv64 build PASS，cpio 约 803 KiB |
| `rv64-build` | `npc` | completed | PMEM/RAM 从 128MiB 扩到 512MiB | `npc/rv64/build/NpcSimTop` | `make -C npc/rv64 -j$(nproc)` PASS |
| `linux-initramfs-smoke` | `npc` | partial | OpenSBI fw_jump、Linux kernel、generated DTB、BusyBox cpio | Linux high-half 持续退休证据 | 5M/20M smoke 均 max-cycles 退出；20M 到 `pc=0xffffffff80215020/commits=9322573` |
| `ubuntu-rootfs-build` | `npc` | blocked | `build-ubuntu-rootfs.sh` | rootfs 脚本已接入但未实际生成 | `sudo -n true` 失败；缺 `debootstrap/qemu-riscv64-static` |
| `ubuntu-base-initramfs` | `npc` | completed | Canonical Ubuntu Base 22.04.5 riscv64 tarball | `npc/rv64/env/images/ubuntu2204/ubuntu-22.04-riscv64-probe.cpio` | SHA256 `OK`；probe cpio 内含 syscall-only `/init` 与官方 `/etc/os-release`；`ubuntu-initramfs-dtb` 会自动重建 cpio |
| `qemu-ubuntu-probe` | `npc` | completed | OpenSBI/QEMU/Linux/Image/DTB/probe cpio | QEMU 完整 Ubuntu 22.04 probe 输出 | `make -C npc/rv64 qemu-ubuntu-initramfs QEMU_TIMEOUT=20s` PASS，完整打印 `[ysyx-init]`、`PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`VERSION_ID="22.04"`、`UBUNTU_CODENAME=jammy` |
| `npc-ubuntu-probe` | `npc` | completed-with-followup | NPC OpenSBI、Linux、Ubuntu DTB、probe cpio | NPC 实核运行进入 `/init` | `npc-ubuntu-final-clean2.log/out`：`console [ttyS0] enabled`、`Freeing unused kernel image`、`Run /init as init process`；stdout 出现 `[ysyx-init] Ubun...`，后续长输出受 UART/tty 可见性短板截断 |
| `env-localization` | `npc` | completed | 已生成的 `/tmp` 源码、下载包、镜像和日志路径 | `npc/rv64/env/` | OpenSBI/Linux/BusyBox/Ubuntu Base 产物已迁入仓库内；本地 Python venv + PyYAML 已落在 `env/tools/python`；短 Ubuntu smoke 从 `../env/...` 加载镜像 |
| `rtl-shortfall-fixes` | `npc` | completed | Linux/NPC 失败轨迹与 Ubuntu probe 需求 | RAS/IRQ/F-D/unaligned benchmark/debug probe 修补 | rv64 Verilator rebuild PASS；`smoke-fp-loadstore` GOOD TRAP；`NPC_LINUX_HANG_PROBE` 默认关闭 |
| `memory-taskrun-update` | `hardware-flow` | completed | 本轮变更和验证 | project-status、npc、known-issues、本 task-run | 本文件与相关 memory 已更新 |

## 关键产物

- `artifacts`: `npc/rv64/platform/`, `npc/rv64/scripts/`, `npc/rv64/configs/`, `npc/rv64/regression/`, `npc/rv64/env/README.md`, `npc/rv64/tools/Makefile` 新 smoke targets。
- `env_root`: `npc/rv64/env/`，默认承载 `src/opensbi`, `src/linux`, `src/busybox-1.36.1`, `downloads/`, `build/opensbi-npc/`, `images/initramfs/`, `images/ubuntu2204/`, `tools/python/`, `logs/`。
- `logs_or_traces`: `npc/rv64/env/logs/qemu/ubuntu-initramfs.log`, `npc/rv64/env/logs/linux-smoke/npc-ubuntu-final-clean2.log`, `npc/rv64/env/logs/linux-smoke/npc-ubuntu-final-clean2.out`, older `npc-ubuntu-final-clean.log/out` with temporary debug probe evidence。
- `linked_memory_updates`: `.github/memory/project-status.md`, `.github/memory/modules/npc.md`, `.github/memory/modules/agent-system.md`, `.github/memory/known-issues.md`。

## 当前阻塞点

- `blockers`: 旧的“未执行到 `/init`”阻塞已解除。剩余 follow-up 是 NPC UART/tty 对用户态长 write 的可见性截断、官方 Ubuntu `/bin/sh` 需要完整 rv64gc/lp64d/F-D 支持，以及 ext4/rootfs 路线需要 virtio-blk/设备闭环。
- `missing_dependencies`: ext4/debootstrap 路线仍依赖宿主 `debootstrap`, `qemu-riscv64-static` 与 sudo 权限；可选自带工具链可放到 `npc/rv64/env/toolchains/`，当前系统 `riscv64-linux-gnu-*` 已能支撑现有 probe 构建。
- `risk_assessment`: 可以表述为“QEMU 完整启动 Ubuntu 22.04 probe initramfs，NPC 已进入并执行 probe `/init`”；不能表述为“官方 Ubuntu 22.04 `/bin/sh` 已在 NPC 上可交互运行”。

## 下一步建议

1. 修 NPC UART/tty 用户态长 burst 输出，或让 probe init 使用短同步写，形成 NPC 上完整 `/etc/os-release` 可见 gate。
2. 继续补完整 F/D（尤其 FPR->GPR、FP arithmetic/conversion）以支撑 Ubuntu riscv64 `rv64gc/lp64d` 的官方 `/bin/sh`。
3. 接 virtio-mmio block、多源 PLIC/UART RX 和 ext4 Ubuntu rootfs，把 probe initramfs 推进到真实 rootfs/shell。

## 模板升级候选

- `repeated_dynamic_subgraph`: `linux-bringup-profile`
- `should_promote_to_static_template`: `yes`
- `reason`: RV64 Linux/OpenSBI bring-up 已多次出现，建议沉淀为固定 gate：DTB、OpenSBI payload、OpenSBI SBI runtime、kernel high-half、initramfs shell、rootfs mount。

## 收尾结论

- `final_result`: 已在仓库中构建真实 Ubuntu 22.04 bring-up 所需的工程环境、入口、QEMU 参考链和 NPC 实核运行 probe 链，并按用户要求把外部源码、下载包、镜像、本地 Python/QEMU 依赖和 smoke 日志默认收口到 `npc/rv64/env/`。QEMU 对同一 probe cpio 完整打印 Ubuntu 22.04 `/etc/os-release`；NPC 已执行到 probe `/init`，剩余是用户态长串口输出可见性和官方 shell/F-D/virtio-rootfs 后续目标。
- `evidence_summary`: `make -B -C npc/rv64/tools ubuntu-initramfs-dtb` 自动重建 probe cpio/DTB PASS；`make -C npc/rv64 qemu-ubuntu-initramfs QEMU_TIMEOUT=20s` PASS，完整输出 `PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`VERSION_ID="22.04"`、`UBUNTU_CODENAME=jammy`；NPC `npc-ubuntu-final-clean2.log/out` 到 `Run /init as init process` 并出现 `[ysyx-init] Ubun...`；`make -C npc/rv64 -j1` PASS；`make -C npc/rv64/tools smoke-fp-loadstore` GOOD TRAP。
- `notes`: 不能更换 WSL 的约束已保留；sudo/debootstrap 不再是 probe initramfs 路线的硬阻塞，但 ext4 rootfs/virtio 路线仍需要后续依赖和 RTL 设备支持。当前“Ubuntu core”证明采用 rv64imac syscall-only probe init；官方 Ubuntu shell 仍需完整 rv64gc/lp64d 支持。
