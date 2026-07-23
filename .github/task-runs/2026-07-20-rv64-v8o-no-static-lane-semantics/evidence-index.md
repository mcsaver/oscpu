# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-rv64-v8o-no-static-lane-semantics
- `task_slug`: 
- `profile`: 
- `asset_count`: 142
- `total_size_bytes`: 1239105

## 证据资产

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-assert.make.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 16
- `sha256`: 9c1eabb6973ce88b6d3b80bd9d2d685378336b51310884f9523c1f6f7c5a7960
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=613 bytes; lines=16; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module test...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-assert/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 9132
- `line_count`: 61
- `sha256`: da650d01b0834d8102b99b89978006bcfe2159332549593e67004d1b330b7800
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=9132 bytes; lines=61; PASS=6; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8O_MODE_ASSERT -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-baseline-assert/tb_ooo...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-assert/summary.txt

- `kind`: txt
- `size_bytes`: 292
- `line_count`: 10
- `sha256`: f80b9b6cd061d1dcc4fc96a796d9f0c0b5add41a9e5cc4a540f9c05c82a0881b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=292 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-assert - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_issue_queue - t...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-release.make.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 16
- `sha256`: fb1e4cf05cd2ce12cde5c9a2f31ece0e0872324e62868f9cc380d3ecb132778c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=614 bytes; lines=16; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module test...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-release/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 9103
- `line_count`: 61
- `sha256`: 74ef575620257d0297f077d58b4a80cd4df4c7bc190bfff44817ad5f88176313
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=9103 bytes; lines=61; PASS=6; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-baseline-release/tb_ooo_int_issue_queue.vvp /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-release/summary.txt

- `kind`: txt
- `size_bytes`: 293
- `line_count`: 10
- `sha256`: 5cb938d27d6e914e52ed305443210c8664b0687f6a43fc876a771e95a4a2ab60
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=293 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-release - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_issue_queue -...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/baseline-summary.log

- `kind`: log
- `size_bytes`: 131
- `line_count`: 2
- `sha256`: 0d9a3b5370478767b867374c6de5851a980a459fd49d3a22f0bb5d840cddf886
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=131 bytes; lines=2; PASS=4; tail=[V8O-BASELINE][PASS] profile=release permutations=12/12 pid=24/24 [V8O-BASELINE][PASS] profile=assert permutations=12/12 pid=24/24

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/evidence-builder.log

- `kind`: log
- `size_bytes`: 140
- `line_count`: 1
- `sha256`: 6866873e0ef2005418d06f1212017b38f20eac00037779a1096d6d2882708eb8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=140 bytes; lines=1; PASS=2; tail=[V8O-EVIDENCE][PASS] no_static_lane_semantics design_id=sha256:9735bdc1f101501d0100a335b4d7ac602fa6b002d77cedbcb4245b833c2bb293 mutations=6

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-corrupt_full_pid.make.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 7
- `sha256`: 9c7a67d026c63fcaf3911967b6a582c44f225a078768ca7ba3e8a0c24cfbee53
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=524 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-corrupt_full_pid.mutator.log

- `kind`: log
- `size_bytes`: 115
- `line_count`: 1
- `sha256`: 029fa8174270c0dc4314b1990941cd4189413eab550e8a5a8e9712e083a290ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=115 bytes; lines=1; PASS=2; tail=[V8O-MUTATOR][PASS] corrupt_full_pid -> /tmp/v8o-no-static-lane.eKj4w3/mutants/corrupt_full_pid/OooIntIssueQueue.v

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-corrupt_full_pid/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11002
- `line_count`: 87
- `sha256`: 5149ac188111a00179f45eac784b3a6f79e97854b4f6976139b05fc492050c3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"FAIL": 48, "PASS": 4}
- `summary`: log evidence; size=11002 bytes; lines=87; FAIL=48; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-mutation-corrupt_full_pid/tb_ooo_int_issue_queue.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-disable_pair_swap.make.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 7
- `sha256`: 9e0bea7fbe5675575c2ed33f0dbf6ec8146cf7aef5b62393f022697098f8e39b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=525 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-disable_pair_swap.mutator.log

