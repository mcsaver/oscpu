# Evidence Index

## 基本信息

- `task_id`: 2026-07-14-rv64-t3v-predecode-mem-dataplane
- `task_slug`: 
- `profile`: 
- `asset_count`: 1389
- `total_size_bytes`: 13308448

## 证据资产

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359856
- `line_count`: 4547
- `sha256`: 9c4daf72ae828bb61b0690cb55d82944e3015e82cbb04d69fa2122a56d255511
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359856 bytes; lines=4547; GOOD_TRAP=21; tail=nch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000080 miss=1 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000010 miss=1 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x80000070 miss=1 [0m [1;34m[cpu-exec.cpp:1600 statistic] #4 pc=0x80...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench.log

- `kind`: log
- `size_bytes`: 3440
- `line_count`: 108
- `sha256`: 55beadde471c8e83cdeb9155c7e3cd4a2901d6c4d366bfd58fe21cd34a7f1371
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: log evidence; size=3440 bytes; lines=108; PASS=194; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-368...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: 1b698a45a0cbf2804124a361232cdd2011bd46bf73e000f176e093543d3a0182
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13021
- `line_count`: 78
- `sha256`: 8301c3bde59878ae6d5109191c241ac592a3ac762edfcdd7ced3653ca7591ccc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13021 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 12697
- `line_count`: 76
- `sha256`: 4a747b90d2bcb5ef4177db439708a9c0aa9041c6fca30fe2e6634102752db064
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12697 bytes; lines=76; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: 50e743af17d3d7029a3a068170a626ca76c6323f3e5a62dd8907501b0fde7e49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 65a906487ab3e95672cb4c41f3189e3c1d40c84050de1dd27bf343ccecc865bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15639
- `line_count`: 67
- `sha256`: 3e224ffaecff9203d946a64eb53ac8145e8c73675b849a75df78a85c1c49d923
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15639 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: 412281b6aa25bc130cbe9f0107c3d7e76cd620154a213b3c5febfe4f2e750275
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 7105
- `line_count`: 50
- `sha256`: 9c38dfa63e9561756ca2572a894f6892ab6d3dbd8c9330939ef27c288f996e60
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7105 bytes; lines=50; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: d5e58b41e4b43d465164107f0f5c963e95696b14baa0731ab4015b55d985617b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: 3b0e88f90869448ec0aecbf4b71381ba749daef8de8920e967bd2a6f82994498
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 9020fadf1571a6bae166fc23caa1978d379d49e27c0f3ca9573855f9a4aa4c3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: d3752bbf4369d1aebb055946b55a1adc819b01885217a162247ab750590a9d20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build/tb_ooo_fetch_branch_target.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: f3b845b1ce2d8c79e16b356fec6024f4ef74a65b77eee8cd81dea31980f22a7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 4ec29a1cdff0f80e3f77c08bb3de14dc7d8fe49e2bc8e4cad52de8c9d873663e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f3a7515456977a869b9657be0b0aea9bff8bc0628550955601e1d083f95f6abd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 5e186a99dd409b52bb1c67147c3b48f201864145d3e4a8bdbb4dfc2552593874
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: b45cb70091362b646ef0addfe93ff480bd540246401570dc5126bb80d213b6b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 74fc78baa425db593c5f0a5302321f305947dcde430aacf50887a69203801a0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 15649
- `line_count`: 67
- `sha256`: 00d74ac2a6db05e75176ff384efa0a5abb781a094131f1785ccc0cfeaae4c72d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15649 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3643
- `line_count`: 36
- `sha256`: 5bf4803c5fcf60371aecd4e0ad40d7e343b1614934213355284d9ba378bafe7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3643 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 12
- `sha256`: 73cf2253470a50eb3504d7bb3d41a250402cc47a6799641ca8ec049bbdfcf358
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=976 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 3ff6b452cbc5e2086c6b98ecab489b3f74bf944a91005a340693ecf9eb3ead68
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12205
- `line_count`: 84
- `sha256`: 5ba11f128a7086de516ca19887034df9e95e21fd1175dfdfd13fe67a5ad5be77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12205 bytes; lines=84; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7516
- `line_count`: 63
- `sha256`: af522b2fe17990243763d684a8d79d4d81a86290002578937272c71807b7457c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7516 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 73f2a262a8820cfdf8b4903d54c8fbbd9381d43099d271ddc577e379aa64c26e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: edece60c135f85ff7b0f7696ed98bb7a8aa49f5d1b17ada2804d9b137a97bbf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build/tb_ooo_pending_drain...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: 6e8b03051f6459e31cca0e186e2c3f11127fd8fb876bb0dfcb212767b79303b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15725
- `line_count`: 68
- `sha256`: 613bb0504f8cd23b2b2e51c2207eadc198542ea5054bf372d3b452501c9a2307
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15725 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 154155
- `line_count`: 1102
- `sha256`: 2b32a3561063f01d7f2ad87e38c7a001846dbfba09bcdb55564fdd196b9b6e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=154155 bytes; lines=1102; PASS=2; tail=ing: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 3293
- `line_count`: 106
- `sha256`: 4cc9bcbc582394b1ac64e38265149836a2e015362b15bb2abb9b6585dac64d24
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: txt evidence; size=3293 bytes; lines=106; PASS=194; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s202603...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/npc-build.log

- `kind`: log
- `size_bytes`: 49016
- `line_count`: 60
- `sha256`: 3a596ed5454039a8d2d779919b03954e5ac267b788a837bf6278506c8d72f68a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__"]}
- `summary`: log evidence; size=49016 bytes; lines=60; symbolic=__0__,__1__,__2__,__3__,__4__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-breakpoint.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 759bacf90a27050b888263f901fd5eb0ffa9c3e8b10d9c2c1add856d31c28392
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-csr.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 4
- `sha256`: 64ea22733c1c648d458ed72ca058e8e6cab07bf1bb3a405c30194b124d72ea43
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-illegal.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: fe618512fc09c6bec94ec603c2d4669b6f9225895d1018c00296d4ae648e9453
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-instret_overflow.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c7eb752ddf7df2836c15e057636b2b3b066bbe61020cfa1fcb7667044ba4fb74
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-ld-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 10
- `sha256`: c44e62773c367801944447046f471368c167a7b46cc18ff61e89ced9b1e10b45
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-lh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 0a625bdb1bde894e591b08910e9c522dae78cacf6f215057e5084ebb7215469f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-lw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 81a2d0f7543c87aab91ea4ba7f6df69cb54772b8b02fc1970baaa2dec4813138
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-ma_addr.bin

- `kind`: bin
- `size_bytes`: 8768
- `line_count`: 11
- `sha256`: 43aba4a5ed598e42eafa14d04575df2738a9dc1b2262e599788408accf523041
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8768 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% �s 0�" �...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 6
- `sha256`: 23128cb88a441f0ec5b0aa92e3ff235468a97a94e292d35d9092ba02c0cd6d75
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-mcsr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c8ab2c5fbb9cf529518ebf007812028ad1dc524efde5bf2edfaa20c2b8a3df6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-pmpaddr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5c82f4f85902b25a1496ffba37f4338b26a971da939e6921985125def9242a2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: fab026d76c46c8506cb94a08cb632f2de6937d8b057204464e3e2cdc019780e3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: eb468050871ee3c797254f90c6571b5dab04bb018834af2c69265c0274a165b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-sd-misaligned.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: 580363d39fef7b89f9e2e386be8a7e60ac3fd56c1df679ebe3ed5de107573e9e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-sh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3c3de98bcf0acee9619646b0ace0b28ce19cad50d97d6323aeb3e30866219c48
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-sw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: e0715db1e4a9e3efd1784bbde55edb741d3ae50f551315ce987e5434a5683aa4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64mi-p-zicntr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: aeadca97e007d646ed5565e489bf1a0b805cfa321e996930effd2ad4bab21159
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-csr.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 5
- `sha256`: 2f7d31a97b4a1a8836b5b16b048e42d6d3be2d02275a1bb9e4810b27575a72f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-dirty.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 302f824e3cbcf3b842793355d42fdc5011dfaed03e59cec2ab8d1b4831766a3f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-icache-alias.bin

- `kind`: bin
- `size_bytes`: 28848
- `line_count`: 4
- `sha256`: 4557a25ddcb7abec27c88269b480cb0d7ec7fa64305725d29d8d3c0a52f7dada
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=28848 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �r �� �s�R0sPDt�r ����s�R0sP �r �� �s�R0� ��R ����s� ;� � s� :sP@0�r �� �s�R0sP 0sP00� �r �� �s�R0 � c\ � � � � s �r ��B�c� s�R �� ��� s�"0sP 07% �s 0�r...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 4f38f4a5a44b94c3317295c23666c5c5d6eb5d5aa6978b7de5509ec65f3ae17c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a27651d09a02b29a03a577555aa3571f8196280aa72cfd8baf0f3fd7b8778ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: 16442ae5360eef6283fa542a660128ff90f325c6385c4f14561403282e63b9d6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64si-p-wfi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00771ff518788f921c94a744180cc11a58d4c6867a7a28e02f20735727e41927
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 4150f7116a5d1ad9544d847f718a27dea539caa5cba32d9db43c0dd3a320cd58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 23ece6fcfa411fe3e9ac8aa2d73a60054e39446808a1551d3feb2c97cc438b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 23d3611c19094402928bdffe805fa8532d82fd77c90420ad9dcbbf546b86a250
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 4
- `sha256`: d235961f7c7c03e9da495ec9a846dad59fd750a8fd31c7bb767a01e623f0b31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=654 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 8474a0af82ef8d14cf5dbc04104d884ee96562d91ed90a22bc87d19350c99f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 6d07c6e4fe8c1fd8b3f44f7dce5500299893ea370f733c6c7e01c48e4b288072
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: e51c2a9f92c0506b9df3f6c48a301a8889b7ac5b3931ac4dcba1a9b2fc2721d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: d5963171dedae952ba273fd6c4b0ef70b6f28a179dafb069832f8f662f963179
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 99b16ce02f59f4a136bb747ddfd6f2348748038875ad51e6bb0192e691402068
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 62379170ad5bb6cc61c4b4dc0ff7e91a9fdde586f642c6ccaee4c80eeb1f3d62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 7b980a18a7a0c0f1265bd180a9ad1db93e8c6cab0d658640d820cb92a3eb9b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 9099de3acbff7f1453867efa55acba173e3f713d751107e9406a5e76a42fea3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cf030de16f0944357c4675d1bcd66e4c9ff80e240125f9290aadda6d928d2760
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: c4a66350fe2e3da52898d8665d719115bc88db0ef8aa4e2c93e8de5ed2e29de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: a22f5126c64613ddf6fd55ea6331fe76d4a0a0a982cbabc5cdd66da0ebc03e51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 237937babe46f052aa4697ccfa94dd5d62fe6e9c4f6ba2ed91df161b8bae8989
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3c5cb1679bbbbdb5587f3c2e0afb816204ec847dee3ec85268b44979b7dc56cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: c2afda182606f2e0a7e63e3474d5921c3aa8471978d516a44873e5c06b70a2ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 107d85d30c6e216d76cd6b59c73db64f75028be38ce1ee747124bff1d6ec90c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 1daaf37379469b4eaf41802fa680ed3c8c7bd6ce953df9c84d4915f239d4d641
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3b729d2c2d818c320db5ca4afe7a1f1348264eb2ffe0eba7ae1049417f20391c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3fb8dc5558e0ec98c7af988859a3cd3baca8da9aea3728df9d7cc85c7fd8bf77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 00b93d77799a70c2e3b84e597ee4c06a7fcea19dce219d84d8aee420edc53bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 8e0c3b0be49d00964fde252f04e3087506e0de98cceb587a5ab3066efb41ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 5342
- `line_count`: 63
- `sha256`: 55081c7797861f9ba988ab1c88e69927ad3dfd6683f8cbe459bdeed702175007
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5342 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-breakpoint.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 5568
- `line_count`: 66
- `sha256`: 02538246e2516aa65bf76e19b73e544f4a59fc48e6af391924d5f265240389fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5568 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 5724
- `line_count`: 68
- `sha256`: 34f88922e8dca0bb4c7c98c4b845e93ad6a24a20c4c0ad23c522027028462504
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5724 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-illegal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 5347
- `line_count`: 63
- `sha256`: dd3aedefadd04938459500e528635f167e58369f5bc7d31018b862b0f73b3a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5347 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-instret_overflow.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 5573
- `line_count`: 66
- `sha256`: 2ebaf16c24e3ab5b13d4698be86bbf70a48ce5c42691d4053a74f4ed209c5030
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5573 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-ld-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 5349
- `line_count`: 63
- `sha256`: c15ba1062654ef5f163219f9b84243ad1f2fe7203f9771f3be50a2a5d7be232f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5349 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-lh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 5562
- `line_count`: 66
- `sha256`: c08ef7bb6b14d35395468b0054077b2024c7045364f6ba36c3a0d0d0f0a330f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5562 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-lw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 5511
- `line_count`: 65
- `sha256`: 18dcaf5c1f5c8020cd71164c4e367f30d64b957d278b484195cf18037352de4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5511 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-ma_addr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 14bc940d89ed407333b1a4d3ff70378e944a7f2a277c9a136f80dbe9f2060836
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 5406
- `line_count`: 64
- `sha256`: 79bf560776b58f3991b797623c53213be362047bc03a138f447ed04c69a5f363
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5406 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-mcsr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 5402
- `line_count`: 64
- `sha256`: fa5d08a6e538b609f09307a26012acbb68c593fb7b98b20f36162ebc60a18b77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5402 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-pmpaddr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 5080
- `line_count`: 60
- `sha256`: 87342d99d518b08b8d2aa4065cb11af271ff59f31172768d178b78fe0973e791
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5080 bytes; lines=60; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: 0f1812d55ca9e2803ac612c5fc6541e361eb6ee295f92ca740c61500c060f09f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 5509
- `line_count`: 65
- `sha256`: a5e65c8d3322e0b2af2a13e0c8f85b9dad1ef874099fbe30c9000a80afc77bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5509 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sd-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 5422
- `line_count`: 64
- `sha256`: 57f5b1ded7e7aadfbf093e3713e79ee87566bde054ae1262604ac160a6471a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5422 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 5429
- `line_count`: 64
- `sha256`: 1d64461f3f8def1a5cc6e4a5efaae8cffc5a98c7346e89209d0153e35b0c52b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5429 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-sw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 5416
- `line_count`: 64
- `sha256`: 8f4766cb7173ecf38d671f2776f548082e131d20fbdc614c1e04705e4c44588c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5416 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64mi-p-zicntr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 5493
- `line_count`: 65
- `sha256`: 869565461156b7577f31db9b52f54c47b87b38b58d18dff1263fb81d8ea2b459
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5493 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 5572
- `line_count`: 66
- `sha256`: aa89f37f9b9acccf645e338b3971ded929af03fffdd2da912b6775b4cb08ddfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5572 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-dirty.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 5447
- `line_count`: 64
- `sha256`: 71c71342be04544238cb43b2881092a19bddf6d7e236fa3d312b2c31a5604bcb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5447 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-icache-alias.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: ad28f1b8772fb966898a361ea866f829ccfe5c8f0cd7923eef15bae63ecf96bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 5149
- `line_count`: 61
- `sha256`: b436a5616d38f5d947cd60c0b8413b07881adf5fb034db0bad827aab98b1a926
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5149 bytes; lines=61; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 5619
- `line_count`: 67
- `sha256`: 25d20d02bf87235e477e3dfaf8e2b3a2ad73ccf8dbc0e7c83bd856b63b6c3d2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5619 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 5327
- `line_count`: 63
- `sha256`: 1a1dd69fc4240c6d7ca42bce7fe1d88468e579592d23d18861c91e7f92c01099
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5327 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64si-p-wfi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5275
- `line_count`: 62
- `sha256`: e9ec88f9a0967d1148137cef4b71cbe94f3b5313a6a5279df912b8624f75d22a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5275 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5344
- `line_count`: 63
- `sha256`: 48e7b9c111dce9d1099c57e4d1a017e2f3fd76eb7a46bb76a9f68363b4585b50
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5344 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5275
- `line_count`: 62
- `sha256`: e147c01898fc6466c436281ea578ff4695a6d16fb044045f407a8b82f0c46db0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5275 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5275
- `line_count`: 62
- `sha256`: aac3330e24080a794dec86b0d41d6ade31a9a80e5e315aa677165c04e65782bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5275 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5277
- `line_count`: 62
- `sha256`: d8804e803da400469e6a6b7a88047b318924f381dd63818dc03b7de7c2b08fc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5277 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5219
- `line_count`: 61
- `sha256`: d8c94d34fda3a26a187292a7c2dfe26ae365bcf1b9cc1e6e7c2ca987d3f8e1dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5219 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5278
- `line_count`: 62
- `sha256`: 868746113ec01035d4ca13dcaed2868cb3916f5dfdc593d0e1c74c1343c5b393
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5278 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5220
- `line_count`: 61
- `sha256`: 6e316fdf7e03c8f1e11459bcf11357265f3fb8764dc81447acbb3e6d431c0992
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5220 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5277
- `line_count`: 62
- `sha256`: 1751d5fc972d120bffc112c9a9c59f70e6dd0bd556bcae1efad5024500ef6053
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5277 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5219
- `line_count`: 61
- `sha256`: ffd2ff76777317f11881206b5a582ae1f365d25ad965850c284b2cd0f6c4efff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5219 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5278
- `line_count`: 62
- `sha256`: 5cb911d3f6775376f4bbf0fa71e5bd41f8bf1c45ec157b4c4f0c834b86e3e217
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5278 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5220
- `line_count`: 61
- `sha256`: 8a1f89f5374414141be5c60a7ac3d40804809be6d789866d82571adaa0caa7e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5220 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5343
- `line_count`: 63
- `sha256`: 0cf067c61ce1322705c1ba78ee0c1d401e6efcd5a80c44afddaec0135686547e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5343 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5343
- `line_count`: 63
- `sha256`: 5985eac78b554fba7c3c19d6cb16a8c53dfd609ab79295a88fb46cf3a525b445
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5343 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5276
- `line_count`: 62
- `sha256`: 1615bd7a20a3995bf420e96fd14714a990765828fd459a52a602bb98c20291fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5276 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5276
- `line_count`: 62
- `sha256`: 670f06da063984a97247969768d619022175763ad6fe012071d683894af7df8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5276 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5344
- `line_count`: 63
- `sha256`: f71693b834727a77bebca2186713d3e952bc3de34a1a75d166728634ea970cf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5344 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5484
- `line_count`: 65
- `sha256`: 587ed731e3079c35d16437a11ea8eb072750d943db21ae9fcbde5a5c81c35c3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5484 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5645
- `line_count`: 66
- `sha256`: cb04ae560630d3794c6c04823be8231d6f91fb6b6a4e334fd387032a6636a954
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5645 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5646
- `line_count`: 67
- `sha256`: 5a667e9ac349095761a17a021185396e24aa6096dc6e85b57e7af91d1dc7131f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5646 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5432
- `line_count`: 64
- `sha256`: e55dbf68f536577b888e2b55e0ba59afaf07fa6b6a9928ed1647f35cb7cdb921
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5432 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5484
- `line_count`: 65
- `sha256`: 138b2b1ff8b6fdfe8d69bcbf2137a5ba2e2cd1d66d046bebc8752bb7b86fa279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5484 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5502
- `line_count`: 65
- `sha256`: 94d747aa5b7a7b5e000c4f9e9f3389b0691c65fb6d7d541ca492159b61ae0627
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5502 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5499
- `line_count`: 65
- `sha256`: 3ce25d7ec191edbb7289a212fb22a4c64ed20b87238ac50c311a98798efb8ef2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5499 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5514
- `line_count`: 65
- `sha256`: 38aea8f1d4fdcc62852c0658748497ef27092b1f63ad4e9d4e9f4942d970675a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5514 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5501
- `line_count`: 65
- `sha256`: 689d7002b18c05ac7bb16b4ad4188b4d266f075e81e0c39b1239cdc63b93e88d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5501 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5503
- `line_count`: 65
- `sha256`: 6ae2708bfa788b4df709e7eca758509c84a9ca4eda423af491836f67de66d70e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5503 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5505
- `line_count`: 65
- `sha256`: 6f4c840ec83759e267134fb8b031458f68728565a58d0069ee9e22eaedbcc1cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5505 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5348
- `line_count`: 63
- `sha256`: ce9bf5fdc642721f7d4a5be04e4e450e226e10d35fd470e666db99e093ca1e40
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5348 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5500
- `line_count`: 65
- `sha256`: b67a3d9d60dfd3d18ece95d98f8cdfd3977d512f88b1944cf9c88007d3bd5579
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5500 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5216
- `line_count`: 61
- `sha256`: a7b27b04958372331b9d5602cf41fe6cc4eb1397f6a3f1a3da3a187343755f99
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5216 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5635
- `line_count`: 67
- `sha256`: 3cf795d292d0896e8c9a1153c8b19b69c816984b2e756778c367613a655bc545
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5635 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5433
- `line_count`: 64
- `sha256`: 620cedbe8bb56f40c2d76bc15a5ae03a527500aa6d1ad49124f9ef45b2b88d6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5433 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5485
- `line_count`: 65
- `sha256`: 2f3fd182d647991cf42d13fa4e905c68bcc45bb8beae65b46283695d92901c0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5485 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5502
- `line_count`: 65
- `sha256`: 607980dcd7237ee1cfb042f7c6f42b7d452787b026a08da18876409fd822936f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5502 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5353
- `line_count`: 63
- `sha256`: e221109cb0583b2dc649d7a7f61d7526d2a79f7f044d5186b8ac4beb07974558
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5353 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5511
- `line_count`: 65
- `sha256`: 806adc2535c4b681fd573d1b6680bc1f394b350f0608310d68430d890083fce0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5511 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5502
- `line_count`: 65
- `sha256`: f2249b8f57420fb001fb02a7ed0cf9e240c499536ef73c7962af2ec5f759097c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5502 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5504
- `line_count`: 65
- `sha256`: 1115eca2820763b10123730e90044a475452c0cf75e388c459143f622841ec13
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5504 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5503
- `line_count`: 65
- `sha256`: 2b88525e68428082ee95b2c0142412746bcce1e00794c763bf64f7570ab3b651
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5503 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5273
- `line_count`: 62
- `sha256`: c984e760dffbf17ef61f7ec7095b5523663ef024665432f5dca2f2c8df66877a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5273 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: 7d6c4bba4da39bc371ccdd5ba7c98d5f4a8e6b84a672c51242abf595f231cd1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5279
- `line_count`: 62
- `sha256`: 92d4eb56fbdf6d00c0b3a3d3c436786892eb0a60d35292ea4c0f889018efb6c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5279 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: a5cf2929221e7e579540c0a31d7f08580551abe6d693383fd71b3b50464984d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: b24920cd6e40bf43eaf9a2d22ca597ca534a8df5e59a5e0c95340469ce8b4507
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: d09e8f25e412b7300d8f9145a6dc58b1cff977b1f03f46d79b11dea7ce525b8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 39b150456798ec5253f61594e58d3ed8bfa74719e24e49d5ced8890396b1f0b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 630b219c4e5948e924a7fa99ce6d37c0606b3685e504dfcb9eb7467abb3c0749
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: fda1cdc5f746a4985403ecdf48729801810ba2750ca1659dbc9ef1ec6fa65398
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: 399c43830e791305d9f1be6d3cf7915031504c1ff1335bde91ef18bedb059d11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 59677e8577815953b542b6fa114e643a1d759f9f8222b9442d1f79b54a247f67
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: c91433882d3e0e6d5699270c3f4f73532648d6ae7f7ec2022acef484c3009a14
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 289a71862a90245b5c125a9fda639f609019cdb40b2f727104bdda5fb7fee2c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 5e89b2c9bb75a1ee58d5bdf4053191860df4779da900334c990aaed1095ab43e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: d0e7aca0deafc4eec9403e3ee5229517c68880c36f3087df1d69a23feb369c91
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: ccc46c672b170f5bc1812ccdf9cdb0095bf5563c6634ecd3df14d1d864d58f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5515
- `line_count`: 65
- `sha256`: b4db420c2b32f4819bd3c7b8def3c589851aeba3025c9bd167983a8aa90a6aa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5515 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5260
- `line_count`: 62
- `sha256`: 0557f50e9e8d546d2084727fb4162203dbab648383b35115788055fa23a2ed6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5260 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5565
- `line_count`: 66
- `sha256`: 3f3f58338b0a04a2ead5259cc93bb981b746167b4d47d467cbced611785fd1cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5565 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 225f51c0f40ecd38ef43e5f48e2e0fda836cd80f3e67a43e327f3606bb5b5b6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 48b5baa353c9ae7c1a64b562cbcef34f2fb5c9ba22006116c3f259bb63305231
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: b65cdddcd9e451fc4fee7a60af32225842eecd98c4154c8050d8b26311197d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5754
- `line_count`: 68
- `sha256`: 7e6a1f4884b97431fec336b3dc8a5307a292aaa16f3ec0f09bae07b988df6178
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5754 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 05095968209156a380d1e96b50e213740da7047d180ccd852779e740af42245e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 1e1cbbf3342a3eece679a36ad61744fcf6092a19d7f3208636e67880b8243840
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5340
- `line_count`: 63
- `sha256`: 68537a5638b6d6fa122646bc008daeaec5bdb79074805936a728f1905329dd27
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5340 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 2853cf0c31b2ceab2859a8547d95a94d1397eb31897badf75138381bf4708741
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: dab321302fbdca6ee6e4c68fc79ff92d8d2ce1608192b7b43b455f236db8935a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5765
- `line_count`: 68
- `sha256`: d6bc41fcb1ba18fad4735fb35adada07884e004a0e8b24d1e21a72cd732d7de5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5765 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 02cf55db78bb36e6c076c45166267abd54e516ec02111011897dbdb53f7643e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: a1635e30c5d98e3782c57296b6c704e328e513207a3ab93b1ddadefd4e499a6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5720
- `line_count`: 68
- `sha256`: a0d0f9bb7731e8fd873e9e7cd9dcc4613dfe6271e6baee922b895bef8226b840
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5720 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5720
- `line_count`: 68
- `sha256`: c1ec43b9aaea506a8bc2b42077772954446d9bb6bffaa89530514902a21b415f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5720 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5720
- `line_count`: 68
- `sha256`: 74f1410a9e8c63aceea37c02b176ceed978b6cac561bc12395e12d948ac27241
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5720 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5182
- `line_count`: 61
- `sha256`: b92d86edfbf4457f0b444e9b24b01372cb062e0a336c05a012fa244bbac7e658
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5182 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 1f4d56e7e08652e3ba63ec5ccc08664a26a24ce2b5ef9e1a7787680a3b3a8cfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 4c690d735bea9c795694ce9276b1ad5690d4c77dcee2e93a1bd9db17a57b2f68
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 410fe26839f2d8f256a9005b401ceb636c2f3381ceedb27a97db77dd3b99fb42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 1cde1b94f735865ad9a2040b2d91c629842a5f03f8f1b816bca4c6fd7280e929
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 8376717492fba8bd2f9877659513e1bef0e1a9a6b7cbe802b52102146c9af346
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 88abd1f402038d9ec23aebbf15604adc8db4cc5a74e8f4ffab01f515bec2ca7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 9a44b481811598f99e0b5d0a206009fccdae944737d4d12fffb886bb69e6c58f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 058678ab03b361e2911c4882603ec6750b929a4152d6492f589f2d2f02071c72
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 31ed95de121c2a80f8826a9d5ff9cefb0039abf732db275f9f276f2fed62f08c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: ef67311875c5cbc9e2735982c8994cb22afa870fdfad5aa8fa5d4d31cf17a463
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: de2a6bb4a5dfd9463aabb84e1045ff949507c09aa0d48b8d4637a19c38050075
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 80607c15a4a8a3cc51e98237a72f72db0b3bb49fc13a02e0b70f805f9c00bdf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 698f65d0347e94691eda47cfdfe3f830c2d5211bef1777873433ccd344f5afee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 34e70d7ac3a2f130b86345c18ee765e2d369f19f005f9e7052093ee9788d6b00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 0eed7db56dd4b7e02cb374584c6682cab9248b400e1080656ce473a75370327f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 35bb68ce81868888c6346f3f4245e16722b7e3c4a9d039d67a863916dbf23c2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5513
- `line_count`: 65
- `sha256`: 7f0ebaf27915cb84d1895bd4b0c30a82adb69e88fab1be2bc9b96829938b0abb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5513 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b18421dae7816034a189444064151cb00361fa495a77bdd84ff96f676f6de9b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 5dcb1204dbd9ef8093b5782fa554954ebc78a952d340e7d858f508f06458a64a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5720
- `line_count`: 68
- `sha256`: 7775b84a428132456cb6179f2ad19b0af1eea8a58feaeaaa58baa199dc29a7c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5720 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 5d714c484dcb6a483ba80b1a80bec8517d02dde82f7151f824b3b98474f5cc16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: f70f321d900ddf12bcff65ecbd35016ae242d3d51722d7599f25ea72a0d8d2d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5342
- `line_count`: 63
- `sha256`: ed3a7b85985066f11a9f1c9aee120a50169ae3b2efe7e290fe8e53126772703e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5342 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: 779a3ed0f3eafd5ec3f188b719e35d980ca95cfd839cc794ccd222386ef590eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5345
- `line_count`: 63
- `sha256`: 2451fb611b5920b447829b087cfe92f89589dd7ff5689c7cb9717c2180fdd5fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5345 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5482
- `line_count`: 65
- `sha256`: a1c400176634e3606af87f69d1f01a7a583219554c6ccff05bd79796ef1b10fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5482 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 5d0dab30540109c6f1a1f5c50d6c3cb4264bd43e0bdc9b3af218e7859add5de3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b12ddecdb51da01551481663a90a9dbe3757ab3a590626863bfd9517da4a1622
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: b3d6b4970234441c7275809275f607cb8138ddb14141e2ef108a78a06a8a39d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 677cea59dead5e9f9266022b764048c22b58b75545ed4b71a88d038739abc071
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: b28178284e00c2515b6e7065f914cba6d1c5ce9f33759736e5df24f75bb98a6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: 84bb86c720d25536389c758507fc0eb7adf0c1aaa703c9d781b089e2c24f6fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5343
- `line_count`: 63
- `sha256`: b10876f963b8203e0a0f0eb9f6ca3f785de12787e756f69326851a532a880b0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5343 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: e99569dbf273a23f5116182dcfd8dbfe2ee073c804b333729f1bed161da2bf7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5482
- `line_count`: 65
- `sha256`: fcffc73126cef4ef97aec1e262e328cee30c9f1eb7ee98aa55058795c3a8ec94
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5482 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: ab6fded00ad11a73936684a2d2ff024588cead619cf60aac95c030ef1957430e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 0a764ac78c0688a0d3fa9b864a3b7c8aa3bb71cec98fdce58213402009acfd2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 15d0c2d8718838eed20f440fd7c66e25d9323a3ba74bbd40e5cc425eee32fb67
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 58959cb01e9cf127bafb26fb3219d052db9d4eead7c40b65f9a351604219237c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: b225bf01989ff404e389460fde1eaf3578b9562339aba706b311a7b597fd1f7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: d99457108d6ac1ef3c4c239753c9b0be108467e0262f3402f61f15e2707d6c60
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 74b1e65edb70fa0f73397c6c209933da802052e9a6ed26d1358a2624cbfee6f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: f27631421d2534bdedd47db40efeea03e3e469d7cb7421896a0877e9d1ee87c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 27a4045873ef32a07049d33afdc9a2c344f64ca65ccac41efb51de30251b0d5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 8ac4922e0f3eac65c70e933185daebae092ff9a9a33816308dd6afacdcc890c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 2ed027372a7b8bbe7952cbce4679727685f08481b0cac5ff210e5b7f6bbcb34a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5495
- `line_count`: 65
- `sha256`: accf57dd24f745a532b2beb93f2da08d99b11f47d2e3b56b1cc290753ba59c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5495 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 44b2d41214b8b26d318f0823c6ee9c10ead89efc2bf60f71b8e707106490009b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 160d732ee68716d539f455f27e0641b1ac5d46b2ead9034ef7db4bbe6d7a6948
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b8780829aadb5f64387b5e3cb728df718a90545bb336f8dbe006356466332837
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 3db36368a87bd59f40f130e58f0a8fe08abed162d6aeacd46b5d4bfcb904987a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: f086b63de29e9c7f35ae1ffb2009e35cb8aaa527b54e939ec2d43c0f6972198c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 35956f69551e3680e713248ee6d01d900c129b4b5df0888fbc4539a74f6bd0e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 5701c3ba864684dbacea4bf3cb5a04c17bdb45cfc326f94173ff78ad25b067f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 098631a576ea6c7b9dba9bd9c91ae582db05f122e77d3d6d33cd6c623579415f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 609ea2f9a63ccd5792d824661086e7f2a522ee34c9618040b88e532124cafed0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c8a9b912ebf29c431d279070c0a7481799beb7002fb816ecf5397b22723b58ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 1b7cb03d94a1bc9be7a8abc6beba376bf3c537c704c7a8e92b4e7ee99ae1a10a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 2e090476058de87ba0c4a1da04bb4841082585957cbea9d53e494dd98addf705
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 217616f972b017b00ce6e1a59f3bb7f760262857d27a2ce12f56350d8b14ea7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 3c0b92c02e4dd41fb961ee99d946f8ae209fc54e0c0b15076a1d769bb119ae4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 1bd146ac665cdc4bb8ec60d51b38d7b3aa56c2bf35953f0591c82111898678ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 0375442784c518a4377cf57eca5783d68941eb2f32094e2778cc332a1c8d807e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: 7610aa29a1da6a425be9738670e308243bbfaf75850cef5dc24922efb98f523e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 0aa265658d1d0fa107a087985f867a847ab1e558fd03168ec03c124a786231d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: bafa0d8b107c77f40f20a488b368d13f82d350f34d48ffd61a7a2c84802e43a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 0db0ebd2bc3e056a7cd32049d3f8b4a20ee592b7e220a525312c09132a20217a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 65817e68bdae5d1b2f4db273605d6852056e0c98b57bf1bc2ad60bb87e1c90b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: dd4bbe924c352ebeb40578cb0e7c36a37bd7665cceed34f9dd036cb1f416b683
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: 86aef342bef2cf3fc19c956e88bc0f9c27ca5684dd2d1553d904deffe2cb027a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: f9e67a50bc0b444b660a3a2556d33be0db135d819b662b5a4061c24d0bd826cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 0c1075370193f14eead86c68eb808e8e7811a405ebb63892acbc04904dd0a0e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 8012d70bc3ae45e2bafb926426711b24e47b6ca5bc7a34c3ff6eea19dc4b8546
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: bce89bf19c10dd2d42fa3f71840389756d793720001dbcbb24fa3c8903be9eae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 031c69856c913c5e03fc703655fe9b679c597526c18ed6c42f70f02f9a452340
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 4670f9ac26a1081e44e5bbd5f07f22ba116573869be697556aa16d33878b408b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: d9f0bb0ee535dc0a04dfc6ed60a10f1777a0abe9fab7edc3555d03bae2a6722f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 8ff4658e88138ac48c4d215242e0685f56e55545138fa8c2a23a7bbd7424d06a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/status.txt

- `kind`: txt
- `size_bytes`: 17953
- `line_count`: 360
- `sha256`: 6331b8133bf6a2f9565da82d98a66e8297454f4b266e02bfba07741e38a5ce54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=17953 bytes; lines=360; PASS=718; tail=module-testbench PASS verilator-lint PASS npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS r...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/summary.txt

- `kind`: txt
- `size_bytes`: 18010
- `line_count`: 546
- `sha256`: af0f3006d00a8c6039f97e801a39c44acae6c202114b13b7ea203a7ec276aac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=18010 bytes; lines=546; PASS=718; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-070445-3680760/verilator-lint.log

- `kind`: log
- `size_bytes`: 8904
- `line_count`: 6
- `sha256`: cb5c471ac4b7b60851b8bec656957cf00fab0d12e424abaad9aa2615589f119c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=8904 bytes; lines=6; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359857
- `line_count`: 4547
- `sha256`: 58d4b0ec7adf041863d0540ed90c8583f63f76d98be97e7d69b5936c1e8bb454
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359857 bytes; lines=4547; GOOD_TRAP=21; tail=nch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000080 miss=1 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000010 miss=1 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x80000070 miss=1 [0m [1;34m[cpu-exec.cpp:1600 statistic] #4 pc=0x80...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench.log

- `kind`: log
- `size_bytes`: 3440
- `line_count`: 108
- `sha256`: 2efa62834454d284b27a7ecc4e5ec3f379bdfcdf7c9736f9783998f0dca09316
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: log evidence; size=3440 bytes; lines=108; PASS=194; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-372...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: 1b698a45a0cbf2804124a361232cdd2011bd46bf73e000f176e093543d3a0182
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13021
- `line_count`: 78
- `sha256`: 8301c3bde59878ae6d5109191c241ac592a3ac762edfcdd7ced3653ca7591ccc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13021 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 12697
- `line_count`: 76
- `sha256`: 4a747b90d2bcb5ef4177db439708a9c0aa9041c6fca30fe2e6634102752db064
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12697 bytes; lines=76; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: 7ea42d26f8d6baca1cff60e5c45a3f8d4e444697bbe112118beba4463b0fa486
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 65a906487ab3e95672cb4c41f3189e3c1d40c84050de1dd27bf343ccecc865bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15720
- `line_count`: 68
- `sha256`: 2d9af0effa6b80241f40994015633b2456be9309290dbc8c4a284911170f7342
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15720 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: 412281b6aa25bc130cbe9f0107c3d7e76cd620154a213b3c5febfe4f2e750275
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 7105
- `line_count`: 50
- `sha256`: 9c38dfa63e9561756ca2572a894f6892ab6d3dbd8c9330939ef27c288f996e60
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7105 bytes; lines=50; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: d5e58b41e4b43d465164107f0f5c963e95696b14baa0731ab4015b55d985617b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: 3b0e88f90869448ec0aecbf4b71381ba749daef8de8920e967bd2a6f82994498
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 9020fadf1571a6bae166fc23caa1978d379d49e27c0f3ca9573855f9a4aa4c3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: d3752bbf4369d1aebb055946b55a1adc819b01885217a162247ab750590a9d20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build/tb_ooo_fetch_branch_target.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: f3b845b1ce2d8c79e16b356fec6024f4ef74a65b77eee8cd81dea31980f22a7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 4ec29a1cdff0f80e3f77c08bb3de14dc7d8fe49e2bc8e4cad52de8c9d873663e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f3a7515456977a869b9657be0b0aea9bff8bc0628550955601e1d083f95f6abd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 5e186a99dd409b52bb1c67147c3b48f201864145d3e4a8bdbb4dfc2552593874
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: b45cb70091362b646ef0addfe93ff480bd540246401570dc5126bb80d213b6b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 74fc78baa425db593c5f0a5302321f305947dcde430aacf50887a69203801a0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 15649
- `line_count`: 67
- `sha256`: 00d74ac2a6db05e75176ff384efa0a5abb781a094131f1785ccc0cfeaae4c72d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15649 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3643
- `line_count`: 36
- `sha256`: 5bf4803c5fcf60371aecd4e0ad40d7e343b1614934213355284d9ba378bafe7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3643 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 12
- `sha256`: 73cf2253470a50eb3504d7bb3d41a250402cc47a6799641ca8ec049bbdfcf358
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=976 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 3ff6b452cbc5e2086c6b98ecab489b3f74bf944a91005a340693ecf9eb3ead68
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12479
- `line_count`: 88
- `sha256`: 806cd2230f0ed134086f9a7d25b52b64a558e1f6ee163cd56165070ba70a4304
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12479 bytes; lines=88; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7516
- `line_count`: 63
- `sha256`: af522b2fe17990243763d684a8d79d4d81a86290002578937272c71807b7457c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7516 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 73f2a262a8820cfdf8b4903d54c8fbbd9381d43099d271ddc577e379aa64c26e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: edece60c135f85ff7b0f7696ed98bb7a8aa49f5d1b17ada2804d9b137a97bbf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build/tb_ooo_pending_drain...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: 6e8b03051f6459e31cca0e186e2c3f11127fd8fb876bb0dfcb212767b79303b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15725
- `line_count`: 68
- `sha256`: 613bb0504f8cd23b2b2e51c2207eadc198542ea5054bf372d3b452501c9a2307
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15725 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 154155
- `line_count`: 1102
- `sha256`: 2b32a3561063f01d7f2ad87e38c7a001846dbfba09bcdb55564fdd196b9b6e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=154155 bytes; lines=1102; PASS=2; tail=ing: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 3293
- `line_count`: 106
- `sha256`: b7f6c223a00445e512f077484a3de6e80883c64bb4b51d08ea193bd1adaac4b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: txt evidence; size=3293 bytes; lines=106; PASS=194; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s202603...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/npc-build.log

- `kind`: log
- `size_bytes`: 49016
- `line_count`: 60
- `sha256`: b4fc559874abef9a6aa77966bd2db640a1b32347a9eeb9e89c99bc834d7c16c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__"]}
- `summary`: log evidence; size=49016 bytes; lines=60; symbolic=__0__,__1__,__2__,__3__,__4__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: cc3283be2d3af0b21b29235ca6c60d83bb098fd68cd6f153d33023eedacc3b52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 47e29494a4241f578e599351b19a82a712b75787d91de83949079ab9d9839adf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 13ce4273d9b27cfcacbeed78b68fd735d70baa5cab02affb6c7f26a35b3e5f93
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: dad7a2991eca65a0e02008e21210373d0f839bab5bbf504b6a69f46565e33384
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 5516e3335eaeb4c9717e68362e0c43474756ac3960da2d83473dcd04b3d03cd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: cf3b7ebfa8e31277e0bb459653f89d6faff6ccbfe923180e43f4e12ba0213da2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: 511df8efb058a5059292beac5ecb0b8ac48bfcb5ba0d3e5f06f47f00d7447d8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 310b101e0f542e6b8834821d875469f208575ca087d5473c86042738a1d725ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 2a0b1ecd16b39937ffbd25c6b8464f7897531f238b0383d75091231e616dfef1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b8fe361aada36ad62e4046f23ad8b74ea6fa3ca3d172033bca1f1e627b6ff5f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: fbfaa89f57adb234bf194c9904c2c49f58b28f79b4d4b841163ad8288bcdfd5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 2995c9d65f30d068ec9be403c8a434494fe1130e94a020e85a9853cd47c84b74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c893efd3c2588ee5d1a4b3a292872c0c5a56c17c0c0be12e484dc27a11227e86
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5515
- `line_count`: 65
- `sha256`: 40bcf18312b6dbf8dd98ceca23bafc8d4470290abbe245b6ee2bd89ebde7a98a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5515 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5260
- `line_count`: 62
- `sha256`: 9fa47b58fdbbb947e5029aa7b55c367cb5707a0e90be46824feb6f6d4422af06
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5260 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5565
- `line_count`: 66
- `sha256`: ccf64c0bbc0cedf5e97bf160c4f50d2a8e9173fae4e44bae7b450100f9bb3ce2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5565 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 6f15fbb053233e763a62e1962d27ff0f8d19cc676e38e78563d24689f41b0c69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 75eee96a5c1df5769e6c4cc3821dd467c1fd46085b54ebe34a47e8d1c92b9001
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 38e9f90f0d4ad06dc9888d9cbdd7de9c0be361dad8aaa0b09a461afa09f7f3fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5754
- `line_count`: 68
- `sha256`: 5bf0cafa79e4c884fa7f47690bdfa07a82b81e954fd4ad6c9727a1fcaa6e4ac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5754 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 148ff0aa7fbd21ab492ed74985ecaae243cfb59a1a41bdf43a8ed507aa443ab4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: b4f722e38b7b42b21c7a3183006fff035ea8471253817694279713f608cc4c46
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5340
- `line_count`: 63
- `sha256`: 50da255122dc557acd93c465fa217b70800d18bf098c88f613018cf033d67078
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5340 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: 9a038f95d1356f084285f27a200a1d302328c514ecf9b3dfbd80897ee29b0a62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 7de510d6de764a807f57429a58385b374296927051fd14b828f2642e3ad4058d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5765
- `line_count`: 68
- `sha256`: 04d00137e2db3842587285cdd274f82cdc6bf48d7d52778d94102cf17fa268b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5765 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: c183382a4b83446604f88945b312912c4942235499f99afb2caaceb7613a2598
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: d01dc72a7f7b4eb9dd98cc3cc77f5ae51ae959e6c3576b620dca3713ca24a4e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/status.txt

- `kind`: txt
- `size_bytes`: 3170
- `line_count`: 65
- `sha256`: f15698e42ae48b6f19acdebee610c15ae805900311c43fc26356922bade998b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 130}
- `summary`: txt evidence; size=3170 bytes; lines=65; PASS=130; tail=module-testbench PASS verilator-lint PASS npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS r...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/summary.txt

- `kind`: txt
- `size_bytes`: 3333
- `line_count`: 104
- `sha256`: 3de0e75f0c8785ad3f0bcbad179966d949ebf2bc32dc742b373f10a75b5e3463
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 130}
- `summary`: txt evidence; size=3333 bytes; lines=104; PASS=130; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/core-regress/20260714-073314-3726461/verilator-lint.log

- `kind`: log
- `size_bytes`: 8904
- `line_count`: 6
- `sha256`: ee159a8bb5eb1638f50555d503b2ea27604a64498af38e8ce9c30fb2b2001891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=8904 bytes; lines=6; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/csrqh-directed-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15767
- `line_count`: 68
- `sha256`: b16045996e8f8d54a9057833803b5fe5acf377a4a45a27bd037e226d2c0a9709
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15767 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DT3U_CSR_QH_DIRECTED -s tb_ooo_core_top_glue -o build-t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/csrqh-directed-v1/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: 530a1810f487b009c06baecab5ac06270810c9519068adcc988049fc273eb4c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DT3U_CSR_QH_DIRECTED -s tb_ooo_frontend_run_gate -o...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/csrqh-directed-v1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 10986
- `line_count`: 66
- `sha256`: 58478ce8f501e637efec8e9a39ae48ff891f046b2ec5c47d7dbfe99a544a48cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=10986 bytes; lines=66; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DT3U_CSR_QH_DIRECTED -s tb_ooo_int_backend -o build-t3v-c...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/csrqh-directed-v1/summary.txt

- `kind`: txt
- `size_bytes`: 341
- `line_count`: 12
- `sha256`: 7b45d07f8fa383e7c3c0178a67ed315704fbcf70b484482f99d9efb6cc1a3fa5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 6}
- `summary`: txt evidence; size=341 bytes; lines=12; PASS=6; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/csrqh-directed-v1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_frontend_run_gate - PASS t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/fetch-fault-predecode-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15796
- `line_count`: 68
- `sha256`: 7f60b37c00794cbd74f30a72e34dbfbf612540be9aa857fb5d516996c319aa10
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15796 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/build...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/fetch-fault-predecode-v1/summary.txt

- `kind`: txt
- `size_bytes`: 565
- `line_count`: 15
- `sha256`: cb53a99526ea8871396c263a48a78a06959cd5eb72e50aac0f1c77eda5274913
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=565 bytes; lines=15; PASS=2; tail=PASS fetch_fault_predecode_integration timestamp=2026-07-14T07:18:46+08:00 head=31e90c679050a3a9138c967151b240f0fa2ab158 tool=Icarus Verilog 12.0 stable ooo_assert=enabled fault_addr=0x0000000080000010 fault_owner=post-CSR-refetch packet lane1 packet_decode...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 5
- `sha256`: 4eac7f5551b4a8407d107c4b330dd0f745f38bf394e0e1609b5f8968f14e80f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=365 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build-t3v-final-module-v1/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/e...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: 0514f8711106a51063d1779d8ed44e7e4c964c9485af2c4e014ee09bcaf6a4a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build-t3v-final-module-v1/tb_axi_clint.vvp /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3495
- `line_count`: 28
- `sha256`: 5a7447189f14aa16bdabe8825e7c7f68c94035b2fb28057139fef92efc4181b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3495 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build-t3v-final-module-v1/tb_axi_exec_firewall.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: 49e14bf18484b4829bd0c10e929edb80384f49107fcf2a89c3937d905c36fb8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build-t3v-final-module-v1/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 461
- `line_count`: 5
- `sha256`: 9539ccf77fe4a7b2880d50c8a04e5c37ab30b3a4ce4bc2a0be3e7e0c09e7e54a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=461 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build-t3v-final-module-v1/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3274
- `line_count`: 28
- `sha256`: 01f35e28b277bfc2eb1e48e3b85774d89bafbb050a2d84527947e20eb57769b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3274 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build-t3v-final-module-v1/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 392
- `line_count`: 5
- `sha256`: 1b47339e8fbb4c19befde133b63a589948f86f1053f17ffee7e81514feda0df8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=392 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build-t3v-final-module-v1/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 392
- `line_count`: 5
- `sha256`: a1555e06a5743445ab9553a7e8a27fa13e308f31755b1003f54a00e4d301f015
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=392 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build-t3v-final-module-v1/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 536
- `line_count`: 5
- `sha256`: 8e0185a57d18c4ed7dd4ede0dcfee6d0f26fbdcc8a3761ebbfbffa81b8a21fee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=536 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build-t3v-final-module-v1/tb_decode_stage.vvp /home/lyg/PA/ysy...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4fbb0d11e559ad69f224c6e32813fdca50b6b753e0d30cc62dba3fa19b49cb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build-t3v-final-module-v1/tb_decode_unit.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 381
- `line_count`: 5
- `sha256`: 0c2f06df8ec075069b65e91fa5bfd9a195c606c31dcfb34f3724e0ea69206d75
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=381 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build-t3v-final-module-v1/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 488
- `line_count`: 5
- `sha256`: df7f2d003f6540aba8e1ec0e25287d6e60c38ead1270ce54c4afc91e91a40986
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=488 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build-t3v-final-module-v1/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/m...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: c56324a50d559605ceb9cc6243d5c347bc444440b9e9439b8db5143226820369
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build-t3v-final-module-v1/tb_lsu_control.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 416
- `line_count`: 5
- `sha256`: e084171c778f351d044d494cdbd710fa7cac04763f32e284c7dd0850fde55aae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=416 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build-t3v-final-module-v1/tb_lsu_datapath.vvp /home/lyg/PA/ysy...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13030
- `line_count`: 78
- `sha256`: b57fea2ba073c917d854a70f8c61b79604af18fc95d31f75946d42408dbea6c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13030 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build-t3v-final-module-v1/tb_ooo_alu_core_slice.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 12706
- `line_count`: 76
- `sha256`: d69bd9cb7f47b30e9de36de117120d1be5a275a4a800a3ee757434044cb734a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12706 bytes; lines=76; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build-t3v-final-module-v1/tb_ooo_alu_decod...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 416
- `line_count`: 5
- `sha256`: 4e8c1bfeffa918888c00a992dd8ae9727be42849fb8b02eb17d3a3c1b2f49bed
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=416 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build-t3v-final-module-v1/tb_ooo_amo_gate.vvp /home/lyg/PA/ysy...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: 4b91361df6cd45e09565df3f05a6ccdb15efecfd68b2a03972aa061b261023c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build-t3v-final-module-v1/tb_ooo_bac...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 446
- `line_count`: 5
- `sha256`: dc4405f81cc6ab5258d1e368cc729ab8ad2adcbe5f5bf2aedb57f1a030331375
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=446 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build-t3v-final-module-v1/tb_ooo_bitmanip_gate.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 873
- `line_count`: 9
- `sha256`: e0cba122e9857a247413dabe49dce68e8506c0244f5d24949d8e6945dca7c024
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=873 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build-t3v-final-module-v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 828
- `line_count`: 9
- `sha256`: 74de98e9a301fc16f519f12f9bcbefa548a394c17524ff2a0fb6461e6e7e5ad5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=828 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build-t3v-final-module-v1/tb_ooo_b...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 611
- `line_count`: 5
- `sha256`: 6fce8b55e5ef9d8979ecb534f78d2bf026ed63616246ed1da46597e45fa6b825
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=611 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build-t3v-final-module-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 883
- `line_count`: 9
- `sha256`: cb6f36f31414bd1124e0d82292edd3eb63e3e514e185152c92f5e65a9b661c1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=883 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build-t3v-final-module...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: a9c99f25b38e0799bca16585661249bd71d9cfda68bad8c5a4a8b4ae5b5aa9b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build-t3v-final-module-v1/tb_ooo_branch_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 568
- `line_count`: 6
- `sha256`: 32ef3559d0f0dfd8d00787cadefa29afb59ba772bbb1cabd42110b82293cb8e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=568 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build-t3v-final-module-v1/tb_ooo_busy_table.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 430
- `line_count`: 5
- `sha256`: 9462e029e3e38d0e12adde52ec18e70745f2d47caf1f6a22f6dfd9eee7814178
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=430 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-t3v-final-module-v1/tb_ooo_clmul_unit.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 786
- `line_count`: 9
- `sha256`: 4b94c473e95e9ac4c9925966b28e75d17361d921c87f1daa30b986cf69067806
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=786 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build-t3v-final-module-v1/tb_ooo_commit_outp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 9
- `sha256`: 81d20913efc570ac6840f4d1ea85e4e6668aecdd7ec88edb1bcfd24feb3d552a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build-t3v-final-module-v1/tb_o...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 838
- `line_count`: 9
- `sha256`: 9b68f313c85d35976463171f0d1f445b680faabf6ca3b3c0dc5dec73ed6a4cc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=838 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build-t3v-final-module-v1/tb_ooo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15740
- `line_count`: 68
- `sha256`: 9aa657e16c1dda6793f0997beeed634eefbd77f8809fbbcb00431b6955cef14b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15740 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build-t3v-final-module-v1/tb_ooo_core_top_glue.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: 0016f91fb24d596b8bd272dea61de0d086b8501d9f94763417f49013a444e42d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build-t3v-final-module-v1/tb_ooo_c...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: 07e527c37b817122b0784c9583c1a7798627e4401df004de6eef84cd1d33649c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build-t3v-final-module-v1/tb_ooo_csr_t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 62fec71a4617604e40733fe3c85364c25bb4d78088b4385741634ce927208266
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build-t3v-final-module-v1/tb_ooo_data_word_cache...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 83f3b2a24702781bde0c5baa67cc8ef7c76f8ba5d86348095ab5e8a1bebc1908
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build-t3v-final-module-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: 89da5d934a39a9a6c23089228a3aa7a4d4c0b8cb602ea5e892d6d14bc7d603ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build-t3v-final-module-v1/tb...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: fd5f50289d0dac3c2ab6bb58453f4f7e1793ff1f2ceffb90a1c130e2fd702d42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build-t3v-final-module-v1/tb...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 7125
- `line_count`: 50
- `sha256`: 4a639e8281c6ded966bfbaafec6b93d3899ccb3be7ee833d82f5758d8638afc4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7125 bytes; lines=50; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build-t3v-final-module-v1/tb_ooo_dispatch_back...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89739
- `line_count`: 717
- `sha256`: 779aae36ad52023c455d76b9fc414cd7bb7ab490159610159a6b2281f4801ef8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89739 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86482
- `line_count`: 650
- `sha256`: 9f616e2f14843abe32fbd56778cdf0b00d61cb6911222d00b38ea15d65cfd054
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86482 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86453
- `line_count`: 650
- `sha256`: 59f4f58ba5f217b340d1977f4d0e714b3823f9715ebd190b148a0b07900e6c44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86453 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89417
- `line_count`: 673
- `sha256`: 4e5114d892f15a7d3347ea8a99a081f53099020e7d4387c97c5a502a243a9056
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89417 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: cede08b0a1bfd212a1a3a57cf8cde78195fee5dab311e7cadf830b83dfe3b373
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build-t3v-final-module-v1/tb_ooo_fetch_b...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 477
- `line_count`: 5
- `sha256`: 6f9670e1be65568b19a32fb4414cfda0419e08ce685fc75b1b943036d09acf82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=477 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build-t3v-final-module-v1/tb_ooo_fetch_flo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 575
- `line_count`: 5
- `sha256`: f65858818e330c79b4c5d0115f4f1b4d68b4f238811242df42c226f157fb07cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=575 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build-t3v-final-module-v1/tb_o...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 629
- `line_count`: 5
- `sha256`: d28b41352b1db7185f04c79167d55b0bba48ea39dfcf2f0d33583b07e55eba1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=629 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build-t3v-final-module-v1/tb_ooo_fetch...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 5
- `sha256`: edc3a477997e11e4df81518ec5389da98294a8de69883b9863e659152af3ad15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=614 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build-t3v-final-module-v1/tb_ooo_fetch_pac...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 552
- `line_count`: 5
- `sha256`: 6575e97dc7750186e1442f786c9c1bb4dd193e777cb66ba578f8d9f96810172d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=552 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build-t3v-final-module-v1/tb_ooo_fetch_p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: 06b8c22fe5651efee053d80d64042c650c55df407420483f01f8e95bd6cf5a83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build-t3v-final-module-v1/tb_ooo_fetch_packe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 493
- `line_count`: 5
- `sha256`: e7fe59ae1d81c7079ac1060c3aa3efb4d9ea685facadaab6649e647294d4bc28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=493 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build-t3v-final-module-v1/tb_ooo_fet...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: f21b78cc1e9b4ebd764d10e4551a8ee650b3964e42abda9254799ca960296295
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build-t3v-final-module-v1/tb_ooo_fet...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87818
- `line_count`: 664
- `sha256`: d0b18ed36f81db64ef21e8dc8ab5d4636aebf4ea58094e09c318d433ab9735be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87818 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 5
- `sha256`: 2a1b21dea2c8329f2c2fae9bd4a6557c38070fd8f869f11da7812db6aafbc225
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build-t3v-final-mo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: 8f16626a95d524cba122340a3a70388ff3fa6b98fc0a53ce3aab0c4e60a53b9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build-t3v-final-module-v1/tb_ooo_fetch_reque...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 15669
- `line_count`: 67
- `sha256`: 9da9d3814fffa1e932ff744621b37a7bd7f2befe4c410bd677b0df6c6cb0c02b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15669 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build-t3v-final-module-v1/tb_ooo_fetch_trap_gate...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 447
- `line_count`: 5
- `sha256`: df1ee339e5f28b3f2f6f3ececa56dc5b28b30b4e2ae86bb6b16e2062da9b790b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=447 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-t3v-final-module-v1/tb_ooo_fp_arith_gate.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: 5588cc1b2aed4ec0569e007ffb9fb352fbf19b7044ec24dbf12a264fc2b94bc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build-t3v-final-module-v1/tb_ooo_fp_classify_g...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: 5a9271be5e62fe3a6347dd03041c37fd3f105d67e432c2d075f5031526a570f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build-t3v-final-module-v1/tb_ooo_fp_compare_gate...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: 3c0d50b6c11089359fdcf7bd5eaad033a1df4f5578a7c65b2d1cd8a37c80e8b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build-t3v-final-module-v1/tb_ooo_fp_convert_gate...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3663
- `line_count`: 36
- `sha256`: 9d963f92947816ee66e005ec0ba796f6a66f5aefb73519251394dafe422d901a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3663 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build-t3v-final-module-v1/tb_ooo_fp_issue_queue.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: f7fe9aa758b3556dffc97ba13f69f6fdd610e883428c764d255143dc220625a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build-t3v-final-module-v1/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1426
- `line_count`: 13
- `sha256`: 455efde998b03a7b2f27749336ddfb6710ce749d5e88557724080e03b6146037
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1426 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build-t3v-final-module-v1/tb...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 589
- `line_count`: 5
- `sha256`: 97dd8d7ca83b9746c9e02e2585b56e94cae1614f178046c6f2eda9ebdc557b04
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=589 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build-t3v-final-module-v1/tb_ooo_fp_long_op_gate...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 996
- `line_count`: 12
- `sha256`: 73c4efe9bb8a5006f243be1e674eb4de71d19df6b8e48b96e0a52c959bc7bbd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=996 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build-t3v-final-module-v1/tb_ooo_fp_phys_reg_f...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 743
- `line_count`: 9
- `sha256`: 3aac45a021a49b29f493dc3ae509aadb6e925a173288c7c1a66d55dc0924f850
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=743 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build-t3v-final-module-v1/tb_ooo_fp_reg_file.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 36f2d264e1624c9534edd416f8a033bb79c921e155342f40210d9c199244c879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build-t3v-final-module-v1/tb_ooo_fp_sgnj_gate.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: 5eb851bb8ede9f2bfd68c6958ae29a2ef2fff809f429397fb192211320e84362
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build-t3v-final-module-v1/tb_ooo_free_list.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 489
- `line_count`: 5
- `sha256`: 3d63d7a0b05ec44941c73aaa1ee8c2485f161ff69199213f61cde13ea3d96bfe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=489 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build-t3v-final-module-v1/tb_ooo_front...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 897
- `line_count`: 10
- `sha256`: 01372e5ebcff47866bf662d7a68b4c526e2122e0e26ff249c471fc3d9fb65266
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=897 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build-t3v-final-modu...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 7
- `sha256`: 06175da8b71d37ba35aec73636df8476958b081c83511cced71c278bd02163fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build-t3v-final-module-v1/tb_ooo_f...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: 88f3c54abaa3de7c860e03b5a0bc968cef6a2b4a8d81fabaab7a98c1321c610a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build-t3v-final-module-v1/tb_ooo_frontend_ru...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 2cb119c23db638133a21fc4a7425911f752e0d55ea0ce66597554e237fa48302
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build-t3v-final-module-v1/tb_ooo_fronten...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3527
- `line_count`: 32
- `sha256`: 9270b22148c75590513d645d6683daad29600b11ae22c2d1e296c21324c82a7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3527 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build-t3v-final-module-v1/tb_ooo_ifu...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12499
- `line_count`: 88
- `sha256`: 8b8ff706d982fe2d21f27300e9ae99c72f191eb12f79b87279db03c6c3cb5550
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12499 bytes; lines=88; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build-t3v-final-module-v1/tb_ooo_int_backend.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7536
- `line_count`: 63
- `sha256`: 45d8a828b978430d8e3ef5b27cb436997ef6eb036ab9e75792fa468ef5854e7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7536 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build-t3v-final-module-v1/tb_ooo_int_issue_queue...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52143
- `line_count`: 392
- `sha256`: 9dd46f5294752d93e16e8bdcfd525f2e2e937a824294f309aec4fc1991ceacbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52143 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build-t3v-final-module-v1/tb_ooo_mem_axi_bridge.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 941
- `line_count`: 8
- `sha256`: 593118861c185b6d56224ec4a0cd7120ab2d7d0628b1925004251f68f8f59c87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=941 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build-t3v-final-module-v1/tb_ooo_memory_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 6912b2d2c684b124864afe24188aa67e20484890c30aafddcc1198aa086202f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build-t3v-final-module-v1/tb_ooo_muldiv_unit.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1081
- `line_count`: 11
- `sha256`: 6709d985da6cf455d40e0c8d3d34c26c3299a0bb7f2e6da94b65acfe290239f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1081 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build-t3v-final-module-v1/tb_o...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 523
- `line_count`: 5
- `sha256`: f8996ad7410f720b9c26966efdf24d71f3ce4c6de38dfa0a2b2d8a05fa68bf4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=523 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build-t3v-final-module-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 871
- `line_count`: 10
- `sha256`: 8bca56a6cf226e2c2101f32a66f5f47791fca41cef67ba42f4ef0547295df34b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=871 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build-t3v-final-module-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 847
- `line_count`: 9
- `sha256`: 2c96ccb251539cabf2ca6277003627f3dd7919fa4c0b18ee343a0af711c5ac3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=847 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build-t3v-final-module-v1/tb_o...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 716
- `line_count`: 6
- `sha256`: 7436d9dbe4632aed29c9720d44ceab49a7d9320866a6d12fbfd25cac69da2cb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=716 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build-t3v-final-module-v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 453
- `line_count`: 5
- `sha256`: 51cb35a5c85f6fa6cf4397ad2191920ee112dd7ad09472baef514f3bc011bfac
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=453 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build-t3v-final-module-v1/tb_ooo_phys_reg_file.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15745
- `line_count`: 68
- `sha256`: adea3fbcb7c1d1304b9e6ea3891ddbe30f1b24ae8e87c92f379be878ae3a4979
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15745 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build-t3v-final-module-v1/tb_ooo_priv_system.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 459
- `line_count`: 5
- `sha256`: ffc3d2e09b938af7385dda074277533ae94780d37b9c88ed62d58d886b383184
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=459 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build-t3v-final-module-v1/tb_ooo_ras_update_gate...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: 2f3a88ca34c4b858928a664a66b7644b5d2fdb1611223a7edb8d8ee9bb6207e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build-t3v-final-module-v1/tb_ooo_redirect_arbi...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: a915f269ac74269e929cdef80031b24d6069820003af375f4e68bca49445dba3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build-t3v-final-module-v1/tb_ooo_rename_map.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 729
- `line_count`: 8
- `sha256`: 3a311e8d6be78be568e7ceb106c7e122659c2f0d1ce348a6695cca8a0c8b11fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=729 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build-t3v-final-module-v1/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 829
- `line_count`: 9
- `sha256`: 03690484543562da43c8f731c19ff18d07e35dbc5149159c51e711ddeb139f1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=829 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build-t3v-final-module-v1/tb_ooo_s...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 962
- `line_count`: 9
- `sha256`: d6c2cfbfb92344069dee91b89345c1276076d5350a26c785fb496dbfb64bec96
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=962 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build-t3v-final-module-v1/tb_ooo_store_queue.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 154175
- `line_count`: 1102
- `sha256`: 54ea2f98b381c62c150eb90fdeb096dba71238652ada0935b6ca773af776f265
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=154175 bytes; lines=1102; PASS=2; tail=ing: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: 55dd5db01340a3120e5dc627c183d4f2f5a7c55ce96754b72d03dbb59684088f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build-t3v-final-module-v1/tb_ooo_trap_ex...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: e31bc28acff34d666a0bfcd9d7809f61b9f4b9aa48609089fa52acf41873828a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build-t3v-final-module-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 430
- `line_count`: 5
- `sha256`: 37222d983ff2db3bcc524b7e3c80bd8d2ac4f3cc759faea8790f6ba1397b17e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=430 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build-t3v-final-module-v1/tb_pipe_stage_reg.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17557
- `line_count`: 134
- `sha256`: 398f92ff3434170c14985a00795b892dfbd0b66e3da1c2e3e3e93d549b227d0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17557 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build-t3v-final-module-v1/tb_pmp_checker.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 368
- `line_count`: 5
- `sha256`: e9bc2ea4694621a755c2170ee541218bef6e0a39c4574d9e7a070937ac03119a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=368 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build-t3v-final-module-v1/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 366
- `line_count`: 5
- `sha256`: 9c9d2b3730b07a783ac87bcf92829ae9eb80f277f495bbd24a4740272e7ac630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=366 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build-t3v-final-module-v1/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1/summary.txt

- `kind`: txt
- `size_bytes`: 3226
- `line_count`: 106
- `sha256`: 4589afe4176e7b51819b2eb334273100b8ae0385df45125da61533971912be1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: txt evidence; size=3226 bytes; lines=106; PASS=194; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/final-module-v1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - P...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 883
- `line_count`: 9
- `sha256`: 0885b8867bb780d86f24df87dc02b68e08f357deff938dbda87e736834d5b89d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=883 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build-t3v-predecode-phys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15669
- `line_count`: 67
- `sha256`: 845d41dc026f2c0af22688ff554e0ef640ea625d1134dd1d0feb9d4421d9a986
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15669 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build-t3v-predecode-physical-cut-v1/tb_ooo_core_top_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 5
- `sha256`: 508b5af614411dc42ca6d7468e098b898e7db6c6061eb6e0df8009e41d2a6f5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build-t3v-predecode-physical-cut-v1/tb_ooo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: 33d060b8f008a58704d1b17d34cdeb53e589c6b253f459c0e1b8c28a51b32a6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=481 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build-t3v-predecode-physical-cut-v1/tb_ooo_f...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 87ee943fabe969ca72ed02488aa5afb310122a86227d50f29259893149066d8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build-t3v-predecode-physical-cut-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: 5e84c713f94ab512f3ab2930aae8f1704dee249166f66d7b9f4ea358faa6d233
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build-t3v-predecode-physical-cut-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 558
- `line_count`: 5
- `sha256`: 7373fa2f13fddd3b2b9626ae444b17da39df9663260666bcd5beee94c985a3be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=558 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build-t3v-predecod...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: 6888e3aad40a805ba4a0e1376a5ceb20c0f6646eac59ba62f36f455a8496f441
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=481 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build-t3v-predecode-physical-cut-v1/tb_ooo_f...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1/summary.txt

- `kind`: txt
- `size_bytes`: 546
- `line_count`: 17
- `sha256`: 3a1489dea5bc8e84c2e18acf67bbd7c710bf0f3951fe54733ddc4fef36fd0e3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 16}
- `summary`: txt evidence; size=546 bytes; lines=17; PASS=16; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/frontend-physical-cut-v1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_fetch_packet_fifo -...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 386
- `line_count`: 5
- `sha256`: 25da483990621c449fa93ef7f5f15a2480524a3d592dac7a24564ef3cb147ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=386 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_alu -o build-t3v-full-csrqh-v1/tb_alu.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: b3f263e89d60f54258057dae4b8f28a0102e9346f4432cd7ede6f0b19d570f85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=418 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_axi_clint -o build-t3v-full-csrqh-v1/tb_axi_clint.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3516
- `line_count`: 28
- `sha256`: 58e15c3100f91c9fcba88907f9c93d83d4c28a351fbefe8d5d1dac653e0c1016
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3516 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_axi_exec_firewall -o build-t3v-full-csrqh-v1/tb_ax...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: a066470d9ba0e8eae04177edec11570a71d2c5fd46b0d2762a82562191c43489
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_axi_plic -o build-t3v-full-csrqh-v1/tb_axi_plic.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: e306f0f1e0326f1f18e91317315501b3bbb10aaba8f2a9f661d18e07bb0026ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_axi_to_uart -o build-t3v-full-csrqh-v1/tb_axi_to_uart.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3295
- `line_count`: 28
- `sha256`: e8122eae174f11b3482f89233bb86037db6dbe8e33b346bc8a862dbdbdc7102a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3295 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_axi_xbar -o build-t3v-full-csrqh-v1/tb_axi_xbar.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: b65dcad9db46d14cba9f9e99703b70fe4f61d70e4bcefa6cf2619288d0dbef2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_compare -o build-t3v-full-csrqh-v1/tb_compare.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: 3e96c8ef9f0cada273bb911c16d1bb21f584c3583ea92bcda9cef609676f0e3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_csr_file -o build-t3v-full-csrqh-v1/tb_csr_file.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 557
- `line_count`: 5
- `sha256`: d5a09a9bac326df7c7d3e57afc74a499104b135d546b4cffd294cc7231ae3e97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=557 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_decode_stage -o build-t3v-full-csrqh-v1/tb_decode_stage...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 432
- `line_count`: 5
- `sha256`: 43e10aeda92ef1c0850be7506763ff257b7cca5baf90a334fb99c321036363f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=432 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_decode_unit -o build-t3v-full-csrqh-v1/tb_decode_unit.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 5
- `sha256`: d4b4eeebc13578b75cfa284bf3644d0204b455189a58d472433b4a67b33362cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=402 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_immgen -o build-t3v-full-csrqh-v1/tb_immgen.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 509
- `line_count`: 5
- `sha256`: 0b0049e0049fca72a9294154c07d3e308a5cda615a2cbdfec73037af77da6803
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=509 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_lsu -o build-t3v-full-csrqh-v1/tb_lsu.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: efa3b79a2db6d7e07079452c7777aa55314277c2b083de969e0ccf60d45adff0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_lsu_control -o build-t3v-full-csrqh-v1/tb_lsu_control.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: bde4bf3ef0d47e85995ad328fc420935bb270036ef16505b0afd62687f5f8d2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_lsu_datapath -o build-t3v-full-csrqh-v1/tb_lsu_datapath...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 589
- `line_count`: 6
- `sha256`: 8db521c0fc6f01d5701df106838e8a67502635573260e8c5c8259f2a018c1048
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=589 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_busy_table -o build-t3v-full-csrqh-v1/tb_ooo_busy...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 6bf944ff08cd323f507b1f000dbfbed6a63ce5cfdc9f472b92e2734ce4615b83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_clmul_unit -o build-t3v-full-csrqh-v1/tb_ooo_clmu...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 7146
- `line_count`: 50
- `sha256`: 401bfb160ff9772f9e1a71131542dc549acf4a50794d75ad973511a7fa7e8b08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7146 bytes; lines=50; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_dispatch_backend -o build-t3v-full-csrqh-v1...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3684
- `line_count`: 36
- `sha256`: 0f1d1dd09080f637090b87bdbb7be3160b00e337a87cf7e947313e9798a0259f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3684 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_fp_issue_queue -o build-t3v-full-csrqh-v1/tb_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1017
- `line_count`: 12
- `sha256`: d58f386728cd7dfb132f9d2fb5b9e12f67e66928f79e580be4fa39aab5ebd0a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1017 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_fp_phys_reg_file -o build-t3v-full-csrqh-v1...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 764
- `line_count`: 9
- `sha256`: ed07c4eb65cfcb42b69769af38d67ea55bb7e2a468a77d725e85455fc1114fc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=764 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_fp_reg_file -o build-t3v-full-csrqh-v1/tb_ooo_fp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: d7e849811590ee6bd612444270cbb40168b70921dbb14550b553cdc0a30fea23
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_free_list -o build-t3v-full-csrqh-v1/tb_ooo_free_l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 20171
- `line_count`: 194
- `sha256`: 866d679076a88ea96468703f22edeeaaf0c0566e4dcbaa867eb81c3dd6c5e172
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"FAIL": 216, "PASS": 2}
- `summary`: log evidence; size=20171 bytes; lines=194; FAIL=216; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_int_backend -o build-t3v-full-csrqh-v1/tb_ooo_in...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7557
- `line_count`: 63
- `sha256`: 24b54363b91936e92c671e6a7e440ba531f50461f84e2ac3520e3accdfab8db5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7557 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_int_issue_queue -o build-t3v-full-csrqh-v1/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: 09c53b27f58710a061c358a6fb6d274b6cbc937f8ee53f6bc5f236dcf41060fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_muldiv_unit -o build-t3v-full-csrqh-v1/tb_ooo_mu...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: 80af37c58171fa53ac0142942ba9ec280dc84f6c8e89961bc386f3ceac941ebf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_phys_reg_file -o build-t3v-full-csrqh-v1/tb_oo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: f68996f778608791eeaf07c4e4e066659f35bea95c86c1b916815ded5e3ea042
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_rename_map -o build-t3v-full-csrqh-v1/tb_ooo_rena...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 750
- `line_count`: 8
- `sha256`: 2e64f90e405b144bbd1483fac703920ab511a66b58c09863f4816c58bafc9c11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=750 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_rob -o build-t3v-full-csrqh-v1/tb_ooo_rob.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 983
- `line_count`: 9
- `sha256`: 9e04e1e2caa0c83478a81a58e96b7e7432cf586e7092a8a7b149ebcc7eb7dcc6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=983 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_ooo_store_queue -o build-t3v-full-csrqh-v1/tb_ooo_st...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 52850b9b2b3ae9375b4d3a592a8d5d17ac68a676a051317856566f59431f70a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_pipe_stage_reg -o build-t3v-full-csrqh-v1/tb_pipe_sta...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17578
- `line_count`: 134
- `sha256`: 6dd93da72ffcb62c4f2dda949e3ab628f0dfbb7a7dd43c164ab223aa94e43830
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17578 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_pmp_checker -o build-t3v-full-csrqh-v1/tb_pmp_checker.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: 780d8c1e5e6e0f6548997d5c8c9caddea13688fa3bf6efeb4318521ad04e7ffe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_uart -o build-t3v-full-csrqh-v1/tb_uart.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-csrqh-v1/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 387
- `line_count`: 5
- `sha256`: 45f8a17f753c814301ff048ec9281630c3ccec50ae343228ff789bd8e524217c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=387 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -s tb_wbu -o build-t3v-full-csrqh-v1/tb_wbu.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 357
- `line_count`: 5
- `sha256`: eacd2428df0e257b35dbea9efbd73b58c4b8b92159b2e843e9775ec2d576405c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=357 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build-t3v-full-v1/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/A...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: 5ed532be7b33522020f0182ef136ea70a4724616e86bb9b6135de119f7bc55d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build-t3v-full-v1/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3487
- `line_count`: 28
- `sha256`: 380b70dc8ccb9516b46c2e8b6f1d3fae81db0b830b54581618a82f377889c4b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3487 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build-t3v-full-v1/tb_axi_exec_firewall.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 383
- `line_count`: 5
- `sha256`: 8e2e7bf332654112d064c7f7d7f1e2b85de734d9390fc9fd645618da702643e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=383 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build-t3v-full-v1/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 453
- `line_count`: 5
- `sha256`: 8066453fd000a15cbecba8c6548bcc87e1088c3d5eed9f1c4244f8cf40e25acc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=453 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build-t3v-full-v1/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3266
- `line_count`: 28
- `sha256`: d8ec5ab56000521732efaadc1f2d452470915755e705b0585acfc67d606002c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3266 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build-t3v-full-v1/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 5
- `sha256`: a97a433bcbd2608a5ffce81c439c88cbfbd8769d3da829273d620ccc5df5a6b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=384 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build-t3v-full-v1/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 5
- `sha256`: fbff3fd2126281438bb048fad8bf56ba5c9dbc441de17cd420762960c0e93034
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=384 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build-t3v-full-v1/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: a9ba9d867aacc588fc366e5f9cd63c9dcc1ca472505f23810af8f628e0a2816d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build-t3v-full-v1/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 403
- `line_count`: 5
- `sha256`: f7f0cdfe1e8fd8b6108f3266b5684a65f0472ca5e690dc08829e8288fb1d607e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=403 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build-t3v-full-v1/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 0b8b44b122d2a7c60ecacba3b6ce8f0c645f80c5c255eedc8604b193d969a45b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build-t3v-full-v1/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: 69d43bb16dcb10569578e643d9167063c8145505f17b27ef8cbffeb8a5b3aeb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build-t3v-full-v1/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LS...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 402
- `line_count`: 5
- `sha256`: 9a632a8edd3c57bc7aaf708cfb7c88dfa84f224d6f5bc2d23446f13b7a052651
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=402 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build-t3v-full-v1/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 408
- `line_count`: 5
- `sha256`: 4a7898438823c9dfb94d3d9a16e0b8d47f29cd0ce81c134bc70beb5628863fae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=408 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build-t3v-full-v1/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13022
- `line_count`: 78
- `sha256`: 985987e56dd6adfe9c6f0080789cf09dcf81f8e23c209b7764561c1ef05b567a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13022 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build-t3v-full-v1/tb_ooo_alu_core_slice.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 12698
- `line_count`: 76
- `sha256`: d0141bf1ee4e7fc61237882bb49ebfd3e3dce19aeb1f28e78a17986101cd111f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12698 bytes; lines=76; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build-t3v-full-v1/tb_ooo_alu_decode_backen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 408
- `line_count`: 5
- `sha256`: edce6d82e53cc46a16da59bcab71b9304c049af0f608a1ac33cb731ef1274af3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=408 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build-t3v-full-v1/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 5
- `sha256`: a1859fe16855f062f1af783314f2715f7562eb2ba3b33a4d8167b6240e2548de
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build-t3v-full-v1/tb_ooo_backend_dra...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: a68f2b2afc2c4745c61ed8ad267997caef79a4fcf6d2dac3bf9787a39a3df8e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build-t3v-full-v1/tb_ooo_bitmanip_gate.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 865
- `line_count`: 9
- `sha256`: 839d042c5742cff1fa4e3139f6195978e4672f47bba49071d5848564e1e2ea0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=865 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build-t3v-full-v1/tb_ooo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 820
- `line_count`: 9
- `sha256`: 02013a6e84367a88ba57f42e27d0a278c18d99391e3a4e69624d69d8bf406983
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=820 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build-t3v-full-v1/tb_ooo_branch_bp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 603
- `line_count`: 5
- `sha256`: 2104991acba7e6f2425bede534d441a6d34d9a0355a984b8e1086a9d1c9a6bc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=603 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build-t3v-full-v1/tb_ooo_b...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 875
- `line_count`: 9
- `sha256`: c77d085c3f369ff057204debc72e90417485355b19654554e0aa8a24c988b5b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=875 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build-t3v-full-v1/tb_o...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: 989d2bded57ffd26bbe5cf75a047bd33b06b866479133067ac059752d846d0b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build-t3v-full-v1/tb_ooo_branch_spec_tra...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 6
- `sha256`: b148d7e6b3483b8ace07529b0c991bdd06f436377f15a03818b3f206ca5869cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=560 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build-t3v-full-v1/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 422
- `line_count`: 5
- `sha256`: ff1b7dcfbeb7f55986204a139c778a912e74ed2344471a0496e55b128c61d40c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=422 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-t3v-full-v1/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 778
- `line_count`: 9
- `sha256`: e1dc3e3446c5029d10ceb9dc74393e89618592c3c0428c22b9f223706ecd7cea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=778 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build-t3v-full-v1/tb_ooo_commit_output_mux.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 843
- `line_count`: 9
- `sha256`: 8ecda3c7c984cd433215454d2baed111822b632c8d5cee38b33f5f7dba50f8e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=843 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build-t3v-full-v1/tb_ooo_contr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 830
- `line_count`: 9
- `sha256`: ef525708045d18b7b343ce2e1da825ba46afdefe7f16cb1619a81998641b3647
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=830 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build-t3v-full-v1/tb_ooo_control...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15651
- `line_count`: 67
- `sha256`: 97958667828b251e2a7b8dd2cc615c37ccb13ab466a40d80d5a24010f0777347
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15651 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build-t3v-full-v1/tb_ooo_core_top_glue.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 508
- `line_count`: 5
- `sha256`: 44d992096c5952562f8592d640112c6bb5e2af974438a6e8177a4912537bd12b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=508 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build-t3v-full-v1/tb_ooo_csr_acces...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: 43898e53f3ea11fa2f4c09bf0128a2274a9ee18b105442a4f57b53553516c2a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build-t3v-full-v1/tb_ooo_csr_trap_requ...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 586
- `line_count`: 5
- `sha256`: 58059a447656ec4c3e59af7880e1e53b6029152ff01dc7ad80a73e89c0a08816
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=586 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build-t3v-full-v1/tb_ooo_data_word_cache.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: 4de2760adf234c6ba96890b73138363d84b60217c3696e1c4ea163be0658d1df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build-t3v-full-v1/tb_ooo_d...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 510
- `line_count`: 5
- `sha256`: e1bacdfd8e5bb0ac5d0098c3cf6148b9f0d2b1d1cfbcf19b01fcce873a5a75e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=510 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build-t3v-full-v1/tb_ooo_dir...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 510
- `line_count`: 5
- `sha256`: 41c09742b84536fe2e008ec61a295b806c846e3d679f59c54904c30d6a6164ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=510 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build-t3v-full-v1/tb_ooo_dir...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 7117
- `line_count`: 50
- `sha256`: 6de2e24303b810c91c0acccdf5f953ed4b06d213cfc0d12f63cb17380d788fc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7117 bytes; lines=50; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build-t3v-full-v1/tb_ooo_dispatch_backend.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89731
- `line_count`: 717
- `sha256`: 246a3e09ade83dd21843ce3aac1cdd82fb74f97cd3b5e00042077dbb5f14463e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89731 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86474
- `line_count`: 650
- `sha256`: 7da0ed4474a6c94cf3530f965ab408cef41245bd208eb45ca225ae276488c8bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86474 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86445
- `line_count`: 650
- `sha256`: ef63e9816085a9ec0a2875c40b1189d86fec7fdc7b8ee8bcf5e94b15f7053744
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86445 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89409
- `line_count`: 673
- `sha256`: dc274575b387083ce013204e7d4d0cee609840081afdee45a0e8b024bc3bbd11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89409 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 477
- `line_count`: 5
- `sha256`: 8cd69bea55bdcd801b9383009efee1803d427d707f019fc7cd80c02bd9dfe095
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=477 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build-t3v-full-v1/tb_ooo_fetch_branch_ta...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 81674d04c645c1e21b51722e761cffc8f2ac8494e05efe49a70e17d7ba069ebc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build-t3v-full-v1/tb_ooo_fetch_flow_contro...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 567
- `line_count`: 5
- `sha256`: b857cb93649b3686c625d5cc34e73a57273eae5836a2ad3bceaa946c29aa8a93
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=567 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build-t3v-full-v1/tb_ooo_fetch...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 621
- `line_count`: 5
- `sha256`: 8d1be641cd721a3ca29e56bb32f1ccadbe4228378808c9c0dd5a8e5ae541b41e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=621 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build-t3v-full-v1/tb_ooo_fetch_head_pa...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 5
- `sha256`: 37c083b6131cdc7b28d715c6ec98bb02453a86e00dd41f2ad6f53afebc51b69a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=606 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build-t3v-full-v1/tb_ooo_fetch_packet_cach...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: e4757cf56c0be454cc30a5c576872198c15db3e40518e6bab64e5307b335e5f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build-t3v-full-v1/tb_ooo_fetch_packet_de...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 7c5bee4a9ea93468ea596fcae90ec0aef70dde52534450348022f33433d4575b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build-t3v-full-v1/tb_ooo_fetch_packet_fifo.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: 431b5d8fd4e82e0d03cb921fa80795f83addcc74fa5790b6476cb822aaedcba5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build-t3v-full-v1/tb_ooo_fetch_packe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 5
- `sha256`: f3e258335519304740cbca2a425a1eef10b70f4e83bb903571e9ceacf7b598cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build-t3v-full-v1/tb_ooo_fetch_packe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87810
- `line_count`: 664
- `sha256`: 7a689427713142b8204edd01003e05ce61ed76eefa7a7fc7dfd58900c1ee5216
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87810 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 540
- `line_count`: 5
- `sha256`: 3fe0ad3219234b9eaa7d68ba087e1430cfadc48fdc6bdc65345aafa4fa7348c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=540 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build-t3v-full-v1/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: bbf150c4395594031fdf57be543ca2eeac7a9158a2e3bdad38d296e9eecbe9b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build-t3v-full-v1/tb_ooo_fetch_request_mux.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 15661
- `line_count`: 67
- `sha256`: 41e54e463626a24255ea7d9a6253f8494c20dd3f68c618813bb5e7fa19196606
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15661 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build-t3v-full-v1/tb_ooo_fetch_trap_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: cf207c6d946f4c27426cda8ead62ce436c4f8a884db098276df67b0e36446daf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-t3v-full-v1/tb_ooo_fp_arith_gate.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 5
- `sha256`: 67fb0bd2e7b3fcca0f63c0ccc770d71cef0761f8449c2963f8ad15165d4853fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=456 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build-t3v-full-v1/tb_ooo_fp_classify_gate.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 5
- `sha256`: e99da968095cc82e679edbefd7a034b0a2fa185fee290d734a8d98b063537862
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build-t3v-full-v1/tb_ooo_fp_compare_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 41cc712dc17c5c4d63b08ba478847bf79d8f139aa9f3c82b5f539d561d6c5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build-t3v-full-v1/tb_ooo_fp_convert_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3655
- `line_count`: 36
- `sha256`: e3d5d85856326649294f2e9431c4bbf39b9e47619121924fb476bcf08eb3ec59
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3655 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build-t3v-full-v1/tb_ooo_fp_issue_queue.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: d0a34c5090462f823a0d964c83d2f11d562129dbda12b1d503f64b764f2f0202
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build-t3v-full-v1/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1418
- `line_count`: 13
- `sha256`: 1d23aed4fdfa35dad6e0ec1305316fcc002f7833c292271ff3413ce91f2583be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1418 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build-t3v-full-v1/tb_ooo_fp_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 581
- `line_count`: 5
- `sha256`: f613d1b097324d7bc57072be6b488ddcfb4e3299020dff947ab742459a406cb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=581 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build-t3v-full-v1/tb_ooo_fp_long_op_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 988
- `line_count`: 12
- `sha256`: 7d3974c52831ffbd4f4efd11bf0f46972c2127e216fefc1b8bc4ece2c35e880c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=988 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build-t3v-full-v1/tb_ooo_fp_phys_reg_file.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 735
- `line_count`: 9
- `sha256`: 3340d40d778d4a13ff4628d27944d72a4dd524a61093ef1536760d60a59c84c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=735 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build-t3v-full-v1/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: 49163378b0b2659ffab1bdcb868cc319cb9535a83821e32d88e8bec23436f62a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build-t3v-full-v1/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 423
- `line_count`: 5
- `sha256`: 8209d49bb417efbb8b64c274a70d267f92bc67d410f6a52b554f48b7e06ab35f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=423 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build-t3v-full-v1/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: 1e18f012dc23c1262ad1aecf7b9f0a77e5b6f707a0fa2a3fe189d7d1956a3fca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=481 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build-t3v-full-v1/tb_ooo_frontend_acti...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 889
- `line_count`: 10
- `sha256`: 5abe0ae1789d0bac9d92c8044ef1d4a1e17eaa651c5dc0c2dfdfd0a79babc92b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=889 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build-t3v-full-v1/tb...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 801
- `line_count`: 7
- `sha256`: 5d7fb7cae29e05e93072405b96377f06f0abd9f8d994a7fdc0d3dd6eee34ccea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=801 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build-t3v-full-v1/tb_ooo_frontend_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: c343ea76a659a4b299fee32a32c2a09370dd2bde2f89e2f86ad1e71e68794cf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build-t3v-full-v1/tb_ooo_frontend_run_gate.v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: 30528fb48549a577a7bf6270a841b50a20b4e1d20ea3bac95c3af6073a543cf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build-t3v-full-v1/tb_ooo_frontend_uop_sa...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3519
- `line_count`: 32
- `sha256`: eacec524ad3b1415b7e171823d69d2bdd302b5cbdaf6bae7b0d09101a48a74f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3519 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build-t3v-full-v1/tb_ooo_ifu_lane1_f...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12217
- `line_count`: 84
- `sha256`: 4a173198f09630d32bdd88335c0d369dac912310a36fe1ce27192b88d2bba262
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12217 bytes; lines=84; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build-t3v-full-v1/tb_ooo_int_backend.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7528
- `line_count`: 63
- `sha256`: 549b65fc17d5bce7c00be84c0ea58f0fe40d3cc0531a46d71a9841dd2316a169
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7528 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build-t3v-full-v1/tb_ooo_int_issue_queue.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52135
- `line_count`: 392
- `sha256`: ea76d3b9e08be6f71ac67b745543c42ccb1a962e9418ebbe84b85f448768821b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52135 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build-t3v-full-v1/tb_ooo_mem_axi_bridge.vvp /home/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 933
- `line_count`: 8
- `sha256`: 91ee2b49328308cda4ac456ec347d5f319657cdf4278899c0c417fe39eb91c2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=933 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build-t3v-full-v1/tb_ooo_memory_request_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 431
- `line_count`: 5
- `sha256`: 3365ba2d27994776aea0dec43417a43e2dcff2c7111dd58d4631be9ac1729d0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=431 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build-t3v-full-v1/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1073
- `line_count`: 11
- `sha256`: dc7f650f54f9f7089e1a77f82989b3f44b9de1ef5a823ece9acd6713b155ba23
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1073 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build-t3v-full-v1/tb_ooo_pendi...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 515
- `line_count`: 5
- `sha256`: 447212ff60c9f2794172509db5bf369017016f82426f20db6d9f55cb89fa9b9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=515 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build-t3v-full-v1/tb_ooo_p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 10
- `sha256`: 3cb62c2030a38f6f8f054dd7850cbfa7bc5e991d87bcb4d00f55d140e0b8fafd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build-t3v-full-v1/tb_ooo_p...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 839
- `line_count`: 9
- `sha256`: 370550e3200209c514411e95421c41d53d328a7b4610bdda86c2b20a361c3502
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=839 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build-t3v-full-v1/tb_ooo_pendi...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 708
- `line_count`: 6
- `sha256`: 168b356a2b7cf55158ebffb82118920a0490a0ac69914d10ea2c02414e9fd02f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=708 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build-t3v-full-v1/tb_ooo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: 16dec2d41bb6de5437d98a48a50fe505b67607c733b677921b6db36295668149
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build-t3v-full-v1/tb_ooo_phys_reg_file.vvp /home/lyg...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15737
- `line_count`: 68
- `sha256`: 079428f21548910b7c36f912676b40d956d750c6170412df16db3607630f7b7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15737 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build-t3v-full-v1/tb_ooo_priv_system.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 76fdf12ab6e7b99e42f469b49b4ea7b146415d46f3a8017230945932ec4d9352
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build-t3v-full-v1/tb_ooo_ras_update_gate.vvp /ho...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: fee0d7609fbc3a05ae60ea7656d947dcfc4c755a55e303189445460a4a00f2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build-t3v-full-v1/tb_ooo_redirect_arbiter.vvp...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 429
- `line_count`: 5
- `sha256`: a1d8697f97786d778d7f44f820a3e8c4b6828b74e6aadadd1c89a61d5a3b8551
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=429 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build-t3v-full-v1/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 721
- `line_count`: 8
- `sha256`: bec551464898daf8ad00d91c4917769359b036c0ca11b41776a2fdff8a3b3aab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=721 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build-t3v-full-v1/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 821
- `line_count`: 9
- `sha256`: 219628508e56905ace102d8c4d414bf877b431ee01ab7c4e5f764fc9ce0b9443
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=821 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build-t3v-full-v1/tb_ooo_stop_pend...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 954
- `line_count`: 9
- `sha256`: 0282f40af2b0696d58a278c6f97c15bad1b5503e7e4a6304df9d2bf4313f0020
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=954 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build-t3v-full-v1/tb_ooo_store_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 154167
- `line_count`: 1102
- `sha256`: 77ced904beb25cbadee8bf99a5eb649c7ad810454e9d59ada7c135492e7d456d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=154167 bytes; lines=1102; PASS=2; tail=ing: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 5
- `sha256`: e084e9b16dcc3760660d1b51a1f632d302896cb6ab3b146eb94e77856f638743
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build-t3v-full-v1/tb_ooo_trap_exit_event...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 536
- `line_count`: 5
- `sha256`: 54b383001c111583c8bc1df4a967fff984018953e68a474c91403ba8b42ab6c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=536 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build-t3v-full-v1/tb_ooo_t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 422
- `line_count`: 5
- `sha256`: bfed50091637e3f8c591291776caa3096ceb0edc93ea70aa16fe5b24d381453e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=422 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build-t3v-full-v1/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17549
- `line_count`: 134
- `sha256`: bda2fdd787dbb33c26db73fed78a3a368dac62a84948bf0a60feceff48f1e82d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17549 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build-t3v-full-v1/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 360
- `line_count`: 5
- `sha256`: 22058b4f54c48785bed0688b63603b59570e5ae9676d24c036a15be5f6d9215b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=360 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build-t3v-full-v1/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ua...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 358
- `line_count`: 5
- `sha256`: 25a45a0fe516a05d1683d3ee192da3d5e2839b40fcc8f3caefb1c142b1b0b20b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=358 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build-t3v-full-v1/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1/summary.txt

