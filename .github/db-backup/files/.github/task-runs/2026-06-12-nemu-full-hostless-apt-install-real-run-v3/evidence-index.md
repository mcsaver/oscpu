# Evidence Index

## 基本信息

- `task_id`: 2026-06-12-nemu-full-hostless-apt-install-real-run-v3
- `task_slug`: nemu-full-hostless-apt-install-real-run-v3
- `profile`: nemu-ubuntu-full-gate
- `asset_count`: 49
- `total_size_bytes`: 8591221368

## 证据资产

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7163
- `line_count`: 89
- `sha256`: 1e0970270f7282bdca7a5d945e5a2c5c6e800d8e2b5b3270a2914b5f2aac429c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=7163 bytes; lines=89; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6856
- `line_count`: 82
- `sha256`: 644bf425027559008b991063da35adafec6641b4770c15eb235284f3fdba728f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=6856 bytes; lines=82; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-ubuntu-full-focused-gate.log

- `kind`: log
- `size_bytes`: 22767
- `line_count`: 412
- `sha256`: 18bd543cec2016833a893b1630f729864835aea03e29c120730a777907b87407
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"FAIL": 4, "PASS": 16, "symbolic": ["__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__", "__NEMU_CHECK_FULL_RESOLV_CONF_END__", "__NEMU_CHECK_FULL_WGET_HTTP_CODE__", "__NEMU_CHECK_HWRNG_CURRENT__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_MEMTOTAL_KB__", "__NEMU_CHECK_MIN_MEMTOTAL_KB__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_RTC0_HWCLOCK__", "__NEMU_CHECK_RTC0_NAME__", "__NEMU_CHECK_RTC0_TIME__", "__NEMU_CHECK_VIRTIO_NET_CARRIER_AFTER_UP__", "__NEMU_CHECK_VIRTIO_NET_CARRIER__", "__NEMU_CHECK_VIRTIO_NET_DRIVER__"]}
- `summary`: log evidence; size=22767 bytes; lines=412; FAIL=4; PASS=16; symbolic=__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__,__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__,__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__; tail=[nemu-ubuntu] focused gate target: check-nemu-systemd-guest-full [nemu-ubuntu] focused gate log dir: .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 62489
- `line_count`: 1315
- `sha256`: 7368bf4ff89963da8181b53ae9d0dd884b8402369db66a0cce205bc9e6aea43f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 8, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2614, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__", "__NEMU_CHECK_FULL_DPKG_LIST__", "__NEMU_CHECK_FULL_DPKG_QUERY__", "__NEMU_CHECK_FULL_DPKG_SEARCH__", "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__", "__NEMU_CHECK_FULL_SSH_CLIENT__", "__NEMU_CHECK_FULL_SSH_DEBUGD_LOG_BEGIN__", "__NEMU_CHECK_FULL_SSH_DEBUG_CLIENT_BEGIN__", "__NEMU_CHECK_FULL_SSH_DEBUG_LOGIN_RC__", "__NEMU_CHECK_FULL_SSH_DEBUG_READY__", "__NEMU_CHECK_FULL_SSH_DROPBEAR_LOG_BEGIN__", "__NEMU_CHECK_FULL_SSH_DROPBEAR_READY__"]}
- `summary`: log evidence; size=62489 bytes; lines=1315; FAIL=8; PASS=2614; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__,__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__,__NEMU_CHECK_FULL_APT_POLICY_RC__; tail=[nemu-ubuntu] slice contract guard PASS nemu/src/device/rng.c PASS nemu/src/device/net.c PASS nemu/src/device/goldfish_rtc.c PASS Linux/tools/nemu-systemd-icmp-probe.c PASS Linux/tools/nemu-systemd-dhcp-probe.c PASS Linux/tools/nemu-systemd-dns-probe.c PASS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 187445
- `line_count`: 3107
- `sha256`: 3df6950efa73fef367242dd3cc65db19cac5b1c886f0a553ad3d07ba5c302fd7
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 450, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=187445 bytes; lines=3107; PASS=450; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=9 ( s3) = 0x0000000000000000 x20 ( s4) = 0x0000000000000000 x21 ( s5) = 0x0000000000000000 x22 ( s6) = 0x0000000000000000 x23 ( s7) = 0x0000000000000000 x24 ( s8) = 0x0000000000000000 x25 ( s9) = 0x0000000000000000 x26 ( s10) = 0x0000000000000000 x27 ( s11)...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28279
- `line_count`: 337
- `sha256`: 75127a2ab8f63b838ea00c65551d5c1d1eff9c839e64a18a85af5a2e5f153f08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28279 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35344
- `line_count`: 324
- `sha256`: 9e4202b99ed7a8f4569743e1c181cf3bda64ad08ca11e29b84fa7a8a8cad218c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35344 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 33020
- `line_count`: 299
- `sha256`: 13c92ac9f91797940986f647012c09837d442c1c2421505a8a580bf0c37ee397
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=33020 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory are...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32408
- `line_count`: 290
- `sha256`: b9b1a17dc74145f873357fe4b88440c45ab4b4358c00bff568a4650a0497d06d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32408 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34835
- `line_count`: 320
- `sha256`: 36324100aa2309f8a0d7b65a3302c29df17da540be0197ca4d9d3e28da5ae2e0
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34835 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 359
- `line_count`: 4
- `sha256`: 3800c94951148363b54b487cf93d3f53907e065b174a3fe65c60875417511d37
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=359 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-12-ne...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1539
- `line_count`: 29
- `sha256`: 6efac58edeff27385c1cd69bce0184e5ac4fd6f042df6137b6392d20b703734a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1539 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1094
- `line_count`: 20
- `sha256`: ae01833cee2527ef39cda651dd87587683bb24096dd0a76abc7f5c738cceaea4
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=1094 bytes; lines=20; markers=<none>; tail=95:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 96:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 97:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 98:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 99:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 100:NPC_S...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30135
- `line_count`: 259
- `sha256`: e55646625d458b4174c03caefc5cb253735072ed979f21b1a0d868bba1ccee4b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30135 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-n...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 13
- `sha256`: 196464eb4ed58b9fffac7d6499cd4dc4e58153b657fe9c534cd87d678f149407
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 329
- `line_count`: 11
- `sha256`: 191469d0a6a90eed2cc07679d056227e16b75b4832b1c860e43dab8734449b0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=329 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS t...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 29021
- `line_count`: 241
- `sha256`: 4f5e518c3cdd66f4cd18c526d0f0b4ee4c511b0a027712d7426f69e7cbf6870b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=29021 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27217
- `line_count`: 220
- `sha256`: d7ea7655f2c572e4db93244415dcfe395d463a6e8976c9a5c5a184cee8289ba3
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27217 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25896
- `line_count`: 213
- `sha256`: a6cd48904c23220b9f3a6fc37e8fa75e29163876c45041935e871b7208e67354
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25896 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/console.log