- `kind`: log
- `size_bytes`: 119
- `line_count`: 1
- `sha256`: f7fbe6ee342f9901f944538cb93598a5d7baf3e23cc6baaf3da46e74d268804d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=119 bytes; lines=1; PASS=2; tail=[V8O-MUTATOR][PASS] disable_pair_swap -> /tmp/v8o-no-static-lane.eKj4w3/mutants/disable_pair_swap/OooIntIssueSelect8.v

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-disable_pair_swap/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 13901
- `line_count`: 130
- `sha256`: 5f4bdc365d4d1ae5d29ef1ffdb99be63f12b458579bc0b1c33422ac6394dd211
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"FAIL": 134, "PASS": 4}
- `summary`: log evidence; size=13901 bytes; lines=130; FAIL=134; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-mutation-disable_pair_swap/tb_ooo_int_issue_queue.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-muldiv_as_alu.make.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 7
- `sha256`: 409b8d02cfcb5d6c739354514166011fd18b1032d257390747656050523616be
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=521 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-muldiv_as_alu.mutator.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: bc80913bcb3f352dcc2bb1d17cb7ff9eb33ad27d6ca3a91ad4addd7f7364373b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=[V8O-MUTATOR][PASS] muldiv_as_alu -> /tmp/v8o-no-static-lane.eKj4w3/mutants/muldiv_as_alu/OooIntIssueQueue.v

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-muldiv_as_alu/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 10522
- `line_count`: 83
- `sha256`: 80d35254cc74a77cf2d93d9307c51c61f761ff8df7cd1b183ea29bd2de3c55bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"FAIL": 40, "PASS": 4}
- `summary`: log evidence; size=10522 bytes; lines=83; FAIL=40; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-mutation-muldiv_as_alu/tb_ooo_int_issue_queue.vvp /ho...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-serialize_second_terminal.make.log

- `kind`: log
- `size_bytes`: 533
- `line_count`: 7
- `sha256`: 156255dd55f07806c324428fbc20a7a743d150ab5fd9a15ea34ffe9b6ed680b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=533 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-serialize_second_terminal.mutator.log

- `kind`: log
- `size_bytes`: 135
- `line_count`: 1
- `sha256`: a9e566d48b46f59f3c97025c74e47de02692f71b9674a2ff349506248cd2667f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=135 bytes; lines=1; PASS=2; tail=[V8O-MUTATOR][PASS] serialize_second_terminal -> /tmp/v8o-no-static-lane.eKj4w3/mutants/serialize_second_terminal/OooIntIssueSelect8.v

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-serialize_second_terminal/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 12754
- `line_count`: 117
- `sha256`: 23ca6f06eebf427212b0e6d7bc7dad7fc162736b445f4e5a9bf77dd39918a8c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"FAIL": 108, "PASS": 4}
- `summary`: log evidence; size=12754 bytes; lines=117; FAIL=108; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-mutation-serialize_second_terminal/tb_ooo_int_issue_q...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-slot1_capability_capture.make.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 7
- `sha256`: a95afc7e86421f3a8ef0bd2415f92c085f7ba0953195204ec9a016d0931bcfef
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=532 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-slot1_capability_capture.mutator.log

- `kind`: log
- `size_bytes`: 131
- `line_count`: 1
- `sha256`: f6528062eb0cd742ffc3dc0ec9368bc7fb4da159b515cf73cfc2424b8396788c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=131 bytes; lines=1; PASS=2; tail=[V8O-MUTATOR][PASS] slot1_capability_capture -> /tmp/v8o-no-static-lane.eKj4w3/mutants/slot1_capability_capture/OooIntIssueQueue.v

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-slot1_capability_capture/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 14966
- `line_count`: 142
- `sha256`: 42d8fc11a3bce2a692aecb5919de14fa4e08d7a26577524bb33bfd800b3c9150
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"FAIL": 158, "PASS": 4}
- `summary`: log evidence; size=14966 bytes; lines=142; FAIL=158; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-mutation-slot1_capability_capture/tb_ooo_int_issue_qu...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-static_entry_capability.make.log

- `kind`: log
- `size_bytes`: 531
- `line_count`: 7
- `sha256`: c2248cf0e5b96b7421084f0045664969b0621e99de8c44e1080791f61740ac5c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=531 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-static_entry_capability.mutator.log

