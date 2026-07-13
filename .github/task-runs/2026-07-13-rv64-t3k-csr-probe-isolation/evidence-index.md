# Evidence Index

## 基本信息

- `task_id`: 2026-07-13-rv64-t3k-csr-probe-isolation
- `task_slug`:
- `profile`:
- `asset_count`: 1528
- `total_size_bytes`: 100846688

## 证据资产

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 359961
- `line_count`: 4549
- `sha256`: 6b35469c969cbab0a6c1666fdfc848693d29031aee5adfe9442f55a8f2a59f35
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"GOOD_TRAP": 21}
- `summary`: log evidence; size=359961 bytes; lines=4549; GOOD_TRAP=21; tail=top branch miss PCs = [0m [1;34m[cpu-exec.cpp:1600 statistic] #1 pc=0x80000070 miss=390 [0m [1;34m[cpu-exec.cpp:1600 statistic] #2 pc=0x80000080 miss=10 [0m [1;34m[cpu-exec.cpp:1600 statistic] #3 pc=0x800000c4 miss=2 [0m [1;34m[cpu-exec.cpp:1600 statistic]...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench.log

- `kind`: log
- `size_bytes`: 3402
- `line_count`: 107
- `sha256`: 6e9b9fcfc80ccd14709a0435ab3ae121aa0d7c4a0caaa0c2acdc7f779d04f84e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 192}
- `summary`: log evidence; size=3402 bytes; lines=107; PASS=192; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' # NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: c21f52e912aa67528d1b30ed60b67928737ec9ec6364290c32bc63ed064b2613
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 13976
- `line_count`: 85
- `sha256`: 0b3bb621155602db11a9f8fd3e10efc4541be8fe95467e8fdc5303d346a9fbb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13976 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 13652
- `line_count`: 83
- `sha256`: 1d7e00b8779766ad160a38c0bcd8a530b8e197e5067477ebe610d3a06532e882
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13652 bytes; lines=83; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: df346793b2fd8aae5df3e18e5eede8858ab4e62ccf1ff100cf64f037647301c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16520
- `line_count`: 74
- `sha256`: beebd8dd98bd72d819c64d93ffa7206345e941974c2b8bbc07b4ef042009b333
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16520 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: 46645325d912893ba660317f1d3edfd2fb39e0b6e26ac8fdb145947b85b4dc69
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8345
- `line_count`: 59
- `sha256`: 5da3a0b5f63dc55d1d96b7af61b4e456b311f3c4aa99c861fa4e89d73db46509
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8345 bytes; lines=59; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: bed4bded9ff9da9ee63d99f1ca3ca507575d627b4c9c6755b36801f5ebbf2b47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 4ec29a1cdff0f80e3f77c08bb3de14dc7d8fe49e2bc8e4cad52de8c9d873663e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 3998893851256d56bbb1a769e031b67cfbfb4f3ce45425ffd04465e415c22a16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 16530
- `line_count`: 74
- `sha256`: 61e162068e4318f10acaac58678f6221f312a257933ea0fb73c9ece99664c8d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16530 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3643
- `line_count`: 36
- `sha256`: 5bf4803c5fcf60371aecd4e0ad40d7e343b1614934213355284d9ba378bafe7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3643 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 12
- `sha256`: 73cf2253470a50eb3504d7bb3d41a250402cc47a6799641ca8ec049bbdfcf358
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=976 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14770
- `line_count`: 99
- `sha256`: fe93a4158503da8239ee1e4c3007c9c691607a96e9939742c2061f96879b1b2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14770 bytes; lines=99; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7816
- `line_count`: 62
- `sha256`: 5cef0c5aa0999dcc250388822cb7e98e9ceb56eb2b387016c91cb18db2ca4154
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7816 bytes; lines=62; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: edece60c135f85ff7b0f7696ed98bb7a8aa49f5d1b17ada2804d9b137a97bbf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build/tb_ooo_pending_drain...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 433
- `line_count`: 5
- `sha256`: 6e8b03051f6459e31cca0e186e2c3f11127fd8fb876bb0dfcb212767b79303b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=433 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 16506
- `line_count`: 74
- `sha256`: 0ca626018208b2f3c549efbeb51c3dc2a1b2d70d323bdfc95119b0377478032d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16506 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155036
- `line_count`: 1109
- `sha256`: 13a15ee16582fa5bbd8c09de5a596634b680cf4cd2f9a38a7835c15ed37ad17e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155036 bytes; lines=1109; PASS=2; tail=ll 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench/summary.txt

- `kind`: txt
- `size_bytes`: 3255
- `line_count`: 105
- `sha256`: a5d0a7d88ec4e9435010eededa907e7b9a48537bd6ff054f796960c287b01265
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 192}
- `summary`: txt evidence; size=3255 bytes; lines=105; PASS=192; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/module-testbench - tool: Icarus Verilog version 14.0 (devel) (s20260301-2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/npc-build.log

- `kind`: log
- `size_bytes`: 49802
- `line_count`: 61
- `sha256`: 04aa0c5e1d60f135f2f4251992d4abc5be2082326f8c641ca22b394e46735f3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__", "__4__", "__5__"]}
- `summary`: log evidence; size=49802 bytes; lines=61; symbolic=__0__,__1__,__2__,__3__,__4__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-breakpoint.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 759bacf90a27050b888263f901fd5eb0ffa9c3e8b10d9c2c1add856d31c28392
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-csr.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 4
- `sha256`: 64ea22733c1c648d458ed72ca058e8e6cab07bf1bb3a405c30194b124d72ea43
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-illegal.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: fe618512fc09c6bec94ec603c2d4669b6f9225895d1018c00296d4ae648e9453
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-instret_overflow.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c7eb752ddf7df2836c15e057636b2b3b066bbe61020cfa1fcb7667044ba4fb74
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-ld-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 10
- `sha256`: c44e62773c367801944447046f471368c167a7b46cc18ff61e89ced9b1e10b45
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-lh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 0a625bdb1bde894e591b08910e9c522dae78cacf6f215057e5084ebb7215469f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-lw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 81a2d0f7543c87aab91ea4ba7f6df69cb54772b8b02fc1970baaa2dec4813138
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-ma_addr.bin

- `kind`: bin
- `size_bytes`: 8768
- `line_count`: 11
- `sha256`: 43aba4a5ed598e42eafa14d04575df2738a9dc1b2262e599788408accf523041
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8768 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% �s 0�" �...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 6
- `sha256`: 23128cb88a441f0ec5b0aa92e3ff235468a97a94e292d35d9092ba02c0cd6d75
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-mcsr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c8ab2c5fbb9cf529518ebf007812028ad1dc524efde5bf2edfaa20c2b8a3df6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-pmpaddr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5c82f4f85902b25a1496ffba37f4338b26a971da939e6921985125def9242a2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: fab026d76c46c8506cb94a08cb632f2de6937d8b057204464e3e2cdc019780e3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: eb468050871ee3c797254f90c6571b5dab04bb018834af2c69265c0274a165b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-sd-misaligned.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: 580363d39fef7b89f9e2e386be8a7e60ac3fd56c1df679ebe3ed5de107573e9e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-sh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3c3de98bcf0acee9619646b0ace0b28ce19cad50d97d6323aeb3e30866219c48
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-sw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: e0715db1e4a9e3efd1784bbde55edb741d3ae50f551315ce987e5434a5683aa4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64mi-p-zicntr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: aeadca97e007d646ed5565e489bf1a0b805cfa321e996930effd2ad4bab21159
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-csr.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 5
- `sha256`: 2f7d31a97b4a1a8836b5b16b048e42d6d3be2d02275a1bb9e4810b27575a72f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-dirty.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 302f824e3cbcf3b842793355d42fdc5011dfaed03e59cec2ab8d1b4831766a3f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-icache-alias.bin

- `kind`: bin
- `size_bytes`: 28848
- `line_count`: 4
- `sha256`: 4557a25ddcb7abec27c88269b480cb0d7ec7fa64305725d29d8d3c0a52f7dada
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=28848 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �r �� �s�R0sPDt�r ����s�R0sP �r �� �s�R0� ��R ����s� ;� � s� :sP@0�r �� �s�R0sP 0sP00� �r �� �s�R0 � c\ � � � � s �r ��B�c� s�R �� ��� s�"0sP 07% �s 0�r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 4f38f4a5a44b94c3317295c23666c5c5d6eb5d5aa6978b7de5509ec65f3ae17c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a27651d09a02b29a03a577555aa3571f8196280aa72cfd8baf0f3fd7b8778ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: 16442ae5360eef6283fa542a660128ff90f325c6385c4f14561403282e63b9d6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64si-p-wfi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00771ff518788f921c94a744180cc11a58d4c6867a7a28e02f20735727e41927
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 4150f7116a5d1ad9544d847f718a27dea539caa5cba32d9db43c0dd3a320cd58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 23ece6fcfa411fe3e9ac8aa2d73a60054e39446808a1551d3feb2c97cc438b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 23d3611c19094402928bdffe805fa8532d82fd77c90420ad9dcbbf546b86a250
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 4
- `sha256`: d235961f7c7c03e9da495ec9a846dad59fd750a8fd31c7bb767a01e623f0b31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=654 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 8474a0af82ef8d14cf5dbc04104d884ee96562d91ed90a22bc87d19350c99f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 6d07c6e4fe8c1fd8b3f44f7dce5500299893ea370f733c6c7e01c48e4b288072
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: e51c2a9f92c0506b9df3f6c48a301a8889b7ac5b3931ac4dcba1a9b2fc2721d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: d5963171dedae952ba273fd6c4b0ef70b6f28a179dafb069832f8f662f963179
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 99b16ce02f59f4a136bb747ddfd6f2348748038875ad51e6bb0192e691402068
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 62379170ad5bb6cc61c4b4dc0ff7e91a9fdde586f642c6ccaee4c80eeb1f3d62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 7b980a18a7a0c0f1265bd180a9ad1db93e8c6cab0d658640d820cb92a3eb9b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 9099de3acbff7f1453867efa55acba173e3f713d751107e9406a5e76a42fea3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cf030de16f0944357c4675d1bcd66e4c9ff80e240125f9290aadda6d928d2760
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: c4a66350fe2e3da52898d8665d719115bc88db0ef8aa4e2c93e8de5ed2e29de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: a22f5126c64613ddf6fd55ea6331fe76d4a0a0a982cbabc5cdd66da0ebc03e51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 237937babe46f052aa4697ccfa94dd5d62fe6e9c4f6ba2ed91df161b8bae8989
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3c5cb1679bbbbdb5587f3c2e0afb816204ec847dee3ec85268b44979b7dc56cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: c2afda182606f2e0a7e63e3474d5921c3aa8471978d516a44873e5c06b70a2ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 107d85d30c6e216d76cd6b59c73db64f75028be38ce1ee747124bff1d6ec90c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 1daaf37379469b4eaf41802fa680ed3c8c7bd6ce953df9c84d4915f239d4d641
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3b729d2c2d818c320db5ca4afe7a1f1348264eb2ffe0eba7ae1049417f20391c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3fb8dc5558e0ec98c7af988859a3cd3baca8da9aea3728df9d7cc85c7fd8bf77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 00b93d77799a70c2e3b84e597ee4c06a7fcea19dce219d84d8aee420edc53bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 8e0c3b0be49d00964fde252f04e3087506e0de98cceb587a5ab3066efb41ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: 439a879d0339470a2e1cd30824d7d8dc608240849187e721bad88d7fc4d08ebc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-breakpoint.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 5565
- `line_count`: 66
- `sha256`: 7734404d63c0c7a7a935549426e41354d3167b94566c3fc5af5e55766c969254
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5565 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 5721
- `line_count`: 68
- `sha256`: d407c1f896b8a389b61c69776b4cdddf792609e3e2cf7233f53b516139aed9d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5721 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-illegal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 5341
- `line_count`: 63
- `sha256`: 794319777c2a68fc12402e48ea0b06d9893f4f23d9b3720256e4b766f0af3ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5341 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-instret_overflow.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 5569
- `line_count`: 66
- `sha256`: c951bc7499a0e5c7d9cf2dd2a059ef68b3a640a303005b4eaf5e7471c499fdc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5569 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-ld-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 5340
- `line_count`: 63
- `sha256`: 9eb36cf27d00796186d72481cb20978b5e4946d002b6a7ab4aae04b00dd1ed2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5340 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-lh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 5557
- `line_count`: 66
- `sha256`: 48f8ba53b440cfc1649deb8fcd21df2046423c254dfcf2fc0e98629fab0f0e8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5557 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-lw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 5507
- `line_count`: 65
- `sha256`: fb1197332d388b8d382162b2736de9a14805993b8b646685033bd5f8b50a2bc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5507 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-ma_addr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: f174c4f5920fdc981a568bed230dec5ee2e6217f3492703105fe530eee3ea030
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 5402
- `line_count`: 64
- `sha256`: 0482c31f2971beee3c12c807bc3703a45d3c383856bbfa3113d5d22266796bea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5402 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-mcsr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 5393
- `line_count`: 64
- `sha256`: 9c94ddac20e1c384d2aa6c9873589444498cf43a26c139adedc4244dcad33708
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5393 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-pmpaddr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 5076
- `line_count`: 60
- `sha256`: 42c76147bb523850f4201a0d23c4d949f52e723637534323e2f94aaddded89cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5076 bytes; lines=60; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 5256
- `line_count`: 62
- `sha256`: 5b19608a10c02196f297b69f7bc7c9119ddcf4403b7204985babee113b6f022a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5256 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 5502
- `line_count`: 65
- `sha256`: 7bdbeb349dfddd9719489199224beb32c671563d80f0381921fe6fb77b305991
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5502 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sd-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 5416
- `line_count`: 64
- `sha256`: aab8e7c79eb1df8589d7b6a849a0f37163579efcc1be882cada23bf3c71d12d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5416 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 5424
- `line_count`: 64
- `sha256`: 6d47a5c5b7b6af907526620229b45f0233c56fa3707d017792ba03c6dde7f4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5424 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-sw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 5412
- `line_count`: 64
- `sha256`: 376d7e53d682b310adf96b97eaefd1c828e002298fbc4dd626c6fc2de3698f1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5412 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64mi-p-zicntr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 5489
- `line_count`: 65
- `sha256`: 7036f6e1665ca38ae69b9f3db494b566ab92324ce6c5159cf47b720c6c155253
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5489 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 5568
- `line_count`: 66
- `sha256`: 88d59cd120040ecf7709c00e97254f21c5faf2db9a5e4fbeb2ca4a13e0d3041c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5568 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-dirty.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 5443
- `line_count`: 64
- `sha256`: 6361862598c063efa9ccf849b007488cd2246f3ebc31a2e876b99c628f28d3be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5443 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-icache-alias.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5486
- `line_count`: 65
- `sha256`: 3046c19cdbff1d08de5c0b2f9a87e150a81ef1c614dd622069393f7a7ba4de85
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5486 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 5145
- `line_count`: 61
- `sha256`: fdfeeb1aee4420f1b39c221b0437a147e7fb4f39572e0152ae11a4dfd5450b70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5145 bytes; lines=61; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 5615
- `line_count`: 67
- `sha256`: 676e6504cfc085230605ef01ab4b306c11e03df584aae5f2dad08c87ae190fec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5615 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 5320
- `line_count`: 63
- `sha256`: c14d20f82eb07d9d84e92008c8b40df8333a3c9fa8816866d383ca328f6f672e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5320 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64si-p-wfi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5266
- `line_count`: 62
- `sha256`: df81a6060b28f195c25905e0c5d086665395cc78d2fbcb0e83e7fd1cdb29df2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5266 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5336
- `line_count`: 63
- `sha256`: 1377cb76915212bfec968cd8e177dcb602730a4711e18fda8860aeed41a5d0fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5336 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: e2d47e6aca093e6e516e33e306b599b541f1ea713132b4551fbfdd5a1f5f698a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: ef83ed7610edbdfbabcdf217ae25b8e3d07aea8c766dcadf350abdfa757d3d24
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: cd1c32bb0c101a0889503357c2b66bf8a6929d26c7ae54993579e697360bf888
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5211
- `line_count`: 61
- `sha256`: 58c0232d067f1f4887979adb6d77467d7575af93a25e0383e4b5f99ccb554b60
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5211 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5266
- `line_count`: 62
- `sha256`: 45d28a73f68d80c36e3d423d019de2391783b489e345b2be0e2e1e3f2bed8c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5266 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5212
- `line_count`: 61
- `sha256`: 048959d1252727a64f1c543346e643d63b2a2bc91b3aadb9215c8e04d0f36083
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5212 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5265
- `line_count`: 62
- `sha256`: 2ac7ec531dcd108dffe29f34f3459482c35340c44bb520ab14ef1375137e47d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5265 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5211
- `line_count`: 61
- `sha256`: 6f2ae5801e7e806bee9fd80580f189f02a28708e5cb5db9ea5760482f3e2249a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5211 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5266
- `line_count`: 62
- `sha256`: 68461da7b2be016b5b53c8627c89feff39b9c98345594d97c8731260bc458985
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5266 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5212
- `line_count`: 61
- `sha256`: 364abf9bf86f51a0838ba9a1278ff8e228a43748f9cd12e117a3f21cd4ae9385
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5212 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5334
- `line_count`: 63
- `sha256`: c526d2ecdd756f800535d05ffc37ecc451797e5400d7ac5ea511fc2b1a7b43fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5334 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5334
- `line_count`: 63
- `sha256`: 6c3e54623ee3e42b3534eea3d70b3a7bcbe9fed835cf238bfea95d6bd8f87388
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5334 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5266
- `line_count`: 62
- `sha256`: 247d51109a3b70fc7850309d2065c78a78049933b740e676b5f2a440aa24d31e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5266 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5266
- `line_count`: 62
- `sha256`: f3b13434f8c22cfceab56fc5f3e8136cff74478a4401b0fb4865ce916b63f4c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5266 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5335
- `line_count`: 63
- `sha256`: 816ef687ce819e2ffc9b231d0290da54334daa4f99cd05017e31bac3771dcc7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5335 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5480
- `line_count`: 65
- `sha256`: 50132d39cc802327bc9777cbfc4a5b19e717856262f3cbc507f9f7c8da1391aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5480 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5637
- `line_count`: 66
- `sha256`: 20ebb6756572c656117688d66207323fdf2a09fd55b756299f49bf3a266084b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5637 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5642
- `line_count`: 67
- `sha256`: ee818755b2dfd30b236356f178ee05cc731424551e1b490ab1b7afe6fa22be84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5642 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5427
- `line_count`: 64
- `sha256`: 01372bc2579c62b24d16a9f3ac592018547f5ed3e6a570ea1009979a017fd595
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5427 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5479
- `line_count`: 65
- `sha256`: abaef3980880910afcdabbdf3587f28b67ddd02e5236fc5b1d320c4e84255a54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5479 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: 4c560df376bb03d45f40ab98f94c50923434ac116e661e7933e6234addf8b9bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: 78f5d65958a8e027e177e52b1d3d2e461e0977cc8a9a86a993512a757b5d7431
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5512
- `line_count`: 65
- `sha256`: 58097e5212240384abf20e00fc2bcd500ca736dca9aa801711d9408a07ada3ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5512 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: aedf0e987950c706004637cfd9e360ecd7f7f02c5966f74eca72a07e1b3c02db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: f97e6fb2e73a7417ce3471229aa1b80552861f8618aa97870e5f8a0ee92fa0e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5500
- `line_count`: 65
- `sha256`: 815ed1b9ebb60a40d8681406d4941794c361e99f9924dde50414c9b03f127d21
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5500 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5343
- `line_count`: 63
- `sha256`: 04e12052bcc6947524d43767c4f76de8d5b00c6d322a98b6efeadbcbf4fc883c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5343 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: 3169b81cf68d71272ffc0dbe3a540265b8001510cf72f4f09dee6b51eab5f0fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5210
- `line_count`: 61
- `sha256`: 6b42a5498b6bf5cd95dbff408e6c351e0cf21308a876d89d9949d2a7f303d977
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5210 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5631
- `line_count`: 67
- `sha256`: 999cfc6919dea460c592c795aa3ae2146ecfb4e0b9396366c55c0938e1ec0beb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5631 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5428
- `line_count`: 64
- `sha256`: bcfb01dc7387a1a527207c890ac49a227ef090732a0785f47908497974e0a304
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5428 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5480
- `line_count`: 65
- `sha256`: e42b5750655413bc0c5a6e003b3ef1df1cc2a192e600711c57a95dfc087d33f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5480 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: 3ecdc02203bbec8a862ff93824a74bfc9f178fed95d5ac5ce3040a8fbbfd040e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5349
- `line_count`: 63
- `sha256`: 46eaa240633ff4c279b7ebb0008cc6736f3880261b4a50aaab3be0fc75f53387
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5349 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5508
- `line_count`: 65
- `sha256`: 3c9a5d742e796cd77c9c6908deec00925c360ed6ccf918001bacc4d9d5b9583c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5508 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5493
- `line_count`: 65
- `sha256`: 619939774b304fea1f639b9d1df0149bc1868cb454770852bf7b48da002a4536
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5493 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5499
- `line_count`: 65
- `sha256`: b4569ee7304838af1d93d53f69ff078ee47056c6199a5b7beaf5ec6143a593ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5499 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: 0db86f0d6f5c51972213ffc0e54666f1b95741ddeff3a1cceeef8fdad64a4e22
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5267
- `line_count`: 62
- `sha256`: 66250f956e2ee2f292084b120e85bdc0c8c0c91261dbe8091d9fa7bb28387284
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5267 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: 7132f458b4b160864611361d0c52be5ba831b43f549840f9d202280cb71be349
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5274
- `line_count`: 62
- `sha256`: 6df1c4b01c6b39cacc9ae1acf1e0855e696936d715dfe390228bc3c7e5089260
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5274 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 1a4d8080a038f89fd4c53b3d955754b68bda323b984a8b07a74caaea0a097c1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 57a6b42ed958c1e9e25073a1515a0ebc5020e6286d54a9d2f4c225b3f3bf72e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: c6f666f340644343e1b9a0f6caea9d1a07fa3343485b44c16125636a9175eaa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 185daa2a5eb51185908d5c5e43a64e61af712267073b8844e687e5ae9e9672ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 086cd9453bb852fd0e08779a5987df676fe774040edbf54a01a73946e30291f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: f705e406e9626f95ef6263fec47b6ad87c2acafad6f29ef891e932efeea882af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5259
- `line_count`: 62
- `sha256`: f1ca9c2c39785ac0821ea8115addc9e0fe9ece0b8ca9cfe6e7078ccf17ac0db2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5259 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 51bc6c2875f66fe74ef7f981486ea840c7a24d9b431c4098a5eae5123c78d93b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 409b05e3644726255b56c7f3bfddf91a1c3ad1738882e837be4cb7cea0cae6b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 231526d17a417f14e7ac12eabaff0abe06c9d2bd4f54b15b7abda92da5df116a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 3461466cb0668f5c0e8af0c6fc2819604c8932f6e08bfd2ca99ae29bb2423126
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: fc39516226c0937bfc0a47c98f9990b1bff1e7d61de37ca02e95a53f36d79be1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 01b5916f0a60851e04ede150e9bcfcef736716042474bd76a0e20c93bcefe880
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5509
- `line_count`: 65
- `sha256`: 64dc1c6d883aa2bf0a746c7e35915f59911030e0414526354253e85a81982121
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5509 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5249
- `line_count`: 62
- `sha256`: 1e77350a3f9e01498d8788e7621217077dfdff0c735243dfe56b97e7d204d8cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5249 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5629
- `line_count`: 67
- `sha256`: 828a5559bb341a63e73425a71da6e56bbcb17ad70da53a77264cfd5c7a7fa758
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5629 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: d09cc74294e6a533bdbbc920eaa6d3d7a7e63c92e6978bd958ea9d8a3bc9645a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: a26d8d17c0e3bd28f627fa94fef7e0b48d1cb38685528258eb68d07a0bb95e44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: d7d20712c8214ae39028e856c06c40c06bc6b01c5978313b0c9e2d4db9bbd6d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5748
- `line_count`: 68
- `sha256`: d64e6bffe876ecefefadda16dc32284053e5f14682a46e0bb0003b85af200147
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5748 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 1fe044c3031a3bd2f4daa9536f9b7d9a74b039754c8e6c9a43cc238e36c64e2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 4a712633f496998be0150c6ce35f48d28901710966b47c6cfa0381c15fdb5295
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5328
- `line_count`: 63
- `sha256`: 66ce2781785364d5758752d4ba3b4d967a9da9236347e46db4f4f99d4657e574
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5328 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 3ad4c1e0b3179cb92937a240c0584a5f5f73a9f43219b2e234b894fafdec9091
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 41d9d805477cd5fe36f33defba7e43aab4b5a3ee22d69a5a13b101902893caab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5763
- `line_count`: 68
- `sha256`: 009a6aad15d13a4a9e13f8584ad14c2a348e89d5cbe4bcb6044182bd5b0417b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5763 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 4d6251c2997806f9112ee030bb43b41731a7000e513870e571721f405cf61d4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 31474f46e2c2ef992758bdb983ca8caa716c0a200e75cd1cdb168e0664562349
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5715
- `line_count`: 68
- `sha256`: ec3ccb62435e20021323a88d21a122b7fbfd563d49bdd977f43d8e19f9482f8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5715 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5717
- `line_count`: 68
- `sha256`: 61941422d204d1ce868b693d70d38e2261dbaeeccd4d4de42abd59c2954c45eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5717 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5717
- `line_count`: 68
- `sha256`: b85c94ed3cb695a5f3a70e00bf8095e976b6df521375b9ddfe20ad76362c1704
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5717 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5178
- `line_count`: 61
- `sha256`: 4e19b6a8b851c1bf4eccae1af6b59d69e0a51eee471693ca614eeebb510cea43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5178 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 53b8e4355075260b4b46bea42039b5883cf2b3c23176aa43fd8512d4a0beedde
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 0a054a0406f08d141ba1da7514f34c19a38fa98277841a2d0f48ff8ffd07df8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 23acd8d665c728919df61197fcb3f8912d5647c094f9e281a9841c3202671f47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: f0054d9a1eacf23db2d3d86d78865a5440ba1eace35b300f8c4d97f636f44277
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 033602575e55fa29b47f526d27904422f3c6a6ef541b65dbea55bc113c33b123
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: c5dc26ad259d2ab4e1756f73b0dc8f20b6a0216597b815c5ced90926b3254b6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 6d766eb47058e38483f387d02715b9622bd1c63e77fcbf4ae71600670e02e81d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 3235efaed71d94411d5418ed4b55a4a495bcf4394fcf4680f60f89fb836dca47
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 4471dd26b4c1713999ecd2f92c61e01c2cf295481036927d694e21492f3123a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 7ee15f8f33fc41c72cd41e2233916be93c3a8b492f369f279aca2c7583d7403c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: d8efbaeef90651d211d05bd1b18141a8a3818168af31c4727abce6e859ef7180
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 1551a3be4e3f8bcb51c7bb1dd39d7c175df8c303685f264e42e682bac4acc2c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: d346f674d280302b33051efba63cc6a7bb01e0512f2e19c4d895ed52624f391f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: e63d59df2224a75c5d3883bddb4bae437ce29dea77de3498baa58276a9947f7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 0b44b811f9012804c17a6aaa0e8467db2782a15e1cad36dd4281521d05ff50c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b6ad8fd6cbedaf32f3dc2baedc20ecf102724b6f245d2891947620cdddcfd356
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5509
- `line_count`: 65
- `sha256`: 42c27e17da2aee0450c0bdac1f3597214e3f91cbe86044b5d40dc0d8ebcfd4cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5509 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 1eb4b5fa465186dc80e46a0beeb555c7d87d53c0062619ed67a9e83391a721e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 2576d1684f59888fa9af4e4eb88c2bd57d3a7c0869435debe9ce25fa9a8c81ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5717
- `line_count`: 68
- `sha256`: 0efe648c596ecd84f49012409bd6e76f14b0adeac9f7dc5e544f55779a06cf25
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5717 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: c1540220a2ebf1f7941881ece58a321f545cd3f732c8629a28eb24aa022e0791
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: 3bcd584efbb327dcca3bc1c084b27a4a944c1feb5aa7e8a6c08b1134f36dae6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5338
- `line_count`: 63
- `sha256`: 5edfefba9e5f083be69de26997b5a61fe45ab6a01230dc637eb9c1b82d8d140f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5338 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: e9ef0a84ae38cd54d73dc8886df40857e5b8224c5b7986b5f8e058151c4d4576
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5341
- `line_count`: 63
- `sha256`: 5e3f4f45ea9d5b1454443bb1e12b6f88af18d2543351b9dd1cd4d19daadd5c12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5341 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5477
- `line_count`: 65
- `sha256`: 930095cc2fb09950a38191ee322228f07362c8d8adc88c5c3beedf12091718a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5477 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 8c2d4e586239def6f1ffcd330a374fda002d97c2a160f91dc4a8ac11e44a8d11
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 257d91205cd2946decd6b3dac827fd508e8caa8151f28a57325c4ea9e55251bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: be1afb5b38ce80b8be21be726bf69e6753bfe1fb6515bbc9838b5f776238d093
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 62716a10dffde81f6bcfb28c8e8cfc6f42936f12341480d407271278e075a0d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 43022379509ffcc14cb26c27afdbffddcc2da7c9f1670c4835d749325bc5048f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5473
- `line_count`: 65
- `sha256`: 2bdfec936de78be370e808465d5cc111b6460bcf25d15288d083bf4449da049d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5473 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5339
- `line_count`: 63
- `sha256`: 064c7950bb75c50546c172dad24ec9365a5660f353f1f8f83747a4a01bf00132
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5339 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: 00c6e5948855b70d409de0923ec371e4ce458185a17a1d5d07fd41a3c0c61ad9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5477
- `line_count`: 65
- `sha256`: 9e09bb455b90d04f805d61e85e5ace6f9814e1e259c97510ab652bf57fa9e8f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5477 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 2643e3550367f331764c8d0c60380fa4437e7175672fef17a391020d75f48aa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: b4ba601f47f5be53ba3356dff2bbd0b6e4c58c9e24fcc264347bad5486b7a029
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: b5c0a0cb3dba9118de3d37cffaeaaccdb2feef3ae5b5c09f978051e90e304ae3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 1a6c359c5f2f5355bb53e5e13fda795a6ccc12c07c6baf0c2e16f3377d8633af
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 5b001efb2ded884a31fcc0b73dd61b516a4894128a494e5ac5246d57d9862f93
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 9bb5f044db45cc44c88259bcbf2e419ba89d5ef81912d25817f4dead12a1eca9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 15e12d91bfe4b065fd8ad952627bba753549cc40e4bca2d9b9dddb14ac83d97c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 72ce64c1cb09f0752c9cd271ae399bd9f7affa9057e3b1b9cd4a349937bb9819
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: b4f143d9673155cc9c7a859d2c1911493619502a73dbb26de503460d7da7fe32
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: 87a56355c540453c720074f9490ae4789ef64f0da8cd68861dc8c70420aa00b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 2861f0c44bca31024cd76226074f3ccec07d269829b596182e23bcdcff32c037
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5492
- `line_count`: 65
- `sha256`: 117a8b4cd88651ef2bab41aec32db43486917340d3e62242fad2c9b6c36eca7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5492 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 604da5f6171ae7da12543e4a4592e39f8d371d6072dbdbc1627b835b1068df9a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: a2f9e7cb1ffd97156c23f7b56247125444e792fb76336472065774d531d0c6ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: b1ddf7211a63febbe1a6ab8224daf1fa021633ae85aee59f2e478163b13ee9cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 9c445ba06bb3afcba7d9c95126bcabafe64db812bd9d16b595ed117871a84b1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: b6280615aae8606a683c977bced3f4e89d78a739e1c93e53522647a0c658fdd4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 444f0875c2173bb690489f34c6a2ee88e1e8d6fc9d97a817ee0cafa74b553fc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5705
- `line_count`: 68
- `sha256`: 1ce8b3a0f8f73e77974b70e3439d289e0f6c12871caf3ee36d6474eee654d867
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5705 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 30c949749246b085a29464dd684cef8ad7f873b26f6d74786fc5013488cd063d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: a632311564b0875a4bbb57257a9015af2a863f2e29d2aa2b2dfd6b2071eeec84
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: 7b5784bb8c1c180c6c93f9e17b65e8bbfdf66f5ee20344be26e0121040dcf741
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: bf078e8d1078eafc6ecc14c52b368b8d4cc6adca6c5661296387e45d325c99a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: f8166046ea79c56b2bc43b4279e54e3b30cda820890abed3dfa5bc4a6da243b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: f8079888f51644a3851a5e5f34bf4837cbed12229b34d7030151caaca7fc43a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5702
- `line_count`: 68
- `sha256`: cef117e54e78fd6cff9cd5b978575341f498c579b388f0ae48473323fe34de30
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5702 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 0e0d43f9f670ecd84845c4a9e6cddf637216305793c4d39c804e1d26c07654cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: beb001a9917df0ddc98ed36b90df379e836f3d32185f06eeb23d98fef7837030
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5494
- `line_count`: 65
- `sha256`: b0a1db425c8ac56ebd430178cf696cd1952cc95ff82f8f7b00fab4c9aa0313d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5494 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 5c9706c51c8544396c7650d482e2a842d33e2561551f0fc5a888a4a21582181a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 7cca98bbb7c0e71f1cb8ad1b4bf29cab49d76b6da88be3f4b60509a03e2f9546
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: 673f5e5b7873bd57ce614024474f104c68044ae97da5edffef54b5700a00c0eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: 16aeb8995489dd01aba607eae1b8ccdc59da59f46dfb71c9f1e828e6837559d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5711
- `line_count`: 68
- `sha256`: 80eb22e41f9d073932d145138180a8778c39ba856c08962b49c375cfeb6e4f44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5711 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5712
- `line_count`: 68
- `sha256`: 96673ca4e70bb3992abaa1639a26bf01203b69cb630cbe052af89a8fbd14b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5712 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: cf02c497484431d293dae25be869ca0406996590403015369eb174c487b6d195
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: bd0811641f70d18f4bb7d49d81c10ad30958402037be07d529bff25c4609b51d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: 09b3ba15a2f17ce94659b2554f6e7dfa32b5bf72ac08d9b83ca560e289260a6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 678a35298cca848b101a3242eb65ebc60a180f4433b04b0351a6e7ab59b9ae92
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: c09fb6766170b6424e9406a420c90cf37dfc50858ce6061d84bd15d554731174
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: 5e654786dd5af4a56d287d41c8c56a5a289c11fd3d47feff423cd150ec378c13
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5707
- `line_count`: 68
- `sha256`: b98a286129e818f6d082bee5f11dc68ecf6f9de333dd759433e48bf3fd24706e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5707 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5703
- `line_count`: 68
- `sha256`: ec6debe054c6af6d24a3496ce6cab9297eafc87ffb879e0ac16b722ff8a42c24
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5703 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/linux-logs/npc-linux.log [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/status.txt

- `kind`: txt
- `size_bytes`: 17953
- `line_count`: 360
- `sha256`: 6331b8133bf6a2f9565da82d98a66e8297454f4b266e02bfba07741e38a5ce54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=17953 bytes; lines=360; PASS=718; tail=module-testbench PASS verilator-lint PASS npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/summary.txt

- `kind`: txt
- `size_bytes`: 18002
- `line_count`: 546
- `sha256`: 62f29574a3410ee4fd50139ee3fa639cfe6e2064221e7bfcc129ae5c2e6badd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 718}
- `summary`: txt evidence; size=18002 bytes; lines=546; PASS=718; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uzbs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/core-regress/20260713-180949-3008402/verilator-lint.log

- `kind`: log
- `size_bytes`: 8830
- `line_count`: 6
- `sha256`: 8dc1a5392d82cfff9ec0efe826105ce6f3ef00f34bb9b14ba6cf8c101594b773
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=8830 bytes; lines=6; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/coremark-clean.log

- `kind`: log
- `size_bytes`: 258
- `line_count`: 3
- `sha256`: bbff8c651da9ad82316dc5f938f6f207d027678972a92291470b2941944e1b06
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=258 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' rm -rf Makefile.html /home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark/build/ make: Leaving directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark'

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/coremark-iter10.log

- `kind`: log
- `size_bytes`: 8315
- `line_count`: 109
- `sha256`: f7cc8e30a108639d301b7da80fe295a4032e7b3dcbd73ce87f73f2a330d29c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=8315 bytes; lines=109; PASS=2; GOOD_TRAP=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' # Building coremark-run [riscv64-npc] + CC src/core_portme.c + CC src/core_matrix.c + CC src/core_list_join.c + CC src/core_state.c + CC src/core_main.c + CC src/core_util...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/complete.txt

- `kind`: txt
- `size_bytes`: 856
- `line_count`: 14
- `sha256`: 07d9229ae32a28e4dfa95be11215b33daf0e3813ea266df36ab83cc7b0c31ac9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=856 bytes; lines=14; markers=<none>; tail=status=COMPLETE git_head=30f34cffc4a1a882feb501471945e62e3a0cb2f8 raw_domain_cases=720896 routing_cases=45056 isolation_cases=45056 mutation_cases=10 negative_assertion_marker_count=1 input_manifest_sha256=144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/inputs.post.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c5762670061355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c5762670061355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/legality-domain-proof.log

- `kind`: log
- `size_bytes`: 314
- `line_count`: 3
- `sha256`: ebc511880c93836bd503df823dd373758c472c948de84083d4b4924d4cec3e4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=314 bytes; lines=3; PASS=4; tail=[T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2 /tmp/t3k-legality-domain-kbrcp5tc/tb_t3k_legality_domain.sv:347: $finish called at 90113 (1s) [T3K-LEGALITY-DOMAIN-PROOF] PASS raw_cases=720896 rout...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/audit.log

- `kind`: log
- `size_bytes`: 256
- `line_count`: 2
- `sha256`: 048421b83d53b134255e911fc0ca81559184a7e4b0127739e282a8adfa17487e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=256 bytes; lines=2; PASS=4; tail=[T3K-NEGATIVE-LOG-CHECK] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=reachable compile_rc=0 sim_rc=0 classifier_rc=1 [T3K-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED false_green=RED missing_reason=RED sim_nonzero=RED classifier_input_error=RED

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/classifier.log

- `kind`: log
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 084aef9fc5b0b5a67c8854f647e7e9c00724074cd02fd290bb6d4056f7c571fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=33 bytes; lines=1; ERROR=2; tail=log contains an ERROR diagnostic

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/result.log

- `kind`: log
- `size_bytes`: 991
- `line_count`: 8
- `sha256`: 1b328e9578bc3b236418c54e7d534da812978980dcbbd1d7e11b5ffbd333f678
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=991 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[COMPILE] iverilog -g2012 -Wall -DOOO_ASSERT -s tb_t3k_csr_equiv_negative -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/sim.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 81c683e36572548671e05195fd7da32486869ed048ec64c5b688c67c01a2cf6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=418 bytes; lines=5; ERROR=2; PASS=2; tail=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v:677: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged Time: 15 Scope: tb_t3k_csr_equiv_negative.dut [PASS] tb_t3k_csr_equiv_ne...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/status.txt

- `kind`: txt
- `size_bytes`: 273
- `line_count`: 9
- `sha256`: 13d9e4ee6dbde5176d1465c894ef51457f38f25b51a23f4d050134cfd921d200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=273 bytes; lines=9; PASS=4; tail=case=csr-legal-view-equiv assertion_marker=[CSR-LEGAL-VIEW-EQUIV] premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 compile_rc=0 sim_rc=0 classifier_rc=1 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_false_gree...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv/tb-t3k-csr-equiv-negative.vvp

- `kind`: vvp
- `size_bytes`: 156015
- `line_count`: 3439
- `sha256`: 3f2562f707def0af0ddf5864255ab8f2571d23e3c4fd80ff1706b59ac19c9e57
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 1}
- `summary`: vvp evidence; size=156015 bytes; lines=3439; ERROR=2; PASS=1; tail=shi/vec4 3860, 0, 12; %cmp/u; %jmp/1 T_2.58, 6; %load/vec4 v0x5cd1d6530f50_0; %store/vec4 v0x5cd1d65325d0_0, 0, 12; %callf/vec4 TD_tb_t3k_csr_equiv_negative.dut.csr_pmpcfg_known, S_0x5cd1d6532440; %flag_set/vec4 8; %flag_get/vec4 8; %jmp/1 T_2.61, 8; %load/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-probe-console.log

- `kind`: log
- `size_bytes`: 243
- `line_count`: 1
- `sha256`: ea65c6214e97b34a01a88d3556d0a689fe9db99fa543c4b139e3939df36329a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=243 bytes; lines=1; PASS=2; tail=[T3K-NEGATIVE-PROBES] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=non-vacuous classifier_rc=1 output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/negative-csr-equiv

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/source-contract.log

- `kind`: log
- `size_bytes`: 149
- `line_count`: 1
- `sha256`: 155bc69194d7501ce1893405d8b98cfef1fd287fcee6d2eaa07a48fd93308227
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=149 bytes; lines=1; PASS=2; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final-v2/source-mutations.log

- `kind`: log
- `size_bytes`: 1514
- `line_count`: 15
- `sha256`: 57b871f8e403ee3e47ecb744665a8ce990de5e61b0585317317fc929a5c375de
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=1514 bytes; lines=15; PASS=28; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16 [T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/complete.txt

- `kind`: txt
- `size_bytes`: 856
- `line_count`: 14
- `sha256`: 56533a20bdaab8d5d0aaf03ec6259d9404076943539ea4607b06def84c88091e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=856 bytes; lines=14; markers=<none>; tail=status=COMPLETE git_head=30f34cffc4a1a882feb501471945e62e3a0cb2f8 raw_domain_cases=720896 routing_cases=45056 isolation_cases=45056 mutation_cases=10 negative_assertion_marker_count=1 input_manifest_sha256=202b724625ff6a61b87150106eb2fe1e2c7e676e4f218bbf26d...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/inputs.post.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 202b724625ff6a61b87150106eb2fe1e2c7e676e4f218bbf26d6dcf3fcf8a209
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 202b724625ff6a61b87150106eb2fe1e2c7e676e4f218bbf26d6dcf3fcf8a209
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/legality-domain-proof.log

- `kind`: log
- `size_bytes`: 314
- `line_count`: 3
- `sha256`: 7cb23d3753a7b857ce39542b19c417e1cec67f1773a9b80fdcdc376755b534cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=314 bytes; lines=3; PASS=4; tail=[T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2 /tmp/t3k-legality-domain-ldvpgcbb/tb_t3k_legality_domain.sv:347: $finish called at 90113 (1s) [T3K-LEGALITY-DOMAIN-PROOF] PASS raw_cases=720896 rout...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/audit.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 2
- `sha256`: af96a488c74ce6a59f039adf234b6abb2e1e72b5d97572a46d524fe671f35c9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=213 bytes; lines=2; PASS=4; tail=[T3K-NEGATIVE-LOG-CHECK] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=reachable compile_rc=0 sim_rc=0 classifier_rc=1 [T3K-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED false_green=RED missing_reason=RED

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/classifier.log

- `kind`: log
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 084aef9fc5b0b5a67c8854f647e7e9c00724074cd02fd290bb6d4056f7c571fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=33 bytes; lines=1; ERROR=2; tail=log contains an ERROR diagnostic

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/result.log

- `kind`: log
- `size_bytes`: 988
- `line_count`: 8
- `sha256`: 2c24f6f02216f4712c44a242f067058377cdc345bc9bef8a88a613d25196ab8d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=988 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[COMPILE] iverilog -g2012 -Wall -DOOO_ASSERT -s tb_t3k_csr_equiv_negative -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/sim.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 81c683e36572548671e05195fd7da32486869ed048ec64c5b688c67c01a2cf6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=418 bytes; lines=5; ERROR=2; PASS=2; tail=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v:677: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged Time: 15 Scope: tb_t3k_csr_equiv_negative.dut [PASS] tb_t3k_csr_equiv_ne...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/status.txt

- `kind`: txt
- `size_bytes`: 273
- `line_count`: 9
- `sha256`: 13d9e4ee6dbde5176d1465c894ef51457f38f25b51a23f4d050134cfd921d200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=273 bytes; lines=9; PASS=4; tail=case=csr-legal-view-equiv assertion_marker=[CSR-LEGAL-VIEW-EQUIV] premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 compile_rc=0 sim_rc=0 classifier_rc=1 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_false_gree...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv/tb-t3k-csr-equiv-negative.vvp

- `kind`: vvp
- `size_bytes`: 156015
- `line_count`: 3439
- `sha256`: 8cc1795cf672d76c6d9afc2e9b4d7857f9379fcbed9ef7343076b8c7a38c622e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 1}
- `summary`: vvp evidence; size=156015 bytes; lines=3439; ERROR=2; PASS=1; tail=shi/vec4 3860, 0, 12; %cmp/u; %jmp/1 T_2.58, 6; %load/vec4 v0x58673093a000_0; %store/vec4 v0x58673093b680_0, 0, 12; %callf/vec4 TD_tb_t3k_csr_equiv_negative.dut.csr_pmpcfg_known, S_0x58673093b4f0; %flag_set/vec4 8; %flag_get/vec4 8; %jmp/1 T_2.61, 8; %load/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-probe-console.log

- `kind`: log
- `size_bytes`: 240
- `line_count`: 1
- `sha256`: 7bf5b00f7191b8b0b922e50f5baf3b4d9f94e0ac221f076969b12f385ec90361
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=240 bytes; lines=1; PASS=2; tail=[T3K-NEGATIVE-PROBES] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=non-vacuous classifier_rc=1 output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/negative-csr-equiv

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/source-contract.log

- `kind`: log
- `size_bytes`: 149
- `line_count`: 1
- `sha256`: 155bc69194d7501ce1893405d8b98cfef1fd287fcee6d2eaa07a48fd93308227
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=149 bytes; lines=1; PASS=2; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-final/source-mutations.log

- `kind`: log
- `size_bytes`: 1514
- `line_count`: 15
- `sha256`: 7d37aac51fda32ce7b874aa811556b67c03fc19e95e4f5043356514b23ce85cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=1514 bytes; lines=15; PASS=28; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16 [T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/complete.txt

- `kind`: txt
- `size_bytes`: 856
- `line_count`: 14
- `sha256`: f32f38abf736bc46b9258d0b25ad5e56a8437ef650a4e7b04b9af67faf758f82
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=856 bytes; lines=14; markers=<none>; tail=status=COMPLETE git_head=30f34cffc4a1a882feb501471945e62e3a0cb2f8 raw_domain_cases=720896 routing_cases=45056 isolation_cases=45056 mutation_cases=10 negative_assertion_marker_count=1 input_manifest_sha256=144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/inputs.post.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c5762670061355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c5762670061355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/legality-domain-proof.log

- `kind`: log
- `size_bytes`: 314
- `line_count`: 3
- `sha256`: 264cd3c1cfaf9408bc3f0b7367748866695ec3e67daab08c33dab96c72dcfeb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=314 bytes; lines=3; PASS=4; tail=[T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2 /tmp/t3k-legality-domain-bxw95w2j/tb_t3k_legality_domain.sv:347: $finish called at 90113 (1s) [T3K-LEGALITY-DOMAIN-PROOF] PASS raw_cases=720896 rout...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/audit.log

- `kind`: log
- `size_bytes`: 256
- `line_count`: 2
- `sha256`: 048421b83d53b134255e911fc0ca81559184a7e4b0127739e282a8adfa17487e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=256 bytes; lines=2; PASS=4; tail=[T3K-NEGATIVE-LOG-CHECK] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=reachable compile_rc=0 sim_rc=0 classifier_rc=1 [T3K-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED false_green=RED missing_reason=RED sim_nonzero=RED classifier_input_error=RED

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/classifier.log

- `kind`: log
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 084aef9fc5b0b5a67c8854f647e7e9c00724074cd02fd290bb6d4056f7c571fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=33 bytes; lines=1; ERROR=2; tail=log contains an ERROR diagnostic

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/result.log

- `kind`: log
- `size_bytes`: 996
- `line_count`: 8
- `sha256`: 1977fd2e56ada12ee6b9db5ddf8afb0751b820a1bb2ad6ad898d2d327b98e060
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=996 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[COMPILE] iverilog -g2012 -Wall -DOOO_ASSERT -s tb_t3k_csr_equiv_negative -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/sim.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 81c683e36572548671e05195fd7da32486869ed048ec64c5b688c67c01a2cf6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=418 bytes; lines=5; ERROR=2; PASS=2; tail=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v:677: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged Time: 15 Scope: tb_t3k_csr_equiv_negative.dut [PASS] tb_t3k_csr_equiv_ne...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/status.txt

- `kind`: txt
- `size_bytes`: 273
- `line_count`: 9
- `sha256`: 13d9e4ee6dbde5176d1465c894ef51457f38f25b51a23f4d050134cfd921d200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=273 bytes; lines=9; PASS=4; tail=case=csr-legal-view-equiv assertion_marker=[CSR-LEGAL-VIEW-EQUIV] premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 compile_rc=0 sim_rc=0 classifier_rc=1 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_false_gree...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv/tb-t3k-csr-equiv-negative.vvp

- `kind`: vvp
- `size_bytes`: 156015
- `line_count`: 3439
- `sha256`: 9ef7d99849dde76161039a3bcc708842c8536167a8fc7ff36b96c73a9ecb7af5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 1}
- `summary`: vvp evidence; size=156015 bytes; lines=3439; ERROR=2; PASS=1; tail=shi/vec4 3860, 0, 12; %cmp/u; %jmp/1 T_2.58, 6; %load/vec4 v0x5b8b65f54f50_0; %store/vec4 v0x5b8b65f565d0_0, 0, 12; %callf/vec4 TD_tb_t3k_csr_equiv_negative.dut.csr_pmpcfg_known, S_0x5b8b65f56440; %flag_set/vec4 8; %flag_get/vec4 8; %jmp/1 T_2.61, 8; %load/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-probe-console.log

- `kind`: log
- `size_bytes`: 248
- `line_count`: 1
- `sha256`: 2329209f67801943895bae9ed485c1e9e5a13966d8b6c1806b82d8c9f78d7e00
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=248 bytes; lines=1; PASS=2; tail=[T3K-NEGATIVE-PROBES] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=non-vacuous classifier_rc=1 output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/negative-csr-equiv

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/source-contract.log

- `kind`: log
- `size_bytes`: 149
- `line_count`: 1
- `sha256`: 155bc69194d7501ce1893405d8b98cfef1fd287fcee6d2eaa07a48fd93308227
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=149 bytes; lines=1; PASS=2; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-final-v2/source-mutations.log

- `kind`: log
- `size_bytes`: 1514
- `line_count`: 15
- `sha256`: 1ded48dbbb4ffe86e8b7da30a1f72f54f5308c521b7bffb672fba00718aedf9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=1514 bytes; lines=15; PASS=28; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16 [T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/inputs.post.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 144704248471ef3bf0a03857161a853fb97979b2c5aab5f759c5762670061355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 1841
- `line_count`: 14
- `sha256`: 202b724625ff6a61b87150106eb2fe1e2c7e676e4f218bbf26d6dcf3fcf8a209
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=1841 bytes; lines=14; markers=<none>; tail=a83337a7980e42b1150f1429c2db816f40195abcf1d6104da3cc4320fa69aa68 npc/rv64/vsrc/control/OooCsrAccessRequestMux.v 6765fb551bfb66c9c553b5b2a7282b42be966d03006e6b5756354cf18317fde2 npc/rv64/vsrc/control/OooControlPlane.v 6a8e26d6f95ad143c68797518e0093a7b05eafc6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/legality-domain-proof.log

- `kind`: log
- `size_bytes`: 314
- `line_count`: 3
- `sha256`: c7e561fd3a04f3933ce92716c004dea8c8123739f5951af4b2e0d51c328ef63d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=314 bytes; lines=3; PASS=4; tail=[T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2 /tmp/t3k-legality-domain-4ys4ccts/tb_t3k_legality_domain.sv:347: $finish called at 90113 (1s) [T3K-LEGALITY-DOMAIN-PROOF] PASS raw_cases=720896 rout...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/audit.log

- `kind`: log
- `size_bytes`: 256
- `line_count`: 2
- `sha256`: 048421b83d53b134255e911fc0ca81559184a7e4b0127739e282a8adfa17487e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=256 bytes; lines=2; PASS=4; tail=[T3K-NEGATIVE-LOG-CHECK] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=reachable compile_rc=0 sim_rc=0 classifier_rc=1 [T3K-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED false_green=RED missing_reason=RED sim_nonzero=RED classifier_input_error=RED

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/classifier.log

- `kind`: log
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 084aef9fc5b0b5a67c8854f647e7e9c00724074cd02fd290bb6d4056f7c571fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=33 bytes; lines=1; ERROR=2; tail=log contains an ERROR diagnostic

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/result.log

- `kind`: log
- `size_bytes`: 993
- `line_count`: 8
- `sha256`: 0f4ee64a6c0c99a2a280a97b9ccb3da8a318da039c906b5bb7aef6450dfc5e40
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=993 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[COMPILE] iverilog -g2012 -Wall -DOOO_ASSERT -s tb_t3k_csr_equiv_negative -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/sim.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 81c683e36572548671e05195fd7da32486869ed048ec64c5b688c67c01a2cf6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=418 bytes; lines=5; ERROR=2; PASS=2; tail=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v:677: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged Time: 15 Scope: tb_t3k_csr_equiv_negative.dut [PASS] tb_t3k_csr_equiv_ne...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/status.txt

- `kind`: txt
- `size_bytes`: 273
- `line_count`: 9
- `sha256`: 13d9e4ee6dbde5176d1465c894ef51457f38f25b51a23f4d050134cfd921d200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=273 bytes; lines=9; PASS=4; tail=case=csr-legal-view-equiv assertion_marker=[CSR-LEGAL-VIEW-EQUIV] premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 compile_rc=0 sim_rc=0 classifier_rc=1 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_false_gree...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv/tb-t3k-csr-equiv-negative.vvp

- `kind`: vvp
- `size_bytes`: 156015
- `line_count`: 3439
- `sha256`: 04edcbc7e605241c3a272aeac3c874ccec5a7ef5525580d81907b4212feedb27
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 1}
- `summary`: vvp evidence; size=156015 bytes; lines=3439; ERROR=2; PASS=1; tail=shi/vec4 3860, 0, 12; %cmp/u; %jmp/1 T_2.58, 6; %load/vec4 v0x603d1698af50_0; %store/vec4 v0x603d1698c5d0_0, 0, 12; %callf/vec4 TD_tb_t3k_csr_equiv_negative.dut.csr_pmpcfg_known, S_0x603d1698c440; %flag_set/vec4 8; %flag_get/vec4 8; %jmp/1 T_2.61, 8; %load/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-probe-console.log

- `kind`: log
- `size_bytes`: 245
- `line_count`: 1
- `sha256`: 361273b2f241a830331f56945c4937012cb63afa7155c167cd413eaca706a63e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=245 bytes; lines=1; PASS=2; tail=[T3K-NEGATIVE-PROBES] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=non-vacuous classifier_rc=1 output=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/negative-csr-equiv

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/source-contract.log

- `kind`: log
- `size_bytes`: 149
- `line_count`: 1
- `sha256`: 155bc69194d7501ce1893405d8b98cfef1fd287fcee6d2eaa07a48fd93308227
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=149 bytes; lines=1; PASS=2; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/current-contract-root-rerun/source-mutations.log

- `kind`: log
- `size_bytes`: 1514
- `line_count`: 15
- `sha256`: bbfe744c85c8fa322035cadc779078945a1561bf706dc3e5a8b62bc878ea1596
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=1514 bytes; lines=15; PASS=28; tail=[T3K-SOURCE-CONTRACT] PASS raw_predicate=csr_access_illegal_raw definitions=1 calls=2 inputs=7 probe_cone_nodes=13 boundaries=4 named_connections=16 [T3K-RTL-LEGALITY-DOMAIN] PASS raw_cases=720896 routing_cases=45056 isolation_cases=45056 valid_gate_cases=2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/final-static/contract.log

- `kind`: log
- `size_bytes`: 271
- `line_count`: 4
- `sha256`: 6cef547e07a292ccfdd5d3114b26ec785e5ae01f1dc1319555757e9e4d1a3036
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=271 bytes; lines=4; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' 契约立即断言（$error）计数：当前=88 基线=88 check-contract: PASS（--assert ✓ / OOO_ASSERT ✓ / 断言计数 88≥88 ✓） make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/final-static/git-diff-check.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/final-static/lint.log

- `kind`: log
- `size_bytes`: 8520
- `line_count`: 3
- `sha256`: 8030466e6f2dbfe96d2adbfeaa0705f75677148d350fcecac749c9b954febb70
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=8520 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator --lint-only -Wall -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include +define+CONFIG_NPC...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/final-static/rtl-style.log

- `kind`: log
- `size_bytes`: 226
- `line_count`: 3
- `sha256`: 17538296cc5586b0985b48152f4764ea83c3f7a88fcfb1fdcbe6a20f8f625c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=226 bytes; lines=3; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64'

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 48967
- `line_count`: 1322
- `sha256`: 8c1121eec379c9cca8596d0139cbf32bdd3c1bc10403f6ce412d10b069767de9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48967 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 266021
- `line_count`: 6944
- `sha256`: 2a6e0ac782c4f00076a86e92439b455a21d86c68241f27eee71ea79841b6c679
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=266021 bytes; lines=6944; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 216945
- `line_count`: 5725
- `sha256`: ef31672b070a85d4fb793dec8e932b243bb7300b8efd2b6762c9929d9918daec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=216945 bytes; lines=5725; FAIL=3; PASS=1; tail=%flag_set/imm 4, 0; %store/vec4 v0x586c8d6d5ac0_0, 4, 3; %pushi/vec4 0, 0, 3; %ix/load 4, 0, 0; %flag_set/imm 4, 0; %store/vec4 v0x586c8d6d5920_0, 4, 3; %alloc S_0x586c8d6c7fc0; %fork TD_tb_axi_exec_firewall.tick, S_0x586c8d6c7fc0; %join; %free S_0x586c8d6c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 370381
- `line_count`: 7336
- `sha256`: bb3778ad94fa6abf7512c7451f7325101a771a8449c0a9092ad5f1a2ed12cf20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=370381 bytes; lines=7336; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 149510
- `line_count`: 3963
- `sha256`: 15e19858ee375c828ea7bab7e9e27f6f30e618efc2c08c40ac7d644eac4a0765
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=149510 bytes; lines=3963; FAIL=3; PASS=1; tail=/vec4 0, 0, 32; %store/vec4 v0x5b298f538170_0, 0, 32; %pushi/vec4 0, 0, 1; %store/vec4 v0x5b298f538ac0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5b298f538550_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x5b298f5383b0_0, 0, 32; %pushi/vec4 0, 0, 1; %store...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 197892
- `line_count`: 5442
- `sha256`: b41ce14ef6f95590a7e62e8a3937416111c2ba8b51aa2bfef792fd8d82a3df53
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=197892 bytes; lines=5442; FAIL=3; PASS=1; tail=%alloc S_0x5dcaaa74d2b0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32438
- `line_count`: 864
- `sha256`: c85c5d1e4f89ddf14c3b47804d34d259c71f352082def455118b2e746c519bdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32438 bytes; lines=864; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 489313
- `line_count`: 12227
- `sha256`: a389c266a1e5c2dc34b08224f29b47ff296fa86e6dae061d4f96b9cbb802c681
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=489313 bytes; lines=12227; markers=<none>; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1702000233, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1936683552, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112262
- `line_count`: 3912
- `sha256`: 46e72f48dc9f6bcd123372ed8b4d6a976c10c4453aa736300965e14e71b6127d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112262 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x596477331970_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x596477331970_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274309
- `line_count`: 8084
- `sha256`: ba31ee60a249ff6a6676b5b99ab43c400751cd52942f85b5415c389ce2dd8ac5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274309 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32654
- `line_count`: 892
- `sha256`: 3d698ee03c2b179d6d75b0ca80660e4756f5c7328641385822bcaf63ffd95451
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32654 bytes; lines=892; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 37930
- `line_count`: 983
- `sha256`: 9456e0af42fe782ddf09fd42dfad713d47e87f20053b78994859c2cb1e28f901
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=37930 bytes; lines=983; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40314
- `line_count`: 1057
- `sha256`: 931199e12f30f511c5fefb5798c93c42f9507731c1a6b7ca53c7dd9fa24d3b55
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40314 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28612
- `line_count`: 748
- `sha256`: 58eae07e73f6ca564cb534826af0938d6dff5e35dc04293aef118c5fe1cd14fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28612 bytes; lines=748; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 2238006
- `line_count`: 57090
- `sha256`: 86b326faf86628a512a7bf265d78f1b5e5741620ffc036b64225e1357319b69b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=2238006 bytes; lines=57090; markers=<none>; tail=45f190; %join; %free S_0x63b7ac45f190; %alloc S_0x63b7ac5aadf0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 2160173
- `line_count`: 55734
- `sha256`: 3a83314dcddc63bd1fea26152526f0f2d8381eab16daa0d6942477ae07292b75
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=2160173 bytes; lines=55734; FAIL=1; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39372
- `line_count`: 1135
- `sha256`: a2e26a9102bc75103dd9098f0c82ddb290da7fd27f8d4563ebb583ed8417c1ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39372 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30684
- `line_count`: 801
- `sha256`: 9c4b0d374737625298a11ca8f8038606c699da3539bd78b1615cc2f79b92d294
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30684 bytes; lines=801; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 73836
- `line_count`: 2388
- `sha256`: bab71138c625c535bf66c5402bcc822ad3ee0819f97ef75ae5c741bef5eebd3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=73836 bytes; lines=2388; FAIL=7; PASS=2; tail=ooo_bitmanip_gate.dut.bitmanip_clz8, S_0x59cfce42ab50; %concat/vec4; draw_concat_vec4 %add; %ret/vec4 0, 0, 7; Assign to bitmanip_clz64 (store_vec4_to_lval) %jmp T_2.21; T_2.20 ; %load/vec4 v0x59cfce42aa70_0; %parti/s 8, 8, 5; %cmpi/ne 0, 0, 8; %jmp/0xz T_2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 39285
- `line_count`: 813
- `sha256`: be767373628c67bae552060c427982d31365a6fff3e2e954bf3ef91e0c83434f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=39285 bytes; lines=813; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30029
- `line_count`: 663
- `sha256`: 30396aa05dc8b4a342b2f9dd12605c535c729489ef760702eacaa0117fde10e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30029 bytes; lines=663; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138036
- `line_count`: 3130
- `sha256`: b8683ccf95e3d595f1fbcf7a04cd0fa86fe2847e8d28f3744411ae2a0de4106e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138036 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5d1d8b7cf4b0_0, 0, 1024;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 33385
- `line_count`: 698
- `sha256`: 212073c31ad793185a85a2308a478ce7eb61698370880a51fa655338399b0951
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=33385 bytes; lines=698; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47153
- `line_count`: 1228
- `sha256`: 3f7b71e55732b6bf5547c7e28b1c4ce339d43c8bea54cead151129e1a39cf469
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47153 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 53833
- `line_count`: 1355
- `sha256`: 7365398c1899c42d0e19001e25a79f6e535e6ecc5e7a7c11ad8abc630f3e6303
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=53833 bytes; lines=1355; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 67963
- `line_count`: 1763
- `sha256`: 0f6726ad27ecb4c85a27c7b00ba5b427f23b110e6ee8f7648f162a0fa4e7a3a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=67963 bytes; lines=1763; FAIL=12; PASS=2; tail=port_info 14 /INPUT 1 "resp_ready_i"; .port_info 15 /OUTPUT 4 "resp_rob_idx_o"; .port_info 16 /OUTPUT 6 "resp_pdest_o"; .port_info 17 /OUTPUT 64 "resp_data_o"; P_0x5bc48e345680 .param/l "CLMUL_OP_HIGH" 1 4 35, C4<01>; P_0x5bc48e3456c0 .param/l "CLMUL_OP_LOW...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 66957
- `line_count`: 1534
- `sha256`: 84c1efacc7e1c031f4f8ba86985a5f0650fd7a6224db80d1130d9b29ebb918bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=66957 bytes; lines=1534; FAIL=11; PASS=1; tail=st", 31 0, L_0x564c5d30fcf0; 1 drivers v0x564c5d2fb7b0_0 .net "commit1_next_pc", 63 0, L_0x564c5d310090; 1 drivers v0x564c5d2fb880_0 .net "commit1_pc", 63 0, L_0x564c5d30fa40; 1 drivers v0x564c5d2fb950_0 .net "commit1_rd_addr", 4 0, L_0x564c5d310700; 1 driv...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 52122
- `line_count`: 1261
- `sha256`: b038f36968cda530fdd2bc2809055b38810b818bdafe767ccf8ca54c01e62fc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=52122 bytes; lines=1261; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29483
- `line_count`: 785
- `sha256`: 4e6b5966f6f8f72d3edf64c592da861b2b870d1a895ffb61efa85d71b6957769
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29483 bytes; lines=785; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 4145484
- `line_count`: 98068
- `sha256`: af4cbfcf77d2cf1c4265272055cdf6c4633304b653a75358a77f6b440cc76c76
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=4145484 bytes; lines=98068; markers=<none>; tail=cat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 40836
- `line_count`: 955
- `sha256`: 5fe7ef1f2fe31a88fc92f1b7e5f89c269c1a5b2a72560135ce83b24c96ed7f56
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40836 bytes; lines=955; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34032
- `line_count`: 798
- `sha256`: 8539d4ac5cf882e4b05d0b4d6c2aba2dbf78e5d7254c21a3b54eda2882f355a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34032 bytes; lines=798; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 160203
- `line_count`: 3978
- `sha256`: 6464d741a2e3a690e457a5f357e215c764fc907a63fef35cd4d5338e4ba39e75
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=160203 bytes; lines=3978; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1668572516, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x6477570b55a0_0, 0, 1024; %load/vec4 v0x6477570bba40_0; %store/vec4 v0x6477570b54e0_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x6477...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101127
- `line_count`: 2454
- `sha256`: ecc7fbcb4ba72a3f3f07ae3f0c784601c4a4d540b3348092c580f852129121b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101127 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53579
- `line_count`: 1375
- `sha256`: e59aa6ee8c7de09001a74293583e77595c09d6934f4eb40b967b0cf82a4b9328
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53579 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 98854
- `line_count`: 2306
- `sha256`: 22d6907d3448784669ce246f6e52b05a5879931bc3052871217564f42b97cb16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=98854 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 556903
- `line_count`: 12403
- `sha256`: 085740334720267eb9751685371084bdb2dd5f5787ab6322885b5c7b3966d179
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=556903 bytes; lines=12403; markers=<none>; tail=0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 984834
- `line_count`: 25188
- `sha256`: 80f1eb38fe6fd728df76e97bca20ae8a0e2567561857876c2bc09059067e2047
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 6}
- `summary`: vvp evidence; size=984834 bytes; lines=25188; FAIL=8; PASS=6; tail=32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 688308
- `line_count`: 17191
- `sha256`: f3403d53025bb9e9278c541aa59f5fd604596a805e9c17c75cd816ed6d87b737
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=688308 bytes; lines=17191; FAIL=3; PASS=1; tail=9; %flag_get/vec4 9; %jmp/0 T_145.4, 9; %load/vec4 v0x5bc31f553260_0; %pushi/vec4 8, 0, 4; %cmp/ne; %flag_get/vec4 4; %and; T_145.4; %flag_set/vec4 8; %jmp/0xz T_145.2, 8; %load/vec4 v0x5bc31f550640_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_145.7, 9;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1080762
- `line_count`: 27273
- `sha256`: c1598db515b68133bbfc4bd35b52df63b67bf749aa8f155b8d2bf06e966e8b88
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=1080762 bytes; lines=27273; FAIL=3; PASS=1; tail=loc S_0x56b4ba3d8620; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x56b4ba3d8620; %join; %free S_0x56b4ba3d8620; %pushi/vec4 0, 0, 1; %store/vec4 v0x56b4ba3db6c0_0, 0, 1; %pushi/vec4 0, 0, 2; %store/vec4 v0x56b4ba3db5f0_0, 0, 2; %alloc S_0x56b4ba081770; %pushi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 801947
- `line_count`: 20203
- `sha256`: 5c503f4d4f2c992dbf85483ada642b02c2b88d7085d2d9faf6cece169571f06c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=801947 bytes; lines=20203; FAIL=4; PASS=1; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 101916
- `line_count`: 2491
- `sha256`: 87c44189dd8e85c29d523f5bddadfbb32c2e8e26a0cbca72e4f4bdd16790e899
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=101916 bytes; lines=2491; FAIL=3; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 1696625253, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1818583411, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702043762, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 324507
- `line_count`: 7415
- `sha256`: 19ad8523d76ae273909b348fb5ef2fa2738c94681d0e87ff1aeeb6acd2e58b76
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=324507 bytes; lines=7415; markers=<none>; tail=raw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544503405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 363363
- `line_count`: 7188
- `sha256`: 8731078617ab429ad1eb91548ff32e12c687ad6c24c0f94cc342c196c3ca073c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=363363 bytes; lines=7188; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126003
- `line_count`: 3153
- `sha256`: 26bb18e40150e47e490681523f424cacc2ac048deff0e2c38460c874b359ec77
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126003 bytes; lines=3153; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 277601
- `line_count`: 7059
- `sha256`: aafb7374ed0dcebab6b84c136f112639e79d5d84f63fe8695b3c4727f4df3da6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=277601 bytes; lines=7059; FAIL=5; PASS=1; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 121779
- `line_count`: 3021
- `sha256`: 697f2f3c76ca5e580076c4cc162fb32ccbf5a3e5964cdf16ac87cb4d2994f754
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=121779 bytes; lines=3021; FAIL=5; PASS=1; tail=b5d440_0; %store/vec4 v0x59d935b585f0_0, 0, 2; %callf/vec4 TD_tb_ooo_fetch_packet_fifo.dut.ptr_inc, S_0x59d935b583f0; %assign/vec4 v0x59d935b5d440_0, 0; T_17.10 ; %load/vec4 v0x59d935b5be80_0; %load/vec4 v0x59d935b5dda0_0; %concat/vec4; draw_concat_vec4 %du...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 65826
- `line_count`: 1604
- `sha256`: 13498190a6c82cefe2cc9c6e41deb5be504517db434f8aa256c4ea822f337abf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=65826 bytes; lines=1604; FAIL=8; PASS=2; tail="/usr/lib/x86_64-linux-gnu/ivl/v2005_math.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/va_math.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/v2009.vpi"; S_0x613f303bc1e0 .scope package, "$unit" "$unit" 2 1; .timescale 0 0; v0x613f303fcdc0_0 .var/i "t...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 115028
- `line_count`: 2951
- `sha256`: 6cd0636a039b9f6ce80fb08e791ec4d2d72996f27893f20aa3c2924efc4a3e50
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=115028 bytes; lines=2951; FAIL=4; PASS=1; tail=4feac0_0; %store/vec4 v0x5e6eb34fc050_0, 0, 64; %load/vec4 v0x5e6eb34feba0_0; %store/vec4 v0x5e6eb34fc130_0, 0, 64; %load/vec4 v0x5e6eb34fe820_0; %store/vec4 v0x5e6eb34fbdb0_0, 0, 64; %load/vec4 v0x5e6eb34fe900_0; %store/vec4 v0x5e6eb34fbe90_0, 0, 64; %load...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1012809
- `line_count`: 25349
- `sha256`: f237e044b04a086014a437fe24436cb0b6df5b9b9313522410c4c6c640bd24f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=1012809 bytes; lines=25349; FAIL=5; PASS=1; tail=2, 3; %store/vec4 v0x5cd5e0017e00_0, 0, 5; %store/vec4 v0x5cd5e0017d20_0, 0, 1; %callf/vec4 TD_tb_ooo_fetch_page_end_fault.u_decode.u_dec1_rvc_decompressor.rvc_imm_6, S_0x5cd5e0017b40; %store/vec4 v0x5cd5e0014610_0, 0, 64; %load/vec4 v0x5cd5e0014610_0; %par...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 119607
- `line_count`: 3201
- `sha256`: 0c9a1d13bc1ce370f97b8893a0640c2e99eef6019d3cdf276af72323de2cdb2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=119607 bytes; lines=3201; FAIL=5; PASS=1; tail=_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 88434
- `line_count`: 2189
- `sha256`: 84205c7012d0cdeb8a29e6feab8fe0a6ae48cba5859a6ca7f2354d27a2d139d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=88434 bytes; lines=2189; FAIL=4; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 3602804
- `line_count`: 83562
- `sha256`: 889c384dea3af610fd7e0a6b88f72de1dd57c343bc7127943d3121a7d0a4906e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=3602804 bytes; lines=83562; FAIL=4; tail=load/vec4 v0x5d075beea920_0; %and; T_437.7; %flag_set/vec4 11; %flag_get/vec4 11; %jmp/0 T_437.6, 11; %load/vec4 v0x5d075bef82a0_0; %nor/r; %and; T_437.6; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_437.5, 10; %load/vec4 v0x5d075bee08e0_0; %nor/r; %and;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 352895
- `line_count`: 10751
- `sha256`: bc7506a011d16b0c384f71bbbbba272bfe3291f234c27944352f76925631a4d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=352895 bytes; lines=10751; FAIL=5; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68451
- `line_count`: 1835
- `sha256`: b80470e784cc108200e6ce78e33425aabf0d40a5236e3be5cd04c9b5b03cbc52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68451 bytes; lines=1835; FAIL=7; PASS=2; tail=559ef7f722f0_0 .var "class_s_bits", 9 0; v0x559ef7f723d0_0 .net "class_value_o", 63 0, L_0x559ef7f83e60; alias, 1 drivers v0x559ef7f724b0_0 .net "double_i", 0 0, v0x559ef7f73430_0; 1 drivers v0x559ef7f72570_0 .net "frs1_value_i", 63 0, v0x559ef7f73500_0; 1...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 97895
- `line_count`: 2767
- `sha256`: 4771baf358815ef3326153a6ac0fadddc087af73021764720a4a5feb48fb957c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=97895 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x5abcb0bb1c70_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x5abcb0bb1f60_0; %store/vec4 v0x5abcb0bb2880_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x5abcb0bb1dc0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x5abcb0bb1e80_0; %store/vec4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202658
- `line_count`: 6365
- `sha256`: 92c4e272a67fdf69e95bb97eb5fb83e0dfee70b2a7b1adaac36588cd6f78be50
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202658 bytes; lines=6365; FAIL=4; tail=72e150_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x61dee772dc40_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x61dee772e750_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x61dee772dd00_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x61dee772e810_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 455206
- `line_count`: 11737
- `sha256`: 2b342d46482f533821e7f648cb329db9fa396ed339084dd8b0cc2bbd19365857
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=455206 bytes; lines=11737; FAIL=3; PASS=1; tail=ring_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 83963
- `line_count`: 2210
- `sha256`: 38ff98404d6aafb8938766683cf173b070a3d06efb2281d5fa989172ce46bc06
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=83963 bytes; lines=2210; FAIL=8; PASS=2; tail=613ef7395170_0 .var "exp_remainder_nonzero", 0 0; v0x613ef7395250_0 .var "exp_root", 55 0; v0x613ef7395330_0 .var "first_value", 111 0; v0x613ef73953f0_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start ; %pushi/vec4 1024, 0, 112; %s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 201144
- `line_count`: 5005
- `sha256`: 06f9aa9993b822f20604b1ec3b4c9277c0165d9a23a6fa034a4011d415c1e02c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=201144 bytes; lines=5005; FAIL=3; PASS=1; tail=0_0, 4, 3; %load/vec4 v0x619b5c1c5bc0_0; %dup/vec4; %pushi/vec4 0, 0, 3; %cmp/u; %jmp/1 T_9.26, 6; %dup/vec4; %pushi/vec4 1, 0, 3; %cmp/u; %jmp/1 T_9.27, 6; %dup/vec4; %pushi/vec4 2, 0, 3; %cmp/u; %jmp/1 T_9.28, 6; %dup/vec4; %pushi/vec4 3, 0, 3; %cmp/u; %j...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197006
- `line_count`: 6101
- `sha256`: 2552df982d0e61da9cdde6c1003b4a9f0398a4209e3b79a0ee6e88eb72a6cbd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197006 bytes; lines=6101; markers=<none>; tail=vec4 v0x55a066046410_0; %parti/s 1, 2, 3; %store/vec4 v0x55a066045e50_0, 0, 1; %load/vec4 v0x55a066046410_0; %parti/s 1, 1, 2; %load/vec4 v0x55a066046410_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x55a066046270_0; %or; %store/vec4 v0x55a066046930_0, 0, 1; %push...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64037
- `line_count`: 1638
- `sha256`: f2ba05471d826a86e3e28f517cc42793f68db6fcc62ee52e56359ff2edf54d23
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64037 bytes; lines=1638; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30253
- `line_count`: 661
- `sha256`: 8eb6403eaea1c592a4070e717fcf22b17864e18c09e3b7d04f0fb6489fdabdfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30253 bytes; lines=661; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39292
- `line_count`: 1056
- `sha256`: 4f4977160f7a1f356ebb1290d0c0a43c2f7f7e553790f242a9b9dd9425e7cb63
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39292 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 75847
- `line_count`: 1877
- `sha256`: fbb5ff5bf65689852875b79c6d4b33c64a186f006e10823554616cf8c9e903c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=75847 bytes; lines=1877; FAIL=6; PASS=2; tail=vers v0x5beed04dac10_0 .var "head_q", 5 0; v0x5beed04db100_0 .var/i "idx", 31 0; v0x5beed04db1e0_0 .net "next_count_w", 6 0, L_0x5beed04e01c0; 1 drivers v0x5beed04db2c0_0 .net "post_alloc_count_w", 6 0, L_0x5beed04decf0; 1 drivers v0x5beed04db3a0_0 .net "po...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 91032
- `line_count`: 2239
- `sha256`: 39e0f8894b080aef9e1769c0d3f08c81ea27303f65a3a213e364cf6a4a0e1337
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=91032 bytes; lines=2239; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 110858
- `line_count`: 2616
- `sha256`: 5e1a6d64b1c127ea4addd535a76a6e7d44aa7fcd2650f6123ddf448dd0da7fd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=110858 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x621e17108140_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x621e171086a0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x621e1710deb0; %join; %free S_0x621e1710deb0; %alloc S_0x621e17155d70; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x621e1715...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 146851
- `line_count`: 3486
- `sha256`: 04365315e2ac3df0f1dadfe0d5d68834a604c4d66f505246f39087d6d8acfdb8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=146851 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x65312e907d80; %alloc S_0x65312e907d80; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 92153
- `line_count`: 2289
- `sha256`: 44804240556c3f310059852710b62c195fa99649b45a95a29d1cfbdf978c45be
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=92153 bytes; lines=2289; FAIL=3; PASS=1; tail=5468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1633840229, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x61ca29993680_0, 0, 1024; %load/vec4 v0x61ca299980e0_0; %store/vec4 v0x61ca29950050_0, 0, 1; %pushi/vec...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138490
- `line_count`: 3101
- `sha256`: 4d2e9217b2250b1e96f8b29134a283db756cc9eda73d5213a9fe8f2dcf6e3871
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138490 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 351073
- `line_count`: 6189
- `sha256`: 5715a93d4d28701c3e185119ab0dcdfce3e9c17ac72f146ff70cd82ac29dc296
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=351073 bytes; lines=6189; FAIL=4; PASS=2; tail=0567252130; alias, 1 drivers v0x5b05671c1bf0_0 .net "trap_exit_exit_valid_o", 0 0, L_0x5b0567252070; alias, 1 drivers v0x5b05671c1cb0_0 .net "trap_exit_tval_o", 63 0, L_0x5b05672533a0; alias, 1 drivers L_0x5b0567250a40 .part L_0x5b05671dd330, 38, 1; L_0x5b0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 3060430
- `line_count`: 78349
- `sha256`: f91a671532417bb89508939c634a993953e270a918ce79fd43e69b70f393505d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3060430 bytes; lines=78349; markers=<none>; tail=ec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543387501, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1835627635, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x60388b5a1070_0, 0, 1024; %load/vec4 v0x60388b5a48c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 592387
- `line_count`: 14941
- `sha256`: b34e86f578e611b39b2ac5e93559813cf241df3d737ba6e916a009c4a84a4197
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=592387 bytes; lines=14941; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1156881
- `line_count`: 29309
- `sha256`: 1ff3a53838c632c1c826d851a3aad4cf716569a28a07e16ea4e6925f0b1ab48d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1156881 bytes; lines=29309; markers=<none>; tail=1; %jmp T_113.4; T_113.2 ; %ix/load 4, 11, 0; %flag_set/imm 4, 0; %load/vec4a v0x5612de551d10, 4; %ix/load 4, 11, 0; %flag_set/imm 4, 0; %load/vec4a v0x5612de551d10, 4; %addi 1, 0, 64; %xor; %store/vec4 v0x5612de54c9c0_0, 0, 64; %pushi/vec4 1, 0, 1; %store/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 48692
- `line_count`: 1193
- `sha256`: f0b334800559059fa96111041abdaeaeafbd83711abd533e40c7577b018f1315
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=48692 bytes; lines=1193; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 265783
- `line_count`: 6674
- `sha256`: 4798569a4208e94a3a9837c0df2a493796c3c233ec8bf16e388862c5dbd3da19
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=265783 bytes; lines=6674; FAIL=7; PASS=1; tail=0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 182736
- `line_count`: 4069
- `sha256`: f3b2851f6bce87505102d091618695f64580a774ee3e5b2920b2425759d3688b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=182736 bytes; lines=4069; FAIL=5; PASS=1; tail=ore/vec4 v0x61dabd6aac60_0, 0, 1024; %load/vec4 v0x61dabd70c540_0; %store/vec4 v0x61dabd6aad00_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x61dabd5cfd50_0, 0, 1; %fork TD_$unit.tb_check1, S_0x61dabd65fea0; %join; %free S_0x61dabd65fea0; %alloc S_0x61dabd67c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 66238
- `line_count`: 1572
- `sha256`: 120fb073367f9c944154895e6df93a459a8ded17b3096afe0a64d2a5c622b440
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=66238 bytes; lines=1572; FAIL=6; PASS=2; tail=000000000000000000000000000100>; P_0x58a352fd1c90 .param/l "ROB_COUNT_W" 1 3 6, +C4<00000000000000000000000000000101>; v0x58a353008590_0 .net "backend_drained", 0 0, L_0x58a35300af70; 1 drivers v0x58a353008650_0 .var "backend_drained_q", 0 0; v0x58a35300872...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 104600
- `line_count`: 2576
- `sha256`: 8624d749f9645cdbe0226c86af1ca2bae9b9bd3111582c69d450b3dd96a341b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=104600 bytes; lines=2576; FAIL=5; PASS=1; tail=$unit.tb_check1, S_0x5ae2b48e97c0; %join; %free S_0x5ae2b48e97c0; %alloc S_0x5ae2b48e97c0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 74265
- `line_count`: 1868
- `sha256`: d786eee2639f772399dfef51b7b2511ab0ce86260a2c187ce23f73d60ffe66db
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=74265 bytes; lines=1868; FAIL=9; PASS=1; tail=000>, C4<0000000000000000000000000000000000000000000000000000000000000000>, C4<0000000000000000000000000000000000000000000000000000000000000000>; L_0x5ec5a58b6380 .functor BUFZ 64, v0x5ec5a58b0750_0, C4<000000000000000000000000000000000000000000000000000000...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 20971
- `line_count`: 597
- `sha256`: 0ecf8aa976f43e11658128561bb54a3c9ad4e1ee75e7c6bda628b84ca7280f87
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=20971 bytes; lines=597; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 197392
- `line_count`: 5034
- `sha256`: 00b229bd48a311d3ddff0e8d7573adfacef473ebdaff4346f5758645d75a088c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=197392 bytes; lines=5034; FAIL=3; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1818850153, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1869488206, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 724639858, 0, 32; draw_string_vec4 %conc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 3922997
- `line_count`: 92178
- `sha256`: e42346dc9046310f0f910ded4554a7885ea7defa2011ccd6ebf11f8443f0b465
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=3922997 bytes; lines=92178; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63728
- `line_count`: 1586
- `sha256`: c4294dfc6035acc857f7d4cefac3ece4550eeafc209aee20c32cbba970000329
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63728 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 29174
- `line_count`: 688
- `sha256`: f23c5205b1de717f00fd730021c04cbfbc00e0c288b1609aa4c2810c4e74c355
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 18, "PASS": 2}
- `summary`: vvp evidence; size=29174 bytes; lines=688; FAIL=18; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99472
- `line_count`: 2436
- `sha256`: 8b946242fe81c1d78bbac30c462e09f312ab2328e39d8f08fbb8369fb72f7107
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99472 bytes; lines=2436; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 298412
- `line_count`: 7124
- `sha256`: 9d9888545f16dc0f9bdaa770d55e01396c15ff02fd5142cb9e132390c5d88f73
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=298412 bytes; lines=7124; markers=<none>; tail=0x56023f0123c0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 54793
- `line_count`: 1562
- `sha256`: 0bb8307bddc3e384125a2ebf4b95d6aa69157b7be55c50a0b4f116eebaf4f1c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=54793 bytes; lines=1562; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 160515
- `line_count`: 3944
- `sha256`: e4df9a2d204e4105d4c2e95c0ff779cbcc308ce57c0e49c66352f4be9976de16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=160515 bytes; lines=3944; FAIL=4; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 4865585
- `line_count`: 114910
- `sha256`: 829b12b45d047805b39ae29f5a486f75a500807381710b835a23ef0004a4de2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=4865585 bytes; lines=114910; FAIL=10; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36101
- `line_count`: 734
- `sha256`: 231d07afff17807d5c30e95dd8ce89fcf3418681c91c32a9dfd1a94a105cac24
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36101 bytes; lines=734; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 16989
- `line_count`: 476
- `sha256`: 694e18da473819a13fe3588e339fdb3342f60ae639925e5fb95c2fd3b38c8108
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=16989 bytes; lines=476; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65157
- `line_count`: 1744
- `sha256`: f8a61a9f3b9d7c51efb24f0e94dd6e666d7d47c20621e31bdd486e32f611ae29
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65157 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180661
- `line_count`: 4649
- `sha256`: 39ec148e4de70b3838f609230ba63ef21df7c1cb32459f98938238d9967138cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180661 bytes; lines=4649; FAIL=3; PASS=1; tail=2d90_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x57796a253060_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x57796a20c490_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x57796a252c10_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x57796a236130; %join; %free...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300070
- `line_count`: 8070
- `sha256`: bf8296b0ce37c7e49c7a095e44b8a44e8b6733e17034d9592388b848057fe87f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300070 bytes; lines=8070; FAIL=4; PASS=1; tail=1; %store/vec4 v0x5fe3f8b1c6e0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5fe3f8b1c6e0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5fe3f8b1ce10_0, 0, 1; %delay 1, 0; %alloc S_0x5fe3f8b1b280; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25241
- `line_count`: 678
- `sha256`: e04658bb7a8174ef977d5f7f29fb685be696b95ee580ed54abaca30eb905fb20
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25241 bytes; lines=678; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 455
- `line_count`: 5
- `sha256`: e3cd46ba114c06d62dc5c879dbc214546486e8c8fa2c3024ec1865ef7e00f351
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=455 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isol...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 5
- `sha256`: 79e224953cc2664ca4fd2241d34fa41480dd80bae443f745b33bbfa9ad9fcb80
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-cs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3585
- `line_count`: 28
- `sha256`: 2a788f2890327d6c08f0a0cb21e7bad30eaf87a3d0e7e455c9fe9ea79138be10
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3585 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: 88598ea9713b3c1cf29ed2c103fff1dccf3e88eae2372753ca6b1f18d00820ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=481 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 551
- `line_count`: 5
- `sha256`: ab31ec084d5cb50cc75618c8e751b5b8469942f62c2ecd02ccbce498ea93e38f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=551 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3364
- `line_count`: 28
- `sha256`: bee425648fae90a889a8ca28e3cb154d6f899b878dc6da6c1246213e5dc4c566
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3364 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: eaab676b8443858d0bc05f946f56f8f1c4f262a4952a966456fafd8dcee0e089
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-pr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: 16ca94d755166c1d807d403dec1ac03a74a84f7db0c6fcb591a9218dbc702bef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 5
- `sha256`: f0b09ff8de8c7c2346389fea61157f4dbe85d2993be6ddfb253b5ed3e39ca6e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=626 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 5
- `sha256`: 0f052c0ac87062941cd913cb80ae99206d7cb0cb3e20241adcafeddcd7dc4495
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: 17db6233b79d9cd8adc5e8c521df7aaa9c06dd97da3eaba6fc35221c58ff6eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-prob...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 578
- `line_count`: 5
- `sha256`: 52546502d8af0290bf915c8e6a3c9d3a8351162aa144187ec9bc3060dc625858
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=578 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isol...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 500
- `line_count`: 5
- `sha256`: 5a8235104a91e084efd886872a29f6fea3fe380aa67079126c55d5056b6fff4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=500 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 5
- `sha256`: c545f87a8fc603caaff7aae8acfa5dd7317049f367701c81274759822d400f9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=506 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14075
- `line_count`: 85
- `sha256`: a6d864208c305bc2671ce390501f7511cac553c08bd32720b068cacc4d8fa6d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14075 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 13751
- `line_count`: 83
- `sha256`: 030b4e0870cbc66c2a514004a223fcad01f5e4a7b07fed42f569d639cf548e59
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13751 bytes; lines=83; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 506
- `line_count`: 5
- `sha256`: cd398140674956398c81748a44e02618965a46ffa819342e60f88db4fb2084fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=506 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: e5889157a5266b9bba281613c93b658d7b8282d88ce293ee4820890d8651f773
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 536
- `line_count`: 5
- `sha256`: b1df3a834907e852b5b82ef3385430057b7705776a3abdf28eadce44693b1a3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=536 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 963
- `line_count`: 9
- `sha256`: de220ee79bea0ca86566257017870b2c80675908a9be87a8da47b06eaeb96515
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=963 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 918
- `line_count`: 9
- `sha256`: b3ece22fec93abaed6697f3f75fa0abffdfc020258984c961ca21b82d584eafa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=918 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 701
- `line_count`: 5
- `sha256`: e915d7dcf0c042e6b46414ed83800e354289cadf8bfcf6194185c4e3a2efdda0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=701 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 973
- `line_count`: 9
- `sha256`: e269bea4901def68b95085283efbb2862209f1ca7ce63dd25d6761a86865d7ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=973 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 573
- `line_count`: 5
- `sha256`: 05bfbb84885943e7e1ba3232a982651df53b58ed71ae517b265d08e5caf4759e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=573 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 658
- `line_count`: 6
- `sha256`: 94308290c042487e170fe826dfb200ed77130366d788349b2c58b7cc995c5219
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=658 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 5
- `sha256`: 2d1457b30361617884999fef19e58f06f09d2c801f689045f2ff829d2964d7cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=520 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 876
- `line_count`: 9
- `sha256`: 3adcdb16b00cd4162aa0ce0bf279f431bd506bcec0febef57dadc7b26d6e56ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=876 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 941
- `line_count`: 9
- `sha256`: 5dea468f351feb4384b6b86187b7ef95e824785a3e52ea7f0ca1fccf477f2b6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=941 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 928
- `line_count`: 9
- `sha256`: 47a838908a210aee1d3dc62f7a2ec2ed3986aae80b71167cf518c6c148ccd0f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=928 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16630
- `line_count`: 74
- `sha256`: 6c3b2ee95e80d26934fabba6444778defbf50944cb9f54f2d718bd1f1b6d2d64
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16630 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 5
- `sha256`: e170a30f23394cd7d79d6c7bc4a52e73d9c93e078f3c0426eae6bb90592ba39d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=606 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 592
- `line_count`: 5
- `sha256`: d15e0ab9a7e0764d35d9de57b75b889565656f18f013f6266550a75d29d881bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=592 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 684
- `line_count`: 5
- `sha256`: 4abd1a81889f845a1361a058d181c9a13e244ebf8cbfc3f73b381a37e63f5d9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=684 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 5
- `sha256`: d9e8bb717b07b802a17f7007ae807eef6361e1a7720359a099a1b720067899c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=614 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 608
- `line_count`: 5
- `sha256`: 6aa1036bb0ce4497706e8683dc6ab787c805dbe966bdf0bf0273ca92e613a702
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=608 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 608
- `line_count`: 5
- `sha256`: 29090fe9051a7ef63b8d8a135767cbed436a6caac8c3e4a9aed96387107ac29d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=608 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8455
- `line_count`: 59
- `sha256`: fc59b2ad1b3c427f7ea26e4de646477b1955c412747babab8552d61b6f056517
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8455 bytes; lines=59; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89829
- `line_count`: 717
- `sha256`: 1b1da0c411a90321556673a22efdd015f3070dfccbc1a4f4af0b2bc96ac893f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89829 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86572
- `line_count`: 650
- `sha256`: ba6f84ed46efb2ae2939caf468a446262607b0605541013955114f5579ce5031
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86572 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86543
- `line_count`: 650
- `sha256`: 8014fc55f3f734498ce13835d0ca761aedfd236289b3402f7052664ddbd53ba8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86543 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89507
- `line_count`: 673
- `sha256`: bc8ad52b56b9275e96f15491fdd8200a85ac1f583ed11d620045361789e07bea
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89507 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 567
- `line_count`: 5
- `sha256`: 0d4293676b1473b832bc968e166dac741040a875f938bebd0fb43a1b53b665d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=567 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 665
- `line_count`: 5
- `sha256`: 789e4988fa6b1a21f6b4f84f90189a4108331205b91d7b02f426a0236a958265
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=665 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 719
- `line_count`: 5
- `sha256`: efa4c55980b26995940421f320048379804b94e2f591d3368d01a6ecdff29256
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=719 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 704
- `line_count`: 5
- `sha256`: f61a486b9ebc31027a18c7f6f3c4d6c860cc2916c0c9d1f7368d0ea42d6f589b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=704 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 5
- `sha256`: 34fa8b1a853905ed1bda9543d1fcc60a2fb12a10c2563f122532fe45d42ffdfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=642 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 561
- `line_count`: 5
- `sha256`: a4b7c3e612463968eebe921be414205b612d46e4f8e4cf4bbf8d3fdd0eb64479
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=561 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: 669e6e2683f434ab0a2e82861b87bd3228372b9cf85544b5dca7b50ba220523d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 737
- `line_count`: 6
- `sha256`: 71bd1ecf7338c327f56a2c618631fa7809a4a86c47482ae2e17e9cf9f489c21d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=737 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87908
- `line_count`: 664
- `sha256`: cb97fdcc993a8391ebdfc8d4640476e387388405c06ce22cb374dfa83dfab794
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87908 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 5
- `sha256`: 2037741d5b06d5b728ea40073357cc741787f80e5740774a034a9aaabb9d85f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=638 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 561
- `line_count`: 5
- `sha256`: 0aa6f7b3fd8e319bddbdcb37080cb58bb2594d5b9c534bc1d88349d2d06a6a64
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=561 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 16640
- `line_count`: 74
- `sha256`: 11da512dc3e4a729851c22d01186420c6fa379952c3a8c40aaa8c1cb84e46907
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16640 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: f850fdba4852cc439e0d87f4ff90414c99132adcd9eb428a1480f7d1c66616b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 554
- `line_count`: 5
- `sha256`: 1bf71cb3964872c510814914b6de00f43f86cb2212c485d04db106baf0577cbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=554 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 5
- `sha256`: 79d77c504a19ef77d883b731cefd2dff5f2a4da0f5eb5c8d1f2acec4b5d22902
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 547
- `line_count`: 5
- `sha256`: 9780d02e0b2da194dea1d512d10f8fcad56bd3c8f581ffafd9e9d7567c40eb63
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=547 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3753
- `line_count`: 36
- `sha256`: a4dcdb6d8f56c5999e9586d091100da666e2841ce9c9185f1e912c849b2dfa4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3753 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 572
- `line_count`: 5
- `sha256`: a2692183887c6d421cd09ef59c77f7e4d81f0ca1a0888c66316c46fb6b6eb670
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=572 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1516
- `line_count`: 13
- `sha256`: 22c8e82d3b9eec05e9bdec0a1d9cdb7f01da11218bc837ea3b075944e3b05126
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1516 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 679
- `line_count`: 5
- `sha256`: f4b55d4eaf548f1a453068ca507a2e713ed040408b6c3176720bb46c862054d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=679 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1086
- `line_count`: 12
- `sha256`: 059b504f7b0018f210f720797346308050fe6e1e2aff77340294ca489831f351
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1086 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 833
- `line_count`: 9
- `sha256`: bc720c6037b4168e4ccd273d120e95760ccf0abe91aa05bb0f99e0b7a41f51c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=833 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 5
- `sha256`: a72ab07bbf642bb516389e8022bb4cfa67b5d74ff1c97fa93d59edfe5b9f08e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=529 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 5
- `sha256`: 38a16483eeab87ca3764be5939dfb9cdaafb659ebf4c5245f030867c1fd46a62
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=521 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 579
- `line_count`: 5
- `sha256`: 00be1f10b5877b10774b23b6be4bd67e7d1b6d7f23fc6622f2710ae4a5357c3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=579 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 987
- `line_count`: 10
- `sha256`: bfe9c2c118e9dffc8ffbb1f996e6dbec7440c57183179897f949f2980f846160
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=987 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 899
- `line_count`: 7
- `sha256`: 1313ffe3fb51f6eece64a4b0f7bdccb7337d6b9e4b77a4a171295f5fcc64b4b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=899 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 561
- `line_count`: 5
- `sha256`: 3f8e2d946d24f0c1668c75499a1a1358551c597c430ea648b78203df9a7618f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=561 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 573
- `line_count`: 5
- `sha256`: 639bf16ef6ef3d28f1ad618f34f1a49236d59e2b621da687306750d545121ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=573 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3617
- `line_count`: 32
- `sha256`: d4b8903cf71f2aa37e13cac2ca26ee11986549839cf8701ea6f0a8849da08dd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3617 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14880
- `line_count`: 99
- `sha256`: b0b8acda8559f3510d186140956673b4a2f3b62cc925d51d54d8c4edc0cddcce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14880 bytes; lines=99; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7926
- `line_count`: 62
- `sha256`: 7f3fbba29fad668055f2cfaaf7c8e53d499b6e6b355372f969d11bf466e63b92
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7926 bytes; lines=62; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52233
- `line_count`: 392
- `sha256`: bc6680505f42507f345a320195b1558f15c28592555fcd14982bca99ee10f72c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52233 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1031
- `line_count`: 8
- `sha256`: e2026fb14b2a8597370f9660fa58282b7f158e81e446b86acab9d84fa974fc72
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1031 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 5
- `sha256`: 71271ee0500384fcbc4d8ea7ace927936be90203d3aa75602849659bc8d79f8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=529 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1171
- `line_count`: 11
- `sha256`: fd588f6b6a3f3984288bc53d8c1862878faa66a46399c0694f47f05fd1dde326
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1171 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 613
- `line_count`: 5
- `sha256`: 3e20e6968564bb159653dcaf11547377a295a2e92de206b71101b5b006781e86
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=613 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 961
- `line_count`: 10
- `sha256`: 0f83ccf175082d41e03392c55c1847e7c194786f7be89b98cb3849516d968f32
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=961 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 937
- `line_count`: 9
- `sha256`: 949c59833166a1568435642b20c1809e0d3dc2c36327f05bab9aaa8c74f6d1d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=937 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 806
- `line_count`: 6
- `sha256`: b21eee3af89f7cdee932799dbda95059aa8efc459be5905e1f9bfad5c781624c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=806 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 543
- `line_count`: 5
- `sha256`: b54f0e5bc0e3a1a5e86822825966168743651c592e5f9d5174f5686d335a0658
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=543 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 16616
- `line_count`: 74
- `sha256`: c3aee129f7ad82489e43f759d39be04f50cd7468bd882285d7ce52a5f9e44a1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16616 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: 8474f122af14bd162ed9f031dea8af0cb4ffd94769518a24820eaaf8a6abb205
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: 3eefe43c1637ef67b709104813daf59a8bcfd3773845d846713a72c7629ca545
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 527
- `line_count`: 5
- `sha256`: 79166e517c5c56d2216323e6dfde04f88f79efc2d99c5675b968347e8c591c4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=527 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 819
- `line_count`: 8
- `sha256`: fe81b099ba8617dc0ae187f289ee03a43f8d33f3b2432c48c9a070216fe2143a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=819 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-pr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 919
- `line_count`: 9
- `sha256`: 70f7733d64fbb703dcbc9759184d61e7a6a446f8a11bdae7a1abe5bf14510a05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=919 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 1052
- `line_count`: 9
- `sha256`: e13ad9d365fff841256511e891c9ca4d4b902b01b73b7215ca079ec3c42a1842
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1052 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155146
- `line_count`: 1109
- `sha256`: 1c9502c6cf67cd26d2271b06800b72116f4ae9a3f85a1c931b886f72d17a0dfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155146 bytes; lines=1109; PASS=2; tail=ll 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: a53f0c56a708acdb17d27d2939581e37653e50b906f42175f2c00366e1db9f4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 634
- `line_count`: 5
- `sha256`: f0fbba07c4fe275d9facf334f1a9d6a86a466a7ebd7d9e813de8276a37e6e62c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=634 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 520
- `line_count`: 5
- `sha256`: 8fbc2606255e5b19e4941a049bfa0adc1034bbeb7639e3d75644754128f9da4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=520 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17647
- `line_count`: 134
- `sha256`: f5beb055af1397e3c48923e89d449e7bc28074c8e55a891bbbcbb4e480a77f64
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17647 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: 4ca44413497b061016f42b10a37ae2922bf8e5a2de46a1bebe9081690817bb0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-is...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 5
- `sha256`: 4a1946c545e1480ab6c8b8d198ad78240e1b93563d14a72806a2e0d82f53187a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=456 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isol...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results/summary.txt

- `kind`: txt
- `size_bytes`: 3195
- `line_count`: 105
- `sha256`: 4e279767f4e58e25fec9cb7e940edb5da482607779b5976282677545ede5ca3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 192}
- `summary`: txt evidence; size=3195 bytes; lines=105; PASS=192; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-current/results - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 48967
- `line_count`: 1322
- `sha256`: 5671c292da73e9124e32d007dddcadd602b2cf72571f06b24bb92ac208858872
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48967 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 266021
- `line_count`: 6944
- `sha256`: b629bb306566ee9e9838c54c8e9dd25f92cc60a75678b2e02efdadafc49d9cd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=266021 bytes; lines=6944; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 216945
- `line_count`: 5725
- `sha256`: d3153b48ce041a8171423f6b6de845c282a915457085af2397cfc85fa38761ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=216945 bytes; lines=5725; FAIL=3; PASS=1; tail=%flag_set/imm 4, 0; %store/vec4 v0x5c319b71aac0_0, 4, 3; %pushi/vec4 0, 0, 3; %ix/load 4, 0, 0; %flag_set/imm 4, 0; %store/vec4 v0x5c319b71a920_0, 4, 3; %alloc S_0x5c319b70cfc0; %fork TD_tb_axi_exec_firewall.tick, S_0x5c319b70cfc0; %join; %free S_0x5c319b70...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 370381
- `line_count`: 7336
- `sha256`: 70278de01629ea23c1bff192aa479ba801fda00dc5fc642a46940a6a0a0a6478
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=370381 bytes; lines=7336; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 149510
- `line_count`: 3963
- `sha256`: dca33b0fcb7b7e7cf57c39784e16397fbef442c057cc4a48e3ad686b08e3ad12
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=149510 bytes; lines=3963; FAIL=3; PASS=1; tail=/vec4 0, 0, 32; %store/vec4 v0x591bfec68170_0, 0, 32; %pushi/vec4 0, 0, 1; %store/vec4 v0x591bfec68ac0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x591bfec68550_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x591bfec683b0_0, 0, 32; %pushi/vec4 0, 0, 1; %store...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 197892
- `line_count`: 5442
- `sha256`: 1cb4ca53139adaefeb3e18119ff8a48fa17e836bf42b64d2be12c3e09f1bada6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=197892 bytes; lines=5442; FAIL=3; PASS=1; tail=%alloc S_0x5e21e5ab32b0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32438
- `line_count`: 864
- `sha256`: 6ac3aefc67488d1ef5f78827f189755f78294eed487e4f8803a416e974cda21f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32438 bytes; lines=864; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 496157
- `line_count`: 12407
- `sha256`: afa0606d7cd933255f042cba73f6d7bc215f9940c55c764434ce1719eac8789e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=496157 bytes; lines=12407; markers=<none>; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1702000233, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1936683552, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112262
- `line_count`: 3912
- `sha256`: 95879cecd1b718ecc978a2426930abd4975ea0a53778e2aeb136690b3ce2994a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112262 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x577c61c49980_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x577c61c49980_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274309
- `line_count`: 8084
- `sha256`: 30ab2f557cda21931dbfc50c3cc1c8f2a95c8f1b366afe39a6cc30556c196a27
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274309 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32654
- `line_count`: 892
- `sha256`: 42bdb8c87d63db7e6615fd47040c878206f4ce9382393cc385e09f9b37df05aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32654 bytes; lines=892; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 37930
- `line_count`: 983
- `sha256`: 70ed8bf26d54305ee6d8c3e7cd1d65a4145688ea3912f5ca0b74fd335d4b6730
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=37930 bytes; lines=983; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40314
- `line_count`: 1057
- `sha256`: 595a2f742720a3748054febc331a67c16ab51f5b58fd062842bb22613593fda5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40314 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28612
- `line_count`: 748
- `sha256`: dab5d6d91734f58f59deb481cea0b9c7e1365a9fe75fe0e186125d5c77df2b72
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28612 bytes; lines=748; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 2238006
- `line_count`: 57090
- `sha256`: 13e9ca9cc79b6df959fc4d8d685561a942d329e18b172671821ad577ddb8d7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=2238006 bytes; lines=57090; markers=<none>; tail=5db190; %join; %free S_0x59af015db190; %alloc S_0x59af01726df0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 2160173
- `line_count`: 55734
- `sha256`: 2c4c44004b98d8753f01a82e4f173919b90fd19ed0fb7f77ef3dc7b57853d8c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=2160173 bytes; lines=55734; FAIL=1; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39372
- `line_count`: 1135
- `sha256`: 5672ffb3af5739a29595d17c6c6e6300531975b97eb05a044a152e3e2cb4eea2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39372 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30684
- `line_count`: 801
- `sha256`: a4d5eb9a9daf44bfc4b0892fc64ecf664bab890f8624823df0f31f5f449de072
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30684 bytes; lines=801; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 73836
- `line_count`: 2388
- `sha256`: 17776fb8f48c14d1664049e3644ca9cd7b85e1a8985337d6449d714e79264655
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=73836 bytes; lines=2388; FAIL=7; PASS=2; tail=ooo_bitmanip_gate.dut.bitmanip_clz8, S_0x566e96812b50; %concat/vec4; draw_concat_vec4 %add; %ret/vec4 0, 0, 7; Assign to bitmanip_clz64 (store_vec4_to_lval) %jmp T_2.21; T_2.20 ; %load/vec4 v0x566e96812a70_0; %parti/s 8, 8, 5; %cmpi/ne 0, 0, 8; %jmp/0xz T_2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 39285
- `line_count`: 813
- `sha256`: 846bb046dd42eecf302d41d7954b4b79f92ce2f7a5fbe8ec7c7f0a70de1dc94f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=39285 bytes; lines=813; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30029
- `line_count`: 663
- `sha256`: 6b424cbc6cd8b66d73d8f044c3dc93763055780185b24df3ba9febe2125a640c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30029 bytes; lines=663; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138036
- `line_count`: 3130
- `sha256`: 40b25f09968c8e5c926cef0e9a9b56c8f3d8fda8d929a94b4e58629c13bd57a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138036 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5dd04c6cc4b0_0, 0, 1024;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 33385
- `line_count`: 698
- `sha256`: 5e8618bf4d90227635132fd4866546aabd05fd35f0097c3fb1e431a194ddd095
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=33385 bytes; lines=698; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47153
- `line_count`: 1228
- `sha256`: 59b65c10077da99375034141df618405466f57e7327587e9751aecfedcfb65f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47153 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 53833
- `line_count`: 1355
- `sha256`: ed7c34b365a954e5b446e6ea64a1f2cf3c3eaf894b164c517cef02677b7bf547
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=53833 bytes; lines=1355; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 67963
- `line_count`: 1763
- `sha256`: 85c70c5aba9831c72b59c694e704747ba4d9cdce708ba230926532784a92b942
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=67963 bytes; lines=1763; FAIL=12; PASS=2; tail=port_info 14 /INPUT 1 "resp_ready_i"; .port_info 15 /OUTPUT 4 "resp_rob_idx_o"; .port_info 16 /OUTPUT 6 "resp_pdest_o"; .port_info 17 /OUTPUT 64 "resp_data_o"; P_0x5cf97057e680 .param/l "CLMUL_OP_HIGH" 1 4 35, C4<01>; P_0x5cf97057e6c0 .param/l "CLMUL_OP_LOW...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 66957
- `line_count`: 1534
- `sha256`: 23a7d9aa3259d843159d5c004c4f233cf2162d964ca0c2ac97b3bc341f035b98
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=66957 bytes; lines=1534; FAIL=11; PASS=1; tail=st", 31 0, L_0x5eb7c0544cf0; 1 drivers v0x5eb7c05307b0_0 .net "commit1_next_pc", 63 0, L_0x5eb7c0545090; 1 drivers v0x5eb7c0530880_0 .net "commit1_pc", 63 0, L_0x5eb7c0544a40; 1 drivers v0x5eb7c0530950_0 .net "commit1_rd_addr", 4 0, L_0x5eb7c0545700; 1 driv...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 52122
- `line_count`: 1261
- `sha256`: 6d0f3551ca893be0cc71d9a31fbca6a3c38f3df67e90ee92542e4eeaae890869
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=52122 bytes; lines=1261; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29483
- `line_count`: 785
- `sha256`: 34eac09fef07e6bf6e434f548aa8d933a148a552820502da1a18384ccad3e1fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29483 bytes; lines=785; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 4145484
- `line_count`: 98068
- `sha256`: 697694c3f07d3ab85eb231550767430243ef5a5e5aef04ba00d8a4f626d261d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=4145484 bytes; lines=98068; markers=<none>; tail=cat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 40844
- `line_count`: 955
- `sha256`: afa0dea3eb9629ade7e961e0e2090440ab40a4aa10ba3dbcdb5820caf7756f42
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40844 bytes; lines=955; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34032
- `line_count`: 798
- `sha256`: e44a8eb702dfdab7ea3cacb72b010893d5e67c7ea4abb897d64080f8a4a04b43
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34032 bytes; lines=798; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 160203
- `line_count`: 3978
- `sha256`: 210a09299170fcff9d7fb46a1c8f8acab82bb9a8a0d7a0eacdf4fdd8cad9b846
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=160203 bytes; lines=3978; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1668572516, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x59b43e44b5a0_0, 0, 1024; %load/vec4 v0x59b43e451a40_0; %store/vec4 v0x59b43e44b4e0_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x59b4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101127
- `line_count`: 2454
- `sha256`: 2c60f73d64a5f71b9f25f1df6b1283c94e12a21d31389ecd27f2fa9f43b35d23
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101127 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53579
- `line_count`: 1375
- `sha256`: cb5d6fd6e4cd99597d5e1e6edd2ea88c86a248b7fff1857c5e2d9963b50ba6ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53579 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 98854
- `line_count`: 2306
- `sha256`: 3d013c3c4c08e74daf3be7f54b7f52ef71a6034a5c3046d5f1846066c03dc167
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=98854 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 556903
- `line_count`: 12403
- `sha256`: 0649180a9c8f2b4a7f51919b14ebc5cc5bb0e2a5cab6df647bda1824a7d9a45d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=556903 bytes; lines=12403; markers=<none>; tail=0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 984834
- `line_count`: 25188
- `sha256`: a1ee631305f3c52f830187535de286959819d9141298590a23bd9048cc528f64
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 6}
- `summary`: vvp evidence; size=984834 bytes; lines=25188; FAIL=8; PASS=6; tail=32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 688308
- `line_count`: 17191
- `sha256`: da4310bfb9607681e0bcdf66b5dc160acffd4f3e66d89bbcc230810c1eda6fb5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=688308 bytes; lines=17191; FAIL=3; PASS=1; tail=9; %flag_get/vec4 9; %jmp/0 T_145.4, 9; %load/vec4 v0x5a95ad229260_0; %pushi/vec4 8, 0, 4; %cmp/ne; %flag_get/vec4 4; %and; T_145.4; %flag_set/vec4 8; %jmp/0xz T_145.2, 8; %load/vec4 v0x5a95ad226640_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_145.7, 9;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1080762
- `line_count`: 27273
- `sha256`: eb1261094b8c3b5c9bcbced94bb2f3b2f7ac6f47a53b4c0782e97744623cf8f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=1080762 bytes; lines=27273; FAIL=3; PASS=1; tail=loc S_0x569ff1c89620; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x569ff1c89620; %join; %free S_0x569ff1c89620; %pushi/vec4 0, 0, 1; %store/vec4 v0x569ff1c8c6c0_0, 0, 1; %pushi/vec4 0, 0, 2; %store/vec4 v0x569ff1c8c5f0_0, 0, 2; %alloc S_0x569ff1932770; %pushi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 801947
- `line_count`: 20203
- `sha256`: 4f56ff6791473acf7c69f787e428adc4edc84136d00d4e7e74df661987e024e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=801947 bytes; lines=20203; FAIL=4; PASS=1; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 101916
- `line_count`: 2491
- `sha256`: cef41765ebd2cd39b9fa3b8583ea9c5e5d20aa6bc1107e64ba9e2050302c309e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=101916 bytes; lines=2491; FAIL=3; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 1696625253, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1818583411, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702043762, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 324507
- `line_count`: 7415
- `sha256`: 9d18ece484fb79e28f1a20c412ed732f6a2723bff7f317b764a62dbf1d16a91c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=324507 bytes; lines=7415; markers=<none>; tail=raw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544503405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 363363
- `line_count`: 7188
- `sha256`: 11e4e2f65a2274b2dcf8e1cb35c77d2d1c367ca4c784c63e36d5aa148f6aca15
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=363363 bytes; lines=7188; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 126003
- `line_count`: 3153
- `sha256`: f588e25177463e0d1768f639657cb786bdd45030381c431fde72f9e0d9e8c6d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=126003 bytes; lines=3153; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 277601
- `line_count`: 7059
- `sha256`: d7cb99fddcdec2a23af7b641a3b3ccb00cdedf7623851d90835abcbcaeedf512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=277601 bytes; lines=7059; FAIL=5; PASS=1; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 121779
- `line_count`: 3021
- `sha256`: 95b1c7f0d2ae382d5815b699612e7e93d74f49c485b4205753a0847a206225c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=121779 bytes; lines=3021; FAIL=5; PASS=1; tail=cc3440_0; %store/vec4 v0x5e5a11cbe5f0_0, 0, 2; %callf/vec4 TD_tb_ooo_fetch_packet_fifo.dut.ptr_inc, S_0x5e5a11cbe3f0; %assign/vec4 v0x5e5a11cc3440_0, 0; T_17.10 ; %load/vec4 v0x5e5a11cc1e80_0; %load/vec4 v0x5e5a11cc3da0_0; %concat/vec4; draw_concat_vec4 %du...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 65826
- `line_count`: 1604
- `sha256`: 1c427d07aae8d8d2e89587c742f38c18443a88e4f540a3c57dcd7852ed534ae0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=65826 bytes; lines=1604; FAIL=8; PASS=2; tail="/usr/lib/x86_64-linux-gnu/ivl/v2005_math.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/va_math.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/v2009.vpi"; S_0x5e207ded01e0 .scope package, "$unit" "$unit" 2 1; .timescale 0 0; v0x5e207df10dc0_0 .var/i "t...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 115028
- `line_count`: 2951
- `sha256`: 3145a708c023140b531093d5734f3365f2c2f65a7ec2cbeebf17f67282ff3b6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=115028 bytes; lines=2951; FAIL=4; PASS=1; tail=e52ac0_0; %store/vec4 v0x5b6f67e50050_0, 0, 64; %load/vec4 v0x5b6f67e52ba0_0; %store/vec4 v0x5b6f67e50130_0, 0, 64; %load/vec4 v0x5b6f67e52820_0; %store/vec4 v0x5b6f67e4fdb0_0, 0, 64; %load/vec4 v0x5b6f67e52900_0; %store/vec4 v0x5b6f67e4fe90_0, 0, 64; %load...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1012809
- `line_count`: 25349
- `sha256`: 28942d7e46ed596a65f7b9e998d2057169c63956565aad6c74bd9e692d458808
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=1012809 bytes; lines=25349; FAIL=5; PASS=1; tail=2, 3; %store/vec4 v0x5729b2a90e00_0, 0, 5; %store/vec4 v0x5729b2a90d20_0, 0, 1; %callf/vec4 TD_tb_ooo_fetch_page_end_fault.u_decode.u_dec1_rvc_decompressor.rvc_imm_6, S_0x5729b2a90b40; %store/vec4 v0x5729b2a8d610_0, 0, 64; %load/vec4 v0x5729b2a8d610_0; %par...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 119607
- `line_count`: 3201
- `sha256`: 689aee669ee1d30a4048826263739bb292dfc1e2085c24b9093c970437f35caf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=119607 bytes; lines=3201; FAIL=5; PASS=1; tail=_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 88434
- `line_count`: 2189
- `sha256`: c646caed5d9b4948a1ae13f2eb2f4df84cf66b13f32e3d6b97adccde38a5ca49
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=88434 bytes; lines=2189; FAIL=4; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 3602804
- `line_count`: 83562
- `sha256`: 70fc400b08776218a57cbb19a236f1aa1ad4bdbbc8956bbe416246ba8f3f8954
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=3602804 bytes; lines=83562; FAIL=4; tail=load/vec4 v0x62675ac81920_0; %and; T_437.7; %flag_set/vec4 11; %flag_get/vec4 11; %jmp/0 T_437.6, 11; %load/vec4 v0x62675ac8f2a0_0; %nor/r; %and; T_437.6; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_437.5, 10; %load/vec4 v0x62675ac778e0_0; %nor/r; %and;...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 352895
- `line_count`: 10751
- `sha256`: b4258f08d499f16c5cc89cb969edfdbe8e140d503dd8619615a081b136eab654
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=352895 bytes; lines=10751; FAIL=5; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68451
- `line_count`: 1835
- `sha256`: e367c7a539b6100fb010006cfc805bf98b599241307af9f56ffcd6952b4a9cf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68451 bytes; lines=1835; FAIL=7; PASS=2; tail=6291e15532f0_0 .var "class_s_bits", 9 0; v0x6291e15533d0_0 .net "class_value_o", 63 0, L_0x6291e1564e60; alias, 1 drivers v0x6291e15534b0_0 .net "double_i", 0 0, v0x6291e1554430_0; 1 drivers v0x6291e1553570_0 .net "frs1_value_i", 63 0, v0x6291e1554500_0; 1...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 97895
- `line_count`: 2767
- `sha256`: 7867d5eae07300723da457cca22693dbcd9483d98a88533f6d1e787fa2f7cc76
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=97895 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x55d268c10c70_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x55d268c10f60_0; %store/vec4 v0x55d268c11880_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x55d268c10dc0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x55d268c10e80_0; %store/vec4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202658
- `line_count`: 6365
- `sha256`: adf9f0dec4dc58c69c13d3dc6ca77016fc19ee0e9625185c8b71af45b7c7af16
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202658 bytes; lines=6365; FAIL=4; tail=f44150_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x64a582f43c40_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x64a582f44750_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x64a582f43d00_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x64a582f44810_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 455206
- `line_count`: 11737
- `sha256`: 02a31b86f02ae6641f354f9dfd45dceb3427167cd82b811c2a4b19feec9a6c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=455206 bytes; lines=11737; FAIL=3; PASS=1; tail=ring_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 83963
- `line_count`: 2210
- `sha256`: dc62e49e95fcecc7a9ef6a179b5d169d54f52acdd132d982cef6ea048e9b9cdf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=83963 bytes; lines=2210; FAIL=8; PASS=2; tail=60fa87784170_0 .var "exp_remainder_nonzero", 0 0; v0x60fa87784250_0 .var "exp_root", 55 0; v0x60fa87784330_0 .var "first_value", 111 0; v0x60fa877843f0_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start ; %pushi/vec4 1024, 0, 112; %s...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 201144
- `line_count`: 5005
- `sha256`: ccbe3aca7a9da8ee72a46749f5ce2cd1fa7ce58622262ec1f7590662b2f0753a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=201144 bytes; lines=5005; FAIL=3; PASS=1; tail=0_0, 4, 3; %load/vec4 v0x59c38ff6fbc0_0; %dup/vec4; %pushi/vec4 0, 0, 3; %cmp/u; %jmp/1 T_9.26, 6; %dup/vec4; %pushi/vec4 1, 0, 3; %cmp/u; %jmp/1 T_9.27, 6; %dup/vec4; %pushi/vec4 2, 0, 3; %cmp/u; %jmp/1 T_9.28, 6; %dup/vec4; %pushi/vec4 3, 0, 3; %cmp/u; %j...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197006
- `line_count`: 6101
- `sha256`: ed967148c265809072d7df171358a7ce34a13224c10c628bb9398b2e81e33f5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197006 bytes; lines=6101; markers=<none>; tail=vec4 v0x5b585e195410_0; %parti/s 1, 2, 3; %store/vec4 v0x5b585e194e50_0, 0, 1; %load/vec4 v0x5b585e195410_0; %parti/s 1, 1, 2; %load/vec4 v0x5b585e195410_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x5b585e195270_0; %or; %store/vec4 v0x5b585e195930_0, 0, 1; %push...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64037
- `line_count`: 1638
- `sha256`: 4fbcf7735a97507a4f3d797bb498c2bc0ad0dda3eec48a64103218f4f4ae172d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64037 bytes; lines=1638; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30253
- `line_count`: 661
- `sha256`: 0bd7a811341b884d2899474188447f0b43ade0fa85c1bba857a035caed805e9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30253 bytes; lines=661; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39292
- `line_count`: 1056
- `sha256`: 988ee6d9a35be2be935a19414c9160b37f4575161c99b9f17f68dffd703997f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39292 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 75847
- `line_count`: 1877
- `sha256`: afc20a4e6cf38a22f42eae632cbf0ca83cc8cb824a6d17d7234feca66e94d3a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=75847 bytes; lines=1877; FAIL=6; PASS=2; tail=vers v0x5e1ac8675c10_0 .var "head_q", 5 0; v0x5e1ac8676100_0 .var/i "idx", 31 0; v0x5e1ac86761e0_0 .net "next_count_w", 6 0, L_0x5e1ac867b1c0; 1 drivers v0x5e1ac86762c0_0 .net "post_alloc_count_w", 6 0, L_0x5e1ac8679cf0; 1 drivers v0x5e1ac86763a0_0 .net "po...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 91032
- `line_count`: 2239
- `sha256`: 87f6dd527bc594b0bef51633c01c509d14bb8515a5d3446723bb339f2ac5d04c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=91032 bytes; lines=2239; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 110858
- `line_count`: 2616
- `sha256`: 40f6d5345d28a43fdd8717031e676ff790e78b466b280349b781c2cc7808d75c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=110858 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x5c76e9783140_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5c76e97836a0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x5c76e9788eb0; %join; %free S_0x5c76e9788eb0; %alloc S_0x5c76e97d0d70; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x5c76e97d...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 146851
- `line_count`: 3486
- `sha256`: 85abd4f6cf06cc3d320e0f60ef97dbf6f24c70e09258ef5dc3307030ef1f819b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=146851 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x5c8d9be85d80; %alloc S_0x5c8d9be85d80; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 92153
- `line_count`: 2289
- `sha256`: 308c5b31b4770516e9a5328bd71aa99308561fa09cac9e4b41835b45ffb531d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=92153 bytes; lines=2289; FAIL=3; PASS=1; tail=5468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1633840229, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5dff28c9e680_0, 0, 1024; %load/vec4 v0x5dff28ca30e0_0; %store/vec4 v0x5dff28c5b050_0, 0, 1; %pushi/vec...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138490
- `line_count`: 3101
- `sha256`: 81da89174a14f7cc865210205c1b4319a7a0f948b75c60e2a9196b5294afa0e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138490 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 351073
- `line_count`: 6189
- `sha256`: 08e3fe3e25270c945df51185e381dcd9eef8432dd47d160001d128e9c265a9aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=351073 bytes; lines=6189; FAIL=4; PASS=2; tail=182651a130; alias, 1 drivers v0x5f1826489bf0_0 .net "trap_exit_exit_valid_o", 0 0, L_0x5f182651a070; alias, 1 drivers v0x5f1826489cb0_0 .net "trap_exit_tval_o", 63 0, L_0x5f182651b3a0; alias, 1 drivers L_0x5f1826518a40 .part L_0x5f18264a5330, 38, 1; L_0x5f1...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 3060430
- `line_count`: 78349
- `sha256`: f347350cb1787fc8916a8e2d80345d443e30a580e3e57b6a154172282ca9a608
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3060430 bytes; lines=78349; markers=<none>; tail=ec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543387501, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1835627635, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5dd79cb2d070_0, 0, 1024; %load/vec4 v0x5dd79cb308c...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 592387
- `line_count`: 14941
- `sha256`: 2029d083a3ee34591cbabf94942a584e238cca29457225f2b0e5c845a093a4d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=592387 bytes; lines=14941; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 1156881
- `line_count`: 29309
- `sha256`: 3d1e94db7c460e34073655eb8064d55968eb81e9dcbdec5b7b0ec7242c64fe95
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1156881 bytes; lines=29309; markers=<none>; tail=1; %jmp T_113.4; T_113.2 ; %ix/load 4, 11, 0; %flag_set/imm 4, 0; %load/vec4a v0x55f80412ad10, 4; %ix/load 4, 11, 0; %flag_set/imm 4, 0; %load/vec4a v0x55f80412ad10, 4; %addi 1, 0, 64; %xor; %store/vec4 v0x55f8041259c0_0, 0, 64; %pushi/vec4 1, 0, 1; %store/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 48692
- `line_count`: 1193
- `sha256`: c2c0d0ed6b34750c814d1f5bb3127a3c167a84e0b0d0884cbd62387a75b0b7fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=48692 bytes; lines=1193; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 265783
- `line_count`: 6674
- `sha256`: 6b34bb3669768a80d0b08a6b799947417725cc7edace19d88d3dc3101910323c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=265783 bytes; lines=6674; FAIL=7; PASS=1; tail=0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 182736
- `line_count`: 4069
- `sha256`: be9326414442756bfbdb873ffbbcf0a43f1ad1699a0a4ebe580db618753ddb66
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=182736 bytes; lines=4069; FAIL=5; PASS=1; tail=ore/vec4 v0x5cc3c1cfdc70_0, 0, 1024; %load/vec4 v0x5cc3c1d5f550_0; %store/vec4 v0x5cc3c1cfdd10_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x5cc3c1c22360_0, 0, 1; %fork TD_$unit.tb_check1, S_0x5cc3c1cb2eb0; %join; %free S_0x5cc3c1cb2eb0; %alloc S_0x5cc3c1ccf...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 66238
- `line_count`: 1572
- `sha256`: 0d91cf376ed154b835418afe4ec5e35b4d6b5c64c8353befe659524f828e62f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=66238 bytes; lines=1572; FAIL=6; PASS=2; tail=000000000000000000000000000100>; P_0x5d3315927c90 .param/l "ROB_COUNT_W" 1 3 6, +C4<00000000000000000000000000000101>; v0x5d331595e590_0 .net "backend_drained", 0 0, L_0x5d3315960f70; 1 drivers v0x5d331595e650_0 .var "backend_drained_q", 0 0; v0x5d331595e72...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 104600
- `line_count`: 2576
- `sha256`: 8bb17106e05954c4b8823081d6138115939020bdc11272f36624ec202d86c92a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=104600 bytes; lines=2576; FAIL=5; PASS=1; tail=$unit.tb_check1, S_0x5bdc7439a7c0; %join; %free S_0x5bdc7439a7c0; %alloc S_0x5bdc7439a7c0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 74265
- `line_count`: 1868
- `sha256`: 4d4f0229fb6e5f92c4c2bfcaa8fb758f9fb95bdafe8d81001f0ba8cb18064e09
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=74265 bytes; lines=1868; FAIL=9; PASS=1; tail=000>, C4<0000000000000000000000000000000000000000000000000000000000000000>, C4<0000000000000000000000000000000000000000000000000000000000000000>; L_0x5900ef429390 .functor BUFZ 64, v0x5900ef423760_0, C4<000000000000000000000000000000000000000000000000000000...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 20971
- `line_count`: 597
- `sha256`: 53c64ac111d0f2e84b45df5a843aac4ba2ac36fc7ee889b62ae3cd82372a04b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=20971 bytes; lines=597; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 197392
- `line_count`: 5034
- `sha256`: 07e61787aecab5f90ff81360c2ec6ac83c3630a7f67a5bfcd72b5bfdaf845b52
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=197392 bytes; lines=5034; FAIL=3; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1818850153, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1869488206, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 724639858, 0, 32; draw_string_vec4 %conc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 3932245
- `line_count`: 92461
- `sha256`: 89451b118ee655d4a1409c294ad3078c4470053569f9a8b8bf0ce24aac8e892a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=3932245 bytes; lines=92461; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63728
- `line_count`: 1586
- `sha256`: a066d2308b6d08daad4bc10ce0bd0fb452cdc174cc38fa4c07dc748550e91abc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63728 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 29174
- `line_count`: 688
- `sha256`: 05880e2b82e34593cf1e91e5650eae9dfdde7baec6fa0bc40303659f65361bfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 18, "PASS": 2}
- `summary`: vvp evidence; size=29174 bytes; lines=688; FAIL=18; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99472
- `line_count`: 2436
- `sha256`: 932c92d955f885ce44c13dccc02442cd08390c2773e4869a843c263626224b54
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99472 bytes; lines=2436; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 298412
- `line_count`: 7124
- `sha256`: f828cdf4cb6a8caa29edd4f6640f2eef70b2f8ee09ce14b920f26c7c6cc5603d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: vvp evidence; size=298412 bytes; lines=7124; markers=<none>; tail=0x63bed25a93c0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_stri...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 54793
- `line_count`: 1562
- `sha256`: f0ded03c5a999a32db5d33aba2ae86207fccc35e2dce9decae9bd299342be904
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=54793 bytes; lines=1562; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 160515
- `line_count`: 3944
- `sha256`: ad7de49985113b55b6c2b6d44d3953782c4f671d0c4ad687e9c4d8b42c1e0218
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=160515 bytes; lines=3944; FAIL=4; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 4865585
- `line_count`: 114910
- `sha256`: 4462a6473cf993682514cedbc1d87f7aebc302feb4fdd1b07fbfbf4e093b6ec6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=4865585 bytes; lines=114910; FAIL=10; PASS=1; tail=c4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36101
- `line_count`: 734
- `sha256`: accdcce89d443557bfc39ef47996f988543076ad2ab9841afcbdc472bb012a3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36101 bytes; lines=734; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 16989
- `line_count`: 476
- `sha256`: 1458a58ed0f2e7b0729a86adc4f84454e7d5536415631db4494392bc5e9e7bbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=16989 bytes; lines=476; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65157
- `line_count`: 1744
- `sha256`: 1bf6da7b56d639d0ec79856f5c01780e00d9862c41a369e97b46f980c1f40184
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65157 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180661
- `line_count`: 4649
- `sha256`: 0deb39a25274e2fb66409a607e01454a13b78bc9af887beb4926eb8388a8f0a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180661 bytes; lines=4649; FAIL=3; PASS=1; tail=6d90_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63a23de57060_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63a23de10490_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63a23de56c10_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x63a23de3a130; %join; %free...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300070
- `line_count`: 8070
- `sha256`: 9c15b910a0dfa6862b375c6fa8692808b3d6a065d5b2cb6ee345a13db72cb7ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300070 bytes; lines=8070; FAIL=4; PASS=1; tail=1; %store/vec4 v0x652b016566e0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x652b016566e0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x652b01656e10_0, 0, 1; %delay 1, 0; %alloc S_0x652b01655280; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25241
- `line_count`: 678
- `sha256`: c0f259f2501d0488e5f50b3e334003308293b6ea32809676d93c466dc7d8580b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25241 bytes; lines=678; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 456
- `line_count`: 5
- `sha256`: d7ee4d9bf2d934d9ead5a4cf8944b9bb8f7a6319177e0f9fcd4ee565339f1e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=456 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isol...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 488
- `line_count`: 5
- `sha256`: eb4d0aea07e979b08aa3e42135b96c1183e85316db3ead923b52d55f71a6294c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=488 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-cs...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3586
- `line_count`: 28
- `sha256`: 59b7ec2c2fb4828d5a94a2c0062a08b7a713f2c2f195dd3b9cc7d8e82cd2c9fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3586 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: 49f3fd3a8042f65f2bdd855b09095bec632d719c7216038b0b68c85f168b0c50
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 552
- `line_count`: 5
- `sha256`: 586e78cd93f668e6863cff7831640ef523556b858b4ff08868900fcba6e5986a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=552 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3365
- `line_count`: 28
- `sha256`: cee04d87568035f82c9b307224c2b1bc1a642a3f1ca8b3ca214822c15f7a073e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3365 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 4890caaa51e86777dca050ca46e985e2b3efb76d6a7fb917fe8fc48dd13dad24
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-pr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 4dfa2bf7af98387fe149bc682276acbedcd5e170349beb79001d086d09c4135d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 5
- `sha256`: 7a71dc7e78f10aafb206388e86128f9b652143612b4e532da7ba50f16fbe0bac
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 502
- `line_count`: 5
- `sha256`: 6adf78ec6ada2f9452cf3adea3049e645bce0fc7fb2e11d14ec8ea8ba98c2a6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=502 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 057d6b28f88255ac66e864f63917827a0d8107ffd483bbe762fa8cb42337a70b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-prob...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 579
- `line_count`: 5
- `sha256`: 943209402eaa01074369d0094f9a6163c9e180db6d2d259eb686c0fd6e3742e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=579 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isol...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 501
- `line_count`: 5
- `sha256`: e4329833ca6eb9ace20cb99414edf5e75abcc0171b482f76793a42c65de9e2d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=501 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 507
- `line_count`: 5
- `sha256`: 4d1c4355ad89edfb52d55ae74193cab45843fbdd6ede6d459ddac331ee6c0aae
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=507 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14076
- `line_count`: 85
- `sha256`: 9b18e1d5e0fddfce56e04863a446dda98d63153ac9ce82f1a0e7e5680243a811
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14076 bytes; lines=85; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 13752
- `line_count`: 83
- `sha256`: 07f24f823b8bb9cd04d47d01e4fb10073b5001b2ea494dbb8a67f76048d93cfe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13752 bytes; lines=83; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 507
- `line_count`: 5
- `sha256`: 7c837b22c42eab2713fbef16449bd4013dec528c32df4491bb1018e0b0d762fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=507 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 586
- `line_count`: 5
- `sha256`: 870516453c08faf05740bbfe3bc7962e8f3954dddd94fcaac6fd936b5263be9b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=586 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: 34afef0f485718f9f2a81954a5053ae043d4a5a49d3888913837c912faeef24a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 964
- `line_count`: 9
- `sha256`: 014e5a95cca7a86544c951498d8cdc2c02bc1841c1c49eebaa2cd3380d2461c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=964 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 919
- `line_count`: 9
- `sha256`: 3cb200cba1f720c4f11291952664c7e55727fdace5861d19d83eeecf0a89e403
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=919 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 702
- `line_count`: 5
- `sha256`: 7c9ab330d44b17974abb7fdf15600816e3bb4e11532b4ccba1710c28715fe8fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=702 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 974
- `line_count`: 9
- `sha256`: 98c1f0937947013fd1e9f4c6413263325e8678c80727b48e42b0967cbc106b5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=974 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: a5e24014a2e9f38f12d5d42ee89c30d23d10e378e250b2b920799302e60b48c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 659
- `line_count`: 6
- `sha256`: 7434e0cc1a022bc5a50e60ff5e0badbfcc454e9158a8746126e6574b292250dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=659 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 5
- `sha256`: 3fc7c1cbcd3d355d5e28d17e95c5c3e0af1a2eccbb310f5e0aee36946507ac1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=521 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 9
- `sha256`: e5a479be882e212f1965b25c8b9360c3b2d1961e5f26f3ee62889c066d7208c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: 4afee0048904fcf397632a2c2b01e962343132dd8819b4b73af39589f66dd24a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 929
- `line_count`: 9
- `sha256`: 233369baa0537a61ade7b87ba38ca4bddedfb32060d20269d9e83600a290cd94
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=929 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 16631
- `line_count`: 74
- `sha256`: 6b78ac271de1b23bbb11f9d3f9aa41b5adceecd276ed9e318f78ca62708d086c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16631 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 607
- `line_count`: 5
- `sha256`: 4a09a5c3966c55278d5f6911b7b7adf1655a13eb5adb4f9b4c5f7e7e0924ed4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=607 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 593
- `line_count`: 5
- `sha256`: 244d33816da778741c76b66767b7db70da895866407d3cebdf4b0c99f099feec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=593 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 685
- `line_count`: 5
- `sha256`: 3b93f0dc2f47f5163a14581ea51d6d05c1236f8d4fb226900b7cc9336f9a9345
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=685 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 615
- `line_count`: 5
- `sha256`: 55546f9ea782868dfa1423081633983cc4527d2bc41b526cca245db21b7f4078
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=615 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: bd97e4313eee77a9c5318f61ffe640db318e297a05041373bda52c03cdab13cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: d2e2a0e586d68469832bb0e8f4b1768a95c99c13159409c4400f23575ae6fdf4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8456
- `line_count`: 59
- `sha256`: fd23453ab3ea401100328213180b18482c61dbedceb12f50c63d4706113fd001
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8456 bytes; lines=59; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89830
- `line_count`: 717
- `sha256`: f67fc66f350c6ecc44c1d67299226649f7f8e4ecc688f8bc404c3882498d77a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89830 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86573
- `line_count`: 650
- `sha256`: dcd70460ae56b287d98220e0ca2e3ab294a9f607f12b9894a7f5b10301c1e07f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86573 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86544
- `line_count`: 650
- `sha256`: d57262abc9d9965acea8edab9a91bb17ed5da6623b5cd0d4b51b73ad856cc74b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86544 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89508
- `line_count`: 673
- `sha256`: 7e4c8a0d7f9e0abc3e8a5d33cf9ab42738bdc9ee2979a167e4cc33e9d53d7645
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89508 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 568
- `line_count`: 5
- `sha256`: fee9c40b6a091e327dcd7ff220dd9ce7d5bc6bbff0d5e54d3760c43c7e8038a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=568 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 666
- `line_count`: 5
- `sha256`: 3ebdfcaf97d7a249dd84fc91a926edede1b6d400260f31fca967199ba16a30a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=666 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 720
- `line_count`: 5
- `sha256`: 3f6139518884cb2cace24b3cbf0cb99c5555a731bb42a429569d40a0fd31a718
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=720 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 705
- `line_count`: 5
- `sha256`: e60bd8db31742bf394167a74d48beb9058904a01aa3d9d4725f3ac07bc5b5a05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=705 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 643
- `line_count`: 5
- `sha256`: 4a4fe726c1a3a8f986d0e02200825f2c010ecb674213c38ad2ea741c283cd918
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=643 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 562
- `line_count`: 5
- `sha256`: c49d57a2f44313f89fc5e9235c340584768d9b223e1f74c295ba28f6046a8866
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=562 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 584
- `line_count`: 5
- `sha256`: df7f506013503c8687cb51017910c7fc19876abd5e1e3543ba9283d1d372962c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=584 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 738
- `line_count`: 6
- `sha256`: 635cf2cf83f4d5c2f6d8815a243220f5be6bb9e22943115ce3114e0749c9b70e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=738 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87909
- `line_count`: 664
- `sha256`: 5b03bc1d718c6c4cd510bb08cd02684f8d64c735fd6c40b5e798f82c3e75929f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87909 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 639
- `line_count`: 5
- `sha256`: cb3e3f1f3d843d1e6b219e2836b7a248d39cba724e80866880a23c9439d152f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=639 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 562
- `line_count`: 5
- `sha256`: 7fbebbdf751c05350d8fc3e0c4bb9920cd7d34d0c2da073adc88316cb70f36d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=562 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 16641
- `line_count`: 74
- `sha256`: 85b310fff31cc690469111d8a97ec687390e41ff9465474ffcb3dd57768b3de0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16641 bytes; lines=74; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 538
- `line_count`: 5
- `sha256`: 0b8365b8a49d75e54934f97d61d37c2f6b009115b6f4830e32e08ba42c16dc7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=538 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: 8dcf5ef74cc8d728b3e7d7862d79a6edc7e5f970a6308daf2c3cc0839e64e127
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: c79f1dd5b87561061cdc3aded7c2ec4035f5ad4a254a8049dd106a72ea71119c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 5
- `sha256`: b0e82413366074cd66488adbd8d492f409450b9c90930ce07ff37fbffd284bf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3754
- `line_count`: 36
- `sha256`: 377e256cd63fb61f345524b3c12aa71a341a95529ccd0e38cc46b05637fe5a50
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3754 bytes; lines=36; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 573
- `line_count`: 5
- `sha256`: e1836c680e0b63cfb66bb5230a37c404b3de9e8bd5a4942a636a91f9a647e7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=573 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1517
- `line_count`: 13
- `sha256`: 6587b215e1e8aa1be5cced0725f1c4c1f8d3686fa1ea35c13e9b80a6e028422f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1517 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 680
- `line_count`: 5
- `sha256`: a7712c32112516b864acfbc2ec0e8bd3a0bc63fd573b60ca19b6e8bd235856e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=680 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1087
- `line_count`: 12
- `sha256`: 2778380efbf576c58d789cc378f9c10325f217c31bab70ea4624ae9592434663
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1087 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 834
- `line_count`: 9
- `sha256`: a9ae14d1109b3802e84b964cfafaa5195fb348523dd2020bdeace9da9be76b40
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=834 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 5
- `sha256`: d9daa9c7e252496223b720e8ad26c29f216db689895d23c1b5c5ef8808fa524c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=530 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 522
- `line_count`: 5
- `sha256`: 8fadd8692ce0d78413c43f0d99030afb6b219c97e9272c4d54c03be44724306d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=522 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv6...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 580
- `line_count`: 5
- `sha256`: 6b0ae0aa12d493bc4fc12331f4cb2ca63e50c6328f5007f127834a9e711c01ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=580 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 988
- `line_count`: 10
- `sha256`: 047d333cd2ca1991856fa3043948b134cbe11b103dce76fba70c6d927dd9d9bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=988 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 900
- `line_count`: 7
- `sha256`: 6d55e8f1c5bfae5f359302fc744a32ed8ede03c42a93fab36963538b29a3b73d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=900 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 562
- `line_count`: 5
- `sha256`: 0433d53c20b319735c2e2265e1e7ae902610a85d167f91cf0f3775663aea9beb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=562 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 60ce0c15554645b6087907f88b7743ff9cbd066859dede9a201ac855ae35e19f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3618
- `line_count`: 32
- `sha256`: 72ecb0d025e6746b0ebf29dc9ed34514315eb81111ba8444db4c18256fa24c2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3618 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 14881
- `line_count`: 99
- `sha256`: 585c6323ece942d051e2788282b7404a515db8bd07985f9d0ebeb0d519a8d130
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14881 bytes; lines=99; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7927
- `line_count`: 62
- `sha256`: a65ad87f1e962d84d3da8427fd6936aca0276557015e8a78530d61906942fb19
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7927 bytes; lines=62; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52234
- `line_count`: 392
- `sha256`: 2cd392f6be2a4c1d689d9063bf033eba8eb8d9253c325eaa6ce15adf98a041a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52234 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1032
- `line_count`: 8
- `sha256`: a0aae64a70f7f45385cc5bba763a358f5daafdb036f77c1196ee3ec4f22d1f5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1032 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 5
- `sha256`: 2d9dae64a22db4ab38789f15856c57609b036f23adea94f8b6642c3b35acb1a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=530 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1172
- `line_count`: 11
- `sha256`: 3d330db336c26a65933c390157f9e40032a20fe00521d9a5cd79e1120f987a63
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1172 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 5
- `sha256`: f928742498fbd65c848f5d90ae564a323186b432f6410e5d425c2c880b2235d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=614 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 962
- `line_count`: 10
- `sha256`: b7cd9c064d0ddb0caa4821838c9e70fd0dafe12c99bda5381b19ce78adb07a63
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=962 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 938
- `line_count`: 9
- `sha256`: b06695f4b07ae38ffeaa74c81f3e1cbca785cc310ad4482757a3f0d2fb64902d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=938 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 807
- `line_count`: 6
- `sha256`: 32f0a1c2fc07489ea00f821693933c2cc0467017e49b0018c9a486180efe8b92
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=807 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 544
- `line_count`: 5
- `sha256`: 5a3120caa1cc0a22e7be3b21fca684a580da2c4b78897ea1e79dcd8bb4a934f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=544 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 16717
- `line_count`: 75
- `sha256`: 21093608250e16aa6ee8fac38f304c66956cc91c14b3e91b18f736d3aa12a871
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=16717 bytes; lines=75; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 550
- `line_count`: 5
- `sha256`: 321c4df44579d6752207e17d6bf6581ad602fde438b00f3fe9e3776448f25cd2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=550 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 5
- `sha256`: 19321107a15857362c8cdd183af536ca52b2a273abc6d3b04d8d9e018248c7d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=556 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: 93af5988aebc199b93da9143d84e4e4e4f66389ab46356956d34fe1e28c620ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 820
- `line_count`: 8
- `sha256`: c68ee1f446a9b270707493ea29a2751f9fd7b4e175b3d38b117f2bc48ac85889
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=820 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-pr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 920
- `line_count`: 9
- `sha256`: 91afdace81a3bd090f5631d36892fbd5f72969c9389f8eabea1413ebaa2384a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=920 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 1053
- `line_count`: 9
- `sha256`: 4582feefb071cb03a1ab53ee70bd292490a6bbd2a88f76f9a8cb65aee652e717
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1053 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155147
- `line_count`: 1109
- `sha256`: aed3b9da9d47e04346ee705541a54fb36ad9975e0d472290a412ec10f58011f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155147 bytes; lines=1109; PASS=2; tail=ll 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensi...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 586
- `line_count`: 5
- `sha256`: c746baa56526dce5620695af48d71da9f4e91f3ecab6e87fe44d1483337b86a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=586 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 635
- `line_count`: 5
- `sha256`: 5648cad30334613139fb03289e72c6187b6be7061b4573f671eb3371c51791c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=635 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 521
- `line_count`: 5
- `sha256`: 5d721afbbf3e6ed9837b264bdd4b742067d7b61842c5e5ccedb0a61cd843e807
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=521 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17648
- `line_count`: 134
- `sha256`: a706ca7f92fae25bdbb736a9e64b391a6ec8755877b3a2220275634cacaabad2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17648 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 459
- `line_count`: 5
- `sha256`: 423dd53f67b6a0c7641aca938c0aa02be470f014e9c2c6b149a50bdf8350da2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=459 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-is...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: ec568caed93b4f1674d7d50c42341715cff1006a11277dc09406ca5806d43e8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isol...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results/summary.txt

- `kind`: txt
- `size_bytes`: 3196
- `line_count`: 105
- `sha256`: 6d11123526638a0f0ea39e1be2ec3dd75cd7fa4bfcfffc7a65bb90a330a1903f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 192}
- `summary`: txt evidence; size=3196 bytes; lines=105; PASS=192; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/module-final-v2/results - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_alu...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/audit.log

- `kind`: log
- `size_bytes`: 256
- `line_count`: 2
- `sha256`: 048421b83d53b134255e911fc0ca81559184a7e4b0127739e282a8adfa17487e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=256 bytes; lines=2; PASS=4; tail=[T3K-NEGATIVE-LOG-CHECK] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=reachable compile_rc=0 sim_rc=0 classifier_rc=1 [T3K-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED false_green=RED missing_reason=RED sim_nonzero=RED classifier_input_error=RED

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/classifier.log

- `kind`: log
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 084aef9fc5b0b5a67c8854f647e7e9c00724074cd02fd290bb6d4056f7c571fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=33 bytes; lines=1; ERROR=2; tail=log contains an ERROR diagnostic

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/result.log

- `kind`: log
- `size_bytes`: 973
- `line_count`: 8
- `sha256`: 3119fa1ba426d15814056c704c15eb433d83925ae308023486c402eb86f1eb26
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=973 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[COMPILE] iverilog -g2012 -Wall -DOOO_ASSERT -s tb_t3k_csr_equiv_negative -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/sim.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 81c683e36572548671e05195fd7da32486869ed048ec64c5b688c67c01a2cf6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=418 bytes; lines=5; ERROR=2; PASS=2; tail=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v:677: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged Time: 15 Scope: tb_t3k_csr_equiv_negative.dut [PASS] tb_t3k_csr_equiv_ne...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/status.txt

- `kind`: txt
- `size_bytes`: 273
- `line_count`: 9
- `sha256`: 13d9e4ee6dbde5176d1465c894ef51457f38f25b51a23f4d050134cfd921d200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=273 bytes; lines=9; PASS=4; tail=case=csr-legal-view-equiv assertion_marker=[CSR-LEGAL-VIEW-EQUIV] premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 compile_rc=0 sim_rc=0 classifier_rc=1 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_false_gree...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final-v2/tb-t3k-csr-equiv-negative.vvp

- `kind`: vvp
- `size_bytes`: 156015
- `line_count`: 3439
- `sha256`: 9493f674f1627cf7fb4d60f26c74bc18e936be4d451170c948e45cbc5fe8daeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 1}
- `summary`: vvp evidence; size=156015 bytes; lines=3439; ERROR=2; PASS=1; tail=shi/vec4 3860, 0, 12; %cmp/u; %jmp/1 T_2.58, 6; %load/vec4 v0x59a85eb73ff0_0; %store/vec4 v0x59a85eb75670_0, 0, 12; %callf/vec4 TD_tb_t3k_csr_equiv_negative.dut.csr_pmpcfg_known, S_0x59a85eb754e0; %flag_set/vec4 8; %flag_get/vec4 8; %jmp/1 T_2.61, 8; %load/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/audit.log

- `kind`: log
- `size_bytes`: 213
- `line_count`: 2
- `sha256`: af96a488c74ce6a59f039adf234b6abb2e1e72b5d97572a46d524fe671f35c9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=213 bytes; lines=2; PASS=4; tail=[T3K-NEGATIVE-LOG-CHECK] PASS assertion=[CSR-LEGAL-VIEW-EQUIV] premise=reachable compile_rc=0 sim_rc=0 classifier_rc=1 [T3K-NEGATIVE-LOG-SELFTEST] PASS missing=RED duplicate=RED false_green=RED missing_reason=RED

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/classifier.log

- `kind`: log
- `size_bytes`: 33
- `line_count`: 1
- `sha256`: 084aef9fc5b0b5a67c8854f647e7e9c00724074cd02fd290bb6d4056f7c571fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=33 bytes; lines=1; ERROR=2; tail=log contains an ERROR diagnostic

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/result.log

- `kind`: log
- `size_bytes`: 970
- `line_count`: 8
- `sha256`: 1d28eeaef878308e85f89ab44fd6057bcf04dcd87422381eb3b6e75673ddebc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 4, "FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=970 bytes; lines=8; FAIL=2; ERROR=4; PASS=2; tail=[COMPILE] iverilog -g2012 -Wall -DOOO_ASSERT -s tb_t3k_csr_equiv_negative -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/sim.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: 81c683e36572548671e05195fd7da32486869ed048ec64c5b688c67c01a2cf6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 2}
- `summary`: log evidence; size=418 bytes; lines=5; ERROR=2; PASS=2; tail=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/CsrFile.v:677: [CSR-LEGAL-VIEW-EQUIV] main/probe legality diverged Time: 15 Scope: tb_t3k_csr_equiv_negative.dut [PASS] tb_t3k_csr_equiv_ne...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/status.txt

- `kind`: txt
- `size_bytes`: 273
- `line_count`: 9
- `sha256`: 13d9e4ee6dbde5176d1465c894ef51457f38f25b51a23f4d050134cfd921d200
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: txt evidence; size=273 bytes; lines=9; PASS=4; tail=case=csr-legal-view-equiv assertion_marker=[CSR-LEGAL-VIEW-EQUIV] premise_marker=[T3K-NEGATIVE-PREMISE] valid=1 same_tuple=1 forced_divergence=1 compile_rc=0 sim_rc=0 classifier_rc=1 global_result=EXPECTED_FAIL marker_audit=PASS missing_duplicate_false_gree...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/negative-contract-final/tb-t3k-csr-equiv-negative.vvp

- `kind`: vvp
- `size_bytes`: 156015
- `line_count`: 3439
- `sha256`: 35917369fd2921abffd9c4ff224373a9a5e2a3e34d1708057531ffa7bd0e8ccc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"ERROR": 2, "PASS": 1}
- `summary`: vvp evidence; size=156015 bytes; lines=3439; ERROR=2; PASS=1; tail=shi/vec4 3860, 0, 12; %cmp/u; %jmp/1 T_2.58, 6; %load/vec4 v0x6388c61efff0_0; %store/vec4 v0x6388c61f1670_0, 0, 12; %callf/vec4 TD_tb_t3k_csr_equiv_negative.dut.csr_pmpcfg_known, S_0x6388c61f14e0; %flag_set/vec4 8; %flag_get/vec4 8; %jmp/1 T_2.61, 8; %load/...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v2/fresh-t3k.log

- `kind`: log
- `size_bytes`: 668
- `line_count`: 1
- `sha256`: ff9dddfde0e91fe46f495b7bbf064b36137fa099e3c20d853a147f39bb2af97f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=668 bytes; lines=1; PASS=4; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=fresh probe=1/12/3/5 legacy=1/12/3/5 distinct_bindings=PASS tokens={'OooCsrAccessRequestMux': {'csr_probe_valid': 5, 'csr_probe_addr': 60, 'csr_probe_funct3': 15, 'csr_probe_rs1_idx': 27}, 'OooControlPlane': {'csr_probe_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v2/old-t3j-expected-fresh-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v2/old-t3j-expected-fresh-red.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: cc6f7b82c77b9ca751ce8425bfb34d4528a7aaacfb2f73a39d12749d1fbe81bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=203 bytes; lines=1; FAIL=2; tail=[T3K-NETLIST-STRUCTURE] FAIL: fresh CSR probe ABI width/cardinality mismatch: {'mux_valid': 0, 'mux_addr': 0, 'mux_funct3': 0, 'mux_rs1': 0, 'csr_valid': 0, 'csr_addr': 0, 'csr_funct3': 0, 'csr_rs1': 0}

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v2/old-t3j.log

- `kind`: log
- `size_bytes`: 79
- `line_count`: 1
- `sha256`: cdc5dd4ee5ab1b6eabd6a0db0bc33e430aa576def8dcde718624de2545ce1f02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=79 bytes; lines=1; PASS=2; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=old probe_tokens=0 legacy_access=1/12/3/5

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v3/fresh-t3k.log

- `kind`: log
- `size_bytes`: 668
- `line_count`: 1
- `sha256`: ff9dddfde0e91fe46f495b7bbf064b36137fa099e3c20d853a147f39bb2af97f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=668 bytes; lines=1; PASS=4; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=fresh probe=1/12/3/5 legacy=1/12/3/5 distinct_bindings=PASS tokens={'OooCsrAccessRequestMux': {'csr_probe_valid': 5, 'csr_probe_addr': 60, 'csr_probe_funct3': 15, 'csr_probe_rs1_idx': 27}, 'OooControlPlane': {'csr_probe_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v3/old-t3j-expected-fresh-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v3/old-t3j-expected-fresh-red.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: cc6f7b82c77b9ca751ce8425bfb34d4528a7aaacfb2f73a39d12749d1fbe81bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=203 bytes; lines=1; FAIL=2; tail=[T3K-NETLIST-STRUCTURE] FAIL: fresh CSR probe ABI width/cardinality mismatch: {'mux_valid': 0, 'mux_addr': 0, 'mux_funct3': 0, 'mux_rs1': 0, 'csr_valid': 0, 'csr_addr': 0, 'csr_funct3': 0, 'csr_rs1': 0}

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v3/old-t3j.log

- `kind`: log
- `size_bytes`: 79
- `line_count`: 1
- `sha256`: cdc5dd4ee5ab1b6eabd6a0db0bc33e430aa576def8dcde718624de2545ce1f02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=79 bytes; lines=1; PASS=2; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=old probe_tokens=0 legacy_access=1/12/3/5

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v4/fresh-t3k.log

- `kind`: log
- `size_bytes`: 668
- `line_count`: 1
- `sha256`: ff9dddfde0e91fe46f495b7bbf064b36137fa099e3c20d853a147f39bb2af97f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=668 bytes; lines=1; PASS=4; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=fresh probe=1/12/3/5 legacy=1/12/3/5 distinct_bindings=PASS tokens={'OooCsrAccessRequestMux': {'csr_probe_valid': 5, 'csr_probe_addr': 60, 'csr_probe_funct3': 15, 'csr_probe_rs1_idx': 27}, 'OooControlPlane': {'csr_probe_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v4/old-t3j-expected-fresh-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v4/old-t3j-expected-fresh-red.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: cc6f7b82c77b9ca751ce8425bfb34d4528a7aaacfb2f73a39d12749d1fbe81bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=203 bytes; lines=1; FAIL=2; tail=[T3K-NETLIST-STRUCTURE] FAIL: fresh CSR probe ABI width/cardinality mismatch: {'mux_valid': 0, 'mux_addr': 0, 'mux_funct3': 0, 'mux_rs1': 0, 'csr_valid': 0, 'csr_addr': 0, 'csr_funct3': 0, 'csr_rs1': 0}

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v4/old-t3j.log

- `kind`: log
- `size_bytes`: 79
- `line_count`: 1
- `sha256`: cdc5dd4ee5ab1b6eabd6a0db0bc33e430aa576def8dcde718624de2545ce1f02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=79 bytes; lines=1; PASS=2; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=old probe_tokens=0 legacy_access=1/12/3/5

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v5/fresh-t3k.log

- `kind`: log
- `size_bytes`: 668
- `line_count`: 1
- `sha256`: ff9dddfde0e91fe46f495b7bbf064b36137fa099e3c20d853a147f39bb2af97f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=668 bytes; lines=1; PASS=4; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=fresh probe=1/12/3/5 legacy=1/12/3/5 distinct_bindings=PASS tokens={'OooCsrAccessRequestMux': {'csr_probe_valid': 5, 'csr_probe_addr': 60, 'csr_probe_funct3': 15, 'csr_probe_rs1_idx': 27}, 'OooControlPlane': {'csr_probe_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v5/old-t3j-expected-fresh-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v5/old-t3j-expected-fresh-red.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: cc6f7b82c77b9ca751ce8425bfb34d4528a7aaacfb2f73a39d12749d1fbe81bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=203 bytes; lines=1; FAIL=2; tail=[T3K-NETLIST-STRUCTURE] FAIL: fresh CSR probe ABI width/cardinality mismatch: {'mux_valid': 0, 'mux_addr': 0, 'mux_funct3': 0, 'mux_rs1': 0, 'csr_valid': 0, 'csr_addr': 0, 'csr_funct3': 0, 'csr_rs1': 0}

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v5/old-t3j.log

- `kind`: log
- `size_bytes`: 79
- `line_count`: 1
- `sha256`: cdc5dd4ee5ab1b6eabd6a0db0bc33e430aa576def8dcde718624de2545ce1f02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=79 bytes; lines=1; PASS=2; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=old probe_tokens=0 legacy_access=1/12/3/5

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v6/fresh-t3k.log

- `kind`: log
- `size_bytes`: 717
- `line_count`: 1
- `sha256`: 31e55b8ea30871dcff78ffde910653c5c08372d86024d45f8839abb8b9faf921
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=717 bytes; lines=1; PASS=4; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=fresh probe=1/12/3/5 legacy=1/12/3/5 distinct_bindings=PASS csr_illegal_cone=probe:19 mux_probe_cone=head:45 tokens={'OooCsrAccessRequestMux': {'csr_probe_valid': 5, 'csr_probe_addr': 60, 'csr_probe_funct3': 15, 'csr_pro...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v6/old-t3j-expected-fresh-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v6/old-t3j-expected-fresh-red.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: cc6f7b82c77b9ca751ce8425bfb34d4528a7aaacfb2f73a39d12749d1fbe81bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=203 bytes; lines=1; FAIL=2; tail=[T3K-NETLIST-STRUCTURE] FAIL: fresh CSR probe ABI width/cardinality mismatch: {'mux_valid': 0, 'mux_addr': 0, 'mux_funct3': 0, 'mux_rs1': 0, 'csr_valid': 0, 'csr_addr': 0, 'csr_funct3': 0, 'csr_rs1': 0}

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final-v6/old-t3j.log

- `kind`: log
- `size_bytes`: 106
- `line_count`: 1
- `sha256`: ead4d11d7973d2cfe5f3dc6c5fe3d20cae047488f91681746b2afe88c13cfd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=106 bytes; lines=1; PASS=2; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=old probe_tokens=0 legacy_access=1/12/3/5 csr_illegal_cone=legacy:19

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final/fresh-t3k.log

- `kind`: log
- `size_bytes`: 668
- `line_count`: 1
- `sha256`: ff9dddfde0e91fe46f495b7bbf064b36137fa099e3c20d853a147f39bb2af97f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=668 bytes; lines=1; PASS=4; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=fresh probe=1/12/3/5 legacy=1/12/3/5 distinct_bindings=PASS tokens={'OooCsrAccessRequestMux': {'csr_probe_valid': 5, 'csr_probe_addr': 60, 'csr_probe_funct3': 15, 'csr_probe_rs1_idx': 27}, 'OooControlPlane': {'csr_probe_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final/old-t3j-expected-fresh-red-status.txt

- `kind`: txt
- `size_bytes`: 27
- `line_count`: 1
- `sha256`: e9acf89dfff414ab3c98f1854c150d139b197a561e93a70ec9ed84771a680995
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=27 bytes; lines=1; markers=<none>; tail=expected_fresh_on_old_rc=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final/old-t3j-expected-fresh-red.log

- `kind`: log
- `size_bytes`: 203
- `line_count`: 1
- `sha256`: cc6f7b82c77b9ca751ce8425bfb34d4528a7aaacfb2f73a39d12749d1fbe81bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=203 bytes; lines=1; FAIL=2; tail=[T3K-NETLIST-STRUCTURE] FAIL: fresh CSR probe ABI width/cardinality mismatch: {'mux_valid': 0, 'mux_addr': 0, 'mux_funct3': 0, 'mux_rs1': 0, 'csr_valid': 0, 'csr_addr': 0, 'csr_funct3': 0, 'csr_rs1': 0}

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/netlist-structure-root-final/old-t3j.log

- `kind`: log
- `size_bytes`: 79
- `line_count`: 1
- `sha256`: cdc5dd4ee5ab1b6eabd6a0db0bc33e430aa576def8dcde718624de2545ce1f02
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=79 bytes; lines=1; PASS=2; tail=[T3K-NETLIST-STRUCTURE] PASS: expect=old probe_tokens=0 legacy_access=1/12/3/5

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/checker.log

- `kind`: log
- `size_bytes`: 18644
- `line_count`: 1
- `sha256`: 471ad38673f5d09bcd62e8ecf58475c733cbcce749fe65c02d5bd4f1032c7ce6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=18644 bytes; lines=1; FAIL=2; tail=[T3K-FOCUSED-STA] FAIL: query selector/status mismatch commit_to_pending: {'source_object': ['u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_valid_i', 'u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_exceptio...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-commit-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 21781
- `line_count`: 234
- `sha256`: 01c5d0dc25e17df705fe061da3e4757e8f60201469f62169d5747cf915161b37
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=21781 bytes; lines=234; markers=<none>; tail=source_count=98 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_exception_i source_object=u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-commit_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 380260
- `line_count`: 3280
- `sha256`: e7d51efb539436a21c7b996827ca20d384c84fdc14627fa287455e4ae2989e9a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=380260 bytes; lines=3280; markers=<none>; tail=/u_int_backend/_51396_/Y (NAND3X1P4H7L) 0.177 7.186 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/_51397_/Z (NOR2BX1P4H7L) 0.086 7.272 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/_514...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 425
- `line_count`: 8
- `sha256`: dfaa8e6e6e37f64ab700c575da71ec1eeb50707da1c8d4cc4279e2da6263e7bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=425 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=fresh period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3k-csr-probe-isolation/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 in...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 364
- `line_count`: 17
- `sha256`: 67e84cc6615cabb2469fb0e8ad4fa6c76e010bcf4d4216893199e31dac2d1abe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=364 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=21 legacy_csr_input_pins=21 probe_csr_input_pins=21 illegal_output_pins=1 state_priv_q_pins=1 state_mst...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 40688
- `line_count`: 643
- `sha256`: cd131cbef39794f653eff291c55a7380d05b65b7dcb3f4530954f2e6b642be44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=40688 bytes; lines=643; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 143671
- `line_count`: 1785
- `sha256`: 741c62a1c17bb7cedbeb0a7ec22b7ac7df0e38813a6b722846f2cedceefc965c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=143671 bytes; lines=1785; markers=<none>; tail=_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/head_inst0_i_19_ source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/head_inst0_i_20_ source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/head_inst0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 146380
- `line_count`: 1760
- `sha256`: 6619768707832e0e75f02ed6fb1a99503f4a6c959a68cdbe5f1026bceba64512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=146380 bytes; lines=1760; markers=<none>; tail=Time Description ----------------------------------------------------------- 0.000 0.000 clock core_clock (rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/_7454_/CK (DFFQX1H7L) 0.082 0.082 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 146380
- `line_count`: 1760
- `sha256`: 6619768707832e0e75f02ed6fb1a99503f4a6c959a68cdbe5f1026bceba64512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=146380 bytes; lines=1760; markers=<none>; tail=Time Description ----------------------------------------------------------- 0.000 0.000 clock core_clock (rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/_7454_/CK (DFFQX1H7L) 0.082 0.082 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 1041
- `line_count`: 24
- `sha256`: cb4c62757c571d69f9871aec0e737965c5b4a4dba345e3dccdcbd1c535ed6184
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=1041 bytes; lines=24; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 52
- `line_count`: 1
- `sha256`: 899fe0c58b9155457f2fd043b9e36f9361a610625ec55d0da173d9b2e8e388d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=52 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=133

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-pending-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 22164
- `line_count`: 236
- `sha256`: 4e1f391b0853f53ccda9d8f684ed0c4aa521aac9e46c170ec4408f32eb8455a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=22164 bytes; lines=236; markers=<none>; tail=source_count=100 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_csr_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_ac...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-pending_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 53560
- `line_count`: 820
- `sha256`: 1edbab07b3ca8e6e7832d02641e50f08ddd907f696337e60b1d72f3979356dbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=53560 bytes; lines=820; markers=<none>; tail=Startpoint: u_core/u_ooo_core/u_control_plane/u_pending_system_sequencer/_2259_ (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_ (rising edge-triggered flip-flop clocked...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13538
- `line_count`: 157
- `sha256`: 99f6afc633344641638bf4c1ba5d72f1cb8efd308daa4dd9498238419677fdab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13538 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_probe_valid_i source_object=u_core/u_csr_file/csr_probe_addr_i_0_ source_object=u_core/u_csr_file/csr_probe_addr_i_1_ source_object=u_core/u_csr_file/csr_probe_addr_i_2_ source_object=u_core/u_csr_file/csr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 146380
- `line_count`: 1760
- `sha256`: 6619768707832e0e75f02ed6fb1a99503f4a6c959a68cdbe5f1026bceba64512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=146380 bytes; lines=1760; markers=<none>; tail=Time Description ----------------------------------------------------------- 0.000 0.000 clock core_clock (rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/_7454_/CK (DFFQX1H7L) 0.082 0.082 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: e85728eadddf1e32f578ef5d38c22d5f0537984e142f67039767c4a4de1953cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_15480_/Q source_object=u_core/u_csr_file/_15087_/Q source_object=u_core/u_csr_file/_15088_/Q source_object=u_core/u_csr_file/_15089_/Q source_object=u_core/u_csr_file/_15090_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v3/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 177580
- `line_count`: 1800
- `sha256`: 15ebec566a61200b4edc3528b4453f85af98a553c0cdbc35b7121e1dbed531bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=177580 bytes; lines=1800; markers=<none>; tail=ore/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20230_/Y (BUFX1P4H7L) 0.097 3.565 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20292_/Y (NOR4BBX0P5H7L...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/checker.log

- `kind`: log
- `size_bytes`: 112
- `line_count`: 1
- `sha256`: 6c02605505b2423d2ed22165d8add22de80669a1fd3044f06c09f292424aa6a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=112 bytes; lines=1; PASS=2; tail=[T3K-FOCUSED-STA] PASS: expect=fresh report_paths=80 pending(legacy/head/state/illegal/probe)=0/133/133/133/133

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 425
- `line_count`: 8
- `sha256`: c3101ed5c4bf3b3a647b8ab71302d7fbdebbc7d438422682b80045f40ca48b63
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=425 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=fresh period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3k-csr-probe-isolation/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 in...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 364
- `line_count`: 17
- `sha256`: 67e84cc6615cabb2469fb0e8ad4fa6c76e010bcf4d4216893199e31dac2d1abe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=364 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=21 legacy_csr_input_pins=21 probe_csr_input_pins=21 illegal_output_pins=1 state_priv_q_pins=1 state_mst...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 40688
- `line_count`: 643
- `sha256`: cd131cbef39794f653eff291c55a7380d05b65b7dcb3f4530954f2e6b642be44
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=40688 bytes; lines=643; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 101160
- `line_count`: 1307
- `sha256`: a87d68217fddefc5e378607e82de4929c407ae1fda30a9ca3407f8af8d811d1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=101160 bytes; lines=1307; markers=<none>; tail=_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/head_inst0_i_19_ source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/head_inst0_i_20_ source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/head_inst0...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 146380
- `line_count`: 1760
- `sha256`: 6619768707832e0e75f02ed6fb1a99503f4a6c959a68cdbe5f1026bceba64512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=146380 bytes; lines=1760; markers=<none>; tail=Time Description ----------------------------------------------------------- 0.000 0.000 clock core_clock (rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/_7454_/CK (DFFQX1H7L) 0.082 0.082 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-illegal-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 12470
- `line_count`: 137
- `sha256`: 953bc94df78e196df9f6a76727175e1b00ad6c18b592fc16634d0e3c149941fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=12470 bytes; lines=137; markers=<none>; tail=source_count=1 source_object=u_core/u_csr_file/csr_illegal_o target_count=133 intersection_count=133 intersection_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D intersection_object=u_core/u_ooo_core/u_control_plane/u_pending...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 146380
- `line_count`: 1760
- `sha256`: 6619768707832e0e75f02ed6fb1a99503f4a6c959a68cdbe5f1026bceba64512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=146380 bytes; lines=1760; markers=<none>; tail=Time Description ----------------------------------------------------------- 0.000 0.000 clock core_clock (rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/_7454_/CK (DFFQX1H7L) 0.082 0.082 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 1041
- `line_count`: 24
- `sha256`: cb4c62757c571d69f9871aec0e737965c5b4a4dba345e3dccdcbd1c535ed6184
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=1041 bytes; lines=24; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 52
- `line_count`: 1
- `sha256`: 899fe0c58b9155457f2fd043b9e36f9361a610625ec55d0da173d9b2e8e388d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=52 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=133

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13538
- `line_count`: 157
- `sha256`: 99f6afc633344641638bf4c1ba5d72f1cb8efd308daa4dd9498238419677fdab
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13538 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_probe_valid_i source_object=u_core/u_csr_file/csr_probe_addr_i_0_ source_object=u_core/u_csr_file/csr_probe_addr_i_1_ source_object=u_core/u_csr_file/csr_probe_addr_i_2_ source_object=u_core/u_csr_file/csr...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 146380
- `line_count`: 1760
- `sha256`: 6619768707832e0e75f02ed6fb1a99503f4a6c959a68cdbe5f1026bceba64512
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=146380 bytes; lines=1760; markers=<none>; tail=Time Description ----------------------------------------------------------- 0.000 0.000 clock core_clock (rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_packet_fifo/_7454_/CK (DFFQX1H7L) 0.082 0.082 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: e85728eadddf1e32f578ef5d38c22d5f0537984e142f67039767c4a4de1953cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_15480_/Q source_object=u_core/u_csr_file/_15087_/Q source_object=u_core/u_csr_file/_15088_/Q source_object=u_core/u_csr_file/_15089_/Q source_object=u_core/u_csr_file/_15090_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-fresh-t3k-root-final-v6/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 177580
- `line_count`: 1800
- `sha256`: 15ebec566a61200b4edc3528b4453f85af98a553c0cdbc35b7121e1dbed531bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=177580 bytes; lines=1800; markers=<none>; tail=ore/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20230_/Y (BUFX1P4H7L) 0.097 3.565 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20292_/Y (NOR4BBX0P5H7L...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/checker.log

- `kind`: log
- `size_bytes`: 8570
- `line_count`: 1
- `sha256`: dd605852f9284ad8c7b1ca4aa56594d9c399fc733b6d3289da9de5d7c521b01e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=8570 bytes; lines=1; FAIL=2; tail=[T3K-FOCUSED-STA] FAIL: query selector/status mismatch commit_to_illegal: {'source_object': ['u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_valid_i', 'u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_exceptio...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 8
- `sha256`: 99f09a8b3d03ed0a48a66f792b9223e8a262dd67218badcb27e089cbeca0d375
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=421 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a input_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 362
- `line_count`: 17
- `sha256`: 2bb8c5e0a19cc7dc44ad29ae47b2171fbc9c9193d42d7610e11856cbfb7d67f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=362 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=0 legacy_csr_input_pins=21 probe_csr_input_pins=0 illegal_output_pins=1 state_priv_q_pins=1 state_mstat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 38187
- `line_count`: 601
- `sha256`: 1ca0f03c1a953efe772f7f04c5349b338f48d772e22e29fd1dfaec7fccdf739c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=38187 bytes; lines=601; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 87307
- `line_count`: 1131
- `sha256`: e17c8fbfc1a3e98acbcbe73ffa40bd7d0781fd9f7c63600aab1a196397aba2c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=87307 bytes; lines=1131; markers=<none>; tail=t=133 target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0871_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 158840
- `line_count`: 1860
- `sha256`: 9a7f76e09ac8cfe90eff6e5f75de23c3b4c436b5e95782d3bad17345fbb1dfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=158840 bytes; lines=1860; markers=<none>; tail=oo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_080_/Y (BUFX1P4H7L) 0.105 4.715 ^ u_core/u_ooo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_081_/Y (BUFX7H7L) 0.063 4.778 ^ u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13412
- `line_count`: 157
- `sha256`: db9ec3f717002ab03b7e8c2c89df4676615bc41605f56dc1108e11d3e026aaaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13412 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 72
- `line_count`: 4
- `sha256`: 164080b657c21c3e695477dbbbedd70edb9c9788d585625a09d3b7c0466b473d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=72 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=133 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: da6794e7fc126b80c04e04f91e4cbcc7219d64f9b96dfc1894eda9d462f8782c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v2/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 203580
- `line_count`: 2100
- `sha256`: b5d62380761c2e6ffb4234b1dca78435f5ffa7abe9c519ba3029216efa812bba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203580 bytes; lines=2100; markers=<none>; tail=tch_backend/u_rob/_20231_/Y (XOR2X0P5H7L) 0.102 3.643 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20234_/Y (NOR4X0P5H7L) 0.069 3.712 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/checker.log

- `kind`: log
- `size_bytes`: 161
- `line_count`: 1
- `sha256`: 7ac72a55a6123abce74301b59ad7ff1c87aea566d5a8d043ed37df50a7731aca
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=161 bytes; lines=1; PASS=2; tail=[T3K-FOCUSED-STA] PASS: expect=old report_paths=120 commit_pending=133 pending_pending=133 legacy_pending=133 head_pending=133 state_pending=133 probe_pending=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-commit-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 21781
- `line_count`: 234
- `sha256`: 01c5d0dc25e17df705fe061da3e4757e8f60201469f62169d5747cf915161b37
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=21781 bytes; lines=234; markers=<none>; tail=source_count=98 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_exception_i source_object=u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-commit_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 8
- `sha256`: 91d27f36e1c4b65db6ca80e73b90f11353f3427d823841532bf087b8dbf305f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=421 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a input_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 362
- `line_count`: 17
- `sha256`: 2bb8c5e0a19cc7dc44ad29ae47b2171fbc9c9193d42d7610e11856cbfb7d67f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=362 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=0 legacy_csr_input_pins=21 probe_csr_input_pins=0 illegal_output_pins=1 state_priv_q_pins=1 state_mstat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 38187
- `line_count`: 601
- `sha256`: 1ca0f03c1a953efe772f7f04c5349b338f48d772e22e29fd1dfaec7fccdf739c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=38187 bytes; lines=601; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 129818
- `line_count`: 1609
- `sha256`: 7d2f010e2fca2e25ff10bcaf8a2d0a17d06000d9439ca8e165f2cc4ce570f1ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=129818 bytes; lines=1609; markers=<none>; tail=t=133 target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0871_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 158840
- `line_count`: 1860
- `sha256`: 9a7f76e09ac8cfe90eff6e5f75de23c3b4c436b5e95782d3bad17345fbb1dfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=158840 bytes; lines=1860; markers=<none>; tail=oo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_080_/Y (BUFX1P4H7L) 0.105 4.715 ^ u_core/u_ooo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_081_/Y (BUFX7H7L) 0.063 4.778 ^ u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13412
- `line_count`: 157
- `sha256`: db9ec3f717002ab03b7e8c2c89df4676615bc41605f56dc1108e11d3e026aaaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13412 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-pending-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 22164
- `line_count`: 236
- `sha256`: 4e1f391b0853f53ccda9d8f684ed0c4aa521aac9e46c170ec4408f32eb8455a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=22164 bytes; lines=236; markers=<none>; tail=source_count=100 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_csr_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_ac...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-pending_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 88000
- `line_count`: 1180
- `sha256`: 144aa07705c0f5ef7de1e419c136cd53dc3bedde5c20319c2f0cb59b9f9469a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=88000 bytes; lines=1180; markers=<none>; tail=rise edge) 0.000 0.000 clock network delay (ideal) 0.000 0.000 ^ u_core/u_ooo_core/u_control_plane/u_pending_system_sequencer/_2259_/CK (DFFQX1H7L) 0.160 0.160 ^ u_core/u_ooo_core/u_control_plane/u_pending_system_sequencer/_2259_/Q (DFFQX1H7L) 0.131 0.291 ^...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 72
- `line_count`: 4
- `sha256`: 164080b657c21c3e695477dbbbedd70edb9c9788d585625a09d3b7c0466b473d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=72 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=133 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: da6794e7fc126b80c04e04f91e4cbcc7219d64f9b96dfc1894eda9d462f8782c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v3/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 203580
- `line_count`: 2100
- `sha256`: b5d62380761c2e6ffb4234b1dca78435f5ffa7abe9c519ba3029216efa812bba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203580 bytes; lines=2100; markers=<none>; tail=tch_backend/u_rob/_20231_/Y (XOR2X0P5H7L) 0.102 3.643 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20234_/Y (NOR4X0P5H7L) 0.069 3.712 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/checker.log

- `kind`: log
- `size_bytes`: 116
- `line_count`: 1
- `sha256`: 0b6a5df86574b1ffdc1a5e361ab31b8a7eb9fe6ece4c4aa4275d17e54ea7d729
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=116 bytes; lines=1; FAIL=2; tail=[T3K-FOCUSED-STA] FAIL: intersection count mismatch opensta-t3k-commit-illegal-intersection.txt: count=0 expected=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-commit-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 9408
- `line_count`: 101
- `sha256`: 54e9572f21554f2348b1d6846b550064160f34656f90b1b01952bca3b1134473
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=9408 bytes; lines=101; markers=<none>; tail=source_count=98 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_exception_i source_object=u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 8
- `sha256`: e57f7c1c705e1017127dae43ebd3fd636f07cbf03c8d589be9397334f46c627f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=421 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a input_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 362
- `line_count`: 17
- `sha256`: 2bb8c5e0a19cc7dc44ad29ae47b2171fbc9c9193d42d7610e11856cbfb7d67f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=362 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=0 legacy_csr_input_pins=21 probe_csr_input_pins=0 illegal_output_pins=1 state_priv_q_pins=1 state_mstat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 38187
- `line_count`: 601
- `sha256`: 1ca0f03c1a953efe772f7f04c5349b338f48d772e22e29fd1dfaec7fccdf739c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=38187 bytes; lines=601; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 87307
- `line_count`: 1131
- `sha256`: e17c8fbfc1a3e98acbcbe73ffa40bd7d0781fd9f7c63600aab1a196397aba2c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=87307 bytes; lines=1131; markers=<none>; tail=t=133 target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0871_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-head-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 6245
- `line_count`: 72
- `sha256`: 7cf02611c5839c0b58c8153850d469328dc2e6c1b1c48c75e66954ae3127bbc6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=6245 bytes; lines=72; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 158840
- `line_count`: 1860
- `sha256`: 9a7f76e09ac8cfe90eff6e5f75de23c3b4c436b5e95782d3bad17345fbb1dfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=158840 bytes; lines=1860; markers=<none>; tail=oo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_080_/Y (BUFX1P4H7L) 0.105 4.715 ^ u_core/u_ooo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_081_/Y (BUFX7H7L) 0.063 4.778 ^ u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-illegal-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 12470
- `line_count`: 137
- `sha256`: 953bc94df78e196df9f6a76727175e1b00ad6c18b592fc16634d0e3c149941fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=12470 bytes; lines=137; markers=<none>; tail=source_count=1 source_object=u_core/u_csr_file/csr_illegal_o target_count=133 intersection_count=133 intersection_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D intersection_object=u_core/u_ooo_core/u_control_plane/u_pending...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-legacy-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 1039
- `line_count`: 24
- `sha256`: ca46c75b6200ae1dcb0ede6cc8a8fd04a2f157970c59f7a4d749f8a51671d601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=1039 bytes; lines=24; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13412
- `line_count`: 157
- `sha256`: db9ec3f717002ab03b7e8c2c89df4676615bc41605f56dc1108e11d3e026aaaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13412 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-pending-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 9791
- `line_count`: 103
- `sha256`: c854ae32e83c483741057106e118fbe9f631c4a75ce5767aca06b470e57111c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=9791 bytes; lines=103; markers=<none>; tail=source_count=100 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_csr_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_ac...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-probe-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 70
- `line_count`: 4
- `sha256`: 0420a639d886c3863aa5fb918095d7dce61868555be7a55053d79f327819af90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=70 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=1 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 72
- `line_count`: 4
- `sha256`: 164080b657c21c3e695477dbbbedd70edb9c9788d585625a09d3b7c0466b473d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=72 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=133 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-state-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 2950
- `line_count`: 72
- `sha256`: 125d7846bf1fa1312df67decd6ecb35af7fb3e799ca06a51385384395ae8ec2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=2950 bytes; lines=72; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: da6794e7fc126b80c04e04f91e4cbcc7219d64f9b96dfc1894eda9d462f8782c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v4/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 203580
- `line_count`: 2100
- `sha256`: b5d62380761c2e6ffb4234b1dca78435f5ffa7abe9c519ba3029216efa812bba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203580 bytes; lines=2100; markers=<none>; tail=tch_backend/u_rob/_20231_/Y (XOR2X0P5H7L) 0.102 3.643 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20234_/Y (NOR4X0P5H7L) 0.069 3.712 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/checker.log

- `kind`: log
- `size_bytes`: 116
- `line_count`: 1
- `sha256`: 0b6a5df86574b1ffdc1a5e361ab31b8a7eb9fe6ece4c4aa4275d17e54ea7d729
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=116 bytes; lines=1; FAIL=2; tail=[T3K-FOCUSED-STA] FAIL: intersection count mismatch opensta-t3k-commit-illegal-intersection.txt: count=0 expected=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-commit-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 9408
- `line_count`: 101
- `sha256`: 54e9572f21554f2348b1d6846b550064160f34656f90b1b01952bca3b1134473
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=9408 bytes; lines=101; markers=<none>; tail=source_count=98 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/core_commit0_exception_i source_object=u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 8
- `sha256`: 2cf9d41e2046a313226bc9c1ecc15a3caf07d18e84ca58f8dff7d5f5b8d125c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=421 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a input_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 362
- `line_count`: 17
- `sha256`: 2bb8c5e0a19cc7dc44ad29ae47b2171fbc9c9193d42d7610e11856cbfb7d67f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=362 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=0 legacy_csr_input_pins=21 probe_csr_input_pins=0 illegal_output_pins=1 state_priv_q_pins=1 state_mstat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 38187
- `line_count`: 601
- `sha256`: 1ca0f03c1a953efe772f7f04c5349b338f48d772e22e29fd1dfaec7fccdf739c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=38187 bytes; lines=601; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 87307
- `line_count`: 1131
- `sha256`: e17c8fbfc1a3e98acbcbe73ffa40bd7d0781fd9f7c63600aab1a196397aba2c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=87307 bytes; lines=1131; markers=<none>; tail=t=133 target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0871_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-head-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 6245
- `line_count`: 72
- `sha256`: 7cf02611c5839c0b58c8153850d469328dc2e6c1b1c48c75e66954ae3127bbc6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=6245 bytes; lines=72; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 158840
- `line_count`: 1860
- `sha256`: 9a7f76e09ac8cfe90eff6e5f75de23c3b4c436b5e95782d3bad17345fbb1dfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=158840 bytes; lines=1860; markers=<none>; tail=oo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_080_/Y (BUFX1P4H7L) 0.105 4.715 ^ u_core/u_ooo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_081_/Y (BUFX7H7L) 0.063 4.778 ^ u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-illegal-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 12470
- `line_count`: 137
- `sha256`: 953bc94df78e196df9f6a76727175e1b00ad6c18b592fc16634d0e3c149941fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=12470 bytes; lines=137; markers=<none>; tail=source_count=1 source_object=u_core/u_csr_file/csr_illegal_o target_count=133 intersection_count=133 intersection_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D intersection_object=u_core/u_ooo_core/u_control_plane/u_pending...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-legacy-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 1039
- `line_count`: 24
- `sha256`: ca46c75b6200ae1dcb0ede6cc8a8fd04a2f157970c59f7a4d749f8a51671d601
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=1039 bytes; lines=24; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13412
- `line_count`: 157
- `sha256`: db9ec3f717002ab03b7e8c2c89df4676615bc41605f56dc1108e11d3e026aaaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13412 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-pending-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 9791
- `line_count`: 103
- `sha256`: c854ae32e83c483741057106e118fbe9f631c4a75ce5767aca06b470e57111c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=9791 bytes; lines=103; markers=<none>; tail=source_count=100 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/pending_system_csr_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_ac...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-probe-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 70
- `line_count`: 4
- `sha256`: 0420a639d886c3863aa5fb918095d7dce61868555be7a55053d79f327819af90
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=70 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=1 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 72
- `line_count`: 4
- `sha256`: 164080b657c21c3e695477dbbbedd70edb9c9788d585625a09d3b7c0466b473d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=72 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=133 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-state-illegal-intersection.txt

- `kind`: txt
- `size_bytes`: 3767
- `line_count`: 89
- `sha256`: b4f458abeb0d627b3450331eb5a3a9195c41936249f9b79cfef03fd56f04444e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=3767 bytes; lines=89; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: da6794e7fc126b80c04e04f91e4cbcc7219d64f9b96dfc1894eda9d462f8782c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v5/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 203580
- `line_count`: 2100
- `sha256`: b5d62380761c2e6ffb4234b1dca78435f5ffa7abe9c519ba3029216efa812bba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203580 bytes; lines=2100; markers=<none>; tail=tch_backend/u_rob/_20231_/Y (XOR2X0P5H7L) 0.102 3.643 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20234_/Y (NOR4X0P5H7L) 0.069 3.712 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/checker.log

- `kind`: log
- `size_bytes`: 110
- `line_count`: 1
- `sha256`: a57c6f154538431b084b6afa80de3c61a3d1474da9a35e029f3dbbb09db8c098
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=110 bytes; lines=1; PASS=2; tail=[T3K-FOCUSED-STA] PASS: expect=old report_paths=80 pending(legacy/head/state/illegal/probe)=133/133/133/133/0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: b2dd4b8661612ce2c2ce29e3a87e7a834822b63aa443125e51af77d9123fd776
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=98 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 8
- `sha256`: 8c372b1c0130d408e1c6dc1aa7bbe68874864857634878cd1f3875462818d54d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=421 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a input_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 362
- `line_count`: 17
- `sha256`: 2bb8c5e0a19cc7dc44ad29ae47b2171fbc9c9193d42d7610e11856cbfb7d67f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=362 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=98 pending_source_pins=100 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=0 legacy_csr_input_pins=21 probe_csr_input_pins=0 illegal_output_pins=1 state_priv_q_pins=1 state_mstat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 38187
- `line_count`: 601
- `sha256`: 1ca0f03c1a953efe772f7f04c5349b338f48d772e22e29fd1dfaec7fccdf739c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=38187 bytes; lines=601; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=98 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 87307
- `line_count`: 1131
- `sha256`: e17c8fbfc1a3e98acbcbe73ffa40bd7d0781fd9f7c63600aab1a196397aba2c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=87307 bytes; lines=1131; markers=<none>; tail=t=133 target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0871_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 158840
- `line_count`: 1860
- `sha256`: 9a7f76e09ac8cfe90eff6e5f75de23c3b4c436b5e95782d3bad17345fbb1dfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=158840 bytes; lines=1860; markers=<none>; tail=oo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_080_/Y (BUFX1P4H7L) 0.105 4.715 ^ u_core/u_ooo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_081_/Y (BUFX7H7L) 0.063 4.778 ^ u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-illegal-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 12470
- `line_count`: 137
- `sha256`: 953bc94df78e196df9f6a76727175e1b00ad6c18b592fc16634d0e3c149941fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=12470 bytes; lines=137; markers=<none>; tail=source_count=1 source_object=u_core/u_csr_file/csr_illegal_o target_count=133 intersection_count=133 intersection_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D intersection_object=u_core/u_ooo_core/u_control_plane/u_pending...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13412
- `line_count`: 157
- `sha256`: db9ec3f717002ab03b7e8c2c89df4676615bc41605f56dc1108e11d3e026aaaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13412 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: 05265610f5e76df08fe302d25636473e77a54c2b621ad9bf7a3ffa8da9b15fa0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=100 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 72
- `line_count`: 4
- `sha256`: 164080b657c21c3e695477dbbbedd70edb9c9788d585625a09d3b7c0466b473d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=72 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=133 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: da6794e7fc126b80c04e04f91e4cbcc7219d64f9b96dfc1894eda9d462f8782c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final-v6/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 203580
- `line_count`: 2100
- `sha256`: b5d62380761c2e6ffb4234b1dca78435f5ffa7abe9c519ba3029216efa812bba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203580 bytes; lines=2100; markers=<none>; tail=tch_backend/u_rob/_20231_/Y (XOR2X0P5H7L) 0.102 3.643 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20234_/Y (NOR4X0P5H7L) 0.069 3.712 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/checker.log

- `kind`: log
- `size_bytes`: 83
- `line_count`: 1
- `sha256`: ff0dcdfd3d3bd36c1a5167be78523f5042c02d8bb2ceced48de5eb10a569ff01
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"FAIL": 2}
- `summary`: log evidence; size=83 bytes; lines=1; FAIL=2; tail=[T3K-FOCUSED-STA] FAIL: focused object count mismatch commit_source_pins: 99 != 98

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-commit_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: cee5415bbd46ec74fe262fa9eead50bc4290766b0f343235c5a23dd99034316f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=99 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-focused-complete.txt

- `kind`: txt
- `size_bytes`: 421
- `line_count`: 8
- `sha256`: 5ff252ea30cf1a758409ea28e5d5e35830d8e8e7a6310287ad190496aa47e083
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=421 bytes; lines=8; markers=<none>; tail=status=COMPLETE expect=old period_ns=5.0 top=NpcTop netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a input_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-focused-counts.txt

- `kind`: txt
- `size_bytes`: 362
- `line_count`: 17
- `sha256`: daf70423020babfcf66abef0ce8493a0234fedf268fdd4b030aa330673262152
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=362 bytes; lines=17; markers=<none>; tail=mux_cells=1 csr_cells=1 pending_cells=1 commit_source_pins=99 pending_source_pins=103 head_source_pins=69 legacy_mux_output_pins=21 probe_mux_output_pins=0 legacy_csr_input_pins=21 probe_csr_input_pins=0 illegal_output_pins=1 state_priv_q_pins=1 state_mstat...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-focused-objects.txt

- `kind`: txt
- `size_bytes`: 38536
- `line_count`: 605
- `sha256`: 20b857c09941e141edd8871d13beefa8fea7dbf922a63805d4322b66fb15651f
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=38536 bytes; lines=605; markers=<none>; tail=[mux_cells] count=1 u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux [csr_cells] count=1 u_core/u_csr_file [pending_cells] count=1 u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer [commit_source_pins] count=99 u_core/u_ooo_core/u_co...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-focused-queries.txt

- `kind`: txt
- `size_bytes`: 87712
- `line_count`: 1135
- `sha256`: 7b5fe7d3ab74e690373d79d395c87e3d3dfe862c25e6ba69e4bca964b5e6460c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=87712 bytes; lines=1135; markers=<none>; tail=t=133 target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0870_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer/_0871_/D target_object=u_core/u_ooo_core/u_control_plane/u_pending_trap_exit_sequencer...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-head-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 18618
- `line_count`: 205
- `sha256`: f53148caa5c5114411f0a56aadd3dbb4750c5e7ad17410bfe8a68535af55ce1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=18618 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch_valid_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/dispatch0_system_i source_object=u_core/u_ooo_core/u_control_plane/u_csr_acces...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-head_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-head_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 158840
- `line_count`: 1860
- `sha256`: 9a7f76e09ac8cfe90eff6e5f75de23c3b4c436b5e95782d3bad17345fbb1dfa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=158840 bytes; lines=1860; markers=<none>; tail=oo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_080_/Y (BUFX1P4H7L) 0.105 4.715 ^ u_core/u_ooo_core/u_control_plane/u_pending_dispatch_arbiter/u_lane1_capture_gate/_081_/Y (BUFX7H7L) 0.063 4.778 ^ u_core/u_ooo_core/u_control_plane/u...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-illegal_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-legacy-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 13412
- `line_count`: 157
- `sha256`: db9ec3f717002ab03b7e8c2c89df4676615bc41605f56dc1108e11d3e026aaaf
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=13412 bytes; lines=157; markers=<none>; tail=source_count=21 source_object=u_core/u_csr_file/csr_valid_i source_object=u_core/u_csr_file/csr_addr_i_0_ source_object=u_core/u_csr_file/csr_addr_i_1_ source_object=u_core/u_csr_file/csr_addr_i_2_ source_object=u_core/u_csr_file/csr_addr_i_3_ source_object...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-legacy_access_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 1b8976f3dfa50bf8c55c9f2c78fb94f131e9dfa6ee3700d380f8168c796eb4b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=21 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-legacy_access_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 412680
- `line_count`: 3620
- `sha256`: 47135e768ab7cf66c6a225e1225a5a8f67583b8c69d8c5f2985970c39b58dd4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=412680 bytes; lines=3620; markers=<none>; tail=ntrol_plane/u_csr_access_request_mux/_3828_/Y (NAND2BX0P5H7L) 0.119 11.643 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3832_/Y (OR4X1P4H7L) 0.057 11.700 v u_core/u_ooo_core/u_control_plane/u_csr_access_request_mux/_3833_/Y (BUFX7H7L) 0.077...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-pending_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 51
- `line_count`: 1
- `sha256`: c7116c9385bfa83ea21e2c3b9fbbca766d2ee454862d3ebecdf4792b32e6a5ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=51 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=103 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-probe-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 72
- `line_count`: 4
- `sha256`: 164080b657c21c3e695477dbbbedd70edb9c9788d585625a09d3b7c0466b473d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=72 bytes; lines=4; markers=<none>; tail=status=PORT_ABSENT source_count=0 target_count=133 intersection_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-probe_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-probe_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 34
- `line_count`: 1
- `sha256`: f18e77e336ab184ba8348581753394c95949b7bedf60aa60457696e3766714f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=34 bytes; lines=1; markers=<none>; tail=status=PORT_ABSENT source_count=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-state-pending-intersection.txt

- `kind`: txt
- `size_bytes`: 15323
- `line_count`: 205
- `sha256`: da6794e7fc126b80c04e04f91e4cbcc7219d64f9b96dfc1894eda9d462f8782c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=15323 bytes; lines=205; markers=<none>; tail=source_count=69 source_object=u_core/u_csr_file/_14998_/Q source_object=u_core/u_csr_file/_14731_/Q source_object=u_core/u_csr_file/_14732_/Q source_object=u_core/u_csr_file/_14733_/Q source_object=u_core/u_csr_file/_14734_/Q source_object=u_core/u_csr_file...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-state_to_illegal.rpt

- `kind`: rpt
- `size_bytes`: 50
- `line_count`: 1
- `sha256`: 98e745e078f4483dd859dad73ce8b6952e1fa51506be34b45c750bc82ed20688
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=50 bytes; lines=1; markers=<none>; tail=status=NO_TIMING_PATH through_count=69 to_count=1

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-focused-old-t3j-root-final/opensta-t3k-state_to_pending.rpt

- `kind`: rpt
- `size_bytes`: 203580
- `line_count`: 2100
- `sha256`: b5d62380761c2e6ffb4234b1dca78435f5ffa7abe9c519ba3029216efa812bba
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=203580 bytes; lines=2100; markers=<none>; tail=tch_backend/u_rob/_20231_/Y (XOR2X0P5H7L) 0.102 3.643 ^ u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_dispatch_backend/u_rob/_20234_/Y (NOR4X0P5H7L) 0.069 3.712 v u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v2/opensta-inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: 6678d5280c8f103a190ce680e5f6cd29690b022821e8a496065b2968ad6ca2e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v2/opensta-parameters.pre.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v2/opensta-tool-version.pre.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v3/opensta-inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: c18dc87bfc34e0336ac6ad1c83e71473299c72594551eee65942cb72524effcd
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v3/opensta-parameters.pre.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v3/opensta-tool-version.pre.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v4/opensta-inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: b776fb873658812679893e872a862024e3b43204784e6b3ee9e84336958848d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v4/opensta-parameters.pre.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v4/opensta-tool-version.pre.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v5/opensta-inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: 00f57ffd6f3df38562ebabaf73c7b0a1ccadd9dc892b1b65f05bd16ab806d613
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v5/opensta-parameters.pre.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v5/opensta-tool-version.pre.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-freeze-status.txt

- `kind`: txt
- `size_bytes`: 46
- `line_count`: 3
- `sha256`: c1edfadd29913f2aef8fd71dbe3bd84ac399eabcc0c440b415774438b3d09e3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 6}
- `summary`: txt evidence; size=46 bytes; lines=3; PASS=6; tail=inputs=PASS parameters=PASS tool_version=PASS

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-inputs.post.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: d676e13724ace9e8a55dcda7f32df39e2ce862ca91b24ebdeeeddfcdcda0c4a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: d676e13724ace9e8a55dcda7f32df39e2ce862ca91b24ebdeeeddfcdcda0c4a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-parameters.post.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-parameters.pre.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-tool-version.post.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final-v6/opensta-tool-version.pre.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final/opensta-inputs.pre.sha256

- `kind`: sha256
- `size_bytes`: 2479
- `line_count`: 15
- `sha256`: 414fb7b1e29f37bc508dd8a349e0dd71645e420023a2b49f2f086d7a6c004c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: sha256 evidence; size=2479 bytes; lines=15; markers=<none>; tail=e5ae3b3749af62e6d6f3a51eb70a4472c65ee614b947a113adf72bf3d8b8349a /home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v 0161d3d41300cd41a80f4da3cd649cc8defb98548c23eb324efc140fec583b32 /home/lyg/PA/ysy...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final/opensta-parameters.pre.kv

- `kind`: kv
- `size_bytes`: 875
- `line_count`: 12
- `sha256`: a3be5646e97ed858509e1845c69b30b4ac667360e944604127b8984210f790f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=875 bytes; lines=12; markers=<none>; tail=period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock old_expect=old fresh_expect=fresh target_expect=miss old_netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3j-fetch-read-window/sta-build/NpcTop-200MHz/NpcTop.netlist.v fresh_netlist=/home...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-freeze-root-final/opensta-tool-version.pre.kv

- `kind`: kv
- `size_bytes`: 14
- `line_count`: 1
- `sha256`: 6e1524f6ec325abc564534150c3d313e1520587ce945872281ca93b464a01c05
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: kv evidence; size=14 bytes; lines=1; markers=<none>; tail=opensta=3.1.0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-provisional-global-root/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 95684
- `line_count`: 4030
- `sha256`: 9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=95684 bytes; lines=4030; markers=<none>; tail=_32_ psram_axi_araddr_o_33_ psram_axi_araddr_o_34_ psram_axi_araddr_o_35_ psram_axi_araddr_o_36_ psram_axi_araddr_o_37_ psram_axi_araddr_o_38_ psram_axi_araddr_o_39_ psram_axi_araddr_o_3_ psram_axi_araddr_o_40_ psram_axi_araddr_o_41_ psram_axi_araddr_o_42_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-provisional-global-root/opensta-current-complete.txt

- `kind`: txt
- `size_bytes`: 738
- `line_count`: 14
- `sha256`: d657a24153c0709f3601dadab2700be8b8a12489676146aabf095e2554193d96
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=738 bytes; lines=14; markers=<none>; tail=status=COMPLETE period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3k-csr-probe-isolation/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=0161d3d41300cd41a80f4da3cd649cc8defb98548c2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-provisional-global-root/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: a585bed87e23ea48730a6500d4c06ce97724d29e218bff6b4f19bb23a3c837a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.53e-02 9.24e-05 1.81e-04 9.55e-02 81.7% Combinational 5.89e-03 7.22e-03 4.65e-04 1.36e-02 11.6% Clock 2.80e-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-provisional-global-root/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 325963
- `line_count`: 4373
- `sha256`: e4990ef27d3cff9101c568609e001ae3495ba96eed6cb46bc2f0b7bfc5ccf142
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=325963 bytes; lines=4373; markers=<none>; tail=(rise edge) 0.000 5.000 clock network delay (ideal) 0.000 5.000 clock reconvergence pessimism 5.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/_4165_/CK (DFFQX1H7L) -0.028 4.972 library setup time 4.972 data required time ------------------------...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/checker.log

- `kind`: log
- `size_bytes`: 100
- `line_count`: 1
- `sha256`: c26fb6d0543c25879d8bdcf2dbe541b62bb13de4993eb052693e9cd3360c7f0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=100 bytes; lines=1; PASS=2; tail=[T3K-GLOBAL-STA] PASS: loops=0 paths=40 WNS=-8.720ns TNS=-199154.36ns power=0.117W target_met=False

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/opensta-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 95684
- `line_count`: 4030
- `sha256`: 9dfdcc9ede24b064e1cce61a03d3754370fa163e77293fa5828f8b66b540785d
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=95684 bytes; lines=4030; markers=<none>; tail=_32_ psram_axi_araddr_o_33_ psram_axi_araddr_o_34_ psram_axi_araddr_o_35_ psram_axi_araddr_o_36_ psram_axi_araddr_o_37_ psram_axi_araddr_o_38_ psram_axi_araddr_o_39_ psram_axi_araddr_o_3_ psram_axi_araddr_o_40_ psram_axi_araddr_o_41_ psram_axi_araddr_o_42_...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/opensta-current-complete.txt

- `kind`: txt
- `size_bytes`: 844
- `line_count`: 14
- `sha256`: de03a157741a2ae4703fb69121ccdaa53cdeef18e9f66bb0f59417d0957ab8d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=844 bytes; lines=14; markers=<none>; tail=status=COMPLETE period_ns=5.0 top=NpcTop clock_port=clk clock_name=core_clock netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-t3k-csr-probe-isolation/sta-build/NpcTop-200MHz/NpcTop.netlist.v netlist_sha256=0161d3d41300cd41a80f4da3cd649cc8defb98548c2...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: a585bed87e23ea48730a6500d4c06ce97724d29e218bff6b4f19bb23a3c837a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.53e-02 9.24e-05 1.81e-04 9.55e-02 81.7% Combinational 5.89e-03 7.22e-03 4.65e-04 1.36e-02 11.6% Clock 2.80e-...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 325963
- `line_count`: 4373
- `sha256`: e4990ef27d3cff9101c568609e001ae3495ba96eed6cb46bc2f0b7bfc5ccf142
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: rpt evidence; size=325963 bytes; lines=4373; markers=<none>; tail=(rise edge) 0.000 5.000 clock network delay (ideal) 0.000 5.000 clock reconvergence pessimism 5.000 ^ u_core/u_ooo_core/u_frontend/u_fetch_pc_outstanding/_4165_/CK (DFFQX1H7L) -0.028 4.972 library setup time 4.972 data required time ------------------------...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/summary.json

- `kind`: json
- `size_bytes`: 607
- `line_count`: 25
- `sha256`: 464149c413f96118cd500ff6f23cd909c889a2da5344febf2769b8c711e305a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: json evidence; size=607 bytes; lines=25; markers=<none>; tail={ "combinational_loops": 0, "commit_tokens_in_top40": 0, "csr_access_selector_tokens_in_top40": 0, "csr_probe_tokens_in_top40": 0, "endpoint_classes": { "csr_file": 0, "fetch_payload_sram": 0, "other": 40, "pending_trap_exit": 0 }, "path_count": 40, "pendin...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/opensta-fresh-t3k-root-final-v6/target-200mhz.log

- `kind`: log
- `size_bytes`: 61
- `line_count`: 1
- `sha256`: aad15db09b719e63d8d4980e2b978473fdcdcfa4bc699926d80b172aaf11142c
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=61 bytes; lines=1; PASS=2; tail=[T3K-200MHZ] PASS: expect=miss WNS=-8.720ns TNS=-199154.36ns

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/protected-inputs-status.txt

- `kind`: txt
- `size_bytes`: 618
- `line_count`: 8
- `sha256`: 8fe282fc29542a06521d89898cde083924f6c57bb9b63d7f19d168c335318ef4
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=618 bytes; lines=8; PASS=2; tail=status=PASS policy=pre-existing user changes preserved and excluded from T3K staging build/linux-logs/npc-linux.log=3d66ffa3564aa5f5171604af9b13eb22b3cad3df771d5b37be556064bea64d15 npc/rv64/vsrc/debug/OooAdUpdateChecker.sv=3863f022cddf2f72818a0fddfe424be930...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/superseded-evidence.md

- `kind`: md
- `size_bytes`: 2333
- `line_count`: 41
- `sha256`: dd9e309afcb9be0e385623f0a166f97c30811221ea87d906cf1feecc53bbfae3
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: md evidence; size=2333 bytes; lines=41; markers=<none>; tail=# T3K superseded evidence map Only the following results are canonical for delivery: - executable contract: `current-contract-root-final-v2/` - reviewer-repaired focused function: workspace `tmp/.../functional-evidence-fix-final-v2/result/` - final module r...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/synthesis/audit.json

- `kind`: json
- `size_bytes`: 1230
- `line_count`: 41
- `sha256`: 4e3fcd9ac95752bcf4a3d65b3dd935b28f79b7b0670fb42204fec4a48c7d0642
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: json evidence; size=1230 bytes; lines=41; markers=<none>; tail={ "abc_candidates": 220, "abc_done": 210, "abc_empty": 10, "abc_results": 210, "abc_sdc_driver": "BUFX0P5H7L", "abc_sdc_load": 1.6, "area": 1573200.16, "dynamic_libraries_frozen": false, "end_of_script": 1, "error_lines": 0, "evidence_freeze_inputs": 9, "ex...

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/synthesis/synth-exit-status.txt

- `kind`: txt
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {}
- `summary`: txt evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-13-rv64-t3k-csr-probe-isolation/evidence/synthesis/synth-input-hash-cmp.txt

- `kind`: txt
- `size_bytes`: 143
- `line_count`: 8
- `sha256`: c2fcf3d5c442bf5721171c4b4248f01caebd2975a0560cc141ba86428b3950b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-13T11:25:21+00:00
- `markers`: {"PASS": 16}
- `summary`: txt evidence; size=143 bytes; lines=8; PASS=16; tail=rtl_inputs=PASS vsrc_tree=PASS flow_inputs=PASS liberty_inputs=PASS evidence_inputs=PASS tool_binaries=PASS parameters=PASS tool_versions=PASS
