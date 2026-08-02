# Evidence Index

## 基本信息

- `task_id`: 2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 16
- `total_size_bytes`: 128689

## 证据资产

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current-a2/build.log

- `kind`: log
- `size_bytes`: 75386
- `line_count`: 97
- `sha256`: 7d5184f0165fd43970c8ea73a8b673e90dfc79c04f1518410211fcfccbf2b7be
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"symbolic": ["__0__", "__10__", "__11__", "__1__", "__2__", "__3__", "__4__", "__5__", "__6__", "__7__", "__8__", "__9__"]}
- `summary`: log evidence; size=75386 bytes; lines=97; symbolic=__0__,__10__,__11__,__1__,__2__; tail=vsrc/debug/OooAdUpdateChecker.sv /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/utils.c /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/cpu-exec.cpp /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/difftest.cpp /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/dpi.c /home/ly...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current-a2/command-status.txt

- `kind`: txt
- `size_bytes`: 193
- `line_count`: 8
- `sha256`: 7765f2f65d16c1ffed24df123d69a0697ac87ca2529647494f2a1021c319921d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: txt evidence; size=193 bytes; lines=8; markers=<none>; tail=input_rc=0 build_rc=0 identity_rc=0 run_rc=0 parser_rc=0 cleanup_rc=0 build_bytes_deleted=230213569 simulator_executable_sha256=932bf3f9c964e056a1b8d35212ea448e191d17ed41d78b7aca2fd64388c760a8

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current-a2/coremark-v7.raw.log

