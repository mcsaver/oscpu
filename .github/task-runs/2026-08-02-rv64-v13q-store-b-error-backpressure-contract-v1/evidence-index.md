# Evidence Index

## 基本信息

- `task_id`: 2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 13
- `total_size_bytes`: 1029104

## 证据资产

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/backend-error-backpressure/critical-source-binding.sha256

- `kind`: sha256
- `size_bytes`: 1301
- `line_count`: 12
- `sha256`: 51f6e627586e8e40093aaef4df9bc7f7f30c1315ae24a88a306731e10480b139
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1301 bytes; lines=12; markers=<none>; tail=86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348 npc/rv64/vsrc/memory/OooMemAxiBridge.v a421641abcfbd45a10f28fc0e44c7f2d1b28a1936c5500f0f046e7456590f5c9 npc/rv64/vsrc/memory/OooDualMemBridgeWrapper.v f4b810ed5ada6f68e920ab077a596daf18dee7fe4...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/backend-error-backpressure/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log

- `kind`: log
- `size_bytes`: 159410
- `line_count`: 1169
- `sha256`: ca173e37f6da81f871b25587577276ab84a048de3b2e75a58561a77e09a7c4a0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"ERROR": 1, "PASS": 8}
- `summary`: log evidence; size=159410 bytes; lines=1169; ERROR=1; PASS=8; tail=@* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116:...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/backend-error-backpressure/result.json

- `kind`: json
- `size_bytes`: 374
- `line_count`: 10
- `sha256`: 8f0d49332cf38a3d184f4d1b5b71148ea83b0dcad263d47aa153a11739edcb60
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=374 bytes; lines=10; PASS=2; tail={ "schema_version": 1, "test": "v13q-store-b-error-backpressure-focused", "make_rc": 0, "critical_source_binding_sha256": "51f6e627586e8e40093aaef4df9bc7f7f30c1315ae24a88a306731e10480b139", "log_sha256": "ca173e37f6da81f871b25587577276ab84a048de3b2e75a58561...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-drain-cause-load-fault/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log

- `kind`: log
- `size_bytes`: 160282
- `line_count`: 1180
- `sha256`: adfbedef19ee6d1ab8473833aa58c1e195fbeda8fdea0065ca4e6a0b8d0f3230
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"ERROR": 1, "FAIL": 9, "PASS": 7}
- `summary`: log evidence; size=160282 bytes; lines=1180; FAIL=9; ERROR=1; PASS=7; tail=c/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-drain-cause-load-fault/result.json

- `kind`: json
- `size_bytes`: 424
- `line_count`: 11
- `sha256`: c0845e80b38bb055fcbe4d9f796aa01e52a189f79d3fc7070119b7ccf82fced5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: json evidence; size=424 bytes; lines=11; FAIL=2; PASS=2; tail={ "schema_version": 1, "mutation": "drain-cause-load-fault", "source_sha256": "49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a", "variant_sha256": "a76ce719e3da282c502b670584ba8d5f3df7e9cfe101f0279f240d175eee6ab7", "make_rc": 2, "expected_d...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-drain-tval-uses-pa/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log

- `kind`: log
- `size_bytes`: 160326
- `line_count`: 1180
- `sha256`: 4c324442546447bc4b9997d9c8876cd23103c2a85557d9d1f518c0925470845c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"ERROR": 1, "FAIL": 9, "PASS": 7}
- `summary`: log evidence; size=160326 bytes; lines=1180; FAIL=9; ERROR=1; PASS=7; tail=ive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* i...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-drain-tval-uses-pa/result.json

- `kind`: json
- `size_bytes`: 412
- `line_count`: 11
- `sha256`: 7ba464217cd5b1edec51fac53b3a96d4f76f796e99bedfaa1d5adb8a45e503e5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: json evidence; size=412 bytes; lines=11; FAIL=2; PASS=2; tail={ "schema_version": 1, "mutation": "drain-tval-uses-pa", "source_sha256": "49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a", "variant_sha256": "554248c49a6ab98e2c5436c4feb59740a811c6760790a74e07e9c8b129440bbe", "make_rc": 2, "expected_detec...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-ignore-formal-wb-credit/logs/tb_ooo_int_backend_v13q_store_b_error_backpressure.log

- `kind`: log
- `size_bytes`: 159990
- `line_count`: 1177
- `sha256`: 0af67c76ee1b523f46e42a295fc5c7754135262ced8a92c2044ca0a4a8f3672e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"ERROR": 2, "FAIL": 7, "PASS": 3}
- `summary`: log evidence; size=159990 bytes; lines=1177; FAIL=7; ERROR=2; PASS=3; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /hom...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-ignore-formal-wb-credit/result.json

- `kind`: json
- `size_bytes`: 431
- `line_count`: 11
- `sha256`: 1f030b8706f1d3b9e4279eedc7380da901cbb25310bc4a0e37c413a4f87086c2
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: json evidence; size=431 bytes; lines=11; FAIL=2; PASS=2; tail={ "schema_version": 1, "mutation": "ignore-formal-wb-credit", "source_sha256": "49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a", "variant_sha256": "32eb7757b32e778cb9f344bda276b2302af31ece85e509c45368518be86d1cd8", "make_rc": 2, "expected_...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/mutation-suite-result.json

- `kind`: json
- `size_bytes`: 244
- `line_count`: 8
- `sha256`: 7649bcdb5739aeb59dbd4bf8d428223a664599e995c2d477702ac90d7b289f86
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=244 bytes; lines=8; PASS=2; tail={ "schema_version": 1, "suite": "v13q-backend-error-backpressure-mutations", "source_sha256": "49ec3d7eff22e4146be35bf1a0e56e7c57c7a3418ae4bc6fa0e65d34d83cca5a", "mutation_count": 3, "mutation_detected_count": 3, "status": "PASS" }

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/v13p-regression/logs/tb_ooo_int_backend_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 157990
- `line_count`: 1163
- `sha256`: 10f38f1110cc1fbd532c64b8233be7a7bc42e8f2b48150f866ffe19c5e9f167d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=157990 bytes; lines=1163; PASS=5; tail=x-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/ly...

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/v13p-regression/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 69968
- `line_count`: 527
- `sha256`: cc5bcd21a9e8a6ade13f62904a26710a8e4925215b8cd06fc330f1043dcd6e44
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=69968 bytes; lines=527; PASS=8; tail=/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'....

### .github/task-runs/2026-08-02-rv64-v13q-store-b-error-backpressure-contract-v1/evidence/v8x-regression/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log

- `kind`: log
- `size_bytes`: 157952
- `line_count`: 1163
- `sha256`: 8e38435baefe645f6530ab40ecea1231c6975f5b4b0c764aef097485ff1fe94a
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T19:20:17+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=157952 bytes; lines=1163; PASS=5; tail=A/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /ho...
