# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-rv64-v8n-true-ooo-long-latency
- `task_slug`: 
- `profile`: 
- `asset_count`: 36
- `total_size_bytes`: 212137

## 证据资产

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-assert.make.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 16
- `sha256`: 5e53c6047da45a89e3a8bda977fb8832b3f91285e2b59fcef15953b0abb37ff7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=606 bytes; lines=16; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module test...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13318
- `line_count`: 82
- `sha256`: 32828632e25e2f5952912891090b9362f96e1ad29c4eaa6fc8c3b85199437f50
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=13318 bytes; lines=82; PASS=12; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-baseline-assert/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-assert/summary.txt

- `kind`: txt
- `size_bytes`: 285
- `line_count`: 10
- `sha256`: e9d78a757432b259c6dc3c082da8f88486b59638b5c85d7979b9967c81af3798
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=285 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-assert - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total: 1...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-release.make.log

- `kind`: log
- `size_bytes`: 607
- `line_count`: 16
- `sha256`: 260edb5e4044c085f0d3cb26ba369c80055a60798d3a332f8cc2de7530da54d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=607 bytes; lines=16; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module test...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-release/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12767
- `line_count`: 78
- `sha256`: fcb110f09b2bb18298f18dae134b8f87da61b46360e6f8c2e799ed9c5cf32991
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=12767 bytes; lines=78; PASS=12; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-baseline-release/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-release/summary.txt

- `kind`: txt
- `size_bytes`: 286
- `line_count`: 10
- `sha256`: d25132d413b03179a6979fb1af64a73898b76dcec0bff98b4491794445870512
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=286 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-release - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total:...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/baseline-summary.log

- `kind`: log
- `size_bytes`: 101
- `line_count`: 2
- `sha256`: 2756fa6546ed7060fb89aa9e2ebdf00eb2904ddaf73f1ab9df81d82c448565b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=101 bytes; lines=2; PASS=4; tail=[V8N-BASELINE][PASS] profile=release scenarios=3/3 [V8N-BASELINE][PASS] profile=assert scenarios=3/3

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/evidence-builder.log

- `kind`: log
- `size_bytes`: 137
- `line_count`: 1
- `sha256`: 2a5bc076655c8b31c2322a0ab54ddf6f05bd230f2c9bb7fac2d0ffeec1402aa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=137 bytes; lines=1; PASS=2; tail=[V8N-EVIDENCE][PASS] true_ooo_long_latency design_id=sha256:9735bdc1f101501d0100a335b4d7ac602fa6b002d77cedbcb4245b833c2bb293 mutations=7

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-load_owner_pid_truncate.make.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 7
- `sha256`: ebd779349e959799dc2a684223a9b3dd10cdfc6d8922fa243a32b1cfbca9e011
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=524 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-load_owner_pid_truncate.mutator.log

- `kind`: log
- `size_bytes`: 120
- `line_count`: 1
- `sha256`: 1ba5be21b44bd220207233e00403c8cf377e5ac7e30739a442ae7d392036096d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=120 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] load_owner_pid_truncate -> /tmp/v8n-true-ooo.csDZUJ/mutants/load_owner_pid_truncate/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-load_owner_pid_truncate/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14612
- `line_count`: 105
- `sha256`: f5bc5e0c1f3429b417b99dc0e8525c3fffcbf3bb64df62ea68354d582f36f3bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 50, "PASS": 10}
- `summary`: log evidence; size=14612 bytes; lines=105; FAIL=50; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-load_owner_pid_truncate/tb_ooo_int_backend.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-miq_issue1_freeze.make.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 7
- `sha256`: 06bd45b76a9e04b6202740fa017746b81001791044f0c8e83288ec5d75b34746
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=518 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-miq_issue1_freeze.mutator.log

