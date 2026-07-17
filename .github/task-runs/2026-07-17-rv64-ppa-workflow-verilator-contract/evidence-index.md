# Evidence Index

## 基本信息

- `task_id`: 2026-07-17-rv64-ppa-workflow-verilator-contract
- `task_slug`: rv64-ppa-workflow-verilator-contract
- `profile`: verilator-tapeout
- `asset_count`: 6
- `total_size_bytes`: 199268

## 证据资产

### .github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evidence/npc-rv64-contract.log

- `kind`: log
- `size_bytes`: 155
- `line_count`: 6
- `sha256`: 17664962cd1567c20052fc78a70a50660d0c6219630a67f825e1ab8278230ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-17T09:53:24+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=155 bytes; lines=6; PASS=10; tail=[npc-rv64] contract PASS npc/rv64/Makefile PASS npc/rv64/Kconfig PASS npc/rv64/README.md PASS npc/rv64/design/history/study/README.md PASS Linux/README.md

### .github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evidence/npc-rv64-sv39-sret-u-mode.log

- `kind`: log
- `size_bytes`: 542
- `line_count`: 5
- `sha256`: 400d8bd68cf427984c1e8380aa326cdc935089578e8f331bfbc60051412963c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-17T09:53:24+00:00
- `markers`: {}
- `summary`: log evidence; size=542 bytes; lines=5; markers=<none>; tail=[npc-rv64] command: focused Sv39 SRET-to-U-mode regression make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:298: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evide...

### .github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evidence/npc-rv64-sv39-sret-u-mode/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 189676
- `line_count`: 1363
- `sha256`: 3fd66fd7812ff3a4ff1b313767aa30ee6e426e57ba4201d827f062f8e4ece769
- `encoding`: utf-8
- `indexed_at`: 2026-07-17T09:53:24+00:00
- `markers`: {"FAIL": 1, "PASS": 1}
- `summary`: log evidence; size=189676 bytes; lines=1363; FAIL=1; PASS=1; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-17T09:53:24+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 5798
- `line_count`: 107
- `sha256`: f707f351087e9cc8a22a0421b03111ebb978ce52c81411ae4eee5afb25996ca8
- `encoding`: utf-8
- `indexed_at`: 2026-07-17T09:53:24+00:00
- `markers`: {"PASS": 198}
- `summary`: log evidence; size=5798 bytes; lines=107; PASS=198; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-17-rv64-ppa-workflow-verilator-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-17T09:53:24+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
