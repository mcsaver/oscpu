# Evidence Index

## 基本信息

- `task_id`: 2026-06-16-2026-06-16-nemu-python-int-focused-contract
- `task_slug`: 2026-06-16-nemu-python-int-focused-contract
- `profile`: nemu-ubuntu-profile
- `asset_count`: 10
- `total_size_bytes`: 390659

## 证据资产

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 887
- `line_count`: 12
- `sha256`: 6e02a626a684c2dd233c354025c28b8c8dd35eb9e15410e06f1ad94ff0525983
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {}
- `summary`: log evidence; size=887 bytes; lines=12; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8304
- `line_count`: 99
- `sha256`: a9ffcb3618cc8797db14514404c0dfa65094ccb4584c47a0808044ff27548c30
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {}
- `summary`: log evidence; size=8304 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7997
- `line_count`: 92
- `sha256`: 4c6fe4e3d54b61a0289a6302ae13ca4403dce4062b8b604c1ee1550cf7178b25
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {}
- `summary`: log evidence; size=7997 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7265
- `line_count`: 68
- `sha256`: 0bc3f8ef6b545a96ad51b2dcb6e50d200a02ddb089cb3b1f47fdca17521fb1cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {}
- `summary`: log evidence; size=7265 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 112237
- `line_count`: 2034
- `sha256`: 25913e7fb1caed5f06284b1cf70346adb57c58981dbeaf68e86570e3a5ba8279
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 11, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2354, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=112237 bytes; lines=2034; FAIL=11; PASS=2354; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=stall PASS check-nemu-systemd-guest.sh status-upgrade-installed-v1 PASS check-nemu-systemd-guest.sh status-remove-installed PASS check-nemu-systemd-guest.sh status-purge-config-files PASS check-nemu-systemd-guest.sh installed-v1-target-status-real-dpkg PASS...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 246494
- `line_count`: 4315
- `sha256`: f3bcbc921e4736b6d7bc1e7bc9242682ec9f7fa859b4f11706b13ac21ed64a9b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 379, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=246494 bytes; lines=4315; PASS=379; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=log.swbreak PASS swbreak-qSupported PacketSize=4000;qXfer:features:read+;qXfer:memory-map:read+;swbreak+;hwbreak+;watchpoint+;vContSupported+;async-stop+;QStartNoAckMode+ PASS swbreak-insert OK PASS swbreak-hit S05 PASS swbreak-vcont-hit S05 PASS swbreak-pc...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 704
- `line_count`: 3
- `sha256`: 3e74b7dfee17dc4412b49a46a0290c3fbe351e4ac3a6b3599ff28afc02c3bc28
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=704 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PAS...

### .github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3724
- `line_count`: 95
- `sha256`: f1418bab89808409516f2eddd89f726b3236d8ad669864dc38a7bf2e6671587c
- `encoding`: utf-8
- `indexed_at`: 2026-06-16T00:09:57+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3724 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-16-2026-06-16-nemu-python-int-focused-contract/dispatch-log.md", "evidence_dir": ".gith...
