# Evidence Index

## 基本信息

- `task_id`: 2026-07-19-rv64-v8b-producer-kill-now
- `task_slug`: 
- `profile`: 
- `asset_count`: 291
- `total_size_bytes`: 3641187

## 证据资产

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/broad-gates-hash-check-r1.log

- `kind`: log
- `size_bytes`: 2548
- `line_count`: 21
- `sha256`: 889e30241623193d253681740fb1f97ae1589a1301de5058bbce1e9e8091ce85
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=2548 bytes; lines=21; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/run-producer-kill-broad-gates.sh: OK /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/summary.txt: OK /home/lyg/PA/ysy...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/broad-gates-r1.complete

- `kind`: complete
- `size_bytes`: 367
- `line_count`: 2
- `sha256`: 2ed338766c4c199e7eb8e0c46789b0ce730a3564c175fb6beeb337f560e3066d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: complete evidence; size=367 bytes; lines=2; markers=<none>; tail=4820b8305cfd1824dc37130b26e27fada29643a66a89f57a7d7dc4ae35a01dd4 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/broad-gates-summary-r1.txt 99e9f1bee73941c7f5fb895e38e094193dbc8b3d48ef27390ea30208e7bb829d /home/l...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/broad-gates-r1.sha256

- `kind`: sha256
- `size_bytes`: 3850
- `line_count`: 21
- `sha256`: 99e9f1bee73941c7f5fb895e38e094193dbc8b3d48ef27390ea30208e7bb829d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3850 bytes; lines=21; markers=<none>; tail=278a2fa59c0b31319c056c882ee9f74cadf3a984582a62ffbf49f9a93235ec63 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/run-producer-kill-broad-gates.sh 0d8545550dd60c7132eaf08ae7ce87737993a4b26052ee88deac18e63aace7ae /home/lyg/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/broad-gates-summary-r1.txt

- `kind`: txt
- `size_bytes`: 594
- `line_count`: 13
- `sha256`: 4820b8305cfd1824dc37130b26e27fada29643a66a89f57a7d7dc4ae35a01dd4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 12}
- `summary`: txt evidence; size=594 bytes; lines=13; PASS=12; tail=RV64 v8b-prep producer kill-now broad gate summary r1 focused=PASS release/assert 4/4,4096-age,13/13-mutation module_aggregate=PASS 104/104 rtl_style_full=PASS contract=PASS producer_kill_static_contract=PASS global_strict_lint=RED inherited rc=2 warning_co...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/check-contract-r1.log

- `kind`: log
- `size_bytes`: 273
- `line_count`: 4
- `sha256`: e339e23601db25eb34cfe55f9caf69b0baf876bce180c0ec334e5f4d765b9a7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=273 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=289 基线=89 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 289≥89 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/clmul-r1/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 9b9f82429e8715c17c05bbc90ddad0d836822a986346bd7cb83864db9e048256
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-v8b-kill-clmul/tb_ooo_clmul_unit.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/clmul-r1/summary.txt

- `kind`: txt
- `size_bytes`: 265
- `line_count`: 10
- `sha256`: a70ae89a0e86a433ab9d73ad147374752b8439c1ad36ce976692a5afbced727a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=265 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/clmul-r1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_clmul_unit - total: 1 - passed: 1 - faile...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-canonical-r1.log

- `kind`: log
- `size_bytes`: 238
- `line_count`: 2
- `sha256`: d024856ced8b2cbcae5993ba8957316518ca46c7d2625f0890e2825df54983fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=238 bytes; lines=2; PASS=4; tail=[V8B-KILL-NOW][PASS] release/assert=4/4 mutations=13/13 checker/style/Yosys PASS; FP strict inherited RED=43 [V8B-KILL-NOW][EVIDENCE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-completion-check-r1.log

- `kind`: log
- `size_bytes`: 645
- `line_count`: 5
- `sha256`: c1d4f3ad771388a87414be4e38c321fc22bb0a960148f6e817828c0571199f77
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=645 bytes; lines=5; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/summary.txt: OK /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/sources.sha256: OK /home/lyg/PA/y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/completion.marker

- `kind`: marker
- `size_bytes`: 955
- `line_count`: 5
- `sha256`: e77e8c564d5a9fda305f66d841db9a0d5de2c2dffbc1cbd94e0661293b3f4c92
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: marker evidence; size=955 bytes; lines=5; markers=<none>; tail=0d8545550dd60c7132eaf08ae7ce87737993a4b26052ee88deac18e63aace7ae /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/summary.txt 2bcf269794fce8970e23ca27969e69c739b01be03625616765a42984b9a98f0d /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/checker-self-test.log

- `kind`: log
- `size_bytes`: 209
- `line_count`: 4
- `sha256`: b5462203004f640c9d613def3c32a4a558c16e36e4b3b1a26a892ad13fb3866d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=209 bytes; lines=4; PASS=8; tail=[V8B-KILL-CHECKER][SELFTEST][PASS] clmul-no-kill-valid [V8B-KILL-CHECKER][SELFTEST][PASS] fp-ambient-head [V8B-KILL-CHECKER][SELFTEST][PASS] cut-clmul-provenance [V8B-KILL-CHECKER][SELFTEST][PASS] mutations=3

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/clmul-verilator-assert.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/clmul-verilator-release.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/clmul-yosys.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/fp-verilator-nonfatal.log

- `kind`: log
- `size_bytes`: 19280
- `line_count`: 187
- `sha256`: 8f2b3a87667a260dd635fe416c48ceb7db3f903ecf7cf93015f0f7c890444bbc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=19280 bytes; lines=187; markers=<none>; tail=%Warning-WIDTHEXPAND: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v:493:37: Operator GT expects 32 or 14 bits on the LHS, but LHS's VARREF 'norm_required' generates 8 bits. : ... note: In instance 'OooFpArithGate' 493 | norm_shift = (no...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/fp-verilator-strict.log

- `kind`: log
- `size_bytes`: 19317
- `line_count`: 188
- `sha256`: f28b012f75e45f576730fdccfa984d6c693ba4fd5134219397510d9b982008c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=19317 bytes; lines=188; markers=<none>; tail=%Warning-WIDTHEXPAND: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v:493:37: Operator GT expects 32 or 14 bits on the LHS, but LHS's VARREF 'norm_required' generates 8 bits. : ... note: In instance 'OooFpArithGate' 493 | norm_shift = (no...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/fp-yosys.log

- `kind`: log
- `size_bytes`: 698
- `line_count`: 5
- `sha256`: b88feed78ad985d62e18c7a7d259e23a15fb4c51eb20ef9782319eb8e48d0732
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=698 bytes; lines=5; markers=<none>; tail=Warning: Replacing memory \meta_kind_q with list of registers. See /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v:1443 Warning: Replacing memory \meta_double_q with list of registers. See /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/mutations.log

- `kind`: log
- `size_bytes`: 1062
- `line_count`: 14
- `sha256`: 5788449cbf9455e482e1268deadb0aa68a1495df99425824c3c3d46d6cc277a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=1062 bytes; lines=14; PASS=28; tail=[V8B-KILL-MUTATION][PASS] clmul-ambient-function: kill-valid/cut/head only-toggle [V8B-KILL-MUTATION][PASS] clmul-no-new-kill-valid: kill-valid low request [V8B-KILL-MUTATION][PASS] clmul-no-inflight-kill-valid: nonmatching/kill-low survivor [V8B-KILL-MUTAT...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/rtl-style.log

- `kind`: log
- `size_bytes`: 99
- `line_count`: 1
- `sha256`: 51b1e30a04650d09e1dc3fe5df28316ee495d00e1069812bf2b1bf806434bfb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=99 bytes; lines=1; PASS=2; tail=[check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/gates/structural-contract.log

- `kind`: log
- `size_bytes`: 85
- `line_count`: 1
- `sha256`: e7962ea93c7246f1bbcaeb05d14def13c7748035faba902d54f47e2e3e0341e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=85 bytes; lines=1; PASS=2; tail=[V8B-KILL-CHECKER][PASS] explicit kill dependencies and production provenance locked

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-ambient-function.log

- `kind`: log
- `size_bytes`: 970
- `line_count`: 20
- `sha256`: c60d22e67420251f1c28035996f32c8d3720c5e4a9dc6331055da480dcd9f9e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 22}
- `summary`: log evidence; size=970 bytes; lines=20; FAIL=22; tail=mutation=clmul-ambient-function witness=kill-valid/cut/head only-toggle compile_rc=0 sim_rc=1 [CHECK-FAIL] kill-valid only toggle is immediately visible got=0 expected=1 [CHECK-FAIL] same-cycle killed request stays idle got=0 expected=1 [CHECK-FAIL] run kil...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-inclusive-boundary.log

- `kind`: log
- `size_bytes`: 20676
- `line_count`: 268
- `sha256`: db8cfcca2b8c67d113b510db38b27217c3f1bfb4629cfc870c86e3e601639d93
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 518}
- `summary`: log evidence; size=20676 bytes; lines=268; FAIL=518; tail=mutation=clmul-inclusive-boundary witness=4096 age sweep equal boundary compile_rc=0 sim_rc=1 [CHECK-FAIL] exhaustive kill predicate head=0 cut=0 victim=0 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=0 cut=1 victim=1 got=1 expected=0 [CHECK-...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-no-holder-clear.log

- `kind`: log
- `size_bytes`: 634
- `line_count`: 15
- `sha256`: eaacced917f3ffc50370822b5f1ddbd230117c988e393665a4314d92fe533fa5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 12}
- `summary`: log evidence; size=634 bytes; lines=15; FAIL=12; tail=mutation=clmul-no-holder-clear witness=RUN/RESP kill state clear and reissue compile_rc=0 sim_rc=1 [CHECK-FAIL] run kill clears held producer got=0 expected=1 [CHECK-FAIL] same-index replacement ready before request got=0 expected=1 [CHECK-FAIL] same-index...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-no-inflight-kill-valid.log

- `kind`: log
- `size_bytes`: 1254
- `line_count`: 24
- `sha256`: 7e90518069c949a6d15cf0ce98e7e1e3076079c29a491676affab8fe26614b63
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 30}
- `summary`: log evidence; size=1254 bytes; lines=24; FAIL=30; tail=mutation=clmul-no-inflight-kill-valid witness=nonmatching/kill-low survivor compile_rc=0 sim_rc=1 [CHECK-FAIL] run kill is immediately visible got=0 expected=1 [CHECK-FAIL] same-index replacement resp_valid got=0 expected=1 [CHECK-FAIL] same-index replaceme...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-no-new-kill-valid.log

