# Evidence Index

## 基本信息

- `task_id`: 2026-07-13-rv64-t3g-mem-formal-only
- `task_slug`: rv64-t3g-mem-formal-only
- `profile`: npc-dev
- `asset_count`: 941
- `total_size_bytes`: 7516802

## 证据资产

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359955
- `line_count`: 4549
- `sha256`: 71876fd97cd557483a897a15736e8d3a5c4c64663f175919e9593dc65a1c2077
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359955 bytes; lines=4549; GOOD_TRAP=21; tail=top branch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000070 miss=390 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000080 miss=10 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x800000c4 miss=2 [0m [1;34m[cpu-exec.cpp:1600 statistic]...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench.log

- `kind`: log
- `size_bytes`: 3326
- `line_count`: 105
- `sha256`: acaeedf15233a1aa21476ca4a0baab5ce9d156e9d95f6062d345041f8e9e9484
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 188}
- `summary`: log evidence; size=3326 bytes; lines=105; PASS=188; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/mod...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14535
- `line_count`: 89
- `sha256`: 9173ced8780e124a537e66488addc9825083ef36bff1f21ba81e1d8545152605
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14535 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14211
- `line_count`: 87
- `sha256`: 78ec75ea428ba31fb71673ed24c973c9020083c8bda4ead1d3ab6bfa7518443b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14211 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: df346793b2fd8aae5df3e18e5eede8858ab4e62ccf1ff100cf64f037647301c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17079
- `line_count`: 78
- `sha256`: 53076c2a2adafde46c83a5dfba57cb30478a11826108576cf60180628f8d81b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17079 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8487
- `line_count`: 60
- `sha256`: 636a04773b854c6d9eb71318013a6392db578d13e366690922c579fedafc0b5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8487 bytes; lines=60; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 129fb938bcea093154dbc1dc8e472e099c7f6b610cd4216a77dd8561d9f30187
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 3998893851256d56bbb1a769e031b67cfbfb4f3ce45425ffd04465e415c22a16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17089
- `line_count`: 78
- `sha256`: 9daf05d5a40334d188fe12170953b92c3106eee513e377378bc3c0e36e26160a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17089 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3261
- `line_count`: 28
- `sha256`: 4c8eb65b32ee595b37960555989063c35376c9ac6296817b832acf3c5b8a6529
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3261 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15329
- `line_count`: 103
- `sha256`: 7cb687f257fa6e82cf5a76aa315cccf2c27e84f8c158fca86387eb396563f04a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15329 bytes; lines=103; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7529
- `line_count`: 58
- `sha256`: 3374393f25490609fbc7008f6cdb9c6122683d509705ead523947e4dd087af99
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7529 bytes; lines=58; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: 6e8b03051f6459e31cca0e186e2c3f11127fd8fb876bb0dfcb212767b79303b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17065
- `line_count`: 78
- `sha256`: 54a2bd99e4364708c48b5d99673f1b265ab0cb5f5d1285f984d1e1f5b45a2eb8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17065 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155595
- `line_count`: 1113
- `sha256`: 18dea477ba92fe68d70182ce94e076ac7be516e5d376f2ce2569432287d25c26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155595 bytes; lines=1113; PASS=2; tail=_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in arr...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 3179
- `line_count`: 103
- `sha256`: 072952006e45dc1770c1265e73b9d8506b895669b400198953ece8b3556b7a15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 188}
- `summary`: txt evidence; size=3179 bytes; lines=103; PASS=188; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-g...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/npc-build.log

- `kind`: log
- `size_bytes`: 48082
- `line_count`: 59
- `sha256`: dd27c4e90875fa72b7d9fb4bb23c16b27fee1664c1e030fea993e1e3d8f4c9d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=48082 bytes; lines=59; symbolic=__0__,__1__,__2__,__3__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-breakpoint.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 759bacf90a27050b888263f901fd5eb0ffa9c3e8b10d9c2c1add856d31c28392
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-csr.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 4
- `sha256`: 64ea22733c1c648d458ed72ca058e8e6cab07bf1bb3a405c30194b124d72ea43
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-illegal.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: fe618512fc09c6bec94ec603c2d4669b6f9225895d1018c00296d4ae648e9453
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-instret_overflow.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c7eb752ddf7df2836c15e057636b2b3b066bbe61020cfa1fcb7667044ba4fb74
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-ld-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 10
- `sha256`: c44e62773c367801944447046f471368c167a7b46cc18ff61e89ced9b1e10b45
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-lh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 0a625bdb1bde894e591b08910e9c522dae78cacf6f215057e5084ebb7215469f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-lw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 81a2d0f7543c87aab91ea4ba7f6df69cb54772b8b02fc1970baaa2dec4813138
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-ma_addr.bin

- `kind`: bin
- `size_bytes`: 8768
- `line_count`: 11
- `sha256`: 43aba4a5ed598e42eafa14d04575df2738a9dc1b2262e599788408accf523041
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8768 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% �s 0�" �...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 6
- `sha256`: 23128cb88a441f0ec5b0aa92e3ff235468a97a94e292d35d9092ba02c0cd6d75
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-mcsr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c8ab2c5fbb9cf529518ebf007812028ad1dc524efde5bf2edfaa20c2b8a3df6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-pmpaddr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5c82f4f85902b25a1496ffba37f4338b26a971da939e6921985125def9242a2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: fab026d76c46c8506cb94a08cb632f2de6937d8b057204464e3e2cdc019780e3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: eb468050871ee3c797254f90c6571b5dab04bb018834af2c69265c0274a165b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-sd-misaligned.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: 580363d39fef7b89f9e2e386be8a7e60ac3fd56c1df679ebe3ed5de107573e9e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-sh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3c3de98bcf0acee9619646b0ace0b28ce19cad50d97d6323aeb3e30866219c48
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-sw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: e0715db1e4a9e3efd1784bbde55edb741d3ae50f551315ce987e5434a5683aa4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64mi-p-zicntr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: aeadca97e007d646ed5565e489bf1a0b805cfa321e996930effd2ad4bab21159
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-csr.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 5
- `sha256`: 2f7d31a97b4a1a8836b5b16b048e42d6d3be2d02275a1bb9e4810b27575a72f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-dirty.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 302f824e3cbcf3b842793355d42fdc5011dfaed03e59cec2ab8d1b4831766a3f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-icache-alias.bin

