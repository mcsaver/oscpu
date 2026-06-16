# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke
- `task_slug`: 2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke
- `profile`: nemu-ubuntu-profile
- `asset_count`: 11
- `total_size_bytes`: 390081

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 887
- `line_count`: 12
- `sha256`: 6e02a626a684c2dd233c354025c28b8c8dd35eb9e15410e06f1ad94ff0525983
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {}
- `summary`: log evidence; size=887 bytes; lines=12; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8304
- `line_count`: 99
- `sha256`: a9ffcb3618cc8797db14514404c0dfa65094ccb4584c47a0808044ff27548c30
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {}
- `summary`: log evidence; size=8304 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7997
- `line_count`: 92
- `sha256`: 4c6fe4e3d54b61a0289a6302ae13ca4403dce4062b8b604c1ee1550cf7178b25
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {}
- `summary`: log evidence; size=7997 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7265
- `line_count`: 68
- `sha256`: 0bc3f8ef6b545a96ad51b2dcb6e50d200a02ddb089cb3b1f47fdca17521fb1cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {}
- `summary`: log evidence; size=7265 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-ubuntu-profile.log

- `kind`: log
- `size_bytes`: 132
- `line_count`: 2
- `sha256`: c9140b95a41939e0e12c613904aaa209089f30f72370b1a27107602fc5c0ce2f
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=132 bytes; lines=2; SKIP=2; tail=[nemu-ubuntu] heavy performance profile gate [nemu-ubuntu] SKIP: set AGENT_E2E_NEMU_PROFILE_GATE=1 to run heavy NEMU Ubuntu profile

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 110592
- `line_count`: 2009
- `sha256`: c5932586b99f40084d932ee99294cc1008caf911fc8b37ff028c8d9d0e272cc8
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2356, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=110592 bytes; lines=2009; FAIL=7; PASS=2356; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=-guest.sh http://nemu.local/nemu-health PASS check-nemu-systemd-guest.sh http://nemu.local/nemu-missing PASS check-nemu-systemd-guest.sh http://nemu.local/ubuntu PASS check-nemu-systemd-guest.sh apt-get download nemu-hostless-hello:riscv64=1.0 PASS check-ne...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246494
- `line_count`: 4315
- `sha256`: d118a11f8a0881b171b59a0bb71c2c5f8b060e7fa8cd453eaa21599ee0e8fe84
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246494 bytes; lines=4315; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1049
- `line_count`: 4
- `sha256`: 001ec7adc6e6cf8ebcdd52d9e612cab88ffb2368713ad2a282f461aa234678bc
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {"PASS": 8, "SKIP": 2}
- `summary`: tsv evidence; size=1049 bytes; lines=4; SKIP=2; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/evidence/software-flow-contract.log nemu-ubuntu-static...

### .github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/run-manifest.json

- `kind`: json
- `size_bytes`: 4314
- `line_count`: 104
- `sha256`: da7fe18e3aabcffaa92f9b85521bd4666133183a180e04c9b51483a5850d0609
- `encoding`: utf-8
- `indexed_at`: 2026-06-15T23:21:57+00:00
- `markers`: {"PASS": 10, "SKIP": 6}
- `summary`: json evidence; size=4314 bytes; lines=104; SKIP=6; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-ubuntu-decode-profile-branch-split-smoke/dispatch-log.m...
