# Evidence Index

## 基本信息

- `task_id`: 2026-08-04-rv64-v14o-cpi-bottleneck-census-v2
- `task_slug`: 
- `profile`: 
- `asset_count`: 6
- `total_size_bytes`: 19658

## 证据资产

### .github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/build.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: b8204a8b819bd3c7c4ce889b6e8d298303f5087d3db595315e26e6531db4185c
- `encoding`: utf-8
- `indexed_at`: 2026-08-04T00:24:39+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[CPI-BOTTLENECK-CENSUS][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 dominant=memory_latency/request_outstanding/axi_write_response candidate_authorized=false ppa=UNQUALIFIED

### .github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/census.json

- `kind`: json
- `size_bytes`: 15550
- `line_count`: 517
- `sha256`: 7b4370116e1fc8507d88eb8543d5a3f67642b02bb218fb76c92566062d0e75b7
- `encoding`: utf-8
- `indexed_at`: 2026-08-04T00:24:39+00:00
- `markers`: {}
- `summary`: json evidence; size=15550 bytes; lines=517; markers=<none>; tail={ "blockers_to_candidate": [ "the dominant residency has not yet been separated into transaction count and per-transaction duration", "the effect of bridge concurrency versus downstream B latency is not yet discriminated", "reservation and translation resid...

### .github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/checker-regression.log

- `kind`: log
- `size_bytes`: 97
- `line_count`: 4
- `sha256`: 07591625d6062ee91c4e7901f90b63184e9749d823b080e23ef4dffaa4fc2b96
- `encoding`: utf-8
- `indexed_at`: 2026-08-04T00:24:39+00:00
- `markers`: {}
- `summary`: log evidence; size=97 bytes; lines=4; markers=<none>; tail=---------------------------------------------------------------------- Ran 7 tests in 0.910s OK

### .github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/command-status.txt

- `kind`: txt
- `size_bytes`: 33
- `line_count`: 3
- `sha256`: 7e710df801b187fc69c4a635ebf3455d93b736651b5688dcb62e70c563a5f434
- `encoding`: utf-8
- `indexed_at`: 2026-08-04T00:24:39+00:00
- `markers`: {}
- `summary`: txt evidence; size=33 bytes; lines=3; markers=<none>; tail=test_rc=0 build_rc=0 verify_rc=0

### .github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/independent-review.md

- `kind`: md
- `size_bytes`: 3542
- `line_count`: 68
- `sha256`: b145c8ec62d05e7597bf81c1ad29134ef8d4c0f008569d9f08ff80f94fe03777
- `encoding`: utf-8
- `indexed_at`: 2026-08-04T00:24:39+00:00
- `markers`: {"PASS": 4}
- `summary`: md evidence; size=3542 bytes; lines=68; PASS=4; tail=# V14O CPI bottleneck census v2 independent review ## Binding - review mode: frozen-material, self-contained, no-tools - contract: `.github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/subagent-contracts/v14o-cpi-bottleneck-census-closing-review-...

### .github/task-runs/2026-08-04-rv64-v14o-cpi-bottleneck-census-v2/evidence/cpi-bottleneck-census/verify.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: b8204a8b819bd3c7c4ce889b6e8d298303f5087d3db595315e26e6531db4185c
- `encoding`: utf-8
- `indexed_at`: 2026-08-04T00:24:39+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[CPI-BOTTLENECK-CENSUS][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 dominant=memory_latency/request_outstanding/axi_write_response candidate_authorized=false ppa=UNQUALIFIED
