# Dispatch Log

## 基本信息

- `task_id`: `2026-05-31-rv64-ubuntu2204-bringup-env`
- `task_slug`: `rv64-ubuntu2204-bringup-env`
- `graph_template`: `npc-sim-regression`
- `log_policy`: `append-only`

## 记录格式

每次节点派发、状态变化、失败恢复、handoff 或证据补充时，追加一个条目。

---

### [2026-05-31] `share-page-requirements-extract` - `completed`

- `owner_agent`: `hardware-flow`
- `trigger`: 用户要求根据 ChatGPT 分享页构建真正 Ubuntu 22.04 启动环境。
- `depends_on`: none
- `inputs`: 分享页、当前 `npc/rv64` OpenSBI/Linux 状态。
- `action`: 提取建议中的目录结构、平台配置、OpenSBI/Linux/BusyBox/Ubuntu rootfs 构建路线和 smoke/regression gate。
- `outputs`: 采用 `platform/ + scripts/ + configs/ + regression/` 方案，先以 Linux initramfs profile 建立可验证入口。
- `evidence`: 分享页结论与当前 `.github/memory/modules/npc.md` 的 OpenSBI/Linux 状态一致。
- `handoff_to`: `platform-profile`
- `next_step`: 落地统一平台 yml 和 DTB 生成脚本。
- `notes`: 明确不把脚本接入等同于 Ubuntu 用户态启动。

### [2026-05-31] `platform-profile` - `completed`

- `owner_agent`: `npc`
- `trigger`: 需要统一 Linux/Ubuntu bring-up 的内存、设备、镜像路径和 bootargs。
- `depends_on`: `share-page-requirements-extract`
- `inputs`: `npc/rv64/tools/npc-rv64.dts`, 现有 OpenSBI/Linux smoke 布局。
- `action`: 新增 `npc/rv64/platform/npc-rv64.yml`、`gen_dts.py`、`README.md`，支持 kernel/initramfs/rootfs mode。
- `outputs`: 可生成 ordinary DTB、initramfs DTB 和 rootfs/virtio 预留 DTB。
- `evidence`: `make -C npc/rv64/tools dtb rootfs-dtb initramfs-dtb` PASS；fdtget 验证 512MiB memory、`virtio,mmio`、PLIC `riscv,ndev=32`。
- `handoff_to`: `bringup-scripts`
- `next_step`: 接入构建与 smoke 脚本。
- `notes`: rootfs mode 是未来 virtio-blk 平台预留，不表示当前硬件已可 mount rootfs。

### [2026-05-31] `bringup-scripts` - `completed`

- `owner_agent`: `npc`
- `trigger`: 需要一键构建 OpenSBI、Linux、BusyBox initramfs 和 Ubuntu 22.04 rootfs。
- `depends_on`: `platform-profile`
- `inputs`: 分享页建议、现有 Makefile/tools smoke。
- `action`: 新增 `setup-env.sh`、`build-opensbi.sh`、`build-linux.sh`、`build-busybox-initramfs.sh`、`build-ubuntu-rootfs.sh`、`run-linux-initramfs.sh`、`collect-linux-log.sh`；顶层 Makefile 增加对应入口。
- `outputs`: `make -C npc/rv64 setup-env/opensbi/linux/initramfs/ubuntu-rootfs/linux-initramfs`。
- `evidence`: `bash -n npc/rv64/scripts/*.sh npc/rv64/regression/run_all.sh` PASS；`python3 -m py_compile npc/rv64/platform/gen_dts.py` PASS。
- `handoff_to`: `busybox-initramfs`
- `next_step`: 先生成可跑的 static BusyBox initramfs。
- `notes`: `setup-env` 和 `ubuntu-rootfs` 需要 sudo。

### [2026-05-31] `busybox-initramfs` - `completed`

- `owner_agent`: `npc`
- `trigger`: Linux kernel smoke 需要真实 initramfs payload。
- `depends_on`: `bringup-scripts`
- `inputs`: `riscv64-linux-gnu-gcc`, BusyBox 1.36.1。
- `action`: 将 BusyBox 构建收敛为 minimal static allnoconfig，避免 defconfig applet 编译失败。
- `outputs`: `/tmp/ysyx-initramfs/rootfs.cpio`。
- `evidence`: BusyBox ELF 为 riscv64 statically linked；cpio 约 803 KiB。
- `handoff_to`: `linux-initramfs-smoke`
- `next_step`: 用 OpenSBI + kernel + generated initramfs DTB 启动。
- `notes`: 本轮先用 BusyBox 作为 Ubuntu rootfs 前的可控 gate。

