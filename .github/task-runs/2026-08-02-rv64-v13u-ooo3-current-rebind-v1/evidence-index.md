# Evidence Index

## 基本信息

- `task_id`: 2026-08-02-rv64-v13u-ooo3-current-rebind-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 109
- `total_size_bytes`: 1054519

## 证据资产

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/architecture-current.json

- `kind`: json
- `size_bytes`: 19241
- `line_count`: 255
- `sha256`: 90e4421f343f7b5027c99e23e4631d70a19e8f6ea01b58bb029e8aea9fdff500
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=19241 bytes; lines=255; PASS=2; tail={ "design_id": "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488", "generated_at_utc": "2026-08-01T22:47:03.936708+00:00", "schema": "npc-rv64-architecture-directed-suite-v2", "tests": { "memory_ordering": { "command": "make -C npc/rv...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/architecture-manifest.post.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: f79840bef4db9fa2672d9dc732e39eecd15e2ab964722d1a773beeee76cac560
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/architecture-manifest.pre.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: f79840bef4db9fa2672d9dc732e39eecd15e2ab964722d1a773beeee76cac560
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=a0bd58bf4ef9bdfa7724087af3dcef79a72cb8384d8e1e8131d20957897c1bc1 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/final.log

- `kind`: log
- `size_bytes`: 194
- `line_count`: 1
- `sha256`: 6a885b85b99d8153a3f075847c95be6e2a69ef471d350e13023ba9f8710b8fca
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=194 bytes; lines=1; PASS=2; tail=[V8S-F2][PASS] run_id=v8s-f2-20260801T221621Z-219527 claim=architecture_checkpoint profiles=6 mutations=18 predecessor=F1_FROZEN_REPLAY architecture=RED ppa=UNQUALIFIED promotion_eligible=false

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutation-summary.log

- `kind`: log
- `size_bytes`: 6498
- `line_count`: 18
- `sha256`: f348f7233d77d18826c12ef95083874be54471c6061dfbe9a5db5d6c5aafebbc
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 36}
- `summary`: log evidence; size=6498 bytes; lines=18; PASS=36; tail=[V8S-MUTATION][PASS] run_id=v8s-f2-20260801T221621Z-219527 name=bank1_tieoff compile_success=true elaborated=true activated=true target_rejected=true oracle=V8S bank1 valid independent of ready mutant_sha256=8ff2c9739557bb68f390d80d6611792481e0f261153aa629c...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/alias_miq1_completion_head.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/alias_miq1_completion_head.mutator.log

- `kind`: log
- `size_bytes`: 216
- `line_count`: 1
- `sha256`: 40397f424a5299626879e2acca50c5c91a1937ac22927b228d03fce1a94e9a8f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=216 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=alias_miq1_completion_head source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/alias_miq1_completion_head/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/alias_miq1_completion_head.run.log

- `kind`: log
- `size_bytes`: 245
- `line_count`: 4
- `sha256`: 60dd5350119083f5f342909d8d9a831d82f8ab7df09a4613308d223f970b6142
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=245 bytes; lines=4; FAIL=2; tail=[CHECK-FAIL] V8S bank1 PID reaches MIQ got=0 expected=1 [V8S-MEM1-PID-INDEX] token PID=00 raw=1 @19 FATAL: /tmp/v8s-dual-memory-core.suMDo9/mutants/alias_miq1_completion_head/OooIntBackend.v:8167: Time: 19 Scope: tb_ooo_int_backend.dut

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/allow_killed_mem1_wb.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/allow_killed_mem1_wb.mutator.log

- `kind`: log
- `size_bytes`: 204
- `line_count`: 1
- `sha256`: 92a3f9d3eb659a58d2680fbf4dd812ad9345fcbbbe5397b2fbd8d04671f92fe5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=204 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=allow_killed_mem1_wb source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/allow_killed_mem1_wb/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/allow_killed_mem1_wb.run.log

- `kind`: log
- `size_bytes`: 1002
- `line_count`: 12
- `sha256`: def5d719657def0e139c151f206c139a13899390ceb1f4ea41aafa5ff8cfa5a9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"ERROR": 2, "FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=1002 bytes; lines=12; FAIL=4; ERROR=2; PASS=10; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bank1_tieoff.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bank1_tieoff.mutator.log

- `kind`: log
- `size_bytes`: 188
- `line_count`: 1
- `sha256`: 8a57c4eb9988598f132ff594b125922eb3f5e884568b27f6ce84edb3b3e40060
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=188 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=bank1_tieoff source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/bank1_tieoff/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bank1_tieoff.run.log

- `kind`: log
- `size_bytes`: 791
- `line_count`: 12
- `sha256`: c8686ca26a793268954f2c696b26a0ba54b0ed8c133fc557d396773dc4fe6ce5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 18}
- `summary`: log evidence; size=791 bytes; lines=12; FAIL=18; tail=[CHECK-FAIL] V8S bank1 valid independent of ready got=0 expected=1 [CHECK-FAIL] V8S bank1 request fire got=0 expected=1 [CHECK-FAIL] V8S bank1 MIQ count got=0x00000000 expected=0x00000001 [CHECK-FAIL] V8S bank1 expected tuple live got=0 expected=1 [CHECK-FA...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_checkpoint_commit1_block.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_checkpoint_commit1_block.mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: 842f31debca5b6e6f3ba0b942ffcab49b79400fff7184303a3a298fbdcfcb34b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=bypass_checkpoint_commit1_block source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/bypass_checkpoint_commit1_block/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_checkpoint_commit1_block.run.log

- `kind`: log
- `size_bytes`: 815
- `line_count`: 10
- `sha256`: def1bca8d1515c0ade1df5ebf27d7ad4af84c647ef22a9adea2c9cd14da2c03c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 2, "PASS": 12}
- `summary`: log evidence; size=815 bytes; lines=10; FAIL=2; PASS=12; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_checkpoint_irrevocable_guard.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_checkpoint_irrevocable_guard.mutator.log

- `kind`: log
- `size_bytes`: 234
- `line_count`: 1
- `sha256`: c6bc6adc1db1ede526302cafd5ae8dd3ca5be0cadc6aff979dc92d95d739353a
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=234 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=bypass_checkpoint_irrevocable_guard source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/bypass_checkpoint_irrevocable_guard/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_checkpoint_irrevocable_guard.run.log

- `kind`: log
- `size_bytes`: 971
- `line_count`: 12
- `sha256`: 5a39ed00aadb816ac1953441c15077411f32e8e00cb6c6f58e27bc1b25ba3b60
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 6, "PASS": 12}
- `summary`: log evidence; size=971 bytes; lines=12; FAIL=6; PASS=12; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_lq_retire_permit.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_lq_retire_permit.mutator.log