- `kind`: bin
- `size_bytes`: 28848
- `line_count`: 4
- `sha256`: 4557a25ddcb7abec27c88269b480cb0d7ec7fa64305725d29d8d3c0a52f7dada
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=28848 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �r �� �s�R0sPDt�r ����s�R0sP �r �� �s�R0� ��R ����s� ;� � s� :sP@0�r �� �s�R0sP 0sP00� �r �� �s�R0 � c\ � � � � s �r ��B�c� s�R �� ��� s�"0sP 07% �s 0�r...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 4f38f4a5a44b94c3317295c23666c5c5d6eb5d5aa6978b7de5509ec65f3ae17c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a27651d09a02b29a03a577555aa3571f8196280aa72cfd8baf0f3fd7b8778ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: 16442ae5360eef6283fa542a660128ff90f325c6385c4f14561403282e63b9d6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64si-p-wfi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00771ff518788f921c94a744180cc11a58d4c6867a7a28e02f20735727e41927
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 4150f7116a5d1ad9544d847f718a27dea539caa5cba32d9db43c0dd3a320cd58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 23ece6fcfa411fe3e9ac8aa2d73a60054e39446808a1551d3feb2c97cc438b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 23d3611c19094402928bdffe805fa8532d82fd77c90420ad9dcbbf546b86a250
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 4
- `sha256`: d235961f7c7c03e9da495ec9a846dad59fd750a8fd31c7bb767a01e623f0b31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=654 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 8474a0af82ef8d14cf5dbc04104d884ee96562d91ed90a22bc87d19350c99f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 6d07c6e4fe8c1fd8b3f44f7dce5500299893ea370f733c6c7e01c48e4b288072
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: e51c2a9f92c0506b9df3f6c48a301a8889b7ac5b3931ac4dcba1a9b2fc2721d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: d5963171dedae952ba273fd6c4b0ef70b6f28a179dafb069832f8f662f963179
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 99b16ce02f59f4a136bb747ddfd6f2348748038875ad51e6bb0192e691402068
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 62379170ad5bb6cc61c4b4dc0ff7e91a9fdde586f642c6ccaee4c80eeb1f3d62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 7b980a18a7a0c0f1265bd180a9ad1db93e8c6cab0d658640d820cb92a3eb9b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 9099de3acbff7f1453867efa55acba173e3f713d751107e9406a5e76a42fea3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cf030de16f0944357c4675d1bcd66e4c9ff80e240125f9290aadda6d928d2760
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: c4a66350fe2e3da52898d8665d719115bc88db0ef8aa4e2c93e8de5ed2e29de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: a22f5126c64613ddf6fd55ea6331fe76d4a0a0a982cbabc5cdd66da0ebc03e51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 237937babe46f052aa4697ccfa94dd5d62fe6e9c4f6ba2ed91df161b8bae8989
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3c5cb1679bbbbdb5587f3c2e0afb816204ec847dee3ec85268b44979b7dc56cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: c2afda182606f2e0a7e63e3474d5921c3aa8471978d516a44873e5c06b70a2ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 107d85d30c6e216d76cd6b59c73db64f75028be38ce1ee747124bff1d6ec90c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 1daaf37379469b4eaf41802fa680ed3c8c7bd6ce953df9c84d4915f239d4d641
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3b729d2c2d818c320db5ca4afe7a1f1348264eb2ffe0eba7ae1049417f20391c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3fb8dc5558e0ec98c7af988859a3cd3baca8da9aea3728df9d7cc85c7fd8bf77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 00b93d77799a70c2e3b84e597ee4c06a7fcea19dce219d84d8aee420edc53bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 8e0c3b0be49d00964fde252f04e3087506e0de98cceb587a5ab3066efb41ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 5332
- `line_count`: 63
- `sha256`: 3f9984ff572c57b4223b784b2d63839b9465651f2a587423c21ebe14662330f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5332 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-breakpoint.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 5561
- `line_count`: 66
- `sha256`: bab04e31d401a3c4363aaaa8235f830b977772c7b497518d6a2f379fe43e209e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5561 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 5717
- `line_count`: 68
- `sha256`: 9b097f2adc59a94384dcf606b9def3f67a64dfd32926471a4e5caba29c2e8455
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5717 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-illegal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 5337
- `line_count`: 63
- `sha256`: c9b229a8823d5baf6cfc5e8d994bff6ad79708542333104a7e23c87e44da10b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5337 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-instret_overflow.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 5565
- `line_count`: 66
- `sha256`: 45bf416d0188f31d369204da10d3da1807d2aad07fc514578163aaa9d749fb30
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5565 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-ld-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: d83db9c92e4cc58a07b704172e91139d749306058d08b02cff209be0f796c53a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-lh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 5553
- `line_count`: 66
- `sha256`: d0f26135a1cc7a368f78d13d1f77c2989f3d41843753db62db7048028e1891dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5553 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-lw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 5503
- `line_count`: 65
- `sha256`: 8961a7df6c6bf67141a19cb8b0fc3a5948cbb28fde4216d5fad79d6da279298b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5503 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-ma_addr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5484
- `line_count`: 65
- `sha256`: c75879505530e4a688b6ff6e36963497dedf342a4f200496fd9671b0ccd0e9c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5484 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 5398
- `line_count`: 64
- `sha256`: d234ce49c8ecc1c83b399db6872eccb787c140dad773b12f844ff883cb9fea50
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5398 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-mcsr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 5389
- `line_count`: 64
- `sha256`: 272bc8ce2bc990b13e862a4f4a0070d45348f1f77967f9dbba32b63e02715cb3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5389 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-pmpaddr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 5072
- `line_count`: 60
- `sha256`: 0b665f26f3c72c48a719a54fb47ae353968498e1add1e3dac9f7388f6010a40b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5072 bytes; lines=60; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 5252
- `line_count`: 62
- `sha256`: c1036c3285a4ebf2f5ba63c8886554d96b06318e24f93c55c67675ad0cd1b835
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5252 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: 58067b191ba6145f63dc9c42366ff16e26363b8cdd81142a331b919aa1a91ddf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sd-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 5412
- `line_count`: 64
- `sha256`: 2b2c4f063393113f89467d6e5ee01b2b2b7e49ac94d56c71df1c006ad162651e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5412 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 5420
- `line_count`: 64
- `sha256`: 1bd6acbf4794645e12a99d535150f6f5a184880b42be4fda2a0feba5cd130984
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5420 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-sw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 5408
- `line_count`: 64
- `sha256`: 16c76a1280f6b196b5ad054f018b8c681b208f9e7d1d6266bcbba57dbd1d342f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5408 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64mi-p-zicntr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 5485
- `line_count`: 65
- `sha256`: a7c9b58d0d626406783b35d6a76976d011c0f9528704fdd02c7a059df5e28507
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5485 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 5564
- `line_count`: 66
- `sha256`: 958071676ca91203a6a91e59e0393d7dbf8f4cb5d2bb4d02ee20116c3b650be4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5564 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-dirty.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 5439
- `line_count`: 64
- `sha256`: cde3ba0a3f309b3b33c93f903a008e5139713a56ebf581288a5b61a0a48bcf16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5439 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-icache-alias.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5482
- `line_count`: 65
- `sha256`: 4d014e05af9432bf24085d2029e75232a6f1244262086457ca020626ff4d2b2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5482 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 5141
- `line_count`: 61
- `sha256`: a87c41c58f94e53e15a1769220a790ee98a488ba008a53403fea8b9711cda478
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5141 bytes; lines=61; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 5611
- `line_count`: 67
- `sha256`: 5c6004c0f410ace27c651428fd7413ca58f5b1df749c7be9dde8521a83e8f31e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5611 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 5316
- `line_count`: 63
- `sha256`: fe6a03b68107b373c0e22f081f05df29f92b904def09b72bdd0465d83de3da80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5316 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64si-p-wfi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5262
- `line_count`: 62
- `sha256`: 4939261732fe5cbac3497c4ae56fea6683119f7ffcae81c495cba8a35c997bf8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5262 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5332
- `line_count`: 63
- `sha256`: 20f5c7b7291eb3ae540d9dd27d50fa286d7f67c641b473a35ccec782fc5a6bd4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5332 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5261
- `line_count`: 62
- `sha256`: 62b1918770fa3a5369c48d875f531bbdabd32dd1b3a31827737f27e7b8e3ec2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5261 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5261
- `line_count`: 62
- `sha256`: 52a0bcb1b1520b3137dfb2a1e57ba48e2653194ae8315cfe318e6bf38c8de6a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5261 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5261
- `line_count`: 62
- `sha256`: ff5b9c1f4e209ff45b2598f900b271e995d2d4607dafcff151e51d858ec6d125
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5261 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5207
- `line_count`: 61
- `sha256`: 603f1758d48fed9e35c11cae8350df6f29421efd9e8d75c08985d479b970344b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5207 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5262
- `line_count`: 62
- `sha256`: 823acb38ce776913761a5a9fe5d93ee4dddc3da5a19e47ac618aa713d9d5005b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5262 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5208
- `line_count`: 61
- `sha256`: 1b6dd35f2ec863f10db06691ec64cf9cb257a5d1dae4f02e727b583457e7432c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5208 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5261
- `line_count`: 62
- `sha256`: b1289c76dbc39815d523adcc19644fdc2efac395cbb84d59027262146f8a614a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5261 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5207
- `line_count`: 61
- `sha256`: 780f165d25c48768d20ed4707b16f7911f25feffb6e2fa09ef325f236990e9b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5207 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5262
- `line_count`: 62
- `sha256`: fbb7b5a2c319dc4ec33db16f9ef4e712d7a66a1d644c83cd941e83300bb71199
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5262 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5208
- `line_count`: 61
- `sha256`: 49a61f0a13c07bfa1815932c6c8382bd246bb40a17af65c4abf10b1e2c55e459
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5208 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: 6539ad70d887645f4f8001860a8b889f280120a2aa0b4a9f1286d176e6aad50a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: 2ef7e8d53937dd0bea26b9da9bd27c9a59eb30e242141f77222e6f2fb10e925b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5262
- `line_count`: 62
- `sha256`: 8ea6e8d0b4932126474e3dd34b7cde5f83ff5439e9236762e281a804e2b0e986
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5262 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5262
- `line_count`: 62
- `sha256`: 63c7b6791100272fc28ddc399c3b19c49cc6a6a8ea8902f7091cda02ff2ca399
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5262 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5331
- `line_count`: 63
- `sha256`: 9cd20e8e8dc5435bf4cdcc9493939af38f3eac1f9310cee4b95ddc4ea4dd1095
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5331 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5476
- `line_count`: 65
- `sha256`: 801f189a0af654797590a6e2573c7f73bbd11760af036746593521023e15a72c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5476 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5633
- `line_count`: 66
- `sha256`: 9d1072b6cc0b0211f572a2053fca5a7e17a6cccfa57bc7ca4cc7a25497b76980
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5633 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5638
- `line_count`: 67
- `sha256`: 5b1db0d9f0d0d05a0b61b270e0c74dbacb5130e73d1b8a563cc515162b7e28c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5638 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5423
- `line_count`: 64
- `sha256`: 60117b49f576e3611807122de51e6dca23d8287cb04829815ed64a4039f3f2d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5423 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: 7cab717915c84cc9afda2ec0411fb25bfe8970592bea8b42fb3210e16a0bba2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5493
- `line_count`: 65
- `sha256`: b1f0914ab1d7d522d9562ee944bb2db1d4e8ca060cd45206c992dd685a741009
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5493 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: db310a1cf7f4afb416420332a11e4994f4dfe033cacb55ed9d559f9a311a275f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5508
- `line_count`: 65
- `sha256`: 8b40f3b0e538e929ea84ab9eb304780fb7fd17711d31cbae515945ef9a4aa611
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5508 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: e56b742e71e79112771f9ef7c88ec7f3077b8c27fad09f762b75229aefbff456
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 93b1a48b955b87b01cb2a6d252c3531abd63853b03bca2ac955fe85c1658d900
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 859727503206d261033c77b9b50b996c98c20444dcc0e18bafe66a1be71aab8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5339
- `line_count`: 63
- `sha256`: c1d838629a4fd56e5176e8bfb2d6575b68121a9b2b2e897d29d474b6f29f9f7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5339 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5492
- `line_count`: 65
- `sha256`: 575bf04013b48f6033b35fdea2f2183eb6d7da774ad652f77d0586617ed2f096
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5492 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5206
- `line_count`: 61
- `sha256`: 4289bba26e752889fc6649cdb24c156a530f54738f8e13b5aa000780b2840949
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5206 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5627
- `line_count`: 67
- `sha256`: 3e6ecc955c8e18edcd43e317b03968d393a7a5986b3aefd6b744d4b662aefdfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5627 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5424
- `line_count`: 64
- `sha256`: d235a361aeafbd532466838b395daae6f0ed85330cb9a4bd2dc962321333fe1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5424 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5476
- `line_count`: 65
- `sha256`: c0a6f0663851fd3d2b912928cd10a0f4f35aba39157f30baf198fd0e36ec97a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5476 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 4e968f23a7f4ddc24396216be7c607200bde70533e6a0911b0320169011a2658
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5345
- `line_count`: 63
- `sha256`: 64a5f5052bfe8949f136d772530a949879ff0dd3a202c5688aa15b0f798dce30
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5345 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5504
- `line_count`: 65
- `sha256`: 0bbd07f22c20aec8039ef6e25d2e3f65d3d08c6192e313717dca2a0dbe9f3d40
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5504 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: 05d193a731a0aad4a1b93e9de0b8d01a08057f3c3f218748d1fd555c64833167
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5495
- `line_count`: 65
- `sha256`: 20072b699cea3e2c5722bf0cf79588d5a57b05169fac98b0a04176c5557f2951
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5495 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5495
- `line_count`: 65
- `sha256`: a925dc950f7a40cd046a5fa4129c5086f53d76d2919beb477031d9b82ee974b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5495 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: 899f0c3d7beb3a5d6444873dfd6382ee385b004b66a8e2c1640e223c2abbcb14
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: 4b4b6731a65037a0c425765a557e9170a5e3549bfa170ae1897be062236f167b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5270
- `line_count`: 62
- `sha256`: 5e13bda874c578c3ea2d9b2ea54cc83cce34e0d2c4ae0e02fdaa76dcd874f803
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5270 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: d37365f122aed30e3ebbd157daf09825284209300a765feda69b1bab87748e6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 3d155a7d5455deaedfc28560ded648bd7eb98b056e726507dc871a67c7f50a64
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 3fd4f5ca029240da01348fa00d8fc8d8e9cf0a618399277caf975137e050e341
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: f8ece4bf5c7c5d4febcaf7e83080ba4872ca4a19544f3c007a14b7dd010cbb66
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 4b90a3417b03181371e38255a402f3f7d99517b29de08939efeecd5cfdf011d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 1608e0b0fd1bbc44da353fc813e1094c7d17727a0abd3c6f7baff89dd06acbbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 7ef636a0e6b689d5b71efe54fb5583c268960fc44936365c21bcdb23f9af7a5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 8a10c523061ef3d3ec5215df3db83f27e61b856a552c8ca5e59806fc69235f85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 2d7483a7763245a6abd64c747139113f4e62caf81241da2dbfd4a4c585c86d61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 9cd0d1f59348bb217b48c073509b3442bf6ed972173095f3c727c7b3792baa08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 11f1647b4845a1ec186ff7cd0246fd4d723bae1de2dd39709260ea24bcd82484
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 16983fe09ecf4f01bef9fd9f0350bdbcf214da679b79689965513edeb467235b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 1d87ef856954e643bc75476a5f0dae7a0dfa2071126019f4fcf72f5b3e3dec5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5505
- `line_count`: 65
- `sha256`: d79fe1d53a265fb19238c5077fd0a5738e87e5e5adbe1228c3e06b4f0605ecd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5505 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5245
- `line_count`: 62
- `sha256`: a2a4e75a08f827ff960e8e7bb0d0e93abe223f2594d496fba85bb8f725f5cfeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5245 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5625
- `line_count`: 67
- `sha256`: 8631d480ff98783ed19e3027f581f67cb81c8a4cc0fcdd8b13e68f799dc97145
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5625 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 05a907206dcdbaef59bdb44ec3182c4996faddd6582b25f56065ed7d4640f575
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 00d5154c862c119d1170cd2a5372535b9d79d43669e652041390a0a5dd2dd22f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 26aa2619768fef69a624d8ba90d1455d7cd6dd2d4764abea16317758dd643ad5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5744
- `line_count`: 68
- `sha256`: 3d36fc70eddc645967b660dc42f76d56b8085db01e7072ee53c97e1b4efb039f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5744 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 8d59c9dcb8b96fa3bcdc82f18376db9d26855cc85a373fb2a9af04e0a932c636
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 00e7fd0856c1800aef6d7cb02d2770f1a1dd19de981c4635eca5f745544f7c27
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5324
- `line_count`: 63
- `sha256`: 677db60c59e4c56ccee9d48a1ffa566f16533b56f0c1aa04d77bfb7a1e6960ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5324 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 41129b7feaf6264f53c286dfac0593dd0e41ee2a0f3d14ad1a4c80dca75499a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 83930971dae1eba95fcc70e2f592f3b921a673dd65b625658fc4a353c1a39cfe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5759
- `line_count`: 68
- `sha256`: fcb093639f605b032eaeb6e532a516c2eb01a4f0c26273f11ee5bd0ccd62e5db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5759 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 9114ab427afb5e58ddbd910d0daf62307975fa22991fa7214938168daa14df92
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 8785b1bb84568124ee8fbadf7dcbe50f6da6e2981e933f7d4ca2177824e0010e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: 99f273d44bed8a134fc4124411710e76745ee36f69c7eba20115ce884dcdc862
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 52c7509abe2f330b547c5b4147d323c9bc5651036f936e7d15eb6e78fee9d2e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: 9eacb840f6eedb65fdbb8b543292bf79fd39cd494184bda4f00627c4945b4943
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5174
- `line_count`: 61
- `sha256`: a72e96b21bb066b1d592bf5c11d429d1da45eec000eb15b76313c87800f1e92e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5174 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 6f07a3a73a00a8d1d0b036fe974bd6c03b191feaa94e89a9d255b5a3474dedfd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 5d850f77bc5a83ea64f6115e03ff7d6abbe6fdfc30e9ae064e283a63ae715ca0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 3c6840915885f9b44fe4a34c037c8fc3ddfb47ff1398d98a237a117b7c620b6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 51600a9aa01807bfe8e4b8c6b6c09946208cef0b3b24ef35bc0257b83d2fc843
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: a19abc552dff799d5832dda9579b84a9ea65e52e4561aa1054b2dcd09a7aea4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 11148c2a659e58d4bbb4d0e672601a4d015400fa9caf4c1d0c4d8bd8a139bfe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: 20749270853bd2dbf85e0f1d6fa9c3f4083d36beb99c93f737484f694ee03eca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 122403cdbc886a721ff024f23bd55dfcf505cfe493738994954db80cb628b5e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 2b2bcf8b5056bd4ee9c3802e364f3ec0a17751bbf7911c73ca31025f037ccea0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 75bf6862a6da9ccc5a7d8c8585105fc6b725e777abab8e70047fa5cbb967d297
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5697
- `line_count`: 68
- `sha256`: b8b6dd4efcc926350e0105a8c686f2e5b48394a13168e0ccffad4fee2994f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5697 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 4074e04a2701ba1402fb8324457bb97d85a13352dc760872330b999cd6e0e1f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 1ea3085c3ec8232b9934fbea3e4346b265d4de85e1bdf7af6efe1007b863f68a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 7f85599d719e2f9df57b7b4e50160ff3e8c4b485cf1507ad6393bd67ca801050
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: 436c39f4edfe17a55a75a7ac0bb746b096971ab697820d41714a304a4d299773
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 6859ebcc541f90d7df45390ff7332b3c072104a4d4ca6a882f3fd719f121cdfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5505
- `line_count`: 65
- `sha256`: 0703264f5190ab2e489e79ef1ebf6669ced8e74d9307532547937a0be2d78fb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5505 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: f88b5f372ff73c01eadcaf1644297c3adf06562184a5dbf557908f14dde2544c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 3a6ff00e73c13de6c7df4ed2c266fe4b7b7e5e7985a050c4df4e68c7e7ebfbb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5713
- `line_count`: 68
- `sha256`: ce916551cf57179f86c149e660cb7ab5fb389275fd1e471213f05b9e3ce14090
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5713 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: d00fedb556c2a8a64831cc338413a5d24696f921649a6d1ecf8c57c77fa0cc08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: e40e94f9df2d762195e87073c8f37deb6de9927522107cba68420e616d2b487e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5334
- `line_count`: 63
- `sha256`: 14efcdc3128f376fdff31a84a61fa10108b2a5c3b064caf22ba356fe7624ce7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5334 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5471
- `line_count`: 65
- `sha256`: 5bea9f3d55ab90b45e9945ce337c845357a78ab239956a52fa6b01cd9831b0f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5471 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5337
- `line_count`: 63
- `sha256`: c80818ee42f9221f736d577822b58426d7a9e24594f9631ebf3373d02b17cd40
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5337 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5473
- `line_count`: 65
- `sha256`: 5aaef0a0ffaeba6d413919b0e0b94e885cf3ff5a9b51a0d8b6ae58fe4e601a03
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5473 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: d410534aea6bb5f573ba3b8f38c44988b67d3d4e0f4e5c9b5f75238f691beb05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: cf3b0cbef7c0b16abb36b692f73611cceb9587817beb8c5b755a4e868d094a4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: f800d33b1f987aa3291c13022d55e177ca357c55c67a5eaee6eea51e9fe1afc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: e6a4f421289a4fdecb16add8158556dce96adca395e6a04782a86fb4a3285708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 6529a276a2a9a9309abba7f5c04e79db7e7a085973dd12010e63407571840495
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5469
- `line_count`: 65
- `sha256`: 920d655d79f7f14421c4e830d82de61c61d06176beb60a25c6d92e1f1c703de3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5469 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5335
- `line_count`: 63
- `sha256`: c73ce4e5a052ae5e8792e207ab8eb75d4be696f3da3a5ae45337eea135b90a89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5335 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5471
- `line_count`: 65
- `sha256`: 742f389e99b19d501f3e4cff3c974ba715f9bcc935888b1a13953de5930a8f5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5471 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5473
- `line_count`: 65
- `sha256`: a08836bf009c2166cabb3c59e89638a898d6d76c75478c8051ef7d84edcfa5cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5473 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 434da68783de2cee5d83b1d699698b9c5cdd2a409cf80ba3d90269ece30b6d67
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: e32360a2aa864a917fd25064f855adde667b67a0006be508532d2589e7339d8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: b435fb653cfcb9aad5acd7770972cd310e4bbbbe97363eb5267bedf54f96df2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 7bc1c629420b5f36760ef76fa4f9754769e7b5152ea9b9b9c8fd8cebf9ca1c02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: b5cc558a558788365f2d30aa79a31c658c7cf14fa65777d546c3206bb35b8958
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 7638aa9b657491859151b3353f3d42ed0e60f4aa5d01c543aead3cd0aa65cdfd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 3a8d12f2ce3a7860077ea43910fd99bf76f3f63e8e4a3a4456d6c3184cd34243
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: bf09dd4cb47f220d4dce7ee77343771b3ba91cbd083f5764a94888d223cca708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 979a8c880354ca3aadd3255ec20adc979478f5c9e392a1debacbe820ebbc57bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: e322d50e7099ebf4a517fd275c61dfe1045b94803e04fdf8ae768199abbe4951
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: c4e2dece4420d611c1219219f2b19481978709fa2cfd2ec3c8b135172bf877d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: 95898d792524e0ff504d8497143cbb74badeb397c627a715b4da88f6b066d4d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 6fea869e80d462ca62198946804a8a708ab7a395421a608d1d036376d10107ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: 18bf6d611a367e4335a27a1f8b973026e698397d6e09661b8a7348af6652cd51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: d868634e70ce3a089bb16ac3e57811d809f88be570321c859d984ca345f042b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 187734c834601a8a5175e7b338a485b100d0bcafc8f51fcb97e4c23fd9012615
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: f8613081353b877bb36c3038735d66a8ce507f2057b3b2a42b43d76a41d8d7e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: ad3a1b9874cd887456c91ef5af63a90c42cf3bf7f268f4eca41cbab0bb838fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 82788c7e710227245c407d1f0d27c5c74d087cf710e4b1b2f7eeda1c312ba492
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: ef85854211864f9617368be4f40c0f7c312da3b174f8df523d8a182beaf34670
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: f1bafd94c67e691d7dd0ec094d79b618cc0edc57d15d4f9d8562ba55a16206d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: ad827b2ab6e3fc2ddf333776e324afaf811fa2f1fbf74fab7c3aec665603b3a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: e0c988ee8f47b1e06acb0565b62e554662ee4f31831e1fd72c9243435697a934
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 587c3f504d8b2b3c259d3199997589a2ac3949c94c0e796b656a249b0556d60e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: bc28cd78d13ad123daf0bbe97e73b038ce7440b4272e5f04023393e722dd06c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5698
- `line_count`: 68
- `sha256`: f84f596ca4136c1643a251352a9375448c0144205ac673c8407ed154c0285cdc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5698 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: af03ba549bb4fe6f04ce97332a8c8b8c32240c2c05be1a8386706d9de6f4237c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 078fed537aa6a3e32facf82c668e6bec45d4df7a45da0b0d80cc9240a378685f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5490
- `line_count`: 65
- `sha256`: 4f76e8cd13ecdf9ae9f409b410f9c7707e912c955a69a5bb98f0125a60d6215e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5490 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: f3b71ed4e0ea68c891919485390566e8eada1ddb1c414aafa64c6eab4edc3e6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: c4966dbc6730bcd52d253a921607d8517fa9b96ed235d758a842edd8adb53461
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: dda3e09c6f7f82614ca4a7361a42ccd9d3ff844da5cab762760233c74b9b95a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: f96c687d3d212966e7eeb00321cef00bbc7256a31ca18628806ce216681c364b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: b8509ac085db7a62b72ce19a2a674eea2c72eef4a8bb44337f16c212f3e7149a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5708
- `line_count`: 68
- `sha256`: 1d18832d8c7aa41c173ded66ed6ba99e2ccf86cdb5a3f766ef871d0ead211442
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5708 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: ad5b9b465fa27a0be709a76786bb62a5f83ecfe300b0f02adc68fa25413e80e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: fa4bc7ddc38013d7595500d65888de9fec9b44b3f7b5ca4d5cfb6a5df837d909
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 7b89c1a2f355daadfb6ec6181205a7b31d1aa5030ed1bdde355aeda242a4615d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: fff8265b2fe1540125e1a8188cc069bcaa835c255aa9de63d33d578d8a41fdb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: c1d9a94206df54013580ef888f9a383b070c132fae5a821952268c951b4b3eeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 00c94c960143aee80ba92febaf865ca143df588f512343d75d9948662f6cd83f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 0c5c13a6cf2c4efc22046f39c012f3b6235677058c26b3f6b1eec2bc98920bc5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: e0d3f5c68c40e0cbadbb60f0060cdf7750816b5ccc465a341bdf6a7c7c7e8c41
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/status.txt

