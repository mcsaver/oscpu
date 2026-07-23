# Evidence Index

## 基本信息

- `task_id`: 2026-07-20-rv64-v8r-dual-memory-bridge-wrapper
- `task_slug`: `rv64-dual-memory-bridge-cache-hit-leaf-revtag-v8r`
- `profile`: 
- `asset_count`: 66
- `total_size_bytes`: 1879694

## 证据资产

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/architecture-manifest.post.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/architecture-manifest.pre.sha256

- `kind`: sha256
- `size_bytes`: 147
- `line_count`: 1
- `sha256`: afc5bd04c0e09b0fca0d6649adfbf4a63ed9905f44d92672281a7170ac7b1b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=147 bytes; lines=1; markers=<none>; tail=506e2b897be8d28c0445f5b842daafdaef82408842f8ae0d19a11313b85787f7 /home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evidence/architecture-current.json

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/final.log

- `kind`: log
- `size_bytes`: 174
- `line_count`: 1
- `sha256`: 22f9d5d29a695dec6fe9ede33c4601465e1760408ccc66883944da33b02c1fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=174 bytes; lines=1; PASS=2; tail=[V8R-F1][PASS] run_id=v8r-f1-20260720T052716Z-935556 claim=dual_bridge_cache_hit_leaf_verified mutations=10 architecture=RED ppa=UNQUALIFIED canonical_core_integration=false

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutation-summary.log

- `kind`: log
- `size_bytes`: 3149
- `line_count`: 10
- `sha256`: c48835a773b05143e40c4ce245275a57805937e51348399b1be458d6cc22b50d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=3149 bytes; lines=10; PASS=20; tail=[V8R-MUTATION][PASS] run_id=v8r-f1-20260720T052716Z-935556 name=disconnect_peer_valid compile_success=true elaborated=true activated=true target_rejected=true source_sha256=3d8ef7b0e8808f7c2a7e7ce3569ea9f36379df76896902698567bfb1a37298f6 image_sha256=e51725...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/b_ok_only_peer.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/b_ok_only_peer.mutator.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 1
- `sha256`: fabf7af5de4b9e7136741cfa352739972b91c3518b23bbe6d220864b1f7a88ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=367 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:b_ok_only_peer", "anchor_count": 1, "expected_rejection": "V8R-MUT-B-OK-ONLY-PEER", "mutant_sha256": "e894f39b80c2db5aed20759d270ebf80eeca68b0bebac125563b27f1fecf2dbc", "mutation": "b_ok_only_peer", "source_sha256": "e78cbdf52...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/b_ok_only_peer.run.log

- `kind`: log
- `size_bytes`: 277
- `line_count`: 4
- `sha256`: 41a651cceaea386523d945cb1bb3c8e6d5293a654928b0c29fc50115275365e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=277 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:b_ok_only_peer] [V8R-MUT-B-OK-ONLY-PEER] B-error terminal failed to invalidate peer alias FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 68 Scope: tb_ooo_dual_mem_bridge_wrapper.mutat...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/disconnect_peer_valid.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/disconnect_peer_valid.mutator.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 1
- `sha256`: 41907a99345381b07d3dcd3fc26f2de1e834540ccc6e5938d1e503dd8ef612ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=396 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:disconnect_peer_valid", "anchor_count": 1, "expected_rejection": "V8R-MUT-DISCONNECT-PEER-VALID", "mutant_sha256": "3d8ef7b0e8808f7c2a7e7ce3569ea9f36379df76896902698567bfb1a37298f6", "mutation": "disconnect_peer_valid", "sourc...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/disconnect_peer_valid.run.log

- `kind`: log
- `size_bytes`: 297
- `line_count`: 4
- `sha256`: d8cb7c7966054a4e22d8f33dd5dcc7449f69da13b2c33ee701c6740607b9ddba
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=297 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:disconnect_peer_valid] [V8R-MUT-DISCONNECT-PEER-VALID] peer lookup exposed a stale hit on producer B terminal FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 64 Scope: tb_ooo_dual_mem_...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/drop_cross_line_peer.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/drop_cross_line_peer.mutator.log