- `kind`: log
- `size_bytes`: 210
- `line_count`: 1
- `sha256`: 36a7e95b577daa248cb78c1d6569750542ce176fe9921081cc0fa58a887fa4ee
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=210 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=bypass_lq_retire_permit source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/bypass_lq_retire_permit/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/bypass_lq_retire_permit.run.log

- `kind`: log
- `size_bytes`: 1569
- `line_count`: 16
- `sha256`: e8cb94814b45b6ca6d1ae3043ced7fb03bf537f50fc996e2de4b38f9ad1662bb
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 2, "PASS": 24}
- `summary`: log evidence; size=1569 bytes; lines=16; FAIL=2; PASS=24; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/double_claim_wb0.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/double_claim_wb0.mutator.log

- `kind`: log
- `size_bytes`: 196
- `line_count`: 1
- `sha256`: 82054921fd8b1650fd6b1cd8ef7d8cdf617a690bd727a2bb0c1b1a8b85ccb0f6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=196 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=double_claim_wb0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/double_claim_wb0/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/double_claim_wb0.run.log

- `kind`: log
- `size_bytes`: 4546
- `line_count`: 50
- `sha256`: d1c12a776a99820e7f4aa7089d719f0b71792e960b3c9c1112fe478d021e6854
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"ERROR": 8, "FAIL": 38, "PASS": 42}
- `summary`: log evidence; size=4546 bytes; lines=50; FAIL=38; ERROR=8; PASS=42; tail=[CHECK-FAIL] V8S bank1 owns WB1 got=0 expected=1 [CHECK-FAIL] V8S simultaneous WB1 valid got=0 expected=1 [CHECK-FAIL] V8S WB1 exact ROB got=0x00000000 expected=0x00000001 [CHECK-FAIL] V8S WB1 load data got=0x0000000000000000 expected=0xaaaabbbbccccdddd ERR...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/duplicate_bridge_drop_token.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/duplicate_bridge_drop_token.mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: 6471585f3a55684452165fdb50f0fbcfff6898f674cf8425e8db710387b50856
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=duplicate_bridge_drop_token source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/duplicate_bridge_drop_token/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/duplicate_bridge_drop_token.run.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: 2aab0718be8c568ca47aa05e4a31407a8e507a0aa30221cc19af96cb9d26a01d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=481 bytes; lines=5; markers=<none>; tail=[S2-G1-TCOLL-INGRESS-DUP] same token arrived on multiple ingress lanes valid=000000010100 duplicate=000000010100 pending=00000000 live=00000003 [S2-G1-TCOLL-INGRESS] lane=2 kind=00 token=0 epoch=00 duplicate=1 pending=0 live=1 [S2-G1-TCOLL-INGRESS] lane=4 k...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/invert_same_bank_age.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/invert_same_bank_age.mutator.log

