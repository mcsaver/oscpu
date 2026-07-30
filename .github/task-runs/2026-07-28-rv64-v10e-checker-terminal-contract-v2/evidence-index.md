# Evidence Index

## 基本信息

- `task_id`: 2026-07-28-rv64-v10e-checker-terminal-contract-v2
- `task_slug`: rv64-v10e-checker-terminal-contract-v2
- `profile`: rv64-systemd-contract
- `asset_count`: 3
- `total_size_bytes`: 20310

## 证据资产

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract-v2/evidence/context-live-index-refresh.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: b81710781999d78a3049746d4752c013768f583054263d54b9cb7e3f1a099c8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:07:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=88 bytes; lines=1; PASS=2; tail=PASS rebuild files=131 db=/home/lyg/PA/ysyx-workbench/.github/cache/github-index.sqlite

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract-v2/evidence/npc-rv64-systemd-guest-check-contract.log

- `kind`: log
- `size_bytes`: 10861
- `line_count`: 101
- `sha256`: e3f18afd661aa818db65117052a8a9fe249df500d773de8a0450c09e6334fb49
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:07:04+00:00
- `markers`: {"PASS": 32, "symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: log evidence; size=10861 bytes; lines=101; PASS=32; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=[npc-rv64] contract: NPC systemd guest prompt/script gate PASS Linux/scripts/check-npc-systemd-guest.sh PASS Linux/scripts/npc-systemd-strict-check.sh PASS Linux/scripts/npc_systemd_transaction_evidence.py PASS Linux/scripts/tests/test_npc_systemd_strict_ch...

### .github/task-runs/2026-07-28-rv64-v10e-checker-terminal-contract-v2/evidence/npc-rv64-systemd-guest-check-contract/make-dry-run.log

- `kind`: log
- `size_bytes`: 9361
- `line_count`: 63
- `sha256`: e4fa4aa81f273e6d7248dcd8ccc4541cf75d76284a0f2020f12382986d90251c
- `encoding`: utf-8
- `indexed_at`: 2026-07-28T07:07:04+00:00
- `markers`: {"symbolic": ["__NPC_CONSOLE_SHELL_READY__"]}
- `summary`: log evidence; size=9361 bytes; lines=63; symbolic=__NPC_CONSOLE_SHELL_READY__; tail=191:NPC_SYSTEMD_CHECK_LOG_DIR ?= $(LOG_ROOT)/riscv64-npc-systemd-guest-check 192:NPC_SYSTEMD_CHECK_MAX_CYCLES ?= 3000000000 193:NPC_SYSTEMD_HOST_TIMEOUT ?= 10800 194:NPC_SYSTEMD_PROMPT ?= root@ysyx-ubuntu2204:~\# 195:NPC_SYSTEMD_UART_WAIT ?= $(NPC_SYSTEMD_P...
