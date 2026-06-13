# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-nemu-apt-install-actual-instrument-contract
- `task_slug`: nemu-apt-install-actual-instrument-contract
- `profile`: nemu-ubuntu
- `asset_count`: 31
- `total_size_bytes`: 585959

## 证据资产

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 8
- `sha256`: 76a924046263f6e502b07a6883cd199e993ea2b9f2d9678e573c50912a0539ad
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=578 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 7286
- `line_count`: 92
- `sha256`: 91142fc1aeff8456b1869f0b9199a02f1333b6282c5121627dda7ed3961043d5
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=7286 bytes; lines=92; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 6979
- `line_count`: 85
- `sha256`: 76ed115a741c20a9af333c57f643b778d65f5b492f9f0aac9cbaab024c823280
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=6979 bytes; lines=85; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 66331
- `line_count`: 1371
- `sha256`: 82b3bb5692a9ee3c7ff13140d463a004dba117acb03465211d2a61c1cb756be6
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 8, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2684, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__", "__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_DEADLINE_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOCKS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_LOG_TAIL_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE_SNAPSHOT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PID__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_PS_BEGIN__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_SAMPLE__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_START__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_INSTALL_TIMEOUT__", "__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_SIM_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_DOWNLOAD_SHA256__"]}
- `summary`: log evidence; size=66331 bytes; lines=1371; FAIL=8; PASS=2684; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_RC__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_DOWNLOAD_SHA256__,__NEMU_CHECK_FULL_APT_DIRECT_EMPTY_STATUS_SIM_RC__,__NEMU_CHECK_FULL_APT_DIRECT_FULL_STATUS_DPKG_STATUS_SNAPSHOT__; tail=v64i.c PASS nemu/src/isa/riscv64/inst/fp.c PASS nemu/src/isa/riscv64/inst/muldiv.c PASS nemu/src/isa/riscv64/inst/amo.c PASS nemu/src/isa/riscv64/inst/bitmanip.c PASS nemu/src/isa/riscv64/inst/compressed.c PASS nemu/src/isa/riscv64/inst/decode_cache.c PASS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 190564
- `line_count`: 3134
- `sha256`: fa2685ed83e7367eeceed5c58b4598d48dfd9a8c8c50e1ab9f7e7d513d0ea27d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 416, "symbolic": ["__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=190564 bytes; lines=3134; PASS=416; GOOD_TRAP=23; symbolic=__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=wbreak-remove OK PASS swbreak-continue-exit W00 PASS swbreak-vcont-continue-exit W00 PASS swbreak-nemu-exit rc=0 [1;34m[src/utils/log.c:30 init_log] Log is written to /home/lyg/PA/ysyx-workbench/Linux/build/nemu-gdbstub-smoke-nemu.log.hbreak[0m [1;34m[sr...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28280
- `line_count`: 337
- `sha256`: 42f6cd1aa4c2b8e63bea5eb44097241eca429232cc715aa07ed108bd0ba7ec29
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28280 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35330
- `line_count`: 324
- `sha256`: 70694ed3248e76d61fe397ba92d7f616b64509240944fc4dc3fae8e8c9004cfa
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35330 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 33000
- `line_count`: 299
- `sha256`: d931f4f28e368c71c49e8e7db8947732f2e62ae51c287e403b69219bb974f3c0
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=33000 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory ar...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32388
- `line_count`: 290
- `sha256`: 44ce1838a565136a8935e5e01bee4fde090e364b1a30bf181a072830bff5cb07
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32388 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x000000008000...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34818
- `line_count`: 320
- `sha256`: d9ff35f995f21e3cf19fb18616476e542ec82d8dcfc5d1536d84eef872919454
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34818 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 360
- `line_count`: 4
- `sha256`: 078f9a39f1f98b035ec0e9c2a87938af5081fa377a4ba22bd912f7c4e8b1c83a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=360 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-13-ne...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1543
- `line_count`: 29
- `sha256`: f93396a01c9a0376727fda703b77aa6d4cc07d4ba194f441af34cb441653a184
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1543 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1097
- `line_count`: 20
- `sha256`: 9ff869aaaa0a6e5c018487ece7423d5ce640e48a02cb389f64eaee889e94ccd5
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=1097 bytes; lines=20; markers=<none>; tail=98:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 99:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 100:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 101:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 102:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 103:NP...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30144
- `line_count`: 259
- `sha256`: db2878e2b63ce93fe8d69278d925140f3d6dfc2ece1ebf77e5cae95fdd33dbb0
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30144 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-n...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 477
- `line_count`: 13
- `sha256`: 6314cfef98f4536afe1d9f73da94e515387646899443ec2f0c1a44e42759c987
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=477 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smok...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 330
- `line_count`: 11
- `sha256`: 241e9b305ae2b50e1b3f8ecc0ba8b99d90a9eb7e6979031daaa23acf38cc0fd4
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=330 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 29025
- `line_count`: 241
- `sha256`: 86d2472d1930216a664281ae8f342609630fbc6beea09ff6c642229db5c89d36
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=29025 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27218
- `line_count`: 220
- `sha256`: 3738593a6a4c61274e9edce40e29e0ea69fc3a32fbc37bb299e820ca468f2d6b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27218 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25897
- `line_count`: 213
- `sha256`: 4335265f94c16ff2cb4011b81a991125bf683162b25d50c9d63c17146a29c810
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25897 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x000000008000000...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2319
- `line_count`: 41
- `sha256`: 1b010560b5f39f8b38fa20e0664b738610b63bd808508b30ad2d9401358fb206
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2319 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3556
- `line_count`: 13
- `sha256`: e64ad4bb2af9ad4cab37f74ad62a5c0a2c13bd3bf3f0d0807ce06400ca832f1f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T22:03:11+00:00
- `markers`: {"PASS": 30}
- `summary`: tsv evidence; size=3556 bytes; lines=13; PASS=30; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-nemu-apt-install-actual-instrument-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PA...
