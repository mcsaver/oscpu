# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4
- `task_slug`: 2026-06-16-nemu-dev-runtime-isolation-pass-4
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 392363

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 887
- `line_count`: 12
- `sha256`: 6e02a626a684c2dd233c354025c28b8c8dd35eb9e15410e06f1ad94ff0525983
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {}
- `summary`: log evidence; size=887 bytes; lines=12; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8304
- `line_count`: 99
- `sha256`: a9ffcb3618cc8797db14514404c0dfa65094ccb4584c47a0808044ff27548c30
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {}
- `summary`: log evidence; size=8304 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7997
- `line_count`: 92
- `sha256`: 4c6fe4e3d54b61a0289a6302ae13ca4403dce4062b8b604c1ee1550cf7178b25
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {}
- `summary`: log evidence; size=7997 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7265
- `line_count`: 68
- `sha256`: 0bc3f8ef6b545a96ad51b2dcb6e50d200a02ddb089cb3b1f47fdca17521fb1cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {}
- `summary`: log evidence; size=7265 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 114080
- `line_count`: 2063
- `sha256`: ffba2ceecbc504ae819dd1ff838a3e9c46951dd2c4032f9aa10a6ff48e3096d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2361, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=114080 bytes; lines=2063; FAIL=7; PASS=2361; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=emu-systemd-guest.sh __NEMU_CHECK_FULL_SSH_NOPAM_CLIENT_BEGIN__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_SSH_NOPAM_DEBUGD_LOG_BEGIN__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_SSH_NOPAM_LOGIN_OK__ PASS check-nemu-systemd-guest.sh __NEMU_C...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246409
- `line_count`: 4314
- `sha256`: e4c9c72765ff0c6a59cf64fa7a35b2fb0ad326727336ffa865c9f726436802aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246409 bytes; lines=4314; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/nodes.tsv

- `kind`: tsv
- `size_bytes`: 758
- `line_count`: 3
- `sha256`: 917f9ca9de36829f56ce0446bf2e4dc8b500593aae455f5a62f089acfce6b304
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=758 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PA...

### .github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/run-manifest.json

- `kind`: json
- `size_bytes`: 3616
- `line_count`: 94
- `sha256`: b2fd8c7408d46852423b2bd4b398fbdfcf27d882a4e5e5b60759cb6800c3b6f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T01:59:36+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3616 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-dev-runtime-isolation-pass-4/dispatch-log.md", "evidence_dir": ".gi...
