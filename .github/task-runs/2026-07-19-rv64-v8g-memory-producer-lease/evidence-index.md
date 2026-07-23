# Evidence Index

## 基本信息

- `task_id`: 2026-07-19-rv64-v8g-memory-producer-lease
- `task_slug`: 
- `profile`: 
- `asset_count`: 347
- `total_size_bytes`: 2837302

## 证据资产

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert-backend-focused.make.log

- `kind`: log
- `size_bytes`: 616
- `line_count`: 16
- `sha256`: 5c55b19d8d618ea1ced82a75a28ed92849fde98c97a753d3fb4ca417a1f0f767
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=616 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert-backend-focused/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11561
- `line_count`: 70
- `sha256`: 215e094cb6b95346ca999e7dc2a0f14ae08d4dffb3a0befd4db391cc0e9ba4d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11561 bytes; lines=70; PASS=16; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-baseline-assert-backend-focused/tb_ooo_int_backend.vv...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert-backend-focused/summary.txt

- `kind`: txt
- `size_bytes`: 301
- `line_count`: 10
- `sha256`: 967d514498910012e302678fcc13d99f0bf7f5cc70add48d32c4eab8807b5c26
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=301 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert-backend-focused - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_ba...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert.make.log

- `kind`: log
- `size_bytes`: 736
- `line_count`: 21
- `sha256`: 549a8893605337a5cd7f2337d20c3a51db48e49ea78b79cd427a326a386958cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=736 bytes; lines=21; PASS=14; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 4902
- `line_count`: 35
- `sha256`: 2a14a90afceca64d7f74d23eb6ed4ef5c738c00325096cf06d04e5895b11989a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4902 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8g-memory-lease.guxixu/build-baseline-assert/tb_ooo_dispatch_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14201
- `line_count`: 109
- `sha256`: 64baab136b236ee96d1f45d4e213478971ae0ee11617c8201e1cf571b78d7d56
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 2, "PASS": 38}
- `summary`: log evidence; size=14201 bytes; lines=109; ERROR=2; PASS=38; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-baseline-assert/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71228
- `line_count`: 546
- `sha256`: 86942c5285e62d7c9907b50d37b580b74b8bdca0ffb91b2a877808813d2ac772
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 17}
- `summary`: log evidence; size=71228 bytes; lines=546; PASS=17; tail=ry/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1111
- `line_count`: 12
- `sha256`: 349ffb0b4af7fa336251899139899515ff59c4448fb668ca0f4f334d35b62cbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1111 bytes; lines=12; PASS=6; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /tmp/v8g-memory-lease.guxixu/build-baseline-assert/tb_ooo_mem_owner_tracker.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1034
- `line_count`: 11
- `sha256`: 9fad6c3316fe5dec67229b9da9876a3746e8f99e595d03e22d109df0dbd5b641
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1034 bytes; lines=11; PASS=12; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8g-memory-lease.guxixu/build-baseline-assert/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCsrTrapRequestMux.v /...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2598
- `line_count`: 25
- `sha256`: 6a0faf13a9ee349eb1f18f54892082c9970ce0c6150b55bf4479ae5f345f0edf
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=2598 bytes; lines=25; PASS=20; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-memory-lease.guxixu/build-baseline-assert/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/O...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert/summary.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 15
- `sha256`: 81f2dfe3184e9ef5ea61b642a368de927e54227e922b9ada23569fbb679ad3d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 12}
- `summary`: txt evidence; size=421 bytes; lines=15; PASS=12; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_mem_owner_tracker - PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release-backend-focused.make.log

- `kind`: log
- `size_bytes`: 617
- `line_count`: 16
- `sha256`: c42d0c5d02ef70788375a995455ffcab91314062dc4823ede7c6067c286e6b34
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=617 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release-backend-focused/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11010
- `line_count`: 66
- `sha256`: 1e029c51715a8f97bf36a4ef19da6a379d54f13a3bc766abf823d313b370facc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11010 bytes; lines=66; PASS=16; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-baseline-release-backend-focused/tb_ooo_int_backend.vvp /home/lyg/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release-backend-focused/summary.txt

- `kind`: txt
- `size_bytes`: 302
- `line_count`: 10
- `sha256`: eaa2819a83af59e43aa7af4585473677cdcd337d662eff097a178592248b3d3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=302 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release-backend-focused - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_b...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release.make.log

- `kind`: log
- `size_bytes`: 737
- `line_count`: 21
- `sha256`: 6bac41c3989463973e637f6c5e25606939209e7ae7ba7d61a09e3dd24d0771b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=737 bytes; lines=21; PASS=14; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 4890
- `line_count`: 35
- `sha256`: 79043800bd29181f960d4f3e7f88b96f8c7bd791b01af7b5de612361e49c1384
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4890 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_dispatch_backend -o /tmp/v8g-memory-lease.guxixu/build-baseline-release/tb_ooo_dispatch_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/renam...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13723
- `line_count`: 106
- `sha256`: 6049e57ecf7978c67bc5fd950819706bfa79fe42ae3ad04b273a714493d44bf4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 2, "PASS": 40}
- `summary`: log evidence; size=13723 bytes; lines=106; ERROR=2; PASS=40; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-baseline-release/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71216
- `line_count`: 546
- `sha256`: 6444c60ceb8db456c3881b9d44e7cab528a22f7ed09ca6f660b5a3e6ae2c9591
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 17}
- `summary`: log evidence; size=71216 bytes; lines=546; PASS=17; tail=ry/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1099
- `line_count`: 12
- `sha256`: d8a7b80da932518e2b64bc8d855a0d3e51ab2bb3eb6e1b4d056658f7c17c2f47
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1099 bytes; lines=12; PASS=6; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_mem_owner_tracker -o /tmp/v8g-memory-lease.guxixu/build-baseline-release/tb_ooo_mem_owner_tracker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/me...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1022
- `line_count`: 11
- `sha256`: 99d136f6ea798ff0baf0df927896440b34bfc8d64802564ce9738ec42d9b3ad5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1022 bytes; lines=11; PASS=12; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_rob -o /tmp/v8g-memory-lease.guxixu/build-baseline-release/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCsrTrapRequestMux.v /home/lyg/PA/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2047
- `line_count`: 21
- `sha256`: 8cf59df9e69d220316b999fd22c4a7f044a3c325ac8328a305928b43c38458b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=2047 bytes; lines=21; PASS=20; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -s tb_ooo_store_queue -o /tmp/v8g-memory-lease.guxixu/build-baseline-release/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/OooStoreQueue...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release/summary.txt

- `kind`: txt
- `size_bytes`: 422
- `line_count`: 15
- `sha256`: 753466255fa2676ebf780aed4ac5359679214606cad85191ecb51979e284c937
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 12}
- `summary`: txt evidence; size=422 bytes; lines=15; PASS=12; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-release - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_mem_owner_tracker - P...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/complete.marker

- `kind`: marker
- `size_bytes`: 27645
- `line_count`: 124
- `sha256`: 4ba207f303689dc90018dcbf08a778d9dd647955c04fec72a41de53010ce5109
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: marker evidence; size=27645 bytes; lines=124; PASS=2; tail=5c55b19d8d618ea1ced82a75a28ed92849fde98c97a753d3fb4ca417a1f0f767 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/baseline-assert-backend-focused.make.log 215e094cb6b95346ca999e7dc2a0f14ae08d4dffb3a0be...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_amo_read_ignore_owner_open.make.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 7
- `sha256`: 6d2fcde310413b54ba4d65d9d266afe76ce01100ab706c43f517fe52c83ad6da
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=526 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_amo_read_ignore_owner_open.mutator.log

- `kind`: log
- `size_bytes`: 55
- `line_count`: 1
- `sha256`: 44f3e51d2ead1eea18b7780b718282f519baeebd8f17f80d6326c0b27d661e96
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=55 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_amo_read_ignore_owner_open

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_amo_read_ignore_owner_open/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12076
- `line_count`: 79
- `sha256`: ec88c1ea200df83484f735700d26a0676b7515fbd13e7d812542d861d6d2c5f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 14, "PASS": 14}
- `summary`: log evidence; size=12076 bytes; lines=79; FAIL=14; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_amo_read_ignore_owner_open/tb_ooo_in...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_amo_write_launch_completes_early.make.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 7
- `sha256`: 524d89c3b84cf7de3c70de953a95f63a4da82895a05046a9ae4598ea49316919
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=532 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_amo_write_launch_completes_early.mutator.log

- `kind`: log
- `size_bytes`: 61
- `line_count`: 1
- `sha256`: 7b74039e8e325ec48cc3a1df52d4140154536f3b7e6cb7137a9dec699a94d9ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=61 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_amo_write_launch_completes_early

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_amo_write_launch_completes_early/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11659
- `line_count`: 71
- `sha256`: 73d08b266a10f4996fcec53c6d5dcb018da1624bc4a2738ea93cb809482cb75b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 2, "PASS": 10}
- `summary`: log evidence; size=11659 bytes; lines=71; FAIL=2; PASS=10; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_amo_write_launch_completes_early/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_buffer_kill_handoff_ready_loop.make.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 7
- `sha256`: 0f266c03fcba0a274afbb5edacd70e5b2c2420ef68c551f31f563953f883322d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=530 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_buffer_kill_handoff_ready_loop.mutator.log

- `kind`: log
- `size_bytes`: 59
- `line_count`: 1
- `sha256`: 6b4a29f2d9c07cdc89d26d1391803d88d6eb9cdb4215028c7ee6d24fb881fb44
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=59 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_buffer_kill_handoff_ready_loop

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_buffer_kill_handoff_ready_loop/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15292
- `line_count`: 124
- `sha256`: 6d90b43d417cbfc92e4cde3ac202c7604bc202bc98f8df649a2ca3de5eb97209
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 8, "FAIL": 16, "PASS": 36}
- `summary`: log evidence; size=15292 bytes; lines=124; FAIL=16; ERROR=8; PASS=36; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_buffer_kill_handoff_ready_loop/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_fatal_enters_normal_final.make.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 7
- `sha256`: b9c2104f3becfaea1b58f3c71be50851d4064873e3c91ddaa2ea37bcbc967876
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=525 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_fatal_enters_normal_final.mutator.log

- `kind`: log
- `size_bytes`: 54
- `line_count`: 1
- `sha256`: 7874f71bd0740b96da615a0f0b63aeecf39be66ed1a1f06c881acffc796d2f27
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=54 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_fatal_enters_normal_final

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_fatal_enters_normal_final/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11923
- `line_count`: 77
- `sha256`: 6ae484c7a6faafcb3ae09baa660e9358689c27013d10a586b35fce58e33589d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 10, "PASS": 14}
- `summary`: log evidence; size=11923 bytes; lines=77; FAIL=10; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_fatal_enters_normal_final/tb_ooo_int...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_ingress_ignore_current.make.log

