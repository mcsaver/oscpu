# Evidence Index

## 基本信息

- `task_id`: 2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1
- `task_slug`: 
- `profile`: 
- `asset_count`: 42
- `total_size_bytes`: 2010425

## 证据资产

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/backend-bridge-directed/logs/tb_ooo_int_backend_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 157990
- `line_count`: 1163
- `sha256`: c0e94bfa2613d24a018cba97b072120daa8463fe48d4568ce453d0e136911dec
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=157990 bytes; lines=1163; PASS=5; tail=x-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/ly...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/baseline-tieoff.diff

- `kind`: diff
- `size_bytes`: 456
- `line_count`: 11
- `sha256`: ea13d26bb5cc23997bfd88f81082c5381b8d6c83e14d176e7a04a8e7fa310576
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: diff evidence; size=456 bytes; lines=11; markers=<none>; tail=--- candidate/OooMemAxiBridge.v +++ baseline-tieoff/OooMemAxiBridge.v @@ -778,7 +778,7 @@ // Response READY never qualifies VALID and only selects direct fire versus // the registered S_RESP fallback in the sequential FSM. assign data_store_b_response_fusio...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/baseline/build.log

- `kind`: log
- `size_bytes`: 75309
- `line_count`: 97
- `sha256`: 7ebad9c966014a48df3ce8ed5d0f8f23b246470de3d96fbcc4720abb04dde09f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"symbolic": ["__0__", "__10__", "__11__", "__1__", "__2__", "__3__", "__4__", "__5__", "__6__", "__7__", "__8__", "__9__"]}
- `summary`: log evidence; size=75309 bytes; lines=97; symbolic=__0__,__10__,__11__,__1__,__2__; tail=Checker.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/utils.c /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/cpu-exec.cpp /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/difftest.cpp /home/ly...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/baseline/coremark-v8.raw.log

