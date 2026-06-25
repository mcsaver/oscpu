# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate
- `task_slug`: 2026-06-22-nemu-full-cron-timeout-full-gate
- `profile`: nemu-dev-full-gate
- `asset_count`: 29
- `total_size_bytes`: 8591936879

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 277431
- `line_count`: 5197
- `sha256`: 61cee4c76805b85efabf3220779db44c839731f96ed4ac3513eac573c742ad3b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"GOOD_TRAP": 1, "PANIC": 1, "PASS": 199, "symbolic": ["__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUP__", "__NEMU_CHECK_FULL_ACCOUNT_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__", "__NEMU_CHECK_FULL_ACCOUNT_SU_GID__", "__NEMU_CHECK_FULL_ACCOUNT_SU_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_END__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_UID__", "__NEMU_CHECK_FULL_ACCOUNT_SU_USER__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__"]}
- `summary`: log evidence; size=277431 bytes; lines=5197; PASS=199; GOOD_TRAP=1; PANIC=1; symbolic=__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__,__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__,__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_GROUP__; tail=f69b43a7dd20b81d8ef97bd1a5af717b18bc5cd0a1b __PYTHON_RE_SOURCE_DIAG_IPADDRESS_INT_FROM_BYTES_TOKEN_OFFSET__:38610 __PYTHON_RE_SOURCE_DIAG_IPADDRESS_INT_FROM_BYTES_WINDOW_HEX__:705f737472290a0a20202020202020207472793a0a20202020202020202020202072657475726e206...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1276
- `line_count`: 21
- `sha256`: e4ab64ed365ba135743e085cdfc4afad279c30f26b17e033a05e8e67b2c62c65
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: log evidence; size=1276 bytes; lines=21; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8813
- `line_count`: 100
- `sha256`: b246de93835399c4c6b9723bc487fd22c87f95334144e153aae4ff673879d509
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: log evidence; size=8813 bytes; lines=100; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8506
- `line_count`: 93
- `sha256`: 23e74ff6e18a35fb5d6ee94777dc2cd81190cc55ffe08d482835b911c6be32a9
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: log evidence; size=8506 bytes; lines=93; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7735
- `line_count`: 68
- `sha256`: a643557f78f8461b4f9d9005fd3b8b0adc79bc0ebf2a5ca0af31de60f029715b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: log evidence; size=7735 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 141008
- `line_count`: 2513
- `sha256`: 1660feabc3503ec4fad7f4f6e73f195b5f68ffd663d49b7dedf465c3bfab275f
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2306, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__"]}
- `summary`: log evidence; size=141008 bytes; lines=2513; FAIL=4; PASS=2306; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=check-ubuntu-rootfs.sh account groupadd command PASS check-ubuntu-rootfs.sh account groupdel command PASS check-ubuntu-rootfs.sh account useradd command PASS check-ubuntu-rootfs.sh account userdel command PASS check-ubuntu-rootfs.sh account passwd command P...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 256817
- `line_count`: 4470
- `sha256`: 41ecb38aea616fe7317e8ea55fe7bfb38728b03b413d77a69b88669d48805c46
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=256817 bytes; lines=4470; PASS=370; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 349462
- `line_count`: 6663
- `sha256`: 9e11fa60a0df1a09efea6108e6ee1e0351db505d624635a04656a4b519fb8d61
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"GOOD_TRAP": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_END__"]}
- `summary`: log evidence; size=349462 bytes; lines=6663; GOOD_TRAP=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__; tail=T_FROM_BYTES_MAP__:2851995648 __PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP_BIT_LENGTH__:32 __PYTHON_INT_PREFLIGHT_OK__ __PYTHON_INT_PREFLIGHT_TEXT_0_REPR__:'0' __PYTHON_INT_PREFLIGHT_TEXT_0_LEN__:1 __PYTHON_INT_PREFLIGHT_TEXT_0_ORDS__:48 __PYTHON_INT_PREFLIGHT...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 24606
- `line_count`: 345
- `sha256`: 5a35c18b315adbb1c01adaf2e781d026cc8f6533f874a74b89f34dde0f33722c
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"PANIC": 2, "PASS": 48, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=24606 bytes; lines=345; PASS=48; PANIC=2; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 434313
- `line_count`: 205
- `sha256`: c110e188bfd5ea2fc1dc52f816ebf7b59c70e15f4308686fad2ac7fe6e66eaf7
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_APPEND_DONE__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_GUEST_UPLOAD_GROUP__", "__NEMU_GUEST_UPLOAD_MODE__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=434313 bytes; lines=205; symbolic=__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__,__NEMU_GUEST_SCRIPT_SHA256__; tail=BQUZBQUFBTmdBQUFBQUFB' 'QUFBQUFBQVdJNEFBQUFBQUFBRkFBQUFOd0FBQUFBQQpBQUFBQUFBQVlJNEFBQUFBQUFBRkFBQUFP' 'QUFBQUFBQUFBQUFBQUFBYUk0QUFBQUFBQUFGQUFBQU9RQUFBQUFBQUFBQUFBQUFjSTRBCkFBQUFB' 'QUFGQUFBQU9nQUFBQUFBQUFBQUFBQUFlSTRBQUFBQUFBQUZBQUFBT3dBQUFBQUFBQUFBQUFBQWd...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 305257
- `line_count`: 5808
- `sha256`: 55c2cb516b34bae098d9027a90fa6481893fa0c0903485e9bd94b8ed8827be35
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"ERROR": 5, "PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUP__", "__NEMU_CHECK_FULL_ACCOUNT_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__"]}
- `summary`: cmd evidence; size=305257 bytes; lines=5808; ERROR=5; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_DEV_DISK_LINK__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF � 0 @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � ( (- (- � � � D D P�td < < < T T Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU >��� ����䊵 �����}� GNU k �| W K D + � = i � � � � p � 8 z " ' P � d snprintf setsockopt puts __stack_chk_fail __pr...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � 4 4 Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU <�2ᑤ��n��6�:U ���| GNU k �| � V Q / " � ~ h 6 � � � = J o " � � c � ` setsockopt puts __stack_chk_fail __printf_ch...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF � � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � $ $ Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU �ږד�� ����D��]�?A� GNU k �| � T 6 " � / f = � � � m F w " ! M � � a � $ setsockopt puts __stack_chk_fail __print...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF � @< @ �� @ 8 @ @ @ @ 0 0 p p p ! ! p 5� S \r \r �z �� �� p � �z �� �� � � � D D P�td �l �l �l � � Q�td R�td �z �� �� h h /lib/ld-linux-riscv64-lp64d.so.1 GNU # �Ʈ /��A�ۭ oﰁ GNU h h k �| 0" � 0 I C S � � # G � � � � u > - � d 5 � v � � " � � S � � � ( p...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S | | ( (- (- � � @ @- @- � � � D D P�td ( ( ( $ $ Q�td R�td ( (- (- � � /lib/ld-linux-riscv64-lp64d.so.1 GNU � �mY�Y��F��rq ��5 GNU k �| ` O * � ? 1 � D p y � � 8 a " # � \ ` � setsockopt __stack_chk_fail __printf_c...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/perf.tsv

- `kind`: tsv
- `size_bytes`: 495
- `line_count`: 2
- `sha256`: 9450707a9bd5b5b19207faa37be2f39c285dc4652a69ec12a0804c738c597494
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: tsv evidence; size=495 bytes; lines=2; markers=<none>; tail=boot_seconds guest_check_seconds poweroff_seconds total_seconds soak_seconds fs_stress_mib fs_tree_files process_loops uart_rx_stress_lines block_parallel_jobs block_job_mib net_tcp_burst_loops input_chunk_bytes input_chunk_delay cron_job_timeout locale_gen...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 116593
- `sha256`: d82abd878fb0f24941adc7793cd4378deb685a7ac0c01bdc5d31c4e2739132e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=116593; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1058
- `line_count`: 4
- `sha256`: 83e86615fe887375462d35366650962a79bd96a5c1c828d72086033de30f59d1
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"PASS": 10, "SKIP": 2}
- `summary`: tsv evidence; size=1058 bytes; lines=4; SKIP=2; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PAS...

### .github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/run-manifest.json

- `kind`: json
- `size_bytes`: 4152
- `line_count`: 107
- `sha256`: 4101e75c7d1013b05e515a701c770b090a70df6a008a5844193e2174dcdbceed
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T14:48:25+00:00
- `markers`: {"PASS": 12, "SKIP": 2}
- `summary`: json evidence; size=4152 bytes; lines=107; SKIP=2; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-22-2026-06-22-nemu-full-cron-timeout-full-gate/dispatch-log.md", "evidence_dir": ".gith...
