# Evidence Index

## 基本信息

- `task_id`: 2026-07-13-rv64-t3j-fetch-read-window
- `task_slug`: `2026-07-13-rv64-t3j-fetch-read-window`
- `profile`: `npc-dev (separate completed profile run)`
- `asset_count`: 1176
- `total_size_bytes`: 52363195

## 证据资产

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359963
- `line_count`: 4549
- `sha256`: d169af1b92f58b6532d464383889543406d278978c738a500bd9f4b573eee155
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359963 bytes; lines=4549; GOOD_TRAP=21; tail=top branch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000070 miss=390 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000080 miss=10 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x800000c4 miss=2 [0m [1;34m[cpu-exec.cpp:1600 statistic]...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench.log

- `kind`: log
- `size_bytes`: 3400
- `line_count`: 107
- `sha256`: 9b8434160612236bc20f12a0b8ad444ead3a2bc6260a96e6dcaeac05f91aeea8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 192}
- `summary`: log evidence; size=3400 bytes; lines=107; PASS=192; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13976
- `line_count`: 85
- `sha256`: 0b3bb621155602db11a9f8fd3e10efc4541be8fe95467e8fdc5303d346a9fbb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13976 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 13652
- `line_count`: 83
- `sha256`: 1d7e00b8779766ad160a38c0bcd8a530b8e197e5067477ebe610d3a06532e882
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13652 bytes; lines=83; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: df346793b2fd8aae5df3e18e5eede8858ab4e62ccf1ff100cf64f037647301c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16520
- `line_count`: 74
- `sha256`: 7b66ae6da05cbe3146bab0990e7074dca337daf1027b7475f2c48b1c08b43273
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16520 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8345
- `line_count`: 59
- `sha256`: 5da3a0b5f63dc55d1d96b7af61b4e456b311f3c4aa99c861fa4e89d73db46509
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8345 bytes; lines=59; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: bed4bded9ff9da9ee63d99f1ca3ca507575d627b4c9c6755b36801f5ebbf2b47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 4ec29a1cdff0f80e3f77c08bb3de14dc7d8fe49e2bc8e4cad52de8c9d873663e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 3998893851256d56bbb1a769e031b67cfbfb4f3ce45425ffd04465e415c22a16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 16530
- `line_count`: 74
- `sha256`: 4d14671c2f26ab55f0afe0a800c7145a9350dd507c768f606384299449711399
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16530 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3643
- `line_count`: 36
- `sha256`: 5bf4803c5fcf60371aecd4e0ad40d7e343b1614934213355284d9ba378bafe7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3643 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 12
- `sha256`: 73cf2253470a50eb3504d7bb3d41a250402cc47a6799641ca8ec049bbdfcf358
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=976 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14770
- `line_count`: 99
- `sha256`: fe93a4158503da8239ee1e4c3007c9c691607a96e9939742c2061f96879b1b2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14770 bytes; lines=99; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7816
- `line_count`: 62
- `sha256`: 5cef0c5aa0999dcc250388822cb7e98e9ceb56eb2b387016c91cb18db2ca4154
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7816 bytes; lines=62; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: edece60c135f85ff7b0f7696ed98bb7a8aa49f5d1b17ada2804d9b137a97bbf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build/tb_ooo_pending_drain...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: 6e8b03051f6459e31cca0e186e2c3f11127fd8fb876bb0dfcb212767b79303b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 16506
- `line_count`: 74
- `sha256`: 8f54a03392b3a914a3a9b4d9e29ed2681fdd31b05b2d8c998fa7c099fc92a548
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16506 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155036
- `line_count`: 1109
- `sha256`: 13a15ee16582fa5bbd8c09de5a596634b680cf4cd2f9a38a7835c15ed37ad17e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155036 bytes; lines=1109; PASS=2; tail=ll 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensi...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 3253
- `line_count`: 105
- `sha256`: 128eed0a06076c368b0b78fc2bf76aab1e3e872f0977db91ad74d93841160942
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 192}
- `summary`: txt evidence; size=3253 bytes; lines=105; PASS=192; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s20260301-263...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/npc-build.log

- `kind`: log
- `size_bytes`: 48942
- `line_count`: 60
- `sha256`: a291dd6881cff4152fb6fcccae85025f94ffa85975c8e574abf246051a0f9c0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__"]}
- `summary`: log evidence; size=48942 bytes; lines=60; symbolic=__0__,__1__,__2__,__3__,__4__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-breakpoint.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 759bacf90a27050b888263f901fd5eb0ffa9c3e8b10d9c2c1add856d31c28392
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-csr.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 4
- `sha256`: 64ea22733c1c648d458ed72ca058e8e6cab07bf1bb3a405c30194b124d72ea43
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-illegal.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: fe618512fc09c6bec94ec603c2d4669b6f9225895d1018c00296d4ae648e9453
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-instret_overflow.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c7eb752ddf7df2836c15e057636b2b3b066bbe61020cfa1fcb7667044ba4fb74
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-ld-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 10
- `sha256`: c44e62773c367801944447046f471368c167a7b46cc18ff61e89ced9b1e10b45
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-lh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 0a625bdb1bde894e591b08910e9c522dae78cacf6f215057e5084ebb7215469f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-lw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 81a2d0f7543c87aab91ea4ba7f6df69cb54772b8b02fc1970baaa2dec4813138
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-ma_addr.bin

- `kind`: bin
- `size_bytes`: 8768
- `line_count`: 11
- `sha256`: 43aba4a5ed598e42eafa14d04575df2738a9dc1b2262e599788408accf523041
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8768 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% �s 0�" �...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 6
- `sha256`: 23128cb88a441f0ec5b0aa92e3ff235468a97a94e292d35d9092ba02c0cd6d75
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-mcsr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c8ab2c5fbb9cf529518ebf007812028ad1dc524efde5bf2edfaa20c2b8a3df6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-pmpaddr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5c82f4f85902b25a1496ffba37f4338b26a971da939e6921985125def9242a2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: fab026d76c46c8506cb94a08cb632f2de6937d8b057204464e3e2cdc019780e3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: eb468050871ee3c797254f90c6571b5dab04bb018834af2c69265c0274a165b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-sd-misaligned.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: 580363d39fef7b89f9e2e386be8a7e60ac3fd56c1df679ebe3ed5de107573e9e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-sh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3c3de98bcf0acee9619646b0ace0b28ce19cad50d97d6323aeb3e30866219c48
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-sw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: e0715db1e4a9e3efd1784bbde55edb741d3ae50f551315ce987e5434a5683aa4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64mi-p-zicntr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: aeadca97e007d646ed5565e489bf1a0b805cfa321e996930effd2ad4bab21159
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-csr.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 5
- `sha256`: 2f7d31a97b4a1a8836b5b16b048e42d6d3be2d02275a1bb9e4810b27575a72f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-dirty.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 302f824e3cbcf3b842793355d42fdc5011dfaed03e59cec2ab8d1b4831766a3f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-icache-alias.bin

