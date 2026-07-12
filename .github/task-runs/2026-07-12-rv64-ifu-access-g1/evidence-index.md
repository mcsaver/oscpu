# Evidence Index

## 基本信息

- `task_id`: 2026-07-12-rv64-ifu-access-g1
- `task_slug`:
- `profile`: npc-dev (+ linux-device/nemu only if sized DPI/platform coverage requires it)
- `asset_count`: 936
- `total_size_bytes`: 12184107

## 证据资产

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/FAULT-ABI.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 4
- `sha256`: 690a710de0efc49aaa531cbead82da1957ac44a3f6b19b2b89fe6fc95c8856b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=384 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1109: [IFU-ACCESS-FAULT-ABI] fault response is not successful-prefix/fault-suffix Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=FAULT-ABI /home/ly...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/HOLD.log

- `kind`: log
- `size_bytes`: 383
- `line_count`: 4
- `sha256`: 90e6a6a5ad41979522697ffd26abc5c91798bc6a142921a2023a30eb1594766b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=383 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1097: [IFU-FETCH-G2-HOLD] stalled fetch response withdrew/changed resp0 byte boundary Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=HOLD /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/SPLIT-RANGE.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 4
- `sha256`: 4ced9df5e3c5cf0afb3463c0fd771ec55c49dbac62fb748bbc54ed83b1a22a4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=374 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1102: [IFU-ACCESS-SPLIT-RANGE] valid fetch response has illegal split Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=SPLIT-RANGE /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/SUCCESS-SPLIT.log

- `kind`: log
- `size_bytes`: 383
- `line_count`: 4
- `sha256`: a14691d235b9b389ff482ff9682add3ae62fe333d8edcd4c4ed8cf99077f7f79
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=383 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1106: [IFU-ACCESS-SUCCESS-SPLIT] successful fetch response split is not four Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=SUCCESS-SPLIT /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/compile.log

- `kind`: log
- `size_bytes`: 85730
- `line_count`: 645
- `sha256`: 2640bb24c344cf64dfd0bcc116312e2415e371d4620ca7ee0d0a8e100ac67c5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=85730 bytes; lines=645; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/source-hashes.after.txt

- `kind`: txt
- `size_bytes`: 283
- `line_count`: 2
- `sha256`: 1915fc07b54f0beb1bb8482cbf883bb63bab514d0402ef2b1b2f76ed24ea6775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=283 bytes; lines=2; markers=<none>; tail=5e303442e3af5c1d4c114a298db3c0bd49f48691ddf5d0f2ba254f4fbcd7defd /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v 997adaf5fd2137fc8505c46dc84d71b53a1db59ccd001d67bfc0695e0ee61bb0 /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/source-hashes.before.txt

- `kind`: txt
- `size_bytes`: 283
- `line_count`: 2
- `sha256`: 1915fc07b54f0beb1bb8482cbf883bb63bab514d0402ef2b1b2f76ed24ea6775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=283 bytes; lines=2; markers=<none>; tail=5e303442e3af5c1d4c114a298db3c0bd49f48691ddf5d0f2ba254f4fbcd7defd /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v 997adaf5fd2137fc8505c46dc84d71b53a1db59ccd001d67bfc0695e0ee61bb0 /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/summary.tsv

- `kind`: tsv
- `size_bytes`: 236
- `line_count`: 5
- `sha256`: 2259dba6dfbe802411e8d65d022ba53cb13a562535a9d249fbcf03af04e66244
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=236 bytes; lines=5; PASS=8; tail=case expected_marker marker_count error_count done_count status HOLD IFU-FETCH-G2-HOLD 1 1 1 PASS SPLIT-RANGE IFU-ACCESS-SPLIT-RANGE 1 1 1 PASS SUCCESS-SPLIT IFU-ACCESS-SUCCESS-SPLIT 1 1 1 PASS FAULT-ABI IFU-ACCESS-FAULT-ABI 1 1 1 PASS

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-current/tb_ooo_ifu_access_assert_negative.vvp

- `kind`: vvp
- `size_bytes`: 1030323
- `line_count`: 26003
- `sha256`: 85c725e2c54e0bc1c39296065201d4f3b81aa408362ec10eac17180bcd3f4dec
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 3, "PASS": 1, "SKIP": 1}
- `summary`: vvp evidence; size=1030323 bytes; lines=26003; FAIL=3; SKIP=1; PASS=1; tail=c4 544501536, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1229212741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x55555b624e20_0, 0, 1024; %fork TD_tb_ooo_fetch_axi_bridge.check_dropped_write_quiet, S_0x55555...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/FAULT-ABI.log

- `kind`: log
- `size_bytes`: 384
- `line_count`: 4
- `sha256`: 690a710de0efc49aaa531cbead82da1957ac44a3f6b19b2b89fe6fc95c8856b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=384 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1109: [IFU-ACCESS-FAULT-ABI] fault response is not successful-prefix/fault-suffix Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=FAULT-ABI /home/ly...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/HOLD.log

- `kind`: log
- `size_bytes`: 383
- `line_count`: 4
- `sha256`: 90e6a6a5ad41979522697ffd26abc5c91798bc6a142921a2023a30eb1594766b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=383 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1097: [IFU-FETCH-G2-HOLD] stalled fetch response withdrew/changed resp0 byte boundary Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=HOLD /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/SPLIT-RANGE.log

- `kind`: log
- `size_bytes`: 374
- `line_count`: 4
- `sha256`: 4ced9df5e3c5cf0afb3463c0fd771ec55c49dbac62fb748bbc54ed83b1a22a4b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=374 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1102: [IFU-ACCESS-SPLIT-RANGE] valid fetch response has illegal split Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=SPLIT-RANGE /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/SUCCESS-SPLIT.log

- `kind`: log
- `size_bytes`: 383
- `line_count`: 4
- `sha256`: a14691d235b9b389ff482ff9682add3ae62fe333d8edcd4c4ed8cf99077f7f79
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"ERROR": 2}
- `summary`: log evidence; size=383 bytes; lines=4; ERROR=2; tail=ERROR: /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v:1106: [IFU-ACCESS-SUCCESS-SPLIT] successful fetch response split is not four Time: 35 Scope: tb_ooo_fetch_axi_bridge.dut ACCESS-ASSERT-NEGATIVE-DONE marker=SUCCESS-SPLIT /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/compile.log

- `kind`: log
- `size_bytes`: 85730
- `line_count`: 645
- `sha256`: 2640bb24c344cf64dfd0bcc116312e2415e371d4620ca7ee0d0a8e100ac67c5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=85730 bytes; lines=645; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/source-hashes.after.txt

- `kind`: txt
- `size_bytes`: 283
- `line_count`: 2
- `sha256`: 1915fc07b54f0beb1bb8482cbf883bb63bab514d0402ef2b1b2f76ed24ea6775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=283 bytes; lines=2; markers=<none>; tail=5e303442e3af5c1d4c114a298db3c0bd49f48691ddf5d0f2ba254f4fbcd7defd /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v 997adaf5fd2137fc8505c46dc84d71b53a1db59ccd001d67bfc0695e0ee61bb0 /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/source-hashes.before.txt

- `kind`: txt
- `size_bytes`: 283
- `line_count`: 2
- `sha256`: 1915fc07b54f0beb1bb8482cbf883bb63bab514d0402ef2b1b2f76ed24ea6775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=283 bytes; lines=2; markers=<none>; tail=5e303442e3af5c1d4c114a298db3c0bd49f48691ddf5d0f2ba254f4fbcd7defd /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/frontend/OooFetchAxiBridge.v 997adaf5fd2137fc8505c46dc84d71b53a1db59ccd001d67bfc0695e0ee61bb0 /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/tests/tb_...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/summary.tsv

- `kind`: tsv
- `size_bytes`: 236
- `line_count`: 5
- `sha256`: 2259dba6dfbe802411e8d65d022ba53cb13a562535a9d249fbcf03af04e66244
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 8}
- `summary`: tsv evidence; size=236 bytes; lines=5; PASS=8; tail=case expected_marker marker_count error_count done_count status HOLD IFU-FETCH-G2-HOLD 1 1 1 PASS SPLIT-RANGE IFU-ACCESS-SPLIT-RANGE 1 1 1 PASS SUCCESS-SPLIT IFU-ACCESS-SUCCESS-SPLIT 1 1 1 PASS FAULT-ABI IFU-ACCESS-FAULT-ABI 1 1 1 PASS

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/assert-negative-final-current/tb_ooo_ifu_access_assert_negative.vvp

- `kind`: vvp
- `size_bytes`: 1030323
- `line_count`: 26003
- `sha256`: 0e03f82c639f4e683ebc77c1bc7ef2e739b362e388701de3c0f9616c2fd3928e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 3, "PASS": 1, "SKIP": 1}
- `summary`: vvp evidence; size=1030323 bytes; lines=26003; FAIL=3; SKIP=1; PASS=1; tail=c4 544501536, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 1229212741, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %store/vec4 v0x55556580ee30_0, 0, 1024; %fork TD_tb_ooo_fetch_axi_bridge.check_dropped_write_quiet, S_0x55556...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave

- `kind`: file
- `size_bytes`: 253376
- `line_count`: 335
- `sha256`: dd997f463821823ba8df440f4d9edb161339fca5b1b36746dcdc979c1d7ed5d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__FRAME_END__", "__TMC_END__", "__TOP__"]}
- `summary`: file evidence; size=253376 bytes; lines=335; symbolic=__FRAME_END__,__TMC_END__,__TOP__; tail=�x �] " ʀ � Q^ Ƨ � m^ �^ " �a " �^ �^ �� � _ " �� . l_ .� o �_ �a �_ `Z �_ " �i Y ` AJ � -` " �� F` Y` �` " v� T �` � �` � a " �� 8 La B� _a �; � �a �� �a ޓ N �a \ � b b� � rb L� i �b H� �b �x �b ! �� 8 c �� L cc YG V |c " �� �c p� �c � � d Ed ad ۠ � sd ��...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave.cpp

- `kind`: cpp
- `size_bytes`: 4323
- `line_count`: 119
- `sha256`: 2755eead40c65528bbde1132d3943cbe77cf2da494538926c1e67d99f511085f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__FILE__", "__LINE__", "__PVT____"]}
- `summary`: cpp evidence; size=4323 bytes; lines=119; symbolic=__FILE__,__LINE__,__PVT____; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Model implementation (design independent parts) #include "VAxiDpiSlave__pch.h" //============================================================ // Constructors VAxiDpiSlave::VAxiDpiSlave(VerilatedCont...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave.h

- `kind`: h
- `size_bytes`: 4274
- `line_count`: 112
- `sha256`: 6df1a3356f7b69c0a3a3791a8368a5c319880189ef2411a430a87f2a1282693b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__PVT____"]}
- `summary`: h evidence; size=4274 bytes; lines=112; symbolic=__PVT____; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Primary model header // // This header should be included by all source files instantiating the design. // The class here is then constructed to instantiate the design. // See the Verilator manual f...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave.mk

- `kind`: mk
- `size_bytes`: 2203
- `line_count`: 70
- `sha256`: dbad933d0c6b6920395a671653bb6a9cf075e39afcfa0c2230867e8d47e20524
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: mk evidence; size=2203 bytes; lines=70; markers=<none>; tail=# Verilated -*- Makefile -*- # DESCRIPTION: Verilator output: Makefile for building Verilated archive or executable # # Execute this makefile from the object directory: # make -f VAxiDpiSlave.mk default: VAxiDpiSlave ### Constants... # Perl executable (from...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__ALL.a

- `kind`: a
- `size_bytes`: 27146
- `line_count`: 51
- `sha256`: 144141d1984adc32c82e0e1d27a2c5104bffffa977ffffcb3ca19f3cfbdc4387
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__TOP__"]}
- `summary`: a evidence; size=27146 bytes; lines=51; symbolic=__TOP__; tail=!<arch> / 0 0 0 0 3312 ` E � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � �_ZNK18VAxiDpiSlave__Syms4nameEv _ZNK12VAxiDpiSlave4nameEv _ZNK12VAxiDpiSlave8hierNameEv _ZNK1...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__ALL.cpp

- `kind`: cpp
- `size_bytes`: 410
- `line_count`: 10
- `sha256`: a5b208b532ed62715e0da5733e4f2b8ac74487d2c43a3d6b07658921233ce931
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: cpp evidence; size=410 bytes; lines=10; symbolic=__0__; tail=// DESCRIPTION: Generated by verilator_includer via makefile #define VL_INCLUDE_OPT include #include "VAxiDpiSlave.cpp" #include "VAxiDpiSlave___024root__0.cpp" #include "VAxiDpiSlave___024unit__0.cpp" #include "VAxiDpiSlave__Dpi.cpp" #include "VAxiDpiSlave...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__ALL.d

- `kind`: d
- `size_bytes`: 1184
- `line_count`: 16
- `sha256`: 552bf876c6abf58f54cba1ccaff6c632ddec61db31dd7d1431492698af46ad59
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: d evidence; size=1184 bytes; lines=16; symbolic=__0__; tail=VAxiDpiSlave__ALL.o: VAxiDpiSlave__ALL.cpp VAxiDpiSlave.cpp \ VAxiDpiSlave__pch.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_config.h \ /home/...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__ALL.o

- `kind`: o
- `size_bytes`: 23624
- `line_count`: 45
- `sha256`: 7c6c0a9dcc7ef321d2a79bf782d44ffc7e9e7ca7048dfd0908e1ac3e2af9d0fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__TOP__"]}
- `summary`: o evidence; size=23624 bytes; lines=45; symbolic=__TOP__; tail=ELF > O @ @ 5 4 ! " # $ % & ' ( ) * + , - H�G H��� �H� ø �1�ÐPH� H� �X H�= � 1�Z�H� � �H� � H��AW1ɊP D�H AVD�p D�P AUD�h D�X ATD�` L�@PUH�h@H9�� S ��H�wX�X �� 8P+@� �� ���� �1�D8p" �� �1�D8`$ ���� �1�D8h# ��E1� � �H9�� �H A ��A�� 8H* �� ���� D �E1�L9�� H���...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__Dpi.cpp

- `kind`: cpp
- `size_bytes`: 692
- `line_count`: 16
- `sha256`: 8ee150890a87e30f962f89f0f4934d1e28442a2d78e326bec9c34dd18a314357
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=692 bytes; lines=16; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Implementation of DPI export functions // // Verilator compiles this file in when DPI functions are used. // If you have multiple Verilated designs with the same DPI exported // function names, you...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__Dpi.h

- `kind`: h
- `size_bytes`: 1178
- `line_count`: 30
- `sha256`: 8e0bee492abdb4223ca57b8fedfa39d90d5275cd9e67ae06b7f627fcbe120eb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=1178 bytes; lines=30; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Prototypes for DPI import and export functions. // // Verilator includes this file in all generated .cpp files that use DPI functions. // Manually include this file where DPI .c import functions are...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__Syms.h

- `kind`: h
- `size_bytes`: 1133
- `line_count`: 42
- `sha256`: caef4af935ba553845ebe9bf36ede40e3c3e9c4f78ebeec3e75bc5715a4bfd76
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=1133 bytes; lines=42; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Symbol table internal header // // Internal details; most calling programs do not need this header, // unless using verilator public meta comments. #ifndef VERILATED_VAXIDPISLAVE__SYMS_H_ #define VE...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__Syms__Slow.cpp

- `kind`: cpp
- `size_bytes`: 1132
- `line_count`: 34
- `sha256`: 9c43eb74546ecdfe0bbb5db27db472d564404d84c8f9dd89a4dbde2be1e58c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__PVT____"]}
- `summary`: cpp evidence; size=1132 bytes; lines=34; symbolic=__PVT____; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Symbol table implementation internals #include "VAxiDpiSlave__pch.h" VAxiDpiSlave__Syms::VAxiDpiSlave__Syms(VerilatedContext* contextp, const char* namep, VAxiDpiSlave* modelp) : VerilatedSyms{conte...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024root.h

- `kind`: h
- `size_bytes`: 3639
- `line_count`: 97
- `sha256`: 3d7746e7a7e958d5a526a5406b4519518d0c0458bd297aa8d9f6abd6d76cb08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__DOT__", "__PVT____", "___TOP__"]}
- `summary`: h evidence; size=3639 bytes; lines=97; symbolic=__DOT__,__PVT____,___TOP__; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design internal header // See VAxiDpiSlave.h for the primary calling header #ifndef VERILATED_VAXIDPISLAVE___024ROOT_H_ #define VERILATED_VAXIDPISLAVE___024ROOT_H_ // guard #include "verilated.h" cl...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024root__0.cpp

- `kind`: cpp
- `size_bytes`: 25807
- `line_count`: 473
- `sha256`: b7e45020a2c35a0132d9f43791cef9cb4a2581d0b629d6e8b3252705ce59b50a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__DOT__", "__TOP__", "___TOP__"]}
- `summary`: cpp evidence; size=25807 bytes; lines=473; symbolic=__0__,__1__,__2__,__DOT__,__TOP__; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" void VAxiDpiSlave___024root___eval_triggers_vec__ico(VAxiDpiSlave___024root* vlSel...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024root__0__Slow.cpp

- `kind`: cpp
- `size_bytes`: 15951
- `line_count`: 304
- `sha256`: d4986bd2ebece760a36488b858adeb18abd612d7652f5430fb9ede5d5e355009
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__DOT__", "__TOP__", "___TOP__"]}
- `summary`: cpp evidence; size=15951 bytes; lines=304; symbolic=__DOT__,__TOP__,___TOP__; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" VL_ATTR_COLD void VAxiDpiSlave___024root___eval_static(VAxiDpiSlave___024root* vlS...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024root__Slow.cpp

- `kind`: cpp
- `size_bytes`: 720
- `line_count`: 23
- `sha256`: f337f5384e15f3473733c7c1f5024588bcd25cca16aab669bd6b058ae61c1cc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=720 bytes; lines=23; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" void VAxiDpiSlave___024root___ctor_var_reset(VAxiDpiSlave___024root* vlSelf); VAxi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024unit.h

- `kind`: h
- `size_bytes`: 733
- `line_count`: 32
- `sha256`: 72af91391b09a8f34f356b83895d09864b39bbebda723c2d099846cf969b259d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=733 bytes; lines=32; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design internal header // See VAxiDpiSlave.h for the primary calling header #ifndef VERILATED_VAXIDPISLAVE___024UNIT_H_ #define VERILATED_VAXIDPISLAVE___024UNIT_H_ // guard #include "verilated.h" cl...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024unit__0.cpp

- `kind`: cpp
- `size_bytes`: 2403
- `line_count`: 58
- `sha256`: 331288bbbc20db886cb87245181fb3a34f30abc3696a030ac895080c97c72b5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=2403 bytes; lines=58; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" extern "C" int npc_ifetch_sized(unsigned long long addr, unsigned int nbytes, unsi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave___024unit__Slow.cpp

- `kind`: cpp
- `size_bytes`: 722
- `line_count`: 23
- `sha256`: ba3dd5dc9c65cf15b35dc9a02e4ddcd2aa427f4c1d62b895ed7d93c46af61531
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=722 bytes; lines=23; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" VAxiDpiSlave___024unit::VAxiDpiSlave___024unit() = default; VAxiDpiSlave___024unit...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__pch.h

- `kind`: h
- `size_bytes`: 812
- `line_count`: 28
- `sha256`: a565d99150a48569bc8dbcaef74e5344a7e8dd4e6771df10fa3cdecdfaa4a897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=812 bytes; lines=28; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Precompiled header // // Internal details; most user sources do not need this header, // unless using verilator public meta comments. // Suggest use VAxiDpiSlave.h instead. #ifndef VERILATED_VAXIDPI...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__ver.d

- `kind`: d
- `size_bytes`: 2899
- `line_count`: 1
- `sha256`: e00bb784f73f2b8628ec07c915e2a4076f9efa905db85c2fa69b8b330b0fde23
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: d evidence; size=2899 bytes; lines=1; symbolic=__0__; tail=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave.cpp /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_ax...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave__verFiles.dat

- `kind`: dat
- `size_bytes`: 5512
- `line_count`: 25
- `sha256`: fdc9eeb757a130b4a0351fcc3e06fb4a99308f9cc884fcc249db2e54f724e08d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: dat evidence; size=5512 bytes; lines=25; symbolic=__0__; tail=# DESCRIPTION: Verilator output: Timestamp data for --skip-identical. Delete at will. C "--cc --exe --build --top-module AxiDpiSlave -Wall -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include --Mdir /home/lyg/PA/ysyx-workbench/.github/task-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/VAxiDpiSlave_classes.mk

- `kind`: mk
- `size_bytes`: 1810
- `line_count`: 57
- `sha256`: 24a11963bade6b7514d362ab34c352f1bb50d4baece7bb76bb97705272383e13
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: mk evidence; size=1810 bytes; lines=57; symbolic=__0__; tail=# Verilated -*- Makefile -*- # DESCRIPTION: Verilator output: Make include file with class lists # # This file lists generated Verilated files, for including in higher level makefiles. # See VAxiDpiSlave.mk for the caller. ### Switches... # C11 constructs r...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/axi_dpi_slave_sized_tb.d

- `kind`: d
- `size_bytes`: 635
- `line_count`: 9
- `sha256`: 846f2ced1b1d6d73c1983d774991e2b2fe11e33146af4f1647fbe73d30ff50eb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=635 bytes; lines=9; markers=<none>; tail=axi_dpi_slave_sized_tb.o: \ /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/cpp/axi_dpi_slave_sized_tb.cpp \ VAxiDpiSlave.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/veri...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/axi_dpi_slave_sized_tb.o

