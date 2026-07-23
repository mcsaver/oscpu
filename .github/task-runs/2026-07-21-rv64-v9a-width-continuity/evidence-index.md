# Evidence Index

## 基本信息

- `task_id`: 2026-07-21-rv64-v9a-width-continuity
- `task_slug`: 
- `profile`: 
- `asset_count`: 44
- `total_size_bytes`: 1513101

## 证据资产

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/final.log

- `kind`: log
- `size_bytes`: 165
- `line_count`: 1
- `sha256`: 02947ea07d6be16b7f4aa13f58d391e9b7682be49e8d75318ee3a953d92d1eba
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=165 bytes; lines=1; PASS=2; tail=[V9A-DI2-RUNNER][PASS] suite_run_id=v9a-di2-20260721T101435Z-1815092 focused=2 stall=1 mutations=11/11 regressions=8/8 DI-2=GREEN architecture=GREEN ppa=UNQUALIFIED

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/focused/assert/logs/tb_ooo_core_top_glue_v9a_width_continuity.log

- `kind`: log
- `size_bytes`: 45229
- `line_count`: 198
- `sha256`: c417d4ebf9300d1358a28219edd8aa9d7b2e05647c68aadfb575b52367f72316
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=45229 bytes; lines=198; PASS=8; tail=[TEST] tb_ooo_core_top_glue_v9a_width_continuity [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV9A_WIDTH_CONTINUITY_FOCUSED -s tb_ooo_core_top_glue -o /tmp/v9a-di2-focused.aF6nxc/build-assert/tb_ooo_core_top_glue_v9a_wi...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/focused/release/logs/tb_ooo_core_top_glue_v9a_width_continuity.log

- `kind`: log
- `size_bytes`: 44276
- `line_count`: 191
- `sha256`: b347870092605ebff5c62b17105f5ed9b9e0ff878d646529dbcf39751b27eec4
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=44276 bytes; lines=191; PASS=8; tail=[TEST] tb_ooo_core_top_glue_v9a_width_continuity [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV9A_WIDTH_CONTINUITY_FOCUSED -s tb_ooo_core_top_glue -o /tmp/v9a-di2-focused.aF6nxc/build-release/tb_ooo_core_top_glue_v9a_width_continui...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31255
- `line_count`: 204
- `sha256`: 7fac0ac964d1d806672b80560d38618f07bff9fb95803c6a8dd23ffa2dc4bd00
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31255 bytes; lines=204; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_alu_decode_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24922
- `line_count`: 137
- `sha256`: 66db3b2a097ccff2e2843475f94c243a5a0257c25ce442814be5110cc0f7bb73
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24922 bytes; lines=137; PASS=10; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5359
- `line_count`: 38
- `sha256`: c911e48ebc982410cd4e7433990b1ecf633b8d8809eb317c66be021a2dbeac3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5359 bytes; lines=38; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_dispatch_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 757
- `line_count`: 10
- `sha256`: 3778e034a773bacf0f31a3bb7bc358f3d7dcb91db4f6e4159cf5263c77db90c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=757 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_fetch_packet_fifo.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26206
- `line_count`: 222
- `sha256`: 9c65ec21f4a4b9b3999970be35521292046764e35c96e76f490221eb2f434c71
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"ERROR": 2, "PASS": 94}
- `summary`: log evidence; size=26206 bytes; lines=222; ERROR=2; PASS=94; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11430
- `line_count`: 96
- `sha256`: 4b56ad53b7303c551f41319d487e85eef80e4d5d5e1e0275373d718d8470724c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11430 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/s...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1460
- `line_count`: 15
- `sha256`: 063904f71c182b9a0b1f023a115b735669e742cecce98202934a5de27aef197e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=1460 bytes; lines=15; PASS=16; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCsrTrapRequestMux.v /home/...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/regressions/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 383
- `line_count`: 5
- `sha256`: 9104f64c1fd29f670baf6b4c546b13e1337f58ca280b0f608bae2c56ab05202f
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=383 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/v9a-di2-focused.aF6nxc/build-regressions/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/pipeline/PipeSta...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/result.json

- `kind`: json
- `size_bytes`: 950
- `line_count`: 44
- `sha256`: ad42466c2b52fd630e6754e31a707f22c1e9c8d2f2b86f7b2c5a191138b8627f
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 6}
- `summary`: json evidence; size=950 bytes; lines=44; PASS=6; tail={ "architecture": { "green": [ "DI-1", "DI-2", "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3", "OOO-4" ], "overall": "GREEN" }, "claim": "di2_width_continuity", "design_id": "sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc", "fixe...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 5000
- `line_count`: 43
- `sha256`: 175e936535f57e665029fdcbf0a6de3b31d2813dfde63c05403ec4023e0c6c3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=5000 bytes; lines=43; markers=<none>; tail=2d89909500f3c3231e0543a7c3ff2686bd97cb2f0985890a45bea88faa152927 .github/task-runs/2026-07-21-rv64-v9a-width-continuity/contract.md d93cec38002e6c97d603eb2baf48405e296643bd92a59cbc7fe5236b5c3ca223 .github/task-runs/2026-07-21-rv64-v9a-width-continuity/rtl-d...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 5000
- `line_count`: 43
- `sha256`: 175e936535f57e665029fdcbf0a6de3b31d2813dfde63c05403ec4023e0c6c3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=5000 bytes; lines=43; markers=<none>; tail=2d89909500f3c3231e0543a7c3ff2686bd97cb2f0985890a45bea88faa152927 .github/task-runs/2026-07-21-rv64-v9a-width-continuity/contract.md d93cec38002e6c97d603eb2baf48405e296643bd92a59cbc7fe5236b5c3ca223 .github/task-runs/2026-07-21-rv64-v9a-width-continuity/rtl-d...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/stall-probe/logs/tb_ooo_core_top_glue_v9a_width_stall_probe.log

- `kind`: log
- `size_bytes`: 45416
- `line_count`: 210
- `sha256`: fdccdcd8814e3fe5afb122bf39622d5ca5fb6c2f5a9643c4aa0f9a17422502ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 34, "PASS": 6}
- `summary`: log evidence; size=45416 bytes; lines=210; FAIL=34; PASS=6; tail=[TEST] tb_ooo_core_top_glue_v9a_width_stall_probe [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV9A_WIDTH_CONTINUITY_FOCUSED -DV9A_WIDTH_WINDOW_STALL_PROBE -s tb_ooo_core_top_glue -o /tmp/v9a-di2-focused.aF6nxc/build-stall/tb_ooo_co...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 5224
- `line_count`: 48
- `sha256`: cc4e829dc515514a1614bc83f0b7e89e2c9dd21ab66625a469c960f62ab39820
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: log evidence; size=5224 bytes; lines=48; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_actual_di3_chain_rejects_each_structural_cut (test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/architecture-result.json

- `kind`: json
- `size_bytes`: 61825
- `line_count`: 1435
- `sha256`: 37659140e9618189f95a950bf6b33e36cd43d98f3f5a67f52323d9adbbe6a4c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 36}
- `summary`: json evidence; size=61825 bytes; lines=1435; PASS=36; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "96b9984e0a75609b692e62eaabe4b360a38b5bf295adfdde2d4415ac6efa85a9" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/architecture-unit.log

- `kind`: log
- `size_bytes`: 7498
- `line_count`: 47
- `sha256`: 6de6b05af01637bb4c88f69f38e3e132e139aed66b8c8c3d2cfe619938a8f666
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: log evidence; size=7498 bytes; lines=47; markers=<none>; tail=test_actual_di3_chain_rejects_each_structural_cut (npc.rv64.eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pass_vacuously_or_statically (npc.rv64.eval.ppa.test...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/check-contract.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 9
- `sha256`: e1ecce2fb928260de3112a1cd659bf7bc49a9acedb93af0e5c1df963155343dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=9; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 13 tests in 3.292s OK [PRODUCER-HOLDER-CENSUS] PASS direct=20 packed=5 token_q=15 generation=1 契约立即断言（$error）计数：当前=...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/evidence-builder.log

- `kind`: log
- `size_bytes`: 196
- `line_count`: 1
- `sha256`: 191a70953f325981266a0203e6c58661814352d285c5ee6e7223d001afcc8334
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=196 bytes; lines=1; PASS=2; tail=[V9A-DI2-EVIDENCE][PASS] width_continuity suite_run_id=v9a-di2-20260721T101435Z-1815092 design_id=sha256:6236b176da0c10bccac9c2feb405a0d65ba586d826616f0beaeee0cbbfe2f3dc boundaries=7 mutations=11

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/focused-assert.make.log

- `kind`: log
- `size_bytes`: 20888
- `line_count`: 72
- `sha256`: 66ee7444f147f22f57819572f66a198ad9a5914c95fd52b5ef4447fff499eda2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=20888 bytes; lines=72; PASS=8; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V9A-DI2-ANCHOR] first_fetch_request_fire warmup_cycles=24 [V9A-DI2-TRACE] cycle=0 fetch=2 decode=2 rename=2 dispatch=2 issue=2 execute=2 retire=2 fetch_pc0=00000000800000c0 fetch_...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/focused-release.make.log

- `kind`: log
- `size_bytes`: 20888
- `line_count`: 72
- `sha256`: 66ee7444f147f22f57819572f66a198ad9a5914c95fd52b5ef4447fff499eda2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=20888 bytes; lines=72; PASS=8; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V9A-DI2-ANCHOR] first_fetch_request_fire warmup_cycles=24 [V9A-DI2-TRACE] cycle=0 fetch=2 decode=2 rename=2 dispatch=2 issue=2 execute=2 retire=2 fetch_pc0=00000000800000c0 fetch_...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/manifest-before-di2.json

- `kind`: json
- `size_bytes`: 77197
- `line_count`: 934
- `sha256`: 449ea279e24b0708d074af33f092ba0022b8660bf1554745fe82d87ac897142f
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 13}
- `summary`: json evidence; size=77197 bytes; lines=934; PASS=13; tail=-v8z-frontend-ii1/contract-review-v2-result.json": "ce306b7dd1c20ec4a77227f16d6407f91a503b7dce62098d871f0212f13f3b1e", ".github/task-runs/2026-07-21-rv64-v8z-frontend-ii1/contract.md": "7879a769791004835c980afb203d087740579496aa29183ba1715183b75e799c", ".gi...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/mutations.log