- `kind`: bin
- `size_bytes`: 28848
- `line_count`: 4
- `sha256`: 4557a25ddcb7abec27c88269b480cb0d7ec7fa64305725d29d8d3c0a52f7dada
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=28848 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �r �� �s�R0sPDt�r ����s�R0sP �r �� �s�R0� ��R ����s� ;� � s� :sP@0�r �� �s�R0sP 0sP00� �r �� �s�R0 � c\ � � � � s �r ��B�c� s�R �� ��� s�"0sP 07% �s 0�r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 4f38f4a5a44b94c3317295c23666c5c5d6eb5d5aa6978b7de5509ec65f3ae17c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a27651d09a02b29a03a577555aa3571f8196280aa72cfd8baf0f3fd7b8778ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: 16442ae5360eef6283fa542a660128ff90f325c6385c4f14561403282e63b9d6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64si-p-wfi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00771ff518788f921c94a744180cc11a58d4c6867a7a28e02f20735727e41927
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 4150f7116a5d1ad9544d847f718a27dea539caa5cba32d9db43c0dd3a320cd58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 23ece6fcfa411fe3e9ac8aa2d73a60054e39446808a1551d3feb2c97cc438b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 23d3611c19094402928bdffe805fa8532d82fd77c90420ad9dcbbf546b86a250
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 4
- `sha256`: d235961f7c7c03e9da495ec9a846dad59fd750a8fd31c7bb767a01e623f0b31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=654 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 8474a0af82ef8d14cf5dbc04104d884ee96562d91ed90a22bc87d19350c99f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 6d07c6e4fe8c1fd8b3f44f7dce5500299893ea370f733c6c7e01c48e4b288072
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: e51c2a9f92c0506b9df3f6c48a301a8889b7ac5b3931ac4dcba1a9b2fc2721d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: d5963171dedae952ba273fd6c4b0ef70b6f28a179dafb069832f8f662f963179
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 99b16ce02f59f4a136bb747ddfd6f2348748038875ad51e6bb0192e691402068
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 62379170ad5bb6cc61c4b4dc0ff7e91a9fdde586f642c6ccaee4c80eeb1f3d62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 7b980a18a7a0c0f1265bd180a9ad1db93e8c6cab0d658640d820cb92a3eb9b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 9099de3acbff7f1453867efa55acba173e3f713d751107e9406a5e76a42fea3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cf030de16f0944357c4675d1bcd66e4c9ff80e240125f9290aadda6d928d2760
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: c4a66350fe2e3da52898d8665d719115bc88db0ef8aa4e2c93e8de5ed2e29de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: a22f5126c64613ddf6fd55ea6331fe76d4a0a0a982cbabc5cdd66da0ebc03e51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 237937babe46f052aa4697ccfa94dd5d62fe6e9c4f6ba2ed91df161b8bae8989
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3c5cb1679bbbbdb5587f3c2e0afb816204ec847dee3ec85268b44979b7dc56cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: c2afda182606f2e0a7e63e3474d5921c3aa8471978d516a44873e5c06b70a2ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 107d85d30c6e216d76cd6b59c73db64f75028be38ce1ee747124bff1d6ec90c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 1daaf37379469b4eaf41802fa680ed3c8c7bd6ce953df9c84d4915f239d4d641
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3b729d2c2d818c320db5ca4afe7a1f1348264eb2ffe0eba7ae1049417f20391c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3fb8dc5558e0ec98c7af988859a3cd3baca8da9aea3728df9d7cc85c7fd8bf77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 00b93d77799a70c2e3b84e597ee4c06a7fcea19dce219d84d8aee420edc53bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 8e0c3b0be49d00964fde252f04e3087506e0de98cceb587a5ab3066efb41ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 5334
- `line_count`: 63
- `sha256`: f1419bd80e05a61529c12736fd5187eae98150c078ce322556727dd4a4a820e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5334 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-breakpoint.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 5563
- `line_count`: 66
- `sha256`: 3707e1b7dfb38efb153c141b89660131b7d01a03b5127687b474a2e58410050e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5563 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 5719
- `line_count`: 68
- `sha256`: 380c5069856163115fe98b969c4f08c9ce148eb9e42cbf1b2e1156cc07cfdc02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5719 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-illegal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 5339
- `line_count`: 63
- `sha256`: f3edfe0d1c4b2b7b1911a72bea0e9f24d2d446ec91a23f273b0ecc0911bd7bb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5339 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-instret_overflow.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 5567
- `line_count`: 66
- `sha256`: 9024033de34d8f882f31e70f2fd55f852413d72917149f9b641330c847e955f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5567 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-ld-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 5338
- `line_count`: 63
- `sha256`: dd8669f485357cbd03d3e74cf745128bc2a64e646cc481a6b2770eb38dc67fe6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5338 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-lh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 5555
- `line_count`: 66
- `sha256`: 7bbfdb7911dcbec63300d8766215e5fed2ef500aafbb3a840c2e4f5b1e95adc4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5555 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-lw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 5505
- `line_count`: 65
- `sha256`: 805f4aa9d6e64c6e1bc43ec4baad431b5ee913362a11bfb8ef8d77cb61d83bdb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5505 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-ma_addr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5486
- `line_count`: 65
- `sha256`: 048e818e1634e7e7a29e58895d8631e2e92bad9d636b8f69ad35810040a7318a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5486 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 5400
- `line_count`: 64
- `sha256`: 027677aaf84f3d6590a1fef2950ecd88088686ad24e7ed6aab120f75e209885a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5400 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-mcsr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 5391
- `line_count`: 64
- `sha256`: be2d764e0667cba40df1d8e23721e2d063676c6dae1b04fbd5b8e9ea858ab267
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5391 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-pmpaddr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 5074
- `line_count`: 60
- `sha256`: 7137bcb85769fe161a9a8d7698d51f36f8c8a37ae79721655ddee62d9dd921b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5074 bytes; lines=60; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 5254
- `line_count`: 62
- `sha256`: 8c67d5f8add6759d15a72339db323ae0e2f59dbd1fad0e26e142f9088ad66793
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5254 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 5500
- `line_count`: 65
- `sha256`: b8389df6ac658a2bd67387460c81fadafdf5a807ad05da53977edda8294af9ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5500 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sd-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 5414
- `line_count`: 64
- `sha256`: 9a1b2d0ee53ab9287599cf56c47c57c2d61a20ddb6c8c3f6722d20c3bb047fb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5414 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 5422
- `line_count`: 64
- `sha256`: 03052bf77b0a2fd6da09804a8b41a7e0e1a8970997f92dfa24ae55858728371a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5422 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-sw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 5410
- `line_count`: 64
- `sha256`: 6a9a3b58e45dcf2276eb2235ba211c73bcc0878dc49c2f5c442705e2e69135a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5410 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64mi-p-zicntr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: 06317ce51f6b77a0e2ccd88cd483da7c98ada9d8ebc596943369634ffe88ce90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 5566
- `line_count`: 66
- `sha256`: f8a104bae881abcbf9793e89f60fc0d9707c8d19fd61bf2364a5ff7df8b2b449
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5566 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-dirty.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 5441
- `line_count`: 64
- `sha256`: 2242f31d8ee3b010b3e54a7ee7624aa1c45a467c347923a4b14c9c00a43fac3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5441 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-icache-alias.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5484
- `line_count`: 65
- `sha256`: fdc63f0b55fc9ceed7d6450d2919a5afbb598934278092da8fb4210170b1bbe0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5484 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 5143
- `line_count`: 61
- `sha256`: f630f333e15b0921b0aec5868d24e058973199465163ec6b5d24764f94cd5e55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5143 bytes; lines=61; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 5613
- `line_count`: 67
- `sha256`: 03b5174371c98fb4c48f88733b19f212090d4b0374a76536af55dda6cf183d1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5613 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 5318
- `line_count`: 63
- `sha256`: 448e6bd5f48bdc57383aebcd8b5200390cfc9eaac1e86ba084d8821c463ca84f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5318 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64si-p-wfi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5264
- `line_count`: 62
- `sha256`: 55055bd1e8a265942b141b03f1ec32253ce5e972e4c2e4d63f20725d70b93bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5264 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5334
- `line_count`: 63
- `sha256`: 06ef7621e96092d16e06cdaef65d6ce8958019a27539c4a045edcf5d4572d9e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5334 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: 3ccaa18a8c28c994c9e361596849bc6d7fae532e9a0aa69b142071035f2c8794
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: f2e419c8de88b4693f74316011807e2bbb6763cd653a5abb44f2b5cc8b0d981f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: c34abc608499e170e558f0e4fcbf3a79f2ec8141fef206c15dbbd658571fef78
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5209
- `line_count`: 61
- `sha256`: 391be7d0f8e3a325eb8aebb2785109a95ef0bb335975ae71f1db485daa154df8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5209 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5264
- `line_count`: 62
- `sha256`: 5cde88f8e848317f4a497ce5be5a331ee64ab92b1ce2cfed8381371cfcad5f4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5264 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5210
- `line_count`: 61
- `sha256`: 197ab4ae1350e9c076769cc49bfc0b486b02c48c1d3abbb59e933eae9ecb7e59
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5210 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: dd935d8d9300496965b2ac55cf3a9028382fb452e969c2a6676175201323480a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5209
- `line_count`: 61
- `sha256`: c167c3f4138fd2e060b6e6a0c750fab34c85a48563d68d693d765c3dd4324a3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5209 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5264
- `line_count`: 62
- `sha256`: b8dda4ba3d340b80aac86cae81578e696bb899251e6d6e0523123f83920a1b9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5264 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5210
- `line_count`: 61
- `sha256`: c0cd74390259bf32c0e40cadd3a222af61837c58ceb6fc9ec0cfbae6f02ff040
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5210 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5332
- `line_count`: 63
- `sha256`: 53db41413e69447d4c1f1c8a759e8caa2254ab99f59be4aebd032136c5e02959
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5332 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5332
- `line_count`: 63
- `sha256`: 66c40f5002f7138c66dd63112d42df9ee133f415178d0306a28940c50bb93edd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5332 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5264
- `line_count`: 62
- `sha256`: deba063ab24e31279b9fd0815f68b3347eb762eb0a311994f6483706e7fafd3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5264 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5264
- `line_count`: 62
- `sha256`: c73222693b3817f5e65a9276076c7c392f5e48e01ea6d3f2aab28b324e458a68
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5264 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5333
- `line_count`: 63
- `sha256`: 891792a30987b2860e3308b5b81a901c14ee255eebaaebf25cbfb0779e6b136e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5333 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: fc084a66af05cce828e2925273736e51b7a90868055f16b04a3776e934f03fb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5635
- `line_count`: 66
- `sha256`: 2a0e3f8924af09af3e4ae3f85c5c57e65be4989e9b6e9638ddf861f0b1e3c4fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5635 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5640
- `line_count`: 67
- `sha256`: d1ab1ce641e9a0c3ecde680147d78ed6201852174bdda2bfb603d30e56508f28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5640 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5425
- `line_count`: 64
- `sha256`: 2c2cad522da12be3ceccb7a6d1ffd096e2d1f9a6b4a7c21a98cbc6967ce6a4a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5425 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5477
- `line_count`: 65
- `sha256`: 66441781d08cb40f84be7131035e4a4e440bb618bf87974915d885d3e6518771
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5477 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5495
- `line_count`: 65
- `sha256`: d70b7611c0c87796417c3992c3c8f493c4909f14c7947ebf10a4bdebf6f19851
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5495 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5492
- `line_count`: 65
- `sha256`: ebf3ee4291ec2a9b70c5f0ff907e48f0a05afd44d74997f9812fbbbe65dc28d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5492 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5510
- `line_count`: 65
- `sha256`: 275fdb34929fe6d2d404703589b4e7bd653e9065b241d4b96edfa672218a08c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5510 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5492
- `line_count`: 65
- `sha256`: fd2fabc33f573ae47a935f83e13dbe1ec3fc9933031c425c673f9fd46350a02d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5492 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 551098ca77c0dc5c700810778b2334c268e8da627c77da5ecfd4e3136afbdf21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: 7857d39234ea8d16e2bc2409572f2930765d08a1cfd9c6a4ca7352073f0c101d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5341
- `line_count`: 63
- `sha256`: c8e3d0dbb39b91e474cc84176574a7563be36f120e5a109e8cb88184a6a1e280
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5341 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 1c173055de8467b4558cd65310686c481cf0dd611b7b8ace46603918eeaeb5a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5208
- `line_count`: 61
- `sha256`: c579e6a055975f5075141690a9f194cace7c5a258ca574e7217b58be7865487c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5208 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5629
- `line_count`: 67
- `sha256`: 8aa2636182be959d69fbbf1c9322834cccf2a90e0b4c17485f4645563b6aebd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5629 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5426
- `line_count`: 64
- `sha256`: fc59701797eba14375bcab991eeb7bb179ce0aca0402c51cde0e7dd9e7498f4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5426 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: 5ad521e13ce1e58df16c377955dc8af2fb532ef7db3b8589dd33575a1020d0a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: a96505080c69da83bb0606f8c641d20c5a41e146f76d594eb82950760e7a934b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5347
- `line_count`: 63
- `sha256`: 9bd341a46104b35053a2af036529bee5c22ff374d796448b781d01ed6d437553
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5347 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5506
- `line_count`: 65
- `sha256`: 6488828c58a15ec24ca1721e849cbc744b39f01869903931562c0be543449b0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5506 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: 293d5d0f14bf0a8994c479af31f0c6c3a6d82c7538223688692601335f1271fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: e01022f0dd3d8b18b30872439ed231322500f33d2f2d823db3fc68ffdf3f6bd6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 117facde392b4c16937803f6c47ba319c910c220a5eec1d9b211b3de4d5e7212
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: debe49e730da9b02edc498c0f36fb0093a4d1f5b72a988205d327e36bf45fa47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5485
- `line_count`: 65
- `sha256`: 812eb3598c447acbf641767d3359a0a7bc112d96cfefd07dc086a54bb2d48907
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5485 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5272
- `line_count`: 62
- `sha256`: 36734723c7f74a33107962a17d34c21885850f71e7dcbec7d72824020a0aba3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5272 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 646088c53e6b8068a34030f6f7c3bdee8e75225723e88e3bb6b9f28228653d4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 6bc085311235ef93e2dc6b12c56b8ebebf3eb86968c2093c9b4f1542f67e57fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 9f10796c7e11d490c8066c58fe84753b9df51ccbf9bc5c6c039ba8e201d0bf16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: b48b28bd0f476535484445d255a503f9ef52ce20eeb06367879a7ba48a80686b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: ffb15a4fcaa0f703dad6fb560953fb0863738d50c33ab6fb1c1fded315846482
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 556cb3b39dd8d1502f218652715258cd1f0d6ea343e9fcbbb904be41837cef6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5257
- `line_count`: 62
- `sha256`: cf0bb4732f6d27bca34f28c8724c60eb699c3fd11d41f7ce40a40bfcb45adf29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5257 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: c4fa348d0d893efa434cef2fd3c2aa3060a96ab8eebbbc19826236d6fb04517c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 9ad38f725e081f147ad0cbc410a6e9189d635c419e4fb53092c82c0c9aead274
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 127b261942ceff3663bd9f8db72e563b68fcfc51a6bbd77d8b3dc7aadc49346d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: b204c27a5efb155af55469ab9e042088e22797345fda36dad121ea69c56a17c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 6eb9b503163ee715dd70d23630a274240358651961d835b37104ae20a66f3dff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 29af05a2fa04aa268873a22a447aefb89265e174aed55eed34c78876a744e66e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5507
- `line_count`: 65
- `sha256`: 9c67949479011b8fd9dac510035dca9e03501441fec2691740151f8531093c2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5507 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5247
- `line_count`: 62
- `sha256`: cb2aafcc2d813276e80d560d8386d9b74282ae6a52061848cd8201fa817c54dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5247 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5627
- `line_count`: 67
- `sha256`: 57d6836c9b4b748f2ed18b4ae1732df557cf69e9f8877c44048feccc537dba31
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5627 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 98738129a2afe6a19f82ffa158d99b33a0401341cc0a7e07809caa850420e23d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c741fe87696a0e9f4d3c42da739ee1e25935b8563a84097f3e8d9ca6788ba964
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 51fa7af81e763da85625bc98e9d2b9cd82fce883a7117678721980b855068a5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5746
- `line_count`: 68
- `sha256`: 24ad66fb917e40413841230a64bbeff0a1ce222d56e264fe6a612119f8bc038b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5746 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: af8ffaf9a4637bf2e5987ae2bef426b6a2a11ce00d67bb2102e65e2988c4b0b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: a69edcd2c64067837687806a8516ce745c344b37e920d587b9a54e4bc6ab31ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5326
- `line_count`: 63
- `sha256`: e07bca67533ddbb51608b231b3d9090804b77aff18c2758dffa6317f9958e093
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5326 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 834cd33a6a03c2520898e4ea3accc1caaf7d792dc398697d9203562a8e9a0ba3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: de297450c776db91d1bfefc6b9f8eb8136c7a3691b0dd6cd4a3536deedc3f1f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5761
- `line_count`: 68
- `sha256`: a226b42326dcaba97e0243158cf41c57d477d21cd8005567d7a067f036891b8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5761 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: c87b75b3393668df63dc792a83324701a8fe2efd3fe644116e3417f46f3fd0c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 8b85dc9d17370375cce5e156cbfc6f89f5eeb170365a48fabe8a58d9f72eedb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 2814f4c394d4207e26ad87aaabd0e59d3f78a344d6a09a563809616ff355ad8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5715
- `line_count`: 68
- `sha256`: 49910f115fa6357d3dd8f11a4c4e02e9cd047dc5f0b2b5396829cb70492e581f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5715 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5715
- `line_count`: 68
- `sha256`: b80ad4cc3d1dd3c1b84b14d1d1495145dab14da7f5c4d30444404e14b03e973d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5715 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5176
- `line_count`: 61
- `sha256`: 180d0cf0597c18f18a6f22d8c8c1895465ebf09f3a4a4a08d45e00d11ff44e26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5176 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 62a8e24e2c896dd5c56eaf28deb7f7b3eb0baaab18a924150626a39c13c9fc62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 7bc356b44ce5e0e4ce84a00df6e4f6ed4a782d612eefd61cc8b41180891f33d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 5d97e904010ae8b926e7a74d5e923e8dfb6abfc4a881a478d9c5e218ad5cbd26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 10639d2b94c24be19adf4df53c5fc89740ce675b1713f4e7a09c0b20824e694f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: de92b9760031096bb76a6ef2a0f702740babf97259bc11dbddaf4bf9238fb82a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: f67aff13b3e00426d96e39d0077c91dcd7eb5b3985f8cba7d8c6661c8bbea5cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 09a33972008de545ac8624474a9084d35f51c833c40432f492c803b202e74757
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: c2713d9cd24334b300b09a7ba6893d6a45b24c461115168d6ca97ec6c6576b4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: c5461b838f8448703922d8f8d2d3870ffb30a676f4b791fdd6af7b05c5911123
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: fbdb94415a93e28360f2995223a7376b5a73bb7efff23e6c83b7dbfc0d029e39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 19946ee0d2c49892aa837382eae9668416a1e3ea6c542b61983a60cb35c43d33
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: e05dd430a228911bc756e7c3cb3389c37baf466c03962688300a3a1f9487d415
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: bdaa84f48f40ce889a01a3abf0a98c4f862d3bbced3aaa1c839a1f29803e905f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 1f01f0a4a9989778eeb129b1cb875c93a3a04457130056596a134cd9461d487b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 0b75a540dc93a40921bb253ce6e5620cb0d85c6e1e6851c2b20bb847afebc546
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 75f2ecb9ee7ff3c714a7a32158969efebe6dfafaff6d3e49116941c74ce521a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5507
- `line_count`: 65
- `sha256`: da0796c449dc63e193816d0c4dfce73b69edb652a364179c292d86b24e0b26f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5507 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 6ffa41cee85546fb10a4a65ddf18530d143c4a21993af09a98a6c652e535f3a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: b5df6d533f68b4e6210aa22d1608b2acfd54f03cd7939a72afba046663fcca70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5715
- `line_count`: 68
- `sha256`: c64673c86da906a9488f999b975e8e03b646aa4a6be06b8361e3e11ad5499a1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5715 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: f576fcdc7189e86e68e4ad7b2d0c50941cae97fc7a7ccafd0b164213feb83d6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 402e9d869908b8c60eca8da2c05f5d28149a5210e08de2f2a1130d0181ce916d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: 0766d1ce47860bd9d30edd1ebc77f0a9d051cc48b22f87a7bb621f6a9a7b823b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5473
- `line_count`: 65
- `sha256`: 510698f3c58035aa8fb17a8d0da36430dd8bbac6c1356ee19fc1936f76bc64a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5473 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5339
- `line_count`: 63
- `sha256`: 2c6faeba04dff7c3215792d37821b55bc49950e6131fd390cb3d22c0abc079d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5339 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: d074c78df962ed1623d2e5148c8153026747ccd20c55e1fdd346e74b56487223
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 4098d90801f2819ffb566ef4c3aad6438d97730631da8d345d03f1f3c141f305
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 6892934e48d3d4fe4ed556d29fcc225b93ed9ff53dcbaf4bdd8138cdd8472a80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: e731adf690c4054d38eb760e62290022b9f3c3fe2e07f2cf5fa330b91ac9ae46
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: e5722340ed55a8430b954f2de5add520adb7cd8be32d84698a4a86673a2461fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: dfd25e0a9792f13ce0d0b80e9084c710d7393aa436bbd30edab9ed1f1dfdd19c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5471
- `line_count`: 65
- `sha256`: 7623b2a0cc3ba2c3154ea789921082490b6f8d66df72346448d5e0d092ede777
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5471 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5337
- `line_count`: 63
- `sha256`: 39aeb92186a386e577e208e95657354018e54dad7394f79f21005058a8b9dba0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5337 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5473
- `line_count`: 65
- `sha256`: 1ca8a149862c10f1dbd361e41bad458d88f4ce81d0506cd782b47314f29cf85d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5473 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: 93aef0f855cd91f50c586f2c053b7448bdabef02342fdabd198184f69b0bb784
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: c742c119479479928480d201662ff3f9b89daddc41914426686733fb71d4becb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b615ce502e71dc62c9f0fe47ee22d97f58c232f0b9b521ddc63eb81ed6fabddf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 25a45395aa11e3bf8da239b1a5c33c7e34e93011f707ea41639bc1723759c91f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 08f5c8ec198580c76dc9e51049cb05ad86cbfac1bd86854d4844dd9e3e189f6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 3ea7883cf84c469850bba08d838ea545bd2c22d182a62aa1e66c9fd2b276143a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: fb62e514afcbc118ab1cf81856d07eeef927e90f0882619e7331146811cbd86e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: f811a792c385be476c7f1471262f11b1e807ef4ad4c7aeb99be5ed5a90016acb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: f84ed7c978fecaae018ddc97854dd37ea0acd6cbdd7c4efe2da3271041f7d2e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 473cc6eaf4a7913ffd5869cb0cad9e394393ee52a957875b88d5aca6dbff97e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5489
- `line_count`: 65
- `sha256`: d90184e8e449cb6128aea7347cf2749185279754a00194c478efa180e60d3b01
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5489 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 409d01c9e2bb80fa7319f2370b1934108e48dc0f81082134db255862a1ee4166
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: 5f6ef1a9617948f850e02f9a0cf5d9be96efc316bcea9006d606db7e175fed0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: e1b46e942b2fddb62bf2662e40e32d8bfd91a26bc3bb5ea0c4543a3f6ce0805a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5489
- `line_count`: 65
- `sha256`: 6f4b97add7ec3f8fdb5cb15e1746eabd7d7d3175456a6150891ffcf4b582d8a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5489 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 519f06f0e31ab08f27acf887ab34f3591a37135656fd904934f2426c305fb29d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: f990975bf8473090906aa47ce854927d008a01d3f2b5d2e7b7f61f97f777887f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: e41f1b8dfa4dbd18809e6951d78ed2bf4da5e8713711743e73ff3c9b0f6b65e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: ec1a98bf0cdda73f7a6e7bd99ff44d67c12f7a8747a276e1605898376421dd0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: b9d577dea4db08f5fbfb1734cff2e543be5318b5a81a1589adc81db3f3661446
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: e61b00dcf800d9fb9ad0c6d1ef2154908c06d5e0ca0c88c234646e06cb839dad
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 593b3e2cb693a2d0c0d1ae31296574d524a93ce45bb2e4ef1e682cc6ebf4ec52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 933f8a89ecdf10d8835f74d88b2fd7f2f5ea54270590cf06d8b86170bf2ec55f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 79fb4e2e34e4e79dcc99e2e54cca18eda78f57391bb696a1b3a7cb66b97bd02a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: bb5c989f75f271310767b5cb988abfed560b3d0a6da4a455fc9a72966d5029b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 50d1c9c2354863edbd15f3096d3f5d1ec73d79d419ff7af8f97ce20bc4368dee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 87cc247e20973b14b01a25df1f858eca7245a672ef75c80a455720b8bd229b18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: cc6e45d651a320c089a872fa048a86b6f0962ac591d1d36a5762c6a73e05e470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: aa9b0cfe4f33e834960ebff9e287d4924810fddbdc35c7ab330e8a75c1bcce5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5492
- `line_count`: 65
- `sha256`: c5656bf786a5ecc181b2e43ecb3d04da0e40e689607a43a4bf72f632ec78083b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5492 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 6149c2f77643e391842c4df567988227be45bdb30a658e7aa650d9735b2fd313
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: f7361d460b8317473f0e960ff297eeb57ad31ce41c20c88ec27e7dc8d2db265d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 64c497cf37e73f10c42586c76741264289fb2d920b404f5c1413b260ef69628b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 9a1c645332634ebd9a3de4bbcf541be7648aab56a05c0eac85ff8ff65f1c7e18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5709
- `line_count`: 68
- `sha256`: d4b760e3e85461a1099f1639e1bf768c95f66a40c15f885e957a973efd26d575
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5709 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 5d591816068a2f7bdbf08f616830806a41b62c93f54c1838180d7a4169234abc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 5c5f6198cafc90b366c157b8f84d04817101da5051d83c04cff4ad9e02f2f082
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: cdcae9584f7361cde25313e808ceb11e62ee51d7376365e8d968dd8c6a53e17c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: a431060ccd1039866428008386dd27461d56d178464dabe7793606e19b9461d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 4507e5b0e9e6d4a6cfbc261b9b92a8738f8bee08426a7d691aeef760322c83f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 146340e7239d085f911335f91508b3e9f02d256b9c79b10719ffca5950df8c0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: acc47a3c14e84204dc67d69b1319a90cc6a36e1184fbbff36c72fdde86acfe25
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 603a3f8fc38cc7392555a6453a9b97edef0236fe0c687ed9358c2e0c46268107
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: eae1d513bb1eb78dde3fdcc91a8005ff2372109f1674410df1efb42cbf548e39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/status.txt