- `kind`: log
- `size_bytes`: 204
- `line_count`: 1
- `sha256`: 234693188a32ba4e623f285afeb4bdaac2f0d253a3eca13c95f4e5f91f12ecf7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=204 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=invert_same_bank_age source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/invert_same_bank_age/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/invert_same_bank_age.run.log

- `kind`: log
- `size_bytes`: 4113
- `line_count`: 45
- `sha256`: 7060d48c1c2bae13e4949652308c971e765e2ecb7e4dbc70117bab6ad8202075
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 44, "PASS": 42}
- `summary`: log evidence; size=4113 bytes; lines=45; FAIL=44; PASS=42; tail=[CHECK-FAIL] V8S same-bank older selected got=0x0000000000000320 expected=0x0000000000000300 [CHECK-FAIL] V8S same-bank older consumes got=0 expected=1 [CHECK-FAIL] V8S same-bank younger held got=1 expected=0 [CHECK-FAIL] V8S same-bank older reservation dra...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/legacy_release_lookthrough.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/legacy_release_lookthrough.mutator.log

- `kind`: log
- `size_bytes`: 216
- `line_count`: 1
- `sha256`: 3cb76190061bef401dcfaa0fa95cde2470f678f28ee967d873a6b2acc111cbaa
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=216 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=legacy_release_lookthrough source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/legacy_release_lookthrough/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/legacy_release_lookthrough.run.log

- `kind`: log
- `size_bytes`: 2776
- `line_count`: 27
- `sha256`: 89e0a78ca4e396f07f02154528c01d591b8d470f095b87a03522d8458c4388f7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 8, "PASS": 42}
- `summary`: log evidence; size=2776 bytes; lines=27; FAIL=8; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_dispatch_recovery.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_dispatch_recovery.mutator.log

- `kind`: log
- `size_bytes`: 230
- `line_count`: 1
- `sha256`: 94dfa1a3655baf2096cc3cb8c5e63ec450b614414055916c9e0388768a465278
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=230 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=omit_checkpoint_dispatch_recovery source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/omit_checkpoint_dispatch_recovery/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_dispatch_recovery.run.log

- `kind`: log
- `size_bytes`: 3367
- `line_count`: 33
- `sha256`: 4090681bf18858a398b78acdf34130276e8eec507a486469bd2403619fa516a4
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 20, "PASS": 42}
- `summary`: log evidence; size=3367 bytes; lines=33; FAIL=20; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_lq_recovery.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_lq_recovery.mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: 3867c6d3bc2ded7802e16d9785a6cb94e5cbcc7c2469790e2700f283cad405a6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=omit_checkpoint_lq_recovery source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/omit_checkpoint_lq_recovery/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_lq_recovery.run.log

- `kind`: log
- `size_bytes`: 2866
- `line_count`: 28
- `sha256`: 605f7252a831b580cf703a12f1fd8efda81f0e6d24a86fdcc56563591b4c474b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 10, "PASS": 42}
- `summary`: log evidence; size=2866 bytes; lines=28; FAIL=10; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_sq_recovery.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_sq_recovery.mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: ea862f24df7f1362c2f560ec4a7fc64ce11736eab5703f0a0e875ddb68d9b8a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=omit_checkpoint_sq_recovery source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/omit_checkpoint_sq_recovery/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/omit_checkpoint_sq_recovery.run.log

- `kind`: log
- `size_bytes`: 2656
- `line_count`: 25
- `sha256`: 136a26fc006a1ecddfa6efdad7c355f0f790dc9ec35d3daf40e5bf12204030d0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 4, "PASS": 42}
- `summary`: log evidence; size=2656 bytes; lines=25; FAIL=4; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/ordinary_store_direct_write.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/ordinary_store_direct_write.mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: 4337e88d2122854962810dc988d694c5e03e2340a2775ea1f55e37643d21cb8f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=ordinary_store_direct_write source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/ordinary_store_direct_write/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/ordinary_store_direct_write.run.log

- `kind`: log
- `size_bytes`: 2824
- `line_count`: 28
- `sha256`: 5a2a63890670751590f38842b3e4a83dfdae98c75dd5fb86fd80d4c555c118e1
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 10, "PASS": 42}
- `summary`: log evidence; size=2824 bytes; lines=28; FAIL=10; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [CHECK-FAIL] V8S dual-store b...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/raw_checkpoint_local_flush_bypass.compile.log

- `kind`: log
- `size_bytes`: 293
- `line_count`: 3
- `sha256`: ee4af828d65b215461e06e6f4e064ce70fbf2b093b71f5a0ddd54065703da112
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=293 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:660: /tmp/v8s-dual-memory-core.suMDo9/mutants/raw_checkpoint_local_flush_bypass/result/logs/tb_ooo_core_top_glue.log] Error 1 make: Leaving directory '/home/lyg/PA...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/raw_checkpoint_local_flush_bypass.mutator.log

