# Evidence Index

## 基本信息

- `task_id`: 2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract
- `task_slug`: 2026-06-23-nemu-full-systemd-user-manager-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 454461

## 证据资产

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1276
- `line_count`: 21
- `sha256`: e4ab64ed365ba135743e085cdfc4afad279c30f26b17e033a05e8e67b2c62c65
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {}
- `summary`: log evidence; size=1276 bytes; lines=21; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8895
- `line_count`: 102
- `sha256`: 47cc9318c95b62e3604da1834be9ae669f93fc7db6163a24f7a7b617cb5baf30
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {}
- `summary`: log evidence; size=8895 bytes; lines=102; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8588
- `line_count`: 95
- `sha256`: 608388743df055a034613079bc3712627ecfd421a8379ea0101892b45dd198fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {}
- `summary`: log evidence; size=8588 bytes; lines=95; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7735
- `line_count`: 68
- `sha256`: a643557f78f8461b4f9d9005fd3b8b0adc79bc0ebf2a5ca0af31de60f029715b
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {}
- `summary`: log evidence; size=7735 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 163314
- `line_count`: 2818
- `sha256`: 73bfb4b94b8e21315951b6bb09b3665c6fea68e484355e11251d49124c1bac4a
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2246, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"]}
- `summary`: log evidence; size=163314 bytes; lines=2818; FAIL=1; PASS=2246; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=emd-logind PASS check-ubuntu-rootfs.sh systemd:/lib/systemd/system/systemd-logind.service PASS check-ubuntu-rootfs.sh systemd:/lib/systemd/system/user@.service PASS check-ubuntu-rootfs.sh systemd:/lib/systemd/system/user-runtime-dir@.service PASS check-ubun...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 257085
- `line_count`: 4476
- `sha256`: d68be1b87ed9057f5ae0ea6be29f1b166ce7b72078986cec2ed7479a000e6d67
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 372, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=257085 bytes; lines=4476; PASS=372; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 725
- `line_count`: 3
- `sha256`: 7105d412c258aeb7662e43ab525b71092766ed3aefff47c59c8cd024697db62c
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=725 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu n...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3796
- `line_count`: 95
- `sha256`: 7a2abdc3b687750d2a70ee12cd491b8cfc77d5d38f36ffaccd25c6cb3c47b655
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T15:55:24+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3796 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-23-2026-06-23-nemu-full-systemd-user-manager-contract/dispatch-log.md", "evidenc...
