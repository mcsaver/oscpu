# Evidence Index

## 基本信息

- `task_id`: 2026-07-26-rv64-v9x-serialize-recovery-owner-birth
- `task_slug`: 
- `profile`: 
- `asset_count`: 727
- `total_size_bytes`: 214621251

## 证据资产

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/birth.log

- `kind`: log
- `size_bytes`: 354
- `line_count`: 4
- `sha256`: b43968b3fba60a1e31b9cfbb96a64e8ec24ff06b2f028e7fc718b90713a44119
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=354 bytes; lines=4; ERROR=2; tail=ERROR: npc/rv64/vsrc/control/OooStopPendingSequencer.v:126: [V9X-STOP-BIRTH-WITNESS] stop rose without accepted holder/queue-head birth @0 Time: 35000 Scope: tb_ooo_stop_pending_sequencer_assert_negative.dut FATAL: npc/rv64/vsrc/control/OooStopPendingSequen...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/exit-squash.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 4
- `sha256`: cc745d97adb38d69abd42e978668333aabcb3e312c99ddde615dd683103baa28
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=361 bytes; lines=4; ERROR=2; tail=ERROR: npc/rv64/vsrc/control/OooPendingTrapExitSequencer.v:139: [V9X-EXIT-SQUASH-COLLISION] squash/capture 同拍后 wrong-path exit 复活: valid=1 ecall=1 ebreak=0 @35 Time: 35 Scope: tb_ooo_pending_trap_exit_sequencer.dut FATAL: npc/rv64/vsrc/control/OooPendingTra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/lease.log

- `kind`: log
- `size_bytes`: 340
- `line_count`: 4
- `sha256`: a7c210e49af9a5af77b271b6e89f10691bf0491df024ff6d33ef05d51f5da795
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=340 bytes; lines=4; ERROR=2; tail=ERROR: npc/rv64/vsrc/control/OooStopPendingSequencer.v:131: [V9X-STOP-LEASE-HOLD] exact pending CSR lease lost stop owner @0 Time: 25000 Scope: tb_ooo_stop_pending_sequencer_assert_negative.dut FATAL: npc/rv64/vsrc/control/OooStopPendingSequencer.v:133: Tim...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/live.log

- `kind`: log
- `size_bytes`: 351
- `line_count`: 4
- `sha256`: fa9485bf7bb1c549e96ee61b1c57f812c746cdb0bab1629105a7c7cc586124a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=351 bytes; lines=4; ERROR=2; tail=ERROR: npc/rv64/vsrc/control/OooStopPendingSequencer.v:145: [V9X-STOP-OWNER-LIVE] stop_pending has no registered serialization owner @0 Time: 35000 Scope: tb_ooo_stop_pending_sequencer_assert_negative.dut FATAL: npc/rv64/vsrc/control/OooStopPendingSequencer...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/qcsr.log

- `kind`: log
- `size_bytes`: 339
- `line_count`: 4
- `sha256`: 44cfa34b31cf93b3f9dccb9f0696501b0c6e2adcded71a672e743d495263882c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=339 bytes; lines=4; ERROR=2; tail=ERROR: npc/rv64/vsrc/control/OooStopPendingSequencer.v:137: [V9X-STOP-QCSR-HOLD] queue-head CSR inflight lost stop owner @0 Time: 25000 Scope: tb_ooo_stop_pending_sequencer_assert_negative.dut FATAL: npc/rv64/vsrc/control/OooStopPendingSequencer.v:139: Time...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/tb_ooo_pending_trap_exit_sequencer_assert_negative.vvp

- `kind`: vvp
- `size_bytes`: 28454
- `line_count`: 854
- `sha256`: 56fc3a8b24a1c6edccac7abc41588a25a3a047cf429dc1a520665e1b14c67e81
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: vvp evidence; size=28454 bytes; lines=854; FAIL=2; PASS=6; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/assert-negative/tb_ooo_stop_pending_sequencer_assert_negative.vvp

- `kind`: vvp
- `size_bytes`: 21117
- `line_count`: 586
- `sha256`: d3cba44a4da1dc37e8150205eb08f77d13c50e120e3b9d45587c95edf1a5537f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=21117 bytes; lines=586; markers=<none>; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/full-functional.log

- `kind`: log
- `size_bytes`: 12338
- `line_count`: 107
- `sha256`: 4be9e59d127077da4d2878c245659723a16080cd6cbf9a5aa3a53ffaec9e0bc0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 44}
- `summary`: log evidence; size=12338 bytes; lines=107; PASS=44; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [F0-G1] START npc-default-config: make -C <REPO>/npc/rv64 default_defconfig [F0-G1] PASS npc-default-config [F0-G1] START nemu-reference-build: make -C <REPO>/npc/rv64 difftest-ref [F0-G1] PASS...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 48967
- `line_count`: 1322
- `sha256`: ef39d5f38a1d6cba782f5bffd41f16f265ae54219e3061cc4dd195bb2ccfdd42
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48967 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 276271
- `line_count`: 7135
- `sha256`: fbed363e4650869ffcae6179df36746e71458b3a3335710b3fb6badbdf09a0b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=276271 bytes; lines=7135; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 219285
- `line_count`: 5754
- `sha256`: 462b5f2b8f0d493367a7f19e8d3aa87a1c2b056d8f8afb106a316d60d5c448c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=219285 bytes; lines=5754; FAIL=3; PASS=2; tail=, S_0x59466c5a85b0; %join; %free S_0x59466c5a85b0; %alloc S_0x59466c502550; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %p...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 905889
- `line_count`: 16698
- `sha256`: 1100af11abed9114b4fbaaacc398e5ab1b0ebf272d0920b7215fb73bc4cb2766
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=905889 bytes; lines=16698; markers=<none>; tail=ng_vec4 %pushi/vec4 1919513701, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544566893, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1634954099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 5...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_axi_reset_syscon.vvp

- `kind`: vvp
- `size_bytes`: 169874
- `line_count`: 4395
- `sha256`: c97aae039aa8dadc3d8448f26b56fad5b8828e4f73d13c47ec16dd9ad2a88938
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=169874 bytes; lines=4395; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 1751738216, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 541204578, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701015405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 151922
- `line_count`: 4004
- `sha256`: ccc5739ecfee89cc556c1b25312006ecdbb51254668664f36afbf62bba87a5e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=151922 bytes; lines=4004; FAIL=3; PASS=1; tail=, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x59770d2579e0_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x59770d257770_0, 0, 32; %pushi/vec4 2, 0, 3; %store/vec4 v0x59770d257910_0, 0, 3; %pushi/vec4 0, 0, 1; %store/vec4 v0x59770d258980_0, 0, 1; %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 314045
- `line_count`: 8462
- `sha256`: 4e74c14bf82c174fd2ccfe689ee03c273422279da3df6655422cdfe77d341d91
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=314045 bytes; lines=8462; FAIL=3; PASS=2; tail=g_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32438
- `line_count`: 864
- `sha256`: bd03c522f9227bc70e287fb5be6aa9dbc7c5fd5d7df29e1f7d1ab190e0a9b880
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32438 bytes; lines=864; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 581129
- `line_count`: 14244
- `sha256`: feec966ccb6b2c3d237f103c42a7b0b59269ba46cceb1bf5d7379de56529ce3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=581129 bytes; lines=14244; markers=<none>; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1702000233, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1936683552, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_csr_file_vectored_trap.vvp

- `kind`: vvp
- `size_bytes`: 355728
- `line_count`: 8239
- `sha256`: 2edf68e9fa40627a5285f8a2411b3d334c384f5f12b96b87aeff7dae420fc14c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=355728 bytes; lines=8239; FAIL=2; PASS=1; tail=%pushi/vec4 66, 0, 64; %store/vec4 v0x55dcb1f6f840_0, 0, 64; %fork TD_tb_csr_file_vectored_trap.check64, S_0x55dcb1f32b40; %join; %free S_0x55dcb1f32b40; %alloc S_0x55dcb20a7090; %fork TD_tb_csr_file_vectored_trap.reset_case, S_0x55dcb20a7090; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112262
- `line_count`: 3912
- `sha256`: da12187809458b0a272e1bd11b53af157af07f83bee00f4df1039ff8f80b0003
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112262 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x58a7998f5980_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x58a7998f5980_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274309
- `line_count`: 8084
- `sha256`: 93b336604bebc34ab8ec132f1d3a5202ad07114fc0205d5d88d4cff174c0cacd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274309 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32654
- `line_count`: 892
- `sha256`: 6f685bea58a60153a02c88b287e5c0cf611427dc51cd993621f75f057b23959b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32654 bytes; lines=892; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 37930
- `line_count`: 983
- `sha256`: 956bd6884b76bfdb3166baab37d045a916dcdcdd28904d48b8c02f0003047870
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=37930 bytes; lines=983; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40314
- `line_count`: 1057
- `sha256`: 9b5ceb42bbd3f2465d36c8ec3dcea4f16f326361da7caf3cc803e46736d80338
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40314 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28612
- `line_count`: 748
- `sha256`: b58b70e4821839b1059265f2403ccddb7cede1981f25bcc79011f2a052e6989a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28612 bytes; lines=748; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 3719560
- `line_count`: 86376
- `sha256`: 472e9cef0345524664204b57ebdd78a01462f75f3af66c78890a357988f1c4be
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3719560 bytes; lines=86376; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 3620243
- `line_count`: 84757
- `sha256`: 809a7b3c21fe5feb031f69daa88438e1225b07c87f1c623763dd306b91a258f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=3620243 bytes; lines=84757; FAIL=1; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 114, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1635197028, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701864814, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39372
- `line_count`: 1135
- `sha256`: 4cac994a0ba69bb59f1067eac4b0ff61eac0b1139f82b11aca44a38f3ecb0310
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39372 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30684
- `line_count`: 801
- `sha256`: be667672c41802f64a2fb83af4f27c3c4f331de5e7f6043ec83e7a80defe75c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30684 bytes; lines=801; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 108566
- `line_count`: 3346
- `sha256`: e9179399859bbb59399d34fa7011031afe06c5f242c9b3c4facd6900f4f3dc41
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108566 bytes; lines=3346; FAIL=5; PASS=1; tail=load/vec4 v0x62b55b9facb0_0; %concat/vec4; draw_concat_vec4 %sub; %ix/vec4 4; %shiftl 4; %or; %jmp/0 T_22.19, 8; ; End of false expr. %blend; T_22.19; %store/vec4 v0x62b55b9fc290_0, 0, 64; %jmp T_22.17; T_22.9 ; %load/vec4 v0x62b55b9facb0_0; %cmpi/e 0, 0, 6...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 36516
- `line_count`: 758
- `sha256`: 55eb3d2ed0c63d4bac1b004d538fe9a7e2dbbdf40ff3c6ad6aab27f59ec4cc6f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=36516 bytes; lines=758; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30029
- `line_count`: 663
- `sha256`: 1151ea62c61f1b11f2511304337df05005e586468c219be855829dd2ea7d33ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30029 bytes; lines=663; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138036
- `line_count`: 3130
- `sha256`: ab71d2b34078b5a0266bf9e08c677bb6ad110779a7bc4a3b0dde563fab29f263
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138036 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5d08295b94b0_0, 0, 1024;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 34196
- `line_count`: 710
- `sha256`: e8df0102d684016a8d20c93803dc97729023f606acbafbaf6765d5f2291b25a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34196 bytes; lines=710; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47153
- `line_count`: 1228
- `sha256`: 47234c76337f2da4d12c85205c8e6a0d9583b649e02f01cb2479f7d6f9c69cff
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47153 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 53833
- `line_count`: 1355
- `sha256`: 95760a0cda984d47066a5daf3660cc37f3b4021648a0158f4c15a7bc30bc21c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=53833 bytes; lines=1355; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 147679
- `line_count`: 3839
- `sha256`: 32e9a0ca610688e1ba40571e2588b896ba30e9f61091a290c4f17b852a81be28
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=147679 bytes; lines=3839; FAIL=9; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1751479072, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1380275024, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x621dbba90010_0, 0, 1024; %load/vec4 v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 72082
- `line_count`: 1665
- `sha256`: 29dfb570ca4484998f7323f2e370c0fbe008c47a5e64985486f9054041f15215
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=72082 bytes; lines=1665; FAIL=11; PASS=1; tail=.port_info 8 /INPUT 1 "synth_lane1_branch_append_i"; .port_info 9 /INPUT 64 "synth_branch_append_pc_i"; .port_info 10 /INPUT 32 "synth_branch_append_inst_i"; .port_info 11 /INPUT 64 "synth_branch_append_next_pc_i"; .port_info 12 /INPUT 1 "core_commit0_valid...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 53875
- `line_count`: 1306
- `sha256`: 80cef88d009c6e36e4b0e387b2e80e2065ce8b9fef2d3901ecf83223bf07cf76
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53875 bytes; lines=1306; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_control_event_apply_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 23763
- `line_count`: 627
- `sha256`: 085e13b6ee40cc1eb25366b9d9fa6595a08507e0942ee7db0aaeefbc66a28e05
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=23763 bytes; lines=627; FAIL=12; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29483
- `line_count`: 785
- `sha256`: b95fe286ac4c64cbcbc17cc56b8330b18fd0f25267998a9db415c6c2a8403c1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29483 bytes; lines=785; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 6356106
- `line_count`: 144798
- `sha256`: 6ca3141de24d445217d2a11c371c32812d9be66b8c06ec45f056b74916241867
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 1}
- `summary`: vvp evidence; size=6356106 bytes; lines=144798; PASS=1; tail=%pushi/vec4 1635085428, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543711598, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1684825458, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543520873...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: 4d49447ea589aa38dd9cd45e9a6342423604b8a4270d5d7d138871ba573f5070
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34154
- `line_count`: 799
- `sha256`: dd23b9333388b8be05400da8e61c17445ac35b9c9c1767e7c82646e49ed7d353
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: vvp evidence; size=34154 bytes; lines=799; FAIL=4; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 401936
- `line_count`: 10153
- `sha256`: 073362e00689061998ba2d79e3b1da96eb932cdcb6b4dc9ef9d88570d820b5be
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=401936 bytes; lines=10153; markers=<none>; tail=ing_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101127
- `line_count`: 2454
- `sha256`: 4d10f60abb7095ddc173a4d5c7a7f93d34df21cb1d9025583c22988e9dc547d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101127 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53579
- `line_count`: 1375
- `sha256`: 88448e8349d1626272e32f384bdf29a36e440097392be326ddbdcb56d2c5b794
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53579 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 98854
- `line_count`: 2306
- `sha256`: c43c22de0d59e6fd159454c0bf77f55bb28872cf138b313854ed32a5bdea67c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=98854 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 1143803
- `line_count`: 26012
- `sha256`: 4e9e2ee984137763d1374bef700eb89302db013b6db6991534a0be8aa7a03a26
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1143803 bytes; lines=26012; markers=<none>; tail=ore/vec4 v0x5b7ecbc45360_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x5b7ecbc45280_0, 0, 1; %fork TD_tb_ooo_dispatch_backend.tb_check1, S_0x5b7ecbc450a0; %join; %free S_0x5b7ecbc450a0; %pushi/vec4 1, 0, 1; %store/vec4 v0x5b7ecbc46730_0, 0, 1; %pushi/vec4 1,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_dual_memory_sustained_issue.vvp

- `kind`: vvp
- `size_bytes`: 8148067
- `line_count`: 187342
- `sha256`: 305a4cc46876e6fb7539a6de64160612c94ae02ee367651cb418731d218b7e3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=8148067 bytes; lines=187342; FAIL=10; PASS=1; tail=%nor/r; %flag_set/vec4 9; %flag_or 8, 9; T_1031.7; %jmp/1 T_1031.6, 8; %load/vec4 v0x5a9d1fbf4980_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1031.6; %jmp/1 T_1031.5, 8; %load/vec4 v0x5a9d1fbf5670_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1031.5; %jmp/0xz T_1031.3, 8...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 1266778
- `line_count`: 33289
- `sha256`: abdb8d1885f2617ab50bb88fd6785da8f124599eaae605921fc3a0f642da1f13
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 12, "PASS": 13}
- `summary`: vvp evidence; size=1266778 bytes; lines=33289; FAIL=12; PASS=13; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 840389
- `line_count`: 21428
- `sha256`: c40dbe2e6ac2408bd29f8e0414c78d791d1768612f5fabc2052cbe8fcdb0d2d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=840389 bytes; lines=21428; FAIL=3; PASS=2; tail=ad/vec4 v0x62bcb1b598a0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_170.88, 9; %load/vec4 v0x62bcb1b592c0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/1 T_170.89, 9; %load/vec4 v0x62bcb1b59200_0; %or; T_170.89; %nor/r; %and; T_170.88; %flag_set/vec4 8; %...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2338470
- `line_count`: 59667
- `sha256`: 83781a9c4ab7e595cba5c64e6b437edb6735ef98e808ef2abfd771c57fb34f2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=2338470 bytes; lines=59667; FAIL=3; PASS=2; tail=eed_ad_update, S_0x571f061d1360; %join; %free S_0x571f061d1360; %pushi/vec4 1, 0, 1; %store/vec4 v0x571f061f2590_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x571f061f1650_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x571f061f1f30_0, 0, 1; %pushi/vec4 1, 0, 1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 960578
- `line_count`: 24597
- `sha256`: 24e2c445689dd10fb469f57f4b14e1e7baa77f6a1a72c5b0d6da598320ae2d1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=960578 bytes; lines=24597; FAIL=4; PASS=2; tail=/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_branch_target.vvp

- `kind`: vvp
- `size_bytes`: 43990
- `line_count`: 1076
- `sha256`: bd54f7e2e2dacec3c0920d4282a03565b6f194667b7e9bffbd154733404f6d61
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=43990 bytes; lines=1076; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 126494
- `line_count`: 3125
- `sha256`: e282274356ab11e57b00b3a5367961bcdf3f9c160ffe07d5bf5e52c2c75449d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=126494 bytes; lines=3125; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 543585644, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1814062697, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1718558820, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 457066
- `line_count`: 9835
- `sha256`: 576ba8b6ebacd2f68a1940a3e3ee3c88418235c56275654eb12d624d0d105264
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=457066 bytes; lines=9835; FAIL=2; PASS=1; tail=%pushi/vec4 1970303087, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1920230756, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544367987, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 176819132...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 417800
- `line_count`: 8306
- `sha256`: 8c99298aadcea1b9d141f36c02cfb5f712513485e6de6bf6f97794a5ab7b497a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2}
- `summary`: vvp evidence; size=417800 bytes; lines=8306; FAIL=2; tail=ncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 3...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 125913
- `line_count`: 3149
- `sha256`: 11767c8aa23eeb3d054b715d81e931eee1d545bde9bfc20a00b5345295190dd6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=125913 bytes; lines=3149; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 323785
- `line_count`: 8272
- `sha256`: c5947eeecf8e9d3f1f71f9995d3fc77c1e15a9a1d5af50adde932632d21fe183
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=323785 bytes; lines=8272; FAIL=6; PASS=3; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 197151
- `line_count`: 5127
- `sha256`: a7f46ca65cde4ab66b9ba1f673098f99de649a53449e4e88474a71a71f265833
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 3}
- `summary`: vvp evidence; size=197151 bytes; lines=5127; FAIL=8; PASS=3; tail=ec4 2147500032, 0, 64; %store/vec4 v0x5da510e693d0_0, 0, 64; %pushi/vec4 6292243, 0, 32; %store/vec4 v0x5da510e691f0_0, 0, 32; %pushi/vec4 7340947, 0, 32; %store/vec4 v0x5da510e692f0_0, 0, 32; %fork TD_tb_ooo_fetch_packet_fifo.drive_enqueue_packet, S_0x5da5...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 56265
- `line_count`: 1292
- `sha256`: 682437e69a3d6deef9c456a3f88af4b5532032bbe9dac618d3ba1e77d7a0e7a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=56265 bytes; lines=1292; FAIL=14; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 69962
- `line_count`: 1833
- `sha256`: ea0e7ed7aa43e60dad1df89a6102d9e2d86fc7aa870a86b1eb5264da3f2a744a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=69962 bytes; lines=1833; FAIL=3; PASS=1; tail=INPUT 1 "drain_pending_system_i"; .port_info 16 /INPUT 1 "drain_pending_branch_undispatched_i"; .port_info 17 /INPUT 1 "drain_pending_jump_i"; .port_info 18 /INPUT 1 "drain_pending_mem_i"; .port_info 19 /OUTPUT 1 "clear_o"; v0x58f5dee6cbc0_0 .net "branch_re...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1377237
- `line_count`: 35164
- `sha256`: cfc376f9f2650e4479fd6f9e50f8d3b7b154b6a96aa77ed29458049dfa9b6e6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 3}
- `summary`: vvp evidence; size=1377237 bytes; lines=35164; FAIL=5; PASS=3; tail=vec4 v0x59d43fb71170_0; %parti/s 12, 0, 2; %load/vec4 v0x59d43fb71520_0; %pushi/vec4 2, 0, 5; %pushi/vec4 3, 0, 3; %store/vec4 v0x59d43fb73620_0, 0, 3; %store/vec4 v0x59d43fb737c0_0, 0, 5; %store/vec4 v0x59d43fb738a0_0, 0, 5; %store/vec4 v0x59d43fb73700_0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 131596
- `line_count`: 3397
- `sha256`: 54f0128b77ee71e63f6fc0b2b6a0ebb32de990f21e824c395437bb1bbb7917be
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 1}
- `summary`: vvp evidence; size=131596 bytes; lines=3397; FAIL=6; PASS=1; tail=ng_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 94731
- `line_count`: 2349
- `sha256`: 65703b98cd040a6482c800e310f775da23fdec1160c9abdecb6155e10eb72c68
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=94731 bytes; lines=2349; FAIL=4; PASS=1; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_static_classify.vvp

