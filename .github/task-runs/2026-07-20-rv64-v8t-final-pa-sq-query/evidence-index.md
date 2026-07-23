# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-rv64-v8t-final-pa-sq-query
- `task_slug`: `rv64-v8t-final-pa-sq-query`
- `profile`: 
- `asset_count`: 558
- `total_size_bytes`: 4547918

## 证据资产

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/architecture-manifest.post.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/architecture-manifest.pre.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/checkpoint-final.log

- `kind`: log
- `size_bytes`: 320
- `line_count`: 1
- `sha256`: 7154b6ddf886bc8952eaa0c334fd6c31d7e71282556c8983b2e4d2aba7276254
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=320 bytes; lines=1; PASS=6; tail=[V8T-F3-CHECKPOINT][PASS] run_id=v8t-f3-20260720T133351Z-1183319 claim=final_pa_sq_ordering_checkpoint coverage=contract_p0_closure profiles=11 mutations=38 dynamic_rejections=37 retry_proof=PASS predecessors=F0/F1/F2_PASS architecture=RED ppa=UNQUALIFIED c...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/checkpoint-result.json

- `kind`: json
- `size_bytes`: 21887
- `line_count`: 523
- `sha256`: 69133fbe3624aad6d0bc013dafeddf8705b65ff70548954d325845e240b72296
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 24}
- `summary`: json evidence; size=21887 bytes; lines=523; PASS=24; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "checkpoint_eligible": true, "claim": "final_pa_sq_ordering_checkpoint", "coverage_mode": "contract_p0_closure", "full_contract_mutatio...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/commands.log

- `kind`: log
- `size_bytes`: 1294
- `line_count`: 24
- `sha256`: 50bddc2dfe8bba564fef69f9022174d48aacb5845dc06b370a356fcb0f3ff1fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=1294 bytes; lines=24; markers=<none>; tail=python3 checker unit tests python3 mutator anchor unit tests python3 retry-holder proof binding unit tests python3 checkpoint finalizer unit tests python3 retry-holder exhaustive proof python3 baseline source checker make check-rtl-style make check-contract...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/final.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 1
- `sha256`: 770f50cc7468464f41e8125207de6992e503ebad0c2cdff18416b4ac96509392
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=1; PASS=4; tail=[V8T-F3-RUNNER][PASS] run_id=v8t-f3-20260720T133351Z-1183319 claim=final_pa_sq_ordering_candidate coverage=contract_p0_implementation_closure profiles=11 mutations=38 dynamic_rejections=37 retry_proof=PASS predecessors=F0/F1/F2_PASS architecture=RED ppa=UNQ...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutation-summary.tsv

- `kind`: tsv
- `size_bytes`: 8306
- `line_count`: 38
- `sha256`: 71c3b1812387bf8f8be68a572b9cb491177c00d66105d5ca02a8175466399af6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: tsv evidence; size=8306 bytes; lines=38; markers=<none>; tail=sq_compare_va|sq|sq.final_physical_byte_compare_only|target_rejected|a8f9f2f7b7e6d16b60900f090fb0e409250674f9f0ae3dc095a2c2cef2c3bbea|f2cf4cd0203e338266d8f0fa090170f3800eea677bc6dda91e1919f2fc26b63d|2 sq_partial_allow|sq|sq.fail_closed_youngest_merge_semant...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_dtlb_fault_query/activation.json

- `kind`: json
- `size_bytes`: 158
- `line_count`: 9
- `sha256`: d9be54f59a6e78620e7dcd7b35843f37a31d03fd4df0f92743df9c7cdae7f351
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=158 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_dtlb_fault_query", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_dtlb_fault_query/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70418
- `line_count`: 532
- `sha256`: 7c48a57637835b70b0d9d365391fe12b6d812c2797bfed6e86401e96297a8799
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: log evidence; size=70418 bytes; lines=532; FAIL=4; PASS=3; tail=_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'e...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_dtlb_fault_query/make.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 3
- `sha256`: 17c84a4be65d3b05ac3533cf81831a4b6abffee59d80013f0e6db9abd63505ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/logs/tb_ooo_mem_axi_bri...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_dtlb_fault_query/mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: 6bd8ed164c2fefa2ccff77d5dc6b93d31d453d82d76cc4bddbb51653420260d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_dtlb_fault_query source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_dtlb_fault_query/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_dtlb_fault_query/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 83af78cbcd14f1abdc64cab4f1ff5acae345de3c42320620e5a7d1e7c96f3f8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_dtlb_fault_query/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 588f0208f7f152ea271996fa84e55cef38cedd144e97d0150dfd06613d1db024
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_forward_lookup/activation.json

- `kind`: json
- `size_bytes`: 156
- `line_count`: 9
- `sha256`: 0a70e670bd85f9ef1c8b609676bb2a15874ed1c8fd19fac733737624a635792e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=156 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_forward_lookup", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_forward_lookup/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70099
- `line_count`: 529
- `sha256`: 68eb3af5289900c60cd5115d8443c90205dc5a54f17c501d397fe394271321bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: log evidence; size=70099 bytes; lines=529; FAIL=4; PASS=2; tail=is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: war...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_forward_lookup/make.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 3
- `sha256`: e109f768c8177596fe878623b09cbc830d5b0b648c91fdc3673f279c39c5a302
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=345 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/logs/tb_ooo_mem_axi_bridg...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_forward_lookup/mutator.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 1
- `sha256`: 783d6441223fceec78882a3302a1f8f4eed5028834b21e8ff2774cc56e694c9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=222 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_forward_lookup source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_forward_lookup/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_forward_lookup/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: d82b5b45adb3a7ae4e2def3df02b9056ddbe22678b8f213c88884c490a473dad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_forward_lookup/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 44522a3f7fd1356caf27ca96074a8f4a157b8795247d1268d096a0f771d38d72
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_hold_replay/activation.json

- `kind`: json
- `size_bytes`: 153
- `line_count`: 9
- `sha256`: b9644a469495ebdc1ffa3c70d9235181e0d7688d60425b022a8a36028e4cf7ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=153 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_hold_replay", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_hold_replay/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70084
- `line_count`: 529
- `sha256`: f5e3e42827d1f88fd03cb8fb465802cb6292fb6d0c1b2fb800915aed7c97f388
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: log evidence; size=70084 bytes; lines=529; FAIL=4; PASS=2; tail=ning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_hold_replay/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: c1a18b1efe7bf5d4e24e69cb68a8d6868556110c6a4a445d8e12e8c307fa8bcc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/logs/tb_ooo_mem_axi_bridge.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_hold_replay/mutator.log

- `kind`: log
- `size_bytes`: 216
- `line_count`: 1
- `sha256`: a8cb317b7675aa5ea206797b94517d6515348de8659310d2d3b9269e6be19882
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=216 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_hold_replay source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_hold_replay/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_hold_replay/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 24e0ff4d730fe6a1cfed8121a25df413874bde2710df0c161e479c837839073f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_hold_replay/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 6c8bc2ed05966b138ac053d2c09c4ea5b4bcda1f58c817799ccf94bb9e8c864f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_late_ad_dtlb_fill/activation.json

- `kind`: json
- `size_bytes`: 159
- `line_count`: 9
- `sha256`: 8bc8ee2dd68cddb724b5a5449f9cea42578b34af5c3990838528eaa9573d4cc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=159 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_late_ad_dtlb_fill", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_late_ad_dtlb_fill/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71665
- `line_count`: 552
- `sha256`: bfee9ca53b7d51476fccadc50518880c9c2cdd2d0bea012a531e4f37f43063ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 3, "PASS": 17}
- `summary`: log evidence; size=71665 bytes; lines=552; FAIL=3; PASS=17; tail=mory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_late_ad_dtlb_fill/make.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 3
- `sha256`: 36358a3bb1deb309e088bb45e6de336b623a82bbbbe9d3ae20a544e724bbf9f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=348 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/logs/tb_ooo_mem_axi_br...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_late_ad_dtlb_fill/mutator.log

- `kind`: log
- `size_bytes`: 228
- `line_count`: 1
- `sha256`: 56d9a120decbe3240e82d738543446b2ce7af934ea2f67f46faa2e9983284a06
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=228 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_late_ad_dtlb_fill source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_late_ad_dtlb_fill/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_late_ad_dtlb_fill/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 3012e188eefa0336adc97e95413ef161d4a79deb06d23c4b7719fa7a02d81f42
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_late_ad_dtlb_fill/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 8ef521e1af6b80f8631cc411e9d54567fd606f335d1522cd99e20b4b8bb2f5cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_pmp_fault_query/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: 479898a3c839212e8641aaf94c63b3ab65707853ac33bc6f8a94aeb89fcd7550
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_pmp_fault_query", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_pmp_fault_query/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70335
- `line_count`: 531
- `sha256`: 16aba704f265c5845e8e5e3f39dd447de9e1a48a17de1c7a2686a9dcf2aa8413
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: log evidence; size=70335 bytes; lines=531; FAIL=4; PASS=3; tail=y/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_pmp_fault_query/make.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 3
- `sha256`: 2ed0de97d117cf5c75fbfc7a6a1cd8b124b73901f3010fa5c32c55ed55456472
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=346 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/logs/tb_ooo_mem_axi_brid...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_pmp_fault_query/mutator.log

- `kind`: log
- `size_bytes`: 224
- `line_count`: 1
- `sha256`: 5dbd679c715e83e54c36791215dc69b55848038826d3b17613c696d64591d9f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=224 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_pmp_fault_query source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_pmp_fault_query/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_pmp_fault_query/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 30351ee592d85b547555c6eb28b045f0e01c1a93e7aa6555a562c0969cb18ed2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_pmp_fault_query/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 06dd0c0a9cbd515ad6e9ccdb72b350d4a2f48152efa99c795965814d0134aee4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_release_without_credit/activation.json

- `kind`: json
- `size_bytes`: 164
- `line_count`: 9
- `sha256`: 2df64821c6d72fc4fca728ccf264c4272d1fd86bcc1596d94b598e2d34484b05
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=164 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_release_without_credit", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_release_without_credit/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70127
- `line_count`: 529
- `sha256`: 3da57b0ba11c7895fa6a434c43d8c9134d61d5531de9307b43c9ba829bb2e495
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: log evidence; size=70127 bytes; lines=529; FAIL=4; PASS=2; tail=to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is s...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_release_without_credit/make.log

- `kind`: log
- `size_bytes`: 353
- `line_count`: 3
- `sha256`: d4cabee1905a9ba31a46e44ea4e34a8eea1de9fc96d2a2cec146c2cc221e45a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=353 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/logs/tb_ooo_mem_a...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_release_without_credit/mutator.log

- `kind`: log
- `size_bytes`: 238
- `line_count`: 1
- `sha256`: fac16ef8703b13a28a4a7ebec20e470994b184cb2df902c2317c3bff8cd9e0fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=238 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_release_without_credit source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_release_without_credit/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_release_without_credit/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8bd5235ca5fd8a10bf1026d3aec02f0b630a3e7ec674e5ee1c9f9e35ff22d707
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_release_without_credit/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 0ef1add9a4acfa622905e1247cde5fa6f201bc445a9655ef20cde95344409c6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ad_bypass/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: 52dcb40b8cff003e7ee9bbbe18abfb015c7ec7fa60ee1faa2e14080a8b834882
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_route_ad_bypass", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ad_bypass/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71698
- `line_count`: 555
- `sha256`: 557dc76f5660b5ceb813fd3e83dbd997dda11d8798bb42a6f626760c20638eb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 5, "PASS": 18}
- `summary`: log evidence; size=71698 bytes; lines=555; FAIL=5; PASS=18; tail=sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ad_bypass/make.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 3
- `sha256`: 7fac387a7b3ea2b462d6b0184ab5144f3c754cd80116404bbbaf606a6e897f2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=346 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/logs/tb_ooo_mem_axi_brid...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ad_bypass/mutator.log

- `kind`: log
- `size_bytes`: 224
- `line_count`: 1
- `sha256`: 5c29a40b8e9b1ba9dd3a0197211cb409e08d164f21e081cc0109ba83c1681a76
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=224 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_route_ad_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_route_ad_bypass/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ad_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 0074c9d3946a4ddceca1229fac1fff066980f79617cf54e7b9c05f95f67b6ba8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ad_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 07095a87a854bb981ef607f3a8512d100bddc18792a2e6ebaec372dd1ebefd25
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_bare_bypass/activation.json

- `kind`: json
- `size_bytes`: 159
- `line_count`: 9
- `sha256`: e2cd7ab38beaa610666fcc94a1f37430bade164f18f57e15fb7a19955d8671d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=159 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_route_bare_bypass", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_bare_bypass/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 96225
- `line_count`: 906
- `sha256`: 0a111924c0408b39915afec8a9fc8bb7699ab0eb7958baae8c8c1499535ced6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 356, "PASS": 18}
- `summary`: log evidence; size=96225 bytes; lines=906; FAIL=356; PASS=18; tail=-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_bare_bypass/make.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 3
- `sha256`: 7ad1a03574210f17a5009815f79984d9f50fe5fe197b104a3e79b650df633fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=348 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/logs/tb_ooo_mem_axi_br...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_bare_bypass/mutator.log

- `kind`: log
- `size_bytes`: 228
- `line_count`: 1
- `sha256`: b640003532ec32f6b187df4441d32ef799850546afa77afe51117ebd96b6dda2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=228 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_route_bare_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_route_bare_bypass/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_bare_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 2a578a5a37739964147dd4c8101287307996180689a9f250ddc35cb09adfca63
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_bare_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 79e2c35d105c56ceb2b7d6bd51c77de4d5e0f97322acaba831b804aedec0e771
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ptw_bypass/activation.json

- `kind`: json
- `size_bytes`: 158
- `line_count`: 9
- `sha256`: d6f0e7bc038e53545336271a66e37e7cbd2cb3f8730608a8ddfaba66c4524d0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=158 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_route_ptw_bypass", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ptw_bypass/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 88888
- `line_count`: 803
- `sha256`: 694f34bb6405f13219d8aac0b79daa19815dc0f68e1d5c279172ef4b9ed3b046
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 253, "PASS": 18}
- `summary`: log evidence; size=88888 bytes; lines=803; FAIL=253; PASS=18; tail=_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in arra...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ptw_bypass/make.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 3
- `sha256`: 45874225f8c4ad987817b7c18f875649dbdd6515b66e2c5b96dbe740ec3434a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/logs/tb_ooo_mem_axi_bri...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ptw_bypass/mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: c6b252290a852a9cf5d732b3c7f5b25d055fa6812d5e81bc27ff2a1d237f97e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_route_ptw_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_route_ptw_bypass/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ptw_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: af195ae00065a9e0d243e61eff619897a07acbdd9465df042f37aa7124ff6857
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/bridge_route_ptw_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 9362e1e1e27c2d8873b66337bd5d3b1bf50da71f8e915b0d9f32abd3a2fb0aa2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/cross_bank_query_pid/activation.json

- `kind`: json
- `size_bytes`: 153
- `line_count`: 9
- `sha256`: 09635bfda626806f898cb9fa6d3f8ca374753dd7771cc83ebee95cbad206c484
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=153 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "cross_bank_query_pid", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/cross_bank_query_pid/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18115
- `line_count`: 121
- `sha256`: 1d284733e0fd6d4267ee9e72a7b5cf210c9956da7c8a22caf74f19c4db25cff3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 14}
- `summary`: log evidence; size=18115 bytes; lines=121; FAIL=10; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/cross_bank_query_pid/tb_ooo_int_backend.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/cross_bank_query_pid/make.log

- `kind`: log
- `size_bytes`: 341
- `line_count`: 3
- `sha256`: 6e867979ecda3581bb5ed77eee187347cb69c3af6ee3bd26030625d4e94ec45a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=341 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/logs/tb_ooo_int_backend.lo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/cross_bank_query_pid/mutator.log