- `kind`: txt
- `size_bytes`: 3225
- `line_count`: 106
- `sha256`: d4085f1b0146cec685540120889faee65e2c2f90e2cd68cbe8c5c1a0d8827163
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: txt evidence; size=3225 bytes; lines=106; PASS=194; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/module-full-v1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PA...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/predecode-coherence-mutation-negative-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16242
- `line_count`: 71
- `sha256`: aaef230d2d2c928a59d487ab6f31a60b11205d5f25fa52303b0b83cca7367230
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=16242 bytes; lines=71; FAIL=2; ERROR=4; PASS=2; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/tmp/2026-07-14-rv64-t3v-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/predecode-coherence-mutation-negative-v1/make-console.log

- `kind`: log
- `size_bytes`: 351
- `line_count`: 3
- `sha256`: e72df7fa61987104cb5bebfd46e05b608b0748ce7757c454bd67a64155a088f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=351 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:264: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/predecode-coherence-mutation-negative-v1/logs/tb_ooo_core_t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/predecode-coherence-mutation-negative-v1/mutation.diff

- `kind`: diff
- `size_bytes`: 651
- `line_count`: 11
- `sha256`: 893f53c22871b3d38f7830382cf1569a866c02a08a5826d3f26ee14319e83e83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: diff evidence; size=651 bytes; lines=11; markers=<none>; tail=--- /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFrontend.v 2026-07-14 07:12:03.488851793 +0800 +++ /home/lyg/PA/ysyx-workbench/tmp/2026-07-14-rv64-t3v-predecode-mem-dataplane/predecode-coherence-mutation-negative-v1/OooFrontend.mutated.v 2026-07-1...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/predecode-coherence-mutation-negative-v1/summary.txt