- `kind`: vvp
- `size_bytes`: 133289
- `line_count`: 2374
- `sha256`: 4ef7dbac8b33c48392a7fd1bde77a412fcf1410118b8e81d450bb72bd1848c2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=133289 bytes; lines=2374; FAIL=4; PASS=1; tail=OR 1, L_0x5bd88b02e5e0, L_0x5bd88b02f1d0, C4<0>, C4<0>; L_0x5bd88b0165a0 .functor OR 1, L_0x5bd88b016530, L_0x5bd88b030420, C4<0>, C4<0>; L_0x5bd88b016660 .functor OR 1, L_0x5bd88b0165a0, L_0x5bd88b031820, C4<0>, C4<0>; L_0x5bd88b041f40 .functor OR 1, L_0x5...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 5577818
- `line_count`: 124631
- `sha256`: fc5232ae0717580e4ceb3634546c94cd1be85c0d9eb95e4a4c1857e63fc6adc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=5577818 bytes; lines=124631; FAIL=4; tail=9O-CONTROL-EVENT-SELECTIVE-SOURCE] frontend winner lacks matching backend branch projection @%0t", $time {0 0 0}; %vpi_call/w 4 1932 "$fatal" {0 0 0}; T_544.2 ; %load/vec4 v0x5c61e2a235d0_0; %nor/r; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_544.14, 10;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 400745
- `line_count`: 12008
- `sha256`: dc668e1204cfd80fb6f37c0ff2708f737731d769f7d91c5886e5ab113d27185a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6}
- `summary`: vvp evidence; size=400745 bytes; lines=12008; FAIL=6; tail=aw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68451
- `line_count`: 1835
- `sha256`: ddc818a8adad9cb102ebf4af60ba90418647d36bd8c77479fea2a7e81f3cbdda
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68451 bytes; lines=1835; FAIL=7; PASS=2; tail=5e8c862fb300_0 .var "class_s_bits", 9 0; v0x5e8c862fb3e0_0 .net "class_value_o", 63 0, L_0x5e8c8630ce70; alias, 1 drivers v0x5e8c862fb4c0_0 .net "double_i", 0 0, v0x5e8c862fc440_0; 1 drivers v0x5e8c862fb580_0 .net "frs1_value_i", 63 0, v0x5e8c862fc510_0; 1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 97895
- `line_count`: 2767
- `sha256`: 3c3d349b8075bd83fdd58b36740caca50b3e2e00b6c62873fe1358f6bcfd943c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=97895 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x639596551c70_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x639596551f60_0; %store/vec4 v0x639596552880_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x639596551dc0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x639596551e80_0; %store/vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202658
- `line_count`: 6365
- `sha256`: d3f220502eabaf596c45e91ef9020273eaf30a23cada2eec915deffbf7db34a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202658 bytes; lines=6365; FAIL=4; tail=657150_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x61689c656c40_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x61689c657750_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x61689c656d00_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x61689c657810_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 481776
- `line_count`: 12442
- `sha256`: 343100fdf2b2de7c2fb4039371c5615474db2225f8f98a451fe65866e9b49c4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=481776 bytes; lines=12442; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1412646432, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919247215, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986359909, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 83963
- `line_count`: 2210
- `sha256`: 4387f2d6ac46c5acaef8ca6686a174d641fdd3a609f996522bfc678d79bb9d33
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=83963 bytes; lines=2210; FAIL=8; PASS=2; tail=61056a030180_0 .var "exp_remainder_nonzero", 0 0; v0x61056a030260_0 .var "exp_root", 55 0; v0x61056a030340_0 .var "first_value", 111 0; v0x61056a030400_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start ; %pushi/vec4 1024, 0, 112; %s...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 216182
- `line_count`: 5300
- `sha256`: cb9aaa4e9db6adfa0e3edc37878c6a55b13b16363f41a7b51b7c30d3af98e6e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=216182 bytes; lines=5300; FAIL=3; PASS=2; tail=set/imm 4, 0; %store/vec4 v0x5d987019bc40_0, 4, 2; %pushi/vec4 1, 0, 1; %ix/load 4, 29, 0; %flag_set/imm 4, 0; %store/vec4 v0x5d987019bc40_0, 4, 1; %jmp T_9.34; T_9.31 ; %pushi/vec4 0, 0, 1; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x5d987019bc40_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197006
- `line_count`: 6101
- `sha256`: 1de6d6082c9d3c10116ba6443180cf51a4d205c1c9ec3ed991ab6abbbd0c2c72
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197006 bytes; lines=6101; markers=<none>; tail=vec4 v0x6259c2d13410_0; %parti/s 1, 2, 3; %store/vec4 v0x6259c2d12e50_0, 0, 1; %load/vec4 v0x6259c2d13410_0; %parti/s 1, 1, 2; %load/vec4 v0x6259c2d13410_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x6259c2d13270_0; %or; %store/vec4 v0x6259c2d13930_0, 0, 1; %push...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64037
- `line_count`: 1638
- `sha256`: f3282f078f14b85016143aab928fe172a4f9e372e42875bbf244c48b211b6488
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64037 bytes; lines=1638; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30253
- `line_count`: 661
- `sha256`: 2613feb925675a60d423976886098937010e2f437da110d99fe3d91fb9c5eab7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30253 bytes; lines=661; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39292
- `line_count`: 1056
- `sha256`: d968e3aa560453181d2eead0f268a7ac7f7b723d81fc0493de2f84aa288defc1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39292 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 75847
- `line_count`: 1877
- `sha256`: a72cb3f701c0f82bfa42ecc157e91c68de37cf2d8b72fa65402a8c8fd99e254e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=75847 bytes; lines=1877; FAIL=6; PASS=2; tail=vers v0x58767df1fc10_0 .var "head_q", 5 0; v0x58767df20100_0 .var/i "idx", 31 0; v0x58767df201e0_0 .net "next_count_w", 6 0, L_0x58767df251c0; 1 drivers v0x58767df202c0_0 .net "post_alloc_count_w", 6 0, L_0x58767df23cf0; 1 drivers v0x58767df203a0_0 .net "po...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 100928
- `line_count`: 2481
- `sha256`: 04c0a4d0ab8b02a1069aab18b1367c2b4acb099d09ace0d55056f8d88b352150
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=100928 bytes; lines=2481; FAIL=3; PASS=1; tail=, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 110858
- `line_count`: 2616
- `sha256`: b521b62f6efcb41915167b45b4423a26bd1b4dd05d6018f4c2fa40ae9e04eb76
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=110858 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x644701789140_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x6447017896a0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x64470178eeb0; %join; %free S_0x64470178eeb0; %alloc S_0x6447017d6d70; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x6447017d...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 146851
- `line_count`: 3486
- `sha256`: 73ec4828daab62d2713bfbe0f1feb76184b3fe7340b214cb2a239a5e471b1dd0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=146851 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x5650f2d92d90; %alloc S_0x5650f2d92d90; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 90847
- `line_count`: 2250
- `sha256`: 4c7fc5e08f4c41fc0ce9aa47a5058b56865af8280b106311c224ce044f62c8f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=90847 bytes; lines=2250; FAIL=3; PASS=1; tail=4 1718558834, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702061426, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986338913, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986095468, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138490
- `line_count`: 3101
- `sha256`: 623154f3186ca9f0b4b347afd570c6ffbd588099d87ee0d314c68b43d961aa08
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138490 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 696839
- `line_count`: 15284
- `sha256`: 1eb182332454c1225ae4ca9cae5fb000d59d41cd30bc3ef494a93fe5081cd093
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 6}
- `summary`: vvp evidence; size=696839 bytes; lines=15284; FAIL=3; PASS=6; tail=v0x576781a40280_0, 0, 2; %pushi/vec4 0, 0, 1; %store/vec4 v0x576781a17de0_0, 0, 1; %fork TD_tb_ooo_ifu_lane1_fault_owner.run_tval_lifecycle_row, S_0x57678187d070; %join; %free S_0x57678187d070; %alloc S_0x57678187d070; %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 12186069
- `line_count`: 305776
- `sha256`: 33ca60a5746ef45aeb2b4a3ab12c956f6b2ee4d0734b503530d30432899c9cd4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=12186069 bytes; lines=305776; PASS=2; tail=v0x5cacc8c18960_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5cacc8c18960_0, 0, 1; %delay 1, 0; %alloc S_0x5cacc79b0310; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1196504
- `line_count`: 30124
- `sha256`: bf2bfe2ace8deeb7ed575b1510e97b68ca224619f730e330f77dcedc03ff92c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1196504 bytes; lines=30124; markers=<none>; tail=/vec4 1, 0, 1; %store/vec4 v0x5ed9f6685180_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5ed9f6685180_0, 0, 1; %alloc S_0x5ed9f64c2c60; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x5ed9f64c2c60; %join; %free S_0x5ed9f64c2c60; %delay 1, 0; %...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_load_queue.vvp

- `kind`: vvp
- `size_bytes`: 199457
- `line_count`: 4947
- `sha256`: a4e33fb771a4a15b289b79e999818579f87d61a6788be0dc302e1cca1fb35a45
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: vvp evidence; size=199457 bytes; lines=4947; PASS=3; tail=string_vec4 %pushi/vec4 1852142177, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1953066862, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543781664, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_lsu_axi_lane_adapter.vvp

- `kind`: vvp
- `size_bytes`: 118694
- `line_count`: 3332
- `sha256`: 4ec1f117601cb970f23d0af82b470efcd9aae95c42d62e85f77e3f8a2b9f9bca
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 9, "PASS": 2}
- `summary`: vvp evidence; size=118694 bytes; lines=3332; FAIL=9; PASS=2; tail=750050 .reduce/nor v0x5e92b2732e20_0; L_0x5e92b2750560 .cmp/eq 3, v0x5e92b27344a0_0, L_0x752c75b572e8; L_0x5e92b2750ab0 .ufunc/vec4 TD_tb_ooo_lsu_axi_lane_adapter.dut.sticky_resp, 2, v0x5e92b2734140_0, v0x5e92b273b500_0 (v0x5e92b272d2c0_0, v0x5e92b272d1c0_0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 3579822
- `line_count`: 91070
- `sha256`: 688292510e09001400102fe36ce988dfb8a3add177b9e25e17f5a451d6206f9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 1}
- `summary`: vvp evidence; size=3579822 bytes; lines=91070; FAIL=1; PASS=1; tail=%and; T_215.148; %flag_set/vec4 10; %flag_or 9, 10; T_215.147; %flag_get/vec4 9; %jmp/1 T_215.146, 9; %load/vec4 v0x56700af85cd0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_215.150, 9; %load/vec4 v0x56700af7fb00_0; %load/vec4 v0x56700af8a630_0; %cmp/ne;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_mem_inflight_queue.vvp

- `kind`: vvp
- `size_bytes`: 305323
- `line_count`: 7665
- `sha256`: dccf2e46e0a37549d8c68f55b29ebb76931d26aa093e474cd9221b59515115f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=305323 bytes; lines=7665; FAIL=4; PASS=2; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 84965
- `line_count`: 2354
- `sha256`: fc42e011a5487a80be83d72cfb57d1aca5a0e6398fcc6485f2251d2dcdaddcfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 3}
- `summary`: vvp evidence; size=84965 bytes; lines=2354; FAIL=1; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_mem_owner_tracker.vvp

- `kind`: vvp
- `size_bytes`: 136101
- `line_count`: 3605
- `sha256`: 40cd6e203bef97caac0e75091cfbda7c36fa2a5fd44b356311aad97fcd12a5bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: vvp evidence; size=136101 bytes; lines=3605; FAIL=2; PASS=4; tail=/ne 3, 0, 3; %jmp/1 T_14.19, 4; %flag_mov 8, 4; %load/vec4 v0x63c214b306d0_0; %parti/s 1, 5, 4; %nor/r; %flag_set/vec4 9; %flag_or 9, 8; %flag_mov 4, 9; T_14.19; %jmp/0xz T_14.17, 4; %alloc S_0x63c214b2ea30; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 58048
- `line_count`: 1438
- `sha256`: c54b2fe70f8fb76f98261e664f24b9b9c5843cb6f82094f76a1bbd36c6b4e00e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=58048 bytes; lines=1438; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_mmu_epoch_owner.vvp

- `kind`: vvp
- `size_bytes`: 135188
- `line_count`: 3828
- `sha256`: 12142e53671316475900331779dec9e8e853676b2d550db68ec1f2c7f6e9ba51
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=135188 bytes; lines=3828; FAIL=1; PASS=4; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 348991
- `line_count`: 8867
- `sha256`: 34f76b437d6d44407814b60abb29d5110c7065ac25166e707a0d4a4924d1cb0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=348991 bytes; lines=8867; FAIL=5; tail=ushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 218534
- `line_count`: 4978
- `sha256`: 63d05ff7ea1c8d0b468c8d89a364b4fb6683be34dd6ca4f8e59c9d8dcab3befe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=218534 bytes; lines=4978; FAIL=5; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 824206949, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1952671776, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1717663084, 0, 32; draw_string_vec4 %concat/vec4; draw_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 86084
- `line_count`: 2063
- `sha256`: 6763ed50b84013afda91cfe39653f926f96c317702ce8e6d63987c134a83dd59
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=86084 bytes; lines=2063; FAIL=3; PASS=1; tail=; %join; %free S_0x62a5ac152b00; %delay 1, 0; %alloc S_0x62a5ac1a2aa0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 108020
- `line_count`: 2656
- `sha256`: fbb3640e453670acf73b1619378b06c1117ad854bce195326e8325538bbc67de
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108020 bytes; lines=2656; FAIL=5; PASS=1; tail=_capture_gate.clear_inputs, S_0x6429d9d7d390; %join; %free S_0x6429d9d7d390; %pushi/vec4 1, 0, 1; %store/vec4 v0x6429d9d7d780_0, 0, 1; %pushi/vec4 1, 0, 1; %ix/load 4, 38, 0; %flag_set/imm 4, 0; %store/vec4 v0x6429d9d81270_0, 4, 1; %delay 1000, 0; %alloc S_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pending_system_admission_cancel_gate.vvp

- `kind`: vvp
- `size_bytes`: 14437
- `line_count`: 323
- `sha256`: 3692b10e87ddd98796c0d69d90ba6ac9bfa6acbf0cd721ad633b0ff3814536bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=14437 bytes; lines=323; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 135644
- `line_count`: 3392
- `sha256`: 63d75c152bc1b5c1c74384d8d4ddb4986f02b05901be46cd0493edc0f0add62e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 2}
- `summary`: vvp evidence; size=135644 bytes; lines=3392; FAIL=5; PASS=2; tail=%load/vec4 v0x5b6ef4f32930_0; %assign/vec4 v0x5b6ef4f34050_0, 0; %pushi/vec4 0, 0, 5; %assign/vec4 v0x5b6ef4f35620_0, 0; %pushi/vec4 0, 0, 8; %assign/vec4 v0x5b6ef4f362a0_0, 0; %jmp T_9.12; T_9.11 ; %load/vec4 v0x5b6ef4f34de0_0; %flag_set/vec4 9; %flag_get/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 28463
- `line_count`: 854
- `sha256`: 53b79659a62d586afc42d25af4da08682d8d8998cf6c3c340ad7d75c3436d7d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: vvp evidence; size=28463 bytes; lines=854; FAIL=2; PASS=6; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 192896
- `line_count`: 4897
- `sha256`: d3bbe75afac1980a643aabeeba90014343f16ead2c3e130e386abf1eadce7fd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=192896 bytes; lines=4897; FAIL=3; PASS=1; tail=w_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_pma_checker.vvp

- `kind`: vvp
- `size_bytes`: 118579
- `line_count`: 2750
- `sha256`: 402e945fd42e5bddcdc20e27003efee04758f97f84da5e1beaadceb1a4e9c9e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=118579 bytes; lines=2750; FAIL=4; PASS=2; tail=768843040, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1347637825, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1293968485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1668244581, 0, 32; dr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6377586
- `line_count`: 146431
- `sha256`: 28c46289c845c71b1022362762dae646419271c6281ed05c493985f8d9e93c16
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6377586 bytes; lines=146431; FAIL=3; PASS=2; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63728
- `line_count`: 1586
- `sha256`: ae2a4ed98190a8fdb78a5cf382c596664f0c80a0780f00776339cc4de6949364
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63728 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 34854
- `line_count`: 876
- `sha256`: 12e891b291ba25aeb4fcfbd168dad9091dbaa3d9fada9a073fcb2bd2183df212
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 22, "PASS": 2}
- `summary`: vvp evidence; size=34854 bytes; lines=876; FAIL=22; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99472
- `line_count`: 2436
- `sha256`: 17ef88f4bdf176a603ed6d4d0a97b5e5a43c999bc2048df65f5556683396bdff
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99472 bytes; lines=2436; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 1076006
- `line_count`: 26450
- `sha256`: fe82776468eae31fee69f276c82589531b646c31a873e8caa971a9a1b156676f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1076006 bytes; lines=26450; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 66064
- `line_count`: 1798
- `sha256`: 969f856a6f79a3fbb7eecd34ac91c84f104babe4dfb4c8d31901717e2758f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 3}
- `summary`: vvp evidence; size=66064 bytes; lines=1798; FAIL=3; PASS=3; tail=716a50aac0 .scope module, "tb_ooo_stop_pending_sequencer" "tb_ooo_stop_pending_sequencer" 3 4; .timescale -9 -12; v0x5e716a52bec0_0 .var "branch_resolve_untracked", 0 0; v0x5e716a52bf80_0 .var "branch_spec_checkpoint_capture", 0 0; v0x5e716a52c020_0 .var "b...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 584857
- `line_count`: 14289
- `sha256`: c940d1662a27b1fd1231aeaa4e80188386728ffcc425be1e5871bc83839e9102
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=584857 bytes; lines=14289; FAIL=1; PASS=4; tail=020; %alloc S_0x6302171cd7e0; %pushi/vec4 12, 0, 4; %store/vec4 v0x6302171eb4e0_0, 0, 4; %fork TD_tb_ooo_store_queue.alloc_one, S_0x6302171cd7e0; %join; %free S_0x6302171cd7e0; %alloc S_0x6302172c4560; %pushi/vec4 12, 0, 4; %store/vec4 v0x6302172c4740_0, 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 8303998
- `line_count`: 192391
- `sha256`: 4c6207606299ae897166ddeb44fe26486936663bedf8d5ce78dca563166d8c1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=8303998 bytes; lines=192391; FAIL=14; PASS=2; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36101
- `line_count`: 734
- `sha256`: 5aa2cfb82d4a2b836e78c33481e57781445c5efd863cba51da2b6fce83b546c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36101 bytes; lines=734; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 16989
- `line_count`: 476
- `sha256`: eec4cf8f521e4ed2b3f0dabfb03afeaec4178c2ad49f28c9ccfc9e5d133330b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=16989 bytes; lines=476; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_ooo_typed_memory_classifier.vvp

- `kind`: vvp
- `size_bytes`: 52197
- `line_count`: 1446
- `sha256`: 2e1d143bd18732b693b9fae09de8f20d9f4367225e0b99dbfa84658fefb1a408
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 4}
- `summary`: vvp evidence; size=52197 bytes; lines=1446; FAIL=10; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65157
- `line_count`: 1744
- `sha256`: 70f02fe8ab3f002557f99cd702caeb7894d53bec17ddafe7b5d1d14ffe9e9d9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65157 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180661
- `line_count`: 4649
- `sha256`: 61615d37b9c4472b778feeed0cb7ae9cdb9861b9c99da5fd13ddb9c5312cad57
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180661 bytes; lines=4649; FAIL=3; PASS=1; tail=1da0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x64cce0752070_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x64cce070b4a0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x64cce0751c20_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x64cce0735140; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300070
- `line_count`: 8070
- `sha256`: e46a39bd5b551ac99784040f5a7433842ab0693d0fcc663d832786b8d5b9e6d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300070 bytes; lines=8070; FAIL=4; PASS=1; tail=1; %store/vec4 v0x5d36ea30e6f0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5d36ea30e6f0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5d36ea30ee20_0, 0, 1; %delay 1, 0; %alloc S_0x5d36ea30d290; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25241
- `line_count`: 678
- `sha256`: d9a78fd8e963a92e63cd37bc04be2f68aac706effd590f21ca797a415217388b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25241 bytes; lines=678; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current-run.log