- `kind`: txt
- `size_bytes`: 17953
- `line_count`: 360
- `sha256`: 6331b8133bf6a2f9565da82d98a66e8297454f4b266e02bfba07741e38a5ce54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=17953 bytes; lines=360; PASS=718; tail=module-testbench PASS verilator-lint PASS npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS r...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/summary.txt

- `kind`: txt
- `size_bytes`: 17994
- `line_count`: 546
- `sha256`: e4d9ddd0d5bfa9fb5651e73d46fb7f81de3a7576a62a934b678da7c16d21ba1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=17994 bytes; lines=546; PASS=718; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uzbs rv6...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/core-regress/20260713-122959-2093816/verilator-lint.log

- `kind`: log
- `size_bytes`: 8830
- `line_count`: 6
- `sha256`: 2f91ea8dd29749dcb84180e3cc532fde01daf9ecda33c52059413190f20d9469
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=8830 bytes; lines=6; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/coremark-iter10-retry.log

- `kind`: log
- `size_bytes`: 8109
- `line_count`: 101
- `sha256`: 892c2782201eeb41dda21f47b19b7857241bf3ae9a7e2f1aacc79b211b8970dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=8109 bytes; lines=101; PASS=2; GOOD_TRAP=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' # Building coremark-run [riscv64-npc] make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/abstract-machine/am' # Building am-archive [riscv64-npc] make[1]: Leaving di...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/coremark-iter10.log