- `kind`: o
- `size_bytes`: 9736
- `line_count`: 12
- `sha256`: acda622df2713b70e261099550dec453d8478f3e26bc71153d86d13b057f63bb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 2}
- `summary`: o evidence; size=9736 bytes; lines=12; FAIL=2; tail=ELF > H @ @ SH�G H��� � H�C H��� � H�C H��� [� @��u&PH�= H��1�H� � � � Z��AWE��AVAUATUH��SH��H�� H��� D�% D�l$PD�t$XL�D$ H�0H�G8� H�G@� H�G(� H�GP� � H�C01�H�5 �8 @ ���e���H���.���H�C(H��� � H�CH1�H�5 �8 @ ���5���H��� 1�L�D$ H�5 L9 @ ��� ���H�CX1�H�5 � D9�@...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/verilated.d

- `kind`: d
- `size_bytes`: 1045
- `line_count`: 13
- `sha256`: c2f6ac84ebaf2b69e8d3317f6bb24eba8350c0b6397ebd368eb4b17fc0f80bac
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=1045 bytes; lines=13; markers=<none>; tail=verilated.o: \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated.cpp \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_config.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilat...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/verilated.o

- `kind`: o
- `size_bytes`: 290072
- `line_count`: 359
- `sha256`: 7cf4465df575246d06362db4be6117908681f1e6ce5c34799c8714e4ea1a5d54
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=290072 bytes; lines=359; markers=<none>; tail=�� ;� ?� C� �� $ 0� ( 4� , 8� 0 <� 4 @� 8 D� < �� @ @� D P� H T� L %� P �� T \� X � \ h� ` �� d p� h p� l �� p � t � x B� | �� � � � �� � +� � M� ! ��������! ��������! ��������W � ��������\ ��������� r � ��������( ��������P ��������d ��������( ��������P ���...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/verilated_dpi.d

- `kind`: d
- `size_bytes`: 1045
- `line_count`: 13
- `sha256`: d2695c12dc3488c9c6d7ab585fb25c5e8ffff08118af9799ec552431e3c13361
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=1045 bytes; lines=13; markers=<none>; tail=verilated_dpi.o: \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_dpi.cpp \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilatedos.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/veri...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/verilated_dpi.o

- `kind`: o
- `size_bytes`: 32664
- `line_count`: 63
- `sha256`: 4f99b39f9526eb9a128095f8f1be2f152f55226daa6cfcebac41f7e2c583e4d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=32664 bytes; lines=63; markers=<none>; tail=ELF > �p @ @ ; : # $ ! " % & ' ( ) * + , - . / 0 2 3 SH��H��u H� H� �� H�= � H� �8)���t H� H� �� H�= � H��[Ð��u �WD�#� ~ H�O H�G H)�H�� 9� ��Hc��T� ��Ð��u �W@�"� ~ H�O H�G H)�H�� 9� ��Hc�� ���H�G H+G H�� Ð9�| )��G �)��F �H�W(L�G0� L9�t �r �:H�� ����� ������...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/verilated_threads.d

- `kind`: d
- `size_bytes`: 627
- `line_count`: 8
- `sha256`: f1af5b872b4786ff32aa87b3a45ec7b5f541ce234b7cf2029669234f5597de2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=627 bytes; lines=8; markers=<none>; tail=verilated_threads.o: \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_threads.cpp \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilatedos.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/incl...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_axi/verilated_threads.o

- `kind`: o
- `size_bytes`: 63064
- `line_count`: 81
- `sha256`: e3f49c3dfea1a213193e34f94cb52a87324ed7d196e549c43baf9b41bdcfb4e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=63064 bytes; lines=81; markers=<none>; tail=ELF > �� @ @ � � D E G H F I J K L M N Z [ � � � � O P Q R q r S T U V s t X Y � � \ ] ^ _ ` a b c d e g h i j k l m n o p v w x y z } ~ � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � �...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave

- `kind`: file
- `size_bytes`: 123312
- `line_count`: 247
- `sha256`: a31e9ea7fb456ea7db628dfb9a566ca1d2d91b9f051631bc049a296eede02288
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 1, "symbolic": ["__FRAME_END__", "__TMC_END__", "__TOP__"]}
- `summary`: file evidence; size=123312 bytes; lines=247; FAIL=1; symbolic=__FRAME_END__,__TMC_END__,__TOP__; tail=��@ �� I�^@L��H�������I9�t/� �S�H�C�9� �� f��P H�ƋP�H�� 9�|�H�� � I9�u�� c��f ��L��E1�D$ HǄ$` HǄ$� )�$P )�$� � � I9�t}D�#D��$� E��u@H��$� H;�$� �� D�&H�� H��$� H�� D9d$ u�I9�t8D�#D��$� H��$X H;�$` �q D�&H�� A� H��$X �H��$X L��$P L��$� H��L)�M)�H��H�\$ H�� H...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave.cpp

- `kind`: cpp
- `size_bytes`: 4323
- `line_count`: 119
- `sha256`: 2755eead40c65528bbde1132d3943cbe77cf2da494538926c1e67d99f511085f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__FILE__", "__LINE__", "__PVT____"]}
- `summary`: cpp evidence; size=4323 bytes; lines=119; symbolic=__FILE__,__LINE__,__PVT____; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Model implementation (design independent parts) #include "VAxiDpiSlave__pch.h" //============================================================ // Constructors VAxiDpiSlave::VAxiDpiSlave(VerilatedCont...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave.h

- `kind`: h
- `size_bytes`: 4274
- `line_count`: 112
- `sha256`: 6df1a3356f7b69c0a3a3791a8368a5c319880189ef2411a430a87f2a1282693b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__PVT____"]}
- `summary`: h evidence; size=4274 bytes; lines=112; symbolic=__PVT____; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Primary model header // // This header should be included by all source files instantiating the design. // The class here is then constructed to instantiate the design. // See the Verilator manual f...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave.mk

- `kind`: mk
- `size_bytes`: 2534
- `line_count`: 75
- `sha256`: 0e61237b299fb412363faa55d412656f5f75da6dcd118a99672d2707fb6ef654
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: mk evidence; size=2534 bytes; lines=75; markers=<none>; tail=# Verilated -*- Makefile -*- # DESCRIPTION: Verilator output: Makefile for building Verilated archive or executable # # Execute this makefile from the object directory: # make -f VAxiDpiSlave.mk default: VAxiDpiSlave ### Constants... # Perl executable (from...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__ALL.a

- `kind`: a
- `size_bytes`: 37312
- `line_count`: 51
- `sha256`: c584972b684d25a2c94254d00d0830a3c915ca0a2f2a34d53261d934179d452f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__TOP__"]}
- `summary`: a evidence; size=37312 bytes; lines=51; symbolic=__TOP__; tail=!<arch> / 0 0 0 0 3166 ` A � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � � �_ZNK18VAxiDpiSlave__Syms4nameEv _ZNK12VAxiDpiSlave4nameEv _ZNK12VAxiDpiSlave8hierNameEv _ZNK12VAxiDpi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__ALL.cpp

- `kind`: cpp
- `size_bytes`: 410
- `line_count`: 10
- `sha256`: a5b208b532ed62715e0da5733e4f2b8ac74487d2c43a3d6b07658921233ce931
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: cpp evidence; size=410 bytes; lines=10; symbolic=__0__; tail=// DESCRIPTION: Generated by verilator_includer via makefile #define VL_INCLUDE_OPT include #include "VAxiDpiSlave.cpp" #include "VAxiDpiSlave___024root__0.cpp" #include "VAxiDpiSlave___024unit__0.cpp" #include "VAxiDpiSlave__Dpi.cpp" #include "VAxiDpiSlave...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__ALL.d

- `kind`: d
- `size_bytes`: 1184
- `line_count`: 16
- `sha256`: 552bf876c6abf58f54cba1ccaff6c632ddec61db31dd7d1431492698af46ad59
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: d evidence; size=1184 bytes; lines=16; symbolic=__0__; tail=VAxiDpiSlave__ALL.o: VAxiDpiSlave__ALL.cpp VAxiDpiSlave.cpp \ VAxiDpiSlave__pch.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_config.h \ /home/...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__ALL.o

- `kind`: o
- `size_bytes`: 33936
- `line_count`: 45
- `sha256`: 7e3cd888eef0f1f1696e472cc64f0bb37b35c9abfcddfe010c7abdf30e50494f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__TOP__"]}
- `summary`: o evidence; size=33936 bytes; lines=45; symbolic=__TOP__; tail=ELF > �d @ @ ~ g h i j k l m n o p q r s t u v w H��� � H�G H��� �VAxiDpiSlave H� � � � 1��No delays in the design VAxiDpiSlave.cpp H�� H� H� �X H�= � 1�H�� �SH��H� � � H�{ 1�[� H� � H� � H��AW1�AVAUATUSL�w@L9�� �o @ ��1�D �G �_ �� @8h+D �_ ��D �W D �O �� L...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__Dpi.cpp

- `kind`: cpp
- `size_bytes`: 692
- `line_count`: 16
- `sha256`: 8ee150890a87e30f962f89f0f4934d1e28442a2d78e326bec9c34dd18a314357
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=692 bytes; lines=16; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Implementation of DPI export functions // // Verilator compiles this file in when DPI functions are used. // If you have multiple Verilated designs with the same DPI exported // function names, you...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__Dpi.h

- `kind`: h
- `size_bytes`: 1178
- `line_count`: 30
- `sha256`: 8e0bee492abdb4223ca57b8fedfa39d90d5275cd9e67ae06b7f627fcbe120eb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=1178 bytes; lines=30; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Prototypes for DPI import and export functions. // // Verilator includes this file in all generated .cpp files that use DPI functions. // Manually include this file where DPI .c import functions are...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__Syms.h

- `kind`: h
- `size_bytes`: 1133
- `line_count`: 42
- `sha256`: caef4af935ba553845ebe9bf36ede40e3c3e9c4f78ebeec3e75bc5715a4bfd76
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=1133 bytes; lines=42; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Symbol table internal header // // Internal details; most calling programs do not need this header, // unless using verilator public meta comments. #ifndef VERILATED_VAXIDPISLAVE__SYMS_H_ #define VE...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__Syms__Slow.cpp

- `kind`: cpp
- `size_bytes`: 1132
- `line_count`: 34
- `sha256`: 9c43eb74546ecdfe0bbb5db27db472d564404d84c8f9dd89a4dbde2be1e58c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__PVT____"]}
- `summary`: cpp evidence; size=1132 bytes; lines=34; symbolic=__PVT____; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Symbol table implementation internals #include "VAxiDpiSlave__pch.h" VAxiDpiSlave__Syms::VAxiDpiSlave__Syms(VerilatedContext* contextp, const char* namep, VAxiDpiSlave* modelp) : VerilatedSyms{conte...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024root.h

- `kind`: h
- `size_bytes`: 3639
- `line_count`: 97
- `sha256`: 3d7746e7a7e958d5a526a5406b4519518d0c0458bd297aa8d9f6abd6d76cb08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__DOT__", "__PVT____", "___TOP__"]}
- `summary`: h evidence; size=3639 bytes; lines=97; symbolic=__DOT__,__PVT____,___TOP__; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design internal header // See VAxiDpiSlave.h for the primary calling header #ifndef VERILATED_VAXIDPISLAVE___024ROOT_H_ #define VERILATED_VAXIDPISLAVE___024ROOT_H_ // guard #include "verilated.h" cl...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024root__0.cpp

- `kind`: cpp
- `size_bytes`: 25807
- `line_count`: 473
- `sha256`: b7e45020a2c35a0132d9f43791cef9cb4a2581d0b629d6e8b3252705ce59b50a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__DOT__", "__TOP__", "___TOP__"]}
- `summary`: cpp evidence; size=25807 bytes; lines=473; symbolic=__0__,__1__,__2__,__DOT__,__TOP__; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" void VAxiDpiSlave___024root___eval_triggers_vec__ico(VAxiDpiSlave___024root* vlSel...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024root__0__Slow.cpp

- `kind`: cpp
- `size_bytes`: 15951
- `line_count`: 304
- `sha256`: d4986bd2ebece760a36488b858adeb18abd612d7652f5430fb9ede5d5e355009
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__DOT__", "__TOP__", "___TOP__"]}
- `summary`: cpp evidence; size=15951 bytes; lines=304; symbolic=__DOT__,__TOP__,___TOP__; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" VL_ATTR_COLD void VAxiDpiSlave___024root___eval_static(VAxiDpiSlave___024root* vlS...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024root__Slow.cpp

- `kind`: cpp
- `size_bytes`: 720
- `line_count`: 23
- `sha256`: f337f5384e15f3473733c7c1f5024588bcd25cca16aab669bd6b058ae61c1cc7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=720 bytes; lines=23; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" void VAxiDpiSlave___024root___ctor_var_reset(VAxiDpiSlave___024root* vlSelf); VAxi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024unit.h

- `kind`: h
- `size_bytes`: 733
- `line_count`: 32
- `sha256`: 72af91391b09a8f34f356b83895d09864b39bbebda723c2d099846cf969b259d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=733 bytes; lines=32; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design internal header // See VAxiDpiSlave.h for the primary calling header #ifndef VERILATED_VAXIDPISLAVE___024UNIT_H_ #define VERILATED_VAXIDPISLAVE___024UNIT_H_ // guard #include "verilated.h" cl...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024unit__0.cpp

- `kind`: cpp
- `size_bytes`: 2403
- `line_count`: 58
- `sha256`: 331288bbbc20db886cb87245181fb3a34f30abc3696a030ac895080c97c72b5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=2403 bytes; lines=58; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" extern "C" int npc_ifetch_sized(unsigned long long addr, unsigned int nbytes, unsi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave___024unit__Slow.cpp

- `kind`: cpp
- `size_bytes`: 722
- `line_count`: 23
- `sha256`: ba3dd5dc9c65cf15b35dc9a02e4ddcd2aa427f4c1d62b895ed7d93c46af61531
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: cpp evidence; size=722 bytes; lines=23; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Design implementation internals // See VAxiDpiSlave.h for the primary calling header #include "VAxiDpiSlave__pch.h" VAxiDpiSlave___024unit::VAxiDpiSlave___024unit() = default; VAxiDpiSlave___024unit...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__pch.h

- `kind`: h
- `size_bytes`: 812
- `line_count`: 28
- `sha256`: a565d99150a48569bc8dbcaef74e5344a7e8dd4e6771df10fa3cdecdfaa4a897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: h evidence; size=812 bytes; lines=28; markers=<none>; tail=// Verilated -*- C++ -*- // DESCRIPTION: Verilator output: Precompiled header // // Internal details; most user sources do not need this header, // unless using verilator public meta comments. // Suggest use VAxiDpiSlave.h instead. #ifndef VERILATED_VAXIDPI...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__ver.d

- `kind`: d
- `size_bytes`: 2933
- `line_count`: 1
- `sha256`: 9e867fbbcf03be3f47b7b40e04fbb6895882eef8d1a612c17dc39e2865730607
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: d evidence; size=2933 bytes; lines=1; symbolic=__0__; tail=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave.cpp /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave__verFiles.dat

- `kind`: dat
- `size_bytes`: 5770
- `line_count`: 25
- `sha256`: 075b486ab011646af9144af0b696b5b70d24a7508f2af5eaaa964cdee3752e32
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: dat evidence; size=5770 bytes; lines=25; symbolic=__0__; tail=# DESCRIPTION: Verilator output: Timestamp data for --skip-identical. Delete at will. C "--cc --exe --build --top-module AxiDpiSlave -Wall -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include --Mdir /home/lyg/PA/ysyx-workbench/.github/task-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/VAxiDpiSlave_classes.mk

- `kind`: mk
- `size_bytes`: 1810
- `line_count`: 57
- `sha256`: 24a11963bade6b7514d362ab34c352f1bb50d4baece7bb76bb97705272383e13
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: mk evidence; size=1810 bytes; lines=57; symbolic=__0__; tail=# Verilated -*- Makefile -*- # DESCRIPTION: Verilator output: Make include file with class lists # # This file lists generated Verilated files, for including in higher level makefiles. # See VAxiDpiSlave.mk for the caller. ### Switches... # C11 constructs r...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/dpi.d

- `kind`: d
- `size_bytes`: 691
- `line_count`: 10
- `sha256`: 18d43ff3878d82dd458f3b6bb0dd18602720bca1bbbebb77b1f71344376faeed
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=691 bytes; lines=10; markers=<none>; tail=dpi.o: /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/dpi.c \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/vltstd/svdpi.h \ /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/include/cpu/difftest.h \ /home/lyg/PA/ysyx-workbench/npc/rv64/csrc/include/...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/dpi.o

- `kind`: o
- `size_bytes`: 21312
- `line_count`: 9
- `sha256`: 2301681e4d2a8d2b3c7d774fd358b4e1c725e9331ce5e5dc5d09b8835e8d3d6e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=21312 bytes; lines=9; markers=<none>; tail=ELF > C @ @ A @ NPC_UART_TX_TRACE NPC_UART_TX_TRACE_MIN_COMMIT NPC_UART_TX_TRACE_LIMIT NPC_UART_ACCESS_TRACE NPC_UART_ACCESS_TRACE_MIN_COMMIT NPC_UART_ACCESS_TRACE_LIMIT NPC_IRQ_TRACE NPC_IRQ_TRACE_MIN_COMMIT NPC_IRQ_TRACE_LIMIT enabled min_commit=%llu limi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/sized_dpi_guard_tb.d

- `kind`: d
- `size_bytes`: 1468
- `line_count`: 21
- `sha256`: dae78eac9c8b3316905a00aeb2c2e4b76db5452bbece4a30b8006ba8f65a99c1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=1468 bytes; lines=21; markers=<none>; tail=sized_dpi_guard_tb.o: \ /home/lyg/PA/ysyx-workbench/npc/rv64/testbench/cpp/sized_dpi_guard_tb.cpp \ VAxiDpiSlave.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/in...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/sized_dpi_guard_tb.o

- `kind`: o
- `size_bytes`: 18088
- `line_count`: 18
- `sha256`: 45028cd548637cf95961207165f0e9d88e0ffa49c2a41aa8c68bfb6473bff236
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 2}
- `summary`: o evidence; size=18088 bytes; lines=18; FAIL=2; tail=ELF > �6 @ @ ? > 4 5 6 7 SH�G H��� � H�C H��� � H�C H��� [� [FAIL] %s @��u&PH�= H��1�H� � � � Z��真实 DPI 请求前 ARREADY 应为 1 真实 DPI 请求应产生 RVALID 真实 DPI 请求的 RDATA 不符 真实 DPI 请求的 RRESP 不符 真实 DPI 响应 fire 后必须撤销 RVALID ATI��UD��SH��� H��H�0H�G8� H�G@� H�G(� H�GP� � H...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/verilated.d

- `kind`: d
- `size_bytes`: 1045
- `line_count`: 13
- `sha256`: c2f6ac84ebaf2b69e8d3317f6bb24eba8350c0b6397ebd368eb4b17fc0f80bac
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=1045 bytes; lines=13; markers=<none>; tail=verilated.o: \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated.cpp \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_config.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilat...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/verilated.o

- `kind`: o
- `size_bytes`: 515744
- `line_count`: 593
- `sha256`: b04b8dfc61000fd1c28a89ca24305857d29b2b123a654b0804fd7b04441eb44e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=515744 bytes; lines=593; markers=<none>; tail=r% @ �� �% �a �% 2 �a �% �a 6 �% @ �� � & e * & @ 8� 0 ! 1& @e ,& @ h� # J& 2 Oe �& pe R }& @ �� @ & �& �g �& @ �� 0 ( ,' �g � '' @ �� ` * �' `h ( �h ( @ P� � - F( �i �( �i � �( @ �� 0 0 �( @j �( Pj ) `j : .) �j , [) �j / �) k 2 �) @k U �) @ (� x 8 �) �k �)...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/verilated_dpi.d

- `kind`: d
- `size_bytes`: 1045
- `line_count`: 13
- `sha256`: d2695c12dc3488c9c6d7ab585fb25c5e8ffff08118af9799ec552431e3c13361
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=1045 bytes; lines=13; markers=<none>; tail=verilated_dpi.o: \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_dpi.cpp \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilatedos.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/veri...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/verilated_dpi.o

- `kind`: o
- `size_bytes`: 76656
- `line_count`: 160
- `sha256`: c24b89ac96dd0b76fa2f5bfcc2e8ce91840889f90668dc8b0aa9e03b3bef413a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=76656 bytes; lines=160; markers=<none>; tail=\�f D H�D$ �� H��L��D�H D�@ � � � H�D$ E1ɉ� H��L��D�@ � �1ɺ����H��L��� � @ H� H� �� H�= � H� � ����H� H� �� H�= � ������ ��E1�E1�� � A��E1ɉѺ � E��A�ȉѺ � U��SH��H��XH�T$0H�L$8L�D$@dH� %( H�D$ 1�H�� �� H� �:)��� �� H�D$p� $ H�D$ H�D$ H�D$ H�B H+B H�� �� tb��...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/verilated_threads.d

- `kind`: d
- `size_bytes`: 627
- `line_count`: 8
- `sha256`: f1af5b872b4786ff32aa87b3a45ec7b5f541ce234b7cf2029669234f5597de2c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: d evidence; size=627 bytes; lines=8; markers=<none>; tail=verilated_threads.o: \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilated_threads.cpp \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include/verilatedos.h \ /home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/incl...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build/obj_guard/verilated_threads.o

- `kind`: o
- `size_bytes`: 72872
- `line_count`: 90
- `sha256`: 300c7a5825267a9bb6631ce853f87b2277052b78cd9ee8ab671c928d0fb6706d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: o evidence; size=72872 bytes; lines=90; markers=<none>; tail=]A\A]A^A_�f D H�������� H��H� $� H� $H��H ��f D H��L��L� $� H��M�� 9H�u L��H� $L)�� H� $�H�� r�H�������� H9�H��H F�H�� �H�<$L��L��H�D$ � H�L$ �H�������� H9�H G�H� � �Y���H�= � ATI��USH���( � E�$$H��H��D�` D��� H��t1� H�K H��tCH��A� � H�C( H��L��H��[]A\�f�H�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/final-rerun.log

- `kind`: log
- `size_bytes`: 11151
- `line_count`: 35
- `sha256`: 07931b577cb51cd79ded5b46add9b1b3655e41bc997ebb5dcb5884112e3adc63
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__"]}
- `summary`: log evidence; size=11151 bytes; lines=35; symbolic=__0__; tail=[axi-dpi-sized] build real AxiDpiSlave with instrumented DPI callbacks make: Entering directory '/tmp/ysyx-axi-dpi-sized-final/obj_axi' g++ -I. -MMD -I/home/lyg/PA/ysyx-workbench/oss-cad-suite/share/verilator/include -I/home/lyg/PA/ysyx-workbench/oss-cad-su...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/run.log

- `kind`: log
- `size_bytes`: 2168
- `line_count`: 23
- `sha256`: 22852c71f75cfef78d0d2bf8d491f03f9e0d8316adc6f70b10c05700aa4b6958
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=2168 bytes; lines=23; markers=<none>; tail=Script started on 2026-07-13 00:37:03+08:00 [COMMAND="AXI_DPI_SIZED_BUILD_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/build npc/rv64/testbench/scripts/run_axi_dpi_sized.sh" <not executed on...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-current/summary.md

- `kind`: md
- `size_bytes`: 1587
- `line_count`: 35
- `sha256`: fa97526e5bd1d18ea5d8306f1d5cfd539ac4f8048a7419142da7d269b896d857
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: md evidence; size=1587 bytes; lines=35; PASS=2; tail=# IFU-ACCESS-G1 sized DPI dynamic evidence - public command: `make -C npc/rv64/testbench axi-dpi-sized` - exact captured command: `AXI_DPI_SIZED_BUILD_DIR=/home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/axi-dpi-sized-cur...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/bus-firewall-red-summary.md

- `kind`: md
- `size_bytes`: 3020
- `line_count`: 76
- `sha256`: 715104e3e767c118a37a079fc1579e0ef1b380e382bec0a2882af002eb9501d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 18, "PASS": 2}
- `summary`: md evidence; size=3020 bytes; lines=76; FAIL=18; PASS=2; tail=# IFU-ACCESS-G1 bus/firewall RED summary - base: `b1b1156db` - production RTL changed by this worker: **no** - test-only files: - `npc/rv64/testbench/tests/tb_ooo_fetch_axi_access_attrs.sv` - `npc/rv64/testbench/tests/tb_axi_exec_firewall.sv` - `npc/rv64/te...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/am-cpu-tests.log

