# Evidence Index

## 基本信息

- `task_id`: 2026-07-21-rv64-v8z-frontend-ii1
- `task_slug`: 
- `profile`: 
- `asset_count`: 42
- `total_size_bytes`: 1312798

## 证据资产

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/final.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 1
- `sha256`: 2bebb0591c3a974f340bfe00ca007e94c5c041759478c09a21a99b6136a6f839
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=153 bytes; lines=1; PASS=2; tail=[V8Z-DI1-RUNNER][PASS] suite_run_id=v8z-di1-20260721T082600Z-1762933 focused=4 mutations=9/9 regressions=6/6 DI-1=GREEN DI-2/overall=RED ppa=UNQUALIFIED

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/focused/assert/bridge/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104387
- `line_count`: 788
- `sha256`: 6ce03f2373d2e26c95061d45741959c95feb14c60250790b84acc3cdb1f10c7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104387 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/focused/assert/frontend/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log

- `kind`: log
- `size_bytes`: 24981
- `line_count`: 133
- `sha256`: 12fd298c310bd987823b4c5e8b6ec67d70726a72cfa21d556937b81fac88adba
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24981 bytes; lines=133; PASS=10; tail=[TEST] tb_ooo_core_top_glue_v8z_frontend_ii1 [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue -o /tmp/v8z-di1-focused.Up3qdn/build-assert-frontend/tb_ooo_core_top_glue_v8z_f...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/focused/release/bridge/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104375
- `line_count`: 788
- `sha256`: 9ba36b4770e373d616faa12561db067a4c86e7bc9d2bd7ffb08c35a73ab583cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104375 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/focused/release/frontend/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log

- `kind`: log
- `size_bytes`: 24028
- `line_count`: 126
- `sha256`: ae567324d0b3999c87241c51e3ea51b1302ec317bae34d471c98284f6c06fed3
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24028 bytes; lines=126; PASS=10; tail=[TEST] tb_ooo_core_top_glue_v8z_frontend_ii1 [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue -o /tmp/v8z-di1-focused.Up3qdn/build-release-frontend/tb_ooo_core_top_glue_v8z_frontend_ii1....

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/regressions/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24922
- `line_count`: 137
- `sha256`: 372d14d271411b7b5a99d20663d7f86012dc9c314cf32ea27d858517ca4da2cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24922 bytes; lines=137; PASS=10; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8z-di1-focused.Up3qdn/build-regressions/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/regressions/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 430
- `line_count`: 5
- `sha256`: 847464e3e13b8c3ce1dd8f75c4efde64271774734db4832f964710799d31eb53
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=430 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/v8z-di1-focused.Up3qdn/build-regressions/tb_ooo_fetch_flow_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/regressions/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 757
- `line_count`: 10
- `sha256`: ea498b4d9d28d06dda97f2e88dad23d946ac3b3f2264f33ab3c70ddfdbff90db
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=757 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/v8z-di1-focused.Up3qdn/build-regressions/tb_ooo_fetch_packet_fifo.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/regressions/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 5
- `sha256`: f8bd2fd6cc4f8ead12cc7ae6c28d7e85cc3515fde5cb9c799ddb3568bbdaca7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/v8z-di1-focused.Up3qdn/build-regressions/tb_ooo_fetch_pc_outstanding_sequencer.vv...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/regressions/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 424
- `line_count`: 5
- `sha256`: 3a4f60d6fb22f91393e685e0ec1624219d06e98f287eb044b0c72ccb0d7173a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=424 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/v8z-di1-focused.Up3qdn/build-regressions/tb_ooo_fetch_request_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/regressions/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 75586e59185cec63b8e29784013e5b9cd9616850b780df566c2f16e2a1833d6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/v8z-di1-focused.Up3qdn/build-regressions/tb_ooo_frontend_action_gate.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/result.json

- `kind`: json
- `size_bytes`: 843
- `line_count`: 43
- `sha256`: e9a0323212a2d6a5528a2cba0a7df8aadff27ac094a246eba4d9b3b3f3817a6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 6}
- `summary`: json evidence; size=843 bytes; lines=43; PASS=6; tail={ "architecture": { "green": [ "DI-1", "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4" ], "overall": "RED", "red": [ "DI-2" ] }, "claim": "di1_frontend_ii1", "design_id": "sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc",...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 3427
- `line_count`: 29
- `sha256`: 0d4c864fb4edbdfd77154920b54de53fbfba7fd040a0483aaf28c4785783b3f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3427 bytes; lines=29; markers=<none>; tail=7879a769791004835c980afb203d087740579496aa29183ba1715183b75e799c .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md 08741e6d09004000d8f442a49984b209fc77bad003b4342d50b02a5b59659c84 .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract-revi...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 3427
- `line_count`: 29
- `sha256`: 0d4c864fb4edbdfd77154920b54de53fbfba7fd040a0483aaf28c4785783b3f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3427 bytes; lines=29; markers=<none>; tail=7879a769791004835c980afb203d087740579496aa29183ba1715183b75e799c .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md 08741e6d09004000d8f442a49984b209fc77bad003b4342d50b02a5b59659c84 .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract-revi...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 49
- `sha256`: 2e0801e2c55d421115f20cb90a4280cd94a7124dc1e420e4559d79e698c1b72e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: log evidence; size=5265 bytes; lines=49; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_actual_di3_chain_rejects_each_structural_cut (test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/architecture-result.json

- `kind`: json
- `size_bytes`: 60705
- `line_count`: 1405
- `sha256`: 0ae84c70dceba9d5eace264d25c20288c9ea86edb8f7b425a17693bf1c7012df
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 32}
- `summary`: json evidence; size=60705 bytes; lines=1405; PASS=32; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/architecture-unit.log

- `kind`: log
- `size_bytes`: 7170
- `line_count`: 45
- `sha256`: 3c24acd6568ae081739c3682cbfa1c15713cc971307766938f650ff85237736a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: log evidence; size=7170 bytes; lines=45; markers=<none>; tail=test_actual_di3_chain_rejects_each_structural_cut (npc.rv64.eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pass_vacuously_or_statically (npc.rv64.eval.ppa.test...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/check-contract.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 9
- `sha256`: 5c1623f23a1a8e16a9d894d5bd67d9abc037f7762dc005159190b15611c957d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=9; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 13 tests in 3.367s OK [PRODUCER-HOLDER-CENSUS] PASS direct=20 packed=5 token_q=15 generation=1 契约立即断言（$error）计数：当前=...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/evidence-builder.log

- `kind`: log
- `size_bytes`: 188
- `line_count`: 1
- `sha256`: 8ec10c467a3965e417dbaae3a6250ba629a188a13afb80f83edab2a9b566eca2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=188 bytes; lines=1; PASS=2; tail=[V8Z-DI1-EVIDENCE][PASS] frontend_ii1 suite_run_id=v8z-di1-20260721T082600Z-1762933 design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc metrics=5 mutations=9

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/focused-assert-bridge.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/focused-assert-frontend.make.log

- `kind`: log
- `size_bytes`: 643
- `line_count`: 7
- `sha256`: dfcac0d26df56d407051b2491d047979c1d7c2f72e63715c851c8b6110b4ee20
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=643 bytes; lines=7; PASS=10; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V8Z-FRONTEND-II1-INTEGRATION] preheated_cycles=64 packets_observed=64 accepted=64 responses=64 enqueues=64 produced=64 max_ii=1 sequential=64 redirects=0 stalls=0 PASS [V8Z-FRONTE...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/focused-release-bridge.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/focused-release-frontend.make.log

- `kind`: log
- `size_bytes`: 643
- `line_count`: 7
- `sha256`: dfcac0d26df56d407051b2491d047979c1d7c2f72e63715c851c8b6110b4ee20
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=643 bytes; lines=7; PASS=10; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V8Z-FRONTEND-II1-INTEGRATION] preheated_cycles=64 packets_observed=64 accepted=64 responses=64 enqueues=64 produced=64 max_ii=1 sequential=64 redirects=0 stalls=0 PASS [V8Z-FRONTE...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/manifest-before-di1.json

- `kind`: json
- `size_bytes`: 56310
- `line_count`: 719
- `sha256`: 53e3f1fc417c7f5945d851526e50775c9109584b39a22e2e87e22f6b086a5c1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 14}
- `summary`: json evidence; size=56310 bytes; lines=719; PASS=14; tail={ "design_id": "sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc", "generated_at_utc": "2026-07-21T08:29:20.978505+00:00", "schema": "npc-rv64-architecture-directed-suite-v2", "tests": { "dual_memory_issue": { "command": "make -C npc/...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/mutations.log

- `kind`: log
- `size_bytes`: 1168
- `line_count`: 10
- `sha256`: 92e4a311ead323b3ce53e4c2902e720c5af8ca8b377a1c1195f38a3317a22d73
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 2, "PASS": 20}
- `summary`: log evidence; size=1168 bytes; lines=10; FAIL=2; PASS=20; tail=[V8Z-MUTATION][PASS] name=bridge_h1_ready_cut compile_rc=0 sim_rc=1 witness=II1 burst accepts successor every cycle [V8Z-MUTATION][PASS] name=bridge_h1_state_turnover_cut compile_rc=0 sim_rc=1 witness=II1 burst remains in H1 result state [V8Z-MUTATION][PASS...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/regressions.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/reset-record.log

- `kind`: log
- `size_bytes`: 22
- `line_count`: 1
- `sha256`: 325a4f61e3caf0382d0b174dbbd46f21e500c3fcc8d1af1e9b1494a0b531fc57
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=22 bytes; lines=1; PASS=2; tail=[V8Z-DI1-RESET][PASS]

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/same-design-predecessors.log

- `kind`: log
- `size_bytes`: 294
- `line_count`: 3
- `sha256`: 9653abcab521634b11281307b24d6b6a65550ae6a81d42cec96f0cccb5cf67b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=294 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8Y-OOO4-RUNNER][PASS] suite_run_id=v8y-ooo4-20260721T082600Z-1762955 focused=2 mutations=9/9 regressions=6/6 OOO-4=GREEN DI-1/DI-2/overall=RED ppa=UNQUALIFIED make[1]: Leaving directory '/...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/source-snapshot-post.log

- `kind`: log
- `size_bytes`: 150
- `line_count`: 1
- `sha256`: a2b48c3a652ab5a74ef586335d664c1392288a99825b33666d74dbbcf9d8c08d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=150 bytes; lines=1; PASS=2; tail=[V8Z-DI1-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/sources.post.sha256

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/static/source-snapshot-pre.log

- `kind`: log
- `size_bytes`: 149
- `line_count`: 1
- `sha256`: 1589bafb41d348f2ec420cbd95f558c6687c9f4f9cc105c5f7b3a62ba178bd5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=149 bytes; lines=1; PASS=2; tail=[V8Z-DI1-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/sources.pre.sha256

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/final-run/suite-run-id.txt

- `kind`: txt
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 5f7714e28aaab7c21e534ccb74333d660f6d8c36bd84c6d893a1b5273fe0ba4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {}
- `summary`: txt evidence; size=33 bytes; lines=1; markers=<none>; tail=v8z-di1-20260721T082600Z-1762933

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/blocked_response_tail_ghost.log

- `kind`: log
- `size_bytes`: 25285
- `line_count`: 133
- `sha256`: 127181fb3c10d973c7a5ff2451891520d6b8f9c532c972ab5d5e4c92c340344c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: log evidence; size=25285 bytes; lines=133; FAIL=4; PASS=4; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/bridge_h1_ready_cut.log

- `kind`: log
- `size_bytes`: 150003
- `line_count`: 1465
- `sha256`: 6eba00750614596198fc4b71b22b6c1700113e389f91c8b6a902980982528647
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 678}
- `summary`: log evidence; size=150003 bytes; lines=1465; FAIL=678; tail='entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words i...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/bridge_h1_state_turnover_cut.log

- `kind`: log
- `size_bytes`: 193769
- `line_count`: 1696
- `sha256`: 21d5ce385284ebb5fc39700be69e1e7fa9d9e0e23932e55dd390ef8e45064111
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"ERROR": 191, "FAIL": 281}
- `summary`: log evidence; size=193769 bytes; lines=1696; FAIL=281; ERROR=191; tail=e: tb_ooo_fetch_axi_bridge.dut ERROR: /tmp/rv64-v8z-frontend-ii1-mutations/bridge_h1_state_turnover_cut/OooFetchAxiBridge.v:1480: [T4A-ATOMIC-REPLACE] response replacement did not expose the new candidate owner Time: 1795 Scope: tb_ooo_fetch_axi_bridge.dut...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/bridge_semantic_lookup_cut.log

- `kind`: log
- `size_bytes`: 202925
- `line_count`: 2226
- `sha256`: a94591f3819e7230d5dcdbf22198fc0074134c777ab29c58e87bc2a21958b7d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"ERROR": 25, "FAIL": 927}
- `summary`: log evidence; size=202925 bytes; lines=2226; FAIL=927; ERROR=25; tail=0 expected=1 [CHECK-FAIL] II1 burst successor is semantic lookup got=0 expected=1 [CHECK-FAIL] II1 burst keeps physical read window open got=0 expected=1 [CHECK-FAIL] II1 burst remains in H1 result state got=0 expected=1 [CHECK-FAIL] II1 burst returns one h...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/flow_enqueue_credit_cut.log

- `kind`: log
- `size_bytes`: 63300
- `line_count`: 632
- `sha256`: 761f39f2ac071768b77883ba48be7ea071f93a32b197dc15a5024954d3927c70
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 1006}
- `summary`: log evidence; size=63300 bytes; lines=632; FAIL=1006; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/flow_outstanding_turnover_cut.log

- `kind`: log
- `size_bytes`: 47860
- `line_count`: 433
- `sha256`: 0ed8ac17c605084aa946ff82a4a3e18d065f5349ce2f3be90c3147c456be7cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 608}
- `summary`: log evidence; size=47860 bytes; lines=433; FAIL=608; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/sequencer_replacement_clear.log

- `kind`: log
- `size_bytes`: 63646
- `line_count`: 628
- `sha256`: a639320f3d362c077166b264167ee16f0b7955c03247132652f30a32a53f657d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 998}
- `summary`: log evidence; size=63646 bytes; lines=628; FAIL=998; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/sink_dequeue_cut.log

- `kind`: log
- `size_bytes`: 73224
- `line_count`: 780
- `sha256`: 56136f99f326b6d830cf0a97658e6d40d20ea2b0170fdce69b0f6fc20e27c9ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 1201}
- `summary`: log evidence; size=73224 bytes; lines=780; FAIL=1201; tail=sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:532: warning: @* is sensitive to all 8 words in array 'producer_id_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/successor_pc_old_owner.log

- `kind`: log
- `size_bytes`: 57407
- `line_count`: 460
- `sha256`: 6612e74ec0d9a12260345e02418a78e6920a12ab373af8923fbed834f5e20b33
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"ERROR": 164, "FAIL": 334}
- `summary`: log evidence; size=57407 bytes; lines=460; FAIL=334; ERROR=164; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/evidence/mutations/summary.json

- `kind`: json
- `size_bytes`: 8633
- `line_count`: 213
- `sha256`: c54b69a1e02739f125fbc45487707b544f165073f11887ee7ba41dcd65e88a50
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T08:41:12+00:00
- `markers`: {"FAIL": 2}
- `summary`: json evidence; size=8633 bytes; lines=213; FAIL=2; tail={ "bridge_testbench_sha256": "1bf5448d96cc7224c6b930d98aaece13a8ba038c4b3eea85f3f3f4526295fa3b", "compile_success": 9, "dynamic_rejected": 9, "frontend_testbench_sha256": "b07e8b65f58ff52f786d29470652824b6931a3d8d73964e4dc34c867b06b8d2e", "required": 9, "re...