- `kind`: log
- `size_bytes`: 273
- `line_count`: 4
- `sha256`: 725a9eec41d7619962014d05394f2da0fcbb7622c8bbc44974eee3d78cc6a554
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=273 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' Makefile:5: /Makefile: No such file or directory make: *** No rule to make target '/Makefile'. Stop. make: Leaving directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchm...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/gates/contract.log

- `kind`: log
- `size_bytes`: 271
- `line_count`: 4
- `sha256`: f233ff516447cbbf40aef34337dd2a447361cd56757195a71a4f3e03b7303159
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=271 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=83 基线=59 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 83≥59 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/gates/full-build-retry.log

- `kind`: log
- `size_bytes`: 48193
- `line_count`: 61
- `sha256`: 71ae5b9fdb281d6705eb0ec47ff17e92c494754ee05e684e893509356ee2a267
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=48193 bytes; lines=61; symbolic=__0__,__1__,__2__,__3__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUN...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/gates/full-build.log

- `kind`: log
- `size_bytes`: 10812
- `line_count`: 18
- `sha256`: f1d516fb3de1d9ed770b837a1fd07fa7b614df08bc90a4085c95a4468dac7273
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=10812 bytes; lines=18; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUN...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/gates/lint.log

- `kind`: log
- `size_bytes`: 8651
- `line_count`: 5
- `sha256`: 7e8543a8408c414a94beb1f250eb0eb6c369e6cfd62128d9a689b5b6e012db2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=8651 bytes; lines=5; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/sim' make[1]: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/h...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/gates/style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/green/focused-command.log