- `kind`: log
- `size_bytes`: 1361
- `line_count`: 26
- `sha256`: b84ba9c1848b223e6f989521147d6aa939848ca90f2e19c3d44ddfbb5261b30d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 34}
- `summary`: log evidence; size=1361 bytes; lines=26; FAIL=34; tail=mutation=clmul-no-new-kill-valid witness=kill-valid low request compile_rc=0 sim_rc=1 [CHECK-FAIL] kill-valid low leaves new request live got=1 expected=0 [CHECK-FAIL] run kill is immediately visible got=0 expected=1 [CHECK-FAIL] same-index replacement resp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-no-new-request-kill.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 11
- `sha256`: 7237c7c13c59d6f9be5dc57c7964cd40384a79b64c2eb6100ea1256d3b9afca0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=340 bytes; lines=11; FAIL=4; tail=mutation=clmul-no-new-request-kill witness=same-cycle killed request stays idle compile_rc=0 sim_rc=1 [CHECK-FAIL] same-cycle killed request stays idle got=0 expected=1 [FAIL] tb_ooo_clmul_unit errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-no-response-mask.log

- `kind`: log
- `size_bytes`: 338
- `line_count`: 11
- `sha256`: 920f78b7b42c19be8fc021535b9de056146fb14f6cd536494f6b45b69ec89104
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=338 bytes; lines=11; FAIL=4; tail=mutation=clmul-no-response-mask witness=backpressured RESP same-cycle mask compile_rc=0 sim_rc=1 [CHECK-FAIL] response kill masks valid in same cycle got=1 expected=0 [FAIL] tb_ooo_clmul_unit errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/co...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/clmul-raw-index-age.log

- `kind`: log
- `size_bytes`: 108078
- `line_count`: 1372
- `sha256`: b5d22c96948b44db55bbfa7d9dca7f2529eaa9ce501ff56393e45f0e732c8a7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 1655}
- `summary`: log evidence; size=108078 bytes; lines=1372; FAIL=1655; tail=m=12 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=7 cut=5 victim=13 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=7 cut=5 victim=14 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=7 cut=5 victim=15 got=1 expected=...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/fp-ambient-function.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 13
- `sha256`: 61f5aadd94a1bee3f5d15e749c0ab773457ce94a99fea14067ea5431276ef23c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 8}
- `summary`: log evidence; size=471 bytes; lines=13; FAIL=8; tail=mutation=fp-ambient-function witness=FP cut/kill/head only-toggle compile_rc=0 sim_rc=1 [CHECK-FAIL] fp cut-only toggle masks output got=1 expected=0 [CHECK-FAIL] fp kill-valid only toggle masks output got=1 expected=0 [CHECK-FAIL] fp head-only toggle masks...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/fp-no-output-mask.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 13
- `sha256`: e1b22379bad1eaac32462d4b619641e58910386e0d671e4f49cf211b8a94b1c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 8}
- `summary`: log evidence; size=466 bytes; lines=13; FAIL=8; tail=mutation=fp-no-output-mask witness=FP stage5 same-cycle mask compile_rc=0 sim_rc=1 [CHECK-FAIL] fp cut-only toggle masks output got=1 expected=0 [CHECK-FAIL] fp kill-valid only toggle masks output got=1 expected=0 [CHECK-FAIL] fp head-only toggle masks wrap...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/fp-no-propagation-kill.log

- `kind`: log
- `size_bytes`: 336
- `line_count`: 11
- `sha256`: d3e8bb1c04fdbef8fa60443992e722ccbeac238c0294e7253403fd3f79a4408f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=336 bytes; lines=11; FAIL=4; tail=mutation=fp-no-propagation-kill witness=FP in-flight younger meta delayed pulse compile_rc=0 sim_rc=1 [CHECK-FAIL] launch killed younger meta valid got=1 exp=0 [FAIL] tb_ooo_fp_arith_gate errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/fp-raw-index-age.log

- `kind`: log
- `size_bytes`: 326
- `line_count`: 11
- `sha256`: 68b6078c2003d859ee40c2dfabb8f0c1583993ec584ef487603db11424f64a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=326 bytes; lines=11; FAIL=4; tail=mutation=fp-raw-index-age witness=FP head-only wrap compile_rc=0 sim_rc=1 [CHECK-FAIL] fp head-only toggle masks wrap-younger output got=1 expected=0 [FAIL] tb_ooo_fp_arith_gate errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/fp-reversed-age.log

- `kind`: log
- `size_bytes`: 647
- `line_count`: 16
- `sha256`: 0c1565d268ad3809d1ef38962e2e2de78cdd35684a5c1f336692687a7d67b5fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 14}
- `summary`: log evidence; size=647 bytes; lines=16; FAIL=14; tail=mutation=fp-reversed-age witness=FP survivor/victim polarity compile_rc=0 sim_rc=1 [CHECK-FAIL] fp nonmatching kill preserves output got=0 expected=1 [CHECK-FAIL] fp cut-only toggle masks output got=1 expected=0 [CHECK-FAIL] fp kill-valid only toggle masks...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/mutations/summary.txt

- `kind`: txt
- `size_bytes`: 32
- `line_count`: 3
- `sha256`: bc5d14aa6e73517d411c9c9cf9d212781a62785be98cbb6645cf0722ff83fbc0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: txt evidence; size=32 bytes; lines=3; markers=<none>; tail=mutations=13 passed=13 failed=0

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/assert/tb_ooo_clmul_unit.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/assert/tb_ooo_clmul_unit.sim.log

- `kind`: log
- `size_bytes`: 125
- `line_count`: 2
- `sha256`: c64ffa50bff19f0b173d6f38355a57970228d61fafac335aab55604342601b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=125 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_clmul_unit /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 5330 (1s)

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/assert/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 128157
- `line_count`: 3341
- `sha256`: 1ed851388f191a7a7a4485847614dd2f1a27f3917b399558f7d73bcb4fc9f0db
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=128157 bytes; lines=3341; FAIL=7; PASS=1; tail=%fork TD_tb_ooo_clmul_unit.reset_dut, S_0x60e6dbd2f860; %join; %free S_0x60e6dbd2f860; %alloc S_0x60e6dbd2ea10; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_ve...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/assert/tb_ooo_fp_arith_gate.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/assert/tb_ooo_fp_arith_gate.sim.log

- `kind`: log
- `size_bytes`: 127
- `line_count`: 2
- `sha256`: 5923da039c8ffb780674199dbbb6cad758f83470a9ddb89d0ea02da88afc4b07
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=127 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_fp_arith_gate /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 966 (1s)

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/assert/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 387216
- `line_count`: 11665
- `sha256`: cf2a70afc680c8a21051f7009222abb83254eb8ee0cd6bb486fbe908f8436d0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=387216 bytes; lines=11665; FAIL=5; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/release/tb_ooo_clmul_unit.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/release/tb_ooo_clmul_unit.sim.log

- `kind`: log
- `size_bytes`: 125
- `line_count`: 2
- `sha256`: c64ffa50bff19f0b173d6f38355a57970228d61fafac335aab55604342601b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=125 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_clmul_unit /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 5330 (1s)

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/release/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 128157
- `line_count`: 3341
- `sha256`: 8d76bc57a87f4accdc6ecd3e62448f433afe8ca47983d422f9b1474394152576
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=128157 bytes; lines=3341; FAIL=7; PASS=1; tail=%fork TD_tb_ooo_clmul_unit.reset_dut, S_0x64cd43ab1860; %join; %free S_0x64cd43ab1860; %alloc S_0x64cd43ab0a10; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_ve...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/release/tb_ooo_fp_arith_gate.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/release/tb_ooo_fp_arith_gate.sim.log

