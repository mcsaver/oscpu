# Evidence Index

## 基本信息

- `task_id`: 2026-07-26-rv64-v9y-serialize-memory-owner-terminal
- `task_slug`: 
- `profile`: 
- `asset_count`: 491
- `total_size_bytes`: 296521308

## 证据资产

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/acceptance-mutations/logs/collector-exports-raw-valid.log

- `kind`: log
- `size_bytes`: 22041
- `line_count`: 151
- `sha256`: 8cc7dadd48c28e14b6f33756e2e8c4649fc194c7606a93b5f18778f4f631f555
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 16, "PASS": 14}
- `summary`: log evidence; size=22041 bytes; lines=151; FAIL=16; PASS=14; tail=[MUTATION] collector-exports-raw-valid [MAKE-RC] 2 [COMMAND] /usr/bin/make -B -C /home/lyg/PA/ysyx-workbench/npc/rv64/testbench IVFLAGS=-g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon RES...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/acceptance-mutations/logs/predicate-guarded-by-ooo-assert.log

- `kind`: log
- `size_bytes`: 22342
- `line_count`: 155
- `sha256`: a8110038a1b35fc01c3e90567be2b3755acf807226c9a4f987b060f423c5bb40
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 24, "PASS": 14}
- `summary`: log evidence; size=22342 bytes; lines=155; FAIL=24; PASS=14; tail=[MUTATION] predicate-guarded-by-ooo-assert [MAKE-RC] 2 [COMMAND] /usr/bin/make -B -C /home/lyg/PA/ysyx-workbench/npc/rv64/testbench IVFLAGS=-g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/acceptance-mutations/logs/raw-ingress-is-transfer-authority.log

- `kind`: log
- `size_bytes`: 21834
- `line_count`: 148
- `sha256`: c5e973209b4379140ac081005177319fede46f3401b676bfe8232ecbad6b5b5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 14}
- `summary`: log evidence; size=21834 bytes; lines=148; FAIL=10; PASS=14; tail=[MUTATION] raw-ingress-is-transfer-authority [MAKE-RC] 2 [COMMAND] /usr/bin/make -B -C /home/lyg/PA/ysyx-workbench/npc/rv64/testbench IVFLAGS=-g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icomm...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/acceptance-mutations/summary.json

- `kind`: json
- `size_bytes`: 2287
- `line_count`: 52
- `sha256`: dd61912b544c8706c9645af6cba874173ec1954c947b824af9cb1259ad3a9580
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6}
- `summary`: json evidence; size=2287 bytes; lines=52; FAIL=6; tail={ "configuration": { "focused_define": "V8W_MEMORY_RECOVERY_FOCUSED", "ivflags": "-g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon", "ooo_assert": false }, "mutation_count": 3, "mutations"...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/debug-v8w-build/tb_ooo_int_backend_v8w_memory_recovery.vvp

- `kind`: vvp
- `size_bytes`: 11343224
- `line_count`: 283886
- `sha256`: b8ccee53dae10309a6a86e4b277aeb0ade2716b1fb72e0551f6a11ec3ee2a47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=11343224 bytes; lines=283886; PASS=2; tail=, 11; %load/vec4 v0x648434043ab0_0; %and; T_488.577; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_488.576, 10; %load/vec4 v0x648434061770_0; %and; T_488.576; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_488.575, 9; %load/vec4 v0x6484340490c0_0; %flag_set/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/debug-v8w/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 21354
- `line_count`: 139
- `sha256`: 82e09ae0148078bc7a75704410a294fff74900ca8713e3aa9f87bb8504715025
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: log evidence; size=21354 bytes; lines=139; FAIL=2; PASS=4; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/assert/build/tb_ooo_int_backend_v8w_memory_recovery.vvp

- `kind`: vvp
- `size_bytes`: 11405938
- `line_count`: 285084
- `sha256`: 7fedb522425c7d18e60d396f319edbca20b732606c62596bdc5be3fffa17aa30
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=11405938 bytes; lines=285084; PASS=2; tail=, 11; %load/vec4 v0x59021bb76370_0; %and; T_488.577; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_488.576, 10; %load/vec4 v0x59021bb941f0_0; %and; T_488.576; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_488.575, 9; %load/vec4 v0x59021bb7bb00_0; %flag_set/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/assert/build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 106024
- `line_count`: 2903
- `sha256`: 98314ad81271fd7c0f945ea97cc066a5db14757ed905a0f1bd031401095e32b7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 5}
- `summary`: vvp evidence; size=106024 bytes; lines=2903; FAIL=1; PASS=5; tail=%addi 1, 0, 32; %store/vec4 v0x5f647c3ba620_0, 0, 32; %jmp T_11.13; T_11.14 ; T_11.10 ; %jmp T_11; .thread T_11, $push; .scope S_0x5f647c35e0e0; T_12 ; %wait E_0x5f647c308dc0; %load/vec4 v0x5f647c3ba560_0; %flag_set/vec4 8; %jmp/0xz T_12.0, 8; %pushi/vec4 0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/assert/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 21438
- `line_count`: 141
- `sha256`: 30c51a051431b4c8d2e419b43f6489208fe39c99f8e58d7c70a059b43816b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=21438 bytes; lines=141; PASS=16; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/assert/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1198
- `line_count`: 13
- `sha256`: 8fd1fe69cd33727b396a5aa2933a6ae84e8bf9514db61fbe8d0053e87adda405
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1198 bytes; lines=13; PASS=12; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/base-assert/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 12260310
- `line_count`: 307161
- `sha256`: b42feaac1966c2a6156cc070cc10a824f3ab38b00004515a4d9d203a46d4c1f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=12260310 bytes; lines=307161; PASS=2; tail=v0x5b772fe90ec0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5b772fe90ec0_0, 0, 1; %delay 1, 0; %alloc S_0x5b772ec08b10; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/base-assert/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26928
- `line_count`: 228
- `sha256`: e9a561b250c8bc56237c9d7a2a5489981ab7ef62d70c72d39a6eda80dcccb80e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"ERROR": 2, "PASS": 102}
- `summary`: log evidence; size=26928 bytes; lines=228; ERROR=2; PASS=102; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/base-release/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 11738510
- `line_count`: 290409
- `sha256`: a414069faa8486d4751b4add1181c414ea8b99c04337843fa680f4cde7d6cd24
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=11738510 bytes; lines=290409; PASS=2; tail=pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/base-release/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26048
- `line_count`: 222
- `sha256`: 528f06ece5d838f7ef57c0cb93e4f74356b50b803fa3defe8aeab098f51abca8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"ERROR": 2, "PASS": 104}
- `summary`: log evidence; size=26048 bytes; lines=222; ERROR=2; PASS=104; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-ser...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/release/build/tb_ooo_int_backend_v8w_memory_recovery.vvp

- `kind`: vvp
- `size_bytes`: 10866648
- `line_count`: 267633
- `sha256`: 968407b930f6bdd4aac6acf9bc2c8578e179c1d744dd564aac8e19f267ec16fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=10866648 bytes; lines=267633; FAIL=3; PASS=2; tail=v0x60da8de25630_0, 0; %load/vec4 v0x60da8de13c50_0; %assign/vec4 v0x60da8de260f0_0, 0; %load/vec4 v0x60da8de2b020_0; %assign/vec4 v0x60da8de253b0_0, 0; %load/vec4 v0x60da8de2ae80_0; %parti/s 2, 27, 6; %assign/vec4 v0x60da8de25e70_0, 0; %load/vec4 v0x60da8de...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/release/build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 94965
- `line_count`: 2540
- `sha256`: 20bde9371586c9c6f381444fae72642916c04da35fae73e87d9ed5c42239f4a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 6}
- `summary`: vvp evidence; size=94965 bytes; lines=2540; FAIL=1; PASS=6; tail=ail, S_0x638c92b50980; %join; %free S_0x638c92b50980; T_8.8 ; %pushi/vec4 1, 0, 1; %ix/getv 4, v0x638c92b50fb0_0; %store/vec4 v0x638c92b52670_0, 4, 1; %load/vec4 v0x638c92b525d0_0; %addi 1, 0, 32; %store/vec4 v0x638c92b525d0_0, 0, 32; %end; .scope S_0x638c9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/release/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 20485
- `line_count`: 134
- `sha256`: 1b0938c2770953094c38ce06e09d2eaad3420b9f9ace1f98bf2d638e8f1cf5a1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=20485 bytes; lines=134; PASS=16; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int_backend -o /...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green-v3/release/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1186
- `line_count`: 13
- `sha256`: f4c578834b89ee402d061031fa5e70d411c7fc074ed6cb8b827c68d8e9343ac9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1186 bytes; lines=13; PASS=12; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-workbench/.github...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/backend/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31484
- `line_count`: 208
- `sha256`: 6bee1be220e99cab9eb310dd4860662b60b7b894a2b3463041c5292140be2723
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31484 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/backend/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25473
- `line_count`: 140
- `sha256`: b17e03cbcb7f36762a1c9b3f781943bf5891c964a48c94771fa0eec2f1b3448d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25473 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/backend/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26779
- `line_count`: 226
- `sha256`: f74a5e918f81d80cf93a53df2e73c102fb78a445b453d1b51660f584b92c9d73
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"ERROR": 2, "PASS": 98}
- `summary`: log evidence; size=26779 bytes; lines=226; ERROR=2; PASS=98; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 3728114
- `line_count`: 86488
- `sha256`: a40f542ceac0eb23c39161bba21bd9ba8f1c7777d05497e02c6a2709bec93f46
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3728114 bytes; lines=86488; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 6365808
- `line_count`: 144925
- `sha256`: ece7e04fa161c5025c44c45a6c0308af983804519c9756709a39a20cf9a4225a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 1}
- `summary`: vvp evidence; size=6365808 bytes; lines=144925; PASS=1; tail=%pushi/vec4 1635085428, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543711598, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1684825458, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543520873...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 12194321
- `line_count`: 305884
- `sha256`: 1c4b1cfd0064d7e1402b3b1b6400aaba8c6b4189992166d23953fea5a22f01f9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=12194321 bytes; lines=305884; PASS=2; tail=v0x593f7157cb60_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x593f7157cb60_0, 0, 1; %delay 1, 0; %alloc S_0x593f70308080; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 96464
- `line_count`: 2319
- `sha256`: 0492229b2efd40185c95c89e885cfaabb3a72cfb1370419b7b7c9180c799179e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=96464 bytes; lines=2319; FAIL=3; PASS=1; tail=hi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/gate/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 617
- `line_count`: 5
- `sha256`: 793b6ff2fb3fa346b11974eef0c8ab6e0d6fe2806695d1d591e34bfbec931de1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=617 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery-build-v2/tb_ooo_int_backend_v8w_memory_recovery.vvp

- `kind`: vvp
- `size_bytes`: 11344500
- `line_count`: 283897
- `sha256`: 49f6065f89670f6cc904d0788feca757f3b29e313398e2da4b7b1b6f65d8aa73
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=11344500 bytes; lines=283897; PASS=2; tail=, 11; %load/vec4 v0x62dc17df90e0_0; %and; T_488.577; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_488.576, 10; %load/vec4 v0x62dc17e16ee0_0; %and; T_488.576; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_488.575, 9; %load/vec4 v0x62dc17dfe870_0; %flag_set/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery-build-v2/tb_ooo_int_backend_v8x_backend_bridge_recovery.vvp

- `kind`: vvp
- `size_bytes`: 13208285
- `line_count`: 330407
- `sha256`: ff5a34fade439525d3fe730c8757bdd35c7964ecc3b3f37071d679accf51ce3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=13208285 bytes; lines=330407; FAIL=8; PASS=2; tail=cbc10_0, 0; %jmp T_799.1; T_799.0 ; %load/vec4 v0x559cab2c5970_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_799.4, 9; %load/vec4 v0x559cab2c5770_0; %and; T_799.4; %flag_set/vec4 8; %jmp/0xz T_799.2, 8; %load/vec4 v0x559cab2c51a0_0; %addi 1, 0, 32; %assig...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery-build/tb_ooo_int_backend_v8w_memory_recovery.vvp

- `kind`: vvp
- `size_bytes`: 11343022
- `line_count`: 283886
- `sha256`: f17387359d3a8f3f21f3688126f416efbc8a27bc8b417e0820e7d27efee7f5a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=11343022 bytes; lines=283886; PASS=2; tail=, 11; %load/vec4 v0x560908cca050_0; %and; T_488.577; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_488.576, 10; %load/vec4 v0x560908ce7aa0_0; %and; T_488.576; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_488.575, 9; %load/vec4 v0x560908ccf3f0_0; %flag_set/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery-build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 84965
- `line_count`: 2354
- `sha256`: 72c6a6013516bc39c1e8746cc48eb2db2fc0d54e4dededa01717b7e66ef72688
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 3}
- `summary`: vvp evidence; size=84965 bytes; lines=2354; FAIL=1; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery-v2/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 21274
- `line_count`: 139
- `sha256`: cf835fb063bae0a73483eb2c63c4ad0a9781975eee231d514b7b993d188a3050
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=21274 bytes; lines=139; PASS=12; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery-v2/logs/tb_ooo_int_backend_v8x_backend_bridge_recovery.log

- `kind`: log
- `size_bytes`: 159366
- `line_count`: 1171
- `sha256`: cba928da39d60fa6bdedd1de329f84ac218925a334610083a50d048dbf7f1381
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 5}
- `summary`: log evidence; size=159366 bytes; lines=1171; PASS=5; tail=rds in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sensitive to a...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 21305
- `line_count`: 139
- `sha256`: 4cf21a299a419cd526746ceb01f91dcaadda2e0682a7d70f9c337ef88a0c5df5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: log evidence; size=21305 bytes; lines=139; FAIL=2; PASS=4; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/recovery/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1098
- `line_count`: 11
- `sha256`: bc273296363bafeebca531ede0aa2c8cde89f7e15cf79caac67430473bbf088a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=1098 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/v9y-phase-build/tb_ooo_int_backend_v8w_memory_recovery.vvp

- `kind`: vvp
- `size_bytes`: 11367615
- `line_count`: 284474
- `sha256`: 2c40965d2709e38a14bf44c0f5c19dd7119a4f660b241b2fed4ce4b59efbeba5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=11367615 bytes; lines=284474; PASS=2; tail=, 11; %load/vec4 v0x5824213af890_0; %and; T_488.577; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_488.576, 10; %load/vec4 v0x5824213cd300_0; %and; T_488.576; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_488.575, 9; %load/vec4 v0x5824213b4c50_0; %flag_set/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/green/v9y-phase/logs/tb_ooo_int_backend_v8w_memory_recovery.log