- `kind`: log
- `size_bytes`: 375615
- `line_count`: 4677
- `sha256`: c557e1ebfdaf417963acf5e21ec0f36c411158c751a4aeafb6a94b758f18b847
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"GOOD_TRAP": 20}
- `summary`: log evidence; size=375615 bytes; lines=4677; GOOD_TRAP=20; tail=riscv64-npc] make[2]: Leaving directory '/home/lyg/PA/ysyx-workbench/abstract-machine/am' make[2]: Entering directory '/home/lyg/PA/ysyx-workbench/abstract-machine/klib' # Building klib-archive [riscv64-npc] make[2]: Leaving directory '/home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/npc-build.log

- `kind`: log
- `size_bytes`: 57498
- `line_count`: 75
- `sha256`: 54fba64c80d3bb2be3f74f0e0a66cf65c3cf6de890a27173ff360680c47189e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"symbolic": ["__0__", "__1__", "__2__", "__3__"]}
- `summary`: log evidence; size=57498 bytes; lines=75; symbolic=__0__,__1__,__2__,__3__; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64' verilator -MMD --cc --exe -O3 --x-assign fast --x-initial fast --assert -Wall -Wno-DECLFILENAME -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-UNUSEDSIGNAL -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-breakpoint.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 759bacf90a27050b888263f901fd5eb0ffa9c3e8b10d9c2c1add856d31c28392
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-csr.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 4
- `sha256`: 64ea22733c1c648d458ed72ca058e8e6cab07bf1bb3a405c30194b124d72ea43
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-illegal.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: fe618512fc09c6bec94ec603c2d4669b6f9225895d1018c00296d4ae648e9453
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-instret_overflow.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c7eb752ddf7df2836c15e057636b2b3b066bbe61020cfa1fcb7667044ba4fb74
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-ld-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 10
- `sha256`: c44e62773c367801944447046f471368c167a7b46cc18ff61e89ced9b1e10b45
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-lh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 0a625bdb1bde894e591b08910e9c522dae78cacf6f215057e5084ebb7215469f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-lw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 81a2d0f7543c87aab91ea4ba7f6df69cb54772b8b02fc1970baaa2dec4813138
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-ma_addr.bin

- `kind`: bin
- `size_bytes`: 8768
- `line_count`: 11
- `sha256`: 43aba4a5ed598e42eafa14d04575df2738a9dc1b2262e599788408accf523041
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8768 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% �s 0�" �...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 6
- `sha256`: 23128cb88a441f0ec5b0aa92e3ff235468a97a94e292d35d9092ba02c0cd6d75
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-mcsr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c8ab2c5fbb9cf529518ebf007812028ad1dc524efde5bf2edfaa20c2b8a3df6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-pmpaddr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5c82f4f85902b25a1496ffba37f4338b26a971da939e6921985125def9242a2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: fab026d76c46c8506cb94a08cb632f2de6937d8b057204464e3e2cdc019780e3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: eb468050871ee3c797254f90c6571b5dab04bb018834af2c69265c0274a165b8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-sd-misaligned.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 4
- `sha256`: 580363d39fef7b89f9e2e386be8a7e60ac3fd56c1df679ebe3ed5de107573e9e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-sh-misaligned.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3c3de98bcf0acee9619646b0ace0b28ce19cad50d97d6323aeb3e30866219c48
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-sw-misaligned.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: e0715db1e4a9e3efd1784bbde55edb741d3ae50f551315ce987e5434a5683aa4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64mi-p-zicntr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: aeadca97e007d646ed5565e489bf1a0b805cfa321e996930effd2ad4bab21159
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-csr.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 5
- `sha256`: 2f7d31a97b4a1a8836b5b16b048e42d6d3be2d02275a1bb9e4810b27575a72f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-dirty.bin

- `kind`: bin
- `size_bytes`: 8304
- `line_count`: 4
- `sha256`: 302f824e3cbcf3b842793355d42fdc5011dfaed03e59cec2ab8d1b4831766a3f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8304 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% �s 0�...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-icache-alias.bin

- `kind`: bin
- `size_bytes`: 28848
- `line_count`: 4
- `sha256`: 4557a25ddcb7abec27c88269b480cb0d7ec7fa64305725d29d8d3c0a52f7dada
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=28848 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �r �� �s�R0sPDt�r ����s�R0sP �r �� �s�R0� ��R ����s� ;� � s� :sP@0�r �� �s�R0sP 0sP00� �r �� �s�R0 � c\ � � � � s �r ��B�c� s�R �� ��� s�"0sP 07% �s 0�r...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-ma_fetch.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 4f38f4a5a44b94c3317295c23666c5c5d6eb5d5aa6978b7de5509ec65f3ae17c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-sbreak.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a27651d09a02b29a03a577555aa3571f8196280aa72cfd8baf0f3fd7b8778ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07 �s 0 s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-scall.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: 16442ae5360eef6283fa542a660128ff90f325c6385c4f14561403282e63b9d6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64si-p-wfi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00771ff518788f921c94a744180cc11a58d4c6867a7a28e02f20735727e41927
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07 �s 0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoadd_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 40e36f29967eb4e4805ce6477ff3f3b783b42c57d705830f2472b839dfe48e55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoadd_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: ac499bd0251351f4b1e130a27056d44e45d75979cc4af96639d6acfe7c13ac23
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoand_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83526b92eb1da801ad8660b78a289d1e160b9b4c125d1c30d936ac216cf31ecb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoand_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 981f7712d80bd44562f82e9da3a41ec67699e500a43ca80bc887a014b467df84
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amomax_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5a72b7c6b753e84547cdab70ca9d7780b800c9c6f4760db2eb2064c37e65fcb6
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amomax_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 7b8c04a10dc435a2ddde3e9528ff897203351b99f92f779560651b9278d42ad7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amomaxu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: f5d3864b8101cbf257989c27910912f0825615d420e8ac6b1f19e3c5c5c1bcdc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amomaxu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 505c10ab25037803850bbc52edf18b2073ddd78b15768a6a27b1030b9f04a2c4
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amomin_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: b10fde08ed33e391d3ff5713e06fc91aaaac9d0e909f96332add44427e1168ac
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amomin_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 4851f09c3903fa24910dd59972ef663328987e6b2f62bb178cdf7b29c1f9d117
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amominu_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 5e6b8e0bdc3c2c50052ec5d43972747e350316163eb08091236fbafa8d7ca7eb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amominu_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 83740d372ffcb61e19f26331c8f5d8c533d65cffde907bb8b2c9656ceb7dee2e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: c9afab2a4030512754ec44ad51f1e8624a29613681448e5d45ded9e797a2c171
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 9754b97b64e07d958a6282a148d26f218f550e94f4e724a60878c5c567e811ed
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoswap_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 019138d4a449c94f2983d64cf02306e2a0ae07feed0ece548550806df77bafbb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoswap_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 896e94d947929333edc5b7483a3f23f39a0d13732e92d2a721c2fa607b1151f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoxor_d.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 93d5ee153afebc219fd10c90c8799b58115c27678637e10d2906c1828cbe0ce0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-amoxor_w.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: a23e3c5246e5bf6181c96e8e164fcc6ec25c8b4ae0f05f49eeebc1b9233c6708
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ua-p-lrsc.bin

- `kind`: bin
- `size_bytes`: 9344
- `line_count`: 5
- `sha256`: b934d0ff06ddb997af53c9be2710ea84278a1001f4c87a937778c1a58cef8beb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=9344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Dc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� 6s�R0sPDt�" ���5s�R0sP �" �� 5s�R0� ��R ����s� ;� � s� :sP@0�" �� 3s�R0sP 0sP00� �" �� .s�R0 � c\ � � � � s �" ��B0c� s�R �� ��� s�"0sP 0�" ��B-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uc-p-rvc.bin

- `kind`: bin
- `size_bytes`: 16496
- `line_count`: 5
- `sha256`: d11f34f3af9c0724bdb29392691fe6ec38679020d44e62de83bc6256ed1fa132
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=16496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � O ? c g s/ 4cT o @ ��S ? # ?� ? #. �o� �� � � � � � � � � � � � � � � � s%@�c �B �� �s�R0sPDt�B ����s�R0sP �B �� �s�R0� ��R ����s� ;� � s� :sP@0�B �� �s�R0sP 0sP00� �B �� �s�R0 � c\ � � � � s �B ��B�c� s�R �� ��� s�"0sP 0�B �...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8680
- `line_count`: 11
- `sha256`: b0e889ab180282b4cf5e6c57aad517ab7550809d64f0cc473d6b915a95b895f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8680 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: b5100addefba2520e1bbb51e3ce674b327cc5f6c520fc7866a9a558e4e44b35d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8880
- `line_count`: 4
- `sha256`: 0513970de2ddf14819bc8d70b2e526c18da9487a281272771b1ff12a2efb97f3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8880 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? 'c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8496
- `line_count`: 5
- `sha256`: 0ac6c2fb446436b221ab7b4cc0022dc9bb9dd8e4fd2975348876ea88d67e1d0e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8496 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9696
- `line_count`: 6
- `sha256`: 445e86b8b46053286a56e2087568d83355d4ada764ce452c00e4e4709be8f92e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=9696 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? Zc g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� Ls�R0sPDt�" ���Ks�R0sP �" �� Ks�R0� ��R ����s� ;� � s� :sP@0�" �� Is�R0sP 0sP00� �" �� 4s�R0 � c\ � � � � s �" ��BFc� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8600
- `line_count`: 8
- `sha256`: bf081a07cd10966e78a44a59916f2da5d22e1adb56dedafa44d3269aa5b90abc
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8600 bytes; lines=8; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8760
- `line_count`: 6
- `sha256`: 04df09e50d4f00cdc41abc6a91edea03e104c6d50431b97ba13a159d39551a1d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8760 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-fmin.bin

- `kind`: bin
- `size_bytes`: 9000
- `line_count`: 7
- `sha256`: 16fe340833f9d20de8929da17b51d40300445a0da83121f52f8fb162cf301d94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=9000 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�.c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP0...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 3fb88b571e6628e02017cd30299d0cbb9f4f25fda0880e6c2459fe391652b54d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-move.bin

- `kind`: bin
- `size_bytes`: 12376
- `line_count`: 15
- `sha256`: 39228c2a37a0907671708e1f7b2d9aa764eefd15563b0b0879e8ff21580827f7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=12376 bytes; lines=15; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ?� c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 ����s�R0sPDt�2 �� �s�R0sP �2 ����s�R0� ��R ����s� ;� � s� :sP@0�2 ����s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ����c� s�R �� ��� s�"0sP 07%...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8312
- `line_count`: 6
- `sha256`: 75981a7020a53723f745c100b9fc05946a2782a61b478050c0fedbfe1212e267
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8312 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ud-p-structural.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f4a62ea79e01a2943c4a1aa54ed53b92597640168f9a23752bf14dd9c3bd3f2c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fadd.bin

- `kind`: bin
- `size_bytes`: 8520
- `line_count`: 6
- `sha256`: de456b0c77d3b3e6e1acb2fedbfc6a36ee1ee8c69cf9a9f3f4d80362e3508992
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8520 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fclass.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: da0f54056f527d4bc1607f26774d685dde856fce4cf6942eff0b218bb0c27e5c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fcmp.bin

- `kind`: bin
- `size_bytes`: 8640
- `line_count`: 5
- `sha256`: 18d301b130316c7a4dd6484c5a8f892aa0231ccb59b31989ea038bef8d304294
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8640 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� s�R0sPDt�" ��� s�R0sP �" �� s�R0� ��R ����s� ;� � s� :sP@0�" �� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B c� s�R �� ��� s�"0sP 07% s 0sP0 �...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fcvt.bin

- `kind`: bin
- `size_bytes`: 8376
- `line_count`: 5
- `sha256`: d625880b74f7b97c409757846041172d5e93509cf9b79702a612170935068a5e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8376 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fcvt_w.bin

- `kind`: bin
- `size_bytes`: 9032
- `line_count`: 5
- `sha256`: fc5f80f2c1581c2a1b8dcee8fe5598cb80b1ccd878ca5c5c731127d63f250863
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=9032 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?�0c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ���"s�R0sPDt�" �� "s�R0sP �" ���!s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fdiv.bin

- `kind`: bin
- `size_bytes`: 8464
- `line_count`: 6
- `sha256`: a169bccfc06c73ee84565aab803639927d3d21b773248d67218b5c9622fde1de
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8464 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fmadd.bin

- `kind`: bin
- `size_bytes`: 8568
- `line_count`: 6
- `sha256`: ed00e3e01ff59b91cdc3824e3e2ae9ae63a1c3364e189fbf33a79194f40b5c71
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8568 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-fmin.bin

- `kind`: bin
- `size_bytes`: 8712
- `line_count`: 6
- `sha256`: a3479614997bfa55019327d587ba04f10f67dd86e114d4073385ea8bca36af1f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8712 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ��� s�R0sPDt�" �� s�R0sP �" ��� s�R0� ��R ����s� ;� � s� :sP@0�" ��� s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��� c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-ldst.bin

- `kind`: bin
- `size_bytes`: 8320
- `line_count`: 4
- `sha256`: 1aa70a8aa263a27757a3f038ee25ade6ee3189bbbc23e5617ca1ee9fb7cd80c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8320 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 07% s 0sP...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-move.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: e77d600105f5adae64cce494f6fec18c30d4f7ee19eea08d22b7e5e1f12273fb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uf-p-recoding.bin

- `kind`: bin
- `size_bytes`: 8296
- `line_count`: 4
- `sha256`: b3d139f51b82815a69dc2acd83dd16ef3e3b98927059ee1fa234bb889b892b47
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8296 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 07% s 0s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e0de399fa1191cc396b73a5a2a95af51d64d7ebbaa03dfa707b231227303883
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-addi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6aa27611ac4914609dc0bd1fc2c5348bffb0459717524f0affbd8259394dd9ca
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-addiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 73eced0e4a130e15b35aa8b5a9acb6c303caaaa1102d84fcd1d8bdba191dd1f5
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-addw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3fb84def959f1446056d6c66941da4033068109c752cffdd96a0b472a58fa79f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-and.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dc72de604bc42485e0271c7544746a72de89a570ab090bc55b203f680671cf6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-andi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8757079a76ef41dfc130617b2144c2a0fe418991befeeed1d912695b9341e51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-auipc.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 5737a743ca924512a42d40ce3e3b2dd5044b3d3221c219f4aa8c4617a1295454
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-beq.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 518cd4573367f0d382361c2707ce33b41d330608e868ed4afee028e81207dda1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-bge.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c1462b5fb4cf846b54fb69e3e94ab0dfee308c1991fa2293937c80fda1db72e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-bgeu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 66b061fd0f306e8f148bfe163c0ba5d5631335d0c30bea3bbaed4f8b0bdbc1ff
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-blt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 844f0e1f0d01a1c092ca75a06d5aa321622ed07f969ce592732b4cbf0c79d377
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-bltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8eac0b7cdff8e5ee7187e6ea44486ed76fb448c89b8b324773f7ac31bf663fad
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-bne.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fe4ea4101123b640952077d483c6f65f58819ce80577a5ebf86b67cec6a0d5c3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-fence_i.bin

- `kind`: bin
- `size_bytes`: 8328
- `line_count`: 4
- `sha256`: 001bb2441512f111a6966ec788c6a0aa6ba0833b023be3249aaf1fb336dcf51b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8328 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-jal.bin

- `kind`: bin
- `size_bytes`: 8288
- `line_count`: 4
- `sha256`: 97c289adb0a05a00ecfc5e453b799362f5c7eefeccd8de28a174a27f42379926
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8288 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-jalr.bin

- `kind`: bin
- `size_bytes`: 8344
- `line_count`: 5
- `sha256`: 1a870f25986986f0180de3fb002756ce815fa493103da6f14038f285dbd12def
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8344 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lb.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: fe5efc3cf1cb425553acee7541d20eca46c4b3d722e5cf2371b7dcbd148f92d1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lbu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4213656b18ac462e7ec26d3792f43f0b7343d516ff1de66e67d8ee3ac5050ff9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-ld.bin

- `kind`: bin
- `size_bytes`: 8352
- `line_count`: 4
- `sha256`: 7fb6be2f482e67be0e3af4ed092baded2c49edefc7c017a648a37165372ccadb
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8352 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-ld_st.bin

- `kind`: bin
- `size_bytes`: 12464
- `line_count`: 12
- `sha256`: 72cb9b77ea434075d99cb03ab327c7dcd17cf3f8ff6d52341aaf52f0f47a4dce
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=12464 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� �s�R0sPDt�2 ����s�R0sP �2 �� �s�R0� ��R ����s� ;� � s� :sP@0�2 �� �s�R0sP 0sP00� �2 �� �s�R0 � c\ � � � � s �2 ��B�c� s�R �� ��� s�"0sP 0�2 �...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lh.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 341466d1395a140faab6a5814b30ab4f83c0551f80d0d6671c0ef76683ec725b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lhu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 4df1d87d56d9353beaba36442afc43b86b3fd655120607d94b70d22963bdd555
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lui.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 56a456dcc5e9f2ea4c77cc466e720ea79a6c17e01aa529e7125b33546f13e037
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lw.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 5
- `sha256`: 36a994d5c817f93d63d3af87a26dba769f7275c41ac5503e6e8afde59108b5fe
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-lwu.bin

- `kind`: bin
- `size_bytes`: 8336
- `line_count`: 4
- `sha256`: ff0a91d6b257411f081481518152421d17cf1eacae6ee9970615991c5ba05889
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8336 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-ma_data.bin

- `kind`: bin
- `size_bytes`: 12768
- `line_count`: 30
- `sha256`: 13510f7775f6b00ec9758047eba52b9762391479124eab48c0b70e2ebb9f374a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=12768 bytes; lines=30; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � ? ? c g s/ 4cT o @ ��S / # ?� / #. �o� �� � � � � � � � � � � � � � � � s%@�c �2 �� s�R0sPDt�2 ��� s�R0sP �2 �� s�R0� ��R ����s� ;� � s� :sP@0�2 �� s�R0sP 0sP00� �2 �� s�R0 � c\ � � � � s �2 ��B c� s�R �� ��� s�"0sP 0�2 ��B s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-or.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 78225c1a4ebbacbbec69375927f62aa3151aec634f201e25c3adbbcc59e97a93
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-ori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0919e2c9836799768872805903f4f273bf3a6ca54bfb787726a7a9fe52a1a17e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sb.bin

- `kind`: bin
- `size_bytes`: 8392
- `line_count`: 4
- `sha256`: aea94b4b941d5a381806f6d6ab89ec571a2358eb7ac1e5a5209ce6579ca4adee
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8392 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sd.bin

- `kind`: bin
- `size_bytes`: 8456
- `line_count`: 12
- `sha256`: a6242e8c759d72402ec92b7359c91e1985c29f08d9603a580d8dfa2c6bb5d07f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8456 bytes; lines=12; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sh.bin

- `kind`: bin
- `size_bytes`: 8408
- `line_count`: 9
- `sha256`: c02250cb78530fb2fa56a57e05c5c22df5dcdb4b18c1d81f6eb84f0076f5f7ec
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8408 bytes; lines=9; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-simple.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: caae9f5816f6ff2f9a90cfb68eb3e2cedbd701e0fbcb30cf8171df39a0fa97c0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sll.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 18becf549a748446c93404fc8765a111595178cf4cc14195a0f31d18af131b32
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-slli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: fbfa31452bd8b73e1f436cdf83ab84d265647ae633ef41c57f6eeec474a06b94
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-slliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 7d394b5a2d0dc7339db3c2253a8b0e8d732a475b925ff8abcadb08b7e1f5879b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sllw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ddfa5d1ebc4a0b4a327168239aef60b0ed3e2fd2af3bb3d70c95ad80e3379d30
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-slt.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ed0e65bf51d7fc4cf676ffaaab798796ea3533d8d640629ab3422a5baed9fac9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-slti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e33686b1f0a37a1b98cb1982517ef6cdb48a8074b9abe0ed2a750f95b2235e2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sltiu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 9858d08fce765bb22f43a40258c2444346e42baa10b2be7b687609654812f39d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sltu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: da9c47137f6cb7dd35dc660ad6c7125a64b29ea28efeee1ff7f2f34f04f4d86d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sra.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8f6a33066b58bb8677937fff5f2bb8f0c0bbe09492adfbba1b91446838c37a5a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-srai.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 58932bf914fd2c79288c5c2879669571b2562c4865b5009fc38af52ebf118c3e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sraiw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: c57e317cdf106796b258c1fdf2bfd8565ffb40d68277c4bf32993d6d43c39bc3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sraw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b9b9e8362cc9b690e492d19e6991671f1fecd4eb423d4b5db55df69260726012
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-srl.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31177e38a90aef3df4d0156bc763fcfb14e6eb91813dc3602cdd026f0641c8b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-srli.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0e3348cf25e9833f3894b5acf831b92064825f05f57d98f3a681c69df1b39428
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-srliw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e8fe166c0b04a7ef084a82c33809b4aeb0d45574dc4da7560bb1ea7e998ef9a3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-srlw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e912ffc7f56ad5844b242c2a0e8c79909ed0a3140ffccd8b29d9038be79d02a1
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-st_ld.bin

