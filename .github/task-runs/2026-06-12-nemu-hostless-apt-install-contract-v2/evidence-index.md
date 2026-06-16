# Evidence Index

## 基本信息

- `task_id`: 2026-06-12-nemu-hostless-apt-install-contract-v2
- `task_slug`: nemu-hostless-apt-install-contract-v2
- `profile`: nemu-ubuntu
- `asset_count`: 31
- `total_size_bytes`: 598438

## 证据资产

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-host-build.log

- `kind`: log
- `size_bytes`: 669
- `line_count`: 10
- `sha256`: c80ad239a203ab34498f57dd12468c82437cd1a8408223809ba496bc4ed0ab3a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {}
- `summary`: log evidence; size=669 bytes; lines=10; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' make[1]: Leaving dire...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-rootfs-flavor-artifacts-dry-run.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 8
- `sha256`: eefab15ba45fbfab7c2fc99ef5e28764016a7e608958f09ae3982cbbb21f8890
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {}
- `summary`: log evidence; size=613 bytes; lines=8; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS_CPIO_IMAGE='/home/lyg/PA/ysyx-workbench/Lin...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-rootfs-flavor-full-soak-gate-dry-run.log

- `kind`: log
- `size_bytes`: 12145
- `line_count`: 96
- `sha256`: 9221eac63c15e417ee1bf0c7ccbb973bf11d8032a0edb7f303604142ca3e45cf
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["__GUEST_ISA__"]}
- `summary`: log evidence; size=12145 bytes; lines=96; symbolic=__GUEST_ISA__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-rootfs-flavor-guest-gate-dry-run.log

- `kind`: log
- `size_bytes`: 11752
- `line_count`: 87
- `sha256`: 65f1a4d65e878f26d836213cab3b16a31a44f8e38cca1133bfb766d95c802a91
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["__GUEST_ISA__"]}
- `summary`: log evidence; size=11752 bytes; lines=87; symbolic=__GUEST_ISA__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make ARCH=riscv64-nemu BOOT=ubuntu-rootfs \ UBUNTU_ROOTFS_FLAVOR=full \ UBUNTU_ROOTFS_IMAGE='/home/lyg/PA/ysyx-workbench/Linux/env/images/ubuntu2204/ubuntu-22.04-riscv64-full.ext4' \ UBUNTU_ROOTFS...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-run-overlay-dry.log

- `kind`: log
- `size_bytes`: 5971
- `line_count`: 60
- `sha256`: aa61ead693f25971204a828af1c768f48595d100b60ab144dbae57e9112ccb6d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {}
- `summary`: log evidence; size=5971 bytes; lines=60; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' make -C '/home/lyg/PA/ysyx-workbench/nemu' NEMU_HOME='/home/lyg/PA/ysyx-workbench/nemu' riscv64-linux_defconfig make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/nemu' /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-ubuntu-slice-contract.log

- `kind`: log
- `size_bytes`: 62229
- `line_count`: 1311
- `sha256`: 37023b9e2432256e22b2654f585711e8156c3a035bc3e042cd7ea056ad61ed87
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"BAD_TRAP": 2, "FAIL": 8, "GOOD_TRAP": 18, "OOPS": 2, "PANIC": 2, "PASS": 2606, "symbolic": ["__NEMU_CHECK_COMMON_COMMANDS__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__", "__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__", "__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__", "__NEMU_CHECK_FULL_APT_POLICY_RC__", "__NEMU_CHECK_FULL_CURL_404_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HEAD_HTTP_CODE__", "__NEMU_CHECK_FULL_CURL_HTTP_CODE__", "__NEMU_CHECK_FULL_DPKG_AUDIT_RC__", "__NEMU_CHECK_FULL_DPKG_LIST__", "__NEMU_CHECK_FULL_DPKG_QUERY__", "__NEMU_CHECK_FULL_DPKG_SEARCH__", "__NEMU_CHECK_FULL_RESOLV_CONF_BEGIN__", "__NEMU_CHECK_FULL_SSH_CLIENT__", "__NEMU_CHECK_FULL_SSH_DEBUGD_LOG_BEGIN__", "__NEMU_CHECK_FULL_SSH_DEBUG_CLIENT_BEGIN__", "__NEMU_CHECK_FULL_SSH_DEBUG_LOGIN_RC__", "__NEMU_CHECK_FULL_SSH_DEBUG_READY__", "__NEMU_CHECK_FULL_SSH_DROPBEAR_LOG_BEGIN__", "__NEMU_CHECK_FULL_SSH_DROPBEAR_READY__"]}
- `summary`: log evidence; size=62229 bytes; lines=1311; FAIL=8; PASS=2606; GOOD_TRAP=18; BAD_TRAP=2; PANIC=2; OOPS=2; symbolic=__NEMU_CHECK_COMMON_COMMANDS__,__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_MESSAGE__,__NEMU_CHECK_FULL_APT_HOSTLESS_INSTALL_RC__,__NEMU_CHECK_FULL_APT_HOSTLESS_UPDATE_RC__,__NEMU_CHECK_FULL_APT_POLICY_RC__; tail=[nemu-ubuntu] slice contract guard PASS nemu/src/device/rng.c PASS nemu/src/device/net.c PASS nemu/src/device/goldfish_rtc.c PASS Linux/tools/nemu-systemd-icmp-probe.c PASS Linux/tools/nemu-systemd-dhcp-probe.c PASS Linux/tools/nemu-systemd-dns-probe.c PASS...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/nemu-ubuntu-static.log