- `kind`: log
- `size_bytes`: 522
- `line_count`: 7
- `sha256`: e576e6df088ffa69c8c1e3d4496027e4e85422d93536a525fc648a0e30bf8314
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=522 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_ingress_ignore_current.mutator.log

- `kind`: log
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: c2a59f6846bb74fb153b1857f36ee35b3418d8c18eef953bf7b2e5f4465e8b46
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=51 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_ingress_ignore_current

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_ingress_ignore_current/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12531
- `line_count`: 84
- `sha256`: b63d8482d1805bda648bdbcbfa496eb30923d271e749a79fd04555ce9fa6bfe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 6, "FAIL": 14, "PASS": 14}
- `summary`: log evidence; size=12531 bytes; lines=84; FAIL=14; ERROR=6; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_ingress_ignore_current/tb_ooo_int_ba...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_issue1_ignore_response_wait.make.log

- `kind`: log
- `size_bytes`: 527
- `line_count`: 7
- `sha256`: 955b4888834773dd8f53d59e7826ce5dd4e01f23114eb616bb904d572e326117
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=527 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_issue1_ignore_response_wait.mutator.log

- `kind`: log
- `size_bytes`: 56
- `line_count`: 1
- `sha256`: e9fc7f5adfdc7a6b9aeac7b346c07705ec76891cff282d68758a6d4f729a22d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=56 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_issue1_ignore_response_wait

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_issue1_ignore_response_wait/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11811
- `line_count`: 74
- `sha256`: dc3d65ab5a451c439b1b04fe1e211a20a26ef9c5b471d285686d83e991f4fa8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 12, "PASS": 6}
- `summary`: log evidence; size=11811 bytes; lines=74; FAIL=12; PASS=6; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_issue1_ignore_response_wait/tb_ooo_i...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_load_wb_ignore_owner_open.make.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 7
- `sha256`: 0d45b6ace8d25bf70c1e57f27f61739ad7131ccda16c210b635ae883942d213b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=525 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_load_wb_ignore_owner_open.mutator.log

- `kind`: log
- `size_bytes`: 54
- `line_count`: 1
- `sha256`: 19a0ec337b2224a70a5b19e69478a27e7edace71117f38e8f7b71cc78c45821c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=54 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_load_wb_ignore_owner_open

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_load_wb_ignore_owner_open/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11755
- `line_count`: 74
- `sha256`: 84938b0c6651ebd71c46c04c3f19997beeef92c10eb17094326e77dee78eb6ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 10, "PASS": 8}
- `summary`: log evidence; size=11755 bytes; lines=74; FAIL=10; PASS=8; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_load_wb_ignore_owner_open/tb_ooo_int...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_local_terminal_reads_consume.audit.log

- `kind`: log
- `size_bytes`: 106
- `line_count`: 1
- `sha256`: 15fdc2b23be9d15a7168432b0225754a4f90a3113940f125d1717d096fe24a58
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=106 bytes; lines=1; FAIL=2; tail=[V8G-MEMORY-LEASE-AUDIT][FAIL] local terminal re-entered request-ready cone: mem_issue_res_consume_fire_w

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_local_terminal_reads_consume.make.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 16
- `sha256`: e2738951b1f7a367f8417371af9d76d1617ff50b06f1771966f85e21cbcf441c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=630 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_local_terminal_reads_consume.mutator.log

- `kind`: log
- `size_bytes`: 57
- `line_count`: 1
- `sha256`: b363940eaec2f27a727d72cddd751f3d49f1dc2ef56432646a06b24b03fe9e3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=57 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_local_terminal_reads_consume

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_local_terminal_reads_consume/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11599
- `line_count`: 70
- `sha256`: 4b5d777db6c78256dfe6e997e671305d22fa0566d80bec594c3234c267e8e0df
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11599 bytes; lines=70; PASS=16; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_local_terminal_reads_consume/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_local_terminal_reads_consume/summary.txt

- `kind`: txt
- `size_bytes`: 315
- `line_count`: 10
- `sha256`: fe7b1ebd59e558d2088165ddea518bb12c41b687c75569840807330ad808367a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=315 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_local_terminal_reads_consume - tool: Icarus Verilog version 12.0 (stable) () - PASS...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_memory_loses_wb1.make.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 7
- `sha256`: 31987120a03d039c71d99a6ea303491adfa14a2fc1ea088f17edca417b843128
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=516 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_memory_loses_wb1.mutator.log

- `kind`: log
- `size_bytes`: 45
- `line_count`: 1
- `sha256`: 9559056e6808e8f02f67c3625fd0c521c934cb3a423f2d2669f7986e9a65ddbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=45 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_memory_loses_wb1

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_memory_loses_wb1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11910
- `line_count`: 77
- `sha256`: 8761fc415b88a751a8fb71cd6794ce3cbe51985fd64521dc24628e27670d65c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 10, "PASS": 14}
- `summary`: log evidence; size=11910 bytes; lines=77; FAIL=10; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_memory_loses_wb1/tb_ooo_int_backend....

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_query_ignore_tracker_exact.make.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 7
- `sha256`: b0fc0cf4fc975f3c80958de275100c51c2d6c36490ce46a36f6b3836e939ce21
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=526 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_query_ignore_tracker_exact.mutator.log

- `kind`: log
- `size_bytes`: 55
- `line_count`: 1
- `sha256`: 4e86441cdf4380e4a3e8a0105db44b71d7b894358ace06695173054c12e7fce3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=55 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_query_ignore_tracker_exact

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_query_ignore_tracker_exact/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11933
- `line_count`: 77
- `sha256`: 3683728c0b7f99c0c8c12d056cc078601edb77817bc49998500b937f744fb7f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 10, "PASS": 14}
- `summary`: log evidence; size=11933 bytes; lines=77; FAIL=10; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_query_ignore_tracker_exact/tb_ooo_in...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_raw_mask_reads_packed_vector.audit.log

- `kind`: log
- `size_bytes`: 101
- `line_count`: 1
- `sha256`: c78b62f7426fd6ac7f5901fa84aa381c4a45c3ac622d46f1e4b4cc66d872b60e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=101 bytes; lines=1; FAIL=2; tail=[V8G-MEMORY-LEASE-AUDIT][FAIL] terminal mask lane1 reads packed vector: mem_terminal_ingress_valid_w

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_raw_mask_reads_packed_vector.make.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 16
- `sha256`: 4790dd28161fea654b3d2c8182d553c94898141f7a0548cc0b8fa04dd496ca5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=630 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_raw_mask_reads_packed_vector.mutator.log

- `kind`: log
- `size_bytes`: 57
- `line_count`: 1
- `sha256`: e8034cfca967315aebdc8880c27e0ef1c1491a9f4a3ae9bf9462bb9aa2dd1792
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=57 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_raw_mask_reads_packed_vector

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_raw_mask_reads_packed_vector/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11599
- `line_count`: 70
- `sha256`: e9c72fae80a692c25a209a658dd01c0514b3031de5faea090af3bd1615aa3fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11599 bytes; lines=70; PASS=16; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_raw_mask_reads_packed_vector/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_raw_mask_reads_packed_vector/summary.txt

- `kind`: txt
- `size_bytes`: 315
- `line_count`: 10
- `sha256`: 5cc6837a9806fe18b68d7d0385a43b47a55289e0c58858069a685227b4cd0a37
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=315 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_raw_mask_reads_packed_vector - tool: Icarus Verilog version 12.0 (stable) () - PASS...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_store_request_terminals_early.make.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 7
- `sha256`: f0689a8fbf6a1ea11635f1845915c1d75ef277464aa4f3065d4ddd09b7573693
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=529 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_store_request_terminals_early.mutator.log

- `kind`: log
- `size_bytes`: 58
- `line_count`: 1
- `sha256`: f0b6e25db8d93dffb63aff7dc8b0ae4650e54498f25cd95d84c783debe2b8b09
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=58 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_store_request_terminals_early

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_store_request_terminals_early/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 11311
- `line_count`: 68
- `sha256`: 0eda58bd93307bf4bd995e35d5fb573cf3ee3a26f712a3e4c88a822f0775ce1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=11311 bytes; lines=68; FAIL=2; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_store_request_terminals_early/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_tracker_ignore_epoch.make.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 7
- `sha256`: d797543c5a78b44b7fb8569ac48812c94200c2faccf02724ae61c1879e732c3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=520 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_tracker_ignore_epoch.mutator.log

- `kind`: log
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: 01b4547fa00843a52a9b7b5d1ecbdd4835779578b979e054b7d31658a52b63f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=49 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_tracker_ignore_epoch

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_tracker_ignore_epoch/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12118
- `line_count`: 80
- `sha256`: 3ed31a2cb09488eda6422a874b104eb18bbc06a7f6fcf31a40c40ffbe961a8aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 16, "PASS": 14}
- `summary`: log evidence; size=12118 bytes; lines=80; FAIL=16; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_tracker_ignore_epoch/tb_ooo_int_back...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_tracker_ignore_kind.make.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 7
- `sha256`: ba8b485e5c9b99589ece4292e66d2ee12b2d4e4646a15131d8e4c4724e46aa69
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=519 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_tracker_ignore_kind.mutator.log

- `kind`: log
- `size_bytes`: 48
- `line_count`: 1
- `sha256`: 5d9f0ab4e811bd4a4dc637820cd0e5e329dd779616a98e730b77a062320d8034
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=48 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] backend_tracker_ignore_kind

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-backend_tracker_ignore_kind/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12177
- `line_count`: 81
- `sha256`: b1c3cb22cdba7ec33dc1fe372133b84d16e3e8829b166e7ae4bab76e5ed53a68
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 18, "PASS": 14}
- `summary`: log evidence; size=12177 bytes; lines=81; FAIL=18; PASS=14; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -DV8G_MEMORY_PRODUCER_LEASE_FOCUSED -s tb_ooo_int_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-backend_tracker_ignore_kind/tb_ooo_int_backe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_drop_reads_stage_advance.audit.log

- `kind`: log
- `size_bytes`: 93
- `line_count`: 1
- `sha256`: 905f80380115b8572b74e124a0b94dc0539b0cc1cf81902e80a342674ff4a87e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=93 bytes; lines=1; FAIL=2; tail=[V8G-MEMORY-LEASE-AUDIT][FAIL] bridge raw drop terminal reads ready/advance: stage_advance_w

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_drop_reads_stage_advance.make.log

- `kind`: log
- `size_bytes`: 628
- `line_count`: 16
- `sha256`: f0bb617ca79c8b901b4364b0603e69d9f6863cc1ec68d10241d77b10fe02152f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=628 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_drop_reads_stage_advance.mutator.log