- `kind`: log
- `size_bytes`: 1509
- `line_count`: 12
- `sha256`: 55df2a043154de9ef4e2ff80472897f2dc32e4d2c586e0fa082e1b88b7423255
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 2, "PASS": 24}
- `summary`: log evidence; size=1509 bytes; lines=12; FAIL=2; PASS=24; tail=[V9A-MUTATION][PASS] name=fetch_lane1_payload_alias compile_rc=0 sim_rc=1 witness=[V9A-IDENTITY][FAIL] boundary instruction payload mismatch [V9A-MUTATION][PASS] name=decode_lane1_backend_cut compile_rc=0 sim_rc=1 witness=decode acceptance disagrees with in...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/regressions.make.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 2
- `sha256`: bcafe78bdda8cb0dbcf5194ace5a54f4a591eb096d68690ec196c4ef85f3d6a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: log evidence; size=153 bytes; lines=2; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/reset-record.log

- `kind`: log
- `size_bytes`: 22
- `line_count`: 1
- `sha256`: bc7876f16d0022d45a1c0ac7356667dcfe7fd923b2e6a3cb83b81f3a662f6a8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=22 bytes; lines=1; PASS=2; tail=[V9A-DI2-RESET][PASS]

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/same-design-predecessors.log

- `kind`: log
- `size_bytes`: 286
- `line_count`: 3
- `sha256`: 646cedb8a7cdbb85a03b052334b9629ac3f198dde2ff49357082bc27be6f803b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=286 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8Z-DI1-RUNNER][PASS] suite_run_id=v8z-di1-20260721T101435Z-1815114 focused=4 mutations=9/9 regressions=6/6 DI-1=GREEN DI-2/overall=RED ppa=UNQUALIFIED make[1]: Leaving directory '/home/lyg...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/source-snapshot-post.log

