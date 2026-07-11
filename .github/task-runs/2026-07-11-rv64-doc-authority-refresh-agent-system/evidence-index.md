# Evidence Index

## 基本信息

- `task_id`: 2026-07-11-rv64-doc-authority-refresh-agent-system
- `task_slug`: rv64-doc-authority-refresh-agent-system
- `profile`: agent-system
- `asset_count`: 6
- `total_size_bytes`: 19312

## 证据资产

### .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T08:38:20+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4823
- `line_count`: 92
- `sha256`: 3d32a4d0a2aa34f0edf7030c55c46d4d72f920271cff5d1bcbb5590fb44db0d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T08:38:20+00:00
- `markers`: {"PASS": 168}
- `summary`: log evidence; size=4823 bytes; lines=92; PASS=168; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/evidence/three-layer-contract.log

- `kind`: log
- `size_bytes`: 6290
- `line_count`: 92
- `sha256`: 806cf1a92a7e43bcacc136322a95418b1165598fde77d710882cf82bf7baafb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T08:38:20+00:00
- `markers`: {"FAIL": 2, "PASS": 114}
- `summary`: log evidence; size=6290 bytes; lines=92; FAIL=2; PASS=114; tail=[agent-system] three-layer AI environment contract PASS .github/instructions/agent-env-layer-contract.instructions.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuild-matrix.json PASS .github/ai-env/contrac...

### .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T08:38:20+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/nodes.tsv

- `kind`: tsv
- `size_bytes`: 999
- `line_count`: 4
- `sha256`: 4dcaf1c7c65ff67d92de7151639860262b0c15273125d2abb3a720221d682d11
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T08:38:20+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: tsv evidence; size=999 bytes; lines=4; FAIL=2; PASS=6; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS a...

### .github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/run-manifest.json

- `kind`: json
- `size_bytes`: 4103
- `line_count`: 104
- `sha256`: 192a7d1f09d5e2823a864867b181353ff7e0e2e13093ab3412ec807ee16a442e
- `encoding`: utf-8
- `indexed_at`: 2026-07-11T08:38:20+00:00
- `markers`: {"FAIL": 4, "PASS": 8}
- `summary`: json evidence; size=4103 bytes; lines=104; FAIL=4; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-11-rv64-doc-authority-refresh-agent-system/dispatch-log.md", "evidence_dir": ".github/task-...