- `kind`: log
- `size_bytes`: 52
- `line_count`: 1
- `sha256`: d74e19277ab80502fea7b9c765168f6d73f4ecae55d89648a4c547ea8d4938f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=52 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] bridge_drop_reads_stage_advance

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_drop_reads_stage_advance/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71273
- `line_count`: 546
- `sha256`: 20562c750bf42e2a18aa856587ed4c628fbb929943c19ec3c4d7cc02a4802db5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 17}
- `summary`: log evidence; size=71273 bytes; lines=546; PASS=17; tail=ry/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_drop_reads_stage_advance/summary.txt

- `kind`: txt
- `size_bytes`: 313
- `line_count`: 10
- `sha256`: 16c788f8e03cca615126792f2b693be72d45dffbfcc54f7a45ede9e3e0ee229c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=313 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_drop_reads_stage_advance - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_o...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_drop_reads_advance.audit.log

- `kind`: log
- `size_bytes`: 88
- `line_count`: 1
- `sha256`: 859456ddc8249030cf97b67d7833dcc8b43bf2d967b075ac9836702feffa8b4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=88 bytes; lines=1; FAIL=2; tail=[V8G-MEMORY-LEASE-AUDIT][FAIL] bridge station drop reads ready/advance: stage_advance_w

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_drop_reads_advance.make.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 16
- `sha256`: a4f7573be247208571ba744107ffe56dad4a8d831e98aec636e263e91fbfe2ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=630 bytes; lines=16; PASS=4; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract # NPC single module testben...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_drop_reads_advance.mutator.log

- `kind`: log
- `size_bytes`: 54
- `line_count`: 1
- `sha256`: 878b0ab9f9bdc637749efae598620d032f3e7c78f2aa4974a223a0e3684d1081
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=54 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] bridge_station_drop_reads_advance

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_drop_reads_advance/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71277
- `line_count`: 546
- `sha256`: 84dd7f7ccec8df3a354e51d681f5bb2ea6883a6fa0e709e2eafe490c9e374cb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 17}
- `summary`: log evidence; size=71277 bytes; lines=546; PASS=17; tail=ry/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_drop_reads_advance/summary.txt

- `kind`: txt
- `size_bytes`: 315
- `line_count`: 10
- `sha256`: 66fc4435005940ffc8a8e6dd686af36b62e8213eb50b1d6a37ddef77e54b0290
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=315 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_drop_reads_advance - tool: Icarus Verilog version 12.0 (stable) () - PASS tb...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_query_reads_advance.make.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 7
- `sha256`: dadec25450660d197ffd27a0ba521b26d98ae07a2d5133650aac3dcbfd0cd94f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=529 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_query_reads_advance.mutator.log

- `kind`: log
- `size_bytes`: 55
- `line_count`: 1
- `sha256`: ff9caad6f98e0d6a2a919d7238fda9efef32d26e2c3feae3b036e72010cbeda8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=55 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] bridge_station_query_reads_advance

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-bridge_station_query_reads_advance/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71552
- `line_count`: 552
- `sha256`: b5baebae810ef8bd2418dd06f02eba4e812a5e66f55f211d50561ff1a8204546
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 4, "PASS": 16}
- `summary`: log evidence; size=71552 bytes; lines=552; FAIL=4; PASS=16; tail=hecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/me...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_lane0_ignore_memory_lease.make.log

- `kind`: log
- `size_bytes`: 531
- `line_count`: 7
- `sha256`: 7c648a87705d4e3144061387ba0708bebf48d7457ecd93d1234e20767e6bb6ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=531 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_lane0_ignore_memory_lease.mutator.log

- `kind`: log
- `size_bytes`: 55
- `line_count`: 1
- `sha256`: 8cbd46ed345144df3a95b7f102046c8587ab13d72f1182f34da9ccb48bb41379
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=55 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] dispatch_lane0_ignore_memory_lease

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_lane0_ignore_memory_lease/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5271
- `line_count`: 42
- `sha256`: 4725e81873d841ce0de52640f776cad60f0ae12ea6421275f8533473e991946a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 10, "PASS": 8}
- `summary`: log evidence; size=5271 bytes; lines=42; FAIL=10; PASS=8; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-dispatch_lane0_ignore_memory_lease/tb_ooo_dispatch_backend.vvp /home/l...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_lane1_ignore_memory_lease.make.log

- `kind`: log
- `size_bytes`: 531
- `line_count`: 7
- `sha256`: 217dab6412537299cb80d77adf2759d7b1b095ad108e651ff09f9f9cff35f622
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=531 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_lane1_ignore_memory_lease.mutator.log

- `kind`: log
- `size_bytes`: 55
- `line_count`: 1
- `sha256`: 69c85c22e1506d36c7bf3954a65dc93ded7bd0ee199809b2c6761b4e1288182a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=55 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] dispatch_lane1_ignore_memory_lease

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_lane1_ignore_memory_lease/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5460
- `line_count`: 42
- `sha256`: 36f9247857d8277db236a90dd2bee6cb0e656d5dcf143449e009e1e2f11f873f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 4, "FAIL": 8, "PASS": 6}
- `summary`: log evidence; size=5460 bytes; lines=42; FAIL=8; ERROR=4; PASS=6; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-dispatch_lane1_ignore_memory_lease/tb_ooo_dispatch_backend.vvp /home/l...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_pair_ignore_memory_lease.make.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 7
- `sha256`: b4082b45213c79a273602acca36a40ba56b57c5303ec7746bce4c15b28e71578
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=530 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_pair_ignore_memory_lease.mutator.log

- `kind`: log
- `size_bytes`: 54
- `line_count`: 1
- `sha256`: 55d980879e910469b6adf98fd41dd9f1c3c7f08c1c4a02dbb1a2528261acdc44
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=54 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] dispatch_pair_ignore_memory_lease

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-dispatch_pair_ignore_memory_lease/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5210
- `line_count`: 41
- `sha256`: 18b3ec8fa4310fbd56d59d340b98ac085fd60c3a9cdea9d47283c2af6da06fbe
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 8}
- `summary`: log evidence; size=5210 bytes; lines=41; FAIL=8; PASS=8; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8g-memory-lease.guxixu/build-mutation-dispatch_pair_ignore_memory_lease/tb_ooo_dispatch_backend.vvp /home/ly...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_head_launch_ignore_done.make.log

- `kind`: log
- `size_bytes`: 511
- `line_count`: 7
- `sha256`: a67608baeacd37236f6233e9c4af38651b1bbcbde9505b4793d8d99df6f1b3ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=511 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_head_launch_ignore_done.mutator.log

- `kind`: log
- `size_bytes`: 48
- `line_count`: 1
- `sha256`: e4f393aa691f9671e1bdf055d799ad80eaa329eb7746895f499e1f7bb3b33537
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=48 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] rob_head_launch_ignore_done

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_head_launch_ignore_done/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1300
- `line_count`: 17
- `sha256`: b2d3118d3365f710b25a64c962b9370371238cd267fb95516a7c39c1ba0eff56
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=1300 bytes; lines=17; FAIL=8; PASS=10; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8g-memory-lease.guxixu/build-mutation-rob_head_launch_ignore_done/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/Ooo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_query2_ignore_done.make.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 7
- `sha256`: 82b7c778262352355ef8a1cef97be6a3c3063dc3163a9c96057e1307868bd7cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=506 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_query2_ignore_done.mutator.log

- `kind`: log
- `size_bytes`: 43
- `line_count`: 1
- `sha256`: c0540cd7a2609ab68808967ac36bb031521f104d104f7e29d8ab7b9407b95090
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=43 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] rob_query2_ignore_done

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_query2_ignore_done/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1517
- `line_count`: 20
- `sha256`: 094c1735eede1a2042be74fcbcd5c10c7e91b395855d10f8d621bd89d83786e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 4, "FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=1517 bytes; lines=20; FAIL=8; ERROR=4; PASS=10; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8g-memory-lease.guxixu/build-mutation-rob_query2_ignore_done/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/OooCsrTr...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_query2_ignore_generation.make.log

- `kind`: log
- `size_bytes`: 512
- `line_count`: 7
- `sha256`: ae7c708501e56129731aacd9f3583b860188cc2e419e0a9406a95e3b54492931
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=512 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_query2_ignore_generation.mutator.log

- `kind`: log
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: 6dcae93e69b20f6ec231cdf3979adead9adfa164b41605a9b9f4992146551062
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=49 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] rob_query2_ignore_generation

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-rob_query2_ignore_generation/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1318
- `line_count`: 17
- `sha256`: 1f3942a2ca21dafe6e12494cb90146f54a14179b7abcb529ff50c7f83c8fc794
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 10}
- `summary`: log evidence; size=1318 bytes; lines=17; FAIL=8; PASS=10; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8g-memory-lease.guxixu/build-mutation-rob_query2_ignore_generation/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/Oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_release_after_request_sent.make.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 7
- `sha256`: 2daa4092a5d6d42a619dda189c5e7e63e4f277b354746924ec57ecc70faab070
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=521 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_release_after_request_sent.mutator.log

- `kind`: log
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 88c14ad3ff0c3c0133e6cbc0884bde582bb1fa78b7348cf2bf7721da696a9022
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=50 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] sq_release_after_request_sent

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_release_after_request_sent/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 3092
- `line_count`: 31
- `sha256`: bfd3db12bacfb6c793b67e57027a21d3ab5fcc4f1aa69bf3953d6bd04c4c5068
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=3092 bytes; lines=31; FAIL=8; PASS=18; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-memory-lease.guxixu/build-mutation-sq_release_after_request_sent/tb_ooo_store_queue.vvp /tmp/v8g-memory-lease.guxix...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_release_ignore_full_pid.make.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 7
- `sha256`: 0b84807fc63f7f1a42a6667fb96e021c734c9b1aebaab86f7608a1f8ad278d1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=518 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_release_ignore_full_pid.mutator.log

- `kind`: log
- `size_bytes`: 47
- `line_count`: 1
- `sha256`: 939ac7d853d15d2ed4784cd6970c05cdaeafb15c3dc2ca0b39695d1a71a499e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=47 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] sq_release_ignore_full_pid

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_release_ignore_full_pid/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 3074
- `line_count`: 31
- `sha256`: 45c2a4d54c05be0b061a93b7f9bec6a3310205c8e129edbc2f6604029e47ef0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=3074 bytes; lines=31; FAIL=8; PASS=18; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-memory-lease.guxixu/build-mutation-sq_release_ignore_full_pid/tb_ooo_store_queue.vvp /tmp/v8g-memory-lease.guxixu/m...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_request_ignore_full_pid.make.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 7
- `sha256`: 7f0a84184fb87a2dbe1c1cfba57938224d93d1efd1c0d374777f9c2062b6f46c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=518 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_request_ignore_full_pid.mutator.log