- `kind`: log
- `size_bytes`: 217
- `line_count`: 1
- `sha256`: a89c88662c559df01ee48cfe448ca0c662e2c385a046cd5906a267275b5a359c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=217 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=cross_bank_query_pid source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/cross_bank_query_pid/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/cross_bank_query_pid/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8e022c33c27710cebd81c13a91c8966d8977f23c11eac15e5d5d6c277f5eaa7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/cross_bank_query_pid/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 5ba60ec5de1acb5934913e753e5f7ac8cec75920d95edf7363d88aae665f0225
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/dual_slot_valid_bypass/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: bad000f2acbc09718b1bcd280c3bd1469af3f88170a688c6d97fb93fb0a27cd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "dual_slot_valid_bypass", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/dual_slot_valid_bypass/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18573
- `line_count`: 125
- `sha256`: 5bee4e35401f941749d1b1bef53cbe275e681c0c74262526ae340703e984d7fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 14, "PASS": 18}
- `summary`: log evidence; size=18573 bytes; lines=125; FAIL=14; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/dual_slot_valid_bypass/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/dual_slot_valid_bypass/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: 10c4a35d951f190793698ae69ce12c528339376f50c221b9cfcf14932643951c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/dual_slot_valid_bypass/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: 4f8da6bf85035eba567aa2bbdd1b9a8ee9a30ad54d46c001de24288466bbcf9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=dual_slot_valid_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/dual_slot_valid_bypass/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/dual_slot_valid_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8ccef3ba91fb6dc11e0137a403f79f39faa54f4398dab95e0769b6505603214c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/dual_slot_valid_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 14464c2466e46cdb1b979d607d282dd6bedf8e98925b92bbcd28f6c35c54f286
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/legacy_all_load_block/activation.json

- `kind`: json
- `size_bytes`: 154
- `line_count`: 9
- `sha256`: f0b15ad4fc3a4088be549f3250dce7a7f84c3d158aa474492ab72f747dba22ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=154 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "legacy_all_load_block", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/legacy_all_load_block/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18318
- `line_count`: 124
- `sha256`: cb2d24397c3ce1922edd8b4f56671dab9c619c44f42815ba05c79604b99990e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 16, "PASS": 14}
- `summary`: log evidence; size=18318 bytes; lines=124; FAIL=16; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/legacy_all_load_block/tb_ooo_int_backend.vvp /home...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/legacy_all_load_block/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: 014fc0f4b929f578a0940bb0e6e88a0811157b8c3af3c156ab97b80a51b67531
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/logs/tb_ooo_int_backend.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/legacy_all_load_block/mutator.log

- `kind`: log
- `size_bytes`: 219
- `line_count`: 1
- `sha256`: e5b5937a23e0f75db968edabfdb13ba7af95f88ff8e11482213d0a84b17e8a15
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=219 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=legacy_all_load_block source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/legacy_all_load_block/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/legacy_all_load_block/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: cc0427973e7f61d4cc04266f10abea5f24db3524cb5efbe686e22f9f5edf6496
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/legacy_all_load_block/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 95d7257a8db830f3d8cc14dec3501f646b716e14630b0cf99c70d0643bf8f182
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_active_fence_delete1/activation.json

- `kind`: json
- `size_bytes`: 159
- `line_count`: 9
- `sha256`: d564e06f9743f610c0a847ff03e1cd0c9b0f681caeff3d373f2656610bcdf507
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=159 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_active_fence_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_active_fence_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18372
- `line_count`: 122
- `sha256`: b01d428d366770321c5ee04ed13b45d4c2611573d66cc5113d506308ee951fe1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18372 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_active_fence_delete1/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_active_fence_delete1/make.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 3
- `sha256`: 864b9a074886112d43d04f2ebb622772d6ef417c452692e4d811e9719ad4fc6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/logs/tb_ooo_int_back...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_active_fence_delete1/mutator.log

- `kind`: log
- `size_bytes`: 229
- `line_count`: 1
- `sha256`: c53bcdc579cb5f3376187bc42386156e18557b9629f7014de4bf4530b2c90ea1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=229 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_active_fence_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_active_fence_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_active_fence_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 68cd304fe9d21101e3159039eff645a9d7b355ef5a1a9318e1a6eee02c92ca1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_active_fence_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 3b1d9c4aa9f8022384c8f7bf5259dd094c6257377ef20d583338dd681203f7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_cancel_priority_delete1/activation.json

- `kind`: json
- `size_bytes`: 162
- `line_count`: 9
- `sha256`: 326e92b7dc0fa00618e8e80611f352ca5691415f267530fc0edd36e32d99ab6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=162 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_cancel_priority_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_cancel_priority_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18363
- `line_count`: 122
- `sha256`: 1411758e42e80a4f3810835ac68b8b80d21d95b2fc93790f178f55a810fd5801
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18363 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_cancel_priority_delete1/tb_ooo_int_backend.v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_cancel_priority_delete1/make.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 3
- `sha256`: 09ab68ebc84eb635f6b404cdc0a9aa530bc84a9f3ae632b354baf7043d1da84a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/logs/tb_ooo_int_b...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_cancel_priority_delete1/mutator.log

- `kind`: log
- `size_bytes`: 235
- `line_count`: 1
- `sha256`: 6cdaacbb9ca02b573c5a2647b2778841a1308728139dd8eaa09da6e0bc05d1e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=235 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_cancel_priority_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_cancel_priority_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_cancel_priority_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: aea9c104ef02240f9ae13cd307303b45285af819f12cfd964d4b2697d705ed1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_cancel_priority_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 282531f99e9169463121811d9c2d1c8f3d6dbf2b1d8f4cbb097361f8d1e25acb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_capture_drop1/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: 9c615b9e920668ac18eec24f260541123545a2d11dc7c5478494daacab37baad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_fp_capture_drop1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_capture_drop1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18816
- `line_count`: 128
- `sha256`: 45b745086eaba9a5b44ecaf0ceeac0f268ef639b02fde44f86de1e27ca3b9583
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 20, "PASS": 18}
- `summary`: log evidence; size=18816 bytes; lines=128; FAIL=20; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_fp_capture_drop1/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_capture_drop1/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: 263adeb5fc70c32f0521b0bf10671ab0f43d1f6c440c95ea1be0fd82ac2d5f73
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_capture_drop1/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: 70ff6b9af4ec825e2211403da82bc05584e6c2e848f05e45fbb68c6d6f4c7ac6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_fp_capture_drop1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_fp_capture_drop1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_capture_drop1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 6e0c60d5f76126d7d085e36b8cb90b30f83a189ee2b9a863f7c70eb4fcc8c1a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_capture_drop1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 03547ec91df5c8d6e361ef209bae8dea5b423a545a800d98c1261b58e6a4f47a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_repush_drop1/activation.json

- `kind`: json
- `size_bytes`: 154
- `line_count`: 9
- `sha256`: 0439da9ec97e968254b94ae3d96ae71022be63c06cd596348535f9a2813743d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=154 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_fp_repush_drop1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_repush_drop1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18662
- `line_count`: 126
- `sha256`: 0b5a5735c704d9b451184524e493da6fce3d1e42ecdd7d74b1beb49f388ec5bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 16, "PASS": 18}
- `summary`: log evidence; size=18662 bytes; lines=126; FAIL=16; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_fp_repush_drop1/tb_ooo_int_backend.vvp /home...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_repush_drop1/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: 4c8e170231ed429223bf0fc4597d5094a0b7c5f7948f965b2344e8e30aef6fe2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/logs/tb_ooo_int_backend.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_repush_drop1/mutator.log

- `kind`: log
- `size_bytes`: 219
- `line_count`: 1
- `sha256`: 3fde0ab66fc1c09f7c7e93bb2994c89dd9d983b9376ff865bc2e8ab69b26d468
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=219 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_fp_repush_drop1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_fp_repush_drop1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_repush_drop1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: af070598f91cd8a58ef6fca8415b3bad24e940af2f7c8695f3d55649319d5c85
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_fp_repush_drop1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 81ace9a3cc963253cc1ec99cbd1349ff74a9b7883581ff85f5627deb8a8ba18c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete0/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: 3847d171340c0c7ac9bf3802c62f4777d447036fbaa4ba40f35a3ac375205afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_load_fence_delete0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18443
- `line_count`: 123
- `sha256`: 6c271507e7af1f2aa460d51f186d446cf6b2541c3427edba0a19a7923ffa42d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 18}
- `summary`: log evidence; size=18443 bytes; lines=123; FAIL=10; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_load_fence_delete0/tb_ooo_int_backend.vvp /h...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete0/make.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 3
- `sha256`: ee6b5c325c0ed23081b338666ebfa8c4ac2ecd8b455c4782b8cd33e04cef88dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=345 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/logs/tb_ooo_int_backen...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete0/mutator.log

- `kind`: log
- `size_bytes`: 225
- `line_count`: 1
- `sha256`: 1c7820c0cf33b62070b885f4b7db443eb4cb242922e37d9c966a56d2c790c5f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=225 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_load_fence_delete0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_load_fence_delete0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 6f0ba8a6ca5e1ecdb274a9531cac471aa7926266e8d65b7e6968a63fbbf80da0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 203bc7f64f9fd6111fb69044e4b11cb35ce9f1d184ad1bee65420030a6835e31
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete1/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: e05a1072d394c14d573123849899ca1158982f0f525062ef5fa1289c6410f797
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_load_fence_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18368
- `line_count`: 122
- `sha256`: 4f3575ce8334db7f01ef4c85e08c83ae2a5b5d764324892c8f4bcf5af383783d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18368 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_load_fence_delete1/tb_ooo_int_backend.vvp /h...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete1/make.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 3
- `sha256`: dc967838bb57474d2407a41cbf693a981bed6ee76c07c93c7b9d8a85398f7d39
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=345 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/logs/tb_ooo_int_backen...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete1/mutator.log

- `kind`: log
- `size_bytes`: 225
- `line_count`: 1
- `sha256`: dad34e8fd47cd293547e96b64cadc8484e325def045e29edf5f53ad680445909
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=225 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_load_fence_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_load_fence_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 68cd304fe9d21101e3159039eff645a9d7b355ef5a1a9318e1a6eee02c92ca1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_load_fence_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 3b1d9c4aa9f8022384c8f7bf5259dd094c6257377ef20d583338dd681203f7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop0/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: 3e692270df8f795bb1354ac507d4164286be6346b38d1326341835f737de650d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_no_pop0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 17996
- `line_count`: 119
- `sha256`: bf590bcc5efa582dbd1316b73874538b1b6a899fd859068bee3b14a1b63d1bf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=17996 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_no_pop0/tb_ooo_int_backend.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop0/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: bbb491dd27610f8e33919192bfe235272a97b4a63f7bb6578d88527d9a7a3d20
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/logs/tb_ooo_int_backend.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop0/mutator.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: f23b8a100e7c7f13e2b4c3371fc4d82f882fe49705190e04a022b76f1f98dc75
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=203 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_no_pop0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_no_pop0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop0/source-checks.json

- `kind`: json
- `size_bytes`: 5297
- `line_count`: 137
- `sha256`: 09e303723ff833fa9f9bcb49174fb44d1f25dac5c3c22b1e490a5d7630e4f595
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5297 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop0/source-checks.log

- `kind`: log
- `size_bytes`: 3757
- `line_count`: 29
- `sha256`: 4e5317e7485cf67e0c26ad670d45386b014285657f7fa608564804bfdc67c180
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3757 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop1/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: 1f62bd21f000e04647a9baedb75cabf3d1596185f02ed70ac4f8bb400817af59
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_no_pop1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 17996
- `line_count`: 119
- `sha256`: 917e0cc054b40b6609cca16e76768a75ff7e67a70f07605c2940558e197f96a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=17996 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_no_pop1/tb_ooo_int_backend.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop1/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: feaa82b42627b10959f769fa173493ae9b128da75ec9c141da651b300ff6b944
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/logs/tb_ooo_int_backend.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop1/mutator.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: 27108e443663e65dca211a1ffd244eb49f40122089ea53de6d081a4b8c83c875
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=203 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_no_pop1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_no_pop1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop1/source-checks.json

- `kind`: json
- `size_bytes`: 5299
- `line_count`: 137
- `sha256`: f1cd26386df7f7c6fb9bddc2a1605783335f0d902fac23f82f7e96f7fbf53ffe
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5299 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_no_pop1/source-checks.log

- `kind`: log
- `size_bytes`: 3759
- `line_count`: 29
- `sha256`: 155ae3bd4bf35011d37309271851de3a509def9c88bb9db73ea9d2a8d43c10d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3759 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert0/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: e528ea163dd135367ab52fcd6d983e2d1fd322f5d36b172cecc33e6870db0382
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_priority_invert0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18724
- `line_count`: 129
- `sha256`: efe844a376d954958c67c78d00ee25a91c8e1ed7ee54c94ef098aee4a76af96b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 26, "PASS": 14}
- `summary`: log evidence; size=18724 bytes; lines=129; FAIL=26; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_priority_invert0/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert0/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: c701574643c547a81d40243b9347a91ac9af082dc5eded839e7680d48da78b2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert0/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: 9b2f3e4e6c24abf5c5906803884555cb4bf32a3555e01a8a3b1481d1339d3fa6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_priority_invert0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_priority_invert0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 52b1076c2fe01631c5a6531071581099f75cd0b3645255a5c77f958dff062353
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: ea75dee9fa62f9c9726e4d4ebeb39fb56d08fb5e378ba29cbbea7e7d05b0f18e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert1/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: abd58f744699b7d96a99c14fa640730db68958ea3bdd11e868715e1cf1e05c68
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_priority_invert1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 19238
- `line_count`: 137
- `sha256`: cb44aebb623c36a10bcff4c063046996c02565212078de8d260854a12e64ab27
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 42, "PASS": 14}
- `summary`: log evidence; size=19238 bytes; lines=137; FAIL=42; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_priority_invert1/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert1/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: aa7a4d1a8f26147e4612efeba1a4e7a19fb55f683571db42b08fd6aa75f5d948
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert1/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: b88f93ed52d8c78b7b85105fd58cd867bb5bd93707f80bda8679342e5acb4130
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_priority_invert1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_priority_invert1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 2605b7dc866c9fe7d1610fba6dfc1e51c1973c06b2bff241e1342c7ea121656c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_priority_invert1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: bf14c008c3ce7a9787e3434683f785bbbdf199c1dca271cab511e8584091f617
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill0/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 3b2f1c1ffc64f467acdf6a9e7c5755f93ce56daf7d82352415cab4c591391d44
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_silent_kill0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18493
- `line_count`: 124
- `sha256`: eb9f034cd0b45492c28a21feed1655583da6f85bc9c5afae526afce3cde251c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 12, "PASS": 18}
- `summary`: log evidence; size=18493 bytes; lines=124; FAIL=12; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_silent_kill0/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill0/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 415935ee141cc9a84a1901535257505c5e64202bd073b32fb413486fbce13df8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill0/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: 0f0a51839525d244c12617bdbcda37c389de160b90a37bf95cae4b0e63ec51eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_silent_kill0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_silent_kill0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill0/source-checks.json

- `kind`: json
- `size_bytes`: 5275
- `line_count`: 137
- `sha256`: ce1fd063cf4bb43b43c9f4d0467f099d97cef1e19783ba7b16aa0eb35254e4a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5275 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill0/source-checks.log