- `kind`: log
- `size_bytes`: 154
- `line_count`: 1
- `sha256`: a055f16eccf4284d537c4297ef61ec7f39c9c9736438f536d3cabb22bc897e42
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=154 bytes; lines=1; PASS=2; tail=[V9A-DI2-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/sources.post.sha256

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/source-snapshot-pre.log

- `kind`: log
- `size_bytes`: 153
- `line_count`: 1
- `sha256`: 5e4edfc4f140784ec512b6b35b344931cc8d7884ef22eba702f630225fd1bb6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=153 bytes; lines=1; PASS=2; tail=[V9A-DI2-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/sources.pre.sha256

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/static/stall-probe.make.log

- `kind`: log
- `size_bytes`: 356
- `line_count`: 3
- `sha256`: b0eeae2e9a9d0b39c2c947040d9873ed72cc62b8191ce67944ee8544d19dd603
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: log evidence; size=356 bytes; lines=3; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make[1]: *** [Makefile:342: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/stall-probe/logs/tb_ooo_core_top_glue_v9a_width_st...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/final-run/suite-run-id.txt

- `kind`: txt
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 325963b06d3f5fe4ba6ea99404f6edca0e82af3bc61e80e9bbe4f7e4f2c447b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {}
- `summary`: txt evidence; size=33 bytes; lines=1; markers=<none>; tail=v9a-di2-20260721T101435Z-1815092

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/decode_lane1_backend_cut.log

- `kind`: log
- `size_bytes`: 194171
- `line_count`: 2369
- `sha256`: 49957d946111583c9b81b2e74527c1c496ea4b26971dc98fdc1e4fed61a39d59
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 815, "PASS": 1}
- `summary`: log evidence; size=194171 bytes; lines=2369; FAIL=815; PASS=1; tail=PC sequence mismatch [V9A-IDENTITY-DETAIL] boundary=5 seen=56 pc=00000000800001c0 expected=00000000800000e0 [V9A-IDENTITY][FAIL] boundary instruction payload mismatch [V9A-IDENTITY-DETAIL] boundary=5 pc=00000000800001c0 inst=07100b93 expected=03900d93 [V9A-...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/ex1_stage_capture_cut.log

- `kind`: log
- `size_bytes`: 74501
- `line_count`: 705
- `sha256`: ff003f0bd00398d1396365d06d5bc2be855dbf1b4dbcc304eb89eb49403d6eb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 919}
- `summary`: log evidence; size=74501 bytes; lines=705; FAIL=919; tail=o all 8 words in array 'ctrl_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:583: warning: @* is sensitive to all 8 words in array 'producer_id_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:584: warn...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/ex1_stage_payload_alias.log

- `kind`: log
- `size_bytes`: 74019
- `line_count`: 697
- `sha256`: 1e367f71917a255c1c702b709c32636abeaaa867eae2011385af21125c752a97
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 909}
- `summary`: log evidence; size=74019 bytes; lines=697; FAIL=909; tail=64/vsrc/scheduling/OooIntIssueQueue.v:579: warning: @* is sensitive to all 8 words in array 'bht_idx_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:580: warning: @* is sensitive to all 8 words in array 'pred_taken_q'. /home/lyg/...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/fetch_lane1_payload_alias.log

- `kind`: log
- `size_bytes`: 167403
- `line_count`: 1881
- `sha256`: b31a6ba41c35888e8d6fdda4ca448a6da3dfcc8df80cb782857a48be748ceaf0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 744, "PASS": 1}
- `summary`: log evidence; size=167403 bytes; lines=1881; FAIL=744; PASS=1; tail=] boundary instruction payload mismatch [V9A-IDENTITY-DETAIL] boundary=1 pc=000000008000019c inst=06700693 expected=06800713 [V9A-IDENTITY][FAIL] boundary instruction payload mismatch [V9A-IDENTITY-DETAIL] boundary=2 pc=000000008000019c inst=06700693 expect...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/iq_lane1_sink_cut.log