- `kind`: log
- `size_bytes`: 45008
- `line_count`: 856
- `sha256`: ad41c2895eb92cdebf344aab4ce8aeafa0eee2478e080e3f91bd3337cd2d2bfe
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_BEGIN__", "__NEMU_CHECK_FULL_APT_POLICY_END__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_APT_VERSION__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_DATE_UTC__", "__NEMU_CHECK_FULL_DPKG_AUDIT_BEGIN__", "__NEMU_CHECK_FULL_DPKG_AUDIT_END__", "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__", "__NEMU_CHECK_FULL_DPKG_LIST__", "__NEMU_CHECK_FULL_DPKG_QUERY__", "__NEMU_CHECK_FULL_DPKG_SEARCH__", "__NEMU_CHECK_FULL_LOCALE_CHARMAP__"]}
- `summary`: log evidence; size=45008 bytes; lines=856; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_CONSOLE_WRITE__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__; tail=OpenSBI v1.8 ____ _____ ____ _____ / __ \ / ____| _ \_ _| | | | |_ __ ___ _ __ | (___ | |_) || | | | | | '_ \ / _ \ '_ \ \___ \| _ < | | | |__| | |_) | __/ | | |____) | |_) || |_ \____/| .__/ \___|_| |_|_____/|____/_____| | | |_| Platform Name : YSYX NPC RV...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/focused-make.log