- `kind`: log
- `size_bytes`: 3736
- `line_count`: 29
- `sha256`: a7b10ae746039af9cc98203d62544f50b4a155ce4f0d7d9d69ae79f7576cfb3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3736 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill1/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 32c91a16ac689eafd9f0698ca0cf6809bbb5537d39c18423a7e99b2181a85262
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_silent_kill1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18490
- `line_count`: 124
- `sha256`: 354073bd74815255a7121891b05bf2db40dfd133e984633da3986dd647248f1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 12, "PASS": 18}
- `summary`: log evidence; size=18490 bytes; lines=124; FAIL=12; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_silent_kill1/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill1/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 652bc6dffc52db5e7c8937b8c6b1eb5cf360c77ad26e25357c6d9a113d6786ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill1/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: d9cb5ecc1dda10aa37ec4cdf97e42cfd189832e0d1395efcc98636cc4b1545d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_silent_kill1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_silent_kill1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill1/source-checks.json

- `kind`: json
- `size_bytes`: 5275
- `line_count`: 137
- `sha256`: fb26be743800868a443857b2cdc5970559826de379e339c57fe52b6600633f7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5275 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_silent_kill1/source-checks.log

- `kind`: log
- `size_bytes`: 3736
- `line_count`: 29
- `sha256`: c07d9d145ddd121b206706266c59d8c464226c8cc5067eae4831eb4483f2acd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3736 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_station_fence_delete1/activation.json

- `kind`: json
- `size_bytes`: 160
- `line_count`: 9
- `sha256`: 5893693a48d8b4da7f2e66422f7d6a92a444bf38c74b56d738e6fab51a71491e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=160 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_station_fence_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_station_fence_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18375
- `line_count`: 122
- `sha256`: 64b8512b8bf825f9620c69ad96166efce1cfae6cb5e1c9fe7b2d2eeacdbcd660
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18375 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_station_fence_delete1/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_station_fence_delete1/make.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 3
- `sha256`: fd60fd9612d93c23aa8850762bd61175236a9139402d21a6f1e2457286bb0dbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=348 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/logs/tb_ooo_int_bac...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_station_fence_delete1/mutator.log

- `kind`: log
- `size_bytes`: 231
- `line_count`: 1
- `sha256`: 6d7ea9ac5033ef67556d093ce5a63b5af3f8ef58be979397119231065e4ebe13
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=231 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_station_fence_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_station_fence_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_station_fence_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 68cd304fe9d21101e3159039eff645a9d7b355ef5a1a9318e1a6eee02c92ca1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_station_fence_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 3b1d9c4aa9f8022384c8f7bf5259dd094c6257377ef20d583338dd681203f7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token0/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 16a12baea3a1da7513f18e3d21661e9acb90b798e6eb7e42e9060c10c0562120
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_wrong_token0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18016
- `line_count`: 119
- `sha256`: 63a107b20b9c916b7eb37215d2df35ff42ee6a7e82ed9fbcf0e740a56a1732ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=18016 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_wrong_token0/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token0/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 843bd875df3f7612af78a27f00374167172888d4e14667c1a8c989ed19a11af0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token0/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: 8649cf5b7af53a81243fbe2c769c0ed6c8e95024cc63b1fa21a6a11802725ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_wrong_token0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_wrong_token0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token0/source-checks.json

- `kind`: json
- `size_bytes`: 5262
- `line_count`: 137
- `sha256`: 3144c7bf0d53c9c17d77b6040efc827d4e4ae778f87158b054009a0775f92f11
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5262 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token0/source-checks.log

- `kind`: log
- `size_bytes`: 3723
- `line_count`: 29
- `sha256`: 622aa536e149061ef533c99790e3b3e34bf7ea8e1eac4e01edf13a7706fd5860
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3723 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token1/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 44401f76c78d4f559fa1c419e35be200d0e2264dae4a1d5e7125d21048579e4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_wrong_token1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18015
- `line_count`: 119
- `sha256`: 9e2b1cdd273c63949854ab564ba062f4d15dc365e295bfa6c5b2236b9cd58208
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=18015 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_wrong_token1/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token1/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 42312c2402ec9d5710419f1168e0b19f504a39c019f9a71eedc31f056587f856
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token1/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: b52cfc129101198eb9469369de6f6013436ad2358f7e17f064393ded5db99727
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_wrong_token1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_wrong_token1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token1/source-checks.json

- `kind`: json
- `size_bytes`: 5324
- `line_count`: 137
- `sha256`: d888b142eecdda7540f1f82222148f4f95e98348833b76d7edcc6df5b828df5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5324 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/retry_wrong_token1/source-checks.log

- `kind`: log
- `size_bytes`: 3784
- `line_count`: 29
- `sha256`: 080239852fa794afc04ad0328fb6bf7f70c669be85f6503bbd01afe45f9ec55d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3784 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_equal0/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: 3db486769e1666444060f724ee72c6e82c97de9dd1656fb8879cceaffdd95db1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_age_equal0", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_equal0/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7294
- `line_count`: 63
- `sha256`: cf7679f7748449a74adf6a0a8b642854e5b13de97b3eec3dfaf95fead37c043e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7294 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_age_equal0/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mutan...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_equal0/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: d6abcf80e2b8c44ff36d8a3360b9b0188ffb28d1b54d394502d1fa873b6f275a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/logs/tb_ooo_store_queue.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_equal0/mutator.log

- `kind`: log
- `size_bytes`: 202
- `line_count`: 1
- `sha256`: f111d381f5d3b4444b1a07c9ff1f100abcbe94f0d80935aa4398c4278b3c3ad3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=202 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_age_equal0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_age_equal0/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_equal0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 338b7c680efaa9d8c6c4b70a351a7efc6c61bc48125ef8d9577d5e155c3644e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_equal0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 0994ff35ecef829e99e73b57fbfd35423e95b908133aa4ff4781e05702e45850
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_linear0/activation.json

- `kind`: json
- `size_bytes`: 147
- `line_count`: 9
- `sha256`: c77d343784111066d5734c8900c2cf9310ca85d1abab97778d9d71e3326f39b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=147 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_age_linear0", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_linear0/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7406
- `line_count`: 64
- `sha256`: a74a6be8b5e881666f97aa65a1da9dfd730d8c2020008e0bc90a8ba352083d23
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 22}
- `summary`: log evidence; size=7406 bytes; lines=64; FAIL=10; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_age_linear0/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/muta...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_linear0/make.log

- `kind`: log
- `size_bytes`: 335
- `line_count`: 3
- `sha256`: 4b394c219a2a83da86a3cef57ca00fc1f5a1cb9944a909e05e14f6c6f368c3ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=335 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/logs/tb_ooo_store_queue.log] Err...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_linear0/mutator.log

- `kind`: log
- `size_bytes`: 204
- `line_count`: 1
- `sha256`: f7073a52f553eed12e565ecd0b905d49e366843538143cdca1860bdf4ea09be7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=204 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_age_linear0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_age_linear0/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_linear0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 338b7c680efaa9d8c6c4b70a351a7efc6c61bc48125ef8d9577d5e155c3644e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_age_linear0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 0994ff35ecef829e99e73b57fbfd35423e95b908133aa4ff4781e05702e45850
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_compare_va/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: eaf42ea283866e20a217f2a0e4cb7be88e6f63debf06e75a5b29c91e0015b600
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 2 ], "mutation": "sq_compare_va", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_compare_va/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 8297
- `line_count`: 75
- `sha256`: fa8c843b2e3c74ae3045149ad5c2697aa234ccc92f7c19c3b825c872940e9d8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 32, "PASS": 22}
- `summary`: log evidence; size=8297 bytes; lines=75; FAIL=32; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_compare_va/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mutan...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_compare_va/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: 78eaa248d0d9f263efa48b53f2f87a9a1b82c3b6935ec7dabbd14a7f5cb37e4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/logs/tb_ooo_store_queue.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_compare_va/mutator.log

- `kind`: log
- `size_bytes`: 202
- `line_count`: 1
- `sha256`: 13f2af551567c46826cd799eb920285817df596265515d4ddbb7da8230511f4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=202 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_compare_va source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_compare_va/OooStoreQueue.v anchors=[2]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_compare_va/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: bd0e2d96a594d89671ecc8a158e8d500646f266cbfbfe3cc718daa500f760878
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=0 va_assignments=2", "passed": false }, { "check_id": "sq.fail_closed_y...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_compare_va/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 05d64819c9b4a57cfb912ff1c786d1ec47b9315faf93d45c27ef4cf23df448bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][FAIL] sq.final_physical_byte_compare_only: paddr_assignments=0 va_assignments=2 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_include_terminal/activation.json

- `kind`: json
- `size_bytes`: 152
- `line_count`: 9
- `sha256`: 8892572a941ab84f60f47ba14382c8f8821646e49f8ece180094fa92d98f7c86
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=152 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 2 ], "mutation": "sq_include_terminal", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_include_terminal/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7251
- `line_count`: 61
- `sha256`: c142735a76ab592743ca0f3bb055503e6a845251a67014e2c00d86ba410f38ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7251 bytes; lines=61; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_include_terminal/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_include_terminal/make.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 3
- `sha256`: 2f261205b89fef3b6339e4ea80e6fcdf246cd2846bf4aeeb0199f01c44f838ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=340 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/logs/tb_ooo_store_queue.log...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_include_terminal/mutator.log

- `kind`: log
- `size_bytes`: 214
- `line_count`: 1
- `sha256`: a7553b2085645279b40869aeacffbee1416134b976535f00e29c01fc6172922b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=214 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_include_terminal source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_include_terminal/OooStoreQueue.v anchors=[2]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_include_terminal/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 9c795f6943468d3d91991117f6ad90ed0ab84c49716cbfc3ee354737d02ec52e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_include_terminal/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: d5cb8d0b6df01165fb6ceb0e14e7bcd8f672843a5320ff5dff86e840669aea24
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_invalid_metadata_allow/activation.json

- `kind`: json
- `size_bytes`: 158
- `line_count`: 9
- `sha256`: 6275183237353567e09a9f22e1538791e842578a0cfb235d03a21e54bca9f7d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=158 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_invalid_metadata_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_invalid_metadata_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 8270
- `line_count`: 69
- `sha256`: cbdc2a8af27c579169814c8bf0b3127cae2c141da728e18b8ac77bb5c81844ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 20, "PASS": 22}
- `summary`: log evidence; size=8270 bytes; lines=69; FAIL=20; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_invalid_metadata_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_invalid_metadata_allow/make.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 3
- `sha256`: 851c351213b3ebc7bfee55657275af3265ba3327197bb7ac916008f41705fb57
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=346 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/logs/tb_ooo_store_que...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_invalid_metadata_allow/mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: 9c86acb74c59ab59fa52c3b0dfb22ddd0303f1e78299129a6867e09d19ee57eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_invalid_metadata_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_invalid_metadata_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_invalid_metadata_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: a435c78efa44dc9861249e2db83d02469f2bafe3e6c82c5c007abfda24ed6603
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_invalid_metadata_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 66de8a5a8911b8250c8ebc1b0c3347b0db7bb1bc2cfaa0c2aed745f3038c43aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_io_allow/activation.json

- `kind`: json
- `size_bytes`: 144
- `line_count`: 9
- `sha256`: fc88ad8846e9d1e043b3bee05d3192c2a59a3c2a49cfc2a605ccf669fe75b938
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=144 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_io_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_io_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7046
- `line_count`: 62
- `sha256`: 62282e9a91fcfd73ace01020a75b8aa4d9918d79a8efb996d425a1ce456af51f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7046 bytes; lines=62; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_io_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mutants...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_io_allow/make.log

- `kind`: log
- `size_bytes`: 332
- `line_count`: 3
- `sha256`: fa98bbcab94050851b01b5c10d34606a425813967254dbe3f4defc99239efae0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=332 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/logs/tb_ooo_store_queue.log] Error...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_io_allow/mutator.log

- `kind`: log
- `size_bytes`: 198
- `line_count`: 1
- `sha256`: 32d3f69f830ee2c11295fce9a0649271c265369ede1b598d68cef0024ca1f3fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=198 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_io_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_io_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_io_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 963498ec9f89698858346acca0c114fcaaf6748f39c4282454066e05bfc90a87
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_io_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: bd4c2c697da705033c928e5696f261af8ca795bca2d8c4d01e1ee80f1551ff65
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_oldest_byte_wins/activation.json

- `kind`: json
- `size_bytes`: 152
- `line_count`: 9
- `sha256`: 4822597bac82ba90cc4fd66ca1f0af60244c7a3c0028dfb78cb2f5d9db28cd09
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=152 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_oldest_byte_wins", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_oldest_byte_wins/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7552
- `line_count`: 63
- `sha256`: bf65f86f2b9e2e06a304de039e677d4d89e380e756d04957e48d6684f416592a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7552 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_oldest_byte_wins/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_oldest_byte_wins/make.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 3
- `sha256`: e558054260c6d9ad25b7dadf1fd3b63d34f98c4e91b7fad3f81c4dc4b197cbad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=340 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/logs/tb_ooo_store_queue.log...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_oldest_byte_wins/mutator.log

- `kind`: log
- `size_bytes`: 214
- `line_count`: 1
- `sha256`: 73ec4bd4501bbadccb6e042a8ae4c1ea5a1aee329db57b2864aaa31f1957159b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=214 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_oldest_byte_wins source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_oldest_byte_wins/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_oldest_byte_wins/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8f79f499c9f028e934c8bfd609eb8a2b81d7c3bb4500e3330e19e53bf1c68500
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_oldest_byte_wins/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 2ca07f99a9d1c3fff535755845ec054ce7847c80f0dbe2b76e0688861ed3b970
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_partial_allow/activation.json

- `kind`: json
- `size_bytes`: 149
- `line_count`: 9
- `sha256`: cc0aad14c6200afb05a322689247a4ba8ab5a5da5eea3aed9245a4511b93f475
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=149 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_partial_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_partial_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7411
- `line_count`: 63
- `sha256`: 30c2421d54af6e0428bfc1fa2bc3b9d1994b30077891d82d5c5556edc4f69459
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7411 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_partial_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mu...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_partial_allow/make.log

- `kind`: log
- `size_bytes`: 337
- `line_count`: 3
- `sha256`: 1641ce5b016a442c9461a1329328e1f0cf2f9d05ecf981ee72942053838d55e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=337 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/logs/tb_ooo_store_queue.log] E...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_partial_allow/mutator.log

- `kind`: log
- `size_bytes`: 208
- `line_count`: 1
- `sha256`: 57f520223ffe6c40ae84ac5f718657ffe664261033aa82d55e86f3d30e0ad2e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_partial_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_partial_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_partial_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 41b94c8ece0f9d1f429d9a06d1ea1da6afeff8e82f1532ad1a94e839f04b327b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_partial_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: bf10e1acb5ba566a32f52ceeef4ee272887f69a25059695823275f20ae8bd5c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_paddr_cross/activation.json

- `kind`: json
- `size_bytes`: 154
- `line_count`: 9
- `sha256`: b152c8ad1b203070531ca8858772c57ef998467f2ba55610428a99345b9f405b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=154 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_query1_paddr_cross", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_paddr_cross/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7708
- `line_count`: 64
- `sha256`: ecc78b54496d3e8462e97a5fb7e88785ae31a631278d411b568869aca06d4a96
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 22}
- `summary`: log evidence; size=7708 bytes; lines=64; FAIL=10; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_query1_paddr_cross/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOt...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_paddr_cross/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: 98b3bf2145c12398c7691887990f7a68babe9f382af97b9a15c659a7e0548e5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/logs/tb_ooo_store_queue.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_paddr_cross/mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: c7810e41a90a379d89c0a1f4aadba3a56e6be4ac22ee37bca18d212296de4593
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_query1_paddr_cross source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_query1_paddr_cross/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_paddr_cross/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 043e3651839b4601ccd90fdff011bdb70fb04563b84a4c59434fdb8ce4a1b375
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_paddr_cross/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 6eab3e15ce24d9cd5e8e4b1d24fc71612161bf21571448ab7fa0d54d33584464
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_poison_allow/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: 8d8559a6df8f1e8df7d53587b89ca6a99317c1d970f9d33671c6e57c52e76f41
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_query1_poison_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_poison_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7666
- `line_count`: 63
- `sha256`: 511bd4990457637f6fb0220b98c3daeb00a7adbeb266c2f1cae71ed08ebc887d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7666 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_query1_poison_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAO...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_poison_allow/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: 314c89316f1e614150e91481471cccc505a8d796cd02b590f4ddd8d6e5127d86
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/logs/tb_ooo_store_queue....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_poison_allow/mutator.log

