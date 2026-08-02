# Evidence Index

## 基本信息

- `task_id`: 2026-08-02-rv64-v13v-ooo4-current-rebind-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 41
- `total_size_bytes`: 2152129

## 证据资产

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/architecture-current.json

- `kind`: json
- `size_bytes`: 23791
- `line_count`: 309
- `sha256`: f05747b55e698bc5687f90b9eddf86a11d423d32dd01e039582512fb7b397d3f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=23791 bytes; lines=309; PASS=2; tail={ "design_id": "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488", "generated_at_utc": "2026-08-01T23:32:58.189083+00:00", "schema": "npc-rv64-architecture-directed-suite-v2", "tests": { "speculation_recovery": { "artifacts": { ".gith...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/contract-aggregate-gap.log

- `kind`: log
- `size_bytes`: 958
- `line_count`: 17
- `sha256`: f8496df1860f82f61119991dba84935dadad5a1451f5afc432d0a6760f5b28f0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=958 bytes; lines=17; FAIL=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 19 tests in 0.222s OK [PRODUCER-HOLDER-INSTANCE-GRAPH] FAIL - census design_id differs from live RTL source binding -...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/final.log

- `kind`: log
- `size_bytes`: 157
- `line_count`: 1
- `sha256`: 27caf858839402c671029ccd6da869790c7d8f4cbf50b3a00ea1e76a239b872e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=157 bytes; lines=1; PASS=2; tail=[V8Y-OOO4-RUNNER][PASS] suite_run_id=v8y-ooo4-20260801T233216Z-243405 mode=1 focused=2 mutations=9/9 regressions=6/6 OOO-4=GREEN overall=RED ppa=UNQUALIFIED

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/focused/assert/logs/tb_ooo_int_backend_v8y_speculation_recovery.log

- `kind`: log
- `size_bytes`: 158688
- `line_count`: 1169
- `sha256`: 132dbc13094bf75d9c7efce9441dbd6b0e7a02a120e9e0b0dab2a747899dc7d1
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 9}
- `summary`: log evidence; size=158688 bytes; lines=1169; PASS=9; tail=is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: war...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/focused/release/logs/tb_ooo_int_backend_v8y_speculation_recovery.log

- `kind`: log
- `size_bytes`: 157440
- `line_count`: 1160
- `sha256`: da53e3c6e8705395377ac3e5adc951cb45997b5577581e107d43bf1349a4b200
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 9}
- `summary`: log evidence; size=157440 bytes; lines=1160; PASS=9; tail=src/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/n...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/regressions/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 782
- `line_count`: 9
- `sha256`: 358db2416795119e072c0d19aa45de76690f93f7d13c2f43a9ab90f9ef52133e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=782 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/v8y-ooo4-focused.nPDRzB/build-regressions/tb_ooo_branch_bpu_update_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/regressions/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24165
- `line_count`: 134
- `sha256`: 44c8f4bcfdcd8fec73b8eea47de8e45dd91d8ea3a4b6bdd55a875129196d8a24
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=24165 bytes; lines=134; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8y-ooo4-focused.nPDRzB/build-regressions/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/contro...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/regressions/logs/tb_ooo_dual_mem_bridge_wrapper.log

- `kind`: log
- `size_bytes`: 138590
- `line_count`: 1041
- `sha256`: 5e0cd7d8ef981dda40b80affc53dc1f6af3561af43f1a11601b0b89a233d5266
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=138590 bytes; lines=1041; PASS=5; tail=s in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to al...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/regressions/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 25484
- `line_count`: 220
- `sha256`: 3c4ea80413a091668bead2af3842865f63d92f31abd9cfa3322b8f5bc3766b0f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"ERROR": 2, "PASS": 102}
- `summary`: log evidence; size=25484 bytes; lines=220; ERROR=2; PASS=102; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8y-ooo4-focused.nPDRzB/build-regressions/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU....

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/regressions/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74550
- `line_count`: 572
- `sha256`: dafcd0ae1fd84ae0d0e4a1e1877db83fd786066cfdd6d630a534050379d7a320
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74550 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/regressions/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 4cbf68912881866beac9608cf72930627bb4d60fd02d5ffedc00087c091520b1
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/v8y-ooo4-focused.nPDRzB/build-regressions/tb_ooo_redirect_arbiter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/result.json

- `kind`: json
- `size_bytes`: 906
- `line_count`: 44
- `sha256`: d684b7244e9fb480c8900f64fba64dc949e59b912a9489506f660b8b108141d7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 6}
- `summary`: json evidence; size=906 bytes; lines=44; PASS=6; tail={ "architecture": { "green": [ "OOO-4" ], "overall": "RED", "red": [ "DI-1", "DI-2", "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-3" ] }, "claim": "ooo4_speculation_recovery", "design_id": "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a58...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 3302
- `line_count`: 27
- `sha256`: 86bc7c87b98a79cb54d5c26f7e806864a477f57098e0d189555b9cdde220790c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3302 bytes; lines=27; markers=<none>; tail=6951e18e896c4bb1af3cb68af4a6a95239dc64b8ad95fad23958f1eab503fe42 .github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/contract.md 616a444e9a5375afabba1b8feda7ed368f4624eec82035ebe04272405e83d556 .github/task-runs/2026-07-21-rv64-v8y-speculation-recove...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 3302
- `line_count`: 27
- `sha256`: 86bc7c87b98a79cb54d5c26f7e806864a477f57098e0d189555b9cdde220790c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3302 bytes; lines=27; markers=<none>; tail=6951e18e896c4bb1af3cb68af4a6a95239dc64b8ad95fad23958f1eab503fe42 .github/task-runs/2026-07-21-rv64-v8y-speculation-recovery/contract.md 616a444e9a5375afabba1b8feda7ed368f4624eec82035ebe04272405e83d556 .github/task-runs/2026-07-21-rv64-v8y-speculation-recove...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 5560
- `line_count`: 51
- `sha256`: 9e811c189e7ad9b6168040d483f751f7c088309c67199d90aa19e5790c1f08c9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: log evidence; size=5560 bytes; lines=51; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_actual_di3_chain_rejects_each_structural_cut (test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pa...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/architecture-result.json

- `kind`: json
- `size_bytes`: 54144
- `line_count`: 1216
- `sha256`: 55e77219357e856bfa59c3a4fa6d973a83756145d37808346a86d87c15e6307e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 4}
- `summary`: json evidence; size=54144 bytes; lines=1216; PASS=4; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "8884fa871095e01f4e5bdacface70991f986d4114b73f72e9ccf10b1e2069b73" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/architecture-unit.log

- `kind`: log
- `size_bytes`: 7465
- `line_count`: 46
- `sha256`: e019d5d3ac3e493f7447f48593937482b7b6c8314e8ff74efd5e0d08e1c70535
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: log evidence; size=7465 bytes; lines=46; markers=<none>; tail=test_actual_di3_chain_rejects_each_structural_cut (npc.rv64.eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pass_vacuously_or_statically (npc.rv64.eval.ppa.test...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/check-contract.log

- `kind`: log
- `size_bytes`: 146
- `line_count`: 2
- `sha256`: c35965973ad8f5ccb02da2347b5255dc5ef48172c584baa07c6b07c9d0f23dc9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=146 bytes; lines=2; PASS=2; tail=契约立即断言（$error）计数：当前=508 基线=89 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 508≥89 ✓）

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/diff-check.log

- `kind`: log
- `size_bytes`: 82
- `line_count`: 1
- `sha256`: 90e2badfda4637c3531d9d33a56e4166959c8e0d9614d4bce39c81c087914965
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=82 bytes; lines=1; PASS=2; tail=[OOO4-SCOPED-SOURCE-BINDING] pre/post manifest replaces worktree enumeration PASS

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/evidence-builder.log

- `kind`: log
- `size_bytes`: 220
- `line_count`: 1
- `sha256`: fb7d0cd5c1dd8c14423407a07cc4ea9a334e5ba4e4bdb95fca12dc96699991a9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=220 bytes; lines=1; PASS=2; tail=[V8Y-OOO4-EVIDENCE][PASS] speculation_recovery suite_run_id=v8y-ooo4-20260801T233216Z-243405 design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 metrics=7 mutations=9 proof_mode=task-run-v1

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/focused-assert.make.log

- `kind`: log
- `size_bytes`: 1053
- `line_count`: 11
- `sha256`: 89ae7e4f0977c167a85b3dc43ba7b3f416db2a1a93276a59c2292f247ccf2fbc
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1053 bytes; lines=11; PASS=14; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V8Y-CONTROL-RECOVERY] mode=linear rob=D0,A1,B2 controls=2 oldest=A resolves=1 younger_issue=0 younger_resolve=0 complete_survivors=2 wrong_complete=0 retire_survivors=2 wrong_retire=...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/focused-release.make.log

- `kind`: log
- `size_bytes`: 1053
- `line_count`: 11
- `sha256`: 89ae7e4f0977c167a85b3dc43ba7b3f416db2a1a93276a59c2292f247ccf2fbc
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1053 bytes; lines=11; PASS=14; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [V8Y-CONTROL-RECOVERY] mode=linear rob=D0,A1,B2 controls=2 oldest=A resolves=1 younger_issue=0 younger_resolve=0 complete_survivors=2 wrong_complete=0 retire_survivors=2 wrong_retire=...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/manifest-before-ooo4.json

- `kind`: json
- `size_bytes`: 25
- `line_count`: 1
- `sha256`: 23ed3d85962bd1d785adf5f5d190eb7c304fdb2478c789b5b7584704beb9eeb6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: json evidence; size=25 bytes; lines=1; markers=<none>; tail={"manifest_absent":true}

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/mutations.log

- `kind`: log
- `size_bytes`: 1138
- `line_count`: 10
- `sha256`: 547e8bceaefa8ed2fbd77df2898a8eb5399b7a5241ab1f2bf1ab2d2ac4ee2c8d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=1138 bytes; lines=10; PASS=20; tail=[V8Y-MUTATION][PASS] name=control_admit_b compile_rc=0 sim_rc=1 witness=V8Y two controls simultaneously resident [V8Y-MUTATION][PASS] name=youngest_control_select compile_rc=0 sim_rc=1 witness=V8Y oldest branch A issue PC [V8Y-MUTATION][PASS] name=resolve_i...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/regressions.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/simulator-config.txt

- `kind`: txt
- `size_bytes`: 508
- `line_count`: 7
- `sha256`: 2b779d5cdba7d347d1e5bc7176d81a304b5b32617e346e50baa341b7239af35f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: txt evidence; size=508 bytes; lines=7; markers=<none>; tail=schema=rv64-ooo4-simulator-config-v1 target=v8y-speculation-recovery focused_assert_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT focused_release_ivflags=-g2012 -Wall -I../vsrc -I../vsrc/include -Icommon mutation_defines=-DOOO_ASSER...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/source-snapshot-post.log

- `kind`: log
- `size_bytes`: 165
- `line_count`: 1
- `sha256`: e3f4227a1de5ff2f786a0b790bc771fd133d90017753f8b840543c7b5d5c05e6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=165 bytes; lines=1; PASS=2; tail=[V8Y-OOO4-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/sources.post.sha256

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/static/source-snapshot-pre.log

- `kind`: log
- `size_bytes`: 164
- `line_count`: 1
- `sha256`: 1ee7aa4e10257005f96a56ee21dec1ad4d2debed530a1ff69fc97ec0f3b54628
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=164 bytes; lines=1; PASS=2; tail=[V8Y-OOO4-SNAPSHOT][PASS] output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/sources.pre.sha256

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-current/suite-run-id.txt

- `kind`: txt
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 5f610b3be39c1049d9d8cfb727586571c06db112a9c7bc3d1cabbb29d7be32ad
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: txt evidence; size=33 bytes; lines=1; markers=<none>; tail=v8y-ooo4-20260801T233216Z-243405

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/block_killed_station_promotion.log

- `kind`: log
- `size_bytes`: 160315
- `line_count`: 1184
- `sha256`: c0c67863c29f85f7749ec7ea3101edbfe797e92aae654f2ac5cafb0243d53def
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 16, "PASS": 7}
- `summary`: log evidence; size=160315 bytes; lines=1184; FAIL=16; PASS=7; tail=g: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/completion_replay_one_cycle.log

- `kind`: log
- `size_bytes`: 162225
- `line_count`: 1197
- `sha256`: 5f0a9965b302cdfc1efe818fadb5c85c51baadea55f73f16d62669f276bedb70
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"ERROR": 12, "FAIL": 5, "PASS": 7}
- `summary`: log evidence; size=162225 bytes; lines=1197; FAIL=5; ERROR=12; PASS=7; tail='. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'ent...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/control_admit_b.log

- `kind`: log
- `size_bytes`: 159920
- `line_count`: 1179
- `sha256`: 527febc06709b2ca7657e66d17caceb39f98b358b253b9c7a1aec10f876835f0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 11, "PASS": 7}
- `summary`: log evidence; size=159920 bytes; lines=1179; FAIL=11; PASS=7; tail='entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/iq_kill_holder_bypass.log

