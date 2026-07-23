# Evidence Index

## 基本信息

- `task_id`: 2026-07-22-rv64-v9f-memory-issue-lifecycle
- `task_slug`: 
- `profile`: 
- `asset_count`: 128
- `total_size_bytes`: 1784729

## 证据资产

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/architecture-hard-gates.json

- `kind`: json
- `size_bytes`: 61825
- `line_count`: 1435
- `sha256`: 35a542a2bb5722e1795394bf5a837cbf2cd494a3e5b7e52a06b259bd2e03ab99
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 36}
- `summary`: json evidence; size=61825 bytes; lines=1435; PASS=36; tail={ "contract": { "path": "npc/rv64/design/arch/rv64-architecture-ppa-contract.md", "sha256": "8884fa871095e01f4e5bdacface70991f986d4114b73f72e9ccf10b1e2069b73" }, "evidence_errors": [], "evidence_manifest": "/home/lyg/PA/ysyx-workbench/npc/rv64/eval/ppa/evid...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/architecture-source-provenance-rebind.json

- `kind`: json
- `size_bytes`: 15417
- `line_count`: 350
- `sha256`: 15fd21eec3ee1d00f4d285da6e0c2378ab02c67156366d366f64cf2640cd6fa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=15417 bytes; lines=350; PASS=2; tail={ "byte_delta_proofs": { "npc/rv64/Makefile": { "all_recorded_old_hashes_reconstructed": true, "block_sha256": "36746bba7dbc47594263f5f44cccc57342bfcbf70deff5719481e0c76d5d101e", "byte_count": 580, "new_sha256": "615fabd681d5de6c404ce3609093f8e54f609650e995...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/focused/mem-issue/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 21586
- `line_count`: 140
- `sha256`: aa3988b490d8332ac63e79ea02dab232c06a87d2ba359e93ad11d173b8013a39
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=21586 bytes; lines=140; PASS=8; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/focused/mem-issue/summary.txt

- `kind`: txt
- `size_bytes`: 280
- `line_count`: 10
- `sha256`: 364ac5fb4fc810c637b1089693ba3c2fbae5dfd2b66a4ed545947f1c5e7fd0a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=280 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/focused/mem-issue - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total: 1 - pa...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/focused/miq-flush/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1362
- `line_count`: 12
- `sha256`: eb261aabc22eec8612d0be60389b8d05eec120733b702a8ba85fe7b660278e63
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1362 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/miq-build...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/focused/miq-flush/summary.txt

- `kind`: txt
- `size_bytes`: 287
- `line_count`: 10
- `sha256`: 132dcf658f90ac1459806f4a72cd77d3e4ddf6ab262b27049a01505573c9028a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=287 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/focused/miq-flush - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_mem_inflight_queue - total:...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 386
- `line_count`: 5
- `sha256`: 124dfe2d1ed80b1239a18214d9d3d07e8497324f6ff3f910bda00555497bcf68
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=386 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_alu.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 0136f23791bb16af9f9ccc838791c20429cf0dba15786f80e53bb642395c7f7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=418 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_axi_clint.vvp /home...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3518
- `line_count`: 28
- `sha256`: 4601284e06812cc320b30d6d7c396368341ce4b0aa1b8141aa0c445d5ea06434
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3518 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_axi...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 526
- `line_count`: 6
- `sha256`: e113ec98a842d58d42cc4d890fb91064be9edd597d103104c056ff1279255239
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=526 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_axi_plic.vvp /home/ly...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 6
- `sha256`: b917c23363c9fc8cd7593a30bf029a815048517eb33a0df3eed9c975f5b24c80
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=615 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_axi_r...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a18112be52f59766d29c54a8b408b69fffed47552705e6987bb25b6bfaa2e894
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_axi_to_uart.vvp...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3298
- `line_count`: 28
- `sha256`: 32b0106ce3c0b5c0debcd81fc6dd6fd6be50a25186c09b5bfc38a9f68acd5624
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3298 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_axi_xbar.vvp /home/ly...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: 9fdc2fb595436af13541987603c7723d6d2c90379be8d01be5f7fdd2c8ff0291
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_compare.vvp /home/lyg/P...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: 61334053a156a85ef37102912691b78e94bf016ef2d7a17e9598f067f27d9adb
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_csr_file.vvp /home/ly...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 557
- `line_count`: 5
- `sha256`: c00bf78f844c7988216d782a963a7cc0f718e1256779a7bbcd96b58101ddd955
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=557 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_decode_stage....

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 432
- `line_count`: 5
- `sha256`: e48b824d8177cec165e47445c134abae99507794f5b6db64f16e612a70c9afba
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=432 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_decode_unit.vvp...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 5
- `sha256`: dbffbfc9b3523bdc80d4afb266109634159f4092572128d02e4d0edb93290f92
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=402 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_immgen.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 509
- `line_count`: 5
- `sha256`: 903c2787bb19c39998873943bdcad70c46425fdf275840d796568800be4245e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=509 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_lsu.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: d3c70093c3caf843d36da880c9c3f87ee5eeba442143d9a0d11cfb729038eeaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_lsu_control.vvp...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: b0828eee03dd777505782c99d66e3c09cd85d784891c23b508d3011fde8d8497
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_lsu_datapath....

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31143
- `line_count`: 206
- `sha256`: 2b92cf8fea4bd3cdad06b38c6b9b47bac2f4b87625076aaba459db2698219378
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31143 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_o...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31323
- `line_count`: 204
- `sha256`: d0a953304151e8280166c806da49d978b1f7a489026f35b066dd96eb7540bdfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31323 bytes; lines=204; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-bu...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: 40feea336517857549c995fffd998147ee88040b3be4db44f04db7487c8b699d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_amo_gate....

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: 9c77382e329fc738ebb87b9575d5a1af3d4672cd2b8676c7f37733bbab82a620
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/mod...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 83e8bdb38149bfd3e07db37f600bc4d6dcd895169daec6bd07cd43c91569534f
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 894
- `line_count`: 9
- `sha256`: 8a17c18bf248c25be56128a3ceaa9afa28faccbd5ff2ff3998a495451f0a86c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=894 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o <MEMORY_LIFECYCLE_TRANSI...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 849
- `line_count`: 9
- `sha256`: 0a6b900613e17998c4a8803411bcc6a25e4a5a6b9df1f851384859eaa04dbcdc
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=849 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/m...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 632
- `line_count`: 5
- `sha256`: 771c16029745ab60fdca7d784a9fcb06ed4041e91a6cff840a10e939b0fb2cf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=632 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o <MEMORY_LIFECYCLE_TRANSIEN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 904
- `line_count`: 9
- `sha256`: 955421723025a00ca61ca0db93403699cd5f1320e9407652e65f1b8c83bfd09b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=904 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o <MEMORY_LIFECYCLE_TRAN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: b2352c753b758b395a559035b1881070cb175eda34f156cae7e8d4519b34cf13
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 589
- `line_count`: 6
- `sha256`: 350276791cdfa2febc474082641205cb09bcb8102c049209ffabee92b9f353a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=589 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_busy_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 9abe83ec5109340662c0fb664dfa119280cf65e11f17d2c42b99e29a18a404a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_clmul...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 807
- `line_count`: 9
- `sha256`: 760db360627c55cae0322afa93f6e293c3ce9e027129e618acb593b49ab7b303
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=807 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-buil...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 872
- `line_count`: 9
- `sha256`: a3786acf8676c907b9add3846ea449e7d52894276fac93062013f339ec96b343
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=872 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o <MEMORY_LIFECYCLE_TRANSIENT_TM...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 859
- `line_count`: 9
- `sha256`: eb4ae0eb79b462c70ceb84c9dc3044502dd88f3ba974fac5b5ced044e49e15cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=859 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 24990
- `line_count`: 137
- `sha256`: b2c62b371d03ee8c21c65bb9f31afe348810ef719bd64045951cf294bf0b13cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=24990 bytes; lines=137; PASS=10; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: 310b961654fd0c166915d13b95cd8873a43f61b2ae886e87b590c4619642e5b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/m...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 523
- `line_count`: 5
- `sha256`: 1bc0007d558e2c78619e4a5b2176fed92790917d7e53cd12f2850db0e93749d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=523 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/modul...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 5
- `sha256`: 68ecb947ad7a084fbd7839437e1c4cf30e8dac9b382cba1dc560fa3c4aafb0d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=615 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 58a8ea18de2d9c416a1c23cf8f925347bdb3b87ae71398f3f482180e1ec57c53
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o <MEMORY_LIFECYCLE_TRANSIEN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 539
- `line_count`: 5
- `sha256`: 4b90fb4c32b4d9f1cb5404d705ad9d3282b20cfa50e87f3dc709af4dc0568255
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=539 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o <MEMORY_LIFECYCLE_TRANSIENT_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 539
- `line_count`: 5
- `sha256`: f4bd233a00d6ed66b4b9127a32b551aa63ece64e40866d9446f0023353b794a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=539 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o <MEMORY_LIFECYCLE_TRANSIENT_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5427
- `line_count`: 38
- `sha256`: ea4ae4c4e0025643f02083c24b6d86d15d3170d2365dc3fb587418bdc035a150
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5427 bytes; lines=38; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 305858
- `line_count`: 2293
- `sha256`: e7c77a386de665f99220a532ea2cda1d09edbfef5064d6cf25cffdbf85ee97cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=305858 bytes; lines=2293; PASS=2; tail=-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/ly...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 106906
- `line_count`: 846
- `sha256`: cf6e7238c91957f50e2cd380a5e0e8f963449ff9d3184e5394ad9a051ff58d1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=106906 bytes; lines=846; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103649
- `line_count`: 779
- `sha256`: 8eb7779cf7a6c3ae4345a397610abdb41d85f5aeded8420a8273724bbbb132ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=103649 bytes; lines=779; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 104453
- `line_count`: 788
- `sha256`: 913c5d26a26082d45f0a2d681565eb0797e8efd1ea4b0e5076ab54e3a2a2da4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=104453 bytes; lines=788; PASS=2; tail=n array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 1...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106586
- `line_count`: 802
- `sha256`: 2d55e8a289edf267305c629acc36bdd175c168624350bb5fe1297a6167ce3bd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106586 bytes; lines=802; PASS=2; tail=pChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 5
- `sha256`: 0ab6a149945528d48b03705547a6533ef431bf21db0be7ee295020b251e761a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=506 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: dbe83816e09ae44f1cdfa71a0fa07cbd79d6d1e859fdfd515e531e996e48391d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-bu...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 774
- `line_count`: 6
- `sha256`: a46592ab2a9ae1f56014642fb4e9836928f51fa0130541bfe92b6dfff7faef33
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=774 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TM...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 726
- `line_count`: 5
- `sha256`: 91d0e06af535e6a5e6df578a74f6284b30cf26e52ac93aa38c9d015079b89809
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=726 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/modul...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 635
- `line_count`: 5
- `sha256`: e109835b30e8e5b4e81c1cf7a9854afc4b33d49de011d30dd8732a4cd8f606d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=635 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-bu...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 646
- `line_count`: 6
- `sha256`: f9bb85adca656ecf5233db63085b919236de44aee922537cfdfe1b5a7a819515
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=646 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 825
- `line_count`: 10
- `sha256`: 003c5c9ce61dbede10fbd8185b3f6e3f378e7a1606bc9251d4813b52d9138031
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=825 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-buil...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: 87f098e3d45b4243b4b1fa43e73def9a999a575f4cf6bb9ce62bc79df3278255
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/mod...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 515
- `line_count`: 5
- `sha256`: fd6d1b091d5a802ecc2d7b1c7ae1ba1db7350e22e51947f2013942abb1f8ef75
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=515 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/mod...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 106448
- `line_count`: 802
- `sha256`: 0da3f7a188f0f0c9580d548ad4a8dad32c8d9ddae293cf05549fcf45a2ae96b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106448 bytes; lines=802; PASS=2; tail=all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sens...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 7b08f6c9972609d9cb05712ccb02801e810bca311e069cbfc95e9c9b4edf604b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o <MEMORY_LIFECYCLE_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: 8ec4347200a43206407eebdaa5e2b876a24d59773f0a4101a589fa507915996b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-buil...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 1004
- `line_count`: 10
- `sha256`: 626771f7c9c2e437a7787ff6ae6ed4372254928b039d4c13b1e9df1bdabc534f
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1004 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/mod...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34068
- `line_count`: 196
- `sha256`: d8917d488527365436dcb4f6f0657c96bd84829d23ba2c891465189b405f592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34068 bytes; lines=196; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 702ecf270c81fffa88e48a9f4173b2e05b571734491e5fd497f1b8f51bd13e6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: 9cfb844c2fd8059e68ab78b4a454222b6c240ef489b690faf22ed4875e9ed575
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 0de0e26e79bf610825f3245043d76dcea967e171d786291a3d4260d43bf1cd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: fa77180254fc0ded3925d5fae6e63ce7f5147a9acf7d24450e80a9abec8b5db9
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3974
- `line_count`: 38
- `sha256`: 938e1de01b495602fd36f8b17051ecc95398ae6fba8dfd703e81c1a14e781696
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3974 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_o...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 057bc0b63d061a5be4b86524f407158c2a17ce8cc3ab8823c294a822b9fd9676
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_fp_iter.vvp...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1807
- `line_count`: 15
- `sha256`: c3dff43b948ff8df234945f558cd6716767d73898522d71501ab0adbcb2d80a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1807 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o <MEMORY_LIFECYCLE_TRANSIENT_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 5
- `sha256`: 17745d301322830be670603e8b8c758497ffc50c3b600b0dca398d69e5c15946
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=610 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1017
- `line_count`: 12
- `sha256`: bbe6b60283d76e1268fa39f64256241a3d52a44f3017849fb2d0e25cf7435b34
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1017 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 764
- `line_count`: 9
- `sha256`: 0f4a2aa234af30f71184d9b37c22d6c2c106637988e65741d64f84c484fa9db9
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=764 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_fp_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: d0e3218810e49a72b0c53c63c641e954c5aa6a7501fcb3ed1f474113380d2542
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_f...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 12daf5b8c2dac3cde2eb5eae5844346a863d278422e3e5ec25e957f888450f6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_free_li...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 510
- `line_count`: 5
- `sha256`: 3bf8f6d066adceeb216a601e55ad8f7983457e345e8814b68b3738d6614b6d19
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=510 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/modul...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 918
- `line_count`: 10
- `sha256`: afce21cd0dabfbe3678fee40ac6dd5aefa939c8d83b015e4f262637a7db31a00
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=918 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o <MEMORY_LIFECYCLE_TR...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 830
- `line_count`: 7
- `sha256`: ed631544d81dfea1fb78d08f4861e51ec622d926f70eedcc58b95e61f4992783
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=830 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/m...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: 3b933b602ca6db4a0dbae3abe4e726ba235d3ac0785a03accd5f83b30c7938c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-buil...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: 48469898dbd634efe2b5ce096f3de788b912a1e6a6ad13db0c45ee6b991db05e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3861
- `line_count`: 34
- `sha256`: 1b837f5d17c81814b7ac869f8abf8d04c0729f102aff0fefc9eb7bf30c7c73ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3861 bytes; lines=34; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/mod...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26274
- `line_count`: 222
- `sha256`: dfd4dd625d6f55e06810e7d16d59956b9024ce2c52c331971be9fabe0fa6e0c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"ERROR": 2, "PASS": 94}
- `summary`: log evidence; size=26274 bytes; lines=222; ERROR=2; PASS=94; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_int...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11498
- `line_count`: 96
- `sha256`: d880adb3d9dc4854896814dab77b1756d6c3a315e419099f7f5506b9101174c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11498 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 3928
- `line_count`: 33
- `sha256`: 4a5c40e50d738ad74b0fb65be90b641af3dbfe6d09c85fca89b099587783d6cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=3928 bytes; lines=33; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_load_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 862
- `line_count`: 10
- `sha256`: 061a5abc2b2a0fc31cb2709a5ae9516c9f102dcbc7d255e4537b2283483ad9df
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=862 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/modul...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 71766
- `line_count`: 555
- `sha256`: 910097cb1a8dd8e37006931fec1ef67a94279bfbb02465f4e393b12dcaf0dfa7
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=71766 bytes; lines=555; PASS=26; tail=ry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in ar...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1365
- `line_count`: 12
- `sha256`: d39e64d5cce2968713fc76f7f9c139eddaffcf27c095413070b90a4d5142ba40
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1365 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-bu...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1011
- `line_count`: 11
- `sha256`: ecb81fd9ee55a86e25be1d4f76464e22c0cc1d656361090f305e1b57a8f36183
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=1011 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o <MEMORY_LIFECYCLE_TRAN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1330
- `line_count`: 14
- `sha256`: a97bcfbab7de50103fd71c6a44558ab7971a3325b9d51f87f800d7d3c1868a3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1330 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-buil...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 962
- `line_count`: 8
- `sha256`: 8aa5c195123a5864ecfb2772843ef873f4852a8e59e94da1f07e803d3126e5a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=962 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 717
- `line_count`: 8
- `sha256`: fea8c4435e4075aebbad6001f3f8a03aa80af89c93438259b51b86ab34bd28cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=717 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: f327b6b4e39700854c3ce5c7658231b2ef629481d5a188853be687bda86875f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_mul...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1186
- `line_count`: 12
- `sha256`: d93e4b8005a64e4f822b01bf2fdce255db34515503660e0c678de7901405584e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1186 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o <MEMORY_LIFECYCLE_TRANSIENT_TM...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: cc11a4db7397b372fc31e685a232f8f1609036b005dfc3af546546d5cfcf8325
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o <MEMORY_LIFECYCLE_TRANSIEN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 974
- `line_count`: 11
- `sha256`: b0767effa3dafc9badd8906eb5c63f880a472507e86866f274c3ee258e711cd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=974 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o <MEMORY_LIFECYCLE_TRANSIEN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 1001
- `line_count`: 10
- `sha256`: bc65a6c3ef075743dbc222c34f07952bd0a83a67d33653279883c7379c631b92
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1001 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o <MEMOR...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 868
- `line_count`: 9
- `sha256`: 59493c2c6e510956e0c7e5cabca9a0c85241b5d07dee1f4c8e2feca4315465d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=868 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o <MEMORY_LIFECYCLE_TRANSIENT_TM...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 572
- `line_count`: 5
- `sha256`: bed2f2878dd37b5535626fadb99c7d4d564304e0bb3107984d8f2557d015aad4
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=572 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o <MEMORY_LIFECYCLE_TRANSI...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: b6ea4e0912565f6a6b27fe7dd2e77893eb3b028e17174aca9a22f41af02c583a
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 596
- `line_count`: 6
- `sha256`: c6aa4e7ea8d896cb5679087de46b218aee03beb2da20c7fb531f57b19bb4a242
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=596 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_pma...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 25597
- `line_count`: 136
- `sha256`: 1c5f889a1bf3932147118eb564b1358fa3658f8922fae93587773806b2e04107
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=25597 bytes; lines=136; PASS=14; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_pri...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: 4940900ccfb87dc4bcc9826988b233940d4b9ef0f3db4a971359587ef8c6460e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 5
- `sha256`: aeed504bc896bba8ea0bca0a3fe12c48fbfd93ada9bbcf3fbd80247edfc21c6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: b02d0de02670242aff273f5962670464137908109c4fd8f4ce4d576a6c5aa250
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_renam...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1528
- `line_count`: 15
- `sha256`: ccc0399a6e53c5cff4af63af82aa306123b68c907d9922faafd2907d966c8505
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=1528 bytes; lines=15; PASS=16; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_rob.vvp /home/lyg/P...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 850
- `line_count`: 9
- `sha256`: 37e6d2caa55822c203a9d7aa04044628f77620e70d28bf807d6dcbd47030edf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=850 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/m...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6762
- `line_count`: 57
- `sha256`: e816f98c5a643f401710991c0fc4fc56c5278fd776eff8fe62137c6dcaa7d68e
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=6762 bytes; lines=57; PASS=24; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_ooo_sto...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 286588
- `line_count`: 2100
- `sha256`: 1f6e08a5d2dcc53b83c6deebdfaef661b6e95b08d2e4fcc5aaac81e05de6b606
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=286588 bytes; lines=2100; PASS=3; tail=r_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array '...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: 358f8fe85cd982db43721ede2274705d5885d37ef0aea7e36b82f13263ca5813
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 565
- `line_count`: 5
- `sha256`: 02041b61a009591fec6e77a02a8e61b180a8959533d917c3185184cf0d57f9d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=565 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o <MEMORY_LIFECYCLE_TRANSIEN...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 616
- `line_count`: 6
- `sha256`: 031c0e5e726d8dcd8062e9fcb13ce027b113b746c92534b5e0a9de7de108237d
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=616 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 824d38af4484fa0b2b9b6a3c165d82a2113c9290b45ae6c816e926c1b00ed0fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_pipe_stag...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17578
- `line_count`: 134
- `sha256`: 6346e8bc7320c60255e442c2cfee8beaeb279bee8e6f6bb95140a8d002c40343
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17578 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_pmp_checker.vvp...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: 5e6d8b79e13cef8ac5a9c36487e08bfac073b23e13f982da1a6efa2d54971cd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_uart.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 387
- `line_count`: 5
- `sha256`: 5a9c31dc0d59c8a0377da4243073db507f6d1a947f6f476dd11c1e9461c30e31
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=387 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/module-build/tb_wbu.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate/summary.txt

- `kind`: txt
- `size_bytes`: 3646
- `line_count`: 118
- `sha256`: 4bbad3622cd6fdea772172007b150124e1ef603d6e61e976755eb6e997370890
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"PASS": 218}
- `summary`: txt evidence; size=3646 bytes; lines=118; PASS=218; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/module-aggregate - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - P...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue0_miq_birth_uses_terminal1_identity.log

- `kind`: log
- `size_bytes`: 22130
- `line_count`: 151
- `sha256`: 75e43604718cf8478b4160b60045582091ca30d7f232efbc7d182f6d3b1cf9fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 8, "PASS": 6}
- `summary`: log evidence; size=22130 bytes; lines=151; FAIL=8; PASS=6; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue1_consume_uses_global_port_fire.log

- `kind`: log
- `size_bytes`: 22499
- `line_count`: 156
- `sha256`: 9ccf4d69fa1a4934d5d102cadb7e7e3721988f284e0065023be579f592f25852
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"ERROR": 4, "FAIL": 12, "PASS": 6}
- `summary`: log evidence; size=22499 bytes; lines=156; FAIL=12; ERROR=4; PASS=6; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue1_consume_uses_valid_under_backpressure.log