- `kind`: log
- `size_bytes`: 250
- `line_count`: 1
- `sha256`: 8f26247d6a665a31c860d347685c0875d65d9d5427b97231b87010857d9e3db5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=250 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=raw_checkpoint_local_flush_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCoreSliceControlGate.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/raw_checkpoint_local_flush_bypass/OooCoreSliceControlGate.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/raw_checkpoint_local_flush_bypass.run.log

- `kind`: log
- `size_bytes`: 24580
- `line_count`: 141
- `sha256`: 1f37bbf97bee55aafd8f0abebe18c98bcf37f35118fcc7ca02061dcaeff07549
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 12, "PASS": 8}
- `summary`: log evidence; size=24580 bytes; lines=141; FAIL=12; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8s-dual-memory-core.suMDo9/mutants/raw_checkpoint_local_flush_bypass/build/tb_ooo_core_top_glue.vvp /home/lyg/PA/y...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/singleton_priority_bypass.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/singleton_priority_bypass.mutator.log

- `kind`: log
- `size_bytes`: 214
- `line_count`: 1
- `sha256`: c32d6de6ea72dc2857da3e43cc09b91969302e2209351ac06818b950b1b06b20
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=214 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=singleton_priority_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/singleton_priority_bypass/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/singleton_priority_bypass.run.log

- `kind`: log
- `size_bytes`: 3145
- `line_count`: 31
- `sha256`: ad1809c3d26cc3f252f4c75b1dc5f8065fb7b9a7c1aa0ba14abe54e3a4400656
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"ERROR": 2, "FAIL": 12, "PASS": 42}
- `summary`: log evidence; size=3145 bytes; lines=31; FAIL=12; ERROR=2; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/swap_bank_mapping.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/swap_bank_mapping.mutator.log

- `kind`: log
- `size_bytes`: 198
- `line_count`: 1
- `sha256`: fd1ff70517973aa79078489038d0125bc7ed21ecd0dae37ab33598f1069da37f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=198 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=swap_bank_mapping source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/swap_bank_mapping/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/swap_bank_mapping.run.log

- `kind`: log
- `size_bytes`: 1623
- `line_count`: 22
- `sha256`: 00dea56ecec9e6a8728d23ec173029fa5d716eb5afaaf15c841f728329100a7d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 38}
- `summary`: log evidence; size=1623 bytes; lines=22; FAIL=38; tail=[CHECK-FAIL] V8S bank0 captured address got=0x0000000000000208 expected=0x0000000000000200 [CHECK-FAIL] V8S bank1 captured address got=0x0000000000000200 expected=0x0000000000000208 [CHECK-FAIL] V8S bank0 PID reaches MIQ got=0 expected=1 [CHECK-FAIL] V8S ba...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/tieoff_sq_terminal1.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/tieoff_sq_terminal1.mutator.log

- `kind`: log
- `size_bytes`: 202
- `line_count`: 1
- `sha256`: 8b24e98f2cb6909a7a8f1a82eabc9636af8d5a0a5bd82a450ef18ab9e4d57be5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=202 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=tieoff_sq_terminal1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.suMDo9/mutants/tieoff_sq_terminal1/OooIntBackend.v

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/mutations/tieoff_sq_terminal1.run.log

- `kind`: log
- `size_bytes`: 2627
- `line_count`: 25
- `sha256`: 507b34d7d297f80c221c6ea63c0158b8fc5fee3c4ee44dfcc32b9af6de1228c7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 4, "PASS": 42}
- `summary`: log evidence; size=2627 bytes; lines=25; FAIL=4; PASS=42; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [CHECK-FAIL] V8S dual-store f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profile-summary.log

- `kind`: log
- `size_bytes`: 477
- `line_count`: 3
- `sha256`: 445671001eb50b0fd8c4f8834f884105874e8aa095075d91984d4225b3016b6c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=477 bytes; lines=3; PASS=6; tail=[V8S-PROFILE][PASS] run_id=v8s-f2-20260801T221621Z-219527 profile=focused-release image_sha256=95cb026cdc6fb29e4b3a1fb63b7055400f016a181d18c8cefae5ddb7f88a3fe8 [V8S-PROFILE][PASS] run_id=v8s-f2-20260801T221621Z-219527 profile=focused-assert image_sha256=d5d...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profiles/focused-assert.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profiles/focused-assert.run.log

- `kind`: log
- `size_bytes`: 2522
- `line_count`: 23
- `sha256`: 98383846cfabb137dc68e3895891e384f492390541375312bd3f31c9b31cbe0b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 44}
- `summary`: log evidence; size=2522 bytes; lines=23; PASS=44; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profiles/focused-release.compile.log