- `kind`: log
- `size_bytes`: 4095
- `line_count`: 126
- `sha256`: c2b7db93ae591202070f39c50ad9f2068319e3220fc3881b91aee9b5ebda99ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 224}
- `summary`: log evidence; size=4095 bytes; lines=126; PASS=224; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 465
- `line_count`: 5
- `sha256`: e636fcbac7096b3e6c41e0d508e33d58f8866cf26f829fa9c8782a79c0c09f89
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=465 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-reco...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 497
- `line_count`: 5
- `sha256`: df331606b394ee98087ea81d9f14c0e100d4c5a9f50f75b802e5359003dd7936
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=497 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3707
- `line_count`: 29
- `sha256`: 9b80aea8026dd0d350d693e0f4551b2afeac1ee799250a6e94e71cf86a05ccf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3707 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 605
- `line_count`: 6
- `sha256`: c7922c751826459f8a2522c4da3c6bb2747b4c4ad358b19b38221fc23615d834
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=605 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-seri...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 6
- `sha256`: c56ec3164f5d6a5a66b47329c28fc67d609286a5a47e665d22cb6cd9ff648ea3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 561
- `line_count`: 5
- `sha256`: 3b7ed87a4be3196ff5ed9419a40d4d448031f5100fe523022d5ff4b20ebf9673
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=561 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3491
- `line_count`: 29
- `sha256`: 15e79a023976d4912227544bbacaccc0446f48948ba1da6d058133f1846f2920
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3491 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-seri...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: f5fe4a963ef6569b5baa343b83824fef035fa9f026aa8e98925806737ee65d80
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serial...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 492
- `line_count`: 5
- `sha256`: cd2108dbb1e2840ba8dd0a3e0cb05e6457b19571d4506d6c8cb71a6220dc4ee7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=492 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-seri...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_csr_file_vectored_trap.log

- `kind`: log
- `size_bytes`: 677
- `line_count`: 6
- `sha256`: f4ccea6014cf1ae080f61235ba9587c9541af55074ac9ab1aa11bc086063e869
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=677 bytes; lines=6; PASS=6; tail=[TEST] tb_csr_file_vectored_trap [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file_vectored_trap -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 636
- `line_count`: 5
- `sha256`: 756139e8ea12b21da0801ea36f429b50dd59cf9ec464998d56d31f4e3e49f811
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=636 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 511
- `line_count`: 5
- `sha256`: 144ee41fe73e3cf092d6d8cc143232b8158ad7a31ed9bef9c4819644e50e0eda
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=511 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 481
- `line_count`: 5
- `sha256`: c821ad44a624322514a575b659846ddbcd7aab61a40386250edafca4f4d469c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=481 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serializ...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 588
- `line_count`: 5
- `sha256`: 54bb63ccfdad4119bfa1f472728f84cab937bb5552461dde92fd76db46a02918
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=588 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-reco...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 510
- `line_count`: 5
- `sha256`: 1fba805c8f0a2abb0782893c4718dd16eebf5b348252f8824dbc378556efcc63
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=510 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: a95345c1627fa9df69c213586573272f86cfa2e9a798b314c9a7a3dd747177ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31490
- `line_count`: 208
- `sha256`: 4c525428260f9ebd366ad2213e669d95bce2c48a5a1029042eb281c03a50342e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31490 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31670
- `line_count`: 206
- `sha256`: 9bedf26b59cf72f01e03753cc0e3a97ec07a50ef79126bde32b3331410ba5ceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31670 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: 48289820431d93d7c0aae4604b04a4e9feb34146f26089a4c44097b235bf8a60
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: 46b8a1bbc62fc68022e8b05d634660aeb0b166a3fda79518dda190f9682d1d02
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 5
- `sha256`: af2209d29bd9420143ab38ad29eebc9e91e41610f19427ad56fcea2455804593
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 973
- `line_count`: 9
- `sha256`: 69b00c4e2d04702f042414a575de75199d73bfae3ec1bcb46f8c30435785b1a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=973 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 928
- `line_count`: 9
- `sha256`: 5d37ec8038170e934eec71c8a064002f1ff36bd0c3a22fb87c4c08b9517e49c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=928 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 711
- `line_count`: 5
- `sha256`: 9f1ef47b6142c622cb2054d1e3eb1c92d8c54ab85ec06d3f461263b7363a0d6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=711 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 983
- `line_count`: 9
- `sha256`: db54629a99af82eec6dfc0c75fd1ce8c63bddab1f7c68b17364613fcf5f47ad0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=983 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: 9513cbc8cb7fc99c3d13552cd15d8206f4e4085c9f94cdfef56c16ee2ee146ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 668
- `line_count`: 6
- `sha256`: 468661f1390bfddaa70be7eacf3cf75f9be204e89c99d69d83b2a62b0c6f59ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=668 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 531
- `line_count`: 5
- `sha256`: 737d4bbcb34e61837c71de79302ab6bfd1328d8b103cfdabb072a95293c3a54a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=531 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 886
- `line_count`: 9
- `sha256`: 6465f1a61c27bbbd82b970e566238183b186a8125cb7101f011a78da1ca3b27f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=886 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 951
- `line_count`: 9
- `sha256`: 069177d2c9828f34d5c63bfa7d3b18a3eef5990021eaa2f3e34e717af79f898d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=951 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_control_event_apply_sequencer.log

- `kind`: log
- `size_bytes`: 964
- `line_count`: 9
- `sha256`: 4e4c304944b3ef47f43659895ad9fddfaaedadaff24f7c813da38cfc640f99f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=964 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_event_apply_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_event_apply_sequencer -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 938
- `line_count`: 9
- `sha256`: 394e6354121bd425f2f0835f324a021d026b1b78f270c399c7f9c2a8a86ea70f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=938 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25479
- `line_count`: 140
- `sha256`: 415fa7a62af47e47d3c91821d4bf71832ef4f3ebff3f64051abbff079eddea39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25479 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 616
- `line_count`: 5
- `sha256`: 5f851a7b4fe794e29c714a2b1c8b7762dd5e89f7fb84b523fecab563149d3fcd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=616 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 679
- `line_count`: 6
- `sha256`: dca2821c90be6bf7ca8c9351256c615df74540ddd65ed739d64db842d0772dd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=679 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 5
- `sha256`: 4383155d01fa2a6d2dbbb7d6d8869cb9c28956f0eb1677f02c2ce3df40457e47
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 624
- `line_count`: 5
- `sha256`: 58daaf4986e69128cbdaf2124d7891abdf25ed018d8602185b7237938da9f623
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=624 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 5
- `sha256`: b1d67e56ade6f2cb35bead3b5c8905004cf0c6e44e0db60265257591620728ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=618 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 5
- `sha256`: 68081013804ad0af99fcaecbb56ae8699b9320f336d0ea62c44895bc4a1225a4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=618 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5820
- `line_count`: 40
- `sha256`: ed71a1e1fd591892cb497afb1c48fab6ba11c9d2de7e380da61a6a1eeb48e364
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5820 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 306437
- `line_count`: 2296
- `sha256`: 5aafcda7fdc9dc88d2758eabd17357c0475f2fc46c2d40a82447673f665a6e7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=306437 bytes; lines=2296; PASS=2; tail=orkbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 114295
- `line_count`: 944
- `sha256`: 71e774de20b0ef841102713bc4a66ab2ede51b96a1b24427f5d1d8d18bd10bde
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 159}
- `summary`: log evidence; size=114295 bytes; lines=944; PASS=159; tail=yx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103843
- `line_count`: 780
- `sha256`: 6ebfece10c158cf2d9fef642fa3caed167e6ac61f1de9b5bd94f948c0d174b61
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=103843 bytes; lines=780; PASS=3; tail=ing: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105358
- `line_count`: 794
- `sha256`: 79729f95693c08752d071f7ee3efb3d39a91796ebe889e0f3c5a3dd3d98c53f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=105358 bytes; lines=794; PASS=3; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106774
- `line_count`: 803
- `sha256`: 57659cb90e06d3d887900c610de0f93e5135ee189a3cb086e00c5b38779a3cee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=106774 bytes; lines=803; PASS=3; tail=/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: 691ca277965395aa8b62f78e1473c5c29a68f096080fde9cb495980b50f99c86
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 577
- `line_count`: 5
- `sha256`: 1b19a44ad0d30bfeaeabdef86722e6da5e50b6a0b03438c7f2ab82e24c93c1fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=577 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 6
- `sha256`: c6a11fc5db141b9aa87d54b2bcd61dafcca00213202dab6a8ac490db912a9f26
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=853 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 5
- `sha256`: e1f5ceb55aa61ad664127aef2a87a626c99642fd364a2233510bf18710207486
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=805 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 714
- `line_count`: 5
- `sha256`: 31c36f9a9ccc3751f610c4ce92c622aa28f6988367478d0c116b2b18add8c1ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=714 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 844
- `line_count`: 8
- `sha256`: cb98931ef4ff3443094fec4bd62718ac7230aa8cfc43979c9818356777314cf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=844 bytes; lines=8; PASS=8; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1251
- `line_count`: 14
- `sha256`: ad2a1d8999fcdff0c4e963bb494607aaf5e2f4543775269f8142ef40650a8371
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1251 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 593
- `line_count`: 5
- `sha256`: 41cf458a4d4cad79de1c35013685e7b5b79227e3dad0842e537c5ce337ff2b8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=593 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 87eb7b05bb157d12c2f6318dcc795a203039672a27fd9f342c6fa5a3981528a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 108193
- `line_count`: 818
- `sha256`: a29131e4837ba1401c80266cf6881e700766d2eeaa61a9219e9a6350755a2ff0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=108193 bytes; lines=818; PASS=16; tail=v64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 648
- `line_count`: 5
- `sha256`: 338d5a3831690cbd6cf42dd673e279e98f572e2bd5a280eb1053818eebb9af5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=648 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 5
- `sha256`: 41344c7091bc0a122b443a01586d702c3dbd8722b4bd4bd57d58f139638ea0b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=571 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 1083
- `line_count`: 10
- `sha256`: 62d98a22f2a2d3b7058c20a2cbc5255f033d5e873ed1bed12693a1aed8775105
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1083 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34497
- `line_count`: 198
- `sha256`: 23e08d0e535938a16de54f7a6f08f371397f2a05212fdcffb3eb2686a51fad1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34497 bytes; lines=198; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 547
- `line_count`: 5
- `sha256`: 596dadc520d33a981447063b8452d3b80392f5cb8c4a8e53ff6fcd5e89e0ae61
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=547 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 564
- `line_count`: 5
- `sha256`: b236b9d1b361041fbd8b9ed9d270129dda63f78610785ff17e1aad8e884d0c6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=564 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 558
- `line_count`: 5
- `sha256`: e0843356e01b809434292b3a9a04d1a7ac7d0e9a2576f439b275fcf6b8bcc037
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=558 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 557
- `line_count`: 5
- `sha256`: 5e711d3fb94491f2d5fd56677ec64e6adc377d5268d987a0ed6615d9f91a23b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=557 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 4053
- `line_count`: 38
- `sha256`: baf7ce79fa3574393e30db0be3dde9beed226cd277c622064116c2a58dc2d847
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=4053 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 582
- `line_count`: 5
- `sha256`: 6d5d2a0d9aefb2d2f5d8542570d1b2f0463e20c6efbc794cfae36bb5e536ca91
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=582 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1886
- `line_count`: 15
- `sha256`: 6c1b35b52791e2c0381454b0ab064e2af30aeba153b82e3ee935b68a1de5b331
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1886 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 689
- `line_count`: 5
- `sha256`: 1bdc3858f430c04086a0ecc4af03e753b668875a5e7e583fdfc5f34889270a68
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=689 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1096
- `line_count`: 12
- `sha256`: b8a330f987342f65ecb2fb03b28ea3d9bf7735dab4dc559657b8e667e2e575f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1096 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 843
- `line_count`: 9
- `sha256`: eeeb854035a67ec7705ba34d647fdaafbd2ee3aa8aa85792ec10d5e1e4dc32a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=843 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 539
- `line_count`: 5
- `sha256`: e3fc6d4cc31fb2451a3fe8a5605a85815b9e3a0bcd24ef68fbd9adba7099e031
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=539 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 531
- `line_count`: 5
- `sha256`: a3f14ccc5881fd84a6ac154437d470fc033359cd1f3b707164a6c2357a14d71b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=531 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv6...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 589
- `line_count`: 5
- `sha256`: 38dd005fc8903569d023d6cacb6a75076bab4f0971d0e3623c146ea1bac1f827
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=589 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 997
- `line_count`: 10
- `sha256`: 773983152b708808fdd10e0a4e1358f65b31c8a25872d771d5bb70884214a131
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=997 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 909
- `line_count`: 7
- `sha256`: 1564b184a4c58fd0d9768734b1b92f9bcbe4f04f6b53e3663794e82f7d80ad54
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=909 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 5
- `sha256`: 5b8ded442ae3f4631bb523249e7661eaf57a50ed63beca23fd0261a36acdb9a2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=571 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: 1fcea9353247fa88419dd7bb51c3ae05916fd38ebb9167428686381f0a5c37f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8907
- `line_count`: 83
- `sha256`: b2fab9d8e8a948382c76fa568c4b2316e26dfe81f83751d59b671764ec4d28b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8907 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26785
- `line_count`: 226
- `sha256`: 90c6b096edb918c0f8bb92c4e1655aa8e2bb9306c74101369e7499387f5db3e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2, "PASS": 98}
- `summary`: log evidence; size=26785 bytes; lines=226; ERROR=2; PASS=98; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11577
- `line_count`: 96
- `sha256`: e2d5f148c0816b5bf54fd4191f8ca45d5284682df0488fb3fb4aa7b2e4876e7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11577 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 4273
- `line_count`: 35
- `sha256`: f8d50148af0f8690d2018ef4a7b35d5efac1a3f86d6f1c7421a53bfd7bbc6852
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4273 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 941
- `line_count`: 10
- `sha256`: 13f031e644429070ea927b0af65241105175007995467f3e0f9d9e45dbe2124d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=941 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74696
- `line_count`: 572
- `sha256`: 003ce1a350623499db8df29632169981e5ae421501228c14e5245731c7b4b935
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74696 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1444
- `line_count`: 12
- `sha256`: 57aa54b0dd4d3cc159ff93544b9edc7c0e689494c6ade149ebfe02f98103d3dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1444 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1095
- `line_count`: 11
- `sha256`: 4fac28b026e07c858e0121ded39f07b0f4134ea07424809b7958987f3acec238
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=1095 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1409
- `line_count`: 14
- `sha256`: 58c820697f1e6f70847762b67163d0eff4b7f674c52d2857d8255ee9c316514e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1409 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1041
- `line_count`: 8
- `sha256`: 55933f5a4bcc5e7ec70ae85bc46a833f4ded040d0914e6bcb747f67a0528608c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1041 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 796
- `line_count`: 8
- `sha256`: 382c6a592f61ba6b044be5e8234f59c9d908dce52a358980efcc33b1c0400562
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=796 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 539
- `line_count`: 5
- `sha256`: adb953bdc78009a004ed525fb0bd8ad041f3aa4c8f445bc427ed4f54510b985b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=539 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1265
- `line_count`: 12
- `sha256`: 349c77c9ae5d238ccd33d3e387dfb2285c729dff7cda26ed712f45f674839b68
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1265 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 623
- `line_count`: 5
- `sha256`: d3d49bd4adac20d1254604481ad3aee4d7d9a92d78e3bbbb51d5f834496d8642
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=623 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 1053
- `line_count`: 11
- `sha256`: c1047003325f9dcfbde22389951ff3aa028926a103cb67133aa4fddae022067c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1053 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 1080
- `line_count`: 10
- `sha256`: 36bd4d3890d6ae8f1186aa73f7cd0a37b21528572b55b90cdea33ebf149d57f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1080 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 1044
- `line_count`: 10
- `sha256`: c71d68fc1b7b25b0dfcf80b4eb641a50724b5891ad8af0c837ff696b7c689aea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1044 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 810
- `line_count`: 7
- `sha256`: 0eaf52c785ce111da75bbc81854da97a4fe8e49b87f8304e5ce977f2b963eea6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=810 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 553
- `line_count`: 5
- `sha256`: b07ac16dab7f228f9f54a8ecdaca19fd98c9de7c558712a63b2fbe1d1d277697
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=553 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 675
- `line_count`: 6
- `sha256`: 2c0ec7dbb16382cbb641a72942a0a2e774feff79f115b2aad94b4e21e7fb21b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=675 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27062
- `line_count`: 143
- `sha256`: fa6afb829619a81f64a63c9635e28c07e5c232fe86deec03f222011c69d87268
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27062 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 559
- `line_count`: 5
- `sha256`: e0f2aebec3636c0eb2b511af8cf6ebb5bd60cd0c77fd10a9f507147dfa686f56
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=559 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 565
- `line_count`: 5
- `sha256`: 3533ddcea779c29e23f0d7211c74376ad29bdf51c58bb6b6da255d8482e61da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=565 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: 46228ec09d78023f5f3962973e1224d39a9631fa47c2a4cd6ab351a65033dbe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1420
- `line_count`: 14
- `sha256`: 417d4859e50be5e0af1873305f3855a0d6e56108089710915ae88b37a21e6e6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=1420 bytes; lines=14; PASS=18; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serial...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 997
- `line_count`: 10
- `sha256`: 0defd3b0c12198a6302b9ef13ca2ebfa6d22f9edab8b2e5b94e5068d87d47946
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=997 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6933
- `line_count`: 58
- `sha256`: fc6cd538a8ec99ac00ec4e29594ac89cafb6a4b2f763394e1f5a59ec4b1c94ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=6933 bytes; lines=58; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287167
- `line_count`: 2103
- `sha256`: e257cccd52498ab25be7a71cda9d6590913830e40ea3b784e9912066d0e17ce0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287167 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: da2343af38759597cb7ac92cb698c1d53022c64dbd884c534b26b41f1829c079
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 644
- `line_count`: 5
- `sha256`: d8b8709ecaad80e0d61d7966f783ebda44071c2a88dcb23c7340fc5ab39a6d2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=644 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 695
- `line_count`: 6
- `sha256`: 7aca23a52bf9b00defc5b49e9e8f7570db1f0d91c2194c38de7b5d3291db2d24
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=695 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 530
- `line_count`: 5
- `sha256`: 601bc859ce70acdae3c7c727fa2b6665ab282c5696eaa2165bde71a742244aa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=530 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17657
- `line_count`: 134
- `sha256`: 83953fc7d17489718421b05b2794a6f1d62e16dd993521735ec6292f9c0c1548
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17657 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: c3b2d9c9cf2677831eec88ac474b106b9ee0b6978e320f17bfeb052095bc11b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-re...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: a7541fe6f4c10cf45feeaafc0eccd78c2f3aafd258d1681dd5893b2a08dae330
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-reco...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current/summary.txt

- `kind`: txt
- `size_bytes`: 3735
- `line_count`: 120
- `sha256`: fd15bdfbfbdf3662cb25a9d6fb8d49f2bbdfd63c58cb374975643fdf95094658
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 222}
- `summary`: txt evidence; size=3735 bytes; lines=120; PASS=222; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/final/module-current - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PAS...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25801
- `line_count`: 148
- `sha256`: 9b07a2b71a64daaab028f2dd28363bf1f544c7949cada072d8e4d04a5d33a65e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 12, "PASS": 10}
- `summary`: log evidence; size=25801 bytes; lines=148; FAIL=12; PASS=10; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8788
- `line_count`: 83
- `sha256`: d16839107062b7c65a2c62385d3be607ef5ce86fb97c2c9dd268784fe1f16eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8788 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1146
- `line_count`: 12
- `sha256`: dda343028a4a0003b597afc715471732e6f994fb7d78139f53e0fe7d749815ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1146 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 925
- `line_count`: 10
- `sha256`: d02b96b48547c717c176a136201f935248381419ab3198de9f0069656b75f7ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=925 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 713
- `line_count`: 8
- `sha256`: a28a5199366533cf394ec20902f6914ba615d7d7107defd26d49a36b13b54f7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=713 bytes; lines=8; FAIL=6; PASS=2; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 26943
- `line_count`: 143
- `sha256`: 94c96c63f41fb50365f602cf99ad4ffc26eb192c55a7f8f0d9b50a03d1a36e32
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=26943 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/focused/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 876
- `line_count`: 10
- `sha256`: b36a13cb46eab8a901c2c360d9f78b5ec18b92cf51330cf7c676dc2bcaca5591
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=876 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/full-functional.log

- `kind`: log
- `size_bytes`: 12714
- `line_count`: 114
- `sha256`: 8b835124c5c60bbe05619e5b8b6c63b13d36bc8c29d215f2af51cb540383cd25
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 52}
- `summary`: log evidence; size=12714 bytes; lines=114; PASS=52; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 14 tests in 5.008s OK [PRODUCER-HOLDER-CENSUS] PASS direct=20 packed=5 token_q=15 generation=1 [V8L-CENSUS-EVIDENCE][P...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-run.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 9
- `sha256`: 2d0c54a687db371bf27386b13a001aa823010f4b4ee587ea4ef00c6c6dff5a20
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=549 bytes; lines=9; PASS=2; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2-run.log

- `kind`: log
- `size_bytes`: 4098
- `line_count`: 126
- `sha256`: a000529af813e670804f0bcdf9e9673395d64b0a7b7fc5d8b55f62c34091f057
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 224}
- `summary`: log evidence; size=4098 bytes; lines=126; PASS=224; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: b1957764742c93472fc08e624b94c7a22b64dd163fa0b19e79282396f2a02b9b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 378
- `line_count`: 5
- `sha256`: be261126878f4bc4576d6727e50da81741b094b494c7072f847044567379be2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=378 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3588
- `line_count`: 29
- `sha256`: 545544299150cc52e05bbf1095df040db026184aa462f761e21a4c5c6c1a7c31
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3588 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 6
- `sha256`: df213ae1a2067592747405f6b90f344dd9525cec76bb5281d1755505ecd3217d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 575
- `line_count`: 6
- `sha256`: 1af3d72eaae0ac22c3da73047166b963a67d04dd67584dcbf3c938c026dee570
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=575 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o build/tb_axi_reset_syscon.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 59ef82b8d34c4d8e27ccd43f2469d2b2ef223c76815ff75606d1b6f620166254
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3372
- `line_count`: 29
- `sha256`: c8c3973597ff9230435a01d17e502abb49a0dff715a7dba16c0ecb08e4e2f0f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3372 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 2c503bd326818184d2b1f1be9f40f21db6215f83a8285e04c2f9b7bb02f1c961
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 2670cb20833e600b0754d91ed56eb79d1ed95bb0800c7c7c1d4b0a4b478f6bf0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_csr_file_vectored_trap.log

