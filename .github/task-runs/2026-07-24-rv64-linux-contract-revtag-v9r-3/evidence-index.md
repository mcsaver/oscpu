# Evidence Index

## 基本信息

- `task_id`: 2026-07-24-rv64-linux-contract-revtag-v9r-3
- `task_slug`: rv64-linux-contract-revtag-v9r
- `profile`: rv64-linux
- `asset_count`: 21
- `total_size_bytes`: 492391

## 证据资产

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 155
- `line_count`: 6
- `sha256`: 17664962cd1567c20052fc78a70a50660d0c6219630a67f825e1ab8278230ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=155 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/history/study/README.md PASS Linux/README.md

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 27259
- `line_count`: 322
- `sha256`: bcb93f78184678b053c80197e1f0470fb2f151720b829ec8a2dfd45c65068ae9
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=27259 bytes; lines=322; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-rootfs-mount-smoke.log

- `kind`: log
- `size_bytes`: 11857
- `line_count`: 173
- `sha256`: fd857874c17dbce587c60a66be60e06d75b1843cdbf5c6769a1774a70f55bbda
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=11857 bytes; lines=173; symbolic=_____; tail=[npc-rv64] command: Ubuntu rootfs mount + systemd banner smoke on NpcSimTop make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LIN...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-rootfs-mount-smoke/console.log

- `kind`: log
- `size_bytes`: 6646
- `line_count`: 113
- `sha256`: 049192d39324afe9dde0dcdc0b8e5099206a5f3c0b5d42b96bc7d8a8603630ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=6646 bytes; lines=113; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [0m [1;34m[paddr.c:92 npc_init_mem] physical memory area [0x0000000...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log

- `kind`: log
- `size_bytes`: 7129
- `line_count`: 106
- `sha256`: 6b4894a1a9bc2beecc414bc6a41e44e072efe1312bd9dacc3156bcc6136f79b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=7129 bytes; lines=106; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-rootfs-mount-smoke/npc.log [paddr.c:92 npc_init_mem] physical memory area [0x0000000080000000, 0x000...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-linux-rootfs-mount-smoke/run.log

- `kind`: log
- `size_bytes`: 11781
- `line_count`: 172
- `sha256`: 71ffe74233d75cccedb44b36204c7ff482910efffe7016803944dbe5d369765a
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=11781 bytes; lines=172; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 4
- `sha256`: d1313e7b5ece0af010aed17557ede6cd6d8270d8b818a8e1cb30f032af9fc538
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {}
- `summary`: log evidence; size=349 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-07-24-rv...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287048
- `line_count`: 2103
- `sha256`: 742818ba89c86d22cad0198b24ccd57e42233fde8e69beee67b567c923341d64
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287048 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 35329
- `line_count`: 234
- `sha256`: c9dc907e6c6a35f425b1b453a9701ebf73ed6b24809c45b6959af124ce92c9d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 6, "symbolic": ["_____"]}
- `summary`: log evidence; size=35329 bytes; lines=234; PASS=6; symbolic=_____; tail=[npc-rv64] command: 16550 UART RX register and gated DPI injection smoke make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATI...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 703
- `line_count`: 17
- `sha256`: 857bc2cd3b9eb531588eeb44615ac85027e8e91e1adbe884ab1c5cea7a01eec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=703 bytes; lines=17; PASS=6; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 59ef82b8d34c4d8e27ccd43f2469d2b2ef223c76815ff75606d1b6f620166254
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 5
- `sha256`: 857ba22e03ab8db828b31f0c1b80da79244207c57b4663b9ff3fea212f695a32
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=349 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 343
- `line_count`: 11
- `sha256`: 288df59bc9a14e5b1ee6801688f76d83ffde8c08f5b1fc514ed66ea2e598a84f
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=343 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0b...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 34028
- `line_count`: 212
- `sha256`: 6375db80147ce1133fe98acd0bf4433c094b4070a3c083ca42ed0f1ad9a67778
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=34028 bytes; lines=212; symbolic=_____; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] rv64 linux defconfig up to date make -C '/home/lyg/PA/ysyx-workbench/npc/rv64' -j'14' CXX='/usr/bin/clang++' LINK='/usr/bin/clang++' VERILATOR_OPT_FAST='-O3 -march=native' VERILATOR_OPT_GL...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/runtime/console.log

- `kind`: log
- `size_bytes`: 28938
- `line_count`: 153
- `sha256`: 084ecac729cdd894e3e5d1107a8efbda40f62645fce611e1d8f98d7094b8f47a
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=28938 bytes; lines=153; symbolic=_____; tail=[1;34m[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [0m [1;34m[paddr.c:92 npc_init_mem] physical memory area [0x0000000080...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log

- `kind`: log
- `size_bytes`: 27403
- `line_count`: 148
- `sha256`: 6c42cfcfbe00f6d8d9c7acdac5a8d3f5f32e06438295f4bd8b5ba1bc8b9a8492
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"symbolic": ["_____"]}
- `summary`: log evidence; size=27403 bytes; lines=148; symbolic=_____; tail=[log.c:145 npc_init_log] Log is written to /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-rv64-uart-rx-smoke/runtime/npc.log [paddr.c:92 npc_init_mem] physical memory area [0x0000000080000000, 0x000000...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9442
- `line_count`: 159
- `sha256`: 1f6e84e4f7f8efc27ce3b0e4c3182c682876161640e700579369cd8d605143c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 306}
- `summary`: log evidence; size=9442 bytes; lines=159; PASS=306; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-3/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T13:13:18+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