- `kind`: log
- `size_bytes`: 21365
- `line_count`: 140
- `sha256`: 8d1a3f41707e88368241bf82bcd4cfd7b1e6588045481e08086caa65d67eae93
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 14}
- `summary`: log evidence; size=21365 bytes; lines=140; PASS=14; tail=[TEST] tb_ooo_int_backend_v8w_memory_recovery [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -DV8W_MEMORY_RECOVERY_FOCUSED -DV8W_MAKE_TARGET -s tb_ooo_int...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 48967
- `line_count`: 1322
- `sha256`: cf8abac7ca6861d29eba64c4076c3b140ecb1b43c845f7d7a2ab11e724ca7a92
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48967 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 276271
- `line_count`: 7135
- `sha256`: 668d5798aab7b5b1165c02c5b80fe47a08ae1caa1a2fa2b07ddbe20ada33e526
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=276271 bytes; lines=7135; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 219285
- `line_count`: 5754
- `sha256`: 7d5a0f371ca973fabdadaf68c4c19a73a990cdf45c9f1109e8fc6d899c64b348
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=219285 bytes; lines=5754; FAIL=3; PASS=2; tail=, S_0x5ceddab745c0; %join; %free S_0x5ceddab745c0; %alloc S_0x5ceddaace560; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %p...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 905889
- `line_count`: 16698
- `sha256`: 433c7a46c5ec13630c81646214d0811ec57660ac884d478ba29c9b03a27700c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=905889 bytes; lines=16698; markers=<none>; tail=ng_vec4 %pushi/vec4 1919513701, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544566893, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1634954099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 5...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_axi_reset_syscon.vvp

- `kind`: vvp
- `size_bytes`: 169874
- `line_count`: 4395
- `sha256`: bab59085e338dc70053987a89c439b7548149d80b03a42e6c354dcd652f758a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=169874 bytes; lines=4395; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 1751738216, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 541204578, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701015405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 151922
- `line_count`: 4004
- `sha256`: 393e1419ab4650ef497575af0967d6808f37a79c5cfbb3176aafef5881b72fce
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=151922 bytes; lines=4004; FAIL=3; PASS=1; tail=, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x6463be7299e0_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x6463be729770_0, 0, 32; %pushi/vec4 2, 0, 3; %store/vec4 v0x6463be729910_0, 0, 3; %pushi/vec4 0, 0, 1; %store/vec4 v0x6463be72a980_0, 0, 1; %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 314045
- `line_count`: 8462
- `sha256`: 0e4b90fccff976c01d433b0788a1a8e5c44343fb46dd45da561478771d64dc51
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=314045 bytes; lines=8462; FAIL=3; PASS=2; tail=g_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32438
- `line_count`: 864
- `sha256`: 9b26e9d91fa817a2c1ca748648953497cee0e0446c96bf119e86305d308aed47
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32438 bytes; lines=864; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 581129
- `line_count`: 14244
- `sha256`: fa0f742072df23c8e02973dda9319aefce4972a1c548323abb188ca421a756d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=581129 bytes; lines=14244; markers=<none>; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1702000233, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1936683552, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_csr_file_vectored_trap.vvp

- `kind`: vvp
- `size_bytes`: 355728
- `line_count`: 8239
- `sha256`: 1a9dc08f796abf02404cf3d279d6e7b263cb1341bbdcaabf6db16855dcee382b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=355728 bytes; lines=8239; FAIL=2; PASS=1; tail=%pushi/vec4 66, 0, 64; %store/vec4 v0x5d7c46556840_0, 0, 64; %fork TD_tb_csr_file_vectored_trap.check64, S_0x5d7c46519b40; %join; %free S_0x5d7c46519b40; %alloc S_0x5d7c4668e090; %fork TD_tb_csr_file_vectored_trap.reset_case, S_0x5d7c4668e090; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112262
- `line_count`: 3912
- `sha256`: 71123fd1543d058eda4c6f3fc327610de2433fa23161cffc088b97e77ea4d318
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112262 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x5bb656d40980_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x5bb656d40980_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274309
- `line_count`: 8084
- `sha256`: 33369a33be7271e1518a79c648ffe4741e0b2d345d3e883d1d48b7a35b48e3f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274309 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32654
- `line_count`: 892
- `sha256`: d5903320d484251622d6cec77b8685b689f61beea517098b615da2710239b648
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32654 bytes; lines=892; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 37930
- `line_count`: 983
- `sha256`: f5516176decae45b41e7801794383bf4129e6c19adc43bb84f0470dfcc4e25cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=37930 bytes; lines=983; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40314
- `line_count`: 1057
- `sha256`: ebad8c248d98e803a108dfd8ed5d55715c59af8639bbfe6635ff1408a567a936
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40314 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28612
- `line_count`: 748
- `sha256`: e6adead356adf585bc921ad0ff7625b9d83d829c6963ae4c30fafebaac594c8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28612 bytes; lines=748; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 3729590
- `line_count`: 86499
- `sha256`: 4efc575877eda63c547b1e1a7afc3574b8d73933096f792bc2c4282b7f92e928
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3729590 bytes; lines=86499; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 3630120
- `line_count`: 84878
- `sha256`: 883ae746d85cf1fd6acd4e3bc06020e32f982a5109ed350182ae22df2c34a9f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=3630120 bytes; lines=84878; FAIL=1; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 114, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1635197028, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701864814, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39372
- `line_count`: 1135
- `sha256`: a7d301bbdf7824908e40283ee3b3c98de04791cc2b773182742eda07ac589101
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39372 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30684
- `line_count`: 801
- `sha256`: 27cc59dbd78c78e7825aee8524a1828e86f9a4d67c9f5309053e55df69c0878f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30684 bytes; lines=801; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 108566
- `line_count`: 3346
- `sha256`: 038b96f23d888483ecb06c0ed23e511979eaa5124c29750bd725c5dfc6370c00
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108566 bytes; lines=3346; FAIL=5; PASS=1; tail=load/vec4 v0x615c97bb9cc0_0; %concat/vec4; draw_concat_vec4 %sub; %ix/vec4 4; %shiftl 4; %or; %jmp/0 T_22.19, 8; ; End of false expr. %blend; T_22.19; %store/vec4 v0x615c97bbb2a0_0, 0, 64; %jmp T_22.17; T_22.9 ; %load/vec4 v0x615c97bb9cc0_0; %cmpi/e 0, 0, 6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 36516
- `line_count`: 758
- `sha256`: 5d3296c1a20ce59b996413d1bb8ec564e9ae7b12401caf69ae56e942f8357e3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=36516 bytes; lines=758; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30029
- `line_count`: 663
- `sha256`: 034940566491a7bd5514e9b42c988fc53c86e9f3ff370ff3a63d648766c1166a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30029 bytes; lines=663; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138036
- `line_count`: 3130
- `sha256`: 2736cc6c34e98d4d5833cce8801a9602e37ea28289f319a07ddd9a94f5d232b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138036 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5611f38ae4b0_0, 0, 1024;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 34196
- `line_count`: 710
- `sha256`: 6b88ee876b09e6086ac57d3d8142a51cd95cfd32237648fbf4d809ffcf2d5ef7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34196 bytes; lines=710; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47153
- `line_count`: 1228
- `sha256`: 5eea134264e848e917831a0ee3cdcfc152ef73a5a92763b99f375101a4a139c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47153 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 53833
- `line_count`: 1355
- `sha256`: b125968c9da2cf34024c26b95ac7134f796f1263a4ce733fac4b691922462da9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=53833 bytes; lines=1355; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 147679
- `line_count`: 3839
- `sha256`: 93369f3a19d08a56f041928fc3d679c5ad6ed62761b392529106307a1f42ce67
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=147679 bytes; lines=3839; FAIL=9; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1751479072, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1380275024, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x596be4439010_0, 0, 1024; %load/vec4 v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 72082
- `line_count`: 1665
- `sha256`: 46357f40d4401c55298bcd2f48ea94ce003d7c40ea2aad8897bda2fe09448152
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=72082 bytes; lines=1665; FAIL=11; PASS=1; tail=.port_info 8 /INPUT 1 "synth_lane1_branch_append_i"; .port_info 9 /INPUT 64 "synth_branch_append_pc_i"; .port_info 10 /INPUT 32 "synth_branch_append_inst_i"; .port_info 11 /INPUT 64 "synth_branch_append_next_pc_i"; .port_info 12 /INPUT 1 "core_commit0_valid...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 53875
- `line_count`: 1306
- `sha256`: 75127911227c4a327091eb286670985cbd41f0405b16a77d581288517930bbc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53875 bytes; lines=1306; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_control_event_apply_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 23763
- `line_count`: 627
- `sha256`: 790116eee8bbb148ef418faaf69855ed8e2808f5ee286976936308d53208b82c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=23763 bytes; lines=627; FAIL=12; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29483
- `line_count`: 785
- `sha256`: cb16ea91f7f3f1da6bde9690515749c7bb7a43b3b5b0946b856b4b91b784cb43
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29483 bytes; lines=785; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 6367284
- `line_count`: 144936
- `sha256`: 005ab93c96200d1ef24c9af65f8a1ac1e8c75b06e59ec62cfd5c86eadd0c978f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 1}
- `summary`: vvp evidence; size=6367284 bytes; lines=144936; PASS=1; tail=%pushi/vec4 1635085428, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543711598, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1684825458, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543520873...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: a4cad5d347e211457e0d28868d7c274a2f3758b24d5636f0ee6f74b280baca70
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34154
- `line_count`: 799
- `sha256`: be35eec3d1d716e17818a76d992325f37bf4c1c05a5a0a724627aacfa087cf9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: vvp evidence; size=34154 bytes; lines=799; FAIL=4; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 401936
- `line_count`: 10153
- `sha256`: 07c99bb3bab41236dee402c3b3124ca747b3c91ea952af9f2c79ad9dbfa6a049
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=401936 bytes; lines=10153; markers=<none>; tail=ing_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101127
- `line_count`: 2454
- `sha256`: 3f8cde54b7df4f5b5570bede2db84028c8cc26032d4dadbfe06aab78086a4e52
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101127 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53579
- `line_count`: 1375
- `sha256`: dc3f458d566f8203d68ef6bb6b0a870574c8fffd17641b2624118afc1724ee57
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53579 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 98854
- `line_count`: 2306
- `sha256`: 1c4a04d9b07ddee63dfc9f12ce2c748716c3d3a25cd882b803070e1822277012
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=98854 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 1143803
- `line_count`: 26012
- `sha256`: 8758c2db8d5c4e97cd82085826c4a075d668217fc3fdc6c66bbad263b9eb6abb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1143803 bytes; lines=26012; markers=<none>; tail=ore/vec4 v0x620457154360_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x620457154280_0, 0, 1; %fork TD_tb_ooo_dispatch_backend.tb_check1, S_0x6204571540a0; %join; %free S_0x6204571540a0; %pushi/vec4 1, 0, 1; %store/vec4 v0x620457155730_0, 0, 1; %pushi/vec4 1,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_dual_memory_sustained_issue.vvp

- `kind`: vvp
- `size_bytes`: 8159286
- `line_count`: 187480
- `sha256`: 9698431cd2d8d15caf3c80dbf3f55cbbc53012421e614e318e4a61a30b11bb28
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=8159286 bytes; lines=187480; FAIL=10; PASS=1; tail=%nor/r; %flag_set/vec4 9; %flag_or 8, 9; T_1032.7; %jmp/1 T_1032.6, 8; %load/vec4 v0x64c981f88ba0_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1032.6; %jmp/1 T_1032.5, 8; %load/vec4 v0x64c981f89890_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1032.5; %jmp/0xz T_1032.3, 8...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 1266778
- `line_count`: 33289
- `sha256`: a254610c8d335b444b7a7fed9a1c02ed78257a7c8b61f91a289cdaddeca9f642
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 12, "PASS": 13}
- `summary`: vvp evidence; size=1266778 bytes; lines=33289; FAIL=12; PASS=13; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 840389
- `line_count`: 21428
- `sha256`: 04ef4a437694448ee509495c2f356e2e5b3b1b59391ce3aaf6ee97204ef50cf2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=840389 bytes; lines=21428; FAIL=3; PASS=2; tail=ad/vec4 v0x5b80a283c8a0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_170.88, 9; %load/vec4 v0x5b80a283c2c0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/1 T_170.89, 9; %load/vec4 v0x5b80a283c200_0; %or; T_170.89; %nor/r; %and; T_170.88; %flag_set/vec4 8; %...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2338470
- `line_count`: 59667
- `sha256`: 21cdecf45cc52541fd403ea12e154804624198fa1f9ecf8a46662e6077b3ed0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=2338470 bytes; lines=59667; FAIL=3; PASS=2; tail=eed_ad_update, S_0x59dd2cff9360; %join; %free S_0x59dd2cff9360; %pushi/vec4 1, 0, 1; %store/vec4 v0x59dd2d01a590_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x59dd2d019650_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x59dd2d019f30_0, 0, 1; %pushi/vec4 1, 0, 1...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 960578
- `line_count`: 24597
- `sha256`: df18bf608d9f725b15b1f48c00a9e0008c00e95a531ef9c0abc16fccfdbeb8ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=960578 bytes; lines=24597; FAIL=4; PASS=2; tail=/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_branch_target.vvp

- `kind`: vvp
- `size_bytes`: 43990
- `line_count`: 1076
- `sha256`: 97c0ca29367382ea5b64177c90e59fefa3e376e9e6547078de7977520e0e4d75
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=43990 bytes; lines=1076; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 126494
- `line_count`: 3125
- `sha256`: f84568603b26e94d64e414a5a4e410b9726d6a1e251ecfd26abb0290dd0abb4c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=126494 bytes; lines=3125; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 543585644, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1814062697, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1718558820, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 457066
- `line_count`: 9835
- `sha256`: 322948de540140e50d4623210b6185945f8cdb878b9c2c4d034c2ea72de5d847
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=457066 bytes; lines=9835; FAIL=2; PASS=1; tail=%pushi/vec4 1970303087, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1920230756, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544367987, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 176819132...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 417800
- `line_count`: 8306
- `sha256`: 7c70939d794872bf5a8d8761c011b462a7d05afddbcae5eb53a0594ac3061539
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2}
- `summary`: vvp evidence; size=417800 bytes; lines=8306; FAIL=2; tail=ncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 3...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 125913
- `line_count`: 3149
- `sha256`: b396de4ea670b660acf8825d242f6627c3bca3598131512a0dd4c16a77e39bd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=125913 bytes; lines=3149; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 323785
- `line_count`: 8272
- `sha256`: dc8158246aa142dec830c24cbdf80ecc11f454623077934de4669826364e5a0a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=323785 bytes; lines=8272; FAIL=6; PASS=3; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 197151
- `line_count`: 5127
- `sha256`: fde487e7bcd3ba3e4cf2d6124adbe49cb8161cf92c196d9d730414358e8ae5da
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 3}
- `summary`: vvp evidence; size=197151 bytes; lines=5127; FAIL=8; PASS=3; tail=ec4 2147500032, 0, 64; %store/vec4 v0x55905c5213d0_0, 0, 64; %pushi/vec4 6292243, 0, 32; %store/vec4 v0x55905c5211f0_0, 0, 32; %pushi/vec4 7340947, 0, 32; %store/vec4 v0x55905c5212f0_0, 0, 32; %fork TD_tb_ooo_fetch_packet_fifo.drive_enqueue_packet, S_0x5590...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 56265
- `line_count`: 1292
- `sha256`: b7b296ff8479411d00479c2d775d8a838b43f9054f716f9c341f67a47e577333
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=56265 bytes; lines=1292; FAIL=14; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 69962
- `line_count`: 1833
- `sha256`: 5a010479c4d8a6d90b25cdad6e13111673d2b49a435d60265f8d182e0cbb14ed
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=69962 bytes; lines=1833; FAIL=3; PASS=1; tail=INPUT 1 "drain_pending_system_i"; .port_info 16 /INPUT 1 "drain_pending_branch_undispatched_i"; .port_info 17 /INPUT 1 "drain_pending_jump_i"; .port_info 18 /INPUT 1 "drain_pending_mem_i"; .port_info 19 /OUTPUT 1 "clear_o"; v0x5f8ee8b72bc0_0 .net "branch_re...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1377237
- `line_count`: 35164
- `sha256`: 81573822a0ba178beed94cd24fa464194100f48f67961bc68c7e3d4bc8efa200
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 3}
- `summary`: vvp evidence; size=1377237 bytes; lines=35164; FAIL=5; PASS=3; tail=vec4 v0x588164568170_0; %parti/s 12, 0, 2; %load/vec4 v0x588164568520_0; %pushi/vec4 2, 0, 5; %pushi/vec4 3, 0, 3; %store/vec4 v0x58816456a620_0, 0, 3; %store/vec4 v0x58816456a7c0_0, 0, 5; %store/vec4 v0x58816456a8a0_0, 0, 5; %store/vec4 v0x58816456a700_0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 131596
- `line_count`: 3397
- `sha256`: af76e359481f107e2da4983b1a87d4de568176d8d7aedca6e9eb68a9dda64215
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 1}
- `summary`: vvp evidence; size=131596 bytes; lines=3397; FAIL=6; PASS=1; tail=ng_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 94731
- `line_count`: 2349
- `sha256`: ca17f6eccba7031bce8c79c1adaf433c1b471ffbedc9aa1be96c0be6730f2708
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=94731 bytes; lines=2349; FAIL=4; PASS=1; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_static_classify.vvp

- `kind`: vvp
- `size_bytes`: 133289
- `line_count`: 2374
- `sha256`: 9bdf13412cb255886cd73c0072d29e554933398aee1cc6544e69c84226d3e0ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=133289 bytes; lines=2374; FAIL=4; PASS=1; tail=OR 1, L_0x61e6d892c5e0, L_0x61e6d892d1d0, C4<0>, C4<0>; L_0x61e6d89145a0 .functor OR 1, L_0x61e6d8914530, L_0x61e6d892e420, C4<0>, C4<0>; L_0x61e6d8914660 .functor OR 1, L_0x61e6d89145a0, L_0x61e6d892f820, C4<0>, C4<0>; L_0x61e6d893ff40 .functor OR 1, L_0x6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 5588994
- `line_count`: 124769
- `sha256`: 2438adcad51d4737f80e330c46d802914a5e1489ad89b8e56b6fe92bef66f29d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=5588994 bytes; lines=124769; FAIL=4; tail=9O-CONTROL-EVENT-SELECTIVE-SOURCE] frontend winner lacks matching backend branch projection @%0t", $time {0 0 0}; %vpi_call/w 4 1935 "$fatal" {0 0 0}; T_545.2 ; %load/vec4 v0x596f277d18d0_0; %nor/r; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_545.14, 10;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 400745
- `line_count`: 12008
- `sha256`: 58f081dad7bc7380defed568bebbac619be5873eba203cb993fbabff96dddef5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6}
- `summary`: vvp evidence; size=400745 bytes; lines=12008; FAIL=6; tail=aw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68451
- `line_count`: 1835
- `sha256`: 865e2282138548f93eb36fa4eddf6bdc005642f3ed7d5bc8c9471a063beeab5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68451 bytes; lines=1835; FAIL=7; PASS=2; tail=5f223c685300_0 .var "class_s_bits", 9 0; v0x5f223c6853e0_0 .net "class_value_o", 63 0, L_0x5f223c696e70; alias, 1 drivers v0x5f223c6854c0_0 .net "double_i", 0 0, v0x5f223c686440_0; 1 drivers v0x5f223c685580_0 .net "frs1_value_i", 63 0, v0x5f223c686510_0; 1...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 97895
- `line_count`: 2767
- `sha256`: 47b921064e343251f997aaa6684df1905d1d257a336bcebbf5f32cd68ba26717
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=97895 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x5d0ca9a7ac80_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x5d0ca9a7af70_0; %store/vec4 v0x5d0ca9a7b890_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x5d0ca9a7add0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x5d0ca9a7ae90_0; %store/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202658
- `line_count`: 6365
- `sha256`: 470070805abd9309fc3133a799970301a171665bb044c6e348ee83c4844149a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202658 bytes; lines=6365; FAIL=4; tail=aad160_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x579093aacc50_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x579093aad760_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x579093aacd10_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x579093aad820_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 481776
- `line_count`: 12442
- `sha256`: 9f877ac5890507e4e65c168cb0c049186f94f28ac708f96ace6884e2d10023fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=481776 bytes; lines=12442; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1412646432, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919247215, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986359909, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 83963
- `line_count`: 2210
- `sha256`: 6813a7589a0f0d00abc30947bd3242ff27d30471f67e80fad749fb32d1156b03
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=83963 bytes; lines=2210; FAIL=8; PASS=2; tail=5735e6e3d180_0 .var "exp_remainder_nonzero", 0 0; v0x5735e6e3d260_0 .var "exp_root", 55 0; v0x5735e6e3d340_0 .var "first_value", 111 0; v0x5735e6e3d400_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start ; %pushi/vec4 1024, 0, 112; %s...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 216182
- `line_count`: 5300
- `sha256`: cda8ac2682169975a5fa16b04c10fc285603e834635d8bff3cee7c6425026007
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=216182 bytes; lines=5300; FAIL=3; PASS=2; tail=set/imm 4, 0; %store/vec4 v0x64cf734bdc40_0, 4, 2; %pushi/vec4 1, 0, 1; %ix/load 4, 29, 0; %flag_set/imm 4, 0; %store/vec4 v0x64cf734bdc40_0, 4, 1; %jmp T_9.34; T_9.31 ; %pushi/vec4 0, 0, 1; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x64cf734bdc40_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197006
- `line_count`: 6101
- `sha256`: 44099c1b685a8b537df5a9debe45b462164e15d14a2dc624643a18ea0b38a20c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197006 bytes; lines=6101; markers=<none>; tail=vec4 v0x56b55c454420_0; %parti/s 1, 2, 3; %store/vec4 v0x56b55c453e60_0, 0, 1; %load/vec4 v0x56b55c454420_0; %parti/s 1, 1, 2; %load/vec4 v0x56b55c454420_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x56b55c454280_0; %or; %store/vec4 v0x56b55c454940_0, 0, 1; %push...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64037
- `line_count`: 1638
- `sha256`: e2f918e319865f3dfa74e1c34099072b0feb924ff05cbeee67876cc213264a3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64037 bytes; lines=1638; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30253
- `line_count`: 661
- `sha256`: 9b934b036bc9e32a152cd9ac9b0ed3a58f8a09c6781d9b966bb7c655d2d70777
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30253 bytes; lines=661; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39292
- `line_count`: 1056
- `sha256`: b9f208f0ffd3c91e79bdd39beb99f131ac2fdc184d4fd8560b6564744cfe71c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39292 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 75847
- `line_count`: 1877
- `sha256`: 10306fe7314c6d477769b7c90a18a6183ac5bb36c79c8055cda07122f40d56c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=75847 bytes; lines=1877; FAIL=6; PASS=2; tail=vers v0x56fdbba62c10_0 .var "head_q", 5 0; v0x56fdbba63100_0 .var/i "idx", 31 0; v0x56fdbba631e0_0 .net "next_count_w", 6 0, L_0x56fdbba681c0; 1 drivers v0x56fdbba632c0_0 .net "post_alloc_count_w", 6 0, L_0x56fdbba66cf0; 1 drivers v0x56fdbba633a0_0 .net "po...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 100928
- `line_count`: 2481
- `sha256`: c4ccf95fc9b7295ce7cbc797c5ca20a2759353476ca2d1d5ed87ee3ae8d47ffb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=100928 bytes; lines=2481; FAIL=3; PASS=1; tail=, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 110858
- `line_count`: 2616
- `sha256`: b89b082f7054dc51df00492967e36329d52bc00107b43bf5004be41b9fcdb779
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=110858 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x5c93ac877090_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5c93ac8775f0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x5c93ac87cec0; %join; %free S_0x5c93ac87cec0; %alloc S_0x5c93ac8c4d80; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x5c93ac8c...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 146851
- `line_count`: 3486
- `sha256`: 47c795b0cd10e4e08b9704eb206804bce5411f2e55056c42db6454e59d3adced
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=146851 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x59a2e04a0d90; %alloc S_0x59a2e04a0d90; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 90847
- `line_count`: 2250
- `sha256`: 5a95e4fb037ab8fe43dd5124be15f887041e019615eb1d4ed5ccf59d33c6e06c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=90847 bytes; lines=2250; FAIL=3; PASS=1; tail=4 1718558834, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702061426, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986338913, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986095468, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138490
- `line_count`: 3101
- `sha256`: 902e84741a74c85b631238914f3e0ab64afd77fbec2e471712657b730300ba1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138490 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 696839
- `line_count`: 15284
- `sha256`: 3010f2fe749b8a7d28164a66d99b8ba1ed4ed9fbffa24634ee0614fed3a2b51a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 6}
- `summary`: vvp evidence; size=696839 bytes; lines=15284; FAIL=3; PASS=6; tail=v0x63d8c8b1a280_0, 0, 2; %pushi/vec4 0, 0, 1; %store/vec4 v0x63d8c8af1de0_0, 0, 1; %fork TD_tb_ooo_ifu_lane1_fault_owner.run_tval_lifecycle_row, S_0x63d8c8957070; %join; %free S_0x63d8c8957070; %alloc S_0x63d8c8957070; %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 12218914
- `line_count`: 306472
- `sha256`: cc784818a59ead2d1736a0e976950fad87787effa941a45f3e44922d4b24bac4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=12218914 bytes; lines=306472; PASS=2; tail=v0x5668de3d42e0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5668de3d42e0_0, 0, 1; %delay 1, 0; %alloc S_0x5668dd15e2c0; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1196504
- `line_count`: 30124
- `sha256`: 3251e76733a7b8e0a7601a2d26a3ae26b2e4969cc91502565dccd39508f0561e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1196504 bytes; lines=30124; markers=<none>; tail=/vec4 1, 0, 1; %store/vec4 v0x588ec9653190_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x588ec9653190_0, 0, 1; %alloc S_0x588ec9490c70; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x588ec9490c70; %join; %free S_0x588ec9490c70; %delay 1, 0; %...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_load_queue.vvp