- `kind`: bin
- `size_bytes`: 8368
- `line_count`: 10
- `sha256`: e61f1fad19e0cee7c85d55e1a86920a692ee499a95ccdbd4fd211e148f61c357
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8368 bytes; lines=10; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ? c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" �� �s�R0sPDt�" ����s�R0sP �" �� �s�R0� ��R ����s� ;� � s� :sP@0�" �� �s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ��B�c� s�R �� ��� s�"0sP 0�" ��B�s...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sub.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 3d112840acb08e32ef43ef5bd37d5eed92261da52a866ef7d1229afc028850dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-subw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b1da1b356666b94e50970e427b03b68eb46edb0514a062f27a935e356b77180e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-sw.bin

- `kind`: bin
- `size_bytes`: 8424
- `line_count`: 17
- `sha256`: eb76e441433952d6781f3525265b31c213532d4d418844ccc0c8ee04c00cc679
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8424 bytes; lines=17; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-xor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b606a64937436d5c4f4f074785589a8afd427a603d4611cc1e5e953cfee64f96
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64ui-p-xori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 2a1d90b9a3c60dc7e7d231e01a05c0a1d8d3ca986e0c2f602b617bc9c5d3278d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-div.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 44f3840869e0cc074db1ed335c932519ccbe34f1d866807cf86ffb0743c953a9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-divu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 672440b891c867bdaabdb9c9eaca0dbe10d4a04794829edbbc5c130fdf85897b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-divuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: a8d5711ccf23018c73208a0f422dbb7c1e905e738102d4ec7c2eed2dba9a217d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-divw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: bb0d9bb0a24016c4cb11adcd4071e8bfa516605d0f5860e2ca7a198e7b23788e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-mul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 01f2bbace777f073716b8cc5091a3e863c6f3ccff53f89b23aa00ba6696f8ded
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-mulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: fc6fd7c53853a5e5d14990bb6a3421d00530c06b778490af40b8541bcd7b76e8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-mulhsu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f6983457179bd80659fd1afbb9024cee384b3ada4996b262b57faeb49a85d2ae
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-mulhu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: f0438bbeeb21c46bb99761757f0413bccc69e6e5f33bb0a01d30e57f72c268f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-mulw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 11
- `sha256`: 5c7d95105555210e28b07d58c81048f6f78e338e2bd8161c88a8cec0535bd956
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=11; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-rem.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: e82f781f5b19120186f630daa68af1dc202746ea31852f1c808d0eb6383c9326
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-remu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5e6f1723551a16bd7868daffbbe9817055f707d43374a7eab9f6cd5e80d0ed51
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-remuw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f4e559c92755434d1e876748d7c9199e15d419a2c73fd4616b7fa9ea4b09f9f9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64um-p-remw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: cab5034a4b8b98c4420e369d0aa35d0f35271d5efed7e159bd0a027b4b4f8f24
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0aa918cab4e34388264e8098188820d738f44369eb5829ad847a65210809fe4f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-sh1add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4188c2ad410b55bd716f4c2b5297c5a87e04b19e117b7cd69de1bceb0d630bb7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-sh1add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f5ff38ec3295945c11f73a714a2f55791b2310d4822bc9cf01e4e3fdb018705a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-sh2add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1bd567c563aa3412339a468b45424a817f9e5a2bb6bee85029b0773e571cb4e7
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-sh2add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 0074b1b96e82aac4d68087d00870690e364fa5ef58194df4a93d3b6bc321f2e9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-sh3add.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4a9fa44ae324c163c502187fbd91ab065b1a1bdc260364526e6545a00e80566e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-sh3add_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: ae8f68b876fefa498f3a6844f0fb8f0f4aa1b8abd5d9efbc26ab34cdd640f23a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzba-p-slli_uw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 7
- `sha256`: 15b0f47a599f0f0c0d0aaae5e5af1ff928f678235cedd081876bad8a4fb8e32f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=7; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-andn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f19811cbb497c05b5d6e5826225333ae8478bd04946ebc2a9133a70200e593fd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-clz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6ba3a3bc33691afa8d79aedd4d97a9f4c6a16f77b4f073f24dbe96808612be88
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-clzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 33408c5db8a984c06ddb78bc3eddde3d8c4dc1d1b0cabfca2336d557c5ae1813
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-cpop.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 54d9c69097cc7b5c6d74ece7fdfcca78f5b4c47197fb2033da8b8c995d2fbb6d
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-cpopw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d38e270e6f87084436a7d4d3dc269712e1f051d578c3f04e1f07ddc48156b29e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-ctz.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 93c879bd6d9e8052df6c2347e190adf55af18bb6b038e6d5f2c3d471faedbce3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-ctzw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 6b828c243d4c31420d1653b451e86d6828e3ed6f7223500e72d8cf71acb65de0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-max.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 6194cb4ce3d87cb3b42f08c42303d9d17be9d40e58fa3fbf0f6498667676db83
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-maxu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e6e47bd13db350550048d36260bdf5c54cf265ccf628201a972cf84aa47e6d55
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-min.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: 1dce3122d4f7af347afe0704cd2287d2e841d95a33745018704ef4c34c53791c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-minu.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 42
- `sha256`: e42fb382e38e338157a7a09f0af61b81e1adb55fce8c0238fbc18a1f9f854c6c
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=42; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-orc_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: e747140fda5bf4c2a9c7c61baaf50e98f11d9a0868de2929226a73897c24d89a
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-orn.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 1dc85c483efa1dd9ae3caa4ac8b83652a9d703b17e19200432dc03b7344f7860
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-rev8.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 6
- `sha256`: 8323caa090d7bef716030ff48c874bb610e4bcdafa9f40650b67b65b5df587f2
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=6; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-rol.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: b30437b4efdc38041fa7f3359789077de3c4b0354cffb8e557ea373cb3d12fb0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-rolw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 4ea26f5aa28665049b718ca9c205a14211eb22a23d6ade4abced5e6f86d19040
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-ror.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 00e3f4989872295d4cc789ca5157c7d3f4e79f960ae64dc5a4a9f91a8b142b02
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-rori.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: dedf00a9bb2ad52ba976e88740212cffdb2b38241368d634ec25cc88c4e66b1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-roriw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: d0eab7105f35eb9f734d2ec7d0b324b75837d4c2d0945ce6f7ac3bec01571f7b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-rorw.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 033a1c7ae08aa96a008e3bd79de503629bf9ee854e6ac95af66a4d47e6a72115
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-sext_b.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5eaaaa6053c3f1df1397b1efd948ca59a029e8d4cb9e7e109017e12aa93ff1f8
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-sext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: f65dd47398f516e100712d6007e634099fcc8e73eeb780ce4557fa1f376d5656
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-xnor.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 5c9520fd4b5b92c89d63a8125af88be702afbf8361042b894ec8fb96668eb9b0
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbb-p-zext_h.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: b7684eda4bb87bb88bd76be1a5b41c4799d2a21d94881327ff419326b612901b
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbc-p-clmul.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: d144029621d295b0c2ad5c1dfc2dcfd2162695e8c1605400060e8e9dec2797dd
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbc-p-clmulh.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 38
- `sha256`: d14fdd7c58a57a0035f5ca09c2df530c963671bd1ee1cbef9584b52755637731
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=38; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbc-p-clmulr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 37
- `sha256`: a9215a3d0608c6d4f3d495d947fc4f808241ad42d99292913dd9d3d75bf71e1e
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=37; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-bclr.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: f8d5a36e757e695191986e5601ab988354c85febedc4e76cc78c25fb0609392f
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-bclri.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 37d0418280baac2d769f3145216ec157e06966460815bf5740f2f22f6e306f42
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-bext.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: c3b71a5fb246eee19e888009d61837fcf6b2c449d2fdb8af289f60d927e135c9
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-bexti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 793fe375c8e13a7b1c7b5e6f4af73049e37cc664e477bde2cc7555985a92d4db
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-binv.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 8471d3e0a7b4a987ad22ef20b34cecb76d725f29f9c8a5a284e34c7a1032c894
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-binvi.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 5
- `sha256`: 8974fed3cb7c502d42aca753d05044e2db6f8bbd3243a23c4377d82bc5977b39
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=5; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-bset.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 31e4ba324b166112ff91fd8e518c314831ff07fefbda4bb1e90f60cc7fbe30d3
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-bin/rv64uzbs-p-bseti.bin

- `kind`: bin
- `size_bytes`: 8280
- `line_count`: 4
- `sha256`: 937f8e935000f904dff522ad07d3ccc9f029b6cd2cfc072ef92ff2cefff37c97
- `encoding`: binary-or-non-utf8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: bin evidence; size=8280 bytes; lines=4; markers=<none>; tail=o @ s/ 4� � c � � � c � � � c � / ?� c g s/ 4cT o @ ��S # ?� #. �o� �� � � � � � � � � � � � � � � � s%@�c �" ����s�R0sPDt�" �� �s�R0sP �" ����s�R0� ��R ����s� ;� � s� :sP@0�" ����s�R0sP 0sP00� �" �� �s�R0 � c\ � � � � s �" ����c� s�R �� ��� s�"0sP 0�" ����...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 4150f7116a5d1ad9544d847f718a27dea539caa5cba32d9db43c0dd3a320cd58
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 23ece6fcfa411fe3e9ac8aa2d73a60054e39446808a1551d3feb2c97cc438b97
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 23d3611c19094402928bdffe805fa8532d82fd77c90420ad9dcbbf546b86a250
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 654
- `line_count`: 4
- `sha256`: d235961f7c7c03e9da495ec9a846dad59fd750a8fd31c7bb767a01e623f0b31c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=654 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 8474a0af82ef8d14cf5dbc04104d884ee96562d91ed90a22bc87d19350c99f12
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 6d07c6e4fe8c1fd8b3f44f7dce5500299893ea370f733c6c7e01c48e4b288072
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: e51c2a9f92c0506b9df3f6c48a301a8889b7ac5b3931ac4dcba1a9b2fc2721d4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: d5963171dedae952ba273fd6c4b0ef70b6f28a179dafb069832f8f662f963179
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 99b16ce02f59f4a136bb747ddfd6f2348748038875ad51e6bb0192e691402068
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 62379170ad5bb6cc61c4b4dc0ff7e91a9fdde586f642c6ccaee4c80eeb1f3d62
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 7b980a18a7a0c0f1265bd180a9ad1db93e8c6cab0d658640d820cb92a3eb9b49
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 9099de3acbff7f1453867efa55acba173e3f713d751107e9406a5e76a42fea3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cf030de16f0944357c4675d1bcd66e4c9ff80e240125f9290aadda6d928d2760
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: c4a66350fe2e3da52898d8665d719115bc88db0ef8aa4e2c93e8de5ed2e29de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: a22f5126c64613ddf6fd55ea6331fe76d4a0a0a982cbabc5cdd66da0ebc03e51
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 642
- `line_count`: 4
- `sha256`: 237937babe46f052aa4697ccfa94dd5d62fe6e9c4f6ba2ed91df161b8bae8989
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=642 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3c5cb1679bbbbdb5587f3c2e0afb816204ec847dee3ec85268b44979b7dc56cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: c2afda182606f2e0a7e63e3474d5921c3aa8471978d516a44873e5c06b70a2ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 107d85d30c6e216d76cd6b59c73db64f75028be38ce1ee747124bff1d6ec90c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 1daaf37379469b4eaf41802fa680ed3c8c7bd6ce953df9c84d4915f239d4d641
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3b729d2c2d818c320db5ca4afe7a1f1348264eb2ffe0eba7ae1049417f20391c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 3fb8dc5558e0ec98c7af988859a3cd3baca8da9aea3728df9d7cc85c7fd8bf77
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 00b93d77799a70c2e3b84e597ee4c06a7fcea19dce219d84d8aee420edc53bdd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 8e0c3b0be49d00964fde252f04e3087506e0de98cceb587a5ab3066efb41ef58
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 8c3e263f822d9493f64d701a38ac492559000c26b2fbd36e16275bc0d7af6133
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cba9ba738cde63a77d5c3d5cd023e8ce7f5250b653f82215299e24ac1fc5bb1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 0328e04bd6751044f2bd0b2aa2c8ae4098595d854a2bab4e0f4d8f31924498fb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5a2096b964cc3c4ccb85fb6422beafb59a7fea77f0a83a0daff1fdd71ab70c51
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a07f7b8e687c417e2fca93ac54ce55f31de2e25c1f1234003f811ffb88d675a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6568d6c0244091a6278fa44910f8bd47972c56bb87c243cbdcf38aca36f8609f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 873ea4506769dc08b7ccdfc25f658ee20b49c88dd6269882f34c9868941d0fe5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 730fb547874b909ed298899deddc4f5006b875500ae69a7125eb84b8b8419fbd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 5f1da7b7685ffbb8f1df17a49f6176eed3e466595dc4be63d21db337556f0fde
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 007cb416438f4011fd1eb1a0a64fb2a5b0a9f829987d1cc6b77889ce81db4da3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c790f9b5363f0944cbbdefdefe832dbdfbd0905b5d7fbfc1c212553707ea959d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: b794309a130131c93f53f9c2c7cccd333f5961ff23b355e35b7e18328a8bb79c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0b0bc9ea27d137d7530fa5b590dc0cd867a280a51abf5e961bb21233fef947f7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef1f7ce9005d8abf5c638fc4c4b7c52850905d30871b0c06af4e25d6f50c5d2b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 00a4b7cabcc05fb508e5b85d818e60b21afaf3c0d90906549c39e7b435a207b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0f0324a67bfc938ac65b2f337e6529fcf4c61f2239b507ce4c4738e3038868ba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 967200f90c7f95274785a11a981b7577f2c89ecac49d99d8357084bfa9530fe8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: a71ae56c51f66ba8e8394de4e3742e9e5a1476c8c4ad1e1dbb7b0eb0253b01af
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 7ced092784e1e066c358c21ab7c0bb8fa17e90a5d2e8064e33834cd5a9f8d5c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 49672e6a492177ddb4852bc8c4f9eb459c99981f16b7167a58ee246f3d3560a3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b8f160baeb0780d297b43d20a490d3ec215aae57214016c154628ec4aba65919
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 6d75f76b0a20c302c2cd270ad0a555897a69d4684cf64817da06b83bc497b141
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0ee1f9ee92625d8c7212efee27ebd6742653c72a1d316547fe1101208d12a448
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: d82738bf4fe675ea1dadcd90207376479a804037b2fbe5770af814339adcacb0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: b460b639e7987f4246460d4abbc73ec7f43d5678bbd40bfbb4a04c858af885d1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1e53949864fee289560e6da88cdde146cad2303ce21bcb740f5118fb92f11657
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 845933e27bbbccb8cf08c5fa981f20aaf25aec0a8cc40b0e75100fa1baeaba3a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6ee1c4d5ffca1b6703014391be5bfe2880e7f0ba53032a4861f89d7edb89a881
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3662c87f35aa3075cb1d1682e3405c652974dad11340c1d2ee93c59e18e424b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1a4f7ae7876b53b2a9e745359c7ce424143c4f1c8e36a7d1a40233054632e134
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: f7f0d523f2079e39e84c078e9c904694708d7b9997870108f27980839a061daa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: 24ca975dfcf0ad126bbf9ab832cd765d4b6c7080967d08d5d92c9574aa5e022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6d5bd6053f47f7f3200da160de5322980668aaeb2a0216f7a789d9ae8a05dbc3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bd5a47bf7499eab16c975bbecd23d268d8639961ee99d40d7bb885bc9297ace7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a767231264c5337fbc42251f50c27a3dc3569fcfc0dbd870bc0539027ad77420
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b793bf2f868c8c67694a1e18991421e5032a03faa6e297707735529b300edd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4475c4dd36430bb373b9d6c89e04d49075c05830d2aa2329b49549ec44d55afe
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 6765e03cadb0542141bc767fa78d8bf65090367ad901e7d89a731ba422401060
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: af7e66cdf7df5410af2f8767d48c68c9d06973b161e0c72ca4c3a9d56aead27a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 1f3d30184b00b3fc3e777dbdd79338f2ebdcaa5191df5c3b32f57952f537592b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0175e048b8801be943d6f6bcd9ed5c391c086e29bb0a8cf71ecbd21e07315ec9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 0d085575ddb0975419a6ae9c0db8e688bc789de6b2e9d0b8ca19b731fa14f136
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: fccd62e832c8b5ca7f416d4e3bf69178bef407b3e6ec77971ce46143e7b8772c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: bf4a1c4392408d00d665c481fee726d8f04794c9540d504173c60c99f0de5fd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 00554cd110058397ada07abe08992a7d649b486f8b37eb14f5aba9f4f4419807
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: cd7d9a20602103ef97d2ab0ba967d203a9cf3bd9397d12fa870921a636bcce11
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e37cdb95143e1c0b66983c3e1836af7a2f0588aef9d176a20da98991bbff3a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 1441654b5a3e4735bc996771bba27917280299bbfce7d249bc30a8d4faca7775
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 37bf32135a0c7533b59be4a13f20bb9b6c0cc5870f70b850ce3d9e5d78bf15d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: fb24b356088f3b9e03c2f1216b55c87eebd498184414989895d1f7bb4f4f67d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: ab290101f3b35f371ea890e4d240cabd0aff55635db27a67c3821c87c0a8ecd5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e660e20802dfbbc18a6a0a43f18fe7fa29cd0163f17bf2124f0aa409482b4661
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: b01185880ae1d65b4bbc7092cd18fc8dab521dc71d5f5475403ffac74be58828
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: fa4dafcbbc42d2a41237aee6272c5fed3ab2e23e8d2ad749273276d53a64f3f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a3319d2217a3a5406a7d1b704ba524b9b2858b9830178039199a61da0867304c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 0981f78934754aebb0621d478980da4af1f933e0b8e651306fdd470152afc879
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e3c9c563bb0ba1c1f742df97faa61a7b93463789cad9a778f3a61f6237ac4cb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a5007b648c70a1f48077cae2aac48be9baca54af7bb9631008c7716ee40f49f1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 27f90dd10412d4e42449d5fa1c26071b628ff60c2fb45cdcab755867ce37cc15
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: f341419ab08fe5641dd482cbca74a7f62b80818b60cd788e0cbe3d6e8f320a70
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5070951d58314243d4c6cdf9bc5da501263f59b6b7808baf2c634a72030591ab
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: b26d73cbed3a43e17a30b50ee9adc454d9d1d1568ad91cebf862f5ff8264ee39
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a2e07d1b0c078a19bfffa7a46e075741d465a67f35ee42d4e0ae78c12f3567e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 6f85258e91e5ef00797b106e4490e18f40cc8de5e662e3b61a7d04d27c3c0b87
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 4b6e9bf2ffad3723fc9ef8a852d451389bdd8a67a41fe180669269d09015e0dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3615088aa13b78b76e6552f775969dcad5dd1ac91c04976b788160bd2c33546e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 3622b211813265a8b8b3f703e3f7b29ffb2ab1db6161473eb808181499bfb470
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a7a5d49640ece17b6679ff05a14884627e9a81f9467664bfbf506c5369159d00
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 84f532fb2abd6bf16f76318c818dd29db9c87d4a48fb1185c509250b88ca45f8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: aabf14990dbf06cb1d2dc54cfa7fcedbe6d119b5cf633c5aa47000b829ce5c90
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 3b0b3050ca401f6168e3e8bd36bb6f1b1551cffd70985596fd90e9dc7179f1cd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 09ba0ec29a161fc024752db288762e2a2dc786ebefeb83ac1943646d3e77aceb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: e608d7da0ab32aae59884208b96016441e08af82f690aaa8775430c04b1b0513
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 96676a6bc4583fd066d3f5b6732faf68decf3316da72d9964d4414f146d89c4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: d6ba81fc9436b57fb3c022f236bc0d0f75ea2f6d88d18bfa6d02e65b2a6e5a61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: e30a9334da334d2987ea90551486d190c02d203c68db43121c4b0a6577b57aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: a909a846c5da7aa73e4e190a23c55f73622f31069380308f9859f7aeaaf6adb6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 0de5aa49cd552f9037c02a1d9f71c43fca0326e97eba7367841552da5a36b7e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: e86a03d1eee762da10beeeff9017e7aa21bdc89e52aedf75758e1626e612423c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 451fbaa2285cdfdef11a19a2b300a19416c253723218c1cb4286677041bfeec1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ff6c4924050a8d2312dfd3d52d25f98dd4f4ccc83ca0ccefb05988935683f199
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: a65a7072e4fa3bc33902a11a37c29b5b66a5b363bbd7c9eebc4d4bd8250fbd20
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: fa6d3312cdbc106fea127aa50320b4b9d75d36dabfa72c2725671809f747ea1d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b1cc518847e474d4242753bec4c412b386b271fa72f04361b934d5854b441c57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 8cf271ebd3e57c216b719a9ba103bbab71bf37e0d042e82e89546353f6ce733f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 5782dd896faf92bb54d27eabfc7e0762c47de862010f1a8cc1265563ba7e6b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: bd3bfaddab8a0f3dfbbc5308bc0b4fffe992285d592ad6ce7235fdd1b16c74c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: eaf1635de91fcecc7e5da9691d59243f425b6ce1a9c3eb48e24c3c3091539611
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 3e89a77520efd23aeeaf677f88dfd143d94d41ae999fb9604154e2369730bd84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 6f13e38a07b69ee9aeff19dc21ab6df83d46219bbd0b5bf516405d00871170cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4f9265cea9e2a9bbe825e8600096825006515cc777f29dfead027ac81b17309b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 51b30404c6be48d3f66a6c3c21c1e745c60e15ddd1f38b5e83f2930ffadaaefa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: a20f3f6f225e7ef3f270ead0491c1e538339213100ec87f763876a236f49f09d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 59e9ea63634c4d928fd77a06d8c6b6bbd8208a909b62b10c39a32eef18140fe3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 598
- `line_count`: 4
- `sha256`: 9d11779e27f2783c179924e051ab37f40151f22e6620f357507d0dc0ef99d585
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=598 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: 5336fe15cd08aea447556672936e9514439e0635735f07c68c5d1411dda8de58
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 057fea903066bbf822c036d4e171250a0b2ee8cc92c68fb5044f97f5801ed0d8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-div.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cea01dfef4f7fcff2ec964f981c810b099d6a4d86654db064a36628884f016a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 4dc7072115d960aa8300af86124cca7235fed8ee1d1d4f21f40d93987e98effb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 2743691f6c2ed8c0b3e0f263c16783c5a5229697d325fc93f28672a80887f328
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 110b9bf43a73208dcee4a0c3636dd1e890fe37bdce41dc997fc7ceb64270e17b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: b6d4b55af1f3813c864f3431d70a360ae3555d97be63c07346d6608f3af5fbb1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 424c24e486afe4fa9c0b784ddaa94ad0bd7840f3f7b87f2300dadaef6bdf226b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 38c06d60f9780ccf3e2f1a2dda4e66108ba279931ddbf642fb0a2f3684d49630
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: e0e4bcd868b289f52f2ed975bf120ce5c29335707b219d5c6f054953187c7ff9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: ad69dd61b6cde5c9f19a3f3fc3a4a630d86f1c7d5cff670acd3cc5a59c15a136
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 602
- `line_count`: 4
- `sha256`: cb8173748221ae03516aa015301989a03cb3924666db77335399e869ba6f0de7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=602 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: f479540091b7c3332f2f794ba57db1fa8389a46dba1f7aceca95a3a5f4883ac0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 610
- `line_count`: 4
- `sha256`: 4d2a7d55334ad3c556b85bed0fd9edf5637fdc99ee31e1c98f77f0ff84bae11c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=610 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 606
- `line_count`: 4
- `sha256`: 9a2065d083bc656881cf722a2a3c05d88cc10e443127530043aaf500e4581d77
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=606 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p -I....

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: a026fa5d253eff4184dd901cf30bf1c53bdd1c1b5ab1ac995ea59661e0e40615
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 02f922b3f0d981c16f248c291c6b43f64e316e857d450d0bbc9b488003703b84
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 322f9f878cb5140d7e231b0dca073218ed94f483b764c6bc95a19669aa9d036a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 98a380dfbbda7c4f60e919fb37deab62b59fbdee50bc0305052c3a87a2ca773f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 6961da3c9cea0c1d34a7d9beb25e11edfa50432062b2c93b957af1ac6a08be4d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c453a3c99855914e6a453d01010988139dec39724735abf33a8a9b13f31beac8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 638
- `line_count`: 4
- `sha256`: 77c6559fcdae003733a1851a52177f59056172dd88cacd63f28486af064be33d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=638 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 630
- `line_count`: 4
- `sha256`: ce319d1480b3339d0d171885035f70880449213a1272e8a5acb6367131b586e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=630 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zba -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 25976894038694d165b598add4b248dd2d186ae60b8def7bef7fd21db4d92a29
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 15c814ac15613585f9fd7a18c5ce385d98a3063c5b374eee71a78673574ce007
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 4bed0769173fdb2a5b2371315a9a4eaefd032b8f7bf71ccf3c2fbddd99af9d57
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: fa5ed3b50599bda80c15eef631802895bda0d20fdc607819212573c61b188886
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 6b0dce697a03eb4aa9dadb5c6642d2e865390a4a53e821c242c93d963ce7d444
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 8340ed0ce6f2db11a63419b8398f193dd34805ab0a75b7396e6fe0c2bf2bd4b5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6ff05b640ee1d4889d33f464efacef5d37751f81d5440fd411add7520ff6ff42
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: bb035a3474d4b7817136ca6ced85950e3c25b6b17cfb4cea82d402f4ad76eb82
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: e504fed7c884e6659e2cfc092fb6e066ee60379c6c1842511bf8f54419263f62
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4485475cb6218d9fee69324e53f9add108b17923372d1ea0f601a4f9544f4156
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 1f59a9d224a6a1f972725dbfcbf2e2f4ea2f3a6effaca9f38d14e8df0b09e9c2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 11e367979869da596d4bed8117609363874faa0ef602bee772d3dbfc76d77029
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 4201de01d6cc799cf4a8f8f5906deac177a8bc410edea47596d59f1ef7792248
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 711e92169d7b3b9bcde3b9b388bb04ad00e43afcbaceb20a9d9a9adc1817abe9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: ecfccb0da5987672dfe9df637a26dda0cfab07b78922e98b5f34d1f3a9b2a922
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 6923c4a2fc62b0b64067c109bb0bbd0c1ee2dc93a575f45a4335b13262dcf27e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 614
- `line_count`: 4
- `sha256`: 2a213e90eba34497dd221e06023e75babdc4c8839e24ffbc9cd6321e49ca98ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=614 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: abec7e5b916ece1747fdfb1e126285dbe9a20c634a9188fbcd2d9284ebbf9e7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: b906acb153d679642590f74d93ef7c4b0d97e17890fac5ccd7a9a58f367c6c0d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 32a561128c4d5da4d8193109ab5184716a7150e41d60021fcf193e96a91a9e1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: c48853a1e3c8399207703f3a0540e75b1ca2aa07edec73c884d542cafacfa708
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 74e6eaf2600caa78f750945fb9e4a78feee0c66a607caceca5fe4ea584b6414e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 0a81aa5209938953d401469d32b845deea7e736374d5f08d73ad03a3e3ad67e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: e7a9d21edafb7eb531a5f8b5827fde6c57fb88ec23daf17a69b8f4fdfde2e2e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbb -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: cfe83055c50b4f20352835f839c3eabadf06da9d3565c6807dba8f5897e2bd85
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 0a8268d3e908c3bbd1048e7a9ca326234283e4a7656147d9d525b40bc992e891
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 626
- `line_count`: 4
- `sha256`: 6d51f3f70e283d0bc5ecebaf53c89f268a263835dc971234ed36afce9fae3081
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=626 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbc -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ef65e44b2a0eb95a46597bfa728ce180c5c7093eeb1e5165a57d8d11559d114d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 3c14b05f33c181fcbda785f7cf481f2c3960f1c0a9b7f707e8f8085b732ce25f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: ebb163d3e70fb603fb0e8e725a07e200fc24cd60fcb72d69100f67ac481b223f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4aa149bddc46ed2ba84fc0f2eae8ace504a52282d7eb099a39d8dc9ee9dd47f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: b57e16ae8d4a4f84cc79dfbfb439b09c7a99328b1f5786479a11a92d07818738
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: e4baf1e8d123ddb3dd41b5e77788321f11d3e9f38c4257ddd1f29f4e27153a4f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 618
- `line_count`: 4
- `sha256`: 24018fdc186e507d792e7416e8959f5c21549664b8711b7d7300a326b2f624f5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=618 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-build-rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 622
- `line_count`: 4
- `sha256`: 2c181156901f16e99ed8f75a84dc7be8c7606cae649f0ac0377f48ac9950ca04
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=622 bytes; lines=4; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' riscv64-linux-gnu-gcc -march=rv64g_zbs -mabi=lp64d -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -Wl,--build-id=none -I./../env/p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-clean.log