- `kind`: log
- `size_bytes`: 127
- `line_count`: 2
- `sha256`: 5923da039c8ffb780674199dbbb6cad758f83470a9ddb89d0ea02da88afc4b07
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=127 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_fp_arith_gate /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 966 (1s)

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/positive/release/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 386498
- `line_count`: 11632
- `sha256`: 8e17e4fc659d4a9560b92b5d2c2f855df8e3c03e9871c2b03059c19eb5ec7975
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=386498 bytes; lines=11632; FAIL=5; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/sources-check.log

- `kind`: log
- `size_bytes`: 986
- `line_count`: 11
- `sha256`: c8482472583173fcb2eb82a680e93878bbf060f7d5b3be837f9b6881e1c3d561
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=986 bytes; lines=11; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_clmul_unit.sv: OK /home/lyg/PA/ysyx-workbench/npc/rv64/te...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 1668
- `line_count`: 11
- `sha256`: 2bcf269794fce8970e23ca27969e69c739b01be03625616765a42984b9a98f0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1668 bytes; lines=11; markers=<none>; tail=00af91c2c543e09528a6d2f6f1e5d134497a19ad2af5aed337d56602263e98f4 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v 253e3d89f20afc42d58cd246ea0d49d46526000bce5206235825ed5186759276 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGa...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 1668
- `line_count`: 11
- `sha256`: 2bcf269794fce8970e23ca27969e69c739b01be03625616765a42984b9a98f0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1668 bytes; lines=11; markers=<none>; tail=00af91c2c543e09528a6d2f6f1e5d134497a19ad2af5aed337d56602263e98f4 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v 253e3d89f20afc42d58cd246ea0d49d46526000bce5206235825ed5186759276 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGa...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/sources.sha256

- `kind`: sha256
- `size_bytes`: 1668
- `line_count`: 11
- `sha256`: 2bcf269794fce8970e23ca27969e69c739b01be03625616765a42984b9a98f0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1668 bytes; lines=11; markers=<none>; tail=00af91c2c543e09528a6d2f6f1e5d134497a19ad2af5aed337d56602263e98f4 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v 253e3d89f20afc42d58cd246ea0d49d46526000bce5206235825ed5186759276 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGa...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-r2/summary.txt

- `kind`: txt
- `size_bytes`: 893
- `line_count`: 19
- `sha256`: 0d8545550dd60c7132eaf08ae7ce87737993a4b26052ee88deac18e63aace7ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 16}
- `summary`: txt evidence; size=893 bytes; lines=19; PASS=16; tail=RV64 v8b-prep production producer kill-now summary scope=CLMUL-and-FP-arithmetic-producer-local release_positive=2/2 PASS assert_positive=2/2 PASS clmul_age_sweep=4096/4096 PASS compile_success_mutations=13/13 KILLED_BY_SEMANTIC_ORACLE structural_checker=PA...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/focused-sources-check-r1.log

- `kind`: log
- `size_bytes`: 986
- `line_count`: 11
- `sha256`: c8482472583173fcb2eb82a680e93878bbf060f7d5b3be837f9b6881e1c3d561
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=986 bytes; lines=11; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooClmulUnit.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooFpArithGate.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_clmul_unit.sv: OK /home/lyg/PA/ysyx-workbench/npc/rv64/te...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/fp-r1/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 16d851b44fa0a4846bb56eddcda83bf063cefb59e367fb2da8a62ce57cd8c58b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-v8b-kill-fp/tb_ooo_fp_arith_gate.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/fp-r1/summary.txt

- `kind`: txt
- `size_bytes`: 265
- `line_count`: 10
- `sha256`: 77fc231e7f982f3ed9d081db0443355f1da05fcfac78e78dd84a5f8082c5fe21
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=265 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/fp-r1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_fp_arith_gate - total: 1 - passed: 1 - faile...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/full-build-r1.log

- `kind`: log
- `size_bytes`: 64228
- `line_count`: 691
- `sha256`: 23b860c895f7d5d104fd89408acb24b223bcaaf3cc33cc7fcee9e6de12d9d083
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=64228 bytes; lines=691; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/full-build-r1.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/git-diff-check-r1.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/lint-nonfatal-r1.log

- `kind`: log
- `size_bytes`: 62577
- `line_count`: 685
- `sha256`: de9b4a17fd205516dadefb2f82f0ae234a5a2728916ab646cf1fbbd94bd3936d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=62577 bytes; lines=685; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/lint-nonfatal-r1.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-aggregate-r2.log

