# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-env-policy-ci-contract
- `task_slug`: agent-env-policy-ci-contract
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 10296

## 证据资产

### .github/task-runs/2026-06-13-agent-env-policy-ci-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:50:49+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-env-policy-ci-contract/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:50:49+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-env-policy-ci-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3057
- `line_count`: 62
- `sha256`: bbbf81903482d731b214b9acd5613030e80e03cd7328184e1760fd6e91f6d98f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:50:49+00:00
- `markers`: {"PASS": 110}
- `summary`: log evidence; size=3057 bytes; lines=62; PASS=110; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agent-env-policy.json PASS .github/agentic-hardware-blueprint.md PASS .github/instructions/agent-env-layer-contract.instructions.md PASS ....

### .github/task-runs/2026-06-13-agent-env-policy-ci-contract/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 2403
- `line_count`: 33
- `sha256`: b5da9aae1132dabe55fa358f20af9a69846d18fee7e3880dec243aea95618115
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:50:49+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=2403 bytes; lines=33; PASS=64; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/agent-env-policy.json PASS .github/skills/agent-env-maintenance/SKILL.md PASS .github/workflows/agent-maintain.yml PASS script...

### .github/task-runs/2026-06-13-agent-env-policy-ci-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:50:49+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-env-policy-ci-contract/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1185
- `line_count`: 5
- `sha256`: 7260adc2b31f41bbb82e0ca3be638eea739b1c8a7c3b370f29c99bbb31df3b7e
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T12:50:49+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1185 bytes; lines=5; PASS=10; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-agent-env-policy-ci-contract/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env +...
