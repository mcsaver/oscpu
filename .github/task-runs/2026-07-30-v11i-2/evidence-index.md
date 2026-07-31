# Evidence Index

## 基本信息

- `task_id`: 2026-07-30-v11i-2
- `task_slug`: v11i
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 20871

## 证据资产

### .github/task-runs/2026-07-30-v11i-2/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-30T04:25:48+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-30-v11i-2/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: b81710781999d78a3049746d4752c013768f583054263d54b9cb7e3f1a099c8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-30T04:25:48+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=131 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-30-v11i-2/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-30T04:25:48+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-30-v11i-2/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9664
- `line_count`: 164
- `sha256`: 793533c34b5302c313fbb9673807309817a1a10a08cb23242825973f371bc6ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-30T04:25:48+00:00
- `markers`: {"PASS": 314}
- `summary`: log evidence; size=9664 bytes; lines=164; PASS=314; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-30-v11i-2/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 8017
- `line_count`: 103
- `sha256`: 28249657faf0cd3b1bfc04a1058ea6eed3fcd7d377940dcc1d1f01f1f6db03cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-30T04:25:48+00:00
- `markers`: {"FAIL": 2, "PASS": 124}
- `summary`: log evidence; size=8017 bytes; lines=103; FAIL=2; PASS=124; tail=[agent-system] three-layer AI environment contract PASS AI_ENVIRONMENT.md PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuild-matrix.json PASS...

### .github/task-runs/2026-07-30-v11i-2/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-30T04:25:48+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
