# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-nemu-full-apt-lifecycle-real-run-3
- `task_slug`: nemu-full-apt-lifecycle-real-run-3
- `profile`: nemu-ubuntu-full-gate
- `asset_count`: 27
- `total_size_bytes`: 8591006256

## 证据资产

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7286
- `line_count`: 92
- `sha256`: dcc5e2880647f41967b1e9af5477195c181e26bebb761996e8cfef5ba75bbbba
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: log evidence; size=7286 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6979
- `line_count`: 85
- `sha256`: 85994e22d6a2aef8c993d4170638dc8df74b93d43f4e578286c8613709dd7f06
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: log evidence; size=6979 bytes; lines=85; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-ubuntu-full-focused-gate.log

- `kind`: log
- `size_bytes`: 23922
- `line_count`: 435
- `sha256`: 74f360eeb286620d8cdd0e30b78197a7cdc7255206e5244d104505d95c56b158
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"FAIL": 4, "PASS": 16, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_GUEST_UPTIME_END__", "__NEMU_CHECK_HWRNG_CURRENT__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_INTERRUPTS_LINE__", "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL_GROW__", "__NEMU_CHECK_INTERRUPTS_TOTAL_GROW__", "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__", "__NEMU_CHECK_IRQ_VISIBLE_GROW__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_PIPE_BYTES__", "__NEMU_CHECK_ROOTFS_DIRECT_BYTES__", "__NEMU_CHECK_ROOT_FSTYPE__", "__NEMU_CHECK_ROOT_SOURCE__", "__NEMU_CHECK_RTC0_HWCLOCK__"]}
- `summary`: log evidence; size=23922 bytes; lines=435; FAIL=4; PASS=16; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_FS_STRESS_BYTES__,__NEMU_CHECK_FS_TREE_FILES__,__NEMU_CHECK_GUEST_UPTIME_END__; tail=[nemu-ubuntu] focused gate target: check-nemu-systemd-guest-full [nemu-ubuntu] focused gate log dir: .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make A...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 69638
- `line_count`: 1415
- `sha256`: 6a79bcb4a104cecd61a27ec88d2133e72185c1a482ff7c3ab6ddfc6636604c02
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2640, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_EFFECT_OK_AFTER_TIMEOUT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PID__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_SAMPLE__"]}
- `summary`: log evidence; size=69638 bytes; lines=1415; FAIL=7; PASS=2640; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__; tail=NEMU_CHECK_VIRTIO_NET_SPEED__ PASS marker __NEMU_CHECK_VIRTIO_NET_DUPLEX__ PASS marker __NEMU_CHECK_VIRTIO_NET_IPV4__ PASS marker __NEMU_CHECK_VDA_CACHE_TYPE__ PASS marker __NEMU_CHECK_VDA_DISCARD_MAX__ PASS marker __NEMU_CHECK_VDA_WRITE_ZEROES_MAX__ PASS m...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 191026
- `line_count`: 3138
- `sha256`: 645662f89bc49a991a96982aa3f831a7cb6198ade9ab0f26f1a8e86e74af3698
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 411, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=191026 bytes; lines=3138; PASS=411; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=moke-nemu.log.hbreak[0m [1;34m[src/memory/paddr.c:66 init_mem] physical memory area [0x80000000, 0xbfffffff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'serial' at [0x10000000, 0x10000fff][0m [1;34m[src/device/disk.c:1643 open_disk_i...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 76569
- `line_count`: 1397
- `sha256`: de806d7627c1e21eb7d515d2de0f5b1eb9adae42d23e920926634655a47b0ad3
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__"]}
- `summary`: log evidence; size=76569 bytes; lines=1397; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__; tail=on [0;1;39mudev Kernel Socket[0m. [ 47.714553] systemd[1]: Reached target Socket Units. [[0;32m OK [0m] Reached target [0;1;39mSocket Units[0m. [ 47.768947] systemd[1]: Condition check resulted in Huge Pages File System being skipped. [ 47.974330] sys...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 18371
- `line_count`: 313
- `sha256`: 2b7aaceb8717dc1807f3e6eadd45000fd4d6b5c5106de3a96681e77de75649aa
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_GUEST_UPTIME_END__", "__NEMU_CHECK_INTERRUPTS_LINE__", "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL_GROW__", "__NEMU_CHECK_INTERRUPTS_TOTAL_GROW__", "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__", "__NEMU_CHECK_IRQ_VISIBLE_GROW__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_PIPE_BYTES__", "__NEMU_CHECK_ROOTFS_DIRECT_BYTES__", "__NEMU_CHECK_ROOT_FSTYPE__", "__NEMU_CHECK_ROOT_SOURCE__", "__NEMU_CHECK_SIGNAL_RC__", "__NEMU_CHECK_SOAK_SKIP__", "__NEMU_CHECK_UPTIME__", "__NEMU_CHECK_VDA_DIRECT_READ_BYTES__", "__NEMU_CHECK_VDA_WINDOW_COUNT__"]}
- `summary`: log evidence; size=18371 bytes; lines=313; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_FS_STRESS_BYTES__,__NEMU_CHECK_FS_TREE_FILES__,__NEMU_CHECK_GUEST_UPTIME_END__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 281543
- `line_count`: 3665
- `sha256`: 3ada354540059c1a68a92a79ed93c27a1f8d588ef373d0168ff038acd7745260
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_CHECK_B64__", "__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=281543 bytes; lines=3665; symbolic=__NEMU_GUEST_CHECK_B64__,__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__; tail=MjVsVkdGaWJHVUFBQUFBQUFJQUF3QUNBQUlBQWdBQ0FBSUFBd0FDQUFFQUFnQUNBQUlBQWdBQ0FB SUFBZ0FDQUFJQQpBZ0FDQUFJQUFnQUNBQU1BQWdBQ0FBSUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FB SUFBZ0FDQUFJQUFnQUNBQUlBQkFBREFBSUFBZ0FDCkFBSUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FB SUFBZ0FDQUFJQUFnQUNBQUlBQW...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 207454
- `line_count`: 3792
- `sha256`: cea8284dff5770af59a437f5e6a9f851dbad4c600c882e3f8c8a23f13d71f7e8
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__"]}
- `summary`: cmd evidence; size=207454 bytes; lines=3792; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_COMMON_COMMANDS__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF          �    0      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF          �    �      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF          �    @<      @       ��         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5�                      S                                             ...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                              ...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 102516
- `sha256`: 4dd29284295a37a87066deeda5f2684eb5d7a6f2cdf256b5af25c3fe94266e7d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=102516; markers=<none>; tail=                                                                                                                                                                                                                                                                 ...

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/nodes.tsv

- `kind`: tsv
- `size_bytes`: 934
- `line_count`: 4
- `sha256`: c43e85aa0309e18209c65c7196bec646fce24c222c82e1de7f9e8e2fd07307d6
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:03:29+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: tsv evidence; size=934 bytes; lines=4; FAIL=2; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-13-nemu-full-apt-lifecycle-real-run-3/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS Linux/N...
