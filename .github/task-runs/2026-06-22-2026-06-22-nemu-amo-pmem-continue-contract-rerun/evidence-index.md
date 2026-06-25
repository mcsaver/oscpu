# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun
- `task_slug`: 2026-06-22-nemu-amo-pmem-continue-contract-rerun
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 419173

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1090
- `line_count`: 17
- `sha256`: 4d01ea2f11d2f1bf4b6d67538818c3629e68480a1a4802a73cf6e4bd2f89c702
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=1090 bytes; lines=17; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8580
- `line_count`: 99
- `sha256`: 8b97095b96bbd4bb00c11703c3150891927279b99d20ec5bd3018cac0d7d6d22
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=8580 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8273
- `line_count`: 92
- `sha256`: ed2106e77f209dc68de808e3f668b2dae9abd87471dfbe71b9d983cace12d890
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=8273 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7541
- `line_count`: 68
- `sha256`: 196279a5291224b3582e92e5b621a39890334d471031a39b825fa4a17853446e
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=7541 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 131495
- `line_count`: 2344
- `sha256`: 6ecab7bdb4b9eb0353a8149949ecd609db27296755405a124c061f58a2b83896
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2328, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=131495 bytes; lines=2344; FAIL=4; PASS=2328; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=-hostless-hello_1.1_riscv64.deb PASS gen-nemu-hostless-apt-assets.py depends="nemu-hostless-hello (= 1.1)" PASS gen-nemu-hostless-apt-assets.py "depends": "nemu-hostless-hello (= 1.1)" PASS gen_dts.py stdout-path = "serial0:115200n8"; PASS gen_dts.py serial...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 254701
- `line_count`: 4444
- `sha256`: fdce0fdb9f47c4648b05bbefa95a3ce029058604a30c161b95da6237d5b286f2
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=254701 bytes; lines=4444; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail==0x00005555 pc=0x000000008000000c [0m [1;34m[src/cpu/cpu-exec.c:979 cpu_exec] nemu: [1;32mHIT GOOD TRAP [0m at pc = 0x000000008000000c [0m [1;34m[src/device/disk.c:429 virtio_blk_statistic] virtio-blk async runtime submitted=0 completed=0 pending=0 done=0 [...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 770
- `line_count`: 3
- `sha256`: 65a5fad0870e0cf137a7aeb38c3c1226d0b84a6359b257470ee93260fdb1ff1f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=770 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-static nemu nem...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 3676
- `line_count`: 94
- `sha256`: 5a3ef17cb4d0176eb9bd7fd93048fa126c28a6eb5196f4da5a67f64e15be7302
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3676 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-contract-rerun/dispatch-log.md", "evidence_di...
