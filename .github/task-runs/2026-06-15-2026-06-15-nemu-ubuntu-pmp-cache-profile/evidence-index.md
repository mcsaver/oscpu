# Evidence Index

## 基本信息

- `task_id`: 2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile
- `task_slug`: 2026-06-15-nemu-ubuntu-pmp-cache-profile
- `profile`: nemu-ubuntu-profile
- `asset_count`: 10
- `total_size_bytes`: 379139

## 证据资产

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 836
- `line_count`: 11
- `sha256`: 9396f30f2304f5055e5dd517873128217e28f117cf15bb6cd7592958571bd37a
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {}
- `summary`: log evidence; size=836 bytes; lines=11; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8216
- `line_count`: 99
- `sha256`: 405fddef5f75d4547c252896d8da740276248dfa7f46e9d72889b208ba5f3384
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {}
- `summary`: log evidence; size=8216 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7909
- `line_count`: 92
- `sha256`: 2f9d83a7a92b261ef1a20c6d4997ba8c6e02546463deee39c2043af57f822f97
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {}
- `summary`: log evidence; size=7909 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7177
- `line_count`: 68
- `sha256`: 6eec0070e8118cfa1e89771cd5f7313ae598ed65093bf65776b3733112f7e05b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {}
- `summary`: log evidence; size=7177 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 104085
- `line_count`: 1914
- `sha256`: 51a69e8199a972d2e20a2e5e45ae9f14f7c19cf172adadd668e0ceaddc21a00b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 13, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2326, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=104085 bytes; lines=1914; FAIL=13; PASS=2326; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=U_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_MESSAGE_SNAPSHOT__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_DPKG_STATUS_SNAPSHOT__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_UPGRADE_META_ME...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 243495
- `line_count`: 4254
- `sha256`: 1c2b1fac587309dc79476ba9f60892fab5ac6e05ec37f29957505ca24e65843b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=243495 bytes; lines=4254; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail==/home/lyg/PA/ysyx-workbench/Linux/build/riscv64-nemu/nemu-gdbstub-smoke-nemu.log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swb...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/nodes.tsv

- `kind`: tsv
- `size_bytes`: 695
- `line_count`: 3
- `sha256`: ad38844efd69c18a931f2e457c5c20bfa0aae7e6b4e53f079dae7f827f9df42b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=695 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS L...

### .github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/run-manifest.json

- `kind`: json
- `size_bytes`: 3679
- `line_count`: 95
- `sha256`: a4a8f6f075c569d76eaaa9912d2b28353d1c363ffbc5150c8ec81e57bba3d299
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T12:21:11+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3679 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-15-2026-06-15-nemu-ubuntu-pmp-cache-profile/dispatch-log.md", "evidence_dir": ".github/tas...