- `kind`: log
- `size_bytes`: 3744
- `line_count`: 118
- `sha256`: ecfe964e7630f43601755ce16a49a85359b445bc17870e4046fad0ecb6448f01
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 210}
- `summary`: log evidence; size=3744 bytes; lines=118; PASS=210; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: 63a694f1e3cbeda7a501542c521696140f2fe1dab9b994ae358eea10285510e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build-v8b-kill-module/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 393
- `line_count`: 5
- `sha256`: 5b62e6d7dc6b66f199c9e9bc0639c88b8ebbc4aefa7f7ce7d52bed7fc4f9d132
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=393 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build-v8b-kill-module/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/n...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3493
- `line_count`: 28
- `sha256`: d6f9f0beb33c269ff8fa93f7adb4017d410bd009c45ddbd495054a46b7fb6257
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3493 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build-v8b-kill-module/tb_axi_exec_firewall.vvp /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 6
- `sha256`: b1ddaeb1d9d73cdf0f1775455778eda6815200803f8f7faeae398ab60ce59d75
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build-v8b-kill-module/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 6
- `sha256`: 1c183f275fe9fd8bdd0a1d948e8b846c7a077f48306942e7e713f7a89ff613a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o build-v8b-kill-module/tb_axi_reset_syscon.vvp /home/ly...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: fcee55cb3dc79b1c121352e2bbff306a5c089c104a502d939e701febf185e656
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build-v8b-kill-module/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3273
- `line_count`: 28
- `sha256`: b5812ce512baf77e016ae3a7a6d60dc6f9c88356369b8e282c82dfdf329733b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3273 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build-v8b-kill-module/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: 946f0f1d6e35e7d8d8c95d3fd49dfcf689ec85e413b27a0cff5d91bfd7a2bded
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build-v8b-kill-module/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: 7bff44e178672f5fc7f041f0eb76a34deea34c91bce627dc42ff3877b8c590b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build-v8b-kill-module/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: f915d3dd02e3898e5db3d28c3bfaba9ee76ba5cc0ddc8f19c574fdaddc868f7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build-v8b-kill-module/tb_decode_stage.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 407
- `line_count`: 5
- `sha256`: 7da4b824805a79cb77b6a73e5adf03d74cba2a8c925a2aecd38f065889038a60
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=407 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build-v8b-kill-module/tb_decode_unit.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1e08896bf62626bdd06d35f98111dad3e05c9074ba36a81e7602504a88fecddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build-v8b-kill-module/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 6af2c75a2c3357d889be5052420a01ffe57dad33253dae95ee3e00a342ecb879
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build-v8b-kill-module/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memor...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 406
- `line_count`: 5
- `sha256`: 381bac0dd992a7aa417da1895aa4208a79a6e5631dea36212b0820948f135fa2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=406 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build-v8b-kill-module/tb_lsu_control.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: 1de9a1b10b6b4ede602a1b8447414f9f57a4065090d0fa4b074304b1b17c5947
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build-v8b-kill-module/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15698
- `line_count`: 95
- `sha256`: f3d48613a1bf4420a1180c706cab43ae7395d4363691f2bf04c46ff84642255d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15698 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build-v8b-kill-module/tb_ooo_alu_core_slice.vvp /h...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15526
- `line_count`: 93
- `sha256`: 01b37a77cf097045b0723139fbc49741f8deed5c80650b1873fe089fae1a3e8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15526 bytes; lines=93; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build-v8b-kill-module/tb_ooo_alu_decode_ba...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: a64e3c5000fb5276786a32e61b431f71f0bbb715fa40ba83cf519ad810b8736d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build-v8b-kill-module/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: 6ec281d9e99f8649212cde0090c1b2f8d93feec68335b4d0dd5d3c4e9884e70a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build-v8b-kill-module/tb_ooo_backend...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 953f6b25c5e59e92767cfebe42a70238336792d5b37bad9d8393be66ab712f9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build-v8b-kill-module/tb_ooo_bitmanip_gate.vvp /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 869
- `line_count`: 9
- `sha256`: aa95024714ca6d9b2e145171c7fb269b1c2d5f41c7a15699a93b94ce2003a6f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=869 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build-v8b-kill-module/tb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 824
- `line_count`: 9
- `sha256`: d8f1735c7ecb99bf51b61a2240698a562fa57c8a663d23175a22094ca943c02c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=824 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build-v8b-kill-module/tb_ooo_branc...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 607
- `line_count`: 5
- `sha256`: 3cbe44392fd50ea73ec01a18acc77797d55c5e5ae4cce48185dc9aa34d184c40
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=607 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build-v8b-kill-module/tb_o...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 879
- `line_count`: 9
- `sha256`: 7e905cc89bb7339ea3302380d4f66437c29594db396122b70da3a8666efb9729
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=879 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build-v8b-kill-module/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: c3f6b21a6972f33a15a5cfc20094a4e654888b8d8356d273b85cd0d6796d1f2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build-v8b-kill-module/tb_ooo_branch_spec...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 564
- `line_count`: 6
- `sha256`: d1a94b2e6b7cae4c1e57acd7d6c1e2349dcff5e48acc79c2eb0f02ce94114abb
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=564 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build-v8b-kill-module/tb_ooo_busy_table.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 24821e7b5fef6e9b0e4e1cea117e538376855313e3eb28a90a388158a0a4e17e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-v8b-kill-module/tb_ooo_clmul_unit.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 782
- `line_count`: 9
- `sha256`: 9f02b61aa369a1dc747a17b5eb8e89083755aeb8cc02b4f66b0e9e72039af43c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=782 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build-v8b-kill-module/tb_ooo_commit_output_m...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 847
- `line_count`: 9
- `sha256`: 8f5957a1616379b9f07d21e71e09711c71cd8534474ac0dae389122cc60abd0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=847 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build-v8b-kill-module/tb_ooo_c...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 834
- `line_count`: 9
- `sha256`: 4a635a81f5a86e52add86e28a50681c983b33d437efc25c05c5f02077c9f4349
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=834 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build-v8b-kill-module/tb_ooo_con...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15762
- `line_count`: 69
- `sha256`: 203ef783c22cae8650a4264e0a0bb5c81866ce9279acc1752ed068165db65cba
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15762 bytes; lines=69; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build-v8b-kill-module/tb_ooo_core_top_glue.vvp /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 512
- `line_count`: 5
- `sha256`: 76feae3d920e915afe4429b770510f794ef95d063115869c429e512257337fdc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=512 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build-v8b-kill-module/tb_ooo_csr_a...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 184ff440c33f3e58b4101681194dc0c7a8981bae6da110db8eb08aa09e9aa278
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build-v8b-kill-module/tb_ooo_csr_trap_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 5
- `sha256`: 5b68e3952c88a9a8c96f49f142c09b04c3783569fe10825e2a68840174bbc7ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build-v8b-kill-module/tb_ooo_data_word_cache.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 5
- `sha256`: 60c9cf387c757842c8dfa783687b109767afe5fb181a8fc80e5baadae62b0e8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=520 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build-v8b-kill-module/tb_o...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: 4607fe97dfe087875fba89deee4024e984eb3b2150a6113992332a32340ff93b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build-v8b-kill-module/tb_ooo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: e64362db233bdff042aa3b6c5d70cdf70b36ba9d5d9b2de63cb5081b570d3c00
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build-v8b-kill-module/tb_ooo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5417
- `line_count`: 37
- `sha256`: 5b9fccb6eb1946477751533221321a4c1d5a09671f780ce34af0685345598067
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=5417 bytes; lines=37; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build-v8b-kill-module/tb_ooo_dispatch_backend....

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106881
- `line_count`: 846
- `sha256`: c2c047754004f028479c4f508d8de8dfdfe2569c056cd8f9f548c0a3c6e932f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106881 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103624
- `line_count`: 779
- `sha256`: a8c1be56e86f724ea55fb3fa891753c96e12db3c19d2de3ee2f94b09423e5a6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103624 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104428
- `line_count`: 788
- `sha256`: f468d818715c5ac0006762ec251f76441c0256624e894f3f2da85e4cf5ec0236
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104428 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106561
- `line_count`: 802
- `sha256`: 0375ea00cd5cd4e69a4bc9166b2af459c460112f7c71930e8dfe2757cfe9e1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106561 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: 0ee5a42ce1b9b736b78f03480aa41d0922ea87a6ee8aaf77f4a7e77ad79f24a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=481 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build-v8b-kill-module/tb_ooo_fetch_branc...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: f92234dc05a94e90075ed2322097951b45fbc36d59d1fb27ee6fe6204ba4b830
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build-v8b-kill-module/tb_ooo_fetch_flow_co...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 649
- `line_count`: 5
- `sha256`: 0b83e3afc9f1d94bdef1a808318bfee2cac91038a537b10218a40daa667faba7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=649 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build-v8b-kill-module/tb_ooo_f...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 701
- `line_count`: 5
- `sha256`: 2d2657fa1b398d581870a8c346938e92a0e670c0a8cf377e68acda21f2e6a76d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=701 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build-v8b-kill-module/tb_ooo_fetch_hea...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 5
- `sha256`: c7997b095b937a623da254bb1e04dd595b46c004865374b05a91615ff7dac659
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=610 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build-v8b-kill-module/tb_ooo_fetch_packet_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 621
- `line_count`: 6
- `sha256`: 8ad25e810911587d7e6ab4c7ce109b8474ecf3aa4c53a726a45ce49fa8657914
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=621 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build-v8b-kill-module/tb_ooo_fetch_packe...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 800
- `line_count`: 10
- `sha256`: 1b240d7f58dab132a529370a1811addc3bcdc827cfc46e2d62cab136ef319955
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=800 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build-v8b-kill-module/tb_ooo_fetch_packet_fi...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 489
- `line_count`: 5
- `sha256`: 0fba961ce3665a4cac4410da5295c0d564082bfe5d7d44effbc9ad530dbd80c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=489 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build-v8b-kill-module/tb_ooo_fetch_p...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 2919ad3a9c86abebc378fd692e26c07baeddf3b185a22d1e0501f462755a2e36
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build-v8b-kill-module/tb_ooo_fetch_p...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106423
- `line_count`: 802
- `sha256`: 8b5d6832fc89b0227b32b53c9d4d520dfe946f55d0ce8a81c8b91e6c10f2a703
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106423 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: b5f9c1f01eafed6d892227c695f36dc7871751df7cdeb520356cbb876406094d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build-v8b-kill-mod...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: e03c51c22e95b129eb586c2002b57a4942d06a30dd2cf2b44bf93f4cd79297a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build-v8b-kill-module/tb_ooo_fetch_request_m...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 979
- `line_count`: 10
- `sha256`: 71bd12376782e5860ac8c2cb0f7a0e61f51f0be99402a07084cce9125b040cce
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=979 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o build-v8b-kill-module/tb_ooo_fetch_s...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18549
- `line_count`: 85
- `sha256`: 61e0f22284995d82ad5e9fde3016960c7ef245714dd99d019f5e1217d320b96d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18549 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build-v8b-kill-module/tb_ooo_fetch_trap_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 443
- `line_count`: 5
- `sha256`: 865ff0f270cfe658f2d6bbc4005879b73fcae9a9b796754f7314f424a7534999
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=443 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-v8b-kill-module/tb_ooo_fp_arith_gate.vvp /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: 4add4b44b51c4eb0e9cc8dcdb8c4d3ce8e93ba57be104745098f81000c594434
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build-v8b-kill-module/tb_ooo_fp_classify_gate....

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: d8bc619d28472ac9896e51efbc80d55aea6da50bea4967a054bf26d3a5236506
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build-v8b-kill-module/tb_ooo_fp_compare_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 453
- `line_count`: 5
- `sha256`: d29f82d2dd08bb05078292a67f968e9aa4dab7c798086e57cda4012fa8087df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=453 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build-v8b-kill-module/tb_ooo_fp_convert_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3659
- `line_count`: 36
- `sha256`: 6175115023e5f766c56ca28e201f987c4133d3d4189d7a3cf7e5da42d5f5bdaa
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3659 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build-v8b-kill-module/tb_ooo_fp_issue_queue.vvp /h...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: 28ac34e2b3854edcc169bc04dc8ab44b5cf25d8106e64505c49010f2f804dbe6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build-v8b-kill-module/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1635
- `line_count`: 14
- `sha256`: 9e1b6d4e860c6c54fec2e7164b127852e49eaa7baccaa40bbdd232cbb2c09b73
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1635 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build-v8b-kill-module/tb_ooo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: 24f0eb03efc9ca1ef756af490cc8ddea796ef51dcfbcdd6a8119c493d1fab9ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build-v8b-kill-module/tb_ooo_fp_long_op_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 992
- `line_count`: 12
- `sha256`: f5c0c4c085c48ea2deee971f68ccf55d5ddd6249040c1d135fcabeb7ac80b715
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=992 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build-v8b-kill-module/tb_ooo_fp_phys_reg_file....

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 739
- `line_count`: 9
- `sha256`: 3a5846a450bbf07d4ffcf7ad1c73de08e50e2e8e56cbb3504944d8a1aa68be85
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=739 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build-v8b-kill-module/tb_ooo_fp_reg_file.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: fdfbb05fed458cd5f26a64efd87da42716afc78fc658a2a0ee6277713c683ff7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build-v8b-kill-module/tb_ooo_fp_sgnj_gate.vvp /home/ly...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: f8039d0e1bb9240f647c81137ec2ef1c57cc9722b46bdd1864e72d70d5eb804d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build-v8b-kill-module/tb_ooo_free_list.vvp /home/lyg/PA/ysyx...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: 73d9643ebb0be0dc1b255c7e9de28c040e296135b022d653230df218349dcae7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build-v8b-kill-module/tb_ooo_frontend_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 893
- `line_count`: 10
- `sha256`: 8dbefea34d5b56ccec21bb128ce15f6da5027a6a999fb45f2dc0e18f30efa992
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=893 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build-v8b-kill-modul...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 7
- `sha256`: 40f1de19b4dc13017693682dd330b1d811e4d245431880c94fa85766cd36266b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=805 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build-v8b-kill-module/tb_ooo_front...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: 28e7818722f884ce7db2bdf996f2b713339ce64de53af22a3498ace98d1ea8c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build-v8b-kill-module/tb_ooo_frontend_run_ga...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 1d5421f62df5f9c290144e5f9f77da37123a7626988e76d6db0c2b4b97403ba0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build-v8b-kill-module/tb_ooo_frontend_uo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3836
- `line_count`: 34
- `sha256`: e084e87c17711b91b8eceae30f36719519fc61d01c253f779750f5a3bf26e04d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3836 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build-v8b-kill-module/tb_ooo_ifu_lan...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13782
- `line_count`: 105
- `sha256`: 2a3f75985b6bdb6d10454f9de732774c3fc4912ca65b62918de466e09105a8a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"ERROR": 2, "PASS": 32}
- `summary`: log evidence; size=13782 bytes; lines=105; ERROR=2; PASS=32; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build-v8b-kill-module/tb_ooo_int_backend.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7844
- `line_count`: 77
- `sha256`: 725bacff059cc75b9b51457f0656f5dd9c97dafe354b46d86741210eb7b8847d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=7844 bytes; lines=77; PASS=12; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build-v8b-kill-module/tb_ooo_int_issue_queue.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 837
- `line_count`: 10
- `sha256`: 100a2efcd4d85f3047f09c874b54715d79f859a6605313a552f5526bc0362b7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=837 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o build-v8b-kill-module/tb_ooo_lsu_axi_l...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71162
- `line_count`: 545
- `sha256`: 7137e2a9ee80a0eb6c10e302ff69f2f83fa99ea470a68dc4f49d5e4e41a1b3b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=71162 bytes; lines=545; PASS=16; tail=: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1115
- `line_count`: 10
- `sha256`: 8c97467b30e302b2360b1575ea207b8acb43a6b7804027210cfe43de899433e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1115 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o build-v8b-kill-module/tb_ooo_mem_inflight_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 937
- `line_count`: 8
- `sha256`: e7b2b7162574f9e836348e6aac34518adcf34256815e974c8435b600ac16708d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=937 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build-v8b-kill-module/tb_ooo_memory_requ...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 692
- `line_count`: 8
- `sha256`: ae95ad01c2157b365f79d00c4a5a7a2ee81fe1b44440ff8d3a7deb58445ee0ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=692 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o build-v8b-kill-module/tb_ooo_mmu_epoch_owner.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: c6ac4c58e039f9465ad59c7e2ba34beb124b86877bd2bc54ddc7686540f3b86d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build-v8b-kill-module/tb_ooo_muldiv_unit.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1161
- `line_count`: 12
- `sha256`: 3c36fd083db55d9a1dd390aa0df413045d5876e08656577379632c3de86979f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1161 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build-v8b-kill-module/tb_ooo_p...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: d2b1c78fe223ad15184c4a3ebea5c48c0cf3e045655d55ebf40f821a8141f5cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build-v8b-kill-module/tb_o...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 949
- `line_count`: 11
- `sha256`: 0343eab6e4d06824c684892f69b62921e0d6eaa0919b50dd6277d503e6ff13af
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=949 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build-v8b-kill-module/tb_o...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 843
- `line_count`: 9
- `sha256`: 96df722d9a6e24668ab3f42e65e7297e8957ecb2f250f31acfb94a656b0fd5bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=843 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build-v8b-kill-module/tb_ooo_p...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 547
- `line_count`: 5
- `sha256`: 13a0448ccc78639d9b92541e64e07bad2972596a9431c77a4b96b58ab2725efd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=547 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build-v8b-kill-module/tb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 03e13ad1722a50cadddbcdc8d6d63f3a4deb7f407a585661153b0240ceb77027
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build-v8b-kill-module/tb_ooo_phys_reg_file.vvp /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 6
- `sha256`: f5396a18f87c470483b031670619c11ca7159b2bdea147f1208df1dc1d799bbc
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=571 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o build-v8b-kill-module/tb_ooo_pma_checker.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15553
- `line_count`: 64
- `sha256`: 25d9c6ff843c709b3c880078c6c42e4554c327e9d05bf008cc84c705e6a9d633
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15553 bytes; lines=64; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build-v8b-kill-module/tb_ooo_priv_system.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: 7d5768ec5b36051d9c6273176643c6592fca677f31e62305d543d9ad0994e992
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build-v8b-kill-module/tb_ooo_ras_update_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 461
- `line_count`: 5
- `sha256`: 6d99658577d054a39a280a30aa8f86e29a01e8f04d1b8c015a112fb54bc99406
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=461 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build-v8b-kill-module/tb_ooo_redirect_arbiter....

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: d11d458b1c5542b6e88e97ccd37130e19f0ccadf625dd625bb0c1dd0e6aa3447
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build-v8b-kill-module/tb_ooo_rename_map.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1031
- `line_count`: 10
- `sha256`: c109772065dc0e277093f0070f8047dac7cee992884686cf39201111fcc014d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1031 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build-v8b-kill-module/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 825
- `line_count`: 9
- `sha256`: 0b398a1bca8013366756843faf6708e538ecf250d87cbcd64efa4a1428ad66df
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=825 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build-v8b-kill-module/tb_ooo_stop_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2475
- `line_count`: 23
- `sha256`: 9cc9489d8871fd1d223b86868b7f3056f939b61a24982c25fa39443ccf8a2d1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=2475 bytes; lines=23; PASS=16; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build-v8b-kill-module/tb_ooo_store_queue.vvp /home/lyg/P...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 208019
- `line_count`: 1512
- `sha256`: 68d72d32fb9173581f45deb3cb9fd181757a86e78357e9176d6332f1eb9b1adf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208019 bytes; lines=1512; PASS=2; tail=pChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/m...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: 582ee6d8e9060752163b818ed8e1e1dbd2496a945916d3ba8117dc699067157a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build-v8b-kill-module/tb_ooo_trap_exit_e...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 540
- `line_count`: 5
- `sha256`: 629e9a6b1be6041a358de842ff2328f50373179c9c94847bac1e51174f4e0358
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=540 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build-v8b-kill-module/tb_o...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 6
- `sha256`: 0048bae9eec4ac9017a5c6443ba711dace0e7f1763ae7ce2dabef0401c3204a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=591 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o build-v8b-kill-module/tb_ooo_typ...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: dc07b3bbb3c21262b17d17739f25800acc4149e97d1a6d5b83920adb0d973ffd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build-v8b-kill-module/tb_pipe_stage_reg.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17553
- `line_count`: 134
- `sha256`: f25d9a9c6eeb968ce71838899d3c98c6c412ef39bd2f326dfc8cb624d10902da
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17553 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build-v8b-kill-module/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 364
- `line_count`: 5
- `sha256`: 67a9eb22107376bf8700e6e0a298317bb44875ab25e057546ede95db24675b7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=364 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build-v8b-kill-module/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: bc74860848fe165185b56dd9c908116e1aeeabf5036ef2c032eff59c5370c3db
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build-v8b-kill-module/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/write...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1/summary.txt

