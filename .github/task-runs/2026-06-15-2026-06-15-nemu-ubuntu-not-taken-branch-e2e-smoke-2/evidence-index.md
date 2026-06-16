# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2
- `task_slug`: 2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 10
- `total_size_bytes`: 349192

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 9
- `sha256`: 8436d91cae7f3d3c287e8dfb8ecbd85054b584e5b13dcedb3552f12922dd368d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {}
- `summary`: log evidence; size=752 bytes; lines=9; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8191
- `line_count`: 99
- `sha256`: 7ba996db4a660efa281e086ee16d4a8989b5ca72ea6fcc4e825f635a95b0dfe1
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {}
- `summary`: log evidence; size=8191 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7884
- `line_count`: 92
- `sha256`: 97b16e23b5b5a3568a756b33396a827e8f7bc01cce5b546c75b95c6df80ecf89
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {}
- `summary`: log evidence; size=7884 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 6406
- `line_count`: 61
- `sha256`: 063ab89d4a3de0ed7d93987a63af0d1308c097354a3e7ad84e12049f5cfdb711
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {}
- `summary`: log evidence; size=6406 bytes; lines=61; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 100298
- `line_count`: 1852
- `sha256`: 2060c2f8e7391171e43dfa8d77683a18840c6baaf92010dfb6f00b111c004ca7
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 15, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2302, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=100298 bytes; lines=1852; FAIL=15; PASS=2302; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=d-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_START__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TARGET__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__ PASS...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 218044
- `line_count`: 3945
- `sha256`: f85bd3d5e9eb037df12513af908fdecbf048e0be65f7b1a26a45998f4025dfe2
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=218044 bytes; lines=3945; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=4m[src/utils/log.c:30 init_log] Log is written to /home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-gdbstub-smoke-nemu.log.hbreak [0m [1;34m[src/memory/paddr.c:116 init_mem] physical memory area [0x80000000, 0xbfffffff] [0m [1;34m[src/device/io/mmio...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/nodes.tsv

- `kind`: tsv
- `size_bytes`: 728
- `line_count`: 3
- `sha256`: 2aab1fba9209a36c8714a7041f70fa54dff7d0bbced5f8f42ad7257f2f736ea8
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=728 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/evidence/software-flow-contract.log nemu-ubuntu-static nemu...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/run-manifest.json

- `kind`: json
- `size_bytes`: 3842
- `line_count`: 95
- `sha256`: ffb1e0c49e90900bd4e684311cfcde737f475dfcd73ac709d6d6aa3c116cf856
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:23:00+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3842 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke-2/dispatch-log.md", "evide...