- `kind`: log
- `size_bytes`: 108
- `line_count`: 1
- `sha256`: 2bf466cec6037b401a2d971034ab250ed2d6008352b5a866d4e05974468e30b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=108 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] miq_issue1_freeze -> /tmp/v8n-true-ooo.csDZUJ/mutants/miq_issue1_freeze/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-miq_issue1_freeze/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13050
- `line_count`: 84
- `sha256`: e67b123f5a350c94e2f49a66ae14d179d935c44a4ec1c83c29ab0da0851ac03a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=13050 bytes; lines=84; FAIL=8; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-miq_issue1_freeze/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_issue1_freeze.make.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 7
- `sha256`: ee5ecd4c7c729054bf93c8b783c579899e18c77d252b1235ede90cdfc83c3c6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=521 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_issue1_freeze.mutator.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: 6471255bdbd92ebdba0464030f8b11219f824d28dc84d42794749aaae9c4dcdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=114 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] muldiv_issue1_freeze -> /tmp/v8n-true-ooo.csDZUJ/mutants/muldiv_issue1_freeze/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_issue1_freeze/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13142
- `line_count`: 85
- `sha256`: 9b36959e5f4cceaf713a6b73289e0087096bd070d70eaef05da6b77d240ac675
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 10, "PASS": 10}
- `summary`: log evidence; size=13142 bytes; lines=85; FAIL=10; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-muldiv_issue1_freeze/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_owner_pid_truncate.make.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 7
- `sha256`: 8cd2213dfe72d9aa01af0d28a29c7f87b8b805c49a188b413c76e77d83292b3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=526 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_owner_pid_truncate.mutator.log

- `kind`: log
- `size_bytes`: 124
- `line_count`: 1
- `sha256`: cc24d3ce000f336ac84f4e1c615e3bc20e55b7817c56137810ebec0c0f0256eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=124 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] muldiv_owner_pid_truncate -> /tmp/v8n-true-ooo.csDZUJ/mutants/muldiv_owner_pid_truncate/OooMulDivUnit.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_owner_pid_truncate/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 19724
- `line_count`: 179
- `sha256`: a302ce97f3a84c05f11161e8137e403a25a6d8cbd9a363ec228e75deacf3b1a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 198, "PASS": 10}
- `summary`: log evidence; size=19724 bytes; lines=179; FAIL=198; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-muldiv_owner_pid_truncate/tb_ooo_int_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_resp_pid_truncate.make.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 7
- `sha256`: cd6b62cb29143132d70ac33e2a6914796e1a6ee5cd41aee3abff840240a412ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=525 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_resp_pid_truncate.mutator.log

- `kind`: log
- `size_bytes`: 122
- `line_count`: 1
- `sha256`: a72523f1e4b77d2d2b303cc870028792d2cd047c60dd944ea5d80ef7201888aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=122 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] muldiv_resp_pid_truncate -> /tmp/v8n-true-ooo.csDZUJ/mutants/muldiv_resp_pid_truncate/OooMulDivUnit.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-muldiv_resp_pid_truncate/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13572
- `line_count`: 91
- `sha256`: acd38d4f20a66f91d2b6464a1c8ab893edde0a704fcb1c0c164054b6892fe11f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 22, "PASS": 10}
- `summary`: log evidence; size=13572 bytes; lines=91; FAIL=22; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-muldiv_resp_pid_truncate/tb_ooo_int_backend.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-retire_before_head_done.make.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 7
- `sha256`: dfc78a2d10ba4b03ec1a10397dfb391302a33abc83887229c31fbcc85666ffe1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=524 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-retire_before_head_done.mutator.log

- `kind`: log
- `size_bytes`: 113
- `line_count`: 1
- `sha256`: 3d8c9f090e0ed003e382a2dacf9b367bccfc908affd3ebdfeec87e6577163f31
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=113 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] retire_before_head_done -> /tmp/v8n-true-ooo.csDZUJ/mutants/retire_before_head_done/OooRob.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-retire_before_head_done/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15914
- `line_count`: 121
- `sha256`: f5884c7d6b51c746af221a2dd56ac744da29f9fc07088df7ad8ebb7feb6c87b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 82, "PASS": 10}
- `summary`: log evidence; size=15914 bytes; lines=121; FAIL=82; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-retire_before_head_done/tb_ooo_int_backend.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-serial_issue1.make.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 7
- `sha256`: f1bdab00279974d0fe991207ba829ad17cae708f200b39582a610b8b276ddb95
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=514 bytes; lines=7; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make[1]: *** [Makefile:3...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-serial_issue1.mutator.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: 61964f9a9f425f933173dbda64e7caefea87e5472ed136abbe432ba88d8f98c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=[V8N-MUTATOR][PASS] serial_issue1 -> /tmp/v8n-true-ooo.csDZUJ/mutants/serial_issue1/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-serial_issue1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 31375
- `line_count`: 300
- `sha256`: 6758940160ec4953725f7b9fd28df5e37c634ae8c14183e621dbf7de36caa26d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"FAIL": 440, "PASS": 10}
- `summary`: log evidence; size=31375 bytes; lines=300; FAIL=440; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8N_TRUE_OOO_LONG_LATENCY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8n-true-ooo.csDZUJ/build-mutation-serial_issue1/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/mutation-summary.log

