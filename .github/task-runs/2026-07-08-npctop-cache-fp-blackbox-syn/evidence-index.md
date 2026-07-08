# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-npctop-cache-fp-blackbox-syn
- `task_slug`: 
- `profile`: 
- `asset_count`: 3
- `total_size_bytes`: 21764065

## 证据资产

### .github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn/evidence/NpcTop-cache-fp-blackbox-full.log.gz

- `kind`: gz
- `size_bytes`: 21763600
- `line_count`: 60729
- `sha256`: 98620c7745b0b869cda0fd0cd1db6bc6c150fc21d9ae53b7780137e098f8ef40
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T21:06:04+00:00
- `markers`: {}
- `summary`: gz evidence; size=21763600 bytes; lines=60729; markers=<none>; tail=}h� m���>�ч6��F ��C }h� m���>�ч6��F ��C }h� m���>�ч6��F ��C }h� m���>�ч6��F ��C }h� m���>�ч6��F ��C }h� m���>�ч6��F ��C }h� m���>�ч6��F ��C }h� m���>�ч6��F ��S }j�Om���>�ѧ6��F���S }j�Om���>�ѧ6��F���S }j�Om���>�ѧ6��F���S }j�Om���>�ѧ6��F���S }j�Om���>�ѧ6��F��...

### .github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn/evidence/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T21:06:04+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn/run_npctop_cache_fp_blackbox.sh

- `kind`: sh
- `size_bytes`: 465
- `line_count`: 15
- `sha256`: 5ae0c9486a26aaf9a56f2a3b3b0dc387c2d5f3785bd8b19c4202882ea90fa5b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T21:06:04+00:00
- `markers`: {}
- `summary`: sh evidence; size=465 bytes; lines=15; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail ROOT=/home/lyg/PA/ysyx-workbench TASK_DIR="$ROOT/.github/task-runs/2026-07-08-npctop-cache-fp-blackbox-syn" EVIDENCE_DIR="$TASK_DIR/evidence" mkdir -p "$EVIDENCE_DIR" timeout 900s make -B -C "$ROOT/npc/rv64" syn \ STA_D...
