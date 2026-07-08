# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3
- `task_slug`: 2026-07-08-iverilog14-tb-gate-restore
- `profile`: am-kernels
- `asset_count`: 7
- `total_size_bytes`: 13931

## 证据资产

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/evidence/abstract-machine-contract.log

- `kind`: log
- `size_bytes`: 277
- `line_count`: 7
- `sha256`: 9018983feab116e6b0c2da111dd09836c1017d250a7041c2318d4492d835408d
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=277 bytes; lines=7; PASS=12; tail=[abstract-machine] contract PASS abstract-machine/Makefile PASS abstract-machine/am/include/am.h PASS abstract-machine/am/include/amdev.h PASS abstract-machine/scripts/riscv32-nemu.mk PASS abstract-machine/scripts/riscv32-npc.mk PASS .github/memory/modules/...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/evidence/am-kernels-contract.log

- `kind`: log
- `size_bytes`: 262
- `line_count`: 7
- `sha256`: 2dbe29c9a3b8e88a4026d55eccf0f532c1025b3fb736e27a5431f00bd93ac257
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=262 bytes; lines=7; PASS=12; tail=[am-kernels] contract PASS am-kernels/tests/cpu-tests/Makefile PASS am-kernels/tests/am-tests/Makefile PASS am-kernels/tests/klib-tests/Makefile PASS am-kernels/benchmarks/coremark/Makefile PASS scripts/am-regression.sh PASS .github/memory/modules/am-kernel...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4823
- `line_count`: 92
- `sha256`: 3d32a4d0a2aa34f0edf7030c55c46d4d72f920271cff5d1bcbb5590fb44db0d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {"PASS": 168}
- `summary`: log evidence; size=4823 bytes; lines=92; PASS=168; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2637
- `line_count`: 41
- `sha256`: 689c1d0186568a32558ef4cad25d98fa6641cdbb98eaaa95060a6de90dd86373
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2637 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1168
- `line_count`: 5
- `sha256`: e94574ed37fd46bf6384f101aed3df635b56ceb6d1e3db114984c77fb0307274
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1168 bytes; lines=5; PASS=10; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS a...

### .github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/run-manifest.json

- `kind`: json
- `size_bytes`: 4274
- `line_count`: 112
- `sha256`: c990b0773a1e4123fdcdb4730ca2ffdb92d86b2db7d3a331b26ee955cc7a88e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-08T03:39:07+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=4274 bytes; lines=112; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-08-2026-07-08-iverilog14-tb-gate-restore-3/dispatch-log.md", "evidence_dir": ".github/task-...