- `kind`: log
- `size_bytes`: 220
- `line_count`: 1
- `sha256`: 164d57948c5beb72ef36262c96cb77849fe024d33987728edc364994c68394b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=220 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_query1_poison_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_query1_poison_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_poison_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 52e8d37741d584accfdaefd32ca3daa7b9a4b56e0713d6b8ae2c954d748621c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_query1_poison_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 7b1c305e8df7b30aa9c4fb914d382e6e3566ffdcc699375afc740245472976bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_unfilled_allow/activation.json

- `kind`: json
- `size_bytes`: 150
- `line_count`: 9
- `sha256`: 5c3725f6bda5d11a9f968fb7a0086e78c3fd32d7a03553020f3c661337d850fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=150 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 2 ], "mutation": "sq_unfilled_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_unfilled_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6463
- `line_count`: 57
- `sha256`: 9be5ea5a77b0c1aa923391fef896ef694fc507da4f2a9edd15a3d17d6af5a997
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 12, "PASS": 22}
- `summary`: log evidence; size=6463 bytes; lines=57; FAIL=12; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_unfilled_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/m...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_unfilled_allow/make.log

- `kind`: log
- `size_bytes`: 338
- `line_count`: 3
- `sha256`: 3b130006f14fcf08e05865d566399cfade1f557d1d36c7d46e95feff51407d26
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=338 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/logs/tb_ooo_store_queue.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_unfilled_allow/mutator.log

- `kind`: log
- `size_bytes`: 210
- `line_count`: 1
- `sha256`: 959ea82b087ca87f6fd3ce55c399a261700679af86d8f1cb23de9e7ad583df93
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=210 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_unfilled_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_unfilled_allow/OooStoreQueue.v anchors=[2]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_unfilled_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: e713a938dce317d541bf8de965e2881b2ae4952444fa5c21c7d14684fcef67e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/mutations/sq_unfilled_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: d4f65cc37872c2af4b27141b3219663006f4d94ebd19bbb485fe934ca8813fc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/predecessors/f0.log

- `kind`: log
- `size_bytes`: 268
- `line_count`: 3
- `sha256`: 3f299d71dff1729a85f664d5e878d611cc68fb430c0ee234693d6291bc5a6af6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=268 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8Q-F0][PASS] run_id=v8q-f0-20260720T133443Z-1185415 claim=dual_axi_miss_fabric_leaf_verified mutations=12 architecture=RED ppa=UNQUALIFIED make: Leaving directory '/home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/predecessors/f1.log

- `kind`: log
- `size_bytes`: 329
- `line_count`: 3
- `sha256`: 1fa7b397807283b670f082b5a7dcaa72a334996fb86b6386527a7dbd5ae57970
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=329 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8R-F1][PASS] run_id=v8r-f1-20260720T133445Z-1186307 claim=dual_bridge_cache_hit_leaf_verified mutations=10 architecture=RED ppa=UNQUALIFIED canonical_stage=F2_PROMOTED canonical_core_integrat...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/predecessors/f2.log

- `kind`: log
- `size_bytes`: 313
- `line_count`: 3
- `sha256`: 92f8866ca6e549fbd23d72137cbea964173720325773dbebf70635a340611941
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=313 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8S-F2][PASS] run_id=v8s-f2-20260720T133454Z-1188408 claim=architecture_checkpoint profiles=6 mutations=11 predecessor=F1_PASS architecture=RED ppa=UNQUALIFIED promotion_eligible=false make: L...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profile-summary.log

- `kind`: log
- `size_bytes`: 1823
- `line_count`: 11
- `sha256`: ba4854ae2697418f53837e0c9a507319f6479b27814a91b15e5808646248007f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=1823 bytes; lines=11; PASS=22; tail=[V8T-PROFILE][PASS] run_id=v8t-f3-20260720T133351Z-1183319 profile=sq-release image_sha256=fc09bdaed60c9f3839c060a98803d67041beae6fc1cffd6bbf850dbfffa02e5f [V8T-PROFILE][PASS] run_id=v8t-f3-20260720T133351Z-1183319 profile=sq-assert image_sha256=81ae998a4f3...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/backend-dual-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/backend-dual-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18078
- `line_count`: 116
- `sha256`: 63f05043a29b589e8578def8019338d3d5b1bb76ee0abdb7697396a7d41e7095
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=18078 bytes; lines=116; PASS=20; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/backend-dual-assert/tb_ooo_int_backend.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/backend-dual-release.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/backend-dual-release/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 17255
- `line_count`: 110
- `sha256`: 0e17dfd895652d79b6d57b4ed2ee6f3f8a3026dfc30863ae597625b724529cb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=17255 bytes; lines=110; PASS=20; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/backend-dual-release/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/backend-legacy-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/backend-legacy-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 22837
- `line_count`: 197
- `sha256`: 20420c0687c35905908eba62423acf32ef0a3fd3596c1af1d8b96fda7656e425
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"ERROR": 2, "PASS": 94}
- `summary`: log evidence; size=22837 bytes; lines=197; ERROR=2; PASS=94; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/backend-legacy-assert/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/bridge-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/bridge-assert/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71335
- `line_count`: 548
- `sha256`: 91e436d7b67c0363dc7f08260d4373474cf61cab6b096dcc448ff2506e9f13e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 19}
- `summary`: log evidence; size=71335 bytes; lines=548; PASS=19; tail=x-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/bridge-release.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/bridge-release/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71324
- `line_count`: 548
- `sha256`: f1ae7a42b02d8600af2eb648b880fc564977b2075921bab89a4dd8c70c6964eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 19}
- `summary`: log evidence; size=71324 bytes; lines=548; PASS=19; tail=x-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/core-glue-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/core-glue-assert/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 21476
- `line_count`: 111
- `sha256`: a56a2036ccfafacedf0a1f5ee55127748d1c7265fc07a3b43ad7a93c976c67b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=21476 bytes; lines=111; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/core-glue-assert/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/priv-system-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/priv-system-assert/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 21269
- `line_count`: 106
- `sha256`: 9d0c7d44ae058a394bf36eb27b338f08613892bfc6cfd7648d3a267d17c72955
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=21269 bytes; lines=106; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/priv-system-assert/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sq-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sq-assert/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6698
- `line_count`: 57
- `sha256`: 366cc6d224c24bb1755c69a413df46489c91c968b5cbd52dadde6db3ea5c5f28
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=6698 bytes; lines=57; PASS=24; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/sq-assert/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/O...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sq-release.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sq-release/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 5876
- `line_count`: 51
- `sha256`: 27241f73295c0fda35a8b2786e0af38dfec80df5890fb92044cc91d90d8357dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=5876 bytes; lines=51; PASS=24; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/sq-release/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sq-x-metadata-assert.make.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 3
- `sha256`: afdcdf0d79a0b598eb34ce3753710ae6b9282143ab643b588cbf9f788e2bf9ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=340 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-x-metadata-assert/logs/tb_ooo_store_queue.log...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sq-x-metadata-assert/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6943
- `line_count`: 60
- `sha256`: e8d7140609c10633db4916fa8ad6b86d1f6d1cbd6bfabf8125cb1a4015280263
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 22}
- `summary`: log evidence; size=6943 bytes; lines=60; FAIL=2; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8T_X_FAULT_INJECTION -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/sq-x-metadata-assert/tb_ooo_store_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sv39-boot-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/profiles/sv39-boot-assert/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 282894
- `line_count`: 2073
- `sha256`: 03ea16d6c895c74b3819c67637fbf836ed194fbc9fcb484fbe134761f61b2924
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=282894 bytes; lines=2073; PASS=2; tail=_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in arra...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/result.json

- `kind`: json
- `size_bytes`: 20835
- `line_count`: 506
- `sha256`: 030047748ddb9b75bb18e8be2cc164bbc576752d038682c8109c342ee40b8a0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 22}
- `summary`: json evidence; size=20835 bytes; lines=506; PASS=22; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "checkpoint_eligible": false, "claim": "final_pa_sq_ordering_candidate", "coverage_mode": "contract_p0_implementation_closure", "full_c...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/run-id.txt

- `kind`: txt
- `size_bytes`: 32
- `line_count`: 1
- `sha256`: 853d7e5fe18efb4780536dccf25086e2b8e6148bc47dd1a6f02fe5bc5288a3dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: txt evidence; size=32 bytes; lines=1; markers=<none>; tail=v8t-f3-20260720T133351Z-1183319

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 5928
- `line_count`: 39
- `sha256`: 0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=5928 bytes; lines=39; markers=<none>; tail=3773d6ba9bd468ed53aa441dfc225bd57fc1e21384be3c75ac0dfe3016686adc /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/contract.md 5f2b3a7e0691e690e51f2f85ef3184d6324d386fddb32cf63613b2eb3c84c605 /home/lyg/PA/ysyx-workbench/.gi...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 5928
- `line_count`: 39
- `sha256`: 0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=5928 bytes; lines=39; markers=<none>; tail=3773d6ba9bd468ed53aa441dfc225bd57fc1e21384be3c75ac0dfe3016686adc /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/contract.md 5f2b3a7e0691e690e51f2f85ef3184d6324d386fddb32cf63613b2eb3c84c605 /home/lyg/PA/ysyx-workbench/.gi...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 53133
- `line_count`: 1219
- `sha256`: b2f500274dac4d49c92d3aa641b2c870c785f6ff0b33a9b0a59f9bf9c72c0aa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=53133 bytes; lines=1219; PASS=16; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 11
- `sha256`: b89815b128e2d78856eff3d892acfc0601ef68dc3a391dc31b7fbe6623bff8e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=390 bytes; lines=11; markers=<none>; tail=DI-1: RED (7 red checks) DI-2: RED (18 red checks) DI-3: RED (6 red checks) DI-4: RED (3 red checks) DI-5: RED (15 red checks) OOO-1: RED (3 red checks) OOO-2: RED (3 red checks) OOO-3: RED (14 red checks) OOO-4: RED (9 red checks) OVERALL: RED RESULT: /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/checker-unit.log

