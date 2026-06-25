# Evidence Index

## 基本信息

- `task_id`: 2026-06-25-nemu-full-networkd-wait-online-contract-rerun
- `task_slug`: nemu-full-networkd-wait-online-contract-rerun
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 482392

## 证据资产

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9849
- `line_count`: 117
- `sha256`: fe998d611d9d46a00db3506d5bc44ad9bc82778046ad5c37eb1efce5da81fabb
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {}
- `summary`: log evidence; size=9849 bytes; lines=117; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9540
- `line_count`: 110
- `sha256`: 17fbf164c14d6c6c457226410f2768bfc549c191f879ff0157bf5b137de4e27f
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {}
- `summary`: log evidence; size=9540 bytes; lines=110; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 180627
- `line_count`: 3100
- `sha256`: 5b71fa7229333550dff6ffe8218ebbd2dd42eb43285581b13e3f65988fcf836c
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2301, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_SOURCE__"]}
- `summary`: log evidence; size=180627 bytes; lines=3100; FAIL=1; PASS=2301; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=.freedesktop.oom1.service PASS check-ubuntu-rootfs.sh systemd-oomd:/usr/share/dbus-1/system.d/org.freedesktop.oom1.conf PASS check-ubuntu-rootfs.sh passwd:/usr/sbin/groupadd PASS check-ubuntu-rootfs.sh passwd:/usr/sbin/groupdel PASS check-ubuntu-rootfs.sh p...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 265154
- `line_count`: 4629
- `sha256`: 1eaabc9e981233784eef8c7c3d0e8ffbb2ebb459d84126555d6bac04810d415d
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 373, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=265154 bytes; lines=4629; PASS=373; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=0000000 x27 ( s11) = 0x0000000000000000 x28 ( t3) = 0x0000000000000000 x29 ( t4) = 0x0000000000000000 x30 ( t5) = 0x0000000000000000 x31 ( t6) = 0x0000000000000000 pc = 0x0000000080000010 PASS swbreak-syscon-poweroff PASS swbreak-good-trap hbreak-command: /...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 761
- `line_count`: 3
- `sha256`: 808ecb5326bcbe4f30ad13e216c826b5fb8a0703309bc13161ab03876fa37f70
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=761 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu P...

### .github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 3631
- `line_count`: 94
- `sha256`: c5e16e0753877bb1ea849dd701e9d8525f7804af5e73321e8e7b97a3d963b879
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T21:53:36+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3631 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-25-nemu-full-networkd-wait-online-contract-rerun/dispatch-log.md", "evidence_dir": "....