- `kind`: log
- `size_bytes`: 47
- `line_count`: 1
- `sha256`: 831074b7badcac093b9a0e585de8366b6d973a5aca6cc95dc526cb3b5af7417e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=47 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] sq_request_ignore_full_pid

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_request_ignore_full_pid/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 3074
- `line_count`: 31
- `sha256`: 01e81e4a6ceae7c7dc35f36f6d8c94c9fb50b45d45416a3c6c2cc7aff3060711
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=3074 bytes; lines=31; FAIL=8; PASS=18; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-memory-lease.guxixu/build-mutation-sq_request_ignore_full_pid/tb_ooo_store_queue.vvp /tmp/v8g-memory-lease.guxixu/m...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_request_marks_terminal.make.log

- `kind`: log
- `size_bytes`: 517
- `line_count`: 7
- `sha256`: 08fc067f36fb5720f0776061a9a76adc734c8fc8e786875cab7744992ff5202e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=517 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_request_marks_terminal.mutator.log

- `kind`: log
- `size_bytes`: 46
- `line_count`: 1
- `sha256`: b05914eb9dd1fe4a38ead8b74135b5fc442bbc34d6a1589106f4c3278e678491
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=46 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] sq_request_marks_terminal

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-sq_request_marks_terminal/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2637
- `line_count`: 24
- `sha256`: a52456f39ed80285811125de40d1d15be0ec0a0735f26d5b48b3c758c20fba90
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 8, "PASS": 4}
- `summary`: log evidence; size=2637 bytes; lines=24; FAIL=8; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-memory-lease.guxixu/build-mutation-sq_request_marks_terminal/tb_ooo_store_queue.vvp /tmp/v8g-memory-lease.guxixu/mu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-summary.log

- `kind`: log
- `size_bytes`: 4772
- `line_count`: 29
- `sha256`: cbedf4869570b2ac873f819bf644606a1b3d4f0c0cf80e646d2fadb6868a5173
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 46, "PASS": 58}
- `summary`: log evidence; size=4772 bytes; lines=29; FAIL=46; PASS=58; tail=[V8G-MUTATION][PASS] tracker_alloc0_ignore_live_pid kind=tracker profile=standard test=tb_ooo_mem_owner_tracker target=[V8G-TRACKER-LEASE][FAIL] live lane0 PID either reallocated or blocked independent lane1 [V8G-MUTATION][PASS] tracker_dual_duplicate_pid k...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-tracker_alloc0_ignore_live_pid.make.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 7
- `sha256`: 6a647b5633498d67b31ee1bb472ac02b13dde5847075a0196241e1102d20502e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=528 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-tracker_alloc0_ignore_live_pid.mutator.log

- `kind`: log
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 55be6dd888530d1d17d1bb56b32e75d3a20f6a40319e08afb069c0ab6dd20c84
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=51 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] tracker_alloc0_ignore_live_pid

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-tracker_alloc0_ignore_live_pid/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1332
- `line_count`: 15
- `sha256`: 36f5f0d512d0aa0cc31c7f8eee8a7db78fd1b0308e2c489635e628ebb0d75efa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1332 bytes; lines=15; FAIL=6; PASS=2; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /tmp/v8g-memory-lease.guxixu/build-mutation-tracker_alloc0_ignore_live_pid/tb_ooo_mem_owner_tracker.vvp /tmp/v8g...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-tracker_dual_duplicate_pid.make.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 7
- `sha256`: 79cdb93d4f637397e831a1b69e784819a664f29138d9233f47e653c99f1908e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=524 bytes; lines=7; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [PASS] IFU ordinary-store/FENCE.I coherence contract make: *** [Makefile:302: /h...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-tracker_dual_duplicate_pid.mutator.log

- `kind`: log
- `size_bytes`: 47
- `line_count`: 1
- `sha256`: 01abe1adb17aac27b8d3cb607396924c2e399483985771e89903f4d10a2ac73b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=47 bytes; lines=1; PASS=2; tail=[V8G-MUTATOR][PASS] tracker_dual_duplicate_pid

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/mutation-tracker_dual_duplicate_pid/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1308
- `line_count`: 15
- `sha256`: 83393957c3fe29bfec6fdfb7a4316786d10170312e8c2dc6155220454a771edd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1308 bytes; lines=15; FAIL=6; PASS=2; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I../vsrc -I../vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /tmp/v8g-memory-lease.guxixu/build-mutation-tracker_dual_duplicate_pid/tb_ooo_mem_owner_tracker.vvp /tmp/v8g-mem...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/runner-summary.log

- `kind`: log
- `size_bytes`: 5311
- `line_count`: 33
- `sha256`: f6b857177d93d100961023c0ca0ae77c4dbdf2366e1facc3d9b6681a159a7e8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"FAIL": 46, "PASS": 66}
- `summary`: log evidence; size=5311 bytes; lines=33; FAIL=46; PASS=66; tail=[V8G-MEMORY-LEASE-AUDIT] PASS tracker_edge_old=1 dispatch_q_only_lookups=3 rob_query2=1 sq_full_pid=1 terminal_raw_lanes=5 response_classes=3 physical_launch_chains=2 bridge_ready_cut=1 local_ready_cut=1 buffer_ready_cut=1 station_query_q_only=1 station_dro...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/sources.post.sha256

- `kind`: sha256
- `size_bytes`: 3473
- `line_count`: 23
- `sha256`: d31e1dc01fa29b95f2677ab5e2cf2ed66c00750823014815bd41a4f4e9499167
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3473 bytes; lines=23; markers=<none>; tail=d23d6deed7f13a7256de066ce673c74995dfcee97b50236b268a74ed8bb599f2 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/contract.md 9d08f819e1fe27e66ed58ded91903ebaec8db7ab38cf4a93aaa8e0f8455e2846 /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/sources.pre.sha256

- `kind`: sha256
- `size_bytes`: 3473
- `line_count`: 23
- `sha256`: d31e1dc01fa29b95f2677ab5e2cf2ed66c00750823014815bd41a4f4e9499167
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=3473 bytes; lines=23; markers=<none>; tail=d23d6deed7f13a7256de066ce673c74995dfcee97b50236b268a74ed8bb599f2 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/contract.md 9d08f819e1fe27e66ed58ded91903ebaec8db7ab38cf4a93aaa8e0f8455e2846 /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/structural-audit.log

- `kind`: log
- `size_bytes`: 295
- `line_count`: 1
- `sha256`: 7a6bca438cbfbbc9fbb9ec316bf9c11b30b12493bd317e9157030c10eab4141c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=295 bytes; lines=1; PASS=2; tail=[V8G-MEMORY-LEASE-AUDIT] PASS tracker_edge_old=1 dispatch_q_only_lookups=3 rob_query2=1 sq_full_pid=1 terminal_raw_lanes=5 response_classes=3 physical_launch_chains=2 bridge_ready_cut=1 local_ready_cut=1 buffer_ready_cut=1 station_query_q_only=1 station_dro...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/focused/summary.txt

