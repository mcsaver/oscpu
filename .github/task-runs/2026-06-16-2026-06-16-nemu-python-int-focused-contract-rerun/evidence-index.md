# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun
- `task_slug`: 2026-06-16-nemu-python-int-focused-contract-rerun
- `profile`: nemu-ubuntu-profile
- `asset_count`: 11
- `total_size_bytes`: 391586

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 887
- `line_count`: 12
- `sha256`: 6e02a626a684c2dd233c354025c28b8c8dd35eb9e15410e06f1ad94ff0525983
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {}
- `summary`: log evidence; size=887 bytes; lines=12; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8304
- `line_count`: 99
- `sha256`: a9ffcb3618cc8797db14514404c0dfa65094ccb4584c47a0808044ff27548c30
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {}
- `summary`: log evidence; size=8304 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7997
- `line_count`: 92
- `sha256`: 4c6fe4e3d54b61a0289a6302ae13ca4403dce4062b8b604c1ee1550cf7178b25
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {}
- `summary`: log evidence; size=7997 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7265
- `line_count`: 68
- `sha256`: 0bc3f8ef6b545a96ad51b2dcb6e50d200a02ddb089cb3b1f47fdca17521fb1cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {}
- `summary`: log evidence; size=7265 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-ubuntu-profile.log

- `kind`: log
- `size_bytes`: 132
- `line_count`: 2
- `sha256`: c9140b95a41939e0e12c613904aaa209089f30f72370b1a27107602fc5c0ce2f
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=132 bytes; lines=2; SKIP=2; tail=[nemu-ubuntu] heavy performance profile gate [nemu-ubuntu] SKIP: set AGENT_E2E_NEMU_PROFILE_GATE=1 to run heavy NEMU Ubuntu profile

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 112237
- `line_count`: 2034
- `sha256`: 1c95822ec36ab5ad6ceab296b40bb9f19158b1c78dc1e7b1448a9b31fef32fd8
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2358, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=112237 bytes; lines=2034; FAIL=7; PASS=2358; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=stall PASS check-nemu-systemd-guest.sh status-upgrade-installed-v1 PASS check-nemu-systemd-guest.sh status-remove-installed PASS check-nemu-systemd-guest.sh status-purge-config-files PASS check-nemu-systemd-guest.sh installed-v1-target-status-real-dpkg PASS...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246494
- `line_count`: 4315
- `sha256`: 5c6ef4aff8d09fb9cb2ab74de2111eb23caa829cf09e5b3540e7e67d4c55fea9
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246494 bytes; lines=4315; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1021
- `line_count`: 4
- `sha256`: ef5d14292dc772575b861c7fa6fef48d013b0cc4e3fe7dce98659810e9d5f18a
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {"PASS": 8, "SKIP": 2}
- `summary`: tsv evidence; size=1021 bytes; lines=4; SKIP=2; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-static nemu ne...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 4202
- `line_count`: 104
- `sha256`: 9a10ba41b4d965ddc1c2121c52c28e96538151a7537c4a9d239af44b7bb54923
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:11:03+00:00
- `markers`: {"PASS": 10, "SKIP": 6}
- `summary`: json evidence; size=4202 bytes; lines=104; SKIP=6; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract-rerun/dispatch-log.md", "evidence_...
