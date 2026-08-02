# Evidence Index

## 基本信息

- `task_id`: 2026-08-01-rv64-v13m-head-lifecycle-cpi-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 10
- `total_size_bytes`: 109243

## 证据资产

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/coremark-current/build.log

- `kind`: log
- `size_bytes`: 73436
- `line_count`: 95
- `sha256`: 123f898847da42f57d9309e816ed9c5f5a5f6728fcc7d40114c461ba6482108f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__", "__5__", "__6__", "__7__", "__8__", "__9__"]}
- `summary`: log evidence; size=73436 bytes; lines=95; symbolic=__0__,__1__,__2__,__3__,__4__; tail=/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooBusyTable.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooFreeList.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/coremark-current/checker-replay-result.json

- `kind`: json
- `size_bytes`: 3197
- `line_count`: 86
- `sha256`: bea8a0fa27e3306d0e2af47da445427e2a631ec1dc8c0a292696df6b4b6bbad0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: json evidence; size=3197 bytes; lines=86; FAIL=2; PASS=2; tail={ "schema": "npc-rv64-v13m-checker-replay-result-v1", "status": "PASS", "original_task_status_preserved": "FAIL rc=1 stage=evidence-complete evidence_complete=0 cleanup_rc=0", "classification": "SYSTEM_TRANSACTION_COMPLETE_OLD_NONVACUITY_ORACLE_FALSE_NEGATI...

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/coremark-current/command-status.txt

- `kind`: txt
- `size_bytes`: 86
- `line_count`: 6
- `sha256`: fc07e4a66bf2ec54ac609b2a45ff420b84433ee161282009c71263f149286faf
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {}
- `summary`: txt evidence; size=86 bytes; lines=6; markers=<none>; tail=input_rc=0 build_rc=0 run_rc=0 parser_rc=1 cleanup_rc=0 build_bytes_deleted=227337411

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/coremark-current/coremark-v6.raw.log

- `kind`: log
- `size_bytes`: 9582
- `line_count`: 96
- `sha256`: 12af52f4abe0fa3d7e5a15a5bd2b66f86fe5838a5ca60ea75a087359c9916c16
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=9582 bytes; lines=96; PASS=2; GOOD_TRAP=2; tail=[npc] failed to locate libcapstone.so.5: tools/capstone/repo/libcapstone.so.5: cannot open shared object file: No such file or directory [1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory a...

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/focused/synthesis-source-list.txt

- `kind`: txt
- `size_bytes`: 8928
- `line_count`: 1
- `sha256`: 701e64a97301ee549790c854700a68507aee040fdc0eec592d91c81b8124dfa2
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {}
- `summary`: txt evidence; size=8928 bytes; lines=1; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiDefaultSlave.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiResetSyscon.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiClint.v /home/lyg/PA/ysyx...

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/focused/task-run-status-tests.log

- `kind`: log
- `size_bytes`: 133
- `line_count`: 1
- `sha256`: 33fc3f7f53ad33d89c1d11ea0185f2e1eb21e1ff4346d6a8e0579005b71a3292
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=133 bytes; lines=1; PASS=4; tail=[task-run-status-test] PASS explicit completion, early exit, command failure, cleanup failure, PASS-write fallback, and HUP/INT/TERM

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/focused/test-policy-tools.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 5
- `sha256`: 18350d3437c22974f13ccfc1f17cd6a175790490e716e38e430b6d1676ad629c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=5; markers=<none>; tail=...................................................... ---------------------------------------------------------------------- Ran 54 tests in 2.243s OK

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/focused/verilator-lint.log

- `kind`: log
- `size_bytes`: 9856
- `line_count`: 3
- `sha256`: 55af05d530562e9a60047d1f4581ff0ce6653b2f46b1cbd4f16007af897f8088
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {}
- `summary`: log evidence; size=9856 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only --timescale 1ns/1ps -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/includ...

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/memory/npc-section.md

- `kind`: md
- `size_bytes`: 1789
- `line_count`: 20
- `sha256`: c2b686f2cc9cecbaa055cf01b79c81961f61ecbcb150c200d144fac9fdcb9700
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: md evidence; size=1789 bytes; lines=20; FAIL=2; PASS=4; tail=## V13M full-ProducerId ROB-head lifecycle observation - `done=0` 时先用 `OooDispatchBackend.int_iq_producer_live_mask_w` / `OooFpBackend.fp_iq_producer_live_mask_w` 查 exact head `ProducerId`。resident entry 任一 enabled sticky-ready=0 归 dependency；全部 ready 归 iss...

### .github/task-runs/2026-08-01-rv64-v13m-head-lifecycle-cpi-v1/evidence/memory/project-status-section.md

- `kind`: md
- `size_bytes`: 2083
- `line_count`: 23
- `sha256`: 9569b25a8ba1040b1c2a783fb7ef7d9929e253962dc544550000bc3379358c72
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T14:58:56+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: md evidence; size=2083 bytes; lines=23; FAIL=2; PASS=2; tail=## 2026-08-01 RV64 V13M ROB-head lifecycle CPI schema v2 - production core RTL 未修改；`NpcSimTop.sv` 只读 full-`ProducerId` ROB head、整数/FP IQ resident entry 与 sticky-ready、以及既有 execution/memory owner mask。观测不反馈 DUT，且 `print-synth-rtl` 仍排除 `NpcSimTop.sv`/`cpu-exe...
