# Evidence Index

## 基本信息

- `task_id`: 2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run
- `task_slug`: nemu-full-hostless-apt-download-dpkg-real-run
- `profile`: nemu-ubuntu-full-gate
- `asset_count`: 50
- `total_size_bytes`: 8591244564

## 证据资产

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7163
- `line_count`: 89
- `sha256`: 1e0970270f7282bdca7a5d945e5a2c5c6e800d8e2b5b3270a2914b5f2aac429c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=7163 bytes; lines=89; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6856
- `line_count`: 82
- `sha256`: 644bf425027559008b991063da35adafec6641b4770c15eb235284f3fdba728f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=6856 bytes; lines=82; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-ubuntu-full-focused-gate.log

- `kind`: log
- `size_bytes`: 24453
- `line_count`: 365
- `sha256`: 6d93f964a3e30b86bae4b2ae75f998031f0c671639f599ab8a6f6a4b712cde23
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"GOOD_TRAP": 2, "PANIC": 2, "PASS": 108, "symbolic": ["__NEMU_CHECK_HWRNG_CURRENT__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_RTC0_HWCLOCK__", "__NEMU_CHECK_RTC0_NAME__", "__NEMU_CHECK_VDA_CACHE_TYPE__", "__NEMU_CHECK_VDA_DISCARD_MAX__", "__NEMU_CHECK_VDA_WRITE_ZEROES_MAX__", "__NEMU_CHECK_VIRTIO_NET_ARP__", "__NEMU_CHECK_VIRTIO_NET_DRIVER__", "__NEMU_CHECK_VIRTIO_NET_DUPLEX__", "__NEMU_CHECK_VIRTIO_NET_FEATURES__", "__NEMU_CHECK_VIRTIO_NET_IFACE__", "__NEMU_CHECK_VIRTIO_NET_IPV4__", "__NEMU_CHECK_VIRTIO_NET_MAC__", "__NEMU_CHECK_VIRTIO_NET_MODALIAS__", "__NEMU_CHECK_VIRTIO_NET_MTU__", "__NEMU_CHECK_VIRTIO_NET_NEIGH__"]}
- `summary`: log evidence; size=24453 bytes; lines=365; PASS=108; GOOD_TRAP=2; PANIC=2; symbolic=__NEMU_CHECK_HWRNG_CURRENT__,__NEMU_CHECK_INFO__,__NEMU_CHECK_MEMTOTAL_KB__,__NEMU_CHECK_MIN_MEMTOTAL_KB__,__NEMU_CHECK_PASS__; tail=[nemu-ubuntu] focused gate target: check-nemu-systemd-guest-full [nemu-ubuntu] focused gate log dir: .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused make: Entering directory '/home/lyg/PA/ysyx-workbench/Li...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 62920
- `line_count`: 1321
- `sha256`: 8983e68aadecd7652a7e2a41bdad55992b3ca78ed5d89bb4f7b44ccb121efc0d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 8, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2626, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__", "__NEMU_CHECK_FULL_DPKG_LIST__", "__NEMU_CHECK_FULL_DPKG_QUERY__", "__NEMU_CHECK_FULL_DPKG_SEARCH__", "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__", "__NEMU_CHECK_FULL_SSH_CLIENT__", "__NEMU_CHECK_FULL_SSH_DEBUGD_LOG_BEGIN__", "__NEMU_CHECK_FULL_SSH_DEBUG_CLIENT_BEGIN__"]}
- `summary`: log evidence; size=62920 bytes; lines=1321; FAIL=8; PASS=2626; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__,__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__; tail=[nemu-ubuntu] slice contract guard PASS nemu/src/device/rng.c PASS nemu/src/device/net.c PASS nemu/src/device/goldfish_rtc.c PASS Linux/tools/nemu-systemd-icmp-probe.c PASS Linux/tools/nemu-systemd-dhcp-probe.c PASS Linux/tools/nemu-systemd-dns-probe.c PASS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 187530
- `line_count`: 3108
- `sha256`: 6c6d8ef565b1901374e11d5d90ac3f4256741313f7929bfaed58f3b5ac976f7f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 450, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=187530 bytes; lines=3108; PASS=450; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=9 ( s3) = 0x0000000000000000 x20 ( s4) = 0x0000000000000000 x21 ( s5) = 0x0000000000000000 x22 ( s6) = 0x0000000000000000 x23 ( s7) = 0x0000000000000000 x24 ( s8) = 0x0000000000000000 x25 ( s9) = 0x0000000000000000 x26 ( s10) = 0x0000000000000000 x27 ( s11)...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28282
- `line_count`: 337
- `sha256`: fe870bfc3042441e1d733eeaf888da078609842fdf00ad0ff97ff992f61ec99c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28282 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35312
- `line_count`: 324
- `sha256`: 51632b41e0ca22b86f4ec3e36d9ae9fb399275de22dce4229d9e1d569dec0814
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35312 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 32970
- `line_count`: 299
- `sha256`: 1af4ce26778e53032592b8b0fc4ebcf1bcde44d4ea3d8d3aaceb9d19adcc337e
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32970 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32358
- `line_count`: 290
- `sha256`: 171019c17bf57b7f6d7f71c3b4937baa40ccfb30649fb7c7a34a4f8522257a54
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32358 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34794
- `line_count`: 320
- `sha256`: 93d225b8566be67549f4837df13d7b484d3da51b0e613ef584ed4b1b56e2e653
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34794 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 4
- `sha256`: e0927aa39bcb29f4661fa5f81a746ce534a21e0f9640a7b6c2bb5557f2df3cab
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=362 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-12-ne...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1542
- `line_count`: 29
- `sha256`: 2d5dd878efa8d86a170599d112b2ae4801addfa28c941eb1cca0d8b70ca2cb35
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1542 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1094
- `line_count`: 20
- `sha256`: ae01833cee2527ef39cda651dd87587683bb24096dd0a76abc7f5c738cceaea4
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=1094 bytes; lines=20; markers=<none>; tail=95:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 96:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 97:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 98:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 99:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 100:NPC_S...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30162
- `line_count`: 259
- `sha256`: 3f62db4f6a2ba11fdedac846a87079c6d29702fd67d6e1ff8a36b858f0e93a53
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30162 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-n...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 13
- `sha256`: 3f4f9c39ed64c5d8386044b559e4a038a6ce1088049aa925669af3aa5e02125e
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-sm...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 332
- `line_count`: 11
- `sha256`: 528f3deab478de60433ec29d1f13d1eb3432e95d796574296e458a52e4b8946f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=332 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PAS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 29033
- `line_count`: 241
- `sha256`: 4e024a5684de0c575bd8db0a755db4ba23d8eca32df727a98096f8710b9812d8
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=29033 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27220
- `line_count`: 220
- `sha256`: dda3e91e96bf7c81babdafc62c86359774a59f86176e2fdbe51205eaa9af77a1
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27220 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory are...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25899
- `line_count`: 213
- `sha256`: 1facb414f04803723cfdfe3b1825685ffff9b76b8e2365f2a6e755af15d9db85
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25899 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 64335
- `line_count`: 1179
- `sha256`: ac55be2b8372513b4d240432cb6d6a76b64c250c2a152430b7059fcac69e7f8a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"GOOD_TRAP": 2, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_BEGIN__", "__NEMU_CHECK_FULL_APT_POLICY_END__"]}
- `summary`: log evidence; size=64335 bytes; lines=1179; GOOD_TRAP=2; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_DEV_DISK_LINK__; tail=OpenSBI v1.8 ____ _____ ____ _____ / __ \ / ____| _ \_ _| | | | |_ __ ___ _ __ | (___ | |_) || | | | | | '_ \ / _ \ '_ \ \___ \| _ < | | | |__| | |_) | __/ | | |____) | |_) || |_ \____/| .__/ \___|_| |_|_____/|____/_____| | | |_| Platform Name : YSYX NPC RV...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 14634
- `line_count`: 212
- `sha256`: eb4168eb717d25e568700a096d180cb7b4a85799f2d73f6e24672c56262c8faa
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PANIC": 2, "PASS": 48, "symbolic": ["__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=14634 bytes; lines=212; PASS=48; PANIC=2; symbolic=__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 258013
- `line_count`: 3359
- `sha256`: 0b35458fa878525729ab1963731546cfdd0dbf4dd6012527a5607430029ad067
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_CHECK_B64__", "__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=258013 bytes; lines=3359; symbolic=__NEMU_GUEST_CHECK_B64__,__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__; tail=iMjVsVkdGaWJHVUFBQUFBQUFJQUF3QUNBQUlBQWdBQ0FB SUFBd0FDQUFFQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQQpBZ0FDQUFJQUFnQUNBQU1BQWdBQ0FB SUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQUFnQUNBQUlBQkFBREFBSUFBZ0FDCkFB SUFBZ0FDQUFJQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQUFnQUNBQUlBQ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 190036
- `line_count`: 3459
- `sha256`: da9c0eb2330474d338dcef31fc37c65103380f6a9631f771fa50b786018b52fd
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__"]}
- `summary`: cmd evidence; size=190036 bytes; lines=3459; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_COMMON_COMMANDS__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF          �    0      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF          �    �      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF          �    @<      @       ��         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5�                      S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                              ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/perf.tsv