### [2026-05-31] `linux-initramfs-smoke` - `partial`

- `owner_agent`: `npc`
- `trigger`: 验证环境入口不是只会生成文件，而是真实交给 OpenSBI/Linux 执行。
- `depends_on`: `busybox-initramfs`
- `inputs`: OpenSBI `fw_jump.bin`、Linux kernel fallback、generated initramfs DTB、BusyBox cpio。
- `action`: 运行 `make -C npc/rv64/tools smoke-linux-initramfs` 的 5M 与 20M smoke。
- `outputs`: `npc/rv64/build/linux-logs/smoke-initramfs-quick/`, `npc/rv64/build/linux-logs/smoke-initramfs-20m/`。
- `evidence`: 日志显示加载 `build/npc-rv64-initramfs.dtb` 和 `/tmp/ysyx-initramfs/rootfs.cpio`；OpenSBI Domain0 next address `0x80200000`、next arg1 `0x82200000`、S-mode；20M 到 `pc=0xffffffff80215020/commits=9322573`。
- `handoff_to`: `ubuntu-rootfs-build`
- `next_step`: 生成 Ubuntu rootfs，或继续把 initramfs shell 路径闭合。
- `notes`: 结果为 partial，因为仍未出现 Linux banner 或 shell。

### [2026-05-31] `ubuntu-rootfs-build` - `blocked`

- `owner_agent`: `npc`
- `trigger`: 用户目标要求真正 Ubuntu 22.04。
- `depends_on`: `bringup-scripts`
- `inputs`: `build-ubuntu-rootfs.sh`
- `action`: 检查本机是否能无人值守安装/运行 rootfs 构建依赖。
- `outputs`: rootfs 构建脚本已接入，但未生成 `/tmp/ysyx-ubuntu2204/ubuntu-22.04-riscv64.*`。
- `evidence`: `sudo -n true` 失败；当前缺 `debootstrap`、`qemu-riscv64-static`，已有 `riscv64-linux-gnu-gcc`、`dtc`、`verilator`、`mkfs.ext4`、`cpio`、`curl`。
- `handoff_to`: user/environment
- `next_step`: 在当前 WSL 内安装依赖后运行 `make -C npc/rv64 ubuntu-rootfs`。
- `notes`: 这是环境权限阻塞，不是仓库脚本缺失。

### [2026-05-31] `memory-taskrun-update` - `completed`

- `owner_agent`: `hardware-flow`
- `trigger`: AGENTS 要求完成重要任务后更新 memory/task-runs。
- `depends_on`: `linux-initramfs-smoke`, `ubuntu-rootfs-build`
- `inputs`: 本轮变更、验证日志、阻塞点。
- `action`: 更新 project-status、npc、agent-system、known-issues，并创建 task-run 报告。
- `outputs`: `.github/task-runs/2026-05-31-rv64-ubuntu2204-bringup-env/`。
- `evidence`: 记录包含已完成 gate 与未闭合 gate。
- `handoff_to`: future Linux/Ubuntu bring-up work
- `next_step`: 继续从 initramfs shell 和 Ubuntu rootfs 两条线闭合。
- `notes`: 记录口径保持保守，避免误报完整 Ubuntu boot。

### [2026-05-31] `ubuntu-base-initramfs` - `completed`

- `owner_agent`: `npc`
- `trigger`: `debootstrap/qemu-user-static` 需要 sudo，目标仍要求尽量完成 Ubuntu 22.04 启动环境。
- `depends_on`: `ubuntu-rootfs-build`
- `inputs`: Canonical Ubuntu Base 22.04.5 riscv64 tarball 与 `SHA256SUMS`。
- `action`: 新增并执行 `scripts/build-ubuntu-base-initramfs.sh`，下载、校验、普通用户解包 Ubuntu Base rootfs，写入 `/init`，生成 newc cpio。
- `outputs`: `/tmp/ysyx-ubuntu2204/ubuntu-22.04-riscv64.cpio`。
- `evidence`: `ubuntu-base-22.04.5-base-riscv64.tar.gz: OK`；cpio 59M；rootfs `VERSION_ID="22.04"`、`VERSION="22.04.5 LTS (Jammy Jellyfish)"`；cpio 内含 `init/etc/os-release/usr/bin/sh/usr/lib/ld-linux-riscv64-lp64d.so.1`。
- `handoff_to`: `ubuntu-initramfs-smoke`
- `next_step`: 生成 Ubuntu initramfs DTB 并运行 smoke。
- `notes`: 这条路线绕过 sudo，但不替代最终 ext4/virtio rootfs。

