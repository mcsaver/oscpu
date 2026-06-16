# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-system-dev-isolation-final
- `task_slug`: agent-system-dev-isolation-final
- `profile`: agent-system
- `asset_count`: 5
- `total_size_bytes`: 7349

## 证据资产

### .github/task-runs/2026-06-13-agent-system-dev-isolation-final/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:58:28+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-system-dev-isolation-final/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:58:28+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-system-dev-isolation-final/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 2831
- `line_count`: 57
- `sha256`: 91fbfb75fb4a2e513bf61a7d9618bf5b16762561087939da90834ab5f1e7e751
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:58:28+00:00
- `markers`: {"PASS": 100}
- `summary`: log evidence; size=2831 bytes; lines=57; PASS=100; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/memory-protocol.instructions.md PASS .github/instructions/agent-e2e-workflow.instr...

### .github/task-runs/2026-06-13-agent-system-dev-isolation-final/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:58:28+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-system-dev-isolation-final/nodes.tsv

- `kind`: tsv
- `size_bytes`: 867
- `line_count`: 4
- `sha256`: 2bdbc8ed23ff3d066e44c685340619774489a655711ff972c75efaaf39746abf
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T07:58:28+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=867 bytes; lines=4; PASS=8; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-agent-system-dev-isolation-final/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-en...
