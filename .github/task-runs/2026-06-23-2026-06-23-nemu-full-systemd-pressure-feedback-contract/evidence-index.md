# Evidence Index

## 基本信息

- `task_id`: 2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract
- `task_slug`: 2026-06-23-nemu-full-systemd-pressure-feedback-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 442760

## 证据资产

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1276
- `line_count`: 21
- `sha256`: e4ab64ed365ba135743e085cdfc4afad279c30f26b17e033a05e8e67b2c62c65
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {}
- `summary`: log evidence; size=1276 bytes; lines=21; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8895
- `line_count`: 102
- `sha256`: 47cc9318c95b62e3604da1834be9ae669f93fc7db6163a24f7a7b617cb5baf30
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {}
- `summary`: log evidence; size=8895 bytes; lines=102; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8588
- `line_count`: 95
- `sha256`: 608388743df055a034613079bc3712627ecfd421a8379ea0101892b45dd198fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {}
- `summary`: log evidence; size=8588 bytes; lines=95; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7735
- `line_count`: 68
- `sha256`: a643557f78f8461b4f9d9005fd3b8b0adc79bc0ebf2a5ca0af31de60f029715b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {}
- `summary`: log evidence; size=7735 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 151562
- `line_count`: 2663
- `sha256`: a629fd360b0c6fa12acb0a1198a173b55cda160c26700b154799fde3fb65c334
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PANIC": 1, "PASS": 2274, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"]}
- `summary`: log evidence; size=151562 bytes; lines=2663; FAIL=1; PASS=2274; GOOD_TRAP=9; PANIC=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=ntu-rootfs.sh journal query tool PASS check-ubuntu-rootfs.sh sysusers tool PASS check-ubuntu-rootfs.sh sysusers setup unit PASS check-ubuntu-rootfs.sh sysusers base config PASS check-ubuntu-rootfs.sh tmpfiles tool PASS check-ubuntu-rootfs.sh tmpfiles setup...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 257085
- `line_count`: 4476
- `sha256`: 161c38f98157617644cc337765ed53e6c44a8daa6d3b6aa3be469b4aa8afa32f
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 372, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=257085 bytes; lines=4476; PASS=372; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 791
- `line_count`: 3
- `sha256`: 909d0b60c07482a17a48ccfba0f2559102e245bfcd939d6f1b18418b760897c5
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=791 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/evidence/software-flow-contract.log nemu-ubuntu-static n...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3781
- `line_count`: 94
- `sha256`: de52f0528162698fce1936f8f6253dd077bf344b89039d1f3a99429f67b453eb
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T21:34:48+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3781 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-pressure-feedback-contract/dispatch-log.md"...