- `kind`: txt
- `size_bytes`: 420
- `line_count`: 15
- `sha256`: 11055b6b8c912a9d8cc26331485af0666af3a1b436fca97df868a293b6d932d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: txt evidence; size=420 bytes; lines=15; PASS=6; tail=V8G_ASYNC_MEMORY_PRODUCER_LEASE=SCOPED_GREEN RELEASE_STANDARD_BASELINE=6/6 RELEASE_BACKEND_FOCUSED=1/1 ASSERT_STANDARD_BASELINE=6/6 ASSERT_BACKEND_FOCUSED=1/1 STRUCTURAL_AUDIT=PASS COMPILE_SUCCESS_MUTATIONS=29/29 POST_LAUNCH_STORE_AMO=PASS CONTINUOUS_WB_COM...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: 78fe2bc6a614d3ff46450b0451b5c145bacdaa2dac7ce1df273d117ac47ea860
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/v8g-full-module-final-build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 404
- `line_count`: 5
- `sha256`: 0c5cb156ecce079f51ded70169d2931fd1fa2ffc8a33777a8f359aacca8d3497
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=404 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/v8g-full-module-final-build/tb_axi_clint.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3504
- `line_count`: 28
- `sha256`: c8a266aa85f8b2d18aab61837302f1e0c278064a3a9a698de728efa29948f87c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3504 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/v8g-full-module-final-build/tb_axi_exec_firewal...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 512
- `line_count`: 6
- `sha256`: 3d71102224e35f4f779c53f97453ea5ca9c4dcb3b70101a1fc5fdc1138bed1e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=512 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/v8g-full-module-final-build/tb_axi_plic.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 6
- `sha256`: c126d4525c34195cb0d7c6e62690204d86d5c490b9a18dbacc975b3180a3b939
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=601 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /tmp/v8g-full-module-final-build/tb_axi_reset_syscon.v...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 86af9f9d07a876094040cc369c942f418597f32679843d2b74ae3f29a8c01f6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/v8g-full-module-final-build/tb_axi_to_uart.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3284
- `line_count`: 28
- `sha256`: 5c4b16d61b02f3c17c88add32d6000b9b4f92052be96ae6f4ab9a4afa3d2799d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3284 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/v8g-full-module-final-build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 399
- `line_count`: 5
- `sha256`: eb22e90830bb8b88dd29acfda3aba0ffa429d8f6adc8e5488bdfd15fa66fe9a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=399 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/v8g-full-module-final-build/tb_compare.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 399
- `line_count`: 5
- `sha256`: 6fd5a60879a0f226526781b33e5aabc65ea837919080c5f5766e10ebba0d4d8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=399 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/v8g-full-module-final-build/tb_csr_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 543
- `line_count`: 5
- `sha256`: c7660de9c668b5a52bf91712fdb6b2594c3b471c4b52fe7f8122c1ab4ef0ca0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=543 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/v8g-full-module-final-build/tb_decode_stage.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: cb8aee5269820c98965e6de7e05277aecd6740348274f9d3ff235bf6c6a763da
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=418 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/v8g-full-module-final-build/tb_decode_unit.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: 32c679cf94db45115d0ec4ffd1e0351fd5735749deb4749679f8abcc3e19c900
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/v8g-full-module-final-build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: 6e78fd96d292d645443b6298840171f4bf0f3181b6a60f9e1926d2d73e9a461b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/v8g-full-module-final-build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: baa22008a0c72ad0fbab2b9f448abcdd5659d2a4877567cb41dabdb9a7f36d9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/v8g-full-module-final-build/tb_lsu_control.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 423
- `line_count`: 5
- `sha256`: 5389b50d8dee01b0f94207c40316727ed8772ef98c2ac36f0d51501e32c97798
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=423 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/v8g-full-module-final-build/tb_lsu_datapath.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15859
- `line_count`: 96
- `sha256`: f4f213158fd6b7d3a540d9af6350b9d579edd6b3db165c408151cd9a453f99fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15859 bytes; lines=96; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/v8g-full-module-final-build/tb_ooo_alu_core_s...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15687
- `line_count`: 94
- `sha256`: faf8a087b0aa84784412a3489d209859612dc411ecd78fa5dd222542a65db8f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15687 bytes; lines=94; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/v8g-full-module-final-build/tb_ooo_al...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 423
- `line_count`: 5
- `sha256`: b39286300a04182b28f919cc576b60cc1b1be5725d1827622c2f112200aaaa29
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=423 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/v8g-full-module-final-build/tb_ooo_amo_gate.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: 19df62f5ebeb076213745e31d130788f43871c75b7bd79b9b529f9cfa8a21433
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/v8g-full-module-final-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: fd0e1973d0a8f5d7b4d7428d7150a08ffc2f6cb82de54fdd0acedbd5436f8c6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/v8g-full-module-final-build/tb_ooo_bitmanip_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 880
- `line_count`: 9
- `sha256`: ee68cb1cd6acb79d738f547bca258ea1de2717a605472156430d64645d6225a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=880 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/v8g-full-module-fin...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 835
- `line_count`: 9
- `sha256`: fbb2fb0493dc394fdbee4a095d596a0199326d54f852e9214d2fea378c968d65
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=835 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/v8g-full-module-final-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 5
- `sha256`: 0d1a6ae58b4cfbdb36f2ef40e85ebd26f9e07903652a453f303701411225a8c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=618 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/v8g-full-module-final...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 890
- `line_count`: 9
- `sha256`: 04bc22798849b759b455ed985f5c893a14321baabf2e09e8741fcb65a924b021
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=890 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/v8g-full-module-f...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: c77d29612cc60e85710aac3743154949642ba35a2c2fef495260543dcf6d1002
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/v8g-full-module-final-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 575
- `line_count`: 6
- `sha256`: 178e5a6962759251cb05b4cb36235d535d2c5912e6643efeb432dbe8d9681b05
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=575 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/v8g-full-module-final-build/tb_ooo_busy_table.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: cfe73d8eebf5cf1567980bb3355c9955c3747f9c47def5f191cd3024384e591a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/v8g-full-module-final-build/tb_ooo_clmul_unit.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 793
- `line_count`: 9
- `sha256`: 0b6f5b76ec7f2845dfddbddf1dd7565e734fdc17a6004dff9e5ca077694b7022
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=793 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/v8g-full-module-final-build/tb_ooo_comm...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 858
- `line_count`: 9
- `sha256`: e4b9342ae2916c5513a1889d6260f0196c226eaaa8984e3a840e0858e03f6823
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=858 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/v8g-full-module-final-bui...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 845
- `line_count`: 9
- `sha256`: b1137848b8e790614200460b8416b07c83bd9b2709d804140be3e11f0d02b576
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=845 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/v8g-full-module-final-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15923
- `line_count`: 70
- `sha256`: 46a1b078953a9a0c92124931ce742b73a2e9be4df983866828857730d504ab8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15923 bytes; lines=70; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8g-full-module-final-build/tb_ooo_core_top_glu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 523
- `line_count`: 5
- `sha256`: f65b7b27b6a4238502c9e461c685b51ca342963dd479566b1acc5c682ad1c903
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=523 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/v8g-full-module-final-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 509
- `line_count`: 5
- `sha256`: 3eb4c7e4ae265a377eb0bc5609aa36f45b40b3b8e6fbcdb494ad1aabc2f0f5ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=509 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/v8g-full-module-final-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 5
- `sha256`: e171ee02cf745cf28adfb6b21e848de4d57ca30ac1e34b1d647a3e9e88803bff
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=601 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/v8g-full-module-final-build/tb_ooo_data_wor...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 531
- `line_count`: 5
- `sha256`: 45f31cbfd9604dc514bf92a85d581bd8eaaef739701742399343541c59850bc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=531 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/v8g-full-module-final...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: fc13ea1f260ae1ac712cc3cae4cc4846311477058b3d9e8fa6ed8035f218bee4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/v8g-full-module-final-b...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: e226739249c8b8ce4501759fb1373f604572536343b5e23ac7bec703525f1fe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/v8g-full-module-final-b...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 4952
- `line_count`: 35
- `sha256`: 29d94c70e40c5df8ee36ddf8dee674143a28e71aa06055739444cf4ad98f6df9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4952 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8g-full-module-final-build/tb_ooo_dispat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106892
- `line_count`: 846
- `sha256`: adee789621ec9b33ef9394871e0b3f3ec497a2047437bf820cf7b5c2c6e7d571
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106892 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103635
- `line_count`: 779
- `sha256`: 97b431efe3976b7cc25499a06d4c730c815716fbd84d54ca1fed79b0cbe12774
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103635 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104439
- `line_count`: 788
- `sha256`: a4ca09f17c68c83f2b7dc3f6695d9e00d7d2d770103c9b2f8f8ed6c49e7e80f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104439 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106572
- `line_count`: 802
- `sha256`: 472c687d63256f57c2f8bf72f09e333a4ace148b92927c2363c09b7528234c53
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106572 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: 57c9e610a1010dae453c20a07f7abab7a0975124e949de0d4b63577adb497dd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /tmp/v8g-full-module-final-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 80760f370ed0c886051f792b12cc70bac31c63d1e34d400bda9083d21055bb7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/v8g-full-module-final-build/tb_ooo_fe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 660
- `line_count`: 5
- `sha256`: f3e4d6818cbd019613ce7b4a18bd122a7ac86379c9d2fa79694a9005f94c552f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=660 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/v8g-full-module-final-bui...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 712
- `line_count`: 5
- `sha256`: bfdb32c031d257c0325e420ed67ef3789efa26aca18a4556bf028e03046815ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=712 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/v8g-full-module-final-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 621
- `line_count`: 5
- `sha256`: 088f010d0e0048b08ee4029715e66d64c5eaa39bda85b29a9dee14c3a8b6f043
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=621 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/v8g-full-module-final-build/tb_ooo_fe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 632
- `line_count`: 6
- `sha256`: 742be3b54cf8419e2c3ead6864c4e44101aa24b7d47782c32ac8f92539af3c34
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=632 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/v8g-full-module-final-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 811
- `line_count`: 10
- `sha256`: 3d099d70c915e71b4ceaaafb9ae141307c9b749ce8c59e894980683b4a845140
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=811 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/v8g-full-module-final-build/tb_ooo_fetc...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 500
- `line_count`: 5
- `sha256`: 9eef664fce2d70f9ff28ea7874220f8e6d0a7b74aa247c9b7b5a50328e8ca9a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=500 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/v8g-full-module-final-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 5
- `sha256`: fbe003b4843c720d93bb3dbad2a37adca4a7cf5aa586151b1f00e5092e9996b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/v8g-full-module-final-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106434
- `line_count`: 802
- `sha256`: 3b5006df81cef45100c16928102360d54b1505a2fae807f45dafe320c6f2dedc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106434 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: b753a6912f6a91d2c66ff7909a52f9f1b3fd871aefe6d8d27e9804b4b795374e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/v8g-full-modu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: fa49c28ca17c0266743e96a79672e798a1ee556595c7dd4574e05c805d6b93cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/v8g-full-module-final-build/tb_ooo_fetc...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 990
- `line_count`: 10
- `sha256`: 2f731c8b908865e61e976672fc8a9a63ea6d686aa82fe2ed82f0ec8fabd74e73
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=990 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /tmp/v8g-full-module-final-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18710
- `line_count`: 86
- `sha256`: c511d003dc83be202cbc64e97c1aa0b621e528bd86100ea7cdeae0b4c0f6aee9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18710 bytes; lines=86; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fetch_tr...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: b0caec917fb9f227b1078f4c5ae636b76337da4349f344eb8efaa2a8d307493a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fp_arith_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: 745375679446a271d9e5219daadcb6b3226777185cddb8aec5956259d335bc61
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fp_cla...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: 88afe2bafff3ae9ebc1ae51d4033166cc11790293b9eb44e852d516460964ee0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fp_compa...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: 041d251e1604f1575da61ed3254bef9a7df8fc2caab678f5cb05a5bb8d0c7ba6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fp_conve...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3670
- `line_count`: 36
- `sha256`: e2f1c62bc7131b860be88b9889a515a1100d5faf4a24399edea9e251e5447c08
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3670 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/v8g-full-module-final-build/tb_ooo_fp_issue_q...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 489
- `line_count`: 5
- `sha256`: c124243611978e0754078ec44083d46d4cddd5ae5ac12d8060333ef177986516
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=489 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/v8g-full-module-final-build/tb_ooo_fp_iter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1646
- `line_count`: 14
- `sha256`: 8ede956a8612c0f6f8ddfbe85dc841437586325acf78a64527d47ccf19e9b437
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1646 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/v8g-full-module-final-b...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 596
- `line_count`: 5
- `sha256`: ea281e857b9ab9ae5d9a38d9aafce0a19ee3df1565167cf1c66744cd443eb164
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=596 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fp_long_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1003
- `line_count`: 12
- `sha256`: 76a411a3ef2633ae3edd83f3eb65f3cf982d27eb98c1dd22dd64b7c70604e4eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1003 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /tmp/v8g-full-module-final-build/tb_ooo_fp_phy...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 750
- `line_count`: 9
- `sha256`: 9c058feb5a1f0022b90e750426e4cb7f60179d9db4f6041a8aeda6feca56fd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=750 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/v8g-full-module-final-build/tb_ooo_fp_reg_file.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 446
- `line_count`: 5
- `sha256`: b3a99e74e97e995eeb4ed39fbc4a599f13c82b74c634a34a374b427942b3c9b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=446 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fp_sgnj_gate.v...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: d3a6050f55ac99ee37a71dd29c43afbb23c48f22e628f1532d7f104216fb61fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/v8g-full-module-final-build/tb_ooo_free_list.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: 06f3b4c18a6693c42b934dca3aa7cc1f5c6106b44d9a42ca902e91ca24579b15
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/v8g-full-module-final-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 904
- `line_count`: 10
- `sha256`: 56a6010e5e0973e524feff3507b733cda3070bd85f7dcd45a528d35aedf9680a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=904 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/v8g-full-module...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 816
- `line_count`: 7
- `sha256`: 88547ef190ca9290afd11d7e62faa56298f61d49091586e7669477bb992b194b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=816 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/v8g-full-module-final-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: 4e3d66c70452564f39c38921fac8b3ebee9c398d40dff4e3b53a65451200562a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/v8g-full-module-final-build/tb_ooo_fron...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 219e79950967f95e80831e2afb8ce126b4a94c25e1cd786feab0547d4a264594
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/v8g-full-module-final-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3847
- `line_count`: 34
- `sha256`: e0ac83af4b380c748776fc02ddccb4c84825bc78740f2f0a6ab4386a6a316fb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3847 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/v8g-full-module-final-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14251
- `line_count`: 109
- `sha256`: a8df0fc843906e6ea9362f2d2552a28c073245e2b9a76ac24ed355dfadce9b80
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 2, "PASS": 38}
- `summary`: log evidence; size=14251 bytes; lines=109; ERROR=2; PASS=38; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8g-full-module-final-build/tb_ooo_int_backend.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7928
- `line_count`: 78
- `sha256`: c281474a7d5746fb7950cb52ded2c2bcca358a9821808f9f1a03b3ba8d1f12c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=7928 bytes; lines=78; PASS=14; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/v8g-full-module-final-build/tb_ooo_int_issu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 848
- `line_count`: 10
- `sha256`: 1ccb572c563323da6632a10a16965a7b1e282dbd6e10d58246b2b9dccc1aabe4
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=848 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /tmp/v8g-full-module-final-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71278
- `line_count`: 546
- `sha256`: e00ffb734d4c8238d129b047179532a61729293b09594782fb620b8a909d3731
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 17}
- `summary`: log evidence; size=71278 bytes; lines=546; PASS=17; tail=ry/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1126
- `line_count`: 10
- `sha256`: a50feba043ba952c9fbb694790456720646cbd2f17d7eeeeaea390c62187c539
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1126 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /tmp/v8g-full-module-final-build/tb_ooo_me...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1161
- `line_count`: 12
- `sha256`: af8ef205a932f8c2e6cdfaf9dfdd9661694ffaa06d2352095b13bbee1f9976cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1161 bytes; lines=12; PASS=6; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /tmp/v8g-full-module-final-build/tb_ooo_mem_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 948
- `line_count`: 8
- `sha256`: 8f29d492d86694977a844a8fcc34de2b158e4d29e3c75871b118b3f1493ee077
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=948 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/v8g-full-module-final-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 703
- `line_count`: 8
- `sha256`: 479a5dc3a87aa2adac4fbd0c4d1074c4403a022b675d117b37d65242c66b1602
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=703 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /tmp/v8g-full-module-final-build/tb_ooo_mmu_epoc...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 446
- `line_count`: 5
- `sha256`: ad047e91bb8fb05cbddffcc718530e63c7bf92a6fa735e45ce48c60342210a2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=446 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/v8g-full-module-final-build/tb_ooo_muldiv_unit.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1172
- `line_count`: 12
- `sha256`: aa789a5a13d1d774b4928a3b42c55e84d2efcb53ab9bdb06cd713083deaee97e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1172 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/v8g-full-module-final-bui...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 5
- `sha256`: 26269c99af60ba6492cb5969c02b59886088a51db5a7486a4be97792c93b17bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=530 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /tmp/v8g-full-module-final...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 960
- `line_count`: 11
- `sha256`: 8e9cd4c1aee603dff7ddfdb173bd310706bda9481904141dfe6e393b97421f0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=960 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/v8g-full-module-final...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 854
- `line_count`: 9
- `sha256`: 7611fb54c9b3a546f0e68b5d60d8fe8992d913f4ea406753a2197e4c8aea7f9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=854 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/v8g-full-module-final-bui...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 558
- `line_count`: 5
- `sha256`: f4989708737930839d4afc34a67e9478401de209c6f8e65049d8eda1d006bd03
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=558 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/v8g-full-module-fin...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: 2e2dbc1b3383760e5878138f845bc64578b97e6c47441f63c8a71ee8db3fe7f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/v8g-full-module-final-build/tb_ooo_phys_reg_fil...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 582
- `line_count`: 6
- `sha256`: 88c3b20cd04ddc5d45d7d54ad36c89949aad1921cc9d5081d0013163d6f35f68
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=582 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /tmp/v8g-full-module-final-build/tb_ooo_pma_checker.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15714
- `line_count`: 65
- `sha256`: 84aa416d8b10f3f5246baa630277f4da901a9147816de79ef085d9983ad2d550
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15714 bytes; lines=65; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/v8g-full-module-final-build/tb_ooo_priv_system.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: caa0265719253d4900cb126651f6a997ef2cace3a49a90e3de3287e9026fc00b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/v8g-full-module-final-build/tb_ooo_ras_upda...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 1355caf150698958b02659320c49dc03cb872afa188d62a224ed51bd79adece7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/v8g-full-module-final-build/tb_ooo_redire...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 45de1320cb4b7deab3e22fc1dd090f3dfad8208ed0e550fde1177d180e24ba6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/v8g-full-module-final-build/tb_ooo_rename_map.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1084
- `line_count`: 11
- `sha256`: 3d5d9a7a9ca17b263099c1d164c56fa307eb5d7f5b63e3665dc896607e5bac39
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1084 bytes; lines=11; PASS=12; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8g-full-module-final-build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 836
- `line_count`: 9
- `sha256`: 16f3a71e2a8327d4c22d238c37f320741bebf419c472bdd45e443d01aff8caca
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=836 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/v8g-full-module-final-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2648
- `line_count`: 25
- `sha256`: 542e16f727edf131949a1bf35c3737b9d4df0d9d0817aa4a07067f871d26f117
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=2648 bytes; lines=25; PASS=20; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-full-module-final-build/tb_ooo_store_queue.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 208180
- `line_count`: 1513
- `sha256`: 9b96b7421477ac924b9b7569fed7560973691d4c8f47c01b1b011b1453f2263a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208180 bytes; lines=1513; PASS=2; tail=rning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker....

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: d28593429e1ec81923ff0dc4c5318c45f6177a1decf3e3bd03ce3e9138e29cff
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/v8g-full-module-final-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 551
- `line_count`: 5
- `sha256`: cd87bd56e31e656c4bfe83c5c2bd3637ed3c2cb8fd885408204617991b680a7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=551 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/v8g-full-module-final...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 6
- `sha256`: b0073dec99176cc68639c13ea941171d2680ee2486ab78133ee94c5fb7931ab2
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=602 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /tmp/v8g-full-module-final-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: aa898aa3fc12366acd609d925aba2a1f01b4d8f8320546dc107fd5349ed88f2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/v8g-full-module-final-build/tb_pipe_stage_reg.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17564
- `line_count`: 134
- `sha256`: 74326ae51533be739d600cfe78cefabdc50b21bc9be827af5be01c098be06602
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17564 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/v8g-full-module-final-build/tb_pmp_checker.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 375
- `line_count`: 5
- `sha256`: a2b1b839ed265de79d3902d5a927d4ba757bc26669aac4fe88fb7602e24db40c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=375 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/v8g-full-module-final-build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 996be4959658175e79d6fd4df7f1829d8a2f478f0fb76076f56c09401ad0c31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/v8g-full-module-final-build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final/summary.txt