- `kind`: txt
- `size_bytes`: 17953
- `line_count`: 360
- `sha256`: 6331b8133bf6a2f9565da82d98a66e8297454f4b266e02bfba07741e38a5ce54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=17953 bytes; lines=360; PASS=718; tail=module-testbench PASS verilator-lint PASS npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/summary.txt

- `kind`: txt
- `size_bytes`: 17998
- `line_count`: 546
- `sha256`: 660460b96e1c8a5c7df54c77f0911b182d23078d6883ce407603a82730fba02a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=17998 bytes; lines=546; PASS=718; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uzbs r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/core-regress/20260713-164726-2511058/verilator-lint.log

- `kind`: log
- `size_bytes`: 8830
- `line_count`: 6
- `sha256`: 6d01aeb8b173cb026fd462d2d301164a966d3a03181b943207557ceecbaf15e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=8830 bytes; lines=6; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/coremark-clean.log

- `kind`: log
- `size_bytes`: 258
- `line_count`: 3
- `sha256`: bbff8c651da9ad82316dc5f938f6f207d027678972a92291470b2941944e1b06
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=258 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' rm -rf Makefile.html /home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark/build/ make: Leaving directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark'

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/coremark-iter10.log

- `kind`: log
- `size_bytes`: 8315
- `line_count`: 109
- `sha256`: f9d879614fb01e1927ec8637d04595a32c20d221d5680316093fc06735a8f41f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=8315 bytes; lines=109; PASS=2; GOOD_TRAP=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' # Building coremark-run [riscv64-npc] + CC src/core_portme.c + CC src/core_matrix.c + CC src/core_list_join.c + CC src/core_state.c + CC src/core_main.c + CC src/core_util...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/current-contract-final/complete.txt

- `kind`: txt
- `size_bytes`: 434
- `line_count`: 6
- `sha256`: 236a04240af649362520c9ab7511853bd885ae949c6c36cc042e6b5fe4cd20f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=434 bytes; lines=6; markers=<none>; tail=status=COMPLETE git_head=8532bad0794cb34199c8adf49b080e1773b1f16f input_manifest_sha256=94bccb0bca3c30b0b86227932ad1d9cc652ec2beb089cd117aa2a49650f90648 source_contract_log_sha256=67aaa2e29a261a66894e5b6315851f1e968b800e23d746d5a9138e940cacb632 window_domai...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/current-contract-final/inputs.post.sha256

- `kind`: sha256
- `size_bytes`: 813
- `line_count`: 6
- `sha256`: 94bccb0bca3c30b0b86227932ad1d9cc652ec2beb089cd117aa2a49650f90648
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=813 bytes; lines=6; markers=<none>; tail=bdd4510f37a581127cc9e4585df0fc6e228f146156fd5c79fdccf923e5eb65db npc/rv64/vsrc/frontend/OooFetchAxiBridge.v 8fcdaca3c13898de235658227c88872bc53d7348157dd5a64a16c5e2e93ae5ec npc/rv64/vsrc/cache/OooFetchPacketCache.v 496f5b97c115fbebb8a16c1e224b93672bf58482f1...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/current-contract-final/inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 813
- `line_count`: 6
- `sha256`: 94bccb0bca3c30b0b86227932ad1d9cc652ec2beb089cd117aa2a49650f90648
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=813 bytes; lines=6; markers=<none>; tail=bdd4510f37a581127cc9e4585df0fc6e228f146156fd5c79fdccf923e5eb65db npc/rv64/vsrc/frontend/OooFetchAxiBridge.v 8fcdaca3c13898de235658227c88872bc53d7348157dd5a64a16c5e2e93ae5ec npc/rv64/vsrc/cache/OooFetchPacketCache.v 496f5b97c115fbebb8a16c1e224b93672bf58482f1...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/current-contract-final/source-contract.log

- `kind`: log
- `size_bytes`: 149
- `line_count`: 1
- `sha256`: 67aaa2e29a261a66894e5b6315851f1e968b800e23d746d5a9138e940cacb632
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=149 bytes; lines=1; PASS=2; tail=[T3J-SOURCE-CONTRACT] PASS state_width=4 states={'S_IDLE': 0, 'S_RESP': 7, 'S_LOOKUP': 9, 'S_R0': 4} exact_window_terms=3 semantic_context_signals=5

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/current-contract-final/source-mutations.log

- `kind`: log
- `size_bytes`: 1063
- `line_count`: 12
- `sha256`: 0b5e67b2815c0bcb29f5a51107ee941c7de632981246f23e0c6f242f71fd7453
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=1063 bytes; lines=12; PASS=24; tail=[T3J-SOURCE-CONTRACT] PASS state_width=4 states={'S_IDLE': 0, 'S_RESP': 7, 'S_LOOKUP': 9, 'S_R0': 4} exact_window_terms=3 semantic_context_signals=5 [T3J-WINDOW-DOMAIN-PROOF] PASS RTL-premises=ready/fire/window/fill/sram_we fire_cases=256 semantic_cases=256...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/current-contract-final/window-domain-proof.log

- `kind`: log
- `size_bytes`: 142
- `line_count`: 1
- `sha256`: 7552b5b5289a0e510bd51b798a93b84459371a33cbbe8c3ebcf5deee27990ee6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=142 bytes; lines=1; PASS=2; tail=[T3J-WINDOW-DOMAIN-PROOF] PASS RTL-premises=ready/fire/window/fill/sram_we fire_cases=256 semantic_cases=256 mutex_cases=512 total_cases=1024

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-smoke/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1029284
- `line_count`: 25947
- `sha256`: d88debc6e0bdbbecda342ac9dcc8365ed4b82a970baded7cca9b040d5ef3991b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=1029284 bytes; lines=25947; FAIL=3; PASS=1; tail=v0x55558eb4b3c0_0, 0, 2; %alloc S_0x55558eb483f0; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x55558eb483f0; %join; %free S_0x55558eb483f0; %pushi/vec4 0, 0, 1; %store/vec4 v0x55558eb4b490_0, 0, 1; %pushi/vec4 0, 0, 2; %store/vec4 v0x55558eb4b3c0_0, 0, 2; %al...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-smoke/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126192
- `line_count`: 3153
- `sha256`: e32015ac6a13625015e76ec74795ad51c1ed0454bb64df11c2c8631ad93d54ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126192 bytes; lines=3153; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-smoke/results/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86540
- `line_count`: 650
- `sha256`: 0b1275f5c8e656dea06c28c099aba283824e99a39008630fddafa8a2e888623f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86540 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-smoke/results/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 701
- `line_count`: 5
- `sha256`: dce58147584177feb24a5ab9e0dd8374ba421aefdfa2a986223326c941a59f24
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=701 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-smoke/results/summary.txt

- `kind`: txt
- `size_bytes`: 346
- `line_count`: 11
- `sha256`: 3b7efd217d373da63963386fda545af8ddd55a20cc8178a5e37b48246894d9dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=346 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-smoke/results - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-window/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1081247
- `line_count`: 27271
- `sha256`: f4bf93de331e31d8a344211bbb8760c4d3e70d66de9ae457bf5835acc05c671b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=1081247 bytes; lines=27271; FAIL=3; PASS=1; tail=v0x5555640e7930_0, 0, 2; %alloc S_0x5555640e4960; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x5555640e4960; %join; %free S_0x5555640e4960; %pushi/vec4 0, 0, 1; %store/vec4 v0x5555640e7a00_0, 0, 1; %pushi/vec4 0, 0, 2; %store/vec4 v0x5555640e7930_0, 0, 2; %al...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-window/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126192
- `line_count`: 3153
- `sha256`: ea1b45d6a516d7aecb697987ac81837b52963e7ce3ea8e36e5f315a1796eba4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126192 bytes; lines=3153; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-window/results/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86541
- `line_count`: 650
- `sha256`: 133dd56b96b92b6ff3e7982de6a8326bf6312e0e79fea8e57787c73e1e4571eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86541 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-window/results/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 702
- `line_count`: 5
- `sha256`: e612c9e210c5f95ffe20d9330a47ecf4a1c697dd3206a346fb4d4b8591620210
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=702 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-window/results/summary.txt

- `kind`: txt
- `size_bytes`: 347
- `line_count`: 11
- `sha256`: 8f43b3f9c394c6b68281b739aed8236b099e87ae40c97183ab27b265d3643767
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=347 bytes; lines=11; PASS=4; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/focused-window/results - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_oo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/global-checker-old-t3i-smoke.json