- `kind`: log
- `size_bytes`: 15513
- `line_count`: 113
- `sha256`: 910c4614d802ee5debcd053f46eaa99b7ddbb21ceee2dfeeb150e083811f488c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=15513 bytes; lines=113; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profiles/focused-release.run.log

- `kind`: log
- `size_bytes`: 2522
- `line_count`: 23
- `sha256`: 98383846cfabb137dc68e3895891e384f492390541375312bd3f31c9b31cbe0b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 44}
- `summary`: log evidence; size=2522 bytes; lines=23; PASS=44; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profiles/legacy-assert.compile.log

- `kind`: log
- `size_bytes`: 16749
- `line_count`: 122
- `sha256`: a9b236497db656da5f7255ece51b31569bdc964e4e14526e096cf5dd532c91a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=16749 bytes; lines=122; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:803: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:804: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/profiles/legacy-assert.run.log

- `kind`: log
- `size_bytes`: 6173
- `line_count`: 95
- `sha256`: 92692f0874fc3f7cb0120d51a216b0a2d5c790a0a9872d393b3a6587e8b3ec7e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"ERROR": 2, "PASS": 100}
- `summary`: log evidence; size=6173 bytes; lines=95; ERROR=2; PASS=100; tail=[V8K-PENDING-CSR-LEASE] raw onehot/reuse fence/public PID transport PASS [V8J-BRANCH-RESOLVE-AUTH] live/stale/mismatch/death-edge/self-kill PASS [T4H-PMA-PRECISE-STORE] cause=7 tval=0000000018000040 SQ-fill=0 drain=0 [T4N-B-ERROR-PRECISE] va=0x0000000040001...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/result.json

- `kind`: json
- `size_bytes`: 1781
- `line_count`: 49
- `sha256`: a04ca4b2ea7d2bb32843509da5d3f2605f6e27b6b090efcdc56155286120cf08
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=1781 bytes; lines=49; PASS=16; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "claim": "architecture_checkpoint", "core_glue_tb_sha256": "a6cd3c93d42109b9319e4fc9e5544cc0b0a2e52ee576c645ef4fb2a433e928aa", "detecte...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/run-id.txt

- `kind`: txt
- `size_bytes`: 31
- `line_count`: 1
- `sha256`: 1ae44697f06db8fc74f606603a626f6ef2f8fb3810e823accad59e536e0d7f95
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: txt evidence; size=31 bytes; lines=1; markers=<none>; tail=v8s-f2-20260801T221621Z-219527

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 11613
- `line_count`: 80
- `sha256`: 09f2e0f4f5b87eb715c373e8a9bde5d2bdc3ea00fb704ba30fb9d223cdb8d5e9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=11613 bytes; lines=80; markers=<none>; tail=0d4c4f43e9b92eb02281a9261850993c90a5d602d6232536d992ca728b57969a /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/contract.md e0796def32dbca1ae1e111e0125548adc0142dbd2dacf86c653dca8fe9694eb3 /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 11613
- `line_count`: 80
- `sha256`: 09f2e0f4f5b87eb715c373e8a9bde5d2bdc3ea00fb704ba30fb9d223cdb8d5e9
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=11613 bytes; lines=80; markers=<none>; tail=0d4c4f43e9b92eb02281a9261850993c90a5d602d6232536d992ca728b57969a /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/contract.md e0796def32dbca1ae1e111e0125548adc0142dbd2dacf86c653dca8fe9694eb3 /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 62345
- `line_count`: 1436
- `sha256`: ab7c59eb18341a8bb2691bb8c6e138169e2870f5bb0b94921af625145285d027
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 36}
- `summary`: json evidence; size=62345 bytes; lines=1436; PASS=36; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "8884fa871095e01f4e5bdacface70991f986d4114b73f72e9ccf10b1e2069b73" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 11
- `sha256`: 2a54bff0c29f4f398dd8345d166dc468ceac76266497efc6b416724cfe982194
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=396 bytes; lines=11; markers=<none>; tail=DI-1: RED (3 red checks) DI-2: RED (3 red checks) DI-3: RED (3 red checks) DI-4: RED (3 red checks) DI-5: RED (3 red checks) OOO-1: RED (3 red checks) OOO-2: RED (3 red checks) OOO-3: RED (3 red checks) OOO-4: RED (3 red checks) OVERALL: RED RESULT: /home/l...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/checker-unit.log