- `kind`: log
- `size_bytes`: 385
- `line_count`: 1
- `sha256`: 745477048731457b7f1993b00f306311780534f050107ee671c675d2347f9d70
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=385 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:drop_cross_line_peer", "anchor_count": 1, "expected_rejection": "V8R-MUT-DROP-CROSS-LINE-PEER", "mutant_sha256": "4e2b12a63d06099d74fc4a8da145f2d320423b07f01a1dc1ef9d26e6bea6e5c4", "mutation": "drop_cross_line_peer", "source_s...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/drop_cross_line_peer.run.log

- `kind`: log
- `size_bytes`: 284
- `line_count`: 4
- `sha256`: bdc3f967ae5f9237994fd8413e0ec34c3849ad62eaa971f775fc444562953c7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=284 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:drop_cross_line_peer] [V8R-MUT-DROP-CROSS-LINE-PEER] cross-line peer maintenance left p1 visible FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 68 Scope: tb_ooo_dual_mem_bridge_wrappe...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/fill_wins_peer.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/fill_wins_peer.mutator.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 1
- `sha256`: 3d385c5b9b861cee37fac473f636f1eb931d0cc34074aa1201ceb54063d64c4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=367 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:fill_wins_peer", "anchor_count": 1, "expected_rejection": "V8R-MUT-FILL-WINS-PEER", "mutant_sha256": "464864c710b2398721fb044b726cffcb3f7c9465a1562586c1e6264c2aea8a0a", "mutation": "fill_wins_peer", "source_sha256": "50ee1121c...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/fill_wins_peer.run.log

- `kind`: log
- `size_bytes`: 239
- `line_count`: 4
- `sha256`: f159154aab4708eafc547800ece9b07e12b3369f3f0a11c72e45c0c1fb8fc766
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=239 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:fill_wins_peer] [V8R-MUT-FILL-WINS-PEER] same-index fill revived peer-cleared valid FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_data_word_cache.sv:620: Time: 10 Scope: tb_ooo_data_word_cache

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/gate_lane1_ready_on_arbiter_idle.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/gate_lane1_ready_on_arbiter_idle.mutator.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 1
- `sha256`: 964c60a5be5982f33b0f5cae379bba61a999ec14f46cfd864eee935d25150196
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=413 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:gate_lane1_ready_on_arbiter_idle", "anchor_count": 1, "expected_rejection": "V8R-MUT-GATE-LANE1-READY", "mutant_sha256": "132e07185c17d0a0607acb9093c78b2abc1ddf0dc1b2966d06097697b6f78138", "mutation": "gate_lane1_ready_on_arbi...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/gate_lane1_ready_on_arbiter_idle.run.log

- `kind`: log
- `size_bytes`: 295
- `line_count`: 4
- `sha256`: 60e5601dac9d73f9304f3351713f172c3ec2562c2a9d3d9e0e0283752f2c86ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=295 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:gate_lane1_ready_on_arbiter_idle] [V8R-MUT-GATE-LANE1-READY] lane1 hot admission was gated by F0 miss owner FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 40 Scope: tb_ooo_dual_mem_br...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/merge_dual_response.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/merge_dual_response.mutator.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 1
- `sha256`: 89714d0d6afc826fe58109e5a97e222d02b68faab799f43c0e1440c10246fbb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=390 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:merge_dual_response", "anchor_count": 1, "expected_rejection": "V8R-MUT-MERGE-DUAL-RESPONSE", "mutant_sha256": "fc4d901b2bf2d488e45ab957a60d7e18541e25ae586377b974df9df46b8c049a", "mutation": "merge_dual_response", "source_sha2...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/merge_dual_response.run.log

- `kind`: log
- `size_bytes`: 284
- `line_count`: 4
- `sha256`: cbc7cce47f957f27a824e07a3755ba59cf7bda095b414cd26b4b9f0c50babd11
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=284 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:merge_dual_response] [V8R-MUT-MERGE-DUAL-RESPONSE] simultaneous lane-local responses were merged FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 53 Scope: tb_ooo_dual_mem_bridge_wrappe...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/remove_same_cycle_hit_block.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/remove_same_cycle_hit_block.mutator.log

