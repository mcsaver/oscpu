# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation
- `task_slug`: 2026-06-14-nemu-slow-diag-input-chunk-env-isolation
- `profile`: nemu-ubuntu
- `asset_count`: 10
- `total_size_bytes`: 372968

## 证据资产

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7332
- `line_count`: 93
- `sha256`: 5c00a003e5d26b7871e9a4581528b8ccb422166964738d92430fde571123a67d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {}
- `summary`: log evidence; size=7332 bytes; lines=93; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7025
- `line_count`: 86
- `sha256`: 26d23d9464a22a0ade66874d08bbdaec5f4fea9ff0f155331c56ebca86616707
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {}
- `summary`: log evidence; size=7025 bytes; lines=86; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 99157
- `line_count`: 1829
- `sha256`: 523a275164094b4d03c41050d13fe441ddc13e7c408be4ff6e28626a8641e6a7
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2301, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=99157 bytes; lines=1829; FAIL=7; PASS=2301; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=U_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_HOSTLES...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 245317
- `line_count`: 4299
- `sha256`: 7b7296f5e59539da65766a716f1c8e0b56e7513ff3a5e50ba4b5748dc3b36e07
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 367, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=245317 bytes; lines=4299; PASS=367; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=1;32mHIT GOOD TRAP[0m at pc = 0x000000008000000c[0m [1;34m[src/device/disk.c:429 virtio_blk_statistic] virtio-blk async runtime submitted=0 completed=0 pending=0 done=0[0m [1;34m[src/device/net.c:2391 virtio_net_statistic] virtio-net runtime tx_packets...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/nodes.tsv

- `kind`: tsv
- `size_bytes`: 779
- `line_count`: 3
- `sha256`: de403849070c27cff98b240da6d8c980ce7dcd2e15ee0cd359ef530efbf616e1
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=779 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/evidence/software-flow-contract.log nemu-ubuntu-static nemu...

### .github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/run-manifest.json

- `kind`: json
- `size_bytes`: 3727
- `line_count`: 94
- `sha256`: a45d593fb171b1cc5c40b4c695cbf4825e7b6d4de3954eb18ae57c8bc4158f01
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T17:34:52+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3727 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-14-nemu-slow-diag-input-chunk-env-isolation/dispatch-log.md", "evide...
