# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke
- `task_slug`: 2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 7
- `total_size_bytes`: 44780

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 836
- `line_count`: 11
- `sha256`: 9396f30f2304f5055e5dd517873128217e28f117cf15bb6cd7592958571bd37a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {}
- `summary`: log evidence; size=836 bytes; lines=11; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8216
- `line_count`: 99
- `sha256`: 405fddef5f75d4547c252896d8da740276248dfa7f46e9d72889b208ba5f3384
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {}
- `summary`: log evidence; size=8216 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7909
- `line_count`: 92
- `sha256`: 2f9d83a7a92b261ef1a20c6d4997ba8c6e02546463deee39c2043af57f822f97
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {}
- `summary`: log evidence; size=7909 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 21391
- `line_count`: 310
- `sha256`: e8432a14b3845aef95b427354c80c4b6e60d1a6c60445f4ee306863da5c7820e
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {"PASS": 194}
- `summary`: log evidence; size=21391 bytes; lines=310; PASS=194; tail=[nemu-ubuntu] static production gate PASS Linux/Makefile PASS Linux/scripts/build-linux.sh PASS Linux/scripts/build-ubuntu-rootfs.sh PASS Linux/scripts/build-ubuntu-systemd-overlay.sh PASS Linux/scripts/gen-nemu-hostless-apt-assets.py PASS Linux/scripts/ubu...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/nodes.tsv

- `kind`: tsv
- `size_bytes`: 475
- `line_count`: 2
- `sha256`: 736d7feb317ec43893850b4e2016858612cd9925d48814ccebc077bd03105b8a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: tsv evidence; size=475 bytes; lines=2; FAIL=2; PASS=2; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/evidence/software-flow-contract.log nemu-ubuntu-static n...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/run-manifest.json

- `kind`: json
- `size_bytes`: 3484
- `line_count`: 86
- `sha256`: ef3790a2cab5b33a335cffea82c513f5f900dbb84de6d39fa9aa294154fc3f72
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:55:53+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: json evidence; size=3484 bytes; lines=86; FAIL=4; PASS=4; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-profile-inline-counter-e2e-smoke/dispatch-log.md"...