- `kind`: log
- `size_bytes`: 2678
- `line_count`: 28
- `sha256`: de1f7c065abd365157c34119706a39c9ef9ae1d56aa755d3ff3d10e6f771cef8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=2678 bytes; lines=28; markers=<none>; tail=test_baseline_all_checks_pass (__main__.CheckerTests.test_baseline_all_checks_pass) ... ok test_bridge_active_load_fence_removal_is_rejected (__main__.CheckerTests.test_bridge_active_load_fence_removal_is_rejected) ... ok test_claim_inflation_is_rejected (_...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/checkpoint-finalizer-unit.log

- `kind`: log
- `size_bytes`: 884
- `line_count`: 12
- `sha256`: b5210100a7c222dcdea02dbecd1cb6a86b36fd7d0a7918c29273d8c390f94da6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=884 bytes; lines=12; markers=<none>; tail=test_candidate_result_tamper_is_rejected (__main__.FinalizeV8tTest.test_candidate_result_tamper_is_rejected) ... ok test_candidate_run_mismatch_is_rejected (__main__.FinalizeV8tTest.test_candidate_run_mismatch_is_rejected) ... ok test_claim_boundary_inflati...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/contract.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 9
- `sha256`: d2f0b52181f0745adf3f4b1b6e0db3bf236a692fa237a2d1392e9cc38bded200
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=9; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 10 tests in 2.806s OK [PRODUCER-HOLDER-CENSUS] PASS direct=18 packed=5 token_q=15 generation=1 契约立即断言（$error）计数：当前=436...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/mutator-unit.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 7
- `sha256`: 4428b93569b09f86fcea5920550e5140aea7b39f07aaffe0299875c6e779e116
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=7; markers=<none>; tail=test_all_mutations_have_exact_live_anchors (__main__.MutatorTests.test_all_mutations_have_exact_live_anchors) ... ok test_mutations_are_bounded_to_known_rtl_sources (__main__.MutatorTests.test_mutations_are_bounded_to_known_rtl_sources) ... ok -------------...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/npc-core-assert-lint.log

- `kind`: log
- `size_bytes`: 64842
- `line_count`: 718
- `sha256`: e4f9d22439b42e1ba6e0714af79e13b1209e12f39f5661d2cc2d1c536253596c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=64842 bytes; lines=718; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/npc-core-release-lint.log

- `kind`: log
- `size_bytes`: 63280
- `line_count`: 702
- `sha256`: ddcc6693fafc21da343e432c55507cb7d23aea38d63d74cb9e8bf49b2a890250
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=63280 bytes; lines=702; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include --top-m...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/retry-holder-proof-unit.log

- `kind`: log
- `size_bytes`: 691
- `line_count`: 10
- `sha256`: 1b49d09b40b68e21a1793fa8b3af33970f72891191c077203dc4c48ef2575b8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=691 bytes; lines=10; markers=<none>; tail=test_atomic_repush_deletion_is_rejected (__main__.RetryHolderProofBindingTests.test_atomic_repush_deletion_is_rejected) ... ok test_baseline_passes (__main__.RetryHolderProofBindingTests.test_baseline_passes) ... ok test_cancel_priority_deletion_is_rejected...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/retry-holder-proof.json

- `kind`: json
- `size_bytes`: 2065
- `line_count`: 68
- `sha256`: 79291ae3cfc9ffbe80e6a1edf881bae5e3833d821f235528047cef7968d95bf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=2065 bytes; lines=68; markers=<none>; tail={ "bounded_liveness_depth": 6, "checks": [ { "check_id": "source.two_complete_holder_payloads", "detail": "missing=[]", "passed": true }, { "check_id": "source.cancel_or_fire_precedes_capture", "detail": "counts={'bank0': 1, 'bank1': 1}", "passed": true },...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/retry-holder-proof.log

- `kind`: log
- `size_bytes`: 1123
- `line_count`: 11
- `sha256`: cc916611299adc69b102b0efc82258083bf68d5437171d9fda875a92d0d62f04
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=1123 bytes; lines=11; PASS=22; tail=[V8T-RETRY-PROOF][PASS] source.two_complete_holder_payloads: missing=[] [V8T-RETRY-PROOF][PASS] source.cancel_or_fire_precedes_capture: counts={'bank0': 1, 'bank1': 1} [V8T-RETRY-PROOF][PASS] source.capture_payload_exact: field_assignments={'bank0': 13, 'ba...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/source-checks.json

- `kind`: json
- `size_bytes`: 5215
- `line_count`: 137
- `sha256`: a0c6e9b3f9a562583b6a0de179abb23d5a6e9cfd344d8808f3d463555ca6ef5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5215 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/checkpoints/v8t-f3-20260720T133351Z-1183319/static/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: a6724f02dc55c32333b92661d69ea7f35bc6db4a430935b1b40fc623fdb50a3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 52}
- `summary`: log evidence; size=3678 bytes; lines=29; PASS=52; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/architecture-manifest.post.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/architecture-manifest.pre.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/checkpoint-final.log

- `kind`: log
- `size_bytes`: 320
- `line_count`: 1
- `sha256`: 7154b6ddf886bc8952eaa0c334fd6c31d7e71282556c8983b2e4d2aba7276254
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=320 bytes; lines=1; PASS=6; tail=[V8T-F3-CHECKPOINT][PASS] run_id=v8t-f3-20260720T133351Z-1183319 claim=final_pa_sq_ordering_checkpoint coverage=contract_p0_closure profiles=11 mutations=38 dynamic_rejections=37 retry_proof=PASS predecessors=F0/F1/F2_PASS architecture=RED ppa=UNQUALIFIED c...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/checkpoint-result.json

- `kind`: json
- `size_bytes`: 21887
- `line_count`: 523
- `sha256`: 69133fbe3624aad6d0bc013dafeddf8705b65ff70548954d325845e240b72296
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 24}
- `summary`: json evidence; size=21887 bytes; lines=523; PASS=24; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "checkpoint_eligible": true, "claim": "final_pa_sq_ordering_checkpoint", "coverage_mode": "contract_p0_closure", "full_contract_mutatio...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/commands.log

- `kind`: log
- `size_bytes`: 1294
- `line_count`: 24
- `sha256`: 50bddc2dfe8bba564fef69f9022174d48aacb5845dc06b370a356fcb0f3ff1fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=1294 bytes; lines=24; markers=<none>; tail=python3 checker unit tests python3 mutator anchor unit tests python3 retry-holder proof binding unit tests python3 checkpoint finalizer unit tests python3 retry-holder exhaustive proof python3 baseline source checker make check-rtl-style make check-contract...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/final.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 1
- `sha256`: 770f50cc7468464f41e8125207de6992e503ebad0c2cdff18416b4ac96509392
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=334 bytes; lines=1; PASS=4; tail=[V8T-F3-RUNNER][PASS] run_id=v8t-f3-20260720T133351Z-1183319 claim=final_pa_sq_ordering_candidate coverage=contract_p0_implementation_closure profiles=11 mutations=38 dynamic_rejections=37 retry_proof=PASS predecessors=F0/F1/F2_PASS architecture=RED ppa=UNQ...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutation-summary.tsv

- `kind`: tsv
- `size_bytes`: 8306
- `line_count`: 38
- `sha256`: 71c3b1812387bf8f8be68a572b9cb491177c00d66105d5ca02a8175466399af6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: tsv evidence; size=8306 bytes; lines=38; markers=<none>; tail=sq_compare_va|sq|sq.final_physical_byte_compare_only|target_rejected|a8f9f2f7b7e6d16b60900f090fb0e409250674f9f0ae3dc095a2c2cef2c3bbea|f2cf4cd0203e338266d8f0fa090170f3800eea677bc6dda91e1919f2fc26b63d|2 sq_partial_allow|sq|sq.fail_closed_youngest_merge_semant...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/activation.json

- `kind`: json
- `size_bytes`: 158
- `line_count`: 9
- `sha256`: d9be54f59a6e78620e7dcd7b35843f37a31d03fd4df0f92743df9c7cdae7f351
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=158 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_dtlb_fault_query", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70418
- `line_count`: 532
- `sha256`: 7c48a57637835b70b0d9d365391fe12b6d812c2797bfed6e86401e96297a8799
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: log evidence; size=70418 bytes; lines=532; FAIL=4; PASS=3; tail=_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'e...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/make.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 3
- `sha256`: 17c84a4be65d3b05ac3533cf81831a4b6abffee59d80013f0e6db9abd63505ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/logs/tb_ooo_mem_axi_bri...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: 6bd8ed164c2fefa2ccff77d5dc6b93d31d453d82d76cc4bddbb51653420260d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_dtlb_fault_query source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_dtlb_fault_query/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 83af78cbcd14f1abdc64cab4f1ff5acae345de3c42320620e5a7d1e7c96f3f8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_dtlb_fault_query/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 588f0208f7f152ea271996fa84e55cef38cedd144e97d0150dfd06613d1db024
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/activation.json

- `kind`: json
- `size_bytes`: 156
- `line_count`: 9
- `sha256`: 0a70e670bd85f9ef1c8b609676bb2a15874ed1c8fd19fac733737624a635792e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=156 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_forward_lookup", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70099
- `line_count`: 529
- `sha256`: 68eb3af5289900c60cd5115d8443c90205dc5a54f17c501d397fe394271321bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: log evidence; size=70099 bytes; lines=529; FAIL=4; PASS=2; tail=is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: war...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/make.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 3
- `sha256`: e109f768c8177596fe878623b09cbc830d5b0b648c91fdc3673f279c39c5a302
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=345 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/logs/tb_ooo_mem_axi_bridg...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/mutator.log

- `kind`: log
- `size_bytes`: 222
- `line_count`: 1
- `sha256`: 783d6441223fceec78882a3302a1f8f4eed5028834b21e8ff2774cc56e694c9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=222 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_forward_lookup source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_forward_lookup/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: d82b5b45adb3a7ae4e2def3df02b9056ddbe22678b8f213c88884c490a473dad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_forward_lookup/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 44522a3f7fd1356caf27ca96074a8f4a157b8795247d1268d096a0f771d38d72
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/activation.json

- `kind`: json
- `size_bytes`: 153
- `line_count`: 9
- `sha256`: b9644a469495ebdc1ffa3c70d9235181e0d7688d60425b022a8a36028e4cf7ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=153 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_hold_replay", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70084
- `line_count`: 529
- `sha256`: f5e3e42827d1f88fd03cb8fb465802cb6292fb6d0c1b2fb800915aed7c97f388
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: log evidence; size=70084 bytes; lines=529; FAIL=4; PASS=2; tail=ning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: c1a18b1efe7bf5d4e24e69cb68a8d6868556110c6a4a445d8e12e8c307fa8bcc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/logs/tb_ooo_mem_axi_bridge.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/mutator.log

- `kind`: log
- `size_bytes`: 216
- `line_count`: 1
- `sha256`: a8cb317b7675aa5ea206797b94517d6515348de8659310d2d3b9269e6be19882
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=216 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_hold_replay source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_hold_replay/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 24e0ff4d730fe6a1cfed8121a25df413874bde2710df0c161e479c837839073f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_hold_replay/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 6c8bc2ed05966b138ac053d2c09c4ea5b4bcda1f58c817799ccf94bb9e8c864f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/activation.json

- `kind`: json
- `size_bytes`: 159
- `line_count`: 9
- `sha256`: 8bc8ee2dd68cddb724b5a5449f9cea42578b34af5c3990838528eaa9573d4cc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=159 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_late_ad_dtlb_fill", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71665
- `line_count`: 552
- `sha256`: bfee9ca53b7d51476fccadc50518880c9c2cdd2d0bea012a531e4f37f43063ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 3, "PASS": 17}
- `summary`: log evidence; size=71665 bytes; lines=552; FAIL=3; PASS=17; tail=mory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/make.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 3
- `sha256`: 36358a3bb1deb309e088bb45e6de336b623a82bbbbe9d3ae20a544e724bbf9f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=348 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/logs/tb_ooo_mem_axi_br...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/mutator.log

- `kind`: log
- `size_bytes`: 228
- `line_count`: 1
- `sha256`: 56d9a120decbe3240e82d738543446b2ce7af934ea2f67f46faa2e9983284a06
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=228 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_late_ad_dtlb_fill source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_late_ad_dtlb_fill/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 3012e188eefa0336adc97e95413ef161d4a79deb06d23c4b7719fa7a02d81f42
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_late_ad_dtlb_fill/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 8ef521e1af6b80f8631cc411e9d54567fd606f335d1522cd99e20b4b8bb2f5cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: 479898a3c839212e8641aaf94c63b3ab65707853ac33bc6f8a94aeb89fcd7550
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_pmp_fault_query", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70335
- `line_count`: 531
- `sha256`: 16aba704f265c5845e8e5e3f39dd447de9e1a48a17de1c7a2686a9dcf2aa8413
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: log evidence; size=70335 bytes; lines=531; FAIL=4; PASS=3; tail=y/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/make.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 3
- `sha256`: 2ed0de97d117cf5c75fbfc7a6a1cd8b124b73901f3010fa5c32c55ed55456472
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=346 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/logs/tb_ooo_mem_axi_brid...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/mutator.log

- `kind`: log
- `size_bytes`: 224
- `line_count`: 1
- `sha256`: 5dbd679c715e83e54c36791215dc69b55848038826d3b17613c696d64591d9f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=224 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_pmp_fault_query source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_pmp_fault_query/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 30351ee592d85b547555c6eb28b045f0e01c1a93e7aa6555a562c0969cb18ed2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_pmp_fault_query/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 06dd0c0a9cbd515ad6e9ccdb72b350d4a2f48152efa99c795965814d0134aee4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/activation.json

- `kind`: json
- `size_bytes`: 164
- `line_count`: 9
- `sha256`: 2df64821c6d72fc4fca728ccf264c4272d1fd86bcc1596d94b598e2d34484b05
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=164 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_release_without_credit", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 70127
- `line_count`: 529
- `sha256`: 3da57b0ba11c7895fa6a434c43d8c9134d61d5531de9307b43c9ba829bb2e495
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: log evidence; size=70127 bytes; lines=529; FAIL=4; PASS=2; tail=to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is s...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/make.log

- `kind`: log
- `size_bytes`: 353
- `line_count`: 3
- `sha256`: d4cabee1905a9ba31a46e44ea4e34a8eea1de9fc96d2a2cec146c2cc221e45a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=353 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/logs/tb_ooo_mem_a...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/mutator.log

- `kind`: log
- `size_bytes`: 238
- `line_count`: 1
- `sha256`: fac16ef8703b13a28a4a7ebec20e470994b184cb2df902c2317c3bff8cd9e0fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=238 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_release_without_credit source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_release_without_credit/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8bd5235ca5fd8a10bf1026d3aec02f0b630a3e7ec674e5ee1c9f9e35ff22d707
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_release_without_credit/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 0ef1add9a4acfa622905e1247cde5fa6f201bc445a9655ef20cde95344409c6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: 52dcb40b8cff003e7ee9bbbe18abfb015c7ec7fa60ee1faa2e14080a8b834882
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_route_ad_bypass", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71698
- `line_count`: 555
- `sha256`: 557dc76f5660b5ceb813fd3e83dbd997dda11d8798bb42a6f626760c20638eb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 5, "PASS": 18}
- `summary`: log evidence; size=71698 bytes; lines=555; FAIL=5; PASS=18; tail=sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/make.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 3
- `sha256`: 7fac387a7b3ea2b462d6b0184ab5144f3c754cd80116404bbbaf606a6e897f2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=346 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/logs/tb_ooo_mem_axi_brid...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/mutator.log

- `kind`: log
- `size_bytes`: 224
- `line_count`: 1
- `sha256`: 5c29a40b8e9b1ba9dd3a0197211cb409e08d164f21e081cc0109ba83c1681a76
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=224 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_route_ad_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_route_ad_bypass/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 0074c9d3946a4ddceca1229fac1fff066980f79617cf54e7b9c05f95f67b6ba8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ad_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 07095a87a854bb981ef607f3a8512d100bddc18792a2e6ebaec372dd1ebefd25
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/activation.json

- `kind`: json
- `size_bytes`: 159
- `line_count`: 9
- `sha256`: e2cd7ab38beaa610666fcc94a1f37430bade164f18f57e15fb7a19955d8671d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=159 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_route_bare_bypass", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 96225
- `line_count`: 906
- `sha256`: 0a111924c0408b39915afec8a9fc8bb7699ab0eb7958baae8c8c1499535ced6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 356, "PASS": 18}
- `summary`: log evidence; size=96225 bytes; lines=906; FAIL=356; PASS=18; tail=-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/make.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 3
- `sha256`: 7ad1a03574210f17a5009815f79984d9f50fe5fe197b104a3e79b650df633fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=348 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/logs/tb_ooo_mem_axi_br...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/mutator.log

- `kind`: log
- `size_bytes`: 228
- `line_count`: 1
- `sha256`: b640003532ec32f6b187df4441d32ef799850546afa77afe51117ebd96b6dda2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=228 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_route_bare_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_route_bare_bypass/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 2a578a5a37739964147dd4c8101287307996180689a9f250ddc35cb09adfca63
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_bare_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 79e2c35d105c56ceb2b7d6bd51c77de4d5e0f97322acaba831b804aedec0e771
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/activation.json

- `kind`: json
- `size_bytes`: 158
- `line_count`: 9
- `sha256`: d6f0e7bc038e53545336271a66e37e7cbd2cb3f8730608a8ddfaba66c4524d0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=158 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "bridge_route_ptw_bypass", "schema_version": 1, "source_name": "OooMemAxiBridge.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 88888
- `line_count`: 803
- `sha256`: 694f34bb6405f13219d8aac0b79daa19815dc0f68e1d5c279172ef4b9ed3b046
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 253, "PASS": 18}
- `summary`: log evidence; size=88888 bytes; lines=803; FAIL=253; PASS=18; tail=_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in arra...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/make.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 3
- `sha256`: 45874225f8c4ad987817b7c18f875649dbdd6515b66e2c5b96dbe740ec3434a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/logs/tb_ooo_mem_axi_bri...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: c6b252290a852a9cf5d732b3c7f5b25d055fa6812d5e81bc27ff2a1d237f97e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=bridge_route_ptw_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/bridge_route_ptw_bypass/OooMemAxiBridge.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: af195ae00065a9e0d243e61eff619897a07acbdd9465df042f37aa7124ff6857
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/bridge_route_ptw_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 9362e1e1e27c2d8873b66337bd5d3b1bf50da71f8e915b0d9f32abd3a2fb0aa2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/activation.json

- `kind`: json
- `size_bytes`: 153
- `line_count`: 9
- `sha256`: 09635bfda626806f898cb9fa6d3f8ca374753dd7771cc83ebee95cbad206c484
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=153 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "cross_bank_query_pid", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18115
- `line_count`: 121
- `sha256`: 1d284733e0fd6d4267ee9e72a7b5cf210c9956da7c8a22caf74f19c4db25cff3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 14}
- `summary`: log evidence; size=18115 bytes; lines=121; FAIL=10; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/cross_bank_query_pid/tb_ooo_int_backend.vvp /home/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/make.log

- `kind`: log
- `size_bytes`: 341
- `line_count`: 3
- `sha256`: 6e867979ecda3581bb5ed77eee187347cb69c3af6ee3bd26030625d4e94ec45a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=341 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/logs/tb_ooo_int_backend.lo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/mutator.log

- `kind`: log
- `size_bytes`: 217
- `line_count`: 1
- `sha256`: a89c88662c559df01ee48cfe448ca0c662e2c385a046cd5906a267275b5a359c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=217 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=cross_bank_query_pid source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/cross_bank_query_pid/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8e022c33c27710cebd81c13a91c8966d8977f23c11eac15e5d5d6c277f5eaa7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/cross_bank_query_pid/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 5ba60ec5de1acb5934913e753e5f7ac8cec75920d95edf7363d88aae665f0225
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: bad000f2acbc09718b1bcd280c3bd1469af3f88170a688c6d97fb93fb0a27cd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "dual_slot_valid_bypass", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18573
- `line_count`: 125
- `sha256`: 5bee4e35401f941749d1b1bef53cbe275e681c0c74262526ae340703e984d7fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 14, "PASS": 18}
- `summary`: log evidence; size=18573 bytes; lines=125; FAIL=14; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/dual_slot_valid_bypass/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: 10c4a35d951f190793698ae69ce12c528339376f50c221b9cfcf14932643951c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: 4f8da6bf85035eba567aa2bbdd1b9a8ee9a30ad54d46c001de24288466bbcf9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=dual_slot_valid_bypass source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/dual_slot_valid_bypass/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8ccef3ba91fb6dc11e0137a403f79f39faa54f4398dab95e0769b6505603214c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/dual_slot_valid_bypass/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 14464c2466e46cdb1b979d607d282dd6bedf8e98925b92bbcd28f6c35c54f286
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/activation.json