- `kind`: log
- `size_bytes`: 18025
- `line_count`: 307
- `sha256`: b5554f118a9033ff6e3112322b330cb365a0339910d509a725d9041783e886ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"FAIL": 2, "PASS": 16, "symbolic": ["__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__", "__NEMU_CHECK_FULL_RESOLV_CONF_END__", "__NEMU_CHECK_FULL_WGET_HTTP_CODE__", "__NEMU_CHECK_INFO__", "__NEMU_CHECK_PASS__", "__NEMU_CHECK_RTC0_HWCLOCK__", "__NEMU_CHECK_RTC0_TIME__", "__NEMU_CHECK_VIRTIO_NET_CARRIER_AFTER_UP__", "__NEMU_CHECK_VIRTIO_NET_CARRIER__", "__NEMU_CHECK_VIRTIO_NET_DRIVER__", "__NEMU_CHECK_VIRTIO_NET_DUPLEX__", "__NEMU_CHECK_VIRTIO_NET_FEATURES__", "__NEMU_CHECK_VIRTIO_NET_IFACE__", "__NEMU_CHECK_VIRTIO_NET_IPV4__"]}
- `summary`: log evidence; size=18025 bytes; lines=307; FAIL=2; PASS=16; symbolic=__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__,__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__,__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/guest-check-upload.cmd

- `kind`: cmd
- `size_bytes`: 255371
- `line_count`: 3325
- `sha256`: 2916de278e35d2d07da727d2615925d89a30c5d52ecdc2637800d56500078ef6
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_GUEST_CHECK_B64__", "__NEMU_GUEST_SCRIPT_BYTES__", "__NEMU_GUEST_SCRIPT_DECODE_FAIL__", "__NEMU_GUEST_SCRIPT_READY__", "__NEMU_GUEST_SCRIPT_SHA256_FAIL__", "__NEMU_GUEST_SCRIPT_SHA256__", "__NEMU_GUEST_SCRIPT_TOOL_MISSING__", "__NEMU_GUEST_UPLOAD_BEGIN__", "__NEMU_SYSTEMD_CHECK_DONE__"]}
- `summary`: cmd evidence; size=255371 bytes; lines=3325; symbolic=__NEMU_GUEST_CHECK_B64__,__NEMU_GUEST_SCRIPT_BYTES__,__NEMU_GUEST_SCRIPT_DECODE_FAIL__,__NEMU_GUEST_SCRIPT_READY__,__NEMU_GUEST_SCRIPT_SHA256_FAIL__; tail=zYjI1bFZHRmliR1VBQUFBQUFBSUFBd0FDQUFJQUFnQUNBQUlBQXdBQ0FBRUFBZ0FDQUFJ QUFnQUNBQUlBQWdBQ0FBSUEKQWdBQ0FBSUFBZ0FDQUFNQUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJ QUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQUJBQURBQUlBQWdBQwpBQUlBQWdBQ0FBSUFBZ0FDQUFJ QUFnQUNBQUlBQWdBQ0FBSUFBZ0FDQUFJQ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/guest-check.cmd