- `kind`: log
- `size_bytes`: 22304
- `line_count`: 154
- `sha256`: 405a86f29f93c9eafe6989a26ec92893f1e73d60455fa5d6681c9432be42abfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 14, "PASS": 6}
- `summary`: log evidence; size=22304 bytes; lines=154; FAIL=14; PASS=6; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue1_normal_launch_false_closed.log

- `kind`: log
- `size_bytes`: 23123
- `line_count`: 165
- `sha256`: ffeb5f77a242c2493fa0ea374cbbf129d03e21b40984dd06d4e987a9d9af4f18
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 36, "PASS": 6}
- `summary`: log evidence; size=23123 bytes; lines=165; FAIL=36; PASS=6; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue1_request_without_terminal_consume.log

- `kind`: log
- `size_bytes`: 21729
- `line_count`: 149
- `sha256`: d4ca267bdf88b07dd04f78175e84269d686d1f7c9a73014de9311426f4e84d84
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: log evidence; size=21729 bytes; lines=149; FAIL=12; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue1_terminal_consume_without_request.log

- `kind`: log
- `size_bytes`: 22671
- `line_count`: 159
- `sha256`: 7739cfe548982235da0031477b1f8d906bb296acb329283a343afafbbaa9fc48
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"ERROR": 4, "FAIL": 18, "PASS": 6}
- `summary`: log evidence; size=22671 bytes; lines=159; FAIL=18; ERROR=4; PASS=6; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/issue1_terminal_retained_after_launch.log