- `kind`: txt
- `size_bytes`: 3495
- `line_count`: 114
- `sha256`: f2f934bcefc502c1bfc922bef37a8292c95f12015cd6ed45ce91593671fbf8e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 210}
- `summary`: txt evidence; size=3495 bytes; lines=114; PASS=210; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate-final - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 366
- `line_count`: 5
- `sha256`: 06fcb750324f374d90b450cd0a8df8b9fd9130f97befbfe26df232a0a0b43cac
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=366 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/v8g-full-module-build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 398
- `line_count`: 5
- `sha256`: 0da7b5b7b45c7c0669e1a1e47b29cbfafe1a6bd46d984de213a465f46d324fc5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=398 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/v8g-full-module-build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3498
- `line_count`: 28
- `sha256`: c59285544f672bf3a26b098e6ec4072e4b7ca98fae7994f3f8bd08119ccd1392
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3498 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/v8g-full-module-build/tb_axi_exec_firewall.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 6
- `sha256`: bae56de3d515ed00221abf0aef1660b3b0e722e157ab321fe3cdad6a78d09506
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=506 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/v8g-full-module-build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 6
- `sha256`: 4e5a7b71454dd66a3b227689359bd8ea3e49f90700e4cb6618f8e76d6616bf74
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /tmp/v8g-full-module-build/tb_axi_reset_syscon.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: 1c8f605dea0970f4da2602480b806f0523e710ba9af0fb542a87b28f1a2a3176
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/v8g-full-module-build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3278
- `line_count`: 28
- `sha256`: e9a9376ebfbf5bdfe53745e3c2f8e29ba2b2b164eb8ebc6fa481abcc2a4b3719
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3278 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/v8g-full-module-build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 393
- `line_count`: 5
- `sha256`: 983e2e6524a90b5ee55f2179e8b2ff7078ed9d1071f45bc3df11dbd9210962dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=393 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/v8g-full-module-build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 393
- `line_count`: 5
- `sha256`: e81069c794aae4483974770010dfbdac8f16012c42886da23218c4edb8e6b9be
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=393 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/v8g-full-module-build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: ae90bf01d5cf8b90c381bdb764f630ea298f22d8b990fc757bcb9e3d985dc6ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/v8g-full-module-build/tb_decode_stage.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: f6e13423d33d65512a082f5d1e27554a80443ed4c67ffe575cd199f82bc512ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/v8g-full-module-build/tb_decode_unit.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 382
- `line_count`: 5
- `sha256`: d47408d2060cb0722a8c047fdb6c3c25bb1f392f2ebb333c75f1cffacffcc27c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=382 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/v8g-full-module-build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 489
- `line_count`: 5
- `sha256`: 20bdcb578d0e538f7fb8fa9d854fa6ef06d503f6412ebe08bc013b68182bd570
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=489 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/v8g-full-module-build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: 8ca1f8c4341f4ea229cf51c4812c796e175f829258166beebaba3e0ace58d448
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/v8g-full-module-build/tb_lsu_control.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: d78d860206bc79a5cb4feee794f7ae9b6177c41c7510ecdd5f95063d2f63a750
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/v8g-full-module-build/tb_lsu_datapath.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 15853
- `line_count`: 96
- `sha256`: 73156da26a8974b8ca31473558699bbf1090b5f8e84f75084a8fb90976413e37
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15853 bytes; lines=96; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/v8g-full-module-build/tb_ooo_alu_core_slice.v...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 15681
- `line_count`: 94
- `sha256`: 44d5aff3ab4eae280939be99a899be77ddd5e899eea15db4fb883fdaea1b0db3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15681 bytes; lines=94; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/v8g-full-module-build/tb_ooo_alu_deco...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: 10e82bb84758e71c2b407aec2ea9302f97e1a77f8865b9fc3453e9ba02661c5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/v8g-full-module-build/tb_ooo_amo_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: dea6b3d7c8d8cad952fed934cef906a391839b7df2d8dd3209b8e287cc1f804d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/v8g-full-module-build/tb_ooo_ba...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 052075522977475d4f31cdf93fb3fffbd140dcd28492655efe0fcca80b0ac335
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/v8g-full-module-build/tb_ooo_bitmanip_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 874
- `line_count`: 9
- `sha256`: 14d0fc9075cbdf78b6e433a9b59785c0a5753e9090d618544af18db5ca1aed06
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=874 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/v8g-full-module-bui...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 829
- `line_count`: 9
- `sha256`: 957c13226813cbd0ea28fde3ef2a72abaac139219b5943d3f56eddac93d19e0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=829 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/v8g-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 612
- `line_count`: 5
- `sha256`: e1ea6bfbe4e6ec92df354dd09541e488fe43507b8602fa7425c7d0f93a401ee1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=612 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/v8g-full-module-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 884
- `line_count`: 9
- `sha256`: 5878c5352e92261bc09752f16b8fa39f20d1c79cdc9e946c4e17d9073d8e2581
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=884 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/v8g-full-module-b...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 338a739a4675a488a9aa00e0a311d6dc89d4643f5d4d1eed72590d0661092747
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/v8g-full-module-build/tb_ooo_branch...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 6
- `sha256`: e70c37ade50aba34840bca30dd28de1422885e88f74c208a519766f181395f4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/v8g-full-module-build/tb_ooo_busy_table.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 432
- `line_count`: 5
- `sha256`: 37f6699c93c10965b1be08fcefc01f985ffd064b39fca2f6da06e9c7f8f800b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=432 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/v8g-full-module-build/tb_ooo_clmul_unit.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 787
- `line_count`: 9
- `sha256`: bdb881683eb4e81d10a528ec03b21be791f92d6fac7adf000468d1c96dfabc3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=787 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/v8g-full-module-build/tb_ooo_commit_out...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 852
- `line_count`: 9
- `sha256`: a6a3c0b910eb5ececb0cf51c8e3e69aa0d8fe6ae3010c7730a6f630ce819413c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=852 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/v8g-full-module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 839
- `line_count`: 9
- `sha256`: 6e283cca5c444621aac8af5994425652667ec539bcbf1b5b7a0c03bd4c33121a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=839 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/v8g-full-module-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15917
- `line_count`: 70
- `sha256`: 289fe09191795868d0fc576fa48e9233f0d4fe968eca026be9b0c418140dc248
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=15917 bytes; lines=70; PASS=8; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/v8g-full-module-build/tb_ooo_core_top_glue.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 517
- `line_count`: 5
- `sha256`: a7fcd93ef5012207c50db6bac2d5cecc72122373cd69b96c03d23e777b8c448b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=517 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/v8g-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 009f09ab29cc6c7ad2df5805d37e0863acff54693e102855dbe321c4ab767d93
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/v8g-full-module-build/tb_ooo_csr_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: 964458478cc5b3ab89a172f6fb988dcbc168d21b034ee19695996c182a4855e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/v8g-full-module-build/tb_ooo_data_word_cach...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: 3f3e9582711ea40977c86aa76d442c591ba9f90e08e29d95cbb2f04fa0d4f9b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/v8g-full-module-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: cd6045758557fc6e7b26556d6c66247c887ffad4296d5fee4a7feb91e737804b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/v8g-full-module-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: 06f54fa6ed250e9a361d94a42874bcdbca698f9d3f3a94a2fff1dc672a64a37d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/v8g-full-module-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 4946
- `line_count`: 35
- `sha256`: e4fddc1b78be8629b68cb4889adce388093c08b6bbf914db6ea478c643bcdc3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4946 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/v8g-full-module-build/tb_ooo_dispatch_bac...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106886
- `line_count`: 846
- `sha256`: 0b4788cbb7f8a5604f7f47f19d560422e622f921a59f4ac502cdc0fe514746fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106886 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103629
- `line_count`: 779
- `sha256`: 8cf7ad0f4548243758c6e4c00a147e5e9e478208fa4cf67913a3a70aeb3ba5d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103629 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104433
- `line_count`: 788
- `sha256`: aa98f6676433700c49c25257af8dd48e899f495cc4bfd85dc4d1e2bb1c293d8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104433 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106566
- `line_count`: 802
- `sha256`: 18e57f7fa3c0e7ba997579de02169989327500537bea3dff1dc1b63f130aec8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106566 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 5
- `sha256`: 9d4990437307f35ca06c5ac5eb777e22bc3d88c2923269f90e1216384cdd5c86
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /tmp/v8g-full-module-build/tb_ooo_fetch_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: 300d37dacde2868d1725a37679ea99bba4f6357cd8e18ee12c3736f96fa8797b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/v8g-full-module-build/tb_ooo_fetch_fl...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 5
- `sha256`: 019bcaf3e6d022cb91fc3404815543b7f4398ba83aaf0854696cbbfc5b094be5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=654 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/v8g-full-module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 706
- `line_count`: 5
- `sha256`: e40b81fa2bc41cf59254ccd0f772a61e58721e69c85014ddd6db03034641fe79
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=706 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/v8g-full-module-build/tb_ooo_fetc...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 5
- `sha256`: 83da54ec4da88db0b9343f80f7775dde185a0bf99428bc6c747d6379c963ff16
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=615 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/v8g-full-module-build/tb_ooo_fetch_pa...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 6
- `sha256`: 39e3aa5347d8926a8e8e882dec9fa04fbb97dced4d832473248d5bfa008c1f1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=626 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/v8g-full-module-build/tb_ooo_fetch_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 10
- `sha256`: b081e7e247b42cec38633209910acc1cbfcad50800084bfdcaa1983f2ceaedca
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=805 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/v8g-full-module-build/tb_ooo_fetch_pack...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: 3e982842ba208c35c0a69f9b103eb8a790303274776daf9111199dd5454e535d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/v8g-full-module-build/tb_ooo_fe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: 596c2ceaa9cec064d5d7924c7242fbe61054c1baa6c375ddbe58080014d49c4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/v8g-full-module-build/tb_ooo_fe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106428
- `line_count`: 802
- `sha256`: 63d0e36cd786b2ca42a083b523c55cd313fae0c2a6922e873fa1f59fcd2ab6f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106428 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: f40fbc7ce8d1b4941a1425d06250991226c67e96989ca70dd45493366f58b944
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/v8g-full-modu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 24550b3a364b93fc34b3aad1d09ea574e1a6251a44f6ec8acee14bc6332e03b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/v8g-full-module-build/tb_ooo_fetch_requ...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 984
- `line_count`: 10
- `sha256`: b867ec27bd28d4cd3c91e85b4c5afe370faf92ad48965e4144eb78c5ee499463
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=984 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /tmp/v8g-full-module-build/tb_ooo_fe...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 18704
- `line_count`: 86
- `sha256`: ef9779cfe972032bef0997197f726e794f6171cb53d76eb2195c4822af887806
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=18704 bytes; lines=86; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/v8g-full-module-build/tb_ooo_fetch_trap_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 448
- `line_count`: 5
- `sha256`: 2fe6017640d4c73fb833f15d1445cd28993bd078ffe8193de634b443acd83080
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=448 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/v8g-full-module-build/tb_ooo_fp_arith_gate.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: 904c00046d7fd6db79d44c84adf2efe5075e1fff29f61a2bf1107d9b46ef6247
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/v8g-full-module-build/tb_ooo_fp_classify_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 459
- `line_count`: 5
- `sha256`: 7fd745a8c9755fb6c873c3e3ded51a247350ff27b11ef1f6b880ad65bc39b611
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=459 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/v8g-full-module-build/tb_ooo_fp_compare_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: fc98054c7b45c4d7dc038c4c5f0067deba36d029e8db2e4825244f4c750fcaa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/v8g-full-module-build/tb_ooo_fp_convert_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3664
- `line_count`: 36
- `sha256`: 973cb12da757829d4b33e90d58e23a5eaaac470636d44b7b326a83ca061d0f1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3664 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/v8g-full-module-build/tb_ooo_fp_issue_queue.v...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 41e45029b2cf1963c26df2fc9a8d2345a5459a18eed002007a106c6a00564991
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/v8g-full-module-build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1640
- `line_count`: 14
- `sha256`: fb1a727464bcc94945d133e809757ba6738a8a2e270adb91f1b8c3cb1611899f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1640 bytes; lines=14; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/v8g-full-module-build/t...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 5
- `sha256`: 88516bba416fd8804e72ffcebf12be59f1e02bcb7841b306476ecd6fadf84bce
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/v8g-full-module-build/tb_ooo_fp_long_op_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 997
- `line_count`: 12
- `sha256`: d16bc94b06a762df59a222648d92fd737af18002a508728034ea925b474e8cd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=997 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /tmp/v8g-full-module-build/tb_ooo_fp_phys_reg_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 744
- `line_count`: 9
- `sha256`: e1bfa551360575b478f34ee733f7ce2b86ecbe1e2e6ea66013d2c1c52537f514
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=744 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/v8g-full-module-build/tb_ooo_fp_reg_file.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 440
- `line_count`: 5
- `sha256`: a646c2b728db7ca30f2f00972d951cff4317cdbf02c4aa99dcf3bcc536a367ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=440 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/v8g-full-module-build/tb_ooo_fp_sgnj_gate.vvp /ho...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 432
- `line_count`: 5
- `sha256`: 34daf1f77a718bf31aed59d9706bdfd239020d731c03070943cd8c94e05a3522
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=432 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/v8g-full-module-build/tb_ooo_free_list.vvp /home/lyg/PA...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 476d4e8521546f7648aacc22c18b6fd7e8ea7b44c9c52fc5f477c1e27f8bfc97
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/v8g-full-module-build/tb_ooo_fron...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 898
- `line_count`: 10
- `sha256`: 6aaf094b936e64a62e76011b26299b2c158815528949b8a48259697134ac0356
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=898 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/v8g-full-module...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 810
- `line_count`: 7
- `sha256`: 40fc8d553c0c62fb23eb842fbfd28834328f13c6e5546758cc6665ccf1d6dfa7
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=810 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/v8g-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 01c542dc320a93d94ab883130014ebb59b5d248a1d42901744cea5f01ee45a89
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/v8g-full-module-build/tb_ooo_frontend_r...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: df43f0593e9d3bc09e87fd3b3b89dae14643e62489a21b804b9cea60cba2d291
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/v8g-full-module-build/tb_ooo_fronte...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3841
- `line_count`: 34
- `sha256`: 3faf0cfd4b4f39bbeed5e3464b741ff68aafb76ac808a044777dc08baf4f9742
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3841 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/v8g-full-module-build/tb_ooo_if...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14150
- `line_count`: 108
- `sha256`: 7a8d72621543f784ddd467845501d23e9e460385c479724edbdb4aeb7e6ea053
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"ERROR": 2, "PASS": 36}
- `summary`: log evidence; size=14150 bytes; lines=108; ERROR=2; PASS=36; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/v8g-full-module-build/tb_ooo_int_backend.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7922
- `line_count`: 78
- `sha256`: 6d3f91d79f3f78819afc2b2d66d62c0c5c7b2567a7a4133536a82e3f82184e2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=7922 bytes; lines=78; PASS=14; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/v8g-full-module-build/tb_ooo_int_issue_queu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 842
- `line_count`: 10
- `sha256`: c1e9c5761e356f6d334ddd9c5ddc9ab3b9e121e887a7debb7cbc6f82deb70494
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=842 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /tmp/v8g-full-module-build/tb_ooo_lsu_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71167
- `line_count`: 545
- `sha256`: 967e6fc8a7821ae90995f2ad871ddbc9e0254fb7f883d9e74f4c41a3d3f80459
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=71167 bytes; lines=545; PASS=16; tail=: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1120
- `line_count`: 10
- `sha256`: e2df04a6d63b2093d3906f6d227b2b01ad3b568d3ad19e9a32b58db7dd935aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1120 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /tmp/v8g-full-module-build/tb_ooo_mem_infl...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1155
- `line_count`: 12
- `sha256`: 8c7515303edf451230e9efdeeedabfbad27db085d0161b8fd2c76383f61faf64
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1155 bytes; lines=12; PASS=6; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /tmp/v8g-full-module-build/tb_ooo_mem_owner_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 8
- `sha256`: 5c64ee4232ebc1b984f3a52cc8ea3f8d3712f163323fcaa28740329e0660c835
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/v8g-full-module-build/tb_ooo_memory...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 697
- `line_count`: 8
- `sha256`: 73a2bd9f75917daf4a9678955db9f3cd164bb79709397153908500bd5159abf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=697 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /tmp/v8g-full-module-build/tb_ooo_mmu_epoch_owne...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 440
- `line_count`: 5
- `sha256`: daac16f69fb99acdf333c020a4c75b3844c42e47cb690e4d2b9988e3d02b3de5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=440 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/v8g-full-module-build/tb_ooo_muldiv_unit.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1166
- `line_count`: 12
- `sha256`: b14e3fa8379e0ca652f3f0b74587f8b7410f6e8580ef69765a09a7cd02efc8e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1166 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/v8g-full-module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: f3412e0eafec6e539fe67a31029ff189e8bb128d3b9b2b130afa27429543cd4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /tmp/v8g-full-module-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 954
- `line_count`: 11
- `sha256`: ca81476644b3aa2d58f12b36a7ac9ce190b904ba2451f3aa35710a39b9c4c847
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=954 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/v8g-full-module-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 848
- `line_count`: 9
- `sha256`: b687ca039072bb0716403aa50f39be2d08207f7651c92382e960c5aa9e911a96
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=848 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/v8g-full-module-build/tb_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 552
- `line_count`: 5
- `sha256`: ff39eb419b9983630f0ae2d812096a9a8e01104e3369f26a6b65610d9749f638
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=552 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/v8g-full-module-bui...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: e185da8c9ea89f3d539ff13d82977818b43235a15480c0e8f5e49ee6ce50cf8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/v8g-full-module-build/tb_ooo_phys_reg_file.vvp...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 576
- `line_count`: 6
- `sha256`: 7fb574d476a6cf5989a6ace4e48cd0bbc7de8d5d7b9fba9634065326ba50c164
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=576 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /tmp/v8g-full-module-build/tb_ooo_pma_checker.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15708
- `line_count`: 65
- `sha256`: 52216d13f9645176b0d6bc8027b2d7f4cdf152c88ae41c1e6115ad1e1a771944
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15708 bytes; lines=65; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/v8g-full-module-build/tb_ooo_priv_system.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: 55945d5f1f817678648cd89688d0e7dc4bf80fd83568a1e06d2693af5914f5de
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/v8g-full-module-build/tb_ooo_ras_update_gat...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: 2b1f0d142125a520c141671beb8138f5a8546959aedbaf107eaf2fc45b55e818
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/v8g-full-module-build/tb_ooo_redirect_arb...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 7db71ee61f41524b8a80269f6fc03b3e27838dee931f61ee580ad623daf2e47a
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/v8g-full-module-build/tb_ooo_rename_map.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1078
- `line_count`: 11
- `sha256`: abdf3d57b30e97bafd4f291ef1a8f1f694b021167a35e1d0481b42dadd0fdfa9
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1078 bytes; lines=11; PASS=12; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/v8g-full-module-build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 830
- `line_count`: 9
- `sha256`: 6f931634668e1b9d8ecfd16db4afaa6d26a50274e20168677b91af0d4aeb6ea6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=830 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/v8g-full-module-build/tb_ooo_...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 2642
- `line_count`: 25
- `sha256`: 6823331f0ab40f8d7aa980179b315915de6e7f350b9b10d79c3fdc8ae8b17adc
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=2642 bytes; lines=25; PASS=20; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/v8g-full-module-build/tb_ooo_store_queue.vvp /home/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 208174
- `line_count`: 1513
- `sha256`: c4ea3e8eb4a4b3d289663d60df8f29cee81a4f4959b9880831e52eef151ed289
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=208174 bytes; lines=1513; PASS=2; tail=rning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker....

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e090ac944e10781cae3e775f9c34991882c99aac1d070134166b9f0a199d50a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/v8g-full-module-build/tb_ooo_trap_e...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 9f7a8ecba0d5223a324611a399277cc78898de83b393e8313c24c4aa04fd50eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/v8g-full-module-build...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 596
- `line_count`: 6
- `sha256`: 6cffcb29c3c98b771d6e4c2bbb7c5df36c3e03c4c67fb396d84bea6923a04622
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=596 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /tmp/v8g-full-module-build/tb_oo...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: 429dd2f6863c5cb1cfac9a03c7cc5d791061c6e385eb3d0eb0bc0f4fbd0c50f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/v8g-full-module-build/tb_pipe_stage_reg.vvp /home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17558
- `line_count`: 134
- `sha256`: e387ed2c6698def9f3892550ae528426893d8cefaa70e74307d8fe82aed53639
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17558 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/v8g-full-module-build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 369
- `line_count`: 5
- `sha256`: 98e3f14de76f23b911529c9e6b9a82d7d1dfd1fe9b9ba98f7a2f5c4268179678
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=369 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/v8g-full-module-build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 5
- `sha256`: c7961a196e83ed3256854227f452f83c285377bba9549fb3024546a33e1d0866
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=367 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/v8g-full-module-build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate/summary.txt