- `kind`: log
- `size_bytes`: 129
- `line_count`: 1
- `sha256`: fe5569c63a5a3c47e521f1f44e7e60cad3995943b140c6d65e93d6d0d58f7a5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=129 bytes; lines=1; PASS=2; tail=[V8O-MUTATOR][PASS] static_entry_capability -> /tmp/v8o-no-static-lane.eKj4w3/mutants/static_entry_capability/OooIntIssueQueue.v

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-static_entry_capability/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 14587
- `line_count`: 136
- `sha256`: 5a9cbf16857b74afe478928ce66c0afffcdc92275d31d28b85d823f89284d625
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"FAIL": 146, "PASS": 4}
- `summary`: log evidence; size=14587 bytes; lines=136; FAIL=146; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8O_NO_STATIC_LANE_SEMANTICS_FOCUSED -s tb_ooo_int_issue_queue -o /tmp/v8o-no-static-lane.eKj4w3/build-mutation-static_entry_capability/tb_ooo_int_issue_que...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/mutation-summary.log

- `kind`: log
- `size_bytes`: 1642
- `line_count`: 6
- `sha256`: 3418e24a9768d14165385adfd128d2298db0d6d22a0beda0f0eebeaa3a4fb987
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 60}
- `summary`: log evidence; size=1642 bytes; lines=6; PASS=60; tail=[V8O-MUTATION][PASS] name=disable_pair_swap source_sha256=f00aa546668ceed1518a0f040f0553bcf5abd9b31f22935ba4ab2b3c51319911 image_sha256=1c96156a2f946f7d9ed97ff8e68e1daecedf01200a73aee59ceb77d28b9c895b compile=PASS elaboration=PASS activation=PASS semantic_r...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/runner-summary.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: 4101a90e8aef0b619e44d7fae9b6c7b59e86b4fd8af353a4f75ae144bc931deb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=[V8O-RUNNER][PASS] profiles=2/2 permutations=12/12 mutations=6/6 DI-4=GREEN OOO-1=GREEN OOO-2=GREEN overall=RED

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 2475
- `line_count`: 16
- `sha256`: a0b331eeb7cced3f31115798ca3fbf3e8926c0adddb78f20dc693417dbc06d83
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2475 bytes; lines=16; markers=<none>; tail=05bd5184c18c1c47c3c77aa98da56f415f509da867392f004332b86867e97c7d /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/contract.md 1435a9177d652f8d82c05dde07c8deb9f25b95e0f1f278ba413fbe5fddf4ebe2 /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 2475
- `line_count`: 16
- `sha256`: a0b331eeb7cced3f31115798ca3fbf3e8926c0adddb78f20dc693417dbc06d83
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2475 bytes; lines=16; markers=<none>; tail=05bd5184c18c1c47c3c77aa98da56f415f509da867392f004332b86867e97c7d /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/contract.md 1435a9177d652f8d82c05dde07c8deb9f25b95e0f1f278ba413fbe5fddf4ebe2 /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 4030
- `line_count`: 41
- `sha256`: e8a31ea0190933908bbf591c7b219690a7c828bda8ef87833123a422f7a9e58f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {}
- `summary`: log evidence; size=4030 bytes; lines=41; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_actual_di4_chain_cannot_pass_vacuously_or_statically (test_architecture_hard_gates.NegativeTests.test_actual_di4_chain_cannot_pass_vacuously_or_statically) ... ok test_arbitra...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/static/architecture-result-final.json

- `kind`: json
- `size_bytes`: 47343
- `line_count`: 1067
- `sha256`: e5d8a814ed8874d6d087c226ab76ce98cb6dd80c88acf3ef25cedb5492dcab0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=47343 bytes; lines=1067; PASS=12; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/static/architecture-result.json

- `kind`: json
- `size_bytes`: 47343
- `line_count`: 1067
- `sha256`: c0e5f9bf66b4012c703ed529451bc08ef1ee430b225a289ffc1a018d47109a3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 12}
- `summary`: json evidence; size=47343 bytes; lines=1067; PASS=12; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/static/checker-unit.log

