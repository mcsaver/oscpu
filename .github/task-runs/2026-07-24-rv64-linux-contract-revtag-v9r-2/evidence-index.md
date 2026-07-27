# Evidence Index

## 基本信息

- `task_id`: 2026-07-24-rv64-linux-contract-revtag-v9r-2
- `task_slug`: rv64-linux-contract-revtag-v9r
- `profile`: rv64-linux
- `asset_count`: 15
- `total_size_bytes`: 467668

## 证据资产

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 155
- `line_count`: 6
- `sha256`: 17664962cd1567c20052fc78a70a50660d0c6219630a67f825e1ab8278230ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=155 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/history/study/README.md PASS Linux/README.md

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-linux-focused-smokes.log

- `kind`: log
- `size_bytes`: 27597
- `line_count`: 328
- `sha256`: 51c4a1d30696d55b17921fbc95b2b5b2e6d1ab29ec444817eafd04d388226e17
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"GOOD_TRAP": 10}
- `summary`: log evidence; size=27597 bytes; lines=328; GOOD_TRAP=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/Linux' [Linux] NPC sim exists: /home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop make -C '/home/lyg/PA/ysyx-workbench/Linux/tools' NPC_SIM='/home/lyg/PA/ysyx-workbench/npc/rv64/build/NpcSimTop' smoke-...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 4
- `sha256`: 5b3f85ff1707cfbc7aeef2db835a13955a0200700df624f7034d6728a6accfc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {}
- `summary`: log evidence; size=349 bytes; lines=4; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [npc-rv64] evidence=.github/task-runs/2026-07-24-rv...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287048
- `line_count`: 2103
- `sha256`: 742818ba89c86d22cad0198b24ccd57e42233fde8e69beee67b567c923341d64
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287048 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke.log

- `kind`: log
- `size_bytes`: 69413
- `line_count`: 757
- `sha256`: fddd6371a72fd071ee71546fc74b1ea9dbda72a2d2f19cd60d6701e068cc3cf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=69413 bytes; lines=757; PASS=3; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/OooFpDecode.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchStaticClassify.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke/module-testbench.log

- `kind`: log
- `size_bytes`: 703
- `line_count`: 17
- `sha256`: bca35c9cb636c67e172ea971e5e85cbea9889fa27eee4f158c028e050a5557aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=703 bytes; lines=17; PASS=6; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 59ef82b8d34c4d8e27ccd43f2469d2b2ef223c76815ff75606d1b6f620166254
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 5
- `sha256`: 857ba22e03ab8db828b31f0c1b80da79244207c57b4663b9ff3fea212f695a32
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=349 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 343
- `line_count`: 11
- `sha256`: c156e1b03575ab731892e8a757cb1fcf57341bb85b6976b2bdda7ffd6f753a56
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=343 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0b...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-rv64-uart-rx-smoke/runtime.log

- `kind`: log
- `size_bytes`: 68637
- `line_count`: 739
- `sha256`: 21824be643d2eb88028ec07f52cbcfd5c1ba5492a9fa02825b0dd7f71b460542
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {}
- `summary`: log evidence; size=68637 bytes; lines=739; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/OooFpDecode.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchStaticClassify.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchHeadClassifyGate.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9442
- `line_count`: 159
- `sha256`: e8b4d435a75a2fd223484dc01498be8323cd354446894d49899ad8cef4238bbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 306}
- `summary`: log evidence; size=9442 bytes; lines=159; PASS=306; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-24-rv64-linux-contract-revtag-v9r-2/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-24T12:38:02+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
