# Evidence Index

## 基本信息

- `task_id`: 2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract
- `task_slug`: 2026-06-14-nemu-dma-page-invalidate-contract
- `profile`: nemu-ubuntu
- `asset_count`: 10
- `total_size_bytes`: 369371

## 证据资产

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 845
- `line_count`: 16
- `sha256`: 4fc11609129c8a82809e71064839c270a4999b36f599138eeaf40c66af38aef2
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {}
- `summary`: log evidence; size=845 bytes; lines=16; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 18743
- `line_count`: 130
- `sha256`: b38212a8ef17f0f3c698069f7ab0374288b4d3730c153b0a9bcc5757130103fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"symbolic": ["__GUEST_ISA__"]}
- `summary`: log evidence; size=18743 bytes; lines=130; symbolic=__GUEST_ISA__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 18436
- `line_count`: 123
- `sha256`: e00eae480b6fa1cf3beeb633b561a998119ec339b00b593495ad049025c9095a
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"symbolic": ["__GUEST_ISA__"]}
- `summary`: log evidence; size=18436 bytes; lines=123; symbolic=__GUEST_ISA__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 98572
- `line_count`: 1819
- `sha256`: 40ccb4847c087acaaf34ec4ef9d02f60d431560497bc51dde783feebb280e264
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2297, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=98572 bytes; lines=1819; FAIL=7; PASS=2297; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=sh __NEMU_CHECK_FULL_SSH_LOGIN_OK__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_SSH_DROPBEAR_LOG_BEGIN__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_CURL_HTTP_CODE__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_WGET_HTTP_CODE__ PASS chec...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 219342
- `line_count`: 3283
- `sha256`: 5de149f4b8bfc6c9962321a3304ce85b17b8ab496ba7e0f285a0f65d7c705488
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"GOOD_TRAP": 18, "PASS": 366, "symbolic": ["__GUEST_ISA__", "__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=219342 bytes; lines=3283; PASS=366; GOOD_TRAP=18; symbolic=__GUEST_ISA__,__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=o map 'goldfish-rtc' at [0x10003000, 0x10003fff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'syscon-reset' at [0x00100000, 0x00100fff][0m [1;34m[src/monitor/monitor.c:147 load_img] No image is given. Use the default build-in image.[0m...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 758
- `line_count`: 3
- `sha256`: f40476f07b9a890dd2b78514e2c840f511b3932ff4dfc7ccac0b72490764f79c
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=758 bytes; lines=3; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PA...

### .github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 3622
- `line_count`: 94
- `sha256`: 05702752f5dafe0ad8357a0d9c27067c0b2ca899aabd361d3f3951d8bc629bc4
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T13:47:18+00:00
- `markers`: {"PASS": 10}
- `summary`: json evidence; size=3622 bytes; lines=94; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-14-2026-06-14-nemu-dma-page-invalidate-contract/dispatch-log.md", "evidence_dir": ".gi...