- `kind`: log
- `size_bytes`: 406
- `line_count`: 1
- `sha256`: 8c5b74c0fe362d4472c3e7690cbbd3b202e421160a466fb3a1c266972dfb653f
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=406 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:remove_same_cycle_hit_block", "anchor_count": 1, "expected_rejection": "V8R-MUT-REMOVE-SAME-CYCLE-HIT-BLOCK", "mutant_sha256": "449da970fc940b73984144fc0f2873ec5c69060c4b4fb74d75e6bea738ae34be", "mutation": "remove_same_cycle_...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/remove_same_cycle_hit_block.run.log

- `kind`: log
- `size_bytes`: 309
- `line_count`: 4
- `sha256`: 56fe23ffac9b5661fd01b6a111b1ebc46e1e4da8a9a4e3a1d8f5b39a4f30b10c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=309 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:remove_same_cycle_hit_block] [V8R-MUT-REMOVE-SAME-CYCLE-HIT-BLOCK] peer lookup exposed a stale hit on producer B terminal FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 64 Scope: tb_o...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/request_time_maintenance.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/request_time_maintenance.mutator.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 1
- `sha256`: 6e8e29e780bdb1ef890f673b387df5fd5485f546cafa06bc6f53abf799214b1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=397 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:request_time_maintenance", "anchor_count": 1, "expected_rejection": "V8R-MUT-REQUEST-TIME-MAINTENANCE", "mutant_sha256": "cf7856eae13a250fff09b6048e444e40f8dbf178d43c841124ae21db6f42c154", "mutation": "request_time_maintenance...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/request_time_maintenance.run.log

- `kind`: log
- `size_bytes`: 299
- `line_count`: 4
- `sha256`: 2ecbacf8d7ee5eca7b4eaa64e584c9362fe8169c4473fae97a80541adcdd0884
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=299 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:request_time_maintenance] [V8R-MUT-REQUEST-TIME-MAINTENANCE] request-time maintenance invalidated peer before B FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 57 Scope: tb_ooo_dual_me...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/self_only_peer.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/self_only_peer.mutator.log

- `kind`: log
- `size_bytes`: 375
- `line_count`: 1
- `sha256`: 1f3254a5ae7becd8c12cc9ebdbfe69f746bf5807b21e86d8e448d463cc1a3abf
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=375 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:self_only_peer", "anchor_count": 1, "expected_rejection": "V8R-MUT-SELF-ONLY-PEER", "mutant_sha256": "359cc7e6085ae36939f5d1a6ad639aac3ad16007818402d6659a77ed5e99924d", "mutation": "self_only_peer", "source_sha256": "a92661bf8...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/self_only_peer.run.log

- `kind`: log
- `size_bytes`: 283
- `line_count`: 4
- `sha256`: bb14e14ef3391412bbb5dbd4dfac41354ea2bc45c157400de5b35924e0d1c646
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=283 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:self_only_peer] [V8R-MUT-SELF-ONLY-PEER] peer lookup exposed a stale hit on producer B terminal FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 64 Scope: tb_ooo_dual_mem_bridge_wrapper...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/swap_peer_addr.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/swap_peer_addr.mutator.log