- `kind`: log
- `size_bytes`: 558
- `line_count`: 6
- `sha256`: d0020358e5610e330318a458f7ea182742092c7d13bfe0f70d894ff233a30a93
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=558 bytes; lines=6; PASS=6; tail=[TEST] tb_csr_file_vectored_trap [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file_vectored_trap -o build/tb_csr_file_vectored_trap.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 517
- `line_count`: 5
- `sha256`: 367d249905a68691c71fe6fe0072ee17f5e089c0c0ac85e8bf52c47387179fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=517 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 392
- `line_count`: 5
- `sha256`: c1dc97ba3db259094dc1268f339392ba1392f12d36ad147c1b5183de482900da
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=392 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: 536593a2986b02a57a9f06b2f4242213fb1045983476476b18cdc07b612656d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 8433c1fc6059f3929b56a3c521ed17053d06e69401d1c9b38151e50706b8b416
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: 54c2554d7a36acdac73e1768138fcd3159c536668ccffcfef72ff9b87daa04b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: 59b3e93a84574ed8a68596cdb3a36bffdc72fef262686e7828d77c94ccef48ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31371
- `line_count`: 208
- `sha256`: c35fed7c68d7b554a4a74971e9679c8ce1f194618cf8ebe5bcd87ddf5dba7606
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31371 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31551
- `line_count`: 206
- `sha256`: 43a24a13958259cc126b30060a7e9eb6220b02d2460f52906a781dadad9b59f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31551 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: e549c4056e20ab72811dfc9c47c6b20f3066c487c3697ea9e842a43d49e86606
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: 3b27f9ad22a87aa6940e886d4249e2267613f2ce27ae4b3ffb4537eb23fef8d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 429
- `line_count`: 5
- `sha256`: 4d48359cddc629cdade390f3a1a0b403652543beaa9651806dec3a2f7f3edc6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=429 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 854
- `line_count`: 9
- `sha256`: c520cb75bcfd63fe15454d422e6d598645b8e6ea79f9981110f3a50f851a4bf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=854 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 256b27ecb18309910a09d2b3be757d374b2254497f01143f39332414a1490137
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 592
- `line_count`: 5
- `sha256`: 7da97a0c074bccbab360ed71a5ee7c4ead6e95772afd81c22969446fc1ba31e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=592 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 864
- `line_count`: 9
- `sha256`: 77345ec0fa88f87d183330364080d269ab7c668135d10b8e2a96d32a6e7897bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=864 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: c24dd3c2c3ecd96ff06d089b964f92b58d75cc9ea44ab4922ecc1e684098e6ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 6
- `sha256`: a2d985b68077d49c6728bccb1834a8f82ae585b94de6e68c73bb298f2276eff7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: 710aa66305c2cd074845a62f3d710c8d293d67d790b015a003f2118a13aaf761
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 767
- `line_count`: 9
- `sha256`: 552b5195201f3ef0241e123244bab3d1838dbf357c573805cb909c6c17528e90
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=767 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 832
- `line_count`: 9
- `sha256`: 26e398fdfd41dd5d9d578e6c0bca079096ed70e64868bcf6fa05bc379c01fa5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=832 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_control_event_apply_sequencer.log

- `kind`: log
- `size_bytes`: 845
- `line_count`: 9
- `sha256`: e2f1f43eae7d4d03ae09391701286dccc57883bc94ac8952a04c99e47f0ac166
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=845 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_event_apply_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_event_apply_sequencer -o build/tb_ooo_control...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 819
- `line_count`: 9
- `sha256`: d5a7457dc28a78f162aa59ca5fa211a3dfa362ef49f52d9a9e293838b0aafb39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=819 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25360
- `line_count`: 140
- `sha256`: af1351a202e1547e9e99d971ff91d753161db7892427b52a11c7884130287542
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25360 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 497
- `line_count`: 5
- `sha256`: 1bee761c3b68c282b2aaa18db9d83e6a10a8539a48a64507fa2654f0c2d47521
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=497 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 6
- `sha256`: 93e90865fc39568a97e244016a1e6f45ea247c56de656f580fb3a1ad2e7e9c39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=560 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 575
- `line_count`: 5
- `sha256`: cba3272715db5aaf78693f205fbd71e1fdceb2f16aa68db35104d94b7f8a48f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=575 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 505
- `line_count`: 5
- `sha256`: 54110839857f1b66cc746489945d814ce5a4632dc43219d0f00fd4e1d174370f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=505 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: fb829741805185903307404ee0c6a74cab60e1dfa142bf7d29c87b798c40708c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: 002c170c64fa564bf1d2d05076f3858ff9e5987abcd2e4333225d3c9d66d3739
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 40
- `sha256`: f70ce405d85d2ca50438779acdc1147c06a3b36887fb4f76231f8900a649bbf0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5701 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 306318
- `line_count`: 2296
- `sha256`: 59db1889a66b3d87430d069914ef30906c46b455434be1260b3c73cd9e11fec0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=306318 bytes; lines=2296; PASS=2; tail=orkbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 114176
- `line_count`: 944
- `sha256`: b5aff8e4564ac2b0a414cff0ba6f2e3bb6103034bd5c9f35fd2f61c2021e9f45
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 159}
- `summary`: log evidence; size=114176 bytes; lines=944; PASS=159; tail=yx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103724
- `line_count`: 780
- `sha256`: 3120d1afed9f2677addbd45264279a8efc8fc645ffd94a39cf5e301790e16530
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=103724 bytes; lines=780; PASS=3; tail=ing: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105239
- `line_count`: 794
- `sha256`: b83d11e6dcc19f98a00292c768af3aa556f312a10627951c97cdf1bfa559e056
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=105239 bytes; lines=794; PASS=3; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106655
- `line_count`: 803
- `sha256`: 6acb63a8d9dd1fde0d79ac8eec1177aa5ebccf585221c61934552df7951d4524
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=106655 bytes; lines=803; PASS=3; tail=/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: 7fa7a59bbe7e2080a5931132f3ac99b6e7e3104bfe762af73e393a8dedaf23e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build/tb_ooo_fetch_branch_target.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: 0147bb0fb5e65db2a4c17114e70bef86f01b5f977f19c87f7634eeca8bf4b22a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 734
- `line_count`: 6
- `sha256`: 250ba8239837eacbbd1aa0fddf61dd8e61e96c613668df268020361d3d7b31f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=734 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 686
- `line_count`: 5
- `sha256`: cb8204fc3114ec825b983c60d52a1c262fb15eb8d889d3cb08196aac994c9cf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=686 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: eec3c6cd7d8e94d20e2729ee6eab9eaaf49fb077899f08ca00503ef586865809
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 725
- `line_count`: 8
- `sha256`: e7a6aeae1842e9ee655b4f54c32b4862dac91d771a208152e2a3b6e3bb8478b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=725 bytes; lines=8; PASS=8; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1132
- `line_count`: 14
- `sha256`: 8020c3c6b42bf0c1a1ba8d25fe22cd66af2f69fd06d5605610aedd3b093c83af
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1132 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: d775dd1a44e6c0b432a42d22ea6db32d12eba68868c457b318ac6afada6d19e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: d2b3f4a9efd1bde954e54128b6df97377da6706251d56af09d1322f019d86ad3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 108074
- `line_count`: 818
- `sha256`: d1024d7fe5901fd0d11a3bd499d9a674c0bbcb26cfc602ab8f34e776bf2dbeb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=108074 bytes; lines=818; PASS=16; tail=v64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 5
- `sha256`: 0aca4aa7c98ec5ac3e3c9e21cb2810e71be9f284c6a1a074f11f86dc1d2f5818
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=529 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 46ce81c918cf7e7f8e964ee0b3489a32b1c07b93b0a9e4bc2aa710cc30d548d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 964
- `line_count`: 10
- `sha256`: 84ae8fac64ee63c8037b61df0a816f9fcd67e289e633187be668f9dd21e90c24
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=964 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o build/tb_ooo_fetch_static_classify.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34378
- `line_count`: 198
- `sha256`: 0c45fe6322e07b4870ed1434daae1fdde6730ddfb62ebdffd5e735180bbd29bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34378 bytes; lines=198; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 428
- `line_count`: 5
- `sha256`: 2ed161a84bd963ddc5bc3af247866e2d2e7b1533e9091b34de074a1cea59e4fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=428 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: 804b4f06b9def87e7e56d1bf941bcd5816d52624c94354118eb4a39c4478137f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 878e2f552658a6ed3b329348f3e28af67163bb966f70820bab4b8d6ecf53fd7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 350277e6107c56892d3b5444b5808c9ddf61e89e4ffcdb473a2e4e45b841b799
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3934
- `line_count`: 38
- `sha256`: 3369b5639e4bc30e4a6a769a0049250044962d33e9576d11e892e686738986e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3934 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 4c0f0e8d61e9fe572fc0e7440b6cde8e2b517105408f67e9c1392b3ef14b1389
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1767
- `line_count`: 15
- `sha256`: 1271b9b912b9390ae6d2803bed474581173d241da231edd91836bfe3223f5664
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1767 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 570
- `line_count`: 5
- `sha256`: 0b60c7a68130ba088f18e8727139507df3f803f734b5c6a834cb3b63d4a78294
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=570 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 977
- `line_count`: 12
- `sha256`: 9c4ed8c2b7050c3654b4eb789e499c23c4324cf890957fdbd1d0cf68c521a965
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=977 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 724
- `line_count`: 9
- `sha256`: dad5ce0063e1501e27d72dfb0882a75560223d659bf06b0284a886e71d589fc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=724 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 420
- `line_count`: 5
- `sha256`: 0e49365e53ffe21060af2c55ab22225de72325d3d1088ffa9d4fd924a1876ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=420 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: be4527734364f1bb43284b72b048c85e5be38ac25e9e775b0b317275814812f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 470
- `line_count`: 5
- `sha256`: dc431c45a21a7ad688d772d083feaceb6ff29ab44c115bf427430cdc717c6bff
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=470 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 878
- `line_count`: 10
- `sha256`: 204b13b96e365ae56f0beb836f65c9219d981f4f7ad5e5626cedf01ec71bdb7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=878 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 790
- `line_count`: 7
- `sha256`: d458662bfe007a8eaaf10fcf433a3a68c845e50274ffea42a3233cf96b08d911
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=790 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 3f59520cba7f23c81ae669031424a1d353605fc17fc773b06460bd3e501edd5c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: 3843754a10f8eb301fe3ab1f0947fc71c9f9ebb85e27043d77a0d43247cbdd46
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8788
- `line_count`: 83
- `sha256`: d16839107062b7c65a2c62385d3be607ef5ce86fb97c2c9dd268784fe1f16eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8788 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26666
- `line_count`: 226
- `sha256`: 32a708c5486fb784b647e255133e94e5b607b9f149b1c8fb687f7b1d17a63681
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2, "PASS": 98}
- `summary`: log evidence; size=26666 bytes; lines=226; ERROR=2; PASS=98; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11458
- `line_count`: 96
- `sha256`: c673fa611994b80b555e11811b329e4a188c1ff76c5a7965b06c188fb6028b4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11458 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 4154
- `line_count`: 35
- `sha256`: 99f911c8d683ce72ce5898a8e7838752342a444a843e3019b3f4dee145d46ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4154 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o build/tb_ooo_load_queue.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 822
- `line_count`: 10
- `sha256`: 9fbc53a873e8723b3eb61f2166d92fc0d3c333a5bace40bfe5c1910b01a1f8c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=822 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o build/tb_ooo_lsu_axi_lane_adapter.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74577
- `line_count`: 572
- `sha256`: e44ecd28df2ad11dbf2930c5b26e8b2d206e9acb941584656849e8f6f8cabae1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74577 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1325
- `line_count`: 12
- `sha256`: 2d6aa856dcddea472b6ffd29266fc26eaaf15a08354d9be898bf62b43fa8f642
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1325 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o build/tb_ooo_mem_inflight_queue.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 11
- `sha256`: af49d4265b4c034f092ba1f9906b428a494d3af573a778e8fd84d19ab1f131a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=976 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o build/tb_ooo_mem_owner...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1290
- `line_count`: 14
- `sha256`: 4e1a375a35d7527970124618d217e0553fb3f221df6dd638ff59f94766f3e418
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1290 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o build/tb_ooo_mem_owner_tracker.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 922
- `line_count`: 8
- `sha256`: f385b3cb093735c1a898735eb83870802cb851ebfbeab8f3ff8ccceda715d98d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=922 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 677
- `line_count`: 8
- `sha256`: 749f54ca0468373bceb0f1b02acb355fddc189ce240d3cfda798afca514ec74f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=677 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o build/tb_ooo_mmu_epoch_owner.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 420
- `line_count`: 5
- `sha256`: a7598177a68c681c43ab65b3a7e4b1096248f9e8023574fb6ab5a16120a0a4f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=420 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1146
- `line_count`: 12
- `sha256`: dda343028a4a0003b597afc715471732e6f994fb7d78139f53e0fe7d749815ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1146 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: d5b585f90d78dc32d6ae463e58ad257cc999a008503d929b501733e351792618
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build/tb_ooo_pending_drain...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 934
- `line_count`: 11
- `sha256`: c48dcde55e061242f34f8fcd05078ace332babef53582b873a104d084b760543
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=934 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 961
- `line_count`: 10
- `sha256`: f548a412fb8dd3769a420a18a1dfa4a6d4a57225cfdb6042ccda11da6c7fac54
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=961 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o build/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 925
- `line_count`: 10
- `sha256`: d02b96b48547c717c176a136201f935248381419ab3198de9f0069656b75f7ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=925 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 691
- `line_count`: 7
- `sha256`: f72d44e5221895618b3f3d3214b88362f4333812f5f6a75cfe3a5be0d4e6f91a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=691 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 434
- `line_count`: 5
- `sha256`: 0466b7245fdcecb77e8b70357d51e31a17572a8154aeeb05124f553c8c8e9123
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=434 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 6
- `sha256`: cb8260d5fed4f29e81a825c40ceeea4d4ec5d89fb9d91efa3077dcbe635a9f64
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=556 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o build/tb_ooo_pma_checker.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 26943
- `line_count`: 143
- `sha256`: 94c96c63f41fb50365f602cf99ad4ffc26eb192c55a7f8f0d9b50a03d1a36e32
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=26943 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 440
- `line_count`: 5
- `sha256`: 9520ce533df6ec0e45bbd76f3cdfdad1537ae367062d83491f5b1c3ead0b51c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=440 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 446
- `line_count`: 5
- `sha256`: 57fdd27ad1af0afed5070bbd687165039dd7c88fdba97c5545244aa8a7c26f4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=446 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: e39eada2ff3eaeee7e2bd3974b87e73f10bed493c2e7fe9fd4ec5cc222a856d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=418 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1301
- `line_count`: 14
- `sha256`: d99a55b4fe36f5c22a71fef4aac926403684ff3ee782ccbcccb9058c5963ce1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=1301 bytes; lines=14; PASS=18; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/O...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 876
- `line_count`: 10
- `sha256`: b36a13cb46eab8a901c2c360d9f78b5ec18b92cf51330cf7c676dc2bcaca5591
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=876 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6814
- `line_count`: 58
- `sha256`: e9fe85bb5b215034869d475937fc4916884a382ae9af6a2360ab2ed9fd94bd00
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=6814 bytes; lines=58; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287048
- `line_count`: 2103
- `sha256`: 742818ba89c86d22cad0198b24ccd57e42233fde8e69beee67b567c923341d64
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287048 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: 6185579750487ca66a4f2258e51ba3a413a23938760d8b4a1632b2d0c1f44a82
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: 5a33ee8ad874f15ccb8fe2511be61240a46619ab498ed881bebb13955aba5848
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 576
- `line_count`: 6
- `sha256`: 71f63dfb249b1a44c6441d9d6112274b513e872da431d2acc017407e4f53077d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=576 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o build/tb_ooo_typed_memory_classi...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: ff7a8292bd58ed94f9da3919a33869629accf310bd741097b27fdebdf04062b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17538
- `line_count`: 134
- `sha256`: db7f8b7763ad2df8f90622bc099eb9ec11096953a01e0a57c053263043c335f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17538 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 5
- `sha256`: 857ba22e03ab8db828b31f0c1b80da79244207c57b4663b9ff3fea212f695a32
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=349 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 5
- `sha256`: 1d04fd66ce130424f9590a7c2033fe7b52c8b6031d341ccd115b5cc8b8cc2151
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=347 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2/summary.txt

- `kind`: txt
- `size_bytes`: 3738
- `line_count`: 120
- `sha256`: 24d9d77256818cb2224287765962175eb4074ae17379fc59f1e32d914125427a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 222}
- `summary`: txt evidence; size=3738 bytes; lines=120; PASS=222; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current-v2 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg -...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: b1957764742c93472fc08e624b94c7a22b64dd163fa0b19e79282396f2a02b9b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 378
- `line_count`: 5
- `sha256`: be261126878f4bc4576d6727e50da81741b094b494c7072f847044567379be2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=378 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3588
- `line_count`: 29
- `sha256`: 545544299150cc52e05bbf1095df040db026184aa462f761e21a4c5c6c1a7c31
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3588 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 486
- `line_count`: 6
- `sha256`: df213ae1a2067592747405f6b90f344dd9525cec76bb5281d1755505ecd3217d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=486 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 575
- `line_count`: 6
- `sha256`: 1af3d72eaae0ac22c3da73047166b963a67d04dd67584dcbf3c938c026dee570
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=575 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o build/tb_axi_reset_syscon.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 442
- `line_count`: 5
- `sha256`: 59ef82b8d34c4d8e27ccd43f2469d2b2ef223c76815ff75606d1b6f620166254
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=442 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3372
- `line_count`: 29
- `sha256`: c8c3973597ff9230435a01d17e502abb49a0dff715a7dba16c0ecb08e4e2f0f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3372 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 2c503bd326818184d2b1f1be9f40f21db6215f83a8285e04c2f9b7bb02f1c961
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 373
- `line_count`: 5
- `sha256`: 2670cb20833e600b0754d91ed56eb79d1ed95bb0800c7c7c1d4b0a4b478f6bf0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=373 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_csr_file_vectored_trap.log

