# Evidence Index

## 基本信息

- `task_id`: 2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2
- `task_slug`: ownership-rv64-memory-functional-aggregate-revtag-v9l
- `profile`: difftest
- `asset_count`: 10
- `total_size_bytes`: 17980

## 证据资产

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/abstract-machine-contract.log

- `kind`: log
- `size_bytes`: 277
- `line_count`: 7
- `sha256`: 9018983feab116e6b0c2da111dd09836c1017d250a7041c2318d4492d835408d
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=277 bytes; lines=7; PASS=12; tail=[abstract-machine] contract PASS abstract-machine/Makefile PASS abstract-machine/am/include/am.h PASS abstract-machine/am/include/amdev.h PASS abstract-machine/scripts/riscv32-nemu.mk PASS abstract-machine/scripts/riscv32-npc.mk PASS .github/memory/modules/...

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/difftest-contract.log

- `kind`: log
- `size_bytes`: 156
- `line_count`: 5
- `sha256`: 6a44b7bccd144459c2b227368465b564133be84d945c999fbcfad07a9e9f0fe7
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=156 bytes; lines=5; PASS=8; tail=[difftest] contract PASS nemu/tools/spike-diff/Makefile PASS npc/sim/Makefile PASS .github/memory/modules/difftest.md PASS .github/agents/difftest.agent.md

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/nemu-add-smoke.log

- `kind`: log
- `size_bytes`: 4530
- `line_count`: 48
- `sha256`: ef1b4c0942afee1d56190fd20bfd32f24412c571ed0fb552598618d708c5b2eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=4530 bytes; lines=48; GOOD_TRAP=2; tail=[nemu] command: cpu-tests add ARCH=riscv64-nemu make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/tests/cpu-tests' # Building add-run [riscv64-nemu] make[2]:...

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/nemu-config-probe.log

- `kind`: log
- `size_bytes`: 255
- `line_count`: 8
- `sha256`: 645a9655f6527b8ae4410a96a9aa1fa324afadfae1733fdbf91967ade493c9a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=255 bytes; lines=8; PASS=12; tail=[nemu] config summary nemu/.config isa=riscv64 target=NATIVE_ELF PASS nemu/Kconfig PASS nemu/Makefile PASS nemu/configs/riscv32-am_defconfig PASS nemu/configs/riscv64-am_defconfig PASS nemu/configs/riscv64-linux_defconfig PASS nemu/src/device/filelist.mk

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/nemu-reference-config-contract.log

- `kind`: log
- `size_bytes`: 130
- `line_count`: 2
- `sha256`: 1334451561f2efcd06e96c30d8d60339c980d9108bb7eef044ac81567dbc81f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=130 bytes; lines=2; PASS=4; tail=PASS NEMU reference config selector accepts only host-native RISC-V PASS NEMU reference profiles bind host-native smoke semantics

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9442
- `line_count`: 159
- `sha256`: 5ca5172f75558d46564c48c97b4320fae4ebccffbfd8b0b665f1cfa6dd1ed135
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 306}
- `summary`: log evidence; size=9442 bytes; lines=159; PASS=306; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-23-ownership-rv64-memory-functional-aggregate-revtag-v9l-2/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-22T16:13:14+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
