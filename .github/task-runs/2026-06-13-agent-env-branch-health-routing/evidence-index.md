# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-env-branch-health-routing
- `task_slug`: agent-env-branch-health-routing
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 12924

## 证据资产

### .github/task-runs/2026-06-13-agent-env-branch-health-routing/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:18:16+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-env-branch-health-routing/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:18:16+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-env-branch-health-routing/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3295
- `line_count`: 67
- `sha256`: e0e27f6dd06135ec7327826e5ae19556005c6cca3c3683533ca67b1d80090de3
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:18:16+00:00
- `markers`: {"PASS": 120}
- `summary`: log evidence; size=3295 bytes; lines=67; PASS=120; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agent-env-review...

### .github/task-runs/2026-06-13-agent-env-branch-health-routing/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 4827
- `line_count`: 70
- `sha256`: 391eda4205859edb9040ee6669acae469a4ce04d4643f1884c528eee08521389
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:18:16+00:00
- `markers`: {"FAIL": 2, "PASS": 90}
- `summary`: log evidence; size=4827 bytes; lines=70; FAIL=2; PASS=90; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agen...

### .github/task-runs/2026-06-13-agent-env-branch-health-routing/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:18:16+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-env-branch-health-routing/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1151
- `line_count`: 5
- `sha256`: 1717179aa8a442e34ce38f44ef00cffc1e3162adca9024a73f25132b43047a33
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:18:16+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: tsv evidence; size=1151 bytes; lines=5; FAIL=2; PASS=8; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-agent-env-branch-health-routing/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env...