- `kind`: tsv
- `size_bytes`: 452
- `line_count`: 2
- `sha256`: 125da1d41d6860c75c2d199e9f271c4b7ae4f6e115ee18b1172c7b5b279db5b2
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: tsv evidence; size=452 bytes; lines=2; markers=<none>; tail=boot_seconds guest_check_seconds poweroff_seconds total_seconds soak_seconds fs_stress_mib fs_tree_files process_loops uart_rx_stress_lines block_parallel_jobs block_job_mib net_tcp_burst_loops input_chunk_bytes input_chunk_delay max_cycles rootfs_overlay 1...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 75095
- `sha256`: c8eac63ba12488791f1e3f75c25107457e7364091e29bdf40c818ec29572bdbe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=75095; markers=<none>; tail=                                                                                                                                                                                                                                                                 ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3879
- `line_count`: 14
- `sha256`: 59c63057398b914e1a2462e0c5661e293aa0a69f2c1f9c547ea135defd55092a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T16:31:38+00:00
- `markers`: {"PASS": 32, "SKIP": 2}
- `summary`: tsv evidence; size=3879 bytes; lines=14; SKIP=2; PASS=32; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-12-nemu-full-hostless-apt-download-dpkg-real-run/evidence/recall-discovery.log tool-env-check agent-system toolchain...