- `kind`: log
- `size_bytes`: 77367
- `line_count`: 745
- `sha256`: d165c1914dd2375c7d60236a18530efd814c68e041001f08a65df1ee178a827a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 915}
- `summary`: log evidence; size=77367 bytes; lines=745; FAIL=915; tail=oducer_id_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemInflightQueue.v:191: warning: @* is sensitive to all 4 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemInflightQueue.v:192: warning: @* is sensitive to all...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/issue_lane1_terminal_cut.log

- `kind`: log
- `size_bytes`: 75453
- `line_count`: 717
- `sha256`: 2b75df6837c12d0facd626c3fe08a5afd02a22bf5ce9f6971fd6fcb3700ffaf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 906}
- `summary`: log evidence; size=75453 bytes; lines=717; FAIL=906; tail=eQueue.v:595: warning: @* is sensitive to all 8 words in array 'src2_preg_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:600: warning: @* is sensitive to all 8 words in array 'pdest_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/lane1_immediate_alias.log

- `kind`: log
- `size_bytes`: 65842
- `line_count`: 457
- `sha256`: 53b9b398663c347d20067b6e739c2cb50fdb9b1345acd73aaedfee4620c34b63
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 357, "PASS": 1}
- `summary`: log evidence; size=65842 bytes; lines=457; FAIL=357; PASS=1; tail=alias/tb_ooo_core_top_glue_v9a_width_continuity.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlFlushSequencer.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooControlPlane.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCoreObs...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/rename_lane1_sink_cut.log