- `kind`: log
- `size_bytes`: 4260
- `line_count`: 30
- `sha256`: d97f08ace24ceeef508542d824c7b6f15e50310d84263cce6d496330bcaaf1ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {}
- `summary`: log evidence; size=4260 bytes; lines=30; markers=<none>; tail=test_actual_di4_chain_cannot_pass_vacuously_or_statically (eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_actual_di4_chain_cannot_pass_vacuously_or_statically) ... ok test_arbitrary_older_valid_and_reservation_freeze_are_red (eval.ppa.tests....

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/focused/static/manifest-before.json

- `kind`: json
- `size_bytes`: 8938
- `line_count`: 153
- `sha256`: b5a79883283b52c698acf68b0a026815e8c366eb0b21b51d667f29c5b41b8ec5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 6}
- `summary`: json evidence; size=8938 bytes; lines=153; PASS=6; tail={ "design_id": "sha256:9735bdc1f101501d0100a335b4d7ac602fa6b002d77cedbcb4245b833c2bb293", "generated_at_utc": "2026-07-19T23:23:44.697758+00:00", "schema": "npc-rv64-architecture-directed-suite-v2", "tests": { "no_static_lane_semantics": { "command": "make...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 366
- `line_count`: 5
- `sha256`: ccf4b5f8da3bb2d5c07dfacafc176ece22fb6fe98387e2c5377478a279760b9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=366 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/v8o-full-module-build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 398
- `line_count`: 5
- `sha256`: c417519e820a45cbb5cc4345df8d8a983d4f730527011e51b2c438303ee60893
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=398 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/v8o-full-module-build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3498
- `line_count`: 28
- `sha256`: 63c6342b556b85ad3b4be43da6b9601c1da18ef3440b1fc667e743d53f74687e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3498 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/v8o-full-module-build/tb_axi_exec_firewall.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 6
- `sha256`: 4ff2cbf0eef65abc337c53987fac7751b936817f736e431663a90f56d25dff82
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=506 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/v8o-full-module-build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 6
- `sha256`: 48a0312500b65ffc4e6420b16e5f72c2d87228173beae044535861b6454184d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /tmp/v8o-full-module-build/tb_axi_reset_syscon.vvp /ho...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: 5befc25a22e23f2bb5e993bb3b43471870a95f3031f47b2c10b19d5f692199fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/v8o-full-module-build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3278
- `line_count`: 28
- `sha256`: fae23553041a88234269d6830a25ebe5290edd4f0baefc5eebd4eee76cdce342
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3278 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/v8o-full-module-build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 393
- `line_count`: 5
- `sha256`: 39c0ab6dcdda24ebcac1d12fb9df19ed5a72fd82db862a4c643a38c6ff21e2c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=393 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/v8o-full-module-build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 393
- `line_count`: 5
- `sha256`: 075385809107758e30510e91da8eae97652d2ef35bc1d14525ffbf72d6c33917
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=393 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/v8o-full-module-build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: faf3b1f56518f3f04da247117288eac2707b1d168c572d9344c6e8cf98c009c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/v8o-full-module-build/tb_decode_stage.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: 0e86b7a533a6c91cefebb14fbe421ce468245687d0a2ed328860dc60c42e0a90
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/v8o-full-module-build/tb_decode_unit.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 382
- `line_count`: 5
- `sha256`: 4ae7a60da54bece364cbb1969d7422d9c49de85a6a9dd118ab568d973f28a4eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=382 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/v8o-full-module-build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 489
- `line_count`: 5
- `sha256`: c395209b88624e77a950e877378f6203b7736e829839bbf8305665b0627a2557
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=489 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/v8o-full-module-build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c7178f77761db67903c2b50214d07abdb3f4c2c6729c763f72962f6c6ec84a78
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/v8o-full-module-build/tb_lsu_control.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: a1af5e8c1c8ad105c1b58e33030650c509dae0e4e76eb7a90412c31eba52036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/v8o-full-module-build/tb_lsu_datapath.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 16700
- `line_count`: 102
- `sha256`: 13e5df229f901fc2503fb239cca77ae5ba2ab4ca3fc9a5322902bf510e9c2adf
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16700 bytes; lines=102; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/v8o-full-module-build/tb_ooo_alu_core_slice.v...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 16525
- `line_count`: 100
- `sha256`: 72b8f5c20f25955e24d3a845ca4ee839517cae42126dd1ecbeaffc416ab8bbd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16525 bytes; lines=100; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/v8o-full-module-build/tb_ooo_alu_deco...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f275af3050b35e05b31be7fd694678abd3b8d8042f05e54a626049b53dd60fe0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/v8o-full-module-build/tb_ooo_amo_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: c778fe9a3cfd815702b05c2b86027dc6c77b2bf4a3b6cf90e3ee0c04c0be97ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/v8o-full-module-build/tb_ooo_ba...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 9e8b15584dc2a952cf62084e6f866d8ce9769cabf9874b8485c0f894fd1cfb2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/v8o-full-module-build/tb_ooo_bitmanip_gate.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 874
- `line_count`: 9
- `sha256`: 19c68b3247e5177e205896064bf4085e0f1b93b1d988919bbe2332775b0f4a22
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=874 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/v8o-full-module-bui...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 829
- `line_count`: 9
- `sha256`: eb775464072d70d7d5befea776ae4fb4fec70303f7657e06927db2fd70601676
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=829 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/v8o-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 612
- `line_count`: 5
- `sha256`: 27a38e6e014bc05663b8e0f36a90b5caa96f43441bec1b00ab2400c796e4baf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=612 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/v8o-full-module-build...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 884
- `line_count`: 9
- `sha256`: 4b89f20a49145d701b08dcbded548f7f3721a0878b79444017bc313f42a4f255
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=884 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/v8o-full-module-b...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 815e2075cb1590aa57250f750a3da151aa833cbdfa7fdd5107481def03f27e16
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/v8o-full-module-build/tb_ooo_branch...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 6
- `sha256`: 144ce23adda8ecad3d4e36e6f75c54448bd0dab3fa33732afc0e2b4b6618a348
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/v8o-full-module-build/tb_ooo_busy_table.vvp /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 432
- `line_count`: 5
- `sha256`: a0d3ca25c7ecd3a5e669a5a7e0083b6d242c1e990cfcc77b17733b093c6acdc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=432 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/v8o-full-module-build/tb_ooo_clmul_unit.vvp /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 787
- `line_count`: 9
- `sha256`: c668a5f196d64590b87786e5323a765ecaeccfbb39a43c882cffdd0d30a53005
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=787 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/v8o-full-module-build/tb_ooo_commit_out...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 852
- `line_count`: 9
- `sha256`: 74c8e3321b553fe3b23fcc3357de60970d0051fdbcce8060811760acafbd677a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=852 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/v8o-full-module-build/tb_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 839
- `line_count`: 9
- `sha256`: 5e4e364501d0a41ec9d12b01ef4295fa9e587a1a7a7746240ccb57bf22813528
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=839 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/v8o-full-module-build/tb_oo...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16849
- `line_count`: 76
- `sha256`: 8992bcf4211c3b4861793e90b51a3f5ce10980ec4e3455f8ad673dbcf56fbbee
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=16849 bytes; lines=76; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8o-full-module-build/tb_ooo_core_top_glue.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 517
- `line_count`: 5
- `sha256`: aea524dd1c58412430fd04c99f438549fcd96f9e0b0969e863ad7eb8531fc5d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=517 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/v8o-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 9cda59cca0f154ce27900f5105c6798272af762a231cba81b07c29d3c3eef3e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/v8o-full-module-build/tb_ooo_csr_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: aa7befcbaa6f277195df3f105174253d1c9547e10bc9de5a460d8134a6843c64
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/v8o-full-module-build/tb_ooo_data_word_cach...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: 6f248dfc79f134226da32b6913eb1e9c066e6c1ce4000f8695aaed48e7b8e4c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/v8o-full-module-build...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: 6f7333d1d0e6cb7a16a58d907477e3f8a20fbcc232c33014763a56982f4faba9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/v8o-full-module-build/t...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: 7f23b1bca6f4b78cea49913af3a8fdf4087f8a28c01fa62a065b3ce6bf145801
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/v8o-full-module-build/t...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5550
- `line_count`: 39
- `sha256`: b5086546a9dc41f39fb9059eff45c68c57f8599d82b20341ea24b4e93caeed01
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5550 bytes; lines=39; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8o-full-module-build/tb_ooo_dispatch_bac...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106886
- `line_count`: 846
- `sha256`: cb2b2145918c92194cf0d2b03b0838d02aafcd7812932dc36e32f5e49e18ab6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106886 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103629
- `line_count`: 779
- `sha256`: 36808dde7c6c3e8f83dfc0235d60f91a4367bbaacbbd492d2d00c1e13e9afed6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103629 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104433
- `line_count`: 788
- `sha256`: 435896390913bcf4e0d0d411c5e94ba8915ed6b7c15a6513abd04638b0822b9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104433 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106566
- `line_count`: 802
- `sha256`: 3e97c4ca7f52407ba4f0aa51993ca611ae7ef08bd5ab13382db651b5569d0371
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106566 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 5
- `sha256`: aa2c945266799f335490c8ffaa865949f6a6f616fbdc24462550719e1ab8167b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /tmp/v8o-full-module-build/tb_ooo_fetch_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: 90804a6e75ca020ae26e50d3ac4f4cadcfc1d6b54fab2371a0f238c466951dff
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/v8o-full-module-build/tb_ooo_fetch_fl...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 5
- `sha256`: 2c0cfd13f89c28c56dfa21d45851bb8418ceab7dcd8dab361605130ba463d6c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=654 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/v8o-full-module-build/tb_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 706
- `line_count`: 5
- `sha256`: b42c3ffbf726f984af14fed4e7d3afd881afd233776270932a35a1353930799d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=706 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/v8o-full-module-build/tb_ooo_fetc...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 5
- `sha256`: f089f98b5f923c74fb115169202a8f378f15eb08941176dd5534e0efcd16e85e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=615 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/v8o-full-module-build/tb_ooo_fetch_pa...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 6
- `sha256`: d36965cc2a3a8d9352cea167fc5524c2a592dcef428142d1578dc885612bcfac
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=626 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/v8o-full-module-build/tb_ooo_fetch_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 10
- `sha256`: 49765ac4b0a4a574e98c91cde61ed85786824e991dd8a2d931f5c48bd2b708f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=805 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/v8o-full-module-build/tb_ooo_fetch_pack...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: 9ef2265238ab72dae1fa80e684f2185b250b25d21c5b8f99d68dc39b6f6d1ef5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/v8o-full-module-build/tb_ooo_fe...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: bf9234ee3d87446c498c55d4fa8ee3af270e4775fec3f47c161d882a9c5de7fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/v8o-full-module-build/tb_ooo_fe...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106428
- `line_count`: 802
- `sha256`: 7de8a45aa55f361b3a9b5af527397b9abdece7d9fa5a2766b9dec589cb1ead11
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106428 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: c80f334f34fc0718e9b211c8acdd53e7a3020be20eca9a1358bcff71d71639b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/v8o-full-modu...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 56842db6bcbed1cddba933cb52fe717066f913f29e0ff0916e4f19bd73b3408c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/v8o-full-module-build/tb_ooo_fetch_requ...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 984
- `line_count`: 10
- `sha256`: 2316dd43aa0812b6f015182e6c7ac1c6f90d7ada09f0b9278af0924f559e188c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=984 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /tmp/v8o-full-module-build/tb_ooo_fe...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 19636
- `line_count`: 92
- `sha256`: 00dde475c0cb49461ab4d1a578fa3bf0d7bdd51fea5041326682a3cc3daa43f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=19636 bytes; lines=92; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/v8o-full-module-build/tb_ooo_fetch_trap_gat...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 448
- `line_count`: 5
- `sha256`: a6af54b724cdd3e49a16823fc91c3a6c36054c23511c76b47a488c23c37642c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=448 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/v8o-full-module-build/tb_ooo_fp_arith_gate.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: d859222e97e2b3b5fb0ebab04b744c21fb8440b9650868cd944391a441184e00
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/v8o-full-module-build/tb_ooo_fp_classify_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 459
- `line_count`: 5
- `sha256`: a8de89fe8e8cb3c8a6ccb416c69d71a4ace4f151643beec749f3eb9ff7e72065
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=459 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/v8o-full-module-build/tb_ooo_fp_compare_gat...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: bbc5e48925118062fafd3d98030ddc9874268c0842372dc265fae17512656c1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/v8o-full-module-build/tb_ooo_fp_convert_gat...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3954
- `line_count`: 38
- `sha256`: b63d322be199dc1bd19893f3af1ed862924eb76798c71cc5d66b7539fdf9e8eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3954 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/v8o-full-module-build/tb_ooo_fp_issue_queue.v...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 3af95e037b8f79d2d2f3289ae01042a754567b998ff35696a86fef43deef2f5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/v8o-full-module-build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1640
- `line_count`: 14
- `sha256`: 7e4c4733ad1f0f96ae18ff08131244d1dc66b58159b69d6d0a595a5312ae6ab4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1640 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/v8o-full-module-build/t...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 5
- `sha256`: 30108a147e0a5a7bf319fa91669b12be12c63c4dad880363dec1700157c4cfed
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/v8o-full-module-build/tb_ooo_fp_long_op_gat...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 997
- `line_count`: 12
- `sha256`: a3776e74c42a82fb47b35ea6a936f8a92ea55a15000cf0064648a5a01db25585
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=997 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /tmp/v8o-full-module-build/tb_ooo_fp_phys_reg_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 744
- `line_count`: 9
- `sha256`: dc2945343196c068d8b5fd40c1b6ce214bfa0b94422a3ee6bf1fed74d64fcabe
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=744 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/v8o-full-module-build/tb_ooo_fp_reg_file.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 440
- `line_count`: 5
- `sha256`: c933c1dcab2b3cebb7edb8a2601355ff340c21aa03a1997f5595b36e14b6f507
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=440 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/v8o-full-module-build/tb_ooo_fp_sgnj_gate.vvp /ho...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 432
- `line_count`: 5
- `sha256`: 5b5e40fb0c3b656545f6b868716ad7f7356ec0c27d2c06cda7f4eca2a819ac55
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=432 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/v8o-full-module-build/tb_ooo_free_list.vvp /home/lyg/PA...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 8c641e8e35e61e4824338c4e9c4018eb552acf81b2a141c2c543423b11090c1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/v8o-full-module-build/tb_ooo_fron...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 898
- `line_count`: 10
- `sha256`: 458bbb0058de3ca6942631f43affcc7730c2c0012aad53b48cae7965bf642b38
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=898 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/v8o-full-module...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 810
- `line_count`: 7
- `sha256`: 0d895a3d1fa3cadb691943c9ddd72b8213f0a44a5f0ef77b334cdfdbdef1c1ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=810 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/v8o-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: ca7fb580eb1c1c7bc5d3f22822d86400368be4dadb2fe46f18672fcc70b0bead
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/v8o-full-module-build/tb_ooo_frontend_r...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: bb30ef83077947c1b605d729937227b80cc674002dc1ff09df36f69610d75d6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/v8o-full-module-build/tb_ooo_fronte...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3841
- `line_count`: 34
- `sha256`: e6c7b0fddf6c20956ea26b0272067570cc4ec10d1fb74bdbff776f84ed23b08d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3841 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/v8o-full-module-build/tb_ooo_if...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15886
- `line_count`: 120
- `sha256`: 9a8e1420d5f02933bd26b63c9c8959f606b7415c7e2bbbb1169fef605390efe4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"ERROR": 2, "PASS": 42}
- `summary`: log evidence; size=15886 bytes; lines=120; ERROR=2; PASS=42; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8o-full-module-build/tb_ooo_int_backend.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11246
- `line_count`: 94
- `sha256`: f412b34424f67faa818c70b8cba6b0138068cdc7309b69ebc1a7112e59228d32
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=11246 bytes; lines=94; PASS=14; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/v8o-full-module-build/tb_ooo_int_issue_queu...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 842
- `line_count`: 10
- `sha256`: 04e39171d1462e921d31736c12c578d1eb6e0adec39bf2cce6254071e4875316
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=842 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /tmp/v8o-full-module-build/tb_ooo_lsu_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71272
- `line_count`: 546
- `sha256`: 759def987cd9a0b3fac9f0738e9def5f65254b77165a9041efb884ec58b6efe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 17}
- `summary`: log evidence; size=71272 bytes; lines=546; PASS=17; tail=ry/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1120
- `line_count`: 10
- `sha256`: 1a878b3ebf15c3b997dd5685141cb640f0ae55abda354b6e7ce64dd22d0f7758
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1120 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /tmp/v8o-full-module-build/tb_ooo_mem_infl...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1238
- `line_count`: 13
- `sha256`: 1168d28ad7d5f0ae178f9c54686b19a6b69735ec13fe253dee105e6f93c37d06
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=1238 bytes; lines=13; PASS=8; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /tmp/v8o-full-module-build/tb_ooo_mem_owner_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 8
- `sha256`: 5239226114aedeb9d0f424a57deedd9e05c6b6a61d4de2602343b9d614a2cd4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/v8o-full-module-build/tb_ooo_memory...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 697
- `line_count`: 8
- `sha256`: 28c7ed0622bb0cb89ebcab1c5d4e4f510ba0d188bc1f5bf858c21c0adc5d02c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=697 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /tmp/v8o-full-module-build/tb_ooo_mmu_epoch_owne...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 440
- `line_count`: 5
- `sha256`: 1b97e6949149ec376b5c7cd5f8b60bc6359785481093ed902b4d43082218d5dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=440 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/v8o-full-module-build/tb_ooo_muldiv_unit.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1166
- `line_count`: 12
- `sha256`: 2e1203f04f8ddbdaa9fe1652d3cdc382e880b0f0a490e0f70f5094f95b5b16c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1166 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/v8o-full-module-build/tb_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 8fb04d14feddf4a1b23cf91feed0df677e6e86b14aeb15b738b259b133f22849
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /tmp/v8o-full-module-build...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 954
- `line_count`: 11
- `sha256`: a38c62fb0508758bb11ce0d864e53fa4dfde8a31acbf66ac6d867098de02c184
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=954 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/v8o-full-module-build...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 981
- `line_count`: 10
- `sha256`: 2c55c2c2085147c5614ccae1a19ad33b9e77d29ae41503fff3f1624fd25dcf21
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=981 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o /tmp/v...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 848
- `line_count`: 9
- `sha256`: eab71e10ab0c9041b73a85d63afaaba1cd2ecad6fa2702aa5a1a60490a0afbdb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=848 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/v8o-full-module-build/tb_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 552
- `line_count`: 5
- `sha256`: 67fb54dd25666706f0d05c778f82deb6bc6b0cef65dcbb3f506800837fa26859
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=552 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/v8o-full-module-bui...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: da8b16e95b90e7c59c4f1dc4d719b7725e197aa881c4c25661cf98d792954eda
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/v8o-full-module-build/tb_ooo_phys_reg_file.vvp...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 576
- `line_count`: 6
- `sha256`: df9126cab2889b6b45bd9b1193d8f6d3e587ab25b14b6eff3b1961727a9630e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=576 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /tmp/v8o-full-module-build/tb_ooo_pma_checker.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 16640
- `line_count`: 71
- `sha256`: 42a130578e43f79dda5c7ef7f9618f361e585d037783e15dc71a52e0cf189303
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16640 bytes; lines=71; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/v8o-full-module-build/tb_ooo_priv_system.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: 52fd4dc743c2b796b16ee93a4a307608adab72336bacd9dadb767a2ced9d37ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/v8o-full-module-build/tb_ooo_ras_update_gat...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: c82d72d9fe4209219d3479cb25066fa1805cda55a342ab227951291904995c35
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/v8o-full-module-build/tb_ooo_redirect_arb...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: a371eea3933e39ed932c8548a52029301637f7ee0b9d0b336c89799a4d90a39d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/v8o-full-module-build/tb_ooo_rename_map.vvp /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1246
- `line_count`: 13
- `sha256`: 8ef87cb279b50db9702acf8d332798a4c1fb6ab45da1584a60a12af7ede189df
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=1246 bytes; lines=13; PASS=16; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8o-full-module-build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 830
- `line_count`: 9
- `sha256`: eb5185735928d92e641f5e11a3bb4cc3f47c40e223c2300d8c1131ec3288912c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=830 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/v8o-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2642
- `line_count`: 25
- `sha256`: d6ba8837af1492a7c568bf3868b5c4ca3afcc216b1d41a21aaad50cb93b5946c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=2642 bytes; lines=25; PASS=20; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8o-full-module-build/tb_ooo_store_queue.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 209268
- `line_count`: 1520
- `sha256`: 9665d4932febc8a6d73b3652d67454d5752d0786a02819440a61a715dbf80c3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=209268 bytes; lines=1520; PASS=2; tail=y 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: 4da54059c7e5b2e86766dccf08ff8925dda12cbef635db2b423c36042c43227c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/v8o-full-module-build/tb_ooo_trap_e...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 507c7de5f913e3ef6c9d319c8791b911468da9a8634a5bf480acbbac85026b34
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/v8o-full-module-build...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 596
- `line_count`: 6
- `sha256`: f8a74076fa3ee5318b4d3baa7b88f69f0e7a1cdfbb1f8aae5032554a902234f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=596 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /tmp/v8o-full-module-build/tb_oo...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: dd81350d6c4425b229095d7747dcbf984a7d64de408336158f0abcfd5f326041
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/v8o-full-module-build/tb_pipe_stage_reg.vvp /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17558
- `line_count`: 134
- `sha256`: 2aba254ff57e7e67c47969b04a4949256499148f2193376a4bbdf981fc516988
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17558 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/v8o-full-module-build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 369
- `line_count`: 5
- `sha256`: 8a20716593a2cc819c925cddf7b410595ef6a838993909588edcbfb50716d0c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=369 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/v8o-full-module-build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 5
- `sha256`: 927bc39ba37b2e53e81c9403e71012d1707b7036211004585e53ee0be1fa22cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=367 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/v8o-full-module-build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module/summary.txt

- `kind`: txt
- `size_bytes`: 3533
- `line_count`: 115
- `sha256`: 224d32f586e49cae6a578fc2c28420c18b5413ff1a1368d5ad34e2404f76c8a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T23:36:11+00:00
- `markers`: {"PASS": 212}
- `summary`: txt evidence; size=3533 bytes; lines=115; PASS=212; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8o-no-static-lane-semantics/evidence/full-module - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PASS...
