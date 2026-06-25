# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun
- `task_slug`: 2026-06-22-nemu-amo-pmem-continue-full-gate-rerun
- `profile`: nemu-dev-full-gate
- `asset_count`: 29
- `total_size_bytes`: 8591800675

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 258704
- `line_count`: 4943
- `sha256`: 705558bb93c1e0a13bfadf15921dc932cf1d997cfcf5455ab3c97c260ca225ff
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"GOOD_TRAP": 1, "PANIC": 1, "PASS": 117, "symbolic": ["__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_RC__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_FULL_PYTHON_RE_SOURCE_EXEC_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_RC__", "__NEMU_CHECK_HWRNG_CURRENT__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_RTC0_HWCLOCK__"]}
- `summary`: log evidence; size=258704 bytes; lines=4943; PASS=117; GOOD_TRAP=1; PANIC=1; symbolic=__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__,__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__; tail=BYTES__:77780 __PYTHON_RE_SOURCE_DIAG_IPADDRESS_SHA256__:b2dc2c1f2bf13ca8b54a1f69b43a7dd20b81d8ef97bd1a5af717b18bc5cd0a1b __PYTHON_RE_SOURCE_DIAG_IPADDRESS_INT_FROM_BYTES_TOKEN_OFFSET__:38610 __PYTHON_RE_SOURCE_DIAG_IPADDRESS_INT_FROM_BYTES_WINDOW_HEX__:705...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 577
- `line_count`: 8
- `sha256`: 2c6f2b2924698c6e43d6463b4f9f8527ad94cca1b3e66d32c278b7d89b9eb215
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=577 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1090
- `line_count`: 17
- `sha256`: 4d01ea2f11d2f1bf4b6d67538818c3629e68480a1a4802a73cf6e4bd2f89c702
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=1090 bytes; lines=17; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8579
- `line_count`: 99
- `sha256`: c6a469df7114616e501e615f2890bad25a4f03c28c31235f682f1d63ad287e74
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=8579 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8272
- `line_count`: 92
- `sha256`: afff9cf9d8a1ffc33f7310ba085ae003e6163d70844f120cb202e8a6eef0be61
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=8272 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7540
- `line_count`: 68
- `sha256`: fe167dd08017f88a2de53911cf5a38b8248265e7e3ec69e1ccc714891a3e02c5
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=7540 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 131495
- `line_count`: 2344
- `sha256`: 6ecab7bdb4b9eb0353a8149949ecd609db27296755405a124c061f58a2b83896
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2328, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=131495 bytes; lines=2344; FAIL=4; PASS=2328; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=-hostless-hello_1.1_riscv64.deb PASS gen-nemu-hostless-apt-assets.py depends="nemu-hostless-hello (= 1.1)" PASS gen-nemu-hostless-apt-assets.py "depends": "nemu-hostless-hello (= 1.1)" PASS gen_dts.py stdout-path = "serial0:115200n8"; PASS gen_dts.py serial...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 254508
- `line_count`: 4442
- `sha256`: e8b92557af44445a2b23fc421a7f310ee149f1ee4f98d188722346da10876b73
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=254508 bytes; lines=4442; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=ue=0x00005555 pc=0x000000008000000c [0m [1;34m[src/cpu/cpu-exec.c:979 cpu_exec] nemu: [1;32mHIT GOOD TRAP [0m at pc = 0x000000008000000c [0m [1;34m[src/device/disk.c:429 virtio_blk_statistic] virtio-blk async runtime submitted=0 completed=0 pending=0 done=0...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 304515
- `line_count`: 5919
- `sha256`: 055de9f2fc908853e36cb05602942cfff493d152cc6207b5b8eb58eae57ce7f2
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"GOOD_TRAP": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__"]}
- `summary`: log evidence; size=304515 bytes; lines=5919; GOOD_TRAP=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__; tail=TRESS_LOG_END__ __NEMU_CHECK_PASS__:full-userland-python-stdlib-stress-loop __NEMU_CHECK_FULL_PYTHON_CNF_DIAG_RC__:0 __NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__ __PYTHON_CNF_DIAG_VERSION__:3.10.12 __PYTHON_CNF_DIAG_DIVMOD_NEG_US__:(-1, 999999) __PYTHON_CN...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 18917
- `line_count`: 267
- `sha256`: a8cb4906128d313bf0fe94e86e2a0c8d6dd4840f91805a48bcca59c9344672f4
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"PANIC": 2, "PASS": 48, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=18917 bytes; lines=267; PASS=48; PANIC=2; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 402499
- `line_count`: 192
- `sha256`: 399325a1c5d8f27eda05b9df7084c5609fa27ff67d63bda9dd227a43869d2785
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_APPEND_DONE__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_GUEST_UPLOAD_GROUP__", "__NEMU_GUEST_UPLOAD_MODE__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=402499 bytes; lines=192; symbolic=__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__,__NEMU_GUEST_SCRIPT_SHA256__; tail=BQUFGCkFBQUFOUUFBQUFBQUFBQUFBQUFBVUk0' 'QUFBQUFBQUFGQUFBQU5nQUFBQUFBQUFBQUFBQUFXSTRBQUFBQUFBQUZBQUFBTndBQUFBQUEKQUFB' 'QUFBQUFZSTRBQUFBQUFBQUZBQUFBT0FBQUFBQUFBQUFBQUFBQWFJNEFBQUFBQUFBRkFBQUFPUUFB' 'QUFBQUFBQUFBQUFBY0k0QQpBQUFBQUFBRkFBQUFPZ0FBQUFBQUFBQUFBQUF...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 282821
- `line_count`: 5323
- `sha256`: 348e103ee29fc796286e04082b49dfe90e960accbb27f4583804e6fce65dd77d
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__"]}
- `summary`: cmd evidence; size=282821 bytes; lines=5323; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_DEV_DISK_LINK__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF � 0 @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � ( (- (- � � � D D P�td < < < T T Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU >��� ����䊵 �����}� GNU k �| W K D + � = i � � � � p � 8 z " ' P � d snprintf setsockopt puts __stack_chk_fail __pr...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � 4 4 Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU <�2ᑤ��n��6�:U ���| GNU k �| � V Q / " � ~ h 6 � � � = J o " � � c � ` setsockopt puts __stack_chk_fail __printf_ch...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF � � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � $ $ Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU �ږד�� ����D��]�?A� GNU k �| � T 6 " � / f = � � � m F w " ! M � � a � $ setsockopt puts __stack_chk_fail __print...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF � @< @ �� @ 8 @ @ @ @ 0 0 p p p ! ! p 5� S \r \r �z �� �� p � �z �� �� � � � D D P�td �l �l �l � � Q�td R�td �z �� �� h h /lib/ld-linux-riscv64-lp64d.so.1 GNU # �Ʈ /��A�ۭ oﰁ GNU h h k �| 0" � 0 I C S � � # G � � � � u > - � d 5 � v � � " � � S � � � ( p...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S | | ( (- (- � � @ @- @- � � � D D P�td ( ( ( $ $ Q�td R�td ( (- (- � � /lib/ld-linux-riscv64-lp64d.so.1 GNU � �mY�Y��F��rq ��5 GNU k �| ` O * � ? 1 � D p y � � 8 a " # � \ ` � setsockopt __stack_chk_fail __printf_c...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/perf.tsv

- `kind`: tsv
- `size_bytes`: 456
- `line_count`: 2
- `sha256`: c8a59a24b82583eb47c98571b6243e05c5887b220ebffbfe5f5fceb61c0545f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: tsv evidence; size=456 bytes; lines=2; markers=<none>; tail=boot_seconds guest_check_seconds poweroff_seconds total_seconds soak_seconds fs_stress_mib fs_tree_files process_loops uart_rx_stress_lines block_parallel_jobs block_job_mib net_tcp_burst_loops input_chunk_bytes input_chunk_delay max_cycles rootfs_overlay 7...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 80528
- `sha256`: 74f95a53c1633f8f491bca59b28aa34bd32e28f30424fd9a8ecfec418865b87f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=80528; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1082
- `line_count`: 4
- `sha256`: ef24ca72890575c7fefa1ec80c808d834db5a2ed2ce2265dbf6b7f37956a4aee
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"PASS": 10, "SKIP": 2}
- `summary`: tsv evidence; size=1082 bytes; lines=4; SKIP=2; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/evidence/software-flow-contract.log nemu-ubuntu-static nemu ne...

### .github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/run-manifest.json

- `kind`: json
- `size_bytes`: 4248
- `line_count`: 107
- `sha256`: 8bdedf8c898d6ede87ae1fcf99b4b2cadd36d38a9ba912a34b12263f8790a272
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T22:24:49+00:00
- `markers`: {"PASS": 12, "SKIP": 2}
- `summary`: json evidence; size=4248 bytes; lines=107; SKIP=2; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-amo-pmem-continue-full-gate-rerun/dispatch-log.md", "evidence_...