- `kind`: vvp
- `size_bytes`: 199457
- `line_count`: 4947
- `sha256`: df40d7a313de3ec98220817663bddcd899a8021d70bd65f5d985b0e846c26e56
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: vvp evidence; size=199457 bytes; lines=4947; PASS=3; tail=string_vec4 %pushi/vec4 1852142177, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1953066862, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543781664, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_lsu_axi_lane_adapter.vvp

- `kind`: vvp
- `size_bytes`: 118694
- `line_count`: 3332
- `sha256`: 1d5513bdbc483b06524dc605466614faf51a490d61d1dbf01a86a2cecec086bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 9, "PASS": 2}
- `summary`: vvp evidence; size=118694 bytes; lines=3332; FAIL=9; PASS=2; tail=3c9050 .reduce/nor v0x59bef33abe20_0; L_0x59bef33c9560 .cmp/eq 3, v0x59bef33ad4a0_0, L_0x76116c0ce2e8; L_0x59bef33c9ab0 .ufunc/vec4 TD_tb_ooo_lsu_axi_lane_adapter.dut.sticky_resp, 2, v0x59bef33ad140_0, v0x59bef33b4500_0 (v0x59bef33a62c0_0, v0x59bef33a61c0_0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 3579822
- `line_count`: 91070
- `sha256`: 447e4aa4ef4a6a6b968b0a02e9b4007ad5c52433a1a823be059be1d395e92e2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 1}
- `summary`: vvp evidence; size=3579822 bytes; lines=91070; FAIL=1; PASS=1; tail=%and; T_215.148; %flag_set/vec4 10; %flag_or 9, 10; T_215.147; %flag_get/vec4 9; %jmp/1 T_215.146, 9; %load/vec4 v0x59334d375d30_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_215.150, 9; %load/vec4 v0x59334d36fb60_0; %load/vec4 v0x59334d37a690_0; %cmp/ne;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_mem_inflight_queue.vvp

- `kind`: vvp
- `size_bytes`: 305323
- `line_count`: 7665
- `sha256`: c13a6c0227bc06e82059d526d491e928427f8f871ee15a1f5f7b21fc1e9d2ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=305323 bytes; lines=7665; FAIL=4; PASS=2; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 84965
- `line_count`: 2354
- `sha256`: 46b51299e8d4bacfa2db67a21c4a3cf7d8e59eb3fd30f8dc80e4a8861a8abc45
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 3}
- `summary`: vvp evidence; size=84965 bytes; lines=2354; FAIL=1; PASS=3; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_mem_owner_tracker.vvp

- `kind`: vvp
- `size_bytes`: 136101
- `line_count`: 3605
- `sha256`: 465fa9f1d567860c450eb8b1759cd856b69411f1c74018450061b897059d5bd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: vvp evidence; size=136101 bytes; lines=3605; FAIL=2; PASS=4; tail=/ne 3, 0, 3; %jmp/1 T_14.19, 4; %flag_mov 8, 4; %load/vec4 v0x5eee50b736d0_0; %parti/s 1, 5, 4; %nor/r; %flag_set/vec4 9; %flag_or 9, 8; %flag_mov 4, 9; T_14.19; %jmp/0xz T_14.17, 4; %alloc S_0x5eee50b71a30; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 58048
- `line_count`: 1438
- `sha256`: 0ee9c193befca95f7933c617e5859f948239f762d6e28d62ed53d5a777e41aba
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=58048 bytes; lines=1438; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_mmu_epoch_owner.vvp

- `kind`: vvp
- `size_bytes`: 135188
- `line_count`: 3828
- `sha256`: 42bc0988d6a80354bf52d155a5c3e5a9d29bb179dd48ed47b1c22c43527ff14d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=135188 bytes; lines=3828; FAIL=1; PASS=4; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 348991
- `line_count`: 8867
- `sha256`: 8113d85844f91818056f52116fa22c42064e3ec1b149663e2d0bfeccf6606ea7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=348991 bytes; lines=8867; FAIL=5; tail=ushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 218534
- `line_count`: 4978
- `sha256`: 4c4ab777a75e5b3e512631742c03b31eba54fcd8c4fb7491107344a3711ce245
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=218534 bytes; lines=4978; FAIL=5; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 824206949, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1952671776, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1717663084, 0, 32; draw_string_vec4 %concat/vec4; draw_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 96464
- `line_count`: 2319
- `sha256`: 00cc5e94a248ebf82f76c1c3c67850f91ded4b2bb32a155eb1621e3b2862dcfb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=96464 bytes; lines=2319; FAIL=3; PASS=1; tail=hi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 108020
- `line_count`: 2656
- `sha256`: 51e37f62c15fc5c914f7984ca5dfa4710fbbc5aec16d7291865488a13f2f3697
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108020 bytes; lines=2656; FAIL=5; PASS=1; tail=_capture_gate.clear_inputs, S_0x5b8f83ff1390; %join; %free S_0x5b8f83ff1390; %pushi/vec4 1, 0, 1; %store/vec4 v0x5b8f83ff1780_0, 0, 1; %pushi/vec4 1, 0, 1; %ix/load 4, 38, 0; %flag_set/imm 4, 0; %store/vec4 v0x5b8f83ff5270_0, 4, 1; %delay 1000, 0; %alloc S_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pending_system_admission_cancel_gate.vvp

- `kind`: vvp
- `size_bytes`: 14437
- `line_count`: 323
- `sha256`: 5291fe4a2f034f3a621cbde9e9b275dc85a5647360811c4f54c3dddf4e75df95
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=14437 bytes; lines=323; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 135644
- `line_count`: 3392
- `sha256`: 33ab898785aa610c8398f8c28a9d64fd0fca006d9e55c00be49c062d9bdc315f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 2}
- `summary`: vvp evidence; size=135644 bytes; lines=3392; FAIL=5; PASS=2; tail=%load/vec4 v0x61776b0a0930_0; %assign/vec4 v0x61776b0a2050_0, 0; %pushi/vec4 0, 0, 5; %assign/vec4 v0x61776b0a3620_0, 0; %pushi/vec4 0, 0, 8; %assign/vec4 v0x61776b0a42a0_0, 0; %jmp T_9.12; T_9.11 ; %load/vec4 v0x61776b0a2de0_0; %flag_set/vec4 9; %flag_get/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 28463
- `line_count`: 854
- `sha256`: d0d2eff820df6714082600e3d83fdc9a6a3bdf8efc5c73ca43d7dc2b33d6b106
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: vvp evidence; size=28463 bytes; lines=854; FAIL=2; PASS=6; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 192896
- `line_count`: 4897
- `sha256`: 7669b712276726e8a6d9e9db823ecac1e131a731c8f84f1382422e8bddd40536
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=192896 bytes; lines=4897; FAIL=3; PASS=1; tail=w_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_pma_checker.vvp

- `kind`: vvp
- `size_bytes`: 118579
- `line_count`: 2750
- `sha256`: cf7d23ad058ceadddb80e350e60dc04879517628d91a2ed6e5e21040d9942fcb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=118579 bytes; lines=2750; FAIL=4; PASS=2; tail=768843040, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1347637825, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1293968485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1668244581, 0, 32; dr...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6388764
- `line_count`: 146569
- `sha256`: c98d20c5a49ac242f6cd0166872e5f8488f49512d30f73904baca52180b49a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6388764 bytes; lines=146569; FAIL=3; PASS=2; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63728
- `line_count`: 1586
- `sha256`: db0ad9212ca960614186f06076922e2e6359a12492e2026948ed24bd30a7b2b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63728 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 34854
- `line_count`: 876
- `sha256`: 1a88411c1a25bdd51941f659b82bf9a35d494f39140d7e34a2c278ab839b46d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 22, "PASS": 2}
- `summary`: vvp evidence; size=34854 bytes; lines=876; FAIL=22; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99472
- `line_count`: 2436
- `sha256`: 8a879c29e5ee5d62aaf4064072aeb77bdb3f88f496ed1d8031f390a46d96d983
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99472 bytes; lines=2436; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 1076006
- `line_count`: 26450
- `sha256`: 49180a3d276c28e4e3a12c88d339c028eed9db6d267b461b4b8fe5a42e0e6f0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1076006 bytes; lines=26450; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 66064
- `line_count`: 1798
- `sha256`: d663748c1ddffee160efe56ca426a3eea09323b0c2e7b83d71df7054e8a67411
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 3}
- `summary`: vvp evidence; size=66064 bytes; lines=1798; FAIL=3; PASS=3; tail=cd2fd82ac0 .scope module, "tb_ooo_stop_pending_sequencer" "tb_ooo_stop_pending_sequencer" 3 4; .timescale -9 -12; v0x5acd2fda3ec0_0 .var "branch_resolve_untracked", 0 0; v0x5acd2fda3f80_0 .var "branch_spec_checkpoint_capture", 0 0; v0x5acd2fda4020_0 .var "b...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 584857
- `line_count`: 14289
- `sha256`: ca65ac52823a2838d5f5ed21facb6966f6cfcbe8a3e840fda98e796fb10be631
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=584857 bytes; lines=14289; FAIL=1; PASS=4; tail=020; %alloc S_0x5623819eb7e0; %pushi/vec4 12, 0, 4; %store/vec4 v0x562381a094e0_0, 0, 4; %fork TD_tb_ooo_store_queue.alloc_one, S_0x5623819eb7e0; %join; %free S_0x5623819eb7e0; %alloc S_0x562381ae2560; %pushi/vec4 12, 0, 4; %store/vec4 v0x562381ae2740_0, 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 8315187
- `line_count`: 192529
- `sha256`: d4157e12f5003429bedb9d2c6933dae57432cb20e7f886e3e34c92050235ffd4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=8315187 bytes; lines=192529; FAIL=14; PASS=2; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36101
- `line_count`: 734
- `sha256`: b6e59b0c5044fa250bb141ada07df38b3db42c409e90cce29906e8b88c6010ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36101 bytes; lines=734; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 16989
- `line_count`: 476
- `sha256`: d6938d59a8c7fab9283eeed83259dadc2faa4a3b5a239dec7316fda0c3f12260
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=16989 bytes; lines=476; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_ooo_typed_memory_classifier.vvp

- `kind`: vvp
- `size_bytes`: 52197
- `line_count`: 1446
- `sha256`: 82f04b1360966cc28c7537fcdc5e956637a08d9d94d4d3915d6b927c7e45a3e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 4}
- `summary`: vvp evidence; size=52197 bytes; lines=1446; FAIL=10; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65157
- `line_count`: 1744
- `sha256`: e5faf826cc07485ff7b612b64eb7a1ac38b32c6e01792e0050102049bbfda77d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65157 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180661
- `line_count`: 4649
- `sha256`: 66c6ce568435e10f0ed81e08d020d5079aad1c9ad5792d3501cc7cdc6d8fd1a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180661 bytes; lines=4649; FAIL=3; PASS=1; tail=3da0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5a0bfc704070_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5a0bfc6bd4a0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5a0bfc703c20_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x5a0bfc6e7140; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300070
- `line_count`: 8070
- `sha256`: 091598afb635742e386f20527dffe957b7de2c3e131d8b22c700f994b5ca043b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300070 bytes; lines=8070; FAIL=4; PASS=1; tail=1; %store/vec4 v0x6270f13d36f0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x6270f13d36f0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x6270f13d3e20_0, 0, 1; %delay 1, 0; %alloc S_0x6270f13d2290; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25241
- `line_count`: 678
- `sha256`: 7370ad3fb9a97b3a6a84cd238bf5fdc02fcaa30ba13ffcc8da511ddd4f36c2b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25241 bytes; lines=678; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_alu.vvp

- `kind`: vvp
- `size_bytes`: 48967
- `line_count`: 1322
- `sha256`: 66ad4a3ce8591f27669184a84cbf0d5f875273d0942ce22d7c13ac4225ef1664
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48967 bytes; lines=1322; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_axi_clint.vvp

- `kind`: vvp
- `size_bytes`: 276271
- `line_count`: 7135
- `sha256`: a3010e2efe8d8f5c2a14b7a2160adb6bc617ff7ba7e3b88afa749b617d615429
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=276271 bytes; lines=7135; markers=<none>; tail=ec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; dra...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_axi_exec_firewall.vvp

- `kind`: vvp
- `size_bytes`: 219285
- `line_count`: 5754
- `sha256`: bf63735fe885b8e2c99f7f4ec1ff8b99601c13c1b732bab2b12171805b78c241
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=219285 bytes; lines=5754; FAIL=3; PASS=2; tail=, S_0x56449f9305c0; %join; %free S_0x56449f9305c0; %alloc S_0x56449f88a560; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %p...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_axi_plic.vvp

- `kind`: vvp
- `size_bytes`: 905889
- `line_count`: 16698
- `sha256`: b84f2567d5ac586d993ce4b55515205aacb027f0b8c47046ef45b9bb5acb77b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=905889 bytes; lines=16698; markers=<none>; tail=ng_vec4 %pushi/vec4 1919513701, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544566893, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1634954099, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 5...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_axi_reset_syscon.vvp

- `kind`: vvp
- `size_bytes`: 169874
- `line_count`: 4395
- `sha256`: 2d68e65b8da0c73748699c68073a9cbf7f6cdfe88b5d05a9d1513d999d1abe46
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=169874 bytes; lines=4395; FAIL=3; PASS=1; tail=4; draw_string_vec4 %pushi/vec4 1751738216, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 541204578, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701015405, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_axi_to_uart.vvp

- `kind`: vvp
- `size_bytes`: 151922
- `line_count`: 4004
- `sha256`: 2fddc95cddfa6e4fdbfa39b33c9289c9aea9b9dc82e1fc4da6e3bfe48954fb20
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=151922 bytes; lines=4004; FAIL=3; PASS=1; tail=, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x596fe49c79e0_0, 0, 1; %pushi/vec4 0, 0, 32; %store/vec4 v0x596fe49c7770_0, 0, 32; %pushi/vec4 2, 0, 3; %store/vec4 v0x596fe49c7910_0, 0, 3; %pushi/vec4 0, 0, 1; %store/vec4 v0x596fe49c8980_0, 0, 1; %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_axi_xbar.vvp

- `kind`: vvp
- `size_bytes`: 314045
- `line_count`: 8462
- `sha256`: 2943ef2922e61350f4cbe4563a23c93d497c26b55807612413e7925c89eb9b6b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=314045 bytes; lines=8462; FAIL=3; PASS=2; tail=g_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_compare.vvp

- `kind`: vvp
- `size_bytes`: 32438
- `line_count`: 864
- `sha256`: 34d3998ac25556978c1663847ca881fb5da3f9e5c93dd259178e4139a5308dfd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32438 bytes; lines=864; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_csr_file.vvp

- `kind`: vvp
- `size_bytes`: 581129
- `line_count`: 14244
- `sha256`: 85cf1058f5b0f564ebaf17c7bd5608a8a9cc09608a8cc30ad1aea69189403d92
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=581129 bytes; lines=14244; markers=<none>; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 1702000233, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1936683552, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_csr_file_vectored_trap.vvp

