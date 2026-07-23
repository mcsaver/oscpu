# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-rv64-v8s-dual-memory-core-integration
- `task_slug`: `rv64-dual-memory-canonical-integration-revtag-v8s`
- `profile`: 
- `asset_count`: 60
- `total_size_bytes`: 458384

## 证据资产

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/architecture-manifest.post.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/architecture-manifest.pre.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/final.log

- `kind`: log
- `size_bytes`: 186
- `line_count`: 1
- `sha256`: 1cf81d50e340651fa1e916ff761393a71b39fc525021b608ad238a62df3e1c0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=186 bytes; lines=1; PASS=2; tail=[V8S-F2][PASS] run_id=v8s-f2-20260720T080613Z-1010841 claim=architecture_checkpoint profiles=6 mutations=11 predecessor=F1_PASS architecture=RED ppa=UNQUALIFIED promotion_eligible=false

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutation-summary.log

- `kind`: log
- `size_bytes`: 3899
- `line_count`: 11
- `sha256`: bf2e8ffd205415916542761abf42adc57e44233135f84f3aa0f62c0e2c809b3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3899 bytes; lines=11; PASS=22; tail=[V8S-MUTATION][PASS] run_id=v8s-f2-20260720T080613Z-1010841 name=bank1_tieoff compile_success=true elaborated=true activated=true target_rejected=true oracle=V8S bank1 valid independent of ready mutant_sha256=677683a3c2b2a263d576f2d793f549b1d603cf5905dd4c9f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/alias_miq1_completion_head.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/alias_miq1_completion_head.mutator.log

- `kind`: log
- `size_bytes`: 216
- `line_count`: 1
- `sha256`: 38d07b7fdbedd891fe80a0784f6a5a95606cbd5fd7447f59ef0b0579cfc67672
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=216 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=alias_miq1_completion_head source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/alias_miq1_completion_head/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/alias_miq1_completion_head.run.log

- `kind`: log
- `size_bytes`: 326
- `line_count`: 5
- `sha256`: 9aef91c13c92d6e081a0b5d83c96478b3a6964f6f6f8f40789e868e87c709800
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=326 bytes; lines=5; FAIL=4; tail=[CHECK-FAIL] V8S bank1 PID reaches MIQ got=0 expected=1 [CHECK-FAIL] V8S simultaneous WB1 valid got=0 expected=1 [V8S-MEM1-COMPLETION-AUTH] bank1 WB escaped exact PID/open gate @19 FATAL: /tmp/v8s-dual-memory-core.CFagIs/mutants/alias_miq1_completion_head/O...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/allow_killed_mem1_wb.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/allow_killed_mem1_wb.mutator.log

- `kind`: log
- `size_bytes`: 204
- `line_count`: 1
- `sha256`: 7176ecc8bf511efc4c16c94b8be53f2f06a1a1b1dc807ad15ad4bb9e521380c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=204 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=allow_killed_mem1_wb source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/allow_killed_mem1_wb/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/allow_killed_mem1_wb.run.log

- `kind`: log
- `size_bytes`: 993
- `line_count`: 12
- `sha256`: e53b8938ae72c2ed9041c382b6ecb9c3944b8861b61834f93c8c0badbce8e4d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"ERROR": 2, "FAIL": 4, "PASS": 10}
- `summary`: log evidence; size=993 bytes; lines=12; FAIL=4; ERROR=2; PASS=10; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/bank1_tieoff.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/bank1_tieoff.mutator.log

- `kind`: log
- `size_bytes`: 188
- `line_count`: 1
- `sha256`: df14c9c7797baf854dd55448d49f95baac2bbb488fa40ce7005945be65927406
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=188 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=bank1_tieoff source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/bank1_tieoff/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/bank1_tieoff.run.log