- `kind`: cmd
- `size_bytes`: 188081
- `line_count`: 3424
- `sha256`: 52d34ea043c13ac7680c61e79109b4fd5e6df0a9a1ccd64fb2f37a0b8a222568
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"PANIC": 1, "symbolic": ["__NEMU_CHECK_BLOCK_PARALLEL_BYTES__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__", "__NEMU_CHECK_BLOCK_PARALLEL_JOB__", "__NEMU_CHECK_BLOCK_PARALLEL_SKIP__", "__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_CONSOLE_WRITE__", "__NEMU_CHECK_DEV_DISK_LINK__", "__NEMU_CHECK_FAIL__", "__NEMU_CHECK_FS_STRESS_BYTES__", "__NEMU_CHECK_FS_TREE_FILES__", "__NEMU_CHECK_FS_TREE_SKIP__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_BEGIN__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_LOG_END__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_BEGIN__", "__NEMU_CHECK_FULL_APT_POLICY_END__"]}
- `summary`: cmd evidence; size=188081 bytes; lines=3424; PANIC=1; symbolic=__NEMU_CHECK_BLOCK_PARALLEL_BYTES__,__NEMU_CHECK_BLOCK_PARALLEL_JOB_FAIL__,__NEMU_CHECK_BLOCK_PARALLEL_JOB__,__NEMU_CHECK_BLOCK_PARALLEL_SKIP__,__NEMU_CHECK_COMMON_COMMANDS__; tail=rue)" = "write through" ]; then pass vda-cache-type-write-through else fail vda-cache-type-write-through fi if printf 'write back\n' > "$vda_cache_type_path" 2>/dev/null && [ "$(cat "$vda_cache_type_path" 2>/dev/null || true)" = "write back" ]; then pass vd...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 1cb1afb19aade899909c6504769d15e353e04004513af9f793c2d07bb2f7b8de
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAMA8AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-dhcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 35
- `sha256`: d6b10d8d8de7e488ee256534e3af63a3512fafddb58f2cb8231b1e7a95a7b4b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_DHCP_PROBE_ACK__", "__NEMU_DHCP_PROBE_FAIL__", "__NEMU_DHCP_PROBE_OFFER__", "__NEMU_DHCP_PROBE_PASS__", "__NEMU_DHCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=35; symbolic=__NEMU_DHCP_PROBE_ACK__,__NEMU_DHCP_PROBE_FAIL__,__NEMU_DHCP_PROBE_OFFER__,__NEMU_DHCP_PROBE_PASS__,__NEMU_DHCP_PROBE_TX__; tail=ELF          �    0      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 0db9667256b227818d5a3304289dad102e5adf1a4f0bc558725647686b2c54fa
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAABAAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-dns-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 22
- `sha256`: dafbe04ccb6327abc4acd6ae2f3b480e1edc3ed7425339b5eb6187c9b0c025f6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_DNS_PROBE_FAIL__", "__NEMU_DNS_PROBE_PASS__", "__NEMU_DNS_PROBE_RX__", "__NEMU_DNS_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=22; symbolic=__NEMU_DNS_PROBE_FAIL__,__NEMU_DNS_PROBE_PASS__,__NEMU_DNS_PROBE_RX__,__NEMU_DNS_PROBE_TX__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: 58ced202b225f3783087eb3148b09ab345b8252f25e5ce243f2ffd3cba6fb857
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAtA4AAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-icmp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 27
- `sha256`: 9fcde8394107ce5c65be311f5fea887953bb0df4438d04299507ba48f4e94032
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_ICMP_PROBE_FAIL__", "__NEMU_ICMP_PROBE_PASS__", "__NEMU_ICMP_PROBE_RX__", "__NEMU_ICMP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=27; symbolic=__NEMU_ICMP_PROBE_FAIL__,__NEMU_ICMP_PROBE_PASS__,__NEMU_ICMP_PROBE_RX__,__NEMU_ICMP_PROBE_TX__; tail=ELF          �    �      @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.b64

- `kind`: b64
- `size_bytes`: 47043
- `line_count`: 611
- `sha256`: 8de68d1edd0edced7c5df465ca5160d329bb2129b9936fecef339ab476585f0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: b64 evidence; size=47043 bytes; lines=611; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAQDwAAAAAAABAAAAAAAAAAIiBAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADWAAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-syscall-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 34824
- `line_count`: 104
- `sha256`: bbbd9677a2794f256063a965a7e36fac62f677889e6585de1e4bd06faaeecfc8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_SYSCALL_PROBE_BEGIN__", "__NEMU_SYSCALL_PROBE_DONE__", "__NEMU_SYSCALL_PROBE_FAIL__", "__NEMU_SYSCALL_PROBE_PASS__"]}
- `summary`: riscv64 evidence; size=34824 bytes; lines=104; symbolic=__NEMU_SYSCALL_PROBE_BEGIN__,__NEMU_SYSCALL_PROBE_DONE__,__NEMU_SYSCALL_PROBE_FAIL__,__NEMU_SYSCALL_PROBE_PASS__; tail=ELF          �    @<      @       ��         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5�                      S                                             ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.b64