- `kind`: txt
- `size_bytes`: 3441
- `line_count`: 113
- `sha256`: 8afff48e88f1a2baddd17e1def336b90ac14c33a960e398fe5ba0657a4027744
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 208}
- `summary`: txt evidence; size=3441 bytes; lines=113; PASS=208; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PASS tb_compa...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2.sha256

- `kind`: sha256
- `size_bytes`: 21161
- `line_count`: 105
- `sha256`: 859ef5adc011e3806614579f4e1939d1d8ee8d50b9e069faa8c527d9faa388fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=21161 bytes; lines=105; markers=<none>; tail=337a7e75ef376a9a2cf23c6c81d8e1469c607dc73130b23c5a40be4068a2c4c7 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_alu.log b29a081c754bf79d2862624f4563dd6310a2284629c3cec4e5802e71967c3dd6 /home/ly...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 5
- `sha256`: 337a7e75ef376a9a2cf23c6c81d8e1469c607dc73130b23c5a40be4068a2c4c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=384 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_alu.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 416
- `line_count`: 5
- `sha256`: b29a081c754bf79d2862624f4563dd6310a2284629c3cec4e5802e71967c3dd6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=416 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_axi_clint.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3516
- `line_count`: 28
- `sha256`: cce4c9397a0db10a27de8c30b23af907be122e27a4991bd5215710daf67a4336
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3516 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_axi_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 6
- `sha256`: 12f15c6eff3ef2deeb2bfcf66d8a9820a6c9427d2a83838fdc2091d4c8612218
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_axi_plic.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 6
- `sha256`: 30e4282861510ba9306a5ec75ce9d1953e9cd288940382b96a919e861fc997a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=613 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_axi_re...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: 901ce5d25459d785663af970a1fad39b05d09114034de7c9c1558db47379c667
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_axi_to_uart.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3296
- `line_count`: 28
- `sha256`: 5b009a6b97fc9bec9fd3662f9532f104726a72d1006243690597da3edd59b8e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3296 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_axi_xbar.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: b3eb13faa655a2fe8034a167504af9181d8dbff6c9e8aa36c86082ce8c3a0d3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_compare.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: 0d36afc55e0ef604b5fc682d7694dbd3eb8a4069d18ff0cfe25a5971d9f953de
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_csr_file.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: fedc69c725df7a16ccc019a81d299e8316f0939a64a2d2538c88861fc3ddfb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_decode_stage.v...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 430
- `line_count`: 5
- `sha256`: b527ad29854319c8138ecc87771fbe10c8dbc1f0cea81b1ef974fab8286af1f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=430 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_decode_unit.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 400
- `line_count`: 5
- `sha256`: 77384ad8b4c3fe16650f65ae3051c015b01342dad55daf26aa097bf41d606dd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=400 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_immgen.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 507
- `line_count`: 5
- `sha256`: a52bb87a241e557118811c762922c83680d666472a8813a3577aec5df0dd9345
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=507 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_lsu.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 429
- `line_count`: 5
- `sha256`: 3370edb3ccb1298e431ee46dd2f6a30a7c1fab9dab4efb757515f9a5270dc4a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=429 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_lsu_control.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: faed466ed81ae70e0f866b58ea0fbd540a11b14221865e2aff23979b4c34fe65
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_lsu_datapath.v...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15721
- `line_count`: 95
- `sha256`: c40e9d8993dfa28cf556ab12be6c22ddf9f6f207f70fa63481ddc676ace65bdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15721 bytes; lines=95; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15549
- `line_count`: 93
- `sha256`: 1cdce9a843d80bd7ddc24d5eef4d810573af7ad5921198ec862393bdd907b22f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15549 bytes; lines=93; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-bui...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: 113d13d9916c03bee9a58ba013856b7d63b507416d2c17fddffcd01e0572a0b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_amo_gate.v...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: a374e654297c5c3b457317876bc87a6b9677e1b32d852d8ae8a2e0303b27eba9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/ysyx-v8b-kill-broad.75yeMX/modu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: adf2d642600c91f4186c6a6e640c580235e64c4e4113e32340b9f1f425f7f26a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 892
- `line_count`: 9
- `sha256`: 0058a58e6dab03957dc156824793a3a3836079b50c91c522d7c385586c08563a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=892 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/ysyx-v8b-kill-broad...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 847
- `line_count`: 9
- `sha256`: e46e187ffd0c1c972b083e80322a3d8eec82f1185b3925d6a6ef3e007ed53ce9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=847 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/mo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 5
- `sha256`: 02fddd80fba942ded1e7ad5fa756045fc742419a578cb6440e047c149106b94e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=630 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/ysyx-v8b-kill-broad.7...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 902
- `line_count`: 9
- `sha256`: 7c5121cc6bce183cfa71b99af0b7d28ddf8d492af7a438837cb0fe59aa847862
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=902 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/ysyx-v8b-kill-bro...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: 84c624ed632cb1a82d4a56d9de9a164ff38a06e78b7e38695acf477a690e1310
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 587
- `line_count`: 6
- `sha256`: 16309a26d718a903effc1538e766e39175568ea6a54c7b9ea8a9a8251cf10285
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=587 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_busy_t...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 5
- `sha256`: df5091a542519d715a2dc0b30eb86c77b7d32b876bec11dd9935094a63c2d6f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_clmul_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 9
- `sha256`: e9a0afaa100cf320308ee6d53b13976c227c6f454eed814d838773aa82ca211e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=805 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 870
- `line_count`: 9
- `sha256`: efa2c74cc69e228551de7ff10b865325a075b575023ed350de900056616684f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=870 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/ysyx-v8b-kill-broad.75yeM...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 857
- `line_count`: 9
- `sha256`: ccfd3e8c1ccaa47262768d3bb2ebc67a30a953b7a548b57f29333d561370720b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=857 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/ysyx-v8b-kill-broad.75yeMX/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15785
- `line_count`: 69
- `sha256`: 5f688ee83b3a20099b8873b59a5d00bc189779b883f46499d4674563df260fb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15785 bytes; lines=69; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 535
- `line_count`: 5
- `sha256`: ee734b10a223c1c9b98b9c7e3a5e961d5f1ef48b4e5fddfa40e71c5a159900de
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=535 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/mo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 5
- `sha256`: f3826367bfa8b79d24a8bc59839fde16dcd079e2bc842ed96c0c76f38ec34019
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=521 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/module...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 5
- `sha256`: 556bf37d950578e3dbf1061db1f061b0b244d913c45c12dd561fed99dc24005d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=613 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 543
- `line_count`: 5
- `sha256`: 4f2b595537808ad81315f13f54467088a69c5ca74cee60c454db9801264a5a87
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=543 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/ysyx-v8b-kill-broad.7...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: 8bde8f0dbb87d7d83be1f3d83b26a13fb6cb1eba78796c010f8ff5ce2a518d99
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/ysyx-v8b-kill-broad.75y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: 3ede04dfc81d0f2d2be3fd91c56ae1f59ee8e02614d59b42375e9f5ca1657db2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/ysyx-v8b-kill-broad.75y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5440
- `line_count`: 37
- `sha256`: b9d4d275003b082c90f54569843a7cc8f0a472919e7c8469fa55c3baf7bd48cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=5440 bytes; lines=37; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/t...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106904
- `line_count`: 846
- `sha256`: 17a2c1ca2cfae204c6b0ea85591490d270229e29be555a07eaaddd2e7f8a47fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106904 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103647
- `line_count`: 779
- `sha256`: d45e5293f1eeb32d3a2901a685a2c675cf412d6587082ba9f1ee252e983a8125
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103647 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104451
- `line_count`: 788
- `sha256`: 721326b393a5c57a72198b22cbf483d090777917c955aa42aa9d8e8f1e9e9b21
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104451 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106584
- `line_count`: 802
- `sha256`: 37f721f4ff16a975399a158259f2736cea9c0ce0e8a3125e7337b63c2d3eb114
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106584 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: 125848d25ec9832b204cde40de1ce4f5c92a6295950c4653ad2e20430fa749e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: 5b96a04a44dba90e143d876397e6339e69756feaab5bb035e52030df79968382
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-bui...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 672
- `line_count`: 5
- `sha256`: edcf15265c72f7bafc98e037b0bb2390265624e178ee838838acfe21d35e6e58
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=672 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/ysyx-v8b-kill-broad.75yeM...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 724
- `line_count`: 5
- `sha256`: 03a7cfef29e463698f18fe1a787717420dcb22f056818a05db477db7da89c9ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=724 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 633
- `line_count`: 5
- `sha256`: 10e32e779fbcb0468574f9a1735c3f88d53618ceccf6ff511ef6979117d084f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=633 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-bui...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 644
- `line_count`: 6
- `sha256`: 1c99284251cb9854b9a0d3e26f5072b963f79d64f5923e4f6bfec76b98f42c60
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=644 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 823
- `line_count`: 10
- `sha256`: 333ce62490a00a2e87eb43c531927f38aacb473f452bdc4c57d59d62752e8569
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=823 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 512
- `line_count`: 5
- `sha256`: 961a4fe1fd9cce70ca0cc6ed567a66f5e49634147461127ffe7fb63476baf366
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=512 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/modu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 513
- `line_count`: 5
- `sha256`: 7db12e00170aad98978437c5f00f53f7d9ef9f7f3b5cb405fc53b5ac16e5e0f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=513 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/modu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106446
- `line_count`: 802
- `sha256`: 74f492ee3fcefbb0d546751c3216f822c2374303ca9b188f7908b2e2d75d9ca3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106446 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 567
- `line_count`: 5
- `sha256`: ac2b28fffb5a1629b9799d12411f82cb6e4b05b19e82708dcbb57dfd4a5df2c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=567 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/ysyx-v8b-kill...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 532062801f7fc69e59eb7b92271ba7d6b1667c7153299b532160b644c9543c21
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 1002
- `line_count`: 10
- `sha256`: 698ef4230a650223f23346977c95b2631355a5721fed348e397eac2debe4122c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1002 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /tmp/ysyx-v8b-kill-broad.75yeMX/modu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18572
- `line_count`: 85
- `sha256`: c1510a13e056fd181e6377c84e90b3ff7afc2843464d97cb59a004f18293430f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18572 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: db3cba6f8c88324f35c5d2b6142a0a1a61efba98ba2ce980d0313fafab27a4b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 8a348ba7c3f29d4507a436487b19d62476c2195aab57b7d039b3711cd537a38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/t...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 477
- `line_count`: 5
- `sha256`: 34138759f84885c5a480e8e2a5f791221e18c5045d028c336f5597568b110d0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=477 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: f211a637eaffda11ae7b2d7bfe187b74539e7c3ad6e1e561e4182f656413c527
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3682
- `line_count`: 36
- `sha256`: 2cf3a4f6a3367ddbd1abb0dee1af89883d45749b933f8337ef76f2e89a02b167
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3682 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 5
- `sha256`: ca4e1e1c1d9a3ed938ff11d1097eab319bbe41827c6783f1e0814f5c4592bc76
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_fp_iter.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1658
- `line_count`: 14
- `sha256`: 8b58611670d079f444d189393b278da76a8e44d019ae4c43dc90ac11ad6a7892
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1658 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/ysyx-v8b-kill-broad.75y...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 608
- `line_count`: 5
- `sha256`: 4b0e720d6c50960de0f7245ff893527f091cf76cfa835ccb4c3c7dd1305cd103
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=608 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1015
- `line_count`: 12
- `sha256`: 244bfa7331adcceaaaa3c539379d0a26a61e88b0fb79bbb08a3b6fc0d4625fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1015 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/t...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 762
- `line_count`: 9
- `sha256`: ec24f0e427a8184a5aaa8271e5096d7de3f12bdfc885ee793e7ce36b2e75dc2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=762 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_fp_r...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: f8a6e3fcc8d7ffa82f079ac4059fa8a988a43970e89b3f190a629b3b0666ffa5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_fp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 5
- `sha256`: dbf4ff89e42e7e7df5c378c9d8adc8ef7fe582fe82a3cd2ac0f1d68ca36ba5ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_free_lis...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 508
- `line_count`: 5
- `sha256`: f756d7ad18dce5914fe75444bd60abbd83a0a298c4d68a92d9973b183d87cb1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=508 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 916
- `line_count`: 10
- `sha256`: 66e6da80017a3a1e1bd86a8a21331cc5b54898feeeb0492fc9a23a6a8b7a997f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=916 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/ysyx-v8b-kill-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 7
- `sha256`: 242ad736769475d9ba1221098d7feb1b9f0a38bc596d023170e7ee4aee3b8df0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=828 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/mo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 124f818ef42c792135541c8521aca0cc1292ad34d2b8a39af152aaa3508a6391
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: 6e37c89221e09f67b0278ef3ce37ec4d9a9cb9b1b8ad44ebcb013fd17ec98241
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3859
- `line_count`: 34
- `sha256`: 8b2113ae07b4196c635e2fdc924c0edc2a1c332979801820b10575254e703340
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3859 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/ysyx-v8b-kill-broad.75yeMX/modu...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13805
- `line_count`: 105
- `sha256`: acfd1446ea6718a05ae948f624173be6ca4d730300a48c0b3b93c9626e119c30
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"ERROR": 2, "PASS": 32}
- `summary`: log evidence; size=13805 bytes; lines=105; ERROR=2; PASS=32; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_int_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7867
- `line_count`: 77
- `sha256`: b8eac71c1a1c6cfcae550e65a600c2367be956c5c4a954934f70e9f9a2a18ec0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=7867 bytes; lines=77; PASS=12; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 860
- `line_count`: 10
- `sha256`: ff234d6dda79f8ef5a48e4536005b646f5adc4f2288341c1bf7c53707e370106
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=860 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /tmp/ysyx-v8b-kill-broad.75yeMX/module...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71185
- `line_count`: 545
- `sha256`: 4903223218ca154b32dcbf6f43338c43616b92a33b44f83495de8528e1d303bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=71185 bytes; lines=545; PASS=16; tail=: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1138
- `line_count`: 10
- `sha256`: 37e2d63f369311724cbebeaf3d09f98c03eb416fcb39dd6d65e4068b997b8a9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1138 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-bui...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 960
- `line_count`: 8
- `sha256`: a09da5b4c46e3936949c93e7db199e2c44e4207b69d790001b961bd6fc28e015
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=960 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 715
- `line_count`: 8
- `sha256`: 5d10b2b8c9bff5020ee8653ad6a1ef904fdd2a9f8d19d718bb4476d9c9a9f2d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=715 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: 23eb1334282596c753d50ed2b7c77e7be5524e05c875a61d902084b30b49200a
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_muld...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1184
- `line_count`: 12
- `sha256`: 7cb099829c90490a0e0c8c6950799e21041e3ccd55df0e86898ba02ee61ea961
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1184 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/ysyx-v8b-kill-broad.75yeM...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 542
- `line_count`: 5
- `sha256`: 3b7e1cac7152f444fff82253c032a2f6e8a88e1d89cceae1bfb96510aea8bc3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=542 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /tmp/ysyx-v8b-kill-broad.7...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 972
- `line_count`: 11
- `sha256`: bdec572dd87af4c64628aa00a52fa21cd1a6d63431134c6f96e0471cebb2a10e
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=972 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/ysyx-v8b-kill-broad.7...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 866
- `line_count`: 9
- `sha256`: 9c0acb2e7d7efba485622d722dbe9917fe9f8c17db1cd265834bd6552e29b5f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=866 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/ysyx-v8b-kill-broad.75yeM...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 570
- `line_count`: 5
- `sha256`: 60e46e79691272ca9fa28332388fc997705c40a910df9b887a31c2276cc55625
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=570 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/ysyx-v8b-kill-broad...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 27c3cb6f9b411859c83143189b69225144cba915209b253af1f6fb4cb4ef5a59
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 6
- `sha256`: e4e7251ff311a369fd10b327bd149387bf05e3e1cac8cd5911c8751b8216e7a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=594 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_pma_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15576
- `line_count`: 64
- `sha256`: 59f3b54f50f41ec0a0bc27a347482f3efc0b405cf58fafc5b9fb967ccef72c66
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15576 bytes; lines=64; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_priv...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: 44e8dfce4d13463d56b6acdac18717c579a6fd11a959428ebcb979a7c781892c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 99d35e94a0e3fc900832972b8b8c870e63d40793087b59b33dd1b9498c361a8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/t...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 5
- `sha256`: 0e277acf7bd99c6fbeb4294356455d31276f6146c2803c1d8083b8ef72fb0fdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=456 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_rename...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1054
- `line_count`: 10
- `sha256`: d68c0ee6745bc34e7878b37e685e53598e3725ea4287177499f34ae7ab1ff1f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1054 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_rob.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 848
- `line_count`: 9
- `sha256`: 71cc89bd53935ac6ff7c221db5df391024b57ce1d8daf827836a4e6b4357cce2
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=848 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/ysyx-v8b-kill-broad.75yeMX/mo...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2498
- `line_count`: 23
- `sha256`: 8aee8bc82ff20cecd7811f7db12bf2d2eebed643c69ffddeb53ca65652012e3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=2498 bytes; lines=23; PASS=16; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_ooo_stor...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 208042
- `line_count`: 1512
- `sha256`: 62cea8dd894ebb20dee66bec555993c558f01e7be9fbf42c793ce4a06e506eda
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208042 bytes; lines=1512; PASS=2; tail=pChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/m...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: b399883a117e7a9a514a45bb14759e7735203be492239c18790a9b5312e298c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-b...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 563
- `line_count`: 5
- `sha256`: 6c47a3f2241ea26f477c6dcfb3d78bae061cbba62c25e9f87f85764439cc3369
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=563 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/ysyx-v8b-kill-broad.7...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 6
- `sha256`: 01feb751bc30bc078939a2fa52c0d43db90ac621451d083bdc9c3fcda171e730
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=614 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /tmp/ysyx-v8b-kill-broad.75yeMX/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 03de4e9e1001004d04456b37a3d8a8b5a9f7f4ab8d8db4246f66e472903efc6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_pipe_stage...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17576
- `line_count`: 134
- `sha256`: 385869996c1d0162fe4346eef903e726f0dc24b09b3671ebdffa9dfaf60b8025
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17576 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_pmp_checker.vvp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 387
- `line_count`: 5
- `sha256`: c42ea59e9386f68e0f6cb693c04a8e60e6bbe9a54fc07427e8605aa1a2ea0338
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=387 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_uart.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 385
- `line_count`: 5
- `sha256`: ef10558857cda5e565eaec1ea512e7b1a1978f3eb5fa4569f2d0be4389d9ab7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=385 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/ysyx-v8b-kill-broad.75yeMX/module-build/tb_wbu.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2/summary.txt

