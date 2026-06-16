# Evidence Index

## 基本信息

- `task_id`: 2026-06-12-rv64-linux-after-readonly-db-fix
- `task_slug`: rv64-linux-after-readonly-db-fix
- `profile`: rv64-linux
- `asset_count`: 23
- `total_size_bytes`: 303907

## 证据资产

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 28269
- `line_count`: 337
- `sha256`: 8b83b106e5b1a69ef1cac6ecd941edd53ed59336801ee5d1b718e81e5f8f85f2
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=28269 bytes; lines=337; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 35193
- `line_count`: 324
- `sha256`: 5976c56043c027505c6e5af42dea3cea7ef2cb4dda2684006b35669c483e3bfa
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=35193 bytes; lines=324; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering director...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 32929
- `line_count`: 299
- `sha256`: 97589cd4270349472dda0c8ea648b544c74f03ec17e2e622a45863207a71ebb7
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32929 bytes; lines=299; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x00000...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 32317
- `line_count`: 290
- `sha256`: 2af65ded23583381e0a9c33ba43d023664531c9e9b51a6beb4d3a59e46611c0f
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=32317 bytes; lines=290; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x000...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 34714
- `line_count`: 320
- `sha256`: b4b1161b2dc0d9e10e11fd98f6f7665fa5374804e244a2dd6a33d2e8e1fc9514
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34714 bytes; lines=320; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 4
- `sha256`: 102a4dd966078d57c48c6df9ebe0f5712581226168f6967e0b279f9dfae62d33
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {}
- `summary`: log evidence; size=349 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-12-rv...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15635
- `line_count`: 95
- `sha256`: 33e4ce0676e6d397d157da452da5337c05b6f78cfbfb7ac2c28973947e25253b
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15635 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 1528
- `line_count`: 29
- `sha256`: 29eda10d8cc3ceb3c20095df22825b03ebc8b8a04ce5283b8855cb0b22a9486d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1528 bytes; lines=29; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 1093
- `line_count`: 20
- `sha256`: 487a55225e4b234146bb0e6a53638eb7f486c8d52009c3757070633ede3d9cf9
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {}
- `summary`: log evidence; size=1093 bytes; lines=20; markers=<none>; tail=93:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 94:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 95:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 96:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 97:NPC_SYSTEMD_UART_TRACE_LIMIT ?= 128 98:NPC_SY...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 30045
- `line_count`: 259
- `sha256`: beb7a02d0310039cde30a8c3cdad92cbde2e38ea847a3cc1e4c0f9c63e850d7d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=30045 bytes; lines=259; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-r...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 13
- `sha256`: 54035457db3d855722632913b8a39ba932c29770e7981383d94a2a62bee3b0c2
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/module-te...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: a7a8d6b142906090d65063090c5096baf0da7df20c7e7f3321c4f2dde600d27a
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 5
- `sha256`: 14291024b7f73db656499618c26c3816f5589e03e96ff3641bd715690a6f9aae
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 319
- `line_count`: 11
- `sha256`: 0ecb881998ad18b85fa4dd55add291e13e5d0231dd0da39a2267cea857706cc9
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=319 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_uart - P...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 28981
- `line_count`: 241
- `sha256`: 56af6f3a4bc011c9f73af601bd9fd745afb8657ffd5298819a5172258ad19b3d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=28981 bytes; lines=241; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' make[1]: Nothing to be done for 'de...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 27207
- `line_count`: 220
- `sha256`: d7fa8a7ca48b0bafa684b0abbe92b636755592277953df254fe072b6000e0e66
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27207 bytes; lines=220; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log[0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x00000000...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 25886
- `line_count`: 213
- `sha256`: 4deb51a70b417436f6a870deec3dd6020eaf0a967fcc7568bcdd9ab0ed6072d9
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=25886 bytes; lines=213; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000, 0x000000...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2101
- `line_count`: 43
- `sha256`: 3709471f2913e3f0f5a5e7a476e28d479bce54381c7dc5c5217ef610758df78d
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 74}
- `summary`: log evidence; size=2101 bytes; lines=43; PASS=74; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 7
- `sha256`: 3c0ecfc07ce01d69ae3c4f65b6bc38c047110a2b3a9732d82ef1a407fe6c5e08
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=222 bytes; lines=7; PASS=12; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions/rv64-linux-bringup.instructions.md

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/nodes.tsv

- `kind`: tsv
- `size_bytes`: 2691
- `line_count`: 10
- `sha256`: 3857b494fb78b0b9c5abad465b5e0ffc4f823e0d1cfc96523711df0c611e159c
- `encoding`: utf-8
- `indexed_at`: 2026-06-12T09:44:12+00:00
- `markers`: {"PASS": 22}
- `summary`: tsv evidence; size=2691 bytes; lines=10; PASS=22; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-12-rv64-linux-after-readonly-db-fix/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-en...