- `kind`: vvp
- `size_bytes`: 355728
- `line_count`: 8239
- `sha256`: 465e49851fbd832432ca1a83eadf4e571d8269ab9ffe2397b5f1b3ab1f8abc78
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=355728 bytes; lines=8239; FAIL=2; PASS=1; tail=%pushi/vec4 66, 0, 64; %store/vec4 v0x647dca39d840_0, 0, 64; %fork TD_tb_csr_file_vectored_trap.check64, S_0x647dca360b40; %join; %free S_0x647dca360b40; %alloc S_0x647dca4d5090; %fork TD_tb_csr_file_vectored_trap.reset_case, S_0x647dca4d5090; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_decode_stage.vvp

- `kind`: vvp
- `size_bytes`: 112262
- `line_count`: 3912
- `sha256`: 2fbbf2cd6a7a48eecc2a0c68d63e02f0787ad93821e7da49888d5eb26e5ccad4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=112262 bytes; lines=3912; FAIL=3; PASS=1; tail=0, 5; %cmp/ne; %flag_get/vec4 4; %or; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x5da066bed980_0, 4, 1; %jmp T_14.57; T_14.46 ; %pushi/vec4 0, 0, 1; %ix/load 4, 8, 0; %flag_set/imm 4, 0; %store/vec4 v0x5da066bed980_0, 4, 1; %pushi/vec4 1, 0, 1; %ix...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_decode_unit.vvp

- `kind`: vvp
- `size_bytes`: 274309
- `line_count`: 8084
- `sha256`: c792ba20a0047b57ea9bfc45398b2e6763c3d034ebc2b3d8fe21a528f34aabe1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=274309 bytes; lines=8084; FAIL=3; PASS=1; tail=2; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_immgen.vvp

- `kind`: vvp
- `size_bytes`: 32654
- `line_count`: 892
- `sha256`: 85d800333278b2231ac1a787a6860cb2069cbe9d1d339f03e636db990859255d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32654 bytes; lines=892; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_lsu.vvp

- `kind`: vvp
- `size_bytes`: 37930
- `line_count`: 983
- `sha256`: 8713c1df62b5c35d8d7323b04ef2dc390b047d35f7599cfc7512e15c462ae6f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=37930 bytes; lines=983; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_lsu_control.vvp

- `kind`: vvp
- `size_bytes`: 40314
- `line_count`: 1057
- `sha256`: 9e9dddec0d0a9be277a7eab822d755e584f23efde1bbca2621a52e76a246a6e8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=40314 bytes; lines=1057; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_lsu_datapath.vvp

- `kind`: vvp
- `size_bytes`: 28612
- `line_count`: 748
- `sha256`: a991d3ba38c1d471becf6de7580ac561055cd16c6cdc9066c2026391d8909abf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=28612 bytes; lines=748; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_alu_core_slice.vvp

- `kind`: vvp
- `size_bytes`: 3752432
- `line_count`: 86716
- `sha256`: a37620d816346d773b91886e7e1c4043d92f3c66711f6b0d42ab663ccce28b2f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=3752432 bytes; lines=86716; markers=<none>; tail=%pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_alu_decode_backend.vvp

- `kind`: vvp
- `size_bytes`: 3652962
- `line_count`: 85095
- `sha256`: ecf8395e3a506e18fb5909d3d7a92ffdef8bd9dae8b3a1b37b17e3920a0b9d7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1}
- `summary`: vvp evidence; size=3652962 bytes; lines=85095; FAIL=1; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 114, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1635197028, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1701864814, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_amo_gate.vvp

- `kind`: vvp
- `size_bytes`: 39372
- `line_count`: 1135
- `sha256`: c58ccf090faa8529438c56c4259d15170d3152fa7b7a6c53a12257eb5dec4eae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=39372 bytes; lines=1135; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_backend_drain_tracker.vvp

- `kind`: vvp
- `size_bytes`: 30684
- `line_count`: 801
- `sha256`: 701ce69cb86c90e266a1845bce8b00b43ccd0f1b0184ec32857a79235178a8d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=30684 bytes; lines=801; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_bitmanip_gate.vvp

- `kind`: vvp
- `size_bytes`: 108566
- `line_count`: 3346
- `sha256`: 51a7aee446ee37eda5c0ad2e00b86e9893184c839c849719bc17d4084ece4ed8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108566 bytes; lines=3346; FAIL=5; PASS=1; tail=load/vec4 v0x5748d8551cc0_0; %concat/vec4; draw_concat_vec4 %sub; %ix/vec4 4; %shiftl 4; %or; %jmp/0 T_22.19, 8; ; End of false expr. %blend; T_22.19; %store/vec4 v0x5748d85532a0_0, 0, 64; %jmp T_22.17; T_22.9 ; %load/vec4 v0x5748d8551cc0_0; %cmpi/e 0, 0, 6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_branch_append_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 36516
- `line_count`: 758
- `sha256`: a8f2399dab2cf2809df9fb3c6501ead0935551899d117fd61b20319e71e18212
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=36516 bytes; lines=758; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_branch_bpu_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 30029
- `line_count`: 663
- `sha256`: 5b5002c05ec801f0e75d262c861bfe486e010e310bf4616be227a1b221a61d7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=30029 bytes; lines=663; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_branch_direction_predictor.vvp

- `kind`: vvp
- `size_bytes`: 138036
- `line_count`: 3130
- `sha256`: 3091641272860e33318a66c6194a684bb7f4d850724a199c68aedad732f7e6c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=138036 bytes; lines=3130; FAIL=4; PASS=1; tail=541, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1847620468, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919905383, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x5f3fd5db34a0_0, 0, 1024;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_branch_resolve_recovery_gate.vvp

- `kind`: vvp
- `size_bytes`: 34196
- `line_count`: 710
- `sha256`: eeb6824588248d288763121c25a06910eb04b4eaee62e85835b2e3dfe7f8901b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=34196 bytes; lines=710; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_branch_spec_tracker.vvp

- `kind`: vvp
- `size_bytes`: 47153
- `line_count`: 1228
- `sha256`: 556a82740869c3e295d1c4ed61ca9691aba668090d73483291a3862e4c453deb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=47153 bytes; lines=1228; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_busy_table.vvp

- `kind`: vvp
- `size_bytes`: 53833
- `line_count`: 1355
- `sha256`: 0e9ce4572c3ec62027681482f9dc00a7835234a150815249c830a8178fb232d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=53833 bytes; lines=1355; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_clmul_unit.vvp

- `kind`: vvp
- `size_bytes`: 147679
- `line_count`: 3839
- `sha256`: 055247baa8253d03a9a4d47d110563e7c22fe5efa0e79d6112d206bd0ba8cc3c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 9, "PASS": 1}
- `summary`: vvp evidence; size=147679 bytes; lines=3839; FAIL=9; PASS=1; tail=raw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1751479072, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1380275024, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x57dce3de7020_0, 0, 1024; %load/vec4 v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_commit_output_mux.vvp

- `kind`: vvp
- `size_bytes`: 72082
- `line_count`: 1665
- `sha256`: 7ff3f5cd1ad716592d6a08efe35b680b0f361e6a289ece347d993660f0b23e59
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 11, "PASS": 1}
- `summary`: vvp evidence; size=72082 bytes; lines=1665; FAIL=11; PASS=1; tail=.port_info 8 /INPUT 1 "synth_lane1_branch_append_i"; .port_info 9 /INPUT 64 "synth_branch_append_pc_i"; .port_info 10 /INPUT 32 "synth_branch_append_inst_i"; .port_info 11 /INPUT 64 "synth_branch_append_next_pc_i"; .port_info 12 /INPUT 1 "core_commit0_valid...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_control_commit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 53875
- `line_count`: 1306
- `sha256`: 37731fd02e54c6ee140899a313266c9251740f16c14b2f531c8d3e023aa2a122
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53875 bytes; lines=1306; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_control_event_apply_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 23763
- `line_count`: 627
- `sha256`: 87eefe2589cfff8f1c8383614324694b3ab5d7b73ba0f4610c91f7f56a02f1b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 12, "PASS": 2}
- `summary`: vvp evidence; size=23763 bytes; lines=627; FAIL=12; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_control_flush_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 29483
- `line_count`: 785
- `sha256`: 30eaf769a0d6504146306014cc1f8df9ada7a75766dd043db686385a86701f22
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=29483 bytes; lines=785; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_core_top_glue.vvp

- `kind`: vvp
- `size_bytes`: 6390126
- `line_count`: 145153
- `sha256`: 607492cfd12b0fd4f1ee1f028158beeecd9c8d1773d27a9d2a0d77f1843fff65
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 1}
- `summary`: vvp evidence; size=6390126 bytes; lines=145153; PASS=1; tail=%pushi/vec4 1635085428, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543711598, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1684825458, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543520873...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_csr_access_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 48659
- `line_count`: 1144
- `sha256`: 102cb3df97b0a4719675158fcc615032620ec38ea0fa9d9c78248d467b9e7866
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=48659 bytes; lines=1144; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_csr_trap_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 34154
- `line_count`: 799
- `sha256`: ad99a9d995f529b52a83b44ef76323e8105d6ce73338e489c920d041ebca593e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 4}
- `summary`: vvp evidence; size=34154 bytes; lines=799; FAIL=4; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_data_word_cache.vvp

- `kind`: vvp
- `size_bytes`: 401936
- `line_count`: 10153
- `sha256`: 0a688bad19ad14f25f77befee095f79a770c22a98f59a95d4bdec8198fba475f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=401936 bytes; lines=10153; markers=<none>; tail=ing_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_direct_branch_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 101127
- `line_count`: 2454
- `sha256`: 08cc5d534e9289c404dc190882f68b6353eb5b602f2b3f10b095e6f393fe92d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=101127 bytes; lines=2454; FAIL=4; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_direct_branch_wait_buffer.vvp

- `kind`: vvp
- `size_bytes`: 53579
- `line_count`: 1375
- `sha256`: e54ee7483bd2a8267d6497b9dd9f6efaa3c2b400cbbf6d0e18d0f97a02160878
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=53579 bytes; lines=1375; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_direct_ras_candidate_gate.vvp

- `kind`: vvp
- `size_bytes`: 98854
- `line_count`: 2306
- `sha256`: 558c3ef1162e4c8b8e23c3ab56ad27283cd9203d2347956a26f6a51c1897d075
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=98854 bytes; lines=2306; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_dispatch_backend.vvp

- `kind`: vvp
- `size_bytes`: 1143803
- `line_count`: 26012
- `sha256`: 5ba0b0a59ea8f8a265d04b32ef71e673d63d0912a427364706e66af0b112259d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1143803 bytes; lines=26012; markers=<none>; tail=ore/vec4 v0x5834c0034360_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x5834c0034280_0, 0, 1; %fork TD_tb_ooo_dispatch_backend.tb_check1, S_0x5834c00340a0; %join; %free S_0x5834c00340a0; %pushi/vec4 1, 0, 1; %store/vec4 v0x5834c0035730_0, 0, 1; %pushi/vec4 1,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_dual_memory_sustained_issue.vvp

- `kind`: vvp
- `size_bytes`: 8182128
- `line_count`: 187697
- `sha256`: 3ea5503fdae20eba6079f2fb41c992d6ad8081fcb0e7bbc19f337fe040fe1774
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 1}
- `summary`: vvp evidence; size=8182128 bytes; lines=187697; FAIL=10; PASS=1; tail=%nor/r; %flag_set/vec4 9; %flag_or 8, 9; T_1032.7; %jmp/1 T_1032.6, 8; %load/vec4 v0x599dcf4595a0_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1032.6; %jmp/1 T_1032.5, 8; %load/vec4 v0x599dcf45a290_0; %cmpi/ne 0, 0, 2; %flag_or 8, 6; T_1032.5; %jmp/0xz T_1032.3, 8...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 1266778
- `line_count`: 33289
- `sha256`: 8ba35ff4b468c6b35f5ab286afbef365630bc4ed102b21f6f544c32989961cc2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 12, "PASS": 13}
- `summary`: vvp evidence; size=1266778 bytes; lines=33289; FAIL=12; PASS=13; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_axi_access_attrs.vvp

- `kind`: vvp
- `size_bytes`: 840389
- `line_count`: 21428
- `sha256`: b899b248e7d3aa9db9db27082d9311f0601885cb24a48c4c2998ac805b05f15c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=840389 bytes; lines=21428; FAIL=3; PASS=2; tail=ad/vec4 v0x599af21418a0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_170.88, 9; %load/vec4 v0x599af21412c0_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/1 T_170.89, 9; %load/vec4 v0x599af2141200_0; %or; T_170.89; %nor/r; %and; T_170.88; %flag_set/vec4 8; %...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 2338470
- `line_count`: 59667
- `sha256`: 42168b592c9e0a8114920151a4f91016fd3a8c77848e71fcfd3a19dd40496b6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=2338470 bytes; lines=59667; FAIL=3; PASS=2; tail=eed_ad_update, S_0x5a0e05e8f360; %join; %free S_0x5a0e05e8f360; %pushi/vec4 1, 0, 1; %store/vec4 v0x5a0e05eb0590_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x5a0e05eaf650_0, 0, 1; %pushi/vec4 1, 0, 1; %store/vec4 v0x5a0e05eaff30_0, 0, 1; %pushi/vec4 1, 0, 1...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_axi_bridge_xbar.vvp

- `kind`: vvp
- `size_bytes`: 960578
- `line_count`: 24597
- `sha256`: b3049529ae2f51d424f01837f671c9a6d3602c6371c08677a2619b935eb3162f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=960578 bytes; lines=24597; FAIL=4; PASS=2; tail=/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; d...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_branch_target.vvp

- `kind`: vvp
- `size_bytes`: 43990
- `line_count`: 1076
- `sha256`: e7f94bc83df40b2eb2058ee7ad88222a879ea4b701b455d6de4b6fcedb0f6d8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=43990 bytes; lines=1076; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_flow_control.vvp

- `kind`: vvp
- `size_bytes`: 126494
- `line_count`: 3125
- `sha256`: 7d95d95cf61b943b94eb8a52eec1ce61190066611f630209721828ebacd45db2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=126494 bytes; lines=3125; FAIL=3; PASS=1; tail=c4; draw_string_vec4 %pushi/vec4 543585644, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1814062697, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1718558820, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_head_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 457066
- `line_count`: 9835
- `sha256`: 031357ddb324bb8680f5e907b99c467413d29283181cd31cad04ebc09baf58ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 1}
- `summary`: vvp evidence; size=457066 bytes; lines=9835; FAIL=2; PASS=1; tail=%pushi/vec4 1970303087, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1920230756, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 544367987, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 176819132...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_head_pair_gate.vvp

- `kind`: vvp
- `size_bytes`: 417800
- `line_count`: 8306
- `sha256`: e2db2ee4df0daca0935718cf1dd586bf7d7172934ea57216c613b3d1c2979fee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2}
- `summary`: vvp evidence; size=417800 bytes; lines=8306; FAIL=2; tail=ncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 3...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_packet_cache.vvp

- `kind`: vvp
- `size_bytes`: 125913
- `line_count`: 3149
- `sha256`: dce93455967341fe6aa718a8b6ff885a0421e9ec1dfaa7078ffa19706fc44368
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=125913 bytes; lines=3149; FAIL=4; PASS=1; tail=_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_packet_decode.vvp

- `kind`: vvp
- `size_bytes`: 323785
- `line_count`: 8272
- `sha256`: 6960b813a9014819e9238d1d653d947581757450054fdd3a1c31eabffc05a731
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 3}
- `summary`: vvp evidence; size=323785 bytes; lines=8272; FAIL=6; PASS=3; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_packet_fifo.vvp

- `kind`: vvp
- `size_bytes`: 197151
- `line_count`: 5127
- `sha256`: a4fe3b6d05648ae3112e38a7b62b1f936c4e63015b0c32cc89de0f50bdb1c164
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 3}
- `summary`: vvp evidence; size=197151 bytes; lines=5127; FAIL=8; PASS=3; tail=ec4 2147500032, 0, 64; %store/vec4 v0x5e6eadb703d0_0, 0, 64; %pushi/vec4 6292243, 0, 32; %store/vec4 v0x5e6eadb701f0_0, 0, 32; %pushi/vec4 7340947, 0, 32; %store/vec4 v0x5e6eadb702f0_0, 0, 32; %fork TD_tb_ooo_fetch_packet_fifo.drive_enqueue_packet, S_0x5e6e...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_packet_head_mux.vvp

- `kind`: vvp
- `size_bytes`: 56265
- `line_count`: 1292
- `sha256`: e1416d02ec70c8f3142a0fa581bd7683ef2e6a2f9f4cdd62fe334b212ed689a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=56265 bytes; lines=1292; FAIL=14; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_packet_seed_mux.vvp

- `kind`: vvp
- `size_bytes`: 69962
- `line_count`: 1833
- `sha256`: 79c588efe9667de607be8942eb76ca4b877597ac7f6385705a7e8ece9f647d37
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=69962 bytes; lines=1833; FAIL=3; PASS=1; tail=INPUT 1 "drain_pending_system_i"; .port_info 16 /INPUT 1 "drain_pending_branch_undispatched_i"; .port_info 17 /INPUT 1 "drain_pending_jump_i"; .port_info 18 /INPUT 1 "drain_pending_mem_i"; .port_info 19 /OUTPUT 1 "clear_o"; v0x5aeeb155fbc0_0 .net "branch_re...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_page_end_fault.vvp

- `kind`: vvp
- `size_bytes`: 1377237
- `line_count`: 35164
- `sha256`: 964f8436cc2f3afe410fd3e8edf8cb325a44a82ffd58022db5c6e89cd3e648ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 3}
- `summary`: vvp evidence; size=1377237 bytes; lines=35164; FAIL=5; PASS=3; tail=vec4 v0x62745b1d7170_0; %parti/s 12, 0, 2; %load/vec4 v0x62745b1d7520_0; %pushi/vec4 2, 0, 5; %pushi/vec4 3, 0, 3; %store/vec4 v0x62745b1d9620_0, 0, 3; %store/vec4 v0x62745b1d97c0_0, 0, 5; %store/vec4 v0x62745b1d98a0_0, 0, 5; %store/vec4 v0x62745b1d9700_0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_pc_outstanding_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 131596
- `line_count`: 3397
- `sha256`: 94adbb37a30d97a0f3d8d03741f921ba609dce9a161165ff8182b82962d0b0f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 1}
- `summary`: vvp evidence; size=131596 bytes; lines=3397; FAIL=6; PASS=1; tail=ng_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_request_mux.vvp

- `kind`: vvp
- `size_bytes`: 94731
- `line_count`: 2349
- `sha256`: 2f5fb32c292abd5af047ee636ea5310a99391ab93b80f7842caff7805c78998b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=94731 bytes; lines=2349; FAIL=4; PASS=1; tail=0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_s...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_static_classify.vvp

