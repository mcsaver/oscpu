# Evidence Index

## 基本信息

- `task_id`: 2026-07-28-rv64-a3-checker-replay
- `task_slug`: rv64-a3-checker-replay
- `profile`: rv64-systemd-contract
- `asset_count`: 3
- `total_size_bytes`: 20302

## 证据资产

### .github/task-runs/2026-07-28-rv64-a3-checker-replay/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: b81710781999d78a3049746d4752c013768f583054263d54b9cb7e3f1a099c8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T09:52:05+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=131 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-28-rv64-a3-checker-replay/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 10853
- `line_count`: 101
- `sha256`: b95645ef4400bd771be93f8a955f111b8b639195e3562326947ea5a63a34ff3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T09:52:05+00:00
- `markers`: {"PASS": 32, "symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: log evidence; size=10853 bytes; lines=101; PASS=32; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/scripts/npc-systemd-strict-check.sh PASS Linux/scripts/npc_systemd_transaction_evidence.py PASS Linux/scripts/tests/test_npc_systemd_strict_ch...

### .github/task-runs/2026-07-28-rv64-a3-checker-replay/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 9361
- `line_count`: 63
- `sha256`: e4fa4aa81f273e6d7248dcd8ccc4541cf75d76284a0f2020f12382986d90251c
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T09:52:05+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: log evidence; size=9361 bytes; lines=63; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=191:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 192:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 193:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 194:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 195:NPC_SYSTEMD_UART_WAIT ?= $(NPC_SYSTEMD_P...
