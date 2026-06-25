# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract
- `task_slug`: 2026-06-22-nemu-ifetch-page-cache-multi-entry-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 423999

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1192
- `line_count`: 19
- `sha256`: fb229211fba66e7b65fe108c424663d117af0880ca536c5bba44a25af57fcb83
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {}
- `summary`: log evidence; size=1192 bytes; lines=19; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8686
- `line_count`: 99
- `sha256`: 90a3321753123599836997686f46d514558aa078ba07395ed6db6802545cb8d2
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {}
- `summary`: log evidence; size=8686 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8379
- `line_count`: 92
- `sha256`: ac150c617a81e8e205c473c22b8292a4d8136a2403c3fa07966b6ebc38cf3532
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {}
- `summary`: log evidence; size=8379 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7647
- `line_count`: 68
- `sha256`: 23d5a97c696f33c3fa2b6719494c23d9665826b1034087317fe13a0a984cbcca
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {}
- `summary`: log evidence; size=7647 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 134385
- `line_count`: 2404
- `sha256`: 504a4b5a5502b8a7177c978e75d886864f67213c22658dd5d784c37562e11697
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2331, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=134385 bytes; lines=2404; FAIL=4; PASS=2331; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=b/riscv64-linux-gnu/security PASS ubuntu-rootfs-flavors.sh ubuntu_rootfs_flavor_packages PASS ubuntu-rootfs-flavors.sh systemd-minimal PASS ubuntu-rootfs-flavors.sh interactive PASS ubuntu-rootfs-flavors.sh /bin/ping PASS ubuntu-rootfs-flavors.sh ubuntu-sta...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 256109
- `line_count`: 4460
- `sha256`: b1d9ce47404903f260fe1bd811ddc38d88e92ab4736105ff1611637aefea36ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=256109 bytes; lines=4460; PASS=370; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=o_net_statistic] virtio-net runtime tx_packets=0 tx_bytes=0 rx_packets=0 rx_bytes=0 tx_errors=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 788
- `line_count`: 3
- `sha256`: da67276a5d8bcf4e2a55010d03ff81cd8d3e11f6a75339b683309430b4331ed6
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=788 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/evidence/software-flow-contract.log nemu-ubuntu-static ne...

### .github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3766
- `line_count`: 94
- `sha256`: 784552c490bbec3f1ae6927ed9b0d8699dad16759fb27c8823b7847f798ffb89
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T02:33:13+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3766 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-ifetch-page-cache-multi-entry-contract/dispatch-log.md",...
