# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-nemu-apt-install-diag-contract
- `task_slug`: nemu-apt-install-diag-contract
- `profile`: nemu-ubuntu
- `asset_count`: 31
- `total_size_bytes`: 582891

## 证据资产

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7247
- `line_count`: 91
- `sha256`: 54185c56be51901d90299ce3a0f68e87c71d01372d905669c424416f751d9f34
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=7247 bytes; lines=91; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6940
- `line_count`: 84
- `sha256`: 011e4b35dd6d591b847751acd87c348b10bcff115da0e63aa7a4e29031bfc88d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=6940 bytes; lines=84; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 64958
- `line_count`: 1353
- `sha256`: 5730dacb411aed4929f22d901cc7410341a39031eab27b5b495e349b59c45b47
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 10, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2688, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_LARGE_BYTES__"]}
- `summary`: log evidence; size=64958 bytes; lines=1353; FAIL=10; PASS=2688; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DPKG_STATUS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_INSTALL_MESSAGE__; tail=[nemu-ubuntu] slice contract guard PASS nemu/src/device/rng.c PASS nemu/src/device/net.c PASS nemu/src/device/goldfish_rtc.c PASS Linux/tools/nemu-systemd-icmp-probe.c PASS Linux/tools/nemu-systemd-dhcp-probe.c PASS Linux/tools/nemu-systemd-dns-probe.c PASS...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 190486
- `line_count`: 3132
- `sha256`: f1f0b3aea3dac8928a96ad42be286142814db61354325fdc85a96af55616c562
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 418, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=190486 bytes; lines=3132; PASS=418; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=wbreak-remove OK PASS swbreak-continue-exit W00 PASS swbreak-vcont-continue-exit W00 PASS swbreak-nemu-exit rc=0 [1;34m[src/utils/log.c:30 init_log] Log is written to /home/lyg/PA/ysyx-workbench/Linux/build/nemu-gdbstub-smoke-nemu.log.hbreak[0m [1;34m[sr...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28267
- `line_count`: 337
- `sha256`: b04779528ca275a3b568e7cce70208e7748b2c4e1b47740d6fc5dd54d4e14e31
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28267 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35017
- `line_count`: 324
- `sha256`: fa32dd0c7e343eb0e9c3423d94de53736dc979be14717bd0a3dfb5ce20921a41
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35017 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 32765
- `line_count`: 299
- `sha256`: a7ec991e9d6b393e7260cff8dd8838a734e24bcaace85ac62b92b678c241cfa5
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32765 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32153
- `line_count`: 290
- `sha256`: 6ebcb78b3c568bf2bf80a9919d13f520e14bcff77381bf6d05c5833b0fd8095e
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32153 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34544
- `line_count`: 320
- `sha256`: d628267404d17ea1f8e663e5d0b8ff5d6a99129aae46800375947b256464e0e9
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34544 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 4
- `sha256`: fa398c0109d62fee6dffaf4b52f5af9c59c1479641bd2108968742aec317d118
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-13-ne...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1529
- `line_count`: 29
- `sha256`: 8ebf27d7d4fe881c141e7f7c97904299c7fba5d8a7b2b412ecaadff2f49f8ed3
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1529 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1096
- `line_count`: 20
- `sha256`: 67104651c6cc91e9f87f59592354ba8842cff6f474c334604b05a43571f1e0c0
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=1096 bytes; lines=20; markers=<none>; tail=97:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 98:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 99:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 100:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 101:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 102:NPC...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30027
- `line_count`: 259
- `sha256`: 2a4419042aac17890546f876bb1bf453a9a6882867b293a7c246e1b11bf02f5e
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30027 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-n...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 13
- `sha256`: f0463b8041a127afa84ba5f9e60e080cc42e748ed16851fc078a97a092c17a10
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/module-test...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 317
- `line_count`: 11
- `sha256`: 81d31a97d014f105dd6a8ee9bd2e19d4359981a5c59c548aca85dcdaec56ef79
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=317 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_uart - PAS...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 28973
- `line_count`: 241
- `sha256`: 10a6460f8d4f7991bc2ec0957a00d78eb4844012122ed6ef43d452d82a5e3655
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=28973 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27205
- `line_count`: 220
- `sha256`: a21164716d19e18dc1dd821ee3a774cc4668d7f2d49cb58012a581399c794e00
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27205 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x0000000080...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25884
- `line_count`: 213
- `sha256`: 81edecf61447aabc9e452bbc0768acdb45f0d179db9800a7d62c0d0ae935f8a8
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25884 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2319
- `line_count`: 41
- `sha256`: 1b010560b5f39f8b38fa20e0664b738610b63bd808508b30ad2d9401358fb206
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2319 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3336
- `line_count`: 13
- `sha256`: 16fd5b4ddcf0e3cc5af1047625746de57704d1f79dbb988d6f712713d8b2993c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T17:59:42+00:00
- `markers`: {"FAIL": 2, "PASS": 28}
- `summary`: tsv evidence; size=3336 bytes; lines=13; FAIL=2; PASS=28; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-nemu-apt-install-diag-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env...