- `kind`: txt
- `size_bytes`: 3441
- `line_count`: 113
- `sha256`: 1ccd4a4b32c229827aa2dae70132d254343c2740fef2485584842ef732d69646
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 208}
- `summary`: txt evidence; size=3441 bytes; lines=113; PASS=208; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/module-r2 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PASS tb_compa...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-ambient-function.log

- `kind`: log
- `size_bytes`: 970
- `line_count`: 20
- `sha256`: c60d22e67420251f1c28035996f32c8d3720c5e4a9dc6331055da480dcd9f9e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 22}
- `summary`: log evidence; size=970 bytes; lines=20; FAIL=22; tail=mutation=clmul-ambient-function witness=kill-valid/cut/head only-toggle compile_rc=0 sim_rc=1 [CHECK-FAIL] kill-valid only toggle is immediately visible got=0 expected=1 [CHECK-FAIL] same-cycle killed request stays idle got=0 expected=1 [CHECK-FAIL] run kil...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-inclusive-boundary.log

- `kind`: log
- `size_bytes`: 20676
- `line_count`: 268
- `sha256`: db8cfcca2b8c67d113b510db38b27217c3f1bfb4629cfc870c86e3e601639d93
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 518}
- `summary`: log evidence; size=20676 bytes; lines=268; FAIL=518; tail=mutation=clmul-inclusive-boundary witness=4096 age sweep equal boundary compile_rc=0 sim_rc=1 [CHECK-FAIL] exhaustive kill predicate head=0 cut=0 victim=0 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=0 cut=1 victim=1 got=1 expected=0 [CHECK-...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-no-holder-clear.log

- `kind`: log
- `size_bytes`: 634
- `line_count`: 15
- `sha256`: eaacced917f3ffc50370822b5f1ddbd230117c988e393665a4314d92fe533fa5
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 12}
- `summary`: log evidence; size=634 bytes; lines=15; FAIL=12; tail=mutation=clmul-no-holder-clear witness=RUN/RESP kill state clear and reissue compile_rc=0 sim_rc=1 [CHECK-FAIL] run kill clears held producer got=0 expected=1 [CHECK-FAIL] same-index replacement ready before request got=0 expected=1 [CHECK-FAIL] same-index...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-no-inflight-kill-valid.log

