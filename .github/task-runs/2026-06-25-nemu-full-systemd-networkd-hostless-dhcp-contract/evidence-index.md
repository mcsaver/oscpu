# Evidence Index

## 基本信息

- `task_id`: 2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract
- `task_slug`: nemu-full-systemd-networkd-hostless-dhcp-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 479874

## 证据资产

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9799
- `line_count`: 116
- `sha256`: 1a9c09b418f5e1189f33e0c356b00cf9147463cb908f4bc4d8b334dfdc5ae047
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {}
- `summary`: log evidence; size=9799 bytes; lines=116; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9490
- `line_count`: 109
- `sha256`: 457dfb870fdcd10dff922e724ea3cb87dd4c8ae1facaed400c8a8b78e3d91c8c
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {}
- `summary`: log evidence; size=9490 bytes; lines=109; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 178198
- `line_count`: 3065
- `sha256`: 9dab652ce686d6416d3b83d440e779263aa3b6b81c4a78085db8340d0e0f46e3
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {"FAIL": 2, "GOOD_TRAP": 9, "PASS": 2301, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_RC__"]}
- `summary`: log evidence; size=178198 bytes; lines=3065; FAIL=2; PASS=2301; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=-ubuntu-rootfs.sh systemd-oomd:/usr/share/dbus-1/system-services/org.freedesktop.oom1.service PASS check-ubuntu-rootfs.sh systemd-oomd:/usr/share/dbus-1/system.d/org.freedesktop.oom1.conf PASS check-ubuntu-rootfs.sh passwd:/usr/sbin/groupadd PASS check-ubun...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 265054
- `line_count`: 4627
- `sha256`: 030aa65b82a2db0a6bb685a9f47a26bc1dcf4b84115c50539a34b1396c73041d
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 373, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=265054 bytes; lines=4627; PASS=373; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=0000000 x27 ( s11) = 0x0000000000000000 x28 ( t3) = 0x0000000000000000 x29 ( t4) = 0x0000000000000000 x30 ( t5) = 0x0000000000000000 x31 ( t6) = 0x0000000000000000 pc = 0x0000000080000010 PASS swbreak-syscon-poweroff PASS swbreak-good-trap hbreak-command: /...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 722
- `line_count`: 3
- `sha256`: 7b3732fe9a9fdf48af79d23688e2951c5f58506afc7498d561eb23b95c0888ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=722 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu ne...

### .github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3781
- `line_count`: 95
- `sha256`: b27dcfe083d447d62ddfd3854f8c9f4368a3104d19dcf5d710cef54aac51bcdc
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T19:31:36+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3781 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-25-nemu-full-systemd-networkd-hostless-dhcp-contract/dispatch-log.md", "evidence_...
