# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun
- `task_slug`: 2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 411753

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1008
- `line_count`: 15
- `sha256`: c9a43f788d2dba4493db1cf8c32068b1cfe2ee90d68ba27f9aa85e1982e664fb
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {}
- `summary`: log evidence; size=1008 bytes; lines=15; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8494
- `line_count`: 99
- `sha256`: 7f12c86aff1aa34defc4220ecf45d15902cd356578bdc339cdd19806436f5887
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {}
- `summary`: log evidence; size=8494 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8187
- `line_count`: 92
- `sha256`: c2c04d5cc7cf234b833e4a1f7c1ed9f0a078785ec8f0f3a793c87974044286ac
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {}
- `summary`: log evidence; size=8187 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7455
- `line_count`: 68
- `sha256`: 1dd2660074fbe50baccdd67dea773e593b2e9447e122377e658f96339ae787aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {}
- `summary`: log evidence; size=7455 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 126727
- `line_count`: 2276
- `sha256`: c498d6ced040153f4aba305657a03039515714a376225d93a455908924187fa7
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2354, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=126727 bytes; lines=2276; FAIL=4; PASS=2354; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=PYLONG_ARGS_LOOPS_EARLY_ID PASS nemu-python-int-preflight.py PYLONG_ARGS_LOOPS_PREPARSE_CANDIDATE PASS nemu-python-int-preflight.py ARGS_LOOPS_PREPARSE_ID_MATCH PASS nemu-python-int-preflight.py PYLONG_PROBE_LOOPS_PREPARSE_CANDIDATE PASS nemu-python-int-pre...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 252245
- `line_count`: 4412
- `sha256`: 5e33708a561de134275d57b454fc43e5621caf9daf00f32cf97eac0713b1b7a8
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=252245 bytes; lines=4412; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=b inserted hardware breakpoint at 0x0000000080000008 kind=4 [0m [1;34m[src/monitor/gdbstub.c:753 handle_continue] GDB stub continue requested [0m [1;34m[src/cpu/cpu-exec.c:424 debug_breakpoint_stop] GDB stub breakpoint hit at pc = 0x0000000080000008 [0m [1;...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 794
- `line_count`: 3
- `sha256`: 60eba96ab840e3b2be5f838fdd199a38f824f7034dc4deabef9bdb9a536f9cdf
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=794 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-static...

### .github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 3796
- `line_count`: 94
- `sha256`: a69e6962f1c8e06cf995858b5cab1ff9cfbe378b0b45f8d409e68104a4796fe4
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:55:58+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3796 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-rvc-decode-cache-fastpath-contract-rerun/dispatch-log.m...
