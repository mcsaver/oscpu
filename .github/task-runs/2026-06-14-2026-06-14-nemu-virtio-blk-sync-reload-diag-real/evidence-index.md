# Evidence Index

## 基本信息

- `task_id`: 2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real
- `task_slug`: 2026-06-14-nemu-virtio-blk-sync-reload-diag-real
- `profile`: nemu-dev-full-gate
- `asset_count`: 18
- `total_size_bytes`: 8590991583

## 证据资产

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-dev-full-focused-gate.log

- `kind`: log
- `size_bytes`: 123072
- `line_count`: 2393
- `sha256`: f1b50b134a19abe50bcbce82a993a72eef1727f68daf3a36c4d9d7abf52c40a0
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"FAIL": 2, "PASS": 8, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__", "__NEMU_CHECK_FULL_SYSTEMCTL_RELOAD_DIAG_STOP__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_SYSTEMD_CHECK_DONE__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP__", "__PYTHON_INT_PREFLIGHT_OCTET_BYTES_HEX__", "__PYTHON_INT_PREFLIGHT_OK__", "__PYTHON_INT_PREFLIGHT_TEXT_0_LEN__"]}
- `summary`: log evidence; size=123072 bytes; lines=2393; FAIL=2; PASS=8; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_BEGIN__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_RC__,__NEMU_CHECK_FULL_SYSTEMCTL_RELOAD_DIAG_STOP__; tail=_PYTHON_INT_PREFLIGHT_TEXT_169_LEN__:3 __PYTHON_INT_PREFLIGHT_TEXT_169_ORDS__:49,54,57 __PYTHON_INT_PREFLIGHT_VALUE_169__:169 __PYTHON_INT_PREFLIGHT_VALUE_169_BIT_LENGTH__:8 __PYTHON_INT_PREFLIGHT_TEXT_254_REPR__:'254' __PYTHON_INT_PREFLIGHT_TEXT_254_LEN__:...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7332
- `line_count`: 93
- `sha256`: 5c00a003e5d26b7871e9a4581528b8ccb422166964738d92430fde571123a67d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: log evidence; size=7332 bytes; lines=93; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7025
- `line_count`: 86
- `sha256`: 26d23d9464a22a0ade66874d08bbdaec5f4fea9ff0f155331c56ebca86616707
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: log evidence; size=7025 bytes; lines=86; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 99135
- `line_count`: 1828
- `sha256`: 2feca1e172da72125831003d7891b8ef391f19c91b9277a1cd0bedc2cd24dbb1
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 7, "GOOD_TRAP": 9, "OOPS": 2, "PANIC": 2, "PASS": 2299, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=99135 bytes; lines=1828; FAIL=7; PASS=2299; GOOD_TRAP=9; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=systemd-guest.sh __NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__ PASS check-nemu-systemd-guest.sh __NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__ PASS check-nemu-systemd-guest.sh __NEMU_...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 196601
- `line_count`: 3176
- `sha256`: 5b9a09382577731e896ff7bcadeb0e8ea34ec5bbbb4f25cde42d14213a4dada3
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"FAIL": 2, "GOOD_TRAP": 27, "PASS": 365, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=196601 bytes; lines=3176; FAIL=2; PASS=365; GOOD_TRAP=27; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=_mmio_map] Add mmio map 'syscon-reset' at [0x00100000, 0x00100fff][0m [1;34m[src/monitor/monitor.c:147 load_img] No image is given. Use the default build-in image.[0m [1;34m[src/monitor/gdbstub.c:929 gdbstub_wait_for_client_if_enabled] GDB stub listenin...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 148088
- `line_count`: 2879
- `sha256`: 5cc11a0cba86f8ac5ddc7bd294eab7f011287c0c3b27dc689b367c27f8b6f875
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_APT_KEYRING_SHA256__", "__NEMU_CHECK_FULL_APT_KEYRING__", "__NEMU_CHECK_FULL_APT_POLICY_BEGIN__", "__NEMU_CHECK_FULL_APT_POLICY_END__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_APT_VERSION__", "__NEMU_CHECK_FULL_CRON_EXEC_FILE__", "__NEMU_CHECK_FULL_DATE_UTC__", "__NEMU_CHECK_FULL_DPKG_AUDIT_BEGIN__", "__NEMU_CHECK_FULL_DPKG_AUDIT_END__", "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__", "__NEMU_CHECK_FULL_DPKG_LIST__", "__NEMU_CHECK_FULL_DPKG_QUERY__", "__NEMU_CHECK_FULL_DPKG_SEARCH__", "__NEMU_CHECK_FULL_GPGV_VERSION__", "__NEMU_CHECK_FULL_HOSTNAMECTL_ERROR_BEGIN__", "__NEMU_CHECK_FULL_HOSTNAMECTL_ERROR_END__", "__NEMU_CHECK_FULL_HOSTNAMECTL_HOSTNAME__"]}
- `summary`: log evidence; size=148088 bytes; lines=2879; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_APT_KEYRING_SHA256__,__NEMU_CHECK_FULL_APT_KEYRING__,__NEMU_CHECK_FULL_APT_POLICY_BEGIN__; tail=bkeyauthentication yes kerberosauthentication no kerberosorlocalpasswd yes kerberosticketcleanup yes gssapiauthentication no gssapicleanupcredentials yes gssapikeyexchange no gssapistrictacceptorcheck yes __NEMU_CHECK_FULL_SSHD_CONFIG_END__ __NEMU_CHECK_PAS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 23219
- `line_count`: 358
- `sha256`: 8b675dc339f2cc2c792cff19b0a519b6c0457d8f35ac99ca0ec1a0e5307fd0b9
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__", "__NEMU_CHECK_FULL_SYSTEMCTL_RELOAD_DIAG_STOP__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__", "__NEMU_SYSTEMD_CHECK_DONE__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_BYTES__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_LIST__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP_BIT_LENGTH__", "__PYTHON_INT_PREFLIGHT_INT_FROM_BYTES_MAP__", "__PYTHON_INT_PREFLIGHT_OCTET_BYTES_HEX__", "__PYTHON_INT_PREFLIGHT_OK__", "__PYTHON_INT_PREFLIGHT_TEXT_0_LEN__", "__PYTHON_INT_PREFLIGHT_TEXT_0_ORDS__", "__PYTHON_INT_PREFLIGHT_TEXT_0_REPR__", "__PYTHON_INT_PREFLIGHT_TEXT_169_LEN__", "__PYTHON_INT_PREFLIGHT_TEXT_169_ORDS__", "__PYTHON_INT_PREFLIGHT_TEXT_169_REPR__"]}
- `summary`: log evidence; size=23219 bytes; lines=358; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FAIL__,__NEMU_CHECK_FULL_PYTHON_INT_PREFLIGHT_LOG_END__,__NEMU_CHECK_FULL_SYSTEMCTL_RELOAD_DIAG_STOP__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 257223
- `line_count`: 132
- `sha256`: 5e87b084fd04962e9e2608e5befa69807cb5a0220fb47745f9de06aada9461c9
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_APPEND_DONE__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_GUEST_UPLOAD_GROUP__", "__NEMU_GUEST_UPLOAD_MODE__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=257223 bytes; lines=132; symbolic=__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__,__NEMU_GUEST_SCRIPT_SHA256__; tail=X05FTVVfQ0hFQ0tfSE9TVE5BTUVDVExfVkVSU0lP' 'Tl9fOiRob3N0bmFtZWN0bF92ZXJzaW9uIgogIGVjaG8gIiRob3N0bmFtZWN0bF92ZXJzaW9uIiB8' 'IGdyZXAgLUVxICdec3lzdGVtZCBbMC05XSsnICYmCiAgICBwYXNzIGNvbW1vbi1ob3N0bmFtZWN0' 'bC12ZXJzaW9uIHx8IGZhaWwgY29tbW9uLWhvc3RuYW1lY3RsLXZlcnNp...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 180402
- `line_count`: 3992
- `sha256`: e40a8449968e5b79876924ae1132b947d2a3319ad9dfbd51645f008d0e12ec22
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_LOG_END__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__"]}
- `summary`: cmd evidence; size=180402 bytes; lines=3992; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_COMMON_COMMANDS__; tail=U_CHECK_FULL_WGET_HTTP_CODE__:$wget_rc:$wget_code" if [ "$wget_code" = "204" ]; then pass full-userland-wget-http else echo "__NEMU_CHECK_FULL_WGET_LOG_BEGIN__" sed -n '1,120p' "$wget_log" 2>/dev/null || true echo "__NEMU_CHECK_FULL_WGET_LOG_END__" fail ful...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 52667
- `sha256`: bb9a626d21fc3b8444f0f078538abc66fce32e3155f8f138a26be44196992092
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=52667; markers=<none>; tail=                                                                                                                                                                                                                                                                 ...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/nodes.tsv

- `kind`: tsv
- `size_bytes`: 959
- `line_count`: 4
- `sha256`: 98e018bf199b32c8139b9e903d501cc2fee1209f0f9b7295f75164f35f3c85ea
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: tsv evidence; size=959 bytes; lines=4; FAIL=4; PASS=4; tail=software-flow-contract software-flow software-flow PASS software-flow agent + profile + memory 软件开发全流程 agent 合约入口存在 .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/evidence/software-flow-contract.log nemu-ubuntu-static nemu nem...

### .github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/run-manifest.json

- `kind`: json
- `size_bytes`: 4228
- `line_count`: 106
- `sha256`: 53b41acadebe00330eb597556d8fda82dae5715a28cd378eadddd00d604ad836
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T15:28:57+00:00
- `markers`: {"FAIL": 6, "PASS": 6}
- `summary`: json evidence; size=4228 bytes; lines=106; FAIL=6; PASS=6; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-14-2026-06-14-nemu-virtio-blk-sync-reload-diag-real/dispatch-log.md", "evidence_di...