- `kind`: log
- `size_bytes`: 1254
- `line_count`: 24
- `sha256`: 7e90518069c949a6d15cf0ce98e7e1e3076079c29a491676affab8fe26614b63
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 30}
- `summary`: log evidence; size=1254 bytes; lines=24; FAIL=30; tail=mutation=clmul-no-inflight-kill-valid witness=nonmatching/kill-low survivor compile_rc=0 sim_rc=1 [CHECK-FAIL] run kill is immediately visible got=0 expected=1 [CHECK-FAIL] same-index replacement resp_valid got=0 expected=1 [CHECK-FAIL] same-index replaceme...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-no-new-kill-valid.log

- `kind`: log
- `size_bytes`: 1361
- `line_count`: 26
- `sha256`: b84ba9c1848b223e6f989521147d6aa939848ca90f2e19c3d44ddfbb5261b30d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 34}
- `summary`: log evidence; size=1361 bytes; lines=26; FAIL=34; tail=mutation=clmul-no-new-kill-valid witness=kill-valid low request compile_rc=0 sim_rc=1 [CHECK-FAIL] kill-valid low leaves new request live got=1 expected=0 [CHECK-FAIL] run kill is immediately visible got=0 expected=1 [CHECK-FAIL] same-index replacement resp...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-no-new-request-kill.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 11
- `sha256`: 7237c7c13c59d6f9be5dc57c7964cd40384a79b64c2eb6100ea1256d3b9afca0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=340 bytes; lines=11; FAIL=4; tail=mutation=clmul-no-new-request-kill witness=same-cycle killed request stays idle compile_rc=0 sim_rc=1 [CHECK-FAIL] same-cycle killed request stays idle got=0 expected=1 [FAIL] tb_ooo_clmul_unit errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-no-response-mask.log