- `kind`: log
- `size_bytes`: 774
- `line_count`: 12
- `sha256`: ec9b83bd72daac28aef3c20e792f095b725a08cc05e645fa7cbcd7a77d1b37f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 18}
- `summary`: log evidence; size=774 bytes; lines=12; FAIL=18; tail=[CHECK-FAIL] V8S bank1 valid independent of ready got=0 expected=1 [CHECK-FAIL] V8S bank1 request fire got=0 expected=1 [CHECK-FAIL] V8S bank1 MIQ count got=0x00000000 expected=0x00000001 [CHECK-FAIL] V8S bank1 expected tuple live got=0 expected=1 [CHECK-FA...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/double_claim_wb0.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/double_claim_wb0.mutator.log

- `kind`: log
- `size_bytes`: 196
- `line_count`: 1
- `sha256`: 47860dade71db67f2f4b9f2e1a789666025d9ea67d060d22216bdf250f70dc5c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=196 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=double_claim_wb0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/double_claim_wb0/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/double_claim_wb0.run.log

- `kind`: log
- `size_bytes`: 2971
- `line_count`: 36
- `sha256`: 466648791e5948b19c4c8e5e20e06e968da213a5e01139d78e9763263bfa74c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"ERROR": 8, "FAIL": 38, "PASS": 14}
- `summary`: log evidence; size=2971 bytes; lines=36; FAIL=38; ERROR=8; PASS=14; tail=[CHECK-FAIL] V8S bank1 owns WB1 got=0 expected=1 [CHECK-FAIL] V8S simultaneous WB1 valid got=0 expected=1 [CHECK-FAIL] V8S WB1 exact ROB got=0x00000000 expected=0x00000001 [CHECK-FAIL] V8S WB1 load data got=0x0000000000000000 expected=0xaaaabbbbccccdddd ERR...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/duplicate_bridge_drop_token.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/duplicate_bridge_drop_token.mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: 2671f9897e6355f1f334d32582d728067e3a2bf5b811156febe9dad714bd9c1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=duplicate_bridge_drop_token source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/duplicate_bridge_drop_token/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/duplicate_bridge_drop_token.run.log

- `kind`: log
- `size_bytes`: 242
- `line_count`: 3
- `sha256`: 4a4c80bc3ec2f925c2afcac9822c15f1b8bcb18390acdceca7dfe54325ac7f1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=242 bytes; lines=3; markers=<none>; tail=[S2-G1-TCOLL-INGRESS-DUP] same token arrived on multiple ingress lanes FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemOwnerTerminalCollector.v:367: Time: 69 Scope: tb_ooo_int_backend.dut.u_mem_owner_terminal_collector

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/invert_same_bank_age.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/invert_same_bank_age.mutator.log

- `kind`: log
- `size_bytes`: 204
- `line_count`: 1
- `sha256`: c7acc159c4f73c9a004f21e6960c562915e680906fa723e477e86fd8472d5246
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=204 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=invert_same_bank_age source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/invert_same_bank_age/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/invert_same_bank_age.run.log

- `kind`: log
- `size_bytes`: 2203
- `line_count`: 26
- `sha256`: 6417c1e6053deaf5d87701144ae04494451b0b7521c80ffa14ab921755f009af
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 34, "PASS": 14}
- `summary`: log evidence; size=2203 bytes; lines=26; FAIL=34; PASS=14; tail=[CHECK-FAIL] V8S same-bank older selected got=0x0000000000000320 expected=0x0000000000000300 [CHECK-FAIL] V8S same-bank older consumes got=0 expected=1 [CHECK-FAIL] V8S same-bank younger held got=1 expected=0 [CHECK-FAIL] V8S same-bank older reservation dra...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/legacy_release_lookthrough.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/legacy_release_lookthrough.mutator.log

- `kind`: log
- `size_bytes`: 216
- `line_count`: 1
- `sha256`: 93681c36cb59a0e8a9dd10152c7dbc267306936400701483812652a29b7d2141
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=216 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=legacy_release_lookthrough source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/legacy_release_lookthrough/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/legacy_release_lookthrough.run.log

- `kind`: log
- `size_bytes`: 1201
- `line_count`: 13
- `sha256`: 48e14a53eb2acc61473e4a02f462fe81139c04b04d43ec55c3b236ac53fdbfb5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 8, "PASS": 14}
- `summary`: log evidence; size=1201 bytes; lines=13; FAIL=8; PASS=14; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/ordinary_store_direct_write.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/ordinary_store_direct_write.mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: 039d6ee42349a87819f9d3281ae5cde17b57424333902c04a3866d5380300bfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=ordinary_store_direct_write source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/ordinary_store_direct_write/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/ordinary_store_direct_write.run.log