- `kind`: json
- `size_bytes`: 479
- `line_count`: 20
- `sha256`: 818bd9fc19e35cda180a2268c6fce44bc3d8c0c141ed5bd2cf6125975392d519
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: json evidence; size=479 bytes; lines=20; markers=<none>; tail={ "combinational_loops": 0, "endpoint_classes": { "csr_file": 0, "fetch_outstanding": 0, "fetch_payload_sram": 1, "other": 0, "pending_trap_exit": 39 }, "fetch_payload_addr_path_blocks": 0, "fetch_payload_en_path_blocks": 1, "path_count": 40, "period_ns": 5...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/global-checker-old-t3i-smoke.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: 94d546f39982e6eb75d6344b3cf0f94a77cc8162f000897c0ecfb24c1708aa26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=[T3J-GLOBAL-STA] PASS: loops=0 paths=40 WNS=-9.380ns TNS=-199464.16ns power=0.120W target_met=False

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 49158
- `line_count`: 1322
- `sha256`: 79667300ffe024803f6549c40e7b637735dd7703888c7faeec464bfcc2db3703
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=49158 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 266212
- `line_count`: 6944
- `sha256`: 0d8f14657bccfa33c4c984b6bf128c122a2139500b213d157dd70aa6c41d89d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=266212 bytes; lines=6944; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 218033
- `line_count`: 5738
- `sha256`: 17e2ee937c9efa6150c39be4b717939d2251438b7b140cbac78dae77fb747ea5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=218033 bytes; lines=5738; FAIL=3; PASS=1; tail=%flag_set/imm 4, 0; %store/vec4 v0x555560022470_0, 4, 3; %pushi/vec4 0, 0, 3; %ix/load 4, 0, 0; %flag_set/imm 4, 0; %store/vec4 v0x5555600222d0_0, 4, 3; %alloc S_0x555560014e70; %fork TD_tb_axi_exec_firewall.tick, S_0x555560014e70; %join; %free S_0x55556001...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 370642
- `line_count`: 7337
- `sha256`: 3215d3038874a89d29823df70f7009f61fcbf02d844a02c874f053e7330dc56e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=370642 bytes; lines=7337; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 149701
- `line_count`: 3963
- `sha256`: 09abbe49d62fd5f2694e65b90fd31bb25c60f63febd4c88287390732185fd982
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=149701 bytes; lines=3963; FAIL=3; PASS=1; tail=/vec4 0, 0, 32; %store/vec4 v0x5555951cecb0_0, 0, 32; %pushi/vec4 0, 0, 1; %store/vec4 v0x5555951cf600_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5555951cf090_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x5555951ceef0_0, 0, 32; %pushi/vec4 0, 0, 1; %store...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 198982
- `line_count`: 5455
- `sha256`: a8af0f8e3b3e968ffd4aa896428f1b918a554108dda4f01523eecbb1de236ad4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=198982 bytes; lines=5455; FAIL=3; PASS=1; tail=%alloc S_0x555561677a40; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32629
- `line_count`: 864
- `sha256`: 9220f0f56c77528de41a7b949751a95f54128de0262e53c37f4c942c24e74f41
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32629 bytes; lines=864; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 380349
- `line_count`: 9321
- `sha256`: 7beadaf37e887a9a06a857293425256ede39a49314eca779af4929a2c15f248f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=380349 bytes; lines=9321; markers=<none>; tail=5; %pushi/vec4 5244928, 0, 64; %store/vec4 v0x555571cd1760_0, 0, 64; %pushi/vec4 1, 0, 1; %store/vec4 v0x555571cd31b0_0, 0, 1; %fork TD_tb_csr_file.drive_csr, S_0x555571d4abd0; %join; %free S_0x555571d4abd0; %delay 1, 0; %alloc S_0x555571e12280; %pushi/vec4...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112453
- `line_count`: 3912
- `sha256`: 02d6bf9ee5b535aaf4285a47a0811ea32de15e5465212e4395b0fde70599c98d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112453 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x55555e58dad0_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x55555e58dad0_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274500
- `line_count`: 8084
- `sha256`: e703ed1e7fa66ca6384a7721eb4155730d1546b57c8e50ba943d512e4ad2f684
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274500 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32845
- `line_count`: 892
- `sha256`: 74c99a1cc6b488829a43e359429cd6830ee44422311279ee4858b7106260b5db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32845 bytes; lines=892; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 38121
- `line_count`: 983
- `sha256`: c13fd316f61d7ac3a1f15c17166ec0a4fb035a973a0681453587814f91590964
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=38121 bytes; lines=983; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40505
- `line_count`: 1057
- `sha256`: d930a9a5ab37f4ea7284f0d385400654efb8d2197f88568eb06752602680f56b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40505 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28803
- `line_count`: 748
- `sha256`: e5a27c5ede3208aa7a05671c73afb0001646692b6c0e4cceeed6e276c0220a5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28803 bytes; lines=748; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 2232091
- `line_count`: 57050
- `sha256`: ef80e81ca35660dfeeabcbe51f02bed4c11f0f287555ded8a7f579c0414c17db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=2232091 bytes; lines=57050; markers=<none>; tail=32; %fork TD_tb_ooo_alu_core_slice.dispatch_pair, S_0x555557d62dc0; %join; %free S_0x555557d62dc0; %alloc S_0x555557ea5ec0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dr...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 2154252
- `line_count`: 55697
- `sha256`: 47694d2648bb96dc7f1322095dfae1d9f8ab2ae1536a53f7d62353db67ee5a5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=2154252 bytes; lines=55697; FAIL=1; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39563
- `line_count`: 1135
- `sha256`: 8197ed1b1e616ba92b10e350eda529903dc58e251c0ef719820de631d7a5f2bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39563 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30875
- `line_count`: 801
- `sha256`: 6d5db8b152f5e10cca78533c44528913edc06588928db39c9f57c4e86a66b07b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30875 bytes; lines=801; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 74027
- `line_count`: 2388
- `sha256`: ac2474058e3611075b743b5a627f2b2b4bb5d6fbbc0747db1ce23034be6a14e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=74027 bytes; lines=2388; FAIL=7; PASS=2; tail=ooo_bitmanip_gate.dut.bitmanip_clz8, S_0x555578e6e290; %concat/vec4; draw_concat_vec4 %add; %ret/vec4 0, 0, 7; Assign to bitmanip_clz64 (store_vec4_to_lval) %jmp T_2.21; T_2.20 ; %load/vec4 v0x555578e6e1b0_0; %parti/s 8, 8, 5; %cmpi/ne 0, 0, 8; %jmp/0xz T_2...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 39476
- `line_count`: 813
- `sha256`: f4f8be90846fb544ee0d8f2ad3a9b678863b8b8792d68f6c5c3567ea80cb2b8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=39476 bytes; lines=813; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30220
- `line_count`: 663
- `sha256`: 525eb349a065d6ba119979d46c5e5066a319e6f08bbe124129a89e816c0ddbb8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30220 bytes; lines=663; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138227
- `line_count`: 3130
- `sha256`: 08476a24a434863df8de626f1c861870aafbdacfe1da88b5437751161951875f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138227 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x55558daea8a0_0, 0, 1024;...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 33576
- `line_count`: 698
- `sha256`: 8c806eed9473ab5a44a016045c39b37c0d3bf174f6b3de4f4835133aff2f1b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=33576 bytes; lines=698; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47344
- `line_count`: 1228
- `sha256`: 096a7bbd1d7500bab0676521063cb4b4858c0a3c77b954e6ec5aa73388c11b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47344 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 54093
- `line_count`: 1356
- `sha256`: fc8dfb25840e0d33c0352888d9849cdc29e91efa90b20a60594fcb9503f2840b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=54093 bytes; lines=1356; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 68358
- `line_count`: 1766
- `sha256`: 86dffb70b818bf3b62fbbfcc96e6d13c85776455177478a30a73d63b2327b67d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=68358 bytes; lines=1766; FAIL=12; PASS=2; tail=_OP_HIGH" 1 4 35, C4<01>; P_0x555594927590 .param/l "CLMUL_OP_LOW" 1 4 34, C4<00>; P_0x5555949275d0 .param/l "CLMUL_OP_REV" 1 4 36, C4<10>; P_0x555594927610 .param/l "PHY_REG_ADDR_W" 0 4 4, +C4<00000000000000000000000000000110>; P_0x555594927650 .param/l "R...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 67148
- `line_count`: 1534
- `sha256`: 9e3a039138a105ee3a36dcd39ff9d65141f3dd0ee8bda68d27491efce6ce2b39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=67148 bytes; lines=1534; FAIL=11; PASS=1; tail=st", 31 0, L_0x555568bf6f30; 1 drivers v0x555568be29a0_0 .net "commit1_next_pc", 63 0, L_0x555568bf72d0; 1 drivers v0x555568be2a70_0 .net "commit1_pc", 63 0, L_0x555568bf6c30; 1 drivers v0x555568be2b40_0 .net "commit1_rd_addr", 4 0, L_0x555568bf7940; 1 driv...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 52281
- `line_count`: 1259
- `sha256`: 4cca3803014baaa1aff85a5a63798f7531a62a6024c0ec7797737211e7a858ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=52281 bytes; lines=1259; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29642
- `line_count`: 783
- `sha256`: 21cb94ecf405ac386e0b3d4b0cab538cb56ca351734d00983e00650e9f855ce2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29642 bytes; lines=783; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 4129484
- `line_count`: 97800
- `sha256`: 9c12ff562c2585d301ef36ecee3edee8f8dcb3ee73e3923493cee973460e73fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=4129484 bytes; lines=97800; markers=<none>; tail=_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 33848
- `line_count`: 768
- `sha256`: e71f2a107cd0ff8978af60cd7578840d215737447f873bdd2b82048ff853c32d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=33848 bytes; lines=768; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34223
- `line_count`: 798
- `sha256`: 627dc71748e9147dbc0bef5d28a53d2aa9f4059edcf7c929e7315d67b277c757
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34223 bytes; lines=798; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 160532
- `line_count`: 3980
- `sha256`: 07786cfe2a582eef7c34d3e9a118e75088a3e9e4e507ff57c1829ecc554901e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=160532 bytes; lines=3980; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1668572516, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x55556715cdc0_0, 0, 1024; %load/vec4 v0x555567163260_0; %store/vec4 v0x55556715cd00_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x5555...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101318
- `line_count`: 2454
- `sha256`: bf0ebc5c6d48f1562d079db659955f2a0130b37ac5b0284f643f1c19dfed8f21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101318 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53770
- `line_count`: 1375
- `sha256`: 76070ba36a9a6decd941cbff2e2251c495d720784548b7fa98c2a23f07f113ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53770 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 99045
- `line_count`: 2306
- `sha256`: 182520c897a76624cf9058153bd92fe82da639845e0ac6eb85b0895b93efb42a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99045 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 557860
- `line_count`: 12414
- `sha256`: 26d3a1cad7439beb426ecf918355cf046f5faf4dffed2f995fd0ac8986372396
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=557860 bytes; lines=12414; markers=<none>; tail=0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 981703
- `line_count`: 25163
- `sha256`: f9ee5dfa1c23724ea0a6755254c251b5e9cd9c6de49ea92d9c16116da0fc0e57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 6}
- `summary`: vvp evidence; size=981703 bytes; lines=25163; FAIL=8; PASS=6; tail=32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 688820
- `line_count`: 17194
- `sha256`: fc62ec1a10c35e9b003b14db92d22e5ee91e5ad75fd38dd971096329805445c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=688820 bytes; lines=17194; FAIL=3; PASS=1; tail=9; %flag_get/vec4 9; %jmp/0 T_145.4, 9; %load/vec4 v0x55557eb72480_0; %pushi/vec4 8, 0, 4; %cmp/ne; %flag_get/vec4 4; %and; T_145.4; %flag_set/vec4 8; %jmp/0xz T_145.2, 8; %load/vec4 v0x55557eb6f860_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_145.7, 9;...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1081247
- `line_count`: 27271
- `sha256`: 997ae25179b014e3512c0c6e8af38d6973cd6ca41edc76bbda7ae2f55cff74ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=1081247 bytes; lines=27271; FAIL=3; PASS=1; tail=v0x5555759c0930_0, 0, 2; %alloc S_0x5555759bd960; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x5555759bd960; %join; %free S_0x5555759bd960; %pushi/vec4 0, 0, 1; %store/vec4 v0x5555759c0a00_0, 0, 1; %pushi/vec4 0, 0, 2; %store/vec4 v0x5555759c0930_0, 0, 2; %al...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 803370
- `line_count`: 20219
- `sha256`: 6bbe5c22b2391211a615eb6709437aa865dacd3d87b3d5405a2b3192695e919d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=803370 bytes; lines=20219; FAIL=4; PASS=1; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 102107
- `line_count`: 2491
- `sha256`: c0a672d445f9fa5665de3b21165273b0db3672cc0ab8e19cdb2925f00dee0111
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=102107 bytes; lines=2491; FAIL=3; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 1696625253, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1818583411, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702043762, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 324698
- `line_count`: 7415
- `sha256`: e5bcd9ebbd2c7c57cbd0bc45e175bad21454788ec61aa870f6197152ebce2092
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=324698 bytes; lines=7415; markers=<none>; tail=raw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544503405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 363554
- `line_count`: 7188
- `sha256`: a46f543dfadf28b2ce735b1777da2233fd918d0ed7627107fc698906b7da7b4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=363554 bytes; lines=7188; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126194
- `line_count`: 3153
- `sha256`: 06a1ae15544a290ec48aa1b7c9cf96f20c76989af0b4a8ae69831a2e5b59164c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126194 bytes; lines=3153; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 273724
- `line_count`: 7025
- `sha256`: 3a121c1aeadda12937e72475203531ca94d4d10415c155f399ce9ac5791dc49d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=273724 bytes; lines=7025; FAIL=5; PASS=1; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 122038
- `line_count`: 3022
- `sha256`: 6e0e9a3f956c306e2101f21e3d0a38a8e6d4d02b57502ec0f3df2f4378643edf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=122038 bytes; lines=3022; FAIL=5; PASS=1; tail=ef3440_0; %store/vec4 v0x55556eeee800_0, 0, 2; %callf/vec4 TD_tb_ooo_fetch_packet_fifo.dut.ptr_inc, S_0x55556eeee600; %assign/vec4 v0x55556eef3440_0, 0; T_17.11 ; %load/vec4 v0x55556eef1e80_0; %load/vec4 v0x55556eef3da0_0; %concat/vec4; draw_concat_vec4 %du...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 66017
- `line_count`: 1604
- `sha256`: 1ff76047d2328687bb03ca90abea726428ac9a362f180368fb6a0a049d5859e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=66017 bytes; lines=1604; FAIL=8; PASS=2; tail=h.vpi"; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/va_math.vpi"; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/v2009.vpi"; S_0x55557da91130 .scope package, "$unit" "$unit" 2 1; .timescale 0 0; v0x55557dadb9c0_0 .var/i "t...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 115219
- `line_count`: 2951
- `sha256`: 5b3be7ec50b3e8c6a19af53cd95f261b1676b1854d0967df85ce02abcca9fd97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=115219 bytes; lines=2951; FAIL=4; PASS=1; tail=98b0e0_0; %store/vec4 v0x55558c988670_0, 0, 64; %load/vec4 v0x55558c98b1c0_0; %store/vec4 v0x55558c988750_0, 0, 64; %load/vec4 v0x55558c98ae40_0; %store/vec4 v0x55558c9883d0_0, 0, 64; %load/vec4 v0x55558c98af20_0; %store/vec4 v0x55558c9884b0_0, 0, 64; %load...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1009294
- `line_count`: 25317
- `sha256`: 5d74a682b834c8290e70714e2efe168022db9cef85df9b046c9bd75dfadda828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=1009294 bytes; lines=25317; FAIL=5; PASS=1; tail=2, 3; %store/vec4 v0x5555698bc520_0, 0, 5; %store/vec4 v0x5555698bc440_0, 0, 1; %callf/vec4 TD_tb_ooo_fetch_page_end_fault.u_decode.u_dec1_rvc_decompressor.rvc_imm_6, S_0x5555698bc260; %store/vec4 v0x5555698b8d30_0, 0, 64; %load/vec4 v0x5555698b8d30_0; %par...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 119798
- `line_count`: 3201
- `sha256`: abd3f1093783d85cd9e23c78d4f48ce279058c02989e6328ffa1e35f9bdaf741
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=119798 bytes; lines=3201; FAIL=5; PASS=1; tail=_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %c...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 88625
- `line_count`: 2189
- `sha256`: 762899680015a9f0b021d7d65e745c6f49e8cc652630525a6eb1480448262004
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=88625 bytes; lines=2189; FAIL=4; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 3587359
- `line_count`: 83330
- `sha256`: 5e25813eeb675ba6c7049e185ae4c8f7c019d8c4f6c74c407913c1eacbdeed1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=3587359 bytes; lines=83330; FAIL=4; tail=2; %jmp/0 T_434.7, 12; %load/vec4 v0x55558f198a70_0; %and; T_434.7; %flag_set/vec4 11; %flag_get/vec4 11; %jmp/0 T_434.6, 11; %load/vec4 v0x55558f1a7b20_0; %nor/r; %and; T_434.6; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_434.5, 10; %load/vec4 v0x55558f...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 352938
- `line_count`: 10735
- `sha256`: b4fd56308e38e4596e1d857fc629e934ce02c5b410bbf48e95319e4f62976768
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=352938 bytes; lines=10735; FAIL=5; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68642
- `line_count`: 1835
- `sha256`: ff63c5bd713cdf4bc92cfa84a2158a4d8ca732c5a1893519f0e25f35168a0b7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68642 bytes; lines=1835; FAIL=7; PASS=2; tail=555582dcefe0_0 .var "class_s_bits", 9 0; v0x555582dcf0c0_0 .net "class_value_o", 63 0, L_0x555582de0b50; alias, 1 drivers v0x555582dcf1a0_0 .net "double_i", 0 0, v0x555582dd0120_0; 1 drivers v0x555582dcf260_0 .net "frs1_value_i", 63 0, v0x555582dd01f0_0; 1...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 98086
- `line_count`: 2767
- `sha256`: 4015a392ccccdb866b5709e166c3995f96203e4717fe97cd55f2db6d2d940d96
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=98086 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x55556cbc0420_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x55556cbc0680_0; %store/vec4 v0x55556cbc0fa0_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x55556cbc04e0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x55556cbc05a0_0; %store/vec4...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202849
- `line_count`: 6365
- `sha256`: d5b7e73d66b2b20639d291610ae6040633a5300f4d292ae9302109b73dded5cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202849 bytes; lines=6365; FAIL=4; tail=c42140_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x555567c41c30_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x555567c42740_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x555567c41cf0_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x555567c42800_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 455878
- `line_count`: 11744
- `sha256`: 32d4548ba84c9f64bf54a74cfc53bd804ac97f6da265918aeaf5349658491ddc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=455878 bytes; lines=11744; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 5518...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 84157
- `line_count`: 2207
- `sha256`: abbd7ea7916406d2e684bde072d26a3d674b943d60c702fc86e60660b0d595fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=84157 bytes; lines=2207; FAIL=8; PASS=2; tail=558006f1e0; .timescale 0 0; v0x5555800ca150_0 .var "exp_remainder_nonzero", 0 0; v0x5555800ca230_0 .var "exp_root", 55 0; v0x5555800ca310_0 .var "first_value", 111 0; v0x5555800ca3d0_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 201335
- `line_count`: 5005
- `sha256`: cd2be93679755a899ad9062a1cc3024de3f809bb788492969c87d63e84e4493f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=201335 bytes; lines=5005; FAIL=3; PASS=1; tail=0_0, 4, 3; %load/vec4 v0x555581f82210_0; %dup/vec4; %pushi/vec4 0, 0, 3; %cmp/e; %jmp/1 T_9.26, 6; %dup/vec4; %pushi/vec4 1, 0, 3; %cmp/e; %jmp/1 T_9.27, 6; %dup/vec4; %pushi/vec4 2, 0, 3; %cmp/e; %jmp/1 T_9.28, 6; %dup/vec4; %pushi/vec4 3, 0, 3; %cmp/e; %j...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197197
- `line_count`: 6101
- `sha256`: de57f3fb7dd9f811515bcc85d1e61be769047e3ccc940fb36994191e88431243
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197197 bytes; lines=6101; markers=<none>; tail=vec4 v0x55555fc25cd0_0; %parti/s 1, 2, 3; %store/vec4 v0x55555fc25710_0, 0, 1; %load/vec4 v0x55555fc25cd0_0; %parti/s 1, 1, 2; %load/vec4 v0x55555fc25cd0_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x55555fc25b30_0; %or; %store/vec4 v0x55555fc261f0_0, 0, 1; %push...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64366
- `line_count`: 1640
- `sha256`: 56cd135033e69ffb0553b906ecd19bba99d1fe210aea8f216533f8f17b35e90d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64366 bytes; lines=1640; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30511
- `line_count`: 662
- `sha256`: cb20b9644f64abd71b23f730428f5e02634546a7de088f36d195b8b811749793
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30511 bytes; lines=662; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39483
- `line_count`: 1056
- `sha256`: b895a0f98c30c804aa4504a8db31eb6a593933e613c0478fb7252604ffe29691
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39483 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 76174
- `line_count`: 1879
- `sha256`: 669455f511bdd99f1452780103acdbb45eb6a2373aab4ee9ffd04112669760ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=76174 bytes; lines=1879; FAIL=6; PASS=2; tail=24440; 1 drivers v0x55558351f450_0 .net "post_alloc_count_w", 6 0, L_0x555583522f70; 1 drivers v0x55558351f530_0 .net "post_free0_count_w", 6 0, L_0x555583523750; 1 drivers v0x55558351f610_0 .net "push_count_w", 1 0, L_0x5555835240c0; 1 drivers v0x55558351f...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 91223
- `line_count`: 2239
- `sha256`: 5724a183b9f01c25283e96f369193fa1938d680392751809f25cd2e2b9526a1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=91223 bytes; lines=2239; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 111049
- `line_count`: 2616
- `sha256`: 37c34eae68dbbd92fe26d7227e20590518542d317e871563bcbe1e2d328cb43c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=111049 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x55559382cbd0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5555938285e0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x55559382e4f0; %join; %free S_0x55559382e4f0; %alloc S_0x555593881740; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x55559388...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 147042
- `line_count`: 3486
- `sha256`: b0660c27830cbeebb1541db26f008c53da5c9de65c5c8d7c093e3cdc7fca2a08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=147042 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x55558f21db50; %alloc S_0x55558f21db50; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 92344
- `line_count`: 2289
- `sha256`: 31ea32f0392bd71fb9302e497c8046edba4fb2fd4a856d47a8543294e3224493
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=92344 bytes; lines=2289; FAIL=3; PASS=1; tail=5468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1633840229, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x55557171cd00_0, 0, 1024; %load/vec4 v0x555571721420_0; %store/vec4 v0x5555716ced30_0, 0, 1; %pushi/vec...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138681
- `line_count`: 3101
- `sha256`: 5150c2b7a8a0f42b50fd96a2870d098bb45244e7a5f061e8a02f771239a25133
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138681 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 351264
- `line_count`: 6189
- `sha256`: 212cb871de04f3c5dc66f6ac8859d1e1bfb7aaa0f05f9e853bc363f9740e2c83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=351264 bytes; lines=6189; FAIL=4; PASS=2; tail=55660c9b40; alias, 1 drivers v0x55556603dca0_0 .net "trap_exit_exit_valid_o", 0 0, L_0x5555660c9a80; alias, 1 drivers v0x55556603dd60_0 .net "trap_exit_tval_o", 63 0, L_0x5555660caf90; alias, 1 drivers L_0x5555660c8450 .part L_0x555566059130, 38, 1; L_0x555...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 3062899
- `line_count`: 78381
- `sha256`: 40ae0757e02f84e7048154547f3852204086d9397ff85f6821d75e1f013e1c5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3062899 bytes; lines=78381; markers=<none>; tail=ec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543387501, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1835627635, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5555805fcdb0_0, 0, 1024; %load/vec4 v0x55558060060...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 593064
- `line_count`: 14948
- `sha256`: f2f83fc0d8473b87cbd93fad2089618e6cad8bda786ce9133fcae8f69c12e09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=593064 bytes; lines=14948; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1157495
- `line_count`: 29315
- `sha256`: b4b8a98dff05ca2e4f9a989a5a0c2174d8c40a267e46294144f2235631017921
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1157495 bytes; lines=29315; markers=<none>; tail=4, 0; %load/vec4a v0x5555868238b0, 4; %ix/load 4, 11, 0; %flag_set/imm 4, 0; %load/vec4a v0x5555868238b0, 4; %addi 1, 0, 64; %xor; %store/vec4 v0x55558681e560_0, 0, 64; %pushi/vec4 1, 0, 1; %store/vec4 v0x55558681e370_0, 0, 1; %ix/load 4, 11, 0; %flag_set/i...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 48883
- `line_count`: 1193
- `sha256`: f2f81c60056a25543bbb5f833bdf85626b9b1524636d46cf0cc109ae2e454ffe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=48883 bytes; lines=1193; FAIL=10; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 266249
- `line_count`: 6678
- `sha256`: dfa1aa65fde178f65c88c4a29a566f420f4b6d47e72defa99f10767ea18e5955
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=266249 bytes; lines=6678; FAIL=7; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 182927
- `line_count`: 4069
- `sha256`: 4a8e361b2827816ec3bba83226e1bebf27f36d3d225ec85f5e04d62bea6824d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=182927 bytes; lines=4069; FAIL=5; PASS=1; tail=ore/vec4 v0x55557da02c10_0, 0, 1024; %load/vec4 v0x55557dafe600_0; %store/vec4 v0x55557da02740_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x55557da02270_0, 0, 1; %fork TD_$unit.tb_check1, S_0x55557da48c50; %join; %free S_0x55557da48c50; %alloc S_0x55557dafa...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 66636
- `line_count`: 1575
- `sha256`: fb0a23e6d40da022592c74b7e5c01de886763c4c8cf243dfbe224615cce64c99
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=66636 bytes; lines=1575; FAIL=6; PASS=2; tail=380_0 .var "backend_drained_q", 0 0; v0x555572eeb450_0 .var "branch_resolve_pending_match", 0 0; v0x555572eeb550_0 .var "branch_spec_active", 0 0; v0x555572eeb620_0 .var "branch_spec_checkpoint_pending", 0 0; v0x555572eeb710_0 .var "direct_frontend_flush",...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 104791
- `line_count`: 2576
- `sha256`: 86ed18d4f1180cd3ca7e84499e137b58a6006b0c8da84ac0bfb354bf59b2d79f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=104791 bytes; lines=2576; FAIL=5; PASS=1; tail=$unit.tb_check1, S_0x555589770520; %join; %free S_0x555589770520; %alloc S_0x555589770520; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 74424
- `line_count`: 1866
- `sha256`: e1581ad6604baf7025b8b04949519c39a0dcdfadb90e9bc4ac1ac77498f571af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=74424 bytes; lines=1866; FAIL=9; PASS=1; tail=00000000000000000000000000000000000>, C4<0000000000000000000000000000000000000000000000000000000000000000>, C4<0000000000000000000000000000000000000000000000000000000000000000>; L_0x555575e34390 .functor BUFZ 64, v0x555575e2e180_0, C4<0000000000000000000000...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 21170
- `line_count`: 598
- `sha256`: 758643d4cb924ada7c66604ef9e3defc73f9bc215431a60d7b87124cd6662f2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=21170 bytes; lines=598; FAIL=2; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 197721
- `line_count`: 5036
- `sha256`: 9a779ae26af66bbe4038798e3a729f8f36be1cb1ba8ac2e31769c596913d48da
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=197721 bytes; lines=5036; FAIL=3; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1818850153, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1869488206, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 724639858, 0, 32; draw_string_vec4 %conc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 3907622
- `line_count`: 91948
- `sha256`: baefaaae12b4fdf8b2fbca4b6d45e6d3f9303863a8de7e821fb5722e72218722
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=3907622 bytes; lines=91948; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63919
- `line_count`: 1586
- `sha256`: e9d01bb1c90f87298463c102e763d4b8e1021a49f8cc17fc78801c6c5149ba05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63919 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 29365
- `line_count`: 688
- `sha256`: dfc34b086efa9cd968377db7c229d440d76551706a87fb98cccdb0eb8e01edba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 18, "PASS": 2}
- `summary`: vvp evidence; size=29365 bytes; lines=688; FAIL=18; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99732
- `line_count`: 2437
- `sha256`: f65b1abf8aa5d52212736adc6b19fe4badfd2922386882d35309d40ff6d87624
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99732 bytes; lines=2437; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 298672
- `line_count`: 7125
- `sha256`: d4e38e19f1b38394d12d4f45fcb1d9eb123ffe59a4dd0e22a8a4029c47a319d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: vvp evidence; size=298672 bytes; lines=7125; markers=<none>; tail=0x55555ddc6c10; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 54952
- `line_count`: 1560
- `sha256`: 082cef5db5204fc764741bd1cac7c3af956c33c7b3f8c40e53209bd32fa5a256
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=54952 bytes; lines=1560; FAIL=4; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_m...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 161087
- `line_count`: 3948
- `sha256`: f684af7e9ba345c703c17f5a125ecf95c656e7c43847adbf6afb38445410e64b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=161087 bytes; lines=3948; FAIL=4; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 4851321
- `line_count`: 114691
- `sha256`: 04a125df52477674b420325e44df36f32eaeedf01eefc9e5dc5865356e108c91
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=4851321 bytes; lines=114691; FAIL=10; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36292
- `line_count`: 734
- `sha256`: c9e68575126f1b6b3bec97d2020f3457d53a19b9674dea991061e688110a81cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36292 bytes; lines=734; FAIL=2; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 17188
- `line_count`: 477
- `sha256`: a4402d3bf1f75b0c608975184e8b7057ce5b3b34b0a79605218e8f7ac4088cbc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=17188 bytes; lines=477; FAIL=2; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65348
- `line_count`: 1744
- `sha256`: 6ee84ac523b82a6ba56d7c93f11c4859cb6970ac30370033f4894eb5a39e6052
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65348 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180922
- `line_count`: 4650
- `sha256`: e5e991e44693810642fc8ab3971fb6329f39a3fc6d4e5cce25664252df6781a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180922 bytes; lines=4650; FAIL=3; PASS=1; tail=a1d0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x555584dea4a0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x555584dc8df0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x555584d99be0_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x555584d0eb60; %join; %free...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300329
- `line_count`: 8071
- `sha256`: 1ebc485beceffbfdb2147996332e458e948786162f5e5fde21bb703749edacbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300329 bytes; lines=8071; FAIL=4; PASS=1; tail=ushi/vec4 0, 0, 1; %store/vec4 v0x555570761740_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x555570761e70_0, 0, 1; %delay 1, 0; %alloc S_0x5555707602e0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25432
- `line_count`: 678
- `sha256`: 8164627a2f944fb2fe63dd97c9466ddf00c9f0b9f24f6b4f8ca27c0bb64af4c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25432 bytes; lines=678; FAIL=6; PASS=2; tail=#! /home/lyg/PA/ysyx-workbench/oss-cad-suite/bin/vvp :ivl_version "14.0 (devel)" "(s20260301-263-ge02a0bc2e-dirty)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/home/lyg/PA/ysyx-workbench/oss-cad-suite/lib/ivl/system.vpi"; :vpi_mo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 453
- `line_count`: 5
- `sha256`: edeaf8436ff6eebfa436a76c18e5a3b6cf10da7fd81849bb1c4b088f816dfd08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=453 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-win...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: a31d505b4cf42549243da78dc929df247c4e0a5576ecba4a8f0fe9317252ddd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fe...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3583
- `line_count`: 28
- `sha256`: 0dab0b85b92a30d61e018a337e4aea97affd534a9f35419e7dd15f456fdaf3b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3583 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: f66847b543d0ac547c0788766ab5ee96f13b4d8388a37c2574406960bf01f5f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: f12711fe60994f915fb290401ea4f6302453b58c47322e5abf278d8e57a7cf35
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3362
- `line_count`: 28
- `sha256`: c60870da744d7574d91b941f394d0e9980b920c13b0148aa327a55251aa7b3ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3362 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: f558a821c416776ae423c26e78066b29e0c08c96e0e42e8b0c2eadd57e5322d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 480
- `line_count`: 5
- `sha256`: 94de2e11df814c635d3d55a0e954d9e0cf137295e1f26b95d67c3611ee6ffb21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=480 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 624
- `line_count`: 5
- `sha256`: 0c16f24f9621cff3c149c15c4c07ce41d8bb5b53a4091cf2ab7dbe2f163f8661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=624 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: 9b6a08592ab980b389b7691810a1acbdd5e62b1fb87cbc85f9a91e6f30db9c80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 40ec6708dbf3c93e64334bc4fe27aaaa6f6a19f0d13d7fa9a0a4a3251616af54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-re...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 576
- `line_count`: 5
- `sha256`: 5922caeb942bd076a6af28d14ee9e8521d41c155bc5761a10fe75036b70debc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=576 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-win...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 26080e65edd594e4083a0ecd0be09bb96ad87bd58910ff32fc07760fa1906edb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: 80b5605b3d0f0afb03caaeb7938eca18a5474ff482b63e454d75b73c724990a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14084
- `line_count`: 85
- `sha256`: 71f5aeb54a0706abcab5f4fd4dda57abb3bbbcb6cd2c57b76838c6d2ca32101a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14084 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 13760
- `line_count`: 83
- `sha256`: 40c884f697c1fb04aa240f517ad096d165843a7ca10b7115f0d1dcd2a742ff44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13760 bytes; lines=83; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: a82b02a977b20b81dca9e23050da21585be8ea920a60bfdc907f2dcb503b6c7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: 8c50665fac4c510fe4e831c4fd225089bf870918860f376c4aa153343136227a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 534
- `line_count`: 5
- `sha256`: 273f855807a9acbeb9a49a93ed5f9a2dbd8249f30b39a855993ffe8c36f0fc9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=534 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 961
- `line_count`: 9
- `sha256`: 81db3c4229e3393b3a86da1cc3ea89ad76dd9db5db27602858dd0ee2bdc8fc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=961 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 916
- `line_count`: 9
- `sha256`: 23db7ddf57723a3f71fc3ba55c96843bcb4ec2c1e16b74c03e1db6766b70523f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=916 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 699
- `line_count`: 5
- `sha256`: 1da9d945f74ddde299e23da71c306c74c7b43b0fce93b4c3e253b7bf36b86bd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=699 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 971
- `line_count`: 9
- `sha256`: fdbc89e0415584a714bfb9cf8a8802ffc56d3673b1a95173e5dc2b06f5103a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=971 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 5
- `sha256`: 064a6de89a888fe56878eccbb4a983070f8972f3c4ef74b4f646eff52e3e5f44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=571 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 656
- `line_count`: 6
- `sha256`: a041ca60cb09d504645cbbf6d4f934ae6e5c96bedff05106111f45963d7a3c01
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=656 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: dbed9dd928d50ea6d84b03ba255d51d29c71b3399fc1102eb7b983acb2b0bb00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 874
- `line_count`: 9
- `sha256`: 909555a645f0f8d45065473d5e1030b30eda9bb8a5278768e18dd67f9f44cd0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=874 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 939
- `line_count`: 9
- `sha256`: a7a6819558c169b05814f085475a27fb59db7e4e113cca278b9c4e85d9066c0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=939 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 926
- `line_count`: 9
- `sha256`: d23529d028621c68d5d7327601907a794698909c412ce7f2060848127ae8950c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=926 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16628
- `line_count`: 74
- `sha256`: 53a59a646d1bea790be6cbf659fdece01f5acf5d57f4ba4e18719ec58e10cdaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16628 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 604
- `line_count`: 5
- `sha256`: 35e15f277e71755bec581abfdbff64b8fd7a3d98f8604880557aa126d6f357c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=604 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 5
- `sha256`: bf96f9f2fa9935273720cdf93daff13b718404619bfc75a7fd5a39ce37f7ace2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 682
- `line_count`: 5
- `sha256`: 8dea7fbe8b0a428a6358ce6c9665bfab90ab0c0954e7ad22e6e1f14f18bd9a17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=682 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 612
- `line_count`: 5
- `sha256`: 8f4fb5b7c9dfe4bc018cc37760fc2efca6c568a8139e74c1c244dbf7b4cb7194
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=612 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 5
- `sha256`: e4460847a5d9de7a6b9b2fd34999a6774690613695e383e2fc7b74d602b0a9da
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=606 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 5
- `sha256`: b17245f97713fe77eafb734771ff98dfc0817ae3e0583ba11f3f474cd2f4eb43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=606 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8453
- `line_count`: 59
- `sha256`: d34bcb47e59cacebb73b4224b4aef3647c435513d341030e7e575c462952a953
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8453 bytes; lines=59; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89827
- `line_count`: 717
- `sha256`: 35cbea7be92533531cabf195fa8a872d7a3a284dd85314f485c90be24204ba02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89827 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86570
- `line_count`: 650
- `sha256`: 6bdb6c1794f16939cccf6885d7cc4fc1f2b198ab2b1eb89aa349cc80abd18394
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86570 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86541
- `line_count`: 650
- `sha256`: e4a3ba8401f752a2c35d7f40258492c57507de94dab2623fb56dfe59bd8fdb74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86541 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89505
- `line_count`: 673
- `sha256`: 45e30c7c8e052b40da93824e7ae1e7dbf0c64922543bae61fea91f98effc0ac3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89505 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 565
- `line_count`: 5
- `sha256`: c117ddd4d6d2ac0787c35dec4801e553b247aaec7e92ba287a65ea2695d24d03
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=565 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 663
- `line_count`: 5
- `sha256`: a0e8e448e362634e105dce28d22dd7021b69aae0b1f24a12e5878d12f903a88a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=663 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 717
- `line_count`: 5
- `sha256`: c8af8119d6b613884b54e2b8f2914fb04835d199feb48cd0b37f711999248f77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=717 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 702
- `line_count`: 5
- `sha256`: 4eaf2f74f50c99846e3ff5bb33626fff99adffd45ce77fa277043982370ffad5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=702 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 640
- `line_count`: 5
- `sha256`: 45d443ce5eb48f2a2c09ade8e96657c64220690ebee45ad860adb351755b1ede
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=640 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 559
- `line_count`: 5
- `sha256`: 05afdda5f2cdff9e13a2e28939d84f18815c2661db888497a4b8ed993a17bb0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=559 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 581
- `line_count`: 5
- `sha256`: 63bf7e11393b4a2bb01329b146381920a12d06e98e7751d615bae57ef3f64e5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=581 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 735
- `line_count`: 6
- `sha256`: 48764797e7e6dbe58126c1951f800ef53a1955bdf2842a91dbfc160ef4db6527
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=735 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87906
- `line_count`: 664
- `sha256`: bdbc492e8b080e2d20898bacda53d4ecc897f996e83149de0bb36bc347da8184
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87906 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 636
- `line_count`: 5
- `sha256`: ae1f3596c9796cdb233eb2e4902f0c02e6e6de20310cfcdb83ffc64ca670a815
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=636 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 559
- `line_count`: 5
- `sha256`: f6578f2265b80e9ab778114c7cdc360fd7382e990cc314ae446b6dbebb8aa982
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=559 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 16638
- `line_count`: 74
- `sha256`: 71f83ff87b2ffc0e88a8cebf7c871129bb6c559c99c5ef793305c1b427bd87e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16638 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 535
- `line_count`: 5
- `sha256`: 4a84aa8d427615335dfed5926d392c6a6e4d981e646b05ce24750db80b7ce04e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=535 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 552
- `line_count`: 5
- `sha256`: 27dda0c35ef390a843aaaf2f3f7a0d2a5d0019075d33e64550c780e910cc7125
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=552 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 546
- `line_count`: 5
- `sha256`: 8bd82662fe5eb876252fba46e3dede0d34b65f639d1b531eead3a59143e59fa5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=546 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 9f5c5470135eb6c6ee53e17bf8812e198e6045cf2aa38407c68fdb1ee2225602
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3751
- `line_count`: 36
- `sha256`: 21c56e4947e96941d710402147a4e750f1662edb27736d622c234311f5337336
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3751 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 570
- `line_count`: 5
- `sha256`: 8df270dacd240aacff464b33ec94358a9047c1ed88e9867f0abdfac94842bde0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=570 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1514
- `line_count`: 13
- `sha256`: eface983f2ffb4f4c3d2545450f805b294a3ce51646bffa7837d773b99db9f09
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1514 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 677
- `line_count`: 5
- `sha256`: c1fdd19fd1d3f587a84beef19ee2d76ccb0f485127ff6a4c4210c6697d103f8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=677 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1084
- `line_count`: 12
- `sha256`: 63dbf58a1f431aad201b692673abd3209bbf3ad75801f8b4d751dd3c85bed82d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1084 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: c73a85059343df6d33312d6fd379cbb037dddb3aa7d6e8574f506d6b44c00906
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 527
- `line_count`: 5
- `sha256`: c28cb568b896f4f16c2048e1078bd718f14cb644ad245f27cd4722fb270a2493
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=527 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: 1a62f53aa52cd4963c980a295501a6a0781ca63edda5ed075263018427c8ba47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv6...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 577
- `line_count`: 5
- `sha256`: d42bf9b0aca980d231749cc8d4c97af3386212068aad1cf7aaac575bab220bc8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=577 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 985
- `line_count`: 10
- `sha256`: 85303847777feb0b8619c8745fe62850ed599664d64a253be7609c619723f4d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=985 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 897
- `line_count`: 7
- `sha256`: fadddbae4343b4048ef1b735c8912b2381b1e3b3cc69c39780c7a0e3d468c482
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=897 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 559
- `line_count`: 5
- `sha256`: 20f470e281d3cfdc0145c3ad01f08673522ca1c23f08810e808e124751a4d2db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=559 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 5
- `sha256`: 55fa3803207ad303109b5186922999c46b5451c4c4b1f8a90400c0bd8eacd879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=571 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3615
- `line_count`: 32
- `sha256`: aadfb405c2da738283d9c5b08e3f7cd145ef58601f0c9b82867aa373c47983ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3615 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14878
- `line_count`: 99
- `sha256`: 99a998b278ff760c4a3c75a45511a955eb126e926ccaa8593b0f8e5c26540f54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14878 bytes; lines=99; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7924
- `line_count`: 62
- `sha256`: cc59f33f51b0b08f6dac369fc41da3aaa594a9748d7af02220055714b08b2880
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7924 bytes; lines=62; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52231
- `line_count`: 392
- `sha256`: d253e3293ce98ff0d45d9fdc550792828f73867f7aec04fa0ccd05083bc766ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52231 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1029
- `line_count`: 8
- `sha256`: ef9c85251ade2cd69e53b797394ff48190a63dae99950b55bca552d87daa23ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1029 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 527
- `line_count`: 5
- `sha256`: c197afedfbb350856e5498d2059495ef894bd514b02839f762c11dfc0fc4bd26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=527 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1169
- `line_count`: 11
- `sha256`: dd28cfc0091a9b01f1da8b628d66febb452059cab1960a303dd320c9c0929ef9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1169 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 611
- `line_count`: 5
- `sha256`: 6b354e42bda123916ce288824a3ba421e8565de6d366c1b26009a2169f32fe95
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=611 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 959
- `line_count`: 10
- `sha256`: e99cd9dc9ac45f2d00480e7a5e7a9cefcbed734595f73a7b319995d5117a827f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=959 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 935
- `line_count`: 9
- `sha256`: 81ca53c1b2d3216284cae0ee678ac01f56449289f9e5e62b33ccedbcbf89c869
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=935 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 804
- `line_count`: 6
- `sha256`: 5909d22b8d391d38dae31e30e4f2bb74385370a43bb5a63af82d7d7fecbc7a80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=804 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 541
- `line_count`: 5
- `sha256`: f30b5acc7a6eb551051e8958fb431f264953660fe06ff9c39de4c611872bb1b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=541 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 16614
- `line_count`: 74
- `sha256`: 0cbcdf3dd5b9fba9a1703f8261471ad9639faed9b408292f62c3027ba435ce82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16614 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 547
- `line_count`: 5
- `sha256`: 869db574c234fcf2f5562677cf639a5b63b75a54713137556aec78fe7f1027a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=547 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 553
- `line_count`: 5
- `sha256`: ad29f52d5bd1d63f43f8a4c88af8e36dd380f0b2f4915e96cd6a75e1ac0daaeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=553 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: a7afe565093e93192473e16b98dda4149454545872c386ede5cc3284d3907e85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 817
- `line_count`: 8
- `sha256`: d6c4bc7bf8e88dcee1ac1f0469d5ec461c891b44ee48bd8f4fbba85563929985
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=817 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 917
- `line_count`: 9
- `sha256`: 6faa56fbc16899d882f738486ffba4655f8230efe999e7dfe235d4175beee9cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=917 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 1050
- `line_count`: 9
- `sha256`: 98c147cc6d905a2d33223ac067a42bc1ec5e37f3ca7aabbc118146ac4baf9dd4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1050 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155144
- `line_count`: 1109
- `sha256`: 57d6e5a7278109f6de0a09a1f53629f31e337589266eb089bd2adeac059ab2d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155144 bytes; lines=1109; PASS=2; tail=ll 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensi...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: 97292e8856c65470abd0da3c9b3833a6947aa203f879d17773e22171fc39b75e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 632
- `line_count`: 5
- `sha256`: 26fcc1a3e72080187549a572a0ba171c6d60ef4010443e14607221167e5ad630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=632 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: a43e1147671ab420310705a89d1d396baa831922a0c7e6cc2538236f1baada88
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17645
- `line_count`: 134
- `sha256`: b46e390fd4f4c807223cf3d07494e96eec0dd8a3e3cd5d806cffd2b02454185f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17645 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 5
- `sha256`: 26ff3c44db2ac980438e8f8a924b1632440a54a43caa71e4cb8010a97ef57e56
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=456 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-w...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: 0cb291524489e4f7e4d7633b2c98e27b955ce20db9ce6a91828ce121571d1f81
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-win...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results/summary.txt