- `kind`: json
- `size_bytes`: 154
- `line_count`: 9
- `sha256`: f0b15ad4fc3a4088be549f3250dce7a7f84c3d158aa474492ab72f747dba22ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=154 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "legacy_all_load_block", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18318
- `line_count`: 124
- `sha256`: cb2d24397c3ce1922edd8b4f56671dab9c619c44f42815ba05c79604b99990e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 16, "PASS": 14}
- `summary`: log evidence; size=18318 bytes; lines=124; FAIL=16; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/legacy_all_load_block/tb_ooo_int_backend.vvp /home...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: 014fc0f4b929f578a0940bb0e6e88a0811157b8c3af3c156ab97b80a51b67531
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/logs/tb_ooo_int_backend.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/mutator.log

- `kind`: log
- `size_bytes`: 219
- `line_count`: 1
- `sha256`: e5b5937a23e0f75db968edabfdb13ba7af95f88ff8e11482213d0a84b17e8a15
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=219 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=legacy_all_load_block source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/legacy_all_load_block/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: cc0427973e7f61d4cc04266f10abea5f24db3524cb5efbe686e22f9f5edf6496
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/legacy_all_load_block/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 95d7257a8db830f3d8cc14dec3501f646b716e14630b0cf99c70d0643bf8f182
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/activation.json

- `kind`: json
- `size_bytes`: 159
- `line_count`: 9
- `sha256`: d564e06f9743f610c0a847ff03e1cd0c9b0f681caeff3d373f2656610bcdf507
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=159 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_active_fence_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18372
- `line_count`: 122
- `sha256`: b01d428d366770321c5ee04ed13b45d4c2611573d66cc5113d506308ee951fe1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18372 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_active_fence_delete1/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/make.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 3
- `sha256`: 864b9a074886112d43d04f2ebb622772d6ef417c452692e4d811e9719ad4fc6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=347 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/logs/tb_ooo_int_back...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/mutator.log

- `kind`: log
- `size_bytes`: 229
- `line_count`: 1
- `sha256`: c53bcdc579cb5f3376187bc42386156e18557b9629f7014de4bf4530b2c90ea1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=229 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_active_fence_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_active_fence_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 68cd304fe9d21101e3159039eff645a9d7b355ef5a1a9318e1a6eee02c92ca1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_active_fence_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 3b1d9c4aa9f8022384c8f7bf5259dd094c6257377ef20d583338dd681203f7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/activation.json

- `kind`: json
- `size_bytes`: 162
- `line_count`: 9
- `sha256`: 326e92b7dc0fa00618e8e80611f352ca5691415f267530fc0edd36e32d99ab6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=162 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_cancel_priority_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18363
- `line_count`: 122
- `sha256`: 1411758e42e80a4f3810835ac68b8b80d21d95b2fc93790f178f55a810fd5801
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18363 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_cancel_priority_delete1/tb_ooo_int_backend.v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/make.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 3
- `sha256`: 09ab68ebc84eb635f6b404cdc0a9aa530bc84a9f3ae632b354baf7043d1da84a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/logs/tb_ooo_int_b...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/mutator.log

- `kind`: log
- `size_bytes`: 235
- `line_count`: 1
- `sha256`: 6cdaacbb9ca02b573c5a2647b2778841a1308728139dd8eaa09da6e0bc05d1e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=235 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_cancel_priority_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_cancel_priority_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: aea9c104ef02240f9ae13cd307303b45285af819f12cfd964d4b2697d705ed1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_cancel_priority_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 282531f99e9169463121811d9c2d1c8f3d6dbf2b1d8f4cbb097361f8d1e25acb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: 9c615b9e920668ac18eec24f260541123545a2d11dc7c5478494daacab37baad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_fp_capture_drop1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18816
- `line_count`: 128
- `sha256`: 45b745086eaba9a5b44ecaf0ceeac0f268ef639b02fde44f86de1e27ca3b9583
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 20, "PASS": 18}
- `summary`: log evidence; size=18816 bytes; lines=128; FAIL=20; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_fp_capture_drop1/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: 263adeb5fc70c32f0521b0bf10671ab0f43d1f6c440c95ea1be0fd82ac2d5f73
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: 70ff6b9af4ec825e2211403da82bc05584e6c2e848f05e45fbb68c6d6f4c7ac6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_fp_capture_drop1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_fp_capture_drop1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 6e0c60d5f76126d7d085e36b8cb90b30f83a189ee2b9a863f7c70eb4fcc8c1a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_capture_drop1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 03547ec91df5c8d6e361ef209bae8dea5b423a545a800d98c1261b58e6a4f47a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/activation.json

- `kind`: json
- `size_bytes`: 154
- `line_count`: 9
- `sha256`: 0439da9ec97e968254b94ae3d96ae71022be63c06cd596348535f9a2813743d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=154 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_fp_repush_drop1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18662
- `line_count`: 126
- `sha256`: 0b5a5735c704d9b451184524e493da6fce3d1e42ecdd7d74b1beb49f388ec5bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 16, "PASS": 18}
- `summary`: log evidence; size=18662 bytes; lines=126; FAIL=16; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_fp_repush_drop1/tb_ooo_int_backend.vvp /home...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: 4c8e170231ed429223bf0fc4597d5094a0b7c5f7948f965b2344e8e30aef6fe2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/logs/tb_ooo_int_backend.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/mutator.log

- `kind`: log
- `size_bytes`: 219
- `line_count`: 1
- `sha256`: 3fde0ab66fc1c09f7c7e93bb2994c89dd9d983b9376ff865bc2e8ab69b26d468
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=219 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_fp_repush_drop1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_fp_repush_drop1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: af070598f91cd8a58ef6fca8415b3bad24e940af2f7c8695f3d55649319d5c85
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_fp_repush_drop1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 81ace9a3cc963253cc1ec99cbd1349ff74a9b7883581ff85f5627deb8a8ba18c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: 3847d171340c0c7ac9bf3802c62f4777d447036fbaa4ba40f35a3ac375205afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_load_fence_delete0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18443
- `line_count`: 123
- `sha256`: 6c271507e7af1f2aa460d51f186d446cf6b2541c3427edba0a19a7923ffa42d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 18}
- `summary`: log evidence; size=18443 bytes; lines=123; FAIL=10; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_load_fence_delete0/tb_ooo_int_backend.vvp /h...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/make.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 3
- `sha256`: ee6b5c325c0ed23081b338666ebfa8c4ac2ecd8b455c4782b8cd33e04cef88dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=345 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/logs/tb_ooo_int_backen...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/mutator.log

- `kind`: log
- `size_bytes`: 225
- `line_count`: 1
- `sha256`: 1c7820c0cf33b62070b885f4b7db443eb4cb242922e37d9c966a56d2c790c5f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=225 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_load_fence_delete0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_load_fence_delete0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 6f0ba8a6ca5e1ecdb274a9531cac471aa7926266e8d65b7e6968a63fbbf80da0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 203bc7f64f9fd6111fb69044e4b11cb35ce9f1d184ad1bee65420030a6835e31
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/activation.json

- `kind`: json
- `size_bytes`: 157
- `line_count`: 9
- `sha256`: e05a1072d394c14d573123849899ca1158982f0f525062ef5fa1289c6410f797
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=157 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_load_fence_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18368
- `line_count`: 122
- `sha256`: 4f3575ce8334db7f01ef4c85e08c83ae2a5b5d764324892c8f4bcf5af383783d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18368 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_load_fence_delete1/tb_ooo_int_backend.vvp /h...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/make.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 3
- `sha256`: dc967838bb57474d2407a41cbf693a981bed6ee76c07c93c7b9d8a85398f7d39
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=345 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/logs/tb_ooo_int_backen...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/mutator.log

- `kind`: log
- `size_bytes`: 225
- `line_count`: 1
- `sha256`: dad34e8fd47cd293547e96b64cadc8484e325def045e29edf5f53ad680445909
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=225 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_load_fence_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_load_fence_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 68cd304fe9d21101e3159039eff645a9d7b355ef5a1a9318e1a6eee02c92ca1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_load_fence_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 3b1d9c4aa9f8022384c8f7bf5259dd094c6257377ef20d583338dd681203f7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: 3e692270df8f795bb1354ac507d4164286be6346b38d1326341835f737de650d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_no_pop0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 17996
- `line_count`: 119
- `sha256`: bf590bcc5efa582dbd1316b73874538b1b6a899fd859068bee3b14a1b63d1bf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=17996 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_no_pop0/tb_ooo_int_backend.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: bbb491dd27610f8e33919192bfe235272a97b4a63f7bb6578d88527d9a7a3d20
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/logs/tb_ooo_int_backend.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/mutator.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: f23b8a100e7c7f13e2b4c3371fc4d82f882fe49705190e04a022b76f1f98dc75
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=203 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_no_pop0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_no_pop0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/source-checks.json

- `kind`: json
- `size_bytes`: 5297
- `line_count`: 137
- `sha256`: 09e303723ff833fa9f9bcb49174fb44d1f25dac5c3c22b1e490a5d7630e4f595
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5297 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop0/source-checks.log

- `kind`: log
- `size_bytes`: 3757
- `line_count`: 29
- `sha256`: 4e5317e7485cf67e0c26ad670d45386b014285657f7fa608564804bfdc67c180
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3757 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: 1f62bd21f000e04647a9baedb75cabf3d1596185f02ed70ac4f8bb400817af59
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_no_pop1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 17996
- `line_count`: 119
- `sha256`: 917e0cc054b40b6609cca16e76768a75ff7e67a70f07605c2940558e197f96a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=17996 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_no_pop1/tb_ooo_int_backend.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: feaa82b42627b10959f769fa173493ae9b128da75ec9c141da651b300ff6b944
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/logs/tb_ooo_int_backend.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/mutator.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: 27108e443663e65dca211a1ffd244eb49f40122089ea53de6d081a4b8c83c875
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=203 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_no_pop1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_no_pop1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/source-checks.json

- `kind`: json
- `size_bytes`: 5299
- `line_count`: 137
- `sha256`: f1cd26386df7f7c6fb9bddc2a1605783335f0d902fac23f82f7e96f7fbf53ffe
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5299 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_no_pop1/source-checks.log

- `kind`: log
- `size_bytes`: 3759
- `line_count`: 29
- `sha256`: 155ae3bd4bf35011d37309271851de3a509def9c88bb9db73ea9d2a8d43c10d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3759 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: e528ea163dd135367ab52fcd6d983e2d1fd322f5d36b172cecc33e6870db0382
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_priority_invert0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18724
- `line_count`: 129
- `sha256`: efe844a376d954958c67c78d00ee25a91c8e1ed7ee54c94ef098aee4a76af96b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 26, "PASS": 14}
- `summary`: log evidence; size=18724 bytes; lines=129; FAIL=26; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_priority_invert0/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: c701574643c547a81d40243b9347a91ac9af082dc5eded839e7680d48da78b2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: 9b2f3e4e6c24abf5c5906803884555cb4bf32a3555e01a8a3b1481d1339d3fa6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_priority_invert0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_priority_invert0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 52b1076c2fe01631c5a6531071581099f75cd0b3645255a5c77f958dff062353
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: ea75dee9fa62f9c9726e4d4ebeb39fb56d08fb5e378ba29cbbea7e7d05b0f18e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: abd58f744699b7d96a99c14fa640730db68958ea3bdd11e868715e1cf1e05c68
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_priority_invert1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 19238
- `line_count`: 137
- `sha256`: cb44aebb623c36a10bcff4c063046996c02565212078de8d260854a12e64ab27
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 42, "PASS": 14}
- `summary`: log evidence; size=19238 bytes; lines=137; FAIL=42; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_priority_invert1/tb_ooo_int_backend.vvp /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: aa7a4d1a8f26147e4612efeba1a4e7a19fb55f683571db42b08fd6aa75f5d948
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/logs/tb_ooo_int_backend....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/mutator.log

- `kind`: log
- `size_bytes`: 221
- `line_count`: 1
- `sha256`: b88f93ed52d8c78b7b85105fd58cd867bb5bd93707f80bda8679342e5acb4130
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=221 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_priority_invert1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_priority_invert1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 2605b7dc866c9fe7d1610fba6dfc1e51c1973c06b2bff241e1342c7ea121656c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_priority_invert1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: bf14c008c3ce7a9787e3434683f785bbbdf199c1dca271cab511e8584091f617
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 3b2f1c1ffc64f467acdf6a9e7c5755f93ce56daf7d82352415cab4c591391d44
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_silent_kill0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18493
- `line_count`: 124
- `sha256`: eb9f034cd0b45492c28a21feed1655583da6f85bc9c5afae526afce3cde251c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 12, "PASS": 18}
- `summary`: log evidence; size=18493 bytes; lines=124; FAIL=12; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_silent_kill0/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 415935ee141cc9a84a1901535257505c5e64202bd073b32fb413486fbce13df8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: 0f0a51839525d244c12617bdbcda37c389de160b90a37bf95cae4b0e63ec51eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_silent_kill0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_silent_kill0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/source-checks.json

- `kind`: json
- `size_bytes`: 5275
- `line_count`: 137
- `sha256`: ce1fd063cf4bb43b43c9f4d0467f099d97cef1e19783ba7b16aa0eb35254e4a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5275 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill0/source-checks.log

- `kind`: log
- `size_bytes`: 3736
- `line_count`: 29
- `sha256`: a7b10ae746039af9cc98203d62544f50b4a155ce4f0d7d9d69ae79f7576cfb3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3736 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 32c91a16ac689eafd9f0698ca0cf6809bbb5537d39c18423a7e99b2181a85262
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_silent_kill1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18490
- `line_count`: 124
- `sha256`: 354073bd74815255a7121891b05bf2db40dfd133e984633da3986dd647248f1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 12, "PASS": 18}
- `summary`: log evidence; size=18490 bytes; lines=124; FAIL=12; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_silent_kill1/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 652bc6dffc52db5e7c8937b8c6b1eb5cf360c77ad26e25357c6d9a113d6786ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: d9cb5ecc1dda10aa37ec4cdf97e42cfd189832e0d1395efcc98636cc4b1545d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_silent_kill1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_silent_kill1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/source-checks.json

- `kind`: json
- `size_bytes`: 5275
- `line_count`: 137
- `sha256`: fb26be743800868a443857b2cdc5970559826de379e339c57fe52b6600633f7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5275 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_silent_kill1/source-checks.log

- `kind`: log
- `size_bytes`: 3736
- `line_count`: 29
- `sha256`: c07d9d145ddd121b206706266c59d8c464226c8cc5067eae4831eb4483f2acd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3736 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/activation.json

- `kind`: json
- `size_bytes`: 160
- `line_count`: 9
- `sha256`: 5893693a48d8b4da7f2e66422f7d6a92a444bf38c74b56d738e6fab51a71491e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=160 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_station_fence_delete1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18375
- `line_count`: 122
- `sha256`: 64b8512b8bf825f9620c69ad96166efce1cfae6cb5e1c9fe7b2d2eeacdbcd660
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=18375 bytes; lines=122; FAIL=8; PASS=18; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_station_fence_delete1/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/make.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 3
- `sha256`: fd60fd9612d93c23aa8850762bd61175236a9139402d21a6f1e2457286bb0dbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=348 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/logs/tb_ooo_int_bac...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/mutator.log

