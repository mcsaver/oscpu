# Evidence Index

## 基本信息

- `task_id`: 2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real
- `task_slug`: 2026-06-24-nemu-full-openssh-local-forward-full-gate-real
- `profile`: nemu-dev-full-gate
- `asset_count`: 31
- `total_size_bytes`: 8592845879

## 证据资产

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 577262
- `line_count`: 11065
- `sha256`: cb421d905c74f41dd8e20b7865bdf4e648575007fc7636d4a3a0a8047cf18e73
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"GOOD_TRAP": 1, "PANIC": 1, "PASS": 298, "symbolic": ["__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUP__", "__NEMU_CHECK_FULL_ACCOUNT_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__", "__NEMU_CHECK_FULL_ACCOUNT_SU_GID__", "__NEMU_CHECK_FULL_ACCOUNT_SU_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_END__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_UID__", "__NEMU_CHECK_FULL_ACCOUNT_SU_USER__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__"]}
- `summary`: log evidence; size=577262 bytes; lines=11065; PASS=298; GOOD_TRAP=1; PANIC=1; symbolic=__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__,__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__,__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_GROUP__; tail=9,54,57 __PYTHON_INT_PREFLIGHT_VALUE_169__:169 __PYTHON_INT_PREFLIGHT_VALUE_169_BIT_LENGTH__:8 __PYTHON_INT_PREFLIGHT_TEXT_254_REPR__:'254' __PYTHON_INT_PREFLIGHT_TEXT_254_LEN__:3 __PYTHON_INT_PREFLIGHT_TEXT_254_ORDS__:50,53,52 __PYTHON_INT_PREFLIGHT_VALUE_...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1654
- `line_count`: 29
- `sha256`: 6aebbc10e503799043d672aff40c7a6c4a2ac3f08da18178e954db9cfb6be41a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: log evidence; size=1654 bytes; lines=29; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 9291
- `line_count`: 102
- `sha256`: 116993d85f8b14d576c39cde5b95d2fa898f7a859ba16c76a0d17fbd16aeaf49
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: log evidence; size=9291 bytes; lines=102; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8982
- `line_count`: 95
- `sha256`: e70d7839b0ad7b999513fd8cd8bb971e08b612bcf80862264ab323e8c5c811cd
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: log evidence; size=8982 bytes; lines=95; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 8129
- `line_count`: 68
- `sha256`: ea4800f4d49360c53521c485ad908cbe55087cc8508bcd5f0762f48649daa8d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: log evidence; size=8129 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 164533
- `line_count`: 2834
- `sha256`: 8b189e99516eeb4ab36cdc48b73e351f7e2fbb32d3ebc6c7783aa939c5375603
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2247, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"]}
- `summary`: log evidence; size=164533 bytes; lines=2834; FAIL=1; PASS=2247; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=ession:/usr/lib/systemd/user/dbus.socket PASS check-ubuntu-rootfs.sh dbus-user-session:/usr/lib/systemd/user/dbus.service PASS check-ubuntu-rootfs.sh dbus-user-session:/usr/lib/systemd/user/sockets.target.wants/dbus.socket PASS check-ubuntu-rootfs.sh ubuntu...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 258253
- `line_count`: 4484
- `sha256`: 31dd4436d94e9fa01271398c1843ea96ff2b981b2e4ebe7347f7bc9acf86d978
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 372, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=258253 bytes; lines=4484; PASS=372; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 655342
- `line_count`: 12659
- `sha256`: b576bdf50b029c3cb64e1c6252f61324aaecb286712e79c5bd515ca50a0f23e6
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"GOOD_TRAP": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_END__"]}
- `summary`: log evidence; size=655342 bytes; lines=12659; GOOD_TRAP=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__; tail=EFLIGHT_VALUE_2_BIT_LENGTH__:2 __PYTHON_INT_PREFLIGHT_TEXT_169_REPR__:'169' __PYTHON_INT_PREFLIGHT_TEXT_169_LEN__:3 __PYTHON_INT_PREFLIGHT_TEXT_169_ORDS__:49,54,57 __PYTHON_INT_PREFLIGHT_VALUE_169__:169 __PYTHON_INT_PREFLIGHT_VALUE_169_BIT_LENGTH__:8 __PYTH...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 30988
- `line_count`: 414
- `sha256`: eaf641c1188e3f597e432939346cd9d5dfdaf61873306d8f824b4b2e0808276f
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"PANIC": 2, "PASS": 52, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=30988 bytes; lines=414; PASS=52; PANIC=2; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 578447
- `line_count`: 265
- `sha256`: e18d537dfea8a02c384e7093ff12930b9d44592b9331bf0a6e6f0924cd4cd807
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_APPEND_DONE__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_GUEST_UPLOAD_GROUP__", "__NEMU_GUEST_UPLOAD_MODE__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=578447 bytes; lines=265; symbolic=__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__,__NEMU_GUEST_SCRIPT_SHA256__; tail=QUFBQUFGQUFBQU5nQUFBQUFBQUFBQUFBQUFXSTRBQUFBQUFBQUZBQUFB' 'TndBQUFBQUEKQUFBQUFBQUFZSTRBQUFBQUFBQUZBQUFBT0FBQUFBQUFBQUFBQUFBQWFJNEFBQUFB' 'QUFBRkFBQUFPUUFBQUFBQUFBQUFBQUFBY0k0QQpBQUFBQUFBRkFBQUFPZ0FBQUFBQUFBQUFBQUFB' 'ZUk0QUFBQUFBQUFGQUFBQU93QUFBQUFBQUFBQUFB...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 406865
- `line_count`: 7485
- `sha256`: 9547f2dd69952f871b8b0c40165d17a195558f941ad0b02555fd58bcf602ce0d
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"ERROR": 7, "PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUP__", "__NEMU_CHECK_FULL_ACCOUNT_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__"]}
- `summary`: cmd evidence; size=406865 bytes; lines=7485; ERROR=7; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_DEV_DISK_LINK__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF � 0 @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � ( (- (- � � � D D P�td < < < T T Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU >��� ����䊵 �����}� GNU k �| W K D + � = i � � � � p � 8 z " ' P � d snprintf setsockopt puts __stack_chk_fail __pr...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � 4 4 Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU <�2ᑤ��n��6�:U ���| GNU k �| � V Q / " � ~ h 6 � � � = J o " � � c � ` setsockopt puts __stack_chk_fail __printf_ch...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF � � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � $ $ Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU �ږד�� ����D��]�?A� GNU k �| � T 6 " � / f = � � � m F w " ! M � � a � $ setsockopt puts __stack_chk_fail __print...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-oomd-pressure-probe.b64

- `kind`: b64
- `size_bytes`: 13856
- `line_count`: 180
- `sha256`: fad1015485c770e96cb717ec972c584ee271af9a1918559427e4ed9ddbd25b58
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13856 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAKBEAAAAAAABAAAAAAAAAAJAhAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADkgAAAAAA...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-oomd-pressure-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10256
- `line_count`: 67
- `sha256`: 2adf2df0baef0e85d498e886511a597f7a6f9b4d3bd40c3a504960cdbc886a38
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: riscv64 evidence; size=10256 bytes; lines=67; markers=<none>; tail=ELF � ( @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 9 S ` ` � �, �, - - � � � D D P�td � � � 4 4 Q�td R�td � �, �, /lib/ld-linux-riscv64-lp64d.so.1 GNU ��� Ɨ� ���"/E��] � GNU k �| � f " _ > L ' � 9 � � � � Z x � � " � � > E 4 s � 6 setvbuf puts sysconf __stack_chk_fai...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF � @< @ �� @ 8 @ @ @ @ 0 0 p p p ! ! p 5� S \r \r �z �� �� p � �z �� �� � � � D D P�td �l �l �l � � Q�td R�td �z �� �� h h /lib/ld-linux-riscv64-lp64d.so.1 GNU # �Ʈ /��A�ۭ oﰁ GNU h h k �| 0" � 0 I C S � � # G � � � � u > - � d 5 � v � � " � � S � � � ( p...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S | | ( (- (- � � @ @- @- � � � D D P�td ( ( ( $ $ Q�td R�td ( (- (- � � /lib/ld-linux-riscv64-lp64d.so.1 GNU � �mY�Y��F��rq ��5 GNU k �| ` O * � ? 1 � D p y � � 8 a " # � \ ` � setsockopt __stack_chk_fail __printf_c...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/perf.tsv

- `kind`: tsv
- `size_bytes`: 581
- `line_count`: 2
- `sha256`: 2dad62dc0598910338d710fd40ac243debb7e4a6263f4100201073a0fc4cb816
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: tsv evidence; size=581 bytes; lines=2; markers=<none>; tail=boot_seconds guest_check_seconds poweroff_seconds total_seconds soak_seconds fs_stress_mib fs_tree_files process_loops uart_rx_stress_lines block_parallel_jobs block_job_mib net_tcp_burst_loops input_chunk_bytes input_chunk_delay cron_job_timeout anacron_ti...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 643499
- `sha256`: 12835f28cf6ec837b1d38c156139d11f9605fffb32ef64487ffdda7deb70d8f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=643499; markers=<none>; tail=

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1114
- `line_count`: 4
- `sha256`: 157fbbb1664094a9a60205420d033cb7ddb2aaadcdf338371212a4761fccdf0a
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"PASS": 10, "SKIP": 2}
- `summary`: tsv evidence; size=1114 bytes; lines=4; SKIP=2; PASS=10; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/evidence/software-flow-contract.log nemu-ubuntu-static...

### .github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/run-manifest.json

- `kind`: json
- `size_bytes`: 4376
- `line_count`: 107
- `sha256`: 7ffcebd680641dca8da9f21238cb17e0cb0c1c705085488c1c843d92f7fe125e
- `encoding`: utf-8
- `indexed_at`: 2026-06-24T07:51:28+00:00
- `markers`: {"PASS": 12, "SKIP": 2}
- `summary`: json evidence; size=4376 bytes; lines=107; SKIP=2; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-24-2026-06-24-nemu-full-openssh-local-forward-full-gate-real/dispatch-log...