- `kind`: txt
- `size_bytes`: 3222
- `line_count`: 105
- `sha256`: 5e996901b9f2dda6eadd082a22d54f82281265587720111f73f5989e12c534cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 192}
- `summary`: txt evidence; size=3222 bytes; lines=105; PASS=192; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/module-current/results - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pi...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/accept-without-read/audit.log

- `kind`: log
- `size_bytes`: 174
- `line_count`: 2
- `sha256`: 93753320c5bc2dad7f7156667d66016e4b64fe7157446e114a2ceaf8fbbc44a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=174 bytes; lines=2; PASS=4; tail=[T3J-NEGATIVE-LOG-CHECK] PASS marker=[FPC-ACCEPT-REQUIRES-READ] make_rc=2 inner_pass=1 result_fail=1 [T3J-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED forbidden=RED

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/accept-without-read/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126409
- `line_count`: 3165
- `sha256`: 63c9e55c6e71451e27b0e86e9cc6bd9199444b1dc6c387fd107b7b93b1f258c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126409 bytes; lines=3165; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/accept-without-read/make-console.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 3
- `sha256`: f806700701020d2329b9e9abd8a39f66f1e3b1f3c5a3b9e1a154a7d25f0fc1b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=374 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:262: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/accept-without-read/result/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/accept-without-read/result/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 1071
- `line_count`: 8
- `sha256`: d1275c80eeb4e72bdeb955c84eb79c90f543cf3e7215160aac1783f8724a920a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=1071 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_NEGATIVE_FPC_ACCEPT_WITHOUT_READ -s tb_ooo_fetch_packet_cache -o /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/accept-without-read/status.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 8
- `sha256`: 6046480cbe71574e253805d57d2e2718a067faf355a1f8bcbfdbecb9c551745b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=246 bytes; lines=8; PASS=4; tail=case=accept-without-read define=OOO_NEGATIVE_FPC_ACCEPT_WITHOUT_READ expected_marker=[FPC-ACCEPT-REQUIRES-READ] forbidden_marker=[CONTRACT-FPC-1RW] make_rc=2 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_forbidden_selftest=PASS

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/read-write-conflict/audit.log

- `kind`: log
- `size_bytes`: 166
- `line_count`: 2
- `sha256`: 528ff6b3f5383431e10a1b012e4a4e39e069263d20a843a2033bf309dd0fd02b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=166 bytes; lines=2; PASS=4; tail=[T3J-NEGATIVE-LOG-CHECK] PASS marker=[CONTRACT-FPC-1RW] make_rc=2 inner_pass=1 result_fail=1 [T3J-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED forbidden=RED

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/read-write-conflict/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126607
- `line_count`: 3171
- `sha256`: 7cd0c02e01de08c173886d9992ca4cdd061784b4e4803085f991e9d3eeb76a75
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126607 bytes; lines=3171; FAIL=4; PASS=1; tail=/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/read-write-conflict/make-console.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 3
- `sha256`: 929eee7bd87f4f50aaacf02068b87e21a0b0b81cbf58d13308b6a613273e2eb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=374 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:262: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/read-write-conflict/result/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/read-write-conflict/result/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 1098
- `line_count`: 8
- `sha256`: e8dd54d3aba6f3e17a1ca5feff7479990ced79b6cd6867f57862f2db1cfd2351
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=1098 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_NEGATIVE_FPC_READ_WRITE_CONFLICT -s tb_ooo_fetch_packet_cache -o /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-relative-outdir-check/read-write-conflict/status.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 8
- `sha256`: 422b95837792a58695c65d0928050d3df57bb977d8b731f72fa852f0ec4a50bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=246 bytes; lines=8; PASS=4; tail=case=read-write-conflict define=OOO_NEGATIVE_FPC_READ_WRITE_CONFLICT expected_marker=[CONTRACT-FPC-1RW] forbidden_marker=[FPC-ACCEPT-REQUIRES-READ] make_rc=2 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_forbidden_selftest=PASS

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-root-rerun/accept-without-read/make-console.log

- `kind`: log
- `size_bytes`: 335
- `line_count`: 3
- `sha256`: a75fb1c3ea6848f54963cbc2b5a0a542467d8173bad9f57c2560e3cff5da3b41
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=335 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:262: .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes-root-rerun/accept-without-read/result/logs/tb_ooo_fetch_packet_cache.log] Err...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/accept-without-read/audit.log

- `kind`: log
- `size_bytes`: 174
- `line_count`: 2
- `sha256`: 93753320c5bc2dad7f7156667d66016e4b64fe7157446e114a2ceaf8fbbc44a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=174 bytes; lines=2; PASS=4; tail=[T3J-NEGATIVE-LOG-CHECK] PASS marker=[FPC-ACCEPT-REQUIRES-READ] make_rc=2 inner_pass=1 result_fail=1 [T3J-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED forbidden=RED

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/accept-without-read/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126409
- `line_count`: 3165
- `sha256`: ca40657a656e58571cd7602490002287efd74d664659bed033acdd2bb5151431
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126409 bytes; lines=3165; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/accept-without-read/make-console.log

- `kind`: log
- `size_bytes`: 352
- `line_count`: 3
- `sha256`: 0553dd4965837e66690481d4a35dd46204b32146021746defb2bef3486621905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=352 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:262: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/accept-without-read/result/logs/tb_ooo_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/accept-without-read/result/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 1049
- `line_count`: 8
- `sha256`: 424f262b2360c49ffc18de8d895acb151f3d12b70b3d732d8017c11803ffaea0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=1049 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_NEGATIVE_FPC_ACCEPT_WITHOUT_READ -s tb_ooo_fetch_packet_cache -o /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/accept-without-read/status.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 8
- `sha256`: 6046480cbe71574e253805d57d2e2718a067faf355a1f8bcbfdbecb9c551745b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=246 bytes; lines=8; PASS=4; tail=case=accept-without-read define=OOO_NEGATIVE_FPC_ACCEPT_WITHOUT_READ expected_marker=[FPC-ACCEPT-REQUIRES-READ] forbidden_marker=[CONTRACT-FPC-1RW] make_rc=2 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_forbidden_selftest=PASS

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/read-write-conflict/audit.log

- `kind`: log
- `size_bytes`: 166
- `line_count`: 2
- `sha256`: 528ff6b3f5383431e10a1b012e4a4e39e069263d20a843a2033bf309dd0fd02b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=166 bytes; lines=2; PASS=4; tail=[T3J-NEGATIVE-LOG-CHECK] PASS marker=[CONTRACT-FPC-1RW] make_rc=2 inner_pass=1 result_fail=1 [T3J-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED forbidden=RED

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/read-write-conflict/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126607
- `line_count`: 3171
- `sha256`: 115f5790a1dfed71fe77ee386a7a18f2c8f33798087b135f7e4155f30a350aab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126607 bytes; lines=3171; FAIL=4; PASS=1; tail=/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/read-write-conflict/make-console.log

- `kind`: log
- `size_bytes`: 352
- `line_count`: 3
- `sha256`: 1959b5e34bd332c53e08c84441ac3bd23f84ed307ba930923ee306154d840ec2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=352 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:262: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/read-write-conflict/result/logs/tb_ooo_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/read-write-conflict/result/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 1076
- `line_count`: 8
- `sha256`: 38c9fbcb299ad644e10e193579d46394e99596ce0cd0ea2d3a084a7f93d14796
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=1076 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_NEGATIVE_FPC_READ_WRITE_CONFLICT -s tb_ooo_fetch_packet_cache -o /ho...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/negative-probes/read-write-conflict/status.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 8
- `sha256`: 422b95837792a58695c65d0928050d3df57bb977d8b731f72fa852f0ec4a50bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=246 bytes; lines=8; PASS=4; tail=case=read-write-conflict define=OOO_NEGATIVE_FPC_READ_WRITE_CONFLICT expected_marker=[CONTRACT-FPC-1RW] forbidden_marker=[FPC-ACCEPT-REQUIRES-READ] make_rc=2 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_forbidden_selftest=PASS

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-final/fresh-t3j.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: a92e4647beca177190ce139e1b8d2b5ee076384f0752d9a24c6229547856d558
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=fresh read_inputs=1 read_connections=1 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-final/old-t3i-expected-fresh-fail.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: e68d35123b1f8fdbf35fe2089478ed15dbe6ce578329735e6c12d22512491c21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=114 bytes; lines=1; FAIL=2; tail=[T3J-NETLIST-STRUCTURE] FAIL: fresh physical read-window ABI width/connectivity mismatch: inputs=0 connections=[]

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-final/old-t3i-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-final/old-t3i.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: 027d42db2c8df1cfc2b9f38c749be14832a27dc4a449aeeed7962af4b33584a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=old read_inputs=0 read_connections=0 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-fresh-t3j.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: a92e4647beca177190ce139e1b8d2b5ee076384f0752d9a24c6229547856d558
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=fresh read_inputs=1 read_connections=1 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-hardening-smoke/fresh-t3j.log

- `kind`: log
- `size_bytes`: 109
- `line_count`: 1
- `sha256`: a92e4647beca177190ce139e1b8d2b5ee076384f0752d9a24c6229547856d558
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=109 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=fresh read_inputs=1 read_connections=1 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-hardening-smoke/old-t3i-expected-fresh-fail.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: e68d35123b1f8fdbf35fe2089478ed15dbe6ce578329735e6c12d22512491c21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=114 bytes; lines=1; FAIL=2; tail=[T3J-NETLIST-STRUCTURE] FAIL: fresh physical read-window ABI width/connectivity mismatch: inputs=0 connections=[]

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-hardening-smoke/old-t3i-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-hardening-smoke/old-t3i.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: 027d42db2c8df1cfc2b9f38c749be14832a27dc4a449aeeed7962af4b33584a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=old read_inputs=0 read_connections=0 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-old-t3i-expected-fresh-fail-final.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: e68d35123b1f8fdbf35fe2089478ed15dbe6ce578329735e6c12d22512491c21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=114 bytes; lines=1; FAIL=2; tail=[T3J-NETLIST-STRUCTURE] FAIL: fresh physical read-window ABI width/connectivity mismatch: inputs=0 connections=[]

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-old-t3i-expected-fresh-fail.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: e68d35123b1f8fdbf35fe2089478ed15dbe6ce578329735e6c12d22512491c21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=114 bytes; lines=1; FAIL=2; tail=[T3J-NETLIST-STRUCTURE] FAIL: fresh physical read-window ABI width/connectivity mismatch: inputs=0 connections=[]

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-old-t3i-final.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: 027d42db2c8df1cfc2b9f38c749be14832a27dc4a449aeeed7962af4b33584a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=old read_inputs=0 read_connections=0 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-old-t3i-red-status-final.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-old-t3i-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/netlist-structure-old-t3i.log

- `kind`: log
- `size_bytes`: 107
- `line_count`: 1
- `sha256`: 027d42db2c8df1cfc2b9f38c749be14832a27dc4a449aeeed7962af4b33584a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=107 bytes; lines=1; PASS=2; tail=[T3J-NETLIST-STRUCTURE] PASS: expect=old read_inputs=0 read_connections=0 semantic_accept=fetch_req_fire_w

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/checker.log

- `kind`: log
- `size_bytes`: 129
- `line_count`: 1
- `sha256`: 1c59a9019580aa487dd5559c487100912fa888e4568858ae08f00c995c0ae812
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=129 bytes; lines=1; PASS=2; tail=[T3J-OPENSTA-FOCUSED] PASS: expect=fresh accept_to_en=absent address_residual=12/12 read_window_startpoints=state_q_0_6_8_only:3

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 276
- `line_count`: 6
- `sha256`: b3e60ad0d0b01ef15607c2b35b1025ac16433cb9edbee3721cbc2458f3b0a37b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=276 bytes; lines=6; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=2 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_42041_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: 331636be84f0c83798aae8fec8978e6ac0c2b57c237adb847aa730cad9904d1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=1 to_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: 3d17c35211aec68d7a6d1f5dbb7a42056b938dea8e007aecc4f624665257ae49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 242
- `line_count`: 5
- `sha256`: 576fecb45bd7c934a6e57b1b26d76803ff4dd2d07dbe63d6b4600b9552414381
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=242 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=fresh period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: aac85e1658a1a5aaa98941f43f15d37f2c7b27ef16d06cf6e90d4206c5d2f849
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=1 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5410
- `line_count`: 90
- `sha256`: 91896ab369df2bdd654763c7fc3c81a5eb9da21cfe417675bfbe6344179b063e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5410 bytes; lines=90; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6854
- `line_count`: 107
- `sha256`: c39e6d497b0487ea6ca5b7600aa95d3cd5228023d896208a3001c1cbdb0cf66f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6854 bytes; lines=107; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=NO_TIMING_PATH source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_co...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204076
- `line_count`: 1827
- `sha256`: 8edd2da1d04bdbbfcc4b68d17baf444a984df98527aa8b6940cfec36e01f33d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204076 bytes; lines=1827; markers=<none>; tail=nd/u_dispatch_backend/u_issue_queue/_28772_/Y (BUFX1P4H7L) 0.129 1.256 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_back...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 223
- `line_count`: 5
- `sha256`: bd211f6d60b96b33fa3c416403c590b6988e82c5102cc12236ed62f305a2d4d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=223 bytes; lines=5; markers=<none>; tail=source_label=read_window_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_read_en_i endpoint_count=1 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram/en_i

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-read-window-startpoints.txt

- `kind`: txt
- `size_bytes`: 1302
- `line_count`: 32
- `sha256`: 56659bdadb168f606d4ba4f38442d1a86d2c626ed2a47448dafb0cce2748ea9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=1302 bytes; lines=32; markers=<none>; tail=status=STARTPOINTS_PRESENT source_label=read_window_pins source_count=1 source.0.object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_read_en_i startpoint_count=3 startpoint.0.object=u_core/u_ooo_fetch_bridge/_7224_/CK startpoint.0.cell_count=1 star...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-final/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 1610
- `line_count`: 33
- `sha256`: 25bd64b9a8b035c4ca8fb9cfe1803824bbfa75cfe7122f73389d3e629b93b973
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=1610 bytes; lines=33; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/_7230_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_clock Path...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/checker.log

- `kind`: log
- `size_bytes`: 129
- `line_count`: 1
- `sha256`: 1c59a9019580aa487dd5559c487100912fa888e4568858ae08f00c995c0ae812
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=129 bytes; lines=1; PASS=2; tail=[T3J-OPENSTA-FOCUSED] PASS: expect=fresh accept_to_en=absent address_residual=12/12 read_window_startpoints=state_q_0_6_8_only:3

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 276
- `line_count`: 6
- `sha256`: b3e60ad0d0b01ef15607c2b35b1025ac16433cb9edbee3721cbc2458f3b0a37b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=276 bytes; lines=6; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=2 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_42041_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: 331636be84f0c83798aae8fec8978e6ac0c2b57c237adb847aa730cad9904d1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=1 to_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: 3d17c35211aec68d7a6d1f5dbb7a42056b938dea8e007aecc4f624665257ae49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 242
- `line_count`: 5
- `sha256`: 576fecb45bd7c934a6e57b1b26d76803ff4dd2d07dbe63d6b4600b9552414381
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=242 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=fresh period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: aac85e1658a1a5aaa98941f43f15d37f2c7b27ef16d06cf6e90d4206c5d2f849
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=1 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5410
- `line_count`: 90
- `sha256`: 91896ab369df2bdd654763c7fc3c81a5eb9da21cfe417675bfbe6344179b063e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5410 bytes; lines=90; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6854
- `line_count`: 107
- `sha256`: c39e6d497b0487ea6ca5b7600aa95d3cd5228023d896208a3001c1cbdb0cf66f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6854 bytes; lines=107; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=NO_TIMING_PATH source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_co...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204076
- `line_count`: 1827
- `sha256`: 8edd2da1d04bdbbfcc4b68d17baf444a984df98527aa8b6940cfec36e01f33d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204076 bytes; lines=1827; markers=<none>; tail=nd/u_dispatch_backend/u_issue_queue/_28772_/Y (BUFX1P4H7L) 0.129 1.256 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_back...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 223
- `line_count`: 5
- `sha256`: bd211f6d60b96b33fa3c416403c590b6988e82c5102cc12236ed62f305a2d4d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=223 bytes; lines=5; markers=<none>; tail=source_label=read_window_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_read_en_i endpoint_count=1 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram/en_i

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-read-window-startpoints.txt

- `kind`: txt
- `size_bytes`: 1302
- `line_count`: 32
- `sha256`: 56659bdadb168f606d4ba4f38442d1a86d2c626ed2a47448dafb0cce2748ea9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=1302 bytes; lines=32; markers=<none>; tail=status=STARTPOINTS_PRESENT source_label=read_window_pins source_count=1 source.0.object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_read_en_i startpoint_count=3 startpoint.0.object=u_core/u_ooo_fetch_bridge/_7224_/CK startpoint.0.cell_count=1 star...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j-hardening-smoke/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 1610
- `line_count`: 33
- `sha256`: 25bd64b9a8b035c4ca8fb9cfe1803824bbfa75cfe7122f73389d3e629b93b973
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=1610 bytes; lines=33; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/_7230_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_clock Path...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/checker.log

- `kind`: log
- `size_bytes`: 168
- `line_count`: 1
- `sha256`: 1bbefcf5d097fedc3ea7ce86b62729e63dcdac7e7cf208c5b55ccbba37695f8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=168 bytes; lines=1; FAIL=2; tail=[T3J-OPENSTA-FOCUSED] FAIL: read-window startpoint 0 is not a direct bridge state flop Q: pin=u_core/u_ooo_fetch_bridge/_7224_/CK cell=u_core/u_ooo_fetch_bridge/_7224_

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 276
- `line_count`: 6
- `sha256`: b3e60ad0d0b01ef15607c2b35b1025ac16433cb9edbee3721cbc2458f3b0a37b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=276 bytes; lines=6; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=2 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_42041_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: 331636be84f0c83798aae8fec8978e6ac0c2b57c237adb847aa730cad9904d1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=1 to_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: 3d17c35211aec68d7a6d1f5dbb7a42056b938dea8e007aecc4f624665257ae49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 242
- `line_count`: 5
- `sha256`: 576fecb45bd7c934a6e57b1b26d76803ff4dd2d07dbe63d6b4600b9552414381
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=242 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=fresh period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: aac85e1658a1a5aaa98941f43f15d37f2c7b27ef16d06cf6e90d4206c5d2f849
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=1 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5410
- `line_count`: 90
- `sha256`: 91896ab369df2bdd654763c7fc3c81a5eb9da21cfe417675bfbe6344179b063e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5410 bytes; lines=90; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6854
- `line_count`: 107
- `sha256`: c39e6d497b0487ea6ca5b7600aa95d3cd5228023d896208a3001c1cbdb0cf66f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6854 bytes; lines=107; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=NO_TIMING_PATH source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_co...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204076
- `line_count`: 1827
- `sha256`: 8edd2da1d04bdbbfcc4b68d17baf444a984df98527aa8b6940cfec36e01f33d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204076 bytes; lines=1827; markers=<none>; tail=nd/u_dispatch_backend/u_issue_queue/_28772_/Y (BUFX1P4H7L) 0.129 1.256 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_back...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 223
- `line_count`: 5
- `sha256`: bd211f6d60b96b33fa3c416403c590b6988e82c5102cc12236ed62f305a2d4d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=223 bytes; lines=5; markers=<none>; tail=source_label=read_window_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_read_en_i endpoint_count=1 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram/en_i

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-read-window-startpoints.txt

- `kind`: txt
- `size_bytes`: 798
- `line_count`: 20
- `sha256`: cc25f7c46b593722908ddb0afcc757de9afb34c453e3eb38aeeda2e5a68dc651
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=798 bytes; lines=20; markers=<none>; tail=status=STARTPOINTS_PRESENT source_label=read_window_pins source_count=1 source.0.object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_read_en_i startpoint_count=3 startpoint.0.object=u_core/u_ooo_fetch_bridge/_7224_/CK startpoint.0.cell_count=1 star...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-fresh-t3j/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 1610
- `line_count`: 33
- `sha256`: 25bd64b9a8b035c4ca8fb9cfe1803824bbfa75cfe7122f73389d3e629b93b973
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=1610 bytes; lines=33; markers=<none>; tail=Startpoint: u_core/u_ooo_fetch_bridge/_7230_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_clock Path...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/checker.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: f613cdc993dff80ab286ed1ab5d9a547368b67fb68d911827357142d5b794830
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=114 bytes; lines=1; PASS=2; tail=[T3J-OPENSTA-FOCUSED] PASS: expect=old accept_to_en=present address_residual=12/12 read_window_startpoints=absent

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 359
- `line_count`: 7
- `sha256`: dc4c4b82950d253324b9bad06cff449d0b8aefca8067e92f6f06d31fa50bcac9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=359 bytes; lines=7; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=3 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_40681_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 18267
- `line_count`: 158
- `sha256`: d61efa6e1adb7391e5796ef1773b42a30c77b764025d7f448ae75a56d7d85d58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=18267 bytes; lines=158; markers=<none>; tail=Startpoint: u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_ex0_stage/_155_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-trigge...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: ebf707cdc0ef74b22ed094326e6ec80ba165d5a15e4d07b86a111a164ab89f83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 5
- `sha256`: b8069169285e652e07146a998d6e58a8bd40b05e145a02bf86dec7d95d1f9e2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=246 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: b3021c0b7ebc46e2747feb26c5edd74ddf933e09450288490ad8aa414aa5d4c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=0 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5346
- `line_count`: 89
- `sha256`: da8c6f96109bf7eef80c2c6b64dc4667b7974c6b2946f323b2d83c4255cbf798
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5346 bytes; lines=89; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6489
- `line_count`: 96
- `sha256`: ea78e670b6dfc5dc53af77449a90b24fcad4f18704fb4fa2a7b13229bdbca89f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6489 bytes; lines=96; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=PATHS_PRESENT source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_cou...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204168
- `line_count`: 1828
- `sha256`: fe28cb27d6f5e4d1408331f14ffc97b1b0e41e90b1c529a5f89cbde0a7d2148a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204168 bytes; lines=1828; markers=<none>; tail=execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28780_/Y (A...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-read-window-startpoints.txt

- `kind`: txt
- `size_bytes`: 83
- `line_count`: 4
- `sha256`: 5390f2345096a920623c937a873de1d79381e13c8064de5aa9762e523c148fce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=83 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_label=read_window_pins source_count=0 startpoint_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-final/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: db5f04b3bff99399d2256fcad0110ebd8ec20b4c965cca40f955817cd373da28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/checker.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: f613cdc993dff80ab286ed1ab5d9a547368b67fb68d911827357142d5b794830
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=114 bytes; lines=1; PASS=2; tail=[T3J-OPENSTA-FOCUSED] PASS: expect=old accept_to_en=present address_residual=12/12 read_window_startpoints=absent

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 359
- `line_count`: 7
- `sha256`: dc4c4b82950d253324b9bad06cff449d0b8aefca8067e92f6f06d31fa50bcac9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=359 bytes; lines=7; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=3 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_40681_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 18267
- `line_count`: 158
- `sha256`: d61efa6e1adb7391e5796ef1773b42a30c77b764025d7f448ae75a56d7d85d58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=18267 bytes; lines=158; markers=<none>; tail=Startpoint: u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_ex0_stage/_155_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-trigge...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: ebf707cdc0ef74b22ed094326e6ec80ba165d5a15e4d07b86a111a164ab89f83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 5
- `sha256`: b8069169285e652e07146a998d6e58a8bd40b05e145a02bf86dec7d95d1f9e2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=246 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: b3021c0b7ebc46e2747feb26c5edd74ddf933e09450288490ad8aa414aa5d4c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=0 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5346
- `line_count`: 89
- `sha256`: da8c6f96109bf7eef80c2c6b64dc4667b7974c6b2946f323b2d83c4255cbf798
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5346 bytes; lines=89; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6489
- `line_count`: 96
- `sha256`: ea78e670b6dfc5dc53af77449a90b24fcad4f18704fb4fa2a7b13229bdbca89f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6489 bytes; lines=96; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=PATHS_PRESENT source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_cou...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204168
- `line_count`: 1828
- `sha256`: fe28cb27d6f5e4d1408331f14ffc97b1b0e41e90b1c529a5f89cbde0a7d2148a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204168 bytes; lines=1828; markers=<none>; tail=execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28780_/Y (A...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-read-window-startpoints.txt

- `kind`: txt
- `size_bytes`: 83
- `line_count`: 4
- `sha256`: 5390f2345096a920623c937a873de1d79381e13c8064de5aa9762e523c148fce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=83 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_label=read_window_pins source_count=0 startpoint_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-hardening-smoke/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: db5f04b3bff99399d2256fcad0110ebd8ec20b4c965cca40f955817cd373da28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/checker.log

- `kind`: log
- `size_bytes`: 83
- `line_count`: 1
- `sha256`: d32ac6b9ffa7bcef9a7b499339154fab023c5fbceab034f206fc3721cc30d7be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=83 bytes; lines=1; PASS=2; tail=[T3J-OPENSTA-FOCUSED] PASS: expect=old accept_to_en=present address_residual=12/12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 359
- `line_count`: 7
- `sha256`: dc4c4b82950d253324b9bad06cff449d0b8aefca8067e92f6f06d31fa50bcac9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=359 bytes; lines=7; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=3 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_40681_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 18267
- `line_count`: 158
- `sha256`: d61efa6e1adb7391e5796ef1773b42a30c77b764025d7f448ae75a56d7d85d58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=18267 bytes; lines=158; markers=<none>; tail=Startpoint: u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_ex0_stage/_155_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-trigge...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: ebf707cdc0ef74b22ed094326e6ec80ba165d5a15e4d07b86a111a164ab89f83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 5
- `sha256`: b8069169285e652e07146a998d6e58a8bd40b05e145a02bf86dec7d95d1f9e2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=246 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: b3021c0b7ebc46e2747feb26c5edd74ddf933e09450288490ad8aa414aa5d4c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=0 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5346
- `line_count`: 89
- `sha256`: da8c6f96109bf7eef80c2c6b64dc4667b7974c6b2946f323b2d83c4255cbf798
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5346 bytes; lines=89; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6489
- `line_count`: 96
- `sha256`: ea78e670b6dfc5dc53af77449a90b24fcad4f18704fb4fa2a7b13229bdbca89f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6489 bytes; lines=96; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=PATHS_PRESENT source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_cou...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204168
- `line_count`: 1828
- `sha256`: fe28cb27d6f5e4d1408331f14ffc97b1b0e41e90b1c529a5f89cbde0a7d2148a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204168 bytes; lines=1828; markers=<none>; tail=execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28780_/Y (A...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i-smoke/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: db5f04b3bff99399d2256fcad0110ebd8ec20b4c965cca40f955817cd373da28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/checker.log

- `kind`: log
- `size_bytes`: 114
- `line_count`: 1
- `sha256`: f613cdc993dff80ab286ed1ab5d9a547368b67fb68d911827357142d5b794830
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=114 bytes; lines=1; PASS=2; tail=[T3J-OPENSTA-FOCUSED] PASS: expect=old accept_to_en=present address_residual=12/12 read_window_startpoints=absent

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-accept-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 359
- `line_count`: 7
- `sha256`: dc4c4b82950d253324b9bad06cff449d0b8aefca8067e92f6f06d31fa50bcac9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=359 bytes; lines=7; markers=<none>; tail=source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i endpoint_count=3 endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/_40681_/E endpoint_object=u_core/u_ooo_fetch_bridge/u_fetch_pack...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-accept-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 18267
- `line_count`: 158
- `sha256`: d61efa6e1adb7391e5796ef1773b42a30c77b764025d7f448ae75a56d7d85d58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=18267 bytes; lines=158; markers=<none>; tail=Startpoint: u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_ex0_stage/_155_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-trigge...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-address-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 10783
- `line_count`: 144
- `sha256`: ebf707cdc0ef74b22ed094326e6ec80ba165d5a15e4d07b86a111a164ab89f83
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=10783 bytes; lines=144; markers=<none>; tail=source_label=lookup_pc_pins source_count=64 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_0_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_pc_i_1_ source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-focused-complete.txt

- `kind`: txt
- `size_bytes`: 246
- `line_count`: 5
- `sha256`: b8069169285e652e07146a998d6e58a8bd40b05e145a02bf86dec7d95d1f9e2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=246 bytes; lines=5; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3i-drain-retire-redundancy/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-focused-counts.txt

- `kind`: txt
- `size_bytes`: 133
- `line_count`: 8
- `sha256`: b3021c0b7ebc46e2747feb26c5edd74ddf933e09450288490ad8aa414aa5d4c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=133 bytes; lines=8; markers=<none>; tail=bridge_cells=1 fpc_cells=1 payload_cells=1 accept_pins=1 read_window_pins=0 lookup_pc_pins=64 payload_en_pins=1 payload_addr_pins=12

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-focused-objects.txt

- `kind`: txt
- `size_bytes`: 5346
- `line_count`: 89
- `sha256`: da8c6f96109bf7eef80c2c6b64dc4667b7974c6b2946f323b2d83c4255cbf798
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=5346 bytes; lines=89; markers=<none>; tail=[bridge_cells] count=1 u_core/u_ooo_fetch_bridge [fpc_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache [payload_cells] count=1 u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram [accept_pins] count=1 u_core/u_ooo_fetch_bridge/u_fetch...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-focused-queries.txt

- `kind`: txt
- `size_bytes`: 6489
- `line_count`: 96
- `sha256`: ea78e670b6dfc5dc53af77449a90b24fcad4f18704fb4fa2a7b13229bdbca89f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=6489 bytes; lines=96; markers=<none>; tail=[accept_to_payload_en] report=opensta-t3j-accept-to-payload-en.rpt selector=through status=PATHS_PRESENT source_label=accept_pins source_count=1 source_object=u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/lookup_en_i target_label=payload_en_pins target_cou...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-pc-to-payload-addr.rpt

- `kind`: rpt
- `size_bytes`: 204168
- `line_count`: 1828
- `sha256`: fe28cb27d6f5e4d1408331f14ffc97b1b0e41e90b1c529a5f89cbde0a7d2148a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=204168 bytes; lines=1828; markers=<none>; tail=execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28779_/Y (AO222X0P5H7L) 0.067 1.323 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_issue_queue/_28780_/Y (A...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-read-window-fanout-endpoints.txt

- `kind`: txt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-read-window-startpoints.txt

- `kind`: txt
- `size_bytes`: 83
- `line_count`: 4
- `sha256`: 5390f2345096a920623c937a873de1d79381e13c8064de5aa9762e523c148fce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=83 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_label=read_window_pins source_count=0 startpoint_count=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-focused-old-t3i/opensta-t3j-read-window-to-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 49
- `line_count`: 1
- `sha256`: db5f04b3bff99399d2256fcad0110ebd8ec20b4c965cca40f955817cd373da28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=49 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/checker.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: ca93b3c25db2c6493d61e327adf2a1bae1d3a56202fe5caeecfbe19ac686ce9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=[T3J-GLOBAL-STA] PASS: loops=0 paths=40 WNS=-8.840ns TNS=-199477.67ns power=0.117W target_met=False

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 95684
- `line_count`: 4030
- `sha256`: 9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=95684 bytes; lines=4030; markers=<none>; tail=_32_ psram_axi_araddr_o_33_ psram_axi_araddr_o_34_ psram_axi_araddr_o_35_ psram_axi_araddr_o_36_ psram_axi_araddr_o_37_ psram_axi_araddr_o_38_ psram_axi_araddr_o_39_ psram_axi_araddr_o_3_ psram_axi_araddr_o_40_ psram_axi_araddr_o_41_ psram_axi_araddr_o_42_...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/opensta-current-complete.txt

- `kind`: txt
- `size_bytes`: 229
- `line_count`: 4
- `sha256`: dd95927e741c334284a3aff5e0d31df23dde7d7eac779f6fb8efe201413890fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=229 bytes; lines=4; markers=<none>; tail=status=COMPLETE period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 84dfc14d94b61f2863deeb22166087af3771236893bf74719d698f938578fc71
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.53e-02 9.28e-05 1.81e-04 9.55e-02 81.7% Combinational 5.88e-03 7.20e-03 4.65e-04 1.35e-02 11.6% Clock 2.80e-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 825393
- `line_count`: 7242
- `sha256`: d300cce37aeda0ecceb6b6e81f8f4b71eaf3685951fd9c5d5669d910725c9bf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=825393 bytes; lines=7242; markers=<none>; tail=mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077 11.776 ^ u_core/u_ooo_core/u_con...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/summary.json

- `kind`: json
- `size_bytes`: 615
- `line_count`: 25
- `sha256`: c69d16e96e0cab89f968c3fd965340ab28103948b9ffc41a9e0eda102584696c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: json evidence; size=615 bytes; lines=25; markers=<none>; tail={ "combinational_loops": 0, "endpoint_classes": { "csr_file": 0, "fetch_outstanding": 0, "fetch_payload_sram": 0, "other": 0, "pending_trap_exit": 40 }, "fetch_payload_addr_path_blocks": 0, "fetch_payload_en_path_blocks": 0, "path_count": 40, "period_ns": 5...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/target-200mhz-status.txt

- `kind`: txt
- `size_bytes`: 17
- `line_count`: 2
- `sha256`: 04b8e04127b2690b1123238f807e5068adc012c281120da4cb85f5489ba017b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=17 bytes; lines=2; markers=<none>; tail=expect=miss rc=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-final/target-200mhz.log

- `kind`: log
- `size_bytes`: 64
- `line_count`: 1
- `sha256`: 37e0890972823d652a622cf6759f82694febba2969112a98b114a8d17728f0b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=64 bytes; lines=1; markers=<none>; tail=[T3J-200MHZ-TARGET] EXPECTED-RED: WNS=-8.840ns TNS=-199477.67ns

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/checker.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: ca93b3c25db2c6493d61e327adf2a1bae1d3a56202fe5caeecfbe19ac686ce9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=[T3J-GLOBAL-STA] PASS: loops=0 paths=40 WNS=-8.840ns TNS=-199477.67ns power=0.117W target_met=False

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 95684
- `line_count`: 4030
- `sha256`: 9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=95684 bytes; lines=4030; markers=<none>; tail=_32_ psram_axi_araddr_o_33_ psram_axi_araddr_o_34_ psram_axi_araddr_o_35_ psram_axi_araddr_o_36_ psram_axi_araddr_o_37_ psram_axi_araddr_o_38_ psram_axi_araddr_o_39_ psram_axi_araddr_o_3_ psram_axi_araddr_o_40_ psram_axi_araddr_o_41_ psram_axi_araddr_o_42_...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/opensta-current-complete.txt

- `kind`: txt
- `size_bytes`: 229
- `line_count`: 4
- `sha256`: dd95927e741c334284a3aff5e0d31df23dde7d7eac779f6fb8efe201413890fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=229 bytes; lines=4; markers=<none>; tail=status=COMPLETE period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 84dfc14d94b61f2863deeb22166087af3771236893bf74719d698f938578fc71
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.53e-02 9.28e-05 1.81e-04 9.55e-02 81.7% Combinational 5.88e-03 7.20e-03 4.65e-04 1.35e-02 11.6% Clock 2.80e-...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 825393
- `line_count`: 7242
- `sha256`: d300cce37aeda0ecceb6b6e81f8f4b71eaf3685951fd9c5d5669d910725c9bf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: rpt evidence; size=825393 bytes; lines=7242; markers=<none>; tail=mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077 11.776 ^ u_core/u_ooo_core/u_con...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/summary.json

- `kind`: json
- `size_bytes`: 615
- `line_count`: 25
- `sha256`: c69d16e96e0cab89f968c3fd965340ab28103948b9ffc41a9e0eda102584696c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: json evidence; size=615 bytes; lines=25; markers=<none>; tail={ "combinational_loops": 0, "endpoint_classes": { "csr_file": 0, "fetch_outstanding": 0, "fetch_payload_sram": 0, "other": 0, "pending_trap_exit": 40 }, "fetch_payload_addr_path_blocks": 0, "fetch_payload_en_path_blocks": 0, "path_count": 40, "period_ns": 5...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/target-200mhz-status.txt

- `kind`: txt
- `size_bytes`: 17
- `line_count`: 2
- `sha256`: 04b8e04127b2690b1123238f807e5068adc012c281120da4cb85f5489ba017b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=17 bytes; lines=2; markers=<none>; tail=expect=miss rc=1

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/opensta-fresh-t3j-hardening-smoke/target-200mhz.log

- `kind`: log
- `size_bytes`: 64
- `line_count`: 1
- `sha256`: 37e0890972823d652a622cf6759f82694febba2969112a98b114a8d17728f0b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=64 bytes; lines=1; markers=<none>; tail=[T3J-200MHZ-TARGET] EXPECTED-RED: WNS=-8.840ns TNS=-199477.67ns

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis-audit-old-t3i-smoke.json

- `kind`: json
- `size_bytes`: 562
- `line_count`: 19
- `sha256`: 4c8b03232c3d88b798a6f0741ec6099b89d95eadfacfbdf5571394e5d4624414
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: json evidence; size=562 bytes; lines=19; markers=<none>; tail={ "abc_candidates": 220, "abc_done": 210, "abc_empty": 10, "abc_results": 210, "area": 1572549.16, "end_of_script": 1, "error_lines": 0, "module_count": 110, "netlist_bytes": 68022335, "netlist_sha256": "91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis-audit-old-t3i-smoke.log

- `kind`: log
- `size_bytes`: 152
- `line_count`: 1
- `sha256`: bc1bf791d2feef303f6d68fa74d60e20ea89d191fd0b81f55c456b6bc329bc22
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=152 bytes; lines=1; PASS=2; tail=[T3J-SYNTH-AUDIT] PASS: netlist_sha256=91badd2b5c77b72222b7d5bba6d9ea4986c554b43f274e3d8a460e9adedf6926 area=1572549.16 runtime=1387.86s peak=3609.14MB

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis/audit.json

- `kind`: json
- `size_bytes`: 1190
- `line_count`: 30
- `sha256`: a3f0d160006898c617483d22d4a36cca45e507ce516267c85570a3a63e3b8735
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: json evidence; size=1190 bytes; lines=30; markers=<none>; tail={ "abc_candidates": 220, "abc_done": 210, "abc_empty": 10, "abc_results": 210, "abc_sdc_driver": "BUFX0P5H7L", "abc_sdc_load": 1.6, "area": 1574381.48, "current_manifest_files_verified": 137, "end_of_script": 1, "error_lines": 0, "flow_manifest_sha256": "dc...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis/audit.log

- `kind`: log
- `size_bytes`: 176
- `line_count`: 1
- `sha256`: 5f35eecd78cf196dee154e3a22547945a05aacf0ed4918519e963d4f65501f46
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=176 bytes; lines=1; PASS=2; tail=[T3J-SYNTH-AUDIT] PASS: netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a area=1574381.48 runtime=1403.87s peak=3608.49MB limited_freeze_inputs=5

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis/current-byte-check.log

- `kind`: log
- `size_bytes`: 18158
- `line_count`: 248
- `sha256`: 3aa83cc0d2c63c52739773563aa015fc18d7a73c06663b3a6f2eacd16b2ca973
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: log evidence; size=18158 bytes; lines=248; markers=<none>; tail=/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiDefaultSlave.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiClint.v: OK /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/AxiPlic.v: OK /home/ly...

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis/synth-exit-status.txt

- `kind`: txt
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {}
- `summary`: txt evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-13-rv64-t3j-fetch-read-window/evidence/synthesis/synth-input-hash-cmp.txt

- `kind`: txt
- `size_bytes`: 48
- `line_count`: 3
- `sha256`: cf28d0e76da01906cc0f59f0d1d017e68d6f0c88bf964b889153981690ff3c92
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T09:45:34+00:00
- `markers`: {"PASS": 6}
- `summary`: txt evidence; size=48 bytes; lines=3; PASS=6; tail=rtl_inputs=PASS vsrc_tree=PASS flow_inputs=PASS
