# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke
- `task_slug`: 2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 8
- `total_size_bytes`: 224801

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 752
- `line_count`: 9
- `sha256`: 8436d91cae7f3d3c287e8dfb8ecbd85054b584e5b13dcedb3552f12922dd368d
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {}
- `summary`: log evidence; size=752 bytes; lines=9; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8191
- `line_count`: 99
- `sha256`: 7ba996db4a660efa281e086ee16d4a8989b5ca72ea6fcc4e825f635a95b0dfe1
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {}
- `summary`: log evidence; size=8191 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7884
- `line_count`: 92
- `sha256`: 97b16e23b5b5a3568a756b33396a827e8f7bc01cce5b546c75b95c6df80ecf89
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {}
- `summary`: log evidence; size=7884 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 201063
- `line_count`: 3423
- `sha256`: 9a548f55723497a94e8d91e694a3e4dd8c4fe2b5a1345b2be6edbc6c1f58422c
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {"FAIL": 43, "GOOD_TRAP": 29, "PASS": 532, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_QMP_SMOKE__"]}
- `summary`: log evidence; size=201063 bytes; lines=3423; FAIL=43; PASS=532; GOOD_TRAP=29; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__,__NEMU_QMP_SMOKE__; tail=lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-monitor-cmd-smoke-nemu.log' \ --monitor-cmd='info r' \ > '/home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-monitor-cmd-smoke.log' 2>&1 [1;34m[src/utils/log.c:30 init_log] Log is written to /home/l...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/nodes.tsv

- `kind`: tsv
- `size_bytes`: 463
- `line_count`: 2
- `sha256`: 1c2a856c370d5208521c3afd24f838b9231dac74c171ef08cb1b60b836c78889
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: tsv evidence; size=463 bytes; lines=2; FAIL=2; PASS=2; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/evidence/software-flow-contract.log nemu-ubuntu-static nemu ne...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/run-manifest.json

- `kind`: json
- `size_bytes`: 3401
- `line_count`: 86
- `sha256`: 1003b8a5b8365ab5cf6955f3ce8dee82cb0254d15ab35bee175e4900ce52d745
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T09:19:29+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: json evidence; size=3401 bytes; lines=86; FAIL=4; PASS=4; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-not-taken-branch-e2e-smoke/dispatch-log.md", "evidence_...