- `kind`: log
- `size_bytes`: 197499
- `line_count`: 3122
- `sha256`: bbd8fb7bc3f99309051248ad44668c447e1f1675add1157b7a72941e06b241f1
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"GOOD_TRAP": 23, "PASS": 370, "symbolic": ["__GUEST_ISA__", "__NEMU_GDBSTUB_SMOKE__", "__NEMU_KERNEL_CONFIG__", "__NEMU_PERFORMANCE_CONFIG__"]}
- `summary`: log evidence; size=197499 bytes; lines=3122; PASS=370; GOOD_TRAP=23; symbolic=__GUEST_ISA__,__NEMU_GDBSTUB_SMOKE__,__NEMU_KERNEL_CONFIG__,__NEMU_PERFORMANCE_CONFIG__; tail=9 ( s3) = 0x0000000000000000 x20 ( s4) = 0x0000000000000000 x21 ( s5) = 0x0000000000000000 x22 ( s6) = 0x0000000000000000 x23 ( s7) = 0x0000000000000000 x24 ( s8) = 0x0000000000000000 x25 ( s9) = 0x0000000000000000 x26 ( s10) = 0x0000000000000000 x27 ( s11)...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28274
- `line_count`: 337
- `sha256`: 0c6ca948ed06d1e2756f368efbc7d9f49c45bf031178b8fc5e0e7d6b17a7ba59
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28274 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35286
- `line_count`: 324
- `sha256`: ae4d4c3865da7ad43ffd640d8d5bbbb1e636448fa592880f0154c4374377eebb
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35286 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 32992
- `line_count`: 299
- `sha256`: 116a81f57cb130950c9fe9b1625a414982cba49b55a023d5f38b3ad2b24be040
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32992 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32380
- `line_count`: 290
- `sha256`: 345335290b41421aa1267cad1d40c997b886b93b463d0bafa4c0deed865fb411
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32380 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000,...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34792
- `line_count`: 320
- `sha256`: 7c406eff0af9d953955bdc1105c9af0fdeb14a08438c0c7584435afc8ba0b4d9
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34792 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 354
- `line_count`: 4
- `sha256`: 239607c0373a2193b39f1964af92da7205637f05c7f71544ed32d56bf7f22a15
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {}
- `summary`: log evidence; size=354 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-12-ne...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1533
- `line_count`: 29
- `sha256`: b78545ead34886b2516f42b8b30ced594a9ebc55ae3e68a524b659ef992e4fad
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1533 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1093
- `line_count`: 20
- `sha256`: 487a55225e4b234146bb0e6a53638eb7f486c8d52009c3757070633ede3d9cf9
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {}
- `summary`: log evidence; size=1093 bytes; lines=20; markers=<none>; tail=93:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 94:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 95:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 96:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 97:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 98:NPC_SY...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30090
- `line_count`: 259
- `sha256`: 167d7189449403f881a4ca56d9590b2a557e2c85c561ca7800bd62a984a89c8a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30090 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-n...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 13
- `sha256`: 5110c62a10fedf02fcc2882ccbdce0f0ffa8d271ee890fb4677c3a3aa5d050ba
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/modu...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 324
- `line_count`: 11
- `sha256`: 81f7b0011b2b5368656e6846811f6d086132539d12c3673bd311fff12c48b060
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=324 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_uar...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 29001
- `line_count`: 241
- `sha256`: afefe386278cf965da74dd055ee71e59c23173fb4730d012ef094fcefe7559cb
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=29001 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27212
- `line_count`: 220
- `sha256`: cbe51e374059a37770ab791ca471ac90a99ab06e9dc24f91ac88afde014276bc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27212 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x000...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25891
- `line_count`: 213
- `sha256`: 6e652b8fed33fd1bba4ee597ff0af2514acf5cbb106ef61ccabfad47aca95bb3
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25891 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x0...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/software-flow-contract.log

- `kind`: log
- `size_bytes`: 2469
- `line_count`: 37
- `sha256`: d7fd15a4d6e627594d6f61c6ae2d8d3e88c330a4b37fbe2868bb28f81205103b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"FAIL": 2, "PASS": 68}
- `summary`: log evidence; size=2469 bytes; lines=37; FAIL=2; PASS=68; tail=[software-flow] contract PASS .github/agents/software-flow.agent.md PASS .github/e2e/modules/software-flow.md PASS .github/e2e/profiles/software-flow.tsv PASS .github/memory/modules/software-flow.md PASS .github/agents/nemu.agent.md PASS .github/agents/abst...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/nodes.tsv

- `kind`: tsv
- `size_bytes`: 3478
- `line_count`: 13
- `sha256`: 8625bdf15fae090b451f272bea767cb14c7eba8e1ac66f85cf061c923f2c71cf
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T13:41:16+00:00
- `markers`: {"PASS": 30}
- `summary`: tsv evidence; size=3478 bytes; lines=13; PASS=30; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-12-nemu-hostless-apt-install-contract-v2/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS age...
