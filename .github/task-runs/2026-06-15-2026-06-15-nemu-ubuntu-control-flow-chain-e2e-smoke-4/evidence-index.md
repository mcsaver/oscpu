# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4
- `task_slug`: 2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 10
- `total_size_bytes`: 375880

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 9
- `sha256`: 8436d91cae7f3d3c287e8dfb8ecbd85054b584e5b13dcedb3552f12922dd368d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {}
- `summary`: log evidence; size=752 bytes; lines=9; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8128
- `line_count`: 99
- `sha256`: 26fe3a0f0a1445462004accda7c989e401eb46cccfb413fb59b1def61aa13596
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {}
- `summary`: log evidence; size=8128 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7821
- `line_count`: 92
- `sha256`: 36d130fd2672d30968223df443abecc33f6ff2d9bce6366776c3af415f2b0b60
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {}
- `summary`: log evidence; size=7821 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7089
- `line_count`: 68
- `sha256`: e1a1b27e1975d6bcc3e2032ba6a2988ef49443ecf78afbb66dc832c43dbaf35b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {}
- `summary`: log evidence; size=7089 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 101938
- `line_count`: 1877
- `sha256`: 5681287bbad10a8ad1444a8fcbe0058dcadba6f85dc6b888120d882e8cde185c
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 9, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2316, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=101938 bytes; lines=1877; FAIL=9; PASS=2316; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=_APT_DIRECT_FULL_STATUS_INSTALL_EFFECT_OK_AFTER_TIMEOUT__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__ PASS check-nemu-sys...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 242499
- `line_count`: 4238
- `sha256`: d50169f1aac52f789de762e9c3a03a64c7238f4445be2e431c5f2cd7df24ba6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 381, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=242499 bytes; lines=4238; PASS=381; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail== 0x0000000080000010 PASS continue-syscon-poweroff PASS continue-good-trap swbreak-command: /home/lyg/PA/ysyx-workbench/nemu/build/riscv64-nemu-interpreter --gdbstub=46894 --monitor-cmd=info r --log=/home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/nodes.tsv

- `kind`: tsv
- `size_bytes`: 734
- `line_count`: 3
- `sha256`: 623b8d305f16669ab882947f9058b67ddc41279790915a7d9adfb50d332c1b1d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=734 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/evidence/software-flow-contract.log nemu-ubuntu-static nem...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/run-manifest.json

- `kind`: json
- `size_bytes`: 3872
- `line_count`: 95
- `sha256`: bce17eb3f5005f0ce8b869988be4ba4543ea1cc389bc4a81cc648d3f04cb5b82
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T10:10:24+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3872 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-4/dispatch-log.md", "e...