- `kind`: log
- `size_bytes`: 9996
- `line_count`: 96
- `sha256`: d995d7eaa7b7bbcec9a3f4c03df131f94a1895f13fb26566204b94b59447ebc9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=9996 bytes; lines=96; PASS=2; GOOD_TRAP=2; tail=[npc] failed to locate libcapstone.so.5: tools/capstone/repo/libcapstone.so.5: cannot open shared object file: No such file or directory [1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory a...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current-a2/counter-check-result.json

- `kind`: json
- `size_bytes`: 3135
- `line_count`: 93
- `sha256`: d3b30eb41d4f284d6a9f1bbf67e3e97079652452b4fb2fc145a89d91fb8b6c1f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=3135 bytes; lines=93; PASS=2; tail={ "schema": "npc-rv64-v13n-memory-lifecycle-smoke-result-v1", "status": "PASS", "claim_scope": "current-config CoreMark v7 conserving exact-token memory holder lifecycle only", "production_semantics_identity": "GAP_TYPED_PRODUCTION_ONLY_CLOSURE_NOT_BOUND",...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current-a2/post-run-binding.json

- `kind`: json
- `size_bytes`: 2325
- `line_count`: 54
- `sha256`: 34435afc16d63ed645e630aa44f9e9484266bca129c09002b8c246869a7c1f8e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: json evidence; size=2325 bytes; lines=54; FAIL=2; PASS=4; tail={ "schema": "npc-rv64-v13n-post-run-binding-v1", "status": "PASS", "attempt_history": { "a1": "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0", "a2": "PASS" }, "transaction": { "build_rc": 0, "identity_rc": 0, "run_rc": 0, "parser_rc": 0...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current-a2/pre-run-identity.json

- `kind`: json
- `size_bytes`: 842
- `line_count`: 14
- `sha256`: af7ee3d372f03dcd637d49bea0c95e61b133e3b0ec0226dbade232f65ad9a3e0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: json evidence; size=842 bytes; lines=14; markers=<none>; tail={ "schema": "npc-rv64-v13n-pre-run-identity-v1", "simulator_executable_sha256": "932bf3f9c964e056a1b8d35212ea448e191d17ed41d78b7aca2fd64388c760a8", "coremark_image_sha256": "a7117f7490f6ff0e23008f631f2f0977b9d0e269380931e2079ae5c1e0cb238b", "config_sha256":...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current/attempt-result.json

- `kind`: json
- `size_bytes`: 800
- `line_count`: 21
- `sha256`: 999d43a93f8e80dead852428cf05b45bb0ce8626c902b261903b7d88810c135b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"FAIL": 4}
- `summary`: json evidence; size=800 bytes; lines=21; FAIL=4; tail={ "schema": "npc-rv64-v13n-coremark-attempt-result-v1", "attempt": "a1", "status": "FAIL", "status_record": "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0", "stage": "verilator-full-build", "coremark_started": false, "cause": "OOO_ASSER...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current/build.log

- `kind`: log
- `size_bytes`: 12812
- `line_count`: 19
- `sha256`: 5baf6ca9dcbacbc1b8279a70ad7b2bcf93bb803a7d9f9544c1a1066c5e703d69
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: log evidence; size=12812 bytes; lines=19; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert --timescale 1ns/1ps -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/coremark-current/command-status.txt

- `kind`: txt
- `size_bytes`: 121
- `line_count`: 8
- `sha256`: c24843f696010c8cc960514b23e48d30de9cd3084225e64c3a41f00509de2840
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: txt evidence; size=121 bytes; lines=8; markers=<none>; tail=input_rc=0 build_rc=2 identity_rc=1 run_rc=1 parser_rc=1 cleanup_rc=0 build_bytes_deleted=0 simulator_executable_sha256=

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/focused/synthesis-scope-check.txt

- `kind`: txt
- `size_bytes`: 71
- `line_count`: 1
- `sha256`: 30b178acafd43131b50332ab50535b514ef9207b850d8bf1a6ffd337deff1e0f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=71 bytes; lines=1; PASS=2; tail=PASS NpcSimTop.sv and cpu-exec.cpp excluded from synthesis source list

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/focused/synthesis-source-list.txt

- `kind`: txt
- `size_bytes`: 8928
- `line_count`: 1
- `sha256`: 701e64a97301ee549790c854700a68507aee040fdc0eec592d91c81b8124dfa2
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: txt evidence; size=8928 bytes; lines=1; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiDefaultSlave.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiResetSyscon.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiClint.v /home/lyg/PA/ysyx...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/focused/task-run-status-tests.log

- `kind`: log
- `size_bytes`: 133
- `line_count`: 1
- `sha256`: 33fc3f7f53ad33d89c1d11ea0185f2e1eb21e1ff4346d6a8e0579005b71a3292
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=133 bytes; lines=1; PASS=4; tail=[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/focused/test-policy-tools.log

- `kind`: log
- `size_bytes`: 155
- `line_count`: 5
- `sha256`: 5634ff61285e888f857080bc5ea96c8b8939b9ce54b1db773eecc914c8c11762
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: log evidence; size=155 bytes; lines=5; markers=<none>; tail=........................................................ ---------------------------------------------------------------------- Ran 56 tests in 2.268s OK

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/focused/verilator-lint.log

- `kind`: log
- `size_bytes`: 9856
- `line_count`: 3
- `sha256`: 55af05d530562e9a60047d1f4581ff0ce6653b2f46b1cbd4f16007af897f8088
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: log evidence; size=9856 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only --timescale 1ns/1ps -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/includ...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/memory/npc-section.md

- `kind`: md
- `size_bytes`: 1794
- `line_count`: 19
- `sha256`: 2b4f2281f413dca3960de130464b84551dad08f4797e568c66c9fdef729c00d5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {}
- `summary`: md evidence; size=1794 bytes; lines=19; markers=<none>; tail=## V13N exact-token memory-holder lifecycle observation - `done=0` 且 V13M 主分类命中 memory 时，observer 用完整 ROB-head `ProducerId` 扫描 `mem_owner_live_mask_w`/`mem_owner_producer_id_table_w`，要求 zero-or-one owner token；随后读取该 token 在双 `OooMemAxiBridge` 的 active/stati...

### .github/task-runs/2026-08-01-rv64-v13n-memory-lifecycle-cpi-v1/evidence/memory/project-status-section.md

- `kind`: md
- `size_bytes`: 2142
- `line_count`: 23
- `sha256`: ceea3581795f081962198ca8fa47210017be3a63ef194af466f2a8f115ba1ee1
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T15:43:42+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: md evidence; size=2142 bytes; lines=23; FAIL=2; PASS=2; tail=## 2026-08-01 RV64 V13N memory-holder lifecycle CPI schema v3 - production core RTL 未修改；`NpcSimTop.sv` 只读 full-`ProducerId` ROB head、memory owner table、双 `OooMemAxiBridge` token/state、terminal collector 与 LQ terminal identity。观测不反馈 DUT，且 synthesis source li...
