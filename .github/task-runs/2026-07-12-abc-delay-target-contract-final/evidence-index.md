# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-abc-delay-target-contract-final
- `task_slug`: abc-delay-target-contract-final
- `profile`: yosys-sta
- `asset_count`: 7
- `total_size_bytes`: 10132

## 证据资产

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/npc-sim-contract.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 13
- `sha256`: 07df703bcae3b6b323fa0a88643baaff9021c04b3682a9afa5d9f100a115bfd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=404 bytes; lines=13; PASS=22; tail=[npc] sim contract PASS npc/sim/Makefile PASS npc/sim/backends/single.mk PASS npc/sim/backends/rv64.mk PASS npc/sim/backends/soc.mk PASS npc/single/Makefile PASS npc/soc/Makefile PASS npc/rv64/Makefile PASS .github/e2e/profiles/npc-dev.tsv PASS .github/e2e/...

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/npc-single-contract.log

- `kind`: log
- `size_bytes`: 142
- `line_count`: 5
- `sha256`: 9d998f2fba2831128acf902dd6130d042f60ab2fa22c87422dc9e39dbf93c773
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=142 bytes; lines=5; PASS=8; tail=[npc-single] contract PASS npc/single/Makefile PASS npc/single/Kconfig PASS npc/single/vsrc/filelist.mk PASS npc/single/csrc/cpu/cpu-exec.cpp

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 5798
- `line_count`: 107
- `sha256`: f707f351087e9cc8a22a0421b03111ebb978ce52c81411ae4eee5afb25996ca8
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {"PASS": 198}
- `summary`: log evidence; size=5798 bytes; lines=107; PASS=198; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/yosys-sta-contract-fail-closed.log

- `kind`: log
- `size_bytes`: 131
- `line_count`: 3
- `sha256`: 00f621c5d23ea8dfdcbf8a8ff90f655bf6a08216dcc2f96099b3074a5f09f319
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=131 bytes; lines=3; PASS=4; tail=[yosys-sta] contract failure propagation PASS yosys-sta required-file failure propagates PASS yosys-sta checker failure propagates

### .github/task-runs/2026-07-12-abc-delay-target-contract-final/evidence/yosys-sta-contract.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 16
- `sha256`: 3878079dbc3a2032f57417ae4561b087b1dd8ae9411f5d6b59b3ccde46db01eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T18:07:22+00:00
- `markers`: {"PASS": 14, "WARN": 2}
- `summary`: log evidence; size=560 bytes; lines=16; WARN=2; PASS=14; tail=[yosys-sta] contract PASS yosys-sta/Makefile PASS yosys-sta/scripts/check_abc_delay_target_contract.py PASS yosys-sta/scripts/test_abc_delay_target_contract.py PASS .github/agents/yosys-sta.agent.md PASS .github/memory/modules/yosys-sta.md .... ------------...