- `kind`: log
- `size_bytes`: 1720
- `line_count`: 20
- `sha256`: 1b40fbbb23d5a823aceaebaf88aa6e642b06a08a54a9f916ccfaaa8bad811fb7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=1720 bytes; lines=20; markers=<none>; tail=test_bank1_tieoff_is_rejected (__main__.CheckerTests.test_bank1_tieoff_is_rejected) ... ok test_baseline_all_checks_pass (__main__.CheckerTests.test_baseline_all_checks_pass) ... ok test_canonical_disable_is_rejected (__main__.CheckerTests.test_canonical_di...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/contract.log

- `kind`: log
- `size_bytes`: 4288
- `line_count`: 32
- `sha256`: c792394ab556735c63811a6c55769d773b8621b8efa5e017fd99e8871b19a02a
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 8, "PASS": 6}
- `summary`: log evidence; size=4288 bytes; lines=32; FAIL=8; PASS=6; tail=test_assertion_only_shadows_are_not_production_holders (npc.rv64.eval.ppa.tests.test_producer_holder_census.ProducerHolderCensusTests.test_assertion_only_shadows_are_not_production_holders) ... ok test_baseline_is_field_and_instance_complete_and_hash_bound...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/f1-handoff.json

- `kind`: json
- `size_bytes`: 398
- `line_count`: 14
- `sha256`: 57499335d2d914df38640dfce5554baa7a45b149c93bd18fe4736820a7ca6c5b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=398 bytes; lines=14; PASS=2; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_core_integration": true, "canonical_stage": "F2_PROMOTED", "claim": "dual_bridge_cache_hit_leaf_verified", "ppa": "UNQUALIFIED", "run_id": "v8r-f1-20260731T222747Z-3901379", "...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/f1-permanent-target.log

- `kind`: log
- `size_bytes`: 79
- `line_count`: 1
- `sha256`: 0cfbf6ef71b836d5a5d60307ef2684ca5672cea1110b10c1a6d2136e52f379ab
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=79 bytes; lines=1; markers=<none>; tail=[V8S-F1-REPLAY] scoped refresh consumes frozen F1 result; no F1 runner invoked

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/npc-core-assert-lint.log

- `kind`: log
- `size_bytes`: 9702
- `line_count`: 3
- `sha256`: ef593c203ff025dbd46e61bb39262290e24c8e6904b993266eead90a78ecf7e8
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=9702 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only --timescale 1ns/1ps -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/npc-core-release-lint.log

- `kind`: log
- `size_bytes`: 9684
- `line_count`: 3
- `sha256`: a9db076e80ad848268b26d7d3de0888435f0f6d552820bd61d41f8bcb80813e0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=9684 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only --timescale 1ns/1ps -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/npc-sim-assert-stats-lint.log

- `kind`: log
- `size_bytes`: 9790
- `line_count`: 3
- `sha256`: 2ca357eefbed5d30238db9dee7839d4fdabb0a579b20e196ca5ca8de338b2c49
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=9790 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only --timescale 1ns/1ps -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/rtl-style.log

- `kind`: log
- `size_bytes`: 305
- `line_count`: 4
- `sha256`: f53131c53120ae51bb7e0d91729aa02bf171896a37ba14e3c85ff1587ee54b04
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=305 bytes; lines=4; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 扩展名、Verilog-2001 关键字和 module 命名均合规 [RTL-STYLE-NAMING][PASS] retired=AxiXbar rejected legal=L2XbarAdapter accepted make: Leaving directory '/home/lyg/PA/ysyx-work...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/source-checks.json