- `kind`: vvp
- `size_bytes`: 133289
- `line_count`: 2374
- `sha256`: e631774e5a1a5f6d7b743409896e03d2ac6fd7c75e1704d00f879d962891d0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=133289 bytes; lines=2374; FAIL=4; PASS=1; tail=OR 1, L_0x651125d6f5e0, L_0x651125d701d0, C4<0>, C4<0>; L_0x651125d575a0 .functor OR 1, L_0x651125d57530, L_0x651125d71420, C4<0>, C4<0>; L_0x651125d57660 .functor OR 1, L_0x651125d575a0, L_0x651125d72820, C4<0>, C4<0>; L_0x651125d82f40 .functor OR 1, L_0x6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fetch_trap_gate.vvp

- `kind`: vvp
- `size_bytes`: 5611836
- `line_count`: 124986
- `sha256`: 53863e341d6b7e7b647f40e028c0bd6a48559b5e80f0639cc7f036bd62abbf6d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=5611836 bytes; lines=124986; FAIL=4; tail=9O-CONTROL-EVENT-SELECTIVE-SOURCE] frontend winner lacks matching backend branch projection @%0t", $time {0 0 0}; %vpi_call/w 4 1935 "$fatal" {0 0 0}; T_545.2 ; %load/vec4 v0x647baf194bf0_0; %nor/r; %flag_set/vec4 10; %flag_get/vec4 10; %jmp/0 T_545.14, 10;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_arith_gate.vvp

- `kind`: vvp
- `size_bytes`: 400745
- `line_count`: 12008
- `sha256`: 1d24b7a0325aae6a8268c453f75c54fb4d8ef58f7f9d10792ae46f56e4dbb160
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6}
- `summary`: vvp evidence; size=400745 bytes; lines=12008; FAIL=6; tail=aw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_classify_gate.vvp

- `kind`: vvp
- `size_bytes`: 68451
- `line_count`: 1835
- `sha256`: 0d0183bec4e131c7875ab29c19e8c5208b5b1e9225babe2447b7015e0ccee1ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 7, "PASS": 2}
- `summary`: vvp evidence; size=68451 bytes; lines=1835; FAIL=7; PASS=2; tail=600e50fa4300_0 .var "class_s_bits", 9 0; v0x600e50fa43e0_0 .net "class_value_o", 63 0, L_0x600e50fb5e70; alias, 1 drivers v0x600e50fa44c0_0 .net "double_i", 0 0, v0x600e50fa5440_0; 1 drivers v0x600e50fa4580_0 .net "frs1_value_i", 63 0, v0x600e50fa5510_0; 1...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_compare_gate.vvp

- `kind`: vvp
- `size_bytes`: 97895
- `line_count`: 2767
- `sha256`: 189f8bc293780453b587e6bf8680da01ddae8e3562f8c62ca42c39cd01da6028
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 7, "PASS": 1}
- `summary`: vvp evidence; size=97895 bytes; lines=2767; FAIL=7; PASS=1; tail=v0x5e7bfc016c80_0; %flag_set/vec4 8; %jmp/0xz T_17.6, 8; %load/vec4 v0x5e7bfc016f70_0; %store/vec4 v0x5e7bfc017890_0, 0, 64; %jmp T_17.7; T_17.6 ; %load/vec4 v0x5e7bfc016dd0_0; %flag_set/vec4 8; %jmp/0xz T_17.8, 8; %load/vec4 v0x5e7bfc016e90_0; %store/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_convert_gate.vvp

- `kind`: vvp
- `size_bytes`: 202658
- `line_count`: 6365
- `sha256`: 4b1186cfb04edf55f520de9dc38b309448ceee75fc10377b5bdd2b5388724578
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4}
- `summary`: vvp evidence; size=202658 bytes; lines=6365; FAIL=4; tail=04e160_0, 0, 65; %pushi/vec4 0, 0, 1; %store/vec4 v0x63bcbe04dc50_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63bcbe04e760_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x63bcbe04dd10_0, 0, 1; %pushi/vec4 0, 0, 7; %store/vec4 v0x63bcbe04e820_0, 0, 7; %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 481776
- `line_count`: 12442
- `sha256`: b854e4618c2159eb1c89a1e8db999f150a3519460aa59ae86a40bb46cc859934
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=481776 bytes; lines=12442; FAIL=3; PASS=1; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1412646432, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1919247215, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986359909, 0, 32; draw_string_vec4 %concat/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_iter.vvp

- `kind`: vvp
- `size_bytes`: 83963
- `line_count`: 2210
- `sha256`: 6e5b2888061b20ddaa3efcf10b2f43c02afe31a0e8138568814a2556a2264b4a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=83963 bytes; lines=2210; FAIL=8; PASS=2; tail=5ebaf4eed180_0 .var "exp_remainder_nonzero", 0 0; v0x5ebaf4eed260_0 .var "exp_root", 55 0; v0x5ebaf4eed340_0 .var "first_value", 111 0; v0x5ebaf4eed400_0 .var "root_square", 113 0; TD_tb_ooo_fp_iter.run_sqrt_busy_ignores_start ; %pushi/vec4 1024, 0, 112; %s...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_legality_dispatch_path.vvp

- `kind`: vvp
- `size_bytes`: 216182
- `line_count`: 5300
- `sha256`: 215eaf96c7da005d2adf71c0fee3a9487f40fa838deeffffe1fe40de65ac64dd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=216182 bytes; lines=5300; FAIL=3; PASS=2; tail=set/imm 4, 0; %store/vec4 v0x56e1c29f6c40_0, 4, 2; %pushi/vec4 1, 0, 1; %ix/load 4, 29, 0; %flag_set/imm 4, 0; %store/vec4 v0x56e1c29f6c40_0, 4, 1; %jmp T_9.34; T_9.31 ; %pushi/vec4 0, 0, 1; %ix/load 4, 1, 0; %flag_set/imm 4, 0; %store/vec4 v0x56e1c29f6c40_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_long_op_gate.vvp

- `kind`: vvp
- `size_bytes`: 197006
- `line_count`: 6101
- `sha256`: a3e350b6e77fc59fa1a05967fd451d39fd08334b81a4284d64ae9d6829aea0fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=197006 bytes; lines=6101; markers=<none>; tail=vec4 v0x571effec8420_0; %parti/s 1, 2, 3; %store/vec4 v0x571effec7e60_0, 0, 1; %load/vec4 v0x571effec8420_0; %parti/s 1, 1, 2; %load/vec4 v0x571effec8420_0; %parti/s 1, 0, 2; %or; %load/vec4 v0x571effec8280_0; %or; %store/vec4 v0x571effec8940_0, 0, 1; %push...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 64037
- `line_count`: 1638
- `sha256`: 0f965efdffebe77d186ecd2337486c2dbecd4d3ff30d5cb5c0aebd4c1bb24e8e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=64037 bytes; lines=1638; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 30253
- `line_count`: 661
- `sha256`: a3cd8cab04fce04a0804c46268fb8f7d1c61d1e37e2ac54aed610d0f0e4072b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=30253 bytes; lines=661; FAIL=4; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_fp_sgnj_gate.vvp

- `kind`: vvp
- `size_bytes`: 39292
- `line_count`: 1056
- `sha256`: 4eef11ceb823b6a06ad322e1ab2c610b96050055ac831f2de970af9fb537e5f4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=39292 bytes; lines=1056; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_free_list.vvp

- `kind`: vvp
- `size_bytes`: 75847
- `line_count`: 1877
- `sha256`: 6671ddd53218f6e8642b7de300e33d7de695b3cefeb55dbb3df82734a0e8948c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=75847 bytes; lines=1877; FAIL=6; PASS=2; tail=vers v0x573530576c10_0 .var "head_q", 5 0; v0x573530577100_0 .var/i "idx", 31 0; v0x5735305771e0_0 .net "next_count_w", 6 0, L_0x57353057c1c0; 1 drivers v0x5735305772c0_0 .net "post_alloc_count_w", 6 0, L_0x57353057acf0; 1 drivers v0x5735305773a0_0 .net "po...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_frontend_action_gate.vvp

- `kind`: vvp
- `size_bytes`: 100928
- `line_count`: 2481
- `sha256`: 7fbe1a7742041526b53e24f88d276834e4fb84b9cfd70db123a91dd0f34098fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=100928 bytes; lines=2481; FAIL=3; PASS=1; tail=, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_strin...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_frontend_backend_dispatch_mux.vvp

- `kind`: vvp
- `size_bytes`: 110858
- `line_count`: 2616
- `sha256`: c8e54f5f999e8a9b99308591ff62ee20c5870b70b11ab5a1ecb6b41c2555c080
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=110858 bytes; lines=2616; FAIL=4; PASS=1; tail=4 v0x5f1dbeb1c090_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5f1dbeb1c5f0_0, 0, 1; %fork TD_$unit.tb_check1, S_0x5f1dbeb21ec0; %join; %free S_0x5f1dbeb21ec0; %alloc S_0x5f1dbeb69d80; %fork TD_tb_ooo_frontend_backend_dispatch_mux.reset_inputs, S_0x5f1dbeb6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_frontend_dispatch_gate.vvp

- `kind`: vvp
- `size_bytes`: 146851
- `line_count`: 3486
- `sha256`: 2676da88edb1e7f4d3de9b4652734bed7051b11436c09ac65df9d2483ba3395a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=146851 bytes; lines=3486; FAIL=3; PASS=1; tail=%free S_0x55fb0bf90d90; %alloc S_0x55fb0bf90d90; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_st...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_frontend_run_gate.vvp

- `kind`: vvp
- `size_bytes`: 90847
- `line_count`: 2250
- `sha256`: 4c637bf7b5872cd11de854084b2f4c3e5791c4a6b66f1d6fb09931e581faadd7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=90847 bytes; lines=2250; FAIL=3; PASS=1; tail=4 1718558834, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1702061426, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986338913, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1986095468, 0, 32;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_frontend_uop_safety.vvp

- `kind`: vvp
- `size_bytes`: 138490
- `line_count`: 3101
- `sha256`: 73aa0305fa87aa6be213644c728f82952e1aecc4c65b6900a256a6b32d99d049
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=138490 bytes; lines=3101; FAIL=3; PASS=1; tail=%concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_ifu_lane1_fault_owner.vvp

- `kind`: vvp
- `size_bytes`: 696839
- `line_count`: 15284
- `sha256`: 73152d251ab8b74c783713d1575181dcb63b2d7bef81268a673cad6f52b6bcca
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 6}
- `summary`: vvp evidence; size=696839 bytes; lines=15284; FAIL=3; PASS=6; tail=v0x5880bba1d280_0, 0, 2; %pushi/vec4 0, 0, 1; %store/vec4 v0x5880bb9f4de0_0, 0, 1; %fork TD_tb_ooo_ifu_lane1_fault_owner.run_tval_lifecycle_row, S_0x5880bb85a070; %join; %free S_0x5880bb85a070; %alloc S_0x5880bb85a070; %pushi/vec4 0, 0, 32; draw_string_vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_int_backend.vvp

- `kind`: vvp
- `size_bytes`: 12260310
- `line_count`: 307161
- `sha256`: 6f8d0ec210be29fa4c1134fa1f01309e6d1eda0aff1ff32df027371778da7dad
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: vvp evidence; size=12260310 bytes; lines=307161; PASS=2; tail=v0x62daf1566ec0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x62daf1566ec0_0, 0, 1; %delay 1, 0; %alloc S_0x62daf02deb10; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_int_issue_queue.vvp

- `kind`: vvp
- `size_bytes`: 1196504
- `line_count`: 30124
- `sha256`: 1745cf7982afc5915bbfdeec5a10cf5c0839b90f36593266e9d152d467baf919
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1196504 bytes; lines=30124; markers=<none>; tail=/vec4 1, 0, 1; %store/vec4 v0x635e3eb8c190_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x635e3eb8c190_0, 0, 1; %alloc S_0x635e3e9c9c70; %fork TD_tb_ooo_int_issue_queue.clear_inputs, S_0x635e3e9c9c70; %join; %free S_0x635e3e9c9c70; %delay 1, 0; %...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_load_queue.vvp

- `kind`: vvp
- `size_bytes`: 199457
- `line_count`: 4947
- `sha256`: dd6bf1e7c585a1ea64f0b924310c77ff551490a178bd4456329b59835469afa9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: vvp evidence; size=199457 bytes; lines=4947; PASS=3; tail=string_vec4 %pushi/vec4 1852142177, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1953066862, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 543781664, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_lsu_axi_lane_adapter.vvp

- `kind`: vvp
- `size_bytes`: 118694
- `line_count`: 3332
- `sha256`: b7cc32066fa33153d822820fb8bb8c953f6f9aec608f83167ce6219079ead441
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 9, "PASS": 2}
- `summary`: vvp evidence; size=118694 bytes; lines=3332; FAIL=9; PASS=2; tail=498050 .reduce/nor v0x62069347ae20_0; L_0x620693498560 .cmp/eq 3, v0x62069347c4a0_0, L_0x744bf02402e8; L_0x620693498ab0 .ufunc/vec4 TD_tb_ooo_lsu_axi_lane_adapter.dut.sticky_resp, 2, v0x62069347c140_0, v0x620693483500_0 (v0x6206934752c0_0, v0x6206934751c0_0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_mem_axi_bridge.vvp

- `kind`: vvp
- `size_bytes`: 3579822
- `line_count`: 91070
- `sha256`: 3d9ec86e95667001f424d6fe778f9ad6cb4976a01d7af5644570202d956e6ef6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 1}
- `summary`: vvp evidence; size=3579822 bytes; lines=91070; FAIL=1; PASS=1; tail=%and; T_215.148; %flag_set/vec4 10; %flag_or 9, 10; T_215.147; %flag_get/vec4 9; %jmp/1 T_215.146, 9; %load/vec4 v0x560d2400dd30_0; %flag_set/vec4 9; %flag_get/vec4 9; %jmp/0 T_215.150, 9; %load/vec4 v0x560d24007b60_0; %load/vec4 v0x560d24012690_0; %cmp/ne;...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_mem_inflight_queue.vvp

- `kind`: vvp
- `size_bytes`: 305323
- `line_count`: 7665
- `sha256`: 6aa374574ae5967fa7c21aa3d08a1ab49586973d1e93e77a2872508662ac4336
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=305323 bytes; lines=7665; FAIL=4; PASS=2; tail=string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pus...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_mem_owner_terminal_collector.vvp

- `kind`: vvp
- `size_bytes`: 106024
- `line_count`: 2903
- `sha256`: 3e1b0d560833c1d3bb673f99ed04f6db3e526f8bc1bbddfb1c22bcc5e22815e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 5}
- `summary`: vvp evidence; size=106024 bytes; lines=2903; FAIL=1; PASS=5; tail=%addi 1, 0, 32; %store/vec4 v0x580c3db36620_0, 0, 32; %jmp T_11.13; T_11.14 ; T_11.10 ; %jmp T_11; .thread T_11, $push; .scope S_0x580c3dada0e0; T_12 ; %wait E_0x580c3da84dc0; %load/vec4 v0x580c3db36560_0; %flag_set/vec4 8; %jmp/0xz T_12.0, 8; %pushi/vec4 0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_mem_owner_tracker.vvp

- `kind`: vvp
- `size_bytes`: 136101
- `line_count`: 3605
- `sha256`: 51343cbd56610a4fa2aa483fe27d2343951ba562a4533304a3011b4d5c6b80f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 4}
- `summary`: vvp evidence; size=136101 bytes; lines=3605; FAIL=2; PASS=4; tail=/ne 3, 0, 3; %jmp/1 T_14.19, 4; %flag_mov 8, 4; %load/vec4 v0x6241379b66d0_0; %parti/s 1, 5, 4; %nor/r; %flag_set/vec4 9; %flag_or 9, 8; %flag_mov 4, 9; T_14.19; %jmp/0xz T_14.17, 4; %alloc S_0x6241379b4a30; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_memory_request_gate.vvp

- `kind`: vvp
- `size_bytes`: 58048
- `line_count`: 1438
- `sha256`: ac920db1acedab6c9a6644211e2c8c147265f2785c0e740a4e14482787b50463
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 2}
- `summary`: vvp evidence; size=58048 bytes; lines=1438; FAIL=10; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_mmu_epoch_owner.vvp

- `kind`: vvp
- `size_bytes`: 135188
- `line_count`: 3828
- `sha256`: 151ce208412ae5122de7f445f5517f79393bf39f088dc8b09f7940f927254147
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=135188 bytes; lines=3828; FAIL=1; PASS=4; tail=draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_str...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_muldiv_unit.vvp

- `kind`: vvp
- `size_bytes`: 348991
- `line_count`: 8867
- `sha256`: f8e5bf37481b0a20ab33e9f1bb601e8239ad61bb2b23a2a11c425aeb54eda2b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5}
- `summary`: vvp evidence; size=348991 bytes; lines=8867; FAIL=5; tail=ushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pending_dispatch_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 218534
- `line_count`: 4978
- `sha256`: a0087779d1699f5d3b981e987bf8314382f3316a7559f83172e5c6b73045a362
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=218534 bytes; lines=4978; FAIL=5; PASS=1; tail=4 %concat/vec4; draw_string_vec4 %pushi/vec4 824206949, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1952671776, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1717663084, 0, 32; draw_string_vec4 %concat/vec4; draw_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pending_drain_resolve_gate.vvp

- `kind`: vvp
- `size_bytes`: 96464
- `line_count`: 2319
- `sha256`: 53f4bd84d4621cf6c782da434066a614aec2d4788143335e36aeab69a1c7ac81
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=96464 bytes; lines=2319; FAIL=3; PASS=1; tail=hi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pending_lane1_capture_gate.vvp

- `kind`: vvp
- `size_bytes`: 108020
- `line_count`: 2656
- `sha256`: c659bfef1f81001922d1db6a5754706f12735650323da2c2c6254bbf190d6747
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 1}
- `summary`: vvp evidence; size=108020 bytes; lines=2656; FAIL=5; PASS=1; tail=_capture_gate.clear_inputs, S_0x64030efb43a0; %join; %free S_0x64030efb43a0; %pushi/vec4 1, 0, 1; %store/vec4 v0x64030efb4790_0, 0, 1; %pushi/vec4 1, 0, 1; %ix/load 4, 38, 0; %flag_set/imm 4, 0; %store/vec4 v0x64030efb8280_0, 4, 1; %delay 1000, 0; %alloc S_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pending_system_admission_cancel_gate.vvp