- `kind`: log
- `size_bytes`: 231
- `line_count`: 1
- `sha256`: 6d7ea9ac5033ef67556d093ce5a63b5af3f8ef58be979397119231065e4ebe13
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=231 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_station_fence_delete1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_station_fence_delete1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 68cd304fe9d21101e3159039eff645a9d7b355ef5a1a9318e1a6eee02c92ca1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_station_fence_delete1/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 3b1d9c4aa9f8022384c8f7bf5259dd094c6257377ef20d583338dd681203f7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 16a12baea3a1da7513f18e3d21661e9acb90b798e6eb7e42e9060c10c0562120
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_wrong_token0", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18016
- `line_count`: 119
- `sha256`: 63a107b20b9c916b7eb37215d2df35ff42ee6a7e82ed9fbcf0e740a56a1732ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=18016 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_wrong_token0/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 843bd875df3f7612af78a27f00374167172888d4e14667c1a8c989ed19a11af0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: 8649cf5b7af53a81243fbe2c769c0ed6c8e95024cc63b1fa21a6a11802725ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_wrong_token0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_wrong_token0/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/source-checks.json

- `kind`: json
- `size_bytes`: 5262
- `line_count`: 137
- `sha256`: 3144c7bf0d53c9c17d77b6040efc827d4e4ae778f87158b054009a0775f92f11
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5262 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token0/source-checks.log

- `kind`: log
- `size_bytes`: 3723
- `line_count`: 29
- `sha256`: 622aa536e149061ef533c99790e3b3e34bf7ea8e1eac4e01edf13a7706fd5860
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3723 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/activation.json

- `kind`: json
- `size_bytes`: 151
- `line_count`: 9
- `sha256`: 44401f76c78d4f559fa1c419e35be200d0e2264dae4a1d5e7125d21048579e4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=151 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "retry_wrong_token1", "schema_version": 1, "source_name": "OooIntBackend.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18015
- `line_count`: 119
- `sha256`: 9e2b1cdd273c63949854ab564ba062f4d15dc365e295bfa6c5b2236b9cd58208
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 6, "PASS": 14}
- `summary`: log evidence; size=18015 bytes; lines=119; FAIL=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/retry_wrong_token1/tb_ooo_int_backend.vvp /home/ly...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/make.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 3
- `sha256`: 42312c2402ec9d5710419f1168e0b19f504a39c019f9a71eedc31f056587f856
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=339 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/logs/tb_ooo_int_backend.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/mutator.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 1
- `sha256`: b52cfc129101198eb9469369de6f6013436ad2358f7e17f064393ded5db99727
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=213 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=retry_wrong_token1 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/OooIntBackend.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/retry_wrong_token1/OooIntBackend.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/source-checks.json

- `kind`: json
- `size_bytes`: 5324
- `line_count`: 137
- `sha256`: d888b142eecdda7540f1f82222148f4f95e98348833b76d7edcc6df5b828df5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5324 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/retry_wrong_token1/source-checks.log

- `kind`: log
- `size_bytes`: 3784
- `line_count`: 29
- `sha256`: 080239852fa794afc04ad0328fb6bf7f70c669be85f6503bbd01afe45f9ec55d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3784 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: 3db486769e1666444060f724ee72c6e82c97de9dd1656fb8879cceaffdd95db1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_age_equal0", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7294
- `line_count`: 63
- `sha256`: cf7679f7748449a74adf6a0a8b642854e5b13de97b3eec3dfaf95fead37c043e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7294 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_age_equal0/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mutan...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: d6abcf80e2b8c44ff36d8a3360b9b0188ffb28d1b54d394502d1fa873b6f275a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/logs/tb_ooo_store_queue.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/mutator.log

- `kind`: log
- `size_bytes`: 202
- `line_count`: 1
- `sha256`: f111d381f5d3b4444b1a07c9ff1f100abcbe94f0d80935aa4398c4278b3c3ad3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=202 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_age_equal0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_age_equal0/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 338b7c680efaa9d8c6c4b70a351a7efc6c61bc48125ef8d9577d5e155c3644e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_equal0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 0994ff35ecef829e99e73b57fbfd35423e95b908133aa4ff4781e05702e45850
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/activation.json

- `kind`: json
- `size_bytes`: 147
- `line_count`: 9
- `sha256`: c77d343784111066d5734c8900c2cf9310ca85d1abab97778d9d71e3326f39b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=147 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_age_linear0", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7406
- `line_count`: 64
- `sha256`: a74a6be8b5e881666f97aa65a1da9dfd730d8c2020008e0bc90a8ba352083d23
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 22}
- `summary`: log evidence; size=7406 bytes; lines=64; FAIL=10; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_age_linear0/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/muta...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/make.log

- `kind`: log
- `size_bytes`: 335
- `line_count`: 3
- `sha256`: 4b394c219a2a83da86a3cef57ca00fc1f5a1cb9944a909e05e14f6c6f368c3ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=335 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/logs/tb_ooo_store_queue.log] Err...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/mutator.log

- `kind`: log
- `size_bytes`: 204
- `line_count`: 1
- `sha256`: f7073a52f553eed12e565ecd0b905d49e366843538143cdca1860bdf4ea09be7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=204 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_age_linear0 source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_age_linear0/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 338b7c680efaa9d8c6c4b70a351a7efc6c61bc48125ef8d9577d5e155c3644e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_age_linear0/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 0994ff35ecef829e99e73b57fbfd35423e95b908133aa4ff4781e05702e45850
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/activation.json

- `kind`: json
- `size_bytes`: 146
- `line_count`: 9
- `sha256`: eaf42ea283866e20a217f2a0e4cb7be88e6f63debf06e75a5b29c91e0015b600
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=146 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 2 ], "mutation": "sq_compare_va", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 8297
- `line_count`: 75
- `sha256`: fa8c843b2e3c74ae3045149ad5c2697aa234ccc92f7c19c3b825c872940e9d8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 32, "PASS": 22}
- `summary`: log evidence; size=8297 bytes; lines=75; FAIL=32; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_compare_va/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mutan...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/make.log

- `kind`: log
- `size_bytes`: 334
- `line_count`: 3
- `sha256`: 78eaa248d0d9f263efa48b53f2f87a9a1b82c3b6935ec7dabbd14a7f5cb37e4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=334 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/logs/tb_ooo_store_queue.log] Erro...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/mutator.log

- `kind`: log
- `size_bytes`: 202
- `line_count`: 1
- `sha256`: 13f2af551567c46826cd799eb920285817df596265515d4ddbb7da8230511f4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=202 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_compare_va source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_compare_va/OooStoreQueue.v anchors=[2]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: bd0e2d96a594d89671ecc8a158e8d500646f266cbfbfe3cc718daa500f760878
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=0 va_assignments=2", "passed": false }, { "check_id": "sq.fail_closed_y...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_compare_va/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 05d64819c9b4a57cfb912ff1c786d1ec47b9315faf93d45c27ef4cf23df448bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][FAIL] sq.final_physical_byte_compare_only: paddr_assignments=0 va_assignments=2 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/activation.json

- `kind`: json
- `size_bytes`: 152
- `line_count`: 9
- `sha256`: 8892572a941ab84f60f47ba14382c8f8821646e49f8ece180094fa92d98f7c86
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=152 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 2 ], "mutation": "sq_include_terminal", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7251
- `line_count`: 61
- `sha256`: c142735a76ab592743ca0f3bb055503e6a845251a67014e2c00d86ba410f38ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7251 bytes; lines=61; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_include_terminal/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/make.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 3
- `sha256`: 2f261205b89fef3b6339e4ea80e6fcdf246cd2846bf4aeeb0199f01c44f838ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=340 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/logs/tb_ooo_store_queue.log...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/mutator.log

- `kind`: log
- `size_bytes`: 214
- `line_count`: 1
- `sha256`: a7553b2085645279b40869aeacffbee1416134b976535f00e29c01fc6172922b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=214 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_include_terminal source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_include_terminal/OooStoreQueue.v anchors=[2]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 9c795f6943468d3d91991117f6ad90ed0ab84c49716cbfc3ee354737d02ec52e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_include_terminal/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: d5cb8d0b6df01165fb6ceb0e14e7bcd8f672843a5320ff5dff86e840669aea24
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/activation.json

- `kind`: json
- `size_bytes`: 158
- `line_count`: 9
- `sha256`: 6275183237353567e09a9f22e1538791e842578a0cfb235d03a21e54bca9f7d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=158 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_invalid_metadata_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 8270
- `line_count`: 69
- `sha256`: cbdc2a8af27c579169814c8bf0b3127cae2c141da728e18b8ac77bb5c81844ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 20, "PASS": 22}
- `summary`: log evidence; size=8270 bytes; lines=69; FAIL=20; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_invalid_metadata_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/make.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 3
- `sha256`: 851c351213b3ebc7bfee55657275af3265ba3327197bb7ac916008f41705fb57
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=346 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/logs/tb_ooo_store_que...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/mutator.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 1
- `sha256`: 9c86acb74c59ab59fa52c3b0dfb22ddd0303f1e78299129a6867e09d19ee57eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_invalid_metadata_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_invalid_metadata_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: a435c78efa44dc9861249e2db83d02469f2bafe3e6c82c5c007abfda24ed6603
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_invalid_metadata_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 66de8a5a8911b8250c8ebc1b0c3347b0db7bb1bc2cfaa0c2aed745f3038c43aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/activation.json

- `kind`: json
- `size_bytes`: 144
- `line_count`: 9
- `sha256`: fc88ad8846e9d1e043b3bee05d3192c2a59a3c2a49cfc2a605ccf669fe75b938
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=144 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_io_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7046
- `line_count`: 62
- `sha256`: 62282e9a91fcfd73ace01020a75b8aa4d9918d79a8efb996d425a1ce456af51f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7046 bytes; lines=62; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_io_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mutants...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/make.log

- `kind`: log
- `size_bytes`: 332
- `line_count`: 3
- `sha256`: fa98bbcab94050851b01b5c10d34606a425813967254dbe3f4defc99239efae0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=332 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/logs/tb_ooo_store_queue.log] Error...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/mutator.log

- `kind`: log
- `size_bytes`: 198
- `line_count`: 1
- `sha256`: 32d3f69f830ee2c11295fce9a0649271c265369ede1b598d68cef0024ca1f3fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=198 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_io_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_io_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 963498ec9f89698858346acca0c114fcaaf6748f39c4282454066e05bfc90a87
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_io_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: bd4c2c697da705033c928e5696f261af8ca795bca2d8c4d01e1ee80f1551ff65
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/activation.json

- `kind`: json
- `size_bytes`: 152
- `line_count`: 9
- `sha256`: 4822597bac82ba90cc4fd66ca1f0af60244c7a3c0028dfb78cb2f5d9db28cd09
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=152 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_oldest_byte_wins", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7552
- `line_count`: 63
- `sha256`: bf65f86f2b9e2e06a304de039e677d4d89e380e756d04957e48d6684f416592a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7552 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_oldest_byte_wins/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/make.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 3
- `sha256`: e558054260c6d9ad25b7dadf1fd3b63d34f98c4e91b7fad3f81c4dc4b197cbad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=340 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/logs/tb_ooo_store_queue.log...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/mutator.log

- `kind`: log
- `size_bytes`: 214
- `line_count`: 1
- `sha256`: 73ec4bd4501bbadccb6e042a8ae4c1ea5a1aee329db57b2864aaa31f1957159b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=214 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_oldest_byte_wins source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_oldest_byte_wins/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 8f79f499c9f028e934c8bfd609eb8a2b81d7c3bb4500e3330e19e53bf1c68500
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_oldest_byte_wins/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 2ca07f99a9d1c3fff535755845ec054ce7847c80f0dbe2b76e0688861ed3b970
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/activation.json

- `kind`: json
- `size_bytes`: 149
- `line_count`: 9
- `sha256`: cc0aad14c6200afb05a322689247a4ba8ab5a5da5eea3aed9245a4511b93f475
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=149 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_partial_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7411
- `line_count`: 63
- `sha256`: 30c2421d54af6e0428bfc1fa2bc3b9d1994b30077891d82d5c5556edc4f69459
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7411 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_partial_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/mu...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/make.log

- `kind`: log
- `size_bytes`: 337
- `line_count`: 3
- `sha256`: 1641ce5b016a442c9461a1329328e1f0cf2f9d05ecf981ee72942053838d55e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=337 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/logs/tb_ooo_store_queue.log] E...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/mutator.log

- `kind`: log
- `size_bytes`: 208
- `line_count`: 1
- `sha256`: 57f520223ffe6c40ae84ac5f718657ffe664261033aa82d55e86f3d30e0ad2e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_partial_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_partial_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5218
- `line_count`: 137
- `sha256`: 41b94c8ece0f9d1f429d9a06d1ea1da6afeff8e82f1532ad1a94e839f04b327b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5218 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_partial_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: bf10e1acb5ba566a32f52ceeef4ee272887f69a25059695823275f20ae8bd5c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 4, "PASS": 48}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=4; PASS=48; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/activation.json

- `kind`: json
- `size_bytes`: 154
- `line_count`: 9
- `sha256`: b152c8ad1b203070531ca8858772c57ef998467f2ba55610428a99345b9f405b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=154 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_query1_paddr_cross", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7708
- `line_count`: 64
- `sha256`: ecc78b54496d3e8462e97a5fb7e88785ae31a631278d411b568869aca06d4a96
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 10, "PASS": 22}
- `summary`: log evidence; size=7708 bytes; lines=64; FAIL=10; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_query1_paddr_cross/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOt...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/make.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 3
- `sha256`: 98b3bf2145c12398c7691887990f7a68babe9f382af97b9a15c659a7e0548e5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/logs/tb_ooo_store_queue.l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/mutator.log

- `kind`: log
- `size_bytes`: 218
- `line_count`: 1
- `sha256`: c7810e41a90a379d89c0a1f4aadba3a56e6be4ac22ee37bca18d212296de4593
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=218 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_query1_paddr_cross source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_query1_paddr_cross/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 043e3651839b4601ccd90fdff011bdb70fb04563b84a4c59434fdb8ce4a1b375
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_paddr_cross/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 6eab3e15ce24d9cd5e8e4b1d24fc71612161bf21571448ab7fa0d54d33584464
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/activation.json

- `kind`: json
- `size_bytes`: 155
- `line_count`: 9
- `sha256`: 8d8559a6df8f1e8df7d53587b89ca6a99317c1d970f9d33671c6e57c52e76f41
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=155 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 1 ], "mutation": "sq_query1_poison_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 7666
- `line_count`: 63
- `sha256`: 511bd4990457637f6fb0220b98c3daeb00a7adbeb266c2f1cae71ed08ebc887d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 8, "PASS": 22}
- `summary`: log evidence; size=7666 bytes; lines=63; FAIL=8; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_query1_poison_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAO...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/make.log

- `kind`: log
- `size_bytes`: 343
- `line_count`: 3
- `sha256`: 314c89316f1e614150e91481471cccc505a8d796cd02b590f4ddd8d6e5127d86
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=343 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/logs/tb_ooo_store_queue....

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/mutator.log

- `kind`: log
- `size_bytes`: 220
- `line_count`: 1
- `sha256`: 164d57948c5beb72ef36262c96cb77849fe024d33987728edc364994c68394b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=220 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_query1_poison_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_query1_poison_allow/OooStoreQueue.v anchors=[1]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: 52e8d37741d584accfdaefd32ca3daa7b9a4b56e0713d6b8ae2c954d748621c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_query1_poison_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: 7b1c305e8df7b30aa9c4fb914d382e6e3566ffdcc699375afc740245472976bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/activation.json

- `kind`: json
- `size_bytes`: 150
- `line_count`: 9
- `sha256`: 5c3725f6bda5d11a9f968fb7a0086e78c3fd32d7a03553020f3c661337d850fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=150 bytes; lines=9; markers=<none>; tail={ "activated": true, "anchor_counts": [ 2 ], "mutation": "sq_unfilled_allow", "schema_version": 1, "source_name": "OooStoreQueue.v" }

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6463
- `line_count`: 57
- `sha256`: 9be5ea5a77b0c1aa923391fef896ef694fc507da4f2a9edd15a3d17d6af5a997
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 12, "PASS": 22}
- `summary`: log evidence; size=6463 bytes; lines=57; FAIL=12; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/mutant-builds/sq_unfilled_allow/tb_ooo_store_queue.vvp /tmp/v8t-final-pa-sq-query.RAOtT9/m...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/make.log

