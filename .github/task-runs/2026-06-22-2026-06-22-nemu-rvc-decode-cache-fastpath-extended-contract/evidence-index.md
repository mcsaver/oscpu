# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract
- `task_slug`: 2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 413852

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1008
- `line_count`: 15
- `sha256`: c9a43f788d2dba4493db1cf8c32068b1cfe2ee90d68ba27f9aa85e1982e664fb
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {}
- `summary`: log evidence; size=1008 bytes; lines=15; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8494
- `line_count`: 99
- `sha256`: 7f12c86aff1aa34defc4220ecf45d15902cd356578bdc339cdd19806436f5887
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {}
- `summary`: log evidence; size=8494 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8187
- `line_count`: 92
- `sha256`: c2c04d5cc7cf234b833e4a1f7c1ed9f0a078785ec8f0f3a793c87974044286ac
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {}
- `summary`: log evidence; size=8187 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7455
- `line_count`: 68
- `sha256`: 1dd2660074fbe50baccdd67dea773e593b2e9447e122377e658f96339ae787aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {}
- `summary`: log evidence; size=7455 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 127612
- `line_count`: 2290
- `sha256`: 419e7d3fe7cd9d69d59175970a797d4e22c2b113a7f42bdccf544af4ce46c060
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2353, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=127612 bytes; lines=2290; FAIL=4; PASS=2353; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=light.py %s_OB_SIZE_PADDR PASS nemu-python-int-preflight.py emit_pylong_ob_size_paddr PASS nemu-python-int-preflight.py /proc/self/pagemap PASS nemu-python-int-preflight.py %s_ERROR_STATE PASS nemu-python-int-preflight.py %s_MAX_REASONABLE_BIT_LENGTH PASS n...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 253405
- `line_count`: 4427
- `sha256`: 11c03d2ec4c4811f9588585a25b964410e8304709a6c089a89f33f087caea565
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=253405 bytes; lines=4427; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=le_breakpoint_packet] GDB stub removed hardware breakpoint at 0x0000000080000008 [0m [1;34m[src/monitor/gdbstub.c:753 handle_continue] GDB stub continue requested [0m [1;34m[src/device/syscon.c:24 syscon_reset_io_handler] syscon-reset: poweroff requested va...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 803
- `line_count`: 3
- `sha256`: 931415dad13361a42c11b2aeccc68c3d25aa61da07eac5504583b122ddd1e278
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=803 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/evidence/software-flow-contract.log nemu-ubuntu-stat...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3841
- `line_count`: 94
- `sha256`: 60989cdcf28b9b3783f9c75e2ee49970f138818c93831faed702da4184e3cf33
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T18:35:07+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3841 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-extended-contract/dispatch...
