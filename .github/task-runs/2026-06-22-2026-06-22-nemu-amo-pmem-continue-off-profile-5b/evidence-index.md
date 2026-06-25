# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b
- `task_slug`: 2026-06-22-nemu-amo-pmem-continue-off-profile-5b
- `profile`: nemu-ubuntu-profile
- `asset_count`: 8
- `total_size_bytes`: 279343

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 577
- `line_count`: 8
- `sha256`: 2c6f2b2924698c6e43d6463b4f9f8527ad94cca1b3e66d32c278b7d89b9eb215
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=577 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1090
- `line_count`: 17
- `sha256`: 4d01ea2f11d2f1bf4b6d67538818c3629e68480a1a4802a73cf6e4bd2f89c702
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=1090 bytes; lines=17; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8579
- `line_count`: 99
- `sha256`: c6a469df7114616e501e615f2890bad25a4f03c28c31235f682f1d63ad287e74
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=8579 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8272
- `line_count`: 92
- `sha256`: afff9cf9d8a1ffc33f7310ba085ae003e6163d70844f120cb202e8a6eef0be61
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=8272 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 254508
- `line_count`: 4442
- `sha256`: e14b373ff3e1ef15e52623709d0f6b8d73efb0e1ea1ed8b35d636082b6008014
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=254508 bytes; lines=4442; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=ue=0x00005555 pc=0x000000008000000c [0m [1;34m[src/cpu/cpu-exec.c:979 cpu_exec] nemu: [1;32mHIT GOOD TRAP [0m at pc = 0x000000008000000c [0m [1;34m[src/device/disk.c:429 virtio_blk_statistic] virtio-blk async runtime submitted=0 completed=0 pending=0 done=0...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/nodes.tsv

- `kind`: tsv
- `size_bytes`: 461
- `line_count`: 2
- `sha256`: b388e2eb5303a08dac5a723692e2789389c8ef611caccfc906c911fc797c6f63
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: tsv evidence; size=461 bytes; lines=2; FAIL=2; PASS=2; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/evidence/software-flow-contract.log nemu-ubuntu-static nemu nem...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/run-manifest.json

- `kind`: json
- `size_bytes`: 3387
- `line_count`: 86
- `sha256`: 1edbf888c938d00aff7f8d54dfc0bc20d833978c582d6b6aa71b3dcaf071baef
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: json evidence; size=3387 bytes; lines=86; FAIL=4; PASS=4; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-off-profile-5b/dispatch-log.md", "evidence_di...
