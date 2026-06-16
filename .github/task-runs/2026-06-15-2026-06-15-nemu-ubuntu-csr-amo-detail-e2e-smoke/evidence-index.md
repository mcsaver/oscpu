# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke
- `task_slug`: 2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 10
- `total_size_bytes`: 377675

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 9
- `sha256`: 8436d91cae7f3d3c287e8dfb8ecbd85054b584e5b13dcedb3552f12922dd368d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {}
- `summary`: log evidence; size=752 bytes; lines=9; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8128
- `line_count`: 99
- `sha256`: 26fe3a0f0a1445462004accda7c989e401eb46cccfb413fb59b1def61aa13596
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {}
- `summary`: log evidence; size=8128 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7821
- `line_count`: 92
- `sha256`: 36d130fd2672d30968223df443abecc33f6ff2d9bce6366776c3af415f2b0b60
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {}
- `summary`: log evidence; size=7821 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7089
- `line_count`: 68
- `sha256`: e1a1b27e1975d6bcc3e2032ba6a2988ef49443ecf78afbb66dc832c43dbaf35b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {}
- `summary`: log evidence; size=7089 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 103103
- `line_count`: 1898
- `sha256`: c51df6f42a449ca28901b81dab9035a4ef93e5ba773e89382409261a2b1ada5a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 9, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2325, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=103103 bytes; lines=1898; FAIL=9; PASS=2325; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=TART__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_TARGET__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_APT_STATE__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FUL...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 243235
- `line_count`: 4252
- `sha256`: e3e5b2c108e2de4d075ce861273aef312bd7c6634c06fcc1ca2686890900aaeb
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=243235 bytes; lines=4252; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail==/home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-gdbstub-smoke-nemu.log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swb...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/nodes.tsv

- `kind`: tsv
- `size_bytes`: 716
- `line_count`: 3
- `sha256`: 3ca6c1a8bf030142699df8777e2ff3e193abfaf0ad6490485125b0391637e886
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=716 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/run-manifest.json

- `kind`: json
- `size_bytes`: 3784
- `line_count`: 95
- `sha256`: 49d7afc6f37405bd31f1ff91a06f59398de27b232ee5d6c33cf90e898506a9c2
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T11:23:35+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3784 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-csr-amo-detail-e2e-smoke/dispatch-log.md", "evidence_dir"...