- `kind`: txt
- `size_bytes`: 472
- `line_count`: 10
- `sha256`: 0081ee9489efdac193f289a58d313c4f2a52c6c9fce92944444b175a1410b403
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=472 bytes; lines=10; PASS=2; tail=PASS predecode_coherence_mutation_negative timestamp=2026-07-14T07:20:19+08:00 head=31e90c679050a3a9138c967151b240f0fa2ab158 mutation=lane1_fault_flips_stored_lane0_rd_lsb formal_rtl_modified=no make_rc=2 assertion_signature_count=1 source_sha256=03af0e7ba2...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: a5f17e6eb2fad5b206dd8440f20ef026d5fa25daf1705c4473c682cc764d6b6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build-t3v-prefreeze-v1/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/exec...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 394
- `line_count`: 5
- `sha256`: 29c15f8e1734f0cf80c45c49cb619850adca6edbe7af73cb520c1dcf819c1d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=394 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build-t3v-prefreeze-v1/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3492
- `line_count`: 28
- `sha256`: 0990a46304fdc5c89974810bf276971d3d95ce563ee35c4b5bb82980a35513cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3492 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build-t3v-prefreeze-v1/tb_axi_exec_firewall.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: 75a22bb588bd14331be06ee0664ecea1d661476a62b5f257cea3c8024343a029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build-t3v-prefreeze-v1/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: 1d5872a69db4c2fea9254354b6590b98bca7d5dc064ee963c530eb73784bbb4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build-t3v-prefreeze-v1/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3271
- `line_count`: 28
- `sha256`: 5009c3ebd5a26dd7f4407b4ef098972cc140c52eb7de16f224975c6552bc4786
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3271 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build-t3v-prefreeze-v1/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: bbc0cd8b51895017737a3197201e27513f1ac8671493b899c0ecdcc9263de2e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build-t3v-prefreeze-v1/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 389
- `line_count`: 5
- `sha256`: a686170d39a39b34fa40a5da01acd50db739b5ada1d3ecda5288e5ace187760f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=389 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build-t3v-prefreeze-v1/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 533
- `line_count`: 5
- `sha256`: 07e55d5d12cec4bf083d7ab0d53547f5504e89501d57d9d8c52113107842e124
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=533 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build-t3v-prefreeze-v1/tb_decode_stage.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 408
- `line_count`: 5
- `sha256`: 2e2d4b70ebb6bfd62a2c1e69f324f653399db24f5258cfdb60068fa93c176cbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=408 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build-t3v-prefreeze-v1/tb_decode_unit.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 378
- `line_count`: 5
- `sha256`: a3917f619aff1c9d5d9fde2cd1db195e6c56cc76b31b90700b37b0b9d5047a18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=378 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build-t3v-prefreeze-v1/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: 4b3ee180dc5ef522ac632ee1a019c1920a23c0fa7fd15495f8af6f3d1faaff23
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build-t3v-prefreeze-v1/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 407
- `line_count`: 5
- `sha256`: 9a6842620b1c8440f319462bdfba46d9c62b0629ee7a48f1b79aced2a95a692d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=407 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build-t3v-prefreeze-v1/tb_lsu_control.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: d1e244d4e681d54feeb964830495ec4d51784d510f805c66d4f0be00c808be0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build-t3v-prefreeze-v1/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13027
- `line_count`: 78
- `sha256`: 1ebdc33b1529c66f0bd4777ffb1865ddf7a56bd84ccce7159513a7b7ca995367
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13027 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build-t3v-prefreeze-v1/tb_ooo_alu_core_slice.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 12703
- `line_count`: 76
- `sha256`: df81145e31e81d3a844ef502c04b3072bd95a82c859c563d5d9926572a88267f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12703 bytes; lines=76; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build-t3v-prefreeze-v1/tb_ooo_alu_decode_b...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 413
- `line_count`: 5
- `sha256`: 555be023110f7ae433bc5309ca86b6cfa42038077b880ab68bfa0087e7e0c891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=413 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build-t3v-prefreeze-v1/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-w...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: b6b60a9b411e82fe1c42124697759034efc2f0d8eb9d3cc58a786ad41b478b2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build-t3v-prefreeze-v1/tb_ooo_backen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 443
- `line_count`: 5
- `sha256`: fb6e206716eee0bf7a384a8c0dbc98996bb45aa4748fea99013433ba955239c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=443 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build-t3v-prefreeze-v1/tb_ooo_bitmanip_gate.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 870
- `line_count`: 9
- `sha256`: 87f645ba75f0c9621d1d2c67bacd572e712f7fab890464fbef2ee67f2ace73dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=870 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build-t3v-prefreeze-v1/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 825
- `line_count`: 9
- `sha256`: 910a8f52b1568692bd964084bd5f159ee62741e7a0c2d2372e6a2a8b867109a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=825 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build-t3v-prefreeze-v1/tb_ooo_bran...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 608
- `line_count`: 5
- `sha256`: fe9584c1dd79a0b93b9b364d014c5035eb49b9b9fed8c140ff4ffd7d4a09a556
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=608 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build-t3v-prefreeze-v1/tb_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 880
- `line_count`: 9
- `sha256`: 5e0b31a0ec29d22529f6951de3b5f40208b59f86484f6d963bb8d56d077c5b10
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=880 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build-t3v-prefreeze-v1...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: c7dfbfd3255e59795dbab93bb7bdbc2c2c0c4adaef815bf2a038e90e3e6fc0ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build-t3v-prefreeze-v1/tb_ooo_branch_spe...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 565
- `line_count`: 6
- `sha256`: 51004a659ce0aee4e776231ad15c56d692789b1ed6b031cb9a9bc52732674da6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=565 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build-t3v-prefreeze-v1/tb_ooo_busy_table.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 64c51a07d3ecb8e50647b2e0e1bd0889d9e8a5cc5a14b4fb45b0e522cdddadcb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build-t3v-prefreeze-v1/tb_ooo_clmul_unit.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 783
- `line_count`: 9
- `sha256`: 7a2cb034c418df230a9922e1be72326a01a3c5954752aeeb51420cc21f0c1706
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=783 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build-t3v-prefreeze-v1/tb_ooo_commit_output_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 848
- `line_count`: 9
- `sha256`: 0075818e6869e86540777a5c37909218d92c17889baa9ca604a79fe21c098159
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=848 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build-t3v-prefreeze-v1/tb_ooo_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 835
- `line_count`: 9
- `sha256`: cfe1e20155e9c6bf266b771b0f6405c689d98ec5b2380a589cbf2471d2a9c10b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=835 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build-t3v-prefreeze-v1/tb_ooo_co...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 15656
- `line_count`: 67
- `sha256`: a7f5f8ffdd154bd500b6f7f0272699f3fc4c3ab06b23cc12fd601d7a81d0b3b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15656 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build-t3v-prefreeze-v1/tb_ooo_core_top_glue.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 513
- `line_count`: 5
- `sha256`: e31fa160109b95f3ef6e589d729834e0109cbacbcb22ee2a982ded8ada955139
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=513 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build-t3v-prefreeze-v1/tb_ooo_csr_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: 14fb5bb447253d595849739ef028d71c1d91398aa6bc4a52f7ee3cf319ec19c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build-t3v-prefreeze-v1/tb_ooo_csr_trap...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: dd114c89fdde2792a1b2a25c5e3cee1accc348d43bfdf64193234faef8619427
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build-t3v-prefreeze-v1/tb_ooo_data_word_cache.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 5
- `sha256`: e6201f03ff0f7e101b5e8d1f48cba5408a3f64744b556399076a748e2161bdc4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=521 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build-t3v-prefreeze-v1/tb_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 515
- `line_count`: 5
- `sha256`: ba6dc33a0e931ee0f4dc1af2214fa1fe9cae551dfbd9120ed2d83cd769454c22
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=515 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build-t3v-prefreeze-v1/tb_oo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 515
- `line_count`: 5
- `sha256`: 055b213f8de8076e7f5714371308a57da37dfac41e7bf76be0c7544db4b1eb81
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=515 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build-t3v-prefreeze-v1/tb_oo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 7122
- `line_count`: 50
- `sha256`: 8fddb8f42eb5cbd257f408fef3e1a07a272af35bf77d15ee102848b80e1f2d45
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7122 bytes; lines=50; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build-t3v-prefreeze-v1/tb_ooo_dispatch_backend...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89736
- `line_count`: 717
- `sha256`: 0148f1b853e773e53c23dffe6f3c49a911d4d6405ff18d88ef1a104750f3e4e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89736 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86479
- `line_count`: 650
- `sha256`: bb05dbb0ff9a255420f7d90f6a6bca19be7c09cf86d2ae819fdfd0483e614e45
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86479 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86450
- `line_count`: 650
- `sha256`: b792970c1ded41f73adc82ad499839113c110844cfc29331a0cdeb096d73f27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86450 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89414
- `line_count`: 673
- `sha256`: 9be69480df0567d67bb586b37b62693d67031d5b9e71c13aea289e78653dca87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89414 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: 1779ef07d68df38d6893988b4d7e574a19efd4a4da1cd7dd5ba9c358a8dfe51a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build-t3v-prefreeze-v1/tb_ooo_fetch_bran...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: dbdbf202511bcfbfa6390d780fc6b5a7d6ade47f0f2e71250c754b879122bcf8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build-t3v-prefreeze-v1/tb_ooo_fetch_flow_c...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 572
- `line_count`: 5
- `sha256`: 69e9a968842a72c9c5a65496a9fdfe63b736931f68fd78f101b8a6901c65a733
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=572 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build-t3v-prefreeze-v1/tb_ooo_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 5
- `sha256`: 5360f5f39b0e26cdfb6300613f5300dbac04fb481247b36c675d432e101428f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=626 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build-t3v-prefreeze-v1/tb_ooo_fetch_he...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 611
- `line_count`: 5
- `sha256`: 790c3e8c8f1dea46e5917d86b7231ef1a4d26f752515f030a780eb5a9f08ac4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=611 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build-t3v-prefreeze-v1/tb_ooo_fetch_packet...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: 2fd0195ce26ea63def81e839ef602f4e594e345dbbf6bdfa5fc266cc5d6124f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build-t3v-prefreeze-v1/tb_ooo_fetch_pack...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 85f744f78e3fb956e7408283cf404b15b8002be3df46d5a32f499b80a7bb752b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build-t3v-prefreeze-v1/tb_ooo_fetch_packet_f...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 490
- `line_count`: 5
- `sha256`: 28f5677bae37bd5788266ac344f301848688887c32e3cf5b481c385058102ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=490 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build-t3v-prefreeze-v1/tb_ooo_fetch_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: 1a149b03b1dbdd6ee85612e4ca213c7cafd0610a99faa8ab4aa20e5b988aa063
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build-t3v-prefreeze-v1/tb_ooo_fetch_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87815
- `line_count`: 664
- `sha256`: 452f6f526fef8e3f5f62c5f6e52b603f8f2154a8f43bf805368d6a08087a989a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87815 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 8301f84f34b91961baf36c2bc343c2c90278af5cb81177dcb9a31938b0375382
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build-t3v-prefreez...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 346c077ba6aae459826999de048af4b8d8db4fad58d15335f570183347289832
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build-t3v-prefreeze-v1/tb_ooo_fetch_request_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 15666
- `line_count`: 67
- `sha256`: 5203c1372ec41667fa41a08b113ec183117d9c15bf704f2ee116d0524a3954ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15666 bytes; lines=67; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build-t3v-prefreeze-v1/tb_ooo_fetch_trap_gate.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: e486d2f9b305871ebb3bc65610ff8eceeca9539716b4c99f5c20d8af36b9e220
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build-t3v-prefreeze-v1/tb_ooo_fp_arith_gate.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 461
- `line_count`: 5
- `sha256`: 70a95b4c9fcd5e3a769aa78bd38d2c887c394bf5c3da0c3b8b5faf6291ea151b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=461 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build-t3v-prefreeze-v1/tb_ooo_fp_classify_gate...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: d08d32905580301ea5f5df4bc89ff173c06fcf42f0a6488c231116cf6cb977d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build-t3v-prefreeze-v1/tb_ooo_fp_compare_gate.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: b64a1638a36b4f4a9536206eb304ab12c47451f67e4d21df28a7849f9db86c78
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build-t3v-prefreeze-v1/tb_ooo_fp_convert_gate.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3660
- `line_count`: 36
- `sha256`: bd96931302846e997fe1866f90fde52d7fec72c46e833c8317d687edd60bb20a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3660 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build-t3v-prefreeze-v1/tb_ooo_fp_issue_queue.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 1e26766d974128c2896e5345859f5e6fdc15174e728a35da051ac01c1c605a81
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build-t3v-prefreeze-v1/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1423
- `line_count`: 13
- `sha256`: 231fbcb13b15b29e753e031dbe83d8fa5d9d5d251403f8f24015acbfacd0e6a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1423 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build-t3v-prefreeze-v1/tb_oo...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 586
- `line_count`: 5
- `sha256`: 44cc34d9be93d899d31edbb80e09fc70cdb9a0d856d57bf81f1312426e75764c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=586 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build-t3v-prefreeze-v1/tb_ooo_fp_long_op_gate.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 993
- `line_count`: 12
- `sha256`: d21e59caff6ce790104dde9cb8edfc33d5ccdd59420542f0c61d26636ec2408a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=993 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build-t3v-prefreeze-v1/tb_ooo_fp_phys_reg_file...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 740
- `line_count`: 9
- `sha256`: c021c3b71ce61d75180774284d13b3fdafad54815e81116630c6acfd3203104f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=740 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build-t3v-prefreeze-v1/tb_ooo_fp_reg_file.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 436
- `line_count`: 5
- `sha256`: 296f3b01db2202578b846134b2e5eccc69a9eb799c85845e8f3d7afda2da35be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=436 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build-t3v-prefreeze-v1/tb_ooo_fp_sgnj_gate.vvp /home/l...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 428
- `line_count`: 5
- `sha256`: ffa6e2fbb7ec24c7a8110f5e42e57efdbe0acfa1034d1aef64575fb526b4e4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=428 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build-t3v-prefreeze-v1/tb_ooo_free_list.vvp /home/lyg/PA/ysy...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 5
- `sha256`: d27ddae465ae4ab62c45b9500e47c2895994aa82324a280c66478ecee5fa4d8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build-t3v-prefreeze-v1/tb_ooo_frontend...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 894
- `line_count`: 10
- `sha256`: eb895892764268586d4dd7a5755c050e5b7fe8aa44a25b30de9d795d46e31cc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=894 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build-t3v-prefreeze-...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 806
- `line_count`: 7
- `sha256`: ff38b916317dd7678fab006058089d1629f61fe451f7c3429686d40956fefead
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=806 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build-t3v-prefreeze-v1/tb_ooo_fron...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 2dec21dff62381326b97207f427651419e9e2e7e5f425a99034fbcffb4be881d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build-t3v-prefreeze-v1/tb_ooo_frontend_run_g...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: e1f0dd674249fd321194fc0054d571157162136426e65d0364acafe18b4c3600
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build-t3v-prefreeze-v1/tb_ooo_frontend_u...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3524
- `line_count`: 32
- `sha256`: c9d0eb418e6397c6b2565643f2a32b3ca5c3b6f3b3a22aa9c4b83f4e6d58b99f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3524 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build-t3v-prefreeze-v1/tb_ooo_ifu_la...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12222
- `line_count`: 84
- `sha256`: 306a5195ffdde238729a170d84b789ac416a180f425a921c7298f1abf1f16f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12222 bytes; lines=84; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build-t3v-prefreeze-v1/tb_ooo_int_backend.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7533
- `line_count`: 63
- `sha256`: 126af7198d3bc897c61a8987c03e399a1394667f942a3815073df614ecacb19d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7533 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build-t3v-prefreeze-v1/tb_ooo_int_issue_queue.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52140
- `line_count`: 392
- `sha256`: 62dfaf676a180bf80afe0707b1efe844320f25c84b4af53107bacb7ae0ba7fc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52140 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build-t3v-prefreeze-v1/tb_ooo_mem_axi_bridge.vvp /...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 938
- `line_count`: 8
- `sha256`: ebff6e5356e2cbf39b5f1079524bb6e6100f90bbdf57bdaae11b99734f3fe441
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=938 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build-t3v-prefreeze-v1/tb_ooo_memory_req...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 436
- `line_count`: 5
- `sha256`: c5cf14ab8bf27951471a806c6f004eec0ce7b08efffb185fc60ffb989b889b5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=436 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build-t3v-prefreeze-v1/tb_ooo_muldiv_unit.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1078
- `line_count`: 11
- `sha256`: 1b426108f1f8a8a7b1749251649965f7bcab4b28f322c5fd19768ef3dd34b818
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1078 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build-t3v-prefreeze-v1/tb_ooo_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 5
- `sha256`: 910c9b809e9d9204fc87a95a66f5e106e251a16253cdbe535e2b447ae87dd769
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=520 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build-t3v-prefreeze-v1/tb_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 868
- `line_count`: 10
- `sha256`: e187b0c97dd3f834bbd44b89e09e15df4f3b63ff113e4e6679c9ad6f31d14ffd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=868 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build-t3v-prefreeze-v1/tb_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 844
- `line_count`: 9
- `sha256`: e7f571e222fecdb78bba8e3577654b3e83aed28cbcee595db5cf10bfc696304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=844 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build-t3v-prefreeze-v1/tb_ooo_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 713
- `line_count`: 6
- `sha256`: 4c3a3e3a4a6af3c404ac8ab889de94db7d9834bf0c97fa83ee654d852b244a7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=713 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build-t3v-prefreeze-v1/t...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 450
- `line_count`: 5
- `sha256`: 54808f3e6ca2b530582e901fb365ba45675180fa4b2d55ddfad4006594dc8bf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=450 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build-t3v-prefreeze-v1/tb_ooo_phys_reg_file.vvp /hom...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 15742
- `line_count`: 68
- `sha256`: 7f2b4686bbeae564d75e55d7220daa966b615c76ef0a9119eeec749400d8f5a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15742 bytes; lines=68; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build-t3v-prefreeze-v1/tb_ooo_priv_system.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 5
- `sha256`: f4df7feab0d3cdf8eb823ed13d685e49bff901c3609315c9e715424f2e6be009
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=456 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build-t3v-prefreeze-v1/tb_ooo_ras_update_gate.vv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: 614b001cc01e47031b9ad584f7b50122dd7377ad645197a0f5d889ab5b61b66d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build-t3v-prefreeze-v1/tb_ooo_redirect_arbiter...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 434
- `line_count`: 5
- `sha256`: e0f72641530e5a4f6f72fd5d4f9557dd873153357cd3b9ea06f03601847d9204
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=434 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build-t3v-prefreeze-v1/tb_ooo_rename_map.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 726
- `line_count`: 8
- `sha256`: 8f1fd10b7674c2e50e8735f5f91ba15eebe533196baf2730cdaf69e7540ffde7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=726 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build-t3v-prefreeze-v1/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 826
- `line_count`: 9
- `sha256`: 758751caaf5e49dcedb775115742d822e89947e6a086a769c23d2bbab8c8872a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=826 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build-t3v-prefreeze-v1/tb_ooo_stop...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 959
- `line_count`: 9
- `sha256`: 5dbabb9e971633126f8009d5036dba1944d0d84611b298eb9c084f08d54a6761
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=959 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build-t3v-prefreeze-v1/tb_ooo_store_queue.vvp /home/lyg/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 154172
- `line_count`: 1102
- `sha256`: b0f7cdda83e8601fa684ab23d769083727f81a03bb285c379109bce50d1e304b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=154172 bytes; lines=1102; PASS=2; tail=ing: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: faf810cc08438d8760a06136957e22589f08a57632e0285e2763d79369bc5db7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build-t3v-prefreeze-v1/tb_ooo_trap_exit_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 541
- `line_count`: 5
- `sha256`: fd0c0279be11e33fd74cc899b9a54f4d9ec9baa015afd10174d2ace4e4dc655f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=541 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build-t3v-prefreeze-v1/tb_...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: a4c0db56d5536960c8bcf33d3055c402cd67ccc9e67df7e531676b7a6a27295b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build-t3v-prefreeze-v1/tb_pipe_stage_reg.vvp /home/lyg/PA/...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17554
- `line_count`: 134
- `sha256`: 6121e95f056690c58a7173983d75c881669ab6fdbb9166ccad2669cbdfe5024f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17554 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build-t3v-prefreeze-v1/tb_pmp_checker.vvp /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 5
- `sha256`: 859c805e3724c62ef88b91c2ee6dff096871fe738f42279605c6dc13707b6acf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=365 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build-t3v-prefreeze-v1/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/b...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 5
- `sha256`: 74a227b8e996d956693873465f0248df53764254b0ead85d8126a6b6c924d4b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=363 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build-t3v-prefreeze-v1/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writ...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1/summary.txt