- `kind`: log
- `size_bytes`: 10573
- `line_count`: 96
- `sha256`: 7880378e777a1c72f3b0a4068f56b2e05c18604a6e19c138e6ecc00cddfbdd66
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=10573 bytes; lines=96; PASS=2; GOOD_TRAP=2; tail=[npc] failed to locate libcapstone.so.5: tools/capstone/repo/libcapstone.so.5: cannot open shared object file: No such file or directory [1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory a...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/baseline/counter-result.json

- `kind`: json
- `size_bytes`: 2545
- `line_count`: 97
- `sha256`: cc510178de4815335347eb1313982725d96a412b41d0bd1c68ee44f5730f12e0
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=2545 bytes; lines=97; PASS=2; tail={ "schema": "npc-rv64-v13p-coremark-ab-result-v1", "status": "PASS", "mode": "baseline", "cycles": 5395310, "retired_instructions": 3183617, "cpi": 1.6947107645172141, "ipc": 0.5900711914607316, "semantic": { "good_trap_count": 1, "exit_code": 0, "iteration...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/baseline/post-run-binding.json

- `kind`: json
- `size_bytes`: 885
- `line_count`: 25
- `sha256`: c56d5ef1484737e4be296abd20b9a439d62e32f434963204fe8d1362710ea5ae
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=885 bytes; lines=25; PASS=2; tail={ "schema": "npc-rv64-v13p-coremark-ab-post-run-v1", "status": "PASS", "mode": "baseline", "transaction": { "build_rc": 0, "identity_rc": 0, "run_rc": 0, "parser_rc": 0, "good_trap_count": 1, "rtl_assertion_failure_count": 0 }, "artifacts": { "pre_run_ident...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/baseline/pre-run-identity.json

- `kind`: json
- `size_bytes`: 43205
- `line_count`: 394
- `sha256`: 5eb08860ae235369146abd4ce147c4c730c0407c9848cc5e7c586611bf006bf7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: json evidence; size=43205 bytes; lines=394; markers=<none>; tail={ "schema": "npc-rv64-v13p-coremark-ab-pre-run-v1", "mode": "baseline", "single_mechanism": "aggregate_b_terminal_response_fusion", "baseline_tieoff": true, "simulator_executable_sha256": "f3add3d8a20747f1c803b2a3caf276dae5917707341346625002b08a30fe1783", "...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/candidate/build.log

- `kind`: log
- `size_bytes`: 75344
- `line_count`: 97
- `sha256`: 5c7469568a21f1037a76880c232db50746e44819bd5022c8bc450d7ddfe138c7
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"symbolic": ["__0__", "__10__", "__11__", "__1__", "__2__", "__3__", "__4__", "__5__", "__6__", "__7__", "__8__", "__9__"]}
- `summary`: log evidence; size=75344 bytes; lines=97; symbolic=__0__,__10__,__11__,__1__,__2__; tail=r.sv /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/debug/OooAdUpdateChecker.sv /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/utils.c /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/cpu-exec.cpp /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/cpu/difftest.cpp /home/lyg/PA/y...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/candidate/coremark-v8.raw.log

- `kind`: log
- `size_bytes`: 10575
- `line_count`: 96
- `sha256`: 060ffcfff0a84cb63fe0eb67276b9e719a4725fc373cdfa080919d5568f5845b
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=10575 bytes; lines=96; PASS=2; GOOD_TRAP=2; tail=[npc] failed to locate libcapstone.so.5: tools/capstone/repo/libcapstone.so.5: cannot open shared object file: No such file or directory [1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory a...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/candidate/counter-result.json

- `kind`: json
- `size_bytes`: 2548
- `line_count`: 97
- `sha256`: e5f09d678a244831fb090f0a330d6b6b5393bd7ca1d0b95833f7cd196cba23eb
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=2548 bytes; lines=97; PASS=2; tail={ "schema": "npc-rv64-v13p-coremark-ab-result-v1", "status": "PASS", "mode": "candidate", "cycles": 5392187, "retired_instructions": 3183617, "cpi": 1.6937298048100635, "ipc": 0.5904129437647471, "semantic": { "good_trap_count": 1, "exit_code": 0, "iteratio...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/candidate/post-run-binding.json

- `kind`: json
- `size_bytes`: 886
- `line_count`: 25
- `sha256`: 5dd38d2d0de612befd9c52f416b3f84b97369c8e7b0f2118ab73de2d030336b6
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=886 bytes; lines=25; PASS=2; tail={ "schema": "npc-rv64-v13p-coremark-ab-post-run-v1", "status": "PASS", "mode": "candidate", "transaction": { "build_rc": 0, "identity_rc": 0, "run_rc": 0, "parser_rc": 0, "good_trap_count": 1, "rtl_assertion_failure_count": 0 }, "artifacts": { "pre_run_iden...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/candidate/pre-run-identity.json

- `kind`: json
- `size_bytes`: 43236
- `line_count`: 394
- `sha256`: 8b100a045619b297c00b2389497f41825c3903e1f2df00f1eff73680735af6ba
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: json evidence; size=43236 bytes; lines=394; markers=<none>; tail={ "schema": "npc-rv64-v13p-coremark-ab-pre-run-v1", "mode": "candidate", "single_mechanism": "aggregate_b_terminal_response_fusion", "baseline_tieoff": false, "simulator_executable_sha256": "4ec5cfcdb09954cf22a3ccb975db06d6a375ad96237146f567526e9ed6624b15",...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/command-status.txt

- `kind`: txt
- `size_bytes`: 281
- `line_count`: 13
- `sha256`: 2a5d0f5e9f8a8ba6bfa2d26b95d3cf97a2ac778c6f962ce9db9dc4fe7333e471
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: txt evidence; size=281 bytes; lines=13; markers=<none>; tail=input_rc=0 baseline_build_rc=0 baseline_identity_rc=0 baseline_run_rc=0 baseline_parser_rc=0 candidate_build_rc=0 candidate_identity_rc=0 candidate_run_rc=0 candidate_parser_rc=0 pair_rc=0 cleanup_rc=0 baseline_build_bytes_deleted=230282250 candidate_build_...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/coremark-b-fusion-ab/comparison.json

- `kind`: json
- `size_bytes`: 991
- `line_count`: 33
- `sha256`: 1a7ac7bac4e758a55cb0a4d7057f086849fec5888d545cbcb76ab8b423275983
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=991 bytes; lines=33; PASS=2; tail={ "schema": "npc-rv64-v13p-coremark-ab-comparison-v1", "status": "PASS", "single_mechanism_source_difference": [ "npc/rv64/vsrc/memory/OooMemAxiBridge.v" ], "baseline": { "cycles": 5395310, "retired_instructions": 3183617, "cpi": 1.6947107645172141, "ipc":...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/integration/logs/tb_ooo_dual_mem_bridge_wrapper.log

- `kind`: log
- `size_bytes`: 138617
- `line_count`: 1041
- `sha256`: 129a9903abebbce0b3c3f2486b0011cdfab63c705418508499b5f9eb07d31276
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=138617 bytes; lines=1041; PASS=5; tail=s in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to al...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/integration/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 305040
- `line_count`: 2288
- `sha256`: b13e1adf4f1666ee5c6afa25478da290d39eb73b2e3a5bf2f14e96645639ad68
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=305040 bytes; lines=2288; PASS=2; tail=r.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/integration/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log

- `kind`: log
- `size_bytes`: 157952
- `line_count`: 1163
- `sha256`: 3a58ce8327b2f5f14cc925b730e56e5761588497e27e307d38c35817f4ef249d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=157952 bytes; lines=1163; PASS=5; tail=A/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /ho...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/integration/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 285770
- `line_count`: 2095
- `sha256`: 5afae7bbaf467ceb4b53b80e47b29fd0705bdce9906847008d7e8cd8d5500a7f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=285770 bytes; lines=2095; PASS=3; tail=4/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/module-testbench-focused/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 69968
- `line_count`: 527
- `sha256`: cc5bcd21a9e8a6ade13f62904a26710a8e4925215b8cd06fc330f1043dcd6e44
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=69968 bytes; lines=527; PASS=8; tail=/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'....

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/module-testbench-full/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74577
- `line_count`: 572
- `sha256`: 3a2f0608dafd7f18ba5e2e2cd2ea10c46fcbb300e9bda0e9c32610313725f393
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74577 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-disable-direct/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 72414
- `line_count`: 568
- `sha256`: 6a19ab1655f5f6d90b8f34d62b65da8a27d045089b78ea614f074073c3b059d5
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"FAIL": 39, "PASS": 7}
- `summary`: log evidence; size=72414 bytes; lines=568; FAIL=39; PASS=7; tail=to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is s...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-disable-direct/result.json

- `kind`: json
- `size_bytes`: 401
- `line_count`: 10
- `sha256`: 895d4786df9487b4ed3c95d87b7e0a36c12dd1a08dda551c877225a08c4ff87d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: json evidence; size=401 bytes; lines=10; FAIL=2; PASS=2; tail={ "schema_version": 1, "mutation": "disable_data_store_b_response_fusion", "source_sha256": "86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348", "variant_sha256": "fbf8bae7066ca7cf4396f3a8413e61d5b82d4ebf6ba921619cafd4cdf530e4b2", "make_rc":...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-drop-fallback-error-snapshot/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 70123
- `line_count`: 529
- `sha256`: 6d6e0989f9f7cfe796c2f9ebd9da4910f52efae99a226a7c9729ec837285245d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"FAIL": 3, "PASS": 4}
- `summary`: log evidence; size=70123 bytes; lines=529; FAIL=3; PASS=4; tail=/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-drop-fallback-error-snapshot/result.json

- `kind`: json
- `size_bytes`: 364
- `line_count`: 10
- `sha256`: 452a503a8a37190274d3f6b087a5f20b0549e4ee5be2b2a8e5322ad8823ac8ef
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=364 bytes; lines=10; PASS=2; tail={ "schema_version": 1, "mutation": "drop-fallback-error-snapshot", "source_sha256": "86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348", "variant_sha256": "46c22345a08f11a56b9db26dbd1619f60b0888e3a65328d602b7f46c2b6b4f50", "make_rc": 2, "expe...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-duplicate-s-resp/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 70014
- `line_count`: 527
- `sha256`: d8d4241d3efaa0ca23a6d9c588cbb62b5d44b305d10d611a4e77b2d1acd6f35d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: log evidence; size=70014 bytes; lines=527; FAIL=4; PASS=1; tail=warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecke...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-duplicate-s-resp/result.json

- `kind`: json
- `size_bytes`: 350
- `line_count`: 10
- `sha256`: 820e85dfc97aed579c3d7276cdd425cec11a4106aae5bb74893d0b0f4f6848f8
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=350 bytes; lines=10; PASS=2; tail={ "schema_version": 1, "mutation": "duplicate-s-resp", "source_sha256": "86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348", "variant_sha256": "6b1fa763fda5c68cbf851738d833bbedd2f210054009154d95fa1007b94dcdee", "make_rc": 2, "expected_detecti...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-expose-killed-b/logs/tb_ooo_mem_axi_bridge_v13p_store_b_fusion.log

- `kind`: log
- `size_bytes`: 70200
- `line_count`: 531
- `sha256`: aed1f7ba3b04de2ebb7cbe2ed02375fd0e9af34896baa4e1c7ff2c257dbef606
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"FAIL": 4, "PASS": 5}
- `summary`: log evidence; size=70200 bytes; lines=531; FAIL=4; PASS=5; tail=ry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in a...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/mutation-expose-killed-b/result.json

- `kind`: json
- `size_bytes`: 382
- `line_count`: 10
- `sha256`: cd899ee75202a57469796befc70e9ba4765d7a4ec581da52d87d4f5f9dc7e79c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: json evidence; size=382 bytes; lines=10; FAIL=2; PASS=2; tail={ "schema_version": 1, "mutation": "expose-killed-b", "source_sha256": "86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348", "variant_sha256": "586eddbff4a0c98c881641d56f2f7bd9c691ca68d836f23c5fa5d81173ad1149", "make_rc": 2, "expected_detectio...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline-to-candidate.patch

- `kind`: patch
- `size_bytes`: 449
- `line_count`: 11
- `sha256`: a248e999f9c1d177f8d25a2162e8f52d4e875acc270e7c9f6171329fcc8cae8c
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: patch evidence; size=449 bytes; lines=11; markers=<none>; tail=--- baseline/OooMemAxiBridge.v +++ candidate/OooMemAxiBridge.v @@ -778,7 +778,7 @@ // Response READY never qualifies VALID and only selects direct fire versus // the registered S_RESP fallback in the sequential FSM. assign data_store_b_response_fusion_w = -...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline/bpath-count.txt

- `kind`: txt
- `size_bytes`: 11
- `line_count`: 1
- `sha256`: db878463fe7eb81fc4b89e073ee1b41038fc0e30abc72a2743f9c8e487f102eb
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: txt evidence; size=11 bytes; lines=1; markers=<none>; tail=0 objects.

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline/bpath-ltp.txt

- `kind`: txt
- `size_bytes`: 45
- `line_count`: 2
- `sha256`: dd05208d6f88a6df9fb0c627e19f64fd70c1720f6bb1dbde0bcaefe72746cd86
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: txt evidence; size=45 bytes; lines=2; markers=<none>; tail=13. Executing LTP pass (find longest path).

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline/bridge-source.sha256

- `kind`: sha256
- `size_bytes`: 113
- `line_count`: 1
- `sha256`: 75cd1df5294daa5ef68d082add8f266007fd5c2c8ee0a097e6cd142903e3b0bc
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=113 bytes; lines=1; markers=<none>; tail=fbf8bae7066ca7cf4396f3a8413e61d5b82d4ebf6ba921619cafd4cdf530e4b2 /tmp/tmp.NmJCrc33IJ/baseline/OooMemAxiBridge.v

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline/dependency-sources.sha256

- `kind`: sha256
- `size_bytes`: 1071
- `line_count`: 8
- `sha256`: b24393ad09c500d479a6ce74ab32b18b19a7cc505cf412ed011f8aa3a27b87da
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1071 bytes; lines=8; markers=<none>; tail=f4600c320b03f0ffd3bcdff9336bcea2a17580fa7b8752da18d7db35956da4c2 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v ce644709dd4bfa8d2710fc4e32dea24b660ab24f55d745552ab5aebd09263de0 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooTypedPmaCheck...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline/stats.json

- `kind`: json
- `size_bytes`: 2305
- `line_count`: 81
- `sha256`: 66bb6254b084bc937e23037061b1f9523297dd8f4e311038b91d9c3387950435
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: json evidence; size=2305 bytes; lines=81; markers=<none>; tail={ "creator": "Yosys 0.66+197 (git sha1 aa18c921a, Release, Clang /usr/bin/clang++ 18.1.8)", "invocation": "stat -json ", "modules": { "\\OooMemAxiBridge": { "num_wires": 1114, "num_wire_bits": 9491, "num_pub_wires": 270, "num_pub_wire_bits": 3788, "num_port...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/baseline/yosys.log

- `kind`: log
- `size_bytes`: 123572
- `line_count`: 1485
- `sha256`: 2b2beeab98ba8cd8285a0a739e004522f3d9a1afb919d4adc86805437db81eca
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: log evidence; size=123572 bytes; lines=1485; markers=<none>; tail=ine/OooMemAxiBridge.v:1579$1533.pte' using process `\OooMemAxiBridge.$proc$/tmp/tmp.NmJCrc33IJ/baseline/OooMemAxiBridge.v:1374$2030'. created $dff cell `$procdff$8838' with positive edge clock. Creating register for signal `\OooMemAxiBridge.\superpage_misal...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/candidate/bpath-count.txt

- `kind`: txt
- `size_bytes`: 12
- `line_count`: 1
- `sha256`: cca648e37154bca9e5c45c2137b9e72eb0ace99d42f5a794246730dbe129cdab
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: txt evidence; size=12 bytes; lines=1; markers=<none>; tail=22 objects.

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/candidate/bpath-ltp.txt

- `kind`: txt
- `size_bytes`: 632
- `line_count`: 9
- `sha256`: ccfe233d1f5eadce301ea1b6227a931195572ab7063cc6057b13dcb90fa61cd8
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: txt evidence; size=632 bytes; lines=9; markers=<none>; tail=13. Executing LTP pass (find longest path). Longest topological path in OooMemAxiBridge (length=4): 0: \lsu_axi_bvalid_i 1: \data_store_b_terminal_w (via $logic_and$/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v:774$1766) 2: \data_store_...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/candidate/bridge-source.sha256

- `kind`: sha256
- `size_bytes`: 133
- `line_count`: 1
- `sha256`: b71a698c4f6cced3701fe23fc3fd2ffddca19f18a302a9fc07d0be2d81c7b03f
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=133 bytes; lines=1; markers=<none>; tail=86299fad8c136030365c92ed9aa3ca4c84306a00d2f9b827a73da71a4f870348 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/candidate/dependency-sources.sha256

- `kind`: sha256
- `size_bytes`: 1071
- `line_count`: 8
- `sha256`: b24393ad09c500d479a6ce74ab32b18b19a7cc505cf412ed011f8aa3a27b87da
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1071 bytes; lines=8; markers=<none>; tail=f4600c320b03f0ffd3bcdff9336bcea2a17580fa7b8752da18d7db35956da4c2 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v ce644709dd4bfa8d2710fc4e32dea24b660ab24f55d745552ab5aebd09263de0 /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooTypedPmaCheck...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/candidate/stats.json

- `kind`: json
- `size_bytes`: 2305
- `line_count`: 81
- `sha256`: 06c8701e5262af364b52e2328a97c710f3d08376cedbef77ef0a8bec0fe90b8d
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: json evidence; size=2305 bytes; lines=81; markers=<none>; tail={ "creator": "Yosys 0.66+197 (git sha1 aa18c921a, Release, Clang /usr/bin/clang++ 18.1.8)", "invocation": "stat -json ", "modules": { "\\OooMemAxiBridge": { "num_wires": 1123, "num_wire_bits": 9566, "num_pub_wires": 272, "num_pub_wire_bits": 3790, "num_port...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/candidate/yosys.log

- `kind`: log
- `size_bytes`: 136543
- `line_count`: 1492
- `sha256`: 5076c12124bfdba87826c5fe0831ff3c294a43bec6ad82d7d07ad5ac2ca08c6e
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {}
- `summary`: log evidence; size=136543 bytes; lines=1492; markers=<none>; tail=l `\OooMemAxiBridge.\pte_leaf$func$/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v:379$1537.pte' using process `\OooMemAxiBridge.$proc$/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooMemAxiBridge.v:1374$2031'. created $dff cell `$proc...

### .github/task-runs/2026-08-02-rv64-v13p-store-b-terminal-cpi-architecture-v1/evidence/yosys-bridge-structural/comparison.json

- `kind`: json
- `size_bytes`: 1167
- `line_count`: 32
- `sha256`: 8060d193fc089db8d3ecd0d9781ce9b6e4a48087f2eabf531a9e2189dc75d186
- `encoding`: utf-8
- `indexed_at`: 2026-08-01T18:12:38+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=1167 bytes; lines=32; PASS=2; tail={ "schema_version": 1, "scope": "OooMemAxiBridge generic structural diagnostic; leaf TLB/cache/checker modules blackboxed", "tool": { "version": "Yosys 0.66+197 (git sha1 aa18c921a, Release, Clang /usr/bin/clang++ 18.1.8)", "sha256": "7c3e3396b38c129dd7485b...