- `kind`: log
- `size_bytes`: 159934
- `line_count`: 1181
- `sha256`: 3e43f3f4534d8f07466bbff4ce2bc6686d66abeac0974b3f9af688021aef9fe7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 13, "PASS": 7}
- `summary`: log evidence; size=159934 bytes; lines=1181; FAIL=13; PASS=7; tail=entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words i...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/mask_active_recovery_while_station_valid.log

- `kind`: log
- `size_bytes`: 160325
- `line_count`: 1184
- `sha256`: 923e06440c3032ae16361d2e6c420eb6c075077088ec389b89bed550015cbd6d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 16, "PASS": 7}
- `summary`: log evidence; size=160325 bytes; lines=1184; FAIL=16; PASS=7; tail=31: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChe...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/resolve_issue_close_bypass.log

- `kind`: log
- `size_bytes`: 159900
- `line_count`: 1175
- `sha256`: 107da234e1728c3a9cadb4985bfa51c7f7fe577e14507b0ed243161f412b35f3
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 7, "PASS": 7}
- `summary`: log evidence; size=159900 bytes; lines=1175; FAIL=7; PASS=7; tail=src/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/n...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/retire1_owner_remap.log

- `kind`: log
- `size_bytes`: 159499
- `line_count`: 1173
- `sha256`: 32b525b610244baee243ad6e99be358da0ceac3e468dc1fbfa74b6142daf12ac
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 5, "PASS": 7}
- `summary`: log evidence; size=159499 bytes; lines=1173; FAIL=5; PASS=7; tail=s sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warn...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/rob_tail_boundary_off_by_one.log

