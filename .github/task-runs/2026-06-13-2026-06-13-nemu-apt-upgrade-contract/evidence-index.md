# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-2026-06-13-nemu-apt-upgrade-contract
- `task_slug`: 2026-06-13-nemu-apt-upgrade-contract
- `profile`: nemu-dev-gate
- `asset_count`: 11
- `total_size_bytes`: 318587

## 证据资产

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-dev-focused-gate.log

- `kind`: log
- `size_bytes`: 237
- `line_count`: 2
- `sha256`: 145e4d6b87c660298f3d2c5c81cb4d83e09491023865ca2c712479b60b7e790f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=237 bytes; lines=2; SKIP=2; tail=[nemu-ubuntu] SKIP: AGENT_E2E_NEMU_UBUNTU_GATE=1 未设置，默认不跑十几分钟 focused guest gate [nemu-ubuntu] next: 需要真实 guest 证据时运行 AGENT_E2E_NEMU_UBUNTU_GATE=1 scripts/agent-e2e.sh --profile nemu-ubuntu-gate

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 669
- `line_count`: 10
- `sha256`: c80ad239a203ab34498f57dd12468c82437cd1a8408223809ba496bc4ed0ab3a
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {}
- `summary`: log evidence; size=669 bytes; lines=10; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 12314
- `line_count`: 100
- `sha256`: 292e317a670053593d8559a4a3bd0df53164247e0b5e7d45ba09861401357b7f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"symbolic": ["__GUEST_ISA__"]}
- `summary`: log evidence; size=12314 bytes; lines=100; symbolic=__GUEST_ISA__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 12007
- `line_count`: 93
- `sha256`: 4c2822641ef2c0b4426fb6cbd4dd45ea11d1c45b73247c5b15345fa54f794488
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"symbolic": ["__GUEST_ISA__"]}
- `summary`: log evidence; size=12007 bytes; lines=93; symbolic=__GUEST_ISA__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 77735
- `line_count`: 1511
- `sha256`: 3988107180d9a015ddf27f5e64d77a763ef4becd87d7bbde07417cc88bee606b
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2442, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=77735 bytes; lines=1511; FAIL=7; PASS=2442; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=e_queue_layout PASS net.c virtq_dma_range_valid PASS net.c CONFIG_VIRTIO_NET_MMIO [nemu-ubuntu] required host console clean hooks PASS check-nemu-systemd-guest.sh NEMU_SYSTEMD_NET_TCP_BURST_LOOPS PASS check-nemu-systemd-guest.sh NEMU_SYSTEMD_ROOTFS_OVERLAY...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 201543
- `line_count`: 3160
- `sha256`: e322824934418a14e6215c7da13fd79d59678e2cec6e3f9061b8ec17982bbaf4
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 359, "symbolic": ["__GUEST_ISA__", "__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=201543 bytes; lines=3160; PASS=359; GOOD_TRAP=23; symbolic=__GUEST_ISA__,__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=erial' at [0x10000000, 0x10000fff][0m [1;34m[src/device/disk.c:1643 open_disk_image] virtio-blk: no --block image, device id stays 0[0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'virtio-blk' at [0x10001000, 0x10001fff][0m [1;34m[src/de...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1008
- `line_count`: 4
- `sha256`: a184f014d106b9cbe7d81abdcc851f54dbe063294238a83ff190bd5078406e6f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"PASS": 8, "SKIP": 4}
- `summary`: tsv evidence; size=1008 bytes; lines=4; SKIP=4; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS Linux...

### .github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/run-manifest.json

- `kind`: json
- `size_bytes`: 4021
- `line_count`: 104
- `sha256`: 182fcbc560a1af74949ddce0a9bb6f608ba6abf770187fe0f37e08470732f2ac
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T15:59:32+00:00
- `markers`: {"PASS": 10, "SKIP": 8}
- `summary`: json evidence; size=4021 bytes; lines=104; SKIP=8; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-13-2026-06-13-nemu-apt-upgrade-contract/dispatch-log.md", "evidence_dir": ".github/task-runs/2...
