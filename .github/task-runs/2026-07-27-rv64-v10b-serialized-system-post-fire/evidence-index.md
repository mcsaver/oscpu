# Evidence Index

## 基本信息

- `task_id`: 2026-07-27-rv64-v10b-serialized-system-post-fire
- `task_slug`: 
- `profile`: 
- `asset_count`: 266
- `total_size_bytes`: 276173190

## 证据资产

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/current-assert/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540016
- `line_count`: 150049
- `sha256`: aa8451847d828868c1c676d52f350e9de094535fc44d73fa12a6a2f5f290e032
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540016 bytes; lines=150049; FAIL=6; PASS=3; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/current-assert/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28222
- `line_count`: 151
- `sha256`: 05b5ed32c80ab688eb6c96cd455660d52e77b6fe831b42fe0e5ddc37dc0e2fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=28222 bytes; lines=151; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/fence-mem-idle-unit-mutation/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 103089
- `line_count`: 2482
- `sha256`: 70cd7d71a924141749745877ee98af020f369f62fcac49f1f94b9ee7ce091196
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=103089 bytes; lines=2482; FAIL=3; PASS=2; tail=ng_vec4 %pushi/vec4 1852138528, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1786080624, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543321199, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/fence-mem-idle-unit-mutation/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 1095
- `line_count`: 12
- `sha256`: d942936b4779496d90d0253c2bd750eb2d1338f0f196e7bb4ee188702f3e9ca6
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 8, "PASS": 4}
- `summary`: log evidence; size=1095 bytes; lines=12; FAIL=8; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/fencei-cache-consumer/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2374788
- `line_count`: 60586
- `sha256`: a771ee1ba874c9cd8b40a309d9da08539e4a570f95302330306f96f5f33a5a67
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: vvp evidence; size=2374788 bytes; lines=60586; FAIL=4; PASS=3; tail=%store/vec4 v0x592fa8e34850_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x592fa8e35130_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x592fa8e34c60_0, 0, 1; %pushi/vec4 2, 0, 2; %store/vec4 v0x592fa8e34b90_0, 0, 2; %alloc S_0x592fa8e160a0; %fork TD_tb_ooo_fetch...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/fencei-cache-consumer/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105468
- `line_count`: 795
- `sha256`: 83a0925ea1652e9778760ddbb801c5323b9e970b394b945316fdc80bdcdb5d56
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=105468 bytes; lines=795; PASS=4; tail=in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/postchange-fencei-mmu-disconnected/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540219
- `line_count`: 150051
- `sha256`: de06cae66086f3e08030e9bb6e38388258235268ee01dfc21877caa3a3338d18
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540219 bytes; lines=150051; FAIL=6; PASS=3; tail=w_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/postchange-fencei-mmu-disconnected/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28244
- `line_count`: 156
- `sha256`: cdaa937c7c9a2550fbfb457b58ffb5c72393a19bcd86a69ef02041a978b7f98e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 12, "PASS": 32}
- `summary`: log evidence; size=28244 bytes; lines=156; FAIL=12; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/baseline-make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/baseline/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6415560
- `line_count`: 146916
- `sha256`: 4f7ebc1ffbf29c80f7253fcadbe5c2cd56689d26c5ff5f76b13c09fb6aa8b251
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6415560 bytes; lines=146916; FAIL=3; PASS=2; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/baseline/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27086
- `line_count`: 143
- `sha256`: ce8838e7680570b1962012b398b6746a57d4eec748ce6e8c6d0355da52975345
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27086 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/fencei-mmu-disconnected-make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/fencei-mmu-disconnected/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6415763
- `line_count`: 146918
- `sha256`: 8b708868e964868179f6fe049540eb03c8dac56a4d575fc92e7653c7fc98c33c
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6415763 bytes; lines=146918; FAIL=3; PASS=2; tail=w_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/fencei-mmu-disconnected/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27194
- `line_count`: 143
- `sha256`: d79689d1fcd86582a4f99798e95b9b9094e73917b44f317b1fe5d3ca0a180dfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27194 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/mutated/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: f380f44a147b63c95ddede303e3c6e0589f42cfdb2d67b0baca184fe71bc5628
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/report.json

