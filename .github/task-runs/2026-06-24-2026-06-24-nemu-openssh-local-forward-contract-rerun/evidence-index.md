# Evidence Index

## 基本信息

- `task_id`: 2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun
- `task_slug`: 2026-06-24-nemu-openssh-local-forward-contract-rerun
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 458407

## 证据资产

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9291
- `line_count`: 102
- `sha256`: 116993d85f8b14d576c39cde5b95d2fa898f7a859ba16c76a0d17fbd16aeaf49
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {}
- `summary`: log evidence; size=9291 bytes; lines=102; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8982
- `line_count`: 95
- `sha256`: e70d7839b0ad7b999513fd8cd8bb971e08b612bcf80862264ab323e8c5c811cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {}
- `summary`: log evidence; size=8982 bytes; lines=95; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 164533
- `line_count`: 2834
- `sha256`: 8b189e99516eeb4ab36cdc48b73e351f7e2fbb32d3ebc6c7783aa939c5375603
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2247, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"]}
- `summary`: log evidence; size=164533 bytes; lines=2834; FAIL=1; PASS=2247; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=ession:/usr/lib/systemd/user/dbus.socket PASS check-ubuntu-rootfs.sh dbus-user-session:/usr/lib/systemd/user/dbus.service PASS check-ubuntu-rootfs.sh dbus-user-session:/usr/lib/systemd/user/sockets.target.wants/dbus.socket PASS check-ubuntu-rootfs.sh ubuntu...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 258253
- `line_count`: 4484
- `sha256`: 3ae00f1c78667d85816b36ba7f28674808a94b5658fae2ce7451b9ab6aa81eab
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 372, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=258253 bytes; lines=4484; PASS=372; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 782
- `line_count`: 3
- `sha256`: c69d8c9430f3eb4547668b3f7b65ac39fa2fcd6816a1990a3d96a1d14acb4f79
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=782 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-static nemu...

### .github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 3736
- `line_count`: 94
- `sha256`: 7dcbf3689693940c58d46df267a55577e7d4a2b046a1a9d68e0d002be9108e82
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:02:00+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3736 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-24-2026-06-24-nemu-openssh-local-forward-contract-rerun/dispatch-log.md", "evi...
