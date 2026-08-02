# Evidence Index

## 基本信息

- `task_id`: 2026-08-02-rv64-v13z-di1-current-rebind-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 41
- `total_size_bytes`: 1285786

## 证据资产

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/architecture-current.json

- `kind`: json
- `size_bytes`: 24312
- `line_count`: 310
- `sha256`: f5b0e0acb3cfbc960a2c14ebab6630ca7556bdbe8007dcd23e1188bbcb4f8fe2
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=24312 bytes; lines=310; PASS=2; tail={ "design_id": "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488", "generated_at_utc": "2026-08-02T03:29:14.659636+00:00", "schema": "npc-rv64-architecture-directed-suite-v2", "tests": { "frontend_ii1": { "artifacts": { ".github/task-...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/final.log

- `kind`: log
- `size_bytes`: 220
- `line_count`: 1
- `sha256`: 787cd92d96a1c130f9089329632711c3bef078c4e5aee6704762d3bd443e34d8
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=220 bytes; lines=1; PASS=2; tail=[V8Z-DI1-RUNNER][PASS] mode=task-run-v1 task_run_id=2026-08-02-rv64-v13z-di1-current-rebind-v1 suite_run_id=v13z-di1-20260802T032848Z-328215 focused=4 mutations=9/9 regressions=6/6 DI-1=GREEN overall=RED ppa=UNQUALIFIED

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/focused/assert/bridge/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105317
- `line_count`: 795
- `sha256`: c817ec2feed767bd7ffe26eee4148381051ac9e3d59b987b404815310dd6ef2c
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=105317 bytes; lines=795; PASS=4; tail=in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/focused/assert/frontend/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log

- `kind`: log
- `size_bytes`: 24042
- `line_count`: 127
- `sha256`: 7625021cc88ec48385107512676ac956fa43ea3ad4458c6716663450c5726bfc
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24042 bytes; lines=127; PASS=10; tail=[TEST] tb_ooo_core_top_glue_v8z_frontend_ii1 [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue -o /tmp/v13z-di1-focused.C5WnIH/build-assert-frontend/tb_ooo_core_top_glue_v8z_...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/focused/release/bridge/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105305
- `line_count`: 795
- `sha256`: 5c5981659b6f7d28bfb568a5e3f05404391b160e6e024bad107472374d40891b
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=105305 bytes; lines=795; PASS=4; tail=in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/focused/release/frontend/logs/tb_ooo_core_top_glue_v8z_frontend_ii1.log

- `kind`: log
- `size_bytes`: 22794
- `line_count`: 118
- `sha256`: 19f97aed8d52c4a28b2341908d894cc4fb51b90919b821533a75f0b589d83924
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=22794 bytes; lines=118; PASS=10; tail=[TEST] tb_ooo_core_top_glue_v8z_frontend_ii1 [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue -o /tmp/v13z-di1-focused.C5WnIH/build-release-frontend/tb_ooo_core_top_glue_v8z_frontend_ii1...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/regressions/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24165
- `line_count`: 134
- `sha256`: 2835d2a5cd218ea9b5202d4b82d608df343cdfbed50aa3934916636bd3c94432
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=24165 bytes; lines=134; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v13z-di1-focused.C5WnIH/build-regressions/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/contro...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/regressions/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: 7a84264210375ad7863945c2d51429701ba6389c39948d7c340c7968c543a491
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/v13z-di1-focused.C5WnIH/build-regressions/tb_ooo_fetch_flow_control.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/regressions/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1105
- `line_count`: 14
- `sha256`: 5d8ebb30948c03ab8a987c87f400120b1bde6b8638783530e5f5c45f3b2d0089
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1105 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/v13z-di1-focused.C5WnIH/build-regressions/tb_ooo_fetch_packet_fifo.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/regressions/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: 05d64917a4f1aa9c47a04de10f552b162461748bd2aa46f5cd6002d9a12cec50
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/v13z-di1-focused.C5WnIH/build-regressions/tb_ooo_fetch_pc_outstanding_sequencer.v...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/regressions/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 425
- `line_count`: 5
- `sha256`: 6e73420117a9fe87984e8d50eb047bf2b3be8b80f5dddc228a78848d5a670fd6
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=425 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/v13z-di1-focused.C5WnIH/build-regressions/tb_ooo_fetch_request_mux.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/regressions/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 443
- `line_count`: 5
- `sha256`: e962380effa2310471861a897fc53e318f982ae0495f73ed2f8c43dad406513d
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=443 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/v13z-di1-focused.C5WnIH/build-regressions/tb_ooo_frontend_action_gate.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/result.json

- `kind`: json
- `size_bytes`: 937
- `line_count`: 45
- `sha256`: feb56f3e1afd786dc8cd2b900f33a4a51ddfbee2dd9d7406a4c1bc4f375014cc
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 6}
- `summary`: json evidence; size=937 bytes; lines=45; PASS=6; tail={ "architecture": { "green": [ "DI-1" ], "overall": "RED", "red": [ "DI-2", "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4" ] }, "claim": "di1_frontend_ii1", "design_id": "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488",...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 3089
- `line_count`: 27
- `sha256`: 52c3cf7f81c7e6965d7d1cccfab330368853d295c7b79f06289b12b26f42a855
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3089 bytes; lines=27; markers=<none>; tail=7879a769791004835c980afb203d087740579496aa29183ba1715183b75e799c .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md 90efc6902ce332a6af02bb0e7973da4be1a71477e395404bf77f6685bce4e582 .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/rtl-derivatio...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 3089
- `line_count`: 27
- `sha256`: 52c3cf7f81c7e6965d7d1cccfab330368853d295c7b79f06289b12b26f42a855
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3089 bytes; lines=27; markers=<none>; tail=7879a769791004835c980afb203d087740579496aa29183ba1715183b75e799c .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md 90efc6902ce332a6af02bb0e7973da4be1a71477e395404bf77f6685bce4e582 .github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/rtl-derivatio...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 6210
- `line_count`: 55
- `sha256`: 591ef045da46054dea724c2c7f62d42777d2184415383b72bb3491bf8578b1e0
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: log evidence; size=6210 bytes; lines=55; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_actual_di3_chain_rejects_each_structural_cut (test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pa...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/architecture-result.json

- `kind`: json
- `size_bytes`: 54043
- `line_count`: 1216
- `sha256`: b603b0a4231fc1bc646f61b965b45ce11e418a085d498f2ed1001d0862487a16
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 4}
- `summary`: json evidence; size=54043 bytes; lines=1216; PASS=4; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "8884fa871095e01f4e5bdacface70991f986d4114b73f72e9ccf10b1e2069b73" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/architecture-unit.log

- `kind`: log
- `size_bytes`: 8600
- `line_count`: 53
- `sha256`: 1755ccd6f8177f67f94a4a1ab17106552e8a6077860de42d476ae8d9bf7029ce
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: log evidence; size=8600 bytes; lines=53; markers=<none>; tail=test_actual_di3_chain_rejects_each_structural_cut (npc.rv64.eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pass_vacuously_or_statically (npc.rv64.eval.ppa.test...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/evidence-builder.log

- `kind`: log
- `size_bytes`: 211
- `line_count`: 1
- `sha256`: 76baae96ba50b7d03792e168980c34899cb823ba6bfdff2bef65a230c1444ed9
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=211 bytes; lines=1; PASS=2; tail=[V8Z-DI1-EVIDENCE][PASS] frontend_ii1 suite_run_id=v13z-di1-20260802T032848Z-328215 design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 metrics=5 mutations=9 proof_mode=task-run-v1

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/focused-assert-bridge.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/focused-assert-frontend.make.log

- `kind`: log
- `size_bytes`: 637
- `line_count`: 7
- `sha256`: 3eed561307da488e6a619d5ed2279d123527efcb68134c2d13ace84927115a19
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=637 bytes; lines=7; PASS=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V8Z-FRONTEND-II1-INTEGRATION] preheated_cycles=64 packets_observed=64 accepted=64 responses=64 enqueues=64 produced=64 max_ii=1 sequential=64 redirects=0 stalls=0 PASS [V8Z-FRONTEND-...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/focused-release-bridge.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/focused-release-frontend.make.log

- `kind`: log
- `size_bytes`: 637
- `line_count`: 7
- `sha256`: 3eed561307da488e6a619d5ed2279d123527efcb68134c2d13ace84927115a19
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=637 bytes; lines=7; PASS=10; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V8Z-FRONTEND-II1-INTEGRATION] preheated_cycles=64 packets_observed=64 accepted=64 responses=64 enqueues=64 produced=64 max_ii=1 sequential=64 redirects=0 stalls=0 PASS [V8Z-FRONTEND-...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/mutations.log

- `kind`: log
- `size_bytes`: 1168
- `line_count`: 10
- `sha256`: 92e4a311ead323b3ce53e4c2902e720c5af8ca8b377a1c1195f38a3317a22d73
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 2, "PASS": 20}
- `summary`: log evidence; size=1168 bytes; lines=10; FAIL=2; PASS=20; tail=[V8Z-MUTATION][PASS] name=bridge_h1_ready_cut compile_rc=0 sim_rc=1 witness=II1 burst accepts successor every cycle [V8Z-MUTATION][PASS] name=bridge_h1_state_turnover_cut compile_rc=0 sim_rc=1 witness=II1 burst remains in H1 result state [V8Z-MUTATION][PASS...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/regressions.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/scoped-run.txt

- `kind`: txt
- `size_bytes`: 236
- `line_count`: 6
- `sha256`: 926648f113caa19819887c3e559b9eb0d085af3936ddc3cbee4f3f9eb63364d5
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: txt evidence; size=236 bytes; lines=6; markers=<none>; tail=schema=rv64-di1-scoped-run-v1 mode=scoped task_run_id=2026-08-02-rv64-v13z-di1-current-rebind-v1 evidence_root=.github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence canonical_manifest_write=0 historical_evidence_write=0

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/simulator-config.txt

- `kind`: txt
- `size_bytes`: 458
- `line_count`: 7
- `sha256`: b499e874938e1ad6fa2bb61500b1d0cd7d935bdb3d34accfa529a5c6fb19a279
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: txt evidence; size=458 bytes; lines=7; markers=<none>; tail=schema=rv64-di1-simulator-config-v1 target=v8z-frontend-ii1 assert_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT release_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon mutation_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/inc...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/source-snapshot-post.log

- `kind`: log
- `size_bytes`: 162
- `line_count`: 1
- `sha256`: 4dbac21a6235dff98c2248b781c1ac1e42e09814a00733c5caaf56be399d4672
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=162 bytes; lines=1; PASS=2; tail=[V8Z-DI1-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/sources.post.sha256

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/static/source-snapshot-pre.log

- `kind`: log
- `size_bytes`: 161
- `line_count`: 1
- `sha256`: 7813f074516e73ac9eb531e08cf02e1d74897cfbbdbb8fab9320a738414be9cb
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=161 bytes; lines=1; PASS=2; tail=[V8Z-DI1-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/sources.pre.sha256

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-current/suite-run-id.txt

- `kind`: txt
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 9d61bb68b5b6c5503089997b5424dc4d64dd1452b8b20649a53d51aa9e7ce82c
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {}
- `summary`: txt evidence; size=33 bytes; lines=1; markers=<none>; tail=v13z-di1-20260802T032848Z-328215

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/blocked_response_tail_ghost.log

- `kind`: log
- `size_bytes`: 24351
- `line_count`: 127
- `sha256`: 3397356da187669ea6502e30330ee594188835baa7e01e1728cd8520bd4c6c76
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: log evidence; size=24351 bytes; lines=127; FAIL=4; PASS=4; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/bridge_h1_ready_cut.log

- `kind`: log
- `size_bytes`: 150938
- `line_count`: 1472
- `sha256`: 6c9a0b410a180ba75d3c37ede2905ea12a27854ebc060749f49f68e6b2b1f4dd
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 678, "PASS": 2}
- `summary`: log evidence; size=150938 bytes; lines=1472; FAIL=678; PASS=2; tail=entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/bridge_h1_state_turnover_cut.log

- `kind`: log
- `size_bytes`: 195224
- `line_count`: 1703
- `sha256`: d9babdbe57c3ada4e701b73a9ce64514dd38439075515f3f6b0eb3542d193cb1
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"ERROR": 188, "FAIL": 280, "PASS": 2}
- `summary`: log evidence; size=195224 bytes; lines=1703; FAIL=280; ERROR=188; PASS=2; tail=ins in H1 result state got=0 expected=1 [CHECK-FAIL] II1 burst returns one hit every cycle got=0 expected=1 [CHECK-FAIL] II1 burst response owner got=0x0000000080001000 expected=0x0000000080002000 [CHECK-FAIL] II1 burst inst0 payload got=0x00000000 expected...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/bridge_semantic_lookup_cut.log

- `kind`: log
- `size_bytes`: 206880
- `line_count`: 2264
- `sha256`: 1c9af8ac454e751ca566b450c96e48e7139945d16186294ad5b76b2f5e491ded
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"ERROR": 31, "FAIL": 904, "PASS": 1}
- `summary`: log evidence; size=206880 bytes; lines=2264; FAIL=904; ERROR=31; PASS=1; tail=3 [CHECK-FAIL] II1 burst accepts successor every cycle got=0 expected=1 [CHECK-FAIL] II1 burst response fires every cycle got=0 expected=1 [CHECK-FAIL] II1 burst successor fires every cycle got=0 expected=1 [CHECK-FAIL] II1 burst successor is semantic looku...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/flow_enqueue_credit_cut.log

- `kind`: log
- `size_bytes`: 62366
- `line_count`: 626
- `sha256`: 0731d6cdefcbf59565f8542b50fae2113ffba980eecc95a02b55b0def922c28f
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 1006}
- `summary`: log evidence; size=62366 bytes; lines=626; FAIL=1006; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/flow_outstanding_turnover_cut.log

- `kind`: log
- `size_bytes`: 46926
- `line_count`: 427
- `sha256`: b8f45d6e015af96a9dac6ecd33518f1fd92a8ceac5e64d7dec1c37fcd7822884
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 608}
- `summary`: log evidence; size=46926 bytes; lines=427; FAIL=608; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/sequencer_replacement_clear.log

- `kind`: log
- `size_bytes`: 62712
- `line_count`: 622
- `sha256`: 860cda72132a53c782273f17f81c8ad669ac8feb8f042db8d0b9661cfb205c64
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 998}
- `summary`: log evidence; size=62712 bytes; lines=622; FAIL=998; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/sink_dequeue_cut.log

- `kind`: log
- `size_bytes`: 72290
- `line_count`: 774
- `sha256`: 0ac50176f07f2abf5d0c42ece109a15cff52019e71083d10c47298447c5fc172
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 1213}
- `summary`: log evidence; size=72290 bytes; lines=774; FAIL=1213; tail=.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooDispatchBackend.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooFreeList.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/rename_allocate/OooRenameMap.v /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/successor_pc_old_owner.log

- `kind`: log
- `size_bytes`: 56473
- `line_count`: 454
- `sha256`: 9661cb6230adc02a306a82976e2a896e7cec7ec8904aa80cc9b3c7cad2027369
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"ERROR": 164, "FAIL": 334}
- `summary`: log evidence; size=56473 bytes; lines=454; FAIL=334; ERROR=164; tail=[COMPILE] /usr/bin/iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -I/home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common -DOOO_ASSERT -DV8Z_FRONTEND_II1_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/di1-mutations/summary.json

- `kind`: json
- `size_bytes`: 11494
- `line_count`: 267
- `sha256`: 68df1f219fbb052bd2a750afd9b516ef46474701bc20082c1d832e4ff81643ad
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"FAIL": 2}
- `summary`: json evidence; size=11494 bytes; lines=267; FAIL=2; tail={ "bridge_testbench_sha256": "bab9479a2007900879bd8469ca992f9095dc6da2d597bf63ae3fb9b145338bd7", "compile_success": 9, "dynamic_rejected": 9, "frontend_testbench_sha256": "a6cd3c93d42109b9319e4fc9e5544cc0b0a2e52ee576c645ef4fb2a433e928aa", "required": 9, "re...

### .github/task-runs/2026-08-02-rv64-v13z-di1-current-rebind-v1/evidence/frontend-ii1.log

- `kind`: log
- `size_bytes`: 6959
- `line_count`: 59
- `sha256`: 4e2561ca6f63d2488374c721655d8e1bc9f247126d9357f1ff77c0749de5a05c
- `encoding`: utf-8
- `indexed_at`: 2026-08-02T03:39:12+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=6959 bytes; lines=59; PASS=2; tail=DI-1 local RV64 frontend initiation-interval evidence task_run_id=2026-08-02-rv64-v13z-di1-current-rebind-v1 suite_run_id=v13z-di1-20260802T032848Z-328215 generated_at_utc=2026-08-02T03:29:14.659636+00:00 design_id=sha256:093c2380b997029944aa4462015d83711d7...