- `kind`: log
- `size_bytes`: 21654
- `line_count`: 148
- `sha256`: b08893ae7ad56adb62f7c50adfef0049b546126c94bc82564a4e1bc28ca3b788
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: log evidence; size=21654 bytes; lines=148; FAIL=10; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/miq_birth_uses_valid_under_backpressure.log

- `kind`: log
- `size_bytes`: 21797
- `line_count`: 148
- `sha256`: 096d5745643af6aecf581ee09597d10e5d1fe2b1a3dec107d85b7b02c310fc29
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 6, "PASS": 4}
- `summary`: log evidence; size=21797 bytes; lines=148; FAIL=6; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED -s tb_ooo_int_backend -o <MEMORY_LIFECYCLE_T...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/miq_flush_drops_unconsumed_drain.log

- `kind`: log
- `size_bytes`: 2920
- `line_count`: 37
- `sha256`: 9a4c68ac67de4f941aa8cdd596cf8fc4937c7532a44b609d14a686b2a3809845
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"ERROR": 4, "FAIL": 30, "PASS": 8}
- `summary`: log evidence; size=2920 bytes; lines=37; FAIL=30; ERROR=4; PASS=8; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/build/tb_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/miq_flush_replays_consumed_drain.log

- `kind`: log
- `size_bytes`: 3006
- `line_count`: 38
- `sha256`: 1ecda5a2c8984113bb8946e5e8683dec5f4aad5c3b91c6bada8e883e5d77b9b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"ERROR": 8, "FAIL": 24, "PASS": 8}
- `summary`: log evidence; size=3006 bytes; lines=38; FAIL=24; ERROR=8; PASS=8; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/build/tb_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/logs/miq_flush_treats_valid_head_as_fired.log