- `kind`: log
- `size_bytes`: 29485
- `line_count`: 3
- `sha256`: 851c71aa716076c9dfa1723796ad31cbb0d683e9102a978e8ef34ddd82f00ed1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=29485 bytes; lines=3; markers=<none>; tail=make: Entering directory '/home/lyg/PA/ysyx-workbench/npc/rv64/testsuites/core-tests/src/riscv-tests/isa' rm -rf rv64ui-p-add rv64ui-p-addi rv64ui-p-addiw rv64ui-p-addw rv64ui-p-and rv64ui-p-andi rv64ui-p-auipc rv64ui-p-beq rv64ui-p-bge rv64ui-p-bgeu rv64ui...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-breakpoint.log

- `kind`: log
- `size_bytes`: 5325
- `line_count`: 63
- `sha256`: cdb1af153f4e753f49f4701c75321f3281f13078d289cfb319c07b2cef4d8924
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5325 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-breakpoint.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-csr.log

- `kind`: log
- `size_bytes`: 5554
- `line_count`: 66
- `sha256`: 52a6ce0e219948dc7035c340a6665f770aff7ac9e49766bc28583bea9723c308
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5554 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-illegal.log

- `kind`: log
- `size_bytes`: 5710
- `line_count`: 68
- `sha256`: 1cbdf7d6b4832a898951ee98c141de8b7740be2cadfea860a9ebc3499b5381e0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5710 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-illegal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-instret_overflow.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: 8d5ae3b15b587251e75448d6f3a0c3d3e6a53bedae0646b576c8db50548d0fbb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-instret_overflow.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-ld-misaligned.log

- `kind`: log
- `size_bytes`: 5558
- `line_count`: 66
- `sha256`: 4a40ae56eaf5bf87894af6912b31be2bb04faf34d631b5bf194ee149b991d7b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5558 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-ld-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-lh-misaligned.log

- `kind`: log
- `size_bytes`: 5329
- `line_count`: 63
- `sha256`: 069ab45bc30ad33e09a0909c9b9eb9cd5dc7a8c2bc624e39d8b7ab66da2f1f72
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5329 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-lh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-lw-misaligned.log

- `kind`: log
- `size_bytes`: 5546
- `line_count`: 66
- `sha256`: f05e2e9b805346814bfc2b44cc3c44328d1b47b2337cb8ac98ace938afe11258
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5546 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-lw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-ma_addr.log

- `kind`: log
- `size_bytes`: 5496
- `line_count`: 65
- `sha256`: cdf057f3d7d826b5cf80489475ea614ecd76bcd151ffbf1a75e415278805a4e5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5496 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-ma_addr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5477
- `line_count`: 65
- `sha256`: e05306526ecac5fd05b7de0500a6fe4271f9833105b29990921ad49e37315177
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5477 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-mcsr.log

- `kind`: log
- `size_bytes`: 5391
- `line_count`: 64
- `sha256`: 8886f3c08d93672c67e3c20164a53989a98733382d40456cc2d23ef71228c052
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5391 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-mcsr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-pmpaddr.log

- `kind`: log
- `size_bytes`: 5382
- `line_count`: 64
- `sha256`: 98981fee886821219b120751ec685d5ccd1a1f32f0b4fbd5de803a48319a204c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5382 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-pmpaddr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sbreak.log

- `kind`: log
- `size_bytes`: 5065
- `line_count`: 60
- `sha256`: 60bfd722b6d25db7a9225da3908671a3fddac501ce4b1afab806ffa679f5762c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5065 bytes; lines=60; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-scall.log

- `kind`: log
- `size_bytes`: 5245
- `line_count`: 62
- `sha256`: e4ca760da0c5d192dddbcc8bd78b77498a62acf123ae4c197b82b3d041a3a2ac
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5245 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sd-misaligned.log

- `kind`: log
- `size_bytes`: 5491
- `line_count`: 65
- `sha256`: 0d1ff52fe6fc5a1f87942df171a455a51cd7502c5266b613786471b7bc8d4691
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5491 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sd-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sh-misaligned.log

- `kind`: log
- `size_bytes`: 5405
- `line_count`: 64
- `sha256`: 1343c31942425e8ec0ff4631df28b8da03c9552aac732435b77cbf41876f3930
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5405 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sh-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sw-misaligned.log

- `kind`: log
- `size_bytes`: 5413
- `line_count`: 64
- `sha256`: 645e424448c1d38d80674a007b3b35ea96c76a93442b0c65117bd7156ced0514
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5413 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-sw-misaligned.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-zicntr.log

- `kind`: log
- `size_bytes`: 5401
- `line_count`: 64
- `sha256`: 9ab71cd6c97f7751914ffdff1f22aae2c2134c91642faee5efd4a003cbbf7418
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5401 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64mi-p-zicntr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-csr.log

- `kind`: log
- `size_bytes`: 5478
- `line_count`: 65
- `sha256`: 451c86c6b802c95ec677f6296493a99e90143bac02f353d52e4225d99c600720
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5478 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-csr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-dirty.log

- `kind`: log
- `size_bytes`: 5557
- `line_count`: 66
- `sha256`: 68d30c7cdaec0929d3f35869a4bd7d8fdf564374f5e318935bce735c8eacf907
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5557 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-dirty.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-icache-alias.log

- `kind`: log
- `size_bytes`: 5432
- `line_count`: 64
- `sha256`: 97b2ba60325b3a0e7aee2b6c2a01ea7d14ed659b3aa37d79335378c8587059be
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5432 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-icache-alias.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-ma_fetch.log

- `kind`: log
- `size_bytes`: 5475
- `line_count`: 65
- `sha256`: 3ad1440668795c52c811f7141ca68f7b731afab25742288503711a3ccc162b51
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5475 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-ma_fetch.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-sbreak.log

- `kind`: log
- `size_bytes`: 5134
- `line_count`: 61
- `sha256`: 87b1b1b0b3c1cd24a60e8c3fa55863ea13a523a6aad17002d0814555ee11bc12
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"GOOD_TRAP": 2}
- `summary`: log evidence; size=5134 bytes; lines=61; GOOD_TRAP=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-sbreak.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-scall.log

- `kind`: log
- `size_bytes`: 5604
- `line_count`: 67
- `sha256`: 97dafa802271ab237b336f6f7e55b92192cd094b2affd0d2abf6bed85d1e5b5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5604 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-scall.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-wfi.log

- `kind`: log
- `size_bytes`: 5309
- `line_count`: 63
- `sha256`: 8514c9b251226d2ad82e282d6b02aff0a1a7595746f9c2f870312e44eeae33dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5309 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64si-p-wfi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoadd_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: e5e0d9d594673b1760f7743f91be87419c0c9fc20c0c10d77db29b6e64dc0d93
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoadd_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoadd_w.log

- `kind`: log
- `size_bytes`: 5325
- `line_count`: 63
- `sha256`: 7a454dbc41c6863fdae8cb9d6eb5edede801b225ffbaf8bf50f63e47cdb10aa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5325 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoadd_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoand_d.log

- `kind`: log
- `size_bytes`: 5254
- `line_count`: 62
- `sha256`: a2b823644053745067d09f1ac2e69b9bfe5f03ca70629379b0148b29e6e37253
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5254 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoand_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoand_w.log

- `kind`: log
- `size_bytes`: 5254
- `line_count`: 62
- `sha256`: 1f683f96ec699234daa915859f8aa71cae0f0ea2424de369f1fd9fc967bd28ce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5254 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoand_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomax_d.log

- `kind`: log
- `size_bytes`: 5254
- `line_count`: 62
- `sha256`: b22e71f31f4d64bff7672deed4480bc9224cc0b5b8d4b43ad4656073f4d432a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5254 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomax_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomax_w.log

- `kind`: log
- `size_bytes`: 5198
- `line_count`: 61
- `sha256`: 5aaa08b1775489cb94781ed8f0d808bbc9e78e2ea64c7d4acdc37c264e3ad41f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5198 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomax_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomaxu_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: abc5efff4ceba4affdd365b001647655857a3638ef00409f7a7d1da624f385a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomaxu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomaxu_w.log

- `kind`: log
- `size_bytes`: 5199
- `line_count`: 61
- `sha256`: 993e71f5f64809a9683ca5a59bbf106ece80cb9f1f01d5c02299e9163c6ab649
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5199 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomaxu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomin_d.log

- `kind`: log
- `size_bytes`: 5254
- `line_count`: 62
- `sha256`: d9fcc9b97088ce1ab510d751f90bb57f8a5aa95cbdd6a517cb6929cfc7a54184
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5254 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomin_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomin_w.log

- `kind`: log
- `size_bytes`: 5198
- `line_count`: 61
- `sha256`: 83d40c8ce2366a5fde9c0a808681e7a643e72289f18f85f12a6708c205edd920
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5198 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amomin_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amominu_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: 079d59c188d957c7726bc316c7ab84a6de5daa225e72c733d71419394db1b2c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amominu_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amominu_w.log

- `kind`: log
- `size_bytes`: 5199
- `line_count`: 61
- `sha256`: 3c53d3535b16787abb005ec58d45f597df778f89f56e4bb457b67119b6d49b25
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5199 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amominu_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoor_d.log

- `kind`: log
- `size_bytes`: 5323
- `line_count`: 63
- `sha256`: de5386419d69a4974575f0f0820d481d91f081ce2fdc62c57891810cb95f36bd
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5323 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoor_w.log

- `kind`: log
- `size_bytes`: 5323
- `line_count`: 63
- `sha256`: 4082810e3f617c33ec00bf47bc7bae51e43777f69af54bc4a892bd1c9dc5b013
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5323 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoswap_d.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: fe69978ae20d94c5a2c6bd517b1d39e68a11b38c98a68533e2bdada7ae49192f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoswap_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoswap_w.log

- `kind`: log
- `size_bytes`: 5255
- `line_count`: 62
- `sha256`: e8abca4a093761fc7584d8cebd7e504e0a63b5225e9773b24fd77603a511038e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5255 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoswap_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoxor_d.log

- `kind`: log
- `size_bytes`: 5324
- `line_count`: 63
- `sha256`: 71c080156534f32d890a7b614c2743e299dee054090720b6ddd4a3f690d1cdda
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5324 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoxor_d.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoxor_w.log

- `kind`: log
- `size_bytes`: 5469
- `line_count`: 65
- `sha256`: e7e2137e6ea1785b4618fb783ff17cc557b8341e9b76d39adac0d74369a6382d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5469 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-amoxor_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-lrsc.log

- `kind`: log
- `size_bytes`: 5625
- `line_count`: 66
- `sha256`: 38edec1b2b3f30bc81da708ed32e201de9601314f7b9960e95d4d395d62d1e5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5625 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ua-p-lrsc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uc-p-rvc.log

- `kind`: log
- `size_bytes`: 5631
- `line_count`: 67
- `sha256`: 648afb0140279c73ea00fb68f6a771751a86e05928b4fac9f8d32fb251206f1b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5631 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uc-p-rvc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fadd.log

- `kind`: log
- `size_bytes`: 5416
- `line_count`: 64
- `sha256`: 78fe1f437236171c3a33e388d3f3478cfcb8050221665d2d269a34bd3e85bbf7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5416 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fclass.log

- `kind`: log
- `size_bytes`: 5468
- `line_count`: 65
- `sha256`: 58591448567d3a5e0ea7813f4219eb5f996ac893112338f4a0b17ceda2526159
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5468 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fcmp.log

- `kind`: log
- `size_bytes`: 5486
- `line_count`: 65
- `sha256`: 76b14a29eabb3ece046749a9e42e0142d579c0d0cc4306ac4f0c6be2373756fe
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5486 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fcvt.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: 5d1289b4626bff4dd86b02cb972a619d0fa8c8f3fdb671fb20b8730db6edadd2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5501
- `line_count`: 65
- `sha256`: e717ae8266c682cb1d99f9080e9aa460cf87f1facf3cf7ae2783835aec65bbef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5501 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fdiv.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: 4f4641a3f9190a18f067c15b9079c854c0b0dabd14f97d42d14964d9ca1047e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fmadd.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: 4b0f62a53cbe729ea7a3b0b3044d9414a3d8ae94d7dbc2fb7e30aac3ab6eb1a7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fmin.log

- `kind`: log
- `size_bytes`: 5489
- `line_count`: 65
- `sha256`: 71cb18990ac1561789ac5b2ee3fd93be3182d1faa65dcc714e7a847d2f6c9749
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5489 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-ldst.log

- `kind`: log
- `size_bytes`: 5332
- `line_count`: 63
- `sha256`: f6d3a92cd4ab1e54b7076c906eb67a0fc59ff13991beaa190932536e33d6f3f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5332 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-move.log

- `kind`: log
- `size_bytes`: 5485
- `line_count`: 65
- `sha256`: 644a7fc7dcc8056237cd25ddc18336e4f7457010b88bd302f9c7bc3ead1fff7a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5485 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-recoding.log

- `kind`: log
- `size_bytes`: 5199
- `line_count`: 61
- `sha256`: 0e46db6b99e824fd9e281bfb2048eb7179a9831a8ffcc00ffde744664d1ea3be
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5199 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-structural.log

- `kind`: log
- `size_bytes`: 5620
- `line_count`: 67
- `sha256`: be1c182a5590e88a595cfff4d8a50614ec85763b55b20bcb02a9425b8bbe9326
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5620 bytes; lines=67; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ud-p-structural.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fadd.log

- `kind`: log
- `size_bytes`: 5417
- `line_count`: 64
- `sha256`: 0432233d08ee768edba97271aa40a88027abcf7d22bbdd46677b33a26df63001
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5417 bytes; lines=64; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fclass.log

- `kind`: log
- `size_bytes`: 5469
- `line_count`: 65
- `sha256`: c5a6376bddf1ade0f5b14ee9853be73752c5a26359199d931950c14ce37dbaec
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5469 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fclass.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fcmp.log

- `kind`: log
- `size_bytes`: 5487
- `line_count`: 65
- `sha256`: 27a80b38bfb50b8fdf109247d3fadc8b60f76967bc69e14812edac34901471e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5487 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fcmp.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fcvt.log

- `kind`: log
- `size_bytes`: 5338
- `line_count`: 63
- `sha256`: 14175ad109058b7b96d737393c25c6adddb8d068ecfe0a2f2ca20f406b75a84b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5338 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fcvt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fcvt_w.log

- `kind`: log
- `size_bytes`: 5497
- `line_count`: 65
- `sha256`: ee85c0130798be5a2153b6d46d52274f7dc1a68fc1511e77f73da1611cfde1b1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5497 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fcvt_w.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fdiv.log

- `kind`: log
- `size_bytes`: 5484
- `line_count`: 65
- `sha256`: d0b42beb9cdf657a6f34de429509e9a4237e3f22b160ad32091181e4a9c9c35e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5484 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fdiv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fmadd.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: 1aaed78c5b3afef47a42e5cc5423d0bc17e3bd0a54ad4e0a60e645728a10bb93
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fmadd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fmin.log

- `kind`: log
- `size_bytes`: 5488
- `line_count`: 65
- `sha256`: ab4205aad21e20bd8be3424a14b8945102064f81388635249140041b10115c71
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5488 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-fmin.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-ldst.log

- `kind`: log
- `size_bytes`: 5256
- `line_count`: 62
- `sha256`: a40efb5643968bc15432a7e95190a4e7bae445f2704bf6575f62bbd42e3f24e7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5256 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-ldst.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-move.log

- `kind`: log
- `size_bytes`: 5476
- `line_count`: 65
- `sha256`: 6d1fb8079ae4a3136df93e3c39852d21cf1041339460580af345ce3945adb75f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5476 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-move.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-recoding.log