- `kind`: txt
- `size_bytes`: 3489
- `line_count`: 114
- `sha256`: 723c1ec2752676c78d2c52d46d90004fb594130a507d0bed82b7dc2d6b6acdfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 210}
- `summary`: txt evidence; size=3489 bytes; lines=114; PASS=210; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/full-module-aggregate - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 40242
- `line_count`: 893
- `sha256`: ef9bdcbd3c2a861e647082595c4472561b765530e963abb5ea5a987d1474e853
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: json evidence; size=40242 bytes; lines=893; markers=<none>; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "f29ea5568045ea5113214eaef866a2e61731f9da5f2919aed162124921ab0050" }, "evidence_errors": [ "directed evidence manifest is missing" ], "evidence_manifest": "/home/lyg...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/architecture-hard-gates.log

- `kind`: log
- `size_bytes`: 2904
- `line_count`: 34
- `sha256`: 55724940af79f280d56fbf0b9bab37c0c86c681eff0fc9740d2c8feab9c7c87b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: log evidence; size=2904 bytes; lines=34; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' test_arbitrary_older_valid_and_reservation_freeze_are_red (test_architecture_hard_gates.NegativeTests.test_arbitrary_older_valid_and_reservation_freeze_are_red) ... ok test_capability...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/architecture-hard-gates.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/check-contract.log

