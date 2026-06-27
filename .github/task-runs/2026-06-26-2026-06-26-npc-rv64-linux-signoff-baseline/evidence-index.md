# Evidence Index

## 基本信息

- `task_id`: 2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline
- `task_slug`: 2026-06-26-npc-rv64-linux-signoff-baseline
- `profile`: rv64-linux
- `asset_count`: 24
- `total_size_bytes`: 191610

## 证据资产

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 6
- `sha256`: 96979325445185b818c422c8920196f5500a43bc0e977f957d990fd2901db99f
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=147 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/study/README.md PASS Linux/README.md

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 10531
- `line_count`: 132
- `sha256`: 556ec581684d8cf303260e3bb1c29b77a011eb159b62a2602e9f6ed61208e31e
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=10531 bytes; lines=132; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 22440
- `line_count`: 279
- `sha256`: 4bb68b985e2cbc4c4b0562d15105e1e1c9a99d099c500b8e8f450831ca558fad
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=22440 bytes; lines=279; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LIN...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 16854
- `line_count`: 216
- `sha256`: 02afdf279c7bb3199750f328b3359a0ac048aca3b6c72e6ebfc235e99496d911
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=16854 bytes; lines=216; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[1;34m[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 17402
- `line_count`: 207
- `sha256`: 67624b0aa632636cbb93335bcd78efbbeec2ee16ebddc2004536e6a2055a990d
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=17402 bytes; lines=207; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 21931
- `line_count`: 275
- `sha256`: 4fd5348e22270a1a7fae9276d324ec8cbef3783190c92e160f967fa26d0836d1
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["__NPC_CHECK_PASS__", "__NPC_CHECK_SYSTEMD_STATE__", "__NPC_SYSTEMD_CHECK_BEGIN__", "__NPC_SYSTEMD_CHECK_DONE__", "_____"]}
- `summary`: log evidence; size=21931 bytes; lines=275; symbolic=__NPC_CHECK_PASS__,__NPC_CHECK_SYSTEMD_STATE__,__NPC_SYSTEMD_CHECK_BEGIN__,__NPC_SYSTEMD_CHECK_DONE__,_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 359
- `line_count`: 4
- `sha256`: d88a907aeb52309df70c90a7addd505233d5013fa8c14d8ae93ee2bf0197e974
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {}
- `summary`: log evidence; size=359 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-06-26-20...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 15898
- `line_count`: 95
- `sha256`: 2b6acb447658ae2e7dde25b8d4f8500d391a76af331676111096743e94ca0bb4
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15898 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_sv39_boot [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_sv39_boot -o build/tb_ooo_sv39_boot.vvp tests/tb_ooo_sv39_boot.sv /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 8252
- `line_count`: 43
- `sha256`: 6edc04a0f9373b1dd3ba6643d761ea0cb9314e28e0d33f82e0dadcc7b265aef3
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=8252 bytes; lines=43; PASS=14; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/Makefile PASS npc/rv64/vsrc/bus/AxiLiteClint.v PASS npc/rv64/vsrc/core/NpcTop.v PASS npc/rv64/csrc/dpi.c PASS npc/rv64/csrc/cpu/cpu-exec.cpp P...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 7807
- `line_count`: 34
- `sha256`: ca466980388684948ace6bac0c745aec632e31126c8347e69b636798533ea31a
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {}
- `summary`: log evidence; size=7807 bytes; lines=34; markers=<none>; tail=181:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 182:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 183:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 184:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 185:NPC_SYSTEMD_UART_WAIT ?= $(NPC_SYSTEMD_P...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 16207
- `line_count`: 201
- `sha256`: 72f84cb6d74650631e26a07b06b716ebe01f23d100923d338ad6d33202e793c1
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 4, "symbolic": ["_____"]}
- `summary`: log evidence; size=16207 bytes; lines=201; PASS=4; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 13
- `sha256`: b5df4e004e70edc2df4c5aba2849cd00c7bf5d6c7bede9de20d55d5fbc25205f
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=13; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_lite_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d699ea75f013789a1dfe22da81b2f6a660ea8b1b2ee1e1e967beceab3a6f76c3
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_lite_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_axi_lite_to_uart -o build/tb_axi_lite_to_uart.vvp tests/tb_axi_lite_to_uart.sv /home/ly...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 335
- `line_count`: 5
- `sha256`: cb6da78ef6b6db74f3138fc8a24a1cdf7e46b75b3100f22107de5fd65847fad9
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=335 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_uart -o build/tb_uart.vvp tests/tb_uart.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v [PA...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 329
- `line_count`: 11
- `sha256`: 74f47c119ddda123fd0c533c84f5c66268fed3215149a2ba70b9feeaa9bd3dd7
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=329 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 12.0 (stable) () - PASS t...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 15093
- `line_count`: 183
- `sha256`: dd8b822dafe08d80a7d3651d682fa977e8cf8556eeb8f070af7d507f9e94dc6c
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=15093 bytes; lines=183; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 10027
- `line_count`: 124
- `sha256`: 78dc0520a368c24d65081e8c434b2d19a25bf691c044527bd9cdfd5612756ea5
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=10027 bytes; lines=124; symbolic=_____; tail=[1;34m[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [0m [1;34m[paddr.c:85 npc_init_mem] physical memory area [0x...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 9762
- `line_count`: 117
- `sha256`: cabf6798ebe902ef9ca66e94956ceb55da7e29c823cfac7012d29c065317c943
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=9762 bytes; lines=117; symbolic=_____; tail=[log.c:174 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:85 npc_init_mem] physical memory area [0x0000000080000000...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4462
- `line_count`: 86
- `sha256`: 8077a0acbe74f293beb156fc162b01c581ce682a8c0f2a6c3ec6f328db18efcc
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 158}
- `summary`: log evidence; size=4462 bytes; lines=86; PASS=158; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/rv64-linux-contract.log

- `kind`: log
- `size_bytes`: 293
- `line_count`: 9
- `sha256`: aac7a50f155f71afb8b7c6066f8b013d6bc28d1e8cd2c2dd1e4277c5fbe37352
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=293 bytes; lines=9; PASS=16; tail=[rv64-linux] contract PASS Linux/README.md PASS Linux/env/README.md PASS Linux/Makefile PASS Linux/scripts/platform/nemu.mk PASS Linux/scripts/platform/npc.mk PASS Linux/platform/npc-rv64.yml PASS .github/agents/rv64-linux.agent.md PASS .github/instructions...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/nodes.tsv

- `kind`: tsv
- `size_bytes`: 2791
- `line_count`: 10
- `sha256`: caaf4cb84b002375e9414d70f389f63ae70869b04b7e366dfd4f1ca0d4a79f7e
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 22}
- `summary`: tsv evidence; size=2791 bytes; lines=10; PASS=22; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/evidence/recall-discovery.log tool-env-check agent-system toolchain PAS...

### .github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/run-manifest.json

- `kind`: json
- `size_bytes`: 6733
- `line_count`: 158
- `sha256`: 03c1d17ff895443d0297077095629a7d23a81d2c0946af62ccb6d9fa8af162e5
- `encoding`: utf-8
- `indexed_at`: 2026-06-26T07:20:10+00:00
- `markers`: {"PASS": 24}
- `summary`: json evidence; size=6733 bytes; lines=158; PASS=24; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-26-2026-06-26-npc-rv64-linux-signoff-baseline/dispatch-log.md", "evidence_dir": ".github...