- `kind`: log
- `size_bytes`: 5263
- `line_count`: 62
- `sha256`: 3cd943df2c637db210d06afe2a5d74010e304d4d3b5fe4d42c67605eb295e24b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5263 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uf-p-recoding.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-add.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: d4a51e1b87fcfc2ffcc827ed5d64f5c83bc982eb310946954d27e84597a87117
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-addi.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 188a3c6eb441a9678bce7fb2f0d3ba02387847fabad2babcf53d2205e59a4801
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-addi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-addiw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 146e8747c161385baebd3563706bfd847704aa755b186f20791e39a59b0016ef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-addiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-addw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 550a030e54525a2ea888e11be3f61a1e68cba20ea7471030d74415c23d8575d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-addw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-and.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: d609fadd88397232871e233bcc0ccf9a7861863c1c2e8fd643471ae9b11d22e2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-and.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-andi.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 3efad9c9a7c354af933483debf2d088776550f0e23269959c3f13fbe4053fb64
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-andi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-auipc.log

- `kind`: log
- `size_bytes`: 5248
- `line_count`: 62
- `sha256`: c450c11d03acec53659d1552d882b5328c8e6747060d522c4fc54aee2bfbf89b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5248 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-auipc.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-beq.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 6996d1e95d280ea84d8b519d63301adf301d7b055ea2c8720db0e75fa043bc71
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-beq.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bge.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 56c5c2d1d12e5b8c5590a4c77fd1761649f20c1c82a6f1688b167198e685bc7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bge.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bgeu.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: de7339c8e5b2f23df810fe1814f4b2c80073c80edd44216f473cea169329bfc5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bgeu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-blt.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 2a5ab494b634ec522b55871ea7d1bcb2ee937a5c5fb57d0f6c3dce8dad8011c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-blt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bltu.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: f357b0431864c201466cf146a6baafa4e8dbd3dc815c0fca5a3ed5842d1dd828
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bne.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 730dffb837aa9866b3ffa197cbfb25f13484ca39fc6570a8dd46c6bff6be0d01
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-bne.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-fence_i.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: 613743f881788e9a734b68998c5deb13578c7c671f1405c76a2a96063dcb2c5e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-fence_i.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-jal.log

- `kind`: log
- `size_bytes`: 5238
- `line_count`: 62
- `sha256`: fda9e82783a94c0ec67685d22e0bf35a8a49871757add69b45a7a2af9892d1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5238 bytes; lines=62; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-jal.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-jalr.log

- `kind`: log
- `size_bytes`: 5549
- `line_count`: 66
- `sha256`: ca01a4bb5f6c2a9da85562fb37c6f102ade2952bf88938636cb37c64d6794974
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5549 bytes; lines=66; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-jalr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lb.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 123dd217ea132d962894457fedabaee20d646786ba2428662bb984020aa91933
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lbu.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 1d077ebcc8970dd250520f4d0feca4530321d2597203638a7e4eb82be51fc9bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lbu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ld.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 8dbbdeb33f6e1a0b059f584b96e56105a678c8f11e2bf9e65aef9f23ae17f9ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ld_st.log

- `kind`: log
- `size_bytes`: 5737
- `line_count`: 68
- `sha256`: b5e3800a98c057a4c023928cdcaaf9e3ca68a5d7549857924fda0171d736ffa8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5737 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ld_st.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lh.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 993213db04ac277c8f82d7de4386ca161107ec3271cba9b441c3207d6167d035
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lhu.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 52c357e3e6394c2521d31bb988a75949337acda2ba58ae60ec257eefae63bfd8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lui.log

- `kind`: log
- `size_bytes`: 5317
- `line_count`: 63
- `sha256`: 7734f06f6cfbc75597721cbfde0752a6bd12f62f8a12f53315a07dff0d7e31cb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5317 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lui.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lw.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 6e82e4ba049d9360b61d0f3ab5067c0b31149beeaee89017014b651a54c9c59d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lwu.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: eb7b394cbe3d4a11ef05f66fde65c547d9309fa83b94aac0a45d995a9f0a7be5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-lwu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ma_data.log

- `kind`: log
- `size_bytes`: 5752
- `line_count`: 68
- `sha256`: aefd56a564b68d6e389a264cd638d83f581732d17f87205f8dc40c3e691fcea4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5752 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ma_data.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-or.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 4260ea4c7d77051a2840f44051b2faa0383aa8f57f59a2cd989d8336dcc28179
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-or.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ori.log

- `kind`: log
- `size_bytes`: 5688
- `line_count`: 68
- `sha256`: 5b3426604dda1f501f1c967689c571fa7b1349e1c0105666e59b45510b6f27a0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5688 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-ori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sb.log

- `kind`: log
- `size_bytes`: 5704
- `line_count`: 68
- `sha256`: e71754397641fa9c04ff1cd377cb161d94bc38933509c6052c63eb57ec61baac
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5704 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sb.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sd.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 140fa647040beb3e85ba03ce8262e6434ae492e41c6c6d8211995455688af22d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sd.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sh.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 0fd04d79c4ec171c072195427e84196d8627c1eda8dcd88bb67a8f68f1c394c8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-simple.log

- `kind`: log
- `size_bytes`: 5167
- `line_count`: 61
- `sha256`: c3cdba5acb318387604dc29f5fe727bd45640fee2b93f539f7abf415e99d4870
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5167 bytes; lines=61; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-simple.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sll.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: a63be946c0b60c28b523bd552a164fc1d36cc1a9a9c16fea41792bd81538c7e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sll.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slli.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 9773255823c2ec0e4d85532d0ee171b4d28fcdc3bfca46bab7ffe4f5b4a1a4b9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slliw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: baf5723320a0f844f199e4d4ea5ec0f35b0b4a520fe639b4f9303215094e593d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sllw.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: c6c8b41902cf767553f8611133fa5e4703fa8f10a3150bf821913a9163b2fb4e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sllw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slt.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 8fa1623d71eff877db5026448354abc6c63abe5c6201fe2d457b398b0505211d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slt.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slti.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: ed21935e542bed375b79bec1a3bf1b2e6a73310de6ad48265746678162697f53
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-slti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sltiu.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: cb1789fd9654a9c2593780c7c9eb1012173839ea7eee82e9f549eab823d595ec
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sltiu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sltu.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: a1231e35854ca7485d8a99bdcc7f57379d94d657d5b2b75457404ba2b5a6829e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sltu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sra.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 144ddeed7229ac3c18809d4e991de12c468eba79a539809cc6f4b72feaa6c253
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sra.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srai.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: f808b89f7b9ed799b40d4803085d30a89736852c3a2f37fb865ab4c5737b71b4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srai.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sraiw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 846f186de48af596f325c59d79c82eead2cde9454e786780056adb74da4bd6d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sraiw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sraw.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 081f419b5a5df0d5beb5adb5a85847a902ad7076798db3482701820cdfd564d2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sraw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srl.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 1f54f746d1e3629e518b0c0b3b5664bc765f42f52b8c14df47af85b5e34a00ee
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srl.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srli.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: 4d9e2ff011765461dd210d957cc8ce8418f760c47fa7b46d3bc507bac775694c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srli.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srliw.log

- `kind`: log
- `size_bytes`: 5690
- `line_count`: 68
- `sha256`: 9d5453b8e562e49b94240795996ea33d234fbd8091e2d121a886f95fe56fe3d9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5690 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srliw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srlw.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: f8c8ccff69a584d5006e728e0ca0d93a969f46d3062baff242f50305ac1526d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-srlw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-st_ld.log

- `kind`: log
- `size_bytes`: 5498
- `line_count`: 65
- `sha256`: f84441c08e3089cc6cb0f52d15d895472d0ae7754ad159fec3a80746e38c0e44
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5498 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-st_ld.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sub.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: cdad848d10fa8b81a864c287e005bc40d348dd6e69a22ad98cf2ec53f66bbdfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sub.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-subw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: cb6daac39e1ec8848fa9cd29a4b10cfe66e57ace5f5cc9672ba0f00200a61c7c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-subw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sw.log

- `kind`: log
- `size_bytes`: 5706
- `line_count`: 68
- `sha256`: 483a14079f35ed4af95e0dd36b853be2a9af8109e3ec7b925370f8b0328e40d5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5706 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-sw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-xor.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: cd43c4c98566dc11a84d09f97939b3792cf3e9f20eba6daffe43057a92211c85
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-xor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-xori.log

- `kind`: log
- `size_bytes`: 5689
- `line_count`: 68
- `sha256`: abb8eb752752fe5907acc87a287a50420fe33a296ea3bde0772c9835e2f214dc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5689 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64ui-p-xori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-div.log

- `kind`: log
- `size_bytes`: 5327
- `line_count`: 63
- `sha256`: bca0aabde0cbad407f10b68990ee9a5a59a79d7b388c32246d7fe8a5dd448fcf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5327 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-div.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-divu.log

- `kind`: log
- `size_bytes`: 5464
- `line_count`: 65
- `sha256`: 0207af9c044ce3e7d0e91907a0a21ac49974d1112a4378e31b46729763c585fc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5464 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-divu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-divuw.log

- `kind`: log
- `size_bytes`: 5330
- `line_count`: 63
- `sha256`: e1e83c561c5610141bb606e5b15383556b1df6c7d230e5a0cab3621ca76f11ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5330 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-divuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-divw.log

- `kind`: log
- `size_bytes`: 5466
- `line_count`: 65
- `sha256`: fec32daebf11cb40e5b07f233e65c511b6af64e6181a315c2133eb34df83adf9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5466 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-divw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mul.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 81940012d2f0542bb593c65e9fb62e904a5d3c60f4e43f339d7f0b4d79dc83ae
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulh.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 2340b4023dc984616524f6249aa66272dbf874eac27be15555aeb75ea2e274b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulhsu.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 3c80fe0fcc955624a7eef3e0fdc6e87a9ccc37aae1e76ee0ef18d1c15b2a8bfa
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulhsu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulhu.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: cf8f8da44be9ad4980c043f263d5fc3bdf4dc090caa1fe0fa66556cef6087985
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulhu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: f8d78b89b8668811334105eee34c40f52c83eddaec90d51f422141ec1fd724ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-mulw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-rem.log

- `kind`: log
- `size_bytes`: 5462
- `line_count`: 65
- `sha256`: 7b6e70b7a26c758920f40bf14679c9bfc8642fa8a0d5cd1937b9a0811fb0c76d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5462 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-rem.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-remu.log

- `kind`: log
- `size_bytes`: 5328
- `line_count`: 63
- `sha256`: 5b2a3b4586c85d3ef16be375141e18664cbc90d6b696d181561e2626f16999be
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5328 bytes; lines=63; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-remu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-remuw.log

- `kind`: log
- `size_bytes`: 5464
- `line_count`: 65
- `sha256`: 01b3cc8345f29c4d180fcc5a0e11b8710eb54fa2d08e6c8b87903899e8860199
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5464 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-remuw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-remw.log

- `kind`: log
- `size_bytes`: 5466
- `line_count`: 65
- `sha256`: 0b71b6d92372d9265e9a69176aea56df6d29352faf78ecf9630cd60821505257
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5466 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64um-p-remw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-add_uw.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 5e706987f2213ee77ef3ec93c30c246fe31b24131dc893c29f122b17b82fe1e1
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh1add.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: b73f38be1dbd671a44a84d2ae0071617dcf2022e01eb2f8d5bcd0ab6a96d0a5b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh1add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh1add_uw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 3af504349c27ddef70010ea46f1dc12f411fd78d807cf8b265399dc1d9ad388f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh1add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh2add.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 94d7dca72e923eaf8801108cdf5af246a0c4d6d0943703220156ca0b72cd63bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh2add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh2add_uw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 98a942af012cc9a4d8f5f1d753d102e18544bf1d1f60a347eb93a3783a94a655
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh2add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh3add.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: c9130554b9d02c2b47c681393245e0d7873d103c8f66c2bf0d1b26c0f92f460c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh3add.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh3add_uw.log

- `kind`: log
- `size_bytes`: 5699
- `line_count`: 68
- `sha256`: 6536f7871e02061fe6ce5d6899bc8a322d5039cd8ec954b0eb50f8a3f7608c75
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5699 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-sh3add_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-slli_uw.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 28c32052afc35e3f53bbb564d220f463bde03b455000588dc6210f63c8d1be35
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzba-p-slli_uw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-andn.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 2345da05428f9df551454d5e8519c077dc0ad1f6cbbc69910555e516167c27bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-andn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-clz.log

- `kind`: log
- `size_bytes`: 5480
- `line_count`: 65
- `sha256`: 800341d4b41b341bee8e2b84afdc3d14f95322fc52db72d9b9552d91ee29f63d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5480 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-clz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-clzw.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: f2d44a54cab9d43f44e4133251deddd60978d09e35d34dcf471071c13a591672
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-clzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-cpop.log

- `kind`: log
- `size_bytes`: 5481
- `line_count`: 65
- `sha256`: 2fd3739632c02c8931af98b473364363829828b9c3cd75310895bc2d38bbb65d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5481 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-cpop.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-cpopw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 9862205016e80fa984ccd995b42132b53656cea2b28b70ea2b718535971d0221
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-cpopw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-ctz.log

- `kind`: log
- `size_bytes`: 5480
- `line_count`: 65
- `sha256`: 92bf8b3bb2d2125015ccb5ba2329e99b1481fa09918f9338064b71ddbe7dfa0f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5480 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-ctz.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-ctzw.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 750815da5f2d224e6a9c62303bbdf8e95fbaad4916747e729428d5c1fca87c08
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-ctzw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-max.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 88eb099139f44ccbe3be629e13c8ad4ed34cbe2449963b73f1397f2a19adaff2
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-max.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-maxu.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: b27e3374361ecc22032e4a988c0756186e9cc8bc8d9dab9a7b41889ecb42687f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-maxu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-min.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 49757b73d5c29cd253f43367af6c40ecc94ea88af70c312178a0f50c43929d8a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-min.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-minu.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 7f0e2893293c80aa2f921d43f902120999b58ffd0368a642a10e7ed4f3d94d3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-minu.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-orc_b.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 5ddcb75a30569676bd0da1a0547f24af7217bbb52f838f5847f4d0f1edb50f20
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-orc_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-orn.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 172ee9971f9f5bce2cb5439edd2f9894133234772cfdcdc0bab1f3601e7058cc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-orn.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rev8.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 352e66d73816dc10c96e5bdd89b4e27bfd999c16ca7a9ae4a0b8ea945235d875
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rev8.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rol.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: f8ded6e8d39f7486076ca14345fc8faffed5c9d7677ed22fbb6f96a028adce47
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rol.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rolw.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: e9d9e21f4ab98eb8a7301dc06da5d3041ca72711a334812562a0ce78dd1f3ea9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rolw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-ror.log

- `kind`: log
- `size_bytes`: 5695
- `line_count`: 68
- `sha256`: 4338a358fa6bb566ae3f1da3fd7e99bfa6f47a98d73343602c65d3e8cd0e1f0c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5695 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-ror.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rori.log

- `kind`: log
- `size_bytes`: 5691
- `line_count`: 68
- `sha256`: 5b99840b77ec0c1d5730c06b3c9060d8e18cf14dc18b1844141207fbc14feed6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5691 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rori.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-roriw.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: a0485b05740f1f00a43254893de8f60d3ec003602babf38271afe2995b4f6a9d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-roriw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rorw.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 8b4b9783d1c33fc0cdfc20798ed5bb9b788c56f1fb09f6bd5606a6d8a4d072d6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-rorw.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-sext_b.log

- `kind`: log
- `size_bytes`: 5483
- `line_count`: 65
- `sha256`: d0a3b03666c7ba56bdae89cbdbf86defcebd10a805922638273d3e1e6998694e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5483 bytes; lines=65; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-sext_b.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-sext_h.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 1951a1baf802b275e58fe389a3b5a652ce70f7b9cc4d64c7dd77f1cfc5618d1a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-sext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-xnor.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 115d14dd83298b649bcdfda92d706055c3fd8eb34677081d234003778dec0236
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-xnor.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-zext_h.log

- `kind`: log
- `size_bytes`: 5694
- `line_count`: 68
- `sha256`: 6d547ee4379ce9218677f2d2090efb45a529cb0bc2efc270645f924dc76dc37d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5694 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbb-p-zext_h.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbc-p-clmul.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 49aa4c9725077379e591264e1b8e65bf16ef8b1f816552c7e153b24c2a527220
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbc-p-clmul.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbc-p-clmulh.log

- `kind`: log
- `size_bytes`: 5700
- `line_count`: 68
- `sha256`: d15552a15b592ffccdc49f7e74cd3ec5280c55a65bcc0a065804577a81e7577b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5700 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbc-p-clmulh.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbc-p-clmulr.log

- `kind`: log
- `size_bytes`: 5701
- `line_count`: 68
- `sha256`: 9bf78134fb09b68d611b3e37bd0dcd8c10d60db4dfbef77cbc323a675a805c25
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5701 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbc-p-clmulr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bclr.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 0b9c20ae97556e5946c861b4871a1dae042d41412e12ff7864e40410f5bf594c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bclr.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bclri.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 0bf397f75282eb4ba0af529c5e72200800e9a83d3db88479e9365a563df110a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bclri.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bext.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 35df30aa7135fa635826d5e7d935e3e3491d767e78cdb953ce5b71a263c6d074
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bext.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bexti.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 8b6ac4c4096b897537d2e14ea52803ed1c2a85a1208e5ebab43cd4496ada271a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bexti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-binv.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 21461c6e6f7da5f9ec24ebaa346604819e3a96a210cadcab790555b797f58d3d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-binv.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-binvi.log

- `kind`: log
- `size_bytes`: 5692
- `line_count`: 68
- `sha256`: 9baf71da33ad55dbd0e95754551dbda20dc36367027ff0682365283f1b516988
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5692 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-binvi.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bset.log

- `kind`: log
- `size_bytes`: 5696
- `line_count`: 68
- `sha256`: 26356c813f095ffbbeace1ef129c73959c00e0a3b1f9b6f085fe634e40db7735
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5696 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bset.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bseti.log

- `kind`: log
- `size_bytes`: 5693
- `line_count`: 68
- `sha256`: 5497c2b5bd2209b07af14377b32f2b23d944b05f1a68dab429c8e7928bbeeee9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=5693 bytes; lines=68; PASS=2; tail=[1;34m[log.c:145 npc_init_log] Log is written to build/npc-log.txt [0m [1;34m[paddr.c:91 npc_init_mem] physical memory area [0x0000000080000000, 0x00000000bfffffff] [0m [1;34m[paddr.c:150 npc_load_img_at] The image is /home/lyg/PA/ysyx-workbench/.github/tas...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/riscv-log/rv64uzbs-p-bseti.log.objcopy

- `kind`: objcopy
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: objcopy evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/status.txt

- `kind`: txt
- `size_bytes`: 17885
- `line_count`: 358
- `sha256`: e1aa30eeda8f8f0ce9c2c870d4bea46343c5d186f105b0f55f4355d8ed17cfa9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 714}
- `summary`: txt evidence; size=17885 bytes; lines=358; PASS=714; tail=npc-build PASS am-cpu-tests PASS riscv-clean PASS build-rv64ui-p-add PASS rv64ui-p-add PASS tohost=0x0000000080001000 build-rv64ui-p-addi PASS rv64ui-p-addi PASS tohost=0x0000000080001000 build-rv64ui-p-addiw PASS rv64ui-p-addiw PASS tohost=0x00000000800010...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175/summary.txt

- `kind`: txt
- `size_bytes`: 17874
- `line_count`: 542
- `sha256`: 038448db72b584ec93f559bbc046093d3fcba686278722697d2a9fcae7baa72b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 714}
- `summary`: txt evidence; size=17874 bytes; lines=542; PASS=714; tail=NPC RV64 core regression run_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/core-regress-difftest-on/20260713-004417-1864175 riscv_suites: rv64ui rv64um rv64ua rv64uc rv64uf rv64ud rv64uzba rv64uzbb rv64uzbc rv64uz...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/coremark-iter10-current.log

- `kind`: log
- `size_bytes`: 8408
- `line_count`: 111
- `sha256`: d7a682fae772fd41e62cbed57cc7529d8375260ab0a0f073dab4db4170f4af95
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"GOOD_TRAP": 2, "PASS": 2}
- `summary`: log evidence; size=8408 bytes; lines=111; PASS=2; GOOD_TRAP=2; tail=Script started on 2026-07-13 00:32:52+08:00 [COMMAND="make -C am-kernels/benchmarks/coremark ARCH=riscv64-npc ITERATIONS=10 run" <not executed on terminal>] make: Entering directory '/home/lyg/PA/ysyx-workbench/am-kernels/benchmarks/coremark' # Building cor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/default-rebuild-current/summary.md

- `kind`: md
- `size_bytes`: 898
- `line_count`: 20
- `sha256`: 859dec78a7e87178a752da99f292f686bb91ae77e66e57924af223fc704b5365
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: md evidence; size=898 bytes; lines=20; markers=<none>; tail=# Default Difftest-OFF rebuild The restored configuration is confirmed by `.config` containing `# CONFIG_NPC_DIFFTEST is not set`. An initial literal `make -C npc/rv64 -j2 default` selected `/usr/bin/verilator` 5.020 and returned rc `2` before code generati...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/difftest-config-restore.md

- `kind`: md
- `size_bytes`: 1007
- `line_count`: 19
- `sha256`: 787eea559903b031eac97066bf9a4300682c88758e67b48b4485fb2c139a2e6a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: md evidence; size=1007 bytes; lines=19; markers=<none>; tail=# Difftest-ON validation and config restoration - core-regress run: `core-regress-difftest-on/20260713-004417-1864175` - underlying result: `overall_rc=0`; AM 59/59; official 177/177 - validation config: `CONFIG_NPC_DIFFTEST=y` The outer shell returned 127...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/fetch-footprint-current-green/compile.log

- `kind`: log
- `size_bytes`: 85730
- `line_count`: 645
- `sha256`: 2640bb24c344cf64dfd0bcc116312e2415e371d4620ca7ee0d0a8e100ac67c5d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=85730 bytes; lines=645; markers=<none>; tail=ntry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/fetch-footprint-current-green/sim.log

- `kind`: log
- `size_bytes`: 3249
- `line_count`: 69
- `sha256`: e4e51a7b0a149ac13825cfb1734f53c589fa865e481825b0dff29ba32a03381d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 126}
- `summary`: log evidence; size=3249 bytes; lines=69; PASS=126; tail=[ACCESS-G1-FOOTPRINT-PASS] C/C offsets={0,2} ARSIZE=2B [ACCESS-G1-FOOTPRINT-PASS] C/U offsets={0,2,4} ARSIZE=2B [ACCESS-G1-FOOTPRINT-PASS] U/C offsets={0,2,4} ARSIZE=2B [ACCESS-G1-FOOTPRINT-PASS] U/U offsets={0,2,4,6} ARSIZE=2B [ACCESS-G1-POISON-PASS] C/C p...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/fetch-footprint-current-green/tb_ooo_fetch_access_footprint.vvp

- `kind`: vvp
- `size_bytes`: 979934
- `line_count`: 25122
- `sha256`: c0498d1fd8d92021cd4386bd59c45812e191d69231fd0d9641b8b43223fbcd31
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"FAIL": 8, "PASS": 6}
- `summary`: vvp evidence; size=979934 bytes; lines=25122; FAIL=8; PASS=6; tail=vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4 0, 0, 32; draw_string_vec4 %concat/vec4; draw_string_vec4 %pushi/vec4...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 129fb938bcea093154dbc1dc8e472e099c7f6b610cd4216a77dd8561d9f30187
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87564
- `line_count`: 662
- `sha256`: 71dc081249f23b85c988bb2955eef9ab25311870c9426b7736c05fa505e5887b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87564 bytes; lines=662; PASS=2; tail=ddr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: b6323debf722ff9677ce8bb0c8f22e2e05315190dfecd48a67dc01b0bd446d19
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green/summary.txt