- `kind`: log
- `size_bytes`: 273
- `line_count`: 4
- `sha256`: 7101072fe847eec0f3ef1f2735a79570d6f71e5882512928e7f6e3ce846c7d33
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=273 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=320 基线=89 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 320≥89 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/check-rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/complete.marker

- `kind`: marker
- `size_bytes`: 2042
- `line_count`: 11
- `sha256`: 39a63513b4540f91fb67906b75fd690f5057dbb866bddac31d48ee24ebb9cf0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: marker evidence; size=2042 bytes; lines=11; PASS=2; tail=ef9bdcbd3c2a861e647082595c4472561b765530e963abb5ea5a987d1474e853 /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/architecture-hard-gates.json 55724940af79f280d56fbf0b9bab37c0c86c681eff0fc9740d2c8feab9c...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/full-lint.log

- `kind`: log
- `size_bytes`: 62643
- `line_count`: 687
- `sha256`: e8932ce0f6815cf6b376d480e443ff36ed5174e6502d34542338a7ea16bbc517
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: log evidence; size=62643 bytes; lines=687; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/full-lint.normalized

- `kind`: normalized
- `size_bytes`: 18147
- `line_count`: 115
- `sha256`: 414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: normalized evidence; size=18147 bytes; lines=115; markers=<none>; tail=%Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc1_ready_o' %Warning-PINCONNECTEMPTY: VSRCDIR/execute/OooIntBackend.v:LINE:COL: Cell pin connected by name with empty reference: 'alloc...

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/full-lint.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=2

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/full-lint.status

- `kind`: status
- `size_bytes`: 135
- `line_count`: 4
- `sha256`: bae4ea37710fefc63cf9e15f61025219b0cdcdf6717283fbe606720531764328
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: status evidence; size=135 bytes; lines=4; PASS=2; tail=lint_rc=2 warning_count=115 normalized_sha256=414dbc3972c90b93acdc05dbebd3d637dd6b3dbb067b22ede9fdb9e320b06e2b normalized_cmp_v8d=PASS

### .github/task-runs/2026-07-19-rv64-v8g-memory-producer-lease/evidence/static/structural-audit.log

- `kind`: log
- `size_bytes`: 295
- `line_count`: 1
- `sha256`: 7a6bca438cbfbbc9fbb9ec316bf9c11b30b12493bd317e9157030c10eab4141c
- `encoding`: utf-8
- `indexed_at`: 2026-07-19T11:53:29+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=295 bytes; lines=1; PASS=2; tail=[V8G-MEMORY-LEASE-AUDIT] PASS tracker_edge_old=1 dispatch_q_only_lookups=3 rob_query2=1 sq_full_pid=1 terminal_raw_lanes=5 response_classes=3 physical_launch_chains=2 bridge_ready_cut=1 local_ready_cut=1 buffer_ready_cut=1 station_query_q_only=1 station_dro...