### [2026-05-31] `ubuntu-initramfs-smoke` - `partial`

- `owner_agent`: `npc`
- `trigger`: 验证 Ubuntu Base initramfs 是否被真实 OpenSBI/Linux 接收。
- `depends_on`: `ubuntu-base-initramfs`
- `inputs`: OpenSBI `fw_jump.bin`、Linux kernel、Ubuntu initramfs DTB、Ubuntu Base cpio。
- `action`: `ubuntu-initramfs-dtb` 使用 `rdinit=/init` 生成 DTB，运行 5M 与 20M `smoke-ubuntu-initramfs`。
- `outputs`: `npc/rv64/build/linux-logs/smoke-ubuntu-initramfs-quick/`, `npc/rv64/build/linux-logs/smoke-ubuntu-initramfs-20m/`。
- `evidence`: DTB bootargs 为 `console=ttyS0 earlycon rdinit=/init`，initrd 范围 `0x84000000..0x87afaa00`；20M 日志显示加载 59M Ubuntu cpio、OpenSBI Domain0 handoff 到 S-mode，最终 `pc=0xffffffff80215020/commits=9322573`。
- `handoff_to`: future kernel/initramfs debug
- `next_step`: 继续定位为什么尚未出现 `[ysyx-init]` 和 Ubuntu `/etc/os-release` 串口输出。
- `notes`: 20M 仍因 max-cycles 退出，不能标记 Ubuntu 用户态完成。

### [2026-05-31] `env-localization` - `completed`

- `owner_agent`: `npc`
- `trigger`: 用户要求“所有开发环境需要的套件都集成到 ysyx-workbench 中，不要放到其他地方”。
- `depends_on`: `bringup-scripts`, `busybox-initramfs`, `ubuntu-base-initramfs`
- `inputs`: `/tmp/ysyx-linux`, `/tmp/ysyx-opensbi`, `/tmp/busybox-1.36.1`, `/tmp/ysyx-initramfs`, `/tmp/ysyx-ubuntu2204` 以及当前脚本默认路径。
- `action`: 新增 `npc/rv64/env/README.md`；`.gitignore` 只跟踪 README，忽略大体积源码/镜像；脚本默认使用 `NPC_RV64_ENV_ROOT` 或 `npc/rv64/env`；`setup-env.sh` 改为创建本地 Python venv 并把 pip cache 放入 `env/downloads`；`tools/Makefile` 优先使用 `env/tools/python/bin/python3` 和可选 `env/toolchains/`。
- `outputs`: OpenSBI build、Linux v6.6 build、BusyBox 源码/initramfs、Ubuntu Base tarball/SHA256/rootfs/cpio 和 smoke 日志均默认位于 `npc/rv64/env/`。
- `evidence`: `setup-env.sh` 创建 `npc/rv64/env/tools/python` 并安装 PyYAML；`bash -n npc/rv64/scripts/*.sh npc/rv64/regression/run_all.sh` PASS；本地 Python `py_compile gen_dts.py` PASS；`build-ubuntu-base-initramfs.sh` 在 `env/downloads` 中 SHA256 `OK`；`make -C npc/rv64/tools initramfs-dtb rootfs-dtb ubuntu-initramfs-dtb` PASS；1M `smoke-ubuntu-initramfs` 从 `../env/build/opensbi-npc`, `../env/src/linux`, `../env/images/ubuntu2204` 加载镜像，`total guest instructions=1034881`。
- `handoff_to`: future kernel/initramfs debug
- `next_step`: 后续继续在 `npc/rv64/env/logs/` 下收集 smoke 日志，并从 guest `/init` 未出现的问题继续定位。
- `notes`: apt/Verilator/dtc/riscv64-linux-gnu 这类宿主基础命令仍属于 WSL 内已有工具；若要自带工具链，可放入 `npc/rv64/env/toolchains/`，脚本会优先使用。