- `kind`: log
- `size_bytes`: 375
- `line_count`: 1
- `sha256`: ce4ed8d1e0ca2fdf613bbedc723f8ed3fb023a028239c01dd30216ed18ee9a46
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=375 bytes; lines=1; markers=<none>; tail={"activation": "V8R-MUT-ACTIVE:swap_peer_addr", "anchor_count": 1, "expected_rejection": "V8R-MUT-SWAP-PEER-ADDR", "mutant_sha256": "90e11814ac68b1970ab2ae866de2a86eff85bf8926b1dd3f0bc01ca7e895ea9c", "mutation": "swap_peer_addr", "source_sha256": "a92661bf8...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/mutations/swap_peer_addr.run.log

- `kind`: log
- `size_bytes`: 283
- `line_count`: 4
- `sha256`: 236de7e7a4257595baeb071d0ec9539371214dc70e769a1e7ff0d407a4803035
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=283 bytes; lines=4; markers=<none>; tail=[V8R-MUT-ACTIVE:swap_peer_addr] [V8R-MUT-SWAP-PEER-ADDR] peer lookup exposed a stale hit on producer B terminal FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_ooo_dual_mem_bridge_wrapper.sv:308: Time: 64 Scope: tb_ooo_dual_mem_bridge_wrapper...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profile-summary.log

- `kind`: log
- `size_bytes`: 1207
- `line_count`: 8
- `sha256`: 2420207d135cecb32db49d3db782441515b94e1bf7ed15b8d2d556234a3fa9f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=1207 bytes; lines=8; PASS=16; tail=[V8R-PROFILE][PASS] run_id=v8r-f1-20260720T052716Z-935556 profile=wrapper-release image_sha256=8c9f97c446ae382f9510aae6c45677869d21fe845ebb1003d01ef6054163088c [V8R-PROFILE][PASS] run_id=v8r-f1-20260720T052716Z-935556 profile=wrapper-assert image_sha256=865...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/bridge-assert.compile.log

- `kind`: log
- `size_bytes`: 68584
- `line_count`: 516
- `sha256`: 0efa428a66320f02df6340342ee2c1e19cf1702eebd536bb7740fd52e0a789ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=68584 bytes; lines=516; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/bridge-assert.run.log

- `kind`: log
- `size_bytes`: 1820
- `line_count`: 27
- `sha256`: 647a9ce8dd9ff9e7eef779b1851b92c000dc1e36e74d7b5e878b4314f2678528
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 32}
- `summary`: log evidence; size=1820 bytes; lines=27; PASS=32; tail=[R4-S0-POSTXLATE-CLASS] 2x2x4 matrix + inactive/default PASS [T4E-MEM-AR-HOLD] data+walk valid/payload held; repeated-flush+ready drained [S1-DCACHE-NO-PREVIEW-PMP] hot-line potential, lookup_en=0 access_fault=1 [S1-DCACHE-NO-PREVIEW-DTLB-PERM] hot-line pot...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/bridge-release.compile.log

- `kind`: log
- `size_bytes`: 68584
- `line_count`: 516
- `sha256`: 0efa428a66320f02df6340342ee2c1e19cf1702eebd536bb7740fd52e0a789ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=68584 bytes; lines=516; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/bridge-release.run.log

- `kind`: log
- `size_bytes`: 1820
- `line_count`: 27
- `sha256`: 647a9ce8dd9ff9e7eef779b1851b92c000dc1e36e74d7b5e878b4314f2678528
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 32}
- `summary`: log evidence; size=1820 bytes; lines=27; PASS=32; tail=[R4-S0-POSTXLATE-CLASS] 2x2x4 matrix + inactive/default PASS [T4E-MEM-AR-HOLD] data+walk valid/payload held; repeated-flush+ready drained [S1-DCACHE-NO-PREVIEW-PMP] hot-line potential, lookup_en=0 access_fault=1 [S1-DCACHE-NO-PREVIEW-DTLB-PERM] hot-line pot...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/dcache-assert.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/dcache-assert.run.log

- `kind`: log
- `size_bytes`: 129
- `line_count`: 2
- `sha256`: 6a8166772b739592ae2e227b77822c154f202e002d0733a89cbfb3362edb9284
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=129 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_data_word_cache /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 827 (1s)

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/dcache-invalid-mask.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/dcache-invalid-mask.run.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 6
- `sha256`: bf948f00dafea027626e89c096513d9c026244ae66287b32c8705225475a6780
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"ERROR": 4}
- `summary`: log evidence; size=610 bytes; lines=6; ERROR=4; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooDataWordCacheChecker.sv:213: [DWC-PEER-WSTRB] peer maintenance mask is not normalized: addr=0000000080001002 wstrb=05 @828 Time: 828 Scope: tb_ooo_data_word_cache.u_checker FATAL: /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/dcache-release.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/dcache-release.run.log

