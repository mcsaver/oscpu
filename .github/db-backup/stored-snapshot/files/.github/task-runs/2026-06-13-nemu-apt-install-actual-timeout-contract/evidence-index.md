# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-nemu-apt-install-actual-timeout-contract
- `task_slug`: nemu-apt-install-actual-timeout-contract
- `profile`: nemu-ubuntu
- `asset_count`: 31
- `total_size_bytes`: 585942

## 证据资产

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7286
- `line_count`: 92
- `sha256`: dcc5e2880647f41967b1e9af5477195c181e26bebb761996e8cfef5ba75bbbba
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=7286 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6979
- `line_count`: 85
- `sha256`: 85994e22d6a2aef8c993d4170638dc8df74b93d43f4e578286c8613709dd7f06
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=6979 bytes; lines=85; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 66331
- `line_count`: 1371
- `sha256`: af492345c008d8197dbe70105566e2aa3fb15f785643e4dbb0905482429cd140
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 8, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2684, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PID__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_SAMPLE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_START__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TIMEOUT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__"]}
- `summary`: log evidence; size=66331 bytes; lines=1371; FAIL=8; PASS=2684; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__,__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__; tail=v64i.c PASS nemu/src/isa/riscv64/inst/fp.c PASS nemu/src/isa/riscv64/inst/muldiv.c PASS nemu/src/isa/riscv64/inst/amo.c PASS nemu/src/isa/riscv64/inst/bitmanip.c PASS nemu/src/isa/riscv64/inst/compressed.c PASS nemu/src/isa/riscv64/inst/decode_cache.c PASS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 190473
- `line_count`: 3133
- `sha256`: 11070d40d6619fd0f9c8785b3c5d365eec53317ecca463bdd5ae253aa1548378
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 416, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=190473 bytes; lines=3133; PASS=416; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=wbreak-remove OK PASS swbreak-continue-exit W00 PASS swbreak-vcont-continue-exit W00 PASS swbreak-nemu-exit rc=0 [1;34m[src/utils/log.c:30 init_log] Log is written to /home/lyg/PA/ysyx-workbench/Linux/build/nemu-gdbstub-smoke-nemu.log.hbreak[0m [1;34m[sr...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28277
- `line_count`: 337
- `sha256`: 82a308c6d49a5d9e8bf28fbe265ee81bf6b8e1574024cc8f393babae7b64d805
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28277 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35362
- `line_count`: 324
- `sha256`: d812cdfbbe2cae211de2d668c93248d20d1113ad2458f901fb86f3cc30b06332
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35362 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 33050
- `line_count`: 299
- `sha256`: 01ef5c187fa3c900fdbcfd995f51bec5f088ea87db9763dcb8295f0a8faa87f5
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=33050 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32438
- `line_count`: 290
- `sha256`: d123882bdd4ff3ac1acc6e44693410f33d608060e498e0fc420fbd202025935c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32438 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x000000008000000...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34859
- `line_count`: 320
- `sha256`: 54218b0c271deb400ed9e65f9744879a77cc39cfd5522c47e01dc201ebe303ef
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34859 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 357
- `line_count`: 4
- `sha256`: 52c997b518812f622c306a1e936b44c04cbc185d6877d92c95a8af552b76f28c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=357 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-13-ne...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1540
- `line_count`: 29
- `sha256`: abb57237eec97dd92aecdc7b1f00daae2fcdc1a2106b029b722daed04f94ad60
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1540 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1097
- `line_count`: 20
- `sha256`: 9ff869aaaa0a6e5c018487ece7423d5ce640e48a02cb389f64eaee889e94ccd5
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=1097 bytes; lines=20; markers=<none>; tail=98:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 99:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 100:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 101:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 102:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 103:NP...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30117
- `line_count`: 259
- `sha256`: 9b368606b4b09821a8f3e576a1d60094244abddf8531a158c74fc3702f1e0888
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30117 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-n...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 13
- `sha256`: 621841061fe3f4bbf16303bd4dd98545f44c296fbddf665bbc58a34591dee87b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/m...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 327
- `line_count`: 11
- `sha256`: c0392483572ba88c8dd33b0373d023cfbb0663aeacc4d46200a7dbc21bfbe0ef
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=327 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 29013
- `line_count`: 241
- `sha256`: 727cfc9ca5e4baa16df8ea4fcb9eb425f47dd10660310e0b9eeb34e328763923
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=29013 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27215
- `line_count`: 220
- `sha256`: 7ffab1ba1e0f03a02b13e7fb51f3ce2efbcda17ec1311816356e6915c2779a44
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27215 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25894
- `line_count`: 213
- `sha256`: e2eb04f905904f3a61f52c2e826760a7ad30ee8e01e26404c54c2a80a15a8450
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25894 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000,...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2319
- `line_count`: 41
- `sha256`: 1b010560b5f39f8b38fa20e0664b738610b63bd808508b30ad2d9401358fb206
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2319 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3517
- `line_count`: 13
- `sha256`: e54364bb437f7f166bc1e5f4a916546b44a413d827f024ad082f4c356d3fc3fe
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T23:20:28+00:00
- `markers`: {"PASS": 30}
- `summary`: tsv evidence; size=3517 bytes; lines=13; PASS=30; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-nemu-apt-install-actual-timeout-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS...