- `kind`: log
- `size_bytes`: 416
- `line_count`: 12
- `sha256`: 82eb072ac284e1d5fbc7ec93471bc193b6df1041f22d364fdefc491ee2fcee59
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=416 bytes; lines=12; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/green/focused - tool: Icarus Verilog ver...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/green/focused/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15344
- `line_count`: 103
- `sha256`: 9d2e02f42618148607c234c6edab19720f18aace37f998fa9e696c780b08cbdb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15344 bytes; lines=103; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/t3g-green-build/tb_ooo_int_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/green/focused/summary.txt

- `kind`: txt
- `size_bytes`: 269
- `line_count`: 10
- `sha256`: d9404161ad744736c1b9608f4266197293b7dded42eab712531e0bf526364ee6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=269 bytes; lines=10; PASS=2; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/green/focused - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_int_backend - total: 1 - passed: 1 - f...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests-command.log

- `kind`: log
- `size_bytes`: 3256
- `line_count`: 105
- `sha256`: ac3152a3d05bdf8f1e7b3b4df9fad910eaf483ac1002a8d03b51ffd53e411403
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 188}
- `summary`: log evidence; size=3256 bytes; lines=105; PASS=188; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests - tool: Icarus Verilog vers...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: e7ff2106821c50c2c089918ca1f74157e53f679b4ec9294317e1c5af23be1394
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /tmp/t3g-module-build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execu...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 393
- `line_count`: 5
- `sha256`: bb8392756f303d7d3975cd5723800630ecb08f6f0105950c8dd6d30e9741fa26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=393 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /tmp/t3g-module-build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/n...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3491
- `line_count`: 28
- `sha256`: 7f0bf62c76703f07aa8566c0a399d1055c29f5b6dd855f6a6f5b58e5f5d99e5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3491 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /tmp/t3g-module-build/tb_axi_exec_firewall.vvp /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 387
- `line_count`: 5
- `sha256`: febb098a6ef8b7355af4a310e72e0bd1c36d7aa4b0d1dfc3f17f3843b49d4c67
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=387 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /tmp/t3g-module-build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: b7ea1bd9f1ac0e1352039afcbe2a86c6a1e7a33407939f3416a88236d9c98991
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /tmp/t3g-module-build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3270
- `line_count`: 28
- `sha256`: 0b0996df1d64d47f16bb8fcd00a67eb7623edff238c2cf919b28889ce01b4c38
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3270 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /tmp/t3g-module-build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: bdec46642747d3126c6ccd141ee2b68f1238c4667b8b350f6b5efadaeedb348a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /tmp/t3g-module-build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 388
- `line_count`: 5
- `sha256`: 4404a5f22e682bef8fe993e8c5f83821648fa6a4c71330f1b9f12115e0ead322
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=388 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /tmp/t3g-module-build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: 22576fdfd229379d287ace525dbd69ddc7e0bf45232b7c479e41cf01f837733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /tmp/t3g-module-build/tb_decode_stage.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 407
- `line_count`: 5
- `sha256`: 7fb2288231b53558f05e09c46f453ea327d1c514f322e50355be70c7d490cd9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=407 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /tmp/t3g-module-build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: ddfe4f12ad31045f4e6f081896db7dfa96db52a5d30aef5d784eb0179805d00e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /tmp/t3g-module-build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/v...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 865bebdb1a582d84b8b5b584bbca184957cc3f50402eb127f9685f5b3f849761
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /tmp/t3g-module-build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memor...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 406
- `line_count`: 5
- `sha256`: 585888165c6e6c0239a3ea6fb5b1cef100acf6aa0c6e8cd5020a0510556a4673
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=406 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /tmp/t3g-module-build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: b54ffc74963e8960f9065350e52f7c435a5e7936784a57c6c49a6f72b3763579
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /tmp/t3g-module-build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14540
- `line_count`: 89
- `sha256`: a3b64a52bbae9369fc8164a575d17799171cd3a799edee6c882a656dba270769
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14540 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /tmp/t3g-module-build/tb_ooo_alu_core_slice.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14216
- `line_count`: 87
- `sha256`: 345d1304581cf1d28bae8b2ab85a0785815c03cab31fa4cff02236c516ff1fdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14216 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /tmp/t3g-module-build/tb_ooo_alu_decode_ba...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: 6f4084412e6ee601388b819ecf55e940e359644b4391ed76e1d613fbb1cdea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /tmp/t3g-module-build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: d2c9536b388490923d97edc9b1cd29e1fea31767128adfdb515ba6c59cab1727
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /tmp/t3g-module-build/tb_ooo_backend...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 81a816813d6edfe8aaa1ee6fdba8f2bb7625b3668e682576a4cc6bb2ab16ea8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /tmp/t3g-module-build/tb_ooo_bitmanip_gate.vvp /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 869
- `line_count`: 9
- `sha256`: 4ed0aa36c0db98f283933d6633006fad224f4ddf013e45ab443d12027e044d80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=869 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /tmp/t3g-module-build/tb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 824
- `line_count`: 9
- `sha256`: ae56d912bd5f07d8ed9beb7db95b76b43049e7b6738c70dfbed677ebfa7b02a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=824 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /tmp/t3g-module-build/tb_ooo_branc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 607
- `line_count`: 5
- `sha256`: a89603a501c7ba77473a01952696306179bb4b280b0cbb8408272a1741a986a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=607 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /tmp/t3g-module-build/tb_o...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 879
- `line_count`: 9
- `sha256`: 2f68f93a4acad80eb5b54a4106504d01633679e0b1b3a47ac2d86a39d9a5fd21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=879 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /tmp/t3g-module-build/...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 16580bd35b106a14dd9f9b8f32f330c10aeb2aeff9cb2069a3a2b74b92d868da
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /tmp/t3g-module-build/tb_ooo_branch_spec...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 564
- `line_count`: 6
- `sha256`: 3f40d750f9eb8f1c49d50c391d7b823d1025644d2ead5fc0dbb6d54fc72e686d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=564 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /tmp/t3g-module-build/tb_ooo_busy_table.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: ac3111846bf28de2a2af69c0d0ab288af4ab0a59f5e52635f9b46bf017bf0f46
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /tmp/t3g-module-build/tb_ooo_clmul_unit.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 782
- `line_count`: 9
- `sha256`: 5e51266e05c15ce50e5ee0468a2b5816505188ca858a3cd9b27574fd7d639cf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=782 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /tmp/t3g-module-build/tb_ooo_commit_output_m...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 847
- `line_count`: 9
- `sha256`: 818b75de162e69f4d9133eadf7ce74f3130ffb48091da828bba481fe5daf73d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=847 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /tmp/t3g-module-build/tb_ooo_c...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 834
- `line_count`: 9
- `sha256`: 393e000519c932b9c04f7cd63f4b7eaf175180e3d9237604a96a73ef7644d16b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=834 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /tmp/t3g-module-build/tb_ooo_con...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17095
- `line_count`: 78
- `sha256`: 549b2ba105b1a82ca6e037d0f4622528ec20a8a5571c0caeaf95287ff665ddc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17095 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /tmp/t3g-module-build/tb_ooo_core_top_glue.vvp /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 512
- `line_count`: 5
- `sha256`: 250673f2aacdbe2d96bb16857fefc29f6638565e020c65e8a2d123190c88e192
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=512 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /tmp/t3g-module-build/tb_ooo_csr_a...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: d3bc16e01326afca93ae507242e10e2c15ef9f6300fe67d5ac03b24fe6fad079
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /tmp/t3g-module-build/tb_ooo_csr_trap_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 5
- `sha256`: 1e279ffcc89d4a223f6c5199c563e20b72e95b40bd960cd814476f436ac88ac1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /tmp/t3g-module-build/tb_ooo_data_word_cache.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 5
- `sha256`: 460156d33a9cb4d3b40062b8cd4ea467ffd84e8d3cc717bd0f3da84f237d2b51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=520 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /tmp/t3g-module-build/tb_o...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: 4e3da01690c20aa872ca9d404aa87d3476b1e6600784c8eb21d967d2a4ca44f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /tmp/t3g-module-build/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: 39f09da30860a0144060949e447fbd3af57df6866c223451e73f7c334b3dcfb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /tmp/t3g-module-build/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8503
- `line_count`: 60
- `sha256`: b68c3de047ccd6cea126ff5de14d23f96345814d24ff41fc50cfe7ff3ab20e48
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8503 bytes; lines=60; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /tmp/t3g-module-build/tb_ooo_dispatch_backend....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89735
- `line_count`: 717
- `sha256`: 26ed22e99d2215a584c859aef17a29bfb832c035deb4daef768d85e74d080ee1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89735 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86478
- `line_count`: 650
- `sha256`: d2e91fb1df7a15585583dc2a15647df1cdb51f6d37be066747f05e60a9fc91fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86478 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86449
- `line_count`: 650
- `sha256`: 283bff8d75bc9c554fc67b28db5054dc013b3bf617f23efb58b5e546a25e6ff4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86449 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89413
- `line_count`: 673
- `sha256`: 71a3ebb51ba074e25ad0d65c1c75fa98a5ae012da5ebb7d6fa7d7913ff6a449a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89413 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 9c54d77b0b1e89f5daca3aea929e5943763033edb4dfdca386b3356dd795a6f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /tmp/t3g-module-build/tb_ooo_fetch_flow_co...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 5
- `sha256`: c8b88069da4225b66c4f2595d0f6f4548a3624e42eaf04fc57191520fa44d8e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=571 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /tmp/t3g-module-build/tb_ooo_f...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 625
- `line_count`: 5
- `sha256`: 91a955b1516da4be4d770546eea9bc20b609c9388cceaf2732179cf2344edf52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=625 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /tmp/t3g-module-build/tb_ooo_fetch_hea...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 5
- `sha256`: 1a03e40a1497fc82628019ec8f6dfb506a4abe4dc64fc7b9d7846d7b657a96e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=610 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /tmp/t3g-module-build/tb_ooo_fetch_packet_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 5
- `sha256`: 6180a7f3ab5d859d745d50b2ad7640454637cf871fd5aa3a53b6f797ad04198e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /tmp/t3g-module-build/tb_ooo_fetch_packe...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: 2f468122426a590b2b4dc669ccc1402463cbc329063bc090c76a9624fa3b06e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /tmp/t3g-module-build/tb_ooo_fetch_packet_fi...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 489
- `line_count`: 5
- `sha256`: 29c73b4ba62d68067dac61ab4f126f0a0b516144bee100ea4b603eead6961771
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=489 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /tmp/t3g-module-build/tb_ooo_fetch_p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 643
- `line_count`: 6
- `sha256`: 33d79fc8347ae92b29e6748fe08fa8bb80fb12fec1131f6ae7db4672dd6fe21d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=643 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /tmp/t3g-module-build/tb_ooo_fetch_p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87814
- `line_count`: 664
- `sha256`: 375d911ca145305bd993f1995a0289ad1556dc1a4ab876652da23ecdb2f08aba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87814 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: 09994e3dd29b1600faff5c746d2e5803d08772c1a22c52411225f01e950b49d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /tmp/t3g-module-bu...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: c7e1b98a488be65b748192078ea77e87c6f48dbb19cd96005aaf73ddf907d269
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /tmp/t3g-module-build/tb_ooo_fetch_request_m...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17105
- `line_count`: 78
- `sha256`: b68e1b5638c0c9869310f9dab58e1b01a3c4b56d58c8c4fafc2a98187df58c35
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17105 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /tmp/t3g-module-build/tb_ooo_fetch_trap_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 443
- `line_count`: 5
- `sha256`: 959130eef611abfb32403cc5393aa6d00ceedf6e5c97975c65f0e5b517fae29f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=443 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /tmp/t3g-module-build/tb_ooo_fp_arith_gate.vvp /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 460
- `line_count`: 5
- `sha256`: 2ad8f9441d166ddb07c7d79049198a65acc9fd6e3039d3c71bf6d173ce75abf6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=460 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /tmp/t3g-module-build/tb_ooo_fp_classify_gate....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 454
- `line_count`: 5
- `sha256`: b23a53b56307d2ea52f8bcf46dffea899f960a4d62da6d8e5fce030dde20f862
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=454 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /tmp/t3g-module-build/tb_ooo_fp_compare_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 453
- `line_count`: 5
- `sha256`: 4242e92a832969235609181016c2e2cf69d3e140410f4c07be77233c5687d543
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=453 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /tmp/t3g-module-build/tb_ooo_fp_convert_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3277
- `line_count`: 28
- `sha256`: c6709b9f92e52dc4b1d2a3dfd0423598ca3f2742b009752372377d3558668de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3277 bytes; lines=28; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /tmp/t3g-module-build/tb_ooo_fp_issue_queue.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 478
- `line_count`: 5
- `sha256`: ceede5f3944ffc6b4a3bbb326a512c114d2fbd3e4d4c3e53bd47000a6d7be097
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=478 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /tmp/t3g-module-build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1422
- `line_count`: 13
- `sha256`: ac428226b03313fd2c928b6974ffd39aa829f529ef2468449a4ef245ec550d1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1422 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /tmp/t3g-module-build/tb_ooo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: 12f87e4e78dbf073ef98a22699a45b39cdbdae0a5335a798b16b2db35f604d9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /tmp/t3g-module-build/tb_ooo_fp_long_op_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 739
- `line_count`: 9
- `sha256`: 47d7ae86ce415784853abc77a8ec1e6e3caa023d239f0bb80a936ebb8f060edc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=739 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /tmp/t3g-module-build/tb_ooo_fp_reg_file.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: 4332d156cc08dc03ea12d0ac9f71f74587a691494a7fbc7383b2927951d7312a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /tmp/t3g-module-build/tb_ooo_fp_sgnj_gate.vvp /home/ly...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 8df6297f107a3c2486c48364aa8523dbf4a4233bc41f7518b2b83ac37ccab5d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /tmp/t3g-module-build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 485
- `line_count`: 5
- `sha256`: be44b1bfca8664b587faf50bf9384221c10086e45df2afceceb650f36497305f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=485 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /tmp/t3g-module-build/tb_ooo_frontend_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 893
- `line_count`: 10
- `sha256`: 0a8b19b0e8fd4570d0bfb558fb85f641270d4c291ea7988467c3ce7e8126b98b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=893 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /tmp/t3g-module-buil...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 7
- `sha256`: c2de5f34dd90032e5a99ebe03ddb2a9aabd203a903cd85234e1ee7d21c4ef263
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=805 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /tmp/t3g-module-build/tb_ooo_front...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: d41b374d56b7e91e74ed29e45ae0d7a94ce50a32a1b5e2953053747118b49211
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /tmp/t3g-module-build/tb_ooo_frontend_run_ga...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 479
- `line_count`: 5
- `sha256`: 8c176cf6030c835360b0ed1fe5d7f9efd2252731f389030f61115e760b46de14
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=479 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /tmp/t3g-module-build/tb_ooo_frontend_uo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3523
- `line_count`: 32
- `sha256`: 15b1a34dd6a7dbe17a297bcf2d57f5fec38f8a56f5600aa2e0c4f84c5fffbe40
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3523 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /tmp/t3g-module-build/tb_ooo_ifu_lan...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 15345
- `line_count`: 103
- `sha256`: f399d7b1da6f7acb3ad97a1a3ae59eb20d5dac7ce09a3e11b8a3556aa71f6b1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=15345 bytes; lines=103; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/t3g-module-build/tb_ooo_int_backend.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7545
- `line_count`: 58
- `sha256`: 82c1c3d5858bea0301ae715eac3992c11460e7c9432f5ddec7f172d20bb57813
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7545 bytes; lines=58; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /tmp/t3g-module-build/tb_ooo_int_issue_queue.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52139
- `line_count`: 392
- `sha256`: d2fe82ccce2a97dc71dd43940baca7585410ee840bf861fa1b31bfb6cd532953
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52139 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o /tmp/t3g-module-build/tb_ooo_mem_axi_bridge.vvp /h...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 937
- `line_count`: 8
- `sha256`: 120093d1266499a85a29a788cfd93c581fa279283d93d81f8803819b4bd59bd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=937 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /tmp/t3g-module-build/tb_ooo_memory_requ...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 435
- `line_count`: 5
- `sha256`: 270729f6ce75765acdfed149a9981f0363edd186bebcfda92913d66229031de3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=435 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /tmp/t3g-module-build/tb_ooo_muldiv_unit.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1077
- `line_count`: 11
- `sha256`: e2c04b032a20109fa660018bd070eb0512a6a2645ff9c0fd993e988a33e6293d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1077 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /tmp/t3g-module-build/tb_ooo_p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 867
- `line_count`: 10
- `sha256`: 579a3c8b46653fb159220349a3d80335c9e094e311516bc901e55b260fb25fb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=867 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /tmp/t3g-module-build/tb_o...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 843
- `line_count`: 9
- `sha256`: 2059844c69300efae41595fac95840bfaa300b1e293e030dc8552182ea684c2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=843 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /tmp/t3g-module-build/tb_ooo_p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 712
- `line_count`: 6
- `sha256`: 8712d03a843a9ba92053e512d3f67473628ee05731166d10b8c6cc0f94add98e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=712 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /tmp/t3g-module-build/tb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 449
- `line_count`: 5
- `sha256`: 3a6bfc0a2724ae777e8fcbe85ae00110c0aed7f34bb587019f80b2d60d7bb501
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=449 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /tmp/t3g-module-build/tb_ooo_phys_reg_file.vvp /home...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17081
- `line_count`: 78
- `sha256`: 8758068f958d0bf8c436ea6c42d0077d5c40740d18919870be0f95cc6be2bdf8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17081 bytes; lines=78; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /tmp/t3g-module-build/tb_ooo_priv_system.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: abee881ab99875def3235e54a242a60a8c1c13f1a03e19e416293e630a245e9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /tmp/t3g-module-build/tb_ooo_ras_update_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 461
- `line_count`: 5
- `sha256`: bbf34e8c86992ebfd5c1c4db0cf2080cf65b04f9002a76945d23a10a45eefeb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=461 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /tmp/t3g-module-build/tb_ooo_redirect_arbiter....

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: b2397c173269a9fdbe3d36f6bd094521215d7f4a59408260d2c87718dfaae68c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /tmp/t3g-module-build/tb_ooo_rename_map.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 725
- `line_count`: 8
- `sha256`: 1bf743a0e101ebf4ccfed6f272dec690795b23c133d6a2b1568ceabe16bb87f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=725 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /tmp/t3g-module-build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv6...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 825
- `line_count`: 9
- `sha256`: d610d87a622ba31b34e666bf5a7967ffee36680d5a1dbf72c51f35ada2972f0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=825 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /tmp/t3g-module-build/tb_ooo_stop_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 958
- `line_count`: 9
- `sha256`: b0426188ef3e4cfcb6f5bd4214fcd41ef3edebab5065c665f11994e87555da0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=958 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /tmp/t3g-module-build/tb_ooo_store_queue.vvp /home/lyg/P...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155611
- `line_count`: 1113
- `sha256`: 9f83b1a6f3a1037978cc919950e0e3b98bcad065ecfbebc5afd05e1a87ceef71
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155611 bytes; lines=1113; PASS=2; tail=_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in arr...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 491
- `line_count`: 5
- `sha256`: 73940b0a7b58a01bd2769b16cbfad26a80120a710b87b8514665257c6fcf1129
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=491 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /tmp/t3g-module-build/tb_ooo_trap_exit_e...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 540
- `line_count`: 5
- `sha256`: 1e607c0ced28d8b83f0b0dd17639967fb4b5a82d7dd7e6377aba70032095f7e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=540 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /tmp/t3g-module-build/tb_o...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 3d6e5be5a43fc524955d2e5dc34be77e6a7111496c8f12aea3109e676bb7dd82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /tmp/t3g-module-build/tb_pipe_stage_reg.vvp /home/lyg/PA/y...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17553
- `line_count`: 134
- `sha256`: a3d211a2fa69597468a8e165e31900a7d6234c98a42dd9894cf907ce26aba69b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17553 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /tmp/t3g-module-build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workb...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 364
- `line_count`: 5
- `sha256`: 64276db612a2da20d912bf3c9045f91494fa1370adffd3ff6366febc3e2cb44b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=364 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /tmp/t3g-module-build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bu...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: bb71cf4accfc99b5ff65ec02479eec9f2014804d7574177db891b76856ed8068
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /tmp/t3g-module-build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/write...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests/summary.txt

