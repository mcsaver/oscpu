# Evidence Index

## 基本信息

- `task_id`: 2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch
- `task_slug`: 2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch
- `profile`: rv64-linux
- `asset_count`: 24
- `total_size_bytes`: 171023

## 证据资产

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 10160
- `line_count`: 125
- `sha256`: 44574543584f2197cb0ad84d5c5db95a5395351c9b9085589d45c8f64fc39e5f
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=10160 bytes; lines=125; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 17217
- `line_count`: 243
- `sha256`: 6cb679c5935c948fde6fb171288ebc9a52921342130763b21331f386f006ecc2
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=17217 bytes; lines=243; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LIN...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 11512
- `line_count`: 180
- `sha256`: 40fed911a5e377a4bd0babe9b0dce53299db778a2d86dcd6d8c1f012af23d9f6
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=11512 bytes; lines=180; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[1;34m[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical m...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 12446
- `line_count`: 172
- `sha256`: df46c2c342d58052154ede92956695bd251442cdeed777b0d35de4d354e212f2
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=12446 bytes; lines=172; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x00...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 16675
- `line_count`: 239
- `sha256`: 0169919334ad5c087cd31ef7f7e2a918a65cb4ca5a90b7797f095712c3872353
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=16675 bytes; lines=239; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 370
- `line_count`: 4
- `sha256`: 0f35c66a801f22812f44c15ed2c88370de82b8654d245953a99747f080334a2c
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {}
- `summary`: log evidence; size=370 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-26-20...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15898
- `line_count`: 95
- `sha256`: 2b6acb447658ae2e7dde25b8d4f8500d391a76af331676111096743e94ca0bb4
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15898 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 8263
- `line_count`: 43
- `sha256`: 3635fd2abc0d6ac1912023345adbc345a600355a6780badc4a495e137ceaa6b8
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=8263 bytes; lines=43; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 7807
- `line_count`: 34
- `sha256`: ca466980388684948ace6bac0c745aec632e31126c8347e69b636798533ea31a
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {}
- `summary`: log evidence; size=7807 bytes; lines=34; markers=<none>; tail=181:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 182:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 183:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 184:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 185:NPC_SYSTEMD_UART_WAIT ?= $(NPC_SYSTEMD_P...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 16306
- `line_count`: 201
- `sha256`: e26eb657dce6a33e18f5f8dc7929e25c66d951ccfeb8605fd96d2e904fdaea8a
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=16306 bytes; lines=201; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 13
- `sha256`: 8fdc2e638b18bdeeadfb91314d7df9a2a654d5af5ae01c450b2af946705ee9f1
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-ua...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d699ea75f013789a1dfe22da81b2f6a660ea8b1b2ee1e1e967beceab3a6f76c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 335
- `line_count`: 5
- `sha256`: cb6da78ef6b6db74f3138fc8a24a1cdf7e46b75b3100f22107de5fd65847fad9
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=335 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 340
- `line_count`: 11
- `sha256`: 423c3a5b2957414c64ae4c16194ad27e16a37ad08efa079d35adb3c9b8824676
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=340 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable)...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 15137
- `line_count`: 183
- `sha256`: 1b18b18561b102fb520f34dc799533c6a18ba7ff9b17974e652a0f99f112db19
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=15137 bytes; lines=183; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 10038
- `line_count`: 124
- `sha256`: 6cb4198dd17c6ae2d7629705b4732aef95f30c68daa5ad9cc88fb841877723f1
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=10038 bytes; lines=124; symbolic=_____; tail=[1;34m[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memo...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 9773
- `line_count`: 117
- `sha256`: b0aba0c3ae7e6c1ce5283f6a77b4208adf1de480bd1414cd00e48782345f335e
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=9773 bytes; lines=117; symbolic=_____; tail=[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x00000...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4462
- `line_count`: 86
- `sha256`: 8077a0acbe74f293beb156fc162b01c581ce682a8c0f2a6c3ec6f328db18efcc
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 158}
- `summary`: log evidence; size=4462 bytes; lines=86; PASS=158; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 293
- `line_count`: 9
- `sha256`: aac7a50f155f71afb8b7c6066f8b013d6bc28d1e8cd2c2dd1e4277c5fbe37352
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=293 bytes; lines=9; PASS=16; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/scripts/platform/nemu.mk PASS Linux/scripts/platform/npc.mk PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/nodes.tsv

- `kind`: tsv
- `size_bytes`: 2901
- `line_count`: 10
- `sha256`: b68cbefa8b5a738b3391d702ea9633ba566c85806d8d77455b78155b4e9f452e
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 22}
- `summary`: tsv evidence; size=2901 bytes; lines=10; PASS=22; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/evidence/recall-discovery.log tool-env-check agent-system to...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/run-manifest.json

- `kind`: json
- `size_bytes`: 6975
- `line_count`: 158
- `sha256`: 8a80cdd0e3569ed79abf67f77ecca24a200ee60a067ed71f6b82dd57bec3703a
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:32:04+00:00
- `markers`: {"PASS": 24}
- `summary`: json evidence; size=6975 bytes; lines=158; PASS=24; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline-guestwatch/dispatch-log.md", "e...
