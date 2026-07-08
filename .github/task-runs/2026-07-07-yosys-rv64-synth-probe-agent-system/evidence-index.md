# Evidence Index

## 基本信息

- `task_id`: 2026-07-07-yosys-rv64-synth-probe-agent-system
- `task_slug`: yosys-rv64-synth-probe-agent-system
- `profile`: agent-system
- `asset_count`: 4
- `total_size_bytes`: 11093

## 证据资产

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 4823
- `line_count`: 92
- `sha256`: 3d32a4d0a2aa34f0edf7030c55c46d4d72f920271cff5d1bcbb5590fb44db0d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:32:43+00:00
- `markers`: {"PASS": 168}
- `summary`: log evidence; size=4823 bytes; lines=92; PASS=168; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2657
- `line_count`: 41
- `sha256`: d33b6084db4c976494a83bc504a2f6ca4fd39f182910bb3ef3c75c69829bb682
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:32:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50, "WARN": 2}
- `summary`: log evidence; size=2657 bytes; lines=41; FAIL=2; WARN=2; PASS=50; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/nodes.tsv

- `kind`: tsv
- `size_bytes`: 433
- `line_count`: 2
- `sha256`: 7788f89203ad120b9ed20358275a867564e4c15c52c41259a36a74a653312bec
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:32:43+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: tsv evidence; size=433 bytes; lines=2; FAIL=2; PASS=2; tail=recall-discovery agent-system agent-system PASS AGENTS/copilot/instructions/memory/e2e profiles 规则发现链和 e2e 配置入口存在 .github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/evidence/recall-discovery.log tool-env-check agent-system toolchain FAIL agent...

### .github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/run-manifest.json

- `kind`: json
- `size_bytes`: 3180
- `line_count`: 86
- `sha256`: aae9bca5e23b0417af83be5d32b81cc8eb8f37ef9b024786e058cf647a055863
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T15:32:43+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: json evidence; size=3180 bytes; lines=86; FAIL=4; PASS=4; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/context-brief.md", "dispatch_log": ".github/task-runs/2026-07-07-yosys-rv64-synth-probe-agent-system/dispatch-log.md", "evidence_dir": ".github/task-runs/202...
