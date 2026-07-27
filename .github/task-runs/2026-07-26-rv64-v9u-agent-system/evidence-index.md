# Evidence Index

## 基本信息

- `task_id`: 2026-07-26-rv64-v9u-agent-system
- `task_slug`: rv64-v9u-agent-system
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 20188

## 证据资产

### .github/task-runs/2026-07-26-rv64-v9u-agent-system/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T12:20:21+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-26-rv64-v9u-agent-system/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: f461c17d41f5758d20d940868e573a03270abbf0b70fc0d2eb3a5378bb43f9f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T12:20:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=130 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-26-rv64-v9u-agent-system/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T12:20:21+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-26-rv64-v9u-agent-system/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9517
- `line_count`: 161
- `sha256`: e86315b056da127e0df68c87be8401789b35e026b378899f3ae4aee57b83907a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T12:20:21+00:00
- `markers`: {"PASS": 310}
- `summary`: log evidence; size=9517 bytes; lines=161; PASS=310; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-26-rv64-v9u-agent-system/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 7481
- `line_count`: 108
- `sha256`: 373473ff7ca67c715ae774d1b31febd47cbfa9c065285b509cc20fee76c2846c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T12:20:21+00:00
- `markers`: {"FAIL": 2, "PASS": 124}
- `summary`: log evidence; size=7481 bytes; lines=108; FAIL=2; PASS=124; tail=[agent-system] three-layer AI environment contract PASS AI_ENVIRONMENT.md PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuild-matrix.json PASS...

### .github/task-runs/2026-07-26-rv64-v9u-agent-system/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T12:20:21+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