- `kind`: txt
- `size_bytes`: 3109
- `line_count`: 103
- `sha256`: 66e348f7c696adc7a4a77241b4d3d9268c9490de665a9d954bcb87d635911b00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 188}
- `summary`: txt evidence; size=3109 bytes; lines=103; PASS=188; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/module-tests - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu - PASS tb_comp...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/negative-command.log

- `kind`: log
- `size_bytes`: 309
- `line_count`: 3
- `sha256`: 76c797f6814473ad2d8d48a58569399b3bd4590e619a792cd9e8a98db10464db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=309 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:258: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/negative/logs/tb_ooo_int_backend.log] Error 1 make: Leaving directo...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/negative/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13441
- `line_count`: 84
- `sha256`: a2aa5af6fb8df708a550457579bb10772fd5c34c5a4cb21127be3997f686d027
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"ERROR": 2, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=13441 bytes; lines=84; FAIL=2; ERROR=2; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DINT_FAST_WB_EX_ONLY_NEGATIVE -s tb_ooo_int_backend -o /tmp/t3g-negative-build/t...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-axixbar-paths.rpt

- `kind`: rpt
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 95684
- `line_count`: 4030
- `sha256`: 9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=95684 bytes; lines=4030; markers=<none>; tail=_32_ psram_axi_araddr_o_33_ psram_axi_araddr_o_34_ psram_axi_araddr_o_35_ psram_axi_araddr_o_36_ psram_axi_araddr_o_37_ psram_axi_araddr_o_38_ psram_axi_araddr_o_39_ psram_axi_araddr_o_3_ psram_axi_araddr_o_40_ psram_axi_araddr_o_41_ psram_axi_araddr_o_42_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-custom-focus-paths.rpt