- `kind`: log
- `size_bytes`: 705
- `line_count`: 7
- `sha256`: 23b41e49c6c82be9a8330be4eb3185059e2bcc4a1bbe692663ae3c5d3a4e79f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 56}
- `summary`: log evidence; size=705 bytes; lines=7; PASS=56; tail=[V8N-MUTATION][PASS] name=serial_issue1 compile=PASS activation=PASS semantic_rejection=PASS [V8N-MUTATION][PASS] name=miq_issue1_freeze compile=PASS activation=PASS semantic_rejection=PASS [V8N-MUTATION][PASS] name=muldiv_issue1_freeze compile=PASS activat...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/runner-summary.log

- `kind`: log
- `size_bytes`: 83
- `line_count`: 1
- `sha256`: 314b3a4919f98b2c95bf95da2006e64f76c472ab1fc1286c984f703047740897
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=83 bytes; lines=1; PASS=2; tail=[V8N-RUNNER][PASS] baselines=6/6 mutations=7/7 OOO-1=GREEN OOO-2=GREEN overall=RED

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 2360
- `line_count`: 16
- `sha256`: 46470388e63cec8bd6f6487e79353f9e728a326741370934384303eca837d93d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2360 bytes; lines=16; markers=<none>; tail=d6169429baf1715b0f522a574b9aadb8fe3f778250e3b4a698e1e6a29674d244 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/contract.md 496fab7cd3eedc5dc1cf3a3ed999f36ad5121e36c49c7e4a7bd4d2daba92d9f7 /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 2360
- `line_count`: 16
- `sha256`: 46470388e63cec8bd6f6487e79353f9e728a326741370934384303eca837d93d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2360 bytes; lines=16; markers=<none>; tail=d6169429baf1715b0f522a574b9aadb8fe3f778250e3b4a698e1e6a29674d244 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/contract.md 496fab7cd3eedc5dc1cf3a3ed999f36ad5121e36c49c7e4a7bd4d2daba92d9f7 /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 3554
- `line_count`: 38
- `sha256`: b3c0340040f949740e9886e7cc1afcfe1dc202cc04e300dbd082fe2311654ad1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {}
- `summary`: log evidence; size=3554 bytes; lines=38; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_arbitrary_older_valid_and_reservation_freeze_are_red (test_architecture_hard_gates.NegativeTests.test_arbitrary_older_valid_and_reservation_freeze_are_red) ... ok test_capabil...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/static/architecture-result.json

- `kind`: json
- `size_bytes`: 45383
- `line_count`: 1027
- `sha256`: f9cf3008dadd62c2fdffd990d46f62cd46fa4bbdd320ab811d5c1f9cce07b62c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {"PASS": 8}
- `summary`: json evidence; size=45383 bytes; lines=1027; PASS=8; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8n-true-ooo-long-latency/evidence/focused/static/checker-unit.log

- `kind`: log
- `size_bytes`: 3743
- `line_count`: 27
- `sha256`: 99b19c464c042c8c06bfd763e8d196d2ce84305246a079ecba9bfd285d87c151
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T22:51:14+00:00
- `markers`: {}
- `summary`: log evidence; size=3743 bytes; lines=27; markers=<none>; tail=test_arbitrary_older_valid_and_reservation_freeze_are_red (eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_arbitrary_older_valid_and_reservation_freeze_are_red) ... ok test_capability_metadata_and_swap_make_asymmetry_legal (eval.ppa.tests.tes...