- `kind`: json
- `size_bytes`: 4549
- `line_count`: 114
- `sha256`: e76739275e0a09e032b836d7a5a583bfb86a39c9a69325473daf7fb89a07951e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: json evidence; size=4549 bytes; lines=114; markers=<none>; tail={ "checks": [ { "check_id": "hierarchy.default_off_reusable_chain", "detail": "counts={'backend': 1, 'decode': 1, 'slice': 1, 'execute': 1, 'glue': 1}", "passed": true }, { "check_id": "hierarchy.explicit_parameter_handoff", "detail": "counts={'decode': 1,...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/f2-current/static/source-checks.log

- `kind`: log
- `size_bytes`: 3078
- `line_count`: 18
- `sha256`: 2f7f674ffb745877bc9488fd9bf31e5dff7cdbc807f1cc5e9685d1775b1081bd
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 36}
- `summary`: log evidence; size=3078 bytes; lines=18; PASS=36; tail=[V8S-CHECK][PASS] hierarchy.default_off_reusable_chain: counts={'backend': 1, 'decode': 1, 'slice': 1, 'execute': 1, 'glue': 1} [V8S-CHECK][PASS] hierarchy.explicit_parameter_handoff: counts={'decode': 1, 'slice': 1, 'execute': 1, 'glue': 1} [V8S-CHECK][PAS...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/lq-mutations/mutation-results.json

- `kind`: json
- `size_bytes`: 7159
- `line_count`: 167
- `sha256`: 4d16da0d41fd24ecfbb89830880afc0a0419d43798354bb921612620f364222c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"FAIL": 36}
- `summary`: json evidence; size=7159 bytes; lines=167; FAIL=36; tail={ "schema_version": "rv64-lq-mutation-evidence-v1", "generated_at_utc": "2026-08-01T22:47:03.826156+00:00", "source": "npc/rv64/vsrc/memory/OooLoadQueue.v", "source_sha256": "5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f", "testbench": "n...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/lq-mutations/mutation-results.md

- `kind`: md
- `size_bytes`: 1472
- `line_count`: 17
- `sha256`: f1ba9369642c3dd4869b07ec9de98ceb184e4c8a0a6d5084077690deba17b8b5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 54}
- `summary`: md evidence; size=1472 bytes; lines=17; PASS=54; tail=# OOO-3 LQ compile-success mutation results - source SHA-256: `5dc60f2f792ecd3c42bc8111a4522cef14736e09cb1b80f5d12e225b71eec92f` - mutations: `9/9` rejected by dynamic hardware oracles - all passed: `true` | Mutation | RTL representation | Compile | Dynamic...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/memory-ordering.log

- `kind`: log
- `size_bytes`: 4724
- `line_count`: 46
- `sha256`: 46b279af663e1280b19f5eacd51412e63ff1a0cdc0fb812615ef73f8485fd32c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=4724 bytes; lines=46; PASS=2; tail=OOO-3 memory ordering evidence run_id=rv64-v13u-ooo3-current-rebind-v1 generated_at_utc=2026-08-01T22:47:03.936708+00:00 design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 rtl_file_count=146 provenance_sha256=45498e9732bad9dbe...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/backend-dual.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/backend-dual/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 21860
- `line_count`: 148
- `sha256`: 9bab338bae918cd8002db476d3f60b8e26e52801cb412709db9874ef74b95bc7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 46}
- `summary`: log evidence; size=21860 bytes; lines=148; PASS=46; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8v-ooo3-focused.6y0cDd/build-backend-dual/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/backend.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/backend/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 25481
- `line_count`: 220
- `sha256`: 5b3e8649f4f2c382d08811bc772ebe39e04d1c2c5f3995cd8edb6bd1bf7eebcb
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"ERROR": 2, "PASS": 102}
- `summary`: log evidence; size=25481 bytes; lines=220; ERROR=2; PASS=102; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8v-ooo3-focused.6y0cDd/build-backend/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v /h...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/final.log

- `kind`: log
- `size_bytes`: 134
- `line_count`: 1
- `sha256`: 813cc892254070978bdc824c6a97b838816b2e04b01c006179ed8ca3779069c0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=134 bytes; lines=1; PASS=2; tail=[V8V-OOO3-RUNNER][PASS] run_id=rv64-v13u-ooo3-current-rebind-v1 mode=1 metrics=11 mutations=9 OOO-3=GREEN overall=RED ppa=UNQUALIFIED

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/glue.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/glue/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24159
- `line_count`: 134
- `sha256`: 6c66778f775abd6ba6442709a2b8b8ffbaadbc07c7500237e92a342ff44a9c1c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=24159 bytes; lines=134; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8v-ooo3-focused.6y0cDd/build-glue/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCo...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/lq.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/lq/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 1090
- `line_count`: 13
- `sha256`: cee81163504d2347fc940fe9c40170216f9ef03b736ac81c5c5709e3521945cd
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=1090 bytes; lines=13; PASS=14; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /tmp/v8v-ooo3-focused.6y0cDd/build-lq/tb_ooo_load_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooLoadQueue.v te...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/result.json