- `kind`: log
- `size_bytes`: 1935
- `line_count`: 24
- `sha256`: 001ae55d4014c761f6cc2532abd1a8c682070d14f91e2a5245cc0f15a5d9f20c
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {"FAIL": 10, "PASS": 8}
- `summary`: log evidence; size=1935 bytes; lines=24; FAIL=10; PASS=8; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o <MEMORY_LIFECYCLE_TRANSIENT_TMP>/build/tb_...

### .github/task-runs/2026-07-22-rv64-v9f-memory-issue-lifecycle/evidence/mutations/summary.json

- `kind`: json
- `size_bytes`: 12833
- `line_count`: 250
- `sha256`: f154ef9a9416deb037b60143ed7f588f5c592ff6b5766259e532daccdc711839
- `encoding`: utf-8
- `indexed_at`: 2026-07-21T18:17:35+00:00
- `markers`: {}
- `summary`: json evidence; size=12833 bytes; lines=250; markers=<none>; tail={ "by_debt": { "MEM-ISSUE-G1": { "compile_success": 8, "dynamic_rejected": 8, "required": 8 }, "MIQ-FLUSH-G1": { "compile_success": 3, "dynamic_rejected": 3, "required": 3 } }, "compile_success": 11, "dynamic_rejected": 11, "required": 11, "results": [ { "c...
