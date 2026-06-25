# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-full-extended-soak-600s
- `task_slug`: 2026-06-22-nemu-full-extended-soak-600s
- `profile`: nemu-dev-full-soak
- `asset_count`: 29
- `total_size_bytes`: 8592306958

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-dev-full-soak-gate.log

- `kind`: log
- `size_bytes`: 259266
- `line_count`: 4953
- `sha256`: 7fd8f81c37dde3af72d4a824084a3e40ce1569bc93a598f89da88805710ae90f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"GOOD_TRAP": 1, "PANIC": 1, "PASS": 119, "symbolic": ["__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_RC__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_FULL_PYTHON_RE_SOURCE_EXEC_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_STDLIB_STRESS_RC__", "__NEMU_CHECK_HWRNG_CURRENT__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_RTC0_HWCLOCK__"]}
- `summary`: log evidence; size=259266 bytes; lines=4953; PASS=119; GOOD_TRAP=1; PANIC=1; symbolic=__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__,__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__,__NEMU_CHECK_FULL_PYTHON_CNF_DIAG_LOG_BEGIN__; tail=2dc2c1f2bf13ca8b54a1f69b43a7dd20b81d8ef97bd1a5af717b18bc5cd0a1b __PYTHON_RE_SOURCE_DIAG_IPADDRESS_INT_FROM_BYTES_TOKEN_OFFSET__:38610 __PYTHON_RE_SOURCE_DIAG_IPADDRESS_INT_FROM_BYTES_WINDOW_HEX__:705f737472290a0a20202020202020207472793a0a2020202020202020202...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1008
- `line_count`: 15
- `sha256`: c9a43f788d2dba4493db1cf8c32068b1cfe2ee90d68ba27f9aa85e1982e664fb
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: log evidence; size=1008 bytes; lines=15; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8386
- `line_count`: 99
- `sha256`: 224816dcdf698c54e09e04ba403de9ea27fc7e3148847dc59deae4ec07ae3d90
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: log evidence; size=8386 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8079
- `line_count`: 92
- `sha256`: d33f9a526e1bc57bc3fb81e37088b976014532af01ff46972b07ba98ef2858c7
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: log evidence; size=8079 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7347
- `line_count`: 68
- `sha256`: b2afde1be14088270ae3e118293b0c47265b248631c3c9f599e00eb064c2fc0a
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: log evidence; size=7347 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 126023
- `line_count`: 2267
- `sha256`: 78cd7cc67b6ef440af5f1b5e01d170dc414d15147b54ccd04ac913b75cc6ec90
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2358, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=126023 bytes; lines=2267; FAIL=4; PASS=2358; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=flight.py VALUE_%s PASS nemu-python-int-preflight.py %s_BIT_LENGTH PASS nemu-python-int-preflight.py import sys PASS nemu-python-int-preflight.py import ctypes PASS nemu-python-int-preflight.py emit_pylong_baseline PASS nemu-python-int-preflight.py emit_pyl...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 251818
- `line_count`: 4407
- `sha256`: 5096320c6de4cca4b45898a3cbac6fe73f901a17bb68152669adc5fe5e6f1ba2
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"GOOD_TRAP": 27, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=251818 bytes; lines=4407; PASS=370; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=for_client_if_enabled] GDB stub client connected [0m [1;34m[src/monitor/gdbstub.c:616 handle_breakpoint_packet] GDB stub inserted hardware breakpoint at 0x0000000080000008 kind=4 [0m [1;34m[src/monitor/gdbstub.c:753 handle_continue] GDB stub continue reques...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/console.log

- `kind`: log
- `size_bytes`: 372926
- `line_count`: 7919
- `sha256`: 940ca1886d7cb9b1c62158b9dffb5af2989708cf0b7ca76e5906942a216a1b83
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"GOOD_TRAP": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_CLEAR_HOOKS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_ETC_PARTS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_GPGV_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INRELEASE_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_BEGIN__"]}
- `summary`: log evidence; size=372926 bytes; lines=7919; GOOD_TRAP=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__,__NEMU_CHECK_FS_STRESS_BYTES__; tail=_PYTHON_CNF_DIAG_ABS_MICROSECONDS_LT_FLOAT__:True __PYTHON_CNF_DIAG_ABS_NEG_ONE_LT_FLOAT__:True __PYTHON_CNF_DIAG_RE_REPEAT_COMPILE__:'(?=-{2,}\\w)' __PYTHON_CNF_DIAG_TEXTWRAP_IMPORT__:ok __PYTHON_CNF_DIAG_TEXTWRAP_WORDSEP_LEN__:483 __PYTHON_CNF_DIAG_OPTPAR...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/focused-make.log

- `kind`: log
- `size_bytes`: 19041
- `line_count`: 274
- `sha256`: a023cdd922f80055d2028d6a4c11cd03853982e8187925d66bab9131475405dc
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"PANIC": 2, "PASS": 48, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=19041 bytes; lines=274; PASS=48; PANIC=2; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 664209
- `line_count`: 300
- `sha256`: 7817dc3fbc6ee14c197fc64698e91eee569cb16bbb7bcd1dba8d7ee05451c160
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_APPEND_DONE__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_GUEST_UPLOAD_GROUP__", "__NEMU_GUEST_UPLOAD_MODE__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=664209 bytes; lines=300; symbolic=__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__,__NEMU_GUEST_SCRIPT_SHA256__; tail=BQUZBQUFBTmdBQUFBQUFBQUFBQUFBQVdJNEFBQUFBQUFBRkFB' 'QUFOd0FBQUFBQQpBQUFBQUFBQVlJNEFBQUFBQUFBRkFBQUFPQUFBQUFBQUFBQUFBQUFBYUk0QUFB' 'QUFBQUFGQUFBQU9RQUFBQUFBQUFBQUFBQUFjSTRBCkFBQUFBQUFGQUFBQU9nQUFBQUFBQUFBQUFB' 'QUFlSTRBQUFBQUFBQUZBQUFBT3dBQUFBQUFBQUFBQUFBQWd...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 467344
- `line_count`: 7307
- `sha256`: 1c421c10864bc7e5a489b3cf95f98a01ce0027e3921e1ff77a448e73b2683a35
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_GUEST_UPTIME_BEGIN__", "__NEMU_CHECK_GUEST_UPTIME_END__", "__NEMU_CHECK_INTERRUPTS_LINE__", "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL_GROW__", "__NEMU_CHECK_INTERRUPTS_TABLE_TOTAL__", "__NEMU_CHECK_INTERRUPTS_TOTAL_GROW__", "__NEMU_CHECK_INTERRUPTS_TOTAL__", "__NEMU_CHECK_INTERRUPTS__", "__NEMU_CHECK_IRQ_SERIAL__", "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW_DIAG__", "__NEMU_CHECK_IRQ_VIRTIO_BLK_GROW__"]}
- `summary`: cmd evidence; size=467344 bytes; lines=7307; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_DEV_DISK_LINK__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF � 0 @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � ( (- (- � � � D D P�td < < < T T Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU >��� ����䊵 �����}� GNU k �| W K D + � = i � � � � p � 8 z " ' P � d snprintf setsockopt puts __stack_chk_fail __pr...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � 4 4 Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU <�2ᑤ��n��6�:U ���| GNU k �| � V Q / " � ~ h 6 � � � = J o " � � c � ` setsockopt puts __stack_chk_fail __printf_ch...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF � � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � $ $ Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU �ږד�� ����D��]�?A� GNU k �| � T 6 " � / f = � � � m F w " ! M � � a � $ setsockopt puts __stack_chk_fail __print...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF � @< @ �� @ 8 @ @ @ @ 0 0 p p p ! ! p 5� S \r \r �z �� �� p � �z �� �� � � � D D P�td �l �l �l � � Q�td R�td �z �� �� h h /lib/ld-linux-riscv64-lp64d.so.1 GNU # �Ʈ /��A�ۭ oﰁ GNU h h k �| 0" � 0 I C S � � # G � � � � u > - � d 5 � v � � " � � S � � � ( p...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S | | ( (- (- � � @ @- @- � � � D D P�td ( ( ( $ $ Q�td R�td ( (- (- � � /lib/ld-linux-riscv64-lp64d.so.1 GNU � �mY�Y��F��rq ��5 GNU k �| ` O * � ? 1 � D p y � � 8 a " # � \ ` � setsockopt __stack_chk_fail __printf_c...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/perf.tsv

- `kind`: tsv
- `size_bytes`: 453
- `line_count`: 2
- `sha256`: c6d05910d5996d5ef3a4366e00de0d546c4f755a1c77e5056761410eaef3afd2
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: tsv evidence; size=453 bytes; lines=2; markers=<none>; tail=boot_seconds guest_check_seconds poweroff_seconds total_seconds soak_seconds fs_stress_mib fs_tree_files process_loops uart_rx_stress_lines block_parallel_jobs block_job_mib net_tcp_burst_loops input_chunk_bytes input_chunk_delay max_cycles rootfs_overlay 7...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 93921
- `sha256`: 8718ed19981d5c73eaa727ff98cb5624cc5021e38d38cd9247ac1967fa2a566f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=93921; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nemu-ubuntu-full-soak/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1031
- `line_count`: 4
- `sha256`: 7d44c00c5a6da1ae63296e6d173c9e1acc0ab5f605de57de59b235ef26725929
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"PASS": 10, "SKIP": 2}
- `summary`: tsv evidence; size=1031 bytes; lines=4; SKIP=2; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PASS Li...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/run-manifest.json

- `kind`: json
- `size_bytes`: 4077
- `line_count`: 107
- `sha256`: 89224acf66ec4cdcee2938ec0f26036020b719272a91abb7af22f25b7ad7d6d0
- `encoding`: utf-8
- `indexed_at`: 2026-06-21T17:19:54+00:00
- `markers`: {"PASS": 12, "SKIP": 2}
- `summary`: json evidence; size=4077 bytes; lines=107; SKIP=2; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-full-extended-soak-600s/dispatch-log.md", "evidence_dir": ".github/task-...