- `kind`: log
- `size_bytes`: 79829
- `line_count`: 697
- `sha256`: 07b061094fa13898979308220ce7fbb484e29755ada55cdeb97fd8100b761d15
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 587, "PASS": 1}
- `summary`: log evidence; size=79829 bytes; lines=697; FAIL=587; PASS=1; tail=ve to all 8 words in array 'producer_id_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v:183: warning: @* is sensitive to all 8 words in array 'producer_id_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v:...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/retire_lane1_event_cut.log

- `kind`: log
- `size_bytes`: 78467
- `line_count`: 750
- `sha256`: e1a8b46207cce20cae55008e6ac52676a94be469e892f4dea6efeca66e5c9d8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 878}
- `summary`: log evidence; size=78467 bytes; lines=750; FAIL=878; tail=ds in array 'kind_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v:164: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooFpIssueQueue.v:165: warning: @* is sensitiv...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/rob_lane1_sink_cut.log

- `kind`: log
- `size_bytes`: 97806
- `line_count`: 1020
- `sha256`: 4fb87a6b5d00a4a8d75bca27d3182f17622eeffa438d3c5cd44fe533caced89d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 945}
- `summary`: log evidence; size=97806 bytes; lines=1020; FAIL=945; tail=undary instruction payload mismatch [V9A-IDENTITY-DETAIL] boundary=6 pc=0000000080000038 inst=00f00793 expected=00800413 [V9A-WIDTH][FAIL] cycle=1 boundary=0 width=0 expected=2 [V9A-WIDTH][FAIL] cycle=1 boundary=3 width=1 expected=2 [V9A-WIDTH][FAIL] cycle=...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/summary.json

- `kind`: json
- `size_bytes`: 12124
- `line_count`: 297
- `sha256`: a7d27f950be61a4ca869a7bb7759de7ef9e5bb5e8db83d64dbb31907ba5133aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 2}
- `summary`: json evidence; size=12124 bytes; lines=297; FAIL=2; tail={ "compile_success": 11, "dynamic_rejected": 11, "required": 11, "results": [ { "compile_rc": 0, "compile_success": true, "dimensions": [ "fetch_identity", "payload_data" ], "dynamic_rejected": true, "log": ".github/task-runs/2026-07-21-rv64-v9a-width-conti...

### .github/task-runs/2026-07-21-rv64-v9a-width-continuity/evidence/mutations/wb1_rob_sink_cut.log

- `kind`: log
- `size_bytes`: 71479
- `line_count`: 661
- `sha256`: 11dcda8364e13da7b08ffabf4dee65718595c7f532240c1124043e6b0d73fe6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T10:29:51+00:00
- `markers`: {"FAIL": 887}
- `summary`: log evidence; size=71479 bytes; lines=661; FAIL=887; tail=inalCollector.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemOwnerTracker.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemoryAccess.v /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemoryRequestGate.v /home/lyg/PA/ysyx-workbench/npc/...