### [2026-05-31] `qemu-ubuntu-probe` - `completed`

- `owner_agent`: `npc`
- `trigger`: 需要一个参考平台确认 Ubuntu 22.04 probe initramfs 内容、bootargs 和 `/init` 输出路径正确。
- `depends_on`: `ubuntu-base-initramfs`, `env-localization`
- `inputs`: 本地 QEMU、OpenSBI、Linux 6.6 Image、Ubuntu probe cpio、generated initramfs DTB。
- `action`: 新增/使用 `scripts/build-qemu.sh` 与 `scripts/run-qemu-ubuntu-initramfs.sh`，并让 `ubuntu-initramfs-dtb` 自动重建 probe cpio。
- `outputs`: `npc/rv64/env/logs/qemu/ubuntu-initramfs.log`。
- `evidence`: `make -C npc/rv64 qemu-ubuntu-initramfs QEMU_TIMEOUT=20s` PASS；输出 `[ysyx-init] Ubuntu 22.04 initramfs reached...`、`PRETTY_NAME="Ubuntu 22.04.5 LTS"`、`VERSION_ID="22.04"`、`UBUNTU_CODENAME=jammy`。
- `handoff_to`: `npc-ubuntu-probe`
- `next_step`: 使用 NPC 实核运行同一 OpenSBI/Linux/DTB/cpio 链路。
- `notes`: QEMU 证明镜像和 Linux 用户态路径正确，不替代 NPC RTL 证明。

### [2026-05-31] `npc-ubuntu-probe` - `completed-with-followup`

- `owner_agent`: `npc`
- `trigger`: 用户目标是用自己的 core 启动 Ubuntu 22.04 probe。
- `depends_on`: `qemu-ubuntu-probe`
- `inputs`: `npc/rv64/build/NpcSimTop`、OpenSBI `fw_jump.bin`、Linux Image、`npc-rv64-ubuntu-initramfs.dtb`、`ubuntu-22.04-riscv64-probe.cpio`。
- `action`: 多轮长跑 NPC smoke，最终在默认关闭 `linux_hang_probe` 后记录 `npc-ubuntu-final-clean2.log/out`。
- `outputs`: `npc/rv64/env/logs/linux-smoke/npc-ubuntu-final-clean2.log`, `npc/rv64/env/logs/linux-smoke/npc-ubuntu-final-clean2.out`。
- `evidence`: 日志包含 Linux 6.6、`console [ttyS0] enabled`、`Freeing unused kernel image (initmem)`、`Run /init as init process`；stdout 出现用户态 banner 前缀 `[ysyx-init] Ubun...`。
- `handoff_to`: `rtl-shortfall-fixes`
- `next_step`: 修 NPC UART/tty 用户态长 write 可见性，并继续补完整 F/D 与官方 shell/rootfs 路线。
- `notes`: 当前可表述为 NPC 已进入并执行 Ubuntu probe `/init`；不能表述为官方 Ubuntu `/bin/sh` 已可交互运行。

### [2026-05-31] `rtl-shortfall-fixes` - `completed`

- `owner_agent`: `npc`
- `trigger`: 用户要求“缺少相关指令集就自动补全 RTL 相关逻辑”，同时 Linux 长跑暴露 RAS/IRQ/unaligned/debug 可见性短板。
- `depends_on`: `npc-ubuntu-probe`
- `inputs`: Linux panic/Oops 轨迹、OpenSBI recursive trap 轨迹、Ubuntu probe 运行日志。
- `action`: 禁用 direct RAS ret 快路径；把 pending IRQ 纳入 dispatch valid gate；补 F/D CSR/MISA/FS 和 FPR load-store/RVC FP load-store 基础；Linux build 自动跳过 RISC-V unaligned benchmark；`NPC_LINUX_HANG_PROBE` 改为显式开启。
- `outputs`: RTL/C++/Linux patch 更新与 FP smoke。
- `evidence`: `make -C npc/rv64 -j1` PASS；`make -C npc/rv64/tools smoke-fp-loadstore` GOOD TRAP，`cycles=219/commits=34`。
- `handoff_to`: future full Ubuntu shell/rootfs work
- `next_step`: F/D 继续补 FPR->GPR、FP arithmetic/conversion，并修 UART/tty 用户态长输出。
- `notes`: 这些是 bring-up 必要短板修补，仍不是完整 rv64gc/lp64d 用户态闭环。
