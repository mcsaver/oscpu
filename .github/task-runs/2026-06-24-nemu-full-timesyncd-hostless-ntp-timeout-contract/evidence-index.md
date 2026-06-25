# Evidence Index

## 基本信息

- `task_id`: 2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract
- `task_slug`: nemu-full-timesyncd-hostless-ntp-timeout-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 475043

## 证据资产

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9714
- `line_count`: 114
- `sha256`: 37ff0d40a50056b596411ce09e4dc7845ae93ca94a10898b0727ae463099e571
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {}
- `summary`: log evidence; size=9714 bytes; lines=114; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9405
- `line_count`: 107
- `sha256`: 0cf97af9a9d2f23b3406310a8f08d8fd1cfcc8881bb33b2bebd0e90dd358fa80
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {}
- `summary`: log evidence; size=9405 bytes; lines=107; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 173746
- `line_count`: 3000
- `sha256`: fd91c37c4101ed229d904e05dc26c4972d61f8a50cd35ea2771fe5115476bad0
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2290, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__"]}
- `summary`: log evidence; size=173746 bytes; lines=3000; FAIL=1; PASS=2290; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=-oomd-user-service-defaults.conf PASS check-ubuntu-rootfs.sh systemd-oomd:/usr/lib/sysusers.d/systemd-oom.conf PASS check-ubuntu-rootfs.sh systemd-oomd:/usr/share/dbus-1/system-services/org.freedesktop.oom1.service PASS check-ubuntu-rootfs.sh systemd-oomd:/...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 264884
- `line_count`: 4623
- `sha256`: 2dce48f75d6540f6ed65c5de355cad3957a5741d068ad5b8f5dc4b27c87957f5
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 373, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=264884 bytes; lines=4623; PASS=373; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=0000000 x27 ( s11) = 0x0000000000000000 x28 ( t3) = 0x0000000000000000 x29 ( t4) = 0x0000000000000000 x30 ( t5) = 0x0000000000000000 x31 ( t6) = 0x0000000000000000 pc = 0x0000000080000010 PASS swbreak-syscon-poweroff PASS swbreak-good-trap hbreak-command: /...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 773
- `line_count`: 3
- `sha256`: 36e31bf8facfcfd335916d4eec36ea92c2002d6462a02d97a472ae8c67f3afac
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=773 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu ne...

### .github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3691
- `line_count`: 94
- `sha256`: 9c988f115889f5eecec97cbc63da953bf80e82bf72c68cfcfd751dc5ce8a2ce1
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T13:19:35+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3691 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-24-nemu-full-timesyncd-hostless-ntp-timeout-contract/dispatch-log.md", "evidence_...