- `kind`: json
- `size_bytes`: 760
- `line_count`: 36
- `sha256`: 2505409d65ab1c8a4d1cf5917ebc72b215c9c3c9bcefe81ae0577334a45b2153
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=760 bytes; lines=36; PASS=2; tail={ "architecture": { "green": [ "OOO-3" ], "overall": "RED", "red": [ "DI-1", "DI-2", "DI-3", "DI-4", "DI-5", "OOO-1", "OOO-2", "OOO-4" ] }, "claim": "ooo3_memory_ordering", "design_id": "sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a748...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/run-id.txt

- `kind`: txt
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 67e7fd87d68cd5ba05de657ac8f2d882dd3ebd2946469f0187c26cd6392c4792
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: txt evidence; size=33 bytes; lines=1; markers=<none>; tail=rv64-v13u-ooo3-current-rebind-v1

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 6607
- `line_count`: 46
- `sha256`: a12535809777d3abcc2d67e95d5f89398ed8bd974a59dad334c321b06c1907dd
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=6607 bytes; lines=46; markers=<none>; tail=4cbcb9163f9f740435dc61dfca60f78b82b3f00d478233b3f19a179d5ee37353 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/contract.md f0f950ee527e56ba7247408c612667c9bb981b02d97c2e7503d7bf01e2e8add5 /home/lyg/PA/ysyx-workbench/.gith...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 6607
- `line_count`: 46
- `sha256`: a12535809777d3abcc2d67e95d5f89398ed8bd974a59dad334c321b06c1907dd
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=6607 bytes; lines=46; markers=<none>; tail=4cbcb9163f9f740435dc61dfca60f78b82b3f00d478233b3f19a179d5ee37353 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-21-rv64-v8v-memory-ordering/contract.md f0f950ee527e56ba7247408c612667c9bb981b02d97c2e7503d7bf01e2e8add5 /home/lyg/PA/ysyx-workbench/.gith...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/sq.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/sq/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 11773
- `line_count`: 96
- `sha256`: aca02c6611159087da87e25a6643a485b546246206161a42be5f84153e259065
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=11773 bytes; lines=96; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8v-ooo3-focused.6y0cDd/build-sq/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue....

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/static/architecture-gates.log

- `kind`: log
- `size_bytes`: 5409
- `line_count`: 50
- `sha256`: 6703cf0328088d9c25d00416a7e4c65aa0b4b0c777a042ea73139cb88e3117ab
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=5409 bytes; lines=50; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_actual_di3_chain_rejects_each_structural_cut (test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pa...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/static/architecture-result.json

- `kind`: json
- `size_bytes`: 54092
- `line_count`: 1216
- `sha256`: c9c4813923841df6adab63fc9f2a8c1a8421796ab38ecfc12e7a8d836d2817f7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 4}
- `summary`: json evidence; size=54092 bytes; lines=1216; PASS=4; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "8884fa871095e01f4e5bdacface70991f986d4114b73f72e9ccf10b1e2069b73" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/static/architecture-unit.log

- `kind`: log
- `size_bytes`: 6719
- `line_count`: 43
- `sha256`: 87a66a7b7848aabcf2e2a13ed762cd6f31343b7da8457a940f53c9d82d0bbf8b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=6719 bytes; lines=43; markers=<none>; tail=test_actual_di3_chain_rejects_each_structural_cut (npc.rv64.eval.ppa.tests.test_architecture_hard_gates.NegativeTests.test_actual_di3_chain_rejects_each_structural_cut) ... ok test_actual_di4_chain_cannot_pass_vacuously_or_statically (npc.rv64.eval.ppa.test...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/static/evidence-builder.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: 57cf84b5fa8ea6b0687460e8639c10ec61fa33dfdad55ae09eae3b37b9ce747e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=147 bytes; lines=1; PASS=2; tail=[V8V-OOO3-EVIDENCE][PASS] memory_ordering design_id=sha256:093c2380b997029944aa4462015d83711d7c5f1d52b15b4803c4515a581a7488 metrics=11 mutations=9

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/static/manifest-before-ooo3.json

- `kind`: json
- `size_bytes`: 25
- `line_count`: 1
- `sha256`: 23ed3d85962bd1d785adf5f5d190eb7c304fdb2478c789b5b7584704beb9eeb6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: json evidence; size=25 bytes; lines=1; markers=<none>; tail={"manifest_absent":true}

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/static/mutations.log

- `kind`: log
- `size_bytes`: 271
- `line_count`: 1
- `sha256`: 8cc1bf552c798606e026a1135099c2c460dd2386e8720da34eb08146b46ee27d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=271 bytes; lines=1; markers=<none>; tail={"scratch": "/tmp/codex-v8v-lq-mutations-yb8jotnc", "scratch_deleted": true, "all_passed": true, "passed": 9, "total": 9, "evidence": "/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/lq-mutations/mutation-r...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/sustained.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/ooo3-current/sustained/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 305012
- `line_count`: 2288
- `sha256`: 38dccabc5ca63f7eb027a9ac1e3d83928bac02622f2dc80951059b657c9b43f3
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=305012 bytes; lines=2288; PASS=2; tail=r.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/...

### .github/task-runs/2026-08-02-rv64-v13u-ooo3-current-rebind-v1/evidence/pre-delivery-review.md

- `kind`: md
- `size_bytes`: 1916
- `line_count`: 23
- `sha256`: 7517a099237d8cf832594fd5233f14f5182aa34dd2f4cacd4c086e0eb940504f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T22:59:04+00:00
- `markers`: {"PASS": 2}
- `summary`: md evidence; size=1916 bytes; lines=23; PASS=2; tail=# V13U OOO-3 pre-delivery review ## Implementer conclusion `OooLoadQueue`/`OooStoreQueue` current-design evidence is PASS for OOO-3 only: six `OOO_ASSERT` configurations pass, 11/11 metrics pass, 9/9 LQ compile-success mutants and 18/18 F2 parent mutants ar...
