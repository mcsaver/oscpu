# Evidence Index

## 基本信息

- `task_id`: 2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l
- `task_slug`: rv64-functional-aggregate-good-trap-revtag-v9l
- `profile`: am-kernels
- `asset_count`: 7
- `total_size_bytes`: 13171

## 证据资产

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/abstract-machine-contract.log

- `kind`: log
- `size_bytes`: 277
- `line_count`: 7
- `sha256`: 9018983feab116e6b0c2da111dd09836c1017d250a7041c2318d4492d835408d
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=277 bytes; lines=7; PASS=12; tail=[abstract-machine] contract PASS abstract-machine/Makefile PASS abstract-machine/am/include/am.h PASS abstract-machine/am/include/amdev.h PASS abstract-machine/scripts/riscv32-nemu.mk PASS abstract-machine/scripts/riscv32-npc.mk PASS .github/memory/modules/...

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/am-kernels-contract.log

- `kind`: log
- `size_bytes`: 262
- `line_count`: 7
- `sha256`: 2dbe29c9a3b8e88a4026d55eccf0f532c1025b3fb736e27a5431f00bd93ac257
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=262 bytes; lines=7; PASS=12; tail=[am-kernels] contract PASS am-kernels/tests/cpu-tests/Makefile PASS am-kernels/tests/am-tests/Makefile PASS am-kernels/tests/klib-tests/Makefile PASS am-kernels/benchmarks/coremark/Makefile PASS scripts/am-regression.sh PASS .github/memory/modules/am-kernel...

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9442
- `line_count`: 159
- `sha256`: b31a5dd431a915df7e47f4537ab9c52bce194ff027496140a3c275f1d005105b
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {"PASS": 306}
- `summary`: log evidence; size=9442 bytes; lines=159; PASS=306; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-22-rv64-functional-aggregate-good-trap-revtag-v9l/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T15:27:20+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
