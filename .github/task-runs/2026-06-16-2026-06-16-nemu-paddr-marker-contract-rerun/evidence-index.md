# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun
- `task_slug`: 2026-06-16-nemu-paddr-marker-contract-rerun
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 401063

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1008
- `line_count`: 15
- `sha256`: c9a43f788d2dba4493db1cf8c32068b1cfe2ee90d68ba27f9aa85e1982e664fb
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {}
- `summary`: log evidence; size=1008 bytes; lines=15; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 99
- `sha256`: 224816dcdf698c54e09e04ba403de9ea27fc7e3148847dc59deae4ec07ae3d90
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8079
- `line_count`: 92
- `sha256`: d33f9a526e1bc57bc3fb81e37088b976014532af01ff46972b07ba98ef2858c7
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {}
- `summary`: log evidence; size=8079 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7347
- `line_count`: 68
- `sha256`: b2afde1be14088270ae3e118293b0c47265b248631c3c9f599e00eb064c2fc0a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {}
- `summary`: log evidence; size=7347 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 118271
- `line_count`: 2129
- `sha256`: 885a9fa510e19a1af471c287d97e03efb067d2032904086ed146721a07ca5e66
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2349, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=118271 bytes; lines=2129; FAIL=7; PASS=2349; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=d full userland marker PASS nemu.sh PASS focused soak marker PASS nemu.sh FAIL focused soak marker PASS nemu.sh __NEMU_CHECK_PASS__:full-userland-runtime PASS nemu.sh __NEMU_CHECK_PASS__:soak-uptime PASS nemu.sh __NEMU_CHECK_PASS__:interrupts-stat-monotonic...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 250530
- `line_count`: 4384
- `sha256`: d5917c2207674bbaf5d08b313c88c4687cca0405fd37f45bf3c48de156679813
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=250530 bytes; lines=4384; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=[1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'syscon-reset' at [0x00100000, 0x00100fff] [0m [1;34m[src/monitor/monitor.c:149 load_img] No image is given. Use the default build-in image. [0m [1;34m[src/monitor/gdbstub.c:931 gdbstub_wait_for_clie...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 704
- `line_count`: 3
- `sha256`: 8c97fca3a67a5fe9f33abb37007eda8101e8e381101add0867c6307ee219ad56
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=704 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PAS...

### .github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 3691
- `line_count`: 95
- `sha256`: a7b9350a4e4204af40619b96216d31422dc82861a6f93adaa11014e01dc6c5e1
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T11:44:25+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3691 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-paddr-marker-contract-rerun/dispatch-log.md", "evidence_dir": ".gith...