- `kind`: txt
- `size_bytes`: 3223
- `line_count`: 106
- `sha256`: 7475cd04e88bc852e15e3bec58174d1b030e167af0147a30e93cc57f8af56591
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 194}
- `summary`: txt evidence; size=3223 bytes; lines=106; PASS=194; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/prefreeze-v1 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PASS...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 4266899
- `line_count`: 109761
- `sha256`: 1efb57d8f7f68b1fc0cafaf62030461a3c2083c4d16a168cc1c9daf00114a426
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: vvp evidence; size=4266899 bytes; lines=109761; markers=<none>; tail=f6ab8acb0; %alloc S_0x5e4f6ab8b0f0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %co...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 725435
- `line_count`: 18590
- `sha256`: b44ed23dc94e50a44c549b4f13763aaaefeae3f096fd364ca81b25f965299ede
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: vvp evidence; size=725435 bytes; lines=18590; markers=<none>; tail=pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/v...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/context-brief.txt

- `kind`: txt
- `size_bytes`: 11805
- `line_count`: 195
- `sha256`: e0a9a3f7df7f8548f3ca07409558c0bc1d117d0bf4d07da99448faacf683ea02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 12}
- `summary`: txt evidence; size=11805 bytes; lines=195; PASS=12; tail=# Agent Brief - `source`: live-or-stored - `profile`: npc - `terms`: T3V memory reservation MIQ branch kill LR SC - `token_estimate`: 1967 / 2400 ## Profile Suggestions - `npc` score=18 matched=requested-profile, sc command=`scripts/agent-e2e.sh --profile n...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/contract.log

