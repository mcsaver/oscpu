# Evidence Index

## 基本信息

- `task_id`: 2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 15
- `total_size_bytes`: 41311

## 证据资产

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/arch-stable-postflight.log

- `kind`: log
- `size_bytes`: 85
- `line_count`: 1
- `sha256`: 163e7cd85f0232175fe3aa1307eadb937c2e774acf9f950256931cc531498fc5
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: log evidence; size=85 bytes; lines=1; markers=<none>; tail=[ARCH-STABLE] status=ARCH_STABLE ppa=UNQUALIFIED promotion_eligible=false blockers=0

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/bind-postflight.log

- `kind`: log
- `size_bytes`: 130
- `line_count`: 1
- `sha256`: 3f9183bdfb43b75a0fae9d5b5ec1794a397bdffa7415fdb1e79efb4218e271f9
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=130 bytes; lines=1; PASS=2; tail=[PERFORMANCE-BASELINE-POSTFLIGHT-BINDING][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/build.log

- `kind`: log
- `size_bytes`: 212
- `line_count`: 1
- `sha256`: 967e27426a809b41add2e291c42b4f704a81fc3f41cdd4b7e5e86b197eb1e419
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=212 bytes; lines=1; PASS=2; tail=[PERFORMANCE-BASELINE-CURRENT][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 coremark=5392187/3183617 dhrystone=10311431/4250000 ppa=UNQUALIFIED promotion_eligible=false

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/checker-regression.log

- `kind`: log
- `size_bytes`: 98
- `line_count`: 4
- `sha256`: 0edde8635a1ce4d1377f2456456a0bae9ab454161e689bb8a2d4a3d8c970f8c5
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: log evidence; size=98 bytes; lines=4; markers=<none>; tail=---------------------------------------------------------------------- Ran 72 tests in 5.437s OK

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/command-status.txt

- `kind`: txt
- `size_bytes`: 77
- `line_count`: 6
- `sha256`: f8fede8822ef4ea77415aa2f15d716d908b62fb8bde088a2037ab07a3cbec9f1
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=77 bytes; lines=6; markers=<none>; tail=manifest_rc=0 precheck_rc=0 postflight_rc=0 bind_rc=0 build_rc=0 verify_rc=0

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/final-manifest.json

- `kind`: json
- `size_bytes`: 7100
- `line_count`: 148
- `sha256`: 87cac52523622915189bf28265c876641f949e669fa2013f7922cdc765a328cd
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: json evidence; size=7100 bytes; lines=148; markers=<none>; tail={ "arch_stable_result": { "path": "npc/rv64/eval/ppa/evidence/arch-stable-current.json", "sha256": "6e2804f35fcf30b9663f7cb134a9f690303b367116c5ba0a9d6f0bb1d86e731c", "size_bytes": 762060 }, "baseline_contract": { "path": "npc/rv64/design/arch/performance-b...

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/final-regression.log

- `kind`: log
- `size_bytes`: 98
- `line_count`: 4
- `sha256`: b3c5825d9dff127b8fa9ae5f63f2a5354988186bfc8b2a09192e2a230454290d
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: log evidence; size=98 bytes; lines=4; markers=<none>; tail=---------------------------------------------------------------------- Ran 75 tests in 5.904s OK

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/independent-review.md

- `kind`: md
- `size_bytes`: 2239
- `line_count`: 17
- `sha256`: b5e5b0835825b7521884daedf648e4f442dccebe4b703604261cb5961b19f5ef
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: md evidence; size=2239 bytes; lines=17; FAIL=2; PASS=2; tail=# V14N PERF_BASELINE v2 independent review RV64 RTL 结论｜对象=`performance-baseline-contract-v2.json` / composite `result.json`｜周期/配置=CoreMark10、Dhrystone10000 各 3×stats-on＋1×stats-off｜TB/EDA 观测=v1 定向拒绝、composite 六阶段 rc=0、72 tests OK｜范围=PASS（仅 PERF_BASELINE；PPA...

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/manifest.log

- `kind`: log
- `size_bytes`: 127
- `line_count`: 1
- `sha256`: d9a5800c3f84214f45425c65eb7c7717cb70d77dde3a21dde1f2e906352f1f77
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=127 bytes; lines=1; PASS=2; tail=[PERFORMANCE-BASELINE-REPLAY-MANIFEST][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/precheck-manifest.json

- `kind`: json
- `size_bytes`: 6807
- `line_count`: 143
- `sha256`: e34e08fdcd6978b831b659cd2b04f8fdad7e4bf3384915c9e72f9e8899a6e07d
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: json evidence; size=6807 bytes; lines=143; markers=<none>; tail={ "arch_stable_result": { "path": "npc/rv64/eval/ppa/evidence/arch-stable-current.json", "sha256": "6e2804f35fcf30b9663f7cb134a9f690303b367116c5ba0a9d6f0bb1d86e731c", "size_bytes": 762060 }, "baseline_contract": { "path": "npc/rv64/design/arch/performance-b...

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/precheck.json

- `kind`: json
- `size_bytes`: 11865
- `line_count`: 309
- `sha256`: 7e1bb6f07850686c42b4868d8a569f0224cea68424f60668d399d5e68781c93e
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=11865 bytes; lines=309; PASS=2; tail={ "arch_stable": { "path": "npc/rv64/eval/ppa/evidence/arch-stable-current.json", "sha256": "6e2804f35fcf30b9663f7cb134a9f690303b367116c5ba0a9d6f0bb1d86e731c", "size_bytes": 762060 }, "baseline_contract": { "path": "npc/rv64/design/arch/performance-baseline...

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/precheck.log

- `kind`: log
- `size_bytes`: 139
- `line_count`: 1
- `sha256`: 3d182e0dbbac7534244f8a03ffa1441f9d2f50e3a08c9462dcec9822fec7bb80
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=139 bytes; lines=1; PASS=2; tail=[PERFORMANCE-BASELINE-PRECHECK][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 postflight=pending

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/publication-regression.log

- `kind`: log
- `size_bytes`: 98
- `line_count`: 4
- `sha256`: bdae000f6ca1066c9ecb17a1d50690dd4b05ef4554e1b2b41849f824e8a76791
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {}
- `summary`: log evidence; size=98 bytes; lines=4; markers=<none>; tail=---------------------------------------------------------------------- Ran 74 tests in 5.718s OK

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/result.json

- `kind`: json
- `size_bytes`: 12024
- `line_count`: 311
- `sha256`: 941bbf0df1c51dd284dba0cacb46c2281da642cbe749d1127d27c29e66f87dd7
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=12024 bytes; lines=311; PASS=2; tail={ "arch_stable": { "path": "npc/rv64/eval/ppa/evidence/arch-stable-current.json", "sha256": "6e2804f35fcf30b9663f7cb134a9f690303b367116c5ba0a9d6f0bb1d86e731c", "size_bytes": 762060 }, "baseline_contract": { "path": "npc/rv64/design/arch/performance-baseline...

### .github/task-runs/2026-08-04-rv64-v14n-performance-baseline-composite-replay-v1/evidence/composite-replay/verify.log

- `kind`: log
- `size_bytes`: 212
- `line_count`: 1
- `sha256`: 967e27426a809b41add2e291c42b4f704a81fc3f41cdd4b7e5e86b197eb1e419
- `encoding`: utf-8
- `indexed_at`: 2026-08-03T23:50:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=212 bytes; lines=1; PASS=2; tail=[PERFORMANCE-BASELINE-CURRENT][PASS] design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 coremark=5392187/3183617 dhrystone=10311431/4250000 ppa=UNQUALIFIED promotion_eligible=false