- `kind`: rpt
- `size_bytes`: 461423
- `line_count`: 4237
- `sha256`: 23b914780cc8b20677f8f9570e3c71cc7a1c0ae0a387dc80983eb83c87edd14c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=461423 bytes; lines=4237; markers=<none>; tail=(NOR4X0P5H7L) 0.081 15.054 v u_core/u_ooo_core/u_control_plane/u_pending_drain_resolve_gate/_18_/Y (NAND4X0P5H7L) 0.255 15.309 ^ u_core/u_ooo_core/u_control_plane/u_pending_drain_resolve_gate/_31_/Y (NOR3X0P5H7L) 0.062 15.371 v u_core/u_ooo_core/u_control_p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-ifu-paths.rpt

- `kind`: rpt
- `size_bytes`: 461423
- `line_count`: 4237
- `sha256`: 23b914780cc8b20677f8f9570e3c71cc7a1c0ae0a387dc80983eb83c87edd14c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=461423 bytes; lines=4237; markers=<none>; tail=(NOR4X0P5H7L) 0.081 15.054 v u_core/u_ooo_core/u_control_plane/u_pending_drain_resolve_gate/_18_/Y (NAND4X0P5H7L) 0.255 15.309 ^ u_core/u_ooo_core/u_control_plane/u_pending_drain_resolve_gate/_31_/Y (NOR3X0P5H7L) 0.062 15.371 v u_core/u_ooo_core/u_control_p...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-manifest.txt

- `kind`: txt
- `size_bytes`: 1441
- `line_count`: 11
- `sha256`: dedbc6ba56b7ff3dc1bf80586dc16313c3f5c6e58a23fcec274f271956c72151
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=1441 bytes; lines=11; markers=<none>; tail=timestamp=2026-07-13T13:02:51+08:00 command=/home/lyg/tools/OpenSTA/build/sta /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current-5ns.tcl period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-netlist-focus-names.txt