- `kind`: log
- `size_bytes`: 129
- `line_count`: 2
- `sha256`: 6a8166772b739592ae2e227b77822c154f202e002d0733a89cbfb3362edb9284
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=129 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_data_word_cache /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 827 (1s)

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/wrapper-assert.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/wrapper-assert.run.log

- `kind`: log
- `size_bytes`: 137
- `line_count`: 2
- `sha256`: 2b29428b7dc8b0605f148a0405d46395d5d94a39323ff5bf01c923826dfeaa1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=137 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_dual_mem_bridge_wrapper /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 705 (1s)

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/wrapper-mmu-nonidle.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/wrapper-mmu-nonidle.run.log

- `kind`: log
- `size_bytes`: 379
- `line_count`: 4
- `sha256`: 28ccb4188e4737e2c938449aadd45804b78dc77662ba454b042897713ffc2a87
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=379 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v:501: [DMBW-MMU-FLUSH-NONIDLE] mmu_flush requires both bridges idle: lane0=0 lane1=1 @710 Time: 710 Scope: tb_ooo_dual_mem_bridge_wrapper.dut FATAL: /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/wrapper-release.compile.log

- `kind`: log
- `size_bytes`: 137168
- `line_count`: 1032
- `sha256`: 87cbefb22d32f0bb7043ebb3967f679ada1c005580c24840d5d17c251576987c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=137168 bytes; lines=1032; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/profiles/wrapper-release.run.log

- `kind`: log
- `size_bytes`: 137
- `line_count`: 2
- `sha256`: 2b29428b7dc8b0605f148a0405d46395d5d94a39323ff5bf01c923826dfeaa1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=137 bytes; lines=2; PASS=2; tail=[PASS] tb_ooo_dual_mem_bridge_wrapper /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:32: $finish called at 705 (1s)

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/result.json

- `kind`: json
- `size_bytes`: 1179
- `line_count`: 37
- `sha256`: 17142e3a73472e952305919d9e05871bfaa3521025341c9dc7d92aff6a582e15
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 20}
- `summary`: json evidence; size=1179 bytes; lines=37; PASS=20; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED" }, "canonical_architecture_manifest_modified": false, "canonical_core_integration": false, "claim": "dual_bridge_cache_hit_leaf_verified", "f0_permanent_target": "PASS", "generated_at_utc":...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/run-id.txt

- `kind`: txt
- `size_bytes`: 31
- `line_count`: 1
- `sha256`: daae528444696bcc09f40771025651b582bfd160b93a254e74410f765df9544a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=31 bytes; lines=1; markers=<none>; tail=v8r-f1-20260720T052716Z-935556

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 7038
- `line_count`: 46
- `sha256`: 05743bcd448bae5da16110a5a0a8644e74de87fde8bf6047b324c904eb1cfc18
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=7038 bytes; lines=46; markers=<none>; tail=b6fc781920e6cd6ab7e7f929a9c3efad6d200d233d8539a6a80f656fde3f567f /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/contract.md 956a893338654e44c4f6fe73cdb328507e845d3d33a136b5b3e0756f4994ed0a /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 7038
- `line_count`: 46
- `sha256`: 05743bcd448bae5da16110a5a0a8644e74de87fde8bf6047b324c904eb1cfc18
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=7038 bytes; lines=46; markers=<none>; tail=b6fc781920e6cd6ab7e7f929a9c3efad6d200d233d8539a6a80f656fde3f567f /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/contract.md 956a893338654e44c4f6fe73cdb328507e845d3d33a136b5b3e0756f4994ed0a /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 53139
- `line_count`: 1219
- `sha256`: e70dc2c2cd7fb219ef33358ea2edae2733fe2cb0cc67db3149764fab75e58a90
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 16}
- `summary`: json evidence; size=53139 bytes; lines=1219; PASS=16; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 399
- `line_count`: 11
- `sha256`: 68ea1fbc7b882e29a92284e548bf6851e86ddb95db965f7da1836544cc74a656
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=399 bytes; lines=11; markers=<none>; tail=DI-1: RED (7 red checks) DI-2: RED (18 red checks) DI-3: RED (3 red checks) DI-4: RED (3 red checks) DI-5: RED (15 red checks) OOO-1: RED (3 red checks) OOO-2: RED (3 red checks) OOO-3: RED (14 red checks) OOO-4: RED (9 red checks) OVERALL: RED RESULT: /hom...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/checker-unit.log