- `kind`: log
- `size_bytes`: 338
- `line_count`: 3
- `sha256`: 3b130006f14fcf08e05865d566399cfade1f557d1d36c7d46e95feff51407d26
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=338 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/logs/tb_ooo_store_queue.log]...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/mutator.log

- `kind`: log
- `size_bytes`: 210
- `line_count`: 1
- `sha256`: 959ea82b087ca87f6fd3ce55c399a261700679af86d8f1cb23de9e7ad583df93
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=210 bytes; lines=1; PASS=2; tail=[V8T-MUTATOR][PASS] name=sq_unfilled_allow source=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue.v output=/tmp/v8t-final-pa-sq-query.RAOtT9/mutants/sq_unfilled_allow/OooStoreQueue.v anchors=[2]

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/source-checks.json

- `kind`: json
- `size_bytes`: 5217
- `line_count`: 137
- `sha256`: e713a938dce317d541bf8de965e2881b2ae4952444fa5c21c7d14684fcef67e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5217 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/mutations/sq_unfilled_allow/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: d4f65cc37872c2af4b27141b3219663006f4d94ebd19bbb485fe934ca8813fc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 50}
- `summary`: log evidence; size=3678 bytes; lines=29; FAIL=2; PASS=50; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][FAIL] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/predecessors/f0.log

- `kind`: log
- `size_bytes`: 268
- `line_count`: 3
- `sha256`: 3f299d71dff1729a85f664d5e878d611cc68fb430c0ee234693d6291bc5a6af6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=268 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8Q-F0][PASS] run_id=v8q-f0-20260720T133443Z-1185415 claim=dual_axi_miss_fabric_leaf_verified mutations=12 architecture=RED ppa=UNQUALIFIED make: Leaving directory '/home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/predecessors/f1.log

- `kind`: log
- `size_bytes`: 329
- `line_count`: 3
- `sha256`: 1fa7b397807283b670f082b5a7dcaa72a334996fb86b6386527a7dbd5ae57970
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=329 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8R-F1][PASS] run_id=v8r-f1-20260720T133445Z-1186307 claim=dual_bridge_cache_hit_leaf_verified mutations=10 architecture=RED ppa=UNQUALIFIED canonical_stage=F2_PROMOTED canonical_core_integrat...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/predecessors/f2.log

- `kind`: log
- `size_bytes`: 313
- `line_count`: 3
- `sha256`: 92f8866ca6e549fbd23d72137cbea964173720325773dbebf70635a340611941
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=313 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8S-F2][PASS] run_id=v8s-f2-20260720T133454Z-1188408 claim=architecture_checkpoint profiles=6 mutations=11 predecessor=F1_PASS architecture=RED ppa=UNQUALIFIED promotion_eligible=false make: L...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profile-summary.log

- `kind`: log
- `size_bytes`: 1823
- `line_count`: 11
- `sha256`: ba4854ae2697418f53837e0c9a507319f6479b27814a91b15e5808646248007f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=1823 bytes; lines=11; PASS=22; tail=[V8T-PROFILE][PASS] run_id=v8t-f3-20260720T133351Z-1183319 profile=sq-release image_sha256=fc09bdaed60c9f3839c060a98803d67041beae6fc1cffd6bbf850dbfffa02e5f [V8T-PROFILE][PASS] run_id=v8t-f3-20260720T133351Z-1183319 profile=sq-assert image_sha256=81ae998a4f3...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/backend-dual-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/backend-dual-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 18078
- `line_count`: 116
- `sha256`: 63f05043a29b589e8578def8019338d3d5b1bb76ee0abdb7697396a7d41e7095
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=18078 bytes; lines=116; PASS=20; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/backend-dual-assert/tb_ooo_int_backend.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/backend-dual-release.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/backend-dual-release/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 17255
- `line_count`: 110
- `sha256`: 0e17dfd895652d79b6d57b4ed2ee6f3f8a3026dfc30863ae597625b724529cb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=17255 bytes; lines=110; PASS=20; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8S_DUAL_MEMORY_FOCUSED -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/backend-dual-release/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/backend-legacy-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/backend-legacy-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 22837
- `line_count`: 197
- `sha256`: 20420c0687c35905908eba62423acf32ef0a3fd3596c1af1d8b96fda7656e425
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"ERROR": 2, "PASS": 94}
- `summary`: log evidence; size=22837 bytes; lines=197; ERROR=2; PASS=94; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/backend-legacy-assert/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/bridge-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/bridge-assert/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71335
- `line_count`: 548
- `sha256`: 91e436d7b67c0363dc7f08260d4373474cf61cab6b096dcc448ff2506e9f13e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 19}
- `summary`: log evidence; size=71335 bytes; lines=548; PASS=19; tail=x-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/bridge-release.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/bridge-release/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71324
- `line_count`: 548
- `sha256`: f1ae7a42b02d8600af2eb648b880fc564977b2075921bab89a4dd8c70c6964eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 19}
- `summary`: log evidence; size=71324 bytes; lines=548; PASS=19; tail=x-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/l...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/core-glue-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/core-glue-assert/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 21476
- `line_count`: 111
- `sha256`: a56a2036ccfafacedf0a1f5ee55127748d1c7265fc07a3b43ad7a93c976c67b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=21476 bytes; lines=111; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/core-glue-assert/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/priv-system-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/priv-system-assert/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 21269
- `line_count`: 106
- `sha256`: 9d0c7d44ae058a394bf36eb27b338f08613892bfc6cfd7648d3a267d17c72955
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=21269 bytes; lines=106; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/priv-system-assert/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-assert/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6698
- `line_count`: 57
- `sha256`: 366cc6d224c24bb1755c69a413df46489c91c968b5cbd52dadde6db3ea5c5f28
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=6698 bytes; lines=57; PASS=24; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/sq-assert/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/O...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-release.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-release/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 5876
- `line_count`: 51
- `sha256`: 27241f73295c0fda35a8b2786e0af38dfec80df5890fb92044cc91d90d8357dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=5876 bytes; lines=51; PASS=24; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/sq-release/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-x-metadata-assert.make.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 3
- `sha256`: afdcdf0d79a0b598eb34ce3753710ae6b9282143ab643b588cbf9f788e2bf9ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=340 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:308: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-x-metadata-assert/logs/tb_ooo_store_queue.log...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sq-x-metadata-assert/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6943
- `line_count`: 60
- `sha256`: e8d7140609c10633db4916fa8ad6b86d1f6d1cbd6bfabf8125cb1a4015280263
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"FAIL": 2, "PASS": 22}
- `summary`: log evidence; size=6943 bytes; lines=60; FAIL=2; PASS=22; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8T_X_FAULT_INJECTION -s tb_ooo_store_queue -o /tmp/v8t-final-pa-sq-query.RAOtT9/builds/sq-x-metadata-assert/tb_ooo_store_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sv39-boot-assert.make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/profiles/sv39-boot-assert/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 282894
- `line_count`: 2073
- `sha256`: 03ea16d6c895c74b3819c67637fbf836ed194fbc9fcb484fbe134761f61b2924
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=282894 bytes; lines=2073; PASS=2; tail=_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in arra...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/result.json

- `kind`: json
- `size_bytes`: 20835
- `line_count`: 506
- `sha256`: 030047748ddb9b75bb18e8be2cc164bbc576752d038682c8109c342ee40b8a0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 22}
- `summary`: json evidence; size=20835 bytes; lines=506; PASS=22; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "checkpoint_eligible": false, "claim": "final_pa_sq_ordering_candidate", "coverage_mode": "contract_p0_implementation_closure", "full_c...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/run-id.txt

- `kind`: txt
- `size_bytes`: 32
- `line_count`: 1
- `sha256`: 853d7e5fe18efb4780536dccf25086e2b8e6148bc47dd1a6f02fe5bc5288a3dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: txt evidence; size=32 bytes; lines=1; markers=<none>; tail=v8t-f3-20260720T133351Z-1183319

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 5928
- `line_count`: 39
- `sha256`: 0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=5928 bytes; lines=39; markers=<none>; tail=3773d6ba9bd468ed53aa441dfc225bd57fc1e21384be3c75ac0dfe3016686adc /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/contract.md 5f2b3a7e0691e690e51f2f85ef3184d6324d386fddb32cf63613b2eb3c84c605 /home/lyg/PA/ysyx-workbench/.gi...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 5928
- `line_count`: 39
- `sha256`: 0be0d3ee3424ee816fe11d0176f2fc5e71849e24bedb764025f4e2dcc8212063
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=5928 bytes; lines=39; markers=<none>; tail=3773d6ba9bd468ed53aa441dfc225bd57fc1e21384be3c75ac0dfe3016686adc /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/contract.md 5f2b3a7e0691e690e51f2f85ef3184d6324d386fddb32cf63613b2eb3c84c605 /home/lyg/PA/ysyx-workbench/.gi...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 53133
- `line_count`: 1219
- `sha256`: b2f500274dac4d49c92d3aa641b2c870c785f6ff0b33a9b0a59f9bf9c72c0aa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=53133 bytes; lines=1219; PASS=16; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 11
- `sha256`: b89815b128e2d78856eff3d892acfc0601ef68dc3a391dc31b7fbe6623bff8e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=390 bytes; lines=11; markers=<none>; tail=DI-1: RED (7 red checks) DI-2: RED (18 red checks) DI-3: RED (6 red checks) DI-4: RED (3 red checks) DI-5: RED (15 red checks) OOO-1: RED (3 red checks) OOO-2: RED (3 red checks) OOO-3: RED (14 red checks) OOO-4: RED (9 red checks) OVERALL: RED RESULT: /hom...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/checker-unit.log

- `kind`: log
- `size_bytes`: 2678
- `line_count`: 28
- `sha256`: de1f7c065abd365157c34119706a39c9ef9ae1d56aa755d3ff3d10e6f771cef8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=2678 bytes; lines=28; markers=<none>; tail=test_baseline_all_checks_pass (__main__.CheckerTests.test_baseline_all_checks_pass) ... ok test_bridge_active_load_fence_removal_is_rejected (__main__.CheckerTests.test_bridge_active_load_fence_removal_is_rejected) ... ok test_claim_inflation_is_rejected (_...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/checkpoint-finalizer-unit.log

- `kind`: log
- `size_bytes`: 884
- `line_count`: 12
- `sha256`: b5210100a7c222dcdea02dbecd1cb6a86b36fd7d0a7918c29273d8c390f94da6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=884 bytes; lines=12; markers=<none>; tail=test_candidate_result_tamper_is_rejected (__main__.FinalizeV8tTest.test_candidate_result_tamper_is_rejected) ... ok test_candidate_run_mismatch_is_rejected (__main__.FinalizeV8tTest.test_candidate_run_mismatch_is_rejected) ... ok test_claim_boundary_inflati...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/contract.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 9
- `sha256`: d2f0b52181f0745adf3f4b1b6e0db3bf236a692fa237a2d1392e9cc38bded200
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=9; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 10 tests in 2.806s OK [PRODUCER-HOLDER-CENSUS] PASS direct=18 packed=5 token_q=15 generation=1 契约立即断言（$error）计数：当前=436...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/mutator-unit.log

- `kind`: log
- `size_bytes`: 342
- `line_count`: 7
- `sha256`: 4428b93569b09f86fcea5920550e5140aea7b39f07aaffe0299875c6e779e116
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=342 bytes; lines=7; markers=<none>; tail=test_all_mutations_have_exact_live_anchors (__main__.MutatorTests.test_all_mutations_have_exact_live_anchors) ... ok test_mutations_are_bounded_to_known_rtl_sources (__main__.MutatorTests.test_mutations_are_bounded_to_known_rtl_sources) ... ok -------------...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/npc-core-assert-lint.log

- `kind`: log
- `size_bytes`: 64842
- `line_count`: 718
- `sha256`: e4f9d22439b42e1ba6e0714af79e13b1209e12f39f5661d2cc2d1c536253596c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=64842 bytes; lines=718; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/npc-core-release-lint.log

- `kind`: log
- `size_bytes`: 63280
- `line_count`: 702
- `sha256`: ddcc6693fafc21da343e432c55507cb7d23aea38d63d74cb9e8bf49b2a890250
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=63280 bytes; lines=702; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -Wno-fatal --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include --top-m...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/retry-holder-proof-unit.log

- `kind`: log
- `size_bytes`: 691
- `line_count`: 10
- `sha256`: 1b49d09b40b68e21a1793fa8b3af33970f72891191c077203dc4c48ef2575b8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: log evidence; size=691 bytes; lines=10; markers=<none>; tail=test_atomic_repush_deletion_is_rejected (__main__.RetryHolderProofBindingTests.test_atomic_repush_deletion_is_rejected) ... ok test_baseline_passes (__main__.RetryHolderProofBindingTests.test_baseline_passes) ... ok test_cancel_priority_deletion_is_rejected...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/retry-holder-proof.json

- `kind`: json
- `size_bytes`: 2065
- `line_count`: 68
- `sha256`: 79291ae3cfc9ffbe80e6a1edf881bae5e3833d821f235528047cef7968d95bf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=2065 bytes; lines=68; markers=<none>; tail={ "bounded_liveness_depth": 6, "checks": [ { "check_id": "source.two_complete_holder_payloads", "detail": "missing=[]", "passed": true }, { "check_id": "source.cancel_or_fire_precedes_capture", "detail": "counts={'bank0': 1, 'bank1': 1}", "passed": true },...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/retry-holder-proof.log

- `kind`: log
- `size_bytes`: 1123
- `line_count`: 11
- `sha256`: cc916611299adc69b102b0efc82258083bf68d5437171d9fda875a92d0d62f04
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=1123 bytes; lines=11; PASS=22; tail=[V8T-RETRY-PROOF][PASS] source.two_complete_holder_payloads: missing=[] [V8T-RETRY-PROOF][PASS] source.cancel_or_fire_precedes_capture: counts={'bank0': 1, 'bank1': 1} [V8T-RETRY-PROOF][PASS] source.capture_payload_exact: field_assignments={'bank0': 13, 'ba...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/source-checks.json

- `kind`: json
- `size_bytes`: 5215
- `line_count`: 137
- `sha256`: a0c6e9b3f9a562583b6a0de179abb23d5a6e9cfd344d8808f3d463555ca6ef5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {}
- `summary`: json evidence; size=5215 bytes; lines=137; markers=<none>; tail={ "checks": [ { "check_id": "sq.two_independent_query_faces", "detail": "missing=[]", "passed": true }, { "check_id": "sq.final_physical_byte_compare_only", "detail": "paddr_assignments=2 va_assignments=0", "passed": true }, { "check_id": "sq.fail_closed_yo...

### .github/task-runs/2026-07-20-rv64-v8t-final-pa-sq-query/evidence/focused/static/source-checks.log

- `kind`: log
- `size_bytes`: 3678
- `line_count`: 29
- `sha256`: a6724f02dc55c32333b92661d69ea7f35bc6db4a430935b1b40fc623fdb50a3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T13:54:43+00:00
- `markers`: {"PASS": 52}
- `summary`: log evidence; size=3678 bytes; lines=29; PASS=52; tail=[V8T-CHECK][PASS] sq.two_independent_query_faces: missing=[] [V8T-CHECK][PASS] sq.final_physical_byte_compare_only: paddr_assignments=2 va_assignments=0 [V8T-CHECK][PASS] sq.fail_closed_youngest_merge_semantics: counts={'head_tail': 2, 'terminal_exclusion':...