- `kind`: log
- `size_bytes`: 159326
- `line_count`: 1171
- `sha256`: 3ad48b0138a56f5004973d3f4faf6ee8e23116a6308246c232ab257eaf97a08b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"FAIL": 3, "PASS": 7}
- `summary`: log evidence; size=159326 bytes; lines=1171; FAIL=3; PASS=7; tail=kbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/summary.json

- `kind`: json
- `size_bytes`: 8614
- `line_count`: 208
- `sha256`: 87db0eb3308f2824a0cefad4e322aab5b822f821ecbc810bb3b20291304124a4
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {}
- `summary`: json evidence; size=8614 bytes; lines=208; markers=<none>; tail={ "adapter_sha256": "efaa7a340ce27a5df4e519c302e028319ce6dafdd8028628ca96483e5108c627", "compile_success": 9, "dynamic_rejected": 9, "required": 9, "results": [ { "compile_rc": 0, "compile_success": true, "dynamic_rejected": true, "log": ".github/task-runs/...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/ooo4-mutations/youngest_control_select.log

- `kind`: log
- `size_bytes`: 168808
- `line_count`: 1283
- `sha256`: 57a88f514677137a753524f528f07da8555215185cd9e3c1e6ca91ab5af1437c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"ERROR": 8, "FAIL": 99, "PASS": 7}
- `summary`: log evidence; size=168808 bytes; lines=1283; FAIL=99; ERROR=8; PASS=7; tail=s sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warni...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/pre-delivery-review.md

- `kind`: md
- `size_bytes`: 2227
- `line_count`: 47
- `sha256`: 924b8d802c89ae55f82c91ded0c47a13007ac2aa3fbdecac7ecc20967d528b65
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 10}
- `summary`: md evidence; size=2227 bytes; lines=47; PASS=10; tail=# V13V OOO-4 frozen-material pre-delivery review ## Contract - Task: `v13v-ooo4-frozen-final-review-v2` - Contract JSON SHA-256: `07da32b6361a5cf919a90e2f9b6e360525c052d1dc6f4624b1e950f3632a5ba5` - Mode: `self-contained-no-tools`; no command or file write w...

### .github/task-runs/2026-08-02-rv64-v13v-ooo4-current-rebind-v1/evidence/speculation-recovery.log

- `kind`: log
- `size_bytes`: 6599
- `line_count`: 48
- `sha256`: 967fc314e2e6ff285982f9f826dca7104d867bf4c75dfd9d5ec863cd23d8ae05
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T23:44:31+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=6599 bytes; lines=48; PASS=2; tail=OOO-4 local RV64 speculation and recovery evidence task_run_id=2026-08-02-rv64-v13v-ooo4-current-rebind-v1 suite_run_id=v8y-ooo4-20260801T233216Z-243405 generated_at_utc=2026-08-01T23:32:58.189083+00:00 design_id=sha256:093c2380b997029944aa4462015d83711d7c5...