- `kind`: txt
- `size_bytes`: 531
- `line_count`: 17
- `sha256`: f86b977b24335fce50a456262ace5d72831990a8ab49ab70b0c86e5db6ed6c9f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 16}
- `summary`: txt evidence; size=531 bytes; lines=17; PASS=16; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-current-green - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_axi_exec_fi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 129fb938bcea093154dbc1dc8e472e099c7f6b610cd4216a77dd8561d9f30187
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 3998893851256d56bbb1a769e031b67cfbfb4f3ce45425ffd04465e415c22a16
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: b6323debf722ff9677ce8bb0c8f22e2e05315190dfecd48a67dc01b0bd446d19
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current/summary.txt

- `kind`: txt
- `size_bytes`: 502
- `line_count`: 17
- `sha256`: 1848dbd9c94b63ff97244e446206a437fcfbe6a0a1cabe1cdf808f6ed92f7619
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 16}
- `summary`: txt evidence; size=502 bytes; lines=17; PASS=16; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/focused-final-current - tool: Icarus Verilog version 12.0 (stable) () - PASS tb_ooo_fetch_access_footprint - PASS tb_ooo...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_alu.log

- `kind`: log
- `size_bytes`: 345
- `line_count`: 5
- `sha256`: 42b4d8d75518f04ed2012f8e78fc9c1722c05521dd902782a9f5895612166ff8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=345 bytes; lines=5; PASS=4; tail=[TEST] tb_alu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_alu -o build/tb_alu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/ALU.v tests/t...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_axi_clint.log

