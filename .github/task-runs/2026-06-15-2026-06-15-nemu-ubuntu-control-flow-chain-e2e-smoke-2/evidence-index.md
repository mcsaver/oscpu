# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2
- `task_slug`: 2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 10
- `total_size_bytes`: 348905

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 9
- `sha256`: 8436d91cae7f3d3c287e8dfb8ecbd85054b584e5b13dcedb3552f12922dd368d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {}
- `summary`: log evidence; size=752 bytes; lines=9; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7729
- `line_count`: 94
- `sha256`: 5fdd2d5188625edf355943ab44f7ddb56c859b7234ac24bb6a12428c185aa3db
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {}
- `summary`: log evidence; size=7729 bytes; lines=94; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7422
- `line_count`: 87
- `sha256`: a6d62fe0513b26aa9bbeea55ad19257103afca024b68cbc50ca633e3d2555a72
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {}
- `summary`: log evidence; size=7422 bytes; lines=87; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 6670
- `line_count`: 63
- `sha256`: b68fa884a381431ff2973c7ff08f574d17fb724c74256493f5df3c337a4e9e7f
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {}
- `summary`: log evidence; size=6670 bytes; lines=63; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 101560
- `line_count`: 1873
- `sha256`: ec4117af997d3638d36a20af6bcd21bba68e6b6e262915b1845f6fdd76f79726
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 12, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2313, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=101560 bytes; lines=1873; FAIL=12; PASS=2313; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=ECT_FULL_STATUS_META_PREINST_SNAPSHOT__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_POSTINST_SNAPSHOT__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_META_DPKG_STATUS_SNAPSHOT__ PASS check-nemu-...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 217119
- `line_count`: 3935
- `sha256`: 3b7da900ef0a6f1e0977e25c1f96af3f8fe3ec9b4b3f3ad112356dbce8aa21c9
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=217119 bytes; lines=3935; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=34m[src/utils/log.c:30 init_log] Log is written to /home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-gdbstub-smoke-nemu.log.hbreak [0m [1;34m[src/memory/paddr.c:116 init_mem] physical memory area [0x80000000, 0xbfffffff] [0m [1;34m[src/device/io/mmi...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/nodes.tsv

- `kind`: tsv
- `size_bytes`: 734
- `line_count`: 3
- `sha256`: de48cc56b2a88f9c67ba38efdef589509a5351acd600741af4dd9b5a9edae5a8
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=734 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/evidence/software-flow-contract.log nemu-ubuntu-static nem...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/run-manifest.json

- `kind`: json
- `size_bytes`: 3872
- `line_count`: 95
- `sha256`: 09ef1f9dfded5e329caa2135cd66c860fec57dc8637d5dee2dfc7ee9afad9879
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:52:33+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3872 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-control-flow-chain-e2e-smoke-2/dispatch-log.md", "e...
