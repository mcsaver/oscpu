# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-env-observability-trace
- `task_slug`: agent-env-observability-trace
- `profile`: agent-system
- `asset_count`: 7
- `total_size_bytes`: 16887

## 证据资产

### .github/task-runs/2026-06-13-agent-env-observability-trace/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-env-observability-trace/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-env-observability-trace/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3337
- `line_count`: 68
- `sha256`: 868456af2a45ef2f9d4dfb3145e62c45f30a18269a56282e24253d078aa6065c
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {"PASS": 122}
- `summary`: log evidence; size=3337 bytes; lines=68; PASS=122; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agent-env-observ...

### .github/task-runs/2026-06-13-agent-env-observability-trace/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 4984
- `line_count`: 73
- `sha256`: 6470f3fd97ea96fbcd01ba4a2da9ff6ec021bee6d7b14b92f536b39b883f9e23
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {"PASS": 98}
- `summary`: log evidence; size=4984 bytes; lines=73; PASS=98; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agen...

### .github/task-runs/2026-06-13-agent-env-observability-trace/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-env-observability-trace/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1190
- `line_count`: 5
- `sha256`: da398ef2669b9627abfdcde46b14b750cd98de88dc24a44b63cd04ebdfcf0e7d
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {"PASS": 10}
- `summary`: tsv evidence; size=1190 bytes; lines=5; PASS=10; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-agent-env-observability-trace/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env +...

### .github/task-runs/2026-06-13-agent-env-observability-trace/run-manifest.json

- `kind`: json
- `size_bytes`: 3725
- `line_count`: 94
- `sha256`: deeb5aad30c093672368a6626293314d3f19a6dd10757bd01e9e0170bfaf8935
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:29:02+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=3725 bytes; lines=94; PASS=12; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-13-agent-env-observability-trace/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-13-agent-env-observability-trace/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-06-13-agen...