- `kind`: log
- `size_bytes`: 558
- `line_count`: 6
- `sha256`: d0020358e5610e330318a458f7ea182742092c7d13bfe0f70d894ff233a30a93
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=558 bytes; lines=6; PASS=6; tail=[TEST] tb_csr_file_vectored_trap [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file_vectored_trap -o build/tb_csr_file_vectored_trap.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 517
- `line_count`: 5
- `sha256`: 367d249905a68691c71fe6fe0072ee17f5e089c0c0ac85e8bf52c47387179fa4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=517 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 392
- `line_count`: 5
- `sha256`: c1dc97ba3db259094dc1268f339392ba1392f12d36ad147c1b5183de482900da
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=392 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 362
- `line_count`: 5
- `sha256`: 536593a2986b02a57a9f06b2f4242213fb1045983476476b18cdc07b612656d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=362 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 8433c1fc6059f3929b56a3c521ed17053d06e69401d1c9b38151e50706b8b416
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: 54c2554d7a36acdac73e1768138fcd3159c536668ccffcfef72ff9b87daa04b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: 59b3e93a84574ed8a68596cdb3a36bffdc72fef262686e7828d77c94ccef48ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31371
- `line_count`: 208
- `sha256`: c35fed7c68d7b554a4a74971e9679c8ce1f194618cf8ebe5bcd87ddf5dba7606
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31371 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31551
- `line_count`: 206
- `sha256`: 43a24a13958259cc126b30060a7e9eb6220b02d2460f52906a781dadad9b59f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31551 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 397
- `line_count`: 5
- `sha256`: e549c4056e20ab72811dfc9c47c6b20f3066c487c3697ea9e842a43d49e86606
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=397 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: 3b27f9ad22a87aa6940e886d4249e2267613f2ce27ae4b3ffb4537eb23fef8d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 429
- `line_count`: 5
- `sha256`: 4d48359cddc629cdade390f3a1a0b403652543beaa9651806dec3a2f7f3edc6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=429 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 854
- `line_count`: 9
- `sha256`: c520cb75bcfd63fe15454d422e6d598645b8e6ea79f9981110f3a50f851a4bf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=854 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 256b27ecb18309910a09d2b3be757d374b2254497f01143f39332414a1490137
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 592
- `line_count`: 5
- `sha256`: 7da97a0c074bccbab360ed71a5ee7c4ead6e95772afd81c22969446fc1ba31e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=592 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 864
- `line_count`: 9
- `sha256`: 77345ec0fa88f87d183330364080d269ab7c668135d10b8e2a96d32a6e7897bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=864 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: c24dd3c2c3ecd96ff06d089b964f92b58d75cc9ea44ab4922ecc1e684098e6ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 6
- `sha256`: a2d985b68077d49c6728bccb1834a8f82ae585b94de6e68c73bb298f2276eff7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: 710aa66305c2cd074845a62f3d710c8d293d67d790b015a003f2118a13aaf761
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 767
- `line_count`: 9
- `sha256`: 552b5195201f3ef0241e123244bab3d1838dbf357c573805cb909c6c17528e90
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=767 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 832
- `line_count`: 9
- `sha256`: 26e398fdfd41dd5d9d578e6c0bca079096ed70e64868bcf6fa05bc379c01fa5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=832 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_control_event_apply_sequencer.log

- `kind`: log
- `size_bytes`: 845
- `line_count`: 9
- `sha256`: e2f1f43eae7d4d03ae09391701286dccc57883bc94ac8952a04c99e47f0ac166
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=845 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_event_apply_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_event_apply_sequencer -o build/tb_ooo_control...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 819
- `line_count`: 9
- `sha256`: d5a7457dc28a78f162aa59ca5fa211a3dfa362ef49f52d9a9e293838b0aafb39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=819 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25360
- `line_count`: 140
- `sha256`: af1351a202e1547e9e99d971ff91d753161db7892427b52a11c7884130287542
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25360 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 497
- `line_count`: 5
- `sha256`: 1bee761c3b68c282b2aaa18db9d83e6a10a8539a48a64507fa2654f0c2d47521
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=497 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 6
- `sha256`: 93e90865fc39568a97e244016a1e6f45ea247c56de656f580fb3a1ad2e7e9c39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=560 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 575
- `line_count`: 5
- `sha256`: cba3272715db5aaf78693f205fbd71e1fdceb2f16aa68db35104d94b7f8a48f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=575 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 505
- `line_count`: 5
- `sha256`: 54110839857f1b66cc746489945d814ce5a4632dc43219d0f00fd4e1d174370f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=505 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: fb829741805185903307404ee0c6a74cab60e1dfa142bf7d29c87b798c40708c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: 002c170c64fa564bf1d2d05076f3858ff9e5987abcd2e4333225d3c9d66d3739
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 40
- `sha256`: f70ce405d85d2ca50438779acdc1147c06a3b36887fb4f76231f8900a649bbf0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5701 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 306318
- `line_count`: 2296
- `sha256`: 59db1889a66b3d87430d069914ef30906c46b455434be1260b3c73cd9e11fec0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=306318 bytes; lines=2296; PASS=2; tail=orkbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 114176
- `line_count`: 944
- `sha256`: b5aff8e4564ac2b0a414cff0ba6f2e3bb6103034bd5c9f35fd2f61c2021e9f45
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 159}
- `summary`: log evidence; size=114176 bytes; lines=944; PASS=159; tail=yx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103724
- `line_count`: 780
- `sha256`: 3120d1afed9f2677addbd45264279a8efc8fc645ffd94a39cf5e301790e16530
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=103724 bytes; lines=780; PASS=3; tail=ing: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105239
- `line_count`: 794
- `sha256`: b83d11e6dcc19f98a00292c768af3aa556f312a10627951c97cdf1bfa559e056
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=105239 bytes; lines=794; PASS=3; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106655
- `line_count`: 803
- `sha256`: 6acb63a8d9dd1fde0d79ac8eec1177aa5ebccf585221c61934552df7951d4524
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=106655 bytes; lines=803; PASS=3; tail=/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 466
- `line_count`: 5
- `sha256`: 7fa7a59bbe7e2080a5931132f3ac99b6e7e3104bfe762af73e393a8dedaf23e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=466 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o build/tb_ooo_fetch_branch_target.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 458
- `line_count`: 5
- `sha256`: 0147bb0fb5e65db2a4c17114e70bef86f01b5f977f19c87f7634eeca8bf4b22a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=458 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 734
- `line_count`: 6
- `sha256`: 250ba8239837eacbbd1aa0fddf61dd8e61e96c613668df268020361d3d7b31f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=734 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 686
- `line_count`: 5
- `sha256`: cb8204fc3114ec825b983c60d52a1c262fb15eb8d889d3cb08196aac994c9cf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=686 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: eec3c6cd7d8e94d20e2729ee6eab9eaaf49fb077899f08ca00503ef586865809
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 725
- `line_count`: 8
- `sha256`: e7a6aeae1842e9ee655b4f54c32b4862dac91d771a208152e2a3b6e3bb8478b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=725 bytes; lines=8; PASS=8; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1132
- `line_count`: 14
- `sha256`: 8020c3c6b42bf0c1a1ba8d25fe22cd66af2f69fd06d5605610aedd3b093c83af
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1132 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: d775dd1a44e6c0b432a42d22ea6db32d12eba68868c457b318ac6afada6d19e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: d2b3f4a9efd1bde954e54128b6df97377da6706251d56af09d1322f019d86ad3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 108074
- `line_count`: 818
- `sha256`: d1024d7fe5901fd0d11a3bd499d9a674c0bbcb26cfc602ab8f34e776bf2dbeb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=108074 bytes; lines=818; PASS=16; tail=v64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 529
- `line_count`: 5
- `sha256`: 0aca4aa7c98ec5ac3e3c9e21cb2810e71be9f284c6a1a074f11f86dc1d2f5818
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=529 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 46ce81c918cf7e7f8e964ee0b3489a32b1c07b93b0a9e4bc2aa710cc30d548d3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 964
- `line_count`: 10
- `sha256`: 84ae8fac64ee63c8037b61df0a816f9fcd67e289e633187be668f9dd21e90c24
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=964 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o build/tb_ooo_fetch_static_classify.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34378
- `line_count`: 198
- `sha256`: 0c45fe6322e07b4870ed1434daae1fdde6730ddfb62ebdffd5e735180bbd29bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34378 bytes; lines=198; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 428
- `line_count`: 5
- `sha256`: 2ed161a84bd963ddc5bc3af247866e2d2e7b1533e9091b34de074a1cea59e4fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=428 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: 804b4f06b9def87e7e56d1bf941bcd5816d52624c94354118eb4a39c4478137f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 878e2f552658a6ed3b329348f3e28af67163bb966f70820bab4b8d6ecf53fd7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 350277e6107c56892d3b5444b5808c9ddf61e89e4ffcdb473a2e4e45b841b799
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 3934
- `line_count`: 38
- `sha256`: 3369b5639e4bc30e4a6a769a0049250044962d33e9576d11e892e686738986e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3934 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o build/tb_ooo_fp_issue_queue.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 4c0f0e8d61e9fe572fc0e7440b6cde8e2b517105408f67e9c1392b3ef14b1389
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1767
- `line_count`: 15
- `sha256`: 1271b9b912b9390ae6d2803bed474581173d241da231edd91836bfe3223f5664
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1767 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 570
- `line_count`: 5
- `sha256`: 0b60c7a68130ba088f18e8727139507df3f803f734b5c6a834cb3b63d4a78294
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=570 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 977
- `line_count`: 12
- `sha256`: 9c4ed8c2b7050c3654b4eb789e499c23c4324cf890957fdbd1d0cf68c521a965
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=977 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o build/tb_ooo_fp_phys_reg_file.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 724
- `line_count`: 9
- `sha256`: dad5ce0063e1501e27d72dfb0882a75560223d659bf06b0284a886e71d589fc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=724 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 420
- `line_count`: 5
- `sha256`: 0e49365e53ffe21060af2c55ab22225de72325d3d1088ffa9d4fd924a1876ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=420 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 412
- `line_count`: 5
- `sha256`: be4527734364f1bb43284b72b048c85e5be38ac25e9e775b0b317275814812f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=412 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 470
- `line_count`: 5
- `sha256`: dc431c45a21a7ad688d772d083feaceb6ff29ab44c115bf427430cdc717c6bff
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=470 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 878
- `line_count`: 10
- `sha256`: 204b13b96e365ae56f0beb836f65c9219d981f4f7ad5e5626cedf01ec71bdb7e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=878 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 790
- `line_count`: 7
- `sha256`: d458662bfe007a8eaaf10fcf433a3a68c845e50274ffea42a3233cf96b08d911
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=790 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 452
- `line_count`: 5
- `sha256`: 3f59520cba7f23c81ae669031424a1d353605fc17fc773b06460bd3e501edd5c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=452 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 464
- `line_count`: 5
- `sha256`: 3843754a10f8eb301fe3ab1f0947fc71c9f9ebb85e27043d77a0d43247cbdd46
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=464 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8788
- `line_count`: 83
- `sha256`: d16839107062b7c65a2c62385d3be607ef5ce86fb97c2c9dd268784fe1f16eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8788 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26666
- `line_count`: 226
- `sha256`: 32a708c5486fb784b647e255133e94e5b607b9f149b1c8fb687f7b1d17a63681
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2, "PASS": 98}
- `summary`: log evidence; size=26666 bytes; lines=226; ERROR=2; PASS=98; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11458
- `line_count`: 96
- `sha256`: c673fa611994b80b555e11811b329e4a188c1ff76c5a7965b06c188fb6028b4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11458 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 4154
- `line_count`: 35
- `sha256`: 99f911c8d683ce72ce5898a8e7838752342a444a843e3019b3f4dee145d46ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4154 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o build/tb_ooo_load_queue.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 822
- `line_count`: 10
- `sha256`: 9fbc53a873e8723b3eb61f2166d92fc0d3c333a5bace40bfe5c1910b01a1f8c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=822 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o build/tb_ooo_lsu_axi_lane_adapter.vvp...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74577
- `line_count`: 572
- `sha256`: e44ecd28df2ad11dbf2930c5b26e8b2d206e9acb941584656849e8f6f8cabae1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74577 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1325
- `line_count`: 12
- `sha256`: 2d6aa856dcddea472b6ffd29266fc26eaaf15a08354d9be898bf62b43fa8f642
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1325 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o build/tb_ooo_mem_inflight_queue.vvp /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 11
- `sha256`: af49d4265b4c034f092ba1f9906b428a494d3af573a778e8fd84d19ab1f131a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=976 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o build/tb_ooo_mem_owner...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1290
- `line_count`: 14
- `sha256`: 4e1a375a35d7527970124618d217e0553fb3f221df6dd638ff59f94766f3e418
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1290 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o build/tb_ooo_mem_owner_tracker.vvp /home/lyg...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 922
- `line_count`: 8
- `sha256`: f385b3cb093735c1a898735eb83870802cb851ebfbeab8f3ff8ccceda715d98d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=922 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 677
- `line_count`: 8
- `sha256`: 749f54ca0468373bceb0f1b02acb355fddc189ce240d3cfda798afca514ec74f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=677 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o build/tb_ooo_mmu_epoch_owner.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 420
- `line_count`: 5
- `sha256`: a7598177a68c681c43ab65b3a7e4b1096248f9e8023574fb6ab5a16120a0a4f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=420 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1146
- `line_count`: 12
- `sha256`: dda343028a4a0003b597afc715471732e6f994fb7d78139f53e0fe7d749815ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1146 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: d5b585f90d78dc32d6ae463e58ad257cc999a008503d929b501733e351792618
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o build/tb_ooo_pending_drain...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 934
- `line_count`: 11
- `sha256`: c48dcde55e061242f34f8fcd05078ace332babef53582b873a104d084b760543
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=934 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 961
- `line_count`: 10
- `sha256`: f548a412fb8dd3769a420a18a1dfa4a6d4a57225cfdb6042ccda11da6c7fac54
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=961 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o build/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 925
- `line_count`: 10
- `sha256`: d02b96b48547c717c176a136201f935248381419ab3198de9f0069656b75f7ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=925 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 691
- `line_count`: 7
- `sha256`: f72d44e5221895618b3f3d3214b88362f4333812f5f6a75cfe3a5be0d4e6f91a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=691 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 434
- `line_count`: 5
- `sha256`: 0466b7245fdcecb77e8b70357d51e31a17572a8154aeeb05124f553c8c8e9123
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=434 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 6
- `sha256`: cb8260d5fed4f29e81a825c40ceeea4d4ec5d89fb9d91efa3077dcbe635a9f64
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=556 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o build/tb_ooo_pma_checker.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 70
- `line_count`: 2
- `sha256`: e2ce03755e8c4954e4cb5a993dfeaf459361cf4e4edfd2b37819dc2b57adbb44
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: log evidence; size=70 bytes; lines=2; FAIL=2; PASS=2; tail=missing exact PASS line for tb_ooo_priv_system [RESULT] FAIL status=1

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 440
- `line_count`: 5
- `sha256`: 9520ce533df6ec0e45bbd76f3cdfdad1537ae367062d83491f5b1c3ead0b51c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=440 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 446
- `line_count`: 5
- `sha256`: 57fdd27ad1af0afed5070bbd687165039dd7c88fdba97c5545244aa8a7c26f4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=446 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 5
- `sha256`: e39eada2ff3eaeee7e2bd3974b87e73f10bed493c2e7fe9fd4ec5cc222a856d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=418 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1301
- `line_count`: 14
- `sha256`: d99a55b4fe36f5c22a71fef4aac926403684ff3ee782ccbcccb9058c5963ce1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=1301 bytes; lines=14; PASS=18; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/control/O...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 876
- `line_count`: 10
- `sha256`: b36a13cb46eab8a901c2c360d9f78b5ec18b92cf51330cf7c676dc2bcaca5591
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=876 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6814
- `line_count`: 58
- `sha256`: e9fe85bb5b215034869d475937fc4916884a382ae9af6a2360ab2ed9fd94bd00
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=6814 bytes; lines=58; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287048
- `line_count`: 2103
- `sha256`: 742818ba89c86d22cad0198b24ccd57e42233fde8e69beee67b567c923341d64
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287048 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 476
- `line_count`: 5
- `sha256`: 6185579750487ca66a4f2258e51ba3a413a23938760d8b4a1632b2d0c1f44a82
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=476 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 525
- `line_count`: 5
- `sha256`: 5a33ee8ad874f15ccb8fe2511be61240a46619ab498ed881bebb13955aba5848
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=525 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 576
- `line_count`: 6
- `sha256`: 71f63dfb249b1a44c6441d9d6112274b513e872da431d2acc017407e4f53077d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=576 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o build/tb_ooo_typed_memory_classi...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: ff7a8292bd58ed94f9da3919a33869629accf310bd741097b27fdebdf04062b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17538
- `line_count`: 134
- `sha256`: db7f8b7763ad2df8f90622bc099eb9ec11096953a01e0a57c053263043c335f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17538 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 349
- `line_count`: 5
- `sha256`: 857ba22e03ab8db828b31f0c1b80da79244207c57b4663b9ff3fea212f695a32
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=349 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 347
- `line_count`: 5
- `sha256`: 1d04fd66ce130424f9590a7c2033fe7b52c8b6031d341ccd115b5cc8b8cc2151
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=347 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current/summary.txt

- `kind`: txt
- `size_bytes`: 3735
- `line_count`: 120
- `sha256`: 2bbed939b3c43022e9286253dc757c13a58da172b1ff0e6091e138e3a20b45f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 220}
- `summary`: txt evidence; size=3735 bytes; lines=120; FAIL=2; PASS=220; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-current - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PAS...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25360
- `line_count`: 140
- `sha256`: af1351a202e1547e9e99d971ff91d753161db7892427b52a11c7884130287542
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25360 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8788
- `line_count`: 83
- `sha256`: d16839107062b7c65a2c62385d3be607ef5ce86fb97c2c9dd268784fe1f16eec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8788 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1146
- `line_count`: 12
- `sha256`: dda343028a4a0003b597afc715471732e6f994fb7d78139f53e0fe7d749815ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1146 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 925
- `line_count`: 10
- `sha256`: d02b96b48547c717c176a136201f935248381419ab3198de9f0069656b75f7ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=925 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 691
- `line_count`: 7
- `sha256`: f72d44e5221895618b3f3d3214b88362f4333812f5f6a75cfe3a5be0d4e6f91a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=691 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 26943
- `line_count`: 143
- `sha256`: 94c96c63f41fb50365f602cf99ad4ffc26eb192c55a7f8f0d9b50a03d1a36e32
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=26943 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/module-testbench/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 876
- `line_count`: 10
- `sha256`: b36a13cb46eab8a901c2c360d9f78b5ec18b92cf51330cf7c676dc2bcaca5591
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=876 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/green/rtl-static-checks.log

- `kind`: log
- `size_bytes`: 543
- `line_count`: 10
- `sha256`: 553831c44e59aa6fc92183764930070de25778f53270815e7d9db3bc339babc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=543 bytes; lines=10; PASS=6; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 ---------------------------------------------------------------------- Ran 14 tests in 5.032s OK [PRODUCER-HOLDER-CE...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 6356106
- `line_count`: 144798
- `sha256`: 3c3045e2274459460912b7b3684a1b4cc3cd44fac977adb62f71f6326d17922f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 1}
- `summary`: vvp evidence; size=6356106 bytes; lines=144798; PASS=1; tail=%pushi/vec4 1635085428, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543711598, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1684825458, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543520873...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/build/tb_ooo_core_top_glue_v9o_csr_qh.vvp

- `kind`: vvp
- `size_bytes`: 5918856
- `line_count`: 133550
- `sha256`: 24ca813b55e91a357cf3e3f3de620b577c68d348072847e8badcc5448d110927
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=5918856 bytes; lines=133550; PASS=2; tail=vec4 %pushi/vec4 1667786099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543319398, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1869767968, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1245...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 696839
- `line_count`: 15284
- `sha256`: 54c89dbe3f9dcffe1c728e601fb52d8df6fb9350fcf5397ba40bc7f46431f36b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 6}
- `summary`: vvp evidence; size=696839 bytes; lines=15284; FAIL=3; PASS=6; tail=v0x5e6088d40280_0, 0, 2; %pushi/vec4 0, 0, 1; %store/vec4 v0x5e6088d17de0_0, 0, 1; %fork TD_tb_ooo_ifu_lane1_fault_owner.run_tval_lifecycle_row, S_0x5e6088b7d070; %join; %free S_0x5e6088b7d070; %alloc S_0x5e6088b7d070; %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 28463
- `line_count`: 854
- `sha256`: 160ee1f2b9bcbc14ebb1ca40b8f7cf4b252d76bda50d85e7045d493fdd97fd4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: vvp evidence; size=28463 bytes; lines=854; FAIL=2; PASS=6; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6377586
- `line_count`: 146431
- `sha256`: 2d1d2c0c740d3b9a619a915259c711e6e171bb52550211747a0db650360762f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6377586 bytes; lines=146431; FAIL=3; PASS=2; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 66064
- `line_count`: 1798
- `sha256`: f3425b5da4af0191514b3e5b04ad177da2496c58df0cc81746a7b049cba7eedd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 3}
- `summary`: vvp evidence; size=66064 bytes; lines=1798; FAIL=3; PASS=3; tail=8bc2392ac0 .scope module, "tb_ooo_stop_pending_sequencer" "tb_ooo_stop_pending_sequencer" 3 4; .timescale -9 -12; v0x648bc23b3ec0_0 .var "branch_resolve_untracked", 0 0; v0x648bc23b3f80_0 .var "branch_spec_checkpoint_capture", 0 0; v0x648bc23b4020_0 .var "b...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/final-flag-on/build/tb_ooo_core_top_glue_v9o_csr_qh.vvp

- `kind`: vvp
- `size_bytes`: 5919217
- `line_count`: 133561
- `sha256`: 1f242bb0fe5f8947ebeee2e4fc314f1670682b03d9fb4d21c23b52f73b1a36ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=5919217 bytes; lines=133561; PASS=2; tail=vec4 %pushi/vec4 1667786099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543319398, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1869767968, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1245...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/final-flag-on/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log

- `kind`: log
- `size_bytes`: 25840
- `line_count`: 145
- `sha256`: c2dd45ed43e78bf76e1ecaf18308a541625578e7e138b2b52d029903a3fd2e65
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=25840 bytes; lines=145; PASS=20; tail=[TEST] tb_ooo_core_top_glue_v9o_csr_qh [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DV9O_CSR_QH_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/full-functional.log

- `kind`: log
- `size_bytes`: 12714
- `line_count`: 114
- `sha256`: 4778f79c0eab3d641b65e46537355556324d9f5c94649266c9aa7a80de884e22
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 52}
- `summary`: log evidence; size=12714 bytes; lines=114; PASS=52; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' ---------------------------------------------------------------------- Ran 14 tests in 4.984s OK [PRODUCER-HOLDER-CENSUS] PASS direct=20 packed=5 token_q=15 generation=1 [V8L-CENSUS-EVIDENCE][P...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 48967
- `line_count`: 1322
- `sha256`: 49a513b1c4b049e56ba00de2efaf93b7927710f498508baa78291c6a73a8fa6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48967 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 276271
- `line_count`: 7135
- `sha256`: 333677fdf1f725e4614d5203b131d9163bf20d26f8e13764651a8d603f149cc6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=276271 bytes; lines=7135; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 219285
- `line_count`: 5754
- `sha256`: 4b8a12a172d8446c297fe91b06f45ac50a0d1e9161538dc858eac6e401ab063b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=219285 bytes; lines=5754; FAIL=3; PASS=2; tail=, S_0x5df5eba395b0; %join; %free S_0x5df5eba395b0; %alloc S_0x5df5eb993550; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %p...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 905889
- `line_count`: 16698
- `sha256`: 4247eda5735ac40165de583e008194cae99c5fd8239cfc7058ad45629885e223
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=905889 bytes; lines=16698; markers=<none>; tail=ng_vec4 %pushi/vec4 1919513701, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544566893, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1634954099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 5...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_axi_reset_syscon.vvp

