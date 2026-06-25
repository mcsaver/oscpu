# Evidence Index

## 基本信息

- `task_id`: 2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b
- `task_slug`: 2026-06-22-nemu-decode-cache-int-fast-profile-on-5b
- `profile`: 5B full-rootfs performance profile，`profile-command.txt` 记录 `runtime.decode_cache_int_fast=1`。
- `asset_count`: 17
- `total_size_bytes`: 8590537330

## 证据资产

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/console.log

- `kind`: log
- `size_bytes`: 46849
- `line_count`: 584
- `sha256`: b7e65a041aba0792b16bbba997a0bb181754c6b6f2b478424f0172cb48f181f5
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=46849 bytes; lines=584; symbolic=_____; tail=OpenSBI v1.8 ____ _____ ____ _____ / __ \ / ____| _ \_ _| | | | |_ __ ___ _ __ | (___ | |_) || | | | | | '_ \ / _ \ '_ \ \___ \| _ < | | | |__| | |_) | __/ | | |____) | |_) || |_ \____/| .__/ \___|_| |_|_____/|____/_____| | | |_| Platform Name : YSYX NPC RV...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/host-profiler.txt

- `kind`: txt
- `size_bytes`: 1163
- `line_count`: 32
- `sha256`: 2fb4e18b032de83b9beb3364c0288f1f4b4655a5ae91f3df99abd308f23e912f
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"WARN": 2}
- `summary`: txt evidence; size=1163 bytes; lines=32; WARN=2; tail=perf.record.requested=0 perf.record.freq=99 perf.source=system perf.path=/usr/bin/perf perf.status=unavailable WARNING: perf not found for kernel 6.6.87.2-microsoft You may need to install the following packages for this specific kernel: linux-tools-6.6.87....

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/perf-smoke.out

- `kind`: out
- `size_bytes`: 243
- `line_count`: 11
- `sha256`: 28cb0490a3cd7aa5e6ecdd90541cabe258a2355ec38389da777fef75b7ae46e7
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: out evidence; size=243 bytes; lines=11; markers=<none>; tail=Performance counter stats for 'true': 0.39 msec task-clock:u # 0.218 CPUs utilized 0.001775595 seconds time elapsed 0.001014000 seconds user 0.000000000 seconds sys

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/profile-command.txt

- `kind`: txt
- `size_bytes`: 670
- `line_count`: 26
- `sha256`: f0ef7810e29fe1b21cb18e54b93cbbc545923f2ace6f0bba80701b2c5811d1c4
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: txt evidence; size=670 bytes; lines=26; markers=<none>; tail=repo_root=/home/lyg/PA/ysyx-workbench rootfs_flavor=full rootfs_image=/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4 max_cycles=5000000000 progress=50000000 tb_max_inst=256 opcode_mix=0 stop_detail=0 de...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/profile-run.log

- `kind`: log
- `size_bytes`: 61061
- `line_count`: 757
- `sha256`: 908508713290fa1daa08083f9b18981aeeaafbfa942f4cadfaac6e889b9c9905
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=61061 bytes; lines=757; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/profile-summary.txt

- `kind`: txt
- `size_bytes`: 12706
- `line_count`: 334
- `sha256`: a02051c5fec5bcae50ebc267b10811da170af29444306c7d0b37e58c2d56dbf7
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: txt evidence; size=12706 bytes; lines=334; markers=<none>; tail=# NEMU Ubuntu Profile Summary profile.available=1 profile.clint.host_time_reads=9871995 profile.cpu.basic_block_avg_inst_x100=22374 profile.cpu.basic_block_inst=5000000000 profile.cpu.basic_blocks=22346424 profile.cpu.csr.sstatus.write.changed=0 profile.cpu...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-profile/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 6900
- `sha256`: bef086c3bbe61d98e6859a5257bd4fdd468bc8a044db453ed0323a3e4a5b823a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=6900; markers=<none>; tail=

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 1090
- `line_count`: 17
- `sha256`: 4d01ea2f11d2f1bf4b6d67538818c3629e68480a1a4802a73cf6e4bd2f89c702
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: log evidence; size=1090 bytes; lines=17; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysy...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8580
- `line_count`: 99
- `sha256`: 8b97095b96bbd4bb00c11703c3150891927279b99d20ec5bd3018cac0d7d6d22
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: log evidence; size=8580 bytes; lines=99; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 8273
- `line_count`: 92
- `sha256`: ed2106e77f209dc68de808e3f668b2dae9abd87471dfbe71b9d983cace12d890
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: log evidence; size=8273 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/platforms/nemu/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4'...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 7541
- `line_count`: 68
- `sha256`: 196279a5291224b3582e92e5b621a39890334d471031a39b825fa4a17853446e
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {}
- `summary`: log evidence; size=7541 bytes; lines=68; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-ubuntu-profile.log

- `kind`: log
- `size_bytes`: 61432
- `line_count`: 760
- `sha256`: 093d0c015157a5b8d0fbd4c88af7a73a08e4577200cbf79bae9238007583c731
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"PASS": 2, "symbolic": ["_____"]}
- `summary`: log evidence; size=61432 bytes; lines=760; PASS=2; symbolic=_____; tail=[nemu-ubuntu] heavy performance profile gate make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 134203
- `line_count`: 2383
- `sha256`: 91c95b0612a16da9afad24244c555e9f095224407eb364ef7c018125b685fc8f
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"BAD_TRAP": 1, "FAIL": 4, "GOOD_TRAP": 9, "OOPS": 1, "PANIC": 1, "PASS": 2317, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_LIST_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_OWNERSHIP_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_HELLO_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_SEARCH_META_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_DPKG_STATUS_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_PURGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_MESSAGE_AFTER_REMOVE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_HELLO_SEARCH_AFTER_PURGE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_APT_STATE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__"]}
- `summary`: log evidence; size=134203 bytes; lines=2383; FAIL=4; PASS=2317; GOOD_TRAP=9; BAD_TRAP=1; PANIC=1; OOPS=1; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_TARGETS__; tail=otfs-flavors.sh /bin/journalctl PASS ubuntu-rootfs-flavors.sh /bin/systemd-sysusers PASS ubuntu-rootfs-flavors.sh /bin/systemd-tmpfiles PASS ubuntu-rootfs-flavors.sh /usr/bin/systemd-cat PASS ubuntu-rootfs-flavors.sh /usr/bin/logger PASS ubuntu-rootfs-flavo...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 255880
- `line_count`: 4459
- `sha256`: 3e9feb6a3dacff1095a9161a3947af5ad85be8396b2db955ebcd24b5495dc3c7
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"GOOD_TRAP": 26, "PASS": 370, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=255880 bytes; lines=4459; PASS=370; GOOD_TRAP=26; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=o_net_statistic] virtio-net runtime tx_packets=0 tx_bytes=0 rx_packets=0 rx_bytes=0 tx_errors=0 rx_drops=0 arp=0/0 icmp=0/0 dhcp=0/0 dns=0/0 tcp_segments=0 tcp_replies=0 tcp_http_requests=0 tcp_http_head_requests=0 tcp_http_not_found=0 tcp_http_apt_requests...

### .github/task-runs/2026-06-22-2026-06-22-nemu-decode-cache-int-fast-profile-on-5b/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-22T00:20:07+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...