- `kind`: log
- `size_bytes`: 377
- `line_count`: 5
- `sha256`: 1784625a722247663126c3dfd8e0e798570458873ed233ab86ca0362e46a4fba
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=377 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_clint [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_clint -o build/tb_axi_clint.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_axi_exec_firewall.log

- `kind`: log
- `size_bytes`: 3475
- `line_count`: 28
- `sha256`: 47d98dec11c00986d5909dd2a3d9e6fc9e0a4186cab26b73d7d1a29605c6401d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3475 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_exec_firewall [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_exec_firewall -o build/tb_axi_exec_firewall.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_axi_plic.log

- `kind`: log
- `size_bytes`: 371
- `line_count`: 5
- `sha256`: 338051cda5ddb88aee8f48e422771f8700612fd4430f2f3115968357fcb9fb07
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=371 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_plic [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_plic -o build/tb_axi_plic.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_axi_to_uart.log

- `kind`: log
- `size_bytes`: 441
- `line_count`: 5
- `sha256`: c261459a359d8b8232352ca4f8fef759c0913ca1b5dfa14c0bc7fcdede8e1897
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=441 bytes; lines=5; PASS=4; tail=[TEST] tb_axi_to_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_to_uart -o build/tb_axi_to_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_axi_xbar.log

- `kind`: log
- `size_bytes`: 3254
- `line_count`: 28
- `sha256`: 21e3dcbe8bc0051b5fab27bc2d363a1dd52a6a417e9c2db1391306edbea04355
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=3254 bytes; lines=28; PASS=4; tail=[TEST] tb_axi_xbar [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_axi_xbar -o build/tb_axi_xbar.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Ax...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_compare.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: b1cbf98e01de41dc9f3e57656c310090d83126b5f0c0f2d9c59e626672fc5c1f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_compare [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_compare -o build/tb_compare.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/execute/C...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_csr_file.log

- `kind`: log
- `size_bytes`: 372
- `line_count`: 5
- `sha256`: ee3c7d36e7bf434c9bead2c2cfb9c1c6d57d037a428336defcc61f7c48ba4f61
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=372 bytes; lines=5; PASS=4; tail=[TEST] tb_csr_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_csr_file -o build/tb_csr_file.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/core/C...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_decode_stage.log

- `kind`: log
- `size_bytes`: 516
- `line_count`: 5
- `sha256`: e630e99952ad995fa2f6c25c5c9266a7963298f82b965cea6e7c8dc90e276aeb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=516 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_stage [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_stage -o build/tb_decode_stage.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_decode_unit.log

- `kind`: log
- `size_bytes`: 391
- `line_count`: 5
- `sha256`: bafb97300fb49a7ac4af5c9cb894b69e418604175e0e42a09172fb4da1418c74
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=391 bytes; lines=5; PASS=4; tail=[TEST] tb_decode_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_decode_unit -o build/tb_decode_unit.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_immgen.log

- `kind`: log
- `size_bytes`: 361
- `line_count`: 5
- `sha256`: fddfa26f1c59924f03b0af856070eff49af2d049418a24b3920522d410766d8f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=361 bytes; lines=5; PASS=4; tail=[TEST] tb_immgen [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_immgen -o build/tb_immgen.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/decode/ImmGe...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_lsu.log

- `kind`: log
- `size_bytes`: 468
- `line_count`: 5
- `sha256`: 076697816ed3471bf5a4cd86e98fd6c9fb2997091b03c1f064e13b1b8ea03e28
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=468 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu -o build/tb_lsu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/LSU.v /home/ly...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_lsu_control.log

- `kind`: log
- `size_bytes`: 390
- `line_count`: 5
- `sha256`: 776e2ca423be2d4d83100350dbb73475d48f7c052ae8a1d83b0b7c743de27f3f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=390 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_control -o build/tb_lsu_control.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_lsu_datapath.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 02688ce160e0b57a4a6f47745966d54c04adac25c0654a244d0e6111df24b631
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_lsu_datapath [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_lsu_datapath -o build/tb_lsu_datapath.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_alu_core_slice.log

- `kind`: log
- `size_bytes`: 14816
- `line_count`: 91
- `sha256`: 6fb736de998e48cf84f0ab90c764e46dd9640e3d2d8812c110a7c122641453a5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14816 bytes; lines=91; PASS=4; tail=[TEST] tb_ooo_alu_core_slice [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_core_slice -o build/tb_ooo_alu_core_slice.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_alu_decode_backend.log

- `kind`: log
- `size_bytes`: 14492
- `line_count`: 89
- `sha256`: cb5943ea83cac758fceec4a67961a742be7e3614c15acc1637138b6008037e54
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=14492 bytes; lines=89; PASS=4; tail=[TEST] tb_ooo_alu_decode_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_alu_decode_backend -o build/tb_ooo_alu_decode_backend.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_amo_gate.log

- `kind`: log
- `size_bytes`: 396
- `line_count`: 5
- `sha256`: 06e005132fed607dee4b000fc9a11a7e5b9a2c548839292ffb3b10b35e7d7911
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=396 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_amo_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_amo_gate -o build/tb_ooo_amo_gate.vvp /home/lyg/PA/ysyx-workbench/npc/rv64...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_backend_drain_tracker.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ad0e070f7dc1daefb1d2b865ed1e3971defae1f51bf30b7267e0165dfac1c279
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_backend_drain_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_backend_drain_tracker -o build/tb_ooo_backend_drain_tracker.v...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_bitmanip_gate.log

- `kind`: log
- `size_bytes`: 426
- `line_count`: 5
- `sha256`: 33be629619f7bb37b78c3c400911ff6bc473ff743841331f2667bb09547886ca
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=426 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_bitmanip_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_bitmanip_gate -o build/tb_ooo_bitmanip_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_branch_append_dispatch_gate.log

- `kind`: log
- `size_bytes`: 853
- `line_count`: 9
- `sha256`: deb10cf9e81db53cca97aa6849ba5caa96daeadf4c7151ac43bba898eb64ec69
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=853 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_append_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_append_dispatch_gate -o build/tb_ooo_branch_appe...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_branch_bpu_update_gate.log

- `kind`: log
- `size_bytes`: 808
- `line_count`: 9
- `sha256`: 8d1c186bfeba676407ef6d6374dd8b832e900a21db68e84bffc3391770d1abef
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=808 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_bpu_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_bpu_update_gate -o build/tb_ooo_branch_bpu_update_gat...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_branch_direction_predictor.log

- `kind`: log
- `size_bytes`: 591
- `line_count`: 5
- `sha256`: fbbab7a7193f101da02687ed699b847627a456b43678442e12e5552e3b8c2601
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=591 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_direction_predictor [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_direction_predictor -o build/tb_ooo_branch_direct...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_branch_resolve_recovery_gate.log

- `kind`: log
- `size_bytes`: 863
- `line_count`: 9
- `sha256`: 5f399347499bc409c478a2226b1cae704a0b6c44d52563fb71e948980546d966
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=863 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_branch_resolve_recovery_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_resolve_recovery_gate -o build/tb_ooo_branch_re...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_branch_spec_tracker.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: 25fdfce6bb70e7bcea8a8d732029f7795e7e5cab7b4e277725bb4d0c30c15634
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_branch_spec_tracker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_branch_spec_tracker -o build/tb_ooo_branch_spec_tracker.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_busy_table.log

- `kind`: log
- `size_bytes`: 548
- `line_count`: 6
- `sha256`: 91807e99d36df920be66cc177b2bc1a06a97badaabba287b86760c104f5eb4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=548 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_busy_table [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_busy_table -o build/tb_ooo_busy_table.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_clmul_unit.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: ee4e797d8e1a9c4d97d154c06f9dcb2ed1c633cba49c7683a62e18cfbed69c18
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_clmul_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_clmul_unit -o build/tb_ooo_clmul_unit.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_commit_output_mux.log

- `kind`: log
- `size_bytes`: 766
- `line_count`: 9
- `sha256`: b1052717b5285c90a4a5782c82a323aad143073a9b30b78afbbdfb88485f68a6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=766 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_commit_output_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_commit_output_mux -o build/tb_ooo_commit_output_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_control_commit_sequencer.log

- `kind`: log
- `size_bytes`: 831
- `line_count`: 9
- `sha256`: defb9bf943a17babafed6fc6c5fae7b9161ff5d066221023d1ebc3310294c905
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=831 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_commit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_commit_sequencer -o build/tb_ooo_control_commit_se...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_control_flush_sequencer.log

- `kind`: log
- `size_bytes`: 818
- `line_count`: 9
- `sha256`: e9338fe5a19cc5d86558687494755a6c614ce60b0f914464f720ed4370f7a2df
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=818 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_control_flush_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_control_flush_sequencer -o build/tb_ooo_control_flush_seque...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_core_top_glue.log

- `kind`: log
- `size_bytes`: 17360
- `line_count`: 80
- `sha256`: b24be2d7a460ee6570cb3c68f3899ca14a0e159c0c5aa68318bb0ab9fc16f67c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17360 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_core_top_glue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_core_top_glue -o build/tb_ooo_core_top_glue.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_csr_access_request_mux.log

- `kind`: log
- `size_bytes`: 496
- `line_count`: 5
- `sha256`: e73e47010a47982608696e5074f786753821ae709512e6d1684094b586a5bd8b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=496 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_access_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_access_request_mux -o build/tb_ooo_csr_access_request_mu...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_csr_trap_request_mux.log

- `kind`: log
- `size_bytes`: 482
- `line_count`: 5
- `sha256`: a7d5aabd586f55422fbcc2f47ea5daa4d8ec67aac26bf0dae3b778252773a578
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=482 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_csr_trap_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_csr_trap_request_mux -o build/tb_ooo_csr_trap_request_mux.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_data_word_cache.log

- `kind`: log
- `size_bytes`: 574
- `line_count`: 5
- `sha256`: 205a59ba86fcb573c18a95c6fcefc8ea3e73999ac190183be2c9f9a9c105f6c3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=574 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_data_word_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_data_word_cache -o build/tb_ooo_data_word_cache.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_direct_branch_resolve_gate.log

- `kind`: log
- `size_bytes`: 504
- `line_count`: 5
- `sha256`: be5162a675ec312415242bc64bf9d7995c9e02b547398c392f49a68dc16da7b6
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=504 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_resolve_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_resolve_gate -o build/tb_ooo_direct_branch...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_direct_branch_wait_buffer.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: be6078e7e9d420366ac8f8d6ab4551866a168e8f4e713d85e6d8e2614dce50b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_branch_wait_buffer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_branch_wait_buffer -o build/tb_ooo_direct_branch_w...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_direct_ras_candidate_gate.log

- `kind`: log
- `size_bytes`: 498
- `line_count`: 5
- `sha256`: 58ed81c8946ecb73fd36ae126a436d4efe259e58f0e057ec152518419096a24e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=498 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_direct_ras_candidate_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_direct_ras_candidate_gate -o build/tb_ooo_direct_ras_cand...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_dispatch_backend.log

- `kind`: log
- `size_bytes`: 8629
- `line_count`: 61
- `sha256`: 41cfec95392b5abd6193913dd468b487a3188c125a5a318c38ff03d28a304ecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=8629 bytes; lines=61; PASS=4; tail=[TEST] tb_ooo_dispatch_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_dispatch_backend -o build/tb_ooo_dispatch_backend.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_access_footprint.log

- `kind`: log
- `size_bytes`: 89719
- `line_count`: 717
- `sha256`: 401de6465c8fd44cf52ee1a5e12796d5660dd17d94afb48009f92edaf0450c73
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 64}
- `summary`: log evidence; size=89719 bytes; lines=717; PASS=64; tail=ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:131: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_axi_access_attrs.log

- `kind`: log
- `size_bytes`: 86462
- `line_count`: 650
- `sha256`: abefa6b3dd6db0f6ab45d37c7eca1e73ef524d13b14aaacbeac0724d3b65b472
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86462 bytes; lines=650; PASS=2; tail=ve to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86433
- `line_count`: 650
- `sha256`: 129fb938bcea093154dbc1dc8e472e099c7f6b610cd4216a77dd8561d9f30187
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86433 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_axi_bridge_xbar.log

- `kind`: log
- `size_bytes`: 89397
- `line_count`: 673
- `sha256`: 41fc91cfb82ef59366a9b847516d5d1534bdcd4ea8fbe0ed0a531b10e846c38b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=89397 bytes; lines=673; PASS=2; tail=PmpChecker.v:126: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:129: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsr...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_flow_control.log

- `kind`: log
- `size_bytes`: 457
- `line_count`: 5
- `sha256`: d4e004ad2ca1424364e6e739a1e9f743ba9ec75bcfcfce53a2a33605f10a1192
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=457 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_flow_control [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_flow_control -o build/tb_ooo_fetch_flow_control.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_head_classify_gate.log

- `kind`: log
- `size_bytes`: 555
- `line_count`: 5
- `sha256`: e6576bee6e45d208e6cbd77ac26b971d1f9fc31e951c9dd81b319cba503a75a8
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=555 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_classify_gate -o build/tb_ooo_fetch_head_classi...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_head_pair_gate.log

- `kind`: log
- `size_bytes`: 609
- `line_count`: 5
- `sha256`: b18336a370894dc5a6a074788a8d57df85188ad8a8dbef6337058700f7348d55
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=609 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_head_pair_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_head_pair_gate -o build/tb_ooo_fetch_head_pair_gate.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_packet_cache.log

- `kind`: log
- `size_bytes`: 594
- `line_count`: 5
- `sha256`: 6239028902f3e8ec0a26df0b9ef979adbdf27fe7f50d9be13f31bcbfd841d08b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=594 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_cache [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_cache -o build/tb_ooo_fetch_packet_cache.vvp /home/...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_packet_decode.log

- `kind`: log
- `size_bytes`: 532
- `line_count`: 5
- `sha256`: cf4de169894ef87f849d75001e9a5b21917634586e9d8bd4b305a72f7b47a4f3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=532 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_decode [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_decode -o build/tb_ooo_fetch_packet_decode.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_packet_fifo.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: b9d6da84fc52b6cc4edddfcad969e4605b4c69953029f76ed93a902e01aec0a9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_fifo [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_fifo -o build/tb_ooo_fetch_packet_fifo.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_packet_head_mux.log

- `kind`: log
- `size_bytes`: 473
- `line_count`: 5
- `sha256`: 96135f14a5faa3a6adc02907fca5d0ed5be4bc2047bf8f7fdec49576eee1022d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=473 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_packet_head_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_head_mux -o build/tb_ooo_fetch_packet_head_mux.v...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_packet_seed_mux.log

- `kind`: log
- `size_bytes`: 627
- `line_count`: 6
- `sha256`: 2dcb9713b85b75c3b128e07e60093bc2337c45cf51a4c57ce734d0bd7553113a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=627 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_fetch_packet_seed_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_packet_seed_mux -o build/tb_ooo_fetch_packet_seed_mux.v...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87798
- `line_count`: 664
- `sha256`: 3998893851256d56bbb1a769e031b67cfbfb4f3ce45425ffd04465e415c22a16
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87798 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_pc_outstanding_sequencer.log

- `kind`: log
- `size_bytes`: 528
- `line_count`: 5
- `sha256`: f59f4ec97b33fe7fb22e9832889ee5b814a2ca2b77929b19a73b68a19ba690cf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=528 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_pc_outstanding_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_pc_outstanding_sequencer -o build/tb_ooo_fetch...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_request_mux.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: f457485d59b3971e89cfb1240e85fee13dd666acd671e9257d163098c18e65b3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fetch_request_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_request_mux -o build/tb_ooo_fetch_request_mux.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fetch_trap_gate.log

- `kind`: log
- `size_bytes`: 17370
- `line_count`: 80
- `sha256`: 173dcccf1007869bdfd11b9b60554ad5bdbaaf7e555ea11d7afd4cb58f2a5649
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17370 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_fetch_trap_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fetch_trap_gate -o build/tb_ooo_fetch_trap_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_arith_gate.log

- `kind`: log
- `size_bytes`: 427
- `line_count`: 5
- `sha256`: 13e0abaffcb3a04e9f92959c9cc7a98b067d057abe84ea813f88e79e1eefcf89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=427 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_arith_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_arith_gate -o build/tb_ooo_fp_arith_gate.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_classify_gate.log

- `kind`: log
- `size_bytes`: 444
- `line_count`: 5
- `sha256`: 68e7c7406ab7d20ac8d2b133afb5c1b1f6f1762ec1e51d102567aee6f9c69a5a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=444 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_classify_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_classify_gate -o build/tb_ooo_fp_classify_gate.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_compare_gate.log

- `kind`: log
- `size_bytes`: 438
- `line_count`: 5
- `sha256`: 1b2e6eedeb3f1f4f8f07cfbfb1cf18bad9acb613e41778f8c912343d4b380956
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=438 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_compare_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_compare_gate -o build/tb_ooo_fp_compare_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_convert_gate.log

- `kind`: log
- `size_bytes`: 437
- `line_count`: 5
- `sha256`: d93b0f3138b257deac4ab84a73a483db3bc2370659cd7e5281fb05707a2fc1c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=437 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_convert_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_convert_gate -o build/tb_ooo_fp_convert_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_iter.log

- `kind`: log
- `size_bytes`: 462
- `line_count`: 5
- `sha256`: c961db43c461f546ffa5c8fdbaba601ca2d0533c87f5310ec2e1801dabb46058
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=462 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_iter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_iter -o build/tb_ooo_fp_iter.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_legality_dispatch_path.log

- `kind`: log
- `size_bytes`: 1406
- `line_count`: 13
- `sha256`: 70c6554f24328279a060d3df904dd67f210ff26c772614e23ef3a15ee8d9fd7f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1406 bytes; lines=13; PASS=4; tail=[TEST] tb_ooo_fp_legality_dispatch_path [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_legality_dispatch_path -o build/tb_ooo_fp_legality_dis...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_long_op_gate.log

- `kind`: log
- `size_bytes`: 569
- `line_count`: 5
- `sha256`: 610a8e10319ce215d413ee832c0a757f00f9beccfa591123d2652a627d554939
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=569 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_long_op_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_long_op_gate -o build/tb_ooo_fp_long_op_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_reg_file.log

- `kind`: log
- `size_bytes`: 723
- `line_count`: 9
- `sha256`: e2487dda1518f5421d50e3b63fa47ebc9c029c008e2ed57b47f8ac5ca181593b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=723 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_fp_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_reg_file -o build/tb_ooo_fp_reg_file.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_fp_sgnj_gate.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: a3c77e36227899854124dc2ab3ad25c6d29db53257965948a3d6971ddc118ef3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_fp_sgnj_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_fp_sgnj_gate -o build/tb_ooo_fp_sgnj_gate.vvp /home/lyg/PA/ysyx-workbe...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_free_list.log

- `kind`: log
- `size_bytes`: 411
- `line_count`: 5
- `sha256`: c4f2b8e8776d63296c38e4ec7aa134e4c70cd30705bf16acc3b83541a89defb9
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=411 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_free_list [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_free_list -o build/tb_ooo_free_list.vvp /home/lyg/PA/ysyx-workbench/npc/r...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_frontend_action_gate.log

- `kind`: log
- `size_bytes`: 469
- `line_count`: 5
- `sha256`: 5d395ffe377001931625d1b3ae0f5570ead967257d584331dd484710da20f4f0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=469 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_action_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_action_gate -o build/tb_ooo_frontend_action_gate.vvp...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_frontend_backend_dispatch_mux.log

- `kind`: log
- `size_bytes`: 877
- `line_count`: 10
- `sha256`: 6048a2e2ae7bb138d331d3a7affb61f17893edabb6376a19b87ec9ba000afd17
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=877 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_frontend_backend_dispatch_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_backend_dispatch_mux -o build/tb_ooo_fronten...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_frontend_dispatch_gate.log

- `kind`: log
- `size_bytes`: 789
- `line_count`: 7
- `sha256`: a580dcc4ba57832ea0627dbca837ebcb4f6a49f7bea9f7ad16467de197a9b8bb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=789 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_frontend_dispatch_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_dispatch_gate -o build/tb_ooo_frontend_dispatch_gat...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_frontend_run_gate.log

- `kind`: log
- `size_bytes`: 451
- `line_count`: 5
- `sha256`: 1002a5f762b59c00bb5b448f129c6e8a4786a5a3d50e81a8cc133b797094d501
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=451 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_run_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_run_gate -o build/tb_ooo_frontend_run_gate.vvp /home/lyg...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_frontend_uop_safety.log

- `kind`: log
- `size_bytes`: 463
- `line_count`: 5
- `sha256`: e382803aa27b72cfbe99f1fe8bc4952e3bd13770fa05c0c94a2c4ee6659d792a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=463 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_frontend_uop_safety [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_frontend_uop_safety -o build/tb_ooo_frontend_uop_safety.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_ifu_lane1_fault_owner.log

- `kind`: log
- `size_bytes`: 3507
- `line_count`: 32
- `sha256`: a63fac822372047ce9be52abd1f663b0ca8f241f3c37788427495d6c0d2ff569
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 22}
- `summary`: log evidence; size=3507 bytes; lines=32; PASS=22; tail=[TEST] tb_ooo_ifu_lane1_fault_owner [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ifu_lane1_fault_owner -o build/tb_ooo_ifu_lane1_fault_owner.v...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_int_backend.log

- `kind`: log
- `size_bytes`: 13729
- `line_count`: 87
- `sha256`: afd1fefafbf18033dee987085379bb4ca1c9eaf51411dde2e697c6eb3e5c62d7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=13729 bytes; lines=87; PASS=4; tail=[TEST] tb_ooo_int_backend [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_backend -o build/tb_ooo_int_backend.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_int_issue_queue.log

- `kind`: log
- `size_bytes`: 7248
- `line_count`: 54
- `sha256`: e9e9535f0f5921ab4a8bbe221d658fdf98e171f8f580b3c212d74c303922ada4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=7248 bytes; lines=54; PASS=4; tail=[TEST] tb_ooo_int_issue_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_int_issue_queue -o build/tb_ooo_int_issue_queue.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_mem_axi_bridge.log

- `kind`: log
- `size_bytes`: 52123
- `line_count`: 392
- `sha256`: 4165d73c06a1c49db69fae0fdb36d44395ec760efc1cd17cab76d3bd72bfb35a
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=52123 bytes; lines=392; PASS=4; tail=[TEST] tb_ooo_mem_axi_bridge [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_mem_axi_bridge -o build/tb_ooo_mem_axi_bridge.vvp /home/lyg/PA/ysyx-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_memory_request_gate.log

- `kind`: log
- `size_bytes`: 921
- `line_count`: 8
- `sha256`: 34283106158711481e0c8c5754eabc5719dff0852b83a73913fe4ca3e5749bfc
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=921 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_memory_request_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_memory_request_gate -o build/tb_ooo_memory_request_gate.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_muldiv_unit.log

- `kind`: log
- `size_bytes`: 419
- `line_count`: 5
- `sha256`: 93fa75b94df25ee3e977a9cb82879bf681b8fe0d0e027b335a14723c93ecf5b0
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=419 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_muldiv_unit [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_muldiv_unit -o build/tb_ooo_muldiv_unit.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_pending_dispatch_arbiter.log

- `kind`: log
- `size_bytes`: 1061
- `line_count`: 11
- `sha256`: 04cf74c5a24d833461dba65276eb023150e614ff1d8011f933828a371816d841
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=1061 bytes; lines=11; PASS=4; tail=[TEST] tb_ooo_pending_dispatch_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_dispatch_arbiter -o build/tb_ooo_pending_dispatch_...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_pending_lane1_capture_gate.log

- `kind`: log
- `size_bytes`: 851
- `line_count`: 10
- `sha256`: df330d04fc9c9fc34c8e049bc34ae0e006a4934d1536eed864def5aa07c90f08
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=851 bytes; lines=10; PASS=4; tail=[TEST] tb_ooo_pending_lane1_capture_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_lane1_capture_gate -o build/tb_ooo_pending_lane1...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_pending_system_sequencer.log

- `kind`: log
- `size_bytes`: 827
- `line_count`: 9
- `sha256`: a03d56440bc0fb1dcaa9b8322429a493b78aec2aae91c802a18b621e36493a2d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=827 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_pending_system_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_system_sequencer -o build/tb_ooo_pending_system_se...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_pending_trap_exit_sequencer.log

- `kind`: log
- `size_bytes`: 696
- `line_count`: 6
- `sha256`: 1319ed77b46cf93e33e2c65c911dceef15fe29b4e539846f6b9d4998733a97bf
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=696 bytes; lines=6; PASS=4; tail=[TEST] tb_ooo_pending_trap_exit_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_pending_trap_exit_sequencer -o build/tb_ooo_pending_tra...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_phys_reg_file.log

- `kind`: log
- `size_bytes`: 694
- `line_count`: 7
- `sha256`: 6b7d5423ef11199618478b4b3977c6b9cae3f9043498163520b419555b9edfce
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=694 bytes; lines=7; PASS=4; tail=[TEST] tb_ooo_phys_reg_file [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_phys_reg_file -o build/tb_ooo_phys_reg_file.vvp /home/lyg/PA/ysyx-wor...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_priv_system.log

- `kind`: log
- `size_bytes`: 17346
- `line_count`: 80
- `sha256`: 5aeb8a2089e7daf7091c19f70e52a05d3a081f39e2363a4d0417d3830c41ee89
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17346 bytes; lines=80; PASS=4; tail=[TEST] tb_ooo_priv_system [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_priv_system -o build/tb_ooo_priv_system.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_ras_update_gate.log

- `kind`: log
- `size_bytes`: 439
- `line_count`: 5
- `sha256`: 645c64e0521fa5914350e0bf00da46cd47decfe0e162793c0a7e9ea7458a1a43
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=439 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_ras_update_gate [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_ras_update_gate -o build/tb_ooo_ras_update_gate.vvp /home/lyg/PA/ys...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_redirect_arbiter.log

- `kind`: log
- `size_bytes`: 445
- `line_count`: 5
- `sha256`: fcd2024f551c192ade5e1524415bebdd4a934746c8ceb9c7179b4d6ea2cf23e3
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=445 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_redirect_arbiter [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_redirect_arbiter -o build/tb_ooo_redirect_arbiter.vvp /home/lyg/PA...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_rename_map.log

- `kind`: log
- `size_bytes`: 417
- `line_count`: 5
- `sha256`: f6ffdc3089928e65a97207705c769b544d71268ef6c353d420ac723c2d7f9c7d
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=417 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_rename_map [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rename_map -o build/tb_ooo_rename_map.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_rob.log

- `kind`: log
- `size_bytes`: 709
- `line_count`: 8
- `sha256`: 5471b6d4c9db65882b0766d7cbf1f69af38cc176f129c7afca23a89dd1633822
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=709 bytes; lines=8; PASS=4; tail=[TEST] tb_ooo_rob [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_rob -o build/tb_ooo_rob.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_stop_pending_sequencer.log

- `kind`: log
- `size_bytes`: 809
- `line_count`: 9
- `sha256`: 4506ecc163609321f79102d4d24c3d33ac549437075e8dfe0bf9e807b3dcb517
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=809 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_stop_pending_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_stop_pending_sequencer -o build/tb_ooo_stop_pending_sequence...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_store_queue.log

- `kind`: log
- `size_bytes`: 942
- `line_count`: 9
- `sha256`: ed46344ff708085739ed4cea99139c689c9bed936fbedfb2efa5a73fb8628eff
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=942 bytes; lines=9; PASS=4; tail=[TEST] tb_ooo_store_queue [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_store_queue -o build/tb_ooo_store_queue.vvp /home/lyg/PA/ysyx-workbench...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_sv39_boot.log

- `kind`: log
- `size_bytes`: 155876
- `line_count`: 1115
- `sha256`: b6323debf722ff9677ce8bb0c8f22e2e05315190dfecd48a67dc01b0bd446d19
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=155876 bytes; lines=1115; PASS=2; tail=/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_trap_exit_event_mux.log

- `kind`: log
- `size_bytes`: 475
- `line_count`: 5
- `sha256`: ac5aab0dd9d94137af320075403c4cb7125a14a16bc1177b34bbfecd400ecf0e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=475 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_event_mux [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_event_mux -o build/tb_ooo_trap_exit_event_mux.vvp /ho...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_ooo_trap_exit_output_sequencer.log

- `kind`: log
- `size_bytes`: 524
- `line_count`: 5
- `sha256`: 1ac211af0e072efca2f4a423d5fea6df28684f6bc3b7d41e103ba515e54087e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=524 bytes; lines=5; PASS=4; tail=[TEST] tb_ooo_trap_exit_output_sequencer [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_ooo_trap_exit_output_sequencer -o build/tb_ooo_trap_exit_out...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_pipe_stage_reg.log

- `kind`: log
- `size_bytes`: 410
- `line_count`: 5
- `sha256`: e73111bedc8ae2d1013926dfdfe0580b15f21a7a7b94854163e41e31e585b9c5
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=410 bytes; lines=5; PASS=4; tail=[TEST] tb_pipe_stage_reg [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pipe_stage_reg -o build/tb_pipe_stage_reg.vvp /home/lyg/PA/ysyx-workbench/np...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_pmp_checker.log

- `kind`: log
- `size_bytes`: 17537
- `line_count`: 134
- `sha256`: 4da5619c385f0d5dbf50104ceacf07b3b07a5ccc38b292a678c81ad0ff8826e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=17537 bytes; lines=134; PASS=4; tail=[TEST] tb_pmp_checker [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_pmp_checker -o build/tb_pmp_checker.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vs...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_uart.log

- `kind`: log
- `size_bytes`: 348
- `line_count`: 5
- `sha256`: eae52d06a4c86245ff39b27490d28d398b26b8e5d02e98a35740060460c68a53
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=348 bytes; lines=5; PASS=4; tail=[TEST] tb_uart [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_uart -o build/tb_uart.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/bus/Uart.v tests/t...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/logs/tb_wbu.log

- `kind`: log
- `size_bytes`: 346
- `line_count`: 5
- `sha256`: 91958f506afb22ad0a7b048c959612424f0b2ea5f6ce9b9c35f1d81418de3df7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=346 bytes; lines=5; PASS=4; tail=[TEST] tb_wbu [COMPILE] iverilog -g2012 -Wall -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc -I/home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/include -Icommon -DOOO_ASSERT -s tb_wbu -o build/tb_wbu.vvp /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/writeback/WBU.v tests...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full/summary.txt

- `kind`: txt
- `size_bytes`: 3110
- `line_count`: 102
- `sha256`: 7d698766a252e64709e86bf48243c50a4e867ffe2dd01f352afeb078e4dfa96b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 186}
- `summary`: txt evidence; size=3110 bytes; lines=102; PASS=186; tail=# NPC single module testbench summary - result_dir: /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/module-current-full - tool: Icarus Verilog version 14.0 (devel) (s20260301-263-ge02a0bc2e-dirty) - PASS tb_pipe_stage_re...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current-5ns.tcl

- `kind`: tcl
- `size_bytes`: 1360
- `line_count`: 39
- `sha256`: 2624aae52ad11a337a99a8bc5ea9fa5ff4cbe8bd4a9e66909ed18ee68be24c7b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: tcl evidence; size=1360 bytes; lines=39; markers=<none>; tail=proc require_env {name} { if {![info exists ::env($name)] || $::env($name) eq ""} { error "required environment variable is missing: $name" } return $::env($name) } set netlist [file normalize [require_env IFU_ACCESS_STA_NETLIST]] set out_dir [file normaliz...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current-runner.md

- `kind`: md
- `size_bytes`: 1603
- `line_count`: 32
- `sha256`: b4c0fa30fa723a520397da3c73017261223b6802c7bfa2bb0d67fcf1961efe75
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: md evidence; size=1603 bytes; lines=32; markers=<none>; tail=# IFU-ACCESS-G1 current 5 ns OpenSTA runner This runner consumes only the dedicated fresh synthesis directory `tmp/2026-07-13-rv64-ifu-access-g1/sta-build/NpcTop-200MHz`. It refuses to run until the netlist, `synth_check.txt`, and the terminal Yosys `End of...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-axixbar-paths.rpt

- `kind`: rpt
- `size_bytes`: 0
- `line_count`: 0
- `sha256`: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: rpt evidence; size=0 bytes; lines=0; markers=<none>; tail=

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-check-setup.txt

- `kind`: txt
- `size_bytes`: 888755
- `line_count`: 11822
- `sha256`: 1b15e22245999f36c9af4688a9b2c55b7a736f54ca4502429b2084cfa4c2a66c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=888755 bytes; lines=11822; markers=<none>; tail=d/u_core_slice/u_decode_backend/u_int_backend/_62881_/A1 | loop cut point u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/_62881_/Y -------------------------------- u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_ba...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-console.log

- `kind`: log
- `size_bytes`: 350
- `line_count`: 6
- `sha256`: 8d96100a9ad9bc64ae133a4de673bd14663ad909dfa96f14ba1dbefe329c398b
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: log evidence; size=350 bytes; lines=6; markers=<none>; tail=OpenSTA 3.1.0 ceb7e6389d Copyright (c) 2026, Parallax Software, Inc. License GPLv3: GNU GPL version 3 <http://gnu.org/licenses/gpl.html> This is free software, and you are free to change and redistribute it under certain conditions; type `show_copying' for...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-custom-focus-paths.rpt

- `kind`: rpt
- `size_bytes`: 19853
- `line_count`: 175
- `sha256`: 595fe73bcd8c2e2ba77fb5cd3430ea29c06274615df52a7ad340356a091c64ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: rpt evidence; size=19853 bytes; lines=175; markers=<none>; tail=Startpoint: u_core/u_ooo_mem_bridge/u_dcache/u_sram (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_cloc...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-ifu-paths.rpt

- `kind`: rpt
- `size_bytes`: 19853
- `line_count`: 175
- `sha256`: 595fe73bcd8c2e2ba77fb5cd3430ea29c06274615df52a7ad340356a091c64ea
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: rpt evidence; size=19853 bytes; lines=175; markers=<none>; tail=Startpoint: u_core/u_ooo_mem_bridge/u_dcache/u_sram (rising edge-triggered flip-flop clocked by core_clock) Endpoint: u_core/u_ooo_fetch_bridge/u_fetch_packet_cache/u_payload_sram (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_cloc...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-manifest.txt

- `kind`: txt
- `size_bytes`: 1429
- `line_count`: 11
- `sha256`: f2f5b60d8b6f0c5f62cdeb5b4fdcadac428b441dff628812965d9136347f6a44
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=1429 bytes; lines=11; markers=<none>; tail=timestamp=2026-07-13T01:12:52+08:00 command=/home/lyg/tools/OpenSTA/build/sta /home/lyg/PA/ysyx-workbench/.github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current-5ns.tcl period_ns=5.0 netlist=/home/lyg/PA/ysyx-workbench/tmp/2026-07-13-rv64-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-netlist-focus-names.txt

- `kind`: txt
- `size_bytes`: 12275
- `line_count`: 80
- `sha256`: 787853172bf15b7ccb6c92828ab36faf4fbefa1a828fff44c3a46f0ab6ec8951
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: txt evidence; size=12275 bytes; lines=80; markers=<none>; tail=754167:, csr_satp_w_55_, csr_satp_w_56_, csr_satp_w_57_, csr_satp_w_58_, csr_satp_w_59_, csr_satp_w_60_, csr_satp_w_61_, csr_satp_w_62_, csr_satp_w_63_, csr_svpbmt_en_w, ctrl_commit_valid_q, direct_branch0_dispatch_valid_w, direct_branch0_fire_w, direct_bra...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-power.rpt

- `kind`: rpt
- `size_bytes`: 754
- `line_count`: 11
- `sha256`: 69ada1cff57f063973feac7c40bcb4b49645f1df949c0a066f8d35c9a31dfc85
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: rpt evidence; size=754 bytes; lines=11; markers=<none>; tail=Group Internal Switching Leakage Total Power Power Power Power (Watts) ---------------------------------------------------------------- Sequential 9.54e-02 1.08e-04 1.81e-04 9.57e-02 80.8% Combinational 6.55e-03 7.95e-03 4.64e-04 1.50e-02 12.6% Clock 2.80e-...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-summary.txt

- `kind`: txt
- `size_bytes`: 229
- `line_count`: 10
- `sha256`: f8ce448abc654dc342d6b1d79ec050232c2dc8fd00c5de288b32703a897a70e4
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: txt evidence; size=229 bytes; lines=10; PASS=2; tail=status=PASS period_ns=5.0 wns max -10.00 tns max -120125.49 top40_requested=40 top40_reported=40 ifu_top40_paths=1 axixbar_top40_paths=0 custom_focus_top40_paths=1 non_signoff=ideal_clock,no_spef,no_cts,no_ocv,placeholder_macros

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/opensta-current/opensta-current-top40.rpt

- `kind`: rpt
- `size_bytes`: 872739
- `line_count`: 7470
- `sha256`: fe4ef7d857af04c290607be13c6e550d6b6f8dfb1d9912920224ecd43b172844
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: rpt evidence; size=872739 bytes; lines=7470; markers=<none>; tail=ed by core_clock) Endpoint: u_core/u_ooo_core/u_execute_backend/u_core_slice/u_decode_backend/u_int_backend/u_mem_inflight_queue/_8002_ (rising edge-triggered flip-flop clocked by core_clock) Path Group: core_clock Path Type: max Delay Time Description ----...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/run-opensta-current-5ns.sh

- `kind`: sh
- `size_bytes`: 5436
- `line_count`: 146
- `sha256`: dd0e237e333a96e1da424b1083bc119c1e1a5219a40936d6bf22765e2f33a004
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: sh evidence; size=5436 bytes; lines=146; PASS=4; tail=#!/usr/bin/env bash set -euo pipefail SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel) SYNTH_RESULT_DIR=${IFU_ACCESS_SYNTH_RESULT_DIR:-"$ROOT/tmp/2026-07-13-rv64-ifu-access-g1/sta-build/NpcTop-2...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/second-page-ad-current/logs/tb_ooo_fetch_axi_bridge.log

- `kind`: log
- `size_bytes`: 86458
- `line_count`: 650
- `sha256`: 850d8e54b86b69ed115662663c410b3cb5bb9c57a21b1315909079ad12bf3f9c
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=86458 bytes; lines=650; PASS=2; tail=nsitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:105: warning: @* is sensitive to all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning:...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/second-page-ad-current/logs/tb_ooo_fetch_page_end_fault.log

- `kind`: log
- `size_bytes`: 87823
- `line_count`: 664
- `sha256`: 4790253c2a68bd68e697ef79130fb48e14959adb77467918e54b50a9fb2c9a5f
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 2}
- `summary`: log evidence; size=87823 bytes; lines=664; PASS=2; tail=o all 16 words in array 'entry_cfg_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:108: warning: @* is sensitive to all 16 words in array 'entry_addr_w'. /home/lyg/PA/ysyx-workbench/npc/rv64/vsrc/memory/PmpChecker.v:109: warning: @* is sen...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/second-page-ad-current/summary.md

- `kind`: md
- `size_bytes`: 3307
- `line_count`: 58
- `sha256`: 08647f7302e7c595e564c7e80b992fa39a14a117557c556c769f9f80f5ebaecb
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 10}
- `summary`: md evidence; size=3307 bytes; lines=58; PASS=10; tail=# IFU-ACCESS-G1 second-page A-update focused evidence - 日期：2026-07-13 - production 改动：无 - 测试改动：`npc/rv64/testbench/tests/tb_ooo_fetch_page_end_fault.sv` - 工具：仓库 `scripts/agent-env.sh` 提供的 Icarus Verilog 14.0，`-DOOO_ASSERT` ## 覆盖合同 1. 从 `PC=page+0xFFE` 发起真实...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/sta-current-review.md

- `kind`: md
- `size_bytes`: 4387
- `line_count`: 73
- `sha256`: 81c58f031282b3705f4f8a9e488de5c61b267ac26707864bf7716c5993affe37
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {}
- `summary`: md evidence; size=4387 bytes; lines=73; markers=<none>; tail=# IFU-ACCESS-G1 fresh 5 ns synthesis / OpenSTA review ## Fresh synthesis - dedicated result root: `tmp/2026-07-13-rv64-ifu-access-g1/sta-build/NpcTop-200MHz`; command, source/config hashes and macro/keep-hierarchy contract are frozen in `tmp/2026-07-13-rv64...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/structural-current.log

- `kind`: log
- `size_bytes`: 9831
- `line_count`: 19
- `sha256`: 0f28c1cd00b992a42d3b0e21283699e5f548457f78fef542c497396aa409695e
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: log evidence; size=9831 bytes; lines=19; PASS=4; tail=Script started on 2026-07-13 00:41:29+08:00 [COMMAND="source scripts/agent-env.sh >/dev/null 2>&1 && make -C npc/rv64 check-rtl-style && make -C npc/rv64 check-contract && make -C npc/rv64 lint && make -C npc/rv64 -j2 default" <not executed on terminal>] ma...

### .github/task-runs/2026-07-12-rv64-ifu-access-g1/evidence/tmp-archive-current/summary.md

- `kind`: md
- `size_bytes`: 1590
- `line_count`: 31
- `sha256`: bb572546700000034b630f8182ed5e1380668820bf370cc0af980ffefaf4a4c7
- `encoding`: utf-8
- `indexed_at`: 2026-07-12T17:29:20+00:00
- `markers`: {"PASS": 4}
- `summary`: md evidence; size=1590 bytes; lines=31; PASS=4; tail=# Related system `/tmp` archive Per the user request, system `/tmp` artifacts related to the RV64 architecture goal were copied into the workspace `tmp/` archive without deleting or rewriting their sources. - archive: `tmp/2026-07-13-goal-tmp-snapshot.tar.z...