- `kind`: vvp
- `size_bytes`: 14437
- `line_count`: 323
- `sha256`: d56f0d7957bd0b8bfb31bed1f4d31e43c888cb57f141bc49b33e6da783d4af0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=14437 bytes; lines=323; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision - 12; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pending_system_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 135644
- `line_count`: 3392
- `sha256`: 7a0fb86396c0019aa81c0bc8d7db8489178565d76f5856a35602f0e1066740f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 5, "PASS": 2}
- `summary`: vvp evidence; size=135644 bytes; lines=3392; FAIL=5; PASS=2; tail=%load/vec4 v0x5cb69ec86930_0; %assign/vec4 v0x5cb69ec88050_0, 0; %pushi/vec4 0, 0, 5; %assign/vec4 v0x5cb69ec89620_0, 0; %pushi/vec4 0, 0, 8; %assign/vec4 v0x5cb69ec8a2a0_0, 0; %jmp T_9.12; T_9.11 ; %load/vec4 v0x5cb69ec88de0_0; %flag_set/vec4 9; %flag_get/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pending_trap_exit_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 28463
- `line_count`: 854
- `sha256`: 660a1d29802501c8a7063da876e98fb27496c7cf0d379f3614eebfac906738c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 6}
- `summary`: vvp evidence; size=28463 bytes; lines=854; FAIL=2; PASS=6; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_phys_reg_file.vvp

- `kind`: vvp
- `size_bytes`: 192896
- `line_count`: 4897
- `sha256`: e310ec7916456bba359bfddf9ac152820c53d8e82bb078424ac92f335ae714ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=192896 bytes; lines=4897; FAIL=3; PASS=1; tail=w_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_pma_checker.vvp

- `kind`: vvp
- `size_bytes`: 118579
- `line_count`: 2750
- `sha256`: 22bef2ebf18e6196c1390521304bbcb1a0ba31bc54c3b91f5d5bf2fed888acea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 2}
- `summary`: vvp evidence; size=118579 bytes; lines=2750; FAIL=4; PASS=2; tail=768843040, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1347637825, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1293968485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1668244581, 0, 32; dr...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_priv_system.vvp

- `kind`: vvp
- `size_bytes`: 6411606
- `line_count`: 146786
- `sha256`: fcee0d5bef18913d24bb244f266da384eac7a3524c00fa647dda460c68b314cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 2}
- `summary`: vvp evidence; size=6411606 bytes; lines=146786; FAIL=3; PASS=2; tail=oncat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_ras_update_gate.vvp

- `kind`: vvp
- `size_bytes`: 63728
- `line_count`: 1586
- `sha256`: 9dbb8829770b2e544d7b90b2fb3275e1762488716a0e8de494769493da203df3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8, "PASS": 2}
- `summary`: vvp evidence; size=63728 bytes; lines=1586; FAIL=8; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_redirect_arbiter.vvp

- `kind`: vvp
- `size_bytes`: 34854
- `line_count`: 876
- `sha256`: 88569c0488e23f1f4c417761395115d406d863ed5cf6d22601a9712059afc1d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 22, "PASS": 2}
- `summary`: vvp evidence; size=34854 bytes; lines=876; FAIL=22; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_rename_map.vvp

- `kind`: vvp
- `size_bytes`: 99472
- `line_count`: 2436
- `sha256`: 213b2a976fe29d5b4fb37ca1d9006fb450ba9a8d6be803351d83cfdc3aa1cfde
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=99472 bytes; lines=2436; FAIL=3; PASS=1; tail=; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_ve...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_rob.vvp

- `kind`: vvp
- `size_bytes`: 1076006
- `line_count`: 26450
- `sha256`: 44033a8a5b947ce3dae35ece68cb7dd4f40ffeffc6ae3cc9140f3aea756098c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: vvp evidence; size=1076006 bytes; lines=26450; markers=<none>; tail=ec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %con...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_stop_pending_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 66064
- `line_count`: 1798
- `sha256`: d66642372c9b1dd1c9a4a4c36cc106fb25183f6461aa3258220f8ae5dc99d471
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 3}
- `summary`: vvp evidence; size=66064 bytes; lines=1798; FAIL=3; PASS=3; tail=787b437ac0 .scope module, "tb_ooo_stop_pending_sequencer" "tb_ooo_stop_pending_sequencer" 3 4; .timescale -9 -12; v0x56787b458ec0_0 .var "branch_resolve_untracked", 0 0; v0x56787b458f80_0 .var "branch_spec_checkpoint_capture", 0 0; v0x56787b459020_0 .var "b...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_store_queue.vvp

- `kind`: vvp
- `size_bytes`: 584857
- `line_count`: 14289
- `sha256`: 34c111e4f1d08cd1e187dc9282d835dc81ed34d8e25e7c3684db28d83298d96e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 1, "PASS": 4}
- `summary`: vvp evidence; size=584857 bytes; lines=14289; FAIL=1; PASS=4; tail=030; %alloc S_0x5c1ddded17f0; %pushi/vec4 12, 0, 4; %store/vec4 v0x5c1dddeef4f0_0, 0, 4; %fork TD_tb_ooo_store_queue.alloc_one, S_0x5c1ddded17f0; %join; %free S_0x5c1ddded17f0; %alloc S_0x5c1dddfc8570; %pushi/vec4 12, 0, 4; %store/vec4 v0x5c1dddfc8750_0, 0,...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_sv39_boot.vvp

- `kind`: vvp
- `size_bytes`: 8338029
- `line_count`: 192746
- `sha256`: 981c980aa46b22c1fc27a025b6f6522068d8dd6438276cf11c70bb53bcdb10de
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 14, "PASS": 2}
- `summary`: vvp evidence; size=8338029 bytes; lines=192746; FAIL=14; PASS=2; tail=at/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 29485, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1836016741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/v...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_trap_exit_event_mux.vvp

- `kind`: vvp
- `size_bytes`: 36101
- `line_count`: 734
- `sha256`: 2b7a96f9f36fa6bf1b09b036db131f3ad9a9358ee2b5122b6556855880885808
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=36101 bytes; lines=734; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_trap_exit_output_sequencer.vvp

- `kind`: vvp
- `size_bytes`: 16989
- `line_count`: 476
- `sha256`: d8675ba5b849a8b4df9b8074d652a24e17e5f091d89814ff9f28277d13dd2226
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 2}
- `summary`: vvp evidence; size=16989 bytes; lines=476; FAIL=2; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_ooo_typed_memory_classifier.vvp

- `kind`: vvp
- `size_bytes`: 52197
- `line_count`: 1446
- `sha256`: a954e3578be706577b4d178376ef7cce08e7f7e2fe6d34ea1f93ec29d62d6910
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 10, "PASS": 4}
- `summary`: vvp evidence; size=52197 bytes; lines=1446; FAIL=10; PASS=4; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_pipe_stage_reg.vvp

- `kind`: vvp
- `size_bytes`: 65157
- `line_count`: 1744
- `sha256`: a3c00f276ba53f119ddb21af3856ad1a2dc5bca1a9ea92e7868b8428de155d27
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=65157 bytes; lines=1744; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_pmp_checker.vvp

- `kind`: vvp
- `size_bytes`: 180661
- `line_count`: 4649
- `sha256`: d5bd93bfaf7950288ec2958d4fcb6d137f883c87513ebb62ff342a847b43fd50
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 3, "PASS": 1}
- `summary`: vvp evidence; size=180661 bytes; lines=4649; FAIL=3; PASS=1; tail=bda0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5eab7e74c070_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5eab7e7054a0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5eab7e74bc20_0, 0, 1; %fork TD_tb_pmp_checker.check_access, S_0x5eab7e72f140; %join; %free...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_uart.vvp

- `kind`: vvp
- `size_bytes`: 300070
- `line_count`: 8070
- `sha256`: 63f264e2be4beba7b848db6641688e6babaf622b709292f740a21c0d1ed8dae1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4, "PASS": 1}
- `summary`: vvp evidence; size=300070 bytes; lines=8070; FAIL=4; PASS=1; tail=1; %store/vec4 v0x5b41613066f0_0, 0, 1; %delay 1, 0; %pushi/vec4 0, 0, 1; %store/vec4 v0x5b41613066f0_0, 0, 1; %pushi/vec4 0, 0, 1; %store/vec4 v0x5b4161306e20_0, 0, 1; %delay 1, 0; %alloc S_0x5b4161305290; %pushi/vec4 0, 0, 32; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3-build/tb_wbu.vvp

- `kind`: vvp
- `size_bytes`: 25241
- `line_count`: 678
- `sha256`: 9933818504187bd02773c5813321524d88df475a5ed300275c5b421299dfc5be
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=25241 bytes; lines=678; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: 1b24588509dcd850ddd0ff5e554baeba43f2242cd6222b3e7ce3f94e81a2dbf9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 503
- `line_count`: 5
- `sha256`: 9e3c492cf354f38760dc03527a5e138828db20e938f4a87ae9883c1c8d2ef6a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=503 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-se...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3713
- `line_count`: 29
- `sha256`: ba0f7632f47f4e176672a7dc0a5993efbe86662c7521cb1806ff048b363d4232
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3713 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 611
- `line_count`: 6
- `sha256`: 21cbdd1943aa30c83221a22c1185f3907ac127c4c18cb28aa6321cbd3bfe57c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=611 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-seri...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 700
- `line_count`: 6
- `sha256`: 1346bbb7833810a91780915a9b29204ee371b8ffa876d5a3e4dddbc724c59053
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=700 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 567
- `line_count`: 5
- `sha256`: 4afb57344b81c74a30ef14b4c1536524b1afedfc70fc3485d6fb93ece5404fb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=567 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3497
- `line_count`: 29
- `sha256`: 98f7245691848467a21398b75f36c2fc346fbbe3bd4af29581884b4e85154e88
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3497 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-seri...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 3105c8fdee8f4159a34681abdce1b84a0bb6a91c5254de184294ae0567e00519
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serial...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 3bb04d81bd2558ece6e3f4f6970ea628548455df4f9f84cfb305bc1b7d3c32ad
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-seri...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_csr_file_vectored_trap.log

- `kind`: log
- `size_bytes`: 683
- `line_count`: 6
- `sha256`: ad6e224765019b0759923e918976eb003dc036be4d28a054b201b0e9de222b2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=683 bytes; lines=6; PASS=6; tail=[TEST] tb_csr_file_vectored_trap [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file_vectored_trap -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 5
- `sha256`: da9d2720c37cf13bf553066c77aa6ffcdb768d86ff1ce5ba4fa382d264cfa737
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=642 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 517
- `line_count`: 5
- `sha256`: 3c099452960a0e26ea1cd2cae70b67f1f18f905458311c041d54de3dcde6ce1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=517 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 487
- `line_count`: 5
- `sha256`: 7a35f62e9668af2a9556dc1d43ee50f9cb40b0bb9f2a462d0fc71920be5e809a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=487 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serializ...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: ea0d5cc77550b9a1bbe38b0fa3058feeb4b64693676d543cfa6443b83e6c1c9a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: 6e2b3da1210e7c1a740303152e5862f3535804617c17b568ceedce4f726d054a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 522
- `line_count`: 5
- `sha256`: 819c7773a74a86bf4605f76b7c3345d114a1694aaa6bca8fda42e8d836ee4ac7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=522 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31496
- `line_count`: 208
- `sha256`: a1ddca5d5fb2b34b4d1aa20c01675f24bbf7674e815da7ab203ddf2d3344cf39
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31496 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31676
- `line_count`: 206
- `sha256`: 6be2fe5b53abf82ba1d1b67ad5b0e6cfc43552134b8a079364061a718108de04
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31676 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 522
- `line_count`: 5
- `sha256`: 2dc723b93385135139fac47a38c47ffb42260613491ca1eee69b14d269d8fbf5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=522 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 5
- `sha256`: fc8b7b6be7d0447935890cca561ebffe9456d9a81a519afad55f94731a573512
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=601 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 554
- `line_count`: 5
- `sha256`: fc2476182c737d5c9326d763cbc82047f0c127fd5c97751dea1111bee0337c86
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=554 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 979
- `line_count`: 9
- `sha256`: 3d4ad0c48661d97a8afbfa4c002c74496dee2b5cf697de2211a0267af3b3d4af
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=979 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 934
- `line_count`: 9
- `sha256`: 41e2c574ef260fda57c8513cd901000f7d97ef1395670a46633567b8c92c1225
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=934 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 717
- `line_count`: 5
- `sha256`: e2b4c8da74ac68089a626dc01f578ad00763c9dee05414c2bf590b6bb5cae2de
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=717 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 989
- `line_count`: 9
- `sha256`: cf69b406a7252a1145d290af01594b51d950bbe83692f16f4ebcda47f1489c80
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=989 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 589
- `line_count`: 5
- `sha256`: 448992b9cf4976ea206ebc005a8021550d526a5778b251bf81373d94b3cdbb7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=589 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 674
- `line_count`: 6
- `sha256`: ae8f901b0d36bc5ff0be09a011fd52d4312e7ffd5727b9b649f7098a1708093c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=674 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: e8bc1d18607c67f91d1f93734b28dc7fe778b8a36e247f21053a84fcab537e97
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 892
- `line_count`: 9
- `sha256`: c02edc78b810650edd6fb673eef869b56ef244d694122b2b4b8eaa39ba809acc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=892 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 957
- `line_count`: 9
- `sha256`: 528ae4a0522be2a9331c1c63956484da55da7c06687b7b043d5408efd0996cb2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=957 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_control_event_apply_sequencer.log

- `kind`: log
- `size_bytes`: 970
- `line_count`: 9
- `sha256`: 4f16e59d1e500a8aef23746a41ba32c4896fab35ea4f34b53937124c2b0dbc83
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=970 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_event_apply_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_event_apply_sequencer -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 944
- `line_count`: 9
- `sha256`: fcaad0d33137da60260aa8dbaeec4c022d17af2143086384337321802730545b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=944 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25485
- `line_count`: 140
- `sha256`: 7326aa03c844fece3a463360d5441d0e239c61a6c541d5f1785710e18f41d7e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25485 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 5
- `sha256`: 275e50611d579f621893c172232b06e43710ab4a9467f8848fdab3b51ca58b3b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=622 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 685
- `line_count`: 6
- `sha256`: 871af1f949547cd3ee65b9920fd3d0af8ed5983f751946ecdbe0bd06cde48a5c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=685 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 700
- `line_count`: 5
- `sha256`: 2eb53797874071330a9d21afba6f978dbda374985debde65452b37cd391c8ec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=700 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 5
- `sha256`: 08fcff54906e9a0318c24f8dff384c79f476d3a14bb8bc0ab0e9c1ce6eb126d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=630 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 624
- `line_count`: 5
- `sha256`: 44c855d62afba3a345f5f1ae6b2b17d7bc8eb0736e9f35f52118bb1669f4f89c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=624 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 624
- `line_count`: 5
- `sha256`: 856244309391ada29001f76e52651c44345179f243b08d7e27512de01ea7eb38
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=624 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5826
- `line_count`: 40
- `sha256`: 8cfcd35aa2963617f8ff1291050be57a9350b8550a9bc0c6f38b9e6fc407e928
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5826 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 306443
- `line_count`: 2296
- `sha256`: b46b0b0eef2840d55d80c5e6d9add5c6848ed4efe5236c663f6d0635559dfb6c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=306443 bytes; lines=2296; PASS=2; tail=orkbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 114301
- `line_count`: 944
- `sha256`: 6dd2a52b08cea81c0ef76f5c9ccf78c1ceb565e24418687a0b7f91362922e515
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 159}
- `summary`: log evidence; size=114301 bytes; lines=944; PASS=159; tail=yx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103849
- `line_count`: 780
- `sha256`: f386346f436e8153c1405b6b87015c2e688fd747fbd5da036cde26b046bfa1f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=103849 bytes; lines=780; PASS=3; tail=ing: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:1...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105364
- `line_count`: 794
- `sha256`: b93544f79ed31d31db80171e25fc9dfd9b5576749a41295ffd4d16c4fb36566a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=105364 bytes; lines=794; PASS=3; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106780
- `line_count`: 803
- `sha256`: a17dafcf199e1fb625eb1d2d00563a3e9c97838f4a2789f167d7d373ca9cfcbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=106780 bytes; lines=803; PASS=3; tail=/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: e8e05205260f48345f2c2f95aabddc1a4e77fa1754f5f3e22fd5b6a43f2f59b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 583
- `line_count`: 5
- `sha256`: b794bcea07be86d928e1ab6955ad39e9fc55df8c4841dcfaef92d18a8fe3d93f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=583 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 859
- `line_count`: 6
- `sha256`: d17eea1b521fcf973e5a22a9d69bbe15ca005f9def5bc87b24e07ad06f4db0b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=859 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 811
- `line_count`: 5
- `sha256`: b055c5bff585878582b8ed160d0391fd658fc4866f91e8a5c80379d46a8c270e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=811 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 720
- `line_count`: 5
- `sha256`: f330a065e1271b5a4b31236d41b19ef52fab36e40cbd5b50cc60a788e0d21986
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=720 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 850
- `line_count`: 8
- `sha256`: adc96eeea75ef4dc2b5af67d573f64ceabeca2e5b0ed4f3be7011768935deba6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=850 bytes; lines=8; PASS=8; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1257
- `line_count`: 14
- `sha256`: 4fb4b5ecaa6c6a26187593a85c16e015b6ac8e1067ca714097de1df149fa5dbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1257 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 599
- `line_count`: 5
- `sha256`: 2b57100d32ee5a2661e6540a6c6ec5d33242e26fce4d7a214f2945e05c07f6ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=599 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 600
- `line_count`: 5
- `sha256`: c897b83051a6bda0015917627aa4f4b52072541acd936c14e391e5835eaa820b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=600 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 108199
- `line_count`: 818
- `sha256`: 6545c36c69c59c604ad94f068670821578f627d1f7ee09dd9d490e1ab1f74ada
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=108199 bytes; lines=818; PASS=16; tail=v64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 5
- `sha256`: 6a706ccc630de86b8bf1108c3c8083b508e3bb03ca9d8158585057100f6f9aa6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=654 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 577
- `line_count`: 5
- `sha256`: 636a9be402a878f24a00c07ba45683f2b7e498b6f060840232082fc2975e6296
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=577 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 1089
- `line_count`: 10
- `sha256`: 327303074177478d8138811de6bc9fab010d55f9f2302ef00ac3d0e881a23824
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1089 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34503
- `line_count`: 198
- `sha256`: 4fd4ec1c683935a8b317bddbe7a2b4cc26fe548c3577519e484d61eda192eed5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34503 bytes; lines=198; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 553
- `line_count`: 5
- `sha256`: 7a31c1ae9433fe2aeafd2db892c182a0ce197129f6925e75e606db5ebd158606
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=553 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 570
- `line_count`: 5
- `sha256`: eb135abd1a4d8546b614efd0d7c1b56069713f94e27183ddebf887d23fbbf033
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=570 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 564
- `line_count`: 5
- `sha256`: 06165165a12091c84f2aa829819dc85f97224e3705d5f85528c9cae05879ae00
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=564 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 563
- `line_count`: 5
- `sha256`: 244e3a8bc68f44d402acdf6551aae355c14b91b8993c8f9ec70b4efb4ef697c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=563 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 4059
- `line_count`: 38
- `sha256`: a2fa0525cce88f952abe748f4770d3f3197fbd2c7d5b54510b50cd350f87da17
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=4059 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 588
- `line_count`: 5
- `sha256`: c178c4913aee6a132f0820b3cc4fd5186e22685a5846162088c6cf33eda029e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=588 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1892
- `line_count`: 15
- `sha256`: baa111d8c5e75a7afbcd21a9a2118912eaf7dd9de293a5e78b98606d9b66c7f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1892 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 695
- `line_count`: 5
- `sha256`: 9b9ce21f90ef6dd16e701f276dc7a48aeca611615da8d12b5486f54f11a57be6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=695 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1102
- `line_count`: 12
- `sha256`: ed38f875949d71095e2efca93ce345d43116050dac0785d99f867da27030b25c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1102 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 849
- `line_count`: 9
- `sha256`: 09df68685bc57049f580e561646a419678de0236bad3fb9ba34d71188d498760
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=849 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 94e538481a1624356da542851f2e6c88c388f285f59c54a52999ef715d1b4df8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 537
- `line_count`: 5
- `sha256`: ec8d53f14e6123840629c7f70f72e490734e0d2bcc7748460ee7aa58a039e13b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=537 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 595
- `line_count`: 5
- `sha256`: 1eabede0808d6a5ef18497eb495bae6565d089ffd3e1ca83fd62ff34793218f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=595 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 1003
- `line_count`: 10
- `sha256`: 3c1306c8921c5318609f8964102f67278baaafddf11f06edf2437c1866d6850b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1003 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 915
- `line_count`: 7
- `sha256`: 589003d1e893a2ec41a521d62c95abed2e50012450d528465abfc9847aa7f973
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=915 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 577
- `line_count`: 5
- `sha256`: 29e3943e9f434814275885bb009b21fded07b1fa82214194a9007a09dc352b25
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=577 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 589
- `line_count`: 5
- `sha256`: 7335a0d52c773a447380941c13503f992300065f9e43d66218a6dfab34d61b5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=589 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8913
- `line_count`: 83
- `sha256`: a1710726912f6b35dd646412f74b8080393e0d2fca04b68bb70c6794ad84700b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8913 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26925
- `line_count`: 228
- `sha256`: 307a3ddaa3a7a63d70a47abfa7fc960f04e83dc2bcafb140d6b3a890015066eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"ERROR": 2, "PASS": 102}
- `summary`: log evidence; size=26925 bytes; lines=228; ERROR=2; PASS=102; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11583
- `line_count`: 96
- `sha256`: ec9674dd675129f614eff0fb0bb57a16473f942559ba8653baa41b23d4a5b768
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11583 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 4279
- `line_count`: 35
- `sha256`: adc5ad3f387af19e101e445d7335bf1f002e19f0faf9c14ee8f777fbaef922a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4279 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 947
- `line_count`: 10
- `sha256`: 76b51b86d32603746adc23ee76d71e1601d9876dd2cf8f47f0f5485e92240c26
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=947 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74702
- `line_count`: 572
- `sha256`: b25668d269de2af0f382188f1c82938eaa6f632d91ed444af6336e69e36779cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74702 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1450
- `line_count`: 12
- `sha256`: d0abca339135e749d82dcb03c5388d3fe8f85f9c1c2fb8dc9f1ea64e5624a4fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1450 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1200
- `line_count`: 13
- `sha256`: 55115eedc0643675eaf4817e7f357dec2323899489e153557e61832270c466ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1200 bytes; lines=13; PASS=12; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1415
- `line_count`: 14
- `sha256`: 94092d89ac2e6498c70caa3928aa9094ff6e708b2aa9c3d44a642cd4acbe7985
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1415 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1047
- `line_count`: 8
- `sha256`: 9da471e1927c6c7be9041179b45a0755dfb183259a150094e14325b5d466fc33
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1047 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 802
- `line_count`: 8
- `sha256`: 3e8f149bd6c5fe704b867b24fcdf6d7a25f67a5e5a2877c241e88d04c301ae40
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=802 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 545
- `line_count`: 5
- `sha256`: 18f3967a563b493c1971e076820c621e85c201ada5a61fbdf9016663f07ec53f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=545 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1271
- `line_count`: 12
- `sha256`: 6697868b90f965744854fba748d68e7392dd9a0ecc495fd8d6df125f018e37b2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1271 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 629
- `line_count`: 5
- `sha256`: f4833a18f3c1475b29f2d8f2ce597af3d96dbc4b37aa31224931c7e50a8c11df
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=629 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 1059
- `line_count`: 11
- `sha256`: 5b6a167f62ae2f1a0bb2e48a34b3ca67e3c51c586ac647712b82e5820ede2c37
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1059 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 1086
- `line_count`: 10
- `sha256`: e4c2fbc2b925516687bf7053160c5e657c158d73afa62af675be395099ddd3b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1086 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o /home/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 1050
- `line_count`: 10
- `sha256`: d1f89c7c0fb7d2045fa900ead1bb92d3d74b396c0e6fc6116a0991b653c5334c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1050 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 816
- `line_count`: 7
- `sha256`: e4837e3c814713929b5dae3cc943f7d3236cf0984230d7dfd74263ba22a2f4ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=816 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 559
- `line_count`: 5
- `sha256`: 8eb0cfde9d9149948acc25d8df8e98b25c5a0c3617827ee0a2581e52e690e87d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=559 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 681
- `line_count`: 6
- `sha256`: 0a76598b89cf598e342c4f237e779e485c50927f3a722c4b49f943d7e80dbf79
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=681 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27068
- `line_count`: 143
- `sha256`: e152ac9be20912a8cf196836bde09d15f93d31b345470f94843151ebaf03d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27068 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 565
- `line_count`: 5
- `sha256`: 251d07eb45e12e48d608c8a087bb4ec5ddee8051ee17dc4dbe68ec4cc8d1937a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=565 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 571
- `line_count`: 5
- `sha256`: f3d53c2303f5d626f941f9f0992aac55be622d071eabb5d74b60218a616d588b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=571 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 543
- `line_count`: 5
- `sha256`: 4c3bd6b4f78ba0cc1f7f954424af68a077de76be868ca97d1d695a1a5134e473
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=543 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1426
- `line_count`: 14
- `sha256`: 7780e3d19213bbdec60a935621963e5d9b56b0e54b70624d008afaade4b60cb5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=1426 bytes; lines=14; PASS=18; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serial...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 1003
- `line_count`: 10
- `sha256`: 2abe0344ccb16fd8d74de2336d6da09f0f8fcccc8dcacbe10aff6951a9410de1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1003 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6939
- `line_count`: 58
- `sha256`: 8219133de38d08c33409ee92544893a06ebdfb35a45b4f11f6bcc1d0fb52dbef
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=6939 bytes; lines=58; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287173
- `line_count`: 2103
- `sha256`: 751301fc41cebd7b656efde146b34df89ae689471778f40715c852a2a6e04817
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287173 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 601
- `line_count`: 5
- `sha256`: 952d5363b09c40ecb1d26ad70d1792ec90c03cb0bc1425bc82f1e984ff819dd1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=601 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 650
- `line_count`: 5
- `sha256`: eb66b374be1c4780748b393d3bef217222c5fe3cfcec8f8bf7e5c37ecb579931
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=650 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 701
- `line_count`: 6
- `sha256`: 591d5d999faf10272c3d74831877fca667b376d42c5d6c68094779bf58dcbe38
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=701 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 536
- `line_count`: 5
- `sha256`: 04acfb81467616d94398c896732d0ad5aa7787b492721fe434ac4a2e4a931a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=536 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17663
- `line_count`: 134
- `sha256`: 90fba3ecbacef06b4d1666b53d90f58d8459ea0b986976f61573d36e44c57c30
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17663 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 474
- `line_count`: 5
- `sha256`: 6106af12a1845e359f505870cb9ba9b5c1a5f5c4ab5c08b72da18cfa2ce09693
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=474 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-me...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 472
- `line_count`: 5
- `sha256`: 4e73275e9b704f5e5267c55f040e52828022704652877f71de095572622c3fc9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=472 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3/summary.txt