- `kind`: log
- `size_bytes`: 338
- `line_count`: 11
- `sha256`: 920f78b7b42c19be8fc021535b9de056146fb14f6cd536494f6b45b69ec89104
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=338 bytes; lines=11; FAIL=4; tail=mutation=clmul-no-response-mask witness=backpressured RESP same-cycle mask compile_rc=0 sim_rc=1 [CHECK-FAIL] response kill masks valid in same cycle got=1 expected=0 [FAIL] tb_ooo_clmul_unit errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/co...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/clmul-raw-index-age.log

- `kind`: log
- `size_bytes`: 108078
- `line_count`: 1372
- `sha256`: b5d22c96948b44db55bbfa7d9dca7f2529eaa9ce501ff56393e45f0e732c8a7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 1655}
- `summary`: log evidence; size=108078 bytes; lines=1372; FAIL=1655; tail=m=12 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=7 cut=5 victim=13 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=7 cut=5 victim=14 got=1 expected=0 [CHECK-FAIL] exhaustive kill predicate head=7 cut=5 victim=15 got=1 expected=...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/fp-ambient-function.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 13
- `sha256`: 61f5aadd94a1bee3f5d15e749c0ab773457ce94a99fea14067ea5431276ef23c
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 8}
- `summary`: log evidence; size=471 bytes; lines=13; FAIL=8; tail=mutation=fp-ambient-function witness=FP cut/kill/head only-toggle compile_rc=0 sim_rc=1 [CHECK-FAIL] fp cut-only toggle masks output got=1 expected=0 [CHECK-FAIL] fp kill-valid only toggle masks output got=1 expected=0 [CHECK-FAIL] fp head-only toggle masks...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/fp-no-output-mask.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 13
- `sha256`: e1b22379bad1eaac32462d4b619641e58910386e0d671e4f49cf211b8a94b1c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 8}
- `summary`: log evidence; size=466 bytes; lines=13; FAIL=8; tail=mutation=fp-no-output-mask witness=FP stage5 same-cycle mask compile_rc=0 sim_rc=1 [CHECK-FAIL] fp cut-only toggle masks output got=1 expected=0 [CHECK-FAIL] fp kill-valid only toggle masks output got=1 expected=0 [CHECK-FAIL] fp head-only toggle masks wrap...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/fp-no-propagation-kill.log

- `kind`: log
- `size_bytes`: 336
- `line_count`: 11
- `sha256`: d3e8bb1c04fdbef8fa60443992e722ccbeac238c0294e7253403fd3f79a4408f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=336 bytes; lines=11; FAIL=4; tail=mutation=fp-no-propagation-kill witness=FP in-flight younger meta delayed pulse compile_rc=0 sim_rc=1 [CHECK-FAIL] launch killed younger meta valid got=1 exp=0 [FAIL] tb_ooo_fp_arith_gate errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/fp-raw-index-age.log

- `kind`: log
- `size_bytes`: 326
- `line_count`: 11
- `sha256`: 68b6078c2003d859ee40c2dfabb8f0c1583993ec584ef487603db11424f64a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=326 bytes; lines=11; FAIL=4; tail=mutation=fp-raw-index-age witness=FP head-only wrap compile_rc=0 sim_rc=1 [CHECK-FAIL] fp head-only toggle masks wrap-younger output got=1 expected=0 [FAIL] tb_ooo_fp_arith_gate errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/fp-reversed-age.log

- `kind`: log
- `size_bytes`: 647
- `line_count`: 16
- `sha256`: 0c1565d268ad3809d1ef38962e2e2de78cdd35684a5c1f336692687a7d67b5fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 14}
- `summary`: log evidence; size=647 bytes; lines=16; FAIL=14; tail=mutation=fp-reversed-age witness=FP survivor/victim polarity compile_rc=0 sim_rc=1 [CHECK-FAIL] fp nonmatching kill preserves output got=0 expected=1 [CHECK-FAIL] fp cut-only toggle masks output got=1 expected=0 [CHECK-FAIL] fp kill-valid only toggle masks...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/mutations-r1/summary.txt

- `kind`: txt
- `size_bytes`: 32
- `line_count`: 3
- `sha256`: bc5d14aa6e73517d411c9c9cf9d212781a62785be98cbb6645cf0722ff83fbc0
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: txt evidence; size=32 bytes; lines=3; markers=<none>; tail=mutations=13 passed=13 failed=0

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/pre-fix-clmul/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 1315
- `line_count`: 20
- `sha256`: 055722b055673e764af155848691676962ef83786d68f2ceabfef38c92e33088
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 26, "PASS": 2}
- `summary`: log evidence; size=1315 bytes; lines=20; FAIL=26; PASS=2; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-v8b-kill-prefx/tb_ooo_clmul_unit.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/pre-fix-fp/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 841
- `line_count`: 13
- `sha256`: 5653a4771973b85e1c0ad9cbeeee2682e0c66b289b7732c4bdb0e4d9bbb99e3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: log evidence; size=841 bytes; lines=13; FAIL=12; PASS=2; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-v8b-kill-fp-prefx/tb_ooo_fp_arith_gate.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/producer-kill-contract-r1.log

- `kind`: log
- `size_bytes`: 85
- `line_count`: 1
- `sha256`: e7962ea93c7246f1bbcaeb05d14def13c7748035faba902d54f47e2e3e0341e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=85 bytes; lines=1; PASS=2; tail=[V8B-KILL-CHECKER][PASS] explicit kill dependencies and production provenance locked

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/rtl-style-full-r1.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/strict-lint-r1.log

- `kind`: log
- `size_bytes`: 62643
- `line_count`: 687
- `sha256`: 901d36a6ba93f4f1022fb5d96549cba08c179818fca85bcd9539dd233b557182
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: log evidence; size=62643 bytes; lines=687; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-19-rv64-v8b-producer-kill-now/evidence/strict-lint-r1.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-18T20:53:47+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...