- `kind`: json
- `size_bytes`: 3395
- `line_count`: 51
- `sha256`: 91619778af66e5b7383e2bc77ddeb31fe4e3b7a450042ea06224e15070b23cf6
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 2}
- `summary`: json evidence; size=3395 bytes; lines=51; PASS=2; tail={ "baseline": { "command": [ "make", "-C", "/home/lyg/PA/ysyx-workbench/npc/rv64/testbench", "RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/prechange-mmu-observation-gap/baseline", "BUILD_...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/add-mmu-action-to-every-drain/OooMemoryRequestGate.v

- `kind`: v
- `size_bytes`: 2502
- `line_count`: 79
- `sha256`: 23ab40dc595da93bc1ec8676cf9303f0465dede56acafa8e0c01bff9c811add7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2502 bytes; lines=79; markers=<none>; tail=`include "define.v" module OooMemoryRequestGate ( input clk, input rst, input core_local_flush_i, input checkpoint_mem_flush_i, input pending_system_satp_write_commit_i, input pending_system_sfence_commit_i, input pending_system_fencei_commit_i, input stop_...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/disconnect-fencei-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: f380f44a147b63c95ddede303e3c6e0589f42cfdb2d67b0baca184fe71bc5628
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/disconnect-satp-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2770
- `line_count`: 76
- `sha256`: f04abf00d84891c7bb089dee44f103b361a73ef4d4ace88535d29cfa0fbbea09
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2770 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/disconnect-sfence-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: a2bb83cb0799c2c97dfbea90aefbf8f2bccf387a2c32e47e314abc71275e5cd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/drop-sfence-inval-ir-classification/DecodeUnit.v

- `kind`: v
- `size_bytes`: 31490
- `line_count`: 813
- `sha256`: 7e2b4b882ce945bff5ecfd362d0039bcbf61c0b22c355c69f23f08aadefe8b71
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 2}
- `summary`: v evidence; size=31490 bytes; lines=813; FAIL=2; tail=`include "define.v" module DecodeUnit ( input [`INST_W-1:0] inst_i, output reg [`CTRL_BUS_W-1:0] ctrl_o, output [`REG_ADDR_W-1:0] rs1_idx_o, output [`REG_ADDR_W-1:0] rs2_idx_o, output [`REG_ADDR_W-1:0] rd_idx_o ); wire [6:0] opcode_w = inst_i[6:0]; wire [2:...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/fencei-reason-to-serial/OooFrontend.v

- `kind`: v
- `size_bytes`: 117941
- `line_count`: 2494
- `sha256`: dcbc85faf43403254fc0eb26f411cef36672242f23852de5948f1ec7bde77313
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=117941 bytes; lines=2494; markers=<none>; tail=assign branch_prefetch_req_pc_w = {`XLEN{1'b0}}; // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0） assign branch_prefetch_match_w = 1'b0; assign branch_prefetch_buffer_match_w = 1'b0; assign branch_prefetch_pending_match_w = 1'b0; assign branch_prefe...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/remove-csr-pc-match/OooCsrAccessRequestMux.v

- `kind`: v
- `size_bytes`: 5077
- `line_count`: 125
- `sha256`: e97305b784d49ce5a4ece56ef44df0abde48ea43988f71f4bf76ed7ae5d77deb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=5077 bytes; lines=125; markers=<none>; tail=`include "include/define.v" module OooCsrAccessRequestMux #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input wire core_commit0_valid_i, input wire cor...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/remove-csr-producerid-match/OooCsrAccessRequestMux.v

- `kind`: v
- `size_bytes`: 5076
- `line_count`: 125
- `sha256`: 6a843f1b982ef4efa594f56f7891a4f9f77c5642f17bb146dac5a97f7b662f0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=5076 bytes; lines=125; markers=<none>; tail=`include "include/define.v" module OooCsrAccessRequestMux #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input wire core_commit0_valid_i, input wire cor...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/remove-fence-mem-idle/OooPendingDrainResolveGate.v

- `kind`: v
- `size_bytes`: 4809
- `line_count`: 108
- `sha256`: 7727b8c0553aaf4ac042aca6009426c1fc517d7ce51774ee165af893e5173caa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=4809 bytes; lines=108; markers=<none>; tail=`include "define.v" // stop-pending 之后的 drain/resolve 事件归 control 中枢，core glue 只转接事件。 module OooPendingDrainResolveGate #( parameter ROB_COUNT_W = `OOO_ROB_COUNT_W, parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W )( input [ROB_COUNT_W-1:0] rob_count_i, input [...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/remove-wfi-control-commit/OooWriteback.v

- `kind`: v
- `size_bytes`: 9162
- `line_count`: 226
- `sha256`: 804abb7f99e8f0ca8443c3876b66b581e058a77cec88f61cb02e900c49c8dae7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=9162 bytes; lines=226; markers=<none>; tail=`include "define.v" `include "common/OooSlotFacts.v" // OooWriteback: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 5 个实例）。 // 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。 module OooWriteback ( input clk, input core_commit0_exception_w, input [`INST_W-1:0] core_commit...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/retain-noncsr-holder-after-terminal/OooPendingSystemSequencer.v

- `kind`: v
- `size_bytes`: 12333
- `line_count`: 327
- `sha256`: 46c043255a50475812f7895299331f56c0e93fad4b4be8fe29089596d2c64b99
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=12333 bytes; lines=327; markers=<none>; tail=`include "define.v" module OooPendingSystemSequencer #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input clk, input rst, input clear_i, input clear_dis...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/retain-stop-after-drain-terminal/OooStopPendingSequencer.v

- `kind`: v
- `size_bytes`: 6767
- `line_count`: 156
- `sha256`: ac260f4988f79ffe38b216a59d084f1c239d7f27dfba2ecd0ad938b02912f3aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=6767 bytes; lines=156; markers=<none>; tail=`include "define.v" module OooStopPendingSequencer ( input wire clk, input wire rst, input wire flush_i, input wire csr_trap_mem_valid_i, input wire direct_frontend_flush_i, input wire direct_branch0_fire_i, input wire direct_branch1_fire_i, input wire dire...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/mutated/sfence-reason-to-serial/OooFrontend.v

- `kind`: v
- `size_bytes`: 117941
- `line_count`: 2494
- `sha256`: c248476177fa8bfd5a68bc4ccbf1027764f80e9db5a2601b8037423f447477cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=117941 bytes; lines=2494; markers=<none>; tail=assign branch_prefetch_req_pc_w = {`XLEN{1'b0}}; // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0） assign branch_prefetch_match_w = 1'b0; assign branch_prefetch_buffer_match_w = 1'b0; assign branch_prefetch_pending_match_w = 1'b0; assign branch_prefe...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/add-mmu-action-to-every-drain/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540586
- `line_count`: 150071
- `sha256`: 4004128cdf5dcf4519ed0fb47f9f03f2cc15c31c4781b1b25c0ec1c0c07d0d59
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540586 bytes; lines=150071; FAIL=6; PASS=3; tail=i/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/add-mmu-action-to-every-drain/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/add-mmu-action-to-every-drain/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 34960
- `line_count`: 244
- `sha256`: 67d2add9f85af044a21bb3dc39808f0dd6035ab98f24c728f1b0c567559dc3d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 194, "PASS": 26}
- `summary`: log evidence; size=34960 bytes; lines=244; FAIL=194; PASS=26; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/add-mmu-action-to-every-drain/make.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 3
- `sha256`: fef67b5345c68dedcb97783e3502937ffe6ef108cda3204171df165d9212fd2a
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=371 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/add-mmu-action-to-every-dr...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/csr-access-assert/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: b0c3e3c05e1c0b0a0316667b780e080d440b994a0a63a01d787b12c3f2378704
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/csr-access-assert/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/csr-access-assert/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 763
- `line_count`: 5
- `sha256`: 58fb569ff447787ae8da25697e48b0ed977408d1e07f1b39de469b0315a5d6d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=763 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/csr-access-assert/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-fencei-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540234
- `line_count`: 150051
- `sha256`: c12df2615f14b65606fc1f88031465ea7d1efb91d0f76d426bd3d38638126f36
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540234 bytes; lines=150051; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-fencei-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-fencei-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28390
- `line_count`: 156
- `sha256`: 4a2647afe589afa508da5925a8559628c3cb371b9b5d031d3d8e546592d3dcf3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 12, "PASS": 32}
- `summary`: log evidence; size=28390 bytes; lines=156; FAIL=12; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-fencei-mmu/make.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 3
- `sha256`: bcbe046e4fb40a9c1ff9d3433b54d5937626dc20295b73114c2fd645ecbfd00b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=363 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-fencei-mmu/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-satp-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540232
- `line_count`: 150051
- `sha256`: 1adeef5b9fa427cb4099e7a5b0a610ebdf8649386417aaba16044639b5d7e3f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540232 bytes; lines=150051; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-satp-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-satp-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28447
- `line_count`: 156
- `sha256`: 58e063c6208f86f59b1a4820e1032b2b0c1fbc8685ad1973f9d01932fed67305
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 12, "PASS": 32}
- `summary`: log evidence; size=28447 bytes; lines=156; FAIL=12; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-satp-mmu/make.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 3
- `sha256`: fa15bf5a755bb7c498a3b024ae67e2422829c0cd6226b082b5cc6fdfe542669e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=361 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-satp-mmu/logs/t...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-sfence-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540234
- `line_count`: 150051
- `sha256`: f54ede7e3df8c5216db87ffb5d0f97d43b6b9b70985a86441b7d77b5ea00b5aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540234 bytes; lines=150051; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-sfence-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-sfence-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28646
- `line_count`: 160
- `sha256`: b23b89ab754e81d79e1d4f0476bac427798b946b6a75a39c40b4d634cc423395
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 24, "PASS": 28}
- `summary`: log evidence; size=28646 bytes; lines=160; FAIL=24; PASS=28; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-sfence-mmu/make.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 3
- `sha256`: a24240d0489d8c03f0cd36e245a123ec22f295a1bb7f40134de2f334cecd3ff1
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=363 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/disconnect-sfence-mmu/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/drop-sfence-inval-ir-classification/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540144
- `line_count`: 150049
- `sha256`: 87bd8e4dc035167a4bce6ee8cc131c26c985e8fadd15d82e5e0f1a1d36e733c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540144 bytes; lines=150049; FAIL=6; PASS=3; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/drop-sfence-inval-ir-classification/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/drop-sfence-inval-ir-classification/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 29130
- `line_count`: 164
- `sha256`: 5ab1777c98549eea7becdf20c3df125117f31b10da4da13b75f1db48110dec87
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 28, "PASS": 32}
- `summary`: log evidence; size=29130 bytes; lines=164; FAIL=28; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/drop-sfence-inval-ir-classification/make.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 3
- `sha256`: f287bc000c0d1131ca08a85c20909d8ec6ebab0c0219c8b40b435df8a203604a
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=377 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/drop-sfence-inval-ir-class...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/fencei-reason-to-serial/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540124
- `line_count`: 150049
- `sha256`: 834fcbfea2e7e67ac40c8baebdd328f6a7314b6c4a1bce3c8c1b2899e315416d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540124 bytes; lines=150049; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/fencei-reason-to-serial/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/fencei-reason-to-serial/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28647
- `line_count`: 158
- `sha256`: b923ba6bb2c60d3fb871346eafe4ec8209d4b8abcb530615052118130c15dfde
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 16, "PASS": 32}
- `summary`: log evidence; size=28647 bytes; lines=158; FAIL=16; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/fencei-reason-to-serial/make.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 3
- `sha256`: bdf1fadf95b6d3408e28308f745d8fa83b22243e0d035aafcc42f0395267054b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=365 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/fencei-reason-to-serial/lo...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-assert/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540016
- `line_count`: 150049
- `sha256`: 1d56f3c8d19e366e51dd79f61b0bc4927b90c53008bbc415c658adc54c702b5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540016 bytes; lines=150049; FAIL=6; PASS=3; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-assert/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-assert/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28370
- `line_count`: 151
- `sha256`: cce5601a48b176b6139bce69f31c6326a89343934d7c8c6c6b495ef5e92c3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=28370 bytes; lines=151; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-assert/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-release/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 5750035
- `line_count`: 125268
- `sha256`: e30a934933469f555acaf9451404294a0e830827fb413fb3f049ee8d648ae714
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=5750035 bytes; lines=125268; FAIL=6; PASS=3; tail=ing_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-release/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-release/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27511
- `line_count`: 144
- `sha256`: e187ab0f2ffbf6b4db2136b8271647bf43a672cd52be32eeaf58ec5964c3fed3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=27511 bytes; lines=144; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/priv-system-release/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-pc-match/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48611
- `line_count`: 1142
- `sha256`: 31051a19271837b55a6fc78d64e998259a83a8a54f9e53e52455285d53432eb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48611 bytes; lines=1142; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-pc-match/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-pc-match/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 1040
- `line_count`: 7
- `sha256`: da83b540041564a8e878869b3833bc966e5137c7890e507c29b306b6809ba87f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1040 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-pc-match/make.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 3
- `sha256`: e4be24b8cbfc103c5b47826f6286aa52d832d63e9dfbdb2eca3717790e82ae58
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=372 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-pc-match/logs/t...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-producerid-match/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48619
- `line_count`: 1142
- `sha256`: 018be69851bed00b327b7bfe107ac315934b5b985b6189063b5c0d4d7faa08c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48619 bytes; lines=1142; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-producerid-match/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-producerid-match/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 1056
- `line_count`: 7
- `sha256`: c5dd9df8b9ed9d7f541570a5c2b51325d4231890fde721b3f9580736e8039e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1056 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-producerid-match/make.log

- `kind`: log
- `size_bytes`: 380
- `line_count`: 3
- `sha256`: ed89fe5df609bde9224982a89706e7d3907faf72a5176e746e90822615f88733
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=380 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-csr-producerid-matc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-fence-mem-idle/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6539986
- `line_count`: 150047
- `sha256`: ef29a032160471a71215365a0de2bf381e64d15d2710bdab8a9c27980bc74538
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6539986 bytes; lines=150047; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-fence-mem-idle/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-fence-mem-idle/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28480
- `line_count`: 151
- `sha256`: a6da1229d7f48ef9863f7945acd0bf4f3e4927f65eeefcf4339baa34114dafa1
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=28480 bytes; lines=151; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-fence-mem-idle/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-wfi-control-commit/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540502
- `line_count`: 150054
- `sha256`: ded8ab0f31e0fde4f0676c7452ab3caedd3190c43285e9fd2159fdba48e27653
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540502 bytes; lines=150054; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-wfi-control-commit/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-wfi-control-commit/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28470
- `line_count`: 158
- `sha256`: abd5c56bb39edfd8b62687d1151efb3503ed621f72613b78dd74b65266f959b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 18, "PASS": 30}
- `summary`: log evidence; size=28470 bytes; lines=158; FAIL=18; PASS=30; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-wfi-control-commit/make.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 3
- `sha256`: 17f4d22c7bc1df678bda056ebbdd560a5eacef2fc77cd101b55b172c6276bbe2
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=367 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/remove-wfi-control-commit/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-noncsr-holder-after-terminal/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540318
- `line_count`: 150058
- `sha256`: 51d11938fe2e8dbf3ac612e38db201313efdb8d6ba5415a9d39a22846950d4b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540318 bytes; lines=150058; FAIL=6; PASS=3; tail=4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-noncsr-holder-after-terminal/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-noncsr-holder-after-terminal/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 25962
- `line_count`: 140
- `sha256`: c85fe482437a976f8a1f9affaf3ef7cd050c4b06b4722f06f6a9ef7e7e807c6e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"ERROR": 4, "FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=25962 bytes; lines=140; FAIL=6; ERROR=4; PASS=2; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-noncsr-holder-after-terminal/make.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 3
- `sha256`: b2b86965a42c715cfbcc830c490626884f41feb02cc789b97bcd2ea55b3c8b13
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=377 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-noncsr-holder-after...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-stop-after-drain-terminal/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540250
- `line_count`: 150055
- `sha256`: 488220f8f8f135bcb2c7104b6fe75e0b465fe50dfa3dac61c03b822f7f95aa5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540250 bytes; lines=150055; FAIL=6; PASS=3; tail=vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; d...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-stop-after-drain-terminal/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-stop-after-drain-terminal/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 26249
- `line_count`: 140
- `sha256`: 873c06365c919d6cd0a6e648270fc06394d2d043150bf50b2621772bf9a5da59
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"ERROR": 4, "FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=26249 bytes; lines=140; FAIL=6; ERROR=4; PASS=2; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-stop-after-drain-terminal/make.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 3
- `sha256`: f5c5783c67b4b9d203dec2b26c95d05ab422f19aa780feef54ba44955f7b5ca3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=374 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/retain-stop-after-drain-te...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/sfence-reason-to-serial/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540124
- `line_count`: 150049
- `sha256`: 4e1a03b47ef8e92a455c23663bb4b0ea9956eba24a3b4ceafe9963779eed917d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540124 bytes; lines=150049; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/sfence-reason-to-serial/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/sfence-reason-to-serial/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 29254
- `line_count`: 163
- `sha256`: 290b5d3a1dc0acdbb6fad65e784052180e3d9739f1e2756050c3220e24c132ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 28, "PASS": 30}
- `summary`: log evidence; size=29254 bytes; lines=163; FAIL=28; PASS=30; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/sfence-reason-to-serial/make.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 3
- `sha256`: 403bbfda5650b62e5eeda15dd86b953620d005d4d6782158ca528d73a1479642
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=365 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/sfence-reason-to-serial/lo...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/status.json

- `kind`: json
- `size_bytes`: 77
- `line_count`: 6
- `sha256`: 0e99ad98c967b8c43b87cb661d210eddbe3e6c734716f254a006d8ff3feded24
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: json evidence; size=77 bytes; lines=6; markers=<none>; tail={ "all_pass": false, "completed": 16, "state": "DONE", "total": 16 }

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/summary.json

- `kind`: json
- `size_bytes`: 37109
- `line_count`: 568
- `sha256`: bb530f17f691c9ef9b3cfd45d90c2c1cd3ea077a2121ff249388c8f416b6539b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: json evidence; size=37109 bytes; lines=568; markers=<none>; tail={ "all_pass": false, "cases": [ { "command": [ "make", "-C", "/home/lyg/PA/ysyx-workbench/npc/rv64/testbench", "RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/runs/pr...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v1/summary.md

- `kind`: md
- `size_bytes`: 1581
- `line_count`: 24
- `sha256`: 11f4f82ab274e6b92e605454c61fe2c951cf799b4a97aa6a4dc4ee27288b8504
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 24, "PASS": 38}
- `summary`: md evidence; size=1581 bytes; lines=24; FAIL=24; PASS=38; tail=# V10B focused matrix v1 | case | test | compile | result | simulation | verdict | | --- | --- | ---: | --- | --- | --- | | `priv-system-assert` | `tb_ooo_priv_system` | 0 | PASS | accepted | PASS | | `priv-system-release` | `tb_ooo_priv_system` | 0 | PASS...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/add-mmu-action-to-every-drain/OooMemoryRequestGate.v

- `kind`: v
- `size_bytes`: 2502
- `line_count`: 79
- `sha256`: 23ab40dc595da93bc1ec8676cf9303f0465dede56acafa8e0c01bff9c811add7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2502 bytes; lines=79; markers=<none>; tail=`include "define.v" module OooMemoryRequestGate ( input clk, input rst, input core_local_flush_i, input checkpoint_mem_flush_i, input pending_system_satp_write_commit_i, input pending_system_sfence_commit_i, input pending_system_fencei_commit_i, input stop_...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/disconnect-fencei-fetch-cache-clear/OooFetchAxiBridge.v

- `kind`: v
- `size_bytes`: 73219
- `line_count`: 1660
- `sha256`: 43a2f71d00312edc55c8d617ce83b1e7b4fae463072e2639e05aa3a42f5a0d2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=73219 bytes; lines=1660; markers=<none>; tail=sv39_enabled = (priv_mode != `PRIV_M) && (satp[63:60] == 4'h8); end endfunction function canonical_sv39; input [`XLEN-1:0] vaddr; begin canonical_sv39 = (vaddr[63:39] == {25{vaddr[38]}}); end endfunction function [8:0] vpn_by_level; input [`XLEN-1:0] vaddr;...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/disconnect-fencei-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: f380f44a147b63c95ddede303e3c6e0589f42cfdb2d67b0baca184fe71bc5628
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/disconnect-satp-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2770
- `line_count`: 76
- `sha256`: f04abf00d84891c7bb089dee44f103b361a73ef4d4ace88535d29cfa0fbbea09
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2770 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/disconnect-sfence-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: a2bb83cb0799c2c97dfbea90aefbf8f2bccf387a2c32e47e314abc71275e5cd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/drop-sfence-inval-ir-classification/DecodeUnit.v

- `kind`: v
- `size_bytes`: 31490
- `line_count`: 813
- `sha256`: 7e2b4b882ce945bff5ecfd362d0039bcbf61c0b22c355c69f23f08aadefe8b71
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 2}
- `summary`: v evidence; size=31490 bytes; lines=813; FAIL=2; tail=`include "define.v" module DecodeUnit ( input [`INST_W-1:0] inst_i, output reg [`CTRL_BUS_W-1:0] ctrl_o, output [`REG_ADDR_W-1:0] rs1_idx_o, output [`REG_ADDR_W-1:0] rs2_idx_o, output [`REG_ADDR_W-1:0] rd_idx_o ); wire [6:0] opcode_w = inst_i[6:0]; wire [2:...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/fencei-reason-to-serial/OooFrontend.v

- `kind`: v
- `size_bytes`: 117941
- `line_count`: 2494
- `sha256`: dcbc85faf43403254fc0eb26f411cef36672242f23852de5948f1ec7bde77313
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=117941 bytes; lines=2494; markers=<none>; tail=assign branch_prefetch_req_pc_w = {`XLEN{1'b0}}; // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0） assign branch_prefetch_match_w = 1'b0; assign branch_prefetch_buffer_match_w = 1'b0; assign branch_prefetch_pending_match_w = 1'b0; assign branch_prefe...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/remove-csr-pc-match/OooCsrAccessRequestMux.v

- `kind`: v
- `size_bytes`: 5077
- `line_count`: 125
- `sha256`: e97305b784d49ce5a4ece56ef44df0abde48ea43988f71f4bf76ed7ae5d77deb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=5077 bytes; lines=125; markers=<none>; tail=`include "include/define.v" module OooCsrAccessRequestMux #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input wire core_commit0_valid_i, input wire cor...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/remove-csr-producerid-match/OooCsrAccessRequestMux.v

- `kind`: v
- `size_bytes`: 5076
- `line_count`: 125
- `sha256`: 6a843f1b982ef4efa594f56f7891a4f9f77c5642f17bb146dac5a97f7b662f0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=5076 bytes; lines=125; markers=<none>; tail=`include "include/define.v" module OooCsrAccessRequestMux #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input wire core_commit0_valid_i, input wire cor...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/remove-fence-mem-idle/OooPendingDrainResolveGate.v

- `kind`: v
- `size_bytes`: 4809
- `line_count`: 108
- `sha256`: 7727b8c0553aaf4ac042aca6009426c1fc517d7ce51774ee165af893e5173caa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=4809 bytes; lines=108; markers=<none>; tail=`include "define.v" // stop-pending 之后的 drain/resolve 事件归 control 中枢，core glue 只转接事件。 module OooPendingDrainResolveGate #( parameter ROB_COUNT_W = `OOO_ROB_COUNT_W, parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W )( input [ROB_COUNT_W-1:0] rob_count_i, input [...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/remove-wfi-control-commit/OooWriteback.v

- `kind`: v
- `size_bytes`: 9162
- `line_count`: 226
- `sha256`: 804abb7f99e8f0ca8443c3876b66b581e058a77cec88f61cb02e900c49c8dae7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=9162 bytes; lines=226; markers=<none>; tail=`include "define.v" `include "common/OooSlotFacts.v" // OooWriteback: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 5 个实例）。 // 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。 module OooWriteback ( input clk, input core_commit0_exception_w, input [`INST_W-1:0] core_commit...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/retain-noncsr-holder-after-terminal/OooPendingSystemSequencer.v

- `kind`: v
- `size_bytes`: 12333
- `line_count`: 327
- `sha256`: 46c043255a50475812f7895299331f56c0e93fad4b4be8fe29089596d2c64b99
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=12333 bytes; lines=327; markers=<none>; tail=`include "define.v" module OooPendingSystemSequencer #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input clk, input rst, input clear_i, input clear_dis...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/retain-stop-after-drain-terminal/OooStopPendingSequencer.v

- `kind`: v
- `size_bytes`: 6767
- `line_count`: 156
- `sha256`: ac260f4988f79ffe38b216a59d084f1c239d7f27dfba2ecd0ad938b02912f3aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=6767 bytes; lines=156; markers=<none>; tail=`include "define.v" module OooStopPendingSequencer ( input wire clk, input wire rst, input wire flush_i, input wire csr_trap_mem_valid_i, input wire direct_frontend_flush_i, input wire direct_branch0_fire_i, input wire direct_branch1_fire_i, input wire dire...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/mutated/sfence-reason-to-serial/OooFrontend.v

- `kind`: v
- `size_bytes`: 117941
- `line_count`: 2494
- `sha256`: c248476177fa8bfd5a68bc4ccbf1027764f80e9db5a2601b8037423f447477cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=117941 bytes; lines=2494; markers=<none>; tail=assign branch_prefetch_req_pc_w = {`XLEN{1'b0}}; // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0） assign branch_prefetch_match_w = 1'b0; assign branch_prefetch_buffer_match_w = 1'b0; assign branch_prefetch_pending_match_w = 1'b0; assign branch_prefe...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/add-mmu-action-to-every-drain/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540586
- `line_count`: 150071
- `sha256`: 82cd88b974b0ed875db7680a2e630e9ec8e57e037bd726e2b3dff7cbbc966a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540586 bytes; lines=150071; FAIL=6; PASS=3; tail=i/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/add-mmu-action-to-every-drain/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/add-mmu-action-to-every-drain/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 34960
- `line_count`: 244
- `sha256`: bf2b1bad0ee6f4e368a8acde62ab04a587ced32109c69374c68062226d02382b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 194, "PASS": 26}
- `summary`: log evidence; size=34960 bytes; lines=244; FAIL=194; PASS=26; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/add-mmu-action-to-every-drain/make.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 3
- `sha256`: ca2ae9891622dc7726d1e6bf1a8325aa46f7a0262b453aea54d69c9670fe82b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=371 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/add-mmu-action-to-every-dr...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/csr-access-assert/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: e45978e2fb1709afdba4bcf3cd4ae0c99dfbe5a4de1cae0835eb771af5cde62b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/csr-access-assert/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/csr-access-assert/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 763
- `line_count`: 5
- `sha256`: b2244a9bdfcfc11faa028e231eab036c028712f313c5c6426812114f306bda74
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=763 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/csr-access-assert/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-fetch-cache-clear/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2374962
- `line_count`: 60587
- `sha256`: f3479a8f402757c2f454acd7664c853ca20526cbd537ee4513a40cc9a3e4e497
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: vvp evidence; size=2374962 bytes; lines=60587; FAIL=4; PASS=3; tail=c4 1, 0, 1; %store/vec4 v0x5eb61d235d60_0, 0, 1; %pushi/vec4 2, 0, 2; %store/vec4 v0x5eb61d235c90_0, 0, 2; %alloc S_0x5eb61d2171a0; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x5eb61d2171a0; %join; %free S_0x5eb61d2171a0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-fetch-cache-clear/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-fetch-cache-clear/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 106608
- `line_count`: 811
- `sha256`: 7c522da05c1f49a7f9dac362063176a109e04d8864b04140ee84733e528ca396
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 15, "PASS": 2}
- `summary`: log evidence; size=106608 bytes; lines=811; FAIL=15; PASS=2; tail=c/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-fetch-cache-clear/make.log

- `kind`: log
- `size_bytes`: 382
- `line_count`: 3
- `sha256`: 20f2f093e37d44c9a45fef7d3f15689e166a0ef3270fd273933eb161709ceb20
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=382 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-fetch-ca...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540234
- `line_count`: 150051
- `sha256`: a6869141fa91e55a031b5aa86a840aee725a241e937d3ef99a440b434c36f651
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540234 bytes; lines=150051; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28390
- `line_count`: 156
- `sha256`: c8c6042bb79bf4766cca42daf8ca5fd308f5157a63f2b397c1802864daf03b0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 12, "PASS": 32}
- `summary`: log evidence; size=28390 bytes; lines=156; FAIL=12; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-mmu/make.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 3
- `sha256`: 95facb7628065935dae5cb2a53a8dc4f74d847c97d3c020ed93bda211c874a22
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=363 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-fencei-mmu/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-satp-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540232
- `line_count`: 150051
- `sha256`: d3370917468c70e6d6de396da12dc35a8cfb73d45d0dcc1f28d3364122cb147b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540232 bytes; lines=150051; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-satp-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-satp-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28447
- `line_count`: 156
- `sha256`: 93c32ce73ca7e460cf70909c659c757d48406959307d8a7b643e8ac60cc3a977
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 12, "PASS": 32}
- `summary`: log evidence; size=28447 bytes; lines=156; FAIL=12; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-satp-mmu/make.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 3
- `sha256`: be2ee707a764e052f3d01a36fa44fa7a95c1370bd27ee607127b183a78c13d53
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=361 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-satp-mmu/logs/t...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-sfence-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540234
- `line_count`: 150051
- `sha256`: 3ae1de477268c0b765382dd5d7a999c0f073159de7b65ef1bb145fb3387159f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540234 bytes; lines=150051; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-sfence-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-sfence-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28646
- `line_count`: 160
- `sha256`: b8217ee07a68c9eb5bcd5968fcf3ab04a6a22ec9dd91641710a87bbb50b22b2e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 24, "PASS": 28}
- `summary`: log evidence; size=28646 bytes; lines=160; FAIL=24; PASS=28; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-sfence-mmu/make.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 3
- `sha256`: 7e9cd38764ab9b9f0bd260d9dc5bc3530d9607ac4f67b7ee4d36e19ce7abe2c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=363 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/disconnect-sfence-mmu/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/drop-sfence-inval-ir-classification/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540144
- `line_count`: 150049
- `sha256`: 8befd1e58b9db6f9dfe9f59dce0d542845bcefc473b8c03b74d1655b07d059bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540144 bytes; lines=150049; FAIL=6; PASS=3; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/drop-sfence-inval-ir-classification/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/drop-sfence-inval-ir-classification/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 29130
- `line_count`: 164
- `sha256`: ac3cd3a79ba49cb82848904cf2a9c96d447d5f2917201a64054174f0469cc658
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 28, "PASS": 32}
- `summary`: log evidence; size=29130 bytes; lines=164; FAIL=28; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/drop-sfence-inval-ir-classification/make.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 3
- `sha256`: 180c56485938474358ef012605b8435680752ae4ee22bda726f7680158ed101b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=377 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/drop-sfence-inval-ir-class...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/fencei-reason-to-serial/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540124
- `line_count`: 150049
- `sha256`: 094069595289fff954408b2982b5aa6a025848617d94ff7a5f0abc4d11867aa1
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540124 bytes; lines=150049; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/fencei-reason-to-serial/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/fencei-reason-to-serial/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28647
- `line_count`: 158
- `sha256`: a7c98721cf2771b5b00ba4eb2211345e784c85774e3e6c19b783ca8f6a9af6a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 16, "PASS": 32}
- `summary`: log evidence; size=28647 bytes; lines=158; FAIL=16; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/fencei-reason-to-serial/make.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 3
- `sha256`: 947ade27756cb19b65d65d8ee7a911fbc190698b8ee60934a3efc5c069087a3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=365 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/fencei-reason-to-serial/lo...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-assert/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540016
- `line_count`: 150049
- `sha256`: 49b2b6700feb1b95c97a20c16e9f68bc5a5941648be72e5f1de20241c080d596
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540016 bytes; lines=150049; FAIL=6; PASS=3; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-assert/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-assert/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28370
- `line_count`: 151
- `sha256`: 8243b4c120cf33c0918be4222bf775a039ddfde253ac9549da5122654c2dbc87
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=28370 bytes; lines=151; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-assert/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-release/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 5750035
- `line_count`: 125268
- `sha256`: d459a3493234dcf09e19dd1412a8b024ae8f8a7ce1cdc406989955e6bafd52b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=5750035 bytes; lines=125268; FAIL=6; PASS=3; tail=ing_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-release/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-release/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27511
- `line_count`: 144
- `sha256`: 6632a2c3466e9464bd4a775e98ef190e1b921e94f311c04e13bc008d943881bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=27511 bytes; lines=144; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/priv-system-release/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-pc-match/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48611
- `line_count`: 1142
- `sha256`: a0582d634505b5266fd4076b7678dd7ecc712798a79a4c81df543ca98626e6a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48611 bytes; lines=1142; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-pc-match/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-pc-match/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 1040
- `line_count`: 7
- `sha256`: cf2258defe6f380f457a57d740f4e5917db3a01e8fb34d55e47c407e6e9db83d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1040 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-pc-match/make.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 3
- `sha256`: 591f12918338d70cc57b7ec19c70435fd0f3575cd125aa73ac63b3ae60909e3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=372 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-pc-match/logs/t...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-producerid-match/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48619
- `line_count`: 1142
- `sha256`: d36405a2fd43d5ede05f0a4394743e0198ee876a3caa57c9dde1dd7d7f88f7b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48619 bytes; lines=1142; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-producerid-match/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-producerid-match/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 1056
- `line_count`: 7
- `sha256`: 042aecb7bf1fee4e2a9c7a497d01e0604f21cd4748473d673212d179811f3874
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1056 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-producerid-match/make.log

- `kind`: log
- `size_bytes`: 380
- `line_count`: 3
- `sha256`: e7ab5c4ce191a0e4443ee8ad426bfda8b0a419e5c3d5dea2c7ec6bb5f31d5dd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=380 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-csr-producerid-matc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-fence-mem-idle/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 103089
- `line_count`: 2482
- `sha256`: 50b9219eb466b2e27eefb2fac29d6abc7bd3a4eb697f1355af3525662ae581cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=103089 bytes; lines=2482; FAIL=3; PASS=2; tail=ng_vec4 %pushi/vec4 1852138528, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1786080624, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543321199, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-fence-mem-idle/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-fence-mem-idle/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 1232
- `line_count`: 12
- `sha256`: 6e944be7995a9569edc6a90ea75cbf4ead0ef542890b9ed327b9da09e2a58ce7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 8, "PASS": 4}
- `summary`: log evidence; size=1232 bytes; lines=12; FAIL=8; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-fence-mem-idle/make.log

- `kind`: log
- `size_bytes`: 378
- `line_count`: 3
- `sha256`: f43525ee1f1176ea451ee945ed14824a30af1087b69ee0507eb42192f0879d8c
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=378 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-fence-mem-idle/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-wfi-control-commit/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540502
- `line_count`: 150054
- `sha256`: 91b061aab5b5948d1c2b11c8ae255b084945143d1a072b29b99aa36b91e36483
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540502 bytes; lines=150054; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-wfi-control-commit/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-wfi-control-commit/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28470
- `line_count`: 158
- `sha256`: afa5fb305293cb9bcfa737abc2f8d0596ce9af4240e4f943f702245da5188d44
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 18, "PASS": 30}
- `summary`: log evidence; size=28470 bytes; lines=158; FAIL=18; PASS=30; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-wfi-control-commit/make.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 3
- `sha256`: 04e33d896ac1025777019ded977cc0c2cbb5145e0fd2c4ed500034b71915bc51
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=367 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/remove-wfi-control-commit/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-noncsr-holder-after-terminal/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540318
- `line_count`: 150058
- `sha256`: 688f9e6da8ba7370e3e22fc7465b92d3d10c54708a5303017ffc1a9214fbff18
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540318 bytes; lines=150058; FAIL=6; PASS=3; tail=4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-noncsr-holder-after-terminal/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-noncsr-holder-after-terminal/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 25962
- `line_count`: 140
- `sha256`: 39dc2f79affcbeb8422ddbde9e684ef6e9967f6c665bf0174e855fe611b9ca89
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"ERROR": 4, "FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=25962 bytes; lines=140; FAIL=6; ERROR=4; PASS=2; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-noncsr-holder-after-terminal/make.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 3
- `sha256`: 43568f4ba879d3d6dfc7e2aa615ae444d18ad5b50bef8459619f19c2c251715d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=377 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-noncsr-holder-after...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-stop-after-drain-terminal/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540250
- `line_count`: 150055
- `sha256`: 0e13d61c6843eb3cffe6fd5a328672e934e5b3f3e1622c4d983be24962d3a311
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540250 bytes; lines=150055; FAIL=6; PASS=3; tail=vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; d...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-stop-after-drain-terminal/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-stop-after-drain-terminal/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 26249
- `line_count`: 140
- `sha256`: ad6d4efba4d972ffa9512f7876350462a79b85ddf9577bc4ae15070aec7e3d8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"ERROR": 4, "FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=26249 bytes; lines=140; FAIL=6; ERROR=4; PASS=2; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-stop-after-drain-terminal/make.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 3
- `sha256`: 2e57f905dbb291e8d255c8a22ea6f9b3bef2a9f6c64acc73b69f45790db98b18
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=374 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/retain-stop-after-drain-te...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/sfence-reason-to-serial/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540124
- `line_count`: 150049
- `sha256`: 042e105e72fcf6b202a8f9dd0e0ffcd8b4d2a784cf96be33ae729bdc2734cfe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540124 bytes; lines=150049; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/sfence-reason-to-serial/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/sfence-reason-to-serial/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 29254
- `line_count`: 163
- `sha256`: 8efc36fa33b8a6692c57b7bb99c2d269ffabfc6b321fd35a87c6d9b38ed284f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 28, "PASS": 30}
- `summary`: log evidence; size=29254 bytes; lines=163; FAIL=28; PASS=30; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/sfence-reason-to-serial/make.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 3
- `sha256`: 83947cc05c657e35de884fa15995f1da7843c016e2daa31649cb4b40cb1be167
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=365 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/sfence-reason-to-serial/lo...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/status.json

- `kind`: json
- `size_bytes`: 76
- `line_count`: 6
- `sha256`: adc25f8d3bc17decd297dfea3e54c11828716a235dc69897356e279ae1d0cd99
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: json evidence; size=76 bytes; lines=6; markers=<none>; tail={ "all_pass": true, "completed": 17, "state": "DONE", "total": 17 }

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/summary.json

- `kind`: json
- `size_bytes`: 39815
- `line_count`: 605
- `sha256`: 11cf1353e8f14ac30e95c7d8d9cee958d83dfb3315e595c586d16389442b7e6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: json evidence; size=39815 bytes; lines=605; markers=<none>; tail={ "all_pass": true, "cases": [ { "command": [ "make", "-C", "/home/lyg/PA/ysyx-workbench/npc/rv64/testbench", "RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/runs/pri...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v2/summary.md

- `kind`: md
- `size_bytes`: 1691
- `line_count`: 25
- `sha256`: e0a4bf39daa589cbbe4bf3e20cc8980bea0c49442b7e68abd1df805afed43d0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 28, "PASS": 40}
- `summary`: md evidence; size=1691 bytes; lines=25; FAIL=28; PASS=40; tail=# V10B focused matrix v2 | case | test | compile | result | simulation | verdict | | --- | --- | ---: | --- | --- | --- | | `priv-system-assert` | `tb_ooo_priv_system` | 0 | PASS | accepted | PASS | | `priv-system-release` | `tb_ooo_priv_system` | 0 | PASS...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/add-mmu-action-to-every-drain/OooMemoryRequestGate.v

- `kind`: v
- `size_bytes`: 2502
- `line_count`: 79
- `sha256`: 23ab40dc595da93bc1ec8676cf9303f0465dede56acafa8e0c01bff9c811add7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2502 bytes; lines=79; markers=<none>; tail=`include "define.v" module OooMemoryRequestGate ( input clk, input rst, input core_local_flush_i, input checkpoint_mem_flush_i, input pending_system_satp_write_commit_i, input pending_system_sfence_commit_i, input pending_system_fencei_commit_i, input stop_...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/disconnect-fencei-fetch-cache-clear/OooFetchAxiBridge.v

- `kind`: v
- `size_bytes`: 73219
- `line_count`: 1660
- `sha256`: 43a2f71d00312edc55c8d617ce83b1e7b4fae463072e2639e05aa3a42f5a0d2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=73219 bytes; lines=1660; markers=<none>; tail=sv39_enabled = (priv_mode != `PRIV_M) && (satp[63:60] == 4'h8); end endfunction function canonical_sv39; input [`XLEN-1:0] vaddr; begin canonical_sv39 = (vaddr[63:39] == {25{vaddr[38]}}); end endfunction function [8:0] vpn_by_level; input [`XLEN-1:0] vaddr;...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/disconnect-fencei-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: f380f44a147b63c95ddede303e3c6e0589f42cfdb2d67b0baca184fe71bc5628
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/disconnect-satp-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2770
- `line_count`: 76
- `sha256`: f04abf00d84891c7bb089dee44f103b361a73ef4d4ace88535d29cfa0fbbea09
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2770 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/disconnect-sfence-mmu/OooMemoryAccess.v

- `kind`: v
- `size_bytes`: 2774
- `line_count`: 76
- `sha256`: a2bb83cb0799c2c97dfbea90aefbf8f2bccf387a2c32e47e314abc71275e5cd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=2774 bytes; lines=76; markers=<none>; tail=`include "define.v" // OooMemoryAccess: OoO core 子系统 wrapper（纯结构聚合）。 // 【pending_mem 全链已删除】rtl-ground-truth §4：lane1 barrier 谓词与 FACT_MEM 严格互斥 // → OooPendingMemorySequencer 的 capture 恒 0（结构不可达），整链退休。本 wrapper 现仅 // 承载活的访存请求门 OooMemoryRequestGate（纯组合，故已无 cl...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/drop-sfence-inval-ir-classification/DecodeUnit.v

- `kind`: v
- `size_bytes`: 31490
- `line_count`: 813
- `sha256`: 7e2b4b882ce945bff5ecfd362d0039bcbf61c0b22c355c69f23f08aadefe8b71
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 2}
- `summary`: v evidence; size=31490 bytes; lines=813; FAIL=2; tail=`include "define.v" module DecodeUnit ( input [`INST_W-1:0] inst_i, output reg [`CTRL_BUS_W-1:0] ctrl_o, output [`REG_ADDR_W-1:0] rs1_idx_o, output [`REG_ADDR_W-1:0] rs2_idx_o, output [`REG_ADDR_W-1:0] rd_idx_o ); wire [6:0] opcode_w = inst_i[6:0]; wire [2:...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/fencei-reason-to-serial/OooFrontend.v

- `kind`: v
- `size_bytes`: 117941
- `line_count`: 2494
- `sha256`: dcbc85faf43403254fc0eb26f411cef36672242f23852de5948f1ec7bde77313
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=117941 bytes; lines=2494; markers=<none>; tail=assign branch_prefetch_req_pc_w = {`XLEN{1'b0}}; // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0） assign branch_prefetch_match_w = 1'b0; assign branch_prefetch_buffer_match_w = 1'b0; assign branch_prefetch_pending_match_w = 1'b0; assign branch_prefe...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/remove-csr-pc-match/OooCsrAccessRequestMux.v

- `kind`: v
- `size_bytes`: 5077
- `line_count`: 125
- `sha256`: e97305b784d49ce5a4ece56ef44df0abde48ea43988f71f4bf76ed7ae5d77deb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=5077 bytes; lines=125; markers=<none>; tail=`include "include/define.v" module OooCsrAccessRequestMux #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input wire core_commit0_valid_i, input wire cor...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/remove-csr-producerid-match/OooCsrAccessRequestMux.v

- `kind`: v
- `size_bytes`: 5076
- `line_count`: 125
- `sha256`: 6a843f1b982ef4efa594f56f7891a4f9f77c5642f17bb146dac5a97f7b662f0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=5076 bytes; lines=125; markers=<none>; tail=`include "include/define.v" module OooCsrAccessRequestMux #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input wire core_commit0_valid_i, input wire cor...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/remove-fence-mem-idle/OooPendingDrainResolveGate.v

- `kind`: v
- `size_bytes`: 4809
- `line_count`: 108
- `sha256`: 7727b8c0553aaf4ac042aca6009426c1fc517d7ce51774ee165af893e5173caa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=4809 bytes; lines=108; markers=<none>; tail=`include "define.v" // stop-pending 之后的 drain/resolve 事件归 control 中枢，core glue 只转接事件。 module OooPendingDrainResolveGate #( parameter ROB_COUNT_W = `OOO_ROB_COUNT_W, parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W )( input [ROB_COUNT_W-1:0] rob_count_i, input [...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/remove-wfi-control-commit/OooWriteback.v

- `kind`: v
- `size_bytes`: 9162
- `line_count`: 226
- `sha256`: 804abb7f99e8f0ca8443c3876b66b581e058a77cec88f61cb02e900c49c8dae7
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=9162 bytes; lines=226; markers=<none>; tail=`include "define.v" `include "common/OooSlotFacts.v" // OooWriteback: OoO core 子系统 wrapper（纯结构聚合，从 OooCoreTopGlue 抽出 5 个实例）。 // 行为与原扁平实例化等价：仅把跨边界信号导出为端口，内部信号下沉。 module OooWriteback ( input clk, input core_commit0_exception_w, input [`INST_W-1:0] core_commit...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/retain-noncsr-holder-after-terminal/OooPendingSystemSequencer.v

- `kind`: v
- `size_bytes`: 12333
- `line_count`: 327
- `sha256`: 46c043255a50475812f7895299331f56c0e93fad4b4be8fe29089596d2c64b99
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=12333 bytes; lines=327; markers=<none>; tail=`include "define.v" module OooPendingSystemSequencer #( parameter ROB_INDEX_W = `OOO_ROB_INDEX_W, parameter PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W, parameter PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W ) ( input clk, input rst, input clear_i, input clear_dis...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/retain-stop-after-drain-terminal/OooStopPendingSequencer.v

- `kind`: v
- `size_bytes`: 6767
- `line_count`: 156
- `sha256`: ac260f4988f79ffe38b216a59d084f1c239d7f27dfba2ecd0ad938b02912f3aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=6767 bytes; lines=156; markers=<none>; tail=`include "define.v" module OooStopPendingSequencer ( input wire clk, input wire rst, input wire flush_i, input wire csr_trap_mem_valid_i, input wire direct_frontend_flush_i, input wire direct_branch0_fire_i, input wire direct_branch1_fire_i, input wire dire...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/mutated/sfence-reason-to-serial/OooFrontend.v

- `kind`: v
- `size_bytes`: 117941
- `line_count`: 2494
- `sha256`: c248476177fa8bfd5a68bc4ccbf1027764f80e9db5a2601b8037423f447477cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: v evidence; size=117941 bytes; lines=2494; markers=<none>; tail=assign branch_prefetch_req_pc_w = {`XLEN{1'b0}}; // OooBranchPrefetchStatusGate（active 恒0 → match/hit 恒0） assign branch_prefetch_match_w = 1'b0; assign branch_prefetch_buffer_match_w = 1'b0; assign branch_prefetch_pending_match_w = 1'b0; assign branch_prefe...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/add-mmu-action-to-every-drain/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541360
- `line_count`: 150083
- `sha256`: 7ef575c4ca716707448ff85a76fc53915072bb826822a64cddbfa272a0dbf23f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541360 bytes; lines=150083; FAIL=6; PASS=3; tail=i/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4;...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/add-mmu-action-to-every-drain/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/add-mmu-action-to-every-drain/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 35097
- `line_count`: 245
- `sha256`: 574982661ed71ddf14f70091b3ab5ff39b4de4ca6e24c3c0901a6f6247748d2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 196, "PASS": 26}
- `summary`: log evidence; size=35097 bytes; lines=245; FAIL=196; PASS=26; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/add-mmu-action-to-every-drain/make.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 3
- `sha256`: 9392c1632c3c3c3111048efdf5866618b74086d1672c693cdc097bc77233cea8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=371 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/add-mmu-action-to-every-dr...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/csr-access-assert/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: fe9c55323685dc0e2ab2f5663009a8ebd68d2d13ada4aad26fbda3fe34ba194a
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/csr-access-assert/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/csr-access-assert/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 763
- `line_count`: 5
- `sha256`: b23bbd4daeca4282410d5d6e1fdd08b4744fdb63c19a46965c11652f555ae4bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=763 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/csr-access-assert/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-fetch-cache-clear/build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2374962
- `line_count`: 60587
- `sha256`: 903e269df3fafc5541a50ad29063edf521d318f2c8ba7e68f1f55f31c845a438
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 4, "PASS": 3}
- `summary`: vvp evidence; size=2374962 bytes; lines=60587; FAIL=4; PASS=3; tail=c4 1, 0, 1; %store/vec4 v0x59574152bd60_0, 0, 1; %pushi/vec4 2, 0, 2; %store/vec4 v0x59574152bc90_0, 0, 2; %alloc S_0x59574150d1a0; %fork TD_tb_ooo_fetch_axi_bridge.tick, S_0x59574150d1a0; %join; %free S_0x59574150d1a0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-fetch-cache-clear/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-fetch-cache-clear/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 106608
- `line_count`: 811
- `sha256`: bd154a06a455c7dd3efeba42e5cacb9cac69412eada54e84faa17a6f41b45900
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 15, "PASS": 2}
- `summary`: log evidence; size=106608 bytes; lines=811; FAIL=15; PASS=2; tail=c/memory/PmpChecker.v:109: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-fetch-cache-clear/make.log

- `kind`: log
- `size_bytes`: 382
- `line_count`: 3
- `sha256`: c65a306dffd3c0d3a781679bcce52a419058900a3f18843e374cc9075eafeac5
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=382 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-fetch-ca...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541008
- `line_count`: 150063
- `sha256`: 97bb9b5ee32457d686d0d7d99f123f16dd94ef4e97d65e753cd7b885960a596d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541008 bytes; lines=150063; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28526
- `line_count`: 157
- `sha256`: 67458cef02fb9a968c42f3d26fcfc4ffb3b5578b142b7437807a873a5e59cc74
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 14, "PASS": 32}
- `summary`: log evidence; size=28526 bytes; lines=157; FAIL=14; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-mmu/make.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 3
- `sha256`: fa84be29df0f0833c9786ceab2cd392e1ec0b0b8087f7bc15ce802a83bfb95c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=363 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-fencei-mmu/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-satp-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541006
- `line_count`: 150063
- `sha256`: a65d9d36a0bf8845fc97d754b8958b15fc26fa69c2e21213b8697aef9229a659
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541006 bytes; lines=150063; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-satp-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-satp-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28447
- `line_count`: 156
- `sha256`: 9f11d9f71edc5d44583f2bdd2b593d31b77ebb3ea49f2702512f81dd596160a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 12, "PASS": 32}
- `summary`: log evidence; size=28447 bytes; lines=156; FAIL=12; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-satp-mmu/make.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 3
- `sha256`: 889b3bb0b8557c891dbd90d950d49df5341252bb165b12d9a7290a1a715502aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=361 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-satp-mmu/logs/t...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-sfence-mmu/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541008
- `line_count`: 150063
- `sha256`: 49dc68709a86a0a68b7e23b0adf80312f63a2801ca30090a8d1c83362387eb3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541008 bytes; lines=150063; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-sfence-mmu/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-sfence-mmu/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28782
- `line_count`: 161
- `sha256`: 24a1f275d6b7ee75292cb9a3e8d62c8b202e8ff8bb759d745866f00c5bb265f6
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 26, "PASS": 28}
- `summary`: log evidence; size=28782 bytes; lines=161; FAIL=26; PASS=28; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-sfence-mmu/make.log

- `kind`: log
- `size_bytes`: 363
- `line_count`: 3
- `sha256`: a9c7f23e0c59ffcc0acd156069b785079874dfa1e966927739e70c267333f57b
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=363 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/disconnect-sfence-mmu/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/drop-sfence-inval-ir-classification/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540918
- `line_count`: 150061
- `sha256`: 647c144f41b96a26a438526757d5ebc608ccde47233fb2e93a2a6c4b82dce69e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540918 bytes; lines=150061; FAIL=6; PASS=3; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/drop-sfence-inval-ir-classification/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/drop-sfence-inval-ir-classification/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 29267
- `line_count`: 165
- `sha256`: 83ca6a508547847631815fcd70bcb2b0fc5a72253b1299de17d83fabea7d5286
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 30, "PASS": 32}
- `summary`: log evidence; size=29267 bytes; lines=165; FAIL=30; PASS=32; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/drop-sfence-inval-ir-classification/make.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 3
- `sha256`: fa6eb85aba102c65d3ff0f7abbf7b2a31c1ab32efb4074132c6efc8696ca3133
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=377 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/drop-sfence-inval-ir-class...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/fencei-reason-to-serial/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540898
- `line_count`: 150061
- `sha256`: b00e1b2c7687d8b41567051a3c6e82547adc1de1db8ab7dbe645e5fbf432078a
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540898 bytes; lines=150061; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/fencei-reason-to-serial/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/fencei-reason-to-serial/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28635
- `line_count`: 158
- `sha256`: 76b4afc4823b42422fc842a0f3db0edd8e190520fda6656697fa701f73af3475
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 18, "PASS": 30}
- `summary`: log evidence; size=28635 bytes; lines=158; FAIL=18; PASS=30; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/fencei-reason-to-serial/make.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 3
- `sha256`: 6dfcc01d91c768c2483a4e7979b7be8abdbaaa44826fffbb96b0c80b53aee945
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=365 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/fencei-reason-to-serial/lo...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-assert/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540790
- `line_count`: 150061
- `sha256`: ba04986816b65945cd01927acbec75fff1c42a341058220b5b57ba2c7438719f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540790 bytes; lines=150061; FAIL=6; PASS=3; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-assert/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-assert/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28370
- `line_count`: 151
- `sha256`: 399b3864e97256fdd675da1a313a79f1a403b278cb28888547926eb611e1c6a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=28370 bytes; lines=151; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-assert/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-release/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 5750809
- `line_count`: 125280
- `sha256`: ce42c7e7489d5da9762ce112d1700d28e7c353e513899fa44820f7a7fd1e92c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=5750809 bytes; lines=125280; FAIL=6; PASS=3; tail=ing_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-release/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-release/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27511
- `line_count`: 144
- `sha256`: 0eb86edc36ef3045c4724b50f89c9adb9e129df9646347cb6b7eff780768701e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"PASS": 40}
- `summary`: log evidence; size=27511 bytes; lines=144; PASS=40; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/priv-system-release/make.log

- `kind`: log
- `size_bytes`: 147
- `line_count`: 2
- `sha256`: f2865cb231c549781e9f4103f92e5b70d465f75218894bcf7c497bd53ec84993
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=147 bytes; lines=2; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: Leaving directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench'

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-pc-match/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48611
- `line_count`: 1142
- `sha256`: 9818304d3dc17232a31b3cbce4689abe67d77feab30548320adc897c2a2066a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48611 bytes; lines=1142; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-pc-match/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-pc-match/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 1040
- `line_count`: 7
- `sha256`: 01ef8a1fcbd04450f30a21a4214192eca4061b9399f7f1e2f5ac789516bb8572
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1040 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-pc-match/make.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 3
- `sha256`: c87d2a1be657c36f165e35e4730c5c0431321ab9efda57f48c422a5ed8b479fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=372 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-pc-match/logs/t...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-producerid-match/build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48619
- `line_count`: 1142
- `sha256`: c7fccf9edff5510cba7b7ef7308f8b7d511c3dd01893fa6d556d559d470d00b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48619 bytes; lines=1142; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-producerid-match/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-producerid-match/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 1056
- `line_count`: 7
- `sha256`: 34a43bdcceb2155fbd73aa116ac9e1021ad2d4ac73fd427effaaed3b90864159
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=1056 bytes; lines=7; FAIL=6; PASS=2; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-producerid-match/make.log

- `kind`: log
- `size_bytes`: 380
- `line_count`: 3
- `sha256`: 48ea1f8677cb1f4cb05a9568dce20c3dfd942a25bdeb8cf52f46c194d7635ba6
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=380 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-csr-producerid-matc...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-fence-mem-idle/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 103089
- `line_count`: 2482
- `sha256`: 8d67c4f7ba33f59aa20fca91da49d2a300f2be8ddb1928023e3e96f539962461
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=103089 bytes; lines=2482; FAIL=3; PASS=2; tail=ng_vec4 %pushi/vec4 1852138528, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1786080624, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543321199, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-fence-mem-idle/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-fence-mem-idle/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 1232
- `line_count`: 12
- `sha256`: e44f4a12c5ec98e51fe64e85a07304367ba18f45ef96792b7044223791e07b1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 8, "PASS": 4}
- `summary`: log evidence; size=1232 bytes; lines=12; FAIL=8; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-fence-mem-idle/make.log

- `kind`: log
- `size_bytes`: 378
- `line_count`: 3
- `sha256`: 10d859edf9bd0249d869927dc4e25fb9abc352cbeec272dfe0a194be500ba272
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=378 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-fence-mem-idle/logs...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-wfi-control-commit/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541276
- `line_count`: 150066
- `sha256`: de1c160a172a001f7729fde224eb57df99bb72b3e06aee442e689ab73f633800
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541276 bytes; lines=150066; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-wfi-control-commit/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-wfi-control-commit/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 28458
- `line_count`: 158
- `sha256`: 64f662822c96ebbc4eabe97d7ae4c2fc436cabe47ebf33e089371210771919c0
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 20, "PASS": 28}
- `summary`: log evidence; size=28458 bytes; lines=158; FAIL=20; PASS=28; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-wfi-control-commit/make.log

- `kind`: log
- `size_bytes`: 367
- `line_count`: 3
- `sha256`: 9d0954d4faf0b1e25f449c42e7a39182b535e30db7dca39b5ed93c29261db514
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=367 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/remove-wfi-control-commit/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-noncsr-holder-after-terminal/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541092
- `line_count`: 150070
- `sha256`: 14fe82443c77f5a509a3e678b443002d763504e1292be1cf78aa3c09507ecd5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541092 bytes; lines=150070; FAIL=6; PASS=3; tail=4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-noncsr-holder-after-terminal/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-noncsr-holder-after-terminal/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 25962
- `line_count`: 140
- `sha256`: 903031b346f17e603a0e06735b491d387025f79d76b029a06e379ae07d069e07
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"ERROR": 4, "FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=25962 bytes; lines=140; FAIL=6; ERROR=4; PASS=2; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-noncsr-holder-after-terminal/make.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 3
- `sha256`: 3c3cc67336c7ce278c23103d88b70fea57848fc44ae2d80c18f2d189e7a7963d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=377 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-noncsr-holder-after...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-stop-after-drain-terminal/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6541024
- `line_count`: 150067
- `sha256`: e5e6e1b5cf6c12a8f1c23fa293e2ca30217a9c9a87012d38fe63149d482058bc
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6541024 bytes; lines=150067; FAIL=6; PASS=3; tail=vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; d...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-stop-after-drain-terminal/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-stop-after-drain-terminal/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 26249
- `line_count`: 140
- `sha256`: 2a8f9b1b4ab2d437d2d84290bfd541a6b97d47a54f4a86979080a3081bedd91f
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"ERROR": 4, "FAIL": 6, "PASS": 2}
- `summary`: log evidence; size=26249 bytes; lines=140; FAIL=6; ERROR=4; PASS=2; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-stop-after-drain-terminal/make.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 3
- `sha256`: 5db9d3933514ffb81a6677d57e5ef3596be0aa95f7cbe891c98f3da6ab6c65ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=374 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/retain-stop-after-drain-te...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/sfence-reason-to-serial/build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6540898
- `line_count`: 150061
- `sha256`: d3e222f9e08fda82f795f95c7e89753ecb15ff4131e7d8e6451e004114d29660
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=6540898 bytes; lines=150061; FAIL=6; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/sfence-reason-to-serial/compile.rc

- `kind`: rc
- `size_bytes`: 2
- `line_count`: 1
- `sha256`: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: rc evidence; size=2 bytes; lines=1; markers=<none>; tail=0

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/sfence-reason-to-serial/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 29242
- `line_count`: 163
- `sha256`: d22abc7d2d3caf652b667c1d6a92ab0db25d29e234738722ee2f0f99ee63ae30
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 30, "PASS": 28}
- `summary`: log evidence; size=29242 bytes; lines=163; FAIL=30; PASS=28; tail=[TEST] tb_ooo_priv_system [COMPILE] /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/iverilog-recording-wrapper.sh -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/sfence-reason-to-serial/make.log

- `kind`: log
- `size_bytes`: 365
- `line_count`: 3
- `sha256`: 0a488522e2dc17309ba5cb1ccbaf2dce9034a5e508e353ae7bca55801e13f22d
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: log evidence; size=365 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testbench' make: *** [Makefile:386: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/sfence-reason-to-serial/lo...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/status.json

- `kind`: json
- `size_bytes`: 76
- `line_count`: 6
- `sha256`: adc25f8d3bc17decd297dfea3e54c11828716a235dc69897356e279ae1d0cd99
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: json evidence; size=76 bytes; lines=6; markers=<none>; tail={ "all_pass": true, "completed": 17, "state": "DONE", "total": 17 }

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/summary.json

- `kind`: json
- `size_bytes`: 43365
- `line_count`: 646
- `sha256`: 524d61360fff6f74dcefc20284c64575abcffac7f42c34023b4527cc45a80125
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {}
- `summary`: json evidence; size=43365 bytes; lines=646; markers=<none>; tail={ "all_pass": true, "cases": [ { "command": [ "make", "-C", "/home/lyg/PA/ysyx-workbench/npc/rv64/testbench", "RESULT_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/runs/pri...

### .github/task-runs/2026-07-27-rv64-v10b-serialized-system-post-fire/evidence/v10b-focused-matrix-v3/summary.md

- `kind`: md
- `size_bytes`: 2317
- `line_count`: 31
- `sha256`: 1ab163895bdcde4b6e932839507b1e70b89a3b655b618b4ec7671d836bad2f51
- `encoding`: utf-8
- `indexed_at`: 2026-07-27T04:10:22+00:00
- `markers`: {"FAIL": 28, "PASS": 40}
- `summary`: md evidence; size=2317 bytes; lines=31; FAIL=28; PASS=40; tail=# V10B focused matrix v3 | case | test | compile | result | simulation | verdict | | --- | --- | ---: | --- | --- | --- | | `priv-system-assert` | `tb_ooo_priv_system` | 0 | PASS | accepted | PASS | | `priv-system-release` | `tb_ooo_priv_system` | 0 | PASS...
