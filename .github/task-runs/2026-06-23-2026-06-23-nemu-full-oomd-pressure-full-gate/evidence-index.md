# Evidence Index

## 基本信息

- `task_id`: 2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate
- `task_slug`: 2026-06-23-nemu-full-oomd-pressure-full-gate
- `profile`: nemu-dev-full-gate
- `asset_count`: 28
- `total_size_bytes`: 8592577734

## 证据资产

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 517938
- `line_count`: 10209
- `sha256`: 28427208cb78255deaa166bab08086485baf761144af813304eb4ba63c3f2935
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"FAIL": 2, "PASS": 10, "symbolic": ["__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUP__", "__NEMU_CHECK_FULL_ACCOUNT_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__", "__NEMU_CHECK_FULL_ACCOUNT_SU_GID__", "__NEMU_CHECK_FULL_ACCOUNT_SU_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_SU_OUTPUT_END__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_UID__", "__NEMU_CHECK_FULL_ACCOUNT_SU_USER__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__"]}
- `summary`: log evidence; size=517938 bytes; lines=10209; FAIL=2; PASS=10; symbolic=__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__,__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__,__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_GROUP__; tail=_ORDS__:52,50,57,52,57,54,55,50,57,53 __PYTHON_INT_PREFLIGHT_VALUE_4294967295__:4294967295 __PYTHON_INT_PREFLIGHT_VALUE_4294967295_BIT_LENGTH__:32 __PYTHON_INT_PREFLIGHT_OCTET_BYTES_HEX__:a9fe0000 __PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES__:2851995648 __P...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1276
- `line_count`: 21
- `sha256`: e4ab64ed365ba135743e085cdfc4afad279c30f26b17e033a05e8e67b2c62c65
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: log evidence; size=1276 bytes; lines=21; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8895
- `line_count`: 102
- `sha256`: 47cc9318c95b62e3604da1834be9ae669f93fc7db6163a24f7a7b617cb5baf30
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: log evidence; size=8895 bytes; lines=102; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8588
- `line_count`: 95
- `sha256`: 608388743df055a034613079bc3712627ecfd421a8379ea0101892b45dd198fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: log evidence; size=8588 bytes; lines=95; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7735
- `line_count`: 68
- `sha256`: a643557f78f8461b4f9d9005fd3b8b0adc79bc0ebf2a5ca0af31de60f029715b
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: log evidence; size=7735 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 160160
- `line_count`: 2775
- `sha256`: 1a36d0a57f4458f09cad0cae4a333ac40939bc708b6fc74f17c785f7bc9756d0
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"FAIL": 1, "GOOD_TRAP": 9, "PASS": 2241, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__", "__NEMU_CHECK_FULL_ACCOUNT_SU_RC__", "__NEMU_CHECK_FULL_ACCOUNT_USERADD_RC__", "__NEMU_CHECK_FULL_ANACRON_OUTPUT__", "__NEMU_CHECK_FULL_ANACRON_RC__", "__NEMU_CHECK_FULL_ANACRON_TAB__", "__NEMU_CHECK_FULL_ANACRON_TIMEOUT__", "__NEMU_CHECK_FULL_ANACRON_UNITS__", "__NEMU_CHECK_FULL_ANACRON_VERSION__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__"]}
- `summary`: log evidence; size=160160 bytes; lines=2775; FAIL=1; PASS=2241; GOOD_TRAP=9; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__,__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__,__NEMU_CHECK_FULL_ACCOUNT_SU_LOGIN_OK__,__NEMU_CHECK_FULL_ACCOUNT_SU_RC__; tail=/journalctl PASS check-ubuntu-rootfs.sh systemd:/bin/systemd-sysusers PASS check-ubuntu-rootfs.sh systemd:/bin/systemd-tmpfiles PASS check-ubuntu-rootfs.sh systemd:/usr/bin/systemd-run PASS check-ubuntu-rootfs.sh systemd:/usr/bin/systemd-cat PASS check-ubun...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 257085
- `line_count`: 4476
- `sha256`: a9620c23bb3971175b0f3c65d8971fd1b37b4e2e73d48372360973f346f514a7
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 372, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=257085 bytes; lines=4476; PASS=372; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=s=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests=0 tcp_http_apt_deb_requests=0 tcp_http_large_requests=0 tcp_http_segmented_responses=0 tcp_...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 563233
- `line_count`: 11077
- `sha256`: e2cf3475442e48074b7a11b44aa013e5a5495245e4d030910572017dfa2b1b66
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_APT_KEYRING_SHA256__", "__NEMU_CHECK_FULL_APT_KEYRING__", "__NEMU_CHECK_FULL_APT_POLICY_BEGIN__", "__NEMU_CHECK_FULL_APT_POLICY_END__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_APT_VERSION__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_BEGIN__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_LOG_END__", "__NEMU_CHECK_FULL_CNF_UPDATE_DB_RC__", "__NEMU_CHECK_FULL_DATE_UTC__", "__NEMU_CHECK_FULL_DPKG_AUDIT_BEGIN__", "__NEMU_CHECK_FULL_DPKG_AUDIT_END__", "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__", "__NEMU_CHECK_FULL_DPKG_LIST__", "__NEMU_CHECK_FULL_DPKG_QUERY__", "__NEMU_CHECK_FULL_DPKG_SEARCH__", "__NEMU_CHECK_FULL_GPGV_VERSION__", "__NEMU_CHECK_FULL_LOCALE_CHARMAP__"]}
- `summary`: log evidence; size=563233 bytes; lines=11077; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_APT_KEYRING_SHA256__,__NEMU_CHECK_FULL_APT_KEYRING__,__NEMU_CHECK_FULL_APT_POLICY_BEGIN__; tail=_ __PYTHON_INT_PREFLIGHT_TEXT_0_REPR__:'0' __PYTHON_INT_PREFLIGHT_TEXT_0_LEN__:1 __PYTHON_INT_PREFLIGHT_TEXT_0_ORDS__:48 __PYTHON_INT_PREFLIGHT_VALUE_0__:0 __PYTHON_INT_PREFLIGHT_VALUE_0_BIT_LENGTH__:0 __PYTHON_INT_PREFLIGHT_TEXT_2_REPR__:'2' __PYTHON_INT_P...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 33336
- `line_count`: 490
- `sha256`: fb8226f8d9cbef1e2a2f0850880a4f3599145502cf6c492df103789b39af4a3a
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"FAIL": 2, "PASS": 20, "symbolic": ["__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_SYSTEMD_CHECK_DONE__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP__", "__PYTHON_INT_PREFLIGHT_OCTET_BYTES_HEX__", "__PYTHON_INT_PREFLIGHT_OK__", "__PYTHON_INT_PREFLIGHT_TEXT_0_LEN__", "__PYTHON_INT_PREFLIGHT_TEXT_0_ORDS__", "__PYTHON_INT_PREFLIGHT_TEXT_0_REPR__", "__PYTHON_INT_PREFLIGHT_TEXT_169_LEN__", "__PYTHON_INT_PREFLIGHT_TEXT_169_ORDS__"]}
- `summary`: log evidence; size=33336 bytes; lines=490; FAIL=2; PASS=20; symbolic=__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_PASS__,__NEMU_CHECK_SYSTEMD_RELOAD_DBUS_TIMEOUT__,__NEMU_KERNEL_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 527413
- `line_count`: 243
- `sha256`: 8ecde08b839ebb869efb7efde8ad00a4b08e3fd4fd50eb2e5f27114965feabe6
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_APPEND_DONE__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_GUEST_UPLOAD_GROUP__", "__NEMU_GUEST_UPLOAD_MODE__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=527413 bytes; lines=243; symbolic=__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__,__NEMU_GUEST_SCRIPT_SHA256__; tail='QUYKQUFBQU5RQUFBQUFBQUFBQUFBQUFVSTRBQUFBQUFBQUZBQUFBTmdBQUFBQUFBQUFBQUFBQVdJ' 'NEFBQUFBQUFBRkFBQUFOd0FBQUFBQQpBQUFBQUFBQVlJNEFBQUFBQUFBRkFBQUFPQUFBQUFBQUFB' 'QUFBQUFBYUk0QUFBQUFBQUFGQUFBQU9RQUFBQUFBQUFBQUFBQUFjSTRBCkFBQUFBQUFGQUFBQU9n' 'QUFBQUFBQUFBQUFBQUF...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 370912
- `line_count`: 6950
- `sha256`: 9b0bc60979ca74824a925b92772ba64f6c1d6e646e9819fc11701a83d1fb476a
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"ERROR": 5, "PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_CLEANUP_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUPADD_RC__", "__NEMU_CHECK_FULL_ACCOUNT_GROUP__", "__NEMU_CHECK_FULL_ACCOUNT_HOME__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_BEGIN__", "__NEMU_CHECK_FULL_ACCOUNT_LOG_END__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS_RC__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD_STATUS__", "__NEMU_CHECK_FULL_ACCOUNT_PASSWD__"]}
- `summary`: cmd evidence; size=370912 bytes; lines=6950; ERROR=5; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_DEV_DISK_LINK__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF � 0 @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � ( (- (- � � � D D P�td < < < T T Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU >��� ����䊵 �����}� GNU k �| W K D + � = i � � � � p � 8 z " ' P � d snprintf setsockopt puts __stack_chk_fail __pr...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � 4 4 Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU <�2ᑤ��n��6�:U ���| GNU k �| � V Q / " � ~ h 6 � � � = J o " � � c � ` setsockopt puts __stack_chk_fail __printf_ch...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF � � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S � � - - � � 8 8- 8- � � � D D P�td � � � $ $ Q�td R�td - - � � /lib/ld-linux-riscv64-lp64d.so.1 GNU �ږד�� ����D��]�?A� GNU k �| � T 6 " � / f = � � � m F w " ! M � � a � $ setsockopt puts __stack_chk_fail __print...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF � @< @ �� @ 8 @ @ @ @ 0 0 p p p ! ! p 5� S \r \r �z �� �� p � �z �� �� � � � D D P�td �l �l �l � � Q�td R�td �z �� �� h h /lib/ld-linux-riscv64-lp64d.so.1 GNU # �Ʈ /��A�ۭ oﰁ GNU h h k �| 0" � 0 I C S � � # G � � � � u > - � d 5 � v � � " � � S � � � ( p...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF � @ �! @ 8 @ @ @ @ 0 0 p p p ! ! p 5 S | | ( (- (- � � @ @- @- � � � D D P�td ( ( ( $ $ Q�td R�td ( (- (- � � /lib/ld-linux-riscv64-lp64d.so.1 GNU � �mY�Y��F��rq ��5 GNU k �| ` O * � ? 1 � D p y � � 8 a " # � \ ` � setsockopt __stack_chk_fail __printf_c...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 82418
- `sha256`: 134c04c795b106c2a71f2e25475f027414e1c3d7b7a40b286dce7e3be9fce607
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=82418; markers=<none>; tail=

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/nodes.tsv

- `kind`: tsv
- `size_bytes`: 978
- `line_count`: 4
- `sha256`: d224ebf89bc6c6e51682a787464a053cc1dc3ac2b845a7a5e2cbeef26387e52b
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: tsv evidence; size=978 bytes; lines=4; FAIL=2; PASS=8; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/evidence/software-flow-contract.log nemu-ubuntu-static nemu nemu PA...

### .github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/run-manifest.json

- `kind`: json
- `size_bytes`: 4235
- `line_count`: 108
- `sha256`: 5b8015d68c9eb9f99de7683227b0e752954862f3cc52154720b95c7c83e303f3
- `encoding`: utf-8
- `indexed_at`: 2026-06-23T00:49:28+00:00
- `markers`: {"FAIL": 4, "PASS": 10}
- `summary`: json evidence; size=4235 bytes; lines=108; FAIL=4; PASS=10; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-23-2026-06-23-nemu-full-oomd-pressure-full-gate/dispatch-log.md", "evidence_dir": ".gi...
