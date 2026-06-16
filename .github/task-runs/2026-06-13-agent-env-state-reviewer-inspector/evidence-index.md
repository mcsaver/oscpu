# Evidence Index

## 基本信息

- `task_id`: 2026-06-13-agent-env-state-reviewer-inspector
- `task_slug`: agent-env-state-reviewer-inspector
- `profile`: agent-system
- `asset_count`: 9
- `total_size_bytes`: 20222

## 证据资产

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/profile-index.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 38
- `sha256`: efb8767a33a5fcb6ed03e315dac8fa2c4ea2ed741cb2dbca59d14b44e8c04338
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {}
- `summary`: log evidence; size=627 bytes; lines=38; markers=<none>; tail=[agent-system] e2e profiles abstract-machine.tsv agent-system.tsv am-kernels.tsv contracts.tsv difftest.tsv digital-logic.tsv discovery.tsv display-vga.tsv fceux-am.tsv full.tsv github-index.tsv hardware-flow.tsv linux-device.tsv nemu-dev-full-gate.tsv nemu...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3384
- `line_count`: 69
- `sha256`: 069e8a3366d5b62e536efc7361e9984eba54b7e1f6040cb6afb905608430fc5f
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 124}
- `summary`: log evidence; size=3384 bytes; lines=69; PASS=124; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agent-env-observ...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/reviewer-inspector-gate.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 9
- `sha256`: 2023aa52d5ec1a2028fef8e4d48ccf16c64630f0ab23951ab67c47c39bf99947
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=491 bytes; lines=9; PASS=16; tail=[agent-system] reviewer/inspector execution gate PASS .github/e2e/profiles/agent-system.tsv PASS .github/agent-env-review-routing.json PASS .github/agent-env-policy.json PASS .github/agent-env-state-traceability.json PASS agent-system profile executes state...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/state-machine-traceback.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 7
- `sha256`: db566d84e10a7fed301505bc2f29427a2fc04543aa41548c59644c46a1406192
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=412 bytes; lines=7; PASS=12; tail=[agent-system] state machine traceback PASS .github/instructions/agent-env-state-machine.instructions.md PASS .github/agent-env-state-traceability.json PASS scripts/e2e/lib/report.sh PASS state machine instruction covers executable states and state_tracebac...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 5159
- `line_count`: 76
- `sha256`: 5e712b03a4079cb07793f3d5e936f8116aeeb8abf4eeed3a28c7bbbba681271b
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 104}
- `summary`: log evidence; size=5159 bytes; lines=76; PASS=104; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agen...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/nodes.tsv

- `kind`: tsv
- `size_bytes`: 1882
- `line_count`: 7
- `sha256`: aa736f65e0f58192b29df1ea20f01105549755253c9390e1faafa59cdb564b1c
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 14}
- `summary`: tsv evidence; size=1882 bytes; lines=7; PASS=14; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-...

### .github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/run-manifest.json

- `kind`: json
- `size_bytes`: 5243
- `line_count`: 130
- `sha256`: a16412bc248cf3b4577c68f339c3a9f4aa6cfccc189e8a72ee18692dc2dd3f11
- `encoding`: utf-8
- `indexed_at`: 2026-06-13T13:40:56+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=5243 bytes; lines=130; PASS=16; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-13-agent-env-state-reviewer-inspector/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-...
