# Evidence Index

## 基本信息

- `task_id`: 2026-06-14-2026-06-14-nemu-python-cnf-hard-real
- `task_slug`: 2026-06-14-nemu-python-cnf-hard-real
- `profile`: nemu-dev-full-gate
- `asset_count`: 29
- `total_size_bytes`: 8591177411

## 证据资产

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 33541
- `line_count`: 486
- `sha256`: 75a6419d9c9255dec2f742449e6e57f989be02b0ba068b0616e90a7360cddb78
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"GOOD_TRAP": 2, "PANIC": 2, "PASS": 176, "symbolic": ["__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__", "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_BEGIN__", "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_END__", "__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_RC__", "__NEMU_CHECK_FULL_LSB_RELEASE_SHA256__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_RC__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_IMPORT_RC__", "__NEMU_CHECK_FULL_PYTHON_TEXTWRAP_SHA256__", "__NEMU_CHECK_HWRNG_CURRENT__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_RTC0_HWCLOCK__"]}
- `summary`: log evidence; size=33541 bytes; lines=486; PASS=176; GOOD_TRAP=2; PANIC=2; symbolic=__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__,__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_BEGIN__,__NEMU_CHECK_FULL_LSB_RELEASE_RETRY_LOG_END__; tail=[nemu-ubuntu] focused gate target: check-nemu-systemd-guest-full [nemu-ubuntu] focused gate log dir: .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7332
- `line_count`: 93
- `sha256`: 5c00a003e5d26b7871e9a4581528b8ccb422166964738d92430fde571123a67d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: log evidence; size=7332 bytes; lines=93; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7025
- `line_count`: 86
- `sha256`: 26d23d9464a22a0ade66874d08bbdaec5f4fea9ff0f155331c56ebca86616707
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: log evidence; size=7025 bytes; lines=86; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 91794
- `line_count`: 1722
- `sha256`: 6572e86b109fedec274928b8825532bf7d0f89a44a62f55f8af8e288251533cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2337, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=91794 bytes; lines=1722; FAIL=7; PASS=2337; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=emu-full-cron-check PASS check-nemu-systemd-guest.sh 99-nemu-full-rsyslog-check.conf PASS check-nemu-systemd-guest.sh /var/log/nemu-full-rsyslog.log PASS check-nemu-systemd-guest.sh nemu-full-rsyslog-ok PASS check-nemu-systemd-guest.sh dpkg --audit PASS che...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 198252
- `line_count`: 3211
- `sha256`: fa614d626787169d76296804ad3420223fdfc2acd2064ae5b2ac4dc0257f2d2a
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 363, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=198252 bytes; lines=3211; PASS=363; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=[0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'virtio-net' at [0x10004000, 0x10004fff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'goldfish-rtc' at [0x10003000, 0x10003fff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_m...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 77197
- `line_count`: 1396
- `sha256`: a9f94f64feec00addb6b3e88cac429164336ad27af08847a1f17e43ae9d323d7
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"GOOD_TRAP": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__"]}
- `summary`: log evidence; size=77197 bytes; lines=1396; GOOD_TRAP=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__; tail=Starting [0;1;39mJournal Service[0m... [ 47.921810] systemd[1]: Condition check resulted in Create List of Static Device Nodes being skipped. [ 48.488810] systemd[1]: Starting Load Kernel Module configfs... Starting [0;1;39mLoad Kernel Module configfs[0...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 18643
- `line_count`: 265
- `sha256`: e51a0800117096820d8ef855341c78481a7953f303d10071b5b564516a00fa6a
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"PANIC": 2, "PASS": 48, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=18643 bytes; lines=265; PASS=48; PANIC=2; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 354280
- `line_count`: 4610
- `sha256`: d2cedf405dc7e404ddc7e2a3cd853946882df43023628639becc18615cadf059
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_CHECK_B64__", "__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=354280 bytes; lines=4610; symbolic=__NEMU_GUEST_CHECK_B64__,__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__; tail=YjI1bFZHRmliR1VBQUFBQUFBSUFB d0FDQUFJQUFnQUNBQUlBQXdBQ0FBRUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FBSUEKQWdBQ0FBSUFB Z0FDQUFNQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQUJB QURBQUlBQWdBQwpBQUlBQWdBQ0FBSUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQU...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 261299
- `line_count`: 4868
- `sha256`: 576275cdf35ef33bb43c1aac29ec27ffe4908083fe46d934978f9c794dec1573
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__"]}
- `summary`: cmd evidence; size=261299 bytes; lines=4868; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_DEV_DISK_LINK__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF          �    0      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF          �    �      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF          �    @<      @       ��         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5�                      S                                             ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                              ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/perf.tsv

- `kind`: tsv
- `size_bytes`: 444
- `line_count`: 2
- `sha256`: e5edd1561c40deb8a1b5ff48d795dc9a9e2f3cddc7b203dce066452f1217a49d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: tsv evidence; size=444 bytes; lines=2; markers=<none>; tail=boot_seconds guest_check_seconds poweroff_seconds total_seconds soak_seconds fs_stress_mib fs_tree_files process_loops uart_rx_stress_lines block_parallel_jobs block_job_mib net_tcp_burst_loops input_chunk_bytes input_chunk_delay max_cycles rootfs_overlay 1...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 82920
- `sha256`: a64cdc06eaeee205c411e6416fa6c3e5ada46fe91c89f2c37597c1953bd9c2e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=82920; markers=<none>; tail=                                                                                                                                                                                                                                                                 ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1030
- `line_count`: 4
- `sha256`: 935458b96562ccb85260acf82bb4f3cee3df18f79cbf30d9c99ebe11643edb6b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"PASS": 10, "SKIP": 2}
- `summary`: tsv evidence; size=1030 bytes; lines=4; SKIP=2; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS Linux...

### .github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/run-manifest.json

- `kind`: json
- `size_bytes`: 4040
- `line_count`: 107
- `sha256`: b3d6006f20537bfc0ddb170e0f53470ece65ab0abc02935ac7a369c75fe233f1
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T02:25:50+00:00
- `markers`: {"PASS": 12, "SKIP": 2}
- `summary`: json evidence; size=4040 bytes; lines=107; SKIP=2; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-14-2026-06-14-nemu-python-cnf-hard-real/dispatch-log.md", "evidence_dir": ".github/task-runs/2...
