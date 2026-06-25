# Evidence Index

## 基本信息

- `task_id`: 2026-06-25-nemu-full-root-user-manager-session-contract-v5
- `task_slug`: nemu-full-root-user-manager-session-contract-v5
- `profile`: nemu-dev-full-gate
- `asset_count`: 11
- `total_size_bytes`: 488763

## 证据资产

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 252
- `line_count`: 2
- `sha256`: d8aa82906554c859e7ef239084de74d6957b229434b01540abe3f2da838a3d10
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=252 bytes; lines=2; SKIP=2; tail=[nemu-ubuntu] SKIP: AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 未设置，默认不跑十几分钟 focused guest gate [nemu-ubuntu] next: 需要真实 guest 证据时运行 AGENT_E2E_NEMU_UBUNTU_FULL_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-full-gate

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9849
- `line_count`: 117
- `sha256`: fe998d611d9d46a00db3506d5bc44ad9bc82778046ad5c37eb1efce5da81fabb
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {}
- `summary`: log evidence; size=9849 bytes; lines=117; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9540
- `line_count`: 110
- `sha256`: 17fbf164c14d6c6c457226410f2768bfc549c191f879ff0157bf5b137de4e27f
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {}
- `summary`: log evidence; size=9540 bytes; lines=110; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 185753
- `line_count`: 3170
- `sha256`: 0642417432bbd8315054335134f963f2b4a91c78da2bb1c784ad77d0870423dd
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2291, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_KEYRING_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_SOURCE__"]}
- `summary`: log evidence; size=185753 bytes; lines=3170; FAIL=1; PASS=2291; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=.freedesktop.oom1.service PASS check-ubuntu-rootfs.sh systemd-oomd:/usr/share/dbus-1/system.d/org.freedesktop.oom1.conf PASS check-ubuntu-rootfs.sh passwd:/usr/sbin/groupadd PASS check-ubuntu-rootfs.sh passwd:/usr/sbin/groupdel PASS check-ubuntu-rootfs.sh p...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 265236
- `line_count`: 4630
- `sha256`: c2ca94acbaa47d2142c96d56a68b2aa953ca1e66c79ef66f26e7d95b73201292
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 373, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=265236 bytes; lines=4630; PASS=373; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=0000000 x27 ( s11) = 0x0000000000000000 x28 ( t3) = 0x0000000000000000 x29 ( t4) = 0x0000000000000000 x30 ( t5) = 0x0000000000000000 x31 ( t6) = 0x0000000000000000 pc = 0x0000000080000010 PASS swbreak-syscon-poweroff PASS swbreak-good-trap hbreak-command: /...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1074
- `line_count`: 4
- `sha256`: 013ffd96552d992a82d26b795e0ad6daa5d9810ac8972b41f4869cce2dc5ec2a
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {"PASS": 8, "SKIP": 4}
- `summary`: tsv evidence; size=1074 bytes; lines=4; SKIP=4; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu...

### .github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/run-manifest.json

- `kind`: json
- `size_bytes`: 4229
- `line_count`: 104
- `sha256`: 551d497b8d2a042b92cc3615e1c3514fe90944909c343413a505ff524fa22d92
- `encoding`: utf-8
- `indexed_at`: 2026-06-25T04:04:42+00:00
- `markers`: {"PASS": 10, "SKIP": 8}
- `summary`: json evidence; size=4229 bytes; lines=104; SKIP=8; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-25-nemu-full-root-user-manager-session-contract-v5/dispatch-log.md", "evidence_dir"...
