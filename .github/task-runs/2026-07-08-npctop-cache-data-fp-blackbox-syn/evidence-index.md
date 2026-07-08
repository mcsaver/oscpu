# Evidence Index

## 基本信息

- `task_id`: 2026-07-08-npctop-cache-data-fp-blackbox-syn
- `task_slug`: 
- `profile`: 
- `asset_count`: 3
- `total_size_bytes`: 20269413

## 证据资产

### .github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn/evidence/NpcTop-cache-data-fp-blackbox-full.log.gz

- `kind`: gz
- `size_bytes`: 20268920
- `line_count`: 66423
- `sha256`: bf86d028bb6286172b48c0a760de09d65c935e38a2b769d57b671e9c76319a40
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-07T21:38:24+00:00
- `markers`: {}
- `summary`: gz evidence; size=20268920 bytes; lines=66423; markers=<none>; tail=� �A=6� ���� xb����� ��̿߇��O�� �u�t G 2�v >e<���y<�͑� N��s� ����������߇��'�ߙϗ � �v � ����ˇ �O��3�/ >.>��>� ĉ�w����/B�x g>_�z 6���g��;��rdm� ���ˑ� N�� � q����|��+ '�ߙϗ3�� Yc���;��r���#� �x g>_�|�{d��������G� 8���|���~��r ��ߙ�w�,8p����|9���5 N��#� �x �=_�,;p�...

### .github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn/evidence/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T21:38:24+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn/run_npctop_cache_data_fp_blackbox.sh

- `kind`: sh
- `size_bytes`: 493
- `line_count`: 15
- `sha256`: 9f7c32062cf88c972399c2fa90a5ebc5b547b726cb93f49d46ee69630606ff4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-07T21:38:24+00:00
- `markers`: {}
- `summary`: sh evidence; size=493 bytes; lines=15; markers=<none>; tail=#!/usr/bin/env bash set -euo pipefail ROOT=/home/lyg/PA/ysyx-workbench TASK_DIR="$ROOT/.github/task-runs/2026-07-08-npctop-cache-data-fp-blackbox-syn" EVIDENCE_DIR="$TASK_DIR/evidence" mkdir -p "$EVIDENCE_DIR" timeout 1200s make -B -C "$ROOT/npc/rv64" syn \...