- `kind`: b64
- `size_bytes`: 13844
- `line_count`: 180
- `sha256`: f1c0f54fe2ba5503afb4a748e27c442c6678f9826177ee548ed3b46719d95d64
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: b64 evidence; size=13844 bytes; lines=180; markers=<none>; tail=f0VMRgIBAQAAAAAAAAAAAAMA8wABAAAAIAwAAAAAAABAAAAAAAAAAIghAAAAAAAABQAAAEAAOAAK AEAAGgAZAAYAAAAEAAAAQAAAAAAAAABAAAAAAAAAAEAAAAAAAAAAMAIAAAAAAAAwAgAAAAAAAAgA AAAAAAAAAwAAAAQAAABwAgAAAAAAAHACAAAAAAAAcAIAAAAAAAAhAAAAAAAAACEAAAAAAAAAAQAA AAAAAAADAABwBAAAADUgAAAAAA...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu-systemd-tcp-probe.riscv64

- `kind`: riscv64
- `size_bytes`: 10248
- `line_count`: 40
- `sha256`: 90c0367f862c49de8d60dcdadd00837daed0fad5252702718563264521e560a8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"symbolic": ["__NEMU_TCP_PROBE_BURST__", "__NEMU_TCP_PROBE_CONNECT__", "__NEMU_TCP_PROBE_FAIL__", "__NEMU_TCP_PROBE_ITER__", "__NEMU_TCP_PROBE_PASS__", "__NEMU_TCP_PROBE_RX__", "__NEMU_TCP_PROBE_TX__"]}
- `summary`: riscv64 evidence; size=10248 bytes; lines=40; symbolic=__NEMU_TCP_PROBE_BURST__,__NEMU_TCP_PROBE_CONNECT__,__NEMU_TCP_PROBE_FAIL__,__NEMU_TCP_PROBE_ITER__,__NEMU_TCP_PROBE_PASS__; tail=ELF          �           @       �!         @ 8   @         @       @       @       0      0                   p      p      p      !       !                p   5                       S                                              ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/nemu.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/rootfs-overlay.raw

- `kind`: raw
- `size_bytes`: 8589934592
- `line_count`: 85014
- `sha256`: a8c2eec1e7dd5ca2db938ac584f6a20a8f6e096817c0e879120a71534f3cc5a0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: raw evidence; size=8589934592 bytes; lines=85014; markers=<none>; tail=                                                                                                                                                                                                                                                                 ...

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nemu-ubuntu-full-focused/vda-direct-read-sha256.tsv

- `kind`: tsv
- `size_bytes`: 76
- `line_count`: 1
- `sha256`: 7346790f78245ba161b1c2a1579926f4805a526615e10f39ed48271774a8dd02
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {}
- `summary`: tsv evidence; size=76 bytes; lines=1; markers=<none>; tail=8589869056:de2f256064a0af797747c2b97505dc0b9f3df0de4f489eac731c23ae9ca9cc31

### .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3757
- `line_count`: 14
- `sha256`: 5c113209e46c31d41f82e175aae4a120e7a9a6ee999db63b82974f6300d951c5
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T15:41:46+00:00
- `markers`: {"FAIL": 2, "PASS": 30}
- `summary`: tsv evidence; size=3757 bytes; lines=14; FAIL=2; PASS=30; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-12-nemu-full-hostless-apt-install-real-run-v3/evidence/recall-discovery.log tool-env-check agent-system toolchain PAS...