- `kind`: vvp
- `size_bytes`: 169874
- `line_count`: 4395
- `sha256`: 36725750b4b19cde83f97772e0595fafbc49013b99242bcb23fb38e8276227f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=169874 bytes; lines=4395; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 1751738216, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 541204578, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701015405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 151922
- `line_count`: 4004
- `sha256`: 82988644bfccca6cce02ded4c1ed26c9c18a1533df1670ed2015a015f7b8eafe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=151922 bytes; lines=4004; FAIL=3; PASS=1; tail=, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x62817a2939e0_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x62817a293770_0, 0, 32; %pushi/vec4 2, 0, 3; %store/vec4 v0x62817a293910_0, 0, 3; %pushi/vec4 0, 0, 1; %store/vec4 v0x62817a294980_0, 0, 1; %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 314045
- `line_count`: 8462
- `sha256`: 085e8c7ca79d554d6f296c69645bd0fd6301b7c7e9fe6ef2b0e16b380b052653
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=314045 bytes; lines=8462; FAIL=3; PASS=2; tail=g_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32438
- `line_count`: 864
- `sha256`: c2a3376c4912ece940f0ce43d2aa06eb8d8785f6aa6c344730202917b221c5ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32438 bytes; lines=864; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 581129
- `line_count`: 14244
- `sha256`: fb966c83d1352e2029fb54e41c032e75199b8d81f70c196d501f958aae160318
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=581129 bytes; lines=14244; markers=<none>; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1702000233, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1936683552, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_csr_file_vectored_trap.vvp

- `kind`: vvp
- `size_bytes`: 355728
- `line_count`: 8239
- `sha256`: f27245e9bbbad47ab77932bd98330feede0fd82bbde4464104aaf5a9361ee131
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=355728 bytes; lines=8239; FAIL=2; PASS=1; tail=%pushi/vec4 66, 0, 64; %store/vec4 v0x5e9265343840_0, 0, 64; %fork TD_tb_csr_file_vectored_trap.check64, S_0x5e9265306b40; %join; %free S_0x5e9265306b40; %alloc S_0x5e926547b090; %fork TD_tb_csr_file_vectored_trap.reset_case, S_0x5e926547b090; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112262
- `line_count`: 3912
- `sha256`: 42951872bc8a34d8f76e4adcda37c9fb3d6599a1a8c7f9818601a239725380bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112262 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x60106f1a4980_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x60106f1a4980_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274309
- `line_count`: 8084
- `sha256`: aaaebfa03afbcb765818498a47052d0d53108beff2b1f4011914760e7d41b89c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274309 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32654
- `line_count`: 892
- `sha256`: 0bb0cd6239a6272a8f910c71ed806cdfc459b7bd3b0549d4d799e3f6a3c4b13f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32654 bytes; lines=892; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 37930
- `line_count`: 983
- `sha256`: 6edcc1e889e74e00ff14dcab79a18ce128c4f26b39f3896f652bde30de6e083a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=37930 bytes; lines=983; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40314
- `line_count`: 1057
- `sha256`: ec85b9e855da02d1f1babdfdd589fe371c27fa9654b04832d675bca80554d607
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40314 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28612
- `line_count`: 748
- `sha256`: 73d4e7f49822466109f48f3e8d701dd190c1fbdef47c0c793baf57b78ef80d15
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28612 bytes; lines=748; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 3719560
- `line_count`: 86376
- `sha256`: 203193b31e9e300c66c423a8a8bd5aa86f6b619f236802148be78715d89f46bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3719560 bytes; lines=86376; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 3620243
- `line_count`: 84757
- `sha256`: f0c7110825b8f6c52d8b04db7ee5229d4e1933a118cd7bf9daa65f883de87fd3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=3620243 bytes; lines=84757; FAIL=1; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 114, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1635197028, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701864814, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39372
- `line_count`: 1135
- `sha256`: 1e8a68f1a2076a5d41f34a6737d246a77c76ffc5f8d25575ed011487c3134b0b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39372 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30684
- `line_count`: 801
- `sha256`: 2b22761cfac26628ecccd587010a037d07166d96bbe25d3b77fb619ce483641b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30684 bytes; lines=801; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 108566
- `line_count`: 3346
- `sha256`: d53f9ddee8481caa41a868aa0cbfaa4eb62ddb1fbbeec1841425f9138fc4e417
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108566 bytes; lines=3346; FAIL=5; PASS=1; tail=load/vec4 v0x55a123e2ccb0_0; %concat/vec4; draw_concat_vec4 %sub; %ix/vec4 4; %shiftl 4; %or; %jmp/0 T_22.19, 8; ; End of false expr. %blend; T_22.19; %store/vec4 v0x55a123e2e290_0, 0, 64; %jmp T_22.17; T_22.9 ; %load/vec4 v0x55a123e2ccb0_0; %cmpi/e 0, 0, 6...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 36516
- `line_count`: 758
- `sha256`: 17d923c81db74c407b71150f1bfb5376b6d06921654a2910e3285a69a647eca9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=36516 bytes; lines=758; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30029
- `line_count`: 663
- `sha256`: 5786eddec722d8360dda58b7f3a668b3f029073ec905079afae150295fa7ce5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30029 bytes; lines=663; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138036
- `line_count`: 3130
- `sha256`: a70b8ab4aab21a26e682288ac3359b9bd684aa6ec093847dcd5b009a47f25704
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138036 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5cff85dcd4b0_0, 0, 1024;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 34196
- `line_count`: 710
- `sha256`: 4959d587358734307d84ae5a6cd0bbdde9d918170b32e38dd1027cc182399c96
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34196 bytes; lines=710; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47153
- `line_count`: 1228
- `sha256`: 6a5b221e23e07f3b138c8c951e1de88b3fcf82bcd871b9718f3e4dcda4964227
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47153 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 53833
- `line_count`: 1355
- `sha256`: 32beb2aa330f84bc4d09cf698c121d6135e3ae8f8b5b1ae2a966a3f8b26d1c2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=53833 bytes; lines=1355; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 147679
- `line_count`: 3839
- `sha256`: 7206821033ee71b2503c2f2d36da5418b0ce58f6fc101874541bba044c868dfe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=147679 bytes; lines=3839; FAIL=9; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1751479072, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1380275024, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x62038655f010_0, 0, 1024; %load/vec4 v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 72082
- `line_count`: 1665
- `sha256`: f68c634612a6e57773c9998ae9c513e8901f6d242bf661de9f4cc2f85f7917dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=72082 bytes; lines=1665; FAIL=11; PASS=1; tail=.port_info 8 /INPUT 1 "synth_lane1_branch_append_i"; .port_info 9 /INPUT 64 "synth_branch_append_pc_i"; .port_info 10 /INPUT 32 "synth_branch_append_inst_i"; .port_info 11 /INPUT 64 "synth_branch_append_next_pc_i"; .port_info 12 /INPUT 1 "core_commit0_valid...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 53875
- `line_count`: 1306
- `sha256`: 03c89530b926bc4011f41b3513dff1ec0c3f6d9f33a21fd7251f7aed47202559
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53875 bytes; lines=1306; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_control_event_apply_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 23763
- `line_count`: 627
- `sha256`: 71325cba6f74bf0be5fe02b09bdb4f3fb6adb7d4279b050f036f4e2ac59ea7f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=23763 bytes; lines=627; FAIL=12; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29483
- `line_count`: 785
- `sha256`: 3b0e64892801aa5c40698a14d2760ae579d9ee3aa399c31d460e11798676acf1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29483 bytes; lines=785; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 6356106
- `line_count`: 144798
- `sha256`: b335cc95b4d252bb11f6667a7ceb6462fbf35f8d51ef326aef54b37eab7f8fbf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 1}
- `summary`: vvp evidence; size=6356106 bytes; lines=144798; PASS=1; tail=%pushi/vec4 1635085428, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543711598, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1684825458, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543520873...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: 45faace75d53fe28e78cf43ea5ae37bcf3aca7b027fe60334f298dd284974058
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34154
- `line_count`: 799
- `sha256`: 632827b6033385063b6cb777e66b583746d8b7dcc94d06374dcb8467eff6c5c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: vvp evidence; size=34154 bytes; lines=799; FAIL=4; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 401936
- `line_count`: 10153
- `sha256`: f090e75ac89121c4e82994c7328b7b42fe32857ed08bebfe5893e23c8895bc8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=401936 bytes; lines=10153; markers=<none>; tail=ing_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101127
- `line_count`: 2454
- `sha256`: 58714a9f271c5ab1925e46eff3919ce19e16d84a135ecf6c50d08f72e084be39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101127 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53579
- `line_count`: 1375
- `sha256`: b8f5847e780b376a9909fecca17b8d86b7b8544c420822380f052c6933b856d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53579 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 98854
- `line_count`: 2306
- `sha256`: d07b31ca318aca2f5f3a72a85a61eb41edeb0e598cc38899d72426b91e755274
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=98854 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 1143803
- `line_count`: 26012
- `sha256`: a4cb93e49c02ea8c02b3adb31eabc59d4fc5f9bb6701dc923bb133bc7335fae8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1143803 bytes; lines=26012; markers=<none>; tail=ore/vec4 v0x647325831360_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x647325831280_0, 0, 1; %fork TD_tb_ooo_dispatch_backend.tb_check1, S_0x6473258310a0; %join; %free S_0x6473258310a0; %pushi/vec4 1, 0, 1; %store/vec4 v0x647325832730_0, 0, 1; %pushi/vec4 1,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_dual_memory_sustained_issue.vvp

- `kind`: vvp
- `size_bytes`: 8148067
- `line_count`: 187342
- `sha256`: 444d7a41b33e4580669549a642f1acfb711550a32e4f9972b155535566034464
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=8148067 bytes; lines=187342; FAIL=10; PASS=1; tail=%nor/r; %flag_set/vec4 9; %flag_or 8, 9; T_1031.7; %jmp/1 T_1031.6, 8; %load/vec4 v0x610378cf1980_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1031.6; %jmp/1 T_1031.5, 8; %load/vec4 v0x610378cf2670_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1031.5; %jmp/0xz T_1031.3, 8...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 1266778
- `line_count`: 33289
- `sha256`: 095cf71fcac591ca4a95fb3d87336be1763d9a44c2d52d5abb2ae42762c3c117
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 12, "PASS": 13}
- `summary`: vvp evidence; size=1266778 bytes; lines=33289; FAIL=12; PASS=13; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 840389
- `line_count`: 21428
- `sha256`: 495e0b010879c17f89f63efb489908ee23131208deb954a2b005e9833e7ba58b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=840389 bytes; lines=21428; FAIL=3; PASS=2; tail=ad/vec4 v0x560010d728a0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_170.88, 9; %load/vec4 v0x560010d722c0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/1 T_170.89, 9; %load/vec4 v0x560010d72200_0; %or; T_170.89; %nor/r; %and; T_170.88; %flag_set/vec4 8; %...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2338470
- `line_count`: 59667
- `sha256`: e5d32d8ff5cb069b14bb71d50d37e2840be679ac31450c43674e6a2eb4352c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=2338470 bytes; lines=59667; FAIL=3; PASS=2; tail=eed_ad_update, S_0x56c5570c7360; %join; %free S_0x56c5570c7360; %pushi/vec4 1, 0, 1; %store/vec4 v0x56c5570e8590_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x56c5570e7650_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x56c5570e7f30_0, 0, 1; %pushi/vec4 1, 0, 1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 960578
- `line_count`: 24597
- `sha256`: 6e8985f7a7653ccdb783d0f6ad8c06067d99091f73fb2fe29bc794277bc24ad3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=960578 bytes; lines=24597; FAIL=4; PASS=2; tail=/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_branch_target.vvp

- `kind`: vvp
- `size_bytes`: 43990
- `line_count`: 1076
- `sha256`: 0491f65fbc3c1cedd34f6d7c5d36a82cb1c8abe268e88d4d0c54a825821bf058
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=43990 bytes; lines=1076; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 126494
- `line_count`: 3125
- `sha256`: 8adf08f95c16d6cb85bcd2521730f611d431a7e3b837b509f8319a2264b0ef45
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=126494 bytes; lines=3125; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 543585644, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1814062697, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1718558820, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 457066
- `line_count`: 9835
- `sha256`: 501e3885a27a145949bf285a0c6196ae43923501c781e839bc0a26b2e8ed2773
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=457066 bytes; lines=9835; FAIL=2; PASS=1; tail=%pushi/vec4 1970303087, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1920230756, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544367987, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 176819132...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 417800
- `line_count`: 8306
- `sha256`: bf4371d0af8260baed309c9c97bc6fa2de2bf8c6509a09757c16ccf3c2c20a83
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2}
- `summary`: vvp evidence; size=417800 bytes; lines=8306; FAIL=2; tail=ncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 3...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 125913
- `line_count`: 3149
- `sha256`: 2523b73bba9baa1842f64681e8432d99329457068354d036c660d0b949f4c9e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=125913 bytes; lines=3149; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 323785
- `line_count`: 8272
- `sha256`: 17bb61a2686fee64b02eb3ab46afeed5a3e9c0cc6b8283644b49a11dcdf49055
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=323785 bytes; lines=8272; FAIL=6; PASS=3; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 197151
- `line_count`: 5127
- `sha256`: 4dbf31eb7025f9b1ce9c22fdea3f3aa93cced07d5b9772a7f0461d8ba642db02
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 3}
- `summary`: vvp evidence; size=197151 bytes; lines=5127; FAIL=8; PASS=3; tail=ec4 2147500032, 0, 64; %store/vec4 v0x587f23fd23d0_0, 0, 64; %pushi/vec4 6292243, 0, 32; %store/vec4 v0x587f23fd21f0_0, 0, 32; %pushi/vec4 7340947, 0, 32; %store/vec4 v0x587f23fd22f0_0, 0, 32; %fork TD_tb_ooo_fetch_packet_fifo.drive_enqueue_packet, S_0x587f...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 56265
- `line_count`: 1292
- `sha256`: 73998d908ead62a8f03489764cffd85620e00748a9a54b9420fc6b76f2e1717b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=56265 bytes; lines=1292; FAIL=14; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 69962
- `line_count`: 1833
- `sha256`: fb9bee4be0736f8a0de8de73a20e4f9acc4fa38e3a2d639e9f273b605b7b564b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=69962 bytes; lines=1833; FAIL=3; PASS=1; tail=INPUT 1 "drain_pending_system_i"; .port_info 16 /INPUT 1 "drain_pending_branch_undispatched_i"; .port_info 17 /INPUT 1 "drain_pending_jump_i"; .port_info 18 /INPUT 1 "drain_pending_mem_i"; .port_info 19 /OUTPUT 1 "clear_o"; v0x592b7c8a2bc0_0 .net "branch_re...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1377237
- `line_count`: 35164
- `sha256`: f0d9704e9d24c985a32ac87a61d2181316d39390fd6f19cdfba353c063b8d0cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 3}
- `summary`: vvp evidence; size=1377237 bytes; lines=35164; FAIL=5; PASS=3; tail=vec4 v0x6526df76e170_0; %parti/s 12, 0, 2; %load/vec4 v0x6526df76e520_0; %pushi/vec4 2, 0, 5; %pushi/vec4 3, 0, 3; %store/vec4 v0x6526df770620_0, 0, 3; %store/vec4 v0x6526df7707c0_0, 0, 5; %store/vec4 v0x6526df7708a0_0, 0, 5; %store/vec4 v0x6526df770700_0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 131596
- `line_count`: 3397
- `sha256`: e714bcd3e7c52a602dc1d47540971099e529704df709dd72c4636ed26170a7fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 1}
- `summary`: vvp evidence; size=131596 bytes; lines=3397; FAIL=6; PASS=1; tail=ng_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 94731
- `line_count`: 2349
- `sha256`: e15fcf1bc9fb1d7d8c4b19d670fd72998721f6592e506bf2008f82f6627a8110
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=94731 bytes; lines=2349; FAIL=4; PASS=1; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_static_classify.vvp

- `kind`: vvp
- `size_bytes`: 133289
- `line_count`: 2374
- `sha256`: b1270606da1aee5279d2a6265499505fc9af49f73c5a2c6943fd8eb9a37e4c9b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=133289 bytes; lines=2374; FAIL=4; PASS=1; tail=OR 1, L_0x5aa8ee17d5e0, L_0x5aa8ee17e1d0, C4<0>, C4<0>; L_0x5aa8ee1655a0 .functor OR 1, L_0x5aa8ee165530, L_0x5aa8ee17f420, C4<0>, C4<0>; L_0x5aa8ee165660 .functor OR 1, L_0x5aa8ee1655a0, L_0x5aa8ee180820, C4<0>, C4<0>; L_0x5aa8ee190f40 .functor OR 1, L_0x5...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 5577818
- `line_count`: 124631
- `sha256`: 826fe2547a4007ab6047ca2344b82aad61d6f1268b97a5146a1d9c846a1406d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=5577818 bytes; lines=124631; FAIL=4; tail=9O-CONTROL-EVENT-SELECTIVE-SOURCE] frontend winner lacks matching backend branch projection @%0t", $time {0 0 0}; %vpi_call/w 4 1932 "$fatal" {0 0 0}; T_544.2 ; %load/vec4 v0x57c4a02d05e0_0; %nor/r; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_544.14, 10;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 400745
- `line_count`: 12008
- `sha256`: 92db03b405ab3114fa4303e59d6133477672596260faf49ad168db2ed6319689
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6}
- `summary`: vvp evidence; size=400745 bytes; lines=12008; FAIL=6; tail=aw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68451
- `line_count`: 1835
- `sha256`: d7f23e9deb12308406fb8b29ff0458083e9f2ae1aced2cd44d2179be05e564c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68451 bytes; lines=1835; FAIL=7; PASS=2; tail=60ee253b7300_0 .var "class_s_bits", 9 0; v0x60ee253b73e0_0 .net "class_value_o", 63 0, L_0x60ee253c8e70; alias, 1 drivers v0x60ee253b74c0_0 .net "double_i", 0 0, v0x60ee253b8440_0; 1 drivers v0x60ee253b7580_0 .net "frs1_value_i", 63 0, v0x60ee253b8510_0; 1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 97895
- `line_count`: 2767
- `sha256`: a69e8b2d795eea56e36e233c82ee1bbf6dcfaf0ac31fb384f325b0949ca7c97e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=97895 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x5747ed36ec80_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x5747ed36ef70_0; %store/vec4 v0x5747ed36f890_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x5747ed36edd0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x5747ed36ee90_0; %store/vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202658
- `line_count`: 6365
- `sha256`: 812b2c09aaa17ac76fb778b3f055f06f3c02ca1da57c102bdf7dae17b18159fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202658 bytes; lines=6365; FAIL=4; tail=6a5160_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x583cfa6a4c50_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x583cfa6a5760_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x583cfa6a4d10_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x583cfa6a5820_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 481776
- `line_count`: 12442
- `sha256`: 1838302b8b098c3fe92aa2f688f51714549b4377cb3f42f0fe82362f8224efa1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=481776 bytes; lines=12442; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1412646432, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919247215, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986359909, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 83963
- `line_count`: 2210
- `sha256`: 0e54b5088a27c7b6185f55842e3273ef76e37602b689a4c8fe5b1aa33221f4df
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=83963 bytes; lines=2210; FAIL=8; PASS=2; tail=5cbe5a297180_0 .var "exp_remainder_nonzero", 0 0; v0x5cbe5a297260_0 .var "exp_root", 55 0; v0x5cbe5a297340_0 .var "first_value", 111 0; v0x5cbe5a297400_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start ; %pushi/vec4 1024, 0, 112; %s...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 216182
- `line_count`: 5300
- `sha256`: 2e8b0741d43bb5de0bb16b295b1d47af499c90736db89d5833aa175399966452
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=216182 bytes; lines=5300; FAIL=3; PASS=2; tail=set/imm 4, 0; %store/vec4 v0x64d90a803c40_0, 4, 2; %pushi/vec4 1, 0, 1; %ix/load 4, 29, 0; %flag_set/imm 4, 0; %store/vec4 v0x64d90a803c40_0, 4, 1; %jmp T_9.34; T_9.31 ; %pushi/vec4 0, 0, 1; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x64d90a803c40_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197006
- `line_count`: 6101
- `sha256`: 5bbb702f94f1224d5022cedb567a67e263e123c13b6fec202dd7a2ca4ff469e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197006 bytes; lines=6101; markers=<none>; tail=vec4 v0x5f86a77e1420_0; %parti/s 1, 2, 3; %store/vec4 v0x5f86a77e0e60_0, 0, 1; %load/vec4 v0x5f86a77e1420_0; %parti/s 1, 1, 2; %load/vec4 v0x5f86a77e1420_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x5f86a77e1280_0; %or; %store/vec4 v0x5f86a77e1940_0, 0, 1; %push...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64037
- `line_count`: 1638
- `sha256`: 3f08607ae402236b053419c6b1d2e1a2c97d570b66f4c4c082fc2139b2e8ee8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64037 bytes; lines=1638; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30253
- `line_count`: 661
- `sha256`: a2f6ba185015c9706113d5eae6aaf46b4f79d4dc338d1f2d750a366905d8069f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30253 bytes; lines=661; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39292
- `line_count`: 1056
- `sha256`: d2df6b4ca4cc888132a01e5cc506bd912988d4858cb2fc028ec2708730482b92
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39292 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 75847
- `line_count`: 1877
- `sha256`: 2eb54cb209621655c6745e08dc73360509adcb0d8c42c4b496f014229f54e6c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=75847 bytes; lines=1877; FAIL=6; PASS=2; tail=vers v0x60fa6ff30c10_0 .var "head_q", 5 0; v0x60fa6ff31100_0 .var/i "idx", 31 0; v0x60fa6ff311e0_0 .net "next_count_w", 6 0, L_0x60fa6ff361c0; 1 drivers v0x60fa6ff312c0_0 .net "post_alloc_count_w", 6 0, L_0x60fa6ff34cf0; 1 drivers v0x60fa6ff313a0_0 .net "po...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 100928
- `line_count`: 2481
- `sha256`: d1e1b09c3a5d210d1519baccc60a8790c4f2a2cd76cb6c8a843a28622f82296d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=100928 bytes; lines=2481; FAIL=3; PASS=1; tail=, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 110858
- `line_count`: 2616
- `sha256`: 7feff48af15e03995d847c28304413b6a27eb6c1948676036ce7dd9130e63d82
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=110858 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x57def05f2140_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x57def05f26a0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x57def05f7eb0; %join; %free S_0x57def05f7eb0; %alloc S_0x57def063fd70; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x57def063...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 146851
- `line_count`: 3486
- `sha256`: 705804fa14ec74ba3d37f6c14b550c50f6a9bb33353abf26a907080d7dc61db2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=146851 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x5e8252ebbd90; %alloc S_0x5e8252ebbd90; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 90847
- `line_count`: 2250
- `sha256`: 160aaf77ac9e100a699c9a495cfb8e1053e4332567f9c3b769674b8947717355
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=90847 bytes; lines=2250; FAIL=3; PASS=1; tail=4 1718558834, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702061426, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986338913, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986095468, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138490
- `line_count`: 3101
- `sha256`: 55a37bf0060cc2058f99312d8b135bac4f6e01ef3d263e50af2590884baf7fd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138490 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 696839
- `line_count`: 15284
- `sha256`: 8f5cd25b20150fcd157d3c1764d2a4a12a1d28787d222a95896c5aa2ef4a001e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 6}
- `summary`: vvp evidence; size=696839 bytes; lines=15284; FAIL=3; PASS=6; tail=v0x633bf4d27280_0, 0, 2; %pushi/vec4 0, 0, 1; %store/vec4 v0x633bf4cfede0_0, 0, 1; %fork TD_tb_ooo_ifu_lane1_fault_owner.run_tval_lifecycle_row, S_0x633bf4b64070; %join; %free S_0x633bf4b64070; %alloc S_0x633bf4b64070; %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 12186069
- `line_count`: 305776
- `sha256`: b300fa443cc3c06363a2d55575ed6da70916913ff3cb8077827db40f96d28a63
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=12186069 bytes; lines=305776; PASS=2; tail=v0x6351a3b41960_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x6351a3b41960_0, 0, 1; %delay 1, 0; %alloc S_0x6351a28d9310; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1196504
- `line_count`: 30124
- `sha256`: 8abb04008741336f9199a8a6f82567745cc6b5f0fc79bf895a47545b4df74ed7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1196504 bytes; lines=30124; markers=<none>; tail=/vec4 1, 0, 1; %store/vec4 v0x59a5df633190_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x59a5df633190_0, 0, 1; %alloc S_0x59a5df470c70; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x59a5df470c70; %join; %free S_0x59a5df470c70; %delay 1, 0; %...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_load_queue.vvp

