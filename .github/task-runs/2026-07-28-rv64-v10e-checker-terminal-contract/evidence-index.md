# Evidence Index

## 基本信息

- `task_id`: 2026-07-28-rv64-v10e-checker-terminal-contract
- `task_slug`: rv64-v10e-checker-terminal-contract
- `profile`: rv64-systemd-contract
- `asset_count`: 7
- `total_size_bytes`: 32975

## 证据资产

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/agent-system-sanitizer-probe/trailing-blank-lines.md

- `kind`: md
- `size_bytes`: 5
- `line_count`: 1
- `sha256`: c73b73af8851e9e91bc6b4dc12e7dace0a2bfb931c1d0b8b36ef367319f58cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {}
- `summary`: md evidence; size=5 bytes; lines=1; markers=<none>; tail=line

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: b81710781999d78a3049746d4752c013768f583054263d54b9cb7e3f1a099c8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=131 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 10858
- `line_count`: 101
- `sha256`: e3d92250a13d3b07021b877e33b057de2cf8e289e48f97d7206be3cacaa1182d
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {"PASS": 32, "symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: log evidence; size=10858 bytes; lines=101; PASS=32; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/scripts/npc-systemd-strict-check.sh PASS Linux/scripts/npc_systemd_transaction_evidence.py PASS Linux/scripts/tests/test_npc_systemd_strict_ch...

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 9361
- `line_count`: 63
- `sha256`: e4fa4aa81f273e6d7248dcd8ccc4541cf75d76284a0f2020f12382986d90251c
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: log evidence; size=9361 bytes; lines=63; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=191:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 192:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 193:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 194:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 195:NPC_SYSTEMD_UART_WAIT ?= $(NPC_SYSTEMD_P...

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/npc-sim-status.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 9
- `sha256`: 82bab21e2cc2d8e36247fdc668ed2de2053823df4683786d7c234549ab7fc7fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {}
- `summary`: log evidence; size=490 bytes; lines=9; markers=<none>; tail=[hardware-flow] command: make -C npc/sim status make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' [npc-sim] selected backend: rv64 [npc-sim] backend directory: /home/lyg/PA/ysyx-workbench/npc/rv64 [npc-sim] backend description: RV64 NpcSimTop s...

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/recall-discovery.log

- `kind`: log
- `size_bytes`: 9566
- `line_count`: 162
- `sha256`: c7c521e59974cd5d58486ce114df389f5eade081d58786dd63c472c560dd44db
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {"FAIL": 2, "PASS": 308}
- `summary`: log evidence; size=9566 bytes; lines=162; FAIL=2; PASS=308; tail=[agent-system] discovery files PASS AGENTS.md PASS AI_ENVIRONMENT.md PASS .github/AGENTS.md PASS .github/copilot-instructions.md PASS .github/ai-env/README.md PASS .github/ai-env/contracts/agent-env-policy.json PASS .github/ai-env/contracts/agent-env-rebuil...

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract/evidence/tool-env-check.log

- `kind`: log
- `size_bytes`: 2607
- `line_count`: 41
- `sha256`: c4e47ace660473deb3861a1231495072f971f26ec5c2f8f0be0e08effb70b4aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:04:38+00:00
- `markers`: {"PASS": 52, "WARN": 2}
- `summary`: log evidence; size=2607 bytes; lines=41; WARN=2; PASS=52; tail=[e2e] required tools PASS bash /usr/bin/bash PASS git /usr/bin/git PASS make /usr/bin/make PASS python3 /usr/bin/python3 PASS gcc /usr/bin/gcc PASS g++ /usr/bin/g++ PASS timeout /usr/bin/timeout [e2e] optional tools PASS rg /usr/bin/rg PASS verilator /home/...
