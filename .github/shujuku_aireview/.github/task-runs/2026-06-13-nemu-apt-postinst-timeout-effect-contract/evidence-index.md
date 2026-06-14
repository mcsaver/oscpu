# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-nemu-apt-postinst-timeout-effect-contract
- `task_slug`: nemu-apt-postinst-timeout-effect-contract
- `profile`: nemu-ubuntu
- `asset_count`: 31
- `total_size_bytes`: 587725

## 证据资产

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7286
- `line_count`: 92
- `sha256`: dcc5e2880647f41967b1e9af5477195c181e26bebb761996e8cfef5ba75bbbba
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=7286 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6979
- `line_count`: 85
- `sha256`: 85994e22d6a2aef8c993d4170638dc8df74b93d43f4e578286c8613709dd7f06
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=6979 bytes; lines=85; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 67524
- `line_count`: 1386
- `sha256`: cbabd27843bc60c7bbe98ea7d3fa5d86ca8f30e983178a7fb3539deeaef43deb
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 8, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2658, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_EFFECT_OK_AFTER_TIMEOUT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PID__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_SAMPLE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_START__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TARGET__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TIMEOUT__"]}
- `summary`: log evidence; size=67524 bytes; lines=1386; FAIL=8; PASS=2658; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_META_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__; tail=ontract PASS software-flow methodology available to nemu-ubuntu software-dev-loop PASS software-flow methodology available to nemu-ubuntu software-bugfix-loop PASS software-flow methodology available to nemu-ubuntu hardware-aware-software-loop PASS software...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 191026
- `line_count`: 3138
- `sha256`: 4bc5d25b41ccdfe22c2fc0f93089ae06b941328ca7a59e0dbcc8af711a41d935
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 411, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=191026 bytes; lines=3138; PASS=411; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=moke-nemu.log.hbreak[0m [1;34m[src/memory/paddr.c:66 init_mem] physical memory area [0x80000000, 0xbfffffff][0m [1;34m[src/device/io/mmio.c:78 add_mmio_map] Add mmio map 'serial' at [0x10000000, 0x10000fff][0m [1;34m[src/device/disk.c:1643 open_disk_i...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28278
- `line_count`: 337
- `sha256`: f3d94006145f9dac36eeeb1ac3619e163b665cc92f02e07173397a44ad3b54c8
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28278 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35313
- `line_count`: 324
- `sha256`: 90b9e35a5df12356f53ac84e1ce2fe686e2de29c70bc2f31143c5c5b3acca662
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35313 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 32995
- `line_count`: 299
- `sha256`: 0a933ae844847f3f0ef9848450cf4a6fa748c06154ccde1fd261bea90acdbfc2
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32995 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32383
- `line_count`: 290
- `sha256`: 38bde7d9f9b5d5cec8fd4fb836f9f3e84157e10147fe0f628b71a14d7810e28e
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32383 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x00000000800000...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34807
- `line_count`: 320
- `sha256`: c86aba8a127dceb1956338a353cee43aa974ec5c88b3657fbf9b7bc7bfe690be
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34807 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 358
- `line_count`: 4
- `sha256`: 4aa1f6ed809c4cb60f408a93fb1dc98c2fbae367c2d5888d39e396974d37590e
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=358 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-13-ne...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1541
- `line_count`: 29
- `sha256`: d62337f161d39c2d87d22f681f996b5e3214db965db887a11960c1b2f1921a48
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1541 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1097
- `line_count`: 20
- `sha256`: 9ff869aaaa0a6e5c018487ece7423d5ce640e48a02cb389f64eaee889e94ccd5
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=1097 bytes; lines=20; markers=<none>; tail=98:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 99:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 100:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 101:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 102:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 103:NP...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30126
- `line_count`: 259
- `sha256`: bb7392024984281e443b6eb96fb4e644e7f919248481a494b2a5f09ec967feae
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30126 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-n...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 13
- `sha256`: 3563c5368e1333664592bafe086d24d899c769817e9207d1a69552b9873ea8c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 328
- `line_count`: 11
- `sha256`: 3ec69d7dfd5a63ca5c1acc2328b48bea77af794f1af9ddb9a882fde5be7424de
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=328 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS tb...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 29017
- `line_count`: 241
- `sha256`: 06e19fbad3bb2bf0c29ec02cd59eb6c009133a38c6f2c82ac73aca1140952615
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=29017 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27216
- `line_count`: 220
- `sha256`: 83097e47711a5c5c682ef8e5d0ffa71b03033e8d56e930b0113a23365566b063
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27216 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25895
- `line_count`: 213
- `sha256`: 787f6351b39ab713b5c656274e75df146af01b2ea1e132a0feebb140f7962ea6
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25895 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000,...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3530
- `line_count`: 13
- `sha256`: 268392f51aeb30c6999344b43fdeeb70adc3acdaec7a41797cc8a2ba914d08f3
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T03:23:39+00:00
- `markers`: {"PASS": 30}
- `summary`: tsv evidence; size=3530 bytes; lines=13; PASS=30; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-nemu-apt-postinst-timeout-effect-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS...