- `kind`: vvp
- `size_bytes`: 199457
- `line_count`: 4947
- `sha256`: 90f3e8656a224eacfba61da503b49d0c54fe63f990c89105b7b12cfe8edc4df2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: vvp evidence; size=199457 bytes; lines=4947; PASS=3; tail=string_vec4 %pushi/vec4 1852142177, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1953066862, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543781664, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_lsu_axi_lane_adapter.vvp

- `kind`: vvp
- `size_bytes`: 118694
- `line_count`: 3332
- `sha256`: cdf45257b6395a60b109e1285abc02c18e37dbd6c55efd1e6bbbd28a9ace287a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 9, "PASS": 2}
- `summary`: vvp evidence; size=118694 bytes; lines=3332; FAIL=9; PASS=2; tail=acc050 .reduce/nor v0x5aaaaeaaee20_0; L_0x5aaaaeacc560 .cmp/eq 3, v0x5aaaaeab04a0_0, L_0x7629901862e8; L_0x5aaaaeaccab0 .ufunc/vec4 TD_tb_ooo_lsu_axi_lane_adapter.dut.sticky_resp, 2, v0x5aaaaeab0140_0, v0x5aaaaeab7500_0 (v0x5aaaaeaa92c0_0, v0x5aaaaeaa91c0_0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 3579822
- `line_count`: 91070
- `sha256`: 2ea9457363a0352054a4a53a422d3754a2c654384a06d508fda77dcb5051f4c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 1}
- `summary`: vvp evidence; size=3579822 bytes; lines=91070; FAIL=1; PASS=1; tail=%and; T_215.148; %flag_set/vec4 10; %flag_or 9, 10; T_215.147; %flag_get/vec4 9; %jmp/1 T_215.146, 9; %load/vec4 v0x5e7693cd3d30_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_215.150, 9; %load/vec4 v0x5e7693ccdb60_0; %load/vec4 v0x5e7693cd8690_0; %cmp/ne;...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_mem_inflight_queue.vvp

- `kind`: vvp
- `size_bytes`: 305323
- `line_count`: 7665
- `sha256`: 0b45991a301d3eac7c71beaf6b991e7201a164aef410286c687c91266dc65389
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=305323 bytes; lines=7665; FAIL=4; PASS=2; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 84965
- `line_count`: 2354
- `sha256`: 5c8b610e2e42b19736c153e00a0461429e112ae3acda55a67fb70644a0c1830a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 3}
- `summary`: vvp evidence; size=84965 bytes; lines=2354; FAIL=1; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_mem_owner_tracker.vvp

- `kind`: vvp
- `size_bytes`: 136101
- `line_count`: 3605
- `sha256`: 2e03da9ec27977851a293024d2826161ca564f3596fe7eecceba515764f28ac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: vvp evidence; size=136101 bytes; lines=3605; FAIL=2; PASS=4; tail=/ne 3, 0, 3; %jmp/1 T_14.19, 4; %flag_mov 8, 4; %load/vec4 v0x577ae21f56d0_0; %parti/s 1, 5, 4; %nor/r; %flag_set/vec4 9; %flag_or 9, 8; %flag_mov 4, 9; T_14.19; %jmp/0xz T_14.17, 4; %alloc S_0x577ae21f3a30; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 58048
- `line_count`: 1438
- `sha256`: 2353b5a2b2d1bf2ecd6e0e2f09ffaf0786d5dbef3c455bad86acf77f6ef1a686
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=58048 bytes; lines=1438; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_mmu_epoch_owner.vvp

- `kind`: vvp
- `size_bytes`: 135188
- `line_count`: 3828
- `sha256`: a7b104aa2e396ec3968f1dc1598310a0693e8e4fe2fbee41d65370ea30a4c1ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=135188 bytes; lines=3828; FAIL=1; PASS=4; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 348991
- `line_count`: 8867
- `sha256`: d177e713a03afecfd533ad5b74dd918b7d30857a9d6ec8fea720285e5c98e01d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=348991 bytes; lines=8867; FAIL=5; tail=ushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 218534
- `line_count`: 4978
- `sha256`: f43b8b7f1b285dae1efa4d05fda6a00d135584a526d2bcfd7751d8c894041e3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=218534 bytes; lines=4978; FAIL=5; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 824206949, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1952671776, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1717663084, 0, 32; draw_string_vec4 %concat/vec4; draw_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 86084
- `line_count`: 2063
- `sha256`: 0dda25836cfd948747a5d44e9f3128d03f2a5f22271ed98d058aaf5099d7de91
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=86084 bytes; lines=2063; FAIL=3; PASS=1; tail=; %join; %free S_0x5d5a3bb62b00; %delay 1, 0; %alloc S_0x5d5a3bbb2aa0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 108020
- `line_count`: 2656
- `sha256`: 888a3aa176d3539d6fe42607a12d4cd8a4067a3f18bc66f29454a20bb04fe7da
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108020 bytes; lines=2656; FAIL=5; PASS=1; tail=_capture_gate.clear_inputs, S_0x603d59e55390; %join; %free S_0x603d59e55390; %pushi/vec4 1, 0, 1; %store/vec4 v0x603d59e55780_0, 0, 1; %pushi/vec4 1, 0, 1; %ix/load 4, 38, 0; %flag_set/imm 4, 0; %store/vec4 v0x603d59e59270_0, 4, 1; %delay 1000, 0; %alloc S_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pending_system_admission_cancel_gate.vvp

- `kind`: vvp
- `size_bytes`: 14437
- `line_count`: 323
- `sha256`: 28701832552f5ac25c16337e38eaacf8dac276e29ce6cf1847a67228c8fac68a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=14437 bytes; lines=323; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 135644
- `line_count`: 3392
- `sha256`: 998892f0c68c8e232f3d6b4dddf2c8673a46377e6a8fe4e0885d73c98215c1ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 5, "PASS": 2}
- `summary`: vvp evidence; size=135644 bytes; lines=3392; FAIL=5; PASS=2; tail=%load/vec4 v0x5ed6dfbba930_0; %assign/vec4 v0x5ed6dfbbc050_0, 0; %pushi/vec4 0, 0, 5; %assign/vec4 v0x5ed6dfbbd620_0, 0; %pushi/vec4 0, 0, 8; %assign/vec4 v0x5ed6dfbbe2a0_0, 0; %jmp T_9.12; T_9.11 ; %load/vec4 v0x5ed6dfbbcde0_0; %flag_set/vec4 9; %flag_get/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 28463
- `line_count`: 854
- `sha256`: 25a8127c470e3b0f90743780a08952978daabbb8e44fa00a78b83704a685ab5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: vvp evidence; size=28463 bytes; lines=854; FAIL=2; PASS=6; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 192896
- `line_count`: 4897
- `sha256`: 6ec747c59147dd82683318b44179c7c5366a6417ccd50b9c1df07696aeb33557
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=192896 bytes; lines=4897; FAIL=3; PASS=1; tail=w_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_pma_checker.vvp

- `kind`: vvp
- `size_bytes`: 118579
- `line_count`: 2750
- `sha256`: a50944562b630419dc4c9e08e16764b125a29f55d6518054d123676ea82a10f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=118579 bytes; lines=2750; FAIL=4; PASS=2; tail=768843040, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1347637825, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1293968485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1668244581, 0, 32; dr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6377586
- `line_count`: 146431
- `sha256`: 29e9e52171dac3b0f6d59f2c0b0175133c81dbed160a8926c7c9613123fdc318
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6377586 bytes; lines=146431; FAIL=3; PASS=2; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63728
- `line_count`: 1586
- `sha256`: 6d6140882f8aae4696ada7f94e77be6a9ed684dfc2d7a21d0d6fde5781e16f98
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63728 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 34854
- `line_count`: 876
- `sha256`: 2c954ec6fde64b45d6e0d429529c63fbffa21a139fda8d51712b9985ad0dbddf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 22, "PASS": 2}
- `summary`: vvp evidence; size=34854 bytes; lines=876; FAIL=22; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99472
- `line_count`: 2436
- `sha256`: 19bb1a36b91a0ef9550ecfc6df694d0873ff5da001880b76eb8fc5467e7978cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99472 bytes; lines=2436; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 1076006
- `line_count`: 26450
- `sha256`: ea75253bbf16fc4c620ebfa0c38ca8392628d5866da1810969f8c8a38c07d3ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1076006 bytes; lines=26450; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 66064
- `line_count`: 1798
- `sha256`: 8c9f536185e1b6e7458a46f8675f07c13401674a35ec5a224e6a9b48211211a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 3}
- `summary`: vvp evidence; size=66064 bytes; lines=1798; FAIL=3; PASS=3; tail=9b027f3ac0 .scope module, "tb_ooo_stop_pending_sequencer" "tb_ooo_stop_pending_sequencer" 3 4; .timescale -9 -12; v0x629b02814ec0_0 .var "branch_resolve_untracked", 0 0; v0x629b02814f80_0 .var "branch_spec_checkpoint_capture", 0 0; v0x629b02815020_0 .var "b...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 584857
- `line_count`: 14289
- `sha256`: 8af124229901997cb462b0449b5a7fcf0f895eb251db2e9f99a6513707b30ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=584857 bytes; lines=14289; FAIL=1; PASS=4; tail=020; %alloc S_0x573f4dcad7e0; %pushi/vec4 12, 0, 4; %store/vec4 v0x573f4dccb4e0_0, 0, 4; %fork TD_tb_ooo_store_queue.alloc_one, S_0x573f4dcad7e0; %join; %free S_0x573f4dcad7e0; %alloc S_0x573f4dda4560; %pushi/vec4 12, 0, 4; %store/vec4 v0x573f4dda4740_0, 0,...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 8303998
- `line_count`: 192391
- `sha256`: 24e2ed9689ae40de2e3aa00818b31fdc22b6df9e759a372bfb4250303668fc48
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=8303998 bytes; lines=192391; FAIL=14; PASS=2; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36101
- `line_count`: 734
- `sha256`: 5fe85cae1eb2c2d6b8c43788bad88ef1156f01b06d99c14399031c744764683d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36101 bytes; lines=734; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 16989
- `line_count`: 476
- `sha256`: 423b742a2f9725a5685ed53c9b7f32957a041f1826d235911e42fbf2f3012061
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=16989 bytes; lines=476; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_ooo_typed_memory_classifier.vvp

- `kind`: vvp
- `size_bytes`: 52197
- `line_count`: 1446
- `sha256`: 15c550817488d3e0c071e0bebd7ff689f2937fba1df62c9f29df98eb503e6fa3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 4}
- `summary`: vvp evidence; size=52197 bytes; lines=1446; FAIL=10; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65157
- `line_count`: 1744
- `sha256`: 21607909672655a9c25f08e4a8d563e21c3c54473aaa1e13432069d96c52f333
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65157 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180661
- `line_count`: 4649
- `sha256`: 4345182f1dca88c01680fbad3fb4a1e9b2dd97225bd716b0d0fbe54058ccea72
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180661 bytes; lines=4649; FAIL=3; PASS=1; tail=eda0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63309d03f070_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63309cff84a0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63309d03ec20_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x63309d022140; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300070
- `line_count`: 8070
- `sha256`: d4e74c9398720544633b59d3b8b3389c8460b64b0ff56430174ae741d7c869e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300070 bytes; lines=8070; FAIL=4; PASS=1; tail=1; %store/vec4 v0x58c9fb9246f0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x58c9fb9246f0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x58c9fb924e20_0, 0, 1; %delay 1, 0; %alloc S_0x58c9fb923290; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25241
- `line_count`: 678
- `sha256`: 6c57c5a2af8763f829b793308cad70059500ebb0ac528ae55bd51de9d823a47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25241 bytes; lines=678; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current-run.log

- `kind`: log
- `size_bytes`: 4097
- `line_count`: 126
- `sha256`: 26e24257fba66b5c3a4715b55b6f2f05026ebfa60ba2b49599e23859df3879d0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 224}
- `summary`: log evidence; size=4097 bytes; lines=126; PASS=224; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' [NEGATIVE] ordinary-store invalidate topology rejected [NEGATIVE] cut FENCE.I/mmu_flush chain rejected [NEGATIVE] cut dual-memory lane mmu_flush chain rejected [PASS] IFU ordinary-sto...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 467
- `line_count`: 5
- `sha256`: 41328804fa0e65efc3e250befedd4f50bc24118cf1864d57509bfd1c14a073d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=467 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-reco...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 499
- `line_count`: 5
- `sha256`: 1e6f7578f08ca8038228b456f77be73c000025a115da4949f12b2d0d22b0553d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=499 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-se...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3709
- `line_count`: 29
- `sha256`: 794fdbdf6f4a12062a776299edf84a13a1c793d1271b4c45c50cd2ad375b8c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3709 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 607
- `line_count`: 6
- `sha256`: adf018b3324888d8496e97fa8208410191f65398fc60642e25845ca8eeaef6c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=607 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-seri...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: fbcdf6bacb8eca5a7cb924d1ef9f25be21000219c3574776b50759787692ad07
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 563
- `line_count`: 5
- `sha256`: 86b57c23f159fd0747a139574d53dbce675133813633f9c7361938c724808065
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=563 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3493
- `line_count`: 29
- `sha256`: dac32e596e1d135091fbed84d2d56f6930edb1b423fc16b291c05da3e96de22f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3493 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-seri...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: 56e71f9f01d9a46751151347b7c9ff8608500ab971056550e8a5ab575e188e4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serial...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 494
- `line_count`: 5
- `sha256`: 49a9058fe651975bb62ca84a3e5fb7ee604a6c45c11452879c2b35caba98844e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=494 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-seri...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_csr_file_vectored_trap.log