- `kind`: txt
- `size_bytes`: 3733
- `line_count`: 120
- `sha256`: 55dc3d8f464047e435d27d010435f4c5623b4e1fb09d771172a7a65c5dc0fbea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 222}
- `summary`: txt evidence; size=3733 bytes; lines=120; PASS=222; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current-v3 - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 8318632628160f87443adf727225fc1f117a535681eb324290739200b36d45c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 500
- `line_count`: 5
- `sha256`: f017da55f2ed7968c16783cfca562092924bf86b07a062329824dcc46a3a2b1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=500 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-se...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3710
- `line_count`: 29
- `sha256`: 42c1546db475017460b034b7c8387c07f1a19f680394a5e57e790a503b3dbf1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3710 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 608
- `line_count`: 6
- `sha256`: 9e98a5b08f573030738ce78b63358f1c1ff9311705afd773dfbbd44021dcb2f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=608 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-seri...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_axi_reset_syscon.log

- `kind`: log
- `size_bytes`: 697
- `line_count`: 6
- `sha256`: e453c8bbb1920cae01409604487aa2202204d44e5342f91480de02cfcc39ecfe
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=697 bytes; lines=6; PASS=4; tail=[TEST] tb_axi_reset_syscon [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_reset_syscon -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 564
- `line_count`: 5
- `sha256`: da847ace56593ad70adee5fe79f789b1f5a414624a8c56614bcd96a27e9fa070
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=564 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3494
- `line_count`: 29
- `sha256`: 4398c464ab2b3c06f6d6fcbdab1e8bcd2e43229ed7cc7820cf955a1a2642c427
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=3494 bytes; lines=29; PASS=6; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-seri...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: 665cf925eec0fcbe55593c47f0030a16c5c39b93c28c67aa4bd829ceefc32008
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serial...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 495
- `line_count`: 5
- `sha256`: a80a8fd1ad5fc9f485a1498589c3ef30db1df8884b1eed992ff0317a721ca1ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=495 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-seri...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_csr_file_vectored_trap.log

- `kind`: log
- `size_bytes`: 680
- `line_count`: 6
- `sha256`: 830886c6b733781c31a944f2735c37881e9d1b4720df5dc904f378286d36d9ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=680 bytes; lines=6; PASS=6; tail=[TEST] tb_csr_file_vectored_trap [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file_vectored_trap -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 639
- `line_count`: 5
- `sha256`: 68a6784c0952a84f727a482e908071b9f504ca3e33bdc4f74f2798775d68d0d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=639 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 514
- `line_count`: 5
- `sha256`: 7696bd615d580cd0bc1a49df64c0224972aef19ed9d48b068972fb70406df2e9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=514 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 484
- `line_count`: 5
- `sha256`: 2175823f7aaae79de95f33c40d0d9548a489195e8cf09327a6a1ac880463554d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=484 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serializ...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: 878f9b44db9addd78a480d7031ac3ce10ffb2026aa7bd8806e1bb12142c29390
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 513
- `line_count`: 5
- `sha256`: 9a083aae63d18753285b32ca258196b679ddfba85ce022fc9c84d7ceb02c8c23
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=513 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: 430995ce8d947004b29c2bd5423ae38c5c7d7392a796431cc9654e11f9fcff1e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 31493
- `line_count`: 208
- `sha256`: ed2d46f0e20fd2d17b686885e78179fb47d85155563ba6e2523efa98a4a847ff
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31493 bytes; lines=208; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 31673
- `line_count`: 206
- `sha256`: ee109a9e8629af6451093cd94761abd42f565a251f3551f841582f78bc913ebd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=31673 bytes; lines=206; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 519
- `line_count`: 5
- `sha256`: 9a91031508b44e348e0d125728d22b6152f4d121460b80f55477aebb4db2f065
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=519 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 5
- `sha256`: fd84777137de0d068d316d97031fcfa582725ba32da27ad79a0a3593925c968a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=598 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 551
- `line_count`: 5
- `sha256`: d93c4e729c1e620b39e2fe185a1f5a96b8a71e28cbebdbb5677c47bebd8d241a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=551 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 976
- `line_count`: 9
- `sha256`: b9620336f434cf7b00998238695e332c7b61cb20e6d04001539426ce3d0fe5fd
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=976 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 931
- `line_count`: 9
- `sha256`: eed09f5d31f076162fc372bfb65ac5454b1f879ae881d98960644e80cac57e2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=931 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 714
- `line_count`: 5
- `sha256`: a0d8397cf5428bf4716c8941d26714a61e05a5fda4a3014528c57ae03270a484
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=714 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 986
- `line_count`: 9
- `sha256`: 15794d3d9504618599f99e2a7f8cbc3e8663a2b50c4d83c7f9ea83ff75d7ff5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=986 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 586
- `line_count`: 5
- `sha256`: 843f89809662ac4fe0a4e0efce0f1e55e336dbd4b9e4ca1b48364c778a67c598
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=586 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 671
- `line_count`: 6
- `sha256`: 26c328388e5a2356ba85cc9e128ff89e0761167fcdbd78ec923fc233e02443f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=671 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 534
- `line_count`: 5
- `sha256`: 147007531b870d7dc657d304df91a1324451e5da4d9cdb286716761a170cc974
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=534 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 889
- `line_count`: 9
- `sha256`: b8666ff16f1ae52e2a912d52f25bb8c7a48fe685db9b8d0d840c7eb8801e7f2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=889 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 954
- `line_count`: 9
- `sha256`: df6e5cad49867f423b6a89737cf0b92decf678d179eea827b6d5d86beaeff98d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=954 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_control_event_apply_sequencer.log

- `kind`: log
- `size_bytes`: 967
- `line_count`: 9
- `sha256`: 30099ebf266d85565f9342c991a497ee3929a3043727f034b68fb43a4d11b9e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=967 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_event_apply_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_event_apply_sequencer -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 941
- `line_count`: 9
- `sha256`: 4994a006f6a17cefe889e53750ddec9dae5b1ceffc0ae57a5c7612838eedc61b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=941 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 25482
- `line_count`: 140
- `sha256`: d2d77cc9757c18af8aef00c2298c81274e17445637db8439448e80c3a0f6de17
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=25482 bytes; lines=140; PASS=12; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 619
- `line_count`: 5
- `sha256`: f8da8689cb997cefb76bdd3e290bdfb0a4c20f41282fb974609fe85f45cba0ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=619 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 682
- `line_count`: 6
- `sha256`: cc16367b5a13a15336f62a47e1925f5a36650e225d5f14fd976765773c2e15c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=682 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 697
- `line_count`: 5
- `sha256`: f7d686e14fa156f27627e981a262ec6d6b36669912e97d03e05e96b7fd041eab
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=697 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 5
- `sha256`: 5eaf447c9f5d05bbd75d17ea4469e8245fbc4e90f64d364b82a4503b8f199bb7
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 621
- `line_count`: 5
- `sha256`: eeb16d0f07d1127c3ecd31b38d16b0cc6ec127329db6a39c6621842265217319
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=621 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 621
- `line_count`: 5
- `sha256`: bfc79a4838cff00d82b042c88ab44064c363c99e5cf6c65a6292970418a72321
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=621 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 5823
- `line_count`: 40
- `sha256`: a7aea2c969d2e314cdf32d02d0639cb6497ea27ed4ce57680abb984d1f7b51e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=5823 bytes; lines=40; PASS=10; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_dual_memory_sustained_issue.log

- `kind`: log
- `size_bytes`: 306440
- `line_count`: 2296
- `sha256`: 41bb684575a1154548a49987739b219257792af765285471e65b85cb663c7ce9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=306440 bytes; lines=2296; PASS=2; tail=orkbench/npc/rv64/vsrc/memory/PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 114298
- `line_count`: 944
- `sha256`: ba147c72078524c06eb87a07af5f5b3128f0916b6dc20a55849bca0e33e6e7ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 159}
- `summary`: log evidence; size=114298 bytes; lines=944; PASS=159; tail=yx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 103846
- `line_count`: 780
- `sha256`: 519abddacb70567953faceac88af928363ae82f63a382711a1eb8f6f5f2bf525
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=103846 bytes; lines=780; PASS=3; tail=ing: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:1...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 105361
- `line_count`: 794
- `sha256`: b737f227994a83ac6fa4a0f6509447c4982d21ba41e85e2470fa98465b041d74
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=105361 bytes; lines=794; PASS=3; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:116: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:125: warning: @* is sensitive to all 16 words in array 'entry_addr_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 106777
- `line_count`: 803
- `sha256`: 4f02dffb7eb4a50c575876173abfb8b2aec2b96c526b3a8925b8bd1595b6b2ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=106777 bytes; lines=803; PASS=3; tail=/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_branch_target.log

- `kind`: log
- `size_bytes`: 588
- `line_count`: 5
- `sha256`: ccf71dbb46db4eed0938d131c6dcbf84418753a2ff69e97fba282d1ecd3e54d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=588 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_branch_target [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_branch_target -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 580
- `line_count`: 5
- `sha256`: c0331fce874e0b583f9906f9ce630e261ba20cd3d5aa301bfef1e662aad89627
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=580 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 856
- `line_count`: 6
- `sha256`: 96156b5083e2a72d4315a10deb07d515f6150cd51e462c632948b87c95246b1c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=856 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 5
- `sha256`: 52080af04fe2b474468dc3cb198f716535e12ded5c9c12df2f29a2c3122ec4e6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 717
- `line_count`: 5
- `sha256`: 97e1de9f047ec0d0ba35c6454b5ab0b543bd7c689de19c27b1a4a6c42c01cf70
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=717 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 847
- `line_count`: 8
- `sha256`: cd31f9ff422c8f6c1ddfe5c48c4408ec4f43f1d0be8177a1659d1fc55c3278d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=847 bytes; lines=8; PASS=8; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 1254
- `line_count`: 14
- `sha256`: 7da40643ab92ff399f095ea3fd2a56ab7a71798f7e583898e1e77f3044ecbd9e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 12}
- `summary`: log evidence; size=1254 bytes; lines=14; PASS=12; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 596
- `line_count`: 5
- `sha256`: 7c52c2030f6db0de776d242cf9a236268e42a1274d9003d1c27ffef1bfb292cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=596 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 597
- `line_count`: 5
- `sha256`: 9f75fe9691535d5a5df60a401c2172d501a0ed51b15cc90e3151a5fb20c82422
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=597 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 108196
- `line_count`: 818
- `sha256`: f919d7303646bce65a323459e59c35f56dfed75ce5aeaa32d444063b247198d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=108196 bytes; lines=818; PASS=16; tail=v64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workben...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 651
- `line_count`: 5
- `sha256`: c88d8cb8e19a10a14d8ad09795bf65dabc51981f1a3070bb9e8728c176021c28
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=651 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 0e679a3f8cc58e8d9dcba555ab92f65a48ad245dd231393c8e60799a19d74923
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_static_classify.log

- `kind`: log
- `size_bytes`: 1086
- `line_count`: 10
- `sha256`: b4e3487c96f274f38c47adf6acb1c0b18ec458a601314967f2348f56be644ceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1086 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_fetch_static_classify [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_static_classify -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 34500
- `line_count`: 198
- `sha256`: a9250d4c7b6034459dcde83b5301777df27030a0a2025097af657ec03867c56a
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=34500 bytes; lines=198; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 550
- `line_count`: 5
- `sha256`: 4f9cfb590c977fa70437ce5eaec611e0f334f8c315841fe68a5391265ac34dd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=550 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 567
- `line_count`: 5
- `sha256`: b2748d3fd123920b08a9d72951023380a501c1e985f41d21bfe3dad602c1ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=567 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 561
- `line_count`: 5
- `sha256`: ade071a33b0bf4a4e72c4ebe3ce750def6ba806724572fd8a34d078a5d7ead3e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=561 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 560
- `line_count`: 5
- `sha256`: 02baf61a632faf84ac4fcbfcb121cdcf3c9fecc2bdf02220f94e75e1b0a6fc84
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=560 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_issue_queue.log

- `kind`: log
- `size_bytes`: 4056
- `line_count`: 38
- `sha256`: 3e61aac27c82060067dfee6af7db31879e5b71fea6a8438245f1d1d3f0242871
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=4056 bytes; lines=38; PASS=4; tail=[TEST] tb_ooo_fp_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 585
- `line_count`: 5
- `sha256`: 17e5d2fa44de0921734f44b5ba5bc8f7ec6e8bd548c5182d83aed7310d61c66c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=585 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1889
- `line_count`: 15
- `sha256`: cb3a38663a5f25b43347863ce66bb5bbf189cd5d3f4a4e035d9103da06fbcd81
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1889 bytes; lines=15; PASS=6; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o /home/lyg/PA/ysyx-workbench/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 692
- `line_count`: 5
- `sha256`: 0c91b0a7c6b17defb7676935bb90778914944a3c1f58571c2f808af28be9c4a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=692 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_phys_reg_file.log

- `kind`: log
- `size_bytes`: 1099
- `line_count`: 12
- `sha256`: 5daf99f610304462467327c1759e7dfcd10980eb11ec8a9ce119bdd66b8c4732
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1099 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_fp_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 846
- `line_count`: 9
- `sha256`: cf27ff94ba928f7fa6d150612a76dfa64fe0fa503ae0a1ecac945777ec158745
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=846 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 542
- `line_count`: 5
- `sha256`: 73eaf64f84d7a6073261c7725577b99fef150053991c607151f8f6363f2b4c9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=542 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 534
- `line_count`: 5
- `sha256`: b6b66be765a71b83c80cfa51540739dfee71f6a13f8e654051d03b6a2e09b16e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=534 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv6...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 592
- `line_count`: 5
- `sha256`: b253c572902011866426016ecf326160e98d3af36a6c4a5cb755b07533338108
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=592 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 1000
- `line_count`: 10
- `sha256`: d0c76f2f083c3769ad5a3725feb96bb2c56a908675ef2e92104e6de7ab63c80b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1000 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o /home/lyg/PA/ysyx-wo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 912
- `line_count`: 7
- `sha256`: 1327edaa22e9ec0ce96bd72f9de210d10d24c7b2fa186568659813ee9491360f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=912 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 92d257d8a19703603823de788e109c138c2d3e7ba069dd9f2e15c714715aa7a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 586
- `line_count`: 5
- `sha256`: a1ca5e332facd7e6e14f2c82beabdbca6403f8121382478dfe43cd89ad0452ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=586 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 8910
- `line_count`: 83
- `sha256`: 710b1da796d2782c6899a8ba86ef25896f1a3ea0930ededf492c917451963120
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 116}
- `summary`: log evidence; size=8910 bytes; lines=83; PASS=116; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o /home/lyg/PA/ysyx-workbench/.github/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 26788
- `line_count`: 226
- `sha256`: 25681486161a10d0c00f7f44a8e9a40be5f511a345436a1032eca3937dd0314c
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"ERROR": 2, "PASS": 98}
- `summary`: log evidence; size=26788 bytes; lines=226; ERROR=2; PASS=98; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 11580
- `line_count`: 96
- `sha256`: dde879c607a6bd88683a6df444763bd36eeef3cd5c3254044666658d59931e5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 16}
- `summary`: log evidence; size=11580 bytes; lines=96; PASS=16; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_load_queue.log

