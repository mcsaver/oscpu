# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-full-account-useradd-contract
- `task_slug`: 2026-06-22-nemu-full-account-useradd-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 429944

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1192
- `line_count`: 19
- `sha256`: fb229211fba66e7b65fe108c424663d117af0880ca536c5bba44a25af57fcb83
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {}
- `summary`: log evidence; size=1192 bytes; lines=19; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8686
- `line_count`: 99
- `sha256`: 90a3321753123599836997686f46d514558aa078ba07395ed6db6802545cb8d2
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {}
- `summary`: log evidence; size=8686 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8379
- `line_count`: 92
- `sha256`: ac150c617a81e8e205c473c22b8292a4d8136a2403c3fa07966b6ebc38cf3532
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {}
- `summary`: log evidence; size=8379 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7647
- `line_count`: 68
- `sha256`: 23d5a97c696f33c3fa2b6719494c23d9665826b1034087317fe13a0a984cbcca
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {}
- `summary`: log evidence; size=7647 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 136073
- `line_count`: 2434
- `sha256`: 5bdc23fddec74746a28351aadde4aeaa6d755e1e5bf1a93d2ccd133df6574d77
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2326, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__"]}
- `summary`: log evidence; size=136073 bytes; lines=2434; FAIL=4; PASS=2326; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=PASS ubuntu-rootfs-flavors.sh /usr/sbin/userdel PASS ubuntu-rootfs-flavors.sh /usr/bin/passwd PASS ubuntu-rootfs-flavors.sh /etc/default/useradd PASS ubuntu-rootfs-flavors.sh /etc/login.defs PASS ubuntu-rootfs-flavors.sh /usr/bin/dbclient PASS ubuntu-rootfs...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 260528
- `line_count`: 4536
- `sha256`: 1642a3388dff6ee402a7be154737453e252ab3f2b540add8cedaab29ee61d44a
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=260528 bytes; lines=4536; PASS=370; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=o_net_statistic] virtio-net runtime tx_packets=0 tx_bytes=0 rx_packets=0 rx_bytes=0 tx_errors=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 761
- `line_count`: 3
- `sha256`: ac96fdd7899742e972bbf21652f6b52255fd6af6b3ce42e51b3261b578f06a4b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=761 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu P...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3631
- `line_count`: 94
- `sha256`: 5063a0f138fa5eb4ad0cd91a449ebb6d54fb3bcbe44d1b1019b3d09f3cadd9bf
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T03:46:01+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3631 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-full-account-useradd-contract/dispatch-log.md", "evidence_dir": "....