- `kind`: log
- `size_bytes`: 1051
- `line_count`: 11
- `sha256`: 8e0e6f9522c5d427322d2f3bb41f1b803ee6df5a0b030bc32fb83fea973cacbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 4, "PASS": 14}
- `summary`: log evidence; size=1051 bytes; lines=11; FAIL=4; PASS=14; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [CHECK-FAIL] V8S dual-store b...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/singleton_priority_bypass.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/singleton_priority_bypass.mutator.log

- `kind`: log
- `size_bytes`: 214
- `line_count`: 1
- `sha256`: d9872afdbdb74e377e54e322544c05ac253d70cc26e1a572621bd30238681ebc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=214 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=singleton_priority_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/singleton_priority_bypass/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/singleton_priority_bypass.run.log

- `kind`: log
- `size_bytes`: 1570
- `line_count`: 17
- `sha256`: d527cc27954f17ebb4302f9b4456e5dd045485c1d510b8f400d85b5d9074cb70
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"ERROR": 2, "FAIL": 12, "PASS": 14}
- `summary`: log evidence; size=1570 bytes; lines=17; FAIL=12; ERROR=2; PASS=14; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/swap_bank_mapping.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/swap_bank_mapping.mutator.log

- `kind`: log
- `size_bytes`: 198
- `line_count`: 1
- `sha256`: a8f37775dcce1db723c1cd7ea6733c8356b19780cbdac78c0abe7cf53ab92706
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=198 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=swap_bank_mapping source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/swap_bank_mapping/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/swap_bank_mapping.run.log

- `kind`: log
- `size_bytes`: 1467
- `line_count`: 20
- `sha256`: 17463249e2b55159219d93656e99b5ebf620f78a52186271ea23a89d002606c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 34}
- `summary`: log evidence; size=1467 bytes; lines=20; FAIL=34; tail=[CHECK-FAIL] V8S bank0 captured address got=0x0000000000000208 expected=0x0000000000000200 [CHECK-FAIL] V8S bank1 captured address got=0x0000000000000200 expected=0x0000000000000208 [CHECK-FAIL] V8S bank0 PID reaches MIQ got=0 expected=1 [CHECK-FAIL] V8S ba...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/tieoff_sq_terminal1.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/tieoff_sq_terminal1.mutator.log

- `kind`: log
- `size_bytes`: 202
- `line_count`: 1
- `sha256`: 7bd18196e8c2c5709b31429344bc1e60254345f9279002a11aebaca3819b766a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=202 bytes; lines=1; PASS=2; tail=[V8S-MUTATOR][PASS] name=tieoff_sq_terminal1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8s-dual-memory-core.CFagIs/mutants/tieoff_sq_terminal1/OooIntBackend.v

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/mutations/tieoff_sq_terminal1.run.log

- `kind`: log
- `size_bytes`: 1052
- `line_count`: 11
- `sha256`: 719c5f3edb6c7a8bd6101270e8e0c211bd89d359c66083f734632f3431249c28
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"FAIL": 4, "PASS": 14}
- `summary`: log evidence; size=1052 bytes; lines=11; FAIL=4; PASS=14; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [CHECK-FAIL] V8S dual-store f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profile-summary.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 3
- `sha256`: 89072e71a58d05e9936376604555293f9be8c39dd3e29a5b9ed4d32ddc1ad93d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=480 bytes; lines=3; PASS=6; tail=[V8S-PROFILE][PASS] run_id=v8s-f2-20260720T080613Z-1010841 profile=focused-release image_sha256=f8efb011580d3dd69104e5a9973753d244345a5f89aa50b16e82620b9b7995be [V8S-PROFILE][PASS] run_id=v8s-f2-20260720T080613Z-1010841 profile=focused-assert image_sha256=b...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profiles/focused-assert.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profiles/focused-assert.run.log

- `kind`: log
- `size_bytes`: 947
- `line_count`: 9
- `sha256`: cc4f3db8af2452b093e82c287d91fcb174d5333768e6b044e9597fe85dd7132b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=947 bytes; lines=9; PASS=16; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profiles/focused-release.compile.log

- `kind`: log
- `size_bytes`: 9967
- `line_count`: 69
- `sha256`: 41fa83980d90808ef873757a24205dc777c14ccb942ad7be53c36d71a4b033c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=9967 bytes; lines=69; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profiles/focused-release.run.log