- `kind`: log
- `size_bytes`: 4276
- `line_count`: 35
- `sha256`: ef2ffdad71d4a170f318436e3bb660cf1a2499f10a14cab92fe1c7cd1d96269d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=4276 bytes; lines=35; PASS=10; tail=[TEST] tb_ooo_load_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_load_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_lsu_axi_lane_adapter.log

- `kind`: log
- `size_bytes`: 944
- `line_count`: 10
- `sha256`: a6722b07aed62b92bb5705f0e27a07edc0f461abf681afdd21f505eb271d978b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=944 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_lsu_axi_lane_adapter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_lsu_axi_lane_adapter -o /home/lyg/PA/ysyx-workbench/.github/ta...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 74699
- `line_count`: 572
- `sha256`: 2e3662e5d34557cd7ec407c13acc1144cbb9e2547b557ea8b6629dfe8b9de2e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 28}
- `summary`: log evidence; size=74699 bytes; lines=572; PASS=28; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_mem_inflight_queue.log

- `kind`: log
- `size_bytes`: 1447
- `line_count`: 12
- `sha256`: bc009e7cc194bc4d788e5ed361661bdb3f2c9dd616f4dfbfd5250455ff1a388b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1447 bytes; lines=12; PASS=10; tail=[TEST] tb_ooo_mem_inflight_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_inflight_queue -o /home/lyg/PA/ysyx-workbench/.github/task-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_mem_owner_terminal_collector.log

- `kind`: log
- `size_bytes`: 1098
- `line_count`: 11
- `sha256`: ccf666a176a1d3788d6d27ead7487405ee0f7687b30ab9232e3f85905847462b
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=1098 bytes; lines=11; PASS=8; tail=[TEST] tb_ooo_mem_owner_terminal_collector [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_terminal_collector -o /home/lyg/PA/ysyx-work...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_mem_owner_tracker.log

- `kind`: log
- `size_bytes`: 1412
- `line_count`: 14
- `sha256`: e0ed33afcd72dec98330259c13c91d597def5f065d64e577f16ec3768d6e36c6
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=1412 bytes; lines=14; PASS=10; tail=[TEST] tb_ooo_mem_owner_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_owner_tracker -o /home/lyg/PA/ysyx-workbench/.github/task-run...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 1044
- `line_count`: 8
- `sha256`: 2ae7804177dfe3d04db0479de976dc42e4f6866bbb502f5e6bc6ae7ec46433c9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1044 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_mmu_epoch_owner.log

- `kind`: log
- `size_bytes`: 799
- `line_count`: 8
- `sha256`: 1b4624a4a537b5fe23900d9d64b056067673c15ead6dc51408d8d29ad47ebc46
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 10}
- `summary`: log evidence; size=799 bytes; lines=8; PASS=10; tail=[TEST] tb_ooo_mmu_epoch_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mmu_epoch_owner -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 542
- `line_count`: 5
- `sha256`: b32a6cb25d0e48e1c9c01aaf1f38d87c620eda72a23b56cfac23c5fa51700a55
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=542 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1268
- `line_count`: 12
- `sha256`: bcdf02d3fe9ff2ac8fc93882cfe4750585d704570cd75e660eb43f6e17a7d183
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1268 bytes; lines=12; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pending_drain_resolve_gate.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 5
- `sha256`: 3de48515b62e4933be6bc9542e9744dc965d288130cd0916994cd9ed809255b8
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=626 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_pending_drain_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_drain_resolve_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 1056
- `line_count`: 11
- `sha256`: 2a9a066e68529130c8b9ab89db710e6937bc8b15edf1fdfb98104c37288b9d63
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1056 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pending_system_admission_cancel_gate.log

- `kind`: log
- `size_bytes`: 1083
- `line_count`: 10
- `sha256`: 435155072cb93cf1cf2cbb95c00fb651dc48d1948f707faa38cce7e559416e58
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1083 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_system_admission_cancel_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_admission_cancel_gate -o /home/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 1047
- `line_count`: 10
- `sha256`: 4812a0011d7dfab4b3a7d6c816fb3ddb234e669a63f1bc09b34c2beef61a9789
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1047 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o /home/lyg/PA/ysyx-workbench/.g...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 813
- `line_count`: 7
- `sha256`: d21034cd9c9bf7071abd4ee7f6c7f70acc32bbe02357574322aaa9afcc954713
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 8}
- `summary`: log evidence; size=813 bytes; lines=7; PASS=8; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 556
- `line_count`: 5
- `sha256`: 7ff62e77ea4f3ecf7710fd9128b300b7b2f037d785c57a2dd1a0181b43824440
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=556 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-0...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_pma_checker.log

- `kind`: log
- `size_bytes`: 678
- `line_count`: 6
- `sha256`: cb5df145c5b1c16b3160fab9ed53d00ef4b077c5bce5eb90bdf0f759c1a7a4e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=678 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_pma_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pma_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 27065
- `line_count`: 143
- `sha256`: d91446a8edb43907919c8325d868bf47b330a3bc2bae23db69cdc7e9aed6a7df
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 24}
- `summary`: log evidence; size=27065 bytes; lines=143; PASS=24; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 562
- `line_count`: 5
- `sha256`: b616a0bd27a364d1a06a3adb3bbc8ba19340e762035912a90c32b713c2f359f2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=562 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o /home/lyg/PA/ysyx-workbench/.github/task-runs/20...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 568
- `line_count`: 5
- `sha256`: dda19eb1c240e8fa19031c920dbd196fd3905352994038b4d956d3923f8edaae
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=568 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o /home/lyg/PA/ysyx-workbench/.github/task-runs/...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 540
- `line_count`: 5
- `sha256`: f1ce20e6712f7f339ae31ae2b7b26d2d852aa62b10412eda24718531e2c48262
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=540 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 1423
- `line_count`: 14
- `sha256`: 647c6bd9a94e820c74280213002c77f0b79c1a8e7b59fefdf176015659d58558
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 18}
- `summary`: log evidence; size=1423 bytes; lines=14; PASS=18; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serial...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 1000
- `line_count`: 10
- `sha256`: aab97f28d60a8450fa9668b8021d88678d87ada5d918f7b5919099cd3aad1afa
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=1000 bytes; lines=10; PASS=6; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o /home/lyg/PA/ysyx-workbench/.githu...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 6936
- `line_count`: 58
- `sha256`: 65097f129ceb6ca06b9968b5690bbed07bd464ae2e8fcdf5decf854a6129e7eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 26}
- `summary`: log evidence; size=6936 bytes; lines=58; PASS=26; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 287170
- `line_count`: 2103
- `sha256`: d9416ac5bdecb647821f655bf0c68c9621b31319c459bfcaef1982bbf61a2eee
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 3}
- `summary`: log evidence; size=287170 bytes; lines=2103; PASS=3; tail=w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'en...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 5
- `sha256`: 39670aba66dbabf99fdafbc3119b7369081831f80322efd27f52301937b77a55
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=598 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o /home/lyg/PA/ysyx-workbench/.github/task...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 647
- `line_count`: 5
- `sha256`: f7447c00231853133101830706d06435e23a4f3bc2da0081f9df55fbce589706
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=647 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o /home/lyg/PA/ysyx-workbenc...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_ooo_typed_memory_classifier.log

- `kind`: log
- `size_bytes`: 698
- `line_count`: 6
- `sha256`: 4ff9e2c15c4e15cfb854bb6964347aa960c13eac7802ec10641edf4c7c70012f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 6}
- `summary`: log evidence; size=698 bytes; lines=6; PASS=6; tail=[TEST] tb_ooo_typed_memory_classifier [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_typed_memory_classifier -o /home/lyg/PA/ysyx-workbench/.git...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 533
- `line_count`: 5
- `sha256`: a622c4b003d3c584d6f4914ee4514c844c52217a15ce955948716d7227a33385
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=533 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-r...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17660
- `line_count`: 134
- `sha256`: 3cf04d1ce7a7fbd5cd738c4e7d3b2bbffee6ed78b1af6dbe6b62afc08d73043e
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17660 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 471
- `line_count`: 5
- `sha256`: f950d541dc1d2cb496b46a000a9c3fbef03cf3ec9bdff6426c983bfcd3f1c0f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=471 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-me...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: d4d5ac3798e2a30669cb64e9f33134ed5b7a177391f34df81acd7409a02d55c4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current/summary.txt

- `kind`: txt
- `size_bytes`: 3730
- `line_count`: 120
- `sha256`: 42a54424e02c3decf94644e55338e2fab3ea672b434879ef49aaa70552eae52f
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"PASS": 222}
- `summary`: txt evidence; size=3730 bytes; lines=120; PASS=222; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/module-current - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_pipe_stage_reg - PASS tb_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/mutations/logs/drop-csr-terminal-gate.log

- `kind`: log
- `size_bytes`: 329
- `line_count`: 7
- `sha256`: ad7c04db9cdbda8e068b20655a920e42a103c7de7608ab24d7b56df7127ce31d
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=329 bytes; lines=7; FAIL=4; tail=[MUTATION] drop-csr-terminal-gate [COMPILE-RC] 0 [SIM-RC] 1 [CHECK-FAIL] CSR dispatch blocks active memory holder got=1 expected=0 [FAIL] tb_ooo_pending_drain_resolve_gate errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_common.svh:3...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/mutations/logs/drop-noncsr-terminal-gate.log

- `kind`: log
- `size_bytes`: 336
- `line_count`: 7
- `sha256`: 0be2b0b2649484afbda973e02d251335d088cb0f12491342c962f1806c741acb
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 4}
- `summary`: log evidence; size=336 bytes; lines=7; FAIL=4; tail=[MUTATION] drop-noncsr-terminal-gate [COMPILE-RC] 0 [SIM-RC] 1 [CHECK-FAIL] non-fence system blocks active memory holder got=1 expected=0 [FAIL] tb_ooo_pending_drain_resolve_gate errors=1 FATAL: /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/common/tb_commo...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/mutations/logs/replace-with-full-mem-idle.log

- `kind`: log
- `size_bytes`: 422
- `line_count`: 8
- `sha256`: aa7064122a0c40517f2cd2a0c1f37e54689bda43af22346703eb65bb497174c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6}
- `summary`: log evidence; size=422 bytes; lines=8; FAIL=6; tail=[MUTATION] replace-with-full-mem-idle [COMPILE-RC] 0 [SIM-RC] 1 [CHECK-FAIL] non-fence system admits terminal-pending-only owner got=0 expected=1 [CHECK-FAIL] CSR dispatch admits terminal-pending-only owner got=0 expected=1 [FAIL] tb_ooo_pending_drain_resol...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/mutations/summary.json

- `kind`: json
- `size_bytes`: 1739
- `line_count`: 39
- `sha256`: 390d68ac2b00d9623585a4e654e059fced569194aef72a28fb3b9091000a04f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6}
- `summary`: json evidence; size=1739 bytes; lines=39; FAIL=6; tail={ "mutation_count": 3, "mutations": [ { "compile_rc": 0, "expected_marker": "[CHECK-FAIL] non-fence system blocks active memory holder", "log": ".github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/mutations/logs/drop-noncsr-termin...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/red/build/tb_v9y_pending_memory_terminal_red.vvp

- `kind`: vvp
- `size_bytes`: 32334
- `line_count`: 657
- `sha256`: be18c6a1642a1d303dbacef1e70d065f7eb1ea22ff10cffeaa54b54e020eeeb4
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 6, "PASS": 2}
- `summary`: vvp evidence; size=32334 bytes; lines=657; FAIL=6; PASS=2; tail=#! /usr/bin/vvp :ivl_version "12.0 (stable)"; :ivl_delay_selection "TYPICAL"; :vpi_time_precision + 0; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/system.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/ivl/vhdl_sys.vpi"; :vpi_module "/usr/lib/x86_64-linux-gnu/i...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/red/logs/tb_v9y_pending_memory_terminal_red.compile.log

- `kind`: log
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: log evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/red/logs/tb_v9y_pending_memory_terminal_red.log

- `kind`: log
- `size_bytes`: 418
- `line_count`: 6
- `sha256`: 20ccff690078820d1d5a74073c9ea9d3b1402b006515c3b6cb6413ca9b20d165
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 8}
- `summary`: log evidence; size=418 bytes; lines=6; FAIL=8; tail=[CHECK-FAIL] V9Y non-CSR active memory owner blocks drain got=1 expected=0 [CHECK-FAIL] V9Y CSR active memory owner blocks dispatch got=1 expected=0 [CHECK-FAIL] V9Y CSR active memory owner blocks fire got=1 expected=0 [FAIL] tb_v9y_pending_memory_terminal_...

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/red/status.txt

- `kind`: txt
- `size_bytes`: 22
- `line_count`: 2
- `sha256`: 83611deb59c82104d3486912e5e9a069ea33ac1b5f42480de0551d66e5421aa2
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {}
- `summary`: txt evidence; size=22 bytes; lines=2; markers=<none>; tail=compile_rc=0 run_rc=1

### .github/task-runs/2026-07-26-rv64-v9y-serialize-memory-owner-terminal/evidence/strict-guard.status

- `kind`: status
- `size_bytes`: 845
- `line_count`: 10
- `sha256`: 14219f0a41e04ed4d441b2f87bf00385dcac9a619d5b0cdbc8339bbfaaa797d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-26T22:17:28+00:00
- `markers`: {"FAIL": 2, "PASS": 8}
- `summary`: status evidence; size=845 bytes; lines=10; FAIL=2; PASS=8; tail=command=scripts/agent-e2e.sh --guard --guard-mode strict exit=1 changed_paths=2192 required_profiles=5 agent-system=PASS evidence=.github/task-runs/2026-07-26-pending-system-sequencer rv64-linux=FAIL reason=missing_evidence npc-dev=PASS evidence=.github/tas...
