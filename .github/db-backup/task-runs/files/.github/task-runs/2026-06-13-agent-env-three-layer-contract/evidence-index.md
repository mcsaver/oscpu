# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-env-three-layer-contract
- `task_slug`: agent-env-three-layer-contract
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 8473

## 证据资产

### .github/task-runs/2026-06-13-agent-env-three-layer-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:36:42+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-env-three-layer-contract/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:36:42+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-env-three-layer-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3044
- `line_count`: 61
- `sha256`: 0f77f8406bdab644073865f8796cae271852ceb5628c9093f9cf1bb7c891af30
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:36:42+00:00
- `markers`: {"FAIL": 2, "PASS": 104}
- `summary`: log evidence; size=3044 bytes; lines=61; FAIL=2; PASS=104; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/instructions/memory-protocol...

### .github/task-runs/2026-06-13-agent-env-three-layer-contract/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 10
- `sha256`: 55d31aea3e1af01091192889c6a8f5408f21182b6646e2ba11b80aef2c9616a9
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:36:42+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=618 bytes; lines=10; PASS=18; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/skills/agent-env-maintenance/SKILL.md PASS scripts/agent-maintain.sh PASS layer contract documents Database/Skill/Agent bounda...

### .github/task-runs/2026-06-13-agent-env-three-layer-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:36:42+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-env-three-layer-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1160
- `line_count`: 5
- `sha256`: 59d125201158f36322cc4cac268e08155a074736f7ab020e3bea12d20e970482
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:36:42+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: tsv evidence; size=1160 bytes; lines=5; FAIL=2; PASS=8; tail=recall-discovery agent-system agent-system FAIL AGENTS/copilot/instructions/memory/e2e profiles exit=1 .github/task-runs/2026-06-13-agent-env-three-layer-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env + bash/git/...
