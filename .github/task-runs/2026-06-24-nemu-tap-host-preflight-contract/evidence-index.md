# Evidence Index

## 基本信息

- `task_id`: 2026-06-24-nemu-tap-host-preflight-contract
- `task_slug`: nemu-tap-host-preflight-contract
- `profile`: nemu-dev
- `asset_count`: 10
- `total_size_bytes`: 470251

## 证据资产

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9587
- `line_count`: 111
- `sha256`: 31878412dc83213f3e560446596003eb7b722f302c7c7a638907e6112a251897
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {}
- `summary`: log evidence; size=9587 bytes; lines=111; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9278
- `line_count`: 104
- `sha256`: fbb7b70fba7b13d1321ef1006b8688e86b70d19d6ff60dbefc24287af5ecaf7c
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {}
- `summary`: log evidence; size=9278 bytes; lines=104; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 170685
- `line_count`: 2950
- `sha256`: fbcd9024b1286262380bef1b69652651823587e7ad306e85eb0c935f8a65b2bb
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2275, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"]}
- `summary`: log evidence; size=170685 bytes; lines=2950; FAIL=1; PASS=2275; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=-ubuntu-rootfs.sh systemd-oomd:/usr/lib/systemd/system/-.slice.d/10-oomd-root-slice-defaults.conf PASS check-ubuntu-rootfs.sh systemd-oomd:/usr/lib/systemd/system/user@.service.d/10-oomd-user-service-defaults.conf PASS check-ubuntu-rootfs.sh systemd-oomd:/u...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 263674
- `line_count`: 4598
- `sha256`: 0a145b57ff23c25b26bf0b9aa25240d91ffc605095a4a42193b8e638cb9cadc8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 373, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=263674 bytes; lines=4598; PASS=373; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s2) = 0x0000000000000000 x19 ( s3) = 0x0000000000000000 x20 ( s4) = 0x0000000000000000 x21 ( s5) = 0x0000000000000000 x22 ( s6) = 0x0000000000000000 x23 ( s7) = 0x0000000000000000 x24 ( s8) = 0x0000000000000000 x25 ( s9) = 0x0000000000000000 x26 ( s10) = 0x...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 671
- `line_count`: 3
- `sha256`: e562dcea756ac649a11ce503098f4bb1d64412079e701da681093c7fa5002a4c
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=671 bytes; lines=3; FAIL=2; PASS=6; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS Linux/NEM...

### .github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3526
- `line_count`: 95
- `sha256`: f9548b275650726b7ce6a5c8ad445770c753ca01cdfb13e295179a349bd9128a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T09:45:41+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=3526 bytes; lines=95; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-24-nemu-tap-host-preflight-contract/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-06-2...
