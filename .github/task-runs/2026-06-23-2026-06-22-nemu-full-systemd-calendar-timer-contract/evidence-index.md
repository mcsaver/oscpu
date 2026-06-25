# Evidence Index

## 基本信息

- `task_id`: 2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract
- `task_slug`: 2026-06-22-nemu-full-systemd-calendar-timer-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 433857

## 证据资产

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1276
- `line_count`: 21
- `sha256`: e4ab64ed365ba135743e085cdfc4afad279c30f26b17e033a05e8e67b2c62c65
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {}
- `summary`: log evidence; size=1276 bytes; lines=21; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8857
- `line_count`: 101
- `sha256`: 06cfdbba7ab5e120b6ee2d3be7c41f5913d365dda1ddc9370fc8d661c0246f32
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {}
- `summary`: log evidence; size=8857 bytes; lines=101; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8550
- `line_count`: 94
- `sha256`: dbf5433d54e0689451bf3c3567a71cd60ad065c737b52ff6224bb3361aa9f83b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {}
- `summary`: log evidence; size=8550 bytes; lines=94; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7735
- `line_count`: 68
- `sha256`: a643557f78f8461b4f9d9005fd3b8b0adc79bc0ebf2a5ca0af31de60f029715b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {}
- `summary`: log evidence; size=7735 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 142969
- `line_count`: 2541
- `sha256`: 770c60d3146419c492ef39c5d1566f4717d627f64c85df12b6982ad2c854731b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2302, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__"]}
- `summary`: log evidence; size=142969 bytes; lines=2541; FAIL=4; PASS=2302; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=rootfs.sh account useradd command PASS check-ubuntu-rootfs.sh account userdel command PASS check-ubuntu-rootfs.sh account passwd command PASS check-ubuntu-rootfs.sh account useradd defaults PASS check-ubuntu-rootfs.sh login defaults PASS check-ubuntu-rootfs...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 256905
- `line_count`: 4472
- `sha256`: 87b9c978c4be89d6d1717d87cfea699488ff40d2fd43a0435482c349f18b68fd
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=256905 bytes; lines=4472; PASS=370; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 782
- `line_count`: 3
- `sha256`: 977349bddc0ec93ef5d72865bc658bc10745082e192854ee33d93228add48c05
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=782 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu...

### .github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3736
- `line_count`: 94
- `sha256`: 6916ad9fa9a662e7a2bec46fce332afe4105b224732327351165e269b056dc16
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T16:03:45+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3736 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-23-2026-06-22-nemu-full-systemd-calendar-timer-contract/dispatch-log.md", "evi...
