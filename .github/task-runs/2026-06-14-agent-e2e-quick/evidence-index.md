# Evidence Index

## 基本信息

- `task_id`: 2026-06-14-agent-e2e-quick
- `task_slug`: agent-e2e-quick
- `profile`: quick
- `asset_count`: 6
- `total_size_bytes`: 11385

## 证据资产

### .github/task-runs/2026-06-14-agent-e2e-quick/evidence/nemu-add-smoke.log

- `kind`: log
- `size_bytes`: 201
- `line_count`: 2
- `sha256`: c33f8c24a70e09ff71763b65509d013e9b774c08ed9adb6ad775b6e85e221acc
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T12:24:22+00:00
- `markers`: {"SKIP": 2}
- `summary`: log evidence; size=201 bytes; lines=2; SKIP=2; tail=[nemu] SKIP: nemu/.config isa=riscv64 target=NATIVE_ELF，不是 CONFIG_TARGET_AM=y [nemu] next: 需要 AM smoke 时先切 riscv32-am_defconfig/riscv64-am_defconfig，或设置 AGENT_E2E_FORCE_SMOKE=1

### .github/task-runs/2026-06-14-agent-e2e-quick/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T12:24:22+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-06-14-agent-e2e-quick/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 3745
- `line_count`: 76
- `sha256`: 1843d84ec0b9e0da58b3916a7cd0365bd3bc4c7a097eb6acf9e8a9c44c68f240
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T12:24:22+00:00
- `markers`: {"FAIL": 2, "PASS": 136}
- `summary`: log evidence; size=3745 bytes; lines=76; FAIL=2; PASS=136; tail=[agent-system] discovery files PASS AGENTS.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/agent-env-policy.json PASS .github/agent-env-rebuild-matrix.json PASS .github/agent-env-schema-contract.json PASS .github/agent-env-observ...

### .github/task-runs/2026-06-14-agent-e2e-quick/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2534
- `line_count`: 41
- `sha256`: 0d05afed8132bd8a90c1c9f78dbb2f1a9a81de054d14a95815da9068bc211789
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T12:24:22+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2534 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /usr/b...

### .github/task-runs/2026-06-14-agent-e2e-quick/nodes.tsv

- `kind`: tsv
- `size_bytes`: 802
- `line_count`: 4
- `sha256`: c5ed90fb443cb6eb0c371a7a23c5667a1e637330d62183fec478f4636377458b
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T12:24:22+00:00
- `markers`: {"FAIL": 2, "PASS": 6, "SKIP": 4}
- `summary`: tsv evidence; size=802 bytes; lines=4; FAIL=2; SKIP=4; PASS=6; tail=recall-discovery agent-system agent-system FAIL AGENTS/copilot/instructions/memory/e2e profiles exit=1 .github/task-runs/2026-06-14-agent-e2e-quick/evidence/recall-discovery.log tool-env-check agent-system toolchain PASS agent-env + bash/git/make/python/gcc...

### .github/task-runs/2026-06-14-agent-e2e-quick/run-manifest.json

- `kind`: json
- `size_bytes`: 3613
- `line_count`: 105
- `sha256`: c934202de77f3b718028a3dcd70462634854f4b075594d5b7421685125e107a6
- `encoding`: utf-8
- `indexed_at`: 2026-06-14T12:24:22+00:00
- `markers`: {"FAIL": 4, "PASS": 8, "SKIP": 6}
- `summary`: json evidence; size=3613 bytes; lines=105; FAIL=4; SKIP=6; PASS=8; tail={ "artifacts": { "context_brief": ".github/task-runs/2026-06-14-agent-e2e-quick/context-brief.md", "dispatch_log": ".github/task-runs/2026-06-14-agent-e2e-quick/dispatch-log.md", "evidence_dir": ".github/task-runs/2026-06-14-agent-e2e-quick/evidence", "evid...