- `kind`: txt
- `size_bytes`: 12275
- `line_count`: 80
- `sha256`: fe7b61630dcb0228f7370b9e6795f00f5f09ee6b8882fdf9c9d2256cacdfbfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=12275 bytes; lines=80; markers=<none>; tail=756196:, csr_satp_w_55_, csr_satp_w_56_, csr_satp_w_57_, csr_satp_w_58_, csr_satp_w_59_, csr_satp_w_60_, csr_satp_w_61_, csr_satp_w_62_, csr_satp_w_63_, csr_svpbmt_en_w, ctrl_commit_valid_q, direct_branch0_dispatch_valid_w, direct_branch0_fire_w, direct_bra...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 87d0112ba7589563802bd6cf5b1aa8998ef9ce2dbf79cbfb39a00f9e94f3a4b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.54e-02 1.06e-04 1.81e-04 9.57e-02 80.0% Combinational 7.11e-03 8.54e-03 4.65e-04 1.61e-02 13.5% Clock 2.80e-...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-summary.txt

- `kind`: txt
- `size_bytes`: 231
- `line_count`: 10
- `sha256`: c5f95020251c619e563f3e73b890a27c90cbba18d093d462c28f853bddf1d861
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=231 bytes; lines=10; PASS=2; tail=status=PASS period_ns=5.0 wns max -12.98 tns max -287092.31 top40_requested=40 top40_reported=40 ifu_top40_paths=22 axixbar_top40_paths=0 custom_focus_top40_paths=22 non_signoff=ideal_clock,no_spef,no_cts,no_ocv,placeholder_macros

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 832277
- `line_count`: 7659
- `sha256`: 09ec7276d78e49f53b2a9ff6f88dd1daf7a57e91633e7051a57a621a2e45f3de
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=832277 bytes; lines=7659; markers=<none>; tail=e_backend/u_int_backend/_64045_/Y (BUFX3H7L) 0.056 13.648 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/_64665_/Y (OAI221X0P5H7L) 0.055 13.703 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_back...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-dcache-to-fetch-payload-en.rpt

- `kind`: rpt
- `size_bytes`: 20482
- `line_count`: 184
- `sha256`: 5178ae448639231c07392c50131b07232da3f1d67239e5860181abfec1c38c39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=20482 bytes; lines=184; markers=<none>; tail=Startpoint: u_core/u_ooo_mem_bridge/u_dcache/u_sram (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_cloc...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-dcache-to-fp-exec1-stage-d.rpt

- `kind`: rpt
- `size_bytes`: 167340
- `line_count`: 1388
- `sha256`: 6418a327bf08ab2c27de2eedc1fa1600bd3baa4be9be5dfc8ec18b56a5e6f741
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=167340 bytes; lines=1388; markers=<none>; tail=6 ^ u_core/u_ooo_mem_bridge/u_dcache/_26016_/Y (NOR4X0P5H7L) 0.038 1.674 v u_core/u_ooo_mem_bridge/u_dcache/_26017_/Y (OAI31X0P5H7L) 0.063 1.737 ^ u_core/u_ooo_mem_bridge/u_dcache/_26018_/Y (AOI31X0P5H7L) 0.179 1.916 ^ u_core/u_ooo_mem_bridge/_3407_/Y (NOR4...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-dcache-to-int-ex0-stage-d.rpt

- `kind`: rpt
- `size_bytes`: 131441
- `line_count`: 1225
- `sha256`: 245430f08399574992cc32504542b0bb882467e178eab58ab956fc4bc7c191ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=131441 bytes; lines=1225; markers=<none>; tail=u_core_slice/u_decode_backend/u_int_backend/u_ex0_stage/_140_ (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_clock Path Type: max Delay Time Description ----------------------------------------------------------- 0.000 0.000 clock...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-dcache-to-int-ex1-stage-d.rpt

- `kind`: rpt
- `size_bytes`: 159255
- `line_count`: 1440
- `sha256`: bcd92ed1b6a265ac532778cebb49f6ee19abfe05c13cad1ee4f5de42858cbfd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=159255 bytes; lines=1440; markers=<none>; tail=nd/u_core_slice/u_decode_backend/u_int_backend/u_issue1_fwd_extract/_418_/Y (MUX4X1P4H7L) 0.072 11.639 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_issue1_fwd_extract/_422_/Y (AO22X0P7H7L) 0.087 11.726 v u_core/u_ooo_c...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused-counts.txt

- `kind`: txt
- `size_bytes`: 487
- `line_count`: 16
- `sha256`: 522db07cdedc71ee8eaac1a3c358c431ed2cb236007b4920588cb62cca63ad90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=487 bytes; lines=16; markers=<none>; tail=dcache_rdata_startpoints=113 int_ex0_d_endpoints=145 int_ex1_d_endpoints=145 fp_exec1_d_endpoints=82 fpiq_q_startpoints=628 fetch_payload_en_endpoints=1 dcache_to_int_ex0_from_count=113 dcache_to_int_ex0_to_count=145 dcache_to_int_ex1_from_count=113 dcache_...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused-manifest.txt

- `kind`: txt
- `size_bytes`: 2077
- `line_count`: 22
- `sha256`: d336593945a37d68c11954afd427b1dc0d1ed7c79d8304045b07e4adfdef38d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=2077 bytes; lines=22; markers=<none>; tail=timestamp=2026-07-13T13:10:34.9934358+08:00 command=/home/lyg/tools/OpenSTA/build/sta .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused.tcl period_ns=5.000 netlist=tmp/2026-07-13-rv64-t3g-mem-formal-only/sta-bu...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused-objects.txt

- `kind`: txt
- `size_bytes`: 119227
- `line_count`: 1120
- `sha256`: edf49e36498afba91d7d838330977e1cd4f58aac9afe8a8646076bb2970625cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: txt evidence; size=119227 bytes; lines=1120; markers=<none>; tail=u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_issue_queue/_6070_/Q u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_issue_queue/_6071_/Q u_core/u_ooo_core/u_execute_backend/u...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused-summary.txt

- `kind`: txt
- `size_bytes`: 2850
- `line_count`: 59
- `sha256`: 50510cceae1b68666cca9514965094c81296db3285216f46977cf610bd9103ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=2850 bytes; lines=59; PASS=2; tail=run_status=PASS acceptance_status=FAIL_EXPECTED_CUT acceptance_reason=dcache_rdata_to_integer_ex0_and_ex1_stage_d_paths_are_still_present period_ns=5.000 netlist_sha256=95bac1a0e1ecc0fe3154d1461997098caf0f8182760fb9b111aacd95f79ef7b4 opensta_version=3.1.0_c...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-focused.tcl

- `kind`: tcl
- `size_bytes`: 5559
- `line_count`: 131
- `sha256`: 33e7831038ecc645387bf04db2a85ed5ffb12ffb487ba6f1c0efa21e071f7f1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: tcl evidence; size=5559 bytes; lines=131; markers=<none>; tail=proc require_env {name} { if {![info exists ::env($name)] || $::env($name) eq ""} { error "required environment variable is missing: $name" } return $::env($name) } proc write_note {path text} { set fp [open $path w] puts $fp $text close $fp } proc report_f...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/opensta-fresh/opensta-t3g-fpiq-q-to-fp-exec1-stage-d.rpt

- `kind`: rpt
- `size_bytes`: 150449
- `line_count`: 1170
- `sha256`: cd078a9bc31e5a195eb27f2b904060b4237af64766b3df3b84f9785859d8d605
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: rpt evidence; size=150449 bytes; lines=1170; markers=<none>; tail=^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_convert/_07592_/Y (OA211X1P4H7L) 0.088 6.385 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_fp_backend/u_fp_convert/_075...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/red/command.log

- `kind`: log
- `size_bytes`: 312
- `line_count`: 3
- `sha256`: f744c8dfc92312ff79db15b26f32cf604bdebaf4c2072c06579652ac9e058bc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {}
- `summary`: log evidence; size=312 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:258: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/red/focused/logs/tb_ooo_int_backend.log] Error 1 make: Leaving dire...

### .github/task-runs/2026-07-13-rv64-t3g-mem-formal-only/evidence/red/focused/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 16387
- `line_count`: 119
- `sha256`: 0336771bb7f492fdc05af9521c4441194e663a03d13f253f5590938eb0d60881
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T05:17:00+00:00
- `markers`: {"FAIL": 28, "PASS": 2}
- `summary`: log evidence; size=16387 bytes; lines=119; FAIL=28; PASS=2; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /tmp/t3g-red-build/tb_ooo_int_backend.vvp /home/lyg/PA/y...