- `kind`: log
- `size_bytes`: 273
- `line_count`: 4
- `sha256`: 03b651fea961b7c2388e9c96dfb34a5bd009909ac27b27375650a872557e3282
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=273 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=129 基线=89 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 129≥89 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/module/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12591
- `line_count`: 88
- `sha256`: 7e6082c91ae6c9b307b38594fba21a2d019ed66b3513dcdd2f46b37e58a5cf7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12591 bytes; lines=88; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/module/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7628
- `line_count`: 63
- `sha256`: b0627fe8bb881ec890d5186179d5106fb6d3ebba2a243f8a75e7768da558c946
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7628 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/summary.txt

- `kind`: txt
- `size_bytes`: 2471
- `line_count`: 30
- `sha256`: 9a1cb69213c995bcb28e7da2d57acb39a0613c6ef0d353bf6042d94d017bdd79
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 10}
- `summary`: txt evidence; size=2471 bytes; lines=30; PASS=10; tail=T3V review-fix focused verification PASS command=.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/run-review-fixes-focused.sh build_dir=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fi...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 12591
- `line_count`: 88
- `sha256`: 7e6082c91ae6c9b307b38594fba21a2d019ed66b3513dcdd2f46b37e58a5cf7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=12591 bytes; lines=88; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-14...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7628
- `line_count`: 63
- `sha256`: b0627fe8bb881ec890d5186179d5106fb6d3ebba2a243f8a75e7768da558c946
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7628 bytes; lines=63; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/review-fixes/verilator-lint.log

- `kind`: log
- `size_bytes`: 8594
- `line_count`: 3
- `sha256`: a13af62b789ebe45f23277b8cfb64f41e33778cecb38995dc598439878edc226
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {}
- `summary`: log evidence; size=8594 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-14-rv64-t3v-predecode-mem-dataplane/evidence/seed-clear-equivalence.txt

- `kind`: txt
- `size_bytes`: 900
- `line_count`: 24
- `sha256`: f49a7de75c3a2348d33862130bea6f6dfd98208e13171c7962c65e8069b2b36f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T23:35:04+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=900 bytes; lines=24; PASS=2; tail=SeedMux clear-only constrained exhaustive equivalence ===================================================== timestamp: 2026-07-14T07:02:58+08:00 workspace: /home/lyg/PA/ysyx-workbench git_head: 31e90c679050a3a9138c967151b240f0fa2ab158 python: Python 3.12.3...