- `kind`: log
- `size_bytes`: 679
- `line_count`: 6
- `sha256`: 248ea20e78f518c3fbaf5499d805bc6566f53ff3bb3e2f7675f62f68e50d5818
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=679 bytes; lines=6; PASS=6; tail=[TEST] tb_csr_file_vectored_trap [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file_vectored_trap -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 5
- `sha256`: 4721da0ab3fb3afe7bc9e20010f5c658a9845a66c465395850bba2e09d0150c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=638 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 513
- `line_count`: 5
- `sha256`: 323ea8dc326f8fb7ca6b32058a5e06d87c2d1ae9b6596e361d76f825702ab242
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=513 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 483
- `line_count`: 5
- `sha256`: 969dceed5f34899d194cdc7d6473a6f3970fa24514238d98447e71618c25b941
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=483 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serializ...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 590
- `line_count`: 5
- `sha256`: daad86ad78d393c66a0599f8fce698802c4b067376c506f0b540e76548b75343
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=590 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-reco...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 512
- `line_count`: 5
- `sha256`: 390b821c464ee5a9608399012f69cb74c2755b670a0d38fd16a9a4a0273b3a9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=512 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: b0c890bc6f71bba9035c7f2dd6ccd9853ab9c4e21f463ee32f4f22ea47236b35
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31492
- `line_count`: 208
- `sha256`: 3df587f66ac17f2ff5a684fd8fd402f9f9f890c73891ac19609524c3d56f95d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31492 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31672
- `line_count`: 206
- `sha256`: 894f21a55a43863655b54bbfa99a6cea2951c32936ab37f841cf03c7dc6852d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31672 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 518
- `line_count`: 5
- `sha256`: 2ab55e60b03e04371f4af62a98a65b17b169c741eb9e8684105ae7b9371d12e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=518 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 597
- `line_count`: 5
- `sha256`: 3bb5a6305127018da2bff412f16a9bff3ca7ca42c2fea1ad798ab520061861fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=597 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 550
- `line_count`: 5
- `sha256`: 3355567d6fb0920af9d7186346486d7842c8bdf0abbf9376a61d1382a27afb44
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=550 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 975
- `line_count`: 9
- `sha256`: 936eefd46b4e2d14079941703c646967bf97b9e27b3f2d9e980626f95bc6ba40
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=975 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 930
- `line_count`: 9
- `sha256`: 1487fda8e18493d177680de0b186fcc40ebc4235c1747b4a7b90843c12c8f2b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=930 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 713
- `line_count`: 5
- `sha256`: e6772bc3e01761d64b1d5ab7e6b94bb6fc0049382b8ec588acd6051ab596fb71
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=713 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 985
- `line_count`: 9
- `sha256`: 9f2fbf12d0795d339c02382d17333e82997c7374a4b87be9d83f38cb8c8ef41d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=985 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: ac92a5f4b6d414876b3abe7ce2a95ed04694797b32bed9435b51bd84028640fa
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 670
- `line_count`: 6
- `sha256`: 957ad17e2573e23ea8b89a240ec64b7bdac50789af7907aac36a05f9ff143c03
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=670 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 533
- `line_count`: 5
- `sha256`: c230cfabdfac30cb9232ac87df4ec5edabaf27d25513b7af3e32335ef0ec430e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=533 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 888
- `line_count`: 9
- `sha256`: 3b776a7c6e17d867defd474c9cda5592568ee913987e822635ea4642a79a692d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=888 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 953
- `line_count`: 9
- `sha256`: 4eba6112a318a3945e6dcaeb47bf2cd1a058009a7a9a37fbb81095306eee9bef
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=953 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_control_event_apply_sequencer.log

- `kind`: log
- `size_bytes`: 966
- `line_count`: 9
- `sha256`: 7bff3c6cd36f147d2d61c0814c8831d93d0364091f79dbd4a98d1a529a82796b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=966 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_event_apply_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_event_apply_sequencer -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 940
- `line_count`: 9
- `sha256`: cb7306c7ee43823929bec76ab13eb9cafec975a27eebc7de2304ded8405aff18
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=940 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25481
- `line_count`: 140
- `sha256`: f4f05986a96cf414d8086bd69220b74323fe35c80098c7a149cf0ba351116fec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25481 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 5
- `sha256`: 00f0cd2ddc90043b8a3eb5ae43a77f5abf16170bffe79bff9a315298f891651a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=618 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 681
- `line_count`: 6
- `sha256`: c812f58afda148a3ecf4cf7af6e76a3022b69345f0f7252ce8c73000d273649e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=681 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 5
- `sha256`: 252dcd4f278fbdbc3bccf28dad570fe555954e8ab03be3069d4d21564b63d935
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 5
- `sha256`: 515f0298bd8ee81114a7c724a4fff2baffb5450de2935b91338139a45edea159
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=626 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 620
- `line_count`: 5
- `sha256`: f8da955a43604214491593969197109653179ed1c7e00cd49d8c1cb4d1b18d38
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=620 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 620
- `line_count`: 5
- `sha256`: 4c8c5dec170dc3d84e051f8ebeaa0e60809776d1ff5e4f6131da95180fd85f81
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=620 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5822
- `line_count`: 40
- `sha256`: 2fdd9064fcf2a08a68c0e9a00214779cd477326e6503d411ebacbc768b7c5d75
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5822 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 306439
- `line_count`: 2296
- `sha256`: 1107cdef8919d9088d3a48b6d1e399753f5b0a48bbb7b00ac9f95bd6f29e7dbc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=306439 bytes; lines=2296; PASS=2; tail=orkbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 114297
- `line_count`: 944
- `sha256`: 8247e88429cbe84559e62c5f1cf17f5d74277e3cc02b80b2bff2546f40a13d02
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 159}
- `summary`: log evidence; size=114297 bytes; lines=944; PASS=159; tail=yx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103845
- `line_count`: 780
- `sha256`: 2911cb81fb0d24489ef481fbbf6dbdb546841099d77d3d2c76087fa02af8753b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=103845 bytes; lines=780; PASS=3; tail=ing: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:1...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105360
- `line_count`: 794
- `sha256`: e1e175f7c15690eeaadfe2d8905eec437599b9d8e93a8014051c2051531919ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=105360 bytes; lines=794; PASS=3; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106776
- `line_count`: 803
- `sha256`: 375b531c5af6a4eee4bfcbf07fd8e5009167e3ea2add9c5670cbcbb345628076
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=106776 bytes; lines=803; PASS=3; tail=/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 587
- `line_count`: 5
- `sha256`: 6c7214d426f9ee4b58aee7a5e9135f4c4f9d372d96b8e7d4b5405aaaa9f31cd9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=587 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 579
- `line_count`: 5
- `sha256`: 9dc1ccc0edacdfc0028fc89e6a6d63feebb926c6b933a419e7e95301283b18d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=579 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 855
- `line_count`: 6
- `sha256`: 9949877caac8fc8247c9881f35dadb1106f6a6e0174652e4b4d58693ea9e2b52
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=855 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 807
- `line_count`: 5
- `sha256`: 85b6384e5ab2893fea81ae919535aad5fb33de1e0eae8e70c06ffe6c136c705b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=807 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 716
- `line_count`: 5
- `sha256`: 3ba9789f04b35b8bbc6bc62e9a546ff4d7df7c61579cc9563a67ca01c1ddbd28
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=716 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 846
- `line_count`: 8
- `sha256`: 4d8ffd4e349509969ecd9e50b3d1caf86d380a728c5cea109154d860810d1bc4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=846 bytes; lines=8; PASS=8; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1253
- `line_count`: 14
- `sha256`: 735f85d1f569e1a77ece23318be6f740b6952fe5ae8792b9e98cfa9133fdc3f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1253 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: fcbeb5466ff717ba4d9c388294a46ca2c3b1f14d91dbf20ccc63a8841d4c88e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 596
- `line_count`: 5
- `sha256`: 3bc4d663da9e49044c9633f1c63afd940c6cfb5f63f398799f4e899b7cf7b257
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=596 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 108195
- `line_count`: 818
- `sha256`: 7cfea1a76c3f0cc4980834cc8ec256bcbd6148f54d8cd63b9a44702cfca138ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=108195 bytes; lines=818; PASS=16; tail=v64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 650
- `line_count`: 5
- `sha256`: 1fe7c3fdc256f21daa3c0150cb32df57f6099a68d195ffce3415e046610624ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=650 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 573
- `line_count`: 5
- `sha256`: b52e8e4fc665f27f97f852fce6cc4405672e5b6a760d35d5a1baed1a8ce466ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=573 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 1085
- `line_count`: 10
- `sha256`: 3b798739f272b793e748fe15c5a1f648d3751db37450e63c0849cf7773521a68
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1085 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34499
- `line_count`: 198
- `sha256`: 5ddc2319b99a6529aa8ef39f3aa30d351b39fd8c2c76e3229d9a4ba36cc65a24
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34499 bytes; lines=198; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 549
- `line_count`: 5
- `sha256`: 50ac59af49b6b5cc92620e35ec80e4bdb8a1beca87064cc7013c812a0dbe0c4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=549 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 566
- `line_count`: 5
- `sha256`: 012b94410b517dd1ac411ed60e2bfbe0db0e4a5d6a9bf76055d225840f643db2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=566 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 5
- `sha256`: 5f862f806b7b6232f854a0b6e153d12430e2ea7cf42e476c1c6bf6192e829911
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=560 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 559
- `line_count`: 5
- `sha256`: 14e4664dea9b78c7d4474c0f6cdd5ac5b53e8df152a7ed22c6704cf28021b2e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=559 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 4055
- `line_count`: 38
- `sha256`: 0e928a7b840cfb760d75616647a501db743ff6aee4c563dd606a51ac101cd158
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=4055 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 584
- `line_count`: 5
- `sha256`: bef44b2c6e798ae283fb8097ce5a4f21ab1669a6136cae798f13256db01acbbe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=584 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1888
- `line_count`: 15
- `sha256`: 116204b7a6d833e0939a836b55e122700cb1b643b34f289bf1a89ede139676f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1888 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 691
- `line_count`: 5
- `sha256`: 24fd41f5c674c307f98b9315841ce2d41bbd5b00eb3ffe42f1b76ce04fd4b9c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=691 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1098
- `line_count`: 12
- `sha256`: 955d14acf9eee69eb59c3933d02cb95545970b0202ef4679837190cad0c143dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1098 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 845
- `line_count`: 9
- `sha256`: 8833c10df181cc2b354a3ea9e6055b1e2a9cf5912940e680f82347d9535a9a31
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=845 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 541
- `line_count`: 5
- `sha256`: 7945bd21a2b9ca26b896ffb67525c93fe8d1d3e09dee067462e523ccf00d09af
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=541 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 533
- `line_count`: 5
- `sha256`: d943ab60c9ad7e6f8ffd6216f42d521e2e54c7988e7fdbc43b807453016cc0bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=533 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv6...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: 6a4dd4a264d57d9014ef103b6215627d85c684fc3d4db808c8663a8c022f2f68
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 999
- `line_count`: 10
- `sha256`: 57e5d4b4ddba95649ecc6fc74a9e7875281674ed951ad647a92b05af7bb22777
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=999 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 911
- `line_count`: 7
- `sha256`: 2e455a559c78a2525470faed04ef0926896b051bb55d161fdf83500f67d68e42
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=911 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 573
- `line_count`: 5
- `sha256`: 0161f7ad20301a9924430f583c01de29b76d8fd414e44512854dc7a2fea5d81d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=573 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: 41af79222df2cf7c3d8dcb047b2cb96157d437c63e96a12541abb74c776c5023
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8909
- `line_count`: 83
- `sha256`: 80f2e9cf6549a1a1036be0cb202acec0152552b6510536c9020529f3da7eab22
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8909 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26787
- `line_count`: 226
- `sha256`: c140536b17b533d58c41643c9d7fb2f4f7b3f10c241a7d78b765a9e157b3da89
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"ERROR": 2, "PASS": 98}
- `summary`: log evidence; size=26787 bytes; lines=226; ERROR=2; PASS=98; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11579
- `line_count`: 96
- `sha256`: cc9e67478094c9f0a44ed5f2327a8228318c1b13528a9713c8782b0e5f02a533
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11579 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 4275
- `line_count`: 35
- `sha256`: 265485711adafa3c43e6b0b9cd18b99d41bf0cc47fb4f42a92cd1de512947eb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4275 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 943
- `line_count`: 10
- `sha256`: 6a158608994e6ced09df62e46cc374adc623580d3bc27ffd70abbd1cdff15f0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=943 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74698
- `line_count`: 572
- `sha256`: 5553d9e5aad75925c7b4516611d1be79d75f6d2748dc732d0b0cf9748daabc59
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74698 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1446
- `line_count`: 12
- `sha256`: b08a26c07762ac1429c05dbb55f2fa38e699aa7e70327ec6f1d2697c5dfa27e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1446 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1097
- `line_count`: 11
- `sha256`: 5ab16754c9200b0fddb9c4067121ec12f24ec2661ae899588ecb687ce4ab925e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=1097 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1411
- `line_count`: 14
- `sha256`: d7e9489244784a3c702459c28fa82e36f655c6100b3b9b8efad64971ccdffb9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1411 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1043
- `line_count`: 8
- `sha256`: 74b91d0a20dde0671f04f03d8aed737bfb0a1fbd0c315016a1e51c784f449cf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1043 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 798
- `line_count`: 8
- `sha256`: 07621d8d822c38aa8408a7d545749e48f216c8793b1e79f1e7ad87c53771be88
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=798 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 541
- `line_count`: 5
- `sha256`: 0afcd7944d298d4c6757b9327eaef5305dc79edc1602c8bfb479c90ff748c56a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=541 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1267
- `line_count`: 12
- `sha256`: 82954dc77f2bf079ef14cd4ea38a44cf8105e91eb14b00543e95cfc57b3db091
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1267 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 625
- `line_count`: 5
- `sha256`: bd38561551de33b9305a7d07532622a9c35f8472ec42882b58202d96f84d951b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=625 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 1055
- `line_count`: 11
- `sha256`: 75dc76169561d75c768ed98c646d0095e764007486f60388f5ab6df7078752ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1055 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 1082
- `line_count`: 10
- `sha256`: 853d5e3fa5b4b067ec17159fc2344af2145edd06d58448042dfb15b07855da4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1082 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o /home/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 1046
- `line_count`: 10
- `sha256`: 43f8376d05739f59b8980d7148ba637536096d87a638bbed98adf4eb18c31d89
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1046 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 812
- `line_count`: 7
- `sha256`: 3e1becd4d8cbacbfe1dbf162018415661df555003b2fee54fa47d863d68b582e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=812 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: 76b7a904431034e1537259a3fb53eb867f78420e4fbe24b8a98d2f19bb52db4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 677
- `line_count`: 6
- `sha256`: 936b67e20e0d775e3ac28b6290b8011feaaa6a254d35b12229be94583bd90a4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=677 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27064
- `line_count`: 143
- `sha256`: 6144ef9fdd0472e4a00773945588bee271d3ff333697596719471d39316f9f97
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27064 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 561
- `line_count`: 5
- `sha256`: 884c7cd0570c9d91b25e5f26507ed6c635e8bcab48b168e0ecee06300295624a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=561 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 567
- `line_count`: 5
- `sha256`: 57e6d4ff723c1c37c4263c869c3a35bb886b1551a39a10cfa73377fdbeadd591
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=567 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 539
- `line_count`: 5
- `sha256`: 2c4fd5ddc042bb49ea2e8c0bf5a45d8d65156cfb6bc8b9426a8dd9d4186cb2c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=539 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1422
- `line_count`: 14
- `sha256`: 65ebd706d628bf6cc5001c85fabc8057d62893e7ac793c8fd42b50b5fdf71e45
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=1422 bytes; lines=14; PASS=18; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serial...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 999
- `line_count`: 10
- `sha256`: 2e2b7a234a1552f16705e474bcb604ad1be8ac95a8cf60f35ef7b37b20c8ecf9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=999 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6935
- `line_count`: 58
- `sha256`: 0813c02b8a3fd8f03a17bb8f1dbd7d13ec1e90b879ca20d944e49abee0dbc290
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=6935 bytes; lines=58; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287169
- `line_count`: 2103
- `sha256`: 9f45d54b9dc9b057588d9ad76bf46228b3152c6f72be940a474c8c9dca16eff4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287169 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 597
- `line_count`: 5
- `sha256`: 467f80d3e87df19730874816be424a0f45f9a0891bfd37a352aa33120560b0f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=597 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 646
- `line_count`: 5
- `sha256`: 3aee3fb630bd0335bcf02e60eb3c260bc6d24f0656cf06080598747667c5a98f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=646 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 697
- `line_count`: 6
- `sha256`: 93e67e6a3ad5e833183aeb1e895c6ae0531b5afa079b8d9b00772d728dfd1a3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=697 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: 00c9f70ea99fb9d4c64bf2bf4290f321d45cbf1b3bb09eb98cbdb99f2c33caf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17659
- `line_count`: 134
- `sha256`: bea4af17e40699ff543125c1ce35016009f4cdd250e6f4070229eb52627df368
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17659 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 470
- `line_count`: 5
- `sha256`: 8f188237b0e6275018eece76b12609e7832819c985f5e8fc32f3382d0542c959
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=470 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-re...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: d7c103c42a31370f2160dd9b61d6bf8de0f999f1ef049ab3fa7203393ad086c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-reco...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current/summary.txt

- `kind`: txt
- `size_bytes`: 3737
- `line_count`: 120
- `sha256`: 669f3d59c1b874b29db1eb5f64f62b0099fb671effca322fa9b1b6e88493dfd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 222}
- `summary`: txt evidence; size=3737 bytes; lines=120; PASS=222; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/module-current - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - P...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/drop-trap-exit-c1-reset/OooControlPlane.v

- `kind`: v
- `size_bytes`: 49989
- `line_count`: 1091
- `sha256`: b1b61859548483f24170dd5951cd8bb59761a5232b95ca9d085988a5c319d769
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2}
- `summary`: v evidence; size=49989 bytes; lines=1091; FAIL=2; tail=`include "define.v" `include "common/OooSlotFacts.v" // OooControlPlane: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 13 个实例）。 // 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。 module OooControlPlane #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter ROB_COUNT_W =...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/drop-trap-exit-c1-reset/build/tb_ooo_core_top_glue_v9o_csr_qh.vvp

- `kind`: vvp
- `size_bytes`: 5920507
- `line_count`: 133559
- `sha256`: b62bf40e8496fe217154ec8d426ab068fb69d0f589a0cfd3294347a9502576b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=5920507 bytes; lines=133559; PASS=2; tail=ec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; dr...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/drop-trap-exit-c1-reset/driver.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 3
- `sha256`: 23c011e586f5ca25e1d9fe5a6a004c4d1a2746683f964ae8eb571500a2d96328
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: log evidence; size=384 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:382: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/drop-trap-exit-c1-reset/resu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/drop-trap-exit-c1-reset/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log

- `kind`: log
- `size_bytes`: 29350
- `line_count`: 151
- `sha256`: 93144df7e93466fb2b8e949f0673af2dda885ad890b175ca5f80be3b7a40eb9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=29350 bytes; lines=151; FAIL=8; PASS=18; tail=[TEST] tb_ooo_core_top_glue_v9o_csr_qh [COMPILE] iverilog -g2012 -Wall -I/tmp/v9x-drop-trap-exit-c1-reset-h9036ecg/npc/rv64/vsrc -I/tmp/v9x-drop-trap-exit-c1-reset-h9036ecg/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DV9O_CSR_QH_FOCU...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/reconstruct-qcsr-birth-from-merged-fire/OooControlPlane.v

- `kind`: v
- `size_bytes`: 50113
- `line_count`: 1094
- `sha256`: 5cd80528d9fe681407905eb4ab73d99a01e83f871c88eca9c2dd36699fcc55f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 2}
- `summary`: v evidence; size=50113 bytes; lines=1094; FAIL=2; tail=`include "define.v" `include "common/OooSlotFacts.v" // OooControlPlane: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 13 个实例）。 // 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。 module OooControlPlane #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter ROB_COUNT_W =...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/reconstruct-qcsr-birth-from-merged-fire/build/tb_ooo_core_top_glue_v9o_csr_qh.vvp

- `kind`: vvp
- `size_bytes`: 5923136
- `line_count`: 133573
- `sha256`: 7e923f735666e016b2b59864042811d833333bb5eb1ca4400922556ad904a0fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=5923136 bytes; lines=133573; PASS=2; tail=83154, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543781664, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1768842860, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1768384628, 0, 32; draw_st...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/reconstruct-qcsr-birth-from-merged-fire/driver.log

- `kind`: log
- `size_bytes`: 400
- `line_count`: 3
- `sha256`: b8b1deaad1fb07779514c0d54c7c5d8f83915a863e5f0aa7dfc1f60ac9d59c96
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {}
- `summary`: log evidence; size=400 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:382: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/reconstruct-qcsr-birth-from-...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/reconstruct-qcsr-birth-from-merged-fire/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log

- `kind`: log
- `size_bytes`: 33064
- `line_count`: 151
- `sha256`: 205de71b858a093afb9d8322d309564d596ff97525fd529fd82303f4516f5952
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 8, "PASS": 18}
- `summary`: log evidence; size=33064 bytes; lines=151; FAIL=8; PASS=18; tail=[TEST] tb_ooo_core_top_glue_v9o_csr_qh [COMPILE] iverilog -g2012 -Wall -I/tmp/v9x-reconstruct-qcsr-birth-from-merged-fire-01_lzckg/npc/rv64/vsrc -I/tmp/v9x-reconstruct-qcsr-birth-from-merged-fire-01_lzckg/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CS...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/owner-mutations/summary.json

- `kind`: json
- `size_bytes`: 4080
- `line_count`: 66
- `sha256`: e079df53f81939b5c3a9dbb2bb2ca029c3b3c9dfe5b0340d0e9fb368446a1e5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 4}
- `summary`: json evidence; size=4080 bytes; lines=66; FAIL=4; tail={ "cases": [ { "checks": { "compile_command_recorded": true, "directed_oracle_fired": true, "make_returned_nonzero": true, "production_source_unchanged": true, "result_rejected": true, "simulation_reached_final_v9p_marker": true }, "command": [ "make", "-B"...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/results/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25474
- `line_count`: 140
- `sha256`: c6b5fc83542662a7840876167267c91ff2465b9cdcdc41311701b40007fc753d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25474 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log

- `kind`: log
- `size_bytes`: 25826
- `line_count`: 145
- `sha256`: ecb90e3635d20789f11e637339caaa4948d965d94eed9bf9b667928825c3e064
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 20}
- `summary`: log evidence; size=25826 bytes; lines=145; PASS=20; tail=[TEST] tb_ooo_core_top_glue_v9o_csr_qh [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DV9O_CSR_QH_FOCUSED -s tb_ooo_core_top_glue...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/results/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8902
- `line_count`: 83
- `sha256`: d28da8a678ad13af2bd0953870c27e0ecf8eb8c2c73074dece5b755602c2c363
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8902 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/results/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 805
- `line_count`: 7
- `sha256`: a9ec2e5ecac9b79c1cf0291e01bf3ad52fa8e64b3c81a0703e7cb1589b1c3da0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=805 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/results/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27057
- `line_count`: 143
- `sha256`: fcff9807a4aee1dcde4a2c800b64fd986495507de807e49cf6869fc786cb5463
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27057 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/results/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 992
- `line_count`: 10
- `sha256`: ccdc454d2bd851db83f8992e0294b21d53bcb873b198f2d2978a2d88ec3baa18
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=992 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/post-v3/rtl-static-checks.log

- `kind`: log
- `size_bytes`: 543
- `line_count`: 10
- `sha256`: 9a6e5f143012c948ebb316743dbe8b6aae685001c435e3699287a9ad612b4101
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=543 bytes; lines=10; PASS=6; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' [check-rtl-style] PASS: 可综合 RTL 全部为 .v 且无 SV always_comb/always_ff/logic 关键字 ---------------------------------------------------------------------- Ran 14 tests in 4.994s OK [PRODUCER-HOLDER-CE...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/red-exit/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 648
- `line_count`: 7
- `sha256`: a999f847744182f75523d7deb139d3fd4539190132161306727a90ab81fc91af
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=648 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/red/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 1187
- `line_count`: 16
- `sha256`: c9fbff11805f8ef20b6476e042998de92e7ff33c69f724283546b125c2cf53bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: log evidence; size=1187 bytes; lines=16; FAIL=10; PASS=2; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/v3-flag-on/build/tb_ooo_core_top_glue_v9o_csr_qh.vvp

- `kind`: vvp
- `size_bytes`: 5907662
- `line_count`: 133237
- `sha256`: 3a4b2f53bbfaff3fe014b7037b5f85a7f1a6f03d046f0c30753c46e87704ae2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=5907662 bytes; lines=133237; PASS=2; tail=vec4 %pushi/vec4 1667786099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543319398, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1869767968, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1245...

### .github/task-runs/2026-07-26-rv64-v9x-serialize-recovery-owner-birth/evidence/v3-flag-on/results/logs/tb_ooo_core_top_glue_v9o_csr_qh.log

- `kind`: log
- `size_bytes`: 25812
- `line_count`: 144
- `sha256`: 79b1ab996a8ab280a041c8f9b55ed8a84079c8763263a84d0aa725c905e328ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T19:28:54+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=25812 bytes; lines=144; PASS=16; tail=[TEST] tb_ooo_core_top_glue_v9o_csr_qh [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DOOO_CSR_QUEUE_HEAD=1 -DV9O_CSR_QH_FOCUSED -s tb_ooo_core_top_glue...
