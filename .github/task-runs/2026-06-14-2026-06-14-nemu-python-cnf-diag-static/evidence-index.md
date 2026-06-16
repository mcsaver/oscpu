# Evidence Index

## 基本信息

- `task_id`: 2026-06-14-2026-06-14-nemu-python-cnf-diag-static
- `task_slug`: 2026-06-14-nemu-python-cnf-diag-static
- `profile`: nemu-dev-gate
- `asset_count`: 10
- `total_size_bytes`: 320931

## 证据资产

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7332
- `line_count`: 93
- `sha256`: 5c00a003e5d26b7871e9a4581528b8ccb422166964738d92430fde571123a67d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {}
- `summary`: log evidence; size=7332 bytes; lines=93; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7025
- `line_count`: 86
- `sha256`: 26d23d9464a22a0ade66874d08bbdaec5f4fea9ff0f155331c56ebca86616707
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {}
- `summary`: log evidence; size=7025 bytes; lines=86; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 90654
- `line_count`: 1705
- `sha256`: 872374fe96b0ddfd224932c600ec7a7470073dd3947fa84cc2e97ef247d331ed
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 9, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2339, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=90654 bytes; lines=1705; FAIL=9; PASS=2339; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=emu-full-cron-check PASS check-nemu-systemd-guest.sh 99-nemu-full-rsyslog-check.conf PASS check-nemu-systemd-guest.sh /var/log/nemu-full-rsyslog.log PASS check-nemu-systemd-guest.sh nemu-full-rsyslog-ok PASS check-nemu-systemd-guest.sh dpkg --audit PASS che...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 201969
- `line_count`: 3275
- `sha256`: fbcafa11a1edc9831e1270524da69c2754bef9ded01ae315d8731bcd020b89c7
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 363, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=201969 bytes; lines=3275; PASS=363; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=[0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'virtio-net' at [0x10004000, 0x10004fff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'goldfish-rtc' at [0x10003000, 0x10003fff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_m...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/nodes.tsv

- `kind`: tsv
- `size_bytes`: 689
- `line_count`: 3
- `sha256`: 2db4a7ac77e70ce9f1895878dce93f16cc0a82389197f4f2a0cb90fd6976c088
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=689 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS Lin...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/run-manifest.json

- `kind`: json
- `size_bytes`: 3631
- `line_count`: 95
- `sha256`: eb92d7e1ff1626a28abe23c166b447823dc9f0a2a1e17bbda67bd71546826eb3
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T00:54:23+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3631 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-diag-static/dispatch-log.md", "evidence_dir": ".github/task-ru...
