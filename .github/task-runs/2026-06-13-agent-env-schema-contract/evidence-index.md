# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-env-schema-contract
- `task_slug`: agent-env-schema-contract
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 11040

## 证据资产

### .github/task-runs/2026-06-13-agent-env-schema-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-env-schema-contract/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:08:37+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-env-schema-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3210
- `line_count`: 65
- `sha256`: e3c18d271b1615d0d23d44b8f84b7533a472ea792675ec06a48b8e9c34ad2c78
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:08:37+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=3210 bytes; lines=65; PASS=116; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agentic-hardware...

### .github/task-runs/2026-06-13-agent-env-schema-contract/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 3009
- `line_count`: 41
- `sha256`: 5af1f3252d32e4d2b8ba757a79930808c8aba0e908c4c1298f0178dbd1ea6fa9
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:08:37+00:00
- `markers`: {"PASS": 80}
- `summary`: log evidence; size=3009 bytes; lines=41; PASS=80; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/inst...

### .github/task-runs/2026-06-13-agent-env-schema-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:08:37+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-env-schema-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1170
- `line_count`: 5
- `sha256`: 5c6217d2df7b3cfca2dea8edbaccb39ca85b50c5c188089bcb83d4596e1cd30d
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:08:37+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1170 bytes; lines=5; PASS=10; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-agent-env-schema-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env + bas...