- `kind`: log
- `size_bytes`: 1129
- `line_count`: 15
- `sha256`: 41fcd12d5c6c8ceef3744334205e47b8220d2ef2f934befecb7fae42881327a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=1129 bytes; lines=15; markers=<none>; tail=test_baseline_all_checks_pass (__main__.CheckerTests.test_baseline_all_checks_pass) ... ok test_canonical_instantiation_is_rejected (__main__.CheckerTests.test_canonical_instantiation_is_rejected) ... ok test_claim_inflation_is_rejected (__main__.CheckerTes...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/contract.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 9
- `sha256`: 25b3b834481458b2fdd3f686bf2ddf17818c15d6ee771a72eee1fd3b2a60b859
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=9; PASS=4; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 9 tests in 2.747s OK [PRODUCER-HOLDER-CENSUS] PASS direct=16 packed=5 token_q=13 generation=1 契约立即断言（$error）计数：当前=4...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/f0-checker-unit.log

- `kind`: log
- `size_bytes`: 1463
- `line_count`: 17
- `sha256`: b945da18645b1989a5a2ef169d26cb3088bf5b8486364d17185c61f269655a5c
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=1463 bytes; lines=17; markers=<none>; tail=test_canonical_instance_detection_ignores_comments (__main__.CheckerFailClosedTests.test_canonical_instance_detection_ignores_comments) ... ok test_comment_only_assertion_marker_fails (__main__.CheckerFailClosedTests.test_comment_only_assertion_marker_fails...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/f0-permanent-target.log

- `kind`: log
- `size_bytes`: 273
- `line_count`: 3
- `sha256`: 9e1aa0676e0bdbe8f3cbe24f8098bf13335e315d4d26341c11a9ea42cb1c1b9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=273 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [V8Q-F0][PASS] run_id=v8q-f0-20260720T052724Z-936745 claim=dual_axi_miss_fabric_leaf_verified mutations=12 architecture=RED ppa=UNQUALIFIED make[1]: Leaving directory '/home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/leaf-checks.json

- `kind`: json
- `size_bytes`: 3717
- `line_count`: 124
- `sha256`: 5fc06c241e7c102fda7485bf6ef17213f0fbfba0640637ff0c52c7d9d48c747a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: json evidence; size=3717 bytes; lines=124; markers=<none>; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED", "ppa": "UNQUALIFIED" }, "candidate_claim": "dual_bridge_cache_hit_leaf_verified", "candidate_only_until_execution_gate": true, "checks": [ { "check_id": "wrapper.one_nonempty_module", "det...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/leaf-checks.log

- `kind`: log
- `size_bytes`: 3717
- `line_count`: 124
- `sha256`: 5fc06c241e7c102fda7485bf6ef17213f0fbfba0640637ff0c52c7d9d48c747a
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=3717 bytes; lines=124; markers=<none>; tail={ "architecture": { "DI-5": "RED", "OOO-3": "RED", "overall": "RED", "ppa": "UNQUALIFIED" }, "candidate_claim": "dual_bridge_cache_hit_leaf_verified", "candidate_only_until_execution_gate": true, "checks": [ { "check_id": "wrapper.one_nonempty_module", "det...

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/rtl-style.log

- `kind`: log
- `size_bytes`: 232
- `line_count`: 3
- `sha256`: 96c33fde944e1dfe18479810ebbb194ce79d090de0454e240cebdb1f88732078
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=232 bytes; lines=3; PASS=2; tail=make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make[1]: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/verilator-assert.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-20-rv64-v8r-dual-memory-bridge-wrapper/evidence/focused/static/verilator-release.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-20T05:48:00+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=