- `kind`: log
- `size_bytes`: 947
- `line_count`: 9
- `sha256`: cc4f3db8af2452b093e82c287d91fcb174d5333768e6b044e9597fe85dd7132b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=947 bytes; lines=9; PASS=16; tail=[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS [V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS [V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS [V8S-DUAL-STORE-PROBE] dual_f...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profiles/legacy-assert.compile.log

- `kind`: log
- `size_bytes`: 10778
- `line_count`: 75
- `sha256`: 049c5f4ea8e60f00807ffd9448c6023441924cb36be5ff3a8eb75e7bdd2312e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=10778 bytes; lines=75; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:517: warning: @* is sensitive to all 8 words in array 'valid_q'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/scheduling/OooIntIssueQueue.v:518: warning: @* is sensitive to all 8 words in...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/profiles/legacy-assert.run.log

- `kind`: log
- `size_bytes`: 5864
- `line_count`: 91
- `sha256`: 020ef73d5d489bacb441d8dfea1f6c3c92c8dd14a2cd7e74b147d859c54fa1d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"ERROR": 2, "PASS": 92}
- `summary`: log evidence; size=5864 bytes; lines=91; ERROR=2; PASS=92; tail=[V8K-PENDING-CSR-LEASE] raw onehot/reuse fence/public PID transport PASS [V8J-BRANCH-RESOLVE-AUTH] live/stale/mismatch/death-edge/self-kill PASS [T4H-PMA-PRECISE-STORE] cause=7 tval=0000000018000040 SQ-fill=0 drain=0 [T4N-B-ERROR-PRECISE] va=0x0000000040001...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/result.json

- `kind`: json
- `size_bytes`: 1494
- `line_count`: 45
- `sha256`: 52211bca11246abd09697884c9624fcc213b879173ba46f6dc6ece930d5eba27
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=1494 bytes; lines=45; PASS=16; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "claim": "architecture_checkpoint", "f1_permanent_target": { "canonical_stage": "F2_PROMOTED", "claim": "dual_bridge_cache_hit_leaf_ver...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/run-id.txt

- `kind`: txt
- `size_bytes`: 32
- `line_count`: 1
- `sha256`: d7118428b077bae6156470e06f4e88943c1efa7b804061d281b5d228f63cfc3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: txt evidence; size=32 bytes; lines=1; markers=<none>; tail=v8s-f2-20260720T080613Z-1010841

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 11010
- `line_count`: 76
- `sha256`: 2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=11010 bytes; lines=76; markers=<none>; tail=0d4c4f43e9b92eb02281a9261850993c90a5d602d6232536d992ca728b57969a /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/contract.md e0796def32dbca1ae1e111e0125548adc0142dbd2dacf86c653dca8fe9694eb3 /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 11010
- `line_count`: 76
- `sha256`: 2334b38fd33e69d95e7ee2dbe40264a3dfb2fec61a00c0388b4edd233e11d2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=11010 bytes; lines=76; markers=<none>; tail=0d4c4f43e9b92eb02281a9261850993c90a5d602d6232536d992ca728b57969a /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/contract.md e0796def32dbca1ae1e111e0125548adc0142dbd2dacf86c653dca8fe9694eb3 /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 53133
- `line_count`: 1219
- `sha256`: 2d3b246e3e26b44dd412dc91662b06d61acbc94699efe9474494b10c10224bb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=53133 bytes; lines=1219; PASS=16; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 401
- `line_count`: 11
- `sha256`: 74c9d15030f3523197ca2c2f629cb2ac1dbe453a59c03c01065fbefb74fd822d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=401 bytes; lines=11; markers=<none>; tail=DI-1: RED (7 red checks) DI-2: RED (18 red checks) DI-3: RED (6 red checks) DI-4: RED (3 red checks) DI-5: RED (15 red checks) OOO-1: RED (3 red checks) OOO-2: RED (3 red checks) OOO-3: RED (14 red checks) OOO-4: RED (9 red checks) OVERALL: RED RESULT: /hom...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/checker-unit.log

- `kind`: log
- `size_bytes`: 1494
- `line_count`: 18
- `sha256`: 5ca40ab9db7f533ac4b2b7dc4fd80613be9f3f61ee7c7477f5040cd8d1477920
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=1494 bytes; lines=18; markers=<none>; tail=test_bank1_tieoff_is_rejected (__main__.CheckerTests.test_bank1_tieoff_is_rejected) ... ok test_baseline_all_checks_pass (__main__.CheckerTests.test_baseline_all_checks_pass) ... ok test_canonical_disable_is_rejected (__main__.CheckerTests.test_canonical_di...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/contract.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 9
- `sha256`: 05fc03d33f473d4641209f6079f5cd59ad3df42eb9bfc022239d906af463e14b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=9; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 9 tests in 2.945s OK [PRODUCER-HOLDER-CENSUS] PASS direct=16 packed=5 token_q=13 generation=1 契约立即断言（$error）计数：当前=4...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/f1-handoff.json

- `kind`: json
- `size_bytes`: 398
- `line_count`: 14
- `sha256`: 5add474d71ca50aa894868407bc33d4d912c1ae769918ae2e7ce2570166ba750
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=398 bytes; lines=14; PASS=2; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_core_integration": true, "canonical_stage": "F2_PROMOTED", "claim": "dual_bridge_cache_hit_leaf_verified", "ppa": "UNQUALIFIED", "run_id": "v8r-f1-20260720T080639Z-1012033", "...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/f1-permanent-target.log

- `kind`: log
- `size_bytes`: 335
- `line_count`: 3
- `sha256`: f024d3ff23613a868a1eba8e6106128753c1dec98314ac33b3651f256b5be627
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=335 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8R-F1][PASS] run_id=v8r-f1-20260720T080639Z-1012033 claim=dual_bridge_cache_hit_leaf_verified mutations=10 architecture=RED ppa=UNQUALIFIED canonical_stage=F2_PROMOTED canonical_core_integ...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/npc-core-assert-lint.log

- `kind`: log
- `size_bytes`: 64848
- `line_count`: 718
- `sha256`: 84d16e6572b0b8844c726daa19551fdfee3292b8cd80c2f764aba2e1ff6ba8fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=64848 bytes; lines=718; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +def...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/npc-core-release-lint.log

- `kind`: log
- `size_bytes`: 63286
- `line_count`: 702
- `sha256`: 7052730d5a8b83379e05d2674eaaf46118f707830d176c99b01d8ab786412f9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=63286 bytes; lines=702; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include --to...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/npc-sim-assert-stats-lint.log

- `kind`: log
- `size_bytes`: 65020
- `line_count`: 718
- `sha256`: 9ae54bc09ec024222bed998279851479b30b0e37927584e2cb3de78054c009b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: log evidence; size=65020 bytes; lines=718; markers=<none>; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +def...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/rtl-style.log

- `kind`: log
- `size_bytes`: 232
- `line_count`: 3
- `sha256`: 96c33fde944e1dfe18479810ebbb194ce79d090de0454e240cebdb1f88732078
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=232 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/source-checks.json

- `kind`: json
- `size_bytes`: 3690
- `line_count`: 91
- `sha256`: caaddd49634b41f2166f5bce120d30955c0230cfbd565f0ee74b90284d00b03f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {}
- `summary`: json evidence; size=3690 bytes; lines=91; markers=<none>; tail={ "checks": [ { "check_id": "hierarchy.default_off_reusable_chain", "detail": "counts={'backend': 1, 'decode': 1, 'slice': 1, 'execute': 1, 'glue': 1}", "passed": true }, { "check_id": "hierarchy.explicit_parameter_handoff", "detail": "counts={'decode': 1,...

### .github/task-runs/2026-07-20-rv64-v8s-dual-memory-core-integration/evidence/focused/static/source-checks.log

- `kind`: log
- `size_bytes`: 2730
- `line_count`: 18
- `sha256`: 69b32c26626f7b88784fe2b464eac3062a5f9ca293e385334004b5aef85c4f99
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T08:16:07+00:00
- `markers`: {"PASS": 36}
- `summary`: log evidence; size=2730 bytes; lines=18; PASS=36; tail=[V8S-CHECK][PASS] hierarchy.default_off_reusable_chain: counts={'backend': 1, 'decode': 1, 'slice': 1, 'execute': 1, 'glue': 1} [V8S-CHECK][PASS] hierarchy.explicit_parameter_handoff: counts={'decode': 1, 'slice': 1, 'execute': 1, 'glue': 1} [V8S-CHECK][PAS...
